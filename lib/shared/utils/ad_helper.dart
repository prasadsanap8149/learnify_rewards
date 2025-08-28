import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5354046379';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Get ad unit ID by format
  static String getAdUnitId(String format) {
    switch (format.toLowerCase()) {
      case 'banner':
        return bannerAdUnitId;
      case 'interstitial':
        return interstitialAdUnitId;
      case 'rewarded':
        return rewardedAdUnitId;
      case 'rewardedinterstitial':
        return rewardedInterstitialAdUnitId;
      default:
        return bannerAdUnitId;
    }
  }

  /// Get minimum engagement time for specific ad format
  static int getMinEngagementTime(String format) {
    switch (format.toLowerCase()) {
      case 'banner':
        return 30; // Must view banner for 30 seconds
      case 'interstitial':
        return 5; // Must engage with interstitial for 5 seconds
      case 'rewarded':
        return 30; // Must complete rewarded video (30+ seconds)
      case 'rewardedinterstitial':
        return 10; // Must engage for 10 seconds
      default:
        return 30;
    }
  }
}
