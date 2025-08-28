import '../domain/entities/app_config.dart';
import '../data/repositories/firestore_config_repository.dart';

class ConfigService {
  final FirestoreConfigRepository _configRepository;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);

  ConfigService({
    FirestoreConfigRepository? configRepository,
  }) : _configRepository = configRepository ?? FirestoreConfigRepository();

  // Default configurations
  static const Map<String, dynamic> _defaults = {
    // AER Configuration
    'aer.base_rate.under13': 0.5,
    'aer.base_rate.thirteen_to_seventeen': 1.0,
    'aer.base_rate.eighteen_plus': 1.5,
    'aer.daily_limit.under13': 50.0,
    'aer.daily_limit.thirteen_to_seventeen': 100.0,
    'aer.daily_limit.eighteen_plus': 200.0,
    'aer.min_engagement_time': 30,

    // Security Configuration
    'security.max_activities_per_hour': 15,
    'security.max_devices_per_user': 3,
    'security.max_earnings_per_day': 500.0,
    'security.suspicious_variance_threshold': 1.0,
    'security.auto_suspend_critical': true,

    // Compliance Configuration
    'compliance.parental_consent_required': true,
    'compliance.min_verification_level': 'email',
    'compliance.data_retention_days': 2555, // 7 years
    'compliance.audit_log_retention_days': 2555,

    // Feature Flags
    'features.ads_enabled': true,
    'features.aer_enabled': true,
    'features.streak_bonus_enabled': true,
    'features.referral_enabled': true,
    'features.withdrawal_enabled': true,

    // Limits
    'limits.max_withdrawal_amount': 10000, // $100 in cents
    'limits.min_withdrawal_amount': 500, // $5 in cents
    'limits.max_lp_balance': 100000, // 100,000 LP
    'limits.max_streak_days': 365,

    // UI Configuration
    'ui.theme_mode': 'system',
    'ui.show_debug_info': false,
    'ui.animation_duration': 300,

    // Ad Configuration
    'ads.banner_refresh_rate': 60000, // 60 seconds
    'ads.interstitial_frequency': 5, // Every 5 activities
    'ads.rewarded_cooldown': 300, // 5 minutes
  };

  // Get configuration value with type safety
  Future<T> getConfig<T>(String key, {T? defaultValue}) async {
    try {
      // Check cache first
      if (_isCacheValid(key)) {
        return _cache[key] as T;
      }

      // Fetch from repository
      final config = await _configRepository.getConfig(key);

      T value;
      if (config != null && config.isActive) {
        value = config.value as T;
      } else {
        // Use provided default or system default
        value = defaultValue ?? _getSystemDefault<T>(key);
      }

      // Cache the value
      _cache[key] = value;
      _cacheTimestamps[key] = DateTime.now();

      return value;
    } catch (e) {
      // Return default on error
      return defaultValue ?? _getSystemDefault<T>(key);
    }
  }

  // Get system default with type safety
  T _getSystemDefault<T>(String key) {
    final defaultValue = _defaults[key];
    if (defaultValue is T) {
      return defaultValue;
    }
    throw Exception('No default value found for key: $key');
  }

  // Check if cached value is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[key]!;
    return DateTime.now().difference(cacheTime) < _cacheTimeout;
  }

  // Clear cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  // Batch get configurations
  Future<Map<String, dynamic>> getConfigs(List<String> keys) async {
    final result = <String, dynamic>{};

    for (final key in keys) {
      try {
        result[key] = await getConfig(key);
      } catch (e) {
        // Continue with other keys if one fails
        continue;
      }
    }

    return result;
  }

  // Update configuration (admin only)
  Future<void> updateConfig(
    String key,
    dynamic value,
    String updatedBy, {
    String? description,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
  }) async {
    try {
      final existingConfig = await _configRepository.getConfig(key);

      if (existingConfig != null) {
        // Update existing config
        await _configRepository.updateConfigValue(key, value, updatedBy);
      } else {
        // Create new config
        final newConfig = AppConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          key: key,
          type: _getConfigType(key),
          value: value,
          status: ConfigStatus.active,
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          updatedBy: updatedBy,
          effectiveFrom: effectiveFrom,
          effectiveUntil: effectiveUntil,
        );

        await _configRepository.setConfig(newConfig);
      }

      // Clear cache for this key
      clearCache(key);
    } catch (e) {
      throw Exception('Failed to update config: $e');
    }
  }

  // Determine config type from key
  ConfigType _getConfigType(String key) {
    if (key.startsWith('aer.')) return ConfigType.aer;
    if (key.startsWith('security.')) return ConfigType.security;
    if (key.startsWith('compliance.')) return ConfigType.compliance;
    if (key.startsWith('features.')) return ConfigType.feature;
    if (key.startsWith('ui.')) return ConfigType.ui;
    if (key.startsWith('ads.')) return ConfigType.ads;
    if (key.startsWith('limits.')) return ConfigType.limits;
    return ConfigType.feature; // Default
  }

  // Get all configurations by type
  Future<Map<String, dynamic>> getConfigsByType(ConfigType type) async {
    try {
      final configs = await _configRepository.getConfigsByType(type);
      final result = <String, dynamic>{};

      for (final config in configs) {
        if (config.isActive) {
          result[config.key] = config.value;
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to get configs by type: $e');
    }
  }

  // Initialize default configurations
  Future<void> initializeDefaults(String adminId) async {
    try {
      final configs = <AppConfig>[];

      for (final entry in _defaults.entries) {
        final existingConfig = await _configRepository.getConfig(entry.key);

        if (existingConfig == null) {
          final config = AppConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                entry.key.hashCode.toString(),
            key: entry.key,
            type: _getConfigType(entry.key),
            value: entry.value,
            status: ConfigStatus.active,
            description: 'Default configuration',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            updatedBy: adminId,
          );

          configs.add(config);
        }
      }

      if (configs.isNotEmpty) {
        await _configRepository.batchUpdateConfigs(configs);
      }
    } catch (e) {
      throw Exception('Failed to initialize defaults: $e');
    }
  }

  // Check if feature is enabled
  Future<bool> isFeatureEnabled(String feature) async {
    return await getConfig('features.${feature}_enabled', defaultValue: false);
  }

  // Get AER configuration
  Future<Map<String, dynamic>> getAERConfig() async {
    return await getConfigsByType(ConfigType.aer);
  }

  // Get security configuration
  Future<Map<String, dynamic>> getSecurityConfig() async {
    return await getConfigsByType(ConfigType.security);
  }

  // Get compliance configuration
  Future<Map<String, dynamic>> getComplianceConfig() async {
    return await getConfigsByType(ConfigType.compliance);
  }

  // Validate configuration value
  bool validateConfigValue(String key, dynamic value) {
    try {
      switch (key) {
        case 'aer.base_rate.under13':
        case 'aer.base_rate.thirteen_to_seventeen':
        case 'aer.base_rate.eighteen_plus':
          return value is double && value >= 0.0 && value <= 10.0;

        case 'aer.daily_limit.under13':
        case 'aer.daily_limit.thirteen_to_seventeen':
        case 'aer.daily_limit.eighteen_plus':
          return value is double && value >= 0.0 && value <= 1000.0;

        case 'aer.min_engagement_time':
          return value is int && value >= 5 && value <= 300;

        case 'security.max_activities_per_hour':
          return value is int && value >= 1 && value <= 100;

        case 'security.max_devices_per_user':
          return value is int && value >= 1 && value <= 10;

        case 'security.max_earnings_per_day':
          return value is double && value >= 0.0 && value <= 10000.0;

        default:
          return true; // Allow unknown keys
      }
    } catch (e) {
      return false;
    }
  }
}
