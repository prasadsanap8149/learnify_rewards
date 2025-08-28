import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'security_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: () => _notificationService.markAllAsRead(),
                  child: Text('Mark all read ($unreadCount)'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading notifications: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see updates about your activities, rewards, and more here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismiss: () =>
                    _notificationService.deleteNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read if not already
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.activity:
        // Navigate to activity details or completion screen
        _showNotificationDetails(notification);
        break;
      case NotificationType.reward:
        // Navigate to rewards screen
        _showNotificationDetails(notification);
        break;
      case NotificationType.achievement:
        // Show achievement details
        _showNotificationDetails(notification);
        break;
      case NotificationType.withdrawal:
        // Navigate to withdrawal history
        _showNotificationDetails(notification);
        break;
      case NotificationType.earning:
        // Navigate to earnings screen
        _showNotificationDetails(notification);
        break;
      case NotificationType.security:
        // Show security alert details
        _showSecurityAlert(notification);
        break;
      case NotificationType.system:
        // Show system message
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatTimestamp(notification.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Details:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...notification.data.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSecurityAlert(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            const Text(
              'If you didn\'t expect this activity, please review your account security.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecuritySettingsScreen(),
                ),
              );
            },
            child: const Text('Review Security'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'This will permanently delete all your notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notificationService.clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.grey.shade300
              : _getTypeColor(notification.type),
          child: Icon(
            _getTypeIcon(notification.type),
            color: notification.isRead ? Colors.grey : Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reward:
        return Icons.card_giftcard;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.activity:
        return Icons.school;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.withdrawal:
        return Icons.account_balance_wallet;
      case NotificationType.earning:
        return Icons.monetization_on;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.reward:
        return Colors.purple;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.activity:
        return Colors.blue;
      case NotificationType.security:
        return Colors.red;
      case NotificationType.withdrawal:
        return Colors.green;
      case NotificationType.earning:
        return Colors.teal;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
