import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/activity_service.dart';
import 'activity_detail_screen.dart';

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
                _buildAvailableActivities(),
                _buildInProgressActivities(),
                _buildCompletedActivities(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecommendedActivities(),
        child: const Icon(Icons.lightbulb),
        tooltip: 'Get Recommendations',
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Categories')),
                DropdownMenuItem(value: 'math', child: Text('Mathematics')),
                DropdownMenuItem(value: 'science', child: Text('Science')),
                DropdownMenuItem(value: 'language', child: Text('Language')),
                DropdownMenuItem(value: 'history', child: Text('History')),
                DropdownMenuItem(value: 'coding', child: Text('Programming')),
                DropdownMenuItem(value: 'art', child: Text('Art & Design')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'all';
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Levels')),
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(
                    value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value ?? 'all';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableActivities() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredActivities('available'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading activities: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No activities found'),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or check back later for new activities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _ActivityCard(
              activity: activity,
              onTap: () => _startActivity(activity),
              actionButton: ElevatedButton.icon(
                onPressed: () => _startActivity(activity),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInProgressActivities() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredActivities('in_progress'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No activities in progress'),
                SizedBox(height: 8),
                Text(
                  'Start an activity from the Available tab to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final progress = (activity['progress'] ?? 0.0) as double;

            return _ActivityCard(
              activity: activity,
              onTap: () => _resumeActivity(activity),
              progressIndicator: LinearProgressIndicator(
                value: progress / 100.0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 80
                      ? Colors.green
                      : progress > 50
                          ? Colors.orange
                          : Colors.blue,
                ),
              ),
              actionButton: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _resumeActivity(activity),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continue'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _abandonActivity(activity),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedActivities() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredActivities('completed'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No completed activities'),
                SizedBox(height: 8),
                Text(
                  'Complete activities to see your achievements here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final score = activity['finalScore'] ?? 0;
            final lpEarned = activity['lpEarned'] ?? 0.0;

            return _ActivityCard(
              activity: activity,
              onTap: () => _viewActivityResults(activity),
              completionInfo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score: $score%',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('LP Earned: ${lpEarned.toStringAsFixed(1)}'),
                  if (activity['completedAt'] != null)
                    Text(
                      'Completed: ${_formatDate(activity['completedAt'])}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
              actionButton: OutlinedButton.icon(
                onPressed: () => _viewActivityResults(activity),
                icon: const Icon(Icons.visibility),
                label: const Text('View Results'),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFilteredActivities(
      String status) async {
    try {
      // Ensure sample activities exist in database
      await _ensureSampleActivitiesExist();

      if (status == 'available') {
        return await _getAvailableActivities();
      } else if (status == 'in_progress') {
        return await _getInProgressActivities();
      } else if (status == 'completed') {
        return await _getCompletedActivities();
      }

      return [];
    } catch (e) {
      print('Error getting filtered activities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableActivities() async {
    // Get all active activities
    Query query = FirebaseFirestore.instance
        .collection('activities')
        .where('isActive', isEqualTo: true);

    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_selectedDifficulty != 'all') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();

    final activities = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['status'] = 'available';
      return data;
    }).toList();

    return activities;
  }

  Future<List<Map<String, dynamic>>> _getInProgressActivities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('user_activities')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'in_progress')
        .orderBy('lastAccessedAt', descending: true)
        .get();

    final activities = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Apply filters
      final matchesCategory = _selectedCategory == 'all' ||
          data['activityCategory'] == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'all' ||
          data['difficulty'] == _selectedDifficulty;

      if (matchesCategory && matchesDifficulty) {
        data['id'] = doc.id;
        data['status'] = 'in_progress';
        activities.add(data);
      }
    }

    return activities;
  }

  Future<List<Map<String, dynamic>>> _getCompletedActivities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('user_activities')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .get();

    final activities = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Apply filters
      final matchesCategory = _selectedCategory == 'all' ||
          data['activityCategory'] == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'all' ||
          data['difficulty'] == _selectedDifficulty;

      if (matchesCategory && matchesDifficulty) {
        data['id'] = doc.id;
        data['status'] = 'completed';
        activities.add(data);
      }
    }

    return activities;
  }

  Future<void> _ensureSampleActivitiesExist() async {
    try {
      // Check if activities already exist
      final existingActivities = await FirebaseFirestore.instance
          .collection('activities')
          .limit(1)
          .get();

      if (existingActivities.docs.isNotEmpty) {
        return; // Activities already exist
      }

      // Create sample activities
      final batch = FirebaseFirestore.instance.batch();
      final activitiesRef = FirebaseFirestore.instance.collection('activities');

      final sampleActivities = [
        {
          'title': 'Basic Algebra',
          'description':
              'Learn fundamental algebraic concepts and solve linear equations. Master variables, expressions, and basic equation solving.',
          'category': 'math',
          'difficulty': 'beginner',
          'duration': 30,
          'durationUnit': 'minutes',
          'lpReward': 250,
          'totalSteps': 5,
          'type': 'interactive_lesson',
          'isActive': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': ['algebra', 'equations', 'math'],
          'prerequisites': [],
          'ageRange': {'min': 12, 'max': 18},
        },
        {
          'title': 'Introduction to Python',
          'description':
              'Start your coding journey with Python programming basics. Learn variables, loops, and functions.',
          'category': 'coding',
          'difficulty': 'beginner',
          'duration': 45,
          'durationUnit': 'minutes',
          'lpReward': 400,
          'totalSteps': 8,
          'type': 'coding_tutorial',
          'isActive': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1526379095098-d400fd0bf935?w=400',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': ['python', 'programming', 'beginner'],
          'prerequisites': [],
          'ageRange': {'min': 14, 'max': 25},
        },
        {
          'title': 'World War II History',
          'description':
              'Explore the major events and impacts of World War II. Understand causes, key battles, and consequences.',
          'category': 'history',
          'difficulty': 'intermediate',
          'duration': 60,
          'durationUnit': 'minutes',
          'lpReward': 500,
          'totalSteps': 6,
          'type': 'educational_content',
          'isActive': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1585944150965-2d2949de5bfb?w=400',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': ['WWII', 'history', 'warfare'],
          'prerequisites': [],
          'ageRange': {'min': 15, 'max': 22},
        },
        {
          'title': 'Creative Writing Basics',
          'description':
              'Develop your storytelling skills with creative writing fundamentals. Learn character development and plot structure.',
          'category': 'language',
          'difficulty': 'beginner',
          'duration': 40,
          'durationUnit': 'minutes',
          'lpReward': 350,
          'totalSteps': 7,
          'type': 'writing_workshop',
          'isActive': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': ['writing', 'creativity', 'language'],
          'prerequisites': [],
          'ageRange': {'min': 12, 'max': 20},
        },
        {
          'title': 'Basic Chemistry',
          'description':
              'Discover the fascinating world of chemistry. Learn about atoms, molecules, and chemical reactions.',
          'category': 'science',
          'difficulty': 'intermediate',
          'duration': 50,
          'durationUnit': 'minutes',
          'lpReward': 450,
          'totalSteps': 6,
          'type': 'science_lab',
          'isActive': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=400',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': ['chemistry', 'science', 'experiments'],
          'prerequisites': [],
          'ageRange': {'min': 14, 'max': 18},
        },
        {
          'title': 'Digital Art Fundamentals',
          'description':
              'Learn the basics of digital art creation. Master color theory, composition, and digital tools.',
          'category': 'art',
          'difficulty': 'beginner',
          'duration': 55,
          'durationUnit': 'minutes',
          'lpReward': 380,
          'totalSteps': 8,
          'type': 'art_tutorial',
          'isActive': true,
          'imageUrl':
              'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'tags': ['digital art', 'design', 'creativity'],
          'prerequisites': [],
          'ageRange': {'min': 13, 'max': 25},
        },
      ];

      for (int i = 0; i < sampleActivities.length; i++) {
        final docRef = activitiesRef.doc();
        batch.set(docRef, sampleActivities[i]);
      }

      await batch.commit();
      print('Sample activities created successfully');
    } catch (e) {
      print('Error creating sample activities: $e');
    }
  }

  void _startActivity(Map<String, dynamic> activity) async {
    try {
      final userActivityId = await ActivityService.startActivity(
        activityId: activity['id'],
        initialData: {
          'startedAt': DateTime.now().toIso8601String(),
          'title': activity['title'],
        },
      );

      if (mounted && userActivityId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started "${activity['title']}"'),
            action: SnackBarAction(
              label: 'Continue',
              onPressed: () => _resumeActivity(activity),
            ),
          ),
        );
        setState(() {}); // Refresh the UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting activity: $e')),
        );
      }
    }
  }

  void _resumeActivity(Map<String, dynamic> activity) {
    // Navigate to activity detail/completion screen
    // This would be implemented based on your activity structure
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resume "${activity['title']}"'),
        content: Text('This will open the activity continuation screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityDetailScreen(
                    activity: activity,
                  ),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _abandonActivity(Map<String, dynamic> activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Activity'),
        content: Text(
            'Are you sure you want to stop "${activity['title']}"? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // For this we need the userActivityId, not just activityId
        // In a real implementation, we'd get this from the activity data
        final userActivityId = activity['userActivityId'] ?? activity['id'];

        final success = await ActivityService.abandonActivity(userActivityId);

        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stopped "${activity['title']}"')),
          );
          setState(() {}); // Refresh the UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping activity: $e')),
          );
        }
      }
    }
  }

  void _viewActivityResults(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Results: ${activity['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: ${activity['finalScore']}%'),
            Text(
                'LP Earned: ${activity['lpEarned']?.toStringAsFixed(1) ?? '0.0'}'),
            if (activity['completedAt'] != null)
              Text('Completed: ${_formatDate(activity['completedAt'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRecommendedActivities() async {
    try {
      final recommendations = await ActivityService.getRecommendedActivities(
        limit: 5,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Recommended for You'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final activity = recommendations[index];
                  return ListTile(
                    title: Text(activity['title'] ?? 'Unknown Activity'),
                    subtitle: Text(activity['description'] ?? ''),
                    trailing: Text('${activity['lpReward'] ?? 0} LP'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _startActivity(activity);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Map<String, dynamic> activity) {
    final duration = activity['duration'];
    final unit = activity['durationUnit'] ?? 'minutes';

    if (duration == null) return '';

    if (unit == 'minutes') {
      if (duration >= 60) {
        final hours = duration ~/ 60;
        final mins = duration % 60;
        if (mins == 0) {
          return '${hours}h';
        } else {
          return '${hours}h ${mins}m';
        }
      } else {
        return '${duration}m';
      }
    }

    return '$duration $unit';
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final Widget? actionButton;
  final Widget? progressIndicator;
  final Widget? completionInfo;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
    this.actionButton,
    this.progressIndicator,
    this.completionInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity['title'] ?? 'Unknown Activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(activity['difficulty']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity['difficulty']?.toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity['description'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  //TODO: CREATE THIS FUNCTION _formatDuration(activity)
                  //Text(_formatDuration(activity)),
                  const SizedBox(width: 16),
                  Icon(Icons.monetization_on,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${activity['lpReward'] ?? 0} LP'),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(activity['category']?.toUpperCase() ?? ''),
                ],
              ),
              if (progressIndicator != null) ...[
                const SizedBox(height: 12),
                progressIndicator!,
                const SizedBox(height: 4),
                Text(
                    '${activity['progress']?.toStringAsFixed(0) ?? 0}% complete'),
              ],
              if (completionInfo != null) ...[
                const SizedBox(height: 12),
                completionInfo!,
              ],
              if (actionButton != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButton!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
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
