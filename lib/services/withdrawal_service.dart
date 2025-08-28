import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/withdrawal_request.dart';
import 'fraud_detection_service.dart';

class WithdrawalService {
  static final WithdrawalService _instance = WithdrawalService._internal();
  factory WithdrawalService() => _instance;
  WithdrawalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FraudDetectionService _fraudDetection = FraudDetectionService();

  // Withdrawal limits
  static const double minWithdrawalAmount = 5.0;
  static const double maxWithdrawalAmount = 1000.0;
  static const int maxWithdrawalsPerDay = 3;
  static const int maxWithdrawalsPerMonth = 20;

  /// Submit a withdrawal request
  Future<WithdrawalRequest> submitWithdrawalRequest({
    required String userId,
    required double amount,
    required WithdrawalMethod method,
    required Map<String, dynamic> paymentDetails,
    String? note,
  }) async {
    try {
      // Validate withdrawal request
      await _validateWithdrawalRequest(userId, amount, method);

      // Check fraud indicators
      final fraudAnalysis = await _fraudDetection.analyzeUserBehavior(
        userId: userId,
        action: 'withdrawal_request',
        additionalData: {
          'amount': amount,
          'method': method.toString(),
          'paymentDetails': _sanitizePaymentDetails(paymentDetails),
        },
      );

      // Determine if manual review is needed
      bool requiresManualReview = _requiresManualReview(fraudAnalysis, amount);

      final request = WithdrawalRequest(
        id: '', // Will be set by Firestore
        userId: userId,
        amount: amount,
        method: method,
        paymentDetails: paymentDetails,
        status: requiresManualReview
            ? WithdrawalStatus.pendingReview
            : WithdrawalStatus.pending,
        requestedAt: DateTime.now(),
        note: note,
        fraudScore: fraudAnalysis.riskScore,
        requiresManualReview: requiresManualReview,
      );

      // Save withdrawal request
      final docRef = await _firestore
          .collection('withdrawal_requests')
          .add(request.toJson());
      final requestWithId = request.copyWith(id: docRef.id);

      // Deduct amount from user's available balance
      await _reserveUserFunds(userId, amount);

      // Log withdrawal attempt
      await _logWithdrawalAttempt(requestWithId, fraudAnalysis);

      // If auto-approved, process immediately
      if (!requiresManualReview && fraudAnalysis.riskScore < 30) {
        await _processWithdrawalAsync(requestWithId);
      }

      return requestWithId;
    } catch (e) {
      throw Exception('Failed to submit withdrawal request: $e');
    }
  }

  /// Validate withdrawal request
  Future<void> _validateWithdrawalRequest(
    String userId,
    double amount,
    WithdrawalMethod method,
  ) async {
    // Check amount limits
    if (amount < minWithdrawalAmount) {
      throw Exception(
          'Minimum withdrawal amount is \$${minWithdrawalAmount.toStringAsFixed(2)}');
    }

    if (amount > maxWithdrawalAmount) {
      throw Exception(
          'Maximum withdrawal amount is \$${maxWithdrawalAmount.toStringAsFixed(2)}');
    }

    // Check user's available balance
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final userData = userDoc.data()!;
    final availableBalance =
        (userData['availableBalance'] as num?)?.toDouble() ?? 0.0;
    final pendingWithdrawals =
        (userData['pendingWithdrawals'] as num?)?.toDouble() ?? 0.0;

    final effectiveBalance = availableBalance - pendingWithdrawals;

    if (effectiveBalance < amount) {
      throw Exception(
          'Insufficient balance. Available: \$${effectiveBalance.toStringAsFixed(2)}');
    }

    // Check daily withdrawal limits
    await _checkDailyLimits(userId);

    // Check monthly withdrawal limits
    await _checkMonthlyLimits(userId);

    // Check if user is verified for the withdrawal method
    await _checkUserVerification(userId, method);
  }

  /// Check daily withdrawal limits
  Future<void> _checkDailyLimits(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayWithdrawals = await _firestore
        .collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .where('requestedAt', isGreaterThanOrEqualTo: startOfDay)
        .get();

    if (todayWithdrawals.docs.length >= maxWithdrawalsPerDay) {
      throw Exception(
          'Daily withdrawal limit exceeded. Maximum $maxWithdrawalsPerDay withdrawals per day.');
    }

    // Check daily amount limit
    final todayAmount = todayWithdrawals.docs.fold(0.0, (sum, doc) {
      return sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0);
    });

