import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/earnings_model.dart';
import '../../../core/config.dart';
import '../../../core/exceptions.dart';

class EarningsRepository {
  final FirebaseFirestore _firestore;

  EarningsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Record LP event
  Future<void> recordLPEvent({
    required String userId,
    required int lp,
    required String reason,
    String? activityRef,
    required String difficulty,
    required int timeTaken,
    required String deviceFingerprint,
    required String ipAddress,
  }) async {
    try {
      final event = LPEvent(
        id: '', // Will be set by Firestore
        userId: userId,
        lp: lp,
        reason: reason,
        activityRef: activityRef,
        difficulty: difficulty,
        timeTaken: timeTaken,
        deviceFingerprint: deviceFingerprint,
        ipAddress: ipAddress,
        createdAt: DateTime.now(),
        serverValidated: false,
      );

      await _firestore
          .collection(AppConfig.lpEventsCollection)
          .doc()
          .set(event.toFirestore());
    } catch (e) {
      throw Exception('Failed to record LP event: ${e.toString()}');
    }
  }

  // Record ad event
  Future<void> recordAdEvent({
    required String userId,
    required String format,
    required String adNetwork,
    required bool impression,
    required bool clicked,
    required String adUnitId,
    required String placementId,
    required double revenue,
    required Map<String, dynamic> deviceInfo,
    required String ipAddress,
    required String userAgent,
    required String consentStatus,
    required String ageGroup,
    required int engagementTime,
  }) async {
    try {
      final event = AdEvent(
        id: '', // Will be set by Firestore
        userId: userId,
        format: format,
        adNetwork: adNetwork,
        impression: impression,
        clicked: clicked,
        adUnitId: adUnitId,
        placementId: placementId,
        revenue: revenue,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        userAgent: userAgent,
        consentStatus: consentStatus,
        ageGroup: ageGroup,
        engagementTime: engagementTime,
        qualifiesForAER: false, // Will be set by Cloud Function
        aerAmount: 0, // Will be set by Cloud Function
        at: DateTime.now(),
      );

      await _firestore
          .collection(AppConfig.adEventsCollection)
          .doc()
          .set(event.toFirestore());
    } catch (e) {
      throw Exception('Failed to record ad event: ${e.toString()}');
    }
  }

  // Get user's daily earnings estimate
  Future<Map<String, dynamic>> getDailyEarningsEstimate(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's LP events
      final lpSnapshot = await _firestore
          .collection(AppConfig.lpEventsCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final todayLP = lpSnapshot.docs
          .fold<int>(0, (sum, doc) => sum + (doc.data()['lp'] as int));

      // Get today's AER events
      final aerSnapshot = await _firestore
          .collection(AppConfig.aerEventsCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('serverValidated', isEqualTo: true)
          .get();

      final todayAER = aerSnapshot.docs.fold<double>(
          0, (sum, doc) => sum + (doc.data()['aerAmount'] as double));

      // Get global config
      final configDoc = await _firestore
          .collection(AppConfig.configCollection)
          .doc('global')
          .get();

      final config = configDoc.data() ?? {};
      final dailyPool = (config['dailyPoolUSD'] as num?)?.toDouble() ??
          AppConfig.defaultDailyPoolUSD;

      // TODO: Calculate pool share based on total LP across all users
      // This is a simplified calculation
      final estimatedPoolShare = (todayLP / 100) * dailyPool;

      return {
        'date': startOfDay,
        'lp': todayLP,
        'aerAmount': todayAER,
        'estimatedPoolShare': estimatedPoolShare,
        'totalEstimate': estimatedPoolShare + todayAER,
      };
    } catch (e) {
      throw Exception('Failed to get daily earnings estimate: ${e.toString()}');
    }
  }

  // Get withdrawal history
  Future<List<Withdrawal>> getWithdrawalHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.withdrawalsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => Withdrawal.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get withdrawal history: ${e.toString()}');
    }
  }

  // Request withdrawal
  Future<void> requestWithdrawal({
    required String userId,
    required double amount,
    required String method,
    required Map<String, String> paymentDetails,
  }) async {
    try {
      // Get global config for validation
      final configDoc = await _firestore
          .collection(AppConfig.configCollection)
          .doc('global')
          .get();

      final config = configDoc.data() ?? {};
      final minThreshold =
          (config['withdrawThresholdUSD'] as num?)?.toDouble() ??
              AppConfig.defaultWithdrawThresholdUSD;
      final platformFee = (config['platformFeePct'] as num?)?.toDouble() ??
          AppConfig.defaultPlatformFeePct;

      // Validate minimum threshold
      if (amount < minThreshold) {
        throw WithdrawalException(
            'Withdrawal amount must be at least \$$minThreshold',
            code: 'MIN_THRESHOLD_NOT_MET');
      }

      // Get user's current balance
      final userDoc = await _firestore
          .collection(AppConfig.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw WithdrawalException('User not found');
      }

      final userStats = userDoc.data()?['stats'] ?? {};
      final currentBalance =
          (userStats['remaining'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < amount) {
        throw WithdrawalException('Insufficient balance',
            code: 'INSUFFICIENT_BALANCE');
      }

      // Calculate fees
      final feeAmount = amount * platformFee;
      final netAmount = amount - feeAmount;

      // Create withdrawal request
      final withdrawal = Withdrawal(
        id: '', // Will be set by Firestore
        userId: userId,
        month:
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
        amount: amount,
        platformFee: feeAmount,
        method: method,
        status: 'requested',
        kycRequired: amount >= 100, // Example threshold
        amlChecked: false,
      );

      final batch = _firestore.batch();

      // Add withdrawal doc
      final withdrawalRef =
          _firestore.collection(AppConfig.withdrawalsCollection).doc();
      batch.set(withdrawalRef, withdrawal.toFirestore());

      // Update user's balance
      batch.update(
          _firestore.collection(AppConfig.usersCollection).doc(userId), {
        'stats.remaining': FieldValue.increment(-amount),
        'stats.totalWithdrawals': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      if (e is WithdrawalException) rethrow;
      throw WithdrawalException(
          'Failed to request withdrawal: ${e.toString()}');
    }
  }

  // Get earnings statistics
  Future<Map<String, dynamic>> getEarningsStats(String userId) async {
    try {
      // Get user stats
      final userDoc = await _firestore
          .collection(AppConfig.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final stats = userDoc.data()?['stats'] ?? {};

      // Get this month's earnings
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final monthlyLPSnapshot = await _firestore
          .collection(AppConfig.lpEventsCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      final monthlyLP = monthlyLPSnapshot.docs
          .fold<int>(0, (sum, doc) => sum + (doc.data()['lp'] as int));

      final monthlyAERSnapshot = await _firestore
          .collection(AppConfig.aerEventsCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('serverValidated', isEqualTo: true)
          .get();

      final monthlyAER = monthlyAERSnapshot.docs.fold<double>(
          0, (sum, doc) => sum + (doc.data()['aerAmount'] as double));

      return {
        'totalEarnings': stats['totalEarnings'] ?? 0.0,
        'totalWithdrawals': stats['totalWithdrawals'] ?? 0.0,
        'currentBalance': stats['remaining'] ?? 0.0,
        'thisMonthLP': monthlyLP,
        'thisMonthAER': monthlyAER,
        'totalLP': stats['totalLP'] ?? 0,
        'totalAER': stats['totalAER'] ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get earnings stats: ${e.toString()}');
    }
  }
}
