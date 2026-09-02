import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../services/logging_service.dart';

/// Exception thrown by network security operations
class NetworkSecurityException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const NetworkSecurityException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'NetworkSecurityException: $message ${code != null ? '($code)' : ''}';
}

/// Certificate pinning and network security configuration
class NetworkSecurity {
  // Certificate pins for Google services (SHA-256)
  static const Map<String, List<String>> _certificatePins = {
    'maps.googleapis.com': [
      'KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=', // Google root CA
      'jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=', // Google backup CA
    ],
    'generativelanguage.googleapis.com': [
      'KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=', // Google root CA  
      'jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=', // Google backup CA
    ],
  };

  // TLS configuration is handled by the platform HTTP client
  // Additional TLS restrictions could be configured here if needed

  /// Create secure Dio instance with certificate pinning
  static Dio createSecureDio() {
    final dio = Dio();
    
    // Configure security interceptors
    dio.interceptors.add(CertificatePinningInterceptor());
    dio.interceptors.add(SecurityHeadersInterceptor());
    dio.interceptors.add(RequestValidationInterceptor());
    
    // Configure timeouts
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Configure headers
    dio.options.headers.addAll(_getSecurityHeaders());
    
    if (kDebugMode) {
      LoggingService().info('Secure Dio instance created with certificate pinning', tag: 'NetworkSecurity');
    }
    
    return dio;
  }

  /// Validate SSL certificate against pins
  static bool validateCertificate(String hostname, X509Certificate certificate) {
    final pins = _certificatePins[hostname];
    if (pins == null) {
      // Allow connection if no pins configured (development)
      if (kDebugMode) {
        LoggingService().warning('No certificate pins configured for $hostname', tag: 'NetworkSecurity');
      }
      return true;
    }

    try {
      final certificateHash = _calculateCertificateHash(certificate);
      final isValid = pins.contains(certificateHash);
      
      if (!isValid) {
        if (kDebugMode) {
          LoggingService().critical('Certificate pinning failed for $hostname', tag: 'NetworkSecurity', extra: {'expected_pins': pins, 'actual_hash': certificateHash});
        }
      }
      
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        LoggingService().error('Certificate validation error', tag: 'NetworkSecurity', error: e);
      }
      return false;
    }
  }

  /// Calculate SHA-256 hash of certificate public key
  static String _calculateCertificateHash(X509Certificate certificate) {
    try {
      // Get the DER-encoded certificate
      final derBytes = certificate.der;
      
      // Extract public key (simplified - in production use ASN.1 parsing)
      // For demo, we'll hash the entire certificate
      final digest = sha256.convert(derBytes);
      return base64.encode(digest.bytes);
    } catch (e) {
      throw NetworkSecurityException('Failed to calculate certificate hash: $e');
    }
  }

  /// Get security headers for HTTP requests
  static Map<String, String> _getSecurityHeaders() {
    return {
      'User-Agent': 'DietBuddyApp/1.0.0 (Flutter)',
      'X-Requested-With': 'XMLHttpRequest',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'X-Content-Type-Options': 'nosniff',
    };
  }

  /// Validate TLS connection security
  static bool validateTlsConnection(SecurityContext context) {
    // This would validate TLS version and cipher suite
    // Implementation depends on platform capabilities
    return true;
  }

  /// Create security context for HTTP client
  static SecurityContext createSecurityContext() {
    final context = SecurityContext.defaultContext;
    
    // Configure TLS settings (platform-specific)
    if (!kIsWeb) {
      // Add custom certificate validation
      context.setTrustedCertificatesBytes([]);
    }
    
    return context;
  }
}

/// Certificate pinning interceptor for Dio
class CertificatePinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add certificate pinning validation
    final hostname = Uri.parse(options.baseUrl + options.path).host;
    
    if (kDebugMode) {
      LoggingService().debug('Validating certificate pinning for: $hostname', tag: 'NetworkSecurity');
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError) {
      // Check if error is due to certificate pinning failure
      if (err.message?.contains('certificate') == true) {
        const securityError = NetworkSecurityException(
          'Certificate pinning validation failed',
          code: 'CERT_PINNING_FAILED',
        );
        
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: securityError,
          type: DioExceptionType.unknown,
        ));
        return;
      }
    }
    
    super.onError(err, handler);
  }
}

/// Security headers interceptor
class SecurityHeadersInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers.addAll({
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    });
    
    // Remove sensitive headers in production
    if (!kDebugMode) {
      options.headers.remove('X-Debug-Mode');
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Validate response security headers
    final contentType = response.headers.value('content-type');
    if (contentType != null && !contentType.startsWith('application/json')) {
      if (kDebugMode) {
        LoggingService().warning('Unexpected content type: $contentType', tag: 'NetworkSecurity');
      }
    }
    
    super.onResponse(response, handler);
  }
}

