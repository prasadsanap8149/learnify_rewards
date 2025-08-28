# Learnify Rewards - Mobile-First Learning App

A Flutter mobile application for learning and earning rewards, designed for Google Play Store and iOS App Store deployment without requiring separate server hosting.

## Features

### 🎯 Core Functionality

- **User Authentication**: Firebase Auth with email/password
- **Learning Activities**: Interactive courses, lessons, and quizzes
- **Learning Points (LP) System**: Earn points for completing activities
- **Rewards Catalog**: Redeem LP for digital rewards and gift cards
- **Progress Tracking**: Level progression, streaks, and achievements
- **Analytics**: Firebase Analytics and Crashlytics integration

### 📱 Mobile-First Architecture

- **Self-Contained**: All business logic runs within the mobile app
- **No Server Dependency**: Uses Firebase client SDKs instead of Cloud Functions
- **Offline-Ready**: Local data caching and sync capabilities
- **Cross-Platform**: Single codebase for Android and iOS

## Technical Architecture

### Services (Mobile-First)

```
lib/services/
├── user_service.dart      # User profile management
├── lp_service.dart        # Learning Points system
├── activity_service.dart  # Learning activities
└── rewards_service.dart   # Rewards and redemption
```

### Key Technologies

- **Flutter 3.24+**: Cross-platform mobile framework
- **Firebase**: Backend-as-a-Service
  - Firestore: NoSQL database
  - Authentication: User management
  - Analytics: Usage tracking
  - Crashlytics: Error reporting
  - Performance: App performance monitoring
- **Material Design 3**: Modern UI components
- **Provider**: State management
- **GoRouter**: Navigation

### Database Structure (Firestore)

```
users/
├── {userId}/
    ├── profile data
    ├── lpBalance
    ├── level, experience
    └── preferences

activities/
├── {activityId}/
    ├── content
    ├── difficulty
    └── LP rewards

user_activities/
├── {userActivityId}/
    ├── progress
    ├── scores
    └── completion status

lp_events/
├── {eventId}/
    ├── transaction records
    ├── earn/spend history
    └── source tracking

rewards/
├── {rewardId}/
    ├── catalog items
    ├── LP costs
    └── availability

redemptions/
├── {redemptionId}/
    ├── user redemptions
    ├── fulfillment status
    └── delivery info
```

## App Store Deployment

### Android (Google Play Store)

- **App ID**: `com.learnifyrewards.app`
- **Target SDK**: 35 (Android 15)
- **Min SDK**: 21 (Android 5.0)
- **Signing**: Release signing configured
- **ProGuard**: Code obfuscation enabled
- **Permissions**: Minimal required permissions

### iOS (App Store)

- **Bundle ID**: `com.learnifyrewards.app`
- **Target iOS**: 12.0+
- **Privacy**: All required usage descriptions
- **App Transport Security**: Configured
- **Background Modes**: Educational content

### Legal Compliance

- ✅ Privacy Policy (COPPA, GDPR compliant)
- ✅ Terms of Service
- ✅ Age-appropriate content (4+ rating)
- ✅ No third-party ads to minors
- ✅ Data collection transparency

## Getting Started

### Prerequisites

- Flutter 3.24+ installed
- Firebase project configured
- Android Studio / Xcode for device testing

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Add `google-services.json` (Android)
   - Add `GoogleService-Info.plist` (iOS)
4. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

#### Android

```bash
flutter build appbundle --release
```

#### iOS

```bash
flutter build ipa --release
```

## Core Business Logic

### Learning Points (LP) System

- **Earning**: Activity completion, daily streaks, achievements
- **Spending**: Rewards redemption, premium features
- **Security**: Client-side validation with Firestore security rules

### Activity Progression

- **Tracking**: Real-time progress updates
- **Scoring**: Performance-based LP rewards
- **Completion**: Automatic advancement and rewards

### Rewards System

- **Catalog**: Digital items, gift cards, discount codes
- **Redemption**: Instant fulfillment for digital rewards
- **History**: Complete transaction tracking

## Security Features

### Firebase Security Rules

- User data isolation
- Read/write permissions based on authentication
- Rate limiting and abuse prevention

### Client-Side Validation

- Input sanitization
- Business rule enforcement
- Fraud prevention measures

## Performance Optimization

### App Performance

- Lazy loading for content
- Image optimization and caching
- Efficient list rendering
- Memory management

### Data Efficiency

- Pagination for large datasets
- Selective field queries
- Local caching strategies
- Batch operations

## Monitoring & Analytics

### Firebase Analytics

- User engagement tracking
- Learning completion rates
- Feature usage metrics
- Custom events

### Crashlytics

- Real-time crash reporting
- Performance monitoring
- User session tracking
- Custom logs

## Development Status

### ✅ Completed

- Mobile app store configuration
- Firebase integration
- Core service architecture
- Authentication system
- Basic UI screens
- Legal compliance documents

### 🔄 In Progress

- Activity content management
- Rewards catalog implementation
- Advanced UI components
- Testing and validation

### 📋 Planned

- Push notifications
- Social features
- Advanced analytics
- Performance optimizations

## Contributing

This is a production-ready mobile app designed for app store deployment. The architecture prioritizes:

- **Simplicity**: No complex server infrastructure
- **Scalability**: Firebase handles backend scaling
- **Maintenance**: Minimal operational overhead
- **Compliance**: Full app store requirement coverage

## License

Proprietary - All rights reserved for app store deployment.
