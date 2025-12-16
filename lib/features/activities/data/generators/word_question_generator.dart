import 'dart:math';
import 'package:learnify_rewards/features/activities/domain/entities/question.dart';

class WordQuestionGenerator {
  static final Random _random = Random();

  // Vocabulary database
  static const Map<String, List<Map<String, String>>> _vocabularyDatabase = {
    'easy': [
      {
        'word': 'happy',
        'synonym': 'joyful',
        'antonym': 'sad',
        'definition': 'feeling pleasure or contentment'
      },
      {
        'word': 'big',
        'synonym': 'large',
        'antonym': 'small',
        'definition': 'of great size or extent'
      },
      {
        'word': 'fast',
        'synonym': 'quick',
        'antonym': 'slow',
        'definition': 'moving at high speed'
      },
      {
        'word': 'bright',
        'synonym': 'brilliant',
        'antonym': 'dark',
        'definition': 'giving out much light'
      },
      {
        'word': 'hot',
        'synonym': 'warm',
        'antonym': 'cold',
        'definition': 'having high temperature'
      },
      {
        'word': 'easy',
        'synonym': 'simple',
        'antonym': 'difficult',
        'definition': 'not hard to do'
      },
      {
        'word': 'good',
        'synonym': 'excellent',
        'antonym': 'bad',
        'definition': 'of high quality'
      },
      {
        'word': 'new',
        'synonym': 'fresh',
        'antonym': 'old',
        'definition': 'recently made or created'
      },
      {
        'word': 'clean',
        'synonym': 'neat',
        'antonym': 'dirty',
        'definition': 'free from dirt'
      },
      {
        'word': 'strong',
        'synonym': 'powerful',
        'antonym': 'weak',
        'definition': 'having great force'
      },
    ],
    'medium': [
      {
        'word': 'abundant',
        'synonym': 'plentiful',
        'antonym': 'scarce',
        'definition': 'existing in large quantities'
      },
      {
        'word': 'curious',
        'synonym': 'inquisitive',
        'antonym': 'indifferent',
        'definition': 'eager to learn'
      },
      {
        'word': 'diligent',
        'synonym': 'hardworking',
        'antonym': 'lazy',
        'definition': 'showing effort and care'
      },
      {
        'word': 'elegant',
        'synonym': 'graceful',
        'antonym': 'clumsy',
        'definition': 'pleasing in appearance'
      },
      {
        'word': 'fierce',
        'synonym': 'aggressive',
        'antonym': 'gentle',
        'definition': 'having violent force'
      },
      {
        'word': 'genuine',
        'synonym': 'authentic',
        'antonym': 'fake',
        'definition': 'truly what it is said to be'
      },
      {
        'word': 'humble',
        'synonym': 'modest',
        'antonym': 'arrogant',
        'definition': 'having low estimate of importance'
      },
      {
        'word': 'immense',
        'synonym': 'enormous',
        'antonym': 'tiny',
        'definition': 'extremely large'
      },
      {
        'word': 'jovial',
        'synonym': 'cheerful',
        'antonym': 'gloomy',
        'definition': 'full of happiness'
      },
      {
        'word': 'keen',
        'synonym': 'eager',
        'antonym': 'reluctant',
        'definition': 'having sharp interest'
      },
    ],
    'hard': [
      {
        'word': 'ubiquitous',
        'synonym': 'omnipresent',
        'antonym': 'rare',
        'definition': 'present everywhere'
      },
      {
        'word': 'meticulous',
        'synonym': 'thorough',
        'antonym': 'careless',
        'definition': 'showing great attention to detail'
      },
      {
        'word': 'enigmatic',
        'synonym': 'mysterious',
        'antonym': 'obvious',
        'definition': 'difficult to interpret'
      },
      {
        'word': 'tenacious',
        'synonym': 'persistent',
        'antonym': 'yielding',
        'definition': 'holding firmly to something'
      },
      {
        'word': 'lucid',
        'synonym': 'clear',
        'antonym': 'confusing',
        'definition': 'easily understood'
      },
      {
        'word': 'arduous',
        'synonym': 'difficult',
        'antonym': 'effortless',
        'definition': 'involving much effort'
      },
      {
        'word': 'cogent',
        'synonym': 'convincing',
        'antonym': 'weak',
        'definition': 'clear and logical'
      },
      {
        'word': 'ephemeral',
        'synonym': 'temporary',
        'antonym': 'permanent',
        'definition': 'lasting for short time'
      },
      {
        'word': 'fastidious',
        'synonym': 'particular',
        'antonym': 'careless',
        'definition': 'very attentive to detail'
      },
      {
        'word': 'gregarious',
        'synonym': 'sociable',
        'antonym': 'solitary',
        'definition': 'fond of company'
      },
    ],
  };

