import 'dart:async';

import '../config/api_config.dart';
import 'logging_service.dart';

/// API monitoring event types
enum ApiEventType {
  request,
  response,
  error,
  rateLimitHit,
  costThresholdReached,
  dailyLimitReached,
}

/// API monitoring event
class ApiMonitoringEvent {
  final String id;
  final ApiEventType type;
  final String service; // 'gemini' or 'google_places'
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final double? costCents;
  final int? requestCount;

  const ApiMonitoringEvent({
    required this.id,
    required this.type,
    required this.service,
    required this.timestamp,
    required this.data,
    this.costCents,
    this.requestCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'service': service,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'costCents': costCents,
      'requestCount': requestCount,
    };
  }

  factory ApiMonitoringEvent.fromJson(Map<String, dynamic> json) {
    return ApiMonitoringEvent(
      id: json['id'],
      type: ApiEventType.values.firstWhere((e) => e.name == json['type']),
      service: json['service'],
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'] ?? {},
      costCents: json['costCents']?.toDouble(),
      requestCount: json['requestCount'],
    );
  }
}

/// API usage statistics for a service
class ServiceUsageStats {
  final String service;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double totalCostCents;
  final double averageResponseTimeMs;
  final Map<String, int> errorCounts;
  final List<DateTime> rateLimitHits;

  const ServiceUsageStats({
    required this.service,
    required this.periodStart,
    required this.periodEnd,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.totalCostCents,
    required this.averageResponseTimeMs,
    required this.errorCounts,
    required this.rateLimitHits,
  });

  double get successRate => totalRequests > 0 ? successfulRequests / totalRequests : 0.0;
  double get totalCostDollars => totalCostCents / 100;
  bool get hasErrors => failedRequests > 0 || errorCounts.isNotEmpty;
  bool get hasRateLimitIssues => rateLimitHits.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'totalCostCents': totalCostCents,
      'averageResponseTimeMs': averageResponseTimeMs,
      'errorCounts': errorCounts,
      'rateLimitHits': rateLimitHits.map((dt) => dt.toIso8601String()).toList(),
    };
  }
}

/// Exception thrown by monitoring service
class ApiMonitoringException implements Exception {
  final String message;
  final String? code;

  const ApiMonitoringException(this.message, {this.code});

  @override
  String toString() => 'ApiMonitoringException: $message ${code != null ? '($code)' : ''}';
}

/// Comprehensive API monitoring and cost tracking service
class ApiMonitoringService {
  final StreamController<ApiMonitoringEvent> _eventController;
  final Map<String, List<DateTime>> _recentRequests = {};
  final Map<String, double> _dailyCosts = {};
  final Map<String, DateTime> _lastCostReset = {};

  // Alert callbacks
  final List<Function(ApiMonitoringEvent)> _alertHandlers = [];
  
  // Security event tracking
  final List<SecurityEvent> _securityEvents = [];

  ApiMonitoringService() 
      : _eventController = StreamController<ApiMonitoringEvent>.broadcast() {
    _initializeService();
  }

  /// Stream of monitoring events
  Stream<ApiMonitoringEvent> get events => _eventController.stream;

