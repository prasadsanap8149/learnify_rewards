import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serverless Environment Configuration Service
///
/// This service manages environment-based configuration without requiring
/// any server infrastructure or Cloud Functions. All configuration is
/// client-side, reducing operational costs to zero.
class ServerlessEnvironmentConfig {
  static ServerlessEnvironmentConfig? _instance;
  static ServerlessEnvironmentConfig get instance {
    _instance ??= ServerlessEnvironmentConfig._internal();
    return _instance!;
  }

  ServerlessEnvironmentConfig._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Environment detection
  String get environment {
    if (kDebugMode) return 'development';
    if (kProfileMode) return 'staging';
    return 'production';
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';

  /// Initialize configuration service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadEnvironmentConfig();
    _initialized = true;
  }

  /// Load environment-specific configuration
  Future<void> _loadEnvironmentConfig() async {
    // Load configuration based on environment
    final configData = _getEnvironmentConfig();

    // Store in local preferences for offline access
    for (final entry in configData.entries) {
      await _prefs.setString('config_${entry.key}', entry.value.toString());
    }
  }

  /// Get environment-specific configuration
  Map<String, dynamic> _getEnvironmentConfig() {
    switch (environment) {
      case 'development':
        return _developmentConfig;
      case 'staging':
        return _stagingConfig;
      case 'production':
        return _productionConfig;
      default:
        return _developmentConfig;
    }
  }

  // =============================================================================
  // DEVELOPMENT CONFIGURATION (No server costs)
  // =============================================================================
  static const Map<String, dynamic> _developmentConfig = {
    // Firebase (free tier limits)
    'firebase_project_id': 'learnify-rewards-dev',
    'use_emulator': true,
    'debug_mode': true,

    // Security (client-side only)
    'encryption_enabled': true,
    'biometric_auth_enabled': false, // Disabled in dev for easier testing
    'fraud_detection_enabled': false,

    // Settlement (manual, no server costs)
    'settlement_enabled': true,
    'settlement_min_amount': 100, // $1 for testing
    'settlement_max_amount': 10000, // $100 for testing
    'settlement_auto_process': false,

    // Features (all enabled for testing)
    'ads_enabled': true,
    'aer_enabled': true,
    'withdrawal_enabled': true,
    'offline_mode_enabled': true,

    // Limits (relaxed for testing)
    'daily_earnings_limit': 50000, // $500
    'max_activities_per_hour': 50,
    'max_withdrawal_requests_per_day': 10,

    // AdMob (test IDs)
    'admob_app_id': 'ca-app-pub-3940256099942544~3347511713',
    'admob_banner_id': 'ca-app-pub-3940256099942544/6300978111',
    'admob_interstitial_id': 'ca-app-pub-3940256099942544/1033173712',
    'admob_rewarded_id': 'ca-app-pub-3940256099942544/5224354917',
  };

  // =============================================================================
  // STAGING CONFIGURATION (Minimal server usage)
  // =============================================================================
  static const Map<String, dynamic> _stagingConfig = {
    // Firebase (free tier with careful usage)
    'firebase_project_id': 'learnify-rewards-staging',
    'use_emulator': false,
    'debug_mode': true,

    // Security (client-side validation)
    'encryption_enabled': true,
    'biometric_auth_enabled': true,
    'fraud_detection_enabled': true,

    // Settlement (manual processing)
    'settlement_enabled': true,
    'settlement_min_amount': 500, // $5
    'settlement_max_amount': 25000, // $250
    'settlement_auto_process': false,

    // Features (production-like)
    'ads_enabled': true,
    'aer_enabled': true,
    'withdrawal_enabled': true,
    'offline_mode_enabled': true,

    // Limits (moderate for staging)
    'daily_earnings_limit': 20000, // $200
    'max_activities_per_hour': 20,
    'max_withdrawal_requests_per_day': 5,

    // AdMob (staging/test environment)
    'admob_app_id': 'ca-app-pub-3940256099942544~3347511713',
    'admob_banner_id': 'ca-app-pub-3940256099942544/6300978111',
    'admob_interstitial_id': 'ca-app-pub-3940256099942544/1033173712',
    'admob_rewarded_id': 'ca-app-pub-3940256099942544/5224354917',
  };

  // =============================================================================
  // PRODUCTION CONFIGURATION (Zero server costs)
  // =============================================================================
  static const Map<String, dynamic> _productionConfig = {
    // Firebase (optimized for free tier)
    'firebase_project_id': 'learnify-rewards-prod',
    'use_emulator': false,
    'debug_mode': false,

    // Security (maximum protection, client-side)
    'encryption_enabled': true,
    'biometric_auth_enabled': true,
    'fraud_detection_enabled': true,

    // Settlement (manual processing - no server costs)
    'settlement_enabled': true,
    'settlement_min_amount': 500, // $5
    'settlement_max_amount': 50000, // $500
    'settlement_auto_process': false, // Manual to avoid server costs

    // Features (production settings)
    'ads_enabled': true,
    'aer_enabled': true,
    'withdrawal_enabled': true,
    'offline_mode_enabled': true,

    // Limits (production values)
    'daily_earnings_limit': 20000, // $200
    'max_activities_per_hour': 15,
    'max_withdrawal_requests_per_day': 3,

    // AdMob (your actual production IDs)
    'admob_app_id': 'YOUR_PRODUCTION_ADMOB_APP_ID',
    'admob_banner_id': 'YOUR_PRODUCTION_BANNER_ID',
    'admob_interstitial_id': 'YOUR_PRODUCTION_INTERSTITIAL_ID',
    'admob_rewarded_id': 'YOUR_PRODUCTION_REWARDED_ID',
  };

