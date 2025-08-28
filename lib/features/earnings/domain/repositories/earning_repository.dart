import 'package:learnify_rewards/features/earnings/domain/entities/earnings.dart';

abstract class EarningsRepository {
  Future<Earnings?> getEarnings(String userId);
  Future<List<Withdrawal>> getWithdrawals(String userId);
  Future<void> requestWithdrawal(String userId, double amount);
}
