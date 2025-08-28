enum ActivityType { math, word, puzzle }

enum Difficulty { easy, medium, hard }

class Activity {
  final String id;
  final ActivityType type;
  final String subType;
  final Difficulty difficulty;
  final Map<String, dynamic> content;

  Activity({
    required this.id,
    required this.type,
    required this.subType,
    required this.difficulty,
    required this.content,
  });
}
