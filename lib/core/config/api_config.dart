import 'package:flutter/foundation.dart';

/// API Configuration Exception
class ApiConfigException implements Exception {
  final String message;
  final String? code;

  const ApiConfigException(this.message, {this.code});

  @override
  String toString() =>
      'ApiConfigException: $message ${code != null ? '($code)' : ''}';
}

/// Environment types for API configuration
enum ApiEnvironment {
  development,
  staging,
  production;

  static ApiEnvironment fromString(String env) {
    return switch (env.toLowerCase()) {
      'development' || 'dev' => ApiEnvironment.development,
      'staging' || 'stage' => ApiEnvironment.staging,
      'production' || 'prod' => ApiEnvironment.production,
      _ => ApiEnvironment.development,
    };
  }
}

/// API Usage Statistics
class ApiUsageStats {
  final int requestCount;
  final double costCents;
  final DateTime lastResetTime;
  final Map<String, dynamic> details;

  const ApiUsageStats({
    required this.requestCount,
    required this.costCents,
    required this.lastResetTime,
    this.details = const {},
  });

  double get costDollars => costCents / 100;

  bool isAtLimit(int maxRequests, double maxCostDollars) {
    return requestCount >= maxRequests || costDollars >= maxCostDollars;
  }

  bool isNearLimit(int maxRequests, double maxCostDollars,
      {double threshold = 0.8}) {
    final requestRatio = requestCount / maxRequests;
    final costRatio = costDollars / maxCostDollars;
    return requestRatio >= threshold || costRatio >= threshold;
  }
}

/// Production-ready API Configuration with security and monitoring
class ApiConfig {
  // Cache for computed values
  static ApiEnvironment? _cachedEnvironment;
  static Map<String, dynamic>? _securityContext;

  // ========================================
  // Environment Detection
  // ========================================

  static const String _appEnvironment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  static ApiEnvironment get environment {
    return _cachedEnvironment ??= ApiEnvironment.fromString(_appEnvironment);
  }

  static bool get isDevelopment => environment == ApiEnvironment.development;
  static bool get isStaging => environment == ApiEnvironment.staging;
  static bool get isProduction => environment == ApiEnvironment.production;

  // ========================================
  // Google Places API Configuration
  // ========================================

