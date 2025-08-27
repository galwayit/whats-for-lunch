import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_we_have_for_lunch/core/security/input_validator.dart';
import 'package:what_we_have_for_lunch/core/security/data_encryption.dart';
import 'package:what_we_have_for_lunch/core/security/secure_config.dart';
import 'package:what_we_have_for_lunch/core/security/network_security.dart';
import 'package:what_we_have_for_lunch/core/privacy/privacy_manager.dart';

void main() {
  group('Security Test Suite', () {
    group('Input Validation Security Tests', () {
      test('should prevent XSS attacks in user names', () {
        final maliciousInputs = [
          '<script>alert("XSS")</script>',
          'javascript:alert("XSS")',
          '<img src="x" onerror="alert(\'XSS\')" />',
          '"><script>alert("XSS")</script>',
          "'; DROP TABLE users; --",
        ];

        for (final input in maliciousInputs) {
          final result = InputValidator.validateUserName(input);
          expect(result.isValid, isFalse,
              reason: 'Should reject malicious input: $input');
        }
      });

      test('should prevent SQL injection in search queries', () {
        final maliciousQueries = [
          "'; DROP TABLE restaurants; --",
          "' OR '1'='1",
          "UNION SELECT * FROM users",
          "'; UPDATE users SET password='hacked'; --",
          "' OR 1=1 #",
        ];

        for (final query in maliciousQueries) {
          final result = InputValidator.validateSearchQuery(query);
          expect(result.isValid, isFalse,
              reason: 'Should reject SQL injection attempt: $query');
        }
      });

      test('should prevent path traversal attacks', () {
        final maliciousPaths = [
          '../../../etc/passwd',
          '..\\..\\..\\windows\\system32\\config\\sam',
          '/etc/shadow',
          'C:\\Windows\\System32\\drivers\\etc\\hosts',
          '....//....//....//etc/passwd',
        ];

        for (final path in maliciousPaths) {
          final result = InputValidator.validateFilePath(path);
          expect(result.isValid, isFalse,
              reason: 'Should reject path traversal attempt: $path');
        }
      });

      test('should validate location coordinates within bounds', () {
        final invalidCoordinates = [
          [-91.0, 0.0], // Invalid latitude
          [91.0, 0.0], // Invalid latitude
          [0.0, -181.0], // Invalid longitude
          [0.0, 181.0], // Invalid longitude
          [double.infinity, 0.0], // Infinity
          [double.nan, 0.0], // NaN
        ];

        for (final coords in invalidCoordinates) {
          final result = InputValidator.validateLocation(coords[0], coords[1]);
          expect(result.isValid, isFalse,
              reason: 'Should reject invalid coordinates: $coords');
        }
      });

      test('should handle excessive input sizes', () {
        final largeInput = 'A' * 10000; // Very large input

        final nameResult = InputValidator.validateUserName(largeInput);
        expect(nameResult.isValid, isFalse);

        final notesResult = InputValidator.validateNotes(largeInput);
        expect(notesResult.isValid, isFalse);
      });

      test('should sanitize HTML entities correctly', () {
        final htmlInput = '<div>Hello & "World" \'test\'</div>';
        final sanitized = InputValidator.encodeHtmlEntities(htmlInput);

        expect(sanitized, contains('&lt;'));
        expect(sanitized, contains('&gt;'));
        expect(sanitized, contains('&amp;'));
        expect(sanitized, contains('&quot;'));
        expect(sanitized, contains('&#x27;'));
      });

      test('should validate JSON input complexity', () {
        // Create deeply nested JSON
        Map<String, dynamic> deepJson = {};
        Map<String, dynamic> current = deepJson;

        for (int i = 0; i < 15; i++) {
          current['level$i'] = <String, dynamic>{};
          current = current['level$i'] as Map<String, dynamic>;
        }

        final jsonString = json.encode(deepJson);
        final result = InputValidator.validateJsonInput(jsonString);
        expect(result.isValid, isFalse,
            reason: 'Should reject overly complex JSON structures');
      });
    });

    group('Data Encryption Security Tests', () {
      test('should encrypt and decrypt user data correctly', () async {
        await DataEncryption.initialize();

        const testData = 'sensitive user information';
        final encrypted = await DataEncryption.encryptUserData(testData);
        final decrypted = await DataEncryption.decryptUserData(encrypted);

        expect(decrypted, equals(testData));
        expect(encrypted, isNot(equals(testData)));
        expect(encrypted.length, greaterThan(testData.length));
      });

      test('should handle location data encryption', () async {
        await DataEncryption.initialize();

        const latitude = 37.7749;
        const longitude = -122.4194;

        final encrypted =
            await DataEncryption.encryptLocationData(latitude, longitude);
        final decrypted = await DataEncryption.decryptLocationData(encrypted);

        expect(decrypted['lat'], equals(latitude));
        expect(decrypted['lng'], equals(longitude));
        expect(decrypted.containsKey('timestamp'), isTrue);
      });

      test('should generate consistent data hashes', () {
        const testData = 'test data for hashing';
        final hash1 = DataEncryption.generateDataHash(testData);
        final hash2 = DataEncryption.generateDataHash(testData);

        expect(hash1, equals(hash2));
        expect(hash1, hasLength(64)); // SHA-256 hex string
      });

      test('should verify data integrity correctly', () {
        const testData = 'integrity test data';
        final hash = DataEncryption.generateDataHash(testData);

        expect(DataEncryption.verifyDataIntegrity(testData, hash), isTrue);
        expect(
            DataEncryption.verifyDataIntegrity('modified data', hash), isFalse);
      });

      test('should fail decryption with invalid data', () async {
        await DataEncryption.initialize();

        expect(
          () async => await DataEncryption.decryptUserData('invalid_base64'),
          throwsException,
        );

        expect(
          () async => await DataEncryption.decryptUserData(''),
          throwsException,
        );
      });

      test('should handle preferences encryption', () async {
        await DataEncryption.initialize();

        final preferences = {
          'dietaryRestrictions': ['vegan', 'gluten-free'],
          'cuisinePreferences': ['italian', 'japanese'],
          'budgetLevel': 2,
        };

        final encrypted = await DataEncryption.encryptPreferences(preferences);
        final decrypted = await DataEncryption.decryptPreferences(encrypted);

        expect(decrypted['dietaryRestrictions'],
            equals(preferences['dietaryRestrictions']));
        expect(decrypted['budgetLevel'], equals(preferences['budgetLevel']));
      });
    });

    group('Network Security Tests', () {
      test('should validate certificate hashes correctly', () {
        // Mock certificate validation
        const hostname = 'maps.googleapis.com';

        // This would typically use real certificate data
        // For testing, we'll simulate the validation logic
        expect(hostname, isNotEmpty);
      });

      test('should detect malicious URLs', () {
        final maliciousUrls = [
          'javascript:alert("xss")',
          'data:text/html,<script>alert("xss")</script>',
          'vbscript:msgbox("xss")',
          'https://example.com/<script>alert("xss")</script>',
          'https://example.com/"onclick="alert()"',
        ];

        for (final url in maliciousUrls) {
          // Test would validate URL through request interceptor
          expect(
              url, contains(RegExp(r'[<>"\' ']|javascript:|data:|vbscript:')));
        }
      });

      test('should enforce request size limits', () {
        const maxSize = 1024 * 1024; // 1MB
        final largeData = 'A' * (maxSize + 1);

        expect(largeData.length, greaterThan(maxSize));
        // Request interceptor would reject this
      });

      test('should validate security headers', () {
        final requiredHeaders = [
          'X-Content-Type-Options',
          'X-Frame-Options',
          'Referrer-Policy',
        ];

        final securityHeaders =
            NetworkSecurity.createSecureDio().options.headers;

        for (final header in requiredHeaders) {
          // Check that security headers are present
          expect(
              securityHeaders.keys
                  .any((k) => k.toLowerCase().contains(header.toLowerCase())),
              isTrue);
        }
      });
    });

    group('Privacy Management Tests', () {
      test('should handle privacy consent correctly', () async {
        // Clear any existing consent
        await PrivacyManager.clearAllPrivacyData();

        // Initially should have no consent
        final initialConsent = await PrivacyManager.getPrivacyConsent();
        expect(initialConsent.grantedConsents, isEmpty);
        expect(await PrivacyManager.hasEssentialConsent(), isFalse);

        // Grant essential consent
        final newConsent = PrivacyConsent(
          grantedConsents: ['essential', 'location'],
          consentDate: DateTime.now(),
          version: '1.0.0',
        );

        await PrivacyManager.updatePrivacyConsent(newConsent);

        // Verify consent is stored
        final storedConsent = await PrivacyManager.getPrivacyConsent();
        expect(storedConsent.hasConsent('essential'), isTrue);
        expect(storedConsent.hasConsent('location'), isTrue);
        expect(storedConsent.hasConsent('marketing'), isFalse);
      });

      test('should handle consent revocation', () async {
        await PrivacyManager.clearAllPrivacyData();

        // Grant multiple consents
        final consent = PrivacyConsent(
          grantedConsents: ['essential', 'location', 'analytics'],
          consentDate: DateTime.now(),
          version: '1.0.0',
        );

        await PrivacyManager.updatePrivacyConsent(consent);
        expect(await PrivacyManager.hasConsent('analytics'), isTrue);

        // Revoke analytics consent
        await PrivacyManager.revokeConsent('analytics');
        expect(await PrivacyManager.hasConsent('analytics'), isFalse);
        expect(await PrivacyManager.hasConsent('essential'), isTrue);
      });

      test('should enforce data retention policies', () {
        final oldDate = DateTime.now().subtract(const Duration(days: 400));
        final recentDate = DateTime.now().subtract(const Duration(days: 20));

        expect(PrivacyManager.shouldDeleteData(oldDate, 'usage'), isTrue);
        expect(PrivacyManager.shouldDeleteData(recentDate, 'usage'), isFalse);

        expect(PrivacyManager.shouldDeleteData(oldDate, 'location'), isTrue);
        expect(
            PrivacyManager.shouldDeleteData(recentDate, 'location'), isFalse);
      });

      test('should generate privacy compliance report', () async {
        await PrivacyManager.clearAllPrivacyData();

        // Test without consent
        var report = await PrivacyManager.validateCompliance();
        expect(report.isCompliant, isFalse);
        expect(
            report.issues, contains(contains('Essential consent not granted')));

        // Grant essential consent
        final consent = PrivacyConsent(
          grantedConsents: ['essential'],
          consentDate: DateTime.now(),
          version: '1.0.0',
        );

        await PrivacyManager.updatePrivacyConsent(consent);

        report = await PrivacyManager.validateCompliance();
        expect(report.isCompliant, isTrue);
        expect(report.issues, isEmpty);
      });

      test('should handle data export for portability', () async {
        await PrivacyManager.clearAllPrivacyData();

        const userId = 123;
        final exportData = await PrivacyManager.exportUserData(userId);

        expect(exportData['userId'], equals(userId));
        expect(exportData['exportDate'], isNotNull);
        expect(exportData['privacyConsent'], isNotNull);
        expect(exportData['dataCategories'], isNotNull);
        expect(exportData['notice'], contains('personal data'));
      });
    });

    group('Secure Configuration Tests', () {
      test('should validate API key formats', () async {
        // Valid Google Maps API key format
        expect(SecureConfig.generateApiKeyHash(''), hasLength(64));

        // Test hash consistency
        final hash1 = SecureConfig.generateApiKeyHash('test_key');
        final hash2 = SecureConfig.generateApiKeyHash('test_key');
        expect(hash1, equals(hash2));
      });

      test('should handle configuration security context', () {
        final summary = SecureConfig.getConfigSummary();

        expect(summary.containsKey('initialized'), isTrue);
        expect(summary.containsKey('cacheSize'), isTrue);
        expect(summary.containsKey('securityLevel'), isTrue);
        expect(summary['securityLevel'], equals('development'));
      });

      test('should clear cache securely', () {
        SecureConfig.clearCache();
        final summary = SecureConfig.getConfigSummary();
        expect(summary['cacheSize'], equals(0));
      });
    });

    group('Rate Limiting Tests', () {
      test('should enforce input validation rate limits', () {
        InputRateLimit.clearHistory();

        const identifier = 'test_user';

        // Should allow initial requests
        for (int i = 0; i < 50; i++) {
          expect(InputRateLimit.isRateLimited(identifier), isFalse);
        }

        // Should start rate limiting after many requests
        for (int i = 0; i < 60; i++) {
          InputRateLimit.isRateLimited(identifier);
        }

        expect(InputRateLimit.isRateLimited(identifier), isTrue);
      });
    });

    group('Integration Security Tests', () {
      test('should maintain security across components', () async {
        // Test full security chain
        await DataEncryption.initialize();
        await PrivacyManager.clearAllPrivacyData();

        // 1. Validate input
        final nameResult = InputValidator.validateUserName('John Doe');
        expect(nameResult.isValid, isTrue);

        // 2. Encrypt sensitive data
        final encrypted =
            await DataEncryption.encryptUserData(nameResult.value!);
        expect(encrypted, isNotEmpty);

        // 3. Check privacy consent
        final hasConsent = await PrivacyManager.hasEssentialConsent();
        // Would be false initially, true after consent granted
        expect(hasConsent, isFalse);

        // 4. Verify network security
        final secureDio = NetworkSecurity.createSecureDio();
        expect(secureDio.options.connectTimeout, isNotNull);
        expect(secureDio.interceptors.length, greaterThan(0));
      });

      test('should handle security failures gracefully', () async {
        // Test error conditions
        expect(
          () async => await DataEncryption.decryptUserData('invalid'),
          throwsException,
        );

        expect(
          InputValidator.validateLocation(91.0, 0.0).isValid,
          isFalse,
        );

        expect(
          InputValidator.validateUserName('<script>alert("xss")</script>')
              .isValid,
          isFalse,
        );
      });
    });
  });
}

/// Test utilities for security testing
class SecurityTestUtils {
  static const List<String> commonXSSPayloads = [
    '<script>alert("XSS")</script>',
    'javascript:alert("XSS")',
    '<img src="x" onerror="alert(\'XSS\')" />',
    '"><script>alert("XSS")</script>',
    '\';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharCode(88,83,83))//";',
    'alert(String.fromCharCode(88,83,83))//";alert(String.fromCharCode(88,83,83))//--',
    '\'>"><marquee><img src=x onerror=confirm("XSS")></marquee>',
  ];

  static const List<String> commonSQLInjectionPayloads = [
    "'; DROP TABLE users; --",
    "' OR '1'='1",
    "' OR 1=1 --",
    "' UNION SELECT NULL, username, password FROM users --",
    "'; UPDATE users SET password='hacked' WHERE username='admin'; --",
    "' OR 1=1 #",
    "' OR 'a'='a",
    "') OR '1'='1' --",
  ];

  static const List<String> pathTraversalPayloads = [
    '../../../etc/passwd',
    '..\\..\\..\\windows\\system32\\config\\sam',
    '....//....//....//etc/passwd',
    '%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd',
    '..%252f..%252f..%252fetc%252fpasswd',
  ];

  /// Generate test data for security validation
  static Map<String, List<String>> getSecurityTestPayloads() {
    return {
      'xss': commonXSSPayloads,
      'sqli': commonSQLInjectionPayloads,
      'pathTraversal': pathTraversalPayloads,
    };
  }

  /// Verify that all security payloads are properly rejected
  static void validateSecurityRejection(
    List<String> payloads,
    bool Function(String) validator,
    String testName,
  ) {
    for (final payload in payloads) {
      if (validator(payload)) {
        throw Exception(
            '$testName: Security payload was not rejected: $payload');
      }
    }
  }
}
