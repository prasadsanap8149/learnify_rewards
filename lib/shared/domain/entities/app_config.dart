enum ConfigType {
  aer, // AER rates and limits
  security, // Security thresholds
  compliance, // Compliance requirements
  feature, // Feature flags
  ui, // UI configuration
  ads, // Ad configuration
  limits, // Various limits
}

enum ConfigStatus {
  active,
  inactive,
  pending,
  archived,
}

class AppConfig {
  final String id;
  final String key;
  final ConfigType type;
  final dynamic value;
  final ConfigStatus status;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;

  AppConfig({
    required this.id,
    required this.key,
    required this.type,
    required this.value,
    required this.status,
    this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
    this.effectiveFrom,
    this.effectiveUntil,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'],
      key: json['key'],
      type: ConfigType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      value: json['value'],
      status: ConfigStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      description: json['description'],
      metadata: json['metadata'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      updatedBy: json['updatedBy'],
      effectiveFrom: json['effectiveFrom']?.toDate(),
      effectiveUntil: json['effectiveUntil']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'type': type.toString().split('.').last,
      'value': value,
      'status': status.toString().split('.').last,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'effectiveFrom': effectiveFrom,
      'effectiveUntil': effectiveUntil,
    };
  }

  bool get isActive {
    if (status != ConfigStatus.active) return false;

    final now = DateTime.now();

    if (effectiveFrom != null && now.isBefore(effectiveFrom!)) {
      return false;
    }

    if (effectiveUntil != null && now.isAfter(effectiveUntil!)) {
      return false;
    }

    return true;
  }
}
