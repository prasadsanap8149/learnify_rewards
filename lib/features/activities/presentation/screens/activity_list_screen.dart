import 'package:flutter/material.dart';
import 'package:learnify_rewards/features/activities/data/repositories/activity_repository_impl.dart';
import 'package:learnify_rewards/features/activities/domain/entities/activity.dart';
import 'package:learnify_rewards/features/activities/domain/repositories/activity_repository.dart';
import 'package:learnify_rewards/shared/services/ad_service.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final ActivityRepository _activityRepository = ActivityRepositoryImpl();
  final AdService _adService = AdService();
  late Future<List<Activity>> _activities;

  @override
  void initState() {
    super.initState();
    _activities = _activityRepository.getActivities();
    _adService.loadInterstitialAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
      ),
      body: FutureBuilder<List<Activity>>(
        future: _activities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No activities found.'));
          }

          final activities = snapshot.data!;
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                title: Text(
                    '${activity.type.toString().split('.').last} - ${activity.subType}'),
                subtitle: Text(
                    'Difficulty: ${activity.difficulty.toString().split('.').last}'),
                onTap: () {
                  // In a real app, you would navigate to the activity details screen.
                  // After completing the activity, you might show an ad.
                  _adService.showInterstitialAd();
                },
              );
            },
          );
        },
      ),
    );
  }
}
