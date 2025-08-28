import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsPool {
  final String id;
  final String name;
  final String description;
  final double totalAmount;
  final double remainingAmount;
  final DateTime startDate;
  final DateTime endDate;
  final EarningsPoolType type;
  final EarningsPoolStatus status;
  final Map<String, dynamic> distributionCriteria;
  final double? maxPerUser;
  final int? maxParticipants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastDistribution;
  final DateTime? closedAt;
  final int participantCount;
  final double distributedAmount;

  EarningsPool({
    required this.id,
    required this.name,
    required this.description,
    required this.totalAmount,
    required this.remainingAmount,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    required this.distributionCriteria,
    this.maxPerUser,
    this.maxParticipants,
    required this.createdAt,
    required this.updatedAt,
    this.lastDistribution,
    this.closedAt,
    this.participantCount = 0,
    this.distributedAmount = 0.0,
  });

  factory EarningsPool.fromJson(Map<String, dynamic> json) {
    return EarningsPool(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: _parseTimestamp(json['startDate']),
      endDate: _parseTimestamp(json['endDate']),
      type: EarningsPoolType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => EarningsPoolType.activity,
      ),
      status: EarningsPoolStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EarningsPoolStatus.scheduled,
      ),
      distributionCriteria:
          Map<String, dynamic>.from(json['distributionCriteria'] ?? {}),
      maxPerUser: (json['maxPerUser'] as num?)?.toDouble(),
      maxParticipants: json['maxParticipants'] as int?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      lastDistribution: json['lastDistribution'] != null
          ? _parseTimestamp(json['lastDistribution'])
          : null,
      closedAt:
          json['closedAt'] != null ? _parseTimestamp(json['closedAt']) : null,
      participantCount: json['participantCount'] as int? ?? 0,
      distributedAmount: (json['distributedAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'type': type.toString(),
      'status': status.toString(),
      'distributionCriteria': distributionCriteria,
      'maxPerUser': maxPerUser,
      'maxParticipants': maxParticipants,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastDistribution': lastDistribution != null
          ? Timestamp.fromDate(lastDistribution!)
          : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'participantCount': participantCount,
      'distributedAmount': distributedAmount,
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

  EarningsPool copyWith({
    String? id,
    String? name,
    String? description,
    double? totalAmount,
    double? remainingAmount,
    DateTime? startDate,
    DateTime? endDate,
    EarningsPoolType? type,
    EarningsPoolStatus? status,
    Map<String, dynamic>? distributionCriteria,
    double? maxPerUser,
    int? maxParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastDistribution,
    DateTime? closedAt,
    int? participantCount,
    double? distributedAmount,
  }) {
    return EarningsPool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      distributionCriteria: distributionCriteria ?? this.distributionCriteria,
      maxPerUser: maxPerUser ?? this.maxPerUser,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastDistribution: lastDistribution ?? this.lastDistribution,
      closedAt: closedAt ?? this.closedAt,
      participantCount: participantCount ?? this.participantCount,
      distributedAmount: distributedAmount ?? this.distributedAmount,
    );
  }

  /// Check if pool is currently active
  bool get isActive =>
      status == EarningsPoolStatus.active &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  /// Check if pool has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  /// Check if pool has started
  bool get hasStarted => DateTime.now().isAfter(startDate);

  /// Get pool completion percentage
  double get completionPercentage {
    if (totalAmount <= 0) return 0.0;
    return ((totalAmount - remainingAmount) / totalAmount * 100)
        .clamp(0.0, 100.0);
  }

  /// Check if pool has reached max participants
  bool get hasReachedMaxParticipants {
    return maxParticipants != null && participantCount >= maxParticipants!;
  }

  /// Get formatted total amount
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  /// Get formatted remaining amount
  String get formattedRemainingAmount =>
      '\$${remainingAmount.toStringAsFixed(2)}';

  /// Get formatted distributed amount
  String get formattedDistributedAmount =>
      '\$${distributedAmount.toStringAsFixed(2)}';

  /// Get pool status display text
  String get statusDisplayText {
    switch (status) {
      case EarningsPoolStatus.scheduled:
        return 'Scheduled';
      case EarningsPoolStatus.active:
        return 'Active';
      case EarningsPoolStatus.paused:
        return 'Paused';
      case EarningsPoolStatus.closed:
        return 'Closed';
      case EarningsPoolStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get pool type display text
  String get typeDisplayText {
    switch (type) {
      case EarningsPoolType.activity:
        return 'Activity Rewards';
      case EarningsPoolType.bonus:
        return 'Bonus Pool';
      case EarningsPoolType.referral:
        return 'Referral Rewards';
      case EarningsPoolType.milestone:
        return 'Milestone Rewards';
    }
  }

  @override
  String toString() {
    return 'EarningsPool(id: $id, name: $name, totalAmount: $totalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EarningsPool && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Earnings pool types
enum EarningsPoolType {
  activity, // Activity-based earnings
  bonus, // Bonus distributions
  referral, // Referral rewards
  milestone, // Milestone achievements
}

/// Earnings pool status
enum EarningsPoolStatus {
  scheduled, // Scheduled for future activation
  active, // Currently active
  paused, // Temporarily paused
  closed, // Permanently closed
  cancelled, // Cancelled before activation
}
