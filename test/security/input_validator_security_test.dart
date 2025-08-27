import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/security/input_validator.dart';

/// Comprehensive security test suite for InputValidator
/// Tests OWASP Top 10 vulnerabilities and security best practices
void main() {
  group('Security Input Validator Tests', () {
    setUp(() {
      // Reset security stats before each test
      InputValidator.resetSecurityStats();
      InputRateLimit.clearHistory();
    });

    group('XSS Prevention Tests', () {
      test('should detect and block basic XSS attempts', () {
        final xssPayloads = [
          '<script>alert("xss")</script>',
          '<img src="x" onerror="alert(1)">',
          '<svg onload="alert(1)">',
          'javascript:alert(1)',
          '<iframe src="javascript:alert(1)">',
          '<body onload="alert(1)">',
          '<div onclick="alert(1)">click</div>',
        ];

        for (final payload in xssPayloads) {
          final result = InputValidator.validateUserName(payload);
          expect(result.isValid, false, reason: 'XSS payload should be rejected: $payload');
          expect(result.error, anyOf(contains('invalid content'), contains('invalid characters')), 
              reason: 'Should indicate malicious content');
        }

        // Verify threat counters
        final stats = InputValidator.getSecurityStats();
        expect(stats['xss_attempts'], greaterThan(0));
        expect(stats['malicious_content_attempts'], greaterThan(0));
      });

      test('should allow safe HTML entities', () {
        final safeInputs = [
          'John &amp; Jane',
          'Price: \$29.99',
          'Rating: 4/5 stars',
          'O\'Connor Restaurant',
          'Café "Le Français"',
        ];

        for (final input in safeInputs) {
          final result = InputValidator.validateUserName(input);
          expect(result.isValid, true, reason: 'Safe input should be accepted: $input');
        }
      });

      test('should properly encode HTML entities', () {
        final testCases = {
          '<script>': '&lt;script&gt;',
          'Tom & Jerry': 'Tom &amp; Jerry',
          '"quotes"': '&quot;quotes&quot;',
          "it's": 'it&#x27;s',
          'path/to/file': 'path&#x2F;to&#x2F;file',
        };

        testCases.forEach((input, expected) {
          final encoded = InputValidator.encodeHtmlEntities(input);
          expect(encoded, equals(expected), 
              reason: 'HTML encoding failed for: $input');
        });
      });
    });

    group('SQL Injection Prevention Tests', () {
      test('should detect SQL injection attempts', () {
        final sqlPayloads = [
          "'; DROP TABLE users; --",
          "1' OR '1'='1",
          "admin'--",
          "' UNION SELECT * FROM users --",
          "1; INSERT INTO users VALUES ('hacker', 'password'); --",
          "' OR 1=1 --",
          "'; EXEC xp_cmdshell('dir'); --",
          "' OR 'x'='x",
        ];

        for (final payload in sqlPayloads) {
          final result = InputValidator.validateSearchQuery(payload);
          expect(result.isValid, false, reason: 'SQL payload should be rejected: $payload');
        }

        final stats = InputValidator.getSecurityStats();
        expect(stats['sql_injection_attempts'], greaterThan(0));
      });

      test('should detect advanced SQL injection patterns', () {
        final advancedPayloads = [
          "1' AND (SELECT COUNT(*) FROM users) > 0 --",
          "'; WAITFOR DELAY '00:00:05' --",
          "1' OR (SELECT SUBSTRING(username,1,1) FROM users WHERE id=1)='a",
          "1' UNION ALL SELECT NULL,NULL,version() --",
        ];

        for (final payload in advancedPayloads) {
          final result = InputValidator.validateNotes(payload);
          expect(result.isValid, false, reason: 'Advanced SQL payload should be rejected: $payload');
        }
      });
    });

    group('Path Traversal Prevention Tests', () {
      test('should detect path traversal attempts', () {
        final pathTraversalPayloads = [
          '../../../etc/passwd',
          '..\\..\\..\\windows\\system32\\',
          '/../../etc/shadow',
          'file.txt../../../secret.txt',
          'normal.jpg../../config.php',
        ];

        for (final payload in pathTraversalPayloads) {
          final result = InputValidator.validateFilePath(payload);
          expect(result.isValid, false, reason: 'Path traversal should be rejected: $payload');
        }

        final stats = InputValidator.getSecurityStats();
        expect(stats['path_traversal_attempts'], greaterThan(0));
      });

      test('should allow safe file paths', () {
        final safeFiles = [
          'image.jpg',
          'document.pdf.png',
          'user-avatar.jpeg',
          'restaurant-photo.webp',
        ];

        for (final file in safeFiles) {
          final result = InputValidator.validateFilePath(file);
          expect(result.isValid, true, reason: 'Safe file path should be accepted: $file');
        }
      });
    });

    group('Input Length and Format Validation', () {
      test('should enforce length limits', () {
        // Test various length limits
        final longString = 'a' * 1000;
        
        expect(InputValidator.validateUserName(longString).isValid, false);
        expect(InputValidator.validateSearchQuery(longString).isValid, false);
        expect(InputValidator.validateNotes(longString).isValid, false);
      });

      test('should validate coordinate ranges', () {
        // Invalid coordinates
        expect(InputValidator.validateLocation(-91.0, 0.0).isValid, false);
        expect(InputValidator.validateLocation(91.0, 0.0).isValid, false);
        expect(InputValidator.validateLocation(0.0, -181.0).isValid, false);
        expect(InputValidator.validateLocation(0.0, 181.0).isValid, false);
        expect(InputValidator.validateLocation(double.nan, 0.0).isValid, false);
        expect(InputValidator.validateLocation(0.0, double.infinity).isValid, false);

        // Valid coordinates
        expect(InputValidator.validateLocation(40.7128, -74.0060).isValid, true);
        expect(InputValidator.validateLocation(0.0, 0.0).isValid, true);
        expect(InputValidator.validateLocation(90.0, 180.0).isValid, true);
        expect(InputValidator.validateLocation(-90.0, -180.0).isValid, true);
      });

      test('should validate budget amounts', () {
        // Invalid amounts
        expect(InputValidator.validateBudgetAmount(-10.0).isValid, false);
        expect(InputValidator.validateBudgetAmount(0.0).isValid, false);
        expect(InputValidator.validateBudgetAmount(20000.0).isValid, false);

        // Valid amounts
        expect(InputValidator.validateBudgetAmount(25.50).isValid, true);
        expect(InputValidator.validateBudgetAmount(100.0).isValid, true);
        expect(InputValidator.validateBudgetAmount(9999.99).isValid, true);
      });
    });

    group('JSON Input Validation', () {
      test('should validate JSON structure and depth', () {
        // Test deeply nested JSON (should be rejected)
        final deepJson = '{"a":{"b":{"c":{"d":{"e":{"f":{"g":{"h":{"i":{"j":{"k":"deep"}}}}}}}}}}';
        expect(InputValidator.validateJsonInput(deepJson).isValid, false);

        // Test large JSON (should be rejected)
        final largeData = "x" * 15000;
        final largeJson = "{\"data\":\"$largeData\"}";
        expect(InputValidator.validateJsonInput(largeJson).isValid, false);

        // Test valid JSON
        expect(InputValidator.validateJsonInput('{"name":"John","age":30}').isValid, true);
        expect(InputValidator.validateJsonInput('[]').isValid, true);
        expect(InputValidator.validateJsonInput('{}').isValid, true);
      });

      test('should sanitize JSON values', () {
        final maliciousJson = '{"name":"<script>alert(1)</script>","description":"safe text"}';
        final result = InputValidator.validateJsonInput(maliciousJson);
        
        expect(result.isValid, true);
        expect(result.value!['name'], contains('&lt;script&gt;'));
        expect(result.value!['description'], equals('safe text'));
      });
    });

    group('Rate Limiting Tests', () {
      test('should enforce basic rate limiting', () {
        final identifier = 'test_user_123';
        
        // Should allow normal usage
        expect(InputRateLimit.isRateLimited(identifier), false);
        
        // Simulate rapid requests (beyond normal limit)
        for (int i = 0; i < 105; i++) {
          InputRateLimit.isRateLimited(identifier);
        }
        
        // Should now be rate limited
        expect(InputRateLimit.isRateLimited(identifier), true);
      });

      test('should track security statistics', () {
        // Generate some security events
        InputValidator.validateUserName('<script>alert(1)</script>');
        InputValidator.validateSearchQuery("'; DROP TABLE users; --");
        InputValidator.validateFilePath('../../../etc/passwd');
        
        final stats = InputValidator.getSecurityStats();
        expect(stats['xss_attempts'], greaterThan(0));
        expect(stats['sql_injection_attempts'], greaterThan(0));
        expect(stats['path_traversal_attempts'], greaterThan(0));
        expect(stats['malicious_content_attempts'], greaterThan(0));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null and empty inputs', () {
        expect(InputValidator.validateUserName(null).isValid, false);
        expect(InputValidator.validateUserName('').isValid, false);
        expect(InputValidator.validateUserName('   ').isValid, false);
        
        expect(InputValidator.validateSearchQuery(null).isValid, false);
        expect(InputValidator.validateSearchQuery('').isValid, false);
        
        expect(InputValidator.validateNotes(null).isValid, true); // Notes can be empty
        expect(InputValidator.validateNotes('').isValid, true);
      });

      test('should handle special characters correctly', () {
        final specialChars = [
          'José García', // Accented characters
          '北京烤鸭',      // Chinese characters
          '🍕🍔🍟',       // Emojis
          'café münchen', // Mixed languages
        ];

        for (final input in specialChars) {
          final result = InputValidator.validateUserName(input);
          // Should be rejected due to current namePattern, but not due to security threats
          if (!result.isValid) {
            expect(result.error, contains('invalid characters'));
          }
        }
      });

      test('should maintain precision in coordinate validation', () {
        final result = InputValidator.validateLocation(40.12345678901234, -74.987654321987654);
        expect(result.isValid, true);
        
        // Should round to 6 decimal places
        expect(result.value!['latitude'].toString().split('.')[1].length, lessThanOrEqualTo(6));
        expect(result.value!['longitude'].toString().split('.')[1].length, lessThanOrEqualTo(6));
      });
    });

    group('Security Best Practices Compliance', () {
      test('should follow fail-secure principle', () {
        // Invalid inputs should fail securely (return false/error)
        expect(InputValidator.validateUserName('invalid<script>').isValid, false);
        expect(InputValidator.validateLocation(null, null).isValid, false);
        expect(InputValidator.validateBudgetAmount(null).isValid, false);
      });

      test('should not leak sensitive information in error messages', () {
        final maliciousInputs = [
          '<script>alert(document.cookie)</script>',
          "'; SELECT password FROM users; --",
          '../../../etc/passwd',
        ];

        for (final input in maliciousInputs) {
          final result = InputValidator.validateUserName(input);
          expect(result.isValid, false);
          // Error messages should be generic, not reveal the actual malicious content
          expect(result.error, anyOf([
            contains('invalid content'),
            contains('invalid characters'),
          ]));
          expect(result.error, isNot(contains(input)));
        }
      });

      test('should properly sanitize inputs', () {
        final testInput = '<script>alert("test")</script>Safe Text';
        final sanitized = InputValidator.sanitizeInput(testInput);
        
        expect(sanitized, isNot(contains('<script>')));
        expect(sanitized, contains('Safe Text'));
      });
    });
  });
}