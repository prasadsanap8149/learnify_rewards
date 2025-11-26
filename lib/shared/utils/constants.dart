/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Learnify Rewards';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Learn, Earn, Achieve';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String userActivitiesCollection = 'user_activities';
  static const String lpEventsCollection = 'lp_events';
  static const String adEventsCollection = 'ad_events';
  static const String aerEventsCollection = 'aer_events';
  static const String rewardsCollection = 'rewards';
  static const String redemptionsCollection = 'redemptions';
  static const String withdrawalsCollection = 'withdrawals';
  static const String securityEventsCollection = 'security_events';
  static const String auditLogsCollection = 'audit_logs';
  static const String appConfigsCollection = 'app_configs';
  static const String ageVerificationsCollection = 'age_verifications';
  static const String referralsCollection = 'referrals';
  static const String notificationsCollection = 'notifications';
  static const String systemStatsCollection = 'system_stats';
  static const String reportsCollection = 'reports';

  // User Roles
  static const String roleUser = 'user';
  static const String roleModerator = 'moderator';
  static const String roleFinance = 'finance';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'superadmin';
  static const String roleCompliance = 'compliance';
  static const String roleSecurity = 'security';

  // User Status
  static const String statusActive = 'active';
  static const String statusDeactivated = 'deactivated';
  static const String statusSuspended = 'suspended';
  static const String statusPendingVerification = 'pendingVerification';

  // Age Groups
  static const String ageGroupUnder13 = 'under13';
  static const String ageGroup13To17 = 'thirteenToSeventeen';
  static const String ageGroup18Plus = 'eighteenPlus';

  // Verification Status
  static const String verificationNone = 'none';
  static const String verificationEmail = 'email';
  static const String verificationPhone = 'phone';
  static const String verificationDocument = 'document';
  static const String verificationFull = 'full';

  // Activity Types
  static const String activityTypeMath = 'math';
  static const String activityTypeWord = 'word';
  static const String activityTypePuzzle = 'puzzle';
  static const String activityTypeQuiz = 'quiz';

  // Activity Difficulty
  static const String difficultyBeginner = 'beginner';
  static const String difficultyIntermediate = 'intermediate';
  static const String difficultyAdvanced = 'advanced';

  // Activity Status
  static const String activityStatusAvailable = 'available';
  static const String activityStatusInProgress = 'in_progress';
  static const String activityStatusCompleted = 'completed';
  static const String activityStatusLocked = 'locked';

  // LP Event Types
  static const String lpEventEarn = 'earn';
  static const String lpEventSpend = 'spend';

  // LP Event Sources
  static const String lpSourceActivity = 'activity_completion';
  static const String lpSourceWelcomeBonus = 'welcome_bonus';
  static const String lpSourceDailyStreak = 'daily_streak';
  static const String lpSourceAchievement = 'achievement';
  static const String lpSourceReferral = 'referral';
  static const String lpSourceAdReward = 'ad_reward';

  // Ad Types
  static const String adTypeBanner = 'banner';
  static const String adTypeInterstitial = 'interstitial';
  static const String adTypeRewarded = 'rewarded';
  static const String adTypeRewardedInterstitial = 'rewarded_interstitial';
  static const String adTypeNative = 'native';

  // Withdrawal Status
  static const String withdrawalPending = 'pending';
  static const String withdrawalApproved = 'approved';
  static const String withdrawalRejected = 'rejected';
  static const String withdrawalCompleted = 'completed';
  static const String withdrawalCancelled = 'cancelled';

  // Withdrawal Methods
  static const String withdrawalMethodPaypal = 'paypal';
  static const String withdrawalMethodUPI = 'upi';
  static const String withdrawalMethodBank = 'bank';
  static const String withdrawalMethodGiftCard = 'gift_card';

  // Reward Types
  static const String rewardTypeDigital = 'digital';
  static const String rewardTypePhysical = 'physical';
  static const String rewardTypeGiftCard = 'gift_card';
  static const String rewardTypeDiscount = 'discount';

  // Notification Types
  static const String notificationTypeInfo = 'info';
  static const String notificationTypeWarning = 'warning';
  static const String notificationTypeSuccess = 'success';
  static const String notificationTypeError = 'error';
  static const String notificationTypeAchievement = 'achievement';

  // Notification Categories
  static const String notificationCategoryActivity = 'activity';
  static const String notificationCategoryReward = 'reward';
  static const String notificationCategoryWithdrawal = 'withdrawal';
  static const String notificationCategorySecurity = 'security';
  static const String notificationCategorySystem = 'system';

  // Security Event Types
  static const String securityEventLogin = 'login';
  static const String securityEventLogout = 'logout';
  static const String securityEventPasswordChange = 'password_change';
  static const String securityEventSuspiciousActivity = 'suspicious_activity';
  static const String securityEventAccountLocked = 'account_locked';
  static const String securityEventFailedLogin = 'failed_login';

  // Audit Log Types
  static const String auditTypeCreate = 'create';
  static const String auditTypeUpdate = 'update';
  static const String auditTypeDelete = 'delete';
  static const String auditTypeAccess = 'access';

  // App Configuration Keys
  static const String configKeyWelcomeBonus = 'welcome_bonus';
  static const String configKeyDailyStreakBonus = 'daily_streak_bonus';
  static const String configKeyMinWithdrawal = 'min_withdrawal_amount';
  static const String configKeyPlatformFee = 'platform_fee_percentage';
  static const String configKeyActivityCooldown = 'activity_cooldown_seconds';
  static const String configKeyAdEarningsRate = 'ad_earnings_rate';
  static const String configKeyMaxDailyLP = 'max_daily_lp';
  static const String configKeyReferralBonus = 'referral_bonus';

  // Default Values
  static const double defaultWelcomeBonus = 50.0;
  static const double defaultDailyStreakBonus = 10.0;
  static const double defaultMinWithdrawal = 50.0;
  static const double defaultPlatformFeePercentage = 5.0;
  static const int defaultActivityCooldownSeconds = 300; // 5 minutes
  static const double defaultAdEarningsRate = 0.01;
  static const double defaultMaxDailyLP = 1000.0;
  static const double defaultReferralBonus = 25.0;

  // Performance Multipliers
  static const double perfectScoreMultiplier = 1.5;
  static const double excellentScoreMultiplier = 1.25;
  static const double goodScoreMultiplier = 1.1;
  static const double baseScoreMultiplier = 1.0;

  // Score Thresholds
  static const int perfectScoreThreshold = 100;
  static const int excellentScoreThreshold = 90;
  static const int goodScoreThreshold = 75;
  static const int passScoreThreshold = 60;

  // Time Limits (seconds)
  static const int defaultActivityTimeLimit = 300; // 5 minutes
  static const int quizQuestionTimeLimit = 30; // 30 seconds
  static const int sessionTimeout = 1800; // 30 minutes

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 5);

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;
  static const int maxCommentLength = 1000;

  // File Upload
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx'];

  // Rate Limiting
  static const int maxLoginAttemptsPerHour = 5;
  static const int maxWithdrawalRequestsPerDay = 3;
  static const int maxActivityAttemptsPerDay = 50;

  // URLs
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const String supportEmail = 'support@learnifyrewards.com';
  static const String websiteUrl = 'https://learnifyrewards.com';

  // Analytics Event Names
  static const String eventActivityStarted = 'activity_started';
  static const String eventActivityCompleted = 'activity_completed';
  static const String eventLPEarned = 'lp_earned';
  static const String eventRewardRedeemed = 'reward_redeemed';
  static const String eventWithdrawalRequested = 'withdrawal_requested';
  static const String eventAdViewed = 'ad_viewed';
  static const String eventUserRegistered = 'user_registered';
  static const String eventUserLogin = 'user_login';

  // Error Messages
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorUnauthorized = 'You are not authorized to perform this action.';
  static const String errorNotFound = 'The requested resource was not found.';
  static const String errorInsufficientLP = 'Insufficient Learning Points.';
  static const String errorActivityLocked = 'This activity is currently locked.';
  static const String errorInvalidInput = 'Invalid input. Please check your data.';
  static const String errorSessionExpired = 'Your session has expired. Please login again.';

  // Success Messages
  static const String successActivityCompleted = 'Activity completed successfully!';
  static const String successLPEarned = 'Learning Points earned!';
  static const String successRewardRedeemed = 'Reward redeemed successfully!';
  static const String successWithdrawalRequested = 'Withdrawal request submitted!';
  static const String successProfileUpdated = 'Profile updated successfully!';

  // Info Messages
  static const String infoActivityCooldown = 'Activity is on cooldown. Please wait.';
  static const String infoInsufficientBalance = 'You don\'t have enough LP for this reward.';
  static const String infoVerificationRequired = 'Please verify your account to continue.';
  static const String infoAgeRestriction = 'This content is age-restricted.';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Shared Preferences Keys
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyLanguage = 'language';
  static const String prefKeyNotifications = 'notifications_enabled';
  static const String prefKeyBiometric = 'biometric_enabled';
  static const String prefKeyLastSyncTime = 'last_sync_time';
  static const String prefKeyUserOnboarded = 'user_onboarded';

  // Asset Paths
  static const String assetsImages = 'assets/images/';
  static const String assetsIcons = 'assets/icons/';
  static const String assetsFonts = 'assets/fonts/';
  static const String assetsAnimations = 'assets/animations/';
  static const String assetsSounds = 'assets/sounds/';

  // Feature Flags
  static const bool enableBiometric = true;
  static const bool enableSocialSharing = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
}