  static const String _googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: 'demo_key_replace_in_production',
  );

  static const int _googlePlacesMaxRequestsPerMinute = int.fromEnvironment(
    'GOOGLE_PLACES_MAX_REQUESTS_PER_MINUTE',
    defaultValue: 60,
  );

  static const int _googlePlacesDailyQuotaLimit = int.fromEnvironment(
    'GOOGLE_PLACES_DAILY_QUOTA_LIMIT',
    defaultValue: 10000,
  );

  /// Google Places API Key with validation
  static String get googlePlacesApiKey {
    _validateApiKey(_googlePlacesApiKey, 'Google Places');
    return _googlePlacesApiKey;
  }

  /// Google Places API Base URL
  static const String googlePlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  /// Google Places request rate limit
  static int get googlePlacesMaxRequestsPerMinute =>
      _googlePlacesMaxRequestsPerMinute;

  /// Google Places daily quota limit
  static int get googlePlacesDailyQuotaLimit => _googlePlacesDailyQuotaLimit;

  /// Check if we have a valid Google Places API key
  static bool get hasValidGooglePlacesKey =>
      _isValidApiKey(_googlePlacesApiKey);

  // ========================================
  // Gemini AI API Configuration
  // ========================================

  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'demo_key_replace_in_production',
  );

  static const String _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash',
  );

  static const double _geminiTemperature = 0.7; // Default temperature

  static const int _geminiMaxTokens = int.fromEnvironment(
    'GEMINI_MAX_TOKENS',
    defaultValue: 1000,
  );

  static const double _geminiDailyCostLimit = 5.0; // Default daily cost limit

  static const int _geminiMaxRequestsPerMinute = int.fromEnvironment(
    'GEMINI_MAX_REQUESTS_PER_MINUTE',
    defaultValue: 10,
  );

  static const bool _geminiEnableCaching = bool.fromEnvironment(
    'GEMINI_ENABLE_CACHING',
    defaultValue: true,
  );

  static const int _geminiCacheTtlHours = int.fromEnvironment(
    'GEMINI_CACHE_TTL_HOURS',
    defaultValue: 24,
  );

  /// Gemini AI API Key with validation
  static String get geminiApiKey {
    _validateApiKey(_geminiApiKey, 'Gemini AI');
    return _geminiApiKey;
  }

  /// Gemini model configuration
  static String get geminiModel => _geminiModel;
  static double get geminiTemperature => _geminiTemperature;
  static int get geminiMaxTokens => _geminiMaxTokens;
  static double get geminiDailyCostLimit => _geminiDailyCostLimit;
  static int get geminiMaxRequestsPerMinute => _geminiMaxRequestsPerMinute;
  static bool get geminiEnableCaching => _geminiEnableCaching;
  static Duration get geminiCacheTtl => Duration(hours: _geminiCacheTtlHours);

  /// Check if we have a valid Gemini API key
  static bool get hasValidGeminiKey => _isValidApiKey(_geminiApiKey);

  // ========================================
  // Security Configuration
  // ========================================

  static const String _allowedBundleIds = String.fromEnvironment(
    'ALLOWED_BUNDLE_IDS',
    defaultValue: 'com.example.whatwehaveforlunch',
  );

  static const String _allowedPackageNames = String.fromEnvironment(
    'ALLOWED_PACKAGE_NAMES',
    defaultValue: 'com.example.whatwehaveforlunch',
  );

  static const String _apiEncryptionKey = String.fromEnvironment(
    'API_ENCRYPTION_KEY',
    defaultValue: 'dev_key_only_not_for_production_use_123',
  );

  static List<String> get allowedBundleIds =>
      _allowedBundleIds.split(',').map((s) => s.trim()).toList();
  static List<String> get allowedPackageNames =>
      _allowedPackageNames.split(',').map((s) => s.trim()).toList();

  /// Get security context for API validation
  static Map<String, dynamic> get securityContext {
    return _securityContext ??= {
      'environment': environment.name,
      'allowedBundleIds': allowedBundleIds,
      'allowedPackageNames': allowedPackageNames,
      'encryptionEnabled': _apiEncryptionKey.isNotEmpty &&
          !_apiEncryptionKey.startsWith('dev_key'),
      'productionMode': isProduction,
    };
  }

  // ========================================
  // Feature Flags
  // ========================================

  static const bool _enableAiFeatures = bool.fromEnvironment(
    'ENABLE_AI_FEATURES',
    defaultValue: true,
  );

  static const bool _enablePlacesApi = bool.fromEnvironment(
    'ENABLE_PLACES_API',
    defaultValue: true,
  );

  static const bool _enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: true,
  );

  static const bool _enableUsageMonitoring = bool.fromEnvironment(
    'ENABLE_USAGE_MONITORING',
    defaultValue: true,
  );

  static const bool _enableCostAlerts = bool.fromEnvironment(
    'ENABLE_COST_ALERTS',
    defaultValue: true,
  );

  static const bool _enableFallbackMode = bool.fromEnvironment(
    'ENABLE_FALLBACK_MODE',
    defaultValue: true,
  );

  static const int _apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static bool get enableAiFeatures => _enableAiFeatures;
  static bool get enablePlacesApi => _enablePlacesApi;
  static bool get enableDebugLogging =>
      _enableDebugLogging && (isDevelopment || kDebugMode);
  static bool get enableUsageMonitoring => _enableUsageMonitoring;
  static bool get enableCostAlerts => _enableCostAlerts;
  static bool get enableFallbackMode => _enableFallbackMode;
  static Duration get apiTimeout => Duration(seconds: _apiTimeoutSeconds);

  // ========================================
  // Alert Configuration
  // ========================================

  static const double _costAlertThreshold =
      80.0; // Default cost alert threshold

  static const double _requestAlertThreshold =
      90.0; // Default request alert threshold

  static const String _alertWebhookUrl = String.fromEnvironment(
    'ALERT_WEBHOOK_URL',
    defaultValue: '',
  );

  static double get costAlertThreshold => _costAlertThreshold / 100;
  static double get requestAlertThreshold => _requestAlertThreshold / 100;
  static String? get alertWebhookUrl =>
      _alertWebhookUrl.isNotEmpty ? _alertWebhookUrl : null;

  // ========================================
  // Validation Methods
  // ========================================

  /// Validate API key format and security
  static void _validateApiKey(String key, String serviceName) {
    if (!_isValidApiKey(key)) {
      if (isProduction) {
        throw ApiConfigException(
          'Invalid $serviceName API key in production environment',
          code: 'INVALID_API_KEY',
        );
      }
    }
  }

  /// Check if API key is valid (not demo/empty)
  static bool _isValidApiKey(String key) {
    return key.isNotEmpty &&
        !key.startsWith('demo_') &&
        key != 'demo_key_replace_in_production' &&
        key.length > 10; // Basic length check
  }

  /// Validate API configuration on app startup
  static Map<String, dynamic> validateConfiguration() {
    final issues = <String>[];
    final warnings = <String>[];

    // Check API keys
    if (!hasValidGooglePlacesKey) {
      if (isProduction) {
        issues.add('Google Places API key is invalid or missing in production');
      } else {
        warnings.add('Google Places API key is using demo value');
      }
    }

    if (!hasValidGeminiKey) {
      if (isProduction) {
        issues.add('Gemini AI API key is invalid or missing in production');
      } else {
        warnings.add('Gemini AI API key is using demo value');
      }
    }

    // Check security configuration
    if (isProduction && _apiEncryptionKey.startsWith('dev_key')) {
      issues.add('Development encryption key detected in production');
    }

    // Check feature flags
    if (isProduction && enableDebugLogging) {
      warnings.add('Debug logging is enabled in production');
    }

    // Check rate limits
    if (googlePlacesMaxRequestsPerMinute > 100) {
      warnings.add(
          'Google Places rate limit is very high (>${googlePlacesMaxRequestsPerMinute}/min)');
    }

    if (geminiDailyCostLimit > 10.0) {
      warnings.add(
          'Gemini daily cost limit is high (\$${geminiDailyCostLimit.toStringAsFixed(2)})');
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'environment': environment.name,
      'securityLevel': _getSecurityLevel(),
      'featuresEnabled': {
        'ai': enableAiFeatures && hasValidGeminiKey,
        'places': enablePlacesApi && hasValidGooglePlacesKey,
        'monitoring': enableUsageMonitoring,
        'alerts': enableCostAlerts,
        'fallback': enableFallbackMode,
      },
    };
  }

  /// Get current security level
  static String _getSecurityLevel() {
    if (isProduction &&
        hasValidGooglePlacesKey &&
        hasValidGeminiKey &&
        !_apiEncryptionKey.startsWith('dev_key')) {
      return 'production';
    } else if (isStaging) {
      return 'staging';
    } else {
      return 'development';
    }
  }

  // ========================================
  // Utility Methods
  // ========================================

  /// Get API configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment.name,
      'apis': {
        'googlePlaces': {
          'configured': hasValidGooglePlacesKey,
          'rateLimitPerMinute': googlePlacesMaxRequestsPerMinute,
          'dailyQuotaLimit': googlePlacesDailyQuotaLimit,
        },
        'gemini': {
          'configured': hasValidGeminiKey,
          'model': geminiModel,
          'dailyCostLimit': geminiDailyCostLimit,
          'rateLimitPerMinute': geminiMaxRequestsPerMinute,
          'cachingEnabled': geminiEnableCaching,
        },
      },
      'features': {
        'aiEnabled': enableAiFeatures,
        'placesEnabled': enablePlacesApi,
        'monitoringEnabled': enableUsageMonitoring,
        'alertsEnabled': enableCostAlerts,
        'fallbackEnabled': enableFallbackMode,
      },
      'security': securityContext,
      'timeouts': {
        'apiTimeoutSeconds': _apiTimeoutSeconds,
        'cacheTtlHours': _geminiCacheTtlHours,
      },
    };
  }

  /// Reset cached values (useful for testing)
  static void resetCache() {
    _cachedEnvironment = null;
    _securityContext = null;
  }
}
