import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'lp_service.dart';

/// Mobile-first service for activity management
/// Handles learning activities, progress tracking, and completion
class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get available activities for the user
  static Stream<List<Map<String, dynamic>>> getAvailableActivities({
    String? category,
    String? difficulty,
    int limit = 20,
  }) {
    Query query =
        _firestore.collection('activities').where('isActive', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get user's activity progress
  static Stream<List<Map<String, dynamic>>> getUserActivityProgress() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('user_activities')
        .where('userId', isEqualTo: user.uid)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Start a new activity
  static Future<String?> startActivity({
    required String activityId,
    Map<String, dynamic>? initialData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get activity details
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) return null;

      final activityData = activityDoc.data()!;
      final timestamp = DateTime.now();
      final userActivityId =
          'ua_${timestamp.millisecondsSinceEpoch}_${user.uid}';

      // Create user activity record
      final userActivity = {
        'id': userActivityId,
        'userId': user.uid,
        'activityId': activityId,
        'activityTitle': activityData['title'],
        'activityType': activityData['type'],
        'difficulty': activityData['difficulty'],
        'status': 'in_progress',
        'progress': 0.0,
        'currentStep': 0,
        'totalSteps': activityData['totalSteps'] ?? 1,
        'timeSpent': 0,
        'startedAt': Timestamp.fromDate(timestamp),
        'lastAccessedAt': Timestamp.fromDate(timestamp),
        'completedAt': null,
        'score': null,
        'attempts': 1,
        'responses': [],
        'metadata': initialData ?? {},
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .set(userActivity);

      // Update activity statistics
      await _updateActivityStats(activityId, 'started');

      return userActivityId;
    } catch (e) {
      print('Error starting activity: $e');
      return null;
    }
  }

  /// Update activity progress
  static Future<bool> updateActivityProgress({
    required String userActivityId,
    required double progress,
    int? currentStep,
    int? timeSpent,
    Map<String, dynamic>? responses,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final timestamp = DateTime.now();
      final updates = <String, dynamic>{
        'progress': progress,
        'lastAccessedAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      if (currentStep != null) {
        updates['currentStep'] = currentStep;
      }

      if (timeSpent != null) {
        updates['timeSpent'] = FieldValue.increment(timeSpent);
      }

      if (responses != null) {
        updates['responses'] = FieldValue.arrayUnion([responses]);
      }

      if (metadata != null) {
        updates['metadata'] = metadata;
      }

      await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating activity progress: $e');
      return false;
    }
  }

  /// Complete an activity
  static Future<bool> completeActivity({
    required String userActivityId,
    required double score,
    required int totalTimeSpent,
    Map<String, dynamic>? finalResponses,
    Map<String, dynamic>? completionMetadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final timestamp = DateTime.now();

      // Get the user activity to get activity details
      final userActivityDoc = await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .get();
      if (!userActivityDoc.exists) return false;

      final userActivityData = userActivityDoc.data()!;
      final activityId = userActivityData['activityId'];

      // Get activity details for LP calculation
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) return false;

      final activityData = activityDoc.data()!;

      // Update user activity to completed
      final updates = <String, dynamic>{
        'status': 'completed',
        'progress': 100.0,
        'score': score,
        'timeSpent': totalTimeSpent,
        'completedAt': Timestamp.fromDate(timestamp),
        'lastAccessedAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      if (finalResponses != null) {
        updates['responses'] = FieldValue.arrayUnion([finalResponses]);
      }

      if (completionMetadata != null) {
        updates['metadata'] = completionMetadata;
      }

      await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .update(updates);

      // Update activity statistics
      await _updateActivityStats(activityId, 'completed');

      // Process LP reward (using LPService)
      await LPService.processActivityCompletion(
        activityId: activityId,
        userActivityId: userActivityId,
        activityData: activityData,
        completionData: {
          'score': score,
          'timeSpent': totalTimeSpent,
          'completedAt': timestamp.toIso8601String(),
        },
      );

      // Update user statistics (using UserService)
      await UserService.updateUserStats(
        activityType: activityData['type'] ?? 'activity',
        score: score,
        timeSpent: totalTimeSpent,
      );

      return true;
    } catch (e) {
      print('Error completing activity: $e');
      return false;
    }
  }

  /// Get activity details by ID
  static Future<Map<String, dynamic>?> getActivityDetails(
      String activityId) async {
    try {
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) return null;

      final data = activityDoc.data()!;
      data['id'] = activityDoc.id;
      return data;
    } catch (e) {
      print('Error getting activity details: $e');
      return null;
    }
  }

  /// Get user's specific activity progress
  static Future<Map<String, dynamic>?> getUserActivityDetails(
      String userActivityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userActivityDoc = await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .get();
      if (!userActivityDoc.exists) return null;

      final data = userActivityDoc.data()!;

      // Verify this belongs to the current user
      if (data['userId'] != user.uid) return null;

      data['id'] = userActivityDoc.id;
      return data;
    } catch (e) {
      print('Error getting user activity details: $e');
      return null;
    }
  }

  /// Search activities by keywords
  static Stream<List<Map<String, dynamic>>> searchActivities({
    required String searchTerm,
    String? category,
    String? difficulty,
    int limit = 20,
  }) {
    Query query =
        _firestore.collection('activities').where('isActive', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    // Note: Firestore doesn't support full-text search natively
    // In a production app, you might want to use Algolia or similar for better search
    // For now, we'll filter client-side which is not ideal for large datasets
    return query
        .limit(limit * 2) // Get more results to filter client-side
        .snapshots()
        .map((snapshot) {
      final searchLower = searchTerm.toLowerCase();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((activity) {
            final title = (activity['title'] as String? ?? '').toLowerCase();
            final description =
                (activity['description'] as String? ?? '').toLowerCase();
            final tags = (activity['tags'] as List<dynamic>? ?? [])
                .join(' ')
                .toLowerCase();

            return title.contains(searchLower) ||
                description.contains(searchLower) ||
                tags.contains(searchLower);
          })
          .take(limit)
          .toList();
    });
  }

  /// Get recommended activities for the user
  static Future<List<Map<String, dynamic>>> getRecommendedActivities(
      {int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get user's completed activities to understand preferences
      final userActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();

      // Simple recommendation: get activities in categories user has completed
      final completedCategories = <String>{};
      for (final doc in userActivities.docs) {
        final activity = doc.data();
        final activityId = activity['activityId'];

        final activityDoc =
            await _firestore.collection('activities').doc(activityId).get();
        if (activityDoc.exists) {
          final category = activityDoc.data()!['category'];
          if (category != null) completedCategories.add(category);
        }
      }

      Query query = _firestore
          .collection('activities')
          .where('isActive', isEqualTo: true);

      // If user has completed activities in specific categories, recommend from those categories
      if (completedCategories.isNotEmpty) {
        query = query.where('category',
            whereIn: completedCategories.take(10).toList());
      }

      final recommendations = await query.limit(limit).get();

      return recommendations.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting recommended activities: $e');
      return [];
    }
  }

  /// Update activity statistics (internal method)
  static Future<void> _updateActivityStats(
      String activityId, String action) async {
    try {
      final activityRef = _firestore.collection('activities').doc(activityId);

      if (action == 'started') {
        await activityRef.update({
          'stats.totalStarted': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else if (action == 'completed') {
        await activityRef.update({
          'stats.totalCompleted': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print('Error updating activity stats: $e');
    }
  }

  /// Get user's learning statistics
  static Future<Map<String, dynamic>> getUserLearningStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .get();

      final stats = <String, dynamic>{
        'totalActivities': userActivities.docs.length,
        'completedActivities': 0,
        'inProgressActivities': 0,
        'totalTimeSpent': 0,
        'averageScore': 0.0,
        'categoriesExplored': <String>{},
        'difficultiesCompleted': <String>{},
      };

      double totalScore = 0.0;
      int completedCount = 0;

      for (final doc in userActivities.docs) {
        final activity = doc.data();
        final status = activity['status'];
        final timeSpent = activity['timeSpent'] ?? 0;
        final score = activity['score'];

        stats['totalTimeSpent'] =
            (stats['totalTimeSpent'] as int) + (timeSpent as int);

        if (status == 'completed') {
          stats['completedActivities'] =
              (stats['completedActivities'] as int) + 1;
          if (score != null) {
            totalScore += (score as num).toDouble();
            completedCount++;
          }

          // Track categories and difficulties
          final difficulty = activity['difficulty'];
          if (difficulty != null) {
            (stats['difficultiesCompleted'] as Set<String>).add(difficulty);
          }
        } else if (status == 'in_progress') {
          stats['inProgressActivities'] =
              (stats['inProgressActivities'] as int) + 1;
        }

        // Get activity details for category
        final activityId = activity['activityId'];
        if (activityId != null) {
          try {
            final activityDoc =
                await _firestore.collection('activities').doc(activityId).get();
            if (activityDoc.exists) {
              final category = activityDoc.data()!['category'];
              if (category != null) {
                (stats['categoriesExplored'] as Set<String>).add(category);
              }
            }
          } catch (e) {
            // Continue if we can't get activity details
          }
        }
      }

      if (completedCount > 0) {
        stats['averageScore'] = totalScore / completedCount;
      }

      // Convert sets to lists for JSON serialization
      stats['categoriesExplored'] =
          (stats['categoriesExplored'] as Set<String>).toList();
      stats['difficultiesCompleted'] =
          (stats['difficultiesCompleted'] as Set<String>).toList();

      return stats;
    } catch (e) {
      print('Error getting user learning stats: $e');
      return {};
    }
  }

  /// Resume an in-progress activity
  static Future<bool> resumeActivity(String userActivityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .update({
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error resuming activity: $e');
      return false;
    }
  }

  /// Abandon an activity (mark as abandoned, not deleted)
  static Future<bool> abandonActivity(String userActivityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('user_activities')
          .doc(userActivityId)
          .update({
        'status': 'abandoned',
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error abandoning activity: $e');
      return false;
    }
  }
}