/// Regular expression patterns
class AppRegex {
  static final RegExp email = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp phone = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  static final RegExp alphabetic = RegExp(r'^[a-zA-Z]+$');
  static final RegExp numeric = RegExp(r'^[0-9]+$');
  static final RegExp url = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );
  static final RegExp strongPassword = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
}

/// Color constants
class AppColors {
  // Primary Colors
  static const int primaryValue = 0xFF6366F1;
  static const int secondaryValue = 0xFF8B5CF6;

  // Status Colors
  static const int successValue = 0xFF10B981;
  static const int warningValue = 0xFFF59E0B;
  static const int errorValue = 0xFFEF4444;
  static const int infoValue = 0xFF3B82F6;

  // Level Colors
  static const int beginnerValue = 0xFF10B981;
  static const int intermediateValue = 0xFFF59E0B;
  static const int advancedValue = 0xFFEF4444;

  // Activity Type Colors
  static const int mathColor = 0xFF3B82F6;
  static const int wordColor = 0xFF10B981;
  static const int puzzleColor = 0xFFF59E0B;
  static const int quizColor = 0xFF8B5CF6;
}

/// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splashScreen = Duration(seconds: 2);
  static const Duration snackBar = Duration(seconds: 3);
  static const Duration toast = Duration(seconds: 2);
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circle = 999.0;
}

/// Font sizes
class AppFontSizes {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double heading = 32.0;
  static const double display = 48.0;
}

/// Icon sizes
class AppIconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}
