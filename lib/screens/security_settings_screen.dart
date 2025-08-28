import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _enableNotificationEncryption = true;
  bool _requireBiometricAuth = false;
  bool _enableTwoFactorAuth = false;
  bool _shareAnalytics = true;
  String _sessionTimeout = '30';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Security',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your privacy and security preferences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),

            // Notification Security
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Security',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Notification Encryption'),
                      subtitle:
                          const Text('Encrypt sensitive notification content'),
                      value: _enableNotificationEncryption,
                      onChanged: (value) {
                        setState(() {
                          _enableNotificationEncryption = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Authentication
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Biometric Authentication'),
                      subtitle:
                          const Text('Use fingerprint or face recognition'),
                      value: _requireBiometricAuth,
                      onChanged: (value) {
                        setState(() {
                          _requireBiometricAuth = value;
                        });
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text('Add an extra layer of security'),
                      value: _enableTwoFactorAuth,
                      onChanged: (value) {
                        setState(() {
                          _enableTwoFactorAuth = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Session Management
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Management',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Session Timeout'),
                      subtitle: Text(
                          'Auto-logout after $_sessionTimeout minutes of inactivity'),
                      trailing: DropdownButton<String>(
                        value: _sessionTimeout,
                        items: const [
                          DropdownMenuItem(value: '15', child: Text('15 min')),
                          DropdownMenuItem(value: '30', child: Text('30 min')),
                          DropdownMenuItem(value: '60', child: Text('1 hour')),
                          DropdownMenuItem(
                              value: '120', child: Text('2 hours')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sessionTimeout = value;
                            });
                            _saveSettings();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data Privacy
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Privacy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Share Analytics'),
                      subtitle: const Text(
                          'Help improve the app with usage analytics'),
                      value: _shareAnalytics,
                      onChanged: (value) {
                        setState(() {
                          _shareAnalytics = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exportSecuritySettings,
                    child: const Text('Export Settings'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetToDefaults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // Save settings to secure storage
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportSecuritySettings() {
    final settings = {
      'notificationEncryption': _enableNotificationEncryption,
      'biometricAuth': _requireBiometricAuth,
      'twoFactorAuth': _enableTwoFactorAuth,
      'shareAnalytics': _shareAnalytics,
      'sessionTimeout': _sessionTimeout,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Security Settings'),
        content: SingleChildScrollView(
          child: SelectableText(
            settings.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: settings.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                ),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Security Settings'),
        content: const Text(
          'This will reset all security settings to their default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _enableNotificationEncryption = true;
                _requireBiometricAuth = false;
                _enableTwoFactorAuth = false;
                _shareAnalytics = true;
                _sessionTimeout = '30';
              });
              Navigator.of(context).pop();
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
