enum AdFormat { banner, interstitial, rewarded, rewardedInterstitial }

class AdEvent {
  final String id;
  final AdFormat format;
  final bool impression;
  final bool clicked;
  final double revenue;
  final int engagementTime;
  final bool qualifiesForAER;
  final double aerAmount;
  final DateTime at;

  AdEvent({
    required this.id,
    required this.format,
    required this.impression,
    required this.clicked,
    required this.revenue,
    required this.engagementTime,
    required this.qualifiesForAER,
    required this.aerAmount,
    required this.at,
  });
}

class AUREvent {
  final String id;
  final String adEventRef;
  final AdFormat format;
  final double aerAmount;
  final int engagementTime;
  final String qualificationReason;
  final DateTime createdAt;

  AUREvent({
    required this.id,
    required this.adEventRef,
    required this.format,
    required this.aerAmount,
    required this.engagementTime,
    required this.qualificationReason,
    required this.createdAt,
  });
}
