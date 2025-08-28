import 'package:learnify_rewards/features/earnings/domain/entities/earnings.dart';

class EarningsModel extends Earnings {
  EarningsModel({
    required double totalLP,
    required double totalEarnings,
    required double totalWithdrawals,
    required double remaining,
  }) : super(
          totalLP: totalLP,
          totalEarnings: totalEarnings,
          totalWithdrawals: totalWithdrawals,
          remaining: remaining,
        );

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      totalLP: json['totalLP'],
      totalEarnings: json['totalEarnings'],
      totalWithdrawals: json['totalWithdrawals'],
      remaining: json['remaining'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLP': totalLP,
      'totalEarnings': totalEarnings,
      'totalWithdrawals': totalWithdrawals,
      'remaining': remaining,
    };
  }
}

class WithdrawalModel extends Withdrawal {
  WithdrawalModel({
    required String id,
    required String month,
    required double amount,
    required String status,
  }) : super(
          id: id,
          month: month,
          amount: amount,
          status: status,
        );

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'],
      month: json['month'],
      amount: json['amount'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'status': status,
    };
  }
}
