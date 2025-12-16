import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

class ServerlessFraudDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Fraud detection thresholds
  static const int _maxActivitiesPerHour = 30;
  static const int _maxActivitiesPerDay = 200;
  static const int _suspiciousScoreThreshold = 80;
  static const Duration _cooldownPeriod = Duration(seconds: 30);

  // Generate device fingerprint
  Future<String> generateDeviceFingerprint() async {
    try {
      Map<String, dynamic> deviceData = {};

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'board': androidInfo.board,
          'hardware': androidInfo.hardware,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'machine': iosInfo.utsname.machine,
        };
      }

      final deviceString = json.encode(deviceData);
      final bytes = utf8.encode(deviceString);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Error generating device fingerprint: $e');
      return 'unknown_device';
    }
  }

  // Check if user can perform activity (rate limiting)
  Future<Map<String, dynamic>> checkActivityPermission() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'allowed': false, 'reason': 'User not authenticated'};
      }

      final now = DateTime.now();
      final hourAgo = now.subtract(const Duration(hours: 1));
      final todayStart = DateTime(now.year, now.month, now.day);

      // Check activities in the last hour
      final hourlyActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(hourAgo))
          .get();

      if (hourlyActivities.docs.length >= _maxActivitiesPerHour) {
        return {
          'allowed': false,
          'reason': 'Too many activities in the last hour. Please wait.',
          'waitTime': 3600 -
              (now.millisecondsSinceEpoch - hourAgo.millisecondsSinceEpoch) ~/
                  1000,
        };
      }

      // Check daily activities
      final dailyActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(todayStart))
          .get();

      if (dailyActivities.docs.length >= _maxActivitiesPerDay) {
        return {
          'allowed': false,
          'reason': 'Daily activity limit reached. Try again tomorrow.',
        };
      }

      // Check for cooldown period
      if (dailyActivities.docs.isNotEmpty) {
        final lastActivity =
            dailyActivities.docs.first.data()['timestamp'] as Timestamp;
        final timeSinceLastActivity = now.difference(lastActivity.toDate());

        if (timeSinceLastActivity < _cooldownPeriod) {
          return {
            'allowed': false,
            'reason': 'Please wait before starting another activity.',
            'waitTime':
                _cooldownPeriod.inSeconds - timeSinceLastActivity.inSeconds,
          };
        }
      }

      return {'allowed': true};
    } catch (e) {
      print('Error checking activity permission: $e');
      return {'allowed': false, 'reason': 'Permission check failed'};
    }
  }

  // Record user activity with fraud detection
  Future<bool> recordUserActivity({
    required String activityType,
    required int lpEarned,
    required Map<String, dynamic> activityData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final deviceFingerprint = await generateDeviceFingerprint();
      final now = DateTime.now();
      final todayString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Calculate fraud score
      final fraudScore = await _calculateFraudScore(user.uid, activityData);

      final activityRecord = {
        'userId': user.uid,
        'activityType': activityType,
        'lpEarned': lpEarned,
        'timestamp': FieldValue.serverTimestamp(),
        'date': todayString,
        'deviceFingerprint': deviceFingerprint,
        'fraudScore': fraudScore,
        'activityData': activityData,
        'ipAddress': 'client_side', // Would need additional service for real IP
      };

      // If fraud score is too high, mark as suspicious
      if (fraudScore >= _suspiciousScoreThreshold) {
        activityRecord['flagged'] = true;
        activityRecord['flagReason'] = 'High fraud score: $fraudScore';

        // Don't award LP for suspicious activities
        activityRecord['lpEarned'] = 0;
      }

      await _firestore.collection('user_activities').add(activityRecord);

      // Update user's LP only if activity is not flagged
      if (fraudScore < _suspiciousScoreThreshold) {
        await _updateUserLP(user.uid, lpEarned);
      }

      return fraudScore < _suspiciousScoreThreshold;
    } catch (e) {
      print('Error recording user activity: $e');
      return false;
    }
  }

  // Calculate fraud score based on various factors
  Future<int> _calculateFraudScore(
      String userId, Map<String, dynamic> activityData) async {
    int score = 0;

    try {
      final now = DateTime.now();
      final hourAgo = now.subtract(const Duration(hours: 1));
      final todayStart = DateTime(now.year, now.month, now.day);

      // Check recent activities
      final recentActivities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(hourAgo))
          .get();

      // Frequency-based scoring
      if (recentActivities.docs.length > 20)
        score += 30;
      else if (recentActivities.docs.length > 15)
        score += 20;
      else if (recentActivities.docs.length > 10) score += 10;

      // Pattern analysis
      final timestamps = recentActivities.docs
          .map((doc) => (doc.data()['timestamp'] as Timestamp).toDate())
          .toList();

      if (timestamps.length > 2) {
        // Check for suspiciously regular intervals
        final intervals = <int>[];
        for (int i = 1; i < timestamps.length; i++) {
          intervals
              .add(timestamps[i - 1].difference(timestamps[i]).inSeconds.abs());
        }

        // If intervals are too regular (within 5 seconds), it's suspicious
        final avgInterval =
            intervals.reduce((a, b) => a + b) / intervals.length;
        final variance = intervals
                .map((i) => (i - avgInterval) * (i - avgInterval))
                .reduce((a, b) => a + b) /
            intervals.length;

        if (variance < 25) score += 25; // Very regular pattern
      }

      // Performance-based scoring (too perfect scores are suspicious)
      final correctAnswers = activityData['correctAnswers'] ?? 0;
      final totalQuestions = activityData['totalQuestions'] ?? 1;
      final accuracy = (correctAnswers / totalQuestions * 100).round();

      if (accuracy == 100 && totalQuestions >= 5) score += 15;
      if (accuracy >= 95 && totalQuestions >= 10) score += 10;

      // Time-based scoring (too fast completion)
      final timeTaken = activityData['timeTaken'] ?? 0;
      final averageTimePerQuestion =
          totalQuestions > 0 ? timeTaken / totalQuestions : 0;

      if (averageTimePerQuestion < 2000)
        score += 20; // Less than 2 seconds per question
      if (averageTimePerQuestion < 1000)
        score += 30; // Less than 1 second per question

      // Device fingerprint analysis
      final deviceFingerprint = await generateDeviceFingerprint();
      final deviceActivities = await _firestore
          .collection('user_activities')
          .where('deviceFingerprint', isEqualTo: deviceFingerprint)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(todayStart))
          .get();

      // Multiple users from same device
      final uniqueUsers =
          deviceActivities.docs.map((doc) => doc.data()['userId']).toSet();

      if (uniqueUsers.length > 3) score += 25;
      if (uniqueUsers.length > 5) score += 40;
    } catch (e) {
      print('Error calculating fraud score: $e');
      score += 10; // Add penalty for calculation errors
    }

    return score.clamp(0, 100);
  }

  // Update user's Learning Points
  Future<void> _updateUserLP(String userId, int lpToAdd) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          final currentLP = userSnapshot.data()!['learningPoints'] ?? 0;
          transaction.update(userRef, {
            'learningPoints': currentLP + lpToAdd,
            'lastActivityTimestamp': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error updating user LP: $e');
    }
  }

  // Get user's fraud status
  Future<Map<String, dynamic>> getUserFraudStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final activities = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      int flaggedCount = 0;
      int totalActivities = activities.docs.length;
      double averageFraudScore = 0;

      for (final doc in activities.docs) {
        final data = doc.data();
        if (data['flagged'] == true) flaggedCount++;
        averageFraudScore += (data['fraudScore'] ?? 0);
      }

      if (totalActivities > 0) {
        averageFraudScore /= totalActivities;
      }

      final flaggedPercentage =
          totalActivities > 0 ? (flaggedCount / totalActivities * 100) : 0.0;

      return {
        'totalActivities': totalActivities,
        'flaggedActivities': flaggedCount,
        'flaggedPercentage': flaggedPercentage.round(),
        'averageFraudScore': averageFraudScore.round(),
        'riskLevel': _getRiskLevel(averageFraudScore, flaggedPercentage),
      };
    } catch (e) {
      print('Error getting fraud status: $e');
      return {};
    }
  }

  String _getRiskLevel(double avgScore, double flaggedPercentage) {
    if (avgScore >= 70 || flaggedPercentage >= 50) return 'HIGH';
    if (avgScore >= 40 || flaggedPercentage >= 25) return 'MEDIUM';
    return 'LOW';
  }

  // Check if user is currently flagged
  Future<bool> isUserFlagged() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['flagged'] == true;
    } catch (e) {
      print('Error checking user flag status: $e');
      return false;
    }
  }

  // Clear user flags (for admin use)
  Future<bool> clearUserFlags(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'flagged': false,
        'flagReason': FieldValue.delete(),
        'flaggedTimestamp': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      print('Error clearing user flags: $e');
      return false;
    }
  }

  Future assessActivityRisk({required String activityType, required String userId, required deviceInfo}) async {
    //TODO: Complete this function logic
  }
}
