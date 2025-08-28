import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnify_rewards/features/activities/data/models/activity_model.dart';
import 'package:learnify_rewards/features/activities/domain/entities/activity.dart';
import 'package:learnify_rewards/features/activities/domain/repositories/activity_repository.dart';

class FirestoreActivityRepository implements ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

  @override
  Future<List<Activity>> getActivities() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('active', isEqualTo: true)
          .where('validFrom', isLessThanOrEqualTo: Timestamp.now())
          .where('validTo', isGreaterThanOrEqualTo: Timestamp.now())
          .get();

      return snapshot.docs
          .map((doc) => ActivityModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities: $e');
    }
  }

  @override
  Future<Activity?> getActivity(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ActivityModel.fromJson({...doc.data()!, 'id': id});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get activity: $e');
    }
  }

  Future<List<Activity>> getActivitiesByType(ActivityType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities by type: $e');
    }
  }

  Future<List<Activity>> getActivitiesByDifficulty(
      Difficulty difficulty) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('difficulty', isEqualTo: difficulty.toString().split('.').last)
          .where('active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivityModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities by difficulty: $e');
    }
  }

  Future<Activity> createActivity(Activity activity) async {
    try {
      final activityModel = ActivityModel(
        id: '', // Will be set by Firestore
        type: activity.type,
        subType: activity.subType,
        difficulty: activity.difficulty,
        content: activity.content,
      );

      final data = activityModel.toJson();
      data.addAll({
        'ageGroup': 'all',
        'validFrom': Timestamp.now(),
        'validTo':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'active': true,
        'createdBy': null, // Should be set by admin
        'moderatedBy': null,
        'approvedAt': null,
      });

      final docRef = await _firestore.collection(_collection).add(data);
      return ActivityModel.fromJson({...data, 'id': docRef.id});
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }
}
