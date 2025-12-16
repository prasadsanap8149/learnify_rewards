import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/serverless_manual_settlement_service.dart';
import '../services/serverless_withdrawal_service.dart';
import '../services/serverless_earnings_service.dart';
import '../services/serverless_fraud_detection_service.dart';

/// Serverless Admin Panel for Manual Settlement
///
/// This admin panel works entirely client-side without any server infrastructure.
/// Zero server costs - all data is managed through Firestore directly.
class ServerlessAdminPanel extends StatefulWidget {
  const ServerlessAdminPanel({Key? key}) : super(key: key);

  @override
  State<ServerlessAdminPanel> createState() => _ServerlessAdminPanelState();
}

class _ServerlessAdminPanelState extends State<ServerlessAdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServerlessManualSettlementService _settlementService =
      ServerlessManualSettlementService.instance;
  final ServerlessWithdrawalService _withdrawalService =
      ServerlessWithdrawalService();
  final ServerlessEarningsService _earningsService =
      ServerlessEarningsService();
  final ServerlessFraudDetectionService _fraudService =
      ServerlessFraudDetectionService();

  DateTime _selectedDate = DateTime.now();
  List<String> _selectedRequests = [];
  bool _isProcessing = false;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic> _systemStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStatistics();
    _loadSystemStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _settlementService.getSettlementStatistics(
        year: _selectedDate.year,
        month: _selectedDate.month,
      );
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load statistics: $e');
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      // Get system-wide statistics
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final withdrawalsSnapshot = await FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .get();
      final activitiesSnapshot =
          await FirebaseFirestore.instance.collection('user_activities').get();

      double totalEarnings = 0;
      int totalLP = 0;
      int activeUsers = 0;
      int flaggedUsers = 0;

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        totalEarnings += (data['totalEarnings'] ?? 0.0).toDouble();
        totalLP += (data['learningPoints'] ?? 0) as int;

        final lastActivity = data['lastActivityTimestamp'] as Timestamp?;
        if (lastActivity != null) {
          final daysSinceActivity =
              DateTime.now().difference(lastActivity.toDate()).inDays;
          if (daysSinceActivity <= 7) activeUsers++;
        }

        if (data['flagged'] == true) flaggedUsers++;
      }

      int pendingWithdrawals = 0;
      double totalWithdrawalAmount = 0;

      for (final doc in withdrawalsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'pending') pendingWithdrawals++;
        totalWithdrawalAmount += (data['amount'] ?? 0.0).toDouble();
      }

      int todayActivities = 0;
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        if (data['date'] == todayString) todayActivities++;
      }

      setState(() {
        _systemStats = {
          'totalUsers': usersSnapshot.docs.length,
          'activeUsers': activeUsers,
          'flaggedUsers': flaggedUsers,
          'totalEarnings': totalEarnings.toStringAsFixed(2),
          'totalLP': totalLP,
          'pendingWithdrawals': pendingWithdrawals,
          'totalWithdrawalAmount': totalWithdrawalAmount.toStringAsFixed(2),
          'todayActivities': todayActivities,
        };
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load system stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Serverless Settlement Admin'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.payment), text: 'Withdrawals'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildCostBanner(),
          _buildDateSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                //TODO: DEVELOP BELO TABS
                // _buildDashboardTab(),
                // _buildUsersTab(),
                // _buildWithdrawalsTab(),
                // _buildSecurityTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade100,
      child: Row(
        children: [
          Icon(Icons.money_off, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🎉 ZERO SERVER COSTS - Serverless architecture with Firebase free tier',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month),
          const SizedBox(width: 8),
          const Text('Settlement Month:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text(DateFormat('MMMM yyyy').format(_selectedDate)),
          ),
          const Spacer(),
          if (_statistics != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_statistics!['pending']['count']} pending',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingWithdrawalsTab() {
    return Column(
      children: [
        if (_selectedRequests.isNotEmpty) _buildBulkActionsBar(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _settlementService.getPendingWithdrawalsForMonth(
              year: _selectedDate.year,
              month: _selectedDate.month,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final requests = snapshot.data!;

              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No pending withdrawals for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text('All settlements are up to date! 🎉'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return _buildWithdrawalCard(request);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> request) {
    final amount = (request['amount'] as int) / 100.0;
    final method = request['method'] as String;
    final createdAt = (request['createdAt'] as Timestamp).toDate();
    final isSelected = _selectedRequests.contains(request['id']);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedRequests.add(request['id']);
              } else {
                _selectedRequests.remove(request['id']);
              }
            });
          },
        ),
        title: Row(
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMethodColor(method).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getMethodDisplayName(method),
                style: TextStyle(
                  color: _getMethodColor(method),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('User ID: ${request['userId']}'),
            Text(
                'Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}'),
            if (request['notes']?.isNotEmpty == true)
              Text('Notes: ${request['notes']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewPaymentDetails(request['id']),
              tooltip: 'View Payment Details',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _settleIndividualRequest(request['id']),
              tooltip: 'Mark as Settled',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _rejectRequest(request['id']),
              tooltip: 'Reject Request',
            ),
          ],
        ),
        onTap: () => _viewPaymentDetails(request['id']),
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Text(
            '${_selectedRequests.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedRequests.clear()),
            child: const Text('Clear Selection'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _bulkSettle,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment),
            label: Text(_isProcessing ? 'Processing...' : 'Bulk Settle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _statistics!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
            'Pending Withdrawals',
            stats['pending']['count'].toString(),
            '\$${(stats['pending']['amount'] / 100.0).toStringAsFixed(2)}',
            Colors.orange,
          ),
          _buildStatCard(
            'Completed Withdrawals',
            stats['completed']['count'].toString(),
            '\$${(stats['completed']['amount'] / 100.0).toStringAsFixed(2)}',
            Colors.green,
          ),
          _buildStatCard(
            'Rejected Requests',
            stats['rejected']['count'].toString(),
            'N/A',
            Colors.red,
          ),
          _buildStatCard(
            'Total Requests',
            stats['total']['count'].toString(),
            '\$${(stats['total']['amount'] / 100.0).toStringAsFixed(2)}',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, String amount, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.analytics, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$count requests'),
        trailing: Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.cloud_off, color: Colors.green.shade600),
          title: const Text('Serverless Mode'),
          subtitle: const Text('Zero server costs - runs entirely client-side'),
          trailing: Icon(Icons.check_circle, color: Colors.green.shade600),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Encrypted Payment Details'),
          subtitle: const Text('All payment information is encrypted'),
          trailing: const Icon(Icons.lock),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Manual Settlement'),
          subtitle: const Text('Admin processes payments outside the app'),
          trailing: const Icon(Icons.person),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.trending_down),
          title: const Text('Cost Optimization'),
          subtitle: const Text('Firebase free tier optimizations enabled'),
          trailing: const Icon(Icons.savings),
        ),
        const SizedBox(height: 24),
        const Text(
          'Cost Breakdown:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildCostItem('Cloud Functions', '\$0.00', 'Not used'),
        _buildCostItem('Firebase Hosting', '\$0.00', 'Free tier'),
        _buildCostItem('Firestore Reads', '≈\$0.00', 'Optimized queries'),
        _buildCostItem('Firestore Writes', '≈\$0.00', 'Minimal writes'),
        _buildCostItem('Authentication', '\$0.00', 'Free tier'),
        const Divider(),
        _buildCostItem('Total Monthly Cost', '\$0.00', 'Truly serverless!',
            isTotal: true),
      ],
    );
  }

  Widget _buildCostItem(String item, String cost, String note,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(item,
                  style: TextStyle(
                      fontWeight:
                          isTotal ? FontWeight.bold : FontWeight.normal))),
          Text(cost,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isTotal ? Colors.green : null)),
          const SizedBox(width: 8),
          Text('($note)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedRequests.clear();
      });
      await _loadStatistics();
    }
  }

  Future<void> _viewPaymentDetails(String requestId) async {
    try {
      final request =
          await _settlementService.getWithdrawalWithDecryptedDetails(requestId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Amount: \$${(request['amount'] / 100.0).toStringAsFixed(2)}'),
              Text('Method: ${_getMethodDisplayName(request['method'])}'),
              const SizedBox(height: 16),
              const Text('Payment Details:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...request['paymentDetails'].entries.map<Widget>(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    ),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _settleIndividualRequest(requestId);
              },
              child: const Text('Mark as Settled'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to load payment details: $e');
    }
  }

  Future<void> _settleIndividualRequest(String requestId) async {
    final reference = await _promptForSettlementReference();
    if (reference == null) return;

    try {
      setState(() => _isProcessing = true);
      await _settlementService.markWithdrawalAsSettled(
        requestId: requestId,
        adminId: 'admin_user', // In real app, get from Firebase Auth
        settlementReference: reference,
        settlementNotes: 'Manually processed by admin',
      );
      _showSuccessSnackBar('Withdrawal marked as settled');
      await _loadStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to settle withdrawal: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _bulkSettle() async {
    final reference = await _promptForSettlementReference();
    if (reference == null) return;

    try {
      setState(() => _isProcessing = true);
      await _settlementService.bulkProcessWithdrawals(
        requestIds: _selectedRequests,
        adminId: 'admin_user', // In real app, get from Firebase Auth
        settlementReference: reference,
        settlementNotes: 'Bulk settlement processed',
      );
      _showSuccessSnackBar('${_selectedRequests.length} withdrawals processed');
      setState(() => _selectedRequests.clear());
      await _loadStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to process bulk settlement: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final reason = await _promptForRejectionReason();
    if (reason == null) return;

    try {
      await _settlementService.rejectWithdrawalRequest(
        requestId: requestId,
        adminId: 'admin_user', // In real app, get from Firebase Auth
        rejectionReason: reason,
      );
      _showSuccessSnackBar('Withdrawal request rejected');
      await _loadStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to reject withdrawal: $e');
    }
  }

  Future<String?> _promptForSettlementReference() async {
    String? reference;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settlement Reference'),
        content: TextField(
          onChanged: (value) => reference = value,
          decoration: const InputDecoration(
            labelText: 'Transaction/Reference ID',
            hintText: 'e.g., PAYPAL_TXN_123456',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reference),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptForRejectionReason() async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          onChanged: (value) => reason = value,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g., Invalid payment details',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason),
            child: const Text('Reject'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getMethodDisplayName(String method) {
    switch (method) {
      case 'WithdrawalMethod.paypal':
        return 'PayPal';
      case 'WithdrawalMethod.bankTransfer':
        return 'Bank Transfer';
      case 'WithdrawalMethod.giftCard':
        return 'Gift Card';
      default:
        return method;
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'WithdrawalMethod.paypal':
        return Colors.blue;
      case 'WithdrawalMethod.bankTransfer':
        return Colors.green;
      case 'WithdrawalMethod.giftCard':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
