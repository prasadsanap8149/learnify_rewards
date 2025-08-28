import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lp_event.dart';

class FirestoreLPEventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'lp_events';

  // Create LP Event
  Future<void> createLPEvent(LPEvent event) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(event.id)
          .set(event.toJson());
    } catch (e) {
      throw Exception('Failed to create LP event: $e');
    }
  }

  // Get LP Events for user
  Stream<List<LPEvent>> getLPEventsStream(
    String userId, {
    LPEventType? type,
    LPSource? source,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (source != null) {
        query =
            query.where('source', isEqualTo: source.toString().split('.').last);
      }

      return query.limit(limit).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return LPEvent.fromJson(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get LP events stream: $e');
    }
  }

  // Get LP Events by date range
  Future<List<LPEvent>> getLPEventsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LPEvent.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get LP events by date range: $e');
    }
  }

  // Calculate total LP earned
  Future<int> getTotalLPEarned(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'earned')
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate total LP earned: $e');
    }
  }

  // Calculate total LP redeemed
  Future<int> getTotalLPRedeemed(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'redeemed')
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate total LP redeemed: $e');
    }
  }

  // Get LP balance (most recent event's new balance)
  Future<int> getCurrentLPBalance(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      final data = snapshot.docs.first.data();
      return data['newBalance'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get current LP balance: $e');
    }
  }

  // Delete LP event (admin only)
  Future<void> deleteLPEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete LP event: $e');
    }
  }

  // Get LP events for admin review
  Future<List<LPEvent>> getLPEventsForReview({
    LPEventType? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return LPEvent.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get LP events for review: $e');
    }
  }
}
