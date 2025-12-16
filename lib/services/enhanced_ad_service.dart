import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../shared/utils/ad_helper.dart';
import '../shared/domain/entities/ad_event.dart';
import '../shared/services/aer_service.dart';
import 'user_service.dart';
import '../shared/services/config_service.dart';
import 'serverless_fraud_detection_service.dart';

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

  // Service dependencies
  late final _userService = UserService();
  late final _configService = ConfigService();
  late final _fraudDetectionService = ServerlessFraudDetectionService();
  late final _logger = Logger('EnhancedAdService');

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
              'eighteenPlus', // Default, should be fetched from user service
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

  /// Check if ads can be shown based on various conditions
  Future<bool> canShowAds() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Check age verification and parental consent
      final userAgeData = await _userService.getUserAgeVerification();
      if (userAgeData?['age'] != null && userAgeData!['age'] < 13) {
        // Check parental consent for users under 13
        final hasParentalConsent = userAgeData['parentalConsent'] == true;
        if (!hasParentalConsent) {
          _logger.info('Ads blocked: No parental consent for user under 13');
          return false;
        }
      }

      // Check fraud detection
      final fraudRisk = await _fraudDetectionService.assessActivityRisk(
        activityType: 'ad_view',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        deviceInfo: await _getDeviceInfo(),
      );

      if (fraudRisk['riskLevel'] == 'high' || fraudRisk['blocked'] == true) {
        _logger.warning('Ads blocked due to fraud risk: $fraudRisk');
        return false;
      }

      return true;
    } catch (e) {
      _logger.severe('Error checking if ads can be shown', e);
      return false;
    }
  }

  /// Show random ad (interstitial or rewarded) based on user eligibility and cooling periods
  Future<Map<String, dynamic>> showRandomAd({
    String? activityId,
    Map<String, dynamic>? context, required Null Function() onAdShown, required Null Function(dynamic error) onAdFailedToShow,
  }) async {
    try {
      _logger.info('Attempting to show random ad', context);

      // Check if ads can be shown
      if (!await canShowAds()) {
        return {
          'success': false,
          'error': 'Ads not allowed for this user',
          'code': 'ADS_NOT_ALLOWED',
        };
      }

      // Check cooldowns for both ad types
      final rewardedCooldown = await _configService.getConfig<int>(
        'ads.rewarded_cooldown',
        defaultValue: 300, // 5 minutes
      );

      final interstitialFrequency = await _configService.getConfig<int>(
        'ads.interstitial_frequency',
        defaultValue: 5, // Every 5 activities
      );

      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
          'code': 'USER_NOT_AUTH',
        };
      }

      // Get user stats to determine ad eligibility
      final userStats = await _userService.getUserStats(userId);
      final totalActivities = userStats['totalActivities'] ?? 0;
      final lastRewardedAdTime = userStats['lastRewardedAdTime'] as Timestamp?;

      // Check rewarded ad cooldown
      bool canShowRewarded = true;
      if (lastRewardedAdTime != null) {
        final timeSinceLastRewarded =
            now.difference(lastRewardedAdTime.toDate());
        canShowRewarded = timeSinceLastRewarded.inSeconds >= rewardedCooldown;
      }

      // Check interstitial frequency
      final canShowInterstitial =
          (totalActivities % interstitialFrequency) == 0;

      // Determine which ad type to show based on availability and random selection
      String selectedAdType;
      if (canShowRewarded && canShowInterstitial) {
        // Both available - random selection with preference for rewarded (70% chance)
        selectedAdType =
            Random().nextDouble() < 0.7 ? 'rewarded' : 'interstitial';
      } else if (canShowRewarded) {
        selectedAdType = 'rewarded';
      } else if (canShowInterstitial) {
        selectedAdType = 'interstitial';
      } else {
        // Neither available due to cooldowns
        final nextRewardedTime = lastRewardedAdTime != null
            ? lastRewardedAdTime
                .toDate()
                .add(Duration(seconds: rewardedCooldown))
            : now;
        final nextInterstitialActivity = totalActivities +
            (interstitialFrequency - (totalActivities % interstitialFrequency));

        return {
          'success': false,
          'error': 'Ads on cooldown',
          'code': 'ADS_ON_COOLDOWN',
          'nextRewardedTime': nextRewardedTime.toIso8601String(),
          'nextInterstitialActivity': nextInterstitialActivity,
        };
      }

      // Show the selected ad type
      if (selectedAdType == 'rewarded') {
        // Check if rewarded ad is ready
        if (_rewardedAd == null) {
          _loadRewardedAd();
          return {
            'success': false,
            'error': 'Rewarded ad not ready',
            'code': 'AD_NOT_READY',
            'selectedAdType': selectedAdType,
          };
        }

        // Show rewarded ad with tracking
        showRewardedAd(
          onUserEarnedReward: (reward) {
            _trackAdEvent(
              format: AdFormat.rewarded,
              completed: true,
              engagementTime: 30,
              aerEligible: true,
            );
          },
          onAdDismissed: () {
            _loadRewardedAd(); // Preload next ad
          },
        );

        // Update last rewarded ad time
        await UserService.updateUserProfile(
          updates: {
            'stats.lastRewardedAdTime': Timestamp.fromDate(now),
          },
        );
      } else {
        // Check if interstitial ad is ready
        if (_interstitialAd == null) {
          _loadInterstitialAd();
          return {
            'success': false,
            'error': 'Interstitial ad not ready',
            'code': 'AD_NOT_READY',
            'selectedAdType': selectedAdType,
          };
        }

        // Show interstitial ad
        showInterstitialAd();

        // Track interstitial ad
        _trackAdEvent(
          format: AdFormat.interstitial,
          completed: true,
          engagementTime: 10,
          aerEligible: false, // Interstitials typically don't offer AER
        );
      }

      _logger.info('Random ad shown: $selectedAdType');
      return {
        'success': true,
        'selectedAdType': selectedAdType,
        'availableTypes': {
          'rewarded': canShowRewarded,
          'interstitial': canShowInterstitial,
        },
      };
    } catch (e) {
      _logger.severe('Error showing random ad', e);
      return {
        'success': false,
        'error': 'Failed to show random ad: $e',
        'code': 'RANDOM_AD_ERROR',
      };
    }
  }

  // Get age-appropriate ad formats
  List<AdFormat> getAllowedAdFormats(String ageGroup) {
    switch (ageGroup) {
      case 'under13':
        return [AdFormat.banner]; // Only banners for under 13
      case 'thirteenToSeventeen':
        return [
          AdFormat.banner,
          AdFormat.interstitial
        ]; // No rewarded for minors
      case 'eighteenPlus':
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

class _getDeviceInfo {
  //TODO: Complete this function
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
      final canShow = await EnhancedAdService().canShowAds();
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
