import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        actions: [
          IconButton(
            onPressed: () => _showPrivacyTips(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Privacy Tips',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.privacy_tip, size: 48, color: Colors.blue.shade700),
                const SizedBox(height: 8),
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Last updated: December 2024',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Overview
          _buildSection(
            title: 'Quick Overview',
            content: [
              '• We collect minimal data necessary for app functionality',
              '• Your personal information is encrypted and secure',
              '• We never sell your data to third parties',
              '• You control your privacy settings',
              '• COPPA compliant for users under 13',
              '• You can delete your account and data anytime',
            ],
          ),

          // Information We Collect
          _buildSection(
            title: '1. Information We Collect',
            content: [
              'Account Information:',
              '• Name, email address, date of birth (for age verification)',
              '• Profile photo (optional)',
              '• Payment information (encrypted and tokenized)',
              '',
              'Usage Data:',
              '• Learning activity progress and scores',
              '• App usage patterns and preferences',
              '• Device information (model, OS version)',
              '• Log data (crashes, errors for improvement)',
              '',
              'Location Data:',
              '• General location (country/region) for compliance',
              '• We do NOT collect precise location data',
            ],
          ),

          // How We Use Information
          _buildSection(
            title: '2. How We Use Your Information',
            content: [
              'Essential Functions:',
              '• Provide learning activities and track progress',
              '• Process reward redemptions and payments',
              '• Maintain account security and prevent fraud',
              '• Comply with age verification requirements',
              '',
              'Improvements:',
              '• Analyze usage to improve app performance',
              '• Develop new features and content',
              '• Provide customer support',
              '',
              'Communications:',
              '• Send important account notifications',
              '• Share learning milestones and achievements',
              '• Provide customer support responses',
            ],
          ),

          // Information Sharing
          _buildSection(
            title: '3. Information Sharing',
            content: [
              'We DO NOT sell your personal information.',
              '',
              'Limited sharing occurs only in these cases:',
              '• Service Providers: Trusted partners who help operate our app (payment processors, cloud storage)',
              '• Legal Requirements: When required by law or to protect safety',
              '• Parental Consent: For users under 13, as required by COPPA',
              '• Business Transfer: In case of merger or acquisition (with notice)',
              '',
              'All third parties are contractually bound to protect your data.',
            ],
          ),

          // Data Security
          _buildSection(
            title: '4. Data Security',
            content: [
              'Security Measures:',
              '• AES-256 encryption for sensitive data',
              '• Secure HTTPS connections',
              '• Regular security audits and updates',
              '• Multi-factor authentication options',
              '• Automatic session timeouts',
              '',
              'Payment Security:',
              '• PCI DSS compliant payment processing',
              '• Tokenized payment information',
              '• No storage of full payment card details',
              '',
              'Access Controls:',
              '• Role-based access for our staff',
              '• Regular access reviews and monitoring',
              '• Secure development practices',
            ],
          ),

          // Children's Privacy (COPPA)
          _buildSection(
            title: '5. Children\'s Privacy (COPPA Compliance)',
            content: [
              'For Users Under 13:',
              '• Parental consent required before account creation',
              '• Limited data collection (only what\'s necessary)',
              '• No behavioral advertising',
              '• No sharing of personal information',
              '• Parents can review, modify, or delete child\'s data',
              '',
              'Parental Rights:',
              '• Request access to child\'s information',
              '• Modify or delete child\'s account',
              '• Withdraw consent at any time',
              '• Contact us at parents@learnifyrewards.com',
              '',
              'Teen Users (13-17):',
              '• Enhanced privacy protections',
              '• Limited data sharing capabilities',
              '• Parental notification options available',
            ],
          ),

          // Your Rights and Choices
          _buildSection(
            title: '6. Your Rights and Choices',
            content: [
              'Data Access and Control:',
              '• View all data we have about you',
              '• Download your data (data portability)',
              '• Correct inaccurate information',
              '• Delete your account and data',
              '',
              'Privacy Settings:',
              '• Control notification preferences',
              '• Manage data sharing settings',
              '• Choose what information to share',
              '• Opt out of non-essential communications',
              '',
              'Marketing Communications:',
              '• Opt out of promotional emails',
              '• Control in-app marketing messages',
              '• Manage push notification preferences',
            ],
          ),

          // Data Retention
          _buildSection(
            title: '7. Data Retention',
            content: [
              'How Long We Keep Data:',
              '• Account data: Until you delete your account',
              '• Learning progress: 3 years after last activity',
              '• Payment records: 7 years (legal requirement)',
              '• Log data: 1 year maximum',
              '',
              'Account Deletion:',
              '• Complete data removal within 30 days',
              '• Some data may be retained for legal compliance',
              '• Anonymized data may be kept for analytics',
              '• You\'ll receive confirmation of deletion',
            ],
          ),

          // International Users
          _buildSection(
            title: '8. International Users',
            content: [
              'Data Transfers:',
              '• Your data may be processed in different countries',
              '• We ensure adequate protection wherever data goes',
              '• GDPR compliant for European users',
              '• Local privacy law compliance',
              '',
              'European Users (GDPR):',
              '• Additional rights under GDPR',
              '• Legal basis for processing explained',
              '• Right to object to processing',
              '• Contact our Data Protection Officer',
            ],
          ),

          // Updates to Privacy Policy
          _buildSection(
            title: '9. Updates to This Privacy Policy',
            content: [
              'Policy Changes:',
              '• We may update this policy occasionally',
              '• Material changes will be prominently notified',
              '• Continued use indicates acceptance',
              '• Previous versions available upon request',
              '',
              'Notification Methods:',
              '• In-app notification',
              '• Email notification',
              '• Website announcement',
              '• Push notification (for significant changes)',
            ],
          ),

          // Contact Information
          _buildSection(
            title: '10. Contact Us',
            content: [
              'Privacy Questions or Concerns:',
              '',
              'Email: privacy@learnifyrewards.com',
              'Address: [Your Company Address]',
              'Phone: [Your Phone Number]',
              '',
              'Data Protection Officer:',
              'Email: dpo@learnifyrewards.com',
              '',
              'Parent/Guardian Inquiries:',
              'Email: parents@learnifyrewards.com',
              '',
              'We will respond to privacy inquiries within 48 hours.',
            ],
          ),

          const SizedBox(height: 32),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text(
                  'Privacy Commitment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We are committed to protecting your privacy and being transparent about our data practices. If you have any questions or concerns, please don\'t hesitate to contact us.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadPrivacyPolicy(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactPrivacyTeam(context),
                  icon: const Icon(Icons.email),
                  label: const Text('Contact Us'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((item) {
                if (item.isEmpty) {
                  return const SizedBox(height: 8);
                }

                if (item.endsWith(':')) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding:  EdgeInsets.only(
                      left: item.startsWith('•') ? 0 : 16, bottom: 4),
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static void _showPrivacyTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Tips'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Protect Your Privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use a strong, unique password'),
              Text('• Enable two-factor authentication'),
              Text('• Review your privacy settings regularly'),
              Text('• Be cautious with personal information'),
              Text('• Keep your app updated'),
              Text('• Report suspicious activity immediately'),
              SizedBox(height: 16),
              Text(
                'Remember:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'You have control over your data and can delete your account at any time.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static void _downloadPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy download feature coming soon!'),
      ),
    );
  }

  static void _contactPrivacyTeam(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Privacy Team'),
        content: const Text(
          'You can reach our privacy team at:\n\n'
          'Email: privacy@learnifyrewards.com\n'
          'Response time: Within 48 hours\n\n'
          'For urgent privacy concerns, please mark your email as "URGENT".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Would open email app with pre-filled email
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }
}
