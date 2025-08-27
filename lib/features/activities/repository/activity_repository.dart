import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../../../core/config.dart';
import '../../../core/exceptions.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore;

  ActivityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get activities by type and age group
  Future<List<Activity>> getActivities({
    required String type,
    required String ageGroup,
    String? difficulty,
    int limit = 10,
  }) async {
    try {
      var query = _firestore
          .collection(AppConfig.activitiesCollection)
          .where('type', isEqualTo: type)
          .where('ageGroup', isEqualTo: ageGroup)
          .where('active', isEqualTo: true)
          .where('validTo', isGreaterThan: DateTime.now());

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
    } catch (e) {
      throw ActivityException('Failed to fetch activities: ${e.toString()}');
    }
  }

  // Get user activity state
  Future<UserActivityState> getUserActivityState(String userId) async {
    try {
      final doc =
          await _firestore.collection('userActivityState').doc(userId).get();

      if (!doc.exists) {
        // Create initial state if it doesn't exist
        final initialState = UserActivityState(
          userId: userId,
          locks: {},
          streaks: ActivityStreak(
            current: 0,
            longest: 0,
          ),
          performance: ActivityPerformance(
            accuracy: 0,
            averageTime: 0,
            improvementRate: 0,
          ),
        );

        await _firestore
            .collection('userActivityState')
            .doc(userId)
            .set(initialState.toFirestore());

        return initialState;
      }

      return UserActivityState.fromFirestore(doc);
    } catch (e) {
      throw ActivityException(
          'Failed to get user activity state: ${e.toString()}');
    }
  }

  // Lock activity for cooldown period
  Future<void> lockActivity({
    required String userId,
    required String activityType,
    required Duration cooldown,
  }) async {
    try {
      final unlockTime = DateTime.now().add(cooldown);

      await _firestore.collection('userActivityState').doc(userId).update({
        'locks.$activityType': {
          'until': Timestamp.fromDate(unlockTime),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ActivityException('Failed to lock activity: ${e.toString()}');
    }
  }

  // Record activity answer
  Future<void> recordAnswer({
    required String userId,
    required String activityId,
    required bool correct,
    required int timeTaken,
  }) async {
    try {
      final batch = _firestore.batch();
      final stateRef = _firestore.collection('userActivityState').doc(userId);

      // Update user activity state
      batch.update(stateRef, {
        'lastAnswered': {
          'activityId': activityId,
          'correct': correct,
          'at': FieldValue.serverTimestamp(),
          'timeTaken': timeTaken,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update streak if correct
      if (correct) {
        final state = await getUserActivityState(userId);
        final lastStreak = state.streaks;

        final now = DateTime.now();
        final isConsecutiveDay = lastStreak.lastStreakDate?.day == now.day - 1;

        final newCurrent = isConsecutiveDay ? lastStreak.current + 1 : 1;
        final newLongest =
            newCurrent > lastStreak.longest ? newCurrent : lastStreak.longest;

        batch.update(stateRef, {
          'streaks.current': newCurrent,
          'streaks.longest': newLongest,
          'streaks.lastStreakDate': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw ActivityException('Failed to record answer: ${e.toString()}');
    }
  }

  // Update user performance metrics
  Future<void> updatePerformance({
    required String userId,
    required double accuracy,
    required double averageTime,
    required double improvementRate,
  }) async {
    try {
      await _firestore.collection('userActivityState').doc(userId).update({
        'performance': {
          'accuracy': accuracy,
          'averageTime': averageTime,
          'improvementRate': improvementRate,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ActivityException('Failed to update performance: ${e.toString()}');
    }
  }

  // Get activity statistics
  Future<Map<String, dynamic>> getActivityStats(String userId) async {
    try {
      final state = await getUserActivityState(userId);

      final correctAnswers = await _firestore
          .collection('lpEvents')
          .where('userId', isEqualTo: userId)
          .where('reason', isEqualTo: 'correct_answer')
          .count()
          .get();

      final totalAnswers = await _firestore
          .collection('lpEvents')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return {
        'totalActivities': totalAnswers.count,
        'correctAnswers': correctAnswers.count,
        'accuracyRate': totalAnswers.count > 0
            ? correctAnswers.count / totalAnswers.count
            : 0.0,
        'currentStreak': state.streaks.current,
        'longestStreak': state.streaks.longest,
        'averageTime': state.performance.averageTime,
        'improvementRate': state.performance.improvementRate,
      };
    } catch (e) {
      throw ActivityException('Failed to get activity stats: ${e.toString()}');
    }
  }
}