    if (todayAmount > 500.0) {
      // Daily amount limit
      throw Exception(
          'Daily withdrawal amount limit exceeded. Maximum \$500 per day.');
    }
  }

  /// Check monthly withdrawal limits
  Future<void> _checkMonthlyLimits(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthlyWithdrawals = await _firestore
        .collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .where('requestedAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    if (monthlyWithdrawals.docs.length >= maxWithdrawalsPerMonth) {
      throw Exception(
          'Monthly withdrawal limit exceeded. Maximum $maxWithdrawalsPerMonth withdrawals per month.');
    }
  }

  /// Check user verification for withdrawal method
  Future<void> _checkUserVerification(
      String userId, WithdrawalMethod method) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data()!;

    final verifications =
        userData['verifications'] as Map<String, dynamic>? ?? {};

    switch (method) {
      case WithdrawalMethod.paypal:
        if (verifications['paypal'] != true) {
          throw Exception(
              'PayPal account verification required for withdrawals');
        }
        break;
      case WithdrawalMethod.bankTransfer:
        if (verifications['bankAccount'] != true) {
          throw Exception('Bank account verification required for withdrawals');
        }
        break;
      case WithdrawalMethod.cryptocurrency:
        if (verifications['crypto'] != true) {
          throw Exception(
              'Cryptocurrency verification required for withdrawals');
        }
        break;
      case WithdrawalMethod.giftCard:
        // Gift cards typically don't require verification
        break;
    }
  }

  /// Reserve user funds for withdrawal
  Future<void> _reserveUserFunds(String userId, double amount) async {
    await _firestore.collection('users').doc(userId).update({
      'pendingWithdrawals': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Release reserved funds (if withdrawal is cancelled/failed)
  Future<void> _releaseUserFunds(String userId, double amount) async {
    await _firestore.collection('users').doc(userId).update({
      'pendingWithdrawals': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sanitize payment details for logging
  Map<String, dynamic> _sanitizePaymentDetails(Map<String, dynamic> details) {
    final sanitized = Map<String, dynamic>.from(details);

    // Remove sensitive information
    if (sanitized.containsKey('accountNumber')) {
      final accountNumber = sanitized['accountNumber'] as String?;
      if (accountNumber != null && accountNumber.length > 4) {
        sanitized['accountNumber'] =
            '****${accountNumber.substring(accountNumber.length - 4)}';
      }
    }

    if (sanitized.containsKey('routingNumber')) {
      sanitized.remove('routingNumber');
    }

    if (sanitized.containsKey('cryptoAddress')) {
      final address = sanitized['cryptoAddress'] as String?;
      if (address != null && address.length > 8) {
        sanitized['cryptoAddress'] =
            '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
      }
    }

    return sanitized;
  }

  /// Check if manual review is required
  bool _requiresManualReview(FraudAnalysisResult fraudAnalysis, double amount) {
    // High risk score always requires review
    if (fraudAnalysis.riskScore >= 70) return true;

    // Large amounts require review
    if (amount >= 100.0) return true;

    // Medium risk with moderate amount requires review
    if (fraudAnalysis.riskScore >= 40 && amount >= 50.0) return true;

    return false;
  }

  /// Log withdrawal attempt
  Future<void> _logWithdrawalAttempt(
    WithdrawalRequest request,
    FraudAnalysisResult fraudAnalysis,
  ) async {
    try {
      await _firestore.collection('withdrawal_logs').add({
        'requestId': request.id,
        'userId': request.userId,
        'amount': request.amount,
        'method': request.method.toString(),
        'status': request.status.toString(),
        'fraudScore': fraudAnalysis.riskScore,
        'riskLevel': fraudAnalysis.riskLevel.toString(),
        'requiresManualReview': request.requiresManualReview,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceFingerprint': fraudAnalysis.deviceFingerprint,
      });
    } catch (e) {
      print('Error logging withdrawal attempt: $e');
    }
  }

  /// Process withdrawal asynchronously
  Future<void> _processWithdrawalAsync(WithdrawalRequest request) async {
    try {
      // Update status to processing
      await _updateWithdrawalStatus(request.id, WithdrawalStatus.processing);

      // Simulate payment processing (replace with actual payment gateway)
      final success = await _processPayment(request);

      if (success) {
        await _completeWithdrawal(request);
      } else {
        await _failWithdrawal(request.id, 'Payment processing failed');
      }
    } catch (e) {
      await _failWithdrawal(request.id, e.toString());
    }
  }

  /// Process payment through appropriate gateway
  Future<bool> _processPayment(WithdrawalRequest request) async {
    try {
      switch (request.method) {
        case WithdrawalMethod.paypal:
          return await _processPayPalPayment(request);
        case WithdrawalMethod.bankTransfer:
          return await _processBankTransfer(request);
        case WithdrawalMethod.cryptocurrency:
          return await _processCryptoPayment(request);
        case WithdrawalMethod.giftCard:
          return await _processGiftCardPayment(request);
      }
    } catch (e) {
      print('Payment processing error: $e');
      return false;
    }
  }

  /// Process PayPal payment
  Future<bool> _processPayPalPayment(WithdrawalRequest request) async {
    // Simulate PayPal API call
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 95% success rate
    return Random().nextDouble() < 0.95;
  }

  /// Process bank transfer
  Future<bool> _processBankTransfer(WithdrawalRequest request) async {
    // Simulate bank API call
    await Future.delayed(const Duration(seconds: 3));

    // Simulate 90% success rate (bank transfers are more prone to issues)
    return Random().nextDouble() < 0.90;
  }

  /// Process cryptocurrency payment
  Future<bool> _processCryptoPayment(WithdrawalRequest request) async {
    // Simulate crypto transaction
    await Future.delayed(const Duration(seconds: 1));

    // Simulate 98% success rate
    return Random().nextDouble() < 0.98;
  }

  /// Process gift card payment
  Future<bool> _processGiftCardPayment(WithdrawalRequest request) async {
    // Simulate gift card generation
    await Future.delayed(const Duration(seconds: 1));

    // Simulate 99% success rate
    return Random().nextDouble() < 0.99;
  }

  /// Complete successful withdrawal
  Future<void> _completeWithdrawal(WithdrawalRequest request) async {
    final batch = _firestore.batch();

    // Update withdrawal status
    batch.update(
      _firestore.collection('withdrawal_requests').doc(request.id),
      {
        'status': WithdrawalStatus.completed.toString(),
        'completedAt': FieldValue.serverTimestamp(),
        'transactionId':
            'TXN_${request.id}_${DateTime.now().millisecondsSinceEpoch}',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // Update user balance
    batch.update(
      _firestore.collection('users').doc(request.userId),
      {
        'availableBalance': FieldValue.increment(-request.amount),
        'pendingWithdrawals': FieldValue.increment(-request.amount),
        'totalWithdrawn': FieldValue.increment(request.amount),
        'lastWithdrawal': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    // Send success notification
    await _sendWithdrawalNotification(request, true);
  }

  /// Fail withdrawal
  Future<void> _failWithdrawal(String requestId, String error) async {
    final requestDoc =
        await _firestore.collection('withdrawal_requests').doc(requestId).get();
    if (!requestDoc.exists) return;

    final request = WithdrawalRequest.fromJson({
      'id': requestDoc.id,
      ...requestDoc.data()!,
    });

    final batch = _firestore.batch();

    // Update withdrawal status
    batch.update(
      _firestore.collection('withdrawal_requests').doc(requestId),
      {
        'status': WithdrawalStatus.failed.toString(),
        'error': error,
        'failedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // Release reserved funds
    batch.update(
      _firestore.collection('users').doc(request.userId),
      {
        'pendingWithdrawals': FieldValue.increment(-request.amount),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    // Send failure notification
    await _sendWithdrawalNotification(request, false, error);
  }

  /// Update withdrawal status
  Future<void> _updateWithdrawalStatus(
      String requestId, WithdrawalStatus status) async {
    await _firestore.collection('withdrawal_requests').doc(requestId).update({
      'status': status.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send withdrawal notification
  Future<void> _sendWithdrawalNotification(
      WithdrawalRequest request, bool success,
      [String? error]) async {
    try {
      final title = success ? 'Withdrawal Successful' : 'Withdrawal Failed';
      final message = success
          ? 'Your withdrawal of \$${request.amount.toStringAsFixed(2)} has been processed successfully.'
          : 'Your withdrawal of \$${request.amount.toStringAsFixed(2)} failed. ${error ?? ''}';

      await _firestore.collection('notifications').add({
        'userId': request.userId,
        'type': 'withdrawal',
        'title': title,
        'message': message,
        'data': {
          'requestId': request.id,
          'amount': request.amount,
          'success': success,
          'error': error,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending withdrawal notification: $e');
    }
  }

  /// Get user's withdrawal requests
  Future<List<WithdrawalRequest>> getUserWithdrawals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('withdrawal_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user withdrawals: $e');
    }
  }

  /// Get pending withdrawal requests for admin review
  Future<List<WithdrawalRequest>> getPendingWithdrawals() async {
    try {
      final snapshot = await _firestore
          .collection('withdrawal_requests')
          .where('status', whereIn: [
            WithdrawalStatus.pending.toString(),
            WithdrawalStatus.pendingReview.toString(),
          ])
          .orderBy('requestedAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending withdrawals: $e');
    }
  }

  /// Approve withdrawal request (admin function)
  Future<void> approveWithdrawal(String requestId, String adminId) async {
    try {
      final requestDoc = await _firestore
          .collection('withdrawal_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) {
        throw Exception('Withdrawal request not found');
      }

      final request = WithdrawalRequest.fromJson({
        'id': requestDoc.id,
        ...requestDoc.data()!,
      });

      if (request.status != WithdrawalStatus.pendingReview) {
        throw Exception('Request is not pending review');
      }

      // Update status and add admin approval
      await _firestore.collection('withdrawal_requests').doc(requestId).update({
        'status': WithdrawalStatus.approved.toString(),
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Process the approved withdrawal
      await _processWithdrawalAsync(request.copyWith(
        status: WithdrawalStatus.approved,
      ));
    } catch (e) {
      throw Exception('Failed to approve withdrawal: $e');
    }
  }

  /// Reject withdrawal request (admin function)
  Future<void> rejectWithdrawal(
      String requestId, String adminId, String reason) async {
    try {
      final requestDoc = await _firestore
          .collection('withdrawal_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) {
        throw Exception('Withdrawal request not found');
      }

      final request = WithdrawalRequest.fromJson({
        'id': requestDoc.id,
        ...requestDoc.data()!,
      });

      // Update status and add rejection details
      await _firestore.collection('withdrawal_requests').doc(requestId).update({
        'status': WithdrawalStatus.rejected.toString(),
        'rejectedBy': adminId,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Release reserved funds
      await _releaseUserFunds(request.userId, request.amount);

      // Send rejection notification
      await _sendRejectionNotification(request, reason);
    } catch (e) {
      throw Exception('Failed to reject withdrawal: $e');
    }
  }

  /// Send rejection notification
  Future<void> _sendRejectionNotification(
      WithdrawalRequest request, String reason) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': request.userId,
        'type': 'withdrawal',
        'title': 'Withdrawal Rejected',
        'message':
            'Your withdrawal of \$${request.amount.toStringAsFixed(2)} was rejected. Reason: $reason',
        'data': {
          'requestId': request.id,
          'amount': request.amount,
          'reason': reason,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending rejection notification: $e');
    }
  }

  /// Get withdrawal statistics
  Future<Map<String, dynamic>> getWithdrawalStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('withdrawal_requests');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startDate != null) {
        query = query.where('requestedAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('requestedAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      final stats = {
        'totalRequests': 0,
        'totalAmount': 0.0,
        'completedRequests': 0,
        'completedAmount': 0.0,
        'pendingRequests': 0,
        'pendingAmount': 0.0,
        'failedRequests': 0,
        'failedAmount': 0.0,
        'rejectedRequests': 0,
        'rejectedAmount': 0.0,
        'averageAmount': 0.0,
        'successRate': 0.0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String?;

        stats['totalRequests'] = (stats['totalRequests'] as int) + 1;
        stats['totalAmount'] = (stats['totalAmount'] as double) + amount;

        switch (status) {
          case 'WithdrawalStatus.completed':
            stats['completedRequests'] =
                (stats['completedRequests'] as int) + 1;
            stats['completedAmount'] =
                (stats['completedAmount'] as double) + amount;
            break;
          case 'WithdrawalStatus.pending':
          case 'WithdrawalStatus.pendingReview':
          case 'WithdrawalStatus.processing':
          case 'WithdrawalStatus.approved':
            stats['pendingRequests'] = (stats['pendingRequests'] as int) + 1;
            stats['pendingAmount'] =
                (stats['pendingAmount'] as double) + amount;
            break;
          case 'WithdrawalStatus.failed':
            stats['failedRequests'] = (stats['failedRequests'] as int) + 1;
            stats['failedAmount'] = (stats['failedAmount'] as double) + amount;
            break;
          case 'WithdrawalStatus.rejected':
            stats['rejectedRequests'] = (stats['rejectedRequests'] as int) + 1;
            stats['rejectedAmount'] =
                (stats['rejectedAmount'] as double) + amount;
            break;
        }
      }

      // Calculate derived stats
      final totalRequests = stats['totalRequests'] as int? ?? 0;
      if (totalRequests > 0) {
        stats['averageAmount'] =
            (stats['totalAmount'] as double) / totalRequests;
        stats['successRate'] =
            ((stats['completedRequests'] as int) / totalRequests) * 100;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get withdrawal stats: $e');
    }
  }
}
