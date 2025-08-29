import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/withdrawal_request.dart';
import '../shared/services/encryption_service.dart';
import '../shared/data/enums.dart';
import 'fraud_detection_service.dart';
import 'notification_service.dart';

/// Enhanced Withdrawal Service with Manual Settlement Workflow
/// Supports the admin dashboard manual payment settlement process
class EnhancedWithdrawalService {
  static final EnhancedWithdrawalService _instance = EnhancedWithdrawalService._internal();
  factory EnhancedWithdrawalService() => _instance;
  EnhancedWithdrawalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FraudDetectionService _fraudDetection = FraudDetectionService();
  final EncryptionService _encryption = EncryptionService();
  final NotificationService _notification = NotificationService();

  // Withdrawal limits
  static const double minWithdrawalAmount = 5.0;
  static const double maxWithdrawalAmount = 1000.0;
  static const int maxWithdrawalsPerDay = 3;
  static const int maxWithdrawalsPerMonth = 20;

  /// Submit a withdrawal request with enhanced security
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

      // Encrypt sensitive payment details
      final encryptedPaymentDetails = await _encryption.encryptPaymentDetails(
        userId: userId,
        paymentDetails: paymentDetails,
      );

      // Check fraud indicators
      final fraudAnalysis = await _fraudDetection.analyzeUserBehavior(
        userId: userId,
        action: 'withdrawal_request',
        additionalData: {
          'amount': amount,
          'method': method.toString(),
          'paymentDetailsHash': _encryption.hashSensitiveData(paymentDetails.toString()),
        },
      );

      // Determine if manual review is needed
      bool requiresManualReview = _requiresManualReview(fraudAnalysis, amount);

