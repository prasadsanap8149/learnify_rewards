import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivityState {
  final String uid;
  final Map<String, DateTime?> locks;
  final Map<String, dynamic>? lastAnswered;
  final Map<String, dynamic> streaks;
  final Map<String, dynamic> performance;

  UserActivityState({
    required this.uid,
    required this.locks,
    this.lastAnswered,
    required this.streaks,
    required this.performance,
  });

  factory UserActivityState.fromJson(Map<String, dynamic> json, String uid) {
    return UserActivityState(
      uid: uid,
      locks: (json['locks'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              value != null ? (value as Timestamp).toDate() : null,
            ),
          ) ??
          {},
      lastAnswered: json['lastAnswered'],
      streaks: json['streaks'] ??
          {'current': 0, 'longest': 0, 'lastStreakDate': null},
      performance: json['performance'] ??
          {'accuracy': 0.0, 'averageTime': 0.0, 'improvementRate': 0.0},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locks': locks.map(
        (key, value) => MapEntry(
          key,
          value != null ? Timestamp.fromDate(value) : null,
        ),
      ),
      'lastAnswered': lastAnswered,
      'streaks': streaks,
      'performance': performance,
    };
  }
}

class FirestoreUserActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'userActivityState';

  Future<UserActivityState?> getUserActivityState(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserActivityState.fromJson(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user activity state: $e');
    }
  }

  Future<void> updateActivityLock(
      String uid, String activityType, DateTime until) async {
    try {
      await _firestore.collection(_collection).doc(uid).set({
        'locks.$activityType.until': Timestamp.fromDate(until),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update activity lock: $e');
    }
  }

  Future<void> updateLastAnswered(
    String uid,
    String activityId,
    bool correct,
    int timeTaken,
  ) async {
    try {
      await _firestore.collection(_collection).doc(uid).set({
        'lastAnswered': {
          'activityId': activityId,
          'correct': correct,
          'at': FieldValue.serverTimestamp(),
          'timeTaken': timeTaken,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update last answered: $e');
    }
  }

  Future<void> updateStreak(String uid, int current, int longest) async {
    try {
      await _firestore.collection(_collection).doc(uid).set({
        'streaks': {
          'current': current,
          'longest': longest,
          'lastStreakDate': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  Future<void> updatePerformance(
    String uid,
    double accuracy,
    double averageTime,
    double improvementRate,
  ) async {
    try {
      await _firestore.collection(_collection).doc(uid).set({
        'performance': {
          'accuracy': accuracy,
          'averageTime': averageTime,
          'improvementRate': improvementRate,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update performance: $e');
    }
  }

  Stream<UserActivityState?> getUserActivityStateStream(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserActivityState.fromJson(doc.data()!, uid);
      }
      return null;
    });
  }
}
