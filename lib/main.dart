import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';

// Import screens
import 'screens/main_screens.dart';
import 'screens/serverless_admin_panel.dart';

// Import serverless configuration (ZERO SERVER COSTS!)
import 'config/serverless_environment_config.dart';
import 'services/encryption_service.dart';
import 'services/serverless_manual_settlement_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Serverless Environment Configuration (Zero cost!)
  await ServerlessEnvironmentConfig.instance.initialize();
  final config = ServerlessEnvironmentConfig.instance;

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Encryption Service (Client-side only - zero server cost!)
  await EncryptionService().initialize();

  // Initialize Serverless Settlement Service (Zero server cost!)
  final _ = ServerlessManualSettlementService.instance;

  // Initialize Firebase services only if enabled and in production
  if (!config.isDevelopment) {
    // Initialize Firebase Crashlytics for production
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Initialize Firebase Analytics (free tier)
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // Initialize Firebase Performance (free tier)
    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }

  // Initialize Google Mobile Ads with environment-specific configuration
  await MobileAds.instance.initialize();

  runApp(LearnifyRewardsApp(config: config));
}

class LearnifyRewardsApp extends StatefulWidget {
  final ServerlessEnvironmentConfig config;

  const LearnifyRewardsApp({
    super.key,
    required this.config,
  });

  @override
  State<LearnifyRewardsApp> createState() => _LearnifyRewardsAppState();
}

class _LearnifyRewardsAppState extends State<LearnifyRewardsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'activities',
              builder: (context, state) => const ActivitiesScreen(),
            ),
            GoRoute(
              path: 'rewards',
              builder: (context, state) => const RewardsScreen(),
            ),
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'admin',
              builder: (context, state) => const ServerlessAdminPanel(),
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        final isLoggedIn = user != null;
        final isSplash = state.uri.path == '/splash';
        final isAuth = state.uri.path == '/auth';

        // If not logged in and not on auth/splash, redirect to auth
        if (!isLoggedIn && !isAuth && !isSplash) {
          return '/auth';
        }

        // If logged in and on auth, redirect to home
        if (isLoggedIn && isAuth) {
          return '/home';
        }

        return null; // No redirect needed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: FirebaseAuth.instance.authStateChanges(),
      initialData: null,
      child: MaterialApp.router(
        title: 'Learnify Rewards',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
      ),
    );
  }
}
