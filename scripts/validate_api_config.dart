#!/usr/bin/env dart

/// API Configuration Validation Script
/// 
/// This script validates the API configuration before deployment.
/// It checks for proper API keys, security settings, and environment-specific
/// configurations to ensure production readiness.
/// 
/// Usage:
///   dart scripts/validate_api_config.dart [environment]
/// 
/// Examples:
///   dart scripts/validate_api_config.dart development
///   dart scripts/validate_api_config.dart staging
///   dart scripts/validate_api_config.dart production

import 'dart:io';
import 'dart:convert';

/// Exit codes
const int exitSuccess = 0;
const int exitConfigError = 1;
const int exitSecurityError = 2;
const int exitEnvironmentError = 3;
const int exitMissingKeys = 4;

/// Colors for terminal output
const String colorReset = '\x1B[0m';
const String colorRed = '\x1B[31m';
const String colorGreen = '\x1B[32m';
const String colorYellow = '\x1B[33m';
const String colorBlue = '\x1B[34m';
const String colorBold = '\x1B[1m';

/// Configuration validation results
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> details;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.details,
  });
}

/// Main validation function
Future<void> main(List<String> arguments) async {
  final environment = arguments.isNotEmpty ? arguments[0] : 'development';
  
  print('${colorBold}API Configuration Validation${colorReset}');
  print('Environment: ${colorBlue}$environment${colorReset}');
  print('');

  try {
    final result = await validateApiConfiguration(environment);
    
    // Print results
    _printValidationResults(result);
    
    // Exit with appropriate code
    if (result.isValid) {
      print('${colorGreen}✓ API configuration validation passed${colorReset}');
      exit(exitSuccess);
    } else {
      print('${colorRed}✗ API configuration validation failed${colorReset}');
      exit(_getExitCode(result.errors));
    }
  } catch (e) {
    print('${colorRed}Fatal error during validation: $e${colorReset}');
    exit(exitConfigError);
  }
}

/// Validate API configuration for the specified environment
Future<ValidationResult> validateApiConfiguration(String environment) async {
  final errors = <String>[];
  final warnings = <String>[];
  final details = <String, dynamic>{};

  // Load environment configuration
  final envConfig = await _loadEnvironmentConfig(environment);
  if (envConfig.isEmpty) {
    errors.add('Failed to load environment configuration for $environment');
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  details['environment'] = environment;
  details['configLoaded'] = envConfig.isNotEmpty;

  // Validate Google Places API
  final placesValidation = _validateGooglePlacesConfig(envConfig, environment);
  errors.addAll(placesValidation['errors'] as List<String>);
  warnings.addAll(placesValidation['warnings'] as List<String>);
  details['googlePlaces'] = placesValidation['details'];

  // Validate Gemini AI API
  final geminiValidation = _validateGeminiConfig(envConfig, environment);
  errors.addAll(geminiValidation['errors'] as List<String>);
  warnings.addAll(geminiValidation['warnings'] as List<String>);
  details['gemini'] = geminiValidation['details'];

  // Validate security configuration
  final securityValidation = _validateSecurityConfig(envConfig, environment);
  errors.addAll(securityValidation['errors'] as List<String>);
  warnings.addAll(securityValidation['warnings'] as List<String>);
  details['security'] = securityValidation['details'];

  // Validate monitoring configuration
  final monitoringValidation = _validateMonitoringConfig(envConfig, environment);
  errors.addAll(monitoringValidation['errors'] as List<String>);
  warnings.addAll(monitoringValidation['warnings'] as List<String>);
  details['monitoring'] = monitoringValidation['details'];

  // Environment-specific validations
  final envValidation = _validateEnvironmentSpecific(envConfig, environment);
  errors.addAll(envValidation['errors'] as List<String>);
  warnings.addAll(envValidation['warnings'] as List<String>);
  details['environmentSpecific'] = envValidation['details'];

  return ValidationResult(
    isValid: errors.isEmpty,
    errors: errors,
    warnings: warnings,
    details: details,
  );
}

/// Load environment configuration from .env file
Future<Map<String, String>> _loadEnvironmentConfig(String environment) async {
  final envFile = File('.env.$environment');
  final config = <String, String>{};

  if (!await envFile.exists()) {
    return config;
  }

  try {
    final lines = await envFile.readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        config[key] = value;
      }
    }
  } catch (e) {
    print('Warning: Failed to read environment file: $e');
  }

  return config;
}