  static const Map<String, List<Map<String, String>>> _spellingWords = {
    'easy': [
      {'word': 'because', 'difficulty': 'common misspelling'},
      {'word': 'friend', 'difficulty': 'ie combination'},
      {'word': 'school', 'difficulty': 'double letters'},
      {'word': 'tomorrow', 'difficulty': 'double letters'},
      {'word': 'necessary', 'difficulty': 'double letters'},
      {'word': 'beautiful', 'difficulty': 'vowel combinations'},
      {'word': 'different', 'difficulty': 'common word'},
      {'word': 'important', 'difficulty': 'common word'},
      {'word': 'through', 'difficulty': 'silent letters'},
      {'word': 'receive', 'difficulty': 'ie/ei rule'},
    ],
    'medium': [
      {'word': 'accommodate', 'difficulty': 'double letters'},
      {'word': 'embarrass', 'difficulty': 'double letters'},
      {'word': 'occurrence', 'difficulty': 'double letters'},
      {'word': 'privilege', 'difficulty': 'vowel patterns'},
      {'word': 'pronunciation', 'difficulty': 'common misspelling'},
      {'word': 'bureaucracy', 'difficulty': 'complex spelling'},
      {'word': 'calendar', 'difficulty': 'vowel patterns'},
      {'word': 'cemetery', 'difficulty': 'vowel patterns'},
      {'word': 'definitely', 'difficulty': 'common misspelling'},
      {'word': 'environment', 'difficulty': 'common misspelling'},
    ],
    'hard': [
      {'word': 'conscientious', 'difficulty': 'complex spelling'},
      {'word': 'entrepreneur', 'difficulty': 'foreign origin'},
      {'word': 'idiosyncrasy', 'difficulty': 'complex spelling'},
      {'word': 'onomatopoeia', 'difficulty': 'vowel combinations'},
      {'word': 'pharmaceutical', 'difficulty': 'technical term'},
      {'word': 'rhythm', 'difficulty': 'no vowels'},
      {'word': 'surveillance', 'difficulty': 'complex spelling'},
      {'word': 'vacuum', 'difficulty': 'double letters'},
      {'word': 'weird', 'difficulty': 'ei/ie exception'},
      {'word': 'yacht', 'difficulty': 'silent letters'},
    ],
  };

  static Question generateQuestion({
    required QuestionDifficulty difficulty,
    WordGameType? gameType,
  }) {
    final selectedType = gameType ?? _getRandomWordGameType();

    switch (selectedType) {
      case WordGameType.synonyms:
        return _generateSynonymQuestion(difficulty);
      case WordGameType.antonyms:
        return _generateAntonymQuestion(difficulty);
      case WordGameType.spelling:
        return _generateSpellingQuestion(difficulty);
      case WordGameType.vocabulary:
        return _generateVocabularyQuestion(difficulty);
      case WordGameType.grammar:
        return _generateGrammarQuestion(difficulty);
    }
  }

  static WordGameType _getRandomWordGameType() {
    return WordGameType.values[_random.nextInt(WordGameType.values.length)];
  }

