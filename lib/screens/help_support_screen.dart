import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Content
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildHelpCategories(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactSupport,
        icon: const Icon(Icons.chat),
        label: const Text('Contact Support'),
      ),
    );
  }

  Widget _buildHelpCategories() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.chat,
                        label: 'Live Chat',
                        onTap: _contactSupport,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.email,
                        label: 'Email Us',
                        onTap: _sendEmail,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.bug_report,
                        label: 'Report Bug',
                        onTap: _reportBug,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // FAQ Categories
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _buildHelpCategory(
          icon: Icons.account_circle,
          title: 'Account & Profile',
          items: [
            'How to update my profile?',
            'How to change my password?',
            'How to delete my account?',
            'How to verify my age?',
          ],
        ),

        _buildHelpCategory(
          icon: Icons.stars,
          title: 'Learning Points & Rewards',
          items: [
            'How do I earn Learning Points?',
            'How to redeem rewards?',
            'Why didn\'t I receive my LP?',
            'What are the reward categories?',
          ],
        ),

        _buildHelpCategory(
          icon: Icons.play_circle,
          title: 'Activities & Learning',
          items: [
            'How to start an activity?',
            'How are activities scored?',
            'Can I retake an activity?',
            'How to track my progress?',
          ],
        ),

        _buildHelpCategory(
          icon: Icons.account_balance_wallet,
          title: 'Withdrawals & Payments',
          items: [
            'How to withdraw my earnings?',
            'When will I receive my payment?',
            'What payment methods are supported?',
            'Why was my withdrawal rejected?',
          ],
        ),

        _buildHelpCategory(
          icon: Icons.security,
          title: 'Security & Privacy',
          items: [
            'Is my data safe?',
            'How to enable two-factor authentication?',
            'What information do you collect?',
            'How to report suspicious activity?',
          ],
        ),

        _buildHelpCategory(
          icon: Icons.phone_android,
          title: 'Technical Issues',
          items: [
            'App is not loading',
            'Push notifications not working',
            'How to clear app cache?',
            'Supported devices and OS versions',
          ],
        ),

        const SizedBox(height: 32),

        // App Information
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Version', '1.0.0'),
                _buildInfoRow('Build', '100'),
                _buildInfoRow('Last Updated', 'December 2024'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _checkForUpdates,
                        child: const Text('Check for Updates'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _viewChangelog,
                        child: const Text('View Changelog'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildSearchResults() {
    // Mock search results - in a real app, this would search through FAQs
    final results = _getSearchResults(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords or contact support',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _contactSupport,
              child: const Text('Contact Support'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(result['question']!),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(result['answer']!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCategory({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: items
            .map((item) => ListTile(
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFAQDetail(item),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getSearchResults(String query) {
    final allFAQs = [
      {
        'question': 'How do I earn Learning Points?',
        'answer':
            'You can earn Learning Points by completing learning activities, watching educational videos, taking quizzes, and participating in interactive lessons. Each activity has a different LP reward based on its difficulty and duration.',
      },
      {
        'question': 'How to redeem rewards?',
        'answer':
            'Go to the Rewards section, browse available rewards, and tap on the one you want to redeem. Make sure you have enough Learning Points for the reward. Once redeemed, you\'ll receive instructions on how to claim your reward.',
      },
      {
        'question': 'How to update my profile?',
        'answer':
            'Go to your Profile section, tap on any field you want to update (like name, email, or payment details), make your changes, and tap Save. Some changes may require verification.',
      },
      {
        'question': 'How to withdraw my earnings?',
        'answer':
            'In the Earnings section, tap on "Withdraw", enter the amount you want to withdraw, select your payment method, and submit the request. Withdrawals are processed within 3-5 business days.',
      },
      {
        'question': 'Is my data safe?',
        'answer':
            'Yes, we use industry-standard encryption to protect your data. We never share your personal information with third parties without your consent, and all payments are processed securely.',
      },
    ];

    return allFAQs
        .where((faq) =>
            faq['question']!.toLowerCase().contains(query.toLowerCase()) ||
            faq['answer']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _showFAQDetail(String question) {
    final faq = _getSearchResults(question).firstWhere(
      (item) => item['question'] == question,
      orElse: () => {
        'question': question,
        'answer':
            'Detailed answer for this question is coming soon. Please contact support for immediate assistance.',
      },
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(faq['question']!),
        content: Text(faq['answer']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: const Text('Still Need Help?'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you like to contact our support team?'),
            SizedBox(height: 16),
            Text(
              'Response time: Usually within 24 hours',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmail();
            },
            child: const Text('Email'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startLiveChat();
            },
            child: const Text('Live Chat'),
          ),
        ],
      ),
    );
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@learnifyrewards.com',
      query:
          'subject=Support Request&body=Please describe your issue or question:',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not open email app. Please email us at support@learnifyrewards.com'),
        ),
      );
    }
  }

  void _startLiveChat() {
    // In a real app, this would open a chat interface
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Live chat feature coming soon! Please use email support for now.'),
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
          'Thank you for helping us improve the app! Please email us at bugs@learnifyrewards.com with:\n\n'
          '• Description of the issue\n'
          '• Steps to reproduce\n'
          '• Your device model and OS version\n'
          '• Screenshots (if applicable)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendBugReport();
            },
            child: const Text('Send Bug Report'),
          ),
        ],
      ),
    );
  }

  void _sendBugReport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bugs@learnifyrewards.com',
      query:
          'subject=Bug Report&body=Device Model:\nOS Version:\n\nIssue Description:\n\nSteps to Reproduce:\n1.\n2.\n3.',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not open email app. Please email us at bugs@learnifyrewards.com'),
        ),
      );
    }
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are using the latest version of the app!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewChangelog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What\'s New'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Initial release'),
              Text('• Learning activities system'),
              Text('• Rewards catalog'),
              Text('• Profile management'),
              Text('• Earnings and withdrawals'),
              Text('• Enhanced security features'),
              Text('• Age verification & COPPA compliance'),
              Text('• Admin dashboard'),
              Text('• Comprehensive help system'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
