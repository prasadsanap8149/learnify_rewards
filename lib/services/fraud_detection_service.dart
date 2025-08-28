import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_fingerprint_service.dart';

class FraudDetectionService {
  static final FraudDetectionService _instance =
      FraudDetectionService._internal();
  factory FraudDetectionService() => _instance;
  FraudDetectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceFingerprintService _fingerprintService =
      DeviceFingerprintService();

  /// Analyze user behavior for fraud patterns
  Future<FraudAnalysisResult> analyzeUserBehavior({
    required String userId,
    required String action,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final deviceFingerprint = await _fingerprintService.generateFingerprint();
      final deviceRiskScore = await _fingerprintService.calculateRiskScore();
      final networkInfo = await _fingerprintService.getNetworkSecurityInfo();

      // Get user's historical behavior
      final userBehavior = await _getUserBehaviorHistory(userId);
      final deviceHistory = await _getDeviceHistory(deviceFingerprint);

      // Calculate various risk factors
      final velocityRisk = _calculateVelocityRisk(userBehavior, action);
      final patternRisk = _calculatePatternRisk(userBehavior, action);
      final deviceRisk = _calculateDeviceRisk(deviceRiskScore, deviceHistory);
      final networkRisk = _calculateNetworkRisk(networkInfo);
      final temporalRisk = _calculateTemporalRisk(userBehavior);

      // Combine risk scores
      final overallRiskScore = _combineRiskScores([
        velocityRisk,
        patternRisk,
        deviceRisk,
        networkRisk,
        temporalRisk,
      ]);

      final riskLevel = _determineRiskLevel(overallRiskScore);
      final recommendation = _getRecommendation(riskLevel, overallRiskScore);

      // Log the analysis
      await _logFraudAnalysis(
        userId: userId,
        action: action,
        deviceFingerprint: deviceFingerprint,
        riskScore: overallRiskScore,
        riskLevel: riskLevel,
        factors: {
          'velocity': velocityRisk,
          'pattern': patternRisk,
          'device': deviceRisk,
          'network': networkRisk,
          'temporal': temporalRisk,
        },
        additionalData: additionalData,
      );

      return FraudAnalysisResult(
        riskScore: overallRiskScore,
        riskLevel: riskLevel,
        recommendation: recommendation,
        deviceFingerprint: deviceFingerprint,
        factors: {
          'velocity': velocityRisk,
          'pattern': patternRisk,
          'device': deviceRisk,
          'network': networkRisk,
          'temporal': temporalRisk,
        },
        explanation: _generateExplanation(riskLevel, overallRiskScore),
      );
    } catch (e) {
      print('Error in fraud analysis: $e');
      return FraudAnalysisResult(
        riskScore: 50, // Default moderate risk
        riskLevel: RiskLevel.medium,
        recommendation: ActionRecommendation.review,
        deviceFingerprint: 'unknown',
        factors: {},
        explanation: 'Analysis failed, defaulting to moderate risk',
      );
    }
  }

