import 'package:learnify_rewards/features/ads/domain/entities/ad_event.dart';

class AdEventModel extends AdEvent {
  AdEventModel({
    required String id,
    required AdFormat format,
    required bool impression,
    required bool clicked,
    required double revenue,
    required int engagementTime,
    required bool qualifiesForAER,
    required double aerAmount,
    required DateTime at,
  }) : super(
          id: id,
          format: format,
          impression: impression,
          clicked: clicked,
          revenue: revenue,
          engagementTime: engagementTime,
          qualifiesForAER: qualifiesForAER,
          aerAmount: aerAmount,
          at: at,
        );

  factory AdEventModel.fromJson(Map<String, dynamic> json) {
    return AdEventModel(
      id: json['id'],
      format: AdFormat.values
          .firstWhere((e) => e.toString() == 'AdFormat.${json['format']}'),
      impression: json['impression'],
      clicked: json['clicked'],
      revenue: json['revenue'],
      engagementTime: json['engagementTime'],
      qualifiesForAER: json['qualifiesForAER'],
      aerAmount: json['aerAmount'],
      at: DateTime.parse(json['at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format.toString().split('.').last,
      'impression': impression,
      'clicked': clicked,
      'revenue': revenue,
      'engagementTime': engagementTime,
      'qualifiesForAER': qualifiesForAER,
      'aerAmount': aerAmount,
      'at': at.toIso8601String(),
    };
  }
}

class AUREventModel extends AUREvent {
  AUREventModel({
    required String id,
    required String adEventRef,
    required AdFormat format,
    required double aerAmount,
    required int engagementTime,
    required String qualificationReason,
    required DateTime createdAt,
  }) : super(
          id: id,
          adEventRef: adEventRef,
          format: format,
          aerAmount: aerAmount,
          engagementTime: engagementTime,
          qualificationReason: qualificationReason,
          createdAt: createdAt,
        );

  factory AUREventModel.fromJson(Map<String, dynamic> json) {
    return AUREventModel(
      id: json['id'],
      adEventRef: json['adEventRef'],
      format: AdFormat.values
          .firstWhere((e) => e.toString() == 'AdFormat.${json['format']}'),
      aerAmount: json['aerAmount'],
      engagementTime: json['engagementTime'],
      qualificationReason: json['qualificationReason'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adEventRef': adEventRef,
      'format': format.toString().split('.').last,
      'aerAmount': aerAmount,
      'engagementTime': engagementTime,
      'qualificationReason': qualificationReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
