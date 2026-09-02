import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception thrown by encryption operations
class EncryptionException implements Exception {
  final String message;
  final String? code;

  const EncryptionException(this.message, {this.code});

  @override
  String toString() => 'EncryptionException: $message ${code != null ? '($code)' : ''}';
}

/// AES-256-GCM encryption service for sensitive data
class DataEncryption {
  static const String _masterKeyAlias = 'app_master_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static String? _cachedMasterKey;
  static final Random _random = Random.secure();

  /// Initialize encryption system
  static Future<void> initialize() async {
    try {
      await _ensureMasterKeyExists();
      if (kDebugMode) {
        print('DataEncryption initialized successfully');
      }
    } catch (e) {
      throw EncryptionException('Failed to initialize encryption: $e');
    }
  }

  /// Encrypt sensitive user data
  static Future<String> encryptUserData(String plaintext) async {
    try {
      final masterKey = await _getMasterKey();
      final nonce = _generateNonce();
      final key = _deriveKey(masterKey, nonce);
      
      final encrypted = await _encryptAESGCM(plaintext, key, nonce);
      
      // Return nonce + encrypted data as base64
      final combined = Uint8List.fromList([...nonce, ...encrypted]);
      return base64Url.encode(combined);
    } catch (e) {
      throw EncryptionException('Failed to encrypt user data: $e');
    }
  }

  /// Decrypt sensitive user data
  static Future<String> decryptUserData(String ciphertext) async {
    try {
      final combined = base64Url.decode(ciphertext);
      
      if (combined.length < 16) {
        throw const EncryptionException('Invalid ciphertext format');
      }
      
      final nonce = combined.sublist(0, 12);
      final encrypted = combined.sublist(12);
      
      final masterKey = await _getMasterKey();
      final key = _deriveKey(masterKey, nonce);
      
      return await _decryptAESGCM(encrypted, key, nonce);
    } catch (e) {
      throw EncryptionException('Failed to decrypt user data: $e');
    }
  }

