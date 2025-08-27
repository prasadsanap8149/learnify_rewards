import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/activities_provider.dart';
import '../models/activity_model.dart';

class ActivityDetailsScreen extends ConsumerStatefulWidget {
  final Activity activity;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  ConsumerState<ActivityDetailsScreen> createState() =>
      _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends ConsumerState<ActivityDetailsScreen> {
  late String _userAnswer;
  bool _hasSubmitted = false;
  bool _isCorrect = false;
  Timer? _timer;
  int _timeLeft = 30; // 30 seconds per activity

  @override
  void initState() {
    super.initState();
    _userAnswer = '';
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _submitAnswer(timeout: true);
      }
    });
  }

  void _submitAnswer({bool timeout = false}) {
    if (_hasSubmitted) return;

    final timeTaken = 30 - _timeLeft;
    _timer?.cancel();
    setState(() {
      _hasSubmitted = true;
    });

    if (timeout) {
      _showTimeoutDialog();
      return;
    }

    final isCorrect = widget.activity.content.options.isNotEmpty
        ? _userAnswer.toLowerCase().trim() ==
            widget.activity.content.correctAnswer.toLowerCase().trim()
        : widget.activity.content.correctAnswer
            .toLowerCase()
            .split(',')
            .any((answer) => _userAnswer.toLowerCase().trim() == answer.trim());
    setState(() {
      _isCorrect = isCorrect;
    });

    // Record the answer
    ref.read(activitiesNotifierProvider.notifier).recordAnswer(
          userId: 'TODO: Get current user ID', // TODO: Get from auth provider
          activityId: widget.activity.id,
          correct: isCorrect,
          timeTaken: timeTaken,
        );

    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null) {
      _showErrorDialog('Please sign in to submit answers');
      return;
    }

    ref.read(activitiesNotifierProvider.notifier).recordAnswer(
          userId: userId,
          activityId: widget.activity.id,
          correct: isCorrect,
          timeTaken: 30 - _timeLeft,
        );

    _showResultDialog(isCorrect);
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text(
          'You ran out of time. Better luck next time!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to activities screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Correct!' : 'Incorrect'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect
                  ? 'Great job! You\'ve completed this activity.'
                  : 'The correct answer was: ${widget.activity.content.correctAnswer}',
            ),
            if (isCorrect) ...[
              const SizedBox(height: 16),
              Text(
                'Time bonus: $_timeLeft seconds remaining',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to activities screen
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Scaffold(
      appBar: AppBar(
        title: Text('${activity.type} Activity'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '$_timeLeft s',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Question:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.content.question,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (activity.content.options.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Options:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: activity.content.options.map((option) {
                          return ListTile(
                            title: Text(option),
                            leading: Radio<String>(
                              value: option,
                              groupValue: _userAnswer,
                              onChanged: !_hasSubmitted
                                  ? (value) =>
                                      setState(() => _userAnswer = value!)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer section
            if (!_hasSubmitted && activity.content.options.isEmpty) ...[
              TextField(
                onChanged: (value) => _userAnswer = value,
                decoration: InputDecoration(
                  labelText: 'Your Answer',
                  hintText: 'Type your answer here',
                  border: const OutlineInputBorder(),
                  suffix: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _submitAnswer(),
                  ),
                ),
                onSubmitted: (_) => _submitAnswer(),
              ),
            ] else ...[
              Card(
                color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _isCorrect ? 'Correct Answer!' : 'Incorrect Answer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _isCorrect
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your answer: $_userAnswer',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Correct answer: ${activity.content.answer}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Info section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Type'),
                        Text(
                          activity.type,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Difficulty'),
                        Text(
                          activity.difficulty.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Points'),
                        Text(
                          activity.points.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
