# Deployment Guide

## Prerequisites

- Firebase CLI installed and authenticated
- Node.js 18+ for Cloud Functions
- Flutter SDK for mobile app

## Firebase Project Setup

### 1. Initialize Firebase Project

```bash
# Login to Firebase
firebase login

# Initialize project (already done)
firebase init

# Set project ID
firebase use --add your-project-id
```

### 2. Deploy Security Rules

```bash
firebase deploy --only firestore:rules
```

### 3. Deploy Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

### 4. Setup Cloud Functions

```bash
cd functions
npm install
npm run build
```

### 5. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

## Flutter App Deployment

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Environment Configuration

### Production Environment

- Update Firebase project ID in `.firebaserc`
- Configure authentication providers
- Set up production domain for auth redirects
- Configure Cloud Storage rules

### Development Environment

```bash
firebase emulators:start
```

## Post-Deployment Checklist

1. **Security Rules Testing**

   - Test role-based access
   - Verify data validation rules
   - Check privacy controls

2. **Cloud Functions Testing**

   - Test trigger functions
   - Verify scheduled functions
   - Test HTTP endpoints

3. **Mobile App Testing**

   - Test authentication flow
   - Verify LP earning system
   - Test activity completion
   - Check security monitoring

4. **Performance Monitoring**
   - Enable Firebase Performance
   - Set up error tracking
   - Monitor function execution times

## Monitoring & Maintenance

### Daily Tasks

- Check security events
- Monitor LP distribution
- Review user registrations

### Weekly Tasks

- Compliance reporting
- Performance analysis
- Security audit review

### Monthly Tasks

- System health check
- User engagement analysis
- Feature usage metrics
