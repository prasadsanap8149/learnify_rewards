import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Learn & Earn'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Learn & Earn'),
            ElevatedButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
