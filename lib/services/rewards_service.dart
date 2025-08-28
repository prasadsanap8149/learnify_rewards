import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mobile-first service for rewards and redemption management
/// Handles LP spending, reward catalog, and redemption tracking
class RewardsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get available rewards catalog
  static Stream<List<Map<String, dynamic>>> getAvailableRewards({
    String? category,
    double? maxCost,
    bool onlyAvailable = true,
    int limit = 20,
  }) {
    Query query = _firestore.collection('rewards');

    if (onlyAvailable) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (maxCost != null) {
      query = query.where('lpCost', isLessThanOrEqualTo: maxCost);
    }

    return query.orderBy('lpCost').limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get user's redemption history
  static Stream<List<Map<String, dynamic>>> getUserRedemptions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('redemptions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Redeem a reward using LP
  static Future<Map<String, dynamic>?> redeemReward({
    required String rewardId,
    Map<String, dynamic>? redemptionData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get reward details
      final rewardDoc =
          await _firestore.collection('rewards').doc(rewardId).get();
      if (!rewardDoc.exists) return null;

      final rewardData = rewardDoc.data()!;
      final lpCost = (rewardData['lpCost'] as num).toDouble();
      final isActive = rewardData['isActive'] ?? false;
      final stock = rewardData['stock'] as int?;

      if (!isActive) {
        return {'success': false, 'error': 'Reward is not available'};
      }

      if (stock != null && stock <= 0) {
        return {'success': false, 'error': 'Reward is out of stock'};
      }

      // Check user's LP balance
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final currentBalance = (userData['lpBalance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < lpCost) {
        return {
          'success': false,
          'error': 'Insufficient LP balance',
          'required': lpCost,
          'current': currentBalance,
        };
      }

      // Create redemption record
      final timestamp = DateTime.now();
      final redemptionId =
          'red_${timestamp.millisecondsSinceEpoch}_${user.uid}';

      final redemption = {
        'id': redemptionId,
        'userId': user.uid,
        'rewardId': rewardId,
        'rewardTitle': rewardData['title'],
        'rewardCategory': rewardData['category'],
        'lpCost': lpCost,
        'status': 'pending', // pending, processing, fulfilled, cancelled
        'redeemedAt': Timestamp.fromDate(timestamp),
        'fulfilledAt': null,
        'fulfillmentMethod': rewardData['fulfillmentMethod'] ?? 'manual',
        'deliveryInfo': redemptionData?['deliveryInfo'] ?? {},
        'metadata': {
          'rewardData': rewardData,
          'redemptionData': redemptionData ?? {},
        },
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      // Start batch transaction
      final batch = _firestore.batch();

      // Create redemption record
      batch.set(
          _firestore.collection('redemptions').doc(redemptionId), redemption);

      // Update user LP balance (using LPService logic)
      final newBalance = currentBalance - lpCost;
      batch.update(_firestore.collection('users').doc(user.uid), {
        'lpBalance': newBalance,
        'totalLPSpent': FieldValue.increment(lpCost),
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      // Create LP event record
      final lpEventId = 'lp_${timestamp.millisecondsSinceEpoch}_${user.uid}';
      final lpEvent = {
        'id': lpEventId,
        'userId': user.uid,
        'type': 'spend',
        'amount': lpCost,
        'source': 'reward_redemption',
        'sourceId': rewardId,
        'description': 'Redeemed: ${rewardData['title']}',
        'previousBalance': currentBalance,
        'newBalance': newBalance,
        'metadata': {
          'rewardId': rewardId,
          'redemptionId': redemptionId,
          'rewardTitle': rewardData['title'],
        },
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      batch.set(_firestore.collection('lp_events').doc(lpEventId), lpEvent);

      // Update reward stock if applicable
      if (stock != null) {
        batch.update(_firestore.collection('rewards').doc(rewardId), {
          'stock': stock - 1,
          'stats.totalRedeemed': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(timestamp),
        });
      }

      // Commit the transaction
      await batch.commit();

      // Handle auto-fulfillment for digital rewards
      if (rewardData['fulfillmentMethod'] == 'auto') {
        await _autoFulfillReward(redemptionId, rewardData);
      }

      return {
        'success': true,
        'redemptionId': redemptionId,
        'newBalance': newBalance,
        'redemption': redemption,
      };
    } catch (e) {
      print('Error redeeming reward: $e');
      return {'success': false, 'error': 'Failed to redeem reward'};
    }
  }

  /// Auto-fulfill digital rewards (codes, vouchers, etc.)
  static Future<bool> _autoFulfillReward(
      String redemptionId, Map<String, dynamic> rewardData) async {
    try {
      String? fulfillmentCode;
      String fulfillmentDetails = '';

      // Generate fulfillment based on reward type
      switch (rewardData['type']) {
        case 'gift_card':
          fulfillmentCode = _generateGiftCardCode();
          fulfillmentDetails = 'Gift card code: $fulfillmentCode';
          break;
        case 'discount_code':
          fulfillmentCode = _generateDiscountCode();
          fulfillmentDetails =
              'Discount code: $fulfillmentCode (${rewardData['discountPercent']}% off)';
          break;
        case 'digital_item':
          fulfillmentCode = _generateDigitalItemCode();
          fulfillmentDetails = 'Digital item code: $fulfillmentCode';
          break;
        default:
          // Manual fulfillment required
          return false;
      }

      // Update redemption with fulfillment information
      await _firestore.collection('redemptions').doc(redemptionId).update({
        'status': 'fulfilled',
        'fulfilledAt': Timestamp.fromDate(DateTime.now()),
        'fulfillmentCode': fulfillmentCode,
        'fulfillmentDetails': fulfillmentDetails,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error auto-fulfilling reward: $e');
      return false;
    }
  }

  /// Generate gift card code (mock implementation)
  static String _generateGiftCardCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'GC${random.toString().substring(random.toString().length - 8)}';
  }

  /// Generate discount code (mock implementation)
  static String _generateDiscountCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'SAVE${random.toString().substring(random.toString().length - 6)}';
  }

  /// Generate digital item code (mock implementation)
  static String _generateDigitalItemCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'DIG${random.toString().substring(random.toString().length - 8)}';
  }

  /// Get specific reward details
  static Future<Map<String, dynamic>?> getRewardDetails(String rewardId) async {
    try {
      final rewardDoc =
          await _firestore.collection('rewards').doc(rewardId).get();
      if (!rewardDoc.exists) return null;

      final data = rewardDoc.data()!;
      data['id'] = rewardDoc.id;
      return data;
    } catch (e) {
      print('Error getting reward details: $e');
      return null;
    }
  }

  /// Get redemption details
  static Future<Map<String, dynamic>?> getRedemptionDetails(
      String redemptionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final redemptionDoc =
          await _firestore.collection('redemptions').doc(redemptionId).get();
      if (!redemptionDoc.exists) return null;

      final data = redemptionDoc.data()!;

      // Verify this belongs to the current user
      if (data['userId'] != user.uid) return null;

      data['id'] = redemptionDoc.id;
      return data;
    } catch (e) {
      print('Error getting redemption details: $e');
      return null;
    }
  }

  /// Search rewards
  static Stream<List<Map<String, dynamic>>> searchRewards({
    required String searchTerm,
    String? category,
    double? maxCost,
    int limit = 20,
  }) {
    Query query =
        _firestore.collection('rewards').where('isActive', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (maxCost != null) {
      query = query.where('lpCost', isLessThanOrEqualTo: maxCost);
    }

    return query
        .limit(limit * 2) // Get more results to filter client-side
        .snapshots()
        .map((snapshot) {
      final searchLower = searchTerm.toLowerCase();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((reward) {
            final title = (reward['title'] as String? ?? '').toLowerCase();
            final description =
                (reward['description'] as String? ?? '').toLowerCase();
            final category =
                (reward['category'] as String? ?? '').toLowerCase();

            return title.contains(searchLower) ||
                description.contains(searchLower) ||
                category.contains(searchLower);
          })
          .take(limit)
          .toList();
    });
  }

  /// Get user's recommended rewards based on preferences and LP balance
  static Future<List<Map<String, dynamic>>> getRecommendedRewards(
      {int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get user's LP balance
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final lpBalance = (userData['lpBalance'] as num?)?.toDouble() ?? 0.0;

      // Get user's redemption history to understand preferences
      final redemptions = await _firestore
          .collection('redemptions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('redeemedAt', descending: true)
          .limit(10)
          .get();

      final preferredCategories = <String>{};
      for (final doc in redemptions.docs) {
        final category = doc.data()['rewardCategory'];
        if (category != null) preferredCategories.add(category);
      }

      Query query = _firestore
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .where('lpCost', isLessThanOrEqualTo: lpBalance);

      // If user has preferred categories, filter by those
      if (preferredCategories.isNotEmpty) {
        query = query.where('category',
            whereIn: preferredCategories.take(10).toList());
      }

      final recommendations = await query.limit(limit).get();

      return recommendations.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting recommended rewards: $e');
      return [];
    }
  }

  /// Get rewards by category
  static Stream<List<Map<String, dynamic>>> getRewardsByCategory(
      String category) {
    return _firestore
        .collection('rewards')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('lpCost')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Cancel a pending redemption (if cancellation is allowed)
  static Future<bool> cancelRedemption(String redemptionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get redemption details
      final redemptionDoc =
          await _firestore.collection('redemptions').doc(redemptionId).get();
      if (!redemptionDoc.exists) return false;

      final redemptionData = redemptionDoc.data()!;

      // Verify ownership and cancellability
      if (redemptionData['userId'] != user.uid) return false;
      if (redemptionData['status'] != 'pending') return false;

      final lpCost = (redemptionData['lpCost'] as num).toDouble();
      final timestamp = DateTime.now();

      // Start batch transaction to refund LP and cancel redemption
      final batch = _firestore.batch();

      // Update redemption status
      batch.update(_firestore.collection('redemptions').doc(redemptionId), {
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      // Refund LP to user
      batch.update(_firestore.collection('users').doc(user.uid), {
        'lpBalance': FieldValue.increment(lpCost),
        'totalLPSpent': FieldValue.increment(-lpCost),
        'updatedAt': Timestamp.fromDate(timestamp),
      });

      // Create LP refund event
      final lpEventId = 'lp_${timestamp.millisecondsSinceEpoch}_${user.uid}';
      final lpEvent = {
        'id': lpEventId,
        'userId': user.uid,
        'type': 'refund',
        'amount': lpCost,
        'source': 'redemption_cancelled',
        'sourceId': redemptionId,
        'description':
            'Refund for cancelled redemption: ${redemptionData['rewardTitle']}',
        'metadata': {
          'redemptionId': redemptionId,
          'rewardId': redemptionData['rewardId'],
          'rewardTitle': redemptionData['rewardTitle'],
        },
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      };

      batch.set(_firestore.collection('lp_events').doc(lpEventId), lpEvent);

      // Restore reward stock if applicable
      final rewardId = redemptionData['rewardId'];
      final rewardDoc =
          await _firestore.collection('rewards').doc(rewardId).get();
      if (rewardDoc.exists) {
        final rewardData = rewardDoc.data()!;
        if (rewardData['stock'] != null) {
          batch.update(_firestore.collection('rewards').doc(rewardId), {
            'stock': FieldValue.increment(1),
            'stats.totalRedeemed': FieldValue.increment(-1),
            'updatedAt': Timestamp.fromDate(timestamp),
          });
        }
      }

      // Commit the transaction
      await batch.commit();

      return true;
    } catch (e) {
      print('Error cancelling redemption: $e');
      return false;
    }
  }

  /// Get user's total LP earned and spent statistics
  static Future<Map<String, dynamic>> getUserLPStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;

      return {
        'currentBalance': (userData['lpBalance'] as num?)?.toDouble() ?? 0.0,
        'totalEarned': (userData['totalLPEarned'] as num?)?.toDouble() ?? 0.0,
        'totalSpent': (userData['totalLPSpent'] as num?)?.toDouble() ?? 0.0,
        'level': userData['level'] ?? 1,
        'experience': userData['experience'] ?? 0,
      };
    } catch (e) {
      print('Error getting user LP stats: $e');
      return {};
    }
  }
}
