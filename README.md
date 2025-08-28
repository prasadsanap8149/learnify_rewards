# Learnify Rewards - Flutter App with Firebase Backend

A comprehensive Learn & Earn mobile application built with Flutter and powered by Firebase, featuring gamified learning experiences with rewards.

## 🚀 Features

### Core Features

- **Gamified Learning**: Interactive activities with LP rewards
- **Age Verification**: Secure age verification system
- **Referral System**: Multi-level referral rewards
- **Real-time Rewards**: Instant LP earning and tracking
- **Security Monitoring**: Advanced fraud detection
- **Admin Dashboard**: Comprehensive management interface

### Technical Features

- **Flutter Frontend**: Cross-platform mobile app
- **Firebase Backend**: Scalable cloud infrastructure
- **Real-time Database**: Firestore with optimized indexes
- **Cloud Functions**: Automated processing and triggers
- **Security Rules**: Role-based access control
- **Automated Monitoring**: Security and compliance checks

## 📱 Mobile App Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── activity.dart           # Activity entity
│   ├── user.dart               # User entity
│   ├── lp_event.dart           # LP event tracking
│   ├── user_activity.dart      # User activity progress
│   ├── security_event.dart     # Security monitoring
│   ├── age_verification.dart   # Age verification
│   ├── referral.dart           # Referral system
│   ├── audit_log.dart          # Audit logging
│   ├── app_config.dart         # App configuration
│   ├── ad_event.dart           # Ad engagement tracking
│   └── aer_event.dart          # Activity engagement records
├── services/                    # Business logic services
│   ├── database_service.dart   # Database operations
│   ├── user_service.dart       # User management
│   ├── activity_service.dart   # Activity management
│   ├── lp_service.dart         # LP management
│   ├── security_service.dart   # Security monitoring
│   ├── age_verification_service.dart  # Age verification
│   ├── referral_service.dart   # Referral management
│   ├── audit_service.dart      # Audit logging
│   ├── config_service.dart     # Configuration management
│   ├── ad_service.dart         # Ad management
│   └── aer_service.dart        # Activity engagement
└── data/                       # Data layer
    ├── repositories/           # Repository pattern implementation
    │   ├── user_repository.dart
    │   ├── activity_repository.dart
    │   ├── lp_repository.dart
    │   ├── security_repository.dart
    │   ├── age_verification_repository.dart
    │   ├── referral_repository.dart
    │   ├── audit_repository.dart
    │   ├── config_repository.dart
    │   ├── ad_repository.dart
    │   └── aer_repository.dart
    └── datasources/            # Data source abstractions
        ├── user_datasource.dart
        ├── activity_datasource.dart
        ├── lp_datasource.dart
        ├── security_datasource.dart
        ├── age_verification_datasource.dart
        ├── referral_datasource.dart
        ├── audit_datasource.dart
        ├── config_datasource.dart
        ├── ad_datasource.dart
        └── aer_datasource.dart
```

## 🔥 Firebase Backend

### Security Rules

- **Role-based Access Control**: 7-tier role system (user → superAdmin)
- **Data Validation**: Comprehensive input validation
- **Privacy Protection**: Personal data access restrictions
- **Administrative Controls**: Secure admin operations

### Cloud Functions

- **User Triggers**: Welcome bonuses, status changes
- **Activity Triggers**: LP rewards, achievement processing
- **Security Triggers**: Fraud detection, integrity validation
- **Scheduled Functions**: Daily maintenance, compliance reports
- **HTTP Functions**: RESTful API endpoints

### Database Collections

- `users`: User profiles and authentication
- `activities`: Learning activities and content
- `user_activities`: User progress tracking
- `lp_events`: LP earning/spending history
- `security_events`: Security monitoring logs
- `age_verifications`: Age verification records
- `referrals`: Referral system data
- `audit_logs`: System audit trails
- `app_configs`: Application configuration
- `ad_events`: Advertisement engagement
- `aer_events`: Activity engagement records

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK (3.0+)
- Firebase CLI
- Node.js (18+) for Cloud Functions
- Android Studio / Xcode for mobile development

### Firebase Setup

1. **Initialize Firebase Functions**:

   ```bash
   cd functions
   npm install
   ```

2. **Deploy Security Rules**:

   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Deploy Cloud Functions**:

   ```bash
   firebase deploy --only functions
   ```

4. **Deploy Firestore Indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Flutter Setup

1. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

2. **Configure Firebase**:

   ```bash
   flutter packages pub run build_runner build
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## 🔒 Security Features

### Authentication & Authorization

- Firebase Authentication integration
- Role-based access control (RBAC)
- JWT token validation
- Session management

### Fraud Detection

- Real-time activity monitoring
- Pattern analysis for suspicious behavior
- Automated security event logging
- LP integrity validation

### Privacy & Compliance

- Age verification system
- Data protection controls
- Audit logging for all operations
- Compliance reporting

## 📊 Admin Dashboard Features

### User Management

- User registration approval
- Role assignment and management
- Account status controls
- Activity monitoring

### Analytics & Reporting

- User engagement metrics
- LP distribution analytics
- Security event dashboards
- Compliance reports

### System Configuration

- Activity management
- Reward configuration
- Security parameter tuning
- Feature flag controls

## 🔄 Development Workflow

### Local Development

1. **Start Firebase Emulators**:

   ```bash
   firebase emulators:start
   ```

2. **Run Flutter App**:
   ```bash
   flutter run
   ```

### Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for Firebase operations
- Security rule testing

### Deployment

1. **Build Flutter App**:

   ```bash
   flutter build apk --release
   ```

2. **Deploy Firebase Backend**:
   ```bash
   firebase deploy
   ```

## 📈 Performance Optimizations

### Database Optimizations

- Composite indexes for complex queries
- Data denormalization for read performance
- Pagination for large result sets
- Caching strategies

### App Performance

- Lazy loading for heavy content
- Image optimization and caching
- Background task optimization
- Memory management

## 🔧 Configuration

### Environment Variables

- Firebase project configuration
- API keys and secrets
- Feature flags
- Performance thresholds

### App Configuration

- LP reward rates
- Activity difficulty levels
- Security parameters
- UI customization

## 📱 Supported Platforms

- iOS (11.0+)
- Android (API 21+)
- Web (Limited features)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper testing
4. Submit a pull request
5. Ensure all CI checks pass

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Check the documentation
- Review Firebase logs
- Contact the development team
- Submit issues via GitHub

---

**Built with ❤️ using Flutter and Firebase**
