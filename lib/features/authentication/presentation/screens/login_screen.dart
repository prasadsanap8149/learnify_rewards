import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learnify_rewards/shared/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user = await authService.signInWithGoogle();
            if (user != null) {
              context.go('/home');
            } else {
              // Handle sign-in failure
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Sign-In Failed')),
              );
            }
          },
          child: const Text('Login with Google'),
        ),
      ),
    );
  }
}
