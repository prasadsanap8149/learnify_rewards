import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/user_service.dart';
import '../services/lp_service.dart';
import '../services/notification_service.dart';
import '../services/activity_service.dart';
import 'notifications_screen.dart';
import 'activity_detail_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Add any initialization logic here
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update last login
        await UserService.updateLastLogin();
        context.go('/home');
      } else {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              'Learnify Rewards',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Learn, Earn, Achieve',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;

      if (_isLogin) {
        // Sign in
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Sign up
        final credential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Initialize user profile
        if (credential.user != null) {
          await UserService.initializeUserProfile(
            userId: credential.user!.uid,
            email: credential.user!.email!,
            displayName: credential.user!.displayName,
            photoURL: credential.user!.photoURL,
          );

          // Award welcome bonus
          await LPService.awardWelcomeBonus();
        }
      }

      if (mounted) {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.school,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome Back' : 'Join Learnify',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to continue learning'
                      : 'Start your learning journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ActivitiesScreen(),
    const RewardsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(),
            SizedBox(height: 16),
            _LPBalanceCard(),
            SizedBox(height: 16),
            _QuickStatsCard(),
            SizedBox(height: 16),
            _RecentActivitiesCard(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Learner';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $displayName!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to continue your learning journey?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LPBalanceCard extends StatelessWidget {
  const _LPBalanceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Learning Points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<double>(
              future: LPService.getUserLPBalance(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                return Text(
                  '${balance.toInt()} LP',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Earned from completing activities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: UserService.getUserProgress(),
              builder: (context, snapshot) {
                final progress = snapshot.data ?? {};
                return Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.emoji_events,
                        label: 'Level',
                        value: '${progress['level'] ?? 1}',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.local_fire_department,
                        label: 'Streak',
                        value: '${progress['streakDays'] ?? 0}',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: '${progress['completedActivities'] ?? 0}',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  const _RecentActivitiesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivitiesScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Start your first activity to see progress here!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.explore)),
            Tab(text: 'In Progress', icon: Icon(Icons.play_circle)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesList('available'),
                _buildActivitiesList('in_progress'),
                _buildActivitiesList('completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Categories')),
                DropdownMenuItem(value: 'math', child: Text('Math')),
                DropdownMenuItem(value: 'word', child: Text('Word Games')),
                DropdownMenuItem(value: 'puzzle', child: Text('Puzzles')),
                DropdownMenuItem(value: 'quiz', child: Text('Quizzes')),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Levels')),
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (value) {
                setState(() => _selectedDifficulty = value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getActivitiesStream(status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data?.docs ?? [];

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No activities found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index].data() as Map<String, dynamic>;
            return _ActivityCard(activity: activity, status: status);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getActivitiesStream(String status) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    Query query = FirebaseFirestore.instance.collection('activities');

    // Apply filters
    if (_selectedCategory != 'all') {
      query = query.where('type', isEqualTo: _selectedCategory);
    }
    if (_selectedDifficulty != 'all') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }

    return query.where('isActive', isEqualTo: true).snapshots();
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String status;

  const _ActivityCard({required this.activity, required this.status});

  @override
  Widget build(BuildContext context) {
    final lpReward = (activity['lpReward'] as num?)?.toDouble() ?? 0.0;
    final difficulty = activity['difficulty'] as String? ?? 'beginner';
    final type = activity['type'] as String? ?? 'quiz';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Navigate to activity detail
          try {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailScreen(
                  activity: activity,
                ),
              ),
            );
          } catch (e) {
            // Handle navigation error
            debugPrint('Navigation error: $e');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getActivityIcon(type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] ?? 'Untitled Activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity['description'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(
                    context,
                    Icons.star,
                    '$lpReward LP',
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    context,
                    Icons.signal_cellular_alt,
                    difficulty.toUpperCase(),
                    _getDifficultyColor(difficulty),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getActivityIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'math':
        icon = Icons.calculate;
        color = Colors.blue;
        break;
      case 'word':
        icon = Icons.font_download;
        color = Colors.green;
        break;
      case 'puzzle':
        icon = Icons.extension;
        color = Colors.orange;
        break;
      default:
        icon = Icons.quiz;
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Catalog'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rewards')
            .where('isAvailable', isEqualTo: true)
            .orderBy('lpCost')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rewards = snapshot.data?.docs ?? [];

          if (rewards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rewards available yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index].data() as Map<String, dynamic>;
              return _RewardCard(reward: reward, rewardId: rewards[index].id);
            },
          );
        },
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final String rewardId;

  const _RewardCard({required this.reward, required this.rewardId});

  @override
  Widget build(BuildContext context) {
    final lpCost = (reward['lpCost'] as num?)?.toDouble() ?? 0.0;
    final stock = (reward['stock'] as num?)?.toInt() ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRewardDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.card_giftcard,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward['title'] ?? 'Reward',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lpCost.toInt()} LP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (stock > 0)
                    Text(
                      '$stock left',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    )
                  else
                    Text(
                      'Out of stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RewardDetailsSheet(reward: reward, rewardId: rewardId),
    );
  }
}

