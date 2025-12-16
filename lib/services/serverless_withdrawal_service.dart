import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum WithdrawalStatus {
  pending,
  approved,
  rejected,
  processing,
  completed,
  failed
}

enum PaymentMethod { upi, paypal, bankTransfer }

class ServerlessWithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Withdrawal constraints
  static const double _minimumWithdrawal = 50.0; // Minimum 50 rupees
  static const double _maximumWithdrawal =
      10000.0; // Maximum 10000 rupees per request
  static const int _maxPendingWithdrawals =
      3; // Max 3 pending withdrawals per user
  static const Duration _withdrawalCooldown =
      Duration(hours: 24); // 24 hours between withdrawals

  // Submit withdrawal request
  Future<Map<String, dynamic>> submitWithdrawalRequest({
    required double amount,
    required PaymentMethod paymentMethod,
    required Map<String, String> paymentDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Validate amount
      if (amount < _minimumWithdrawal) {
        return {
          'success': false,
          'error': 'Minimum withdrawal amount is ₹$_minimumWithdrawal'
        };
      }

      if (amount > _maximumWithdrawal) {
        return {
          'success': false,
          'error': 'Maximum withdrawal amount is ₹$_maximumWithdrawal'
        };
      }

      // Check user eligibility
      final eligibilityCheck =
          await _checkWithdrawalEligibility(user.uid, amount);
      if (!eligibilityCheck['eligible']) {
        return {'success': false, 'error': eligibilityCheck['reason']};
      }

      // Validate payment details
      final validationResult =
          _validatePaymentDetails(paymentMethod, paymentDetails);
      if (!validationResult['valid']) {
        return {'success': false, 'error': validationResult['error']};
      }

      // Create withdrawal request
      final withdrawalData = {
        'userId': user.uid,
        'amount': amount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'paymentDetails':
            _sanitizePaymentDetails(paymentMethod, paymentDetails),
        'status': WithdrawalStatus.pending.toString().split('.').last,
        'requestTimestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'notes': '',
        'adminNotes': '',
      };

      final withdrawalRef = await _firestore
          .collection('withdrawal_requests')
          .add(withdrawalData);

      // Update user's available earnings (reserve the amount)
      await _reserveEarningsForWithdrawal(user.uid, amount, withdrawalRef.id);

      return {
        'success': true,
        'withdrawalId': withdrawalRef.id,
        'message':
            'Withdrawal request submitted successfully. It will be reviewed within 24-48 hours.',
      };
    } catch (e) {
      print('Error submitting withdrawal request: $e');
      return {'success': false, 'error': 'Failed to submit withdrawal request'};
    }
  }

  // Check if user is eligible for withdrawal
  Future<Map<String, dynamic>> _checkWithdrawalEligibility(
      String userId, double amount) async {
    try {
      // Check user balance
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'eligible': false, 'reason': 'User not found'};
      }

      final userData = userDoc.data()!;
      final totalEarnings = (userData['totalEarnings'] ?? 0.0).toDouble();
      final reservedAmount = (userData['reservedEarnings'] ?? 0.0).toDouble();
      final availableEarnings = totalEarnings - reservedAmount;

      if (availableEarnings < amount) {
        return {
          'eligible': false,
          'reason':
              'Insufficient balance. Available: ₹${availableEarnings.toStringAsFixed(2)}'
        };
      }

      // Check for pending withdrawals
      final pendingWithdrawals = await _firestore
          .collection('withdrawal_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingWithdrawals.docs.length >= _maxPendingWithdrawals) {
        return {
          'eligible': false,
          'reason':
              'You have too many pending withdrawal requests. Please wait for them to be processed.'
        };
      }

      // Check cooldown period
      final recentWithdrawals = await _firestore
          .collection('withdrawal_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('requestTimestamp', descending: true)
          .limit(1)
          .get();

      if (recentWithdrawals.docs.isNotEmpty) {
        final lastWithdrawal = recentWithdrawals.docs.first
            .data()['requestTimestamp'] as Timestamp;
        final timeSinceLastWithdrawal =
            DateTime.now().difference(lastWithdrawal.toDate());

        if (timeSinceLastWithdrawal < _withdrawalCooldown) {
          final remainingTime = _withdrawalCooldown - timeSinceLastWithdrawal;
          return {
            'eligible': false,
            'reason':
                'Please wait ${remainingTime.inHours} hours before making another withdrawal request.'
          };
        }
      }

      // Check if user is flagged for fraud
      if (userData['flagged'] == true) {
        return {
          'eligible': false,
          'reason': 'Your account is under review. Please contact support.'
        };
      }

      return {'eligible': true};
    } catch (e) {
      print('Error checking withdrawal eligibility: $e');
      return {'eligible': false, 'reason': 'Eligibility check failed'};
    }
  }

  // Validate payment details based on method
  Map<String, dynamic> _validatePaymentDetails(
      PaymentMethod method, Map<String, String> details) {
    switch (method) {
      case PaymentMethod.upi:
        final upiId = details['upiId'];
        if (upiId == null || upiId.isEmpty) {
          return {'valid': false, 'error': 'UPI ID is required'};
        }
        if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z][a-zA-Z0-9.\-_]{2,64}$')
            .hasMatch(upiId)) {
          return {'valid': false, 'error': 'Invalid UPI ID format'};
        }
        break;

      case PaymentMethod.paypal:
        final email = details['email'];
        if (email == null || email.isEmpty) {
          return {'valid': false, 'error': 'PayPal email is required'};
        }
        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email)) {
          return {'valid': false, 'error': 'Invalid email format'};
        }
        break;

      case PaymentMethod.bankTransfer:
        final accountNumber = details['accountNumber'];
        final ifscCode = details['ifscCode'];
        final accountHolderName = details['accountHolderName'];

        if (accountNumber == null || accountNumber.isEmpty) {
          return {'valid': false, 'error': 'Account number is required'};
        }
        if (ifscCode == null || ifscCode.isEmpty) {
          return {'valid': false, 'error': 'IFSC code is required'};
        }
        if (accountHolderName == null || accountHolderName.isEmpty) {
          return {'valid': false, 'error': 'Account holder name is required'};
        }
        if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscCode)) {
          return {'valid': false, 'error': 'Invalid IFSC code format'};
        }
        break;
    }

    return {'valid': true};
  }

  // Sanitize payment details (remove sensitive info for logging)
  Map<String, String> _sanitizePaymentDetails(
      PaymentMethod method, Map<String, String> details) {
    final sanitized = Map<String, String>.from(details);

    if (method == PaymentMethod.bankTransfer &&
        details['accountNumber'] != null) {
      final accountNumber = details['accountNumber']!;
      if (accountNumber.length > 4) {
        sanitized['accountNumber'] =
            '****' + accountNumber.substring(accountNumber.length - 4);
      }
    }

    return sanitized;
  }

  // Reserve earnings for withdrawal
  Future<void> _reserveEarningsForWithdrawal(
      String userId, double amount, String withdrawalId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          final currentReserved =
              (userSnapshot.data()!['reservedEarnings'] ?? 0.0).toDouble();
          transaction.update(userRef, {
            'reservedEarnings': currentReserved + amount,
            'lastWithdrawalRequest': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error reserving earnings: $e');
    }
  }

  // Get user's withdrawal history
  Future<List<Map<String, dynamic>>> getWithdrawalHistory(
      {int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('withdrawal_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('requestTimestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error fetching withdrawal history: $e');
      return [];
    }
  }

  // Cancel pending withdrawal
  Future<Map<String, dynamic>> cancelWithdrawal(String withdrawalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final withdrawalDoc = await _firestore
          .collection('withdrawal_requests')
          .doc(withdrawalId)
          .get();

      if (!withdrawalDoc.exists) {
        return {'success': false, 'error': 'Withdrawal request not found'};
      }

      final withdrawalData = withdrawalDoc.data()!;

      if (withdrawalData['userId'] != user.uid) {
        return {'success': false, 'error': 'Unauthorized'};
      }

      if (withdrawalData['status'] != 'pending') {
        return {
          'success': false,
          'error': 'Cannot cancel withdrawal in current status'
        };
      }

      // Update withdrawal status
      await _firestore
          .collection('withdrawal_requests')
          .doc(withdrawalId)
          .update({
        'status': 'cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
        'notes': 'Cancelled by user',
      });

      // Release reserved earnings
      final amount = (withdrawalData['amount'] as num).toDouble();
      await _releaseReservedEarnings(user.uid, amount);

      return {'success': true, 'message': 'Withdrawal cancelled successfully'};
    } catch (e) {
      print('Error cancelling withdrawal: $e');
      return {'success': false, 'error': 'Failed to cancel withdrawal'};
    }
  }

  // Release reserved earnings
  Future<void> _releaseReservedEarnings(String userId, double amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          final currentReserved =
              (userSnapshot.data()!['reservedEarnings'] ?? 0.0).toDouble();
          final newReserved =
              (currentReserved - amount).clamp(0.0, double.infinity);
          transaction.update(userRef, {
            'reservedEarnings': newReserved,
          });
        }
      });
    } catch (e) {
      print('Error releasing reserved earnings: $e');
    }
  }

  // Get user's available balance for withdrawal
  Future<Map<String, dynamic>> getAvailableBalance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;
      final totalEarnings = (userData['totalEarnings'] ?? 0.0).toDouble();
      final reservedAmount = (userData['reservedEarnings'] ?? 0.0).toDouble();
      final availableBalance = totalEarnings - reservedAmount;

      return {
        'totalEarnings': totalEarnings,
        'reservedEarnings': reservedAmount,
        'availableBalance': availableBalance,
        'canWithdraw': availableBalance >= _minimumWithdrawal,
        'minimumWithdrawal': _minimumWithdrawal,
        'maximumWithdrawal': _maximumWithdrawal,
      };
    } catch (e) {
      print('Error getting available balance: $e');
      return {};
    }
  }

  // Get withdrawal constraints and info
  Map<String, dynamic> getWithdrawalInfo() {
    return {
      'minimumAmount': _minimumWithdrawal,
      'maximumAmount': _maximumWithdrawal,
      'maxPendingRequests': _maxPendingWithdrawals,
      'cooldownHours': _withdrawalCooldown.inHours,
      'supportedMethods': [
        {'key': 'upi', 'name': 'UPI Payment', 'processingTime': '1-2 hours'},
        {'key': 'paypal', 'name': 'PayPal', 'processingTime': '2-4 hours'},
        {
          'key': 'bankTransfer',
          'name': 'Bank Transfer',
          'processingTime': '1-3 business days'
        },
      ],
    };
  }
}