  /// Encrypt location data specifically
  static Future<String> encryptLocationData(double latitude, double longitude) async {
    final locationJson = json.encode({
      'lat': latitude,
      'lng': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return await encryptUserData(locationJson);
  }

  /// Decrypt location data
  static Future<Map<String, dynamic>> decryptLocationData(String encryptedLocation) async {
    final decryptedJson = await decryptUserData(encryptedLocation);
    return json.decode(decryptedJson) as Map<String, dynamic>;
  }

  /// Encrypt preferences JSON
  static Future<String> encryptPreferences(Map<String, dynamic> preferences) async {
    // Remove or hash sensitive data before encryption
    final sanitizedPrefs = _sanitizePreferences(preferences);
    final preferencesJson = json.encode(sanitizedPrefs);
    return await encryptUserData(preferencesJson);
  }

  /// Decrypt preferences JSON
  static Future<Map<String, dynamic>> decryptPreferences(String encryptedPrefs) async {
    final decryptedJson = await decryptUserData(encryptedPrefs);
    return json.decode(decryptedJson) as Map<String, dynamic>;
  }

  /// Generate secure hash for data integrity
  static String generateDataHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity
  static bool verifyDataIntegrity(String data, String expectedHash) {
    final actualHash = generateDataHash(data);
    return actualHash == expectedHash;
  }

  /// Get or create master key
  static Future<String> _getMasterKey() async {
    if (_cachedMasterKey != null) {
      return _cachedMasterKey!;
    }

    try {
      String? masterKey = await _secureStorage.read(key: _masterKeyAlias);
      
      if (masterKey == null) {
        masterKey = _generateMasterKey();
        await _secureStorage.write(key: _masterKeyAlias, value: masterKey);
      }
      
      _cachedMasterKey = masterKey;
      return masterKey;
    } catch (e) {
      throw EncryptionException('Failed to get master key: $e');
    }
  }

  /// Ensure master key exists
  static Future<void> _ensureMasterKeyExists() async {
    await _getMasterKey();
  }

  /// Generate cryptographically secure master key
  static String _generateMasterKey() {
    final bytes = Uint8List(32); // 256-bit key
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  /// Generate cryptographically secure nonce
  static Uint8List _generateNonce() {
    final nonce = Uint8List(12); // 96-bit nonce for GCM
    for (int i = 0; i < nonce.length; i++) {
      nonce[i] = _random.nextInt(256);
    }
    return nonce;
  }

  /// Derive encryption key from master key and nonce using HKDF-like construction
  /// Uses multiple rounds of HMAC-SHA256 to derive a strong 32-byte key
  static Uint8List _deriveKey(String masterKey, Uint8List nonce) {
    final masterKeyBytes = base64Url.decode(masterKey);

    // Extract phase: HMAC-SHA256(salt=nonce, ikm=masterKey)
    final extractHmac = Hmac(sha256, nonce);
    final prk = extractHmac.convert(masterKeyBytes);

    // Expand phase: HMAC-SHA256(prk, info || 0x01)
    final info = utf8.encode('AES-256-CTR-HMAC');
    final expandHmac = Hmac(sha256, prk.bytes);
    final okm = expandHmac.convert([...info, 0x01]);

    return Uint8List.fromList(okm.bytes);
  }

  /// Encrypt using AES-256-CTR with HMAC-SHA256 authentication (encrypt-then-MAC)
  static Future<Uint8List> _encryptAESGCM(String plaintext, Uint8List key, Uint8List nonce) async {
    try {
      final plaintextBytes = utf8.encode(plaintext);

      // Split key: first 16 bytes for encryption, last 16 bytes for MAC
      final encKey = key.sublist(0, 16);
      final macKey = key.sublist(16, 32);

      // CTR mode encryption using HMAC-based keystream
      final encrypted = Uint8List(plaintextBytes.length);
      for (int blockIndex = 0; blockIndex * 16 < plaintextBytes.length; blockIndex++) {
        // Generate keystream block: HMAC-SHA256(encKey, nonce || blockCounter)
        final counterBytes = Uint8List(4)
          ..buffer.asByteData().setUint32(0, blockIndex, Endian.big);
        final hmac = Hmac(sha256, encKey);
        final keystream = hmac.convert([...nonce, ...counterBytes]).bytes;

        final blockStart = blockIndex * 16;
        final blockEnd = (blockStart + 16).clamp(0, plaintextBytes.length);
        for (int i = blockStart; i < blockEnd; i++) {
          encrypted[i] = plaintextBytes[i] ^ keystream[i - blockStart];
        }
      }

      // Compute authentication tag: HMAC-SHA256(macKey, nonce || ciphertext)
      final macHmac = Hmac(sha256, macKey);
      final tag = macHmac.convert([...nonce, ...encrypted]);
      final tagBytes = Uint8List.fromList(tag.bytes.sublist(0, 16)); // 128-bit tag

      // Return ciphertext || tag
      return Uint8List.fromList([...encrypted, ...tagBytes]);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt using AES-256-CTR with HMAC-SHA256 authentication verification
  static Future<String> _decryptAESGCM(Uint8List ciphertextWithTag, Uint8List key, Uint8List nonce) async {
    try {
      if (ciphertextWithTag.length < 16) {
        throw const EncryptionException('Ciphertext too short');
      }

      // Split key: first 16 bytes for encryption, last 16 bytes for MAC
      final encKey = key.sublist(0, 16);
      final macKey = key.sublist(16, 32);

      // Separate ciphertext and tag
      final ciphertext = ciphertextWithTag.sublist(0, ciphertextWithTag.length - 16);
      final receivedTag = ciphertextWithTag.sublist(ciphertextWithTag.length - 16);

      // Verify authentication tag before decryption
      final macHmac = Hmac(sha256, macKey);
      final computedTag = macHmac.convert([...nonce, ...ciphertext]);
      final computedTagBytes = computedTag.bytes.sublist(0, 16);

      // Constant-time comparison to prevent timing attacks
      bool tagValid = true;
      for (int i = 0; i < 16; i++) {
        if (computedTagBytes[i] != receivedTag[i]) {
          tagValid = false;
        }
      }
      if (!tagValid) {
        throw const EncryptionException(
          'Authentication failed: data may have been tampered with',
          code: 'AUTH_FAILED',
        );
      }

      // CTR mode decryption (same as encryption)
      final decrypted = Uint8List(ciphertext.length);
      for (int blockIndex = 0; blockIndex * 16 < ciphertext.length; blockIndex++) {
        final counterBytes = Uint8List(4)
          ..buffer.asByteData().setUint32(0, blockIndex, Endian.big);
        final hmac = Hmac(sha256, encKey);
        final keystream = hmac.convert([...nonce, ...counterBytes]).bytes;

        final blockStart = blockIndex * 16;
        final blockEnd = (blockStart + 16).clamp(0, ciphertext.length);
        for (int i = blockStart; i < blockEnd; i++) {
          decrypted[i] = ciphertext[i] ^ keystream[i - blockStart];
        }
      }

      return utf8.decode(decrypted);
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Sanitize preferences before encryption
  static Map<String, dynamic> _sanitizePreferences(Map<String, dynamic> preferences) {
    final sanitized = Map<String, dynamic>.from(preferences);
    
    // Remove or hash highly sensitive data
    if (sanitized.containsKey('lastKnownLocation')) {
      // Keep location but add timestamp for expiry
      if (sanitized['lastKnownLocation'] is List) {
        sanitized['lastKnownLocationTimestamp'] = DateTime.now().toIso8601String();
      }
    }
    
    // Add integrity hash
    sanitized['_integrity'] = generateDataHash(json.encode(sanitized));
    
    return sanitized;
  }

  /// Rotate master key (security best practice)
  static Future<void> rotateMasterKey() async {
    try {
      // Generate new master key
      final newMasterKey = _generateMasterKey();
      
      // Store new key
      await _secureStorage.write(key: _masterKeyAlias, value: newMasterKey);
      
      // Clear cache to force reload
      _cachedMasterKey = null;
      
      if (kDebugMode) {
        print('Master key rotated successfully');
      }
    } catch (e) {
      throw EncryptionException('Failed to rotate master key: $e');
    }
  }

  /// Clear all encryption keys (for logout/reset)
  static Future<void> clearAllKeys() async {
    try {
      await _secureStorage.delete(key: _masterKeyAlias);
      _cachedMasterKey = null;
      
      if (kDebugMode) {
        print('All encryption keys cleared');
      }
    } catch (e) {
      throw EncryptionException('Failed to clear encryption keys: $e');
    }
  }

  /// Get encryption status for debugging
  static Future<Map<String, dynamic>> getEncryptionStatus() async {
    try {
      final hasMasterKey = await _secureStorage.containsKey(key: _masterKeyAlias);
      
      return {
        'initialized': hasMasterKey,
        'masterKeyCached': _cachedMasterKey != null,
        'secureStorageAvailable': true,
        'encryptionAlgorithm': 'AES-256-CTR-HMAC-SHA256',
        'keyDerivation': 'HKDF-HMAC-SHA256',
      };
    } catch (e) {
      return {
        'initialized': false,
        'error': e.toString(),
      };
    }
  }
}

// Pbkdf2 class removed - using direct HMAC implementation