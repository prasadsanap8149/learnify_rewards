import '../domain/entities/security_event.dart';
import '../domain/entities/user.dart';
import '../data/repositories/firestore_security_event_repository.dart';
import '../data/repositories/firestore_user_repository.dart';
import '../data/repositories/firestore_lp_event_repository.dart';
import '../data/repositories/firestore_audit_log_repository.dart';
import '../domain/entities/audit_log.dart';

class SecurityService {
  final FirestoreSecurityEventRepository _securityEventRepository;
  final FirestoreUserRepository _userRepository;
  final FirestoreLPEventRepository _lpEventRepository;
  final FirestoreAuditLogRepository _auditLogRepository;

  SecurityService({
    FirestoreSecurityEventRepository? securityEventRepository,
    FirestoreUserRepository? userRepository,
    FirestoreLPEventRepository? lpEventRepository,
    FirestoreAuditLogRepository? auditLogRepository,
  })  : _securityEventRepository =
            securityEventRepository ?? FirestoreSecurityEventRepository(),
        _userRepository = userRepository ?? FirestoreUserRepository(),
        _lpEventRepository = lpEventRepository ?? FirestoreLPEventRepository(),
        _auditLogRepository =
            auditLogRepository ?? FirestoreAuditLogRepository();

  // Fraud detection thresholds
  static const int _maxActivitiesPerHour = 15;
  static const int _maxDevicesPerUser = 3;
  static const double _maxEarningsPerDay = 500.0; // $5.00
  static const double _suspiciousVarianceThreshold = 1.0;

  // Analyze user behavior for fraud patterns
  Future<void> analyzeUserBehavior(String userId) async {
    try {
      final user = await _userRepository.getUser(userId);
      if (user == null) return;

      await Future.wait([
        _checkRapidActivities(userId),
        _checkMultipleDevices(userId),
        _checkSuspiciousEarnings(userId),
        _checkDeviceFingerprinting(userId),
        _checkEngagementPatterns(userId),
      ]);
    } catch (e) {
      await _createSecurityEvent(
        userId,
        SecurityEventType.dataAnomaly,
        SecuritySeverity.low,
        'Error analyzing user behavior: $e',
        {'error': e.toString()},
      );
    }
  }

  // Check for rapid activities
  Future<void> _checkRapidActivities(String userId) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final recentEvents = await _lpEventRepository.getLPEventsByDateRange(
      userId,
      oneHourAgo,
      now,
    );

