class Earnings {
  final double totalLP;
  final double totalEarnings;
  final double totalWithdrawals;
  final double remaining;

  Earnings({
    required this.totalLP,
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.remaining,
  });
}

class Withdrawal {
  final String id;
  final String month;
  final double amount;
  final String status;

  Withdrawal({
    required this.id,
    required this.month,
    required this.amount,
    required this.status,
  });
}
