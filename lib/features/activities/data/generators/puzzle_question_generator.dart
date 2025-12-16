import 'dart:math';

import 'package:learnify_rewards/features/activities/domain/entities/question.dart';

class PuzzleQuestionGenerator {
  static final Random _random = Random();

  static Question generateQuestion({
    required QuestionDifficulty difficulty,
    PuzzleType? puzzleType,
  }) {
    final selectedType = puzzleType ?? _getRandomPuzzleType();

    switch (selectedType) {
      case PuzzleType.logic:
        return _generateLogicPuzzle(difficulty);
      case PuzzleType.pattern:
        return _generatePatternPuzzle(difficulty);
      case PuzzleType.sequence:
        return _generateSequencePuzzle(difficulty);
      case PuzzleType.riddle:
        return _generateRiddle(difficulty);
      case PuzzleType.visual:
        return _generateVisualPuzzle(difficulty);
    }
  }

  static PuzzleType _getRandomPuzzleType() {
    return PuzzleType.values[_random.nextInt(PuzzleType.values.length)];
  }

  static Question _generateLogicPuzzle(QuestionDifficulty difficulty) {
    final logicPuzzles = _getLogicPuzzles(difficulty);
    final selectedPuzzle = logicPuzzles[_random.nextInt(logicPuzzles.length)];

    return Question(
      id: 'puzzle_logic_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: difficulty,
      questionText: selectedPuzzle['question']!,
      options: selectedPuzzle['options']!.split('|'),
      correctAnswer: selectedPuzzle['correct']!,
      timeLimit: _getTimeLimit(difficulty),
      lpReward: _getLpReward(difficulty),
      metadata: {
        'puzzleType': 'logic',
        'reasoning': selectedPuzzle['reasoning'],
      },
    );
  }

