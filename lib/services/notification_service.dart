import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum NotificationType {
  reward,
  achievement,
  activity,
  security,
  system,
  withdrawal,
  earning,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.system,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['isRead'] ?? false,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a notification for a user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _firestore.collection('notifications').doc().id;

      final notification = NotificationItem(
        id: notificationId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        data: data ?? {},
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toJson());

      // Also update user's notification count
      await _firestore.collection('users').doc(userId).update({
        'unreadNotifications': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Get notifications for current user
  Stream<List<NotificationItem>> getUserNotifications({int limit = 20}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromJson(doc.data()))
            .toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Decrement unread count
      await _firestore.collection('users').doc(user.uid).update({
        'unreadNotifications': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final unreadNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('users').doc(user.uid).update({
        'unreadNotifications': 0,
      });
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final notificationRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId);

      final notificationDoc = await notificationRef.get();
      if (notificationDoc.exists) {
        final isRead = notificationDoc.data()?['isRead'] ?? false;

        await notificationRef.delete();

        // Decrement unread count if notification was unread
        if (!isRead) {
          await _firestore.collection('users').doc(user.uid).update({
            'unreadNotifications': FieldValue.increment(-1),
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore.collection('users').doc(user.uid).snapshots().map(
        (snapshot) => (snapshot.data()?['unreadNotifications'] as int?) ?? 0);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('users').doc(user.uid).update({
        'unreadNotifications': 0,
      });
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  /// Create achievement notification
  Future<void> notifyAchievement({
    required String userId,
    required String achievementTitle,
    required String description,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Achievement Unlocked! 🏆',
      message: 'You earned "$achievementTitle" - $description',
      type: NotificationType.achievement,
      data: {
        'achievementTitle': achievementTitle,
        'description': description,
      },
    );
  }

  /// Create reward notification
  Future<void> notifyReward({
    required String userId,
    required String rewardName,
    required double lpAmount,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Reward Earned! 🎁',
      message: 'You earned $lpAmount LP from "$rewardName"',
      type: NotificationType.reward,
      data: {
        'rewardName': rewardName,
        'lpAmount': lpAmount,
      },
    );
  }

  /// Create activity completion notification
  Future<void> notifyActivityComplete({
    required String userId,
    required String activityTitle,
    required double lpEarned,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Activity Completed! 📚',
      message:
          'Great job! You completed "$activityTitle" and earned $lpEarned LP',
      type: NotificationType.activity,
      data: {
        'activityTitle': activityTitle,
        'lpEarned': lpEarned,
      },
    );
  }

  /// Create security alert notification
  Future<void> notifySecurityAlert({
    required String userId,
    required String alertType,
    required String description,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Security Alert ⚠️',
      message: '$alertType: $description',
      type: NotificationType.security,
      data: {
        'alertType': alertType,
        'description': description,
      },
    );
  }

  /// Create withdrawal notification
  Future<void> notifyWithdrawal({
    required String userId,
    required String status,
    required double amount,
    String? reason,
  }) async {
    final statusMessage = status == 'approved'
        ? 'Your withdrawal of \$${amount.toStringAsFixed(2)} has been approved!'
        : 'Your withdrawal of \$${amount.toStringAsFixed(2)} was $status${reason != null ? ': $reason' : ''}';

    await createNotification(
      userId: userId,
      title: 'Withdrawal Update 💰',
      message: statusMessage,
      type: NotificationType.withdrawal,
      data: {
        'status': status,
        'amount': amount,
        'reason': reason,
      },
    );
  }

  /// Create earning notification
  Future<void> notifyEarning({
    required String userId,
    required double amount,
    required String source,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Earning! 💰',
      message: 'You earned \$${amount.toStringAsFixed(2)} from $source',
      type: NotificationType.earning,
      data: {
        'amount': amount,
        'source': source,
      },
    );
  }
}
