import 'package:learnify_rewards/features/activities/data/models/activity_model.dart';
import 'package:learnify_rewards/features/activities/domain/entities/activity.dart';
import 'package:learnify_rewards/features/activities/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  // Dummy data for now
  final List<ActivityModel> _activities = [
    ActivityModel(
      id: '1',
      type: ActivityType.math,
      subType: 'addition',
      difficulty: Difficulty.easy,
      content: {'question': '1 + 1 = ?', 'answer': '2'},
    ),
    ActivityModel(
      id: '2',
      type: ActivityType.word,
      subType: 'scramble',
      difficulty: Difficulty.medium,
      content: {'question': 'elhl', 'answer': 'hello'},
    ),
  ];

  @override
  Future<List<Activity>> getActivities() async {
    return _activities;
  }

  @override
  Future<Activity?> getActivity(String id) async {
    return _activities.firstWhere((activity) => activity.id == id);
  }
}
