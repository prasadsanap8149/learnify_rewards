import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/earnings_pool.dart';
import '../shared/models/user_earning.dart';

class EarningsPoolService {
  static final EarningsPoolService _instance = EarningsPoolService._internal();
  factory EarningsPoolService() => _instance;
  EarningsPoolService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new earnings pool
  Future<String> createEarningsPool({
    required String name,
    required double totalAmount,
    required DateTime startDate,
    required DateTime endDate,
    required EarningsPoolType type,
    required Map<String, dynamic> distributionCriteria,
    String? description,
    double? maxPerUser,
    int? maxParticipants,
  }) async {
    try {
      final pool = EarningsPool(
        id: '', // Will be set by Firestore
        name: name,
        description: description ?? '',
        totalAmount: totalAmount,
        remainingAmount: totalAmount,
        startDate: startDate,
        endDate: endDate,
        type: type,
        status: EarningsPoolStatus.scheduled,
        distributionCriteria: distributionCriteria,
        maxPerUser: maxPerUser,
        maxParticipants: maxParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('earnings_pools').add(pool.toJson());

      // Schedule activation if start date is in the future
      if (startDate.isAfter(DateTime.now())) {
        await _schedulePoolActivation(docRef.id, startDate);
      } else {
        await activatePool(docRef.id);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create earnings pool: $e');
    }
  }

  /// Activate an earnings pool
  Future<void> activatePool(String poolId) async {
    try {
      await _firestore.collection('earnings_pools').doc(poolId).update({
        'status': EarningsPoolStatus.active.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Earnings pool $poolId activated');
    } catch (e) {
      throw Exception('Failed to activate pool: $e');
    }
  }

  /// Close an earnings pool and distribute remaining funds
  Future<void> closePool(String poolId,
      {bool distributeRemaining = true}) async {
    try {
      final poolDoc =
          await _firestore.collection('earnings_pools').doc(poolId).get();
      if (!poolDoc.exists) {
        throw Exception('Pool not found');
      }

      final pool = EarningsPool.fromJson({
        'id': poolDoc.id,
        ...poolDoc.data()!,
      });

      if (distributeRemaining && pool.remainingAmount > 0) {
        await _distributeFinalPayouts(pool);
      }

      await _firestore.collection('earnings_pools').doc(poolId).update({
        'status': EarningsPoolStatus.closed.toString(),
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Earnings pool $poolId closed');
    } catch (e) {
      throw Exception('Failed to close pool: $e');
    }
  }

  /// Distribute earnings to eligible users
  Future<List<UserEarning>> distributeEarnings({
    required String poolId,
    required List<String> eligibleUserIds,
    DistributionMethod method = DistributionMethod.equal,
    Map<String, double>? customWeights,
  }) async {
    try {
      final poolDoc =
          await _firestore.collection('earnings_pools').doc(poolId).get();
      if (!poolDoc.exists) {
        throw Exception('Pool not found');
      }

      final pool = EarningsPool.fromJson({
        'id': poolDoc.id,
        ...poolDoc.data()!,
      });

      if (pool.status != EarningsPoolStatus.active) {
        throw Exception('Pool is not active');
      }

      if (pool.remainingAmount <= 0) {
        throw Exception('No funds remaining in pool');
      }

      // Calculate distribution amounts
      final distributions = await _calculateDistribution(
        pool: pool,
        eligibleUserIds: eligibleUserIds,
        method: method,
        customWeights: customWeights,
      );

      // Create earning records
      final earnings = <UserEarning>[];
      double totalDistributed = 0;

      final batch = _firestore.batch();

      for (final distribution in distributions.entries) {
        final userId = distribution.key;
        final amount = distribution.value;

        if (amount <= 0) continue;

        final earning = UserEarning(
          id: '', // Will be set by Firestore
          userId: userId,
          poolId: poolId,
          amount: amount,
          type: pool.type == EarningsPoolType.activity
              ? EarningType.activity
              : EarningType.bonus,
          timestamp: DateTime.now(),
          status: EarningStatus.pending,
          metadata: {
            'poolName': pool.name,
            'distributionMethod': method.toString(),
            'distributionDate': DateTime.now().toIso8601String(),
          },
        );

        final earningRef = _firestore.collection('user_earnings').doc();
        batch.set(earningRef, earning.toJson());

        earnings.add(earning.copyWith(id: earningRef.id));
        totalDistributed += amount;
      }

      // Update pool remaining amount
      batch.update(_firestore.collection('earnings_pools').doc(poolId), {
        'remainingAmount': pool.remainingAmount - totalDistributed,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastDistribution': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Process earnings asynchronously
      _processEarningsAsync(earnings);

      return earnings;
    } catch (e) {
      throw Exception('Failed to distribute earnings: $e');
    }
  }

  /// Calculate distribution amounts based on method
  Future<Map<String, double>> _calculateDistribution({
    required EarningsPool pool,
    required List<String> eligibleUserIds,
    required DistributionMethod method,
    Map<String, double>? customWeights,
  }) async {
    final distributions = <String, double>{};

    switch (method) {
      case DistributionMethod.equal:
        final amountPerUser = pool.remainingAmount / eligibleUserIds.length;
        final cappedAmount = pool.maxPerUser != null
            ? min(amountPerUser, pool.maxPerUser!)
            : amountPerUser;

        for (final userId in eligibleUserIds) {
          distributions[userId] = cappedAmount;
        }
        break;

      case DistributionMethod.weighted:
        if (customWeights == null) {
          throw Exception('Custom weights required for weighted distribution');
        }

        final totalWeight = customWeights.values.fold(0.0, (a, b) => a + b);

        for (final userId in eligibleUserIds) {
          final weight = customWeights[userId] ?? 0;
          final amount = (pool.remainingAmount * weight / totalWeight);
          final cappedAmount =
              pool.maxPerUser != null ? min(amount, pool.maxPerUser!) : amount;

          distributions[userId] = cappedAmount.toDouble();
        }
        break;

      case DistributionMethod.performance:
        final userPerformance =
            await _getUserPerformanceScores(eligibleUserIds);
        final totalScore = userPerformance.values.fold(0.0, (a, b) => a + b);

        for (final userId in eligibleUserIds) {
          final score = userPerformance[userId] ?? 0;
          final amount = totalScore > 0
              ? (pool.remainingAmount * score / totalScore)
              : 0.0;
          final cappedAmount =
              pool.maxPerUser != null ? min(amount, pool.maxPerUser!) : amount;

          distributions[userId] = cappedAmount.toDouble();
        }
        break;

      case DistributionMethod.tiered:
        final sortedUsers = await _sortUsersByPerformance(eligibleUserIds);
        await _distributeTiered(pool, sortedUsers, distributions);
        break;
    }

    return distributions;
  }

  /// Get user performance scores for distribution
  Future<Map<String, double>> _getUserPerformanceScores(
      List<String> userIds) async {
    final scores = <String, double>{};

    try {
      // Get user activities from the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final userId in userIds) {
        final activities = await _firestore
            .collection('user_activities')
            .where('userId', isEqualTo: userId)
            .where('timestamp', isGreaterThan: thirtyDaysAgo)
            .get();

        double score = 0;

        for (final doc in activities.docs) {
          final data = doc.data();
          final activityType = data['type'] as String? ?? '';
          final points = (data['points'] as num?)?.toDouble() ?? 0;

          // Weight different activities differently
          switch (activityType) {
            case 'quiz_completion':
              score += points * 1.5;
              break;
            case 'lesson_completion':
              score += points * 1.2;
              break;
            case 'daily_login':
              score += points * 0.8;
              break;
            default:
              score += points;
          }
        }

        scores[userId] = score;
      }
    } catch (e) {
      print('Error calculating performance scores: $e');
      // Default to equal scores if calculation fails
      for (final userId in userIds) {
        scores[userId] = 1.0;
      }
    }

    return scores;
  }

  /// Sort users by performance for tiered distribution
  Future<List<String>> _sortUsersByPerformance(List<String> userIds) async {
    final scores = await _getUserPerformanceScores(userIds);

    userIds.sort((a, b) {
      final scoreA = scores[a] ?? 0;
      final scoreB = scores[b] ?? 0;
      return scoreB.compareTo(scoreA); // Descending order
    });

    return userIds;
  }

  /// Distribute funds using tiered approach
  Future<void> _distributeTiered(
    EarningsPool pool,
    List<String> sortedUsers,
    Map<String, double> distributions,
  ) async {
    final totalUsers = sortedUsers.length;

    // Define tiers: top 10%, next 20%, next 30%, bottom 40%
    final tier1Count = (totalUsers * 0.1).ceil();
    final tier2Count = (totalUsers * 0.2).ceil();
    final tier3Count = (totalUsers * 0.3).ceil();
    final tier4Count = totalUsers - tier1Count - tier2Count - tier3Count;

    // Allocate funds: 50% to tier 1, 30% to tier 2, 15% to tier 3, 5% to tier 4
    final tier1Amount = pool.remainingAmount * 0.5;
    final tier2Amount = pool.remainingAmount * 0.3;
    final tier3Amount = pool.remainingAmount * 0.15;
    final tier4Amount = pool.remainingAmount * 0.05;

    // Distribute within each tier
    int index = 0;

    // Tier 1
    final tier1PerUser = tier1Count > 0 ? tier1Amount / tier1Count : 0.0;
    for (int i = 0; i < tier1Count && index < totalUsers; i++, index++) {
      final cappedAmount = pool.maxPerUser != null
          ? min(tier1PerUser, pool.maxPerUser!)
          : tier1PerUser;
      distributions[sortedUsers[index]] = cappedAmount.toDouble();
    }

    // Tier 2
    final tier2PerUser = tier2Count > 0 ? tier2Amount / tier2Count : 0.0;
    for (int i = 0; i < tier2Count && index < totalUsers; i++, index++) {
      final cappedAmount = pool.maxPerUser != null
          ? min(tier2PerUser, pool.maxPerUser!)
          : tier2PerUser;
      distributions[sortedUsers[index]] = cappedAmount.toDouble();
    }

    // Tier 3
    final tier3PerUser = tier3Count > 0 ? tier3Amount / tier3Count : 0.0;
    for (int i = 0; i < tier3Count && index < totalUsers; i++, index++) {
      final cappedAmount = pool.maxPerUser != null
          ? min(tier3PerUser, pool.maxPerUser!)
          : tier3PerUser;
      distributions[sortedUsers[index]] = cappedAmount.toDouble();
    }

    // Tier 4
    final tier4PerUser = tier4Count > 0 ? tier4Amount / tier4Count : 0.0;
    for (int i = 0; i < tier4Count && index < totalUsers; i++, index++) {
      final cappedAmount = pool.maxPerUser != null
          ? min(tier4PerUser, pool.maxPerUser!)
          : tier4PerUser;
      distributions[sortedUsers[index]] = cappedAmount.toDouble();
    }
  }

  /// Process earnings asynchronously
  Future<void> _processEarningsAsync(List<UserEarning> earnings) async {
    for (final earning in earnings) {
      try {
        // Update user's total earnings
        await _updateUserTotalEarnings(earning.userId, earning.amount);

        // Mark earning as processed
        await _firestore.collection('user_earnings').doc(earning.id).update({
          'status': EarningStatus.processed.toString(),
          'processedAt': FieldValue.serverTimestamp(),
        });

        // Send notification (if notification service is available)
        await _sendEarningNotification(earning);
      } catch (e) {
        print('Error processing earning ${earning.id}: $e');

        // Mark as failed
        await _firestore.collection('user_earnings').doc(earning.id).update({
          'status': EarningStatus.failed.toString(),
          'error': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Update user's total earnings
  Future<void> _updateUserTotalEarnings(String userId, double amount) async {
    await _firestore.collection('users').doc(userId).update({
      'totalEarnings': FieldValue.increment(amount),
      'pendingEarnings': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send earning notification
  Future<void> _sendEarningNotification(UserEarning earning) async {
    try {
      // This would integrate with your notification service
      print(
          'Sending earning notification to ${earning.userId} for \$${earning.amount.toStringAsFixed(2)}');

      // Add to notification queue or send directly
      await _firestore.collection('notifications').add({
        'userId': earning.userId,
        'type': 'earning',
        'title': 'You earned money!',
        'message':
            'You earned \$${earning.amount.toStringAsFixed(2)} from ${earning.metadata?['poolName'] ?? 'rewards'}',
        'data': {
          'earningId': earning.id,
          'amount': earning.amount,
          'poolId': earning.poolId,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending earning notification: $e');
    }
  }

  /// Schedule pool activation
  Future<void> _schedulePoolActivation(
      String poolId, DateTime activationDate) async {
    // In a production app, you would use Cloud Functions or similar for scheduling
    print('Pool $poolId scheduled for activation at $activationDate');

    // For now, just log the schedule
    await _firestore.collection('scheduled_tasks').add({
      'type': 'activate_pool',
      'poolId': poolId,
      'scheduledFor': activationDate,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Distribute final payouts when pool closes
  Future<void> _distributeFinalPayouts(EarningsPool pool) async {
    try {
      // Get all users who earned from this pool
      final earnings = await _firestore
          .collection('user_earnings')
          .where('poolId', isEqualTo: pool.id)
          .where('status', isEqualTo: EarningStatus.processed.toString())
          .get();

      final userIds = earnings.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();

      if (userIds.isNotEmpty && pool.remainingAmount > 0) {
        await distributeEarnings(
          poolId: pool.id,
          eligibleUserIds: userIds,
          method: DistributionMethod.equal,
        );
      }
    } catch (e) {
      print('Error distributing final payouts: $e');
    }
  }

  /// Get active pools
  Future<List<EarningsPool>> getActivePools() async {
    try {
      final snapshot = await _firestore
          .collection('earnings_pools')
          .where('status', isEqualTo: EarningsPoolStatus.active.toString())
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EarningsPool.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active pools: $e');
    }
  }

  /// Get pool details
  Future<EarningsPool?> getPool(String poolId) async {
    try {
      final doc =
          await _firestore.collection('earnings_pools').doc(poolId).get();

      if (!doc.exists) return null;

      return EarningsPool.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get pool: $e');
    }
  }

  /// Get user's earnings from a specific pool
  Future<List<UserEarning>> getUserPoolEarnings(
      String userId, String poolId) async {
    try {
      final snapshot = await _firestore
          .collection('user_earnings')
          .where('userId', isEqualTo: userId)
          .where('poolId', isEqualTo: poolId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserEarning.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user pool earnings: $e');
    }
  }
}

/// Distribution methods for earnings pools
enum DistributionMethod {
  equal, // Equal distribution among all eligible users
  weighted, // Distribution based on custom weights
  performance, // Distribution based on performance metrics
  tiered, // Tiered distribution with top performers getting more
}
