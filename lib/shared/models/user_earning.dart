import 'package:cloud_firestore/cloud_firestore.dart';

class UserEarning {
  final String id;
  final String userId;
  final String poolId;
  final double amount;
  final EarningType type;
  final DateTime timestamp;
  final EarningStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime? processedAt;
  final String? error;
  final String? transactionId;

  UserEarning({
    required this.id,
    required this.userId,
    required this.poolId,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.status,
    this.metadata,
    this.processedAt,
    this.error,
    this.transactionId,
  });

  factory UserEarning.fromJson(Map<String, dynamic> json) {
    return UserEarning(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      poolId: json['poolId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: EarningType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => EarningType.activity,
      ),
      timestamp: _parseTimestamp(json['timestamp']),
      status: EarningStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EarningStatus.pending,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      processedAt: json['processedAt'] != null
          ? _parseTimestamp(json['processedAt'])
          : null,
      error: json['error'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'poolId': poolId,
      'amount': amount,
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString(),
      'metadata': metadata,
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'error': error,
      'transactionId': transactionId,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  UserEarning copyWith({
    String? id,
    String? userId,
    String? poolId,
    double? amount,
    EarningType? type,
    DateTime? timestamp,
    EarningStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? processedAt,
    String? error,
    String? transactionId,
  }) {
    return UserEarning(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      poolId: poolId ?? this.poolId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      processedAt: processedAt ?? this.processedAt,
      error: error ?? this.error,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  /// Get formatted amount
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case EarningStatus.pending:
        return 'Pending';
      case EarningStatus.processed:
        return 'Processed';
      case EarningStatus.failed:
        return 'Failed';
      case EarningStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get type display text
  String get typeDisplayText {
    switch (type) {
      case EarningType.activity:
        return 'Activity Reward';
      case EarningType.bonus:
        return 'Bonus';
      case EarningType.referral:
        return 'Referral Reward';
      case EarningType.milestone:
        return 'Milestone Achievement';
    }
  }

  /// Check if earning is successful
  bool get isSuccessful => status == EarningStatus.processed;

  /// Check if earning is failed
  bool get isFailed => status == EarningStatus.failed;

  /// Check if earning is pending
  bool get isPending => status == EarningStatus.pending;

  /// Get pool name from metadata
  String? get poolName => metadata?['poolName'] as String?;

  /// Get distribution method from metadata
  String? get distributionMethod => metadata?['distributionMethod'] as String?;

  /// Get distribution date from metadata
  DateTime? get distributionDate {
    final dateString = metadata?['distributionDate'] as String?;
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'UserEarning(id: $id, userId: $userId, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEarning && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Earning status
enum EarningStatus {
  pending, // Earned but not yet processed
  processed, // Processed and added to user account
  failed, // Processing failed
  cancelled, // Cancelled
}

/// Earning types
enum EarningType {
  activity, // Activity completion reward
  bonus, // Bonus reward
  referral, // Referral reward
  milestone, // Milestone achievement
}
