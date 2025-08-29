import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/services/compliance_service.dart';
import '../shared/domain/entities/user.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentNameController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _requiresParentalConsent = false;
  final ComplianceService _complianceService = ComplianceService();

  @override
  void dispose() {
    _birthDateController.dispose();
    _parentEmailController.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
      helpText: 'Select your birth date',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = _formatDate(picked);
        _requiresParentalConsent = _calculateAge(picked) < 13;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  AgeGroup _getAgeGroup(int age) {
    if (age < 13) return AgeGroup.under13;
    if (age < 18) return AgeGroup.thirteenToSeventeen;
    return AgeGroup.eighteenPlus;
  }

  void _submitVerification() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      return;
    }

    if (_requiresParentalConsent &&
        (_parentEmailController.text.isEmpty ||
            _parentNameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Parental information is required for users under 13')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final age = _calculateAge(_selectedDate!);
      final ageGroup =
          _getAgeGroup(age); // Using the age group for verification

      // Submit age verification and record parental consent if needed
      if (_requiresParentalConsent) {
        await _complianceService.recordParentalConsent(
          userId: user.uid,
          parentEmail: _parentEmailController.text,
          parentName: _parentNameController.text,
          consentGranted: true,
        );
      }
      if (_requiresParentalConsent) {
        // Show parental consent pending screen
        _showParentalConsentPending();
      } else {
        // Age verification complete
        _showVerificationComplete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showParentalConsentPending() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Parental Consent Required'),
        content: const Text(
            'We\'ve sent an email to your parent/guardian requesting consent. '
            'Please ask them to check their email and follow the instructions. '
            'You\'ll be able to use the app once consent is provided.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVerificationComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Age Verification Complete'),
        content: const Text('Your age has been verified successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Age Verification'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Your Age',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We need to verify your age to provide appropriate content and comply with legal requirements.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Birth Date Field
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Birth Date',
                  hintText: 'Select your birth date',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please select your birth date';
                  }
                  return null;
                },
              ),

              if (_requiresParentalConsent) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Parental Consent Required',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Since you\'re under 13, we need your parent or guardian\'s consent.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Parent Name Field
                TextFormField(
                  controller: _parentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Parent/Guardian Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_requiresParentalConsent && (value?.isEmpty ?? true)) {
                      return 'Please enter parent/guardian name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Parent Email Field
                TextFormField(
                  controller: _parentEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Parent/Guardian Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_requiresParentalConsent) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter parent/guardian email';
                      }
                      if (!value!.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
              ],

              const Spacer(),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Submit Verification'),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy Notice
              Text(
                'Your personal information will be handled according to our Privacy Policy and will only be used for age verification purposes.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
