import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/config.dart';
import '../../../core/exceptions.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Title
              const Icon(
                Icons.school,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn, Play, and Earn!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 48),

              // Age Verification Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Age Verification Required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You must be at least 13 years old to use this app. Users under 13 require parental consent.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Google Sign In Button
              ElevatedButton.icon(
                onPressed: () => _handleGoogleSignIn(ref, context),
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 24),

              // Terms and Privacy
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(WidgetRef ref, BuildContext context) async {
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      // After successful sign-in, the authStateProvider will automatically
      // update and navigate to MainNavigator
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AuthException
                ? e.message
                : 'An error occurred. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AgeVerificationDialog extends StatefulWidget {
  const AgeVerificationDialog({super.key});

  @override
  State<AgeVerificationDialog> createState() => _AgeVerificationDialogState();
}

class _AgeVerificationDialogState extends State<AgeVerificationDialog> {
  final _dateController = TextEditingController();
  String? _parentEmail;
  bool _isUnder13 = false;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _handleDateSelected(DateTime? date) {
    if (date == null) return;

    setState(() {
      _dateController.text = '${date.day}/${date.month}/${date.year}';
      _isUnder13 = DateTime.now().difference(date).inDays < (13 * 365);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Age Verification',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Select your date of birth',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().subtract(const Duration(days: 365 * 13)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                _handleDateSelected(date);
              },
            ),
            if (_isUnder13) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Parent/Guardian Email',
                  hintText: 'Enter parent or guardian email',
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _parentEmail = value,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_dateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select your date of birth'),
                    ),
                  );
                  return;
                }

                if (_isUnder13 && (_parentEmail?.isEmpty ?? true)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter parent/guardian email'),
                    ),
                  );
                  return;
                }

                // Return the result
                Navigator.of(context).pop({
                  'dateOfBirth': _dateController.text,
                  'parentEmail': _parentEmail,
                });
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
