import '../domain/entities/user.dart';
import '../domain/entities/ad_event.dart';
import '../domain/entities/lp_event.dart';
import '../domain/entities/security_event.dart';
import '../data/repositories/firestore_lp_event_repository.dart';
import '../data/repositories/firestore_security_event_repository.dart';

class AERService {
  final FirestoreLPEventRepository _lpEventRepository;
  final FirestoreSecurityEventRepository _securityEventRepository;

  AERService({
    FirestoreLPEventRepository? lpEventRepository,
    FirestoreSecurityEventRepository? securityEventRepository,
  })  : _lpEventRepository = lpEventRepository ?? FirestoreLPEventRepository(),
        _securityEventRepository =
            securityEventRepository ?? FirestoreSecurityEventRepository();

  // Base AER rates (in cents)
  static const Map<AgeGroup, double> _baseRates = {
    AgeGroup.under13: 0.5,
    AgeGroup.thirteenToSeventeen: 1.0,
    AgeGroup.eighteenPlus: 1.5,
  };

  // Minimum engagement time for AER qualification (in seconds)
  static const int _minEngagementTime = 30;

  // Daily AER limits by age group (in cents)
  static const Map<AgeGroup, double> _dailyLimits = {
    AgeGroup.under13: 50.0, // $0.50 per day
    AgeGroup.thirteenToSeventeen: 100.0, // $1.00 per day
    AgeGroup.eighteenPlus: 200.0, // $2.00 per day
  };

  // Calculate AER for an ad engagement
  Future<double> calculateAER(AdEvent adEvent, User user) async {
    try {
      // Check if engagement qualifies for AER
      if (!_qualifiesForAER(adEvent)) {
        return 0.0;
      }

      // Check daily limits
      final dailyEarnings = await _getDailyAERTotal(user.uid);
      final dailyLimit = _dailyLimits[user.ageGroup] ?? 0.0;

      if (dailyEarnings >= dailyLimit) {
        await _createSecurityEvent(
          user.uid,
          SecurityEventType.suspiciousEarnings,
          'Daily AER limit reached',
          {'dailyEarnings': dailyEarnings, 'limit': dailyLimit},
        );
        return 0.0;
      }

      // Check for suspicious patterns
      await _checkSuspiciousPatterns(user.uid, adEvent);

      double baseRate = _baseRates[user.ageGroup] ?? 0.0;
      double multiplier = _getMultiplier(adEvent);
      double calculatedAER = baseRate * multiplier;

      // Ensure we don't exceed daily limit
      if (dailyEarnings + calculatedAER > dailyLimit) {
        calculatedAER = dailyLimit - dailyEarnings;
      }

      return calculatedAER;
    } catch (e) {
      throw Exception('Failed to calculate AER: $e');
    }
  }

  // Check if ad engagement qualifies for AER
  static bool _qualifiesForAER(AdEvent adEvent) {
    return adEvent.engagementTimeSeconds >= _minEngagementTime &&
        adEvent.completed;
  }

  // Get multiplier based on ad format and engagement
  static double _getMultiplier(AdEvent adEvent) {
    double baseMultiplier;
    switch (adEvent.format) {
      case AdFormat.banner:
        baseMultiplier = 0.5;
        break;
      case AdFormat.interstitial:
        baseMultiplier = 1.0;
        break;
      case AdFormat.rewarded:
        baseMultiplier = 2.0;
        break;
      case AdFormat.rewardedInterstitial:
        baseMultiplier = 1.5;
        break;
      default:
        baseMultiplier = 1.0;
    }

    // Bonus for longer engagement
    if (adEvent.engagementTimeSeconds > 60) {
      baseMultiplier *= 1.2;
    }

    return baseMultiplier;
  }

  // Get daily AER total for user
  Future<double> _getDailyAERTotal(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final events = await _lpEventRepository.getLPEventsByDateRange(
      userId,
      startOfDay,
      endOfDay,
    );

    double total = 0.0;
    for (final event in events) {
      if (event.source == LPSource.activity &&
          event.metadata?['aerAmount'] != null) {
        total += (event.metadata!['aerAmount'] as num).toDouble();
      }
    }

    return total;
  }

