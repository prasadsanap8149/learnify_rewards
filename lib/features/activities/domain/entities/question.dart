class Question {
  final String id;
  final ActivityType type;
  final QuestionDifficulty difficulty;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int timeLimit; // in seconds
  final int lpReward;
  final Map<String, dynamic> metadata;

  const Question({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.timeLimit,
    required this.lpReward,
    this.metadata = const {},
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ActivityType.math,
      ),
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == map['difficulty'],
        orElse: () => QuestionDifficulty.easy,
      ),
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      timeLimit: map['timeLimit'] ?? 30,
      lpReward: map['lpReward'] ?? 10,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'timeLimit': timeLimit,
      'lpReward': lpReward,
      'metadata': metadata,
    };
  }
}

enum ActivityType {
  math,
  word,
  puzzle,
}

enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

enum MathOperation {
  addition,
  subtraction,
  multiplication,
  division,
  squareRoot,
  mixed,
}

enum WordGameType {
  synonyms,
  antonyms,
  spelling,
  vocabulary,
  grammar,
}

enum PuzzleType {
  logic,
  pattern,
  sequence,
  riddle,
  visual,
}
