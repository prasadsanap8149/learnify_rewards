import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _activityReminders = true;
  bool _rewardNotifications = true;
  bool _achievementAlerts = true;
  bool _withdrawalUpdates = true;
  bool _securityAlerts = true;
  bool _systemUpdates = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  int _reminderFrequency = 2; // 0: Never, 1: Daily, 2: Weekly, 3: Bi-weekly
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _activityReminders = data['activityReminders'] ?? true;
          _rewardNotifications = data['rewardNotifications'] ?? true;
          _achievementAlerts = data['achievementAlerts'] ?? true;
          _withdrawalUpdates = data['withdrawalUpdates'] ?? true;
          _securityAlerts = data['securityAlerts'] ?? true;
          _systemUpdates = data['systemUpdates'] ?? false;
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _reminderFrequency = data['reminderFrequency'] ?? 2;

          if (data['reminderTime'] != null) {
            final timeData = data['reminderTime'] as Map<String, dynamic>;
            _reminderTime = TimeOfDay(
              hour: timeData['hour'] ?? 18,
              minute: timeData['minute'] ?? 0,
            );
          }
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final settingsData = {
        'activityReminders': _activityReminders,
        'rewardNotifications': _rewardNotifications,
        'achievementAlerts': _achievementAlerts,
        'withdrawalUpdates': _withdrawalUpdates,
        'securityAlerts': _securityAlerts,
        'systemUpdates': _systemUpdates,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'reminderFrequency': _reminderFrequency,
        'reminderTime': {
          'hour': _reminderTime.hour,
          'minute': _reminderTime.minute,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set(settingsData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Types Section
          const Text(
            'Notification Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: 'Activity Reminders',
            subtitle: 'Get reminded about incomplete activities',
            value: _activityReminders,
            onChanged: (value) => setState(() => _activityReminders = value),
            icon: Icons.play_circle_outline,
          ),

          _buildSwitchTile(
            title: 'Reward Notifications',
            subtitle: 'Notifications about new rewards and redemptions',
            value: _rewardNotifications,
            onChanged: (value) => setState(() => _rewardNotifications = value),
            icon: Icons.card_giftcard,
          ),

          _buildSwitchTile(
            title: 'Achievement Alerts',
            subtitle: 'Celebrate your achievements and milestones',
            value: _achievementAlerts,
            onChanged: (value) => setState(() => _achievementAlerts = value),
            icon: Icons.emoji_events,
          ),

          _buildSwitchTile(
            title: 'Withdrawal Updates',
            subtitle: 'Status updates for your withdrawal requests',
            value: _withdrawalUpdates,
            onChanged: (value) => setState(() => _withdrawalUpdates = value),
            icon: Icons.account_balance_wallet,
          ),

          _buildSwitchTile(
            title: 'Security Alerts',
            subtitle: 'Important security notifications',
            value: _securityAlerts,
            onChanged: (value) => setState(() => _securityAlerts = value),
            icon: Icons.security,
            important: true,
          ),

          _buildSwitchTile(
            title: 'System Updates',
            subtitle: 'App updates and maintenance notifications',
            value: _systemUpdates,
            onChanged: (value) => setState(() => _systemUpdates = value),
            icon: Icons.system_update,
          ),

          const SizedBox(height: 32),

          // Delivery Methods Section
          const Text(
            'Delivery Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            icon: Icons.notifications,
          ),

          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive important updates via email',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
            icon: Icons.email,
          ),

          const SizedBox(height: 32),

          // Reminder Settings Section
          const Text(
            'Reminder Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reminder Frequency',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _reminderFrequency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Never')),
                      DropdownMenuItem(value: 1, child: Text('Daily')),
                      DropdownMenuItem(value: 2, child: Text('Weekly')),
                      DropdownMenuItem(value: 3, child: Text('Bi-weekly')),
                    ],
                    onChanged: (value) =>
                        setState(() => _reminderFrequency = value ?? 2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reminder Time',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectReminderTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Text(_reminderTime.format(context)),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Test Notification Button
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.notifications, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text(
                    'Test Your Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Send a test notification to verify your settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sendTestNotification,
                    child: const Text('Send Test Notification'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool important = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: important ? FontWeight.bold : FontWeight.normal,
            color: important ? Colors.red.shade700 : null,
          ),
        ),
        subtitle: Text(subtitle),
        secondary: Icon(
          icon,
          color: important ? Colors.red.shade700 : Colors.grey.shade600,
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      // Here you would typically call your notification service
      // For now, we'll just show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Test notification sent! Check your device notifications.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