  static Question _generateSynonymQuestion(QuestionDifficulty difficulty) {
    final difficultyKey = difficulty.toString().split('.').last;
    final words = _vocabularyDatabase[difficultyKey]!;
    final selectedWord = words[_random.nextInt(words.length)];

    final correctAnswer = selectedWord['synonym']!;
    final options = _generateWordOptions(correctAnswer, words, 'synonym');

    return Question(
      id: 'word_syn_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.word,
      difficulty: difficulty,
      questionText: 'What is a synonym for "${selectedWord['word']}"?',
      options: options,
      correctAnswer: correctAnswer,
      timeLimit: _getTimeLimit(difficulty),
      lpReward: _getLpReward(difficulty),
      metadata: {
        'gameType': 'synonyms',
        'word': selectedWord['word'],
        'definition': selectedWord['definition'],
      },
    );
  }

  static Question _generateAntonymQuestion(QuestionDifficulty difficulty) {
    final difficultyKey = difficulty.toString().split('.').last;
    final words = _vocabularyDatabase[difficultyKey]!;
    final selectedWord = words[_random.nextInt(words.length)];

    final correctAnswer = selectedWord['antonym']!;
    final options = _generateWordOptions(correctAnswer, words, 'antonym');

    return Question(
      id: 'word_ant_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.word,
      difficulty: difficulty,
      questionText: 'What is an antonym for "${selectedWord['word']}"?',
      options: options,
      correctAnswer: correctAnswer,
      timeLimit: _getTimeLimit(difficulty),
      lpReward: _getLpReward(difficulty),
      metadata: {
        'gameType': 'antonyms',
        'word': selectedWord['word'],
        'definition': selectedWord['definition'],
      },
    );
  }

  static Question _generateSpellingQuestion(QuestionDifficulty difficulty) {
    final difficultyKey = difficulty.toString().split('.').last;
    final words = _spellingWords[difficultyKey]!;
    final selectedWord = words[_random.nextInt(words.length)];

    final correctAnswer = selectedWord['word']!;
    final options = _generateSpellingOptions(correctAnswer);

    return Question(
      id: 'word_spell_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.word,
      difficulty: difficulty,
      questionText: 'Choose the correct spelling:',
      options: options,
      correctAnswer: correctAnswer,
      timeLimit: _getTimeLimit(difficulty) + 10, // Extra time for spelling
      lpReward: _getLpReward(difficulty) + 5, // Bonus for spelling
      metadata: {
        'gameType': 'spelling',
        'word': selectedWord['word'],
        'difficulty_note': selectedWord['difficulty'],
      },
    );
  }

  static Question _generateVocabularyQuestion(QuestionDifficulty difficulty) {
    final difficultyKey = difficulty.toString().split('.').last;
    final words = _vocabularyDatabase[difficultyKey]!;
    final selectedWord = words[_random.nextInt(words.length)];

    final correctAnswer = selectedWord['definition']!;
    final options = _generateDefinitionOptions(correctAnswer, words);

    return Question(
      id: 'word_vocab_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.word,
      difficulty: difficulty,
      questionText: 'What does "${selectedWord['word']}" mean?',
      options: options,
      correctAnswer: correctAnswer,
      timeLimit: _getTimeLimit(difficulty) + 15, // Extra time for reading
      lpReward: _getLpReward(difficulty),
      metadata: {
        'gameType': 'vocabulary',
        'word': selectedWord['word'],
      },
    );
  }

  static Question _generateGrammarQuestion(QuestionDifficulty difficulty) {
    final grammarQuestions = _getGrammarQuestions(difficulty);
    final selectedQuestion =
        grammarQuestions[_random.nextInt(grammarQuestions.length)];

    return Question(
      id: 'word_grammar_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.word,
      difficulty: difficulty,
      questionText: selectedQuestion['question']!,
      options: selectedQuestion['options']!.split('|'),
      correctAnswer: selectedQuestion['correct']!,
      timeLimit: _getTimeLimit(difficulty) + 10,
      lpReward: _getLpReward(difficulty),
      metadata: {
        'gameType': 'grammar',
        'rule': selectedQuestion['rule'],
      },
    );
  }

