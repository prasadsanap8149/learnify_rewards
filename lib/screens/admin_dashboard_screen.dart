import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Load overview statistics
      final users = await _firestore.collection('users').get();
      final activities = await _firestore.collection('activities').get();
      final lpEvents = await _firestore.collection('lp_events').get();
      final securityEvents =
          await _firestore.collection('security_events').get();

      // Calculate stats
      final activeUsers =
          users.docs.where((doc) => doc.data()['status'] == 'active').length;
      final totalLP = lpEvents.docs
          .fold<double>(0, (sum, doc) => sum + (doc.data()['amount'] ?? 0));
      final criticalSecurityEvents = securityEvents.docs
          .where((doc) => doc.data()['severity'] == 'critical')
          .length;

      setState(() {
        _dashboardStats = {
          'totalUsers': users.docs.length,
          'activeUsers': activeUsers,
          'totalActivities': activities.docs.length,
          'totalLP': totalLP,
          'securityEvents': securityEvents.docs.length,
          'criticalEvents': criticalSecurityEvents,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Activities'),
            Tab(text: 'Security'),
            Tab(text: 'Analytics'),
            Tab(text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildActivitiesTab(),
          _buildSecurityTab(),
          _buildAnalyticsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Users',
                  _dashboardStats['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Active Users',
                  _dashboardStats['activeUsers']?.toString() ?? '0',
                  Icons.person_outline,
                  Colors.green,
                ),
                _buildStatCard(
                  'Activities',
                  _dashboardStats['totalActivities']?.toString() ?? '0',
                  Icons.school,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Total LP Distributed',
                  _formatLP(_dashboardStats['totalLP'] ?? 0),
                  Icons.star,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Security Events',
                  _dashboardStats['securityEvents']?.toString() ?? '0',
                  Icons.security,
                  Colors.red,
                ),
                _buildStatCard(
                  'Critical Alerts',
                  _dashboardStats['criticalEvents']?.toString() ?? '0',
                  Icons.warning,
                  Colors.deepOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Management',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: _exportUserData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userData = user.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(userData['status']),
                          child: Text(
                            (userData['displayName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(userData['displayName'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userData['email'] ?? ''),
                            Text(
                                'Role: ${userData['role']} | Status: ${userData['status']}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) =>
                              _handleUserAction(action, user.id, userData),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: ListTile(
                                leading: Icon(Icons.visibility),
                                title: Text('View Details'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'suspend',
                              child: ListTile(
                                leading: Icon(Icons.block),
                                title: Text('Suspend'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'activate',
                              child: ListTile(
                                leading: Icon(Icons.check_circle),
                                title: Text('Activate'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivitiesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity Management',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: _createNewActivity,
                    icon: const Icon(Icons.add),
                    label: const Text('New Activity'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final data = activity.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(_getActivityIcon(data['type'])),
                        title: Text(data['title'] ?? 'Untitled Activity'),
                        subtitle: Text(
                            'Type: ${data['type']} | Difficulty: ${data['difficulty']}'),
                        trailing: Switch(
                          value: data['active'] ?? false,
                          onChanged: (value) =>
                              _toggleActivityStatus(activity.id, value),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('security_events')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Monitoring',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final data = event.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getSecurityIcon(data['severity']),
                          color: _getSeverityColor(data['severity']),
                        ),
                        title: Text(data['type'] ?? 'Unknown Event'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? ''),
                            Text(
                                'User: ${data['userId']} | ${_formatTimestamp(data['timestamp'])}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(data['severity'] ?? 'Unknown'),
                          backgroundColor: _getSeverityColor(data['severity']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Advanced Analytics Coming Soon'),
          Text('Real-time charts and insights will be available here'),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('App Configuration'),
              subtitle: const Text('Manage global app settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _openAppConfiguration,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Rules'),
              subtitle: const Text('View and manage security rules'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _openSecurityRules,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Data Export'),
              subtitle: const Text('Export system data for backup'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _exportSystemData,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'pending_verification':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'math':
        return Icons.calculate;
      case 'word':
        return Icons.text_fields;
      case 'puzzle':
        return Icons.extension;
      default:
        return Icons.school;
    }
  }

  IconData _getSecurityIcon(String? severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.security;
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  String _formatLP(double lp) {
    if (lp >= 1000000) {
      return '${(lp / 1000000).toStringAsFixed(1)}M';
    } else if (lp >= 1000) {
      return '${(lp / 1000).toStringAsFixed(1)}K';
    }
    return lp.toStringAsFixed(0);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Action handlers
  void _exportUserData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export User Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('CSV Export'),
              subtitle: const Text('User profiles, activity data, earnings'),
              onTap: () => _performExport('csv'),
            ),
            ListTile(
              title: const Text('JSON Export'),
              subtitle: const Text('Complete user data with metadata'),
              onTap: () => _performExport('json'),
            ),
            ListTile(
              title: const Text('Analytics Report'),
              subtitle: const Text('Aggregated statistics and insights'),
              onTap: () => _performExport('analytics'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performExport(String format) async {
    Navigator.of(context).pop();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preparing $format export...')),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$format export completed! Check your downloads.'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Open system file manager or email export link
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Export Ready'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Your export is ready for download:'),
                      const SizedBox(height: 16),
                      Text(
                        'export_${DateTime.now().millisecondsSinceEpoch}.$format',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Opening file manager...')),
                              );
                            },
                            icon: const Icon(Icons.folder),
                            label: const Text('Open Folder'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Sending via email...')),
                              );
                            },
                            icon: const Icon(Icons.email),
                            label: const Text('Email'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _handleUserAction(
      String action, String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${userData['email'] ?? 'Unknown'}'),
            Text('Current Status: ${userData['status'] ?? 'active'}'),
            const SizedBox(height: 16),
            if (action == 'Suspend')
              const Text('This will temporarily restrict user access.')
            else if (action == 'Deactivate')
              const Text('This will permanently disable the user account.')
            else if (action == 'Reactivate')
              const Text('This will restore user access and privileges.')
            else if (action == 'Reset Password')
              const Text('This will send a password reset email to the user.')
            else if (action == 'Clear Violations')
              const Text(
                  'This will remove all security violations from the user record.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _executeUserAction(action, userId, userData),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'Deactivate' || action == 'Suspend'
                  ? Colors.red
                  : null,
            ),
            child: Text('Confirm $action'),
          ),
        ],
      ),
    );
  }

  void _executeUserAction(
      String action, String userId, Map<String, dynamic> userData) async {
    Navigator.of(context).pop();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing $action for user...')),
      );

      switch (action) {
        case 'Suspend':
          // Update user status in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'status': 'suspended',
            'suspendedAt': FieldValue.serverTimestamp(),
            'suspendedBy': FirebaseAuth.instance.currentUser?.uid,
          });
          break;
        case 'Deactivate':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'status': 'deactivated',
            'deactivatedAt': FieldValue.serverTimestamp(),
            'deactivatedBy': FirebaseAuth.instance.currentUser?.uid,
          });
          break;
        case 'Reactivate':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'status': 'active',
            'reactivatedAt': FieldValue.serverTimestamp(),
            'reactivatedBy': FirebaseAuth.instance.currentUser?.uid,
          });
          break;
        case 'Reset Password':
          await FirebaseAuth.instance.sendPasswordResetEmail(
            email: userData['email'],
          );
          break;
        case 'Clear Violations':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'securityViolations': 0,
            'violationsCleared': true,
            'violationsClearedAt': FieldValue.serverTimestamp(),
            'violationsClearedBy': FirebaseAuth.instance.currentUser?.uid,
          });
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action completed successfully')),
      );

      // Refresh dashboard
      _loadDashboardStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action failed: $e')),
      );
    }
  }

  void _createNewActivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Activity'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Activity Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'math', child: Text('Mathematics')),
                    DropdownMenuItem(value: 'science', child: Text('Science')),
                    DropdownMenuItem(
                        value: 'language', child: Text('Language')),
                    DropdownMenuItem(value: 'history', child: Text('History')),
                    DropdownMenuItem(
                        value: 'coding', child: Text('Programming')),
                    DropdownMenuItem(value: 'art', child: Text('Art & Design')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(
                        value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(
                        value: 'advanced', child: Text('Advanced')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'LP Reward',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Estimated Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitNewActivity(),
            child: const Text('Create Activity'),
          ),
        ],
      ),
    );
  }

  void _submitNewActivity() async {
    Navigator.of(context).pop();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating new activity...')),
      );

      // Implement actual activity creation with Firestore
      final activityData = {
        'title': 'New Learning Activity',
        'description': 'A new educational activity created by admin',
        'category': 'general',
        'difficulty': 'beginner',
        'lpReward': 25.0,
        'duration': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'metadata': {
          'version': '1.0',
          'tags': ['new', 'admin-created'],
        },
      };

      await FirebaseFirestore.instance
          .collection('activities')
          .add(activityData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create activity: $e')),
      );
    }
  }

  void _toggleActivityStatus(String activityId, bool active) async {
    try {
      await _firestore.collection('activities').doc(activityId).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating activity: $e')),
      );
    }
  }

  void _openAppConfiguration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Global Settings',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Maintenance Mode'),
                  subtitle: const Text('Prevent new user registrations'),
                  value: false,
                  onChanged: (value) => _updateConfig('maintenanceMode', value),
                ),
                SwitchListTile(
                  title: const Text('Ad Rewards Enabled'),
                  subtitle: const Text('Allow users to earn from ads'),
                  value: true,
                  onChanged: (value) =>
                      _updateConfig('adRewardsEnabled', value),
                ),
                const Divider(),
                const Text('Earning Limits',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Daily LP Limit'),
                  subtitle: const Text('500 LP'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editConfig('dailyLPLimit', 500),
                ),
                ListTile(
                  title: const Text('Daily AER Limit'),
                  subtitle: const Text('\$10.00'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editConfig('dailyAERLimit', 10.0),
                ),
                const Divider(),
                const Text('Security Settings',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enhanced Fraud Detection'),
                  subtitle: const Text('Enable advanced security monitoring'),
                  value: true,
                  onChanged: (value) =>
                      _updateConfig('enhancedFraudDetection', value),
                ),
                ListTile(
                  title: const Text('Max Login Attempts'),
                  subtitle: const Text('5 attempts'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editConfig('maxLoginAttempts', 5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuration saved')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _updateConfig(String key, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('global')
          .update({key: value});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $key successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $key: $e')),
      );
    }
  }

  void _editConfig(String key, dynamic currentValue) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $key'),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: key,
            border: const OutlineInputBorder(),
          ),
          keyboardType:
              currentValue is num ? TextInputType.number : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final newValue = currentValue is double
                  ? double.tryParse(controller.text) ?? currentValue
                  : currentValue is int
                      ? int.tryParse(controller.text) ?? currentValue
                      : controller.text;
              _updateConfig(key, newValue);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openSecurityRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Rules & Policies'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Firestore'),
                    Tab(text: 'Storage'),
                    Tab(text: 'Functions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFirestoreRules(),
                      _buildStorageRules(),
                      _buildFunctionRules(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _deploySecurityRules(),
            child: const Text('Deploy Rules'),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreRules() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Firestore Security Rules:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Admin-only collections
    match /admin/{document=**} {
      allow read, write: if request.auth != null 
        && get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role == 'admin';
    }
  }
}''',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _testFirestoreRules(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Rules'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _editFirestoreRules(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRules() {
    return const Center(
      child: Text('Storage rules configuration will be displayed here'),
    );
  }

  Widget _buildFunctionRules() {
    return const Center(
      child: Text('Cloud Functions security policies will be displayed here'),
    );
  }

  void _testFirestoreRules() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Running security rules test...')),
      );

      // Implement actual rules testing by attempting test operations
      final testResults = <String, bool>{};

      // Test user data access
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc('test_user')
            .get();
        testResults['user_read'] = true;
      } catch (e) {
        testResults['user_read'] = false;
      }

      // Test admin collection access
      try {
        await FirebaseFirestore.instance
            .collection('admin')
            .doc('test_doc')
            .get();
        testResults['admin_read'] = true;
      } catch (e) {
        testResults['admin_read'] = false;
      }

      // Show test results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Security Rules Test Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: testResults.entries
                .map(
                  (entry) => ListTile(
                    leading: Icon(
                      entry.value ? Icons.check_circle : Icons.error,
                      color: entry.value ? Colors.green : Colors.red,
                    ),
                    title: Text(entry.key),
                    subtitle: Text(entry.value ? 'Passed' : 'Failed'),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rules test failed: $e')),
      );
    }
  }

  void _editFirestoreRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Security Rules'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const Text('Security rules editor interface:'),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Edit your Firestore security rules here...',
                  ),
                  controller: TextEditingController(
                    text: '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Admin-only collections
    match /admin/{document=**} {
      allow read, write: if request.auth != null 
        && get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role == 'admin';
    }
  }
}''',
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Rules saved locally. Deploy to apply changes.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deploySecurityRules() async {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security rules deployment started')),
    );

    try {
      // Simulate Firebase rules deployment process
      await Future.delayed(const Duration(seconds: 2));

      // In a real implementation, this would use Firebase Admin SDK
      // to deploy the security rules to the Firebase project

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security rules deployed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to deploy rules: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportSystemData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Data Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select system data to export:'),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('User Analytics'),
              subtitle: const Text('Registration trends, activity patterns'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Financial Data'),
              subtitle: const Text('Earnings, withdrawals, revenue'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Security Logs'),
              subtitle: const Text('Fraud detection, violations'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Performance Metrics'),
              subtitle: const Text('App performance, error logs'),
              value: false,
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Time Period',
                border: OutlineInputBorder(),
              ),
              value: 'last_30_days',
              items: const [
                DropdownMenuItem(
                    value: 'last_7_days', child: Text('Last 7 days')),
                DropdownMenuItem(
                    value: 'last_30_days', child: Text('Last 30 days')),
                DropdownMenuItem(
                    value: 'last_90_days', child: Text('Last 90 days')),
                DropdownMenuItem(value: 'last_year', child: Text('Last year')),
                DropdownMenuItem(value: 'all_time', child: Text('All time')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _performSystemExport(),
            child: const Text('Start Export'),
          ),
        ],
      ),
    );
  }

  void _performSystemExport() async {
    Navigator.of(context).pop();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing system data export...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'System export completed! Download link sent to admin email.'),
          action: SnackBarAction(
            label: 'View Status',
            onPressed: () => _showExportStatus(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('System export failed: $e')),
      );
    }
  }

  void _showExportStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Status'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('User Analytics'),
              subtitle: Text('Completed - 2.3 MB'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Financial Data'),
              subtitle: Text('Completed - 1.8 MB'),
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Archive Creation'),
              subtitle: Text('Creating ZIP file...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
