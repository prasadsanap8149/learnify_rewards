# Testing Guide

## Overview

This guide covers testing strategies for the Learnify Rewards application, including unit tests, integration tests, and Firebase-specific testing.

## Testing Structure

```
test/
├── unit/                       # Unit tests
│   ├── models/                # Model tests
│   ├── services/              # Service layer tests
│   └── repositories/          # Repository tests
├── integration/               # Integration tests
│   ├── firebase/              # Firebase integration tests
│   └── e2e/                   # End-to-end tests
├── widget/                    # Widget tests
└── mocks/                     # Mock objects and data
```

## Firebase Emulator Testing

### Setup Firebase Emulators

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators
firebase emulators:start
```

### Emulator Configuration

```json
{
  "emulators": {
    "firestore": {
      "port": 8080
    },
    "functions": {
      "port": 5001
    },
    "auth": {
      "port": 9099
    },
    "storage": {
      "port": 9199
    }
  }
}
```

## Unit Testing

### Model Tests

```dart
// test/unit/models/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_rewards/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('should create user from JSON', () {
      final json = {
        'id': 'user1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'user',
        'status': 'active',
        'lpBalance': 100.0,
      };

      final user = User.fromJson(json);

      expect(user.id, equals('user1'));
      expect(user.name, equals('John Doe'));
      expect(user.role, equals(UserRole.user));
      expect(user.lpBalance, equals(100.0));
    });

    test('should convert user to JSON', () {
      final user = User(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        lpBalance: 100.0,
        createdAt: DateTime.parse('2024-01-01'),
        updatedAt: DateTime.parse('2024-01-01'),
      );

      final json = user.toJson();

      expect(json['id'], equals('user1'));
      expect(json['name'], equals('John Doe'));
      expect(json['role'], equals('user'));
      expect(json['lpBalance'], equals(100.0));
    });
  });
}
```

### Service Tests

```dart
// test/unit/services/user_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:learnify_rewards/services/user_service.dart';
import 'package:learnify_rewards/data/repositories/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserService Tests', () {
    late UserService userService;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      userService = UserService(repository: mockRepository);
    });

    test('should get user by ID', () async {
      // Given
      final userId = 'user1';
      final expectedUser = User(
        id: userId,
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        lpBalance: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getUser(userId))
          .thenAnswer((_) async => expectedUser);

      // When
      final result = await userService.getUserById(userId);

      // Then
      expect(result, equals(expectedUser));
      verify(mockRepository.getUser(userId)).called(1);
    });
  });
}
```

## Integration Testing

### Firebase Integration Tests

```dart
// test/integration/firebase/user_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:learnify_rewards/data/repositories/user_repository.dart';
import 'package:learnify_rewards/models/user.dart';

void main() {
  group('User Repository Integration Tests', () {
    late FakeFirebaseFirestore firestore;
    late UserRepository userRepository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      userRepository = UserRepository(firestore: firestore);
    });

    test('should create and retrieve user', () async {
      // Given
      final user = User(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        lpBalance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When
      await userRepository.createUser(user);
      final retrievedUser = await userRepository.getUser('user1');

      // Then
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals('user1'));
      expect(retrievedUser.name, equals('John Doe'));
    });

    test('should update user LP balance', () async {
      // Given
      final user = User(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        lpBalance: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.createUser(user);

      // When
      await userRepository.updateLPBalance('user1', 150.0);
      final updatedUser = await userRepository.getUser('user1');

      // Then
      expect(updatedUser!.lpBalance, equals(150.0));
    });
  });
}
```

## Widget Testing

### UI Component Tests

```dart
// test/widget/user_profile_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:learnify_rewards/widgets/user_profile_widget.dart';
import 'package:learnify_rewards/services/user_service.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  group('UserProfileWidget Tests', () {
    late MockUserService mockUserService;

    setUp(() {
      mockUserService = MockUserService();
    });

    testWidgets('should display user information', (WidgetTester tester) async {
      // Given
      final user = User(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        lpBalance: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockUserService.getCurrentUser())
          .thenAnswer((_) async => user);

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserService>.value(
            value: mockUserService,
            child: UserProfileWidget(),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('100.0 LP'), findsOneWidget);
    });
  });
}
```

## Security Rules Testing

### Firestore Rules Tests

```javascript
// test/security_rules/firestore_rules_test.js
const firebase = require("@firebase/rules-unit-testing");
const fs = require("fs");

const projectId = "test-project";
const rules = fs.readFileSync("firestore.rules", "utf8");

describe("Firestore Security Rules", () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await firebase.initializeTestEnvironment({
      projectId,
      firestore: {
        rules,
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  test("should allow user to read their own profile", async () => {
    const alice = testEnv.authenticatedContext("alice", {
      role: "user",
    });

    await firebase.assertSucceeds(
      alice.firestore().collection("users").doc("alice").get()
    );
  });

  test("should deny user reading other profiles", async () => {
    const alice = testEnv.authenticatedContext("alice", {
      role: "user",
    });

    await firebase.assertFails(
      alice.firestore().collection("users").doc("bob").get()
    );
  });

  test("should allow admin to read all users", async () => {
    const admin = testEnv.authenticatedContext("admin", {
      role: "admin",
    });

    await firebase.assertSucceeds(admin.firestore().collection("users").get());
  });
});
```

## Performance Testing

### Load Testing

```dart
// test/performance/load_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_rewards/services/lp_service.dart';

void main() {
  group('Performance Tests', () {
    test('should handle multiple concurrent LP operations', () async {
      final lpService = LPService();
      final futures = <Future>[];

      // Simulate 100 concurrent LP operations
      for (int i = 0; i < 100; i++) {
        futures.add(lpService.awardLP('user$i', 10.0, 'test'));
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      // Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
```

## Test Data Setup

### Mock Data Factory

```dart
// test/mocks/test_data_factory.dart
import 'package:learnify_rewards/models/user.dart';
import 'package:learnify_rewards/models/activity.dart';

class TestDataFactory {
  static User createUser({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    UserStatus? status,
    double? lpBalance,
  }) {
    return User(
      id: id ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test User',
      email: email ?? 'test@example.com',
      role: role ?? UserRole.user,
      status: status ?? UserStatus.active,
      lpBalance: lpBalance ?? 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Activity createActivity({
    String? id,
    String? title,
    ActivityType? type,
    ActivityDifficulty? difficulty,
    double? lpReward,
  }) {
    return Activity(
      id: id ?? 'test_activity_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Activity',
      description: 'Test activity description',
      type: type ?? ActivityType.quiz,
      difficulty: difficulty ?? ActivityDifficulty.beginner,
      lpReward: lpReward ?? 10.0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

## Running Tests

### All Tests

```bash
flutter test
```

### Specific Test Categories

```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests only
flutter test test/integration/
```

### Coverage Report

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Continuous Integration

### GitHub Actions Configuration

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.16.0"

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v1
        with:
          file: coverage/lcov.info
```

## Best Practices

1. **Test Organization**: Group related tests using `group()`
2. **Mock External Dependencies**: Use mockito for service mocking
3. **Test Data Isolation**: Use unique test data for each test
4. **Firebase Emulators**: Always use emulators for Firebase testing
5. **Coverage Goals**: Aim for >80% code coverage
6. **Performance Testing**: Include performance benchmarks
7. **Security Testing**: Test security rules thoroughly
8. **Documentation**: Document complex test scenarios
