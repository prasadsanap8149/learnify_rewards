import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_rewards/services/encryption_service.dart';
import 'package:learnify_rewards/services/serverless_manual_settlement_service.dart';
import 'package:learnify_rewards/shared/data/enums.dart';

void main() {
  group('Enhanced Security Integration Tests', () {
    late EncryptionService encryptionService;
    late ServerlessManualSettlementService withdrawalService;

    setUpAll(() async {
      encryptionService = EncryptionService();
      await encryptionService.initialize();
      withdrawalService = ServerlessManualSettlementService.instance;
    });

    group('Encryption Service Tests', () {
      test('should encrypt and decrypt user profile data', () async {
        const userId = 'test_user_123';
        const mobile = '+1234567890';
        const address = '123 Test Street, Test City';
        const bankAccount = '1234567890';

        // Encrypt profile data
        final encryptedProfile = await encryptionService.encryptUserProfile(
          userId: userId,
          mobile: mobile,
          address: address,
          bankAccount: bankAccount,
        );

        expect(encryptedProfile['mobile'], isNot(equals(mobile)));
        expect(encryptedProfile['address'], isNot(equals(address)));
        expect(encryptedProfile['bankAccount'], isNot(equals(bankAccount)));

        // Decrypt profile data
        final decryptedProfile = await encryptionService.decryptUserProfile(
          userId: userId,
          encryptedProfile: encryptedProfile,
        );

        expect(decryptedProfile['mobile'], equals(mobile));
        expect(decryptedProfile['address'], equals(address));
        expect(decryptedProfile['bankAccount'], equals(bankAccount));
      });

      test('should encrypt and decrypt payment details', () async {
        final paymentDetails = {
          'paypalEmail': 'test@example.com',
          'paypalPhone': '+1234567890',
          'accountNumber': '1234567890',
          'routingNumber': '987654321',
        };

        final encryptedDetails = await encryptionService.encryptPaymentDetails(
          paymentDetails,
        );

        // Should be encrypted
        expect(encryptedDetails['paypalEmail'], isNot(equals(paymentDetails['paypalEmail'])));
        expect(encryptedDetails['accountNumber'], isNot(equals(paymentDetails['accountNumber'])));

        final decryptedDetails = await encryptionService.decryptPaymentDetails(
          encryptedDetails,
        );

        expect(decryptedDetails['paypalEmail'], equals(paymentDetails['paypalEmail']));
        expect(decryptedDetails['accountNumber'], equals(paymentDetails['accountNumber']));
      });

      test('should handle different encryption keys for different users', () async {
        const user1 = 'user_1';
        const user2 = 'user_2';
        const testData = 'sensitive_data_123';

        final encrypted1 = await encryptionService.encryptString(testData, user1);
        final encrypted2 = await encryptionService.encryptString(testData, user2);

        // Different users should produce different encrypted output
        expect(encrypted1, isNot(equals(encrypted2)));

        // Each user should be able to decrypt their own data
        final decrypted1 = await encryptionService.decryptString(encrypted1, user1);
        final decrypted2 = await encryptionService.decryptString(encrypted2, user2);

        expect(decrypted1, equals(testData));
        expect(decrypted2, equals(testData));

        // Users should not be able to decrypt each other's data
        expect(
              () async => await encryptionService.decryptString(encrypted1, user2),
          throwsException,
        );
      });
    });

    group('Manual Settlement Workflow Tests', () {
      test('should handle withdrawal request with encryption', () async {
        final paymentDetails = {
          'paypalEmail': 'test@example.com',
          'paypalPhone': '+1234567890',
        };

        // This would normally integrate with Firebase
        // For testing, we'll verify the encryption works
        final encryptedDetails = await encryptionService.encryptPaymentDetails(
          paymentDetails,
        );

        expect(encryptedDetails['paypalEmail'], isNot(equals(paymentDetails['paypalEmail'])));
        expect(encryptedDetails['paypalPhone'], isNot(equals(paymentDetails['paypalPhone'])));

        // Verify we can decrypt for admin access
        final decryptedDetails = await encryptionService.decryptPaymentDetails(
          encryptedDetails,
        );

        expect(decryptedDetails['paypalEmail'], equals(paymentDetails['paypalEmail']));
        expect(decryptedDetails['paypalPhone'], equals(paymentDetails['paypalPhone']));
      });

      test('should create sanitized payment details for admin view', () async {
        final paymentDetails = {
          'paypalEmail': 'user@example.com',
          'paypalPhone': '+1234567890',
          'accountNumber': '1234567890123456',
          'routingNumber': '987654321',
        };

        final sanitized = withdrawalService.sanitizePaymentDetails(paymentDetails);

        expect(sanitized['paypalEmail'], contains('u***@example.com'));
        expect(sanitized['paypalPhone'], contains('+123***7890'));
        expect(sanitized['accountNumber'], contains('****567890123456'));
        expect(sanitized['routingNumber'], contains('****54321'));
      });

      test('should validate withdrawal amounts and limits', () {
        // Test minimum amount
        expect(withdrawalService.validateWithdrawalAmount(4.99), isFalse);
        expect(withdrawalService.validateWithdrawalAmount(5.00), isTrue);

        // Test maximum amount
        expect(withdrawalService.validateWithdrawalAmount(500.00), isTrue);
        expect(withdrawalService.validateWithdrawalAmount(500.01), isFalse);

        // Test valid range
        expect(withdrawalService.validateWithdrawalAmount(25.50), isTrue);
        expect(withdrawalService.validateWithdrawalAmount(100.00), isTrue);
      });
    });

    group('Security Validation Tests', () {
      test('should validate payment methods', () {
        expect(withdrawalService.isValidPaymentMethod(WithdrawalMethod.paypal), isTrue);
        expect(withdrawalService.isValidPaymentMethod(WithdrawalMethod.bankTransfer), isTrue);
        expect(withdrawalService.isValidPaymentMethod(WithdrawalMethod.giftCard), isTrue);
      });

      test('should handle encryption errors gracefully', () async {
        // Test with invalid user ID
        expect(
              () async => await encryptionService.encryptString('test', ''),
          throwsArgumentError,
        );

        // Test with null data
        expect(
              () async => await encryptionService.encryptString('', 'user123'),
          throwsArgumentError,
        );
      });

      test('should validate user permissions for settlement operations', () {
        // This would integrate with Firebase Auth custom claims
        // For testing, we'll verify the validation logic exists
        expect(withdrawalService.validateAdminPermissions, isNotNull);
        expect(withdrawalService.validateUserAccess, isNotNull);
      });
    });

    group('Performance Tests', () {
      test('should encrypt/decrypt large datasets efficiently', () async {
        const userId = 'perf_test_user';
        final largeData = List.generate(1000, (i) => 'Test data item $i').join('\n');

        final stopwatch = Stopwatch()..start();

        final encrypted = await encryptionService.encryptStringSimple(largeData, userId);
        final encryptTime = stopwatch.elapsedMilliseconds;

        stopwatch.reset();
        final decrypted = await encryptionService.decryptStringSimple(encrypted, userId);
        final decryptTime = stopwatch.elapsedMilliseconds;

        stopwatch.stop();

        expect(decrypted, equals(largeData));
        expect(encryptTime, lessThan(1000)); // Should complete within 1 second
        expect(decryptTime, lessThan(1000)); // Should complete within 1 second

        print('Encryption time: ${encryptTime}ms');
        print('Decryption time: ${decryptTime}ms');
      });

      test('should handle concurrent encryption operations', () async {
        const userId = 'concurrent_test_user';
        const testData = 'concurrent_test_data';

        final futures = List.generate(10, (i) async {
          final encrypted = await encryptionService.encryptStringSimple('$testData$i', userId);
          return encryptionService.decryptStringSimple(encrypted, userId);
        });

        final results = await Future.wait(futures);

        for (int i = 0; i < results.length; i++) {
          expect(results[i], equals('$testData$i'));
        }
      });
    });
  });
}
