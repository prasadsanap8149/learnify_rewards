import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../domain/entities/question.dart';
import '../domain/entities/lifeline.dart';
import '../data/generators/math_question_generator.dart';
import '../data/generators/word_question_generator.dart';
import '../data/generators/puzzle_question_generator.dart';
import '../../../services/enhanced_ad_service.dart';
import '../../../services/lp_service.dart';
import '../../../services/activity_service.dart';
import '../../../services/fraud_detection_service.dart';
import '../../../services/earnings_pool_service.dart';

class ActivityGameScreen extends StatefulWidget {
  final ActivityType activityType;
  final QuestionDifficulty difficulty;

  const ActivityGameScreen({
    super.key,
    required this.activityType,
    required this.difficulty,
  });

  @override
  State<ActivityGameScreen> createState() => _ActivityGameScreenState();
}

class _ActivityGameScreenState extends State<ActivityGameScreen>
    with TickerProviderStateMixin {
  Question? _currentQuestion;
  List<Lifeline> _lifelines = [];
  Timer? _timer;
  int _timeRemaining = 0;
  bool _isAnswering = false;
  bool _showHint = false;
  String? _hintText;
  String? _selectedAnswer;
  bool _showResults = false;
  bool _isCorrect = false;

  late AnimationController _timerAnimationController;
  late AnimationController _questionAnimationController;
  late Animation<double> _timerAnimation;
  late Animation<double> _questionAnimation;

  final EnhancedAdService _adService = EnhancedAdService();
  final FraudDetectionService _fraudService = FraudDetectionService();
  final EarningsPoolService _earningsService = EarningsPoolService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLifelines();
    _generateNewQuestion();
  }

  void _initializeAnimations() {
    _timerAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _timerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _timerAnimationController, curve: Curves.easeInOut),
    );

    _questionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _questionAnimationController, curve: Curves.easeInOut),
    );
  }

  void _initializeLifelines() {
    _lifelines = Lifeline.getDefaultLifelines();
  }

  void _generateNewQuestion() {
    setState(() {
      _showResults = false;
      _selectedAnswer = null;
      _showHint = false;
      _hintText = null;
    });

    Question newQuestion;
    switch (widget.activityType) {
      case ActivityType.math:
        newQuestion = MathQuestionGenerator.generateQuestion(
            difficulty: widget.difficulty);
        break;
      case ActivityType.word:
        newQuestion = WordQuestionGenerator.generateQuestion(
            difficulty: widget.difficulty);
        break;
      case ActivityType.puzzle:
        newQuestion = PuzzleQuestionGenerator.generateQuestion(
            difficulty: widget.difficulty);
        break;
    }

    setState(() {
      _currentQuestion = newQuestion;
      _timeRemaining = newQuestion.timeLimit;
    });

    _startTimer();
    _questionAnimationController.forward(from: 0);
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    _handleAnswer(''); // Empty answer for timeout
  }

  void _handleAnswer(String answer) async {
    if (_isAnswering || _currentQuestion == null) return;

    setState(() {
      _isAnswering = true;
      _selectedAnswer = answer;
    });

    _timer?.cancel();

    final isCorrect = answer == _currentQuestion!.correctAnswer;
    setState(() {
      _isCorrect = isCorrect;
      _showResults = true;
    });

    // Log the activity
    // await ActivityService.logActivityCompletion(
    //   activityId: _currentQuestion!.id,
    //   activityType: widget.activityType,
    //   isCorrect: isCorrect,
    //   timeSpent: _currentQuestion!.timeLimit - _timeRemaining,
    //   difficulty: widget.difficulty,
    // );

    if (isCorrect) {
      // Check fraud detection before awarding LP
      final fraudResult = await _fraudService.analyzeUserBehavior(
        userId: FirebaseAuth.instance.currentUser!.uid,
        action: 'activity_completion',
        additionalData: {
          'activityType': widget.activityType.toString(),
          'difficulty': widget.difficulty.toString(),
          'timeTaken': _currentQuestion!.timeLimit - _timeRemaining,
          'questionId': _currentQuestion!.id,
        },
      );

      // Check if user should be blocked due to high fraud risk
      if (fraudResult.riskLevel == RiskLevel.high) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Activity flagged for review: ${fraudResult.explanation}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // Award LP if fraud risk is acceptable
      await LPService.awardLP(
        amount: fraudResult.riskLevel == RiskLevel.medium
            ? (_currentQuestion!.lpReward * 0.5).toDouble()
            :
            _currentQuestion!.lpReward.toDouble(),
        metadata: {
          'activityType': widget.activityType.toString(),
          'difficulty': widget.difficulty.toString(),
          'questionId': _currentQuestion!.id,
          'fraudRiskScore': fraudResult.riskScore,
          'fraudRiskLevel': fraudResult.riskLevel.toString(),
        }, source: '', description: '',
      );

      // Check for automatic earnings conversion (client-side)
      await _checkAndProcessEarnings();

      // Show ad after correct answer
      _showAdAfterCorrectAnswer();
    }

    // Show results for 3 seconds then continue or go back
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      if (isCorrect) {
        _generateNewQuestion(); // Continue with next question
      } else {
        Navigator.of(context).pop(); // Go back to activities list
      }
    }
  }

  void _showAdAfterCorrectAnswer() async {
    try {
      await _adService.showRandomAd(
        onAdShown: () {
          print('Ad shown after correct answer');
        },
        onAdFailedToShow: (error) {
          print('Failed to show ad: $error');
        },
      );
    } catch (e) {
      print('Error showing ad: $e');
    }
  }

  void _useLifeline(Lifeline lifeline) {
    if (lifeline.isUsed || _currentQuestion == null) return;

    LifelineResult result;

    switch (lifeline.type) {
      case LifelineType.fiftyFifty:
        result = LifelineService.useFiftyFifty(
          _currentQuestion!.options,
          _currentQuestion!.correctAnswer,
        );
        if (result.success && result.modifiedOptions != null) {
          setState(() {
            _currentQuestion = Question(
              id: _currentQuestion!.id,
              type: _currentQuestion!.type,
              difficulty: _currentQuestion!.difficulty,
              questionText: _currentQuestion!.questionText,
              options: result.modifiedOptions!,
              correctAnswer: _currentQuestion!.correctAnswer,
              timeLimit: _currentQuestion!.timeLimit,
              lpReward: _currentQuestion!.lpReward,
              metadata: _currentQuestion!.metadata,
            );
          });
        }
        break;

      case LifelineType.revealHint:
        result = LifelineService.getHint(
          _currentQuestion!.metadata,
          _currentQuestion!.questionText,
        );
        if (result.success && result.hint != null) {
          setState(() {
            _showHint = true;
            _hintText = result.hint;
          });
        }
        break;

      case LifelineType.extraTime:
        result = LifelineService.addExtraTime();
        if (result.success && result.extraTimeSeconds != null) {
          setState(() {
            _timeRemaining += result.extraTimeSeconds!;
          });
        }
        break;
    }

    if (result.success) {
      setState(() {
        final index = _lifelines.indexWhere((l) => l.type == lifeline.type);
        _lifelines[index] = _lifelines[index].copyWith(isUsed: true);
      });

      // Show result message
      if (result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message!),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color _getTimerColor() {
    if (_timeRemaining > 10) return Colors.green;
    if (_timeRemaining > 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getActivityTitle()),
        backgroundColor: _getActivityColor(),
        foregroundColor: Colors.white,
        actions: [
          // Timer display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTimerColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_timeRemaining}s',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _currentQuestion == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _currentQuestion!.timeLimit > 0
                      ? (_currentQuestion!.timeLimit - _timeRemaining) /
                          _currentQuestion!.timeLimit
                      : 1.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(_getTimerColor()),
                ),

                // Lifelines
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _lifelines.map((lifeline) {
                      return _buildLifelineButton(lifeline);
                    }).toList(),
                  ),
                ),

                // Hint display
                if (_showHint && _hintText != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hintText!,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Question section
                Expanded(
                  child: AnimatedBuilder(
                    animation: _questionAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _questionAnimation.value,
                        child: Opacity(
                          opacity: _questionAnimation.value,
                          child: _buildQuestionSection(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLifelineButton(Lifeline lifeline) {
    return GestureDetector(
      onTap: lifeline.isUsed ? null : () => _useLifeline(lifeline),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: lifeline.isUsed ? Colors.grey[300] : _getActivityColor(),
          borderRadius: BorderRadius.circular(30),
          boxShadow: lifeline.isUsed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lifeline.icon,
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              lifeline.name,
              style: TextStyle(
                fontSize: 8,
                color: lifeline.isUsed ? Colors.grey[600] : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question text
          Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                _currentQuestion!.questionText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: _currentQuestion!.options.length,
              itemBuilder: (context, index) {
                final option = _currentQuestion!.options[index];
                return _buildAnswerOption(option, index);
              },
            ),
          ),

          // Results section
          if (_showResults) _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String option, int index) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == _currentQuestion!.correctAnswer;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;

    if (_showResults) {
      if (isCorrect) {
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green[400]!;
        textColor = Colors.green[800]!;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red[400]!;
        textColor = Colors.red[800]!;
      }
    } else if (isSelected) {
      backgroundColor = _getActivityColor().withOpacity(0.1);
      borderColor = _getActivityColor();
      textColor = _getActivityColor();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap:
            _isAnswering || _showResults ? null : () => _handleAnswer(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_showResults && isCorrect)
                Icon(Icons.check_circle, color: Colors.green[600], size: 24),
              if (_showResults && isSelected && !isCorrect)
                Icon(Icons.cancel, color: Colors.red[600], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isCorrect ? Icons.celebration : Icons.close,
            color: _isCorrect ? Colors.green[600] : Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _isCorrect ? 'Correct! 🎉' : 'Incorrect ❌',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isCorrect ? Colors.green[800] : Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          if (_isCorrect)
            Text(
              '+${_currentQuestion!.lpReward} LP earned!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          if (!_isCorrect)
            Text(
              'The correct answer was: ${_currentQuestion!.correctAnswer}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  String _getActivityTitle() {
    switch (widget.activityType) {
      case ActivityType.math:
        return 'Math Challenge';
      case ActivityType.word:
        return 'Word Challenge';
      case ActivityType.puzzle:
        return 'Puzzle Challenge';
    }
  }

  Color _getActivityColor() {
    switch (widget.activityType) {
      case ActivityType.math:
        return Colors.blue;
      case ActivityType.word:
        return Colors.green;
      case ActivityType.puzzle:
        return Colors.purple;
    }
  }

  // Client-side earnings conversion check
  Future<void> _checkAndProcessEarnings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get user's current LP balance
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final currentLP = userData['learningPoints'] ?? 0;
      final lastConversion = userData['lastEarningsConversion'] as Timestamp?;

      // Check if user has enough LP for conversion (minimum 1000 LP)
      const minConversionLP = 1000;
      const lpToEarningsRate = 0.01; // 1 LP = 0.01 rupees

      if (currentLP >= minConversionLP) {
        // Check if it's been 24 hours since last conversion
        bool shouldConvert = false;

        if (lastConversion == null) {
          shouldConvert = true;
        } else {
          final timeSinceLastConversion =
              DateTime.now().difference(lastConversion.toDate());
          shouldConvert = timeSinceLastConversion.inHours >= 24;
        }

        if (shouldConvert) {
          final earningsAmount =
              (currentLP * lpToEarningsRate * 100).floor() / 100;

          // Update user document with earnings conversion
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'totalEarnings': FieldValue.increment(earningsAmount),
            'learningPoints': 0, // Reset LP after conversion
            'lastEarningsConversion': FieldValue.serverTimestamp(),
          });

          // Create earnings history record
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('earnings_history')
              .add({
            'amount': earningsAmount,
            'lpConverted': currentLP,
            'conversionRate': lpToEarningsRate,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'daily_conversion',
          });

          // Show user notification about the conversion
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '🎉 $currentLP LP converted to ₹${earningsAmount.toStringAsFixed(2)}!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error in earnings conversion: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    _questionAnimationController.dispose();
    super.dispose();
  }
}