  // Check for suspicious patterns
  Future<void> _checkSuspiciousPatterns(String userId, AdEvent adEvent) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // Check recent LP events
    final recentEvents = await _lpEventRepository.getLPEventsByDateRange(
      userId,
      oneHourAgo,
      now,
    );

    // Flag if too many AER events in the last hour
    final aerEvents = recentEvents
        .where((e) =>
            e.source == LPSource.activity && e.metadata?['aerAmount'] != null)
        .length;

    if (aerEvents > 10) {
      await _createSecurityEvent(
        userId,
        SecurityEventType.rapidActivities,
        'Too many AER events in one hour',
        {
          'count': aerEvents,
          'timeframe': '1 hour',
          'adEventId': adEvent.id,
        },
      );
    }

    // Flag if engagement time is suspiciously consistent
    final engagementTimes = recentEvents
        .where((e) => e.metadata?['engagementTime'] != null)
        .map((e) => e.metadata!['engagementTime'] as int)
        .toList();

    if (engagementTimes.length >= 5) {
      final variance = _calculateVariance(engagementTimes);
      if (variance < 2.0) {
        // Very low variance suggests automation
        await _createSecurityEvent(
          userId,
          SecurityEventType.suspiciousActivity,
          'Consistent engagement times suggest automation',
          {
            'variance': variance,
            'engagementTimes': engagementTimes,
            'adEventId': adEvent.id,
          },
        );
      }
    }
  }

  // Calculate variance for engagement times
  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((x) => (x - mean) * (x - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  // Create security event
  Future<void> _createSecurityEvent(
    String userId,
    SecurityEventType type,
    String description,
    Map<String, dynamic> details,
  ) async {
    final event = SecurityEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      severity: SecuritySeverity.medium,
      status: SecurityStatus.open,
      description: description,
      details: details,
      timestamp: DateTime.now(),
      relatedEvents: [],
    );

    await _securityEventRepository.createSecurityEvent(event);
  }

  // Process AER reward
  Future<void> processAERReward(
    String userId,
    AdEvent adEvent,
    double aerAmount,
    int lpAmount,
  ) async {
    try {
      final lpEvent = LPEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: LPEventType.earned,
        source: LPSource.activity,
        amount: lpAmount,
        previousBalance: await _lpEventRepository.getCurrentLPBalance(userId),
        newBalance:
            await _lpEventRepository.getCurrentLPBalance(userId) + lpAmount,
        sourceId: adEvent.id,
        description:
            'AER reward for ${adEvent.format.toString().split('.').last} ad',
        metadata: {
          'aerAmount': aerAmount,
          'adFormat': adEvent.format.toString().split('.').last,
          'engagementTime': adEvent.engagementTimeSeconds,
        },
        timestamp: DateTime.now(),
      );

      await _lpEventRepository.createLPEvent(lpEvent);
    } catch (e) {
      throw Exception('Failed to process AER reward: $e');
    }
  }

  // Get AER statistics for user
  Future<Map<String, dynamic>> getAERStatistics(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final todayEvents = await _lpEventRepository.getLPEventsByDateRange(
          userId, startOfDay, now);
      final weekEvents = await _lpEventRepository.getLPEventsByDateRange(
          userId, startOfWeek, now);
      final monthEvents = await _lpEventRepository.getLPEventsByDateRange(
          userId, startOfMonth, now);

      double todayAER = 0.0;
      double weekAER = 0.0;
      double monthAER = 0.0;

      for (final event in todayEvents) {
        if (event.metadata?['aerAmount'] != null) {
          todayAER += (event.metadata!['aerAmount'] as num).toDouble();
        }
      }

      for (final event in weekEvents) {
        if (event.metadata?['aerAmount'] != null) {
          weekAER += (event.metadata!['aerAmount'] as num).toDouble();
        }
      }

      for (final event in monthEvents) {
        if (event.metadata?['aerAmount'] != null) {
          monthAER += (event.metadata!['aerAmount'] as num).toDouble();
        }
      }

      return {
        'todayAER': todayAER,
        'weekAER': weekAER,
        'monthAER': monthAER,
        'todayCount': todayEvents.length,
        'weekCount': weekEvents.length,
        'monthCount': monthEvents.length,
      };
    } catch (e) {
      throw Exception('Failed to get AER statistics: $e');
    }
  }
}
