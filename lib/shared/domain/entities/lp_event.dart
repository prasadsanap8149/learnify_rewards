enum LPEventType {
  earned, // User earned LP
  redeemed, // User redeemed LP
  transferred, // LP transferred between pools
  distributed, // LP distributed from pool
  adjusted, // Manual adjustment by admin
  expired, // LP expired
  bonus, // Bonus LP awarded
  penalty, // LP deducted as penalty
}

enum LPSource {
  activity, // From completing activities
  referral, // From referrals
  bonus, // Bonus LP
  admin, // Admin granted
  streak, // Streak bonus
  achievement, // Achievement reward
  promotion, // Promotional LP
}

class LPEvent {
  final String id;
  final String userId;
  final LPEventType type;
  final LPSource source;
  final int amount;
  final int previousBalance;
  final int newBalance;
  final String? sourceId; // Activity ID, referral ID, etc.
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? adminId; // For admin actions

  LPEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.source,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    this.sourceId,
    this.description,
    this.metadata,
    required this.timestamp,
    this.adminId,
  });

  factory LPEvent.fromJson(Map<String, dynamic> json) {
    return LPEvent(
      id: json['id'],
      userId: json['userId'],
      type: LPEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      source: LPSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['source'],
      ),
      amount: json['amount'],
      previousBalance: json['previousBalance'],
      newBalance: json['newBalance'],
      sourceId: json['sourceId'],
      description: json['description'],
      metadata: json['metadata'],
      timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
      adminId: json['adminId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'source': source.toString().split('.').last,
      'amount': amount,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'sourceId': sourceId,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp,
      'adminId': adminId,
    };
  }
}
