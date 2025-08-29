import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enhanced Data Encryption Service
/// Provides AES-256 encryption for sensitive user data with proper key management
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for encryption keys (user-specific)
  final Map<String, Encrypter> _encrypterCache = {};
  final Map<String, IV> _ivCache = {};

  // Master encryption instance for system-level data
  late final Encrypter _systemEncrypter;
  late final IV _systemIV;

  // Initialize the encryption service
  Future<void> initialize() async {
    // Initialize system-level encryption
    final systemKey = Key.fromSecureRandom(32); // 256-bit key
    _systemEncrypter = Encrypter(AES(systemKey));
    _systemIV = IV.fromSecureRandom(16);

    // Store system key securely (in production, use Google Cloud KMS)
    await _storeSystemKey(systemKey);
  }

  /// Store system encryption key securely
  Future<void> _storeSystemKey(Key key) async {
    // In production, this should use Google Cloud KMS
    // For now, we'll store it in a secure document
    try {
      await _firestore.collection('_system').doc('encryption_config').set({
        'keyHash': sha256.convert(key.bytes).toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'algorithm': 'AES-256-CBC',
      });
    } catch (e) {
      print('Error storing system key: $e');
    }
  }

  /// Generate or retrieve user-specific encryption key
  Future<Encrypter> _getUserEncrypter(String userId) async {
    if (_encrypterCache.containsKey(userId)) {
      return _encrypterCache[userId]!;
    }

    // Generate user-specific key from userId and system key
    final userKeyMaterial =
        '$userId:${_auth.currentUser?.uid}:${DateTime.now().millisecondsSinceEpoch}';
    final userKeyBytes = sha256.convert(utf8.encode(userKeyMaterial)).bytes;
    final userKey = Key(Uint8List.fromList(userKeyBytes.take(32).toList()));

    final encrypter = Encrypter(AES(userKey));
    _encrypterCache[userId] = encrypter;

    return encrypter;
  }

  /// Generate or retrieve user-specific IV
  IV _getUserIV(String userId) {
    if (_ivCache.containsKey(userId)) {
      return _ivCache[userId]!;
    }

    // Generate deterministic IV from user ID (for consistency)
    final ivMaterial = sha256.convert(utf8.encode(userId)).bytes;
    final iv = IV(Uint8List.fromList(ivMaterial.take(16).toList()));
    _ivCache[userId] = iv;

    return iv;
  }

  /// Encrypt sensitive user data
  Future<String> encryptUserData(String plainText, String userId) async {
    try {
      if (plainText.isEmpty) return plainText;

      final encrypter = await _getUserEncrypter(userId);
      final iv = _getUserIV(userId);

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return base64 encoded encrypted data with metadata
      final encryptedData = {
        'data': encrypted.base64,
        'algorithm': 'AES-256-CBC',
        'version': '1.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      return base64.encode(utf8.encode(json.encode(encryptedData)));
    } catch (e) {
      throw Exception('Failed to encrypt user data: $e');
    }
  }

  /// Decrypt sensitive user data
  Future<String> decryptUserData(String encryptedText, String userId) async {
    try {
      if (encryptedText.isEmpty) return encryptedText;

      // Decode the encrypted data structure
      final decodedBytes = base64.decode(encryptedText);
      final decodedString = utf8.decode(decodedBytes);
      final encryptedData = json.decode(decodedString) as Map<String, dynamic>;

      // Verify encryption metadata
      if (encryptedData['algorithm'] != 'AES-256-CBC') {
        throw Exception('Unsupported encryption algorithm');
      }

      final encrypter = await _getUserEncrypter(userId);
      final iv = _getUserIV(userId);

      final encrypted = Encrypted.fromBase64(encryptedData['data']);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt user data: $e');
    }
  }

  /// Encrypt system-level sensitive data
  String encryptSystemData(String plainText) {
    try {
      if (plainText.isEmpty) return plainText;

      final encrypted = _systemEncrypter.encrypt(plainText, iv: _systemIV);

      final encryptedData = {
        'data': encrypted.base64,
        'algorithm': 'AES-256-CBC',
        'version': '1.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      return base64.encode(utf8.encode(json.encode(encryptedData)));
    } catch (e) {
      throw Exception('Failed to encrypt system data: $e');
    }
  }

  /// Decrypt system-level sensitive data
  String decryptSystemData(String encryptedText) {
    try {
      if (encryptedText.isEmpty) return encryptedText;

      final decodedBytes = base64.decode(encryptedText);
      final decodedString = utf8.decode(decodedBytes);
      final encryptedData = json.decode(decodedString) as Map<String, dynamic>;

      if (encryptedData['algorithm'] != 'AES-256-CBC') {
        throw Exception('Unsupported encryption algorithm');
      }

      final encrypted = Encrypted.fromBase64(encryptedData['data']);
      final decrypted = _systemEncrypter.decrypt(encrypted, iv: _systemIV);

      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt system data: $e');
    }
  }

  /// Encrypt user profile data
  Future<Map<String, dynamic>> encryptUserProfile({
    required String userId,
    String? mobile,
    String? address,
    String? pin,
    String? upiId,
    String? paypalEmail,
    String? bankAccount,
    String? parentEmail,
    Map<String, dynamic>? additionalData,
  }) async {
    final encryptedProfile = <String, dynamic>{};

    if (mobile != null && mobile.isNotEmpty) {
      encryptedProfile['mobileEnc'] = await encryptUserData(mobile, userId);
    }

    if (address != null && address.isNotEmpty) {
      encryptedProfile['addressEnc'] = await encryptUserData(address, userId);
    }

    if (pin != null && pin.isNotEmpty) {
      encryptedProfile['pinEnc'] = await encryptUserData(pin, userId);
    }

    if (upiId != null && upiId.isNotEmpty) {
      encryptedProfile['upiEnc'] = await encryptUserData(upiId, userId);
    }

    if (paypalEmail != null && paypalEmail.isNotEmpty) {
      encryptedProfile['paypalEnc'] =
          await encryptUserData(paypalEmail, userId);
    }

    if (bankAccount != null && bankAccount.isNotEmpty) {
      encryptedProfile['bankAccountEnc'] =
          await encryptUserData(bankAccount, userId);
    }

    if (parentEmail != null && parentEmail.isNotEmpty) {
      encryptedProfile['parentalConsentEnc'] =
          await encryptUserData(parentEmail, userId);
    }

    if (additionalData != null && additionalData.isNotEmpty) {
      encryptedProfile['additionalDataEnc'] =
          await encryptUserData(json.encode(additionalData), userId);
    }

    // Add metadata
    encryptedProfile['encryptionVersion'] = '1.0';
    encryptedProfile['encryptedAt'] = FieldValue.serverTimestamp();

    return encryptedProfile;
  }

  /// Decrypt user profile data
  Future<Map<String, dynamic>> decryptUserProfile({
    required String userId,
    required Map<String, dynamic> encryptedProfile,
  }) async {
    final decryptedProfile = <String, dynamic>{};

    if (encryptedProfile.containsKey('mobileEnc')) {
      decryptedProfile['mobile'] =
          await decryptUserData(encryptedProfile['mobileEnc'], userId);
    }

    if (encryptedProfile.containsKey('addressEnc')) {
      decryptedProfile['address'] =
          await decryptUserData(encryptedProfile['addressEnc'], userId);
    }

    if (encryptedProfile.containsKey('pinEnc')) {
      decryptedProfile['pin'] =
          await decryptUserData(encryptedProfile['pinEnc'], userId);
    }

    if (encryptedProfile.containsKey('upiEnc')) {
      decryptedProfile['upiId'] =
          await decryptUserData(encryptedProfile['upiEnc'], userId);
    }

    if (encryptedProfile.containsKey('paypalEnc')) {
      decryptedProfile['paypalEmail'] =
          await decryptUserData(encryptedProfile['paypalEnc'], userId);
    }

    if (encryptedProfile.containsKey('bankAccountEnc')) {
      decryptedProfile['bankAccount'] =
          await decryptUserData(encryptedProfile['bankAccountEnc'], userId);
    }

    if (encryptedProfile.containsKey('parentalConsentEnc')) {
      decryptedProfile['parentEmail'] =
          await decryptUserData(encryptedProfile['parentalConsentEnc'], userId);
    }

    if (encryptedProfile.containsKey('additionalDataEnc')) {
      final decryptedJson =
          await decryptUserData(encryptedProfile['additionalDataEnc'], userId);
      decryptedProfile['additionalData'] = json.decode(decryptedJson);
    }

    return decryptedProfile;
  }

  /// Hash sensitive data for comparison (one-way)
  String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure random token
  String generateSecureToken({int length = 32}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Encrypt withdrawal payment details
  Future<Map<String, dynamic>> encryptPaymentDetails({
    required String userId,
    required Map<String, dynamic> paymentDetails,
  }) async {
    final encryptedDetails = <String, dynamic>{};

    for (final entry in paymentDetails.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        // Encrypt sensitive payment information
        if (_isSensitivePaymentField(entry.key)) {
          encryptedDetails['${entry.key}Enc'] =
              await encryptUserData(entry.value.toString(), userId);
        } else {
          // Keep non-sensitive fields as is
          encryptedDetails[entry.key] = entry.value;
        }
      }
    }

    encryptedDetails['encryptionVersion'] = '1.0';
    encryptedDetails['encryptedAt'] = FieldValue.serverTimestamp();

    return encryptedDetails;
  }

  /// Decrypt withdrawal payment details
  Future<Map<String, dynamic>> decryptPaymentDetails({
    required String userId,
    required Map<String, dynamic> encryptedDetails,
  }) async {
    final decryptedDetails = <String, dynamic>{};

    for (final entry in encryptedDetails.entries) {
      if (entry.key.endsWith('Enc')) {
        // Decrypt encrypted fields
        final originalKey = entry.key.substring(0, entry.key.length - 3);
        decryptedDetails[originalKey] =
            await decryptUserData(entry.value.toString(), userId);
      } else if (!['encryptionVersion', 'encryptedAt'].contains(entry.key)) {
        // Keep non-encrypted fields as is
        decryptedDetails[entry.key] = entry.value;
      }
    }

    return decryptedDetails;
  }

  /// Check if a payment field contains sensitive information
  bool _isSensitivePaymentField(String fieldName) {
    const sensitiveFields = [
      'accountNumber',
      'routingNumber',
      'iban',
      'swiftCode',
      'paypalEmail',
      'cryptoAddress',
      'privateKey',
      'cardNumber',
      'cvv',
      'pin',
    ];

    return sensitiveFields.contains(fieldName.toLowerCase());
  }

  /// Clear encryption cache (call on logout)
  void clearCache() {
    _encrypterCache.clear();
    _ivCache.clear();
  }

  /// Validate encryption integrity
  Future<bool> validateEncryptionIntegrity(
      String encryptedData, String userId) async {
    try {
      final decrypted = await decryptUserData(encryptedData, userId);
      final reencrypted = await encryptUserData(decrypted, userId);

      // Decode both to compare the actual data (timestamps may differ)
      final originalDecoded =
          json.decode(utf8.decode(base64.decode(encryptedData)));
      final reencryptedDecoded =
          json.decode(utf8.decode(base64.decode(reencrypted)));

      return originalDecoded['data'] == reencryptedDecoded['data'];
    } catch (e) {
      return false;
    }
  }

  /// Get encryption statistics for monitoring
  Map<String, dynamic> getEncryptionStats() {
    return {
      'cachedEncrypters': _encrypterCache.length,
      'cachedIVs': _ivCache.length,
      'algorithm': 'AES-256-CBC',
      'version': '1.0',
      'lastActivity': DateTime.now().toIso8601String(),
    };
  }
}

/// Extension for easy encryption of user data models
extension EncryptedUserData on Map<String, dynamic> {
  /// Encrypt sensitive fields in user data
  Future<Map<String, dynamic>> encryptSensitiveFields(String userId) async {
    final encryptionService = EncryptionService();
    final encrypted = Map<String, dynamic>.from(this);

    // List of fields that should be encrypted
    const sensitiveFields = [
      'mobile',
      'address',
      'pin',
      'upiId',
      'paypalEmail',
      'bankAccount',
      'parentEmail',
      'ssn',
      'passport',
      'driverLicense',
    ];

    for (final field in sensitiveFields) {
      if (encrypted.containsKey(field) && encrypted[field] != null) {
        final value = encrypted[field].toString();
        if (value.isNotEmpty) {
          encrypted['${field}Enc'] =
              await encryptionService.encryptUserData(value, userId);
          encrypted.remove(field); // Remove plaintext version
        }
      }
    }

    return encrypted;
  }

  /// Decrypt sensitive fields in user data
  Future<Map<String, dynamic>> decryptSensitiveFields(String userId) async {
    final encryptionService = EncryptionService();
    final decrypted = Map<String, dynamic>.from(this);

    // Find and decrypt encrypted fields
    final encryptedFields =
        decrypted.keys.where((key) => key.endsWith('Enc')).toList();

    for (final encryptedField in encryptedFields) {
      try {
        final originalField =
            encryptedField.substring(0, encryptedField.length - 3);
        final decryptedValue = await encryptionService.decryptUserData(
            decrypted[encryptedField].toString(), userId);
        decrypted[originalField] = decryptedValue;
        decrypted.remove(encryptedField); // Remove encrypted version
      } catch (e) {
        print('Failed to decrypt field $encryptedField: $e');
      }
    }

    return decrypted;
  }
}
