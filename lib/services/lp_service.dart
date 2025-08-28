import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mobile-first service that handles LP (Learning Points) operations
/// This eliminates the need for Cloud Functions by handling logic client-side
class LPService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Award LP to the current user for completing activities
  static Future<bool> awardLP({
    required double amount,
    required String source,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userId = user.uid;
      final timestamp = DateTime.now();

      // Start a batch write for atomic operation
      final batch = _firestore.batch();

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentBalance = (userData['lpBalance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;

      // Create LP event record
      final lpEventId = 'lp_${timestamp.millisecondsSinceEpoch}_$userId';
      final lpEvent = {
        'id': lpEventId,
        'userId': userId,
        'type': 'earn',
        'amount': amount,
        'source': source,
        'sourceId': sourceId,
        'description': description,
        'previousBalance': currentBalance,
        'newBalance': newBalance,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      batch.set(_firestore.collection('lp_events').doc(lpEventId), lpEvent);

      // Update user LP balance
      batch.update(_firestore.collection('users').doc(userId), {
        'lpBalance': newBalance,
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      // Commit the batch
      await batch.commit();

      return true;
    } catch (e) {
      print('Error awarding LP: $e');
      return false;
    }
  }

  /// Spend LP for rewards redemption
  static Future<bool> spendLP({
    required double amount,
    required String source,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userId = user.uid;
      final timestamp = DateTime.now();

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentBalance = (userData['lpBalance'] as num?)?.toDouble() ?? 0.0;

      // Check if user has sufficient balance
      if (currentBalance < amount) {
        return false; // Insufficient balance
      }

      final newBalance = currentBalance - amount;

      // Start a batch write for atomic operation
      final batch = _firestore.batch();

      // Create LP event record
      final lpEventId = 'lp_${timestamp.millisecondsSinceEpoch}_$userId';
      final lpEvent = {
        'id': lpEventId,
        'userId': userId,
        'type': 'spend',
        'amount': amount,
        'source': source,
        'sourceId': sourceId,
        'description': description,
        'previousBalance': currentBalance,
        'newBalance': newBalance,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      batch.set(_firestore.collection('lp_events').doc(lpEventId), lpEvent);

      // Update user LP balance
      batch.update(_firestore.collection('users').doc(userId), {
        'lpBalance': newBalance,
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      // Commit the batch
      await batch.commit();

      return true;
    } catch (e) {
      print('Error spending LP: $e');
      return false;
    }
  }

  /// Get user's LP balance
  static Future<double> getUserLPBalance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return 0.0;

      final userData = userDoc.data()!;
      return (userData['lpBalance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error getting LP balance: $e');
      return 0.0;
    }
  }

  /// Get user's LP transaction history
  static Stream<List<Map<String, dynamic>>> getLPHistory({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('lp_events')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Calculate and award LP for activity completion (mobile logic)
  static Future<bool> processActivityCompletion({
    required String activityId,
    required String userActivityId,
    required Map<String, dynamic> activityData,
    required Map<String, dynamic> completionData,
  }) async {
    try {
      // Calculate LP based on activity difficulty and performance
      double lpAmount = _calculateActivityLP(activityData, completionData);

      if (lpAmount <= 0) return false;

      // Check for streak bonuses
      final streakBonus = await _calculateStreakBonus();
      lpAmount += streakBonus;

      // Award the LP
      return await awardLP(
        amount: lpAmount,
        source: 'activity_completion',
        sourceId: activityId,
        description: 'Completed: ${activityData['title'] ?? 'Activity'}',
        metadata: {
          'activityId': activityId,
          'userActivityId': userActivityId,
          'difficulty': activityData['difficulty'],
          'score': completionData['score'],
          'streakBonus': streakBonus,
        },
      );
    } catch (e) {
      print('Error processing activity completion: $e');
      return false;
    }
  }

  /// Calculate LP reward based on activity difficulty and performance
  static double _calculateActivityLP(
      Map<String, dynamic> activityData, Map<String, dynamic> completionData) {
    final difficulty = activityData['difficulty'] as String? ?? 'beginner';
    final score = (completionData['score'] as num?)?.toDouble() ?? 0.0;

    // Base LP amounts by difficulty
    double baseLP = switch (difficulty) {
      'beginner' => 10.0,
      'intermediate' => 20.0,
      'advanced' => 35.0,
      'expert' => 50.0,
      _ => 10.0,
    };

    // Performance multiplier (score 0-100)
    double performanceMultiplier = (score / 100.0).clamp(0.5, 2.0);

    return (baseLP * performanceMultiplier).roundToDouble();
  }

  /// Calculate streak bonus for consecutive daily activity
  static Future<double> _calculateStreakBonus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final today = DateTime(now.year, now.month, now.day);

      // Check if user completed activities yesterday
      final yesterdayActivities = await _firestore
          .collection('lp_events')
          .where('userId', isEqualTo: user.uid)
          .where('source', isEqualTo: 'activity_completion')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
          .where('timestamp', isLessThan: Timestamp.fromDate(today))
          .get();

      if (yesterdayActivities.docs.isEmpty) {
        return 0.0; // No streak bonus if no activity yesterday
      }

      // Simple streak bonus: 5 LP for maintaining daily activity
      return 5.0;
    } catch (e) {
      print('Error calculating streak bonus: $e');
      return 0.0;
    }
  }

  /// Award welcome bonus for new users (called from registration)
  static Future<bool> awardWelcomeBonus() async {
    return await awardLP(
      amount: 100.0,
      source: 'welcome_bonus',
      description: 'Welcome to Learnify Rewards!',
      metadata: {'isWelcomeBonus': true},
    );
  }

  /// Process ad engagement rewards (mobile-first approach)
  static Future<bool> processAdEngagement({
    required String adEventId,
    required int engagementTime,
    required String adFormat,
    required bool completed,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!completed) return false;

      // Calculate LP based on ad format and engagement time
      double lpAmount = switch (adFormat) {
        'video' => engagementTime >= 30 ? 5.0 : 2.0,
        'banner' => 1.0,
        'interstitial' => 3.0,
        _ => 1.0,
      };

      // Award the LP
      return await awardLP(
        amount: lpAmount,
        source: 'ad_engagement',
        sourceId: adEventId,
        description: 'Ad engagement reward - $adFormat',
        metadata: {
          'adEventId': adEventId,
          'engagementTime': engagementTime,
          'adFormat': adFormat,
          'completed': completed,
          ...?metadata,
        },
      );
    } catch (e) {
      print('Error processing ad engagement: $e');
      return false;
    }
  }
}
