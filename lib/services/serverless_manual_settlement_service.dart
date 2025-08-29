import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/serverless_environment_config.dart';
import '../services/encryption_service.dart';
import '../shared/data/enums.dart';

/// Serverless Manual Settlement Service
///
/// This service handles withdrawal settlements entirely client-side without
/// requiring any Cloud Functions or server infrastructure. Zero server costs!
///
/// Workflow:
/// 1. Users submit withdrawal requests (stored in Firestore)
/// 2. Admin app reads pending requests from Firestore
/// 3. Admin processes payments manually outside the app
/// 4. Admin marks requests as settled in the app
/// 5. Users see updated status in real-time
class ServerlessManualSettlementService {
  static ServerlessManualSettlementService? _instance;
  static ServerlessManualSettlementService get instance {
    _instance ??= ServerlessManualSettlementService._internal();
    return _instance!;
  }

  ServerlessManualSettlementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryption = EncryptionService();
  final ServerlessEnvironmentConfig _config =
      ServerlessEnvironmentConfig.instance;

  // =============================================================================
  // USER WITHDRAWAL REQUEST (No server costs)
  // =============================================================================

  /// Submit withdrawal request - stored directly in Firestore
  Future<String> submitWithdrawalRequest({
    required String userId,
    required double amount,
    required WithdrawalMethod method,
    required Map<String, String> paymentDetails,
    String? notes,
  }) async {
    // Validate request
    if (!_config.withdrawalEnabled) {
      throw Exception('Withdrawals are currently disabled');
    }

    final amountCents = (amount * 100).round();
    if (amountCents < _config.settlementMinAmount) {
      throw Exception(
          'Minimum withdrawal amount is \$${_config.settlementMinAmount / 100}');
    }

    if (amountCents > _config.settlementMaxAmount) {
      throw Exception(
          'Maximum withdrawal amount is \$${_config.settlementMaxAmount / 100}');
    }

    // Check daily limits (client-side validation)
    await _validateDailyLimits(userId);

    // Encrypt payment details
    final encryptedPaymentDetails =
        await _encryption.encryptPaymentDetails(paymentDetails);

    final requestId = _firestore.collection('withdrawal_requests').doc().id;
    final now = DateTime.now();

    final requestData = {
      'id': requestId,
      'userId': userId,
      'amount': amountCents, // Store in cents
      'method': method.toString(),
      'paymentDetails': encryptedPaymentDetails,
      'status': WithdrawalStatus.pending.toString(),
      'createdAt': now,
      'updatedAt': now,
      'notes': notes ?? '',
      'processedBy': null,
      'processedAt': null,
      'settlementReference': null,
      'settlementNotes': null,
      'monthYear':
          '${now.year}-${now.month.toString().padLeft(2, '0')}', // For admin filtering
      'environment': _config.environment,
    };

    // Store request in Firestore (no Cloud Functions needed)
    await _firestore
        .collection('withdrawal_requests')
        .doc(requestId)
        .set(requestData);

    // Update user's pending withdrawal amount
    await _updateUserPendingWithdrawals(userId, amountCents);

    // Log the request for audit purposes
    await _logWithdrawalAction(
      requestId: requestId,
      userId: userId,
      action: 'request_submitted',
      details: {
        'amount': amountCents,
        'method': method.toString(),
      },
    );

    return requestId;
  }

