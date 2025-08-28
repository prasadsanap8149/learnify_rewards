import 'package:flutter/material.dart';
import 'package:learnify_rewards/features/earnings/data/repositories/earnings_repository_impl.dart';
import 'package:learnify_rewards/features/earnings/domain/entities/earnings.dart';
import '../../domain/repositories/earning_repository.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsRepository _earningsRepository = EarningsRepositoryImpl() as EarningsRepository;
  late Future<Earnings?> _earnings;
  late Future<List<Withdrawal>> _withdrawals;

  @override
  void initState() {
    super.initState();
    // Replace 'user1' with the actual user ID
    _earnings = _earningsRepository.getEarnings('user1');
    _withdrawals = _earningsRepository.getWithdrawals('user1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: FutureBuilder<Earnings?>(
        future: _earnings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No earnings data found.'));
          }

          final earnings = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total LP: ${earnings.totalLP}'),
                Text(
                    'Total Earnings: \$${earnings.totalEarnings.toStringAsFixed(2)}'),
                Text(
                    'Withdrawn: \$${earnings.totalWithdrawals.toStringAsFixed(2)}'),
                Text('Remaining: \$${earnings.remaining.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Implement withdrawal request
                  },
                  child: const Text('Request Withdrawal'),
                ),
                const SizedBox(height: 20),
                const Text('Withdrawal History',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: FutureBuilder<List<Withdrawal>>(
                    future: _withdrawals,
                    builder: (context, withdrawalSnapshot) {
                      if (withdrawalSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (withdrawalSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${withdrawalSnapshot.error}'));
                      } else if (!withdrawalSnapshot.hasData ||
                          withdrawalSnapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No withdrawal history.'));
                      }

                      final withdrawals = withdrawalSnapshot.data!;
                      return ListView.builder(
                        itemCount: withdrawals.length,
                        itemBuilder: (context, index) {
                          final withdrawal = withdrawals[index];
                          return ListTile(
                            title: Text(
                                'Amount: \$${withdrawal.amount.toStringAsFixed(2)}'),
                            subtitle: Text('Status: ${withdrawal.status}'),
                            trailing: Text(withdrawal.month),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