      // Create withdrawal request with pending status (manual settlement workflow)
      final request = WithdrawalRequest(
        id: '', // Will be set by Firestore
        userId: userId,
        amount: amount,
        method: method,
        paymentDetails: encryptedPaymentDetails,
        status: requiresManualReview
            ? WithdrawalStatus.pendingSettlement
            : WithdrawalStatus.pendingReview, // New status for manual settlement
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

      // Reserve user funds
      await _reserveUserFunds(userId, amount);

      // Log withdrawal attempt with encrypted data
      await _logWithdrawalAttempt(requestWithId, fraudAnalysis);

      // Send confirmation notification
      await _notification.notifyWithdrawal(
        userId: userId,
        status: 'submitted',
        amount: amount,
      );

      // Create audit log for compliance
      await _createAuditLog(
        userId: userId,
        action: 'withdrawal_request_submitted',
        entityId: requestWithId.id,
        details: {
          'amount': amount,
          'method': method.toString(),
          'fraudScore': fraudAnalysis.riskScore,
          'requiresManualReview': requiresManualReview,
        },
      );

      return requestWithId;
    } catch (e) {
      throw Exception('Failed to submit withdrawal request: $e');
    }
  }

  /// Get pending withdrawal requests for end-of-month settlement (Admin Dashboard)
  Future<List<WithdrawalRequest>> getPendingWithdrawalsForSettlement({
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    List<WithdrawalMethod>? methods,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('withdrawal_requests')
          .where('status', whereIn: [
        WithdrawalStatus.pendingSettlement.toString(),
        WithdrawalStatus.approved.toString(),
      ]);

      if (fromDate != null) {
        query = query.where('requestedAt', isGreaterThanOrEqualTo: fromDate);
      }

      if (toDate != null) {
        query = query.where('requestedAt', isLessThanOrEqualTo: toDate);
      }

      query = query.orderBy('requestedAt', descending: false).limit(limit);

      final snapshot = await query.get();

      List<WithdrawalRequest> requests = [];
      for (final doc in snapshot.docs) {
        final request = WithdrawalRequest.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        // Apply additional filters
        if (minAmount != null && request.amount < minAmount) continue;
        if (maxAmount != null && request.amount > maxAmount) continue;
        if (methods != null && !methods.contains(request.method)) continue;

        requests.add(request);
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to get pending withdrawals: $e');
    }
  }

  /// Get withdrawal requests by settlement batch for admin dashboard
  Future<Map<String, dynamic>> getWithdrawalsBatch({
    required DateTime monthYear,
    WithdrawalStatus? status,
  }) async {
    try {
      final startOfMonth = DateTime(monthYear.year, monthYear.month, 1);
      final endOfMonth = DateTime(monthYear.year, monthYear.month + 1, 1)
          .subtract(Duration(milliseconds: 1));

      Query query = _firestore
          .collection('withdrawal_requests')
          .where('requestedAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('requestedAt', isLessThanOrEqualTo: endOfMonth);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }

      final snapshot = await query.get();

      List<WithdrawalRequest> requests = [];
      double totalAmount = 0.0;
      Map<WithdrawalMethod, int> methodCounts = {};
      Map<String, int> statusCounts = {};

      for (final doc in snapshot.docs) {
        final request = WithdrawalRequest.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        requests.add(request);
        totalAmount += request.amount;

        // Count by method
        methodCounts[request.method] = (methodCounts[request.method] ?? 0) + 1;

        // Count by status
        final statusKey = request.status.toString();
        statusCounts[statusKey] = (statusCounts[statusKey] ?? 0) + 1;
      }

      return {
        'requests': requests,
        'totalAmount': totalAmount,
        'totalCount': requests.length,
        'methodBreakdown': methodCounts,
        'statusBreakdown': statusCounts,
        'monthYear': '${monthYear.year}-${monthYear.month.toString().padLeft(2, '0')}',
      };
    } catch (e) {
      throw Exception('Failed to get withdrawal batch: $e');
    }
  }

  /// Mark withdrawal as settled by admin (Manual Settlement)
  Future<void> markWithdrawalAsSettled({
    required String requestId,
    required String adminId,
    required String transactionReference,
    String? settlementNotes,
    DateTime? settlementDate,
  }) async {
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

      // Validate current status
      if (!request.canBeSettled) {
        throw Exception('Withdrawal request cannot be settled in current status: ${request.status}');
      }

      final settlementTimestamp = settlementDate ?? DateTime.now();

      // Update withdrawal status to completed
      await _firestore.collection('withdrawal_requests').doc(requestId).update({
        'status': WithdrawalStatus.completed.toString(),
        'settledBy': adminId,
        'settledAt': FieldValue.serverTimestamp(),
        'transactionId': transactionReference,
        'settlementNotes': settlementNotes,
        'completedAt': settlementTimestamp,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user statistics
      await _updateUserStats(request.userId, request.amount, true);

      // Send completion notification
      await _notification.notifyWithdrawal(
        userId: request.userId,
        status: 'completed',
        amount: request.amount,
      );

      // Create audit log
      await _createAuditLog(
        userId: adminId,
        action: 'withdrawal_settled_manually',
        entityId: requestId,
        details: {
          'originalUserId': request.userId,
          'amount': request.amount,
          'transactionReference': transactionReference,
          'settlementNotes': settlementNotes,
        },
      );

      print('Withdrawal $requestId marked as settled by admin $adminId');
    } catch (e) {
      throw Exception('Failed to mark withdrawal as settled: $e');
    }
  }

  /// Bulk settlement for multiple withdrawals (End of Month Process)
  Future<Map<String, dynamic>> processBulkSettlement({
    required List<String> requestIds,
    required String adminId,
    required Map<String, String> transactionReferences, // requestId -> transactionRef
    String? batchNotes,
  }) async {
    try {
      final batch = _firestore.batch();
      final results = <String, dynamic>{
        'successful': <String>[],
        'failed': <Map<String, String>>[],
        'totalAmount': 0.0,
        'processedCount': 0,
      };

      for (final requestId in requestIds) {
        try {
          final requestDoc = await _firestore
              .collection('withdrawal_requests')
              .doc(requestId)
              .get();

          if (!requestDoc.exists) {
            results['failed'].add({
              'requestId': requestId,
              'error': 'Request not found',
            });
            continue;
          }

          final requestData = requestDoc.data()!;
          final request = WithdrawalRequest.fromJson({
            'id': requestDoc.id,
            ...requestData,
          });

          if (!request.canBeSettled) {
            results['failed'].add({
              'requestId': requestId,
              'error': 'Cannot be settled in current status: ${request.status}',
            });
            continue;
          }

          final transactionRef = transactionReferences[requestId] ??
              'BATCH_${DateTime.now().millisecondsSinceEpoch}_$requestId';

          // Update withdrawal in batch
          batch.update(
            _firestore.collection('withdrawal_requests').doc(requestId),
            {
              'status': WithdrawalStatus.completed.toString(),
              'settledBy': adminId,
              'settledAt': FieldValue.serverTimestamp(),
              'transactionId': transactionRef,
              'settlementNotes': batchNotes,
              'completedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'batchSettlement': true,
            },
          );

          results['successful'].add(requestId);
          results['totalAmount'] = (results['totalAmount'] as double) + request.amount;
          results['processedCount'] = (results['processedCount'] as int) + 1;

        } catch (e) {
          results['failed'].add({
            'requestId': requestId,
            'error': e.toString(),
          });
        }
      }

      // Commit all updates
      await batch.commit();

      // Send notifications for successful settlements
      for (final requestId in results['successful']) {
        try {
          final requestDoc = await _firestore
              .collection('withdrawal_requests')
              .doc(requestId)
              .get();

          if (requestDoc.exists) {
            final request = WithdrawalRequest.fromJson({
              'id': requestDoc.id,
              ...requestDoc.data()!,
            });

            await _notification.notifyWithdrawal(
              userId: request.userId,
              status: 'completed',
              amount: request.amount,
            );

            await _updateUserStats(request.userId, request.amount, true);
          }
        } catch (e) {
          print('Failed to notify user for withdrawal $requestId: $e');
        }
      }

      // Create bulk settlement audit log
      await _createAuditLog(
        userId: adminId,
        action: 'bulk_withdrawal_settlement',
        entityId: 'batch_${DateTime.now().millisecondsSinceEpoch}',
        details: {
          'totalRequests': requestIds.length,
          'successfulSettlements': results['successful'].length,
          'failedSettlements': results['failed'].length,
          'totalAmount': results['totalAmount'],
          'batchNotes': batchNotes,
        },
      );

      return results;
    } catch (e) {
      throw Exception('Failed to process bulk settlement: $e');
    }
  }

  /// Get decrypted payment details for admin (for settlement processing)
  Future<Map<String, dynamic>> getDecryptedPaymentDetails({
    required String requestId,
    required String adminId,
  }) async {
    try {
      // Verify admin permissions
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      if (!adminDoc.exists) {
        throw Exception('Admin not found');
      }

      final adminData = adminDoc.data()!;
      final adminRole = adminData['role'] as String?;

      if (!['finance', 'admin', 'superadmin'].contains(adminRole)) {
        throw Exception('Insufficient permissions to access payment details');
      }

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

      // Decrypt payment details
      final decryptedDetails = await _encryption.decryptPaymentDetails(
        userId: request.userId,
        encryptedDetails: request.paymentDetails,
      );

      // Log access for audit
      await _createAuditLog(
        userId: adminId,
        action: 'payment_details_accessed',
        entityId: requestId,
        details: {
          'originalUserId': request.userId,
          'amount': request.amount,
          'method': request.method.toString(),
        },
      );

      return {
        'paymentDetails': decryptedDetails,
        'method': request.method.toString(),
        'amount': request.amount,
        'userId': request.userId,
        'requestedAt': request.requestedAt.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get decrypted payment details: $e');
    }
  }

  /// Check if withdrawal can be settled
  bool _canBeSettled(WithdrawalRequest request) {
    return [
      WithdrawalStatus.pendingSettlement,
      WithdrawalStatus.approved,
    ].contains(request.status);
  }

  /// Validate withdrawal request with enhanced security
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
          throw Exception(
              'Bank account verification required for withdrawals');
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
      case WithdrawalMethod.check:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Reserve user funds for withdrawal
  Future<void> _reserveUserFunds(String userId, double amount) async {
    await _firestore.collection('users').doc(userId).update({
      'pendingWithdrawals': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  /// Log withdrawal attempt with encryption
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
        'encryptionVersion': '1.0',
      });
    } catch (e) {
      print('Error logging withdrawal attempt: $e');
    }
  }

  /// Update user statistics after settlement
  Future<void> _updateUserStats(String userId, double amount, bool completed) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (completed) {
      updateData['stats.totalWithdrawals'] = FieldValue.increment(amount);
      updateData['stats.completedWithdrawals'] = FieldValue.increment(1);
      updateData['pendingWithdrawals'] = FieldValue.increment(-amount);
    }

    await _firestore.collection('users').doc(userId).update(updateData);
  }

  /// Create audit log for compliance
  Future<void> _createAuditLog({
    required String userId,
    required String action,
    required String entityId,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'action': action,
        'entity': 'withdrawal',
        'entityId': entityId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'system', // Would be actual IP in production
      });
    } catch (e) {
      print('Error creating audit log: $e');
    }
  }
}

/// Extension for withdrawal request model
extension WithdrawalSettlement on WithdrawalRequest {
  /// Check if withdrawal can be settled manually
  bool get canBeSettled {
    return [
      WithdrawalStatus.pendingSettlement,
      WithdrawalStatus.approved,
    ].contains(status);
  }

  /// Check if withdrawal is in final state
  bool get isFinalState {
    return [
      WithdrawalStatus.completed,
      WithdrawalStatus.failed,
      WithdrawalStatus.rejected,
      WithdrawalStatus.cancelled,
    ].contains(status);
  }
}

/// New withdrawal status for manual settlement workflow
enum WithdrawalStatus {
  pending,
  pendingReview,
  pendingSettlement, // New status for manual settlement
  approved,
  processing,
  completed,
  failed,
  rejected,
  cancelled,
}