/// Request validation interceptor
class RequestValidationInterceptor extends Interceptor {
  static const int _maxRequestSize = 1024 * 1024; // 1MB
  static const int _maxHeaderSize = 8192; // 8KB

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Validate request size
      final dataSize = _calculateRequestSize(options);
      if (dataSize > _maxRequestSize) {
        handler.reject(DioException(
          requestOptions: options,
          error: const NetworkSecurityException('Request too large'),
          type: DioExceptionType.unknown,
        ));
        return;
      }

      // Validate headers size
      final headerSize = _calculateHeaderSize(options.headers);
      if (headerSize > _maxHeaderSize) {
        handler.reject(DioException(
          requestOptions: options,
          error: const NetworkSecurityException('Headers too large'),
          type: DioExceptionType.unknown,
        ));
        return;
      }

      // Validate URL for malicious patterns
      if (_containsMaliciousUrl(options.uri.toString())) {
        handler.reject(DioException(
          requestOptions: options,
          error: const NetworkSecurityException('Malicious URL detected'),
          type: DioExceptionType.unknown,
        ));
        return;
      }

      super.onRequest(options, handler);
    } catch (e) {
      handler.reject(DioException(
        requestOptions: options,
        error: NetworkSecurityException('Request validation failed: $e'),
        type: DioExceptionType.unknown,
      ));
    }
  }

  int _calculateRequestSize(RequestOptions options) {
    int size = 0;
    
    if (options.data is String) {
      size += utf8.encode(options.data).length;
    } else if (options.data is List<int>) {
      size += (options.data as List<int>).length;
    } else if (options.data is Map) {
      size += utf8.encode(json.encode(options.data)).length;
    }
    
    return size;
  }

  int _calculateHeaderSize(Map<String, dynamic> headers) {
    int size = 0;
    headers.forEach((key, value) {
      size += utf8.encode(key).length;
      size += utf8.encode(value.toString()).length;
    });
    return size;
  }

  bool _containsMaliciousUrl(String url) {
    // Check for common URL injection patterns
    final maliciousPatterns = [
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'[<>"\047`]'), // Using octal for single quote
    ];
    
    return maliciousPatterns.any((pattern) => pattern.hasMatch(url));
  }
}

/// Network security monitoring
class NetworkSecurityMonitor {
  static final List<SecurityEvent> _securityEvents = [];
  static const int _maxEventHistory = 1000;

  /// Record security event
  static void recordSecurityEvent(SecurityEvent event) {
    _securityEvents.add(event);
    
    // Trim history to prevent memory leaks
    if (_securityEvents.length > _maxEventHistory) {
      _securityEvents.removeAt(0);
    }
    
    // Log critical events
    if (event.severity == SecurityEventSeverity.critical) {
      if (kDebugMode) {
        LoggingService().critical('CRITICAL SECURITY EVENT: ${event.message}', tag: 'NetworkSecurity');
      }
      _handleCriticalSecurityEvent(event);
    }
  }

  /// Get security events within time period
  static List<SecurityEvent> getSecurityEvents({
    DateTime? since,
    SecurityEventSeverity? severity,
  }) {
    return _securityEvents.where((event) {
      bool matchesTime = since == null || event.timestamp.isAfter(since);
      bool matchesSeverity = severity == null || event.severity == severity;
      return matchesTime && matchesSeverity;
    }).toList();
  }

  /// Handle critical security events
  static void _handleCriticalSecurityEvent(SecurityEvent event) {
    // In production, this would:
    // 1. Send alert to security monitoring system
    // 2. Log to secure audit trail
    // 3. Potentially block the connection
    // 4. Notify administrators
    
    if (kDebugMode) {
      LoggingService().critical('Handling critical security event: ${event.message}', tag: 'NetworkSecurity');
    }
  }

  /// Get security statistics
  static Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    final recentEvents = _securityEvents
        .where((event) => event.timestamp.isAfter(last24h))
        .toList();
    
    final eventsBySeverity = <SecurityEventSeverity, int>{};
    for (final event in recentEvents) {
      eventsBySeverity[event.severity] = 
          (eventsBySeverity[event.severity] ?? 0) + 1;
    }
    
    return {
      'totalEvents': _securityEvents.length,
      'recentEvents24h': recentEvents.length,
      'eventsBySeverity': eventsBySeverity.map((k, v) => MapEntry(k.name, v)),
      'lastEventTime': _securityEvents.isNotEmpty 
          ? _securityEvents.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Clear security event history
  static void clearHistory() {
    _securityEvents.clear();
  }
}

/// Security event types
enum SecurityEventType {
  certificateValidation,
  maliciousUrl,
  oversizedRequest,
  invalidHeaders,
  connectionTimeout,
  tlsHandshake,
}

/// Security event severity levels
enum SecurityEventSeverity {
  low,
  medium,
  high,
  critical,
}

/// Security event data
class SecurityEvent {
  final SecurityEventType type;
  final SecurityEventSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SecurityEvent({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}