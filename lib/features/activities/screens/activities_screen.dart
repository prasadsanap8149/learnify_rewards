import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activities_provider.dart';
import '../../../core/config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/activity_model.dart';
import 'activity_details_screen.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDifficulty = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _loadActivities();
    }
  }

  void _loadActivities() {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    String activityType;
    switch (_tabController.index) {
      case 0:
        activityType = AppConfig.activityMath;
        break;
      case 1:
        activityType = AppConfig.activityWord;
        break;
      case 2:
        activityType = AppConfig.activityPuzzle;
        break;
      default:
        activityType = AppConfig.activityMath;
    }

    ref.read(activitiesNotifierProvider.notifier).loadActivities(
          type: activityType,
          ageGroup: user.ageGroup,
          difficulty: _selectedDifficulty == 'all' ? null : _selectedDifficulty,
        );
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(activitiesNotifierProvider);
    final userState = ref.watch(userActivityStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Math'),
            Tab(text: 'Word'),
            Tab(text: 'Puzzle'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Difficulty selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: 'easy',
                  label: Text('Easy'),
                ),
                ButtonSegment(
                  value: 'medium',
                  label: Text('Medium'),
                ),
                ButtonSegment(
                  value: 'hard',
                  label: Text('Hard'),
                ),
              ],
              selected: {_selectedDifficulty},
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                setState(() {
                  _selectedDifficulty = values.first;
                });
                _loadActivities();
              },
            ),
          ),

          // Activities list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(
                    activities, userState, AppConfig.activityMath),
                _buildActivityList(
                    activities, userState, AppConfig.activityWord),
                _buildActivityList(
                    activities, userState, AppConfig.activityPuzzle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(
    AsyncValue<List<Activity>> activities,
    AsyncValue<UserActivityState> userState,
    String type,
  ) {
    return activities.when(
      data: (activityList) {
        // Filter activities by type
        final filteredList = activityList.where((a) => a.type == type).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Text('No activities available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final activity = filteredList[index];
            final isLocked = userState.value?.locks[type]?.isLocked ?? false;

            return Card(
              child: ListTile(
                leading: _getActivityIcon(activity.type),
                title: Text(activity.content.question),
                subtitle: Text(
                  'Difficulty: ${activity.difficulty.toUpperCase()}',
                ),
                trailing: isLocked
                    ? const Icon(Icons.lock_clock, color: Colors.orange)
                    : const Icon(Icons.arrow_forward_ios),
                onTap: isLocked
                    ? () => _showLockedDialog(context)
                    : () => _startActivity(context, activity),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _getActivityIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case AppConfig.activityMath:
        iconData = Icons.calculate;
        color = Colors.blue;
        break;
      case AppConfig.activityWord:
        iconData = Icons.text_fields;
        color = Colors.green;
        break;
      case AppConfig.activityPuzzle:
        iconData = Icons.extension;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.help;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color),
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Locked'),
        content: const Text(
          'This activity is currently locked. Please wait for the cooldown period to end.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startActivity(BuildContext context, Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailsScreen(activity: activity),
      ),
    );
  }
}