  // =============================================================================
  // CONFIGURATION GETTERS (Type-safe access)
  // =============================================================================

  // Firebase Configuration
  String get firebaseProjectId =>
      getString('firebase_project_id', 'learnify-rewards-dev');
  bool get useEmulator => getBool('use_emulator', false);
  bool get debugMode => getBool('debug_mode', false);

  // Security Configuration
  bool get encryptionEnabled => getBool('encryption_enabled', true);
  bool get biometricAuthEnabled => getBool('biometric_auth_enabled', true);
  bool get fraudDetectionEnabled => getBool('fraud_detection_enabled', true);

  // Settlement Configuration (No server dependency)
  bool get settlementEnabled => getBool('settlement_enabled', true);
  int get settlementMinAmount => getInt('settlement_min_amount', 500);
  int get settlementMaxAmount => getInt('settlement_max_amount', 50000);
  bool get settlementAutoProcess => getBool('settlement_auto_process', false);

  // Feature Flags
  bool get adsEnabled => getBool('ads_enabled', true);
  bool get aerEnabled => getBool('aer_enabled', true);
  bool get withdrawalEnabled => getBool('withdrawal_enabled', true);
  bool get offlineModeEnabled => getBool('offline_mode_enabled', true);

  // Limits
  int get dailyEarningsLimit => getInt('daily_earnings_limit', 20000);
  int get maxActivitiesPerHour => getInt('max_activities_per_hour', 15);
  int get maxWithdrawalRequestsPerDay =>
      getInt('max_withdrawal_requests_per_day', 3);

  // AdMob Configuration
  String get admobAppId =>
      getString('admob_app_id', 'ca-app-pub-3940256099942544~3347511713');
  String get admobBannerId =>
      getString('admob_banner_id', 'ca-app-pub-3940256099942544/6300978111');
  String get admobInterstitialId => getString(
      'admob_interstitial_id', 'ca-app-pub-3940256099942544/1033173712');
  String get admobRewardedId =>
      getString('admob_rewarded_id', 'ca-app-pub-3940256099942544/5224354917');

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  String getString(String key, String defaultValue) {
    if (!_initialized) return defaultValue;
    return _prefs.getString('config_$key') ?? defaultValue;
  }

  int getInt(String key, int defaultValue) {
    if (!_initialized) return defaultValue;
    final stringValue = _prefs.getString('config_$key');
    return stringValue != null
        ? int.tryParse(stringValue) ?? defaultValue
        : defaultValue;
  }

  bool getBool(String key, bool defaultValue) {
    if (!_initialized) return defaultValue;
    final stringValue = _prefs.getString('config_$key');
    return stringValue != null
        ? stringValue.toLowerCase() == 'true'
        : defaultValue;
  }

  double getDouble(String key, double defaultValue) {
    if (!_initialized) return defaultValue;
    final stringValue = _prefs.getString('config_$key');
    return stringValue != null
        ? double.tryParse(stringValue) ?? defaultValue
        : defaultValue;
  }

  // =============================================================================
  // ADMIN CONFIGURATION OVERRIDE (Client-side admin panel)
  // =============================================================================

  /// Update configuration value (for admin use)
  Future<void> updateConfig(String key, dynamic value) async {
    if (!_initialized) return;
    await _prefs.setString('config_$key', value.toString());
  }

  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    if (!_initialized) return;

    final configData = _getEnvironmentConfig();
    for (final entry in configData.entries) {
      await _prefs.setString('config_${entry.key}', entry.value.toString());
    }
  }

  /// Get all current configuration (for admin dashboard)
  Map<String, String> getAllConfig() {
    if (!_initialized) return {};

    final allKeys =
        _prefs.getKeys().where((key) => key.startsWith('config_')).toList();

    final config = <String, String>{};
    for (final key in allKeys) {
      final configKey = key.replaceFirst('config_', '');
      config[configKey] = _prefs.getString(key) ?? '';
    }

    return config;
  }

  // =============================================================================
  // COST OPTIMIZATION SETTINGS
  // =============================================================================

  /// Firebase usage optimization settings
  Map<String, dynamic> get firebaseOptimization => {
        'enable_offline_persistence': true, // Reduce reads
        'cache_size_mb': 100, // Limit cache size
        'merge_queries': true, // Combine multiple queries
        'use_get_from_cache_first': true, // Prefer cache over network
        'batch_writes': true, // Batch write operations
        'limit_concurrent_requests': 5, // Prevent quota exhaustion
      };

  /// AdMob optimization settings for maximum revenue
  Map<String, dynamic> get admobOptimization => {
        'adaptive_banner_enabled': true,
        'load_ads_in_advance': true,
        'respect_coppa_compliance': true,
        'personalized_ads_consent_required': true,
        'mediation_enabled': false, // Keep simple for now
      };

  // =============================================================================
  // ENVIRONMENT INFO
  // =============================================================================

  Map<String, dynamic> get environmentInfo => {
        'environment': environment,
        'debug_mode': debugMode,
        'server_costs': 'Zero - Serverless architecture',
        'firebase_tier': 'Spark (Free)',
        'manual_settlement': true,
        'last_updated': DateTime.now().toIso8601String(),
      };
}