  /// Get user's behavior history
  Future<Map<String, dynamic>> _getUserBehaviorHistory(String userId) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Get recent activities
      final recentActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: oneDayAgo)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      // Get weekly activities for pattern analysis
      final weeklyActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: oneWeekAgo)
          .get();

      // Analyze activity patterns
      final activityCounts = <String, int>{};
      final hourlyDistribution = <int, int>{};
      final deviceFingerprints = <String>{};

      for (var doc in weeklyActivities.docs) {
        final data = doc.data();
        final action = data['action'] as String? ?? 'unknown';
        final timestamp =
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final deviceId = data['deviceFingerprint'] as String? ?? 'unknown';

        activityCounts[action] = (activityCounts[action] ?? 0) + 1;
        hourlyDistribution[timestamp.hour] =
            (hourlyDistribution[timestamp.hour] ?? 0) + 1;
        deviceFingerprints.add(deviceId);
      }

      return {
        'recentActivityCount': recentActivities.docs.length,
        'weeklyActivityCount': weeklyActivities.docs.length,
        'activityCounts': activityCounts,
        'hourlyDistribution': hourlyDistribution,
        'uniqueDevices': deviceFingerprints.length,
        'lastActivity': recentActivities.docs.isNotEmpty
            ? (recentActivities.docs.first.data()['timestamp'] as Timestamp?)
                ?.toDate()
            : null,
      };
    } catch (e) {
      return {};
    }
  }

  /// Get device history
  Future<Map<String, dynamic>> _getDeviceHistory(
      String deviceFingerprint) async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      final deviceActivities = await _firestore
          .collection('user_activities')
          .where('deviceFingerprint', isEqualTo: deviceFingerprint)
          .where('timestamp', isGreaterThan: oneWeekAgo)
          .get();

      final userIds = <String>{};
      final actions = <String, int>{};

      for (var doc in deviceActivities.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? 'unknown';
        final action = data['action'] as String? ?? 'unknown';

        userIds.add(userId);
        actions[action] = (actions[action] ?? 0) + 1;
      }

      return {
        'totalActivities': deviceActivities.docs.length,
        'uniqueUsers': userIds.length,
        'actionCounts': actions,
        'isNewDevice': deviceActivities.docs.isEmpty,
      };
    } catch (e) {
      return {'isNewDevice': true};
    }
  }

  /// Calculate velocity-based risk
  int _calculateVelocityRisk(Map<String, dynamic> behavior, String action) {
    final recentCount = behavior['recentActivityCount'] as int? ?? 0;

    // High frequency of activities in short time is suspicious
    if (recentCount > 50) return 80;
    if (recentCount > 30) return 60;
    if (recentCount > 20) return 40;
    if (recentCount > 10) return 20;

    return 0;
  }

  /// Calculate pattern-based risk
  int _calculatePatternRisk(Map<String, dynamic> behavior, String action) {
    final activityCounts =
        behavior['activityCounts'] as Map<String, int>? ?? {};
    final hourlyDistribution =
        behavior['hourlyDistribution'] as Map<int, int>? ?? {};

    int risk = 0;

    // Check for repetitive patterns
    final totalActivities = activityCounts.values.fold(0, (a, b) => a + b);
    if (totalActivities > 0) {
      final maxActionCount = activityCounts.values.reduce(max);
      final repetitionRatio = maxActionCount / totalActivities;

      if (repetitionRatio > 0.8)
        risk += 40;
      else if (repetitionRatio > 0.6)
        risk += 25;
      else if (repetitionRatio > 0.4) risk += 10;
    }

    // Check for unusual time patterns
    if (hourlyDistribution.isNotEmpty) {
      final nightActivities = hourlyDistribution.entries
          .where((e) => e.key >= 23 || e.key <= 5)
          .fold(0, (sum, e) => sum + e.value);

      if (nightActivities > totalActivities * 0.7)
        risk += 30;
      else if (nightActivities > totalActivities * 0.5) risk += 15;
    }

    return risk.clamp(0, 100);
  }

  /// Calculate device-based risk
  int _calculateDeviceRisk(
      int deviceRiskScore, Map<String, dynamic> deviceHistory) {
    int risk = deviceRiskScore;

    // Check if device is used by multiple users
    final uniqueUsers = deviceHistory['uniqueUsers'] as int? ?? 1;
    if (uniqueUsers > 5)
      risk += 40;
    else if (uniqueUsers > 3)
      risk += 25;
    else if (uniqueUsers > 1) risk += 10;

    // New devices have moderate risk
    if (deviceHistory['isNewDevice'] == true) {
      risk += 20;
    }

    return risk.clamp(0, 100);
  }

  /// Calculate network-based risk
  int _calculateNetworkRisk(Map<String, dynamic> networkInfo) {
    int risk = 0;

    if (networkInfo['isVPNDetected'] == true) risk += 30;
    if (networkInfo['isProxyDetected'] == true) risk += 25;

    return risk.clamp(0, 100);
  }

  /// Calculate temporal risk based on timing patterns
  int _calculateTemporalRisk(Map<String, dynamic> behavior) {
    final lastActivity = behavior['lastActivity'] as DateTime?;
    if (lastActivity == null) return 20; // New user, moderate risk

    final timeSinceLastActivity = DateTime.now().difference(lastActivity);

    // Very frequent activity is suspicious
    if (timeSinceLastActivity.inMinutes < 1) return 50;
    if (timeSinceLastActivity.inMinutes < 5) return 30;
    if (timeSinceLastActivity.inMinutes < 15) return 10;

    return 0;
  }

  /// Combine multiple risk scores using weighted average
  int _combineRiskScores(List<int> scores) {
    if (scores.isEmpty) return 0;

    // Use weighted average - some factors are more important
    final weights = [
      0.25,
      0.2,
      0.25,
      0.15,
      0.15
    ]; // velocity, pattern, device, network, temporal

    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < scores.length && i < weights.length; i++) {
      weightedSum += scores[i] * weights[i];
      totalWeight += weights[i];
    }

    return (weightedSum / totalWeight).round().clamp(0, 100);
  }

  /// Determine risk level from score
  RiskLevel _determineRiskLevel(int riskScore) {
    if (riskScore >= 80) return RiskLevel.high;
    if (riskScore >= 60) return RiskLevel.medium;
    if (riskScore >= 30) return RiskLevel.low;
    return RiskLevel.minimal;
  }

  /// Get action recommendation based on risk
  ActionRecommendation _getRecommendation(RiskLevel riskLevel, int riskScore) {
    switch (riskLevel) {
      case RiskLevel.high:
        return ActionRecommendation.block;
      case RiskLevel.medium:
        return riskScore >= 70
            ? ActionRecommendation.challenge
            : ActionRecommendation.review;
      case RiskLevel.low:
        return ActionRecommendation.monitor;
      case RiskLevel.minimal:
        return ActionRecommendation.allow;
    }
  }

  /// Generate human-readable explanation
  String _generateExplanation(RiskLevel riskLevel, int riskScore) {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'High risk detected (Score: $riskScore). Multiple fraud indicators present.';
      case RiskLevel.medium:
        return 'Moderate risk detected (Score: $riskScore). Some suspicious patterns identified.';
      case RiskLevel.low:
        return 'Low risk detected (Score: $riskScore). Minor concerns identified.';
      case RiskLevel.minimal:
        return 'Minimal risk detected (Score: $riskScore). Normal behavior patterns.';
    }
  }

  /// Log fraud analysis for monitoring
  Future<void> _logFraudAnalysis({
    required String userId,
    required String action,
    required String deviceFingerprint,
    required int riskScore,
    required RiskLevel riskLevel,
    required Map<String, int> factors,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('fraud_analysis_logs').add({
        'userId': userId,
        'action': action,
        'deviceFingerprint':
            _fingerprintService.getShortFingerprint(deviceFingerprint),
        'riskScore': riskScore,
        'riskLevel': riskLevel.toString(),
        'factors': factors,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData ?? {},
      });
    } catch (e) {
      print('Error logging fraud analysis: $e');
    }
  }

  /// Check if user should be temporarily blocked
  Future<bool> shouldBlockUser(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final recentHighRiskEvents = await _firestore
          .collection('fraud_analysis_logs')
          .where('userId', isEqualTo: userId)
          .where('riskLevel', isEqualTo: 'RiskLevel.high')
          .where('timestamp', isGreaterThan: oneHourAgo)
          .get();

      // Block if multiple high-risk events in the last hour
      return recentHighRiskEvents.docs.length >= 3;
    } catch (e) {
      return false;
    }
  }

  /// Get user's fraud risk summary
  Future<Map<String, dynamic>> getUserRiskSummary(String userId) async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      final recentLogs = await _firestore
          .collection('fraud_analysis_logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: oneWeekAgo)
          .orderBy('timestamp', descending: true)
          .get();

      final riskScores = <int>[];
      final riskLevels = <String, int>{};

      for (var doc in recentLogs.docs) {
        final data = doc.data();
        final score = data['riskScore'] as int? ?? 0;
        final level = data['riskLevel'] as String? ?? 'unknown';

        riskScores.add(score);
        riskLevels[level] = (riskLevels[level] ?? 0) + 1;
      }

      final averageRiskScore = riskScores.isNotEmpty
          ? riskScores.reduce((a, b) => a + b) / riskScores.length
          : 0.0;

      return {
        'averageRiskScore': averageRiskScore.round(),
        'totalAnalyses': recentLogs.docs.length,
        'riskLevelDistribution': riskLevels,
        'lastAnalysis': recentLogs.docs.isNotEmpty
            ? (recentLogs.docs.first.data()['timestamp'] as Timestamp?)
                ?.toDate()
            : null,
        'shouldBlock': await shouldBlockUser(userId),
      };
    } catch (e) {
      return {
        'averageRiskScore': 0,
        'totalAnalyses': 0,
        'riskLevelDistribution': {},
        'shouldBlock': false,
      };
    }
  }
}

/// Fraud analysis result
class FraudAnalysisResult {
  final int riskScore;
  final RiskLevel riskLevel;
  final ActionRecommendation recommendation;
  final String deviceFingerprint;
  final Map<String, int> factors;
  final String explanation;

  FraudAnalysisResult({
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    required this.deviceFingerprint,
    required this.factors,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'riskScore': riskScore,
        'riskLevel': riskLevel.toString(),
        'recommendation': recommendation.toString(),
        'deviceFingerprint': deviceFingerprint,
        'factors': factors,
        'explanation': explanation,
      };
}

/// Risk levels
enum RiskLevel {
  minimal,
  low,
  medium,
  high,
}

/// Action recommendations
enum ActionRecommendation {
  allow,
  monitor,
  review,
  challenge,
  block,
}
