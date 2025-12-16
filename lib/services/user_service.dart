import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mobile-first service for user management operations
/// Replaces Cloud Functions with client-side logic
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize user profile after registration
  static Future<bool> initializeUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final timestamp = DateTime.now();

      final userData = {
        'id': userId,
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'photoURL': photoURL,
        'lpBalance': 0.0,
        'totalLPEarned': 0.0,
        'totalLPSpent': 0.0,
        'level': 1,
        'experience': 0,
        'streakDays': 0,
        'lastActivityDate': null,
        'completedActivities': 0,
        'totalTimeSpent': 0,
        'achievements': [],
        'preferences': {
          'notifications': true,
          'emailUpdates': true,
          'theme': 'system',
          'language': 'en',
        },
        'stats': {
          'coursesCompleted': 0,
          'lessonsCompleted': 0,
          'quizzesCompleted': 0,
          'averageScore': 0.0,
          'bestStreak': 0,
          'totalLoginDays': 1,
        },
        'deviceInfo': {
          'platform': 'mobile',
          'lastLoginDevice': 'mobile',
        },
        'privacy': {
          'dataCollection': true,
          'analytics': true,
          'marketing': false,
        },
        'isActive': true,
        'emailVerified': false,
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
        'lastLoginAt': Timestamp.fromDate(timestamp),
        ...?additionalData,
      };

      await _firestore.collection('users').doc(userId).set(userData);
      return true;
    } catch (e) {
      print('Error initializing user profile: $e');
      return false;
    }
  }

  /// Update user profile data
  static Future<bool> updateUserProfile({
    required Map<String, dynamic> updates,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final timestamp = DateTime.now();
      updates['updatedAt'] = Timestamp.fromDate(timestamp);

      await _firestore.collection('users').doc(user.uid).update(updates);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) return null;

      final userDoc =
          await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      data['id'] = userDoc.id;
      return data;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user's last login timestamp
  static Future<bool> updateLastLogin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final timestamp = DateTime.now();

      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      return true;
    } catch (e) {
      print('Error updating last login: $e');
      return false;
    }
  }

  /// Update user statistics after activity completion
  static Future<bool> updateUserStats({
    required String activityType,
    required double score,
    required int timeSpent,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final stats = Map<String, dynamic>.from(userData['stats'] ?? {});
      final timestamp = DateTime.now();

      // Update activity-specific counters
      switch (activityType) {
        case 'course':
          stats['coursesCompleted'] = (stats['coursesCompleted'] ?? 0) + 1;
          break;
        case 'lesson':
          stats['lessonsCompleted'] = (stats['lessonsCompleted'] ?? 0) + 1;
          break;
        case 'quiz':
          stats['quizzesCompleted'] = (stats['quizzesCompleted'] ?? 0) + 1;
          break;
      }

      // Update general stats
      final totalActivities = userData['completedActivities'] ?? 0;
      final totalTime = userData['totalTimeSpent'] ?? 0;
      final currentAverage = (stats['averageScore'] as num?)?.toDouble() ?? 0.0;

      // Calculate new average score
      final newAverage = totalActivities > 0
          ? ((currentAverage * totalActivities) + score) / (totalActivities + 1)
          : score;

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'completedActivities': totalActivities + 1,
        'totalTimeSpent': totalTime + timeSpent,
        'lastActivityDate': Timestamp.fromDate(timestamp),
        'stats': {
          ...stats,
          'averageScore': newAverage,
        },
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      // Check for level progression
      await _checkLevelProgression(user.uid);

      return true;
    } catch (e) {
      print('Error updating user stats: $e');
      return false;
    }
  }

  /// Check and update user level based on experience
  static Future<bool> _checkLevelProgression(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentLevel = userData['level'] ?? 1;
      final experience = userData['experience'] ?? 0;

      // Simple level progression: every 1000 XP = 1 level
      final newLevel = (experience / 1000).floor() + 1;

      if (newLevel > currentLevel) {
        await _firestore.collection('users').doc(userId).update({
          'level': newLevel,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Award level up bonus (handled by LP service)
        // This could trigger a notification or celebration UI
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking level progression: $e');
      return false;
    }
  }

  /// Update user's daily streak
  static Future<bool> updateDailyStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final lastActivityDate = userData['lastActivityDate'] as Timestamp?;
      final currentStreak = userData['streakDays'] ?? 0;
      final bestStreak = userData['stats']?['bestStreak'] ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int newStreak = currentStreak;

      if (lastActivityDate == null) {
        // First activity ever
        newStreak = 1;
      } else {
        final lastActivity = lastActivityDate.toDate();
        final lastActivityDay =
            DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
        final daysSinceLastActivity = today.difference(lastActivityDay).inDays;

        if (daysSinceLastActivity == 0) {
          // Same day, keep current streak
          newStreak = currentStreak;
        } else if (daysSinceLastActivity == 1) {
          // Yesterday, increment streak
          newStreak = currentStreak + 1;
        } else {
          // More than 1 day, reset streak
          newStreak = 1;
        }
      }

      final newBestStreak = newStreak > bestStreak ? newStreak : bestStreak;

      await _firestore.collection('users').doc(user.uid).update({
        'streakDays': newStreak,
        'stats.bestStreak': newBestStreak,
        'updatedAt': Timestamp.fromDate(now),
      });

      return true;
    } catch (e) {
      print('Error updating daily streak: $e');
      return false;
    }
  }

  /// Get user's learning progress and statistics
  static Future<Map<String, dynamic>?> getUserProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;

      return {
        'level': userData['level'] ?? 1,
        'experience': userData['experience'] ?? 0,
        'lpBalance': userData['lpBalance'] ?? 0.0,
        'totalLPEarned': userData['totalLPEarned'] ?? 0.0,
        'streakDays': userData['streakDays'] ?? 0,
        'completedActivities': userData['completedActivities'] ?? 0,
        'totalTimeSpent': userData['totalTimeSpent'] ?? 0,
        'stats': userData['stats'] ?? {},
        'achievements': userData['achievements'] ?? [],
      };
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }

  /// Award achievement to user
  static Future<bool> awardAchievement({
    required String achievementId,
    required String title,
    required String description,
    required String iconUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final achievements =
          List<Map<String, dynamic>>.from(userData['achievements'] ?? []);

      // Check if achievement already exists
      if (achievements
          .any((achievement) => achievement['id'] == achievementId)) {
        return false; // Already has this achievement
      }

      // Add new achievement
      final achievement = {
        'id': achievementId,
        'title': title,
        'description': description,
        'iconUrl': iconUrl,
        'unlockedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': metadata ?? {},
      };

      achievements.add(achievement);

      await _firestore.collection('users').doc(user.uid).update({
        'achievements': achievements,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error awarding achievement: $e');
      return false;
    }
  }

  /// Update user preferences
  static Future<bool> updateUserPreferences({
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        'preferences': preferences,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  /// Delete user account and all associated data
  static Future<bool> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userId = user.uid;
      final batch = _firestore.batch();

      // Delete user document
      batch.delete(_firestore.collection('users').doc(userId));

      // Delete user's LP events
      final lpEvents = await _firestore
          .collection('lp_events')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in lpEvents.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's activity records
      final userActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userActivities.docs) {
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();

      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }

  Future getUserAgeVerification() async {
    //TODO: Complete logic here
  }

  Future getUserStats(String userId) async {
    //TODO: Complete this function

  }
}
