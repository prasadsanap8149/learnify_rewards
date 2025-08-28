import 'package:learnify_rewards/features/activities/domain/entities/activity.dart';

abstract class ActivityRepository {
  Future<List<Activity>> getActivities();
  Future<Activity?> getActivity(String id);
}