/// Validate Google Places API configuration
Map<String, dynamic> _validateGooglePlacesConfig(
  Map<String, String> config,
  String environment,
) {
  final errors = <String>[];
  final warnings = <String>[];
  final details = <String, dynamic>{};

  final apiKey = config['GOOGLE_PLACES_API_KEY'] ?? '';
  final maxRequestsPerMinute = int.tryParse(config['GOOGLE_PLACES_MAX_REQUESTS_PER_MINUTE'] ?? '60') ?? 60;
  final dailyQuotaLimit = int.tryParse(config['GOOGLE_PLACES_DAILY_QUOTA_LIMIT'] ?? '10000') ?? 10000;

  details['apiKeyConfigured'] = apiKey.isNotEmpty;
  details['maxRequestsPerMinute'] = maxRequestsPerMinute;
  details['dailyQuotaLimit'] = dailyQuotaLimit;

  // Validate API key
  if (apiKey.isEmpty) {
    errors.add('Google Places API key is not configured');
  } else if (apiKey == 'demo_key_replace_in_production' || apiKey.startsWith('demo_')) {
    if (environment == 'production') {
      errors.add('Google Places API key is using demo value in production');
    } else {
      warnings.add('Google Places API key is using demo value');
    }
  } else if (apiKey.length < 20) {
    warnings.add('Google Places API key appears to be too short');
  }

  // Validate rate limits
  if (maxRequestsPerMinute > 100) {
    warnings.add('Google Places rate limit is very high (${maxRequestsPerMinute}/min)');
  }

  if (environment == 'production' && dailyQuotaLimit < 1000) {
    warnings.add('Google Places daily quota limit might be too low for production');
  }

  details['validApiKey'] = apiKey.isNotEmpty && !apiKey.startsWith('demo_') && apiKey.length >= 20;

  return {
    'errors': errors,
    'warnings': warnings,
    'details': details,
  };
}