  /// Initialize the monitoring service
  void _initializeService() {
    if (!ApiConfig.enableUsageMonitoring) {
      return;
    }

    // Reset daily costs if needed
    _resetDailyCostsIfNeeded();

    // Setup periodic cleanup
    Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOldData();
      _resetDailyCostsIfNeeded();
    });

    if (ApiConfig.enableDebugLogging) {
      LoggingService().info('API Monitoring Service initialized with environment: ${ApiConfig.environment.name}', tag: 'ApiMonitoring');
    }
  }

  // ========================================
  // Event Recording
  // ========================================

  /// Record an API request
  Future<void> recordRequest({
    required String service,
    required String endpoint,
    required Map<String, dynamic> requestData,
    String? userId,
  }) async {
    if (!ApiConfig.enableUsageMonitoring) return;

    try {
      final event = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.request,
        service: service,
        timestamp: DateTime.now(),
        data: {
          'endpoint': endpoint,
          'requestData': requestData,
          'userId': userId,
        },
        requestCount: 1,
      );

      await _recordEvent(event);
      _updateRecentRequests(service);
      _checkRateLimits(service);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        LoggingService().error('Failed to record API request', tag: 'ApiMonitoring', error: e);
      }
    }
  }

  /// Record an API response
  Future<void> recordResponse({
    required String service,
    required String endpoint,
    required bool success,
    required Duration responseTime,
    double? costCents,
    Map<String, dynamic>? responseData,
    String? error,
  }) async {
    if (!ApiConfig.enableUsageMonitoring) return;

    try {
      final event = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.response,
        service: service,
        timestamp: DateTime.now(),
        data: {
          'endpoint': endpoint,
          'success': success,
          'responseTimeMs': responseTime.inMilliseconds,
          'responseData': responseData,
          'error': error,
        },
        costCents: costCents,
      );

      await _recordEvent(event);

      if (costCents != null) {
        _updateDailyCost(service, costCents);
        _checkCostLimits(service, costCents);
      }

      // Check for alerts
      if (!success && ApiConfig.enableCostAlerts) {
        _triggerAlert(event);
      }
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        LoggingService().error('Failed to record API response', tag: 'ApiMonitoring', error: e);
      }
    }
  }

  /// Record a rate limit hit
  Future<void> recordRateLimitHit({
    required String service,
    required String reason,
    Duration? retryAfter,
  }) async {
    if (!ApiConfig.enableUsageMonitoring) return;

    try {
      final event = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.rateLimitHit,
        service: service,
        timestamp: DateTime.now(),
        data: {
          'reason': reason,
          'retryAfterSeconds': retryAfter?.inSeconds,
        },
      );

      await _recordEvent(event);
      _triggerAlert(event);
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        LoggingService().error('Failed to record rate limit hit', tag: 'ApiMonitoring', error: e);
      }
    }
  }

  /// Record an API error
  Future<void> recordError({
    required String service,
    required String endpoint,
    required String error,
    String? errorCode,
    Map<String, dynamic>? context,
  }) async {
    if (!ApiConfig.enableUsageMonitoring) return;

    try {
      final event = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.error,
        service: service,
        timestamp: DateTime.now(),
        data: {
          'endpoint': endpoint,
          'error': error,
          'errorCode': errorCode,
          'context': context,
        },
      );

      await _recordEvent(event);
      
      if (ApiConfig.enableCostAlerts) {
        _triggerAlert(event);
      }
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        LoggingService().error('Failed to record API error', tag: 'ApiMonitoring', error: e);
      }
    }
  }

  // ========================================
  // Statistics and Analytics
  // ========================================

  /// Get usage statistics for a service within a time period
  Future<ServiceUsageStats> getServiceStats({
    required String service,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final start = startTime ?? DateTime.now().subtract(const Duration(days: 1));
    final end = endTime ?? DateTime.now();

    try {
      final events = await _getEventsInPeriod(service, start, end);
      
      final requests = events.where((e) => e.type == ApiEventType.request).toList();
      final responses = events.where((e) => e.type == ApiEventType.response).toList();
      final errors = events.where((e) => e.type == ApiEventType.error).toList();
      final rateLimits = events.where((e) => e.type == ApiEventType.rateLimitHit).toList();

      final successfulResponses = responses.where((e) => e.data['success'] == true).toList();
      final failedResponses = responses.where((e) => e.data['success'] == false).toList();

      final totalCost = responses
          .where((e) => e.costCents != null)
          .fold(0.0, (sum, e) => sum + (e.costCents ?? 0));

      final avgResponseTime = responses.isNotEmpty
          ? responses.map((e) => e.data['responseTimeMs'] as int? ?? 0).reduce((a, b) => a + b) / responses.length
          : 0.0;

      final errorCounts = <String, int>{};
      for (final error in errors) {
        final errorCode = error.data['errorCode'] as String? ?? 'unknown';
        errorCounts[errorCode] = (errorCounts[errorCode] ?? 0) + 1;
      }

      return ServiceUsageStats(
        service: service,
        periodStart: start,
        periodEnd: end,
        totalRequests: requests.length,
        successfulRequests: successfulResponses.length,
        failedRequests: failedResponses.length + errors.length,
        totalCostCents: totalCost,
        averageResponseTimeMs: avgResponseTime,
        errorCounts: errorCounts,
        rateLimitHits: rateLimits.map((e) => e.timestamp).toList(),
      );
    } catch (e) {
      throw ApiMonitoringException('Failed to get service stats: $e');
    }
  }

  /// Get daily cost for a service
  double getDailyCost(String service) {
    final today = DateTime.now();
    final lastReset = _lastCostReset[service];
    
    if (lastReset == null || !_isSameDay(lastReset, today)) {
      _dailyCosts[service] = 0.0;
      _lastCostReset[service] = today;
    }
    
    return _dailyCosts[service] ?? 0.0;
  }

  /// Get remaining daily budget for a service
  double getRemainingDailyBudget(String service) {
    final dailyCost = getDailyCost(service) / 100; // Convert to dollars
    final limit = service == 'gemini' 
        ? ApiConfig.geminiDailyCostLimit 
        : 100.0; // Default high limit for Places API
    
    return (limit - dailyCost).clamp(0.0, limit);
  }

  /// Check if service is near its daily limits
  bool isNearDailyLimits(String service) {
    final dailyCost = getDailyCost(service) / 100;
    final limit = service == 'gemini' 
        ? ApiConfig.geminiDailyCostLimit 
        : 100.0;
    
    final recentRequestCount = _getRecentRequestCount(service);
    final requestLimit = service == 'gemini'
        ? ApiConfig.geminiMaxRequestsPerMinute * 24 * 60 // Daily equivalent
        : ApiConfig.googlePlacesMaxRequestsPerMinute * 24 * 60;
    
    final costRatio = dailyCost / limit;
    final requestRatio = recentRequestCount / requestLimit;
    
    return costRatio >= ApiConfig.costAlertThreshold || 
           requestRatio >= ApiConfig.requestAlertThreshold;
  }

  /// Get comprehensive monitoring summary
  Future<Map<String, dynamic>> getMonitoringSummary() async {
    final geminiStats = await getServiceStats(service: 'gemini');
    final placesStats = await getServiceStats(service: 'google_places');
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'environment': ApiConfig.environment.name,
      'services': {
        'gemini': {
          'stats': geminiStats.toJson(),
          'dailyCostDollars': getDailyCost('gemini') / 100,
          'remainingBudgetDollars': getRemainingDailyBudget('gemini'),
          'nearLimits': isNearDailyLimits('gemini'),
          'configured': ApiConfig.hasValidGeminiKey,
          'enabled': ApiConfig.enableAiFeatures,
        },
        'google_places': {
          'stats': placesStats.toJson(),
          'dailyCostDollars': getDailyCost('google_places') / 100,
          'remainingBudgetDollars': getRemainingDailyBudget('google_places'),
          'nearLimits': isNearDailyLimits('google_places'),
          'configured': ApiConfig.hasValidGooglePlacesKey,
          'enabled': ApiConfig.enablePlacesApi,
        },
      },
      'alerts': {
        'enabled': ApiConfig.enableCostAlerts,
        'costThreshold': ApiConfig.costAlertThreshold,
        'requestThreshold': ApiConfig.requestAlertThreshold,
        'webhookConfigured': ApiConfig.alertWebhookUrl != null,
      },
      'features': {
        'monitoringEnabled': ApiConfig.enableUsageMonitoring,
        'fallbackEnabled': ApiConfig.enableFallbackMode,
        'debugLogging': ApiConfig.enableDebugLogging,
      },
    };
  }

  // ========================================
  // Alert Management
  // ========================================

  /// Add an alert handler
  void addAlertHandler(Function(ApiMonitoringEvent) handler) {
    _alertHandlers.add(handler);
  }

  /// Remove an alert handler
  void removeAlertHandler(Function(ApiMonitoringEvent) handler) {
    _alertHandlers.remove(handler);
  }

  /// Trigger an alert
  void _triggerAlert(ApiMonitoringEvent event) {
    for (final handler in _alertHandlers) {
      try {
        handler(event);
      } catch (e) {
        if (ApiConfig.enableDebugLogging) {
          LoggingService().error('Alert handler failed', tag: 'ApiMonitoring', error: e);
        }
      }
    }
    
    _eventController.add(event);
  }

  // ========================================
  // Internal Methods
  // ========================================

  /// Record an event in the database
  Future<void> _recordEvent(ApiMonitoringEvent event) async {
    if (!ApiConfig.enableUsageMonitoring) return;

    try {
      // Store in a simple table (you might want to create a proper table for this)
      // For now, using a generic approach
      if (ApiConfig.enableDebugLogging) {
        LoggingService().debug('Recording API event: ${event.service} ${event.type.name}', tag: 'ApiMonitoring');
      }
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        LoggingService().error('Failed to record event in database', tag: 'ApiMonitoring', error: e);
      }
    }
  }

  /// Get events within a time period
  Future<List<ApiMonitoringEvent>> _getEventsInPeriod(
    String service,
    DateTime start,
    DateTime end,
  ) async {
    // This would query your database
    // For now, returning empty list as placeholder
    return [];
  }

  /// Update recent requests tracking
  void _updateRecentRequests(String service) {
    final now = DateTime.now();
    final recentList = _recentRequests[service] ?? [];
    
    // Remove requests older than 1 minute
    recentList.removeWhere((time) => 
        now.difference(time).inMinutes >= 1);
    
    recentList.add(now);
    _recentRequests[service] = recentList;
  }

  /// Get recent request count for rate limiting
  int _getRecentRequestCount(String service) {
    final recentList = _recentRequests[service] ?? [];
    final now = DateTime.now();
    
    // Count requests in the last minute
    return recentList.where((time) => 
        now.difference(time).inMinutes < 1).length;
  }

  /// Check rate limits
  void _checkRateLimits(String service) {
    final recentCount = _getRecentRequestCount(service);
    final limit = service == 'gemini'
        ? ApiConfig.geminiMaxRequestsPerMinute
        : ApiConfig.googlePlacesMaxRequestsPerMinute;
    
    if (recentCount >= limit) {
      recordRateLimitHit(
        service: service,
        reason: 'Exceeded $limit requests per minute',
        retryAfter: const Duration(minutes: 1),
      );
    }
  }

  /// Update daily cost tracking
  void _updateDailyCost(String service, double costCents) {
    final today = DateTime.now();
    final lastReset = _lastCostReset[service];
    
    if (lastReset == null || !_isSameDay(lastReset, today)) {
      _dailyCosts[service] = 0.0;
      _lastCostReset[service] = today;
    }
    
    _dailyCosts[service] = (_dailyCosts[service] ?? 0.0) + costCents;
  }

  /// Check cost limits
  void _checkCostLimits(String service, double costCents) {
    final dailyCostDollars = getDailyCost(service) / 100;
    final limit = service == 'gemini' 
        ? ApiConfig.geminiDailyCostLimit 
        : 100.0; // High default for Places API
    
    final ratio = dailyCostDollars / limit;
    
    if (ratio >= 1.0) {
      final event = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.dailyLimitReached,
        service: service,
        timestamp: DateTime.now(),
        data: {
          'dailyCostDollars': dailyCostDollars,
          'limitDollars': limit,
        },
        costCents: costCents,
      );
      
      _triggerAlert(event);
    } else if (ratio >= ApiConfig.costAlertThreshold) {
      final event = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.costThresholdReached,
        service: service,
        timestamp: DateTime.now(),
        data: {
          'dailyCostDollars': dailyCostDollars,
          'limitDollars': limit,
          'thresholdRatio': ratio,
        },
        costCents: costCents,
      );
      
      _triggerAlert(event);
    }
  }

  /// Reset daily costs if it's a new day
  void _resetDailyCostsIfNeeded() {
    final today = DateTime.now();
    
    for (final service in _lastCostReset.keys.toList()) {
      final lastReset = _lastCostReset[service];
      if (lastReset != null && !_isSameDay(lastReset, today)) {
        _dailyCosts[service] = 0.0;
        _lastCostReset[service] = today;
        
        if (ApiConfig.enableDebugLogging) {
          LoggingService().info('Reset daily costs for $service', tag: 'ApiMonitoring');
        }
      }
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Cleanup old monitoring data
  void _cleanupOldData() {
    // Remove data older than 30 days
    // This would be implemented with database queries
    if (ApiConfig.enableDebugLogging) {
      LoggingService().info('Cleaning up old monitoring data', tag: 'ApiMonitoring');
    }
  }

  /// Generate unique event ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'event_${timestamp}_$random';
  }

  /// Record security event
  void recordSecurityEvent({
    required String type,
    required String severity,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    final event = SecurityEvent(
      type: type,
      severity: severity,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _securityEvents.add(event);
    
    // Limit security event history
    if (_securityEvents.length > 1000) {
      _securityEvents.removeAt(0);
    }
    
    // Trigger alert for high severity events
    if (severity == 'critical' || severity == 'high') {
      final alertEvent = ApiMonitoringEvent(
        id: _generateEventId(),
        type: ApiEventType.error,
        service: 'security',
        timestamp: DateTime.now(),
        data: {
          'securityEventType': type,
          'severity': severity,
          'message': message,
          'metadata': metadata,
        },
      );
      
      _triggerAlert(alertEvent);
    }
    
    if (ApiConfig.enableDebugLogging) {
      LoggingService().warning('Security event recorded: $severity - $message', tag: 'ApiMonitoring');
    }
  }

  /// Get security events
  List<SecurityEvent> getSecurityEvents({
    DateTime? since,
    String? severityFilter,
  }) {
    return _securityEvents.where((event) {
      if (since != null && event.timestamp.isBefore(since)) {
        return false;
      }
      if (severityFilter != null && event.severity != severityFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    final recentEvents = _securityEvents
        .where((event) => event.timestamp.isAfter(last24h))
        .toList();
    
    final eventsBySeverity = <String, int>{};
    final eventsByType = <String, int>{};
    
    for (final event in recentEvents) {
      eventsBySeverity[event.severity] = (eventsBySeverity[event.severity] ?? 0) + 1;
      eventsByType[event.type] = (eventsByType[event.type] ?? 0) + 1;
    }
    
    return {
      'totalSecurityEvents': _securityEvents.length,
      'recentEvents24h': recentEvents.length,
      'eventsBySeverity': eventsBySeverity,
      'eventsByType': eventsByType,
      'lastEventTime': _securityEvents.isNotEmpty 
          ? _securityEvents.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Export monitoring data for analysis
  Future<Map<String, dynamic>> exportMonitoringData({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final start = startTime ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endTime ?? DateTime.now();
    
    final geminiStats = await getServiceStats(service: 'gemini', startTime: start, endTime: end);
    final placesStats = await getServiceStats(service: 'google_places', startTime: start, endTime: end);
    
    return {
      'exportTimestamp': DateTime.now().toIso8601String(),
      'period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
      'configuration': ApiConfig.getConfigSummary(),
      'services': {
        'gemini': geminiStats.toJson(),
        'google_places': placesStats.toJson(),
      },
      'security': getSecurityStats(),
      'summary': await getMonitoringSummary(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
    _alertHandlers.clear();
    _recentRequests.clear();
    _securityEvents.clear();
  }
}

/// Security event for monitoring
class SecurityEvent {
  final String type;
  final String severity;
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
      'type': type,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}