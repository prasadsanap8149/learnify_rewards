import 'package:go_router/go_router.dart';
import 'package:learnify_rewards/features/activities/presentation/screens/activity_list_screen.dart';
import 'package:learnify_rewards/features/authentication/presentation/screens/login_screen.dart';
import 'package:learnify_rewards/features/authentication/presentation/screens/onboarding_screen.dart';
import 'package:learnify_rewards/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:learnify_rewards/features/home/presentation/screens/home_screen.dart';
import 'package:learnify_rewards/features/user_profile/presentation/screens/profile_screen.dart';

class AppRouter {
  static GoRouter createRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivityListScreen(),
        ),
        GoRoute(
          path: '/earnings',
          builder: (context, state) => const EarningsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