class _RewardDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> reward;
  final String rewardId;

  const _RewardDetailsSheet({required this.reward, required this.rewardId});

  @override
  Widget build(BuildContext context) {
    final lpCost = (reward['lpCost'] as num?)?.toDouble() ?? 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                reward['title'] ?? 'Reward',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                reward['description'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.monetization_on,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${lpCost.toInt()} LP',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              FutureBuilder<double>(
                future: LPService.getUserLPBalance(),
                builder: (context, snapshot) {
                  final balance = snapshot.data ?? 0.0;
                  final canAfford = balance >= lpCost;

                  return FilledButton(
                    onPressed: canAfford ? () => _redeemReward(context) : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(canAfford
                        ? 'Redeem Now'
                        : 'Insufficient LP (${balance.toInt()} / ${lpCost.toInt()})'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _redeemReward(BuildContext context) async {
    try {
      // TODO: Implement reward redemption logic
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward redeemed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go('/auth');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: UserService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Failed to load profile'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, user, profile),
                const SizedBox(height: 24),
                _buildLPSection(context, profile),
                const SizedBox(height: 16),
                _buildStatsSection(context, profile),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 16),
                _buildEarningsHistory(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user, Map<String, dynamic> profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: user?.photoURL != null
                  ? ClipOval(child: Image.network(user!.photoURL!))
                  : Text(
                      (profile['displayName'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              profile['displayName'] ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLPSection(BuildContext context, Map<String, dynamic> profile) {
    final lpBalance = (profile['lpBalance'] as num?)?.toDouble() ?? 0.0;
    final totalEarned = (profile['totalLPEarned'] as num?)?.toDouble() ?? 0.0;
    final totalSpent = (profile['totalLPSpent'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLPCard(
                    context,
                    'Current',
                    lpBalance,
                    Icons.monetization_on,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLPCard(
                    context,
                    'Earned',
                    totalEarned,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLPCard(
                    context,
                    'Spent',
                    totalSpent,
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLPCard(BuildContext context, String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toInt().toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> profile) {
    final stats = profile['stats'] as Map<String, dynamic>? ?? {};
    final level = (profile['level'] as num?)?.toInt() ?? 1;
    final streakDays = (profile['streakDays'] as num?)?.toInt() ?? 0;
    final completedActivities = (profile['completedActivities'] as num?)?.toInt() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    label: 'Level',
                    value: level.toString(),
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: '$streakDays days',
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: completedActivities.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star,
                    label: 'Avg Score',
                    value: '${((stats['averageScore'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Withdrawal Requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to withdrawals
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Activity History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to history
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to security settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsHistory(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Earnings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lp_events')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No recent earnings');
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final source = data['source'] as String? ?? 'Unknown';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: amount > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        child: Icon(
                          amount > 0 ? Icons.add : Icons.remove,
                          color: amount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(source),
                      subtitle: timestamp != null
                          ? Text(_formatDate(timestamp))
                          : null,
                      trailing: Text(
                        '${amount > 0 ? '+' : ''}${amount.toInt()} LP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: amount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
