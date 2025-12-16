import 'dart:math';
import 'package:learnify_rewards/features/activities/domain/entities/question.dart';

class MathQuestionGenerator {
  static final Random _random = Random();

  static Question generateQuestion({
    required QuestionDifficulty difficulty,
    MathOperation? operation,
  }) {
    final selectedOperation = operation ?? _getRandomOperation();

    switch (selectedOperation) {
      case MathOperation.addition:
        return _generateAddition(difficulty);
      case MathOperation.subtraction:
        return _generateSubtraction(difficulty);
      case MathOperation.multiplication:
        return _generateMultiplication(difficulty);
      case MathOperation.division:
        return _generateDivision(difficulty);
      case MathOperation.squareRoot:
        return _generateSquareRoot(difficulty);
      case MathOperation.mixed:
        return generateQuestion(
          difficulty: difficulty,
          operation: _getRandomOperation(excludeMixed: true),
        );
    }
  }

  static MathOperation _getRandomOperation({bool excludeMixed = false}) {
    final operations = MathOperation.values
        .where((op) => excludeMixed ? op != MathOperation.mixed : true)
        .toList();
    return operations[_random.nextInt(operations.length)];
  }

  static Question _generateAddition(QuestionDifficulty difficulty) {
    late int num1, num2, answer;
    late List<String> options;
    late int timeLimit, lpReward;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        num1 = _random.nextInt(20) + 1;
        num2 = _random.nextInt(20) + 1;
        timeLimit = 30;
        lpReward = 10;
        break;
      case QuestionDifficulty.medium:
        num1 = _random.nextInt(100) + 1;
        num2 = _random.nextInt(100) + 1;
        timeLimit = 25;
        lpReward = 15;
        break;
      case QuestionDifficulty.hard:
        num1 = _random.nextInt(500) + 1;
        num2 = _random.nextInt(500) + 1;
        timeLimit = 20;
        lpReward = 25;
        break;
    }

    answer = num1 + num2;
    options = _generateOptions(answer, 4);

    return Question(
      id: 'math_add_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.math,
      difficulty: difficulty,
      questionText: 'What is $num1 + $num2?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: timeLimit,
      lpReward: lpReward,
      metadata: {
        'operation': 'addition',
        'operand1': num1,
        'operand2': num2,
      },
    );
  }

  static Question _generateSubtraction(QuestionDifficulty difficulty) {
    late int num1, num2, answer;
    late List<String> options;
    late int timeLimit, lpReward;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        num1 = _random.nextInt(20) + 10; // Ensure positive result
        num2 = _random.nextInt(num1);
        timeLimit = 30;
        lpReward = 10;
        break;
      case QuestionDifficulty.medium:
        num1 = _random.nextInt(100) + 50;
        num2 = _random.nextInt(num1);
        timeLimit = 25;
        lpReward = 15;
        break;
      case QuestionDifficulty.hard:
        num1 = _random.nextInt(500) + 100;
        num2 = _random.nextInt(num1);
        timeLimit = 20;
        lpReward = 25;
        break;
    }

    answer = num1 - num2;
    options = _generateOptions(answer, 4);

    return Question(
      id: 'math_sub_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.math,
      difficulty: difficulty,
      questionText: 'What is $num1 - $num2?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: timeLimit,
      lpReward: lpReward,
      metadata: {
        'operation': 'subtraction',
        'operand1': num1,
        'operand2': num2,
      },
    );
  }

  static Question _generateMultiplication(QuestionDifficulty difficulty) {
    late int num1, num2, answer;
    late List<String> options;
    late int timeLimit, lpReward;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        num1 = _random.nextInt(10) + 1;
        num2 = _random.nextInt(10) + 1;
        timeLimit = 35;
        lpReward = 12;
        break;
      case QuestionDifficulty.medium:
        num1 = _random.nextInt(15) + 1;
        num2 = _random.nextInt(15) + 1;
        timeLimit = 30;
        lpReward = 18;
        break;
      case QuestionDifficulty.hard:
        num1 = _random.nextInt(25) + 1;
        num2 = _random.nextInt(25) + 1;
        timeLimit = 25;
        lpReward = 30;
        break;
    }

    answer = num1 * num2;
    options = _generateOptions(answer, 4);

    return Question(
      id: 'math_mul_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.math,
      difficulty: difficulty,
      questionText: 'What is $num1 × $num2?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: timeLimit,
      lpReward: lpReward,
      metadata: {
        'operation': 'multiplication',
        'operand1': num1,
        'operand2': num2,
      },
    );
  }

  static Question _generateDivision(QuestionDifficulty difficulty) {
    late int divisor, quotient, dividend, answer;
    late List<String> options;
    late int timeLimit, lpReward;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        divisor = _random.nextInt(10) + 2;
        quotient = _random.nextInt(10) + 1;
        timeLimit = 40;
        lpReward = 15;
        break;
      case QuestionDifficulty.medium:
        divisor = _random.nextInt(15) + 2;
        quotient = _random.nextInt(15) + 1;
        timeLimit = 35;
        lpReward = 20;
        break;
      case QuestionDifficulty.hard:
        divisor = _random.nextInt(25) + 2;
        quotient = _random.nextInt(25) + 1;
        timeLimit = 30;
        lpReward = 35;
        break;
    }

    dividend = divisor * quotient;
    answer = quotient;
    options = _generateOptions(answer, 4);

    return Question(
      id: 'math_div_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.math,
      difficulty: difficulty,
      questionText: 'What is $dividend ÷ $divisor?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: timeLimit,
      lpReward: lpReward,
      metadata: {
        'operation': 'division',
        'dividend': dividend,
        'divisor': divisor,
      },
    );
  }

  static Question _generateSquareRoot(QuestionDifficulty difficulty) {
    late int number, answer;
    late List<String> options;
    late int timeLimit, lpReward;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        answer = _random.nextInt(10) + 1;
        timeLimit = 45;
        lpReward = 20;
        break;
      case QuestionDifficulty.medium:
        answer = _random.nextInt(15) + 1;
        timeLimit = 40;
        lpReward = 25;
        break;
      case QuestionDifficulty.hard:
        answer = _random.nextInt(20) + 1;
        timeLimit = 35;
        lpReward = 40;
        break;
    }

    number = answer * answer;
    options = _generateOptions(answer, 4);

    return Question(
      id: 'math_sqrt_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.math,
      difficulty: difficulty,
      questionText: 'What is √$number?',
      options: options,
      correctAnswer: answer.toString(),
      timeLimit: timeLimit,
      lpReward: lpReward,
      metadata: {
        'operation': 'square_root',
        'number': number,
      },
    );
  }

  static List<String> _generateOptions(int correctAnswer, int count) {
    final Set<String> options = {correctAnswer.toString()};

    while (options.length < count) {
      int wrongAnswer;
      if (correctAnswer < 10) {
        wrongAnswer = _random.nextInt(20);
      } else if (correctAnswer < 100) {
        wrongAnswer = correctAnswer + (_random.nextInt(21) - 10);
      } else {
        wrongAnswer = correctAnswer + (_random.nextInt(101) - 50);
      }

      if (wrongAnswer != correctAnswer && wrongAnswer > 0) {
        options.add(wrongAnswer.toString());
      }
    }

    final List<String> shuffledOptions = options.toList();
    shuffledOptions.shuffle(_random);
    return shuffledOptions;
  }
}
