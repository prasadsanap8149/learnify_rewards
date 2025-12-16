import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../services/earnings_pool_service.dart';
import '../../../../services/withdrawal_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with TickerProviderStateMixin {
  final WithdrawalService _withdrawalService = WithdrawalService();
  final EarningsPoolService _earningsService = EarningsPoolService();

  late TabController _tabController;
  Map<String, dynamic> _userEarnings = {};
  List<Map<String, dynamic>> _earningsHistory = [];
  List<Map<String, dynamic>> _withdrawalHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load user earnings data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _userEarnings = {
            'totalEarnings': (userData['totalEarnings'] ?? 0.0).toDouble(),
            'learningPoints': userData['learningPoints'] ?? 0,
            'reservedEarnings': (userData['reservedEarnings'] ?? 0.0)
                .toDouble(),
          };
        });
      }

      // Load earnings history
      final earningsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('earnings_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      setState(() {
        _earningsHistory = earningsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });

      // Load withdrawal history
      final withdrawalSnapshot = await FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('requestTimestamp', descending: true)
          .limit(50)
          .get();

      setState(() {
        _withdrawalHistory = withdrawalSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Overview'),
            Tab(icon: Icon(Icons.history), text: 'Earnings'),
            Tab(icon: Icon(Icons.payment), text: 'Withdrawals'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEarningsHistoryTab(),
                _buildWithdrawalsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final totalEarnings = _userEarnings['totalEarnings'] ?? 0.0;
    final learningPoints = _userEarnings['learningPoints'] ?? 0;
    final reservedEarnings = _userEarnings['reservedEarnings'] ?? 0.0;
    final availableBalance = totalEarnings - reservedEarnings;
    final potentialEarnings = learningPoints >= 1000
        ? (learningPoints * 0.01)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[800]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (reservedEarnings > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '₹${reservedEarnings.toStringAsFixed(2)} reserved for pending withdrawals',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Earned',
                  '₹${totalEarnings.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Learning Points',
                  learningPoints.toString(),
                  Icons.stars,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Potential Earnings',
                  '₹${potentialEarnings.toStringAsFixed(2)}',
                  Icons.lightbulb,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Withdrawals',
                  _withdrawalHistory.length.toString(),
                  Icons.payment,
                  Colors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (learningPoints >= 1000) ...[
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.currency_exchange,
                  color: Colors.green,
                ),
                title: const Text('Convert LP to Earnings'),
                subtitle: Text(
                  'Convert $learningPoints LP to ₹${potentialEarnings.toStringAsFixed(2)}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showConvertLPDialog(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (availableBalance >= 50.0) ...[
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
                title: const Text('Request Withdrawal'),
                subtitle: Text(
                  'Minimum ₹50.00 • Available ₹${availableBalance.toStringAsFixed(2)}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showWithdrawalDialog(),
              ),
            ),
          ] else ...[
            Card(
              color: Colors.grey[100],
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.grey[600]),
                title: Text(
                  'Withdrawal Unavailable',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                subtitle: Text(
                  'Minimum ₹50.00 required • Current ₹${availableBalance.toStringAsFixed(2)}',
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Conversion Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How It Works',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Complete activities to earn Learning Points (LP)',
                  ),
                  const Text(
                    '• 1 LP = ₹0.01 (automatic conversion at 1000+ LP)',
                  ),
                  const Text('• Withdraw earnings when balance ≥ ₹50'),
                  const Text(
                    '• All transactions are processed manually by admin',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsHistoryTab() {
    if (_earningsHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No earnings history yet'),
            Text('Complete activities to start earning!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _earningsHistory.length,
      itemBuilder: (context, index) {
        final earning = _earningsHistory[index];
        final amount = (earning['earningsAmount'] ?? 0.0).toDouble();
        final lpConverted = earning['totalLP'] ?? 0;
        final timestamp = earning['timestamp'] as Timestamp?;
        final type = earning['calculationType'] ?? 'unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            title: Text('₹${amount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$lpConverted LP converted'),
                if (timestamp != null)
                  Text(_formatTimestamp(timestamp.toDate())),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: type == 'daily_automatic' ? Colors.blue : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type == 'daily_automatic' ? 'Auto' : 'Manual',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWithdrawalsTab() {
    if (_withdrawalHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No withdrawals yet'),
            Text('Request your first withdrawal when you have ₹50+'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawalHistory.length,
      itemBuilder: (context, index) {
        final withdrawal = _withdrawalHistory[index];
        final amount = (withdrawal['amount'] ?? 0.0).toDouble();
        final status = withdrawal['status'] ?? 'unknown';
        final method = withdrawal['paymentMethod'] ?? 'unknown';
        final timestamp = withdrawal['requestTimestamp'] as Timestamp?;

        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'pending':
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          case 'approved':
            statusColor = Colors.blue;
            statusIcon = Icons.check_circle;
            break;
          case 'completed':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'rejected':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white),
            ),
            title: Text('₹${amount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${method.toUpperCase()} • ${status.toUpperCase()}'),
                if (timestamp != null)
                  Text(_formatTimestamp(timestamp.toDate())),
              ],
            ),
            trailing: status == 'pending'
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelWithdrawal(withdrawal['id']),
                  )
                : null,
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showConvertLPDialog() {
    final learningPoints = _userEarnings['learningPoints'] ?? 0;
    final potentialEarnings = learningPoints * 0.01;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert Learning Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert $learningPoints LP to ₹${potentialEarnings.toStringAsFixed(2)}?',
            ),
            const SizedBox(height: 16),
            const Text(
              'This will reset your LP to 0 and add the earnings to your balance.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _convertLP();
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog() {
    // This would show a withdrawal form
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Withdrawal feature will be implemented with payment details form',
        ),
      ),
    );
  }

  Future<void> _convertLP() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final learningPoints = _userEarnings['learningPoints'] ?? 0;
      final earningsAmount = learningPoints * 0.01;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          final userData = userSnapshot.data()!;
          final currentEarnings = (userData['totalEarnings'] ?? 0.0).toDouble();

          transaction.update(userRef, {
            'totalEarnings': currentEarnings + earningsAmount,
            'learningPoints': 0,
            'lastEarningsCalculation': FieldValue.serverTimestamp(),
          });

          // Create earnings history record
          final historyRef = userRef.collection('earnings_history').doc();
          transaction.set(historyRef, {
            'totalLP': learningPoints,
            'earningsAmount': earningsAmount,
            'conversionRate': 0.01,
            'timestamp': FieldValue.serverTimestamp(),
            'calculationType': 'manual_conversion',
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Converted $learningPoints LP to ₹${earningsAmount.toStringAsFixed(2)}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadUserData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error converting LP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelWithdrawal(String withdrawalId) async {
    try {
      await FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .doc(withdrawalId)
          .update({
            'status': 'cancelled',
            'lastUpdated': FieldValue.serverTimestamp(),
            'notes': 'Cancelled by user',
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal cancelled'),
          backgroundColor: Colors.green,
        ),
      );

      _loadUserData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling withdrawal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
