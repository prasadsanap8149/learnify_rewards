enum LifelineType {
  fiftyFifty,
  revealHint,
  extraTime,
}

class Lifeline {
  final LifelineType type;
  final String name;
  final String description;
  final String icon;
  final bool isUsed;

  const Lifeline({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    this.isUsed = false,
  });

  Lifeline copyWith({bool? isUsed}) {
    return Lifeline(
      type: type,
      name: name,
      description: description,
      icon: icon,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  static List<Lifeline> getDefaultLifelines() {
    return [
      const Lifeline(
        type: LifelineType.fiftyFifty,
        name: '50:50',
        description: 'Remove two wrong answers',
        icon: '🎯',
      ),
      const Lifeline(
        type: LifelineType.revealHint,
        name: 'Hint',
        description: 'Get a helpful hint',
        icon: '💡',
      ),
      const Lifeline(
        type: LifelineType.extraTime,
        name: 'Extra Time',
        description: 'Add 30 seconds to timer',
        icon: '⏰',
      ),
    ];
  }
}

class LifelineResult {
  final bool success;
  final String? message;
  final List<String>? modifiedOptions;
  final String? hint;
  final int? extraTimeSeconds;

  const LifelineResult({
    required this.success,
    this.message,
    this.modifiedOptions,
    this.hint,
    this.extraTimeSeconds,
  });
}

class LifelineService {
  static LifelineResult useFiftyFifty(
      List<String> options, String correctAnswer) {
    if (options.length < 4) {
      return const LifelineResult(
        success: false,
        message: 'Not enough options to use 50:50',
      );
    }

    final wrongOptions =
        options.where((option) => option != correctAnswer).toList();
    wrongOptions.shuffle();

    // Keep correct answer and one random wrong answer
    final modifiedOptions = [
      correctAnswer,
      wrongOptions.first,
    ];
    modifiedOptions.shuffle();

    return LifelineResult(
      success: true,
      message: 'Two wrong answers removed!',
      modifiedOptions: modifiedOptions,
    );
  }

  static LifelineResult getHint(
      Map<String, dynamic> questionMetadata, String questionText) {
    String hint = '';

    // Generate hints based on question type
    if (questionMetadata.containsKey('operation')) {
      final operation = questionMetadata['operation'];
      switch (operation) {
        case 'addition':
          hint = 'Remember: Addition means combining numbers together.';
          break;
        case 'subtraction':
          hint = 'Remember: Subtraction means taking away.';
          break;
        case 'multiplication':
          hint = 'Remember: Multiplication is repeated addition.';
          break;
        case 'division':
          hint = 'Remember: Division is sharing equally.';
          break;
        case 'square_root':
          hint =
              'Remember: Square root asks "what number times itself equals this?"';
          break;
      }
    } else if (questionMetadata.containsKey('gameType')) {
      final gameType = questionMetadata['gameType'];
      switch (gameType) {
        case 'synonyms':
          hint = 'Look for words with similar meanings.';
          break;
        case 'antonyms':
          hint = 'Look for words with opposite meanings.';
          break;
        case 'spelling':
          hint = 'Think about common spelling patterns and rules.';
          break;
        case 'vocabulary':
          hint = 'Consider the context and word roots.';
          break;
        case 'grammar':
          hint = 'Think about the grammatical rule being tested.';
          break;
      }
    } else if (questionMetadata.containsKey('puzzleType')) {
      final puzzleType = questionMetadata['puzzleType'];
      switch (puzzleType) {
        case 'logic':
          hint = 'Break down the problem step by step.';
          break;
        case 'pattern':
          hint = 'Look for what changes between each item in the sequence.';
          break;
        case 'sequence':
          hint = 'Think about the natural order or progression.';
          break;
        case 'riddle':
          hint = 'Think outside the box - there might be a play on words.';
          break;
        case 'visual':
          hint = 'Visualize the problem carefully and count systematically.';
          break;
      }
    }

    if (hint.isEmpty) {
      hint = 'Take your time and think through each option carefully.';
    }

    return LifelineResult(
      success: true,
      message: 'Here\'s a hint to help you!',
      hint: hint,
    );
  }

  static LifelineResult addExtraTime() {
    return const LifelineResult(
      success: true,
      message: '30 extra seconds added!',
      extraTimeSeconds: 30,
    );
  }
}
