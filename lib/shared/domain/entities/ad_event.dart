enum AdFormat {
  banner,
  interstitial,
  rewarded,
  rewardedInterstitial,
}

enum AdNetwork {
  admob,
  mediation,
}

class AdEvent {
  final String id;
  final String userId;
  final AdFormat format;
  final AdNetwork adNetwork;
  final bool impression;
  final bool clicked;
  final String adUnitId;
  final String? placementId;
  final double revenue;
  final int engagementTime; // seconds spent engaging with ad
  final int engagementTimeSeconds; // alias for engagementTime
  final bool qualifiesForAER; // meets minimum engagement criteria
  final bool completed; // whether ad was fully viewed/completed
  final double aerAmount; // calculated AER for this ad
  final String? deviceInfo;
  final String? ipAddress;
  final String? userAgent;
  final String? consentStatus;
  final String? ageGroup;
  final DateTime at;
  final Map<String, dynamic>? metadata; // Additional event metadata

  DateTime get timestamp => at; // Alias for at property

  AdEvent({
    required this.id,
    required this.userId,
    required this.format,
    required this.adNetwork,
    required this.impression,
    required this.clicked,
    required this.adUnitId,
    this.placementId,
    required this.revenue,
    required this.engagementTime,
    required this.qualifiesForAER,
    this.completed = false,
    required this.aerAmount,
    this.deviceInfo,
    this.ipAddress,
    this.userAgent,
    this.consentStatus,
    this.ageGroup,
    required this.at,
    this.metadata,
  }) : engagementTimeSeconds = engagementTime;

  factory AdEvent.fromJson(Map<String, dynamic> json) {
    return AdEvent(
      id: json['id'],
      userId: json['userId'],
      format: AdFormat.values.firstWhere(
        (e) => e.toString().split('.').last == json['format'],
      ),
      adNetwork: AdNetwork.values.firstWhere(
        (e) => e.toString().split('.').last == json['adNetwork'],
      ),
      impression: json['impression'] ?? false,
      clicked: json['clicked'] ?? false,
      adUnitId: json['adUnitId'],
      placementId: json['placementId'],
      revenue: (json['revenue'] ?? 0).toDouble(),
      engagementTime: json['engagementTime'] ?? 0,
      qualifiesForAER: json['qualifiesForAER'] ?? false,
      completed: json['completed'] ?? false,
      aerAmount: (json['aerAmount'] ?? 0).toDouble(),
      deviceInfo: json['deviceInfo'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      consentStatus: json['consentStatus'],
      ageGroup: json['ageGroup'],
      at: json['at']?.toDate() ?? DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'format': format.toString().split('.').last,
      'adNetwork': adNetwork.toString().split('.').last,
      'impression': impression,
      'clicked': clicked,
      'adUnitId': adUnitId,
      'placementId': placementId,
      'revenue': revenue,
      'engagementTime': engagementTime,
      'qualifiesForAER': qualifiesForAER,
      'completed': completed,
      'aerAmount': aerAmount,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'consentStatus': consentStatus,
      'ageGroup': ageGroup,
      'at': at,
      'metadata': metadata,
    };
  }
}
