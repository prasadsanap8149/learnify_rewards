import 'package:learnify_rewards/features/earnings/data/models/earnings_model.dart';
import 'package:learnify_rewards/features/earnings/domain/entities/earnings.dart';

import '../../domain/repositories/earning_repository.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  // Dummy data
  final Map<String, EarningsModel> _earnings = {
    'user1': EarningsModel(
      totalLP: 1000,
      totalEarnings: 50.0,
      totalWithdrawals: 20.0,
      remaining: 30.0,
    )
  };
  final Map<String, List<WithdrawalModel>> _withdrawals = {
    'user1': [
      WithdrawalModel(
          id: '1', month: '2025-07', amount: 20.0, status: 'settled')
    ]
  };

  @override
  Future<Earnings?> getEarnings(String userId) async {
    return _earnings[userId];
  }

  @override
  Future<List<Withdrawal>> getWithdrawals(String userId) async {
    return _withdrawals[userId] ?? [];
  }

  @override
  Future<void> requestWithdrawal(String userId, double amount) async {
    // In a real app, this would interact with a backend service.
    print('Withdrawal request for $amount for user $userId');
  }
}
