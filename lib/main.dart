import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/activities/screens/activities_screen.dart';
import '../lib copy/features/earnings/screens/earnings_screen.dart';
import '../lib copy/features/profile/screens/profile_screen.dart';
import 'core/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: LearnAndEarnApp(),
    ),
  );
}

class LearnAndEarnApp extends ConsumerWidget {
  const LearnAndEarnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = _buildTheme();
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: AppConfig.appName,
      theme: theme,
      home: authState.when(
        data: (user) =>
            user != null ? const MainNavigator() : const LoginScreen(),
        loading: () => const LoadingScreen(),
        error: (error, stackTrace) => ErrorScreen(error: error.toString()),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      textTheme: GoogleFonts.poppinsTextTheme(),
      brightness: Brightness.light,
      useMaterial3: true,

      // Custom color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Card themes
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class ActivityPage extends StatelessWidget {
  final String activityType;
  const ActivityPage({super.key, required this.activityType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Activity — $activityType')),
      body: Center(child: Text('Activity UI for "$activityType" goes here')),
    );
  }
}

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Daily Estimated Earnings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('LP: 120'),
            Text('AER: 0.80 USD'),
            Text('Total Estimate: 2.35 USD'),
            SizedBox(height: 16),
            Text(
                'This is static demo data. Real values will be computed server-side.'),
          ],
        ),
      ),
    );
  }
}
