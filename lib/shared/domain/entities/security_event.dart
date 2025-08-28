enum SecurityEventType {
  suspiciousActivity, // Abnormal patterns
  multipleDevices, // Multiple device logins
  rapidActivities, // Too many activities in short time
  suspiciousEarnings, // Unusual earning patterns
  deviceChange, // Login from new device
  ipChange, // Login from new IP
  parentalControl, // Parental control violation
  fraudAttempt, // Attempted fraud
  policyViolation, // Policy violation
  dataAnomaly, // Data inconsistency
}

enum SecuritySeverity {
  low, // Minor concern
  medium, // Moderate concern
  high, // Serious concern
  critical // Immediate action required
}

enum SecurityStatus {
  open, // Under investigation
  resolved, // Issue resolved
  falsePositive, // Not actually an issue
  escalated, // Escalated to higher authority
}

class SecurityEvent {
  final String id;
  final String userId;
  final SecurityEventType type;
  final SecuritySeverity severity;
  final SecurityStatus status;
  final String description;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String? deviceId;
  final String? userAgent;
  final DateTime timestamp;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? resolution;
  final List<String> relatedEvents;

  SecurityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.severity,
    required this.status,
    required this.description,
    required this.details,
    this.ipAddress,
    this.deviceId,
    this.userAgent,
    required this.timestamp,
    this.reviewedBy,
    this.reviewedAt,
    this.resolution,
    required this.relatedEvents,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'],
      userId: json['userId'],
      type: SecurityEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      severity: SecuritySeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
      ),
      status: SecurityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      description: json['description'],
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      ipAddress: json['ipAddress'],
      deviceId: json['deviceId'],
      userAgent: json['userAgent'],
      timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
      reviewedBy: json['reviewedBy'],
      reviewedAt: json['reviewedAt']?.toDate(),
      resolution: json['resolution'],
      relatedEvents: List<String>.from(json['relatedEvents'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'details': details,
      'ipAddress': ipAddress,
      'deviceId': deviceId,
      'userAgent': userAgent,
      'timestamp': timestamp,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'resolution': resolution,
      'relatedEvents': relatedEvents,
    };
  }
}
