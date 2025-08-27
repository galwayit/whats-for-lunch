import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Exception thrown by secure configuration operations
class SecureConfigException implements Exception {
  final String message;
  final String? code;

  const SecureConfigException(this.message, {this.code});

  @override
  String toString() => 'SecureConfigException: $message ${code != null ? '($code)' : ''}';
}

/// Secure configuration management with API key obfuscation and runtime decryption
class SecureConfig {
  static const MethodChannel _channel = MethodChannel('secure_config');
  static final Map<String, String> _cache = {};
  static bool _initialized = false;

  /// Initialize secure configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Verify platform security features
      await _verifySecurityFeatures();
      _initialized = true;

      if (kDebugMode) {
        print('SecureConfig initialized successfully');
      }
    } catch (e) {
      throw SecureConfigException('Failed to initialize secure config: $e');
    }
  }

  /// Get Google Maps API key securely
  static Future<String> getGoogleMapsApiKey() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Try cache first
      if (_cache.containsKey('google_maps_api_key')) {
        return _cache['google_maps_api_key']!;
      }

      // Get from native platform securely
      final apiKey = await _getSecureApiKey('google_maps');
      if (apiKey.isEmpty) {
        throw const SecureConfigException('Google Maps API key not configured');
      }

      // Validate API key format
      if (!_isValidGoogleMapsApiKey(apiKey)) {
        throw const SecureConfigException('Invalid Google Maps API key format');
      }

      // Cache for session
      _cache['google_maps_api_key'] = apiKey;
      return apiKey;
    } catch (e) {
      throw SecureConfigException('Failed to get Google Maps API key: $e');
    }
  }

  /// Get Gemini AI API key securely
  static Future<String> getGeminiApiKey() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Try cache first
      if (_cache.containsKey('gemini_api_key')) {
        return _cache['gemini_api_key']!;
      }

      // Get from native platform securely
      final apiKey = await _getSecureApiKey('gemini');
      if (apiKey.isEmpty) {
        throw const SecureConfigException('Gemini API key not configured');
      }

      // Validate API key format
      if (!_isValidGeminiApiKey(apiKey)) {
        throw const SecureConfigException('Invalid Gemini API key format');
      }

      // Cache for session
      _cache['gemini_api_key'] = apiKey;
      return apiKey;
    } catch (e) {
      throw SecureConfigException('Failed to get Gemini API key: $e');
    }
  }

  /// Get API key from native platform securely
  static Future<String> _getSecureApiKey(String keyType) async {
    try {
      // Try native secure storage first
      final result = await _channel.invokeMethod('getApiKey', {'keyType': keyType});
      
      if (result is String && result.isNotEmpty) {
        return result;
      }

      // Fallback to environment variables (development only)
      if (kDebugMode) {
        return _getEnvironmentApiKey(keyType);
      }

      return '';
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Platform exception getting API key: ${e.message}');
      }
      
      // Fallback to environment variables in debug mode
      if (kDebugMode) {
        return _getEnvironmentApiKey(keyType);
      }
      
      throw SecureConfigException('Failed to retrieve API key from platform: ${e.message}');
    }
  }

  /// Get API key from environment variables (development fallback)
  static String _getEnvironmentApiKey(String keyType) {
    switch (keyType) {
      case 'google_maps':
        return const String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');
      case 'gemini':
        return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      default:
        return '';
    }
  }

  /// Validate Google Maps API key format
  static bool _isValidGoogleMapsApiKey(String key) {
    // Google API keys typically start with AIza and are 39 characters long
    return key.startsWith('AIza') && key.length >= 35 && key.length <= 45;
  }

  /// Validate Gemini API key format
  static bool _isValidGeminiApiKey(String key) {
    // Gemini API keys have specific format patterns
    return key.isNotEmpty && 
           key.length >= 20 && 
           !key.contains(' ') &&
           !key.startsWith('demo_');
  }

  /// Verify security features are available
  static Future<void> _verifySecurityFeatures() async {
    try {
      final features = await _channel.invokeMethod('getSecurityFeatures');
      
      if (features is Map) {
        final hasKeystore = features['hasKeystore'] as bool? ?? false;
        final hasSecureEnclave = features['hasSecureEnclave'] as bool? ?? false;
        
        if (kDebugMode) {
          print('Security features: Keystore=$hasKeystore, SecureEnclave=$hasSecureEnclave');
        }
        
        if (!hasKeystore && !kDebugMode) {
          throw const SecureConfigException('Device lacks secure storage capabilities');
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Security verification failed: ${e.message}');
      }
      // Don't fail in debug mode for development purposes
      if (!kDebugMode) {
        rethrow;
      }
    }
  }

  /// Generate secure hash for API key validation
  static String generateApiKeyHash(String apiKey) {
    final bytes = utf8.encode(apiKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clear cached API keys (security measure)
  static void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      print('SecureConfig cache cleared');
    }
  }

  /// Get configuration summary for debugging (without sensitive data)
  static Map<String, dynamic> getConfigSummary() {
    return {
      'initialized': _initialized,
      'cacheSize': _cache.length,
      'availableKeys': _cache.keys.map((k) => k.replaceAll(RegExp(r'[a-z]'), '*')).toList(),
      'securityLevel': kDebugMode ? 'development' : 'production',
    };
  }
}

/// Extension for additional security utilities
extension SecureConfigUtils on SecureConfig {
  /// Validate API key integrity
  static Future<bool> validateApiKeyIntegrity(String keyType, String expectedHash) async {
    try {
      final apiKey = await SecureConfig._getSecureApiKey(keyType);
      final actualHash = SecureConfig.generateApiKeyHash(apiKey);
      return actualHash == expectedHash;
    } catch (e) {
      return false;
    }
  }
}