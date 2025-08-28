import 'package:learnify_rewards/features/activities/domain/entities/activity.dart';

class ActivityModel extends Activity {
  ActivityModel({
    required String id,
    required ActivityType type,
    required String subType,
    required Difficulty difficulty,
    required Map<String, dynamic> content,
  }) : super(
          id: id,
          type: type,
          subType: subType,
          difficulty: difficulty,
          content: content,
        );

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      type: ActivityType.values
          .firstWhere((e) => e.toString() == 'ActivityType.${json['type']}'),
      subType: json['subType'],
      difficulty: Difficulty.values.firstWhere(
          (e) => e.toString() == 'Difficulty.${json['difficulty']}'),
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'subType': subType,
      'difficulty': difficulty.toString().split('.').last,
      'content': content,
    };
  }
}
