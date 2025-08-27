import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/logging_service.dart';

/// Exception thrown by input validation
class ValidationException implements Exception {
  final String message;
  final String field;
  final dynamic value;

  const ValidationException(this.message, this.field, this.value);

  @override
  String toString() => 'ValidationException: $message (field: $field)';
}

/// Comprehensive input validation and sanitization for security
/// Implements OWASP security guidelines for input validation
class InputValidator {
  // Security threat counters for monitoring
  static final Map<String, int> _threatCounters = {
    'xss_attempts': 0,
    'sql_injection_attempts': 0,
    'path_traversal_attempts': 0,
    'malicious_content_attempts': 0,
  };
  // XSS prevention patterns
  static final RegExp _htmlTagPattern = RegExp(r'<[^>]*>', caseSensitive: false);
  static final RegExp _scriptPattern = RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false);
  static final RegExp _jsEventPattern = RegExp(r'on\w+\s*=', caseSensitive: false);
  
  // SQL injection prevention patterns
  static final RegExp _sqlKeywordPattern = RegExp(
    r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b',
    caseSensitive: false,
  );
  
  // Additional SQL injection patterns
  static final RegExp _sqlInjectionPattern = RegExp(
    r"(\'\s*(OR|AND)\s*\'|--|\*\/|\b(OR|AND)\s+\d+\s*=\s*\d+)",
    caseSensitive: false,
  );
  
  // Path traversal prevention
  static final RegExp _pathTraversalPattern = RegExp(r'\.\.|[<>:"|?*]');
  
  // Common injection patterns
  static final RegExp _injectionPattern = RegExp("['\";\\\\]");

  /// Validate and sanitize user name
  static ValidationResult<String> validateUserName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.error('Name is required', 'name', name);
    }

    final trimmed = name.trim();
    
    // Length validation
    if (trimmed.length < 2) {
      return ValidationResult.error('Name must be at least 2 characters', 'name', name);
    }
    
    if (trimmed.length > 50) {
      return ValidationResult.error('Name must be less than 50 characters', 'name', name);
    }

    // Pattern validation - allow letters, numbers, spaces, basic punctuation, and HTML entities
    final namePattern = RegExp("^[a-zA-Z0-9\\s\\-\\.'\"&;\$]+\$");
    if (!namePattern.hasMatch(trimmed)) {
      return ValidationResult.error('Name contains invalid characters', 'name', name);
    }

    // XSS prevention
    if (_containsMaliciousContent(trimmed)) {
      return ValidationResult.error('Name contains invalid content', 'name', name);
    }

    final sanitized = _sanitizeBasicInput(trimmed);
    return ValidationResult.success(sanitized);
  }

  /// Validate restaurant search query
  static ValidationResult<String> validateSearchQuery(String? query) {
    if (query == null || query.trim().isEmpty) {
      return ValidationResult.error('Search query is required', 'query', query);
    }

    final trimmed = query.trim();
    
    // Length validation
    if (trimmed.length > 100) {
      return ValidationResult.error('Search query too long', 'query', query);
    }

    // Check for malicious content
    if (_containsMaliciousContent(trimmed)) {
      return ValidationResult.error('Search query contains invalid content', 'query', query);
    }

    final sanitized = _sanitizeSearchInput(trimmed);
    return ValidationResult.success(sanitized);
  }

  /// Validate dietary preferences
  static ValidationResult<List<String>> validateDietaryPreferences(List<String>? preferences) {
    if (preferences == null) {
      return ValidationResult.success([]);
    }

    if (preferences.length > 20) {
      return ValidationResult.error('Too many dietary preferences', 'preferences', preferences);
    }

    final validPreferences = <String>[];
    for (final pref in preferences) {
      if (pref.trim().isEmpty) continue;
      
      if (pref.length > 50) {
        return ValidationResult.error('Dietary preference too long', 'preferences', pref);
      }

      if (_containsMaliciousContent(pref)) {
        return ValidationResult.error('Invalid dietary preference', 'preferences', pref);
      }

      validPreferences.add(_sanitizeBasicInput(pref.trim()));
    }

    return ValidationResult.success(validPreferences);
  }

  /// Validate location coordinates
  static ValidationResult<Map<String, double>> validateLocation(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return ValidationResult.error('Location coordinates required', 'location', null);
    }

    // Check for invalid numeric values
    if (latitude.isNaN || latitude.isInfinite) {
      return ValidationResult.error('Invalid latitude value', 'latitude', latitude);
    }
    
    if (longitude.isNaN || longitude.isInfinite) {
      return ValidationResult.error('Invalid longitude value', 'longitude', longitude);
    }

    // Validate latitude range (-90 to 90)
    if (latitude < -90 || latitude > 90) {
      return ValidationResult.error('Invalid latitude', 'latitude', latitude);
    }

    // Validate longitude range (-180 to 180)
    if (longitude < -180 || longitude > 180) {
      return ValidationResult.error('Invalid longitude', 'longitude', longitude);
    }

    // Check for suspicious precision (potential fake GPS)
    if (_hasExcessivePrecision(latitude) || _hasExcessivePrecision(longitude)) {
      if (kDebugMode) {
        LoggingService().warning('Location has suspicious precision', tag: 'SecurityValidator');
      }
    }

    return ValidationResult.success({
      'latitude': _roundToPrecision(latitude, 6),
      'longitude': _roundToPrecision(longitude, 6),
    });
  }

  /// Validate budget amount
  static ValidationResult<double> validateBudgetAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return ValidationResult.error('Budget amount must be positive', 'amount', amount);
    }

    if (amount > 10000) {
      return ValidationResult.error('Budget amount too large', 'amount', amount);
    }

    // Round to 2 decimal places
    final rounded = (amount * 100).round() / 100;
    return ValidationResult.success(rounded);
  }

  /// Validate and sanitize notes/comments
  static ValidationResult<String> validateNotes(String? notes) {
    if (notes == null) {
      return ValidationResult.success('');
    }

    final trimmed = notes.trim();
    
    if (trimmed.length > 500) {
      return ValidationResult.error('Notes too long (max 500 characters)', 'notes', notes);
    }

    if (_containsMaliciousContent(trimmed)) {
      return ValidationResult.error('Notes contain invalid content', 'notes', notes);
    }

    final sanitized = _sanitizeTextInput(trimmed);
    return ValidationResult.success(sanitized);
  }

  /// Validate file path (for photo storage)
  static ValidationResult<String> validateFilePath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return ValidationResult.error('File path is required', 'path', path);
    }

    final trimmed = path.trim();
    
    // Check for path traversal
    if (_pathTraversalPattern.hasMatch(trimmed)) {
      return ValidationResult.error('Invalid file path', 'path', path);
    }

    // Validate file extension
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final hasValidExtension = allowedExtensions.any((ext) => 
        trimmed.toLowerCase().endsWith(ext));
        
    if (!hasValidExtension) {
      return ValidationResult.error('Invalid file type', 'path', path);
    }

    return ValidationResult.success(trimmed);
  }

  /// Validate JSON input for preferences
  static ValidationResult<Map<String, dynamic>> validateJsonInput(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) {
      return ValidationResult.success({});
    }

    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      
      // Limit JSON size and depth
      if (jsonString.length > 10000) {
        return ValidationResult.error('JSON input too large', 'json', jsonString);
      }
      
      if (_getJsonDepth(decoded) > 10) {
        return ValidationResult.error('JSON structure too complex', 'json', jsonString);
      }

      // Sanitize string values in JSON
      final sanitized = _sanitizeJsonObject(decoded);
      return ValidationResult.success(sanitized);
    } catch (e) {
      return ValidationResult.error('Invalid JSON format', 'json', jsonString);
    }
  }

  /// Comprehensive input sanitization
  static String sanitizeInput(String input) {
    return _sanitizeTextInput(input);
  }

  /// HTML entity encoding for XSS prevention
  static String encodeHtmlEntities(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Check for malicious content patterns
  static bool _containsMaliciousContent(String input) {
    bool isMalicious = false;
    String threatType = '';
    
    if (_htmlTagPattern.hasMatch(input) || _scriptPattern.hasMatch(input) || _jsEventPattern.hasMatch(input)) {
      isMalicious = true;
      threatType = 'XSS';
      _threatCounters['xss_attempts'] = (_threatCounters['xss_attempts'] ?? 0) + 1;
    }
    
    if (_sqlKeywordPattern.hasMatch(input) || _sqlInjectionPattern.hasMatch(input)) {
      isMalicious = true;
      threatType = threatType.isEmpty ? 'SQL_INJECTION' : '$threatType,SQL_INJECTION';
      _threatCounters['sql_injection_attempts'] = (_threatCounters['sql_injection_attempts'] ?? 0) + 1;
    }
    
    if (_pathTraversalPattern.hasMatch(input)) {
      isMalicious = true;
      threatType = threatType.isEmpty ? 'PATH_TRAVERSAL' : '$threatType,PATH_TRAVERSAL';
      _threatCounters['path_traversal_attempts'] = (_threatCounters['path_traversal_attempts'] ?? 0) + 1;
    }
    
    if (_injectionPattern.hasMatch(input)) {
      isMalicious = true;
      threatType = threatType.isEmpty ? 'INJECTION' : '$threatType,INJECTION';
    }
    
    if (isMalicious) {
      _logSecurityThreat(threatType, input);
      _threatCounters['malicious_content_attempts'] = (_threatCounters['malicious_content_attempts'] ?? 0) + 1;
    }
    
    return isMalicious;
  }

  /// Basic input sanitization
  static String _sanitizeBasicInput(String input) {
    return input
        .replaceAll(_htmlTagPattern, '')
        .replaceAll(_injectionPattern, '')
        .trim();
  }

  /// Search input sanitization
  static String _sanitizeSearchInput(String input) {
    // Allow more characters for search but still prevent XSS
    return input
        .replaceAll(_scriptPattern, '')
        .replaceAll(_jsEventPattern, '')
        .trim();
  }

  /// Text input sanitization with HTML encoding
  static String _sanitizeTextInput(String input) {
    return encodeHtmlEntities(
      input.replaceAll(_scriptPattern, '').trim()
    );
  }

  /// Recursively sanitize JSON object
  static Map<String, dynamic> _sanitizeJsonObject(Map<String, dynamic> obj) {
    final sanitized = <String, dynamic>{};
    
    obj.forEach((key, value) {
      if (value is String) {
        sanitized[key] = _sanitizeTextInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeJsonObject(value);
      } else if (value is List) {
        sanitized[key] = _sanitizeJsonList(value);
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  /// Recursively sanitize JSON list
  static List<dynamic> _sanitizeJsonList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return _sanitizeTextInput(item);
      } else if (item is Map<String, dynamic>) {
        return _sanitizeJsonObject(item);
      } else if (item is List) {
        return _sanitizeJsonList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Get JSON depth for complexity validation
  static int _getJsonDepth(dynamic obj, [int depth = 0]) {
    if (depth > 20) return depth; // Prevent stack overflow
    
    if (obj is Map) {
      return obj.values.fold(depth, (maxDepth, value) => 
          maxDepth.compareTo(_getJsonDepth(value, depth + 1)) > 0 
              ? maxDepth 
              : _getJsonDepth(value, depth + 1));
    } else if (obj is List) {
      return obj.fold(depth, (maxDepth, value) => 
          maxDepth.compareTo(_getJsonDepth(value, depth + 1)) > 0 
              ? maxDepth 
              : _getJsonDepth(value, depth + 1));
    }
    
    return depth;
  }

  /// Check for excessive coordinate precision (potential fake GPS)
  static bool _hasExcessivePrecision(double coordinate) {
    final parts = coordinate.toString().split('.');
    if (parts.length > 1) {
      return parts[1].length > 10; // More than 10 decimal places is suspicious
    }
    return false;
  }

  /// Round number to specified precision
  static double _roundToPrecision(double value, int precision) {
    final factor = (precision * 10.0);
    return (value * factor).round() / factor;
  }
  
  /// Get current security threat statistics
  static Map<String, int> getSecurityStats() {
    return Map.from(_threatCounters);
  }
  
  /// Reset security threat counters
  static void resetSecurityStats() {
    _threatCounters.clear();
    _threatCounters.addAll({
      'xss_attempts': 0,
      'sql_injection_attempts': 0,
      'path_traversal_attempts': 0,
      'malicious_content_attempts': 0,
    });
  }
  
  /// Log security threats for monitoring and analysis
  static void _logSecurityThreat(String threatType, String input) {
    if (kDebugMode) {
      LoggingService().critical('Security Threat Detected: $threatType', tag: 'SecurityValidator', extra: {'input_length': input.length, 'threat_counters': _threatCounters});
    }
  }
}

/// Result of input validation
class ValidationResult<T> {
  final bool isValid;
  final T? value;
  final String? error;
  final String? field;

  const ValidationResult._(this.isValid, this.value, this.error, this.field);

  factory ValidationResult.success(T value) => ValidationResult._(true, value, null, null);
  
  factory ValidationResult.error(String error, String field, dynamic originalValue) => 
      ValidationResult._(false, null, error, field);

  /// Get value or throw exception
  T get valueOrThrow {
    if (!isValid) {
      throw ValidationException(error!, field!, null);
    }
    return value!;
  }
}

/// Rate limiting for input validation
class InputRateLimit {
  static final Map<String, List<DateTime>> _requestHistory = {};
  static const int _maxRequestsPerMinute = 100;

  /// Check if input validation rate limit is exceeded
  static bool isRateLimited(String identifier) {
    final now = DateTime.now();
    final history = _requestHistory[identifier] ?? [];
    
    // Remove entries older than 1 minute
    history.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    if (history.length >= _maxRequestsPerMinute) {
      return true;
    }
    
    history.add(now);
    _requestHistory[identifier] = history;
    
    return false;
  }

  /// Clear rate limiting history
  static void clearHistory() {
    _requestHistory.clear();
  }
}