    if (recentEvents.length > _maxActivitiesPerHour) {
      await _createSecurityEvent(
        userId,
        SecurityEventType.rapidActivities,
        SecuritySeverity.high,
        'User completed ${recentEvents.length} activities in one hour',
        {
          'activityCount': recentEvents.length,
          'timeframe': '1 hour',
          'threshold': _maxActivitiesPerHour,
        },
      );
    }
  }

  // Check for multiple devices
  Future<void> _checkMultipleDevices(String userId) async {
    final user = await _userRepository.getUser(userId);
    if (user?.deviceInfo == null) return;

    final deviceCount = user!.deviceInfo!.deviceIds.length;

    if (deviceCount > _maxDevicesPerUser) {
      await _createSecurityEvent(
        userId,
        SecurityEventType.multipleDevices,
        SecuritySeverity.medium,
        'User has $deviceCount registered devices',
        {
          'deviceCount': deviceCount,
          'threshold': _maxDevicesPerUser,
          'deviceIds': user.deviceInfo!.deviceIds,
        },
      );
    }
  }

  // Check for suspicious earnings
  Future<void> _checkSuspiciousEarnings(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final todayEvents = await _lpEventRepository.getLPEventsByDateRange(
      userId,
      startOfDay,
      now,
    );

    double totalAER = 0.0;
    for (final event in todayEvents) {
      if (event.metadata?['aerAmount'] != null) {
        totalAER += (event.metadata!['aerAmount'] as num).toDouble();
      }
    }

    if (totalAER > _maxEarningsPerDay) {
      await _createSecurityEvent(
        userId,
        SecurityEventType.suspiciousEarnings,
        SecuritySeverity.high,
        'User earned \$${(totalAER / 100).toStringAsFixed(2)} today',
        {
          'dailyEarnings': totalAER,
          'threshold': _maxEarningsPerDay,
          'eventCount': todayEvents.length,
        },
      );
    }
  }

  // Check device fingerprinting
  Future<void> _checkDeviceFingerprinting(String userId) async {
    // This would integrate with device fingerprinting service
    // For now, we'll check basic device info consistency
    final user = await _userRepository.getUser(userId);
    if (user?.deviceInfo == null) return;

    final deviceInfo = user!.deviceInfo!;

    // Check for IP address changes
    if (deviceInfo.lastIP != deviceInfo.registrationIP) {
      await _createSecurityEvent(
        userId,
        SecurityEventType.ipChange,
        SecuritySeverity.low,
        'User IP address changed',
        {
          'registrationIP': deviceInfo.registrationIP,
          'lastIP': deviceInfo.lastIP,
        },
      );
    }
  }

  // Check engagement patterns
  Future<void> _checkEngagementPatterns(String userId) async {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));

    final recentEvents = await _lpEventRepository.getLPEventsByDateRange(
      userId,
      oneDayAgo,
      now,
    );

    // Extract engagement times
    final engagementTimes = recentEvents
        .where((e) => e.metadata?['engagementTime'] != null)
        .map((e) => e.metadata!['engagementTime'] as int)
        .toList();

    if (engagementTimes.length >= 5) {
      final variance = _calculateVariance(engagementTimes);

      if (variance < _suspiciousVarianceThreshold) {
        await _createSecurityEvent(
          userId,
          SecurityEventType.suspiciousActivity,
          SecuritySeverity.medium,
          'Suspiciously consistent engagement times',
          {
            'variance': variance,
            'threshold': _suspiciousVarianceThreshold,
            'engagementTimes': engagementTimes,
            'sampleSize': engagementTimes.length,
          },
        );
      }
    }
  }

  // Calculate variance
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
    SecuritySeverity severity,
    String description,
    Map<String, dynamic> details,
  ) async {
    final event = SecurityEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      severity: severity,
      status: SecurityStatus.open,
      description: description,
      details: details,
      timestamp: DateTime.now(),
      relatedEvents: [],
    );

    await _securityEventRepository.createSecurityEvent(event);

    // Auto-suspend user for critical events
    if (severity == SecuritySeverity.critical) {
      await _autoSuspendUser(userId, event.id);
    }
  }

  // Auto-suspend user for critical security events
  Future<void> _autoSuspendUser(String userId, String eventId) async {
    try {
      await _userRepository.updateUserStatus(
        userId,
        UserStatus.suspended,
        reason: 'Auto-suspended due to critical security event',
      );

      // Create audit log
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        adminId: 'system',
        action: AuditAction.suspend,
        entity: AuditEntity.user,
        entityId: userId,
        reason: 'Auto-suspended due to critical security event: $eventId',
        metadata: {'securityEventId': eventId},
        timestamp: DateTime.now(),
      );

      await _auditLogRepository.createAuditLog(auditLog);
    } catch (e) {
      // Log error but don't throw to avoid breaking the security flow
      print('Failed to auto-suspend user $userId: $e');
    }
  }

  // Validate parental consent for minors
  Future<bool> validateParentalConsent(String userId) async {
    try {
      final user = await _userRepository.getUser(userId);
      if (user == null) return false;

      // Only required for users under 13
      if (user.ageGroup != AgeGroup.under13) {
        return true;
      }

      if (user.parentalConsent == null || !user.parentalConsent!.granted) {
        await _createSecurityEvent(
          userId,
          SecurityEventType.parentalControl,
          SecuritySeverity.high,
          'Minor user without valid parental consent',
          {
            'ageGroup': user.ageGroup.toString(),
            'hasConsent': user.parentalConsent?.granted ?? false,
          },
        );
        return false;
      }

      return true;
    } catch (e) {
      throw Exception('Failed to validate parental consent: $e');
    }
  }

  // Check compliance status
  Future<Map<String, dynamic>> checkComplianceStatus(String userId) async {
    try {
      final user = await _userRepository.getUser(userId);
      if (user == null) {
        return {'compliant': false, 'reason': 'User not found'};
      }

      // Check parental consent for minors
      if (user.ageGroup == AgeGroup.under13) {
        if (user.parentalConsent == null || !user.parentalConsent!.granted) {
          return {
            'compliant': false,
            'reason': 'Missing parental consent',
            'required': 'Parental consent required for users under 13',
          };
        }
      }

      // Check verification status
      if (user.verificationStatus == VerificationStatus.none) {
        return {
          'compliant': false,
          'reason': 'No verification',
          'required': 'At least email verification required',
        };
      }

      // Check for active security issues
      final openEvents = await _securityEventRepository.getOpenEventsBySeverity(
        SecuritySeverity.critical,
      );

      final userCriticalEvents =
          openEvents.where((e) => e.userId == userId).toList();

      if (userCriticalEvents.isNotEmpty) {
        return {
          'compliant': false,
          'reason': 'Critical security issues',
          'required': 'Resolve open security events',
          'eventCount': userCriticalEvents.length,
        };
      }

      return {'compliant': true};
    } catch (e) {
      throw Exception('Failed to check compliance status: $e');
    }
  }

  // Get security dashboard data
  Future<Map<String, dynamic>> getSecurityDashboard({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stats = await _securityEventRepository.getSecurityStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      final openCritical =
          await _securityEventRepository.getOpenEventsBySeverity(
        SecuritySeverity.critical,
      );

      final openHigh = await _securityEventRepository.getOpenEventsBySeverity(
        SecuritySeverity.high,
      );

      return {
        'statistics': stats,
        'openCritical': openCritical.length,
        'openHigh': openHigh.length,
        'totalOpen': (stats['open'] ?? 0),
        'recentEvents': openCritical.take(5).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get security dashboard: $e');
    }
  }
}
