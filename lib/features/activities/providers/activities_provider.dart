import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/activity_repository.dart';
import '../models/activity_model.dart';
import '../repository/activity_repository.dart';
import '../models/activity_model.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

final userActivityStateProvider =
    FutureProvider.family<UserActivityState, String>((ref, userId) async {
  return ref.watch(activityRepositoryProvider).getUserActivityState(userId);
});

final activityStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.watch(activityRepositoryProvider).getActivityStats(userId);
});

final activityLocksProvider =
    Provider.family<bool, String>((ref, activityType) {
  final userState = ref.watch(userActivityStateProvider);
  return userState.value?.locks[activityType]?.isLocked ?? false;
});

class ActivitiesNotifier extends StateNotifier<AsyncValue<List<Activity>>> {
  final ActivityRepository _repository;
  final StateNotifierProviderRef _ref;

  ActivitiesNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  Future<void> loadActivities({
    required String type,
    required String ageGroup,
    String? difficulty,
  }) async {
    try {
      state = const AsyncValue.loading();
      final activities = await _repository.getActivities(
        type: type,
        ageGroup: ageGroup,
        difficulty: difficulty,
      );
      state = AsyncValue.data(activities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordAnswer({
    required String userId,
    required String activityId,
    required bool correct,
    required int timeTaken,
  }) async {
    try {
      await _repository.recordAnswer(
        userId: userId,
        activityId: activityId,
        correct: correct,
        timeTaken: timeTaken,
      );

      // Update performance stats
      final activity =
          (state.value ?? []).firstWhere((a) => a.id == activityId);
      await _repository.updatePerformance(
        userId: userId,
        accuracy: correct ? 1.0 : 0.0,
        averageTime: timeTaken.toDouble(),
        improvementRate:
            0.0, // TODO: Calculate this based on historical performance
      );

      if (correct) {
        await lockActivity(
          userId: userId,
          activityType: activity.type,
          cooldown: const Duration(hours: 24), // TODO: Get from config
        );
      }
    } catch (e, st) {
      // Just rethrow since we don't update state here
      rethrow;
    }
  }

  Future<void> lockActivity({
    required String userId,
    required String activityType,
    required Duration cooldown,
  }) async {
    try {
      await _repository.lockActivity(
        userId: userId,
        activityType: activityType,
        cooldown: cooldown,
      );
    } catch (e, st) {
      rethrow;
    }
  }
}

final activitiesNotifierProvider =
    StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<Activity>>>(
        (ref) {
  return ActivitiesNotifier(
    ref.watch(activityRepositoryProvider),
    ref,
  );
});
