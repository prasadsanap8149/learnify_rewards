class AppConfig {
  static const String appName = 'Learn & Earn';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String lpEventsCollection = 'lpEvents';
  static const String adEventsCollection = 'adEvents';
  static const String aerEventsCollection = 'aerEvents';
  static const String withdrawalsCollection = 'withdrawals';
  static const String configCollection = 'config';
  static const String auditLogsCollection = 'auditLogs';

  // Remote Config Keys
  static const String cooldownConfigKey = 'cooldownSecondsByActivity';
  static const String dailyPoolConfigKey = 'dailyPoolUSD';
  static const String platformFeeConfigKey = 'platformFeePct';
  static const String withdrawThresholdKey = 'withdrawThresholdUSD';
  static const String aerConfigKey = 'aerConfig';

  // Age Groups
  static const String ageGroupUnder13 = 'under13';
  static const String ageGroup13To17 = '13-17';
  static const String ageGroup18Plus = '18+';

  // User Roles
  static const String roleUser = 'user';
  static const String roleModerator = 'moderator';
  static const String roleFinance = 'finance';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'superadmin';
  static const String roleCompliance = 'compliance';
  static const String roleSecurity = 'security';

  // Activity Types
  static const String activityMath = 'math';
  static const String activityWord = 'word';
  static const String activityPuzzle = 'puzzle';

  // Ad Formats
  static const String adFormatBanner = 'banner';
  static const String adFormatInterstitial = 'interstitial';
  static const String adFormatRewarded = 'rewarded';
  static const String adFormatRewardedInterstitial = 'rewardedInterstitial';

  // Default Values
  static const int defaultCooldownSeconds = 5;
  static const double defaultDailyPoolUSD = 1000.0;
  static const double defaultPlatformFeePct = 0.10;
  static const double defaultWithdrawThresholdUSD = 50.0;
  static const int defaultMonthEndSettlementDay = 1;

  // Security
  static const int maxDevicesPerUser = 3;
  static const int maxLoginAttemptsBeforeCooldown = 5;
  static const Duration loginCooldownDuration = Duration(minutes: 15);

  // Compliance
  static const List<String> allowedCountries = ['IN', 'US', 'CA', 'GB', 'AU'];
  static const int dataRetentionDays = 2555; // ~7 years
  static const bool requireParentalConsent = true;
}