/// Validate Gemini AI API configuration
Map<String, dynamic> _validateGeminiConfig(
  Map<String, String> config,
  String environment,
) {
  final errors = <String>[];
  final warnings = <String>[];
  final details = <String, dynamic>{};

  final apiKey = config['GEMINI_API_KEY'] ?? '';
  final model = config['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
  final temperature = double.tryParse(config['GEMINI_TEMPERATURE'] ?? '0.7') ?? 0.7;
  final maxTokens = int.tryParse(config['GEMINI_MAX_TOKENS'] ?? '1000') ?? 1000;
  final dailyCostLimit = double.tryParse(config['GEMINI_DAILY_COST_LIMIT'] ?? '5.0') ?? 5.0;
  final maxRequestsPerMinute = int.tryParse(config['GEMINI_MAX_REQUESTS_PER_MINUTE'] ?? '10') ?? 10;

  details['apiKeyConfigured'] = apiKey.isNotEmpty;
  details['model'] = model;
  details['temperature'] = temperature;
  details['maxTokens'] = maxTokens;
  details['dailyCostLimit'] = dailyCostLimit;
  details['maxRequestsPerMinute'] = maxRequestsPerMinute;

  // Validate API key
  if (apiKey.isEmpty) {
    errors.add('Gemini AI API key is not configured');
  } else if (apiKey == 'demo_key_replace_in_production' || apiKey.startsWith('demo_')) {
    if (environment == 'production') {
      errors.add('Gemini AI API key is using demo value in production');
    } else {
      warnings.add('Gemini AI API key is using demo value');
    }
  } else if (apiKey.length < 30) {
    warnings.add('Gemini AI API key appears to be too short');
  }

  // Validate model configuration
  if (!model.startsWith('gemini-')) {
    warnings.add('Gemini model name appears invalid: $model');
  }

  if (temperature < 0.0 || temperature > 2.0) {
    warnings.add('Gemini temperature should be between 0.0 and 2.0, got: $temperature');
  }

  if (maxTokens < 100 || maxTokens > 4000) {
    warnings.add('Gemini max tokens should be between 100 and 4000, got: $maxTokens');
  }

  // Validate cost limits
  if (dailyCostLimit > 10.0) {
    warnings.add('Gemini daily cost limit is high (\$${dailyCostLimit.toStringAsFixed(2)})');
  }

  if (dailyCostLimit < 1.0 && environment == 'production') {
    warnings.add('Gemini daily cost limit might be too low for production (\$${dailyCostLimit.toStringAsFixed(2)})');
  }

  details['validApiKey'] = apiKey.isNotEmpty && !apiKey.startsWith('demo_') && apiKey.length >= 30;

  return {
    'errors': errors,
    'warnings': warnings,
    'details': details,
  };
}

/// Validate security configuration
Map<String, dynamic> _validateSecurityConfig(
  Map<String, String> config,
  String environment,
) {
  final errors = <String>[];
  final warnings = <String>[];
  final details = <String, dynamic>{};

  final appEnvironment = config['APP_ENVIRONMENT'] ?? 'development';
  final allowedBundleIds = config['ALLOWED_BUNDLE_IDS'] ?? '';
  final allowedPackageNames = config['ALLOWED_PACKAGE_NAMES'] ?? '';
  final encryptionKey = config['API_ENCRYPTION_KEY'] ?? '';
  final enableDebugLogging = config['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';

  details['appEnvironment'] = appEnvironment;
  details['allowedBundleIds'] = allowedBundleIds.split(',').map((s) => s.trim()).toList();
  details['allowedPackageNames'] = allowedPackageNames.split(',').map((s) => s.trim()).toList();
  details['encryptionKeyConfigured'] = encryptionKey.isNotEmpty;
  details['debugLoggingEnabled'] = enableDebugLogging;

  // Validate app environment
  if (appEnvironment != environment) {
    warnings.add('APP_ENVIRONMENT ($appEnvironment) does not match specified environment ($environment)');
  }

  // Validate bundle/package restrictions
  if (allowedBundleIds.isEmpty || allowedBundleIds.contains('com.example.')) {
    if (environment == 'production') {
      errors.add('Production bundle IDs should not use example package names');
    } else {
      warnings.add('Bundle IDs are using example package names');
    }
  }

  if (allowedPackageNames.isEmpty || allowedPackageNames.contains('com.example.')) {
    if (environment == 'production') {
      errors.add('Production package names should not use example package names');
    } else {
      warnings.add('Package names are using example package names');
    }
  }

  // Validate encryption key
  if (encryptionKey.isEmpty) {
    errors.add('API encryption key is not configured');
  } else if (encryptionKey.startsWith('dev_key') || encryptionKey.contains('not_for_production')) {
    if (environment == 'production') {
      errors.add('Development encryption key detected in production');
    } else {
      warnings.add('Using development encryption key');
    }
  } else if (encryptionKey.length < 32) {
    warnings.add('Encryption key appears to be too short (should be 32+ characters)');
  }

  // Validate debug logging
  if (enableDebugLogging && environment == 'production') {
    warnings.add('Debug logging is enabled in production');
  }

  details['securityLevel'] = _calculateSecurityLevel(config, environment);

  return {
    'errors': errors,
    'warnings': warnings,
    'details': details,
  };
}

/// Validate monitoring configuration
Map<String, dynamic> _validateMonitoringConfig(
  Map<String, String> config,
  String environment,
) {
  final errors = <String>[];
  final warnings = <String>[];
  final details = <String, dynamic>{};

  final enableUsageMonitoring = config['ENABLE_USAGE_MONITORING']?.toLowerCase() == 'true';
  final enableCostAlerts = config['ENABLE_COST_ALERTS']?.toLowerCase() == 'true';
  final costAlertThreshold = double.tryParse(config['COST_ALERT_THRESHOLD'] ?? '80.0') ?? 80.0;
  final requestAlertThreshold = double.tryParse(config['REQUEST_ALERT_THRESHOLD'] ?? '90.0') ?? 90.0;
  final alertWebhookUrl = config['ALERT_WEBHOOK_URL'] ?? '';

  details['usageMonitoringEnabled'] = enableUsageMonitoring;
  details['costAlertsEnabled'] = enableCostAlerts;
  details['costAlertThreshold'] = costAlertThreshold;
  details['requestAlertThreshold'] = requestAlertThreshold;
  details['webhookConfigured'] = alertWebhookUrl.isNotEmpty;

  // Validate monitoring settings
  if (!enableUsageMonitoring && environment == 'production') {
    warnings.add('Usage monitoring is disabled in production');
  }

  if (!enableCostAlerts && environment == 'production') {
    warnings.add('Cost alerts are disabled in production');
  }

  // Validate alert thresholds
  if (costAlertThreshold <= 0 || costAlertThreshold > 100) {
    warnings.add('Cost alert threshold should be between 0 and 100, got: $costAlertThreshold');
  }

  if (requestAlertThreshold <= 0 || requestAlertThreshold > 100) {
    warnings.add('Request alert threshold should be between 0 and 100, got: $requestAlertThreshold');
  }

  // Validate webhook URL
  if (enableCostAlerts && alertWebhookUrl.isNotEmpty) {
    if (!alertWebhookUrl.startsWith('https://')) {
      warnings.add('Alert webhook URL should use HTTPS');
    }
  }

  return {
    'errors': errors,
    'warnings': warnings,
    'details': details,
  };
}

/// Validate environment-specific settings
Map<String, dynamic> _validateEnvironmentSpecific(
  Map<String, String> config,
  String environment,
) {
  final errors = <String>[];
  final warnings = <String>[];
  final details = <String, dynamic>{};

  details['environment'] = environment;

  switch (environment) {
    case 'production':
      _validateProductionConfig(config, errors, warnings, details);
      break;
    case 'staging':
      _validateStagingConfig(config, errors, warnings, details);
      break;
    case 'development':
      _validateDevelopmentConfig(config, errors, warnings, details);
      break;
    default:
      warnings.add('Unknown environment: $environment');
  }

  return {
    'errors': errors,
    'warnings': warnings,
    'details': details,
  };
}

/// Validate production-specific settings
void _validateProductionConfig(
  Map<String, String> config,
  List<String> errors,
  List<String> warnings,
  Map<String, dynamic> details,
) {
  details['validationLevel'] = 'production';

  // Production must have real API keys
  final googlePlacesKey = config['GOOGLE_PLACES_API_KEY'] ?? '';
  final geminiKey = config['GEMINI_API_KEY'] ?? '';

  if (googlePlacesKey.startsWith('demo_') || googlePlacesKey.contains('demo')) {
    errors.add('Production cannot use demo Google Places API key');
  }

  if (geminiKey.startsWith('demo_') || geminiKey.contains('demo')) {
    errors.add('Production cannot use demo Gemini API key');
  }

  // Production security requirements
  final encryptionKey = config['API_ENCRYPTION_KEY'] ?? '';
  if (encryptionKey.startsWith('dev_') || encryptionKey.contains('development')) {
    errors.add('Production cannot use development encryption key');
  }

  // Production should have monitoring enabled
  final enableMonitoring = config['ENABLE_USAGE_MONITORING']?.toLowerCase() == 'true';
  if (!enableMonitoring) {
    warnings.add('Production should have usage monitoring enabled');
  }

  // Production should have reasonable limits
  final geminiCostLimit = double.tryParse(config['GEMINI_DAILY_COST_LIMIT'] ?? '5.0') ?? 5.0;
  if (geminiCostLimit < 2.0) {
    warnings.add('Production Gemini cost limit might be too restrictive');
  }
}

/// Validate staging-specific settings
void _validateStagingConfig(
  Map<String, String> config,
  List<String> errors,
  List<String> warnings,
  Map<String, dynamic> details,
) {
  details['validationLevel'] = 'staging';

  // Staging should use real API keys (can be restricted)
  final googlePlacesKey = config['GOOGLE_PLACES_API_KEY'] ?? '';
  final geminiKey = config['GEMINI_API_KEY'] ?? '';

  if (googlePlacesKey.startsWith('demo_')) {
    warnings.add('Staging should use real Google Places API key for accurate testing');
  }

  if (geminiKey.startsWith('demo_')) {
    warnings.add('Staging should use real Gemini API key for accurate testing');
  }

  // Staging should have moderate limits
  final geminiCostLimit = double.tryParse(config['GEMINI_DAILY_COST_LIMIT'] ?? '3.0') ?? 3.0;
  if (geminiCostLimit > 5.0) {
    warnings.add('Staging Gemini cost limit might be too high for testing');
  }
}

/// Validate development-specific settings
void _validateDevelopmentConfig(
  Map<String, String> config,
  List<String> errors,
  List<String> warnings,
  Map<String, dynamic> details,
) {
  details['validationLevel'] = 'development';

  // Development can use demo keys
  final googlePlacesKey = config['GOOGLE_PLACES_API_KEY'] ?? '';
  final geminiKey = config['GEMINI_API_KEY'] ?? '';

  if (!googlePlacesKey.startsWith('demo_') && googlePlacesKey.isNotEmpty) {
    details['usingRealGooglePlacesKey'] = true;
  }

  if (!geminiKey.startsWith('demo_') && geminiKey.isNotEmpty) {
    details['usingRealGeminiKey'] = true;
  }

  // Development should have conservative limits
  final geminiCostLimit = double.tryParse(config['GEMINI_DAILY_COST_LIMIT'] ?? '2.0') ?? 2.0;
  if (geminiCostLimit > 3.0) {
    warnings.add('Development Gemini cost limit is high for local testing');
  }
}

/// Calculate security level based on configuration
String _calculateSecurityLevel(Map<String, String> config, String environment) {
  var score = 0;

  // API key security
  final googlePlacesKey = config['GOOGLE_PLACES_API_KEY'] ?? '';
  final geminiKey = config['GEMINI_API_KEY'] ?? '';

  if (googlePlacesKey.isNotEmpty && !googlePlacesKey.startsWith('demo_')) score += 20;
  if (geminiKey.isNotEmpty && !geminiKey.startsWith('demo_')) score += 20;

  // Encryption
  final encryptionKey = config['API_ENCRYPTION_KEY'] ?? '';
  if (encryptionKey.isNotEmpty && !encryptionKey.startsWith('dev_')) score += 20;

  // Bundle/package restrictions
  final bundleIds = config['ALLOWED_BUNDLE_IDS'] ?? '';
  final packageNames = config['ALLOWED_PACKAGE_NAMES'] ?? '';
  if (bundleIds.isNotEmpty && !bundleIds.contains('example')) score += 10;
  if (packageNames.isNotEmpty && !packageNames.contains('example')) score += 10;

  // Monitoring
  final monitoring = config['ENABLE_USAGE_MONITORING']?.toLowerCase() == 'true';
  if (monitoring) score += 10;

  // Debug logging (negative for production)
  final debugLogging = config['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';
  if (!debugLogging && environment == 'production') score += 10;

  if (score >= 90) return 'high';
  if (score >= 70) return 'medium';
  if (score >= 50) return 'basic';
  return 'low';
}

/// Print validation results with colors
void _printValidationResults(ValidationResult result) {
  print('${colorBold}Validation Results:${colorReset}');
  print('');

  // Print errors
  if (result.errors.isNotEmpty) {
    print('${colorRed}${colorBold}Errors (${result.errors.length}):${colorReset}');
    for (final error in result.errors) {
      print('  ${colorRed}✗ $error${colorReset}');
    }
    print('');
  }

  // Print warnings
  if (result.warnings.isNotEmpty) {
    print('${colorYellow}${colorBold}Warnings (${result.warnings.length}):${colorReset}');
    for (final warning in result.warnings) {
      print('  ${colorYellow}⚠ $warning${colorReset}');
    }
    print('');
  }

  // Print summary
  print('${colorBold}Configuration Summary:${colorReset}');
  
  final googlePlaces = result.details['googlePlaces'] as Map<String, dynamic>? ?? {};
  final gemini = result.details['gemini'] as Map<String, dynamic>? ?? {};
  final security = result.details['security'] as Map<String, dynamic>? ?? {};
  final monitoring = result.details['monitoring'] as Map<String, dynamic>? ?? {};

  print('  Google Places API: ${_formatStatus(googlePlaces['validApiKey'] == true)}');
  print('  Gemini AI API: ${_formatStatus(gemini['validApiKey'] == true)}');
  print('  Security Level: ${_formatSecurityLevel(security['securityLevel'] as String? ?? 'unknown')}');
  print('  Monitoring: ${_formatStatus(monitoring['usageMonitoringEnabled'] == true)}');
  
  if (result.errors.isEmpty && result.warnings.isEmpty) {
    print('');
    print('${colorGreen}All checks passed!${colorReset}');
  }
}

/// Format status with colors
String _formatStatus(bool isValid) {
  return isValid 
      ? '${colorGreen}✓ Configured${colorReset}'
      : '${colorRed}✗ Not configured${colorReset}';
}

/// Format security level with colors
String _formatSecurityLevel(String level) {
  switch (level) {
    case 'high':
      return '${colorGreen}$level${colorReset}';
    case 'medium':
      return '${colorYellow}$level${colorReset}';
    case 'basic':
    case 'low':
      return '${colorRed}$level${colorReset}';
    default:
      return level;
  }
}

/// Get appropriate exit code based on errors
int _getExitCode(List<String> errors) {
  for (final error in errors) {
    if (error.toLowerCase().contains('api key')) {
      return exitMissingKeys;
    }
    if (error.toLowerCase().contains('security') || error.toLowerCase().contains('encryption')) {
      return exitSecurityError;
    }
    if (error.toLowerCase().contains('environment')) {
      return exitEnvironmentError;
    }
  }
  return exitConfigError;
}