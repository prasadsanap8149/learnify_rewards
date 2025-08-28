enum AuditAction {
  create,
  read,
  update,
  delete,
  login,
  logout,
  withdraw,
  transfer,
  flag,
  unflag,
  suspend,
  unsuspend,
  verify,
  approve,
  reject,
}

enum AuditEntity {
  user,
  activity,
  earnings,
  withdrawal,
  lpEvent,
  adEvent,
  aerEvent,
  securityEvent,
  configuration,
  system,
}

class AuditLog {
  final String id;
  final String userId;
  final String? adminId; // If action performed by admin
  final AuditAction action;
  final AuditEntity entity;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? reason; // For admin actions
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    this.adminId,
    required this.action,
    required this.entity,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.reason,
    this.metadata,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['userId'],
      adminId: json['adminId'],
      action: AuditAction.values.firstWhere(
        (e) => e.toString().split('.').last == json['action'],
      ),
      entity: AuditEntity.values.firstWhere(
        (e) => e.toString().split('.').last == json['entity'],
      ),
      entityId: json['entityId'],
      oldValues: json['oldValues'],
      newValues: json['newValues'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      reason: json['reason'],
      metadata: json['metadata'],
      timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'adminId': adminId,
      'action': action.toString().split('.').last,
      'entity': entity.toString().split('.').last,
      'entityId': entityId,
      'oldValues': oldValues,
      'newValues': newValues,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'reason': reason,
      'metadata': metadata,
      'timestamp': timestamp,
    };
  }
}
