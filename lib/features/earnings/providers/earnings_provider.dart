import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/earnings_repository.dart';
import '../models/earnings_model.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository();
});

final dailyEarningsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.watch(earningsRepositoryProvider).getDailyEarningsEstimate(userId);
});

final earningsStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.watch(earningsRepositoryProvider).getEarningsStats(userId);
});

final withdrawalHistoryProvider =
    FutureProvider.family<List<Withdrawal>, String>((ref, userId) async {
  return ref.watch(earningsRepositoryProvider).getWithdrawalHistory(userId);
});

class EarningsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final EarningsRepository _repository;

  EarningsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> recordLPEvent({
    required String userId,
    required int lp,
    required String reason,
    String? activityRef,
    required String difficulty,
    required int timeTaken,
    required String deviceFingerprint,
    required String ipAddress,
  }) async {
    try {
      await _repository.recordLPEvent(
        userId: userId,
        lp: lp,
        reason: reason,
        activityRef: activityRef,
        difficulty: difficulty,
        timeTaken: timeTaken,
        deviceFingerprint: deviceFingerprint,
        ipAddress: ipAddress,
      );

      // Refresh daily earnings estimate
      final estimate = await _repository.getDailyEarningsEstimate(userId);
      state = AsyncValue.data(estimate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordAdEvent({
    required String userId,
    required String format,
    required String adNetwork,
    required bool impression,
    required bool clicked,
    required String adUnitId,
    required String placementId,
    required double revenue,
    required Map<String, dynamic> deviceInfo,
    required String ipAddress,
    required String userAgent,
    required String consentStatus,
    required String ageGroup,
    required int engagementTime,
  }) async {
    try {
      await _repository.recordAdEvent(
        userId: userId,
        format: format,
        adNetwork: adNetwork,
        impression: impression,
        clicked: clicked,
        adUnitId: adUnitId,
        placementId: placementId,
        revenue: revenue,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        userAgent: userAgent,
        consentStatus: consentStatus,
        ageGroup: ageGroup,
        engagementTime: engagementTime,
      );

      // Refresh daily earnings estimate
      final estimate = await _repository.getDailyEarningsEstimate(userId);
      state = AsyncValue.data(estimate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> requestWithdrawal({
    required String userId,
    required double amount,
    required String method,
    required Map<String, String> paymentDetails,
  }) async {
    try {
      await _repository.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: method,
        paymentDetails: paymentDetails,
      );

      // Refresh earnings stats
      final stats = await _repository.getEarningsStats(userId);
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshEarnings(String userId) async {
    try {
      state = const AsyncValue.loading();
      final estimate = await _repository.getDailyEarningsEstimate(userId);
      state = AsyncValue.data(estimate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final earningsNotifierProvider =
    StateNotifierProvider<EarningsNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  return EarningsNotifier(ref.watch(earningsRepositoryProvider));
});
