import 'package:flutter/material.dart';
import 'package:learnify_rewards/config/router/app_router.dart';
import 'package:learnify_rewards/config/theme/app_theme.dart';
import 'package:learnify_rewards/shared/services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder(
      stream: authService.user,
      builder: (context, snapshot) {
        final initialLocation = snapshot.hasData ? '/home' : '/';
        final router = AppRouter.createRouter(initialLocation);

        return MaterialApp.router(
          title: 'Learn & Earn',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
