import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/ad_helper.dart';
import '../shared/domain/entities/ad_event.dart';
import '../shared/services/aer_service.dart';

class EnhancedAdService {
  static final EnhancedAdService _instance = EnhancedAdService._internal();
  factory EnhancedAdService() => _instance;
  EnhancedAdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AERService _aerService = AERService();
  bool _isInitialized = false;

  // Initialize ads system
  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
    _isInitialized = true;
  }

  // Create banner ad
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _trackAdEvent(
            format: AdFormat.banner,
            impression: true,
            engagementTime: 0,
          );
          onAdLoaded(ad);
        },
        onAdFailedToLoad: onAdFailedToLoad,
        onAdClicked: (ad) {
          _trackAdEvent(
            format: AdFormat.banner,
            clicked: true,
            engagementTime: 5, // Estimated click engagement
          );
        },
      ),
    );
  }

  // Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _setInterstitialCallbacks(ad);
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setInterstitialCallbacks(InterstitialAd ad) {
    DateTime? showStartTime;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        showStartTime = DateTime.now();
        _trackAdEvent(
          format: AdFormat.interstitial,
          impression: true,
          engagementTime: 0,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        final engagementTime = showStartTime != null
            ? DateTime.now().difference(showStartTime!).inSeconds
            : 0;

        _trackAdEvent(
          format: AdFormat.interstitial,
          engagementTime: engagementTime,
          completed: engagementTime >= 5, // Consider 5+ seconds as completed
        );

        ad.dispose();
        _loadInterstitialAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );
  }

  // Show interstitial ad
  void showInterstitialAd() {
    _interstitialAd?.show();
  }

  // Load rewarded ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _setRewardedCallbacks(ad);
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  void _setRewardedCallbacks(RewardedAd ad) {
    DateTime? showStartTime;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        showStartTime = DateTime.now();
        _trackAdEvent(
          format: AdFormat.rewarded,
          impression: true,
          engagementTime: 0,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        final engagementTime = showStartTime != null
            ? DateTime.now().difference(showStartTime!).inSeconds
            : 0;

        _trackAdEvent(
          format: AdFormat.rewarded,
          engagementTime: engagementTime,
          completed:
              engagementTime >= 15, // Rewarded ads typically 15-30 seconds
        );

        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );
  }

  // Show rewarded ad
  void showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
    Function()? onAdDismissed,
  }) {
    _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
      onUserEarnedReward(reward);

      // Track reward earned
      _trackAdEvent(
        format: AdFormat.rewarded,
        completed: true,
        engagementTime: 30, // Assume full rewarded ad duration
        aerEligible: true,
      );

      onAdDismissed?.call();
    });
  }

  // Track ad events and calculate AER
  Future<void> _trackAdEvent({
    required AdFormat format,
    bool impression = false,
    bool clicked = false,
    required int engagementTime,
    bool completed = false,
    bool aerEligible = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create ad event first
      final adEvent = AdEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        format: format,
        adNetwork: AdNetwork.admob,
        impression: true,
        clicked: clicked,
        adUnitId: _getAdUnitId(format),
        revenue: 0.0,
        engagementTime: engagementTime,
        qualifiesForAER: false, // Will be updated after AER calculation
        aerAmount: 0.0, // Will be updated after AER calculation
        at: DateTime.now(),
      );

      // Calculate AER based on engagement
      double aerAmount = 0.0;
      bool qualifiesForAER = false;

      if (aerEligible ||
          (engagementTime >= _getMinEngagementTime(format) && completed)) {
        // Need to get user data for AER calculation
        // For now, create a simplified user object
        // In production, this should fetch from user service
        final userData = {
          'uid': user.uid,
          'ageGroup':
              'eighteen_plus', // Default, should be fetched from user service
        };

        // This is a simplified approach - in production you'd use proper user entity
        aerAmount = _calculateSimpleAER(format, engagementTime);
        qualifiesForAER = aerAmount > 0;
      }

      // Update ad event with AER results
      final finalAdEvent = AdEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        format: format,
        adNetwork: AdNetwork.admob,
        impression: impression,
        clicked: clicked,
        adUnitId: _getAdUnitId(format),
        revenue: 0.0, // Will be populated by backend if available
        engagementTime: engagementTime,
        qualifiesForAER: qualifiesForAER,
        completed: completed,
        aerAmount: aerAmount,
        at: DateTime.now(),
      );

      // Log ad event (implement proper backend logging)
      await _logAdEvent(finalAdEvent);

      // Award AER if qualified
      if (qualifiesForAER && aerAmount > 0) {
        await _aerService.processAERReward(
          user.uid,
          finalAdEvent,
          aerAmount,
          1, // 1 LP for ad engagement
        );
      }
    } catch (e) {
      debugPrint('Error tracking ad event: $e');
    }
  }

  int _getMinEngagementTime(AdFormat format) {
    switch (format) {
      case AdFormat.banner:
        return 30; // 30 seconds for banner
      case AdFormat.interstitial:
        return 5; // 5 seconds for interstitial
      case AdFormat.rewarded:
        return 15; // 15 seconds for rewarded
      case AdFormat.rewardedInterstitial:
        return 10; // 10 seconds for rewarded interstitial
    }
  }

  double _calculateSimpleAER(AdFormat format, int engagementTime) {
    // Simplified AER calculation without full user context
    // In production, this should use the full AER service with proper user data
    const baseRates = {
      AdFormat.banner: 0.01,
      AdFormat.interstitial: 0.02,
      AdFormat.rewarded: 0.05,
      AdFormat.rewardedInterstitial: 0.03,
    };

    final baseRate = baseRates[format] ?? 0.01;
    final minTime = _getMinEngagementTime(format);

    if (engagementTime < minTime) return 0.0;

    // Bonus for longer engagement
    final bonus = (engagementTime > minTime * 2) ? 1.5 : 1.0;

    return baseRate * bonus;
  }

  String _getAdUnitId(AdFormat format) {
    switch (format) {
      case AdFormat.banner:
        return AdHelper.bannerAdUnitId;
      case AdFormat.interstitial:
        return AdHelper.interstitialAdUnitId;
      case AdFormat.rewarded:
        return AdHelper.rewardedAdUnitId;
      case AdFormat.rewardedInterstitial:
        return AdHelper.rewardedAdUnitId; // Use same as rewarded for now
    }
  }

  Future<void> _logAdEvent(AdEvent adEvent) async {
    try {
      // Log to Firestore for analytics and monitoring
      await _firestore.collection('ad_events').add({
        'userId': adEvent.userId,
        'adFormat': adEvent.format.toString(),
        'adNetwork': adEvent.adNetwork,
        'adUnitId': adEvent.adUnitId,
        'timestamp': Timestamp.fromDate(adEvent.timestamp),
        'engagementTime': adEvent.engagementTime,
        'revenue': adEvent.revenue,
        'aerAmount': adEvent.aerAmount,
        'metadata': adEvent.metadata,
        'deviceInfo': {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'version': adEvent.metadata?['appVersion'] ?? 'unknown',
        },
      });

      // Also log to user's ad history for tracking
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ad_history')
            .add({
          'adFormat': adEvent.format.toString(),
          'timestamp': Timestamp.fromDate(adEvent.timestamp),
          'engagementTime': adEvent.engagementTime,
          'aerAmount': adEvent.aerAmount,
          'revenue': adEvent.revenue,
        });

        // Update user's total ad stats
        await _firestore.collection('users').doc(user.uid).update({
          'totalAdsWatched': FieldValue.increment(1),
          'totalAdRevenue': FieldValue.increment(adEvent.revenue),
          'totalAERFromAds': FieldValue.increment(adEvent.aerAmount),
          'lastAdWatchedAt': Timestamp.fromDate(adEvent.timestamp),
        });
      }

      debugPrint(
          'Ad Event logged: ${adEvent.format} - Engagement: ${adEvent.engagementTime}s - AER: ${adEvent.aerAmount}');
    } catch (e) {
      debugPrint('Error logging ad event: $e');
      // Still log to console for debugging
      debugPrint(
          'Ad Event: ${adEvent.format} - Engagement: ${adEvent.engagementTime}s - AER: ${adEvent.aerAmount}');
    }
  }

  // Check if ads can be shown based on user age and consent
  Future<bool> canShowAds(String userId) async {
    try {
      // Get user data to check age group and consent status
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final ageGroup = userData['ageGroup'] as String?;

      // Check age restrictions for different ad types
      if (ageGroup == 'under_13') {
        // COPPA compliance - no targeted ads for under 13
        return false;
      }

      if (ageGroup == 'thirteen_to_seventeen') {
        // Check parental consent for 13-17 age group
        final consentData =
            userData['parentalConsent'] as Map<String, dynamic>?;
        if (consentData == null) return false;

        final consentStatus = consentData['status'] as String?;
        final adConsent = consentData['adConsent'] as bool?;

        // Require explicit parental consent for ads
        if (consentStatus != 'verified' || adConsent != true) {
          return false;
        }

        // Check if consent is still valid (not expired)
        final consentDate = (consentData['verifiedAt'] as Timestamp?)?.toDate();
        if (consentDate != null) {
          final daysSinceConsent =
              DateTime.now().difference(consentDate).inDays;
          // Reconfirm consent every 6 months for minors
          if (daysSinceConsent > 180) {
            return false;
          }
        }
      }

      // For 18+ users, check basic consent preferences
      if (ageGroup == 'eighteen_plus') {
        final preferences = userData['preferences'] as Map<String, dynamic>?;
        final adsEnabled = preferences?['adsEnabled'] as bool? ?? true;
        if (!adsEnabled) return false;
      }

      // Check if user has opted out globally
      final adSettings = userData['adSettings'] as Map<String, dynamic>?;
      final globalOptOut = adSettings?['globalOptOut'] as bool? ?? false;
      if (globalOptOut) return false;

      // Check daily ad limit
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final dailyAdCount = adSettings?['dailyCount']?[todayString] as int? ?? 0;
      final maxDailyAds = adSettings?['maxDailyAds'] as int? ?? 50;

      if (dailyAdCount >= maxDailyAds) return false;

      return true;
    } catch (e) {
      debugPrint('Error checking ad consent: $e');
      // Err on the side of caution - don't show ads if there's an error
      return false;
    }
  }

  // Get age-appropriate ad formats
  List<AdFormat> getAllowedAdFormats(String ageGroup) {
    switch (ageGroup) {
      case 'under13':
        return [AdFormat.banner]; // Only banners for under 13
      case 'thirteen_to_seventeen':
        return [
          AdFormat.banner,
          AdFormat.interstitial
        ]; // No rewarded for minors
      case 'eighteen_plus':
        return AdFormat.values; // All formats for adults
      default:
        return [AdFormat.banner]; // Conservative default
    }
  }

  // Dispose resources
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
  }
}

// Widget for easy banner ad integration
class BannerAdWidget extends StatefulWidget {
  final EdgeInsets padding;
  final bool showOnlyIfAllowed;

  const BannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.all(8.0),
    this.showOnlyIfAllowed = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _canShowAds = true;

  @override
  void initState() {
    super.initState();
    _checkAdPermission();
  }

  Future<void> _checkAdPermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.showOnlyIfAllowed) {
      final canShow = await EnhancedAdService().canShowAds(user.uid);
      setState(() => _canShowAds = canShow);
    }

    if (_canShowAds) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd = EnhancedAdService().createBannerAd(
      onAdLoaded: (ad) {
        setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        setState(() => _isLoaded = false);
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canShowAds || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
    );
  }
}