  /// Get user's withdrawal requests
  Stream<List<Map<String, dynamic>>> getUserWithdrawalRequests(String userId) {
    return _firestore
        .collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  // =============================================================================
  // ADMIN SETTLEMENT OPERATIONS (No server costs)
  // =============================================================================

  /// Get pending withdrawal requests for admin review (month filter for efficiency)
  Stream<List<Map<String, dynamic>>> getPendingWithdrawalsForMonth({
    required int year,
    required int month,
  }) async* {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    yield* _firestore
        .collection('withdrawal_requests')
        .where('monthYear', isEqualTo: monthKey)
        .where('status', isEqualTo: WithdrawalStatus.pending.toString())
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
                // Don't decrypt payment details in list view for performance
                'paymentDetailsSanitized': sanitizePaymentDetails(
                    data['paymentDetails'] as Map<String, dynamic>),
              };
            }).toList());
  }

  /// Get full payment details for admin (when processing individual withdrawal)
  Future<Map<String, dynamic>> getWithdrawalWithDecryptedDetails(
      String requestId) async {
    final doc =
        await _firestore.collection('withdrawal_requests').doc(requestId).get();

    if (!doc.exists) {
      throw Exception('Withdrawal request not found');
    }

    final data = doc.data()!;

    // Decrypt payment details for admin processing
    final encryptedDetails = data['paymentDetails'] as Map<String, dynamic>;
    final decryptedDetails =
        await _encryption.decryptPaymentDetails(encryptedDetails);

    return {
      ...data,
      'id': doc.id,
      'paymentDetails': decryptedDetails,
    };
  }

  /// Mark withdrawal as settled (admin action)
  Future<void> markWithdrawalAsSettled({
    required String requestId,
    required String adminId,
    required String settlementReference,
    String? settlementNotes,
  }) async {
    final now = DateTime.now();

    // Update the withdrawal request
    await _firestore.collection('withdrawal_requests').doc(requestId).update({
      'status': WithdrawalStatus.completed.toString(),
      'processedBy': adminId,
      'processedAt': now,
      'updatedAt': now,
      'settlementReference': settlementReference,
      'settlementNotes': settlementNotes ?? '',
    });

    // Get the request details for updating user balance
    final doc =
        await _firestore.collection('withdrawal_requests').doc(requestId).get();

    if (doc.exists) {
      final data = doc.data()!;
      final userId = data['userId'] as String;
      final amount = data['amount'] as int;

      // Update user's completed withdrawals
      await _updateUserCompletedWithdrawals(userId, amount);

      // Log the settlement action
      await _logWithdrawalAction(
        requestId: requestId,
        userId: userId,
        action: 'settlement_completed',
        adminId: adminId,
        details: {
          'amount': amount,
          'settlementReference': settlementReference,
          'settlementNotes': settlementNotes ?? '',
        },
      );
    }
  }

  /// Reject withdrawal request (admin action)
  Future<void> rejectWithdrawalRequest({
    required String requestId,
    required String adminId,
    required String rejectionReason,
  }) async {
    final now = DateTime.now();

    // Update the withdrawal request
    await _firestore.collection('withdrawal_requests').doc(requestId).update({
      'status': WithdrawalStatus.rejected.toString(),
      'processedBy': adminId,
      'processedAt': now,
      'updatedAt': now,
      'settlementNotes': 'Rejected: $rejectionReason',
    });

    // Get the request details for refunding user balance
    final doc =
        await _firestore.collection('withdrawal_requests').doc(requestId).get();

    if (doc.exists) {
      final data = doc.data()!;
      final userId = data['userId'] as String;
      final amount = data['amount'] as int;

      // Refund the amount to user's available balance
      await _refundUserBalance(userId, amount);

      // Log the rejection action
      await _logWithdrawalAction(
        requestId: requestId,
        userId: userId,
        action: 'withdrawal_rejected',
        adminId: adminId,
        details: {
          'amount': amount,
          'rejectionReason': rejectionReason,
        },
      );
    }
  }

  // =============================================================================
  // BULK OPERATIONS (No server costs)
  // =============================================================================

  /// Process multiple withdrawals at once (admin bulk operation)
  Future<void> bulkProcessWithdrawals({
    required List<String> requestIds,
    required String adminId,
    required String settlementReference,
    String? settlementNotes,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final requestId in requestIds) {
      final docRef =
          _firestore.collection('withdrawal_requests').doc(requestId);

      batch.update(docRef, {
        'status': WithdrawalStatus.completed.toString(),
        'processedBy': adminId,
        'processedAt': now,
        'updatedAt': now,
        'settlementReference': settlementReference,
        'settlementNotes': settlementNotes ?? 'Bulk settlement',
      });
    }

    // Execute batch operation
    await batch.commit();

    // Update user balances (done separately to avoid batch size limits)
    for (final requestId in requestIds) {
      final doc = await _firestore
          .collection('withdrawal_requests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final userId = data['userId'] as String;
        final amount = data['amount'] as int;

        await _updateUserCompletedWithdrawals(userId, amount);

        await _logWithdrawalAction(
          requestId: requestId,
          userId: userId,
          action: 'bulk_settlement_completed',
          adminId: adminId,
          details: {
            'amount': amount,
            'settlementReference': settlementReference,
            'bulkOperation': true,
          },
        );
      }
    }
  }

  // =============================================================================
  // HELPER METHODS (All client-side)
  // =============================================================================

  Future<void> _validateDailyLimits(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayRequests = await _firestore
        .collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThan: endOfDay)
        .get();

    if (todayRequests.docs.length >= _config.maxWithdrawalRequestsPerDay) {
      throw Exception('Daily withdrawal request limit exceeded');
    }
  }

  Future<void> _updateUserPendingWithdrawals(String userId, int amount) async {
    await _firestore.collection('users').doc(userId).update({
      'pendingWithdrawals': FieldValue.increment(amount),
      'totalWithdrawalRequests': FieldValue.increment(1),
      'lastWithdrawalRequest': DateTime.now(),
    });
  }

  Future<void> _updateUserCompletedWithdrawals(
      String userId, int amount) async {
    await _firestore.collection('users').doc(userId).update({
      'pendingWithdrawals': FieldValue.increment(-amount),
      'completedWithdrawals': FieldValue.increment(amount),
      'totalWithdrawalRequests': FieldValue.increment(0), // Keep same count
      'lastWithdrawalCompleted': DateTime.now(),
    });
  }

  Future<void> _refundUserBalance(String userId, int amount) async {
    await _firestore.collection('users').doc(userId).update({
      'pendingWithdrawals': FieldValue.increment(-amount),
      'availableBalance': FieldValue.increment(amount), // Refund to available
    });
  }

  Future<void> _logWithdrawalAction({
    required String requestId,
    required String userId,
    required String action,
    String? adminId,
    Map<String, dynamic>? details,
  }) async {
    await _firestore.collection('withdrawal_audit_log').add({
      'requestId': requestId,
      'userId': userId,
      'action': action,
      'adminId': adminId,
      'details': details ?? {},
      'timestamp': DateTime.now(),
      'environment': _config.environment,
    });
  }

  /// Sanitize payment details for admin list view (without decryption)
  Map<String, String> sanitizePaymentDetails(
      Map<String, dynamic> encryptedDetails) {
    final sanitized = <String, String>{};

    for (final entry in encryptedDetails.entries) {
      final key = entry.key;
      final value = entry.value.toString();

      if (key.toLowerCase().contains('email') && value.length > 3) {
        final parts = value.split('@');
        if (parts.length == 2) {
          sanitized[key] = '${parts[0].substring(0, 1)}***@${parts[1]}';
        } else {
          sanitized[key] = '${value.substring(0, 1)}***';
        }
      } else if (key.toLowerCase().contains('phone') && value.length > 6) {
        sanitized[key] =
            '${value.substring(0, 3)}***${value.substring(value.length - 4)}';
      } else if (key.toLowerCase().contains('account') && value.length > 4) {
        sanitized[key] = '****${value.substring(value.length - 4)}';
      } else {
        sanitized[key] = '****';
      }
    }

    return sanitized;
  }

  /// Validate withdrawal amount
  bool validateWithdrawalAmount(double amount) {
    final amountCents = (amount * 100).round();
    return amountCents >= _config.settlementMinAmount &&
        amountCents <= _config.settlementMaxAmount;
  }

  /// Check if payment method is valid
  bool isValidPaymentMethod(WithdrawalMethod method) {
    return [
      WithdrawalMethod.paypal,
      WithdrawalMethod.bankTransfer,
      WithdrawalMethod.giftCard,
      WithdrawalMethod.check,
    ].contains(method);
  }

  /// Validate admin permissions (placeholder)
  bool get validateAdminPermissions => true;

  /// Validate user access (placeholder)
  bool get validateUserAccess => true;

  // =============================================================================
  // ADMIN DASHBOARD DATA (No server costs)
  // =============================================================================

  /// Get settlement statistics for admin dashboard
  Future<Map<String, dynamic>> getSettlementStatistics({
    required int year,
    required int month,
  }) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    final allRequests = await _firestore
        .collection('withdrawal_requests')
        .where('monthYear', isEqualTo: monthKey)
        .get();

    int pendingCount = 0;
    int completedCount = 0;
    int rejectedCount = 0;
    int totalPendingAmount = 0;
    int totalCompletedAmount = 0;

    for (final doc in allRequests.docs) {
      final data = doc.data();
      final status = data['status'] as String;
      final amount = data['amount'] as int;

      switch (status) {
        case 'WithdrawalStatus.pending':
          pendingCount++;
          totalPendingAmount += amount;
          break;
        case 'WithdrawalStatus.completed':
          completedCount++;
          totalCompletedAmount += amount;
          break;
        case 'WithdrawalStatus.rejected':
          rejectedCount++;
          break;
      }
    }

    return {
      'month': monthKey,
      'pending': {
        'count': pendingCount,
        'amount': totalPendingAmount,
      },
      'completed': {
        'count': completedCount,
        'amount': totalCompletedAmount,
      },
      'rejected': {
        'count': rejectedCount,
      },
      'total': {
        'count': allRequests.docs.length,
        'amount': totalPendingAmount + totalCompletedAmount,
      },
    };
  }

  /// Check if current user has admin permissions
  Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult();
      final customClaims = idTokenResult.claims;
      return customClaims?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}
