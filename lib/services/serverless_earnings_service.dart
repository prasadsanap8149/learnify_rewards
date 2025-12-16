import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServerlessEarningsService {
  static const double _lpToEarningsRate = 0.01; // 1 LP = 0.01 rupees
  static const int _minConversionLP = 1000; // Minimum 1000 LP to convert
  static const int _dailyLPLimit = 5000; // Daily LP earning limit per user

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Client-side earnings calculation - runs when user opens app
  Future<Map<String, dynamic>?> checkAndCalculateDailyEarnings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final lastCalculation = userData['lastEarningsCalculation'] as Timestamp?;
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Check if earnings already calculated today
      if (lastCalculation != null) {
        final lastCalculationDate = lastCalculation.toDate();
        final lastDateString =
            '${lastCalculationDate.year}-${lastCalculationDate.month.toString().padLeft(2, '0')}-${lastCalculationDate.day.toString().padLeft(2, '0')}';

        if (lastDateString == todayString) {
          return null; // Already calculated today
        }
      }

      final currentLP = userData['learningPoints'] ?? 0;

      // Only convert if user has minimum LP
      if (currentLP < _minConversionLP) {
        return null;
      }

      return await _performEarningsConversion(user.uid, currentLP, true);
    } catch (e) {
      print('Error in daily earnings calculation: $e');
      return null;
    }
  }

  // Manual LP to earnings conversion
  Future<Map<String, dynamic>> convertLPToEarnings(int lpAmount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      if (lpAmount < _minConversionLP) {
        return {
          'success': false,
          'error': 'Minimum $_minConversionLP LP required for conversion'
        };
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return {'success': false, 'error': 'User not found'};
      }

      final currentLP = userDoc.data()!['learningPoints'] ?? 0;
      if (currentLP < lpAmount) {
        return {'success': false, 'error': 'Insufficient Learning Points'};
      }

      return await _performEarningsConversion(user.uid, lpAmount, false);
    } catch (e) {
      print('Error converting LP to earnings: $e');
      return {'success': false, 'error': 'Conversion failed'};
    }
  }

  // Core conversion logic
  Future<Map<String, dynamic>> _performEarningsConversion(
      String userId, int lpAmount, bool isDailyAutomatic) async {
    try {
      final earningsAmount = (lpAmount * _lpToEarningsRate * 100).floor() / 100;
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Use Firestore transaction for atomic updates
      return await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception('User not found');
        }

        final userData = userSnapshot.data()!;
        final currentEarnings = (userData['totalEarnings'] ?? 0.0).toDouble();
        final currentLP = userData['learningPoints'] ?? 0;

        if (currentLP < lpAmount) {
          throw Exception('Insufficient LP balance');
        }

        // Update user document
        transaction.update(userRef, {
          'totalEarnings': currentEarnings + earningsAmount,
          'learningPoints': isDailyAutomatic ? 0 : (currentLP - lpAmount),
          'lastEarningsCalculation': FieldValue.serverTimestamp(),
        });

        // Create earnings history record
        final earningsHistoryRef = userRef.collection('earnings_history').doc();
        transaction.set(earningsHistoryRef, {
          'totalLP': lpAmount,
          'conversionRate': _lpToEarningsRate,
          'earningsAmount': earningsAmount,
          'date': todayString,
          'timestamp': FieldValue.serverTimestamp(),
          'calculationType':
              isDailyAutomatic ? 'daily_automatic' : 'manual_conversion',
        });

        return {
          'success': true,
          'lpConverted': lpAmount,
          'earningsAdded': earningsAmount,
          'conversionRate': _lpToEarningsRate,
          'newTotalEarnings': currentEarnings + earningsAmount,
        };
      });
    } catch (e) {
      print('Error in earnings conversion: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check daily LP earning limit
  Future<bool> canEarnLP(String userId, int lpToAdd) async {
    try {
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final activitiesQuery = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: todayString)
          .get();

      int totalLPToday = 0;
      for (final doc in activitiesQuery.docs) {
        totalLPToday += (doc.data()['lpEarned'] ?? 0) as int;
      }

      return (totalLPToday + lpToAdd) <= _dailyLPLimit;
    } catch (e) {
      print('Error checking LP limit: $e');
      return false;
    }
  }

  // Get user earnings history
  Future<List<Map<String, dynamic>>> getEarningsHistory(
      {int limit = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('earnings_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error fetching earnings history: $e');
      return [];
    }
  }

  // Get current conversion rate and minimum LP
  Map<String, dynamic> getConversionInfo() {
    return {
      'conversionRate': _lpToEarningsRate,
      'minimumLP': _minConversionLP,
      'dailyLPLimit': _dailyLPLimit,
    };
  }

  // Calculate potential earnings from current LP
  double calculatePotentialEarnings(int currentLP) {
    if (currentLP < _minConversionLP) return 0.0;
    return (currentLP * _lpToEarningsRate * 100).floor() / 100;
  }

  // Get earnings statistics for display
  Future<Map<String, dynamic>> getUserEarningsStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;
      final totalEarnings = (userData['totalEarnings'] ?? 0.0).toDouble();
      final currentLP = userData['learningPoints'] ?? 0;
      final potentialEarnings = calculatePotentialEarnings(currentLP);

      // Get total conversions count
      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('earnings_history')
          .get();

      return {
        'totalEarnings': totalEarnings,
        'currentLP': currentLP,
        'potentialEarnings': potentialEarnings,
        'totalConversions': historySnapshot.docs.length,
        'canConvert': currentLP >= _minConversionLP,
      };
    } catch (e) {
      print('Error fetching earnings stats: $e');
      return {};
    }
  }
}