  static List<String> _generateWordOptions(
      String correct, List<Map<String, String>> words, String type) {
    final Set<String> options = {correct};

    while (options.length < 4) {
      final randomWord = words[_random.nextInt(words.length)];
      final option = randomWord[type];
      if (option != null && option != correct) {
        options.add(option);
      }
    }

    final List<String> shuffledOptions = options.toList();
    shuffledOptions.shuffle(_random);
    return shuffledOptions;
  }

  static List<String> _generateSpellingOptions(String correct) {
    final options = <String>[correct];

    // Generate common misspellings
    options.addAll(_generateMisspellings(correct).take(3));

    options.shuffle(_random);
    return options;
  }

  static List<String> _generateMisspellings(String word) {
    final misspellings = <String>[];

    // Double letter mistakes
    for (int i = 0; i < word.length - 1; i++) {
      if (word[i] == word[i + 1]) {
        misspellings.add(word.substring(0, i) + word.substring(i + 1));
      } else {
        misspellings
            .add(word.substring(0, i + 1) + word[i] + word.substring(i + 1));
      }
    }

    // Common vowel mistakes
    const vowelMistakes = {'e': 'a', 'i': 'e', 'a': 'e', 'o': 'a'};
    for (int i = 0; i < word.length; i++) {
      final replacement = vowelMistakes[word[i]];
      if (replacement != null) {
        misspellings
            .add(word.substring(0, i) + replacement + word.substring(i + 1));
      }
    }

    return misspellings.take(10).toList();
  }

  static List<String> _generateDefinitionOptions(
      String correct, List<Map<String, String>> words) {
    final Set<String> options = {correct};

    while (options.length < 4) {
      final randomWord = words[_random.nextInt(words.length)];
      final definition = randomWord['definition'];
      if (definition != null && definition != correct) {
        options.add(definition);
      }
    }

    final List<String> shuffledOptions = options.toList();
    shuffledOptions.shuffle(_random);
    return shuffledOptions;
  }

  static List<Map<String, String>> _getGrammarQuestions(
      QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return [
          {
            'question':
                'Choose the correct verb: "She ___ to school every day."',
            'options': 'goes|go|going|gone',
            'correct': 'goes',
            'rule': 'subject-verb agreement'
          },
          {
            'question': 'Which is the plural of "child"?',
            'options': 'childs|children|childes|child',
            'correct': 'children',
            'rule': 'irregular plurals'
          },
        ];
      case QuestionDifficulty.medium:
        return [
          {
            'question': 'Choose the correct form: "I have ___ there before."',
            'options': 'been|gone|went|go',
            'correct': 'been',
            'rule': 'perfect tense'
          },
          {
            'question': 'Which sentence uses the passive voice?',
            'options':
                'The book was read by John|John read the book|John is reading|John will read',
            'correct': 'The book was read by John',
            'rule': 'passive voice'
          },
        ];
      case QuestionDifficulty.hard:
        return [
          {
            'question':
                'Choose the correct subjunctive: "If I ___ you, I would study harder."',
            'options': 'was|were|am|be',
            'correct': 'were',
            'rule': 'subjunctive mood'
          },
          {
            'question':
                'Identify the gerund: "Swimming is excellent exercise."',
            'options': 'Swimming|is|excellent|exercise',
            'correct': 'Swimming',
            'rule': 'gerunds'
          },
        ];
    }
  }

  static int _getTimeLimit(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 30;
      case QuestionDifficulty.medium:
        return 25;
      case QuestionDifficulty.hard:
        return 20;
    }
  }

  static int _getLpReward(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 12;
      case QuestionDifficulty.medium:
        return 18;
      case QuestionDifficulty.hard:
        return 28;
    }
  }
}
