import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String type;
  final String subType;
  final String difficulty;
  final String ageGroup;
  final ActivityContent content;
  final DateTime validFrom;
  final DateTime validTo;
  final bool active;
  final String createdBy;
  final String? moderatedBy;
  final DateTime? approvedAt;

  Activity({
    required this.id,
    required this.type,
    required this.subType,
    required this.difficulty,
    required this.ageGroup,
    required this.content,
    required this.validFrom,
    required this.validTo,
    required this.active,
    required this.createdBy,
    this.moderatedBy,
    this.approvedAt,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      type: data['type'] ?? '',
      subType: data['subType'] ?? '',
      difficulty: data['difficulty'] ?? 'easy',
      ageGroup: data['ageGroup'] ?? 'all',
      content: ActivityContent.fromMap(data['content'] ?? {}),
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      active: data['active'] ?? false,
      createdBy: data['createdBy'] ?? '',
      moderatedBy: data['moderatedBy'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'subType': subType,
      'difficulty': difficulty,
      'ageGroup': ageGroup,
      'content': content.toMap(),
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': Timestamp.fromDate(validTo),
      'active': active,
      'createdBy': createdBy,
      'moderatedBy': moderatedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}

class ActivityContent {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final Map<String, dynamic>? metadata;
  final String? explanation;
  final Map<String, String>? hints;

  ActivityContent({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.metadata,
    this.explanation,
    this.hints,
  });

  factory ActivityContent.fromMap(Map<String, dynamic> map) {
    return ActivityContent(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      metadata: map['metadata'],
      explanation: map['explanation'],
      hints:
          map['hints'] != null ? Map<String, String>.from(map['hints']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'metadata': metadata,
      'explanation': explanation,
      'hints': hints,
    };
  }
}

class UserActivityState {
  final String userId;
  final Map<String, ActivityLock> locks;
  final ActivityAnswer? lastAnswered;
  final ActivityStreak streaks;
  final ActivityPerformance performance;

  UserActivityState({
    required this.userId,
    required this.locks,
    this.lastAnswered,
    required this.streaks,
    required this.performance,
  });

  factory UserActivityState.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserActivityState(
      userId: doc.id,
      locks: (data['locks'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ActivityLock.fromMap(value)),
          ) ??
          {},
      lastAnswered: data['lastAnswered'] != null
          ? ActivityAnswer.fromMap(data['lastAnswered'])
          : null,
      streaks: ActivityStreak.fromMap(data['streaks'] ?? {}),
      performance: ActivityPerformance.fromMap(data['performance'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'locks': locks.map((key, value) => MapEntry(key, value.toMap())),
      'lastAnswered': lastAnswered?.toMap(),
      'streaks': streaks.toMap(),
      'performance': performance.toMap(),
    };
  }
}

class ActivityLock {
  final DateTime until;

  ActivityLock({required this.until});

  factory ActivityLock.fromMap(Map<String, dynamic> map) {
    return ActivityLock(
      until: (map['until'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'until': Timestamp.fromDate(until),
    };
  }

  bool get isLocked => DateTime.now().isBefore(until);
}

class ActivityAnswer {
  final String activityId;
  final bool correct;
  final DateTime at;
  final int timeTaken;

  ActivityAnswer({
    required this.activityId,
    required this.correct,
    required this.at,
    required this.timeTaken,
  });

  factory ActivityAnswer.fromMap(Map<String, dynamic> map) {
    return ActivityAnswer(
      activityId: map['activityId'] ?? '',
      correct: map['correct'] ?? false,
      at: (map['at'] as Timestamp).toDate(),
      timeTaken: map['timeTaken'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'correct': correct,
      'at': Timestamp.fromDate(at),
      'timeTaken': timeTaken,
    };
  }
}

class ActivityStreak {
  final int current;
  final int longest;
  final DateTime? lastStreakDate;

  ActivityStreak({
    required this.current,
    required this.longest,
    this.lastStreakDate,
  });

  factory ActivityStreak.fromMap(Map<String, dynamic> map) {
    return ActivityStreak(
      current: map['current'] ?? 0,
      longest: map['longest'] ?? 0,
      lastStreakDate: map['lastStreakDate'] != null
          ? (map['lastStreakDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current': current,
      'longest': longest,
      'lastStreakDate':
          lastStreakDate != null ? Timestamp.fromDate(lastStreakDate!) : null,
    };
  }
}

class ActivityPerformance {
  final double accuracy;
  final double averageTime;
  final double improvementRate;

  ActivityPerformance({
    required this.accuracy,
    required this.averageTime,
    required this.improvementRate,
  });

  factory ActivityPerformance.fromMap(Map<String, dynamic> map) {
    return ActivityPerformance(
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      averageTime: (map['averageTime'] ?? 0.0).toDouble(),
      improvementRate: (map['improvementRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'averageTime': averageTime,
      'improvementRate': improvementRate,
    };
  }
}