  static Question _generatePatternPuzzle(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return _generateNumberPattern();
      case QuestionDifficulty.medium:
        return _generateLetterPattern();
      case QuestionDifficulty.hard:
        return _generateComplexPattern();
    }
  }

  static Question _generateNumberPattern() {
    final patterns = [
      // Arithmetic sequence
      () {
        final start = _random.nextInt(10) + 1;
        final diff = _random.nextInt(5) + 2;
        final sequence = [
          start,
          start + diff,
          start + 2 * diff,
          start + 3 * diff
        ];
        final next = start + 4 * diff;
        return {
          'sequence': sequence,
          'answer': next,
          'type': 'arithmetic',
        };
      },
      // Multiplication pattern
      () {
        final start = _random.nextInt(3) + 2;
        final multiplier = _random.nextInt(3) + 2;
        final sequence = [
          start,
          start * multiplier,
          start * multiplier * multiplier
        ];
        final next = start * multiplier * multiplier * multiplier;
        return {
          'sequence': sequence,
          'answer': next,
          'type': 'multiplication',
        };
      },
    ];

    final patternGen = patterns[_random.nextInt(patterns.length)];
    final pattern = patternGen();
    final sequence = pattern['sequence'] as List<int>;
    final answer = pattern['answer'] as int;

    final options = _generateNumberOptions(answer, 4);

    return Question(
      id: 'puzzle_pattern_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: QuestionDifficulty.easy,
      questionText: 'What comes next in the pattern: ${sequence.join(', ')}, ?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: 45,
      lpReward: 15,
      metadata: {
        'puzzleType': 'pattern',
        'patternType': pattern['type'],
        'sequence': sequence,
      },
    );
  }

  static Question _generateLetterPattern() {
    final patterns = [
      // Alphabetical sequence
      () {
        final start = _random.nextInt(20); // A=0, B=1, etc.
        const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        final skip = _random.nextInt(3) + 1;
        final sequence = [
          alphabet[start],
          alphabet[(start + skip) % 26],
          alphabet[(start + 2 * skip) % 26],
          alphabet[(start + 3 * skip) % 26],
        ];
        final next = alphabet[(start + 4 * skip) % 26];
        return {
          'sequence': sequence,
          'answer': next,
        };
      },
    ];

    final patternGen = patterns[_random.nextInt(patterns.length)];
    final pattern = patternGen();
    final sequence = pattern['sequence'] as List<String>;
    final answer = pattern['answer'] as String;

    final options = _generateLetterOptions(answer, 4);

    return Question(
      id: 'puzzle_letter_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: QuestionDifficulty.medium,
      questionText: 'What comes next in the pattern: ${sequence.join(', ')}, ?',
      options: options,
      correctAnswer: answer,
      timeLimit: 40,
      lpReward: 20,
      metadata: {
        'puzzleType': 'pattern',
        'patternType': 'alphabetical',
        'sequence': sequence,
      },
    );
  }

  static Question _generateComplexPattern() {
    final patterns = [
      // Fibonacci-like
      () {
        final a = _random.nextInt(5) + 1;
        final b = _random.nextInt(5) + 1;
        final sequence = [a, b, a + b, a + 2 * b, 2 * a + 3 * b];
        final next = 3 * a + 5 * b;
        return {
          'sequence': sequence,
          'answer': next,
          'type': 'fibonacci',
        };
      },
      // Square sequence
      () {
        final start = _random.nextInt(3) + 2;
        final sequence = [
          start * start,
          (start + 1) * (start + 1),
          (start + 2) * (start + 2)
        ];
        final next = (start + 3) * (start + 3);
        return {
          'sequence': sequence,
          'answer': next,
          'type': 'squares',
        };
      },
    ];

    final patternGen = patterns[_random.nextInt(patterns.length)];
    final pattern = patternGen();
    final sequence = pattern['sequence'] as List<int>;
    final answer = pattern['answer'] as int;

    final options = _generateNumberOptions(answer, 4);

    return Question(
      id: 'puzzle_complex_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: QuestionDifficulty.hard,
      questionText: 'What comes next in the pattern: ${sequence.join(', ')}, ?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: 60,
      lpReward: 30,
      metadata: {
        'puzzleType': 'pattern',
        'patternType': pattern['type'],
        'sequence': sequence,
      },
    );
  }

  static Question _generateSequencePuzzle(QuestionDifficulty difficulty) {
    final sequences = _getSequencePuzzles(difficulty);
    final selectedSequence = sequences[_random.nextInt(sequences.length)];

    return Question(
      id: 'puzzle_seq_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: difficulty,
      questionText: selectedSequence['question']!,
      options: selectedSequence['options']!.split('|'),
      correctAnswer: selectedSequence['correct']!,
      timeLimit: _getTimeLimit(difficulty),
      lpReward: _getLpReward(difficulty),
      metadata: {
        'puzzleType': 'sequence',
        'sequenceType': selectedSequence['type'],
      },
    );
  }

  static Question _generateRiddle(QuestionDifficulty difficulty) {
    final riddles = _getRiddles(difficulty);
    final selectedRiddle = riddles[_random.nextInt(riddles.length)];

    return Question(
      id: 'puzzle_riddle_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: difficulty,
      questionText: selectedRiddle['question']!,
      options: selectedRiddle['options']!.split('|'),
      correctAnswer: selectedRiddle['correct']!,
      timeLimit: _getTimeLimit(difficulty) + 20, // Extra time for thinking
      lpReward: _getLpReward(difficulty) + 5, // Bonus for riddles
      metadata: {
        'puzzleType': 'riddle',
        'category': selectedRiddle['category'],
      },
    );
  }

  static Question _generateVisualPuzzle(QuestionDifficulty difficulty) {
    final visualPuzzles = _getVisualPuzzles(difficulty);
    final selectedPuzzle = visualPuzzles[_random.nextInt(visualPuzzles.length)];

    return Question(
      id: 'puzzle_visual_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.puzzle,
      difficulty: difficulty,
      questionText: selectedPuzzle['question']!,
      options: selectedPuzzle['options']!.split('|'),
      correctAnswer: selectedPuzzle['correct']!,
      timeLimit: _getTimeLimit(difficulty) + 10,
      lpReward: _getLpReward(difficulty),
      metadata: {
        'puzzleType': 'visual',
        'visualType': selectedPuzzle['type'],
      },
    );
  }

  static List<String> _generateNumberOptions(int correct, int count) {
    final Set<String> options = {correct.toString()};

    while (options.length < count) {
      int wrongAnswer;
      if (correct < 20) {
        wrongAnswer = _random.nextInt(40);
      } else if (correct < 100) {
        wrongAnswer = correct + (_random.nextInt(21) - 10);
      } else {
        wrongAnswer = correct + (_random.nextInt(101) - 50);
      }

      if (wrongAnswer != correct && wrongAnswer > 0) {
        options.add(wrongAnswer.toString());
      }
    }

    final List<String> shuffledOptions = options.toList();
    shuffledOptions.shuffle(_random);
    return shuffledOptions;
  }

  static List<String> _generateLetterOptions(String correct, int count) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Set<String> options = {correct};

    while (options.length < count) {
      final randomLetter = alphabet[_random.nextInt(alphabet.length)];
      if (randomLetter != correct) {
        options.add(randomLetter);
      }
    }

    final List<String> shuffledOptions = options.toList();
    shuffledOptions.shuffle(_random);
    return shuffledOptions;
  }

  static List<Map<String, String>> _getLogicPuzzles(
      QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return [
          {
            'question':
                'If all cats are animals, and Fluffy is a cat, what is Fluffy?',
            'options': 'An animal|A dog|A bird|A fish',
            'correct': 'An animal',
            'reasoning': 'syllogism',
          },
          {
            'question': 'Which one is different? Apple, Orange, Banana, Car',
            'options': 'Apple|Orange|Banana|Car',
            'correct': 'Car',
            'reasoning': 'categorization',
          },
        ];
      case QuestionDifficulty.medium:
        return [
          {
            'question':
                'If it takes 5 machines 5 minutes to make 5 widgets, how long would it take 100 machines to make 100 widgets?',
            'options': '5 minutes|100 minutes|500 minutes|1 minute',
            'correct': '5 minutes',
            'reasoning': 'proportional thinking',
          },
          {
            'question':
                'A man lives on the 20th floor. Every day he takes the elevator down to ground floor. When he comes back, he takes elevator to 10th floor and walks the rest, except on rainy days when he takes elevator all the way up. Why?',
            'options':
                'He likes exercise|He is short and cannot reach button 20|The elevator is broken|He is afraid of heights',
            'correct': 'He is short and cannot reach button 20',
            'reasoning': 'lateral thinking',
          },
        ];
      case QuestionDifficulty.hard:
        return [
          {
            'question':
                'You have 12 balls, one of which is slightly heavier or lighter. Using a balance scale only 3 times, how do you identify the odd ball?',
            'options':
                'Impossible|Use systematic elimination|Weigh them randomly|Use 4 weighings',
            'correct': 'Use systematic elimination',
            'reasoning': 'advanced logic',
          },
          {
            'question':
                'Three boxes: one contains only apples, one only oranges, one both. All labels are wrong. You can pick one fruit from one box. How do you correctly label all boxes?',
            'options':
                'Pick from the "both" box|Pick from any box randomly|Pick from "apples" box|Cannot be done',
            'correct': 'Pick from the "both" box',
            'reasoning': 'deductive reasoning',
          },
        ];
    }
  }

  static List<Map<String, String>> _getSequencePuzzles(
      QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return [
          {
            'question': 'Monday, Tuesday, Wednesday, ___',
            'options': 'Thursday|Friday|Saturday|Sunday',
            'correct': 'Thursday',
            'type': 'days',
          },
          {
            'question': 'January, February, March, ___',
            'options': 'April|May|June|July',
            'correct': 'April',
            'type': 'months',
          },
        ];
      case QuestionDifficulty.medium:
        return [
          {
            'question': 'Red, Orange, Yellow, Green, ___',
            'options': 'Blue|Purple|Pink|Brown',
            'correct': 'Blue',
            'type': 'rainbow colors',
          },
          {
            'question': 'First, Second, Third, ___',
            'options': 'Fourth|Fifth|Last|Next',
            'correct': 'Fourth',
            'type': 'ordinal numbers',
          },
        ];
      case QuestionDifficulty.hard:
        return [
          {
            'question': 'Mercury, Venus, Earth, Mars, ___',
            'options': 'Jupiter|Saturn|Uranus|Neptune',
            'correct': 'Jupiter',
            'type': 'planets',
          },
          {
            'question': 'Hydrogen, Helium, Lithium, ___',
            'options': 'Beryllium|Boron|Carbon|Nitrogen',
            'correct': 'Beryllium',
            'type': 'periodic table',
          },
        ];
    }
  }

  static List<Map<String, String>> _getRiddles(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return [
          {
            'question': 'What has hands but cannot clap?',
            'options': 'A clock|A statue|A robot|A tree',
            'correct': 'A clock',
            'category': 'object riddle',
          },
          {
            'question': 'What gets wet while drying?',
            'options': 'A towel|Hair|Clothes|A sponge',
            'correct': 'A towel',
            'category': 'paradox riddle',
          },
        ];
      case QuestionDifficulty.medium:
        return [
          {
            'question':
                'I have cities, but no houses. I have mountains, but no trees. I have water, but no fish. What am I?',
            'options': 'A map|A picture|A book|A dream',
            'correct': 'A map',
            'category': 'description riddle',
          },
          {
            'question':
                'The more you take, the more you leave behind. What am I?',
            'options': 'Footsteps|Memories|Time|Money',
            'correct': 'Footsteps',
            'category': 'paradox riddle',
          },
        ];
      case QuestionDifficulty.hard:
        return [
          {
            'question':
                'I am not alive, but I grow; I don\'t have lungs, but I need air; I don\'t have a mouth, but water kills me. What am I?',
            'options': 'Fire|Plant|Crystal|Sound',
            'correct': 'Fire',
            'category': 'complex riddle',
          },
          {
            'question':
                'What comes once in a minute, twice in a moment, but never in a thousand years?',
            'options': 'The letter M|Time|Sound|Light',
            'correct': 'The letter M',
            'category': 'wordplay riddle',
          },
        ];
    }
  }

  static List<Map<String, String>> _getVisualPuzzles(
      QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return [
          {
            'question':
                'How many triangles can you see in a Star of David (6-pointed star)?',
            'options': '2|6|8|13',
            'correct': '13',
            'type': 'counting shapes',
          },
          {
            'question':
                'If you fold a piece of paper in half 3 times and make one cut, how many holes will there be when unfolded?',
            'options': '8|4|6|2',
            'correct': '8',
            'type': 'spatial reasoning',
          },
        ];
      case QuestionDifficulty.medium:
        return [
          {
            'question': 'In a cube, how many edges meet at each vertex?',
            'options': '2|3|4|6',
            'correct': '3',
            'type': '3D geometry',
          },
          {
            'question':
                'If you look at a clock at 3:15, what is the angle between the hour and minute hands?',
            'options': '0°|7.5°|15°|90°',
            'correct': '7.5°',
            'type': 'clock angles',
          },
        ];
      case QuestionDifficulty.hard:
        return [
          {
            'question':
                'How many squares are in an 8x8 chessboard (including all sizes)?',
            'options': '64|204|208|240',
            'correct': '204',
            'type': 'complex counting',
          },
          {
            'question':
                'In how many ways can you arrange 4 different colored balls in a row?',
            'options': '12|16|24|32',
            'correct': '24',
            'type': 'permutations',
          },
        ];
    }
  }

  static int _getTimeLimit(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 45;
      case QuestionDifficulty.medium:
        return 60;
      case QuestionDifficulty.hard:
        return 90;
    }
  }

  static int _getLpReward(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 15;
      case QuestionDifficulty.medium:
        return 25;
      case QuestionDifficulty.hard:
        return 40;
    }
  }
}
