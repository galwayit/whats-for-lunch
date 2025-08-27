import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_monitoring_service.dart';
import '../../core/services/logging_service.dart';

/// Provider for API monitoring service
final apiMonitoringServiceProvider = Provider<ApiMonitoringService>((ref) {
  return ApiMonitoringService();
});

/// State for API monitoring dashboard
class ApiMonitoringState {
  final Map<String, ServiceUsageStats> serviceStats;
  final Map<String, dynamic> monitoringSummary;
  final List<ApiMonitoringEvent> recentEvents;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ApiMonitoringState({
    this.serviceStats = const {},
    this.monitoringSummary = const {},
    this.recentEvents = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ApiMonitoringState copyWith({
    Map<String, ServiceUsageStats>? serviceStats,
    Map<String, dynamic>? monitoringSummary,
    List<ApiMonitoringEvent>? recentEvents,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ApiMonitoringState(
      serviceStats: serviceStats ?? this.serviceStats,
      monitoringSummary: monitoringSummary ?? this.monitoringSummary,
      recentEvents: recentEvents ?? this.recentEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Computed properties
  bool get hasData => serviceStats.isNotEmpty || monitoringSummary.isNotEmpty;
  bool get hasError => error != null;
  
  ServiceUsageStats? get geminiStats => serviceStats['gemini'];
  ServiceUsageStats? get placesStats => serviceStats['google_places'];
  
  double get totalDailyCost {
    final geminiCost = geminiStats?.totalCostDollars ?? 0.0;
    final placesCost = placesStats?.totalCostDollars ?? 0.0;
    return geminiCost + placesCost;
  }
  
  int get totalDailyRequests {
    final geminiRequests = geminiStats?.totalRequests ?? 0;
    final placesRequests = placesStats?.totalRequests ?? 0;
    return geminiRequests + placesRequests;
  }
  
  double get overallSuccessRate {
    final totalRequests = totalDailyRequests;
    if (totalRequests == 0) return 1.0;
    
    final geminiSuccessful = geminiStats?.successfulRequests ?? 0;
    final placesSuccessful = placesStats?.successfulRequests ?? 0;
    final totalSuccessful = geminiSuccessful + placesSuccessful;
    
    return totalSuccessful / totalRequests;
  }
  
  bool get hasActiveAlerts {
    return recentEvents.any((event) => 
      event.type == ApiEventType.costThresholdReached ||
      event.type == ApiEventType.dailyLimitReached ||
      event.type == ApiEventType.rateLimitHit ||
      event.type == ApiEventType.error
    );
  }
}

/// API monitoring notifier
class ApiMonitoringNotifier extends StateNotifier<ApiMonitoringState> {
  ApiMonitoringNotifier(this._monitoringService) : super(const ApiMonitoringState()) {
    _initialize();
  }

  final ApiMonitoringService _monitoringService;
  StreamSubscription<ApiMonitoringEvent>? _eventSubscription;
  Timer? _refreshTimer;

  void _initialize() {
    if (!ApiConfig.enableUsageMonitoring) {
      return;
    }

    // Listen to monitoring events
    _eventSubscription = _monitoringService.events.listen(
      _handleMonitoringEvent,
      onError: (error) {
        state = state.copyWith(error: 'Monitoring service error: $error');
      },
    );

    // Setup periodic refresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refresh();
    });

    // Initial load
    _loadInitialData();
  }

  /// Handle incoming monitoring events
  void _handleMonitoringEvent(ApiMonitoringEvent event) {
    // Add event to recent events (keep last 50)
    final updatedEvents = [event, ...state.recentEvents].take(50).toList();
    
    state = state.copyWith(
      recentEvents: updatedEvents,
      lastUpdated: DateTime.now(),
    );

    // Trigger UI alerts for critical events
    if (_isCriticalEvent(event)) {
      _showCriticalAlert(event);
    }
  }

  /// Load initial monitoring data
  Future<void> _loadInitialData() async {
    if (!ApiConfig.enableUsageMonitoring) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await refresh();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load monitoring data: $e',
      );
    }
  }

  /// Refresh all monitoring data
  Future<void> refresh() async {
    if (!ApiConfig.enableUsageMonitoring) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load service statistics
      final geminiStats = await _monitoringService.getServiceStats(service: 'gemini');
      final placesStats = await _monitoringService.getServiceStats(service: 'google_places');
      
      // Load monitoring summary
      final summary = await _monitoringService.getMonitoringSummary();

      state = state.copyWith(
        serviceStats: {
          'gemini': geminiStats,
          'google_places': placesStats,
        },
        monitoringSummary: summary,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh monitoring data: $e',
      );
    }
  }

  /// Get usage statistics for a specific service
  Future<ServiceUsageStats?> getServiceStats(String service) async {
    try {
      return await _monitoringService.getServiceStats(service: service);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get $service stats: $e');
      }
      return null;
    }
  }

  /// Export monitoring data
  Future<Map<String, dynamic>?> exportData({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      return await _monitoringService.exportMonitoringData(
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to export data: $e');
      return null;
    }
  }

  /// Clear recent events
  void clearEvents() {
    state = state.copyWith(recentEvents: []);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if event is critical and needs immediate attention
  bool _isCriticalEvent(ApiMonitoringEvent event) {
    return event.type == ApiEventType.dailyLimitReached ||
           event.type == ApiEventType.rateLimitHit ||
           (event.type == ApiEventType.error && 
            event.data['errorCode'] != null);
  }

  /// Show critical alert to user
  void _showCriticalAlert(ApiMonitoringEvent event) {
    // This could trigger a notification, dialog, or banner
    // For now, just log in debug mode
    if (kDebugMode) {
      LoggingService().critical('CRITICAL API ALERT: ${event.type.name} for ${event.service}', tag: 'ApiMonitoring', extra: {'data': event.data});
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for API monitoring state
final apiMonitoringProvider = StateNotifierProvider<ApiMonitoringNotifier, ApiMonitoringState>((ref) {
  final monitoringService = ref.watch(apiMonitoringServiceProvider);
  return ApiMonitoringNotifier(monitoringService);
});

/// Provider for API configuration validation
final apiConfigValidationProvider = Provider<Map<String, dynamic>>((ref) {
  return ApiConfig.validateConfiguration();
});

/// Provider for API configuration summary
final apiConfigSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  return ApiConfig.getConfigSummary();
});

/// Provider for current daily costs
final dailyCostsProvider = Provider<Map<String, double>>((ref) {
  final monitoringService = ref.watch(apiMonitoringServiceProvider);
  
  return {
    'gemini': monitoringService.getDailyCost('gemini') / 100, // Convert to dollars
    'google_places': monitoringService.getDailyCost('google_places') / 100,
  };
});

/// Provider for remaining daily budgets
final remainingBudgetsProvider = Provider<Map<String, double>>((ref) {
  final monitoringService = ref.watch(apiMonitoringServiceProvider);
  
  return {
    'gemini': monitoringService.getRemainingDailyBudget('gemini'),
    'google_places': monitoringService.getRemainingDailyBudget('google_places'),
  };
});

/// Provider for API health status
final apiHealthProvider = Provider<Map<String, dynamic>>((ref) {
  final monitoringState = ref.watch(apiMonitoringProvider);
  final configValidation = ref.watch(apiConfigValidationProvider);
  
  final geminiStats = monitoringState.geminiStats;
  final placesStats = monitoringState.placesStats;
  
  return {
    'overall': {
      'healthy': configValidation['valid'] && !monitoringState.hasActiveAlerts,
      'configurationValid': configValidation['valid'],
      'hasActiveAlerts': monitoringState.hasActiveAlerts,
      'successRate': monitoringState.overallSuccessRate,
      'lastUpdated': monitoringState.lastUpdated?.toIso8601String(),
    },
    'gemini': {
      'configured': ApiConfig.hasValidGeminiKey,
      'enabled': ApiConfig.enableAiFeatures,
      'healthy': geminiStats?.successRate ?? 0.0 > 0.9,
      'nearLimits': ref.read(apiMonitoringServiceProvider).isNearDailyLimits('gemini'),
      'hasErrors': geminiStats?.hasErrors ?? false,
      'rateLimitIssues': geminiStats?.hasRateLimitIssues ?? false,
    },
    'google_places': {
      'configured': ApiConfig.hasValidGooglePlacesKey,
      'enabled': ApiConfig.enablePlacesApi,
      'healthy': placesStats?.successRate ?? 0.0 > 0.9,
      'nearLimits': ref.read(apiMonitoringServiceProvider).isNearDailyLimits('google_places'),
      'hasErrors': placesStats?.hasErrors ?? false,
      'rateLimitIssues': placesStats?.hasRateLimitIssues ?? false,
    },
  };
});

/// Provider for alert handling
final alertHandlerProvider = Provider<void>((ref) {
  final monitoringService = ref.watch(apiMonitoringServiceProvider);
  
  if (!ApiConfig.enableCostAlerts) {
    return;
  }

  // Add default alert handler
  monitoringService.addAlertHandler((event) {
    // Log critical events
    if (kDebugMode) {
      print('API Alert: ${event.type.name} for ${event.service}');
      print('Data: ${event.data}');
    }
    
    // You can add additional alert handling here:
    // - Send push notifications
    // - Send to external monitoring service
    // - Email alerts
    // - SMS alerts
    
    if (ApiConfig.alertWebhookUrl != null) {
      _sendWebhookAlert(event, ApiConfig.alertWebhookUrl!);
    }
  });
});

/// Send alert to webhook endpoint
Future<void> _sendWebhookAlert(ApiMonitoringEvent event, String webhookUrl) async {
  try {
    // This would send the alert to your monitoring service
    // Implementation depends on your monitoring setup
    if (kDebugMode) {
      print('Sending webhook alert to: $webhookUrl');
      print('Event: ${event.toJson()}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to send webhook alert: $e');
    }
  }
}

/// Provider for environment-specific features
final environmentFeaturesProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'environment': ApiConfig.environment.name,
    'isDevelopment': ApiConfig.isDevelopment,
    'isStaging': ApiConfig.isStaging,
    'isProduction': ApiConfig.isProduction,
    'features': {
      'aiEnabled': ApiConfig.enableAiFeatures,
      'placesEnabled': ApiConfig.enablePlacesApi,
      'monitoringEnabled': ApiConfig.enableUsageMonitoring,
      'alertsEnabled': ApiConfig.enableCostAlerts,
      'fallbackEnabled': ApiConfig.enableFallbackMode,
      'debugLogging': ApiConfig.enableDebugLogging,
    },
    'security': ApiConfig.securityContext,
  };
});

/// Provider for cost analytics
final costAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final monitoringState = ref.watch(apiMonitoringProvider);
  
  if (!monitoringState.hasData) {
    return {'hasData': false};
  }
  
  final geminiStats = monitoringState.geminiStats;
  final placesStats = monitoringState.placesStats;
  
  final totalCost = monitoringState.totalDailyCost;
  final totalRequests = monitoringState.totalDailyRequests;
  
  // Calculate cost per request
  final costPerRequest = totalRequests > 0 ? totalCost / totalRequests : 0.0;
  
  // Calculate projected monthly cost
  final projectedMonthlyCost = totalCost * 30;
  
  // Calculate efficiency metrics
  final successRate = monitoringState.overallSuccessRate;
  final costEfficiency = successRate * (1 / (costPerRequest + 0.001)); // Avoid division by zero
  
  return {
    'hasData': true,
    'summary': {
      'totalDailyCostDollars': totalCost,
      'totalDailyRequests': totalRequests,
      'costPerRequest': costPerRequest,
      'projectedMonthlyCostDollars': projectedMonthlyCost,
      'overallSuccessRate': successRate,
      'costEfficiencyScore': costEfficiency,
    },
    'services': {
      'gemini': {
        'dailyCostDollars': geminiStats?.totalCostDollars ?? 0.0,
        'dailyRequests': geminiStats?.totalRequests ?? 0,
        'successRate': geminiStats?.successRate ?? 0.0,
        'averageResponseTimeMs': geminiStats?.averageResponseTimeMs ?? 0.0,
      },
      'google_places': {
        'dailyCostDollars': placesStats?.totalCostDollars ?? 0.0,
        'dailyRequests': placesStats?.totalRequests ?? 0,
        'successRate': placesStats?.successRate ?? 0.0,
        'averageResponseTimeMs': placesStats?.averageResponseTimeMs ?? 0.0,
      },
    },
    'trends': {
      // This could be enhanced with historical data
      'costTrend': 'stable', // 'increasing', 'decreasing', 'stable'
      'requestTrend': 'stable',
      'errorTrend': 'stable',
    },
  };
});

/// Provider for API performance metrics
final performanceMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  final monitoringState = ref.watch(apiMonitoringProvider);
  
  if (!monitoringState.hasData) {
    return {'hasData': false};
  }
  
  final geminiStats = monitoringState.geminiStats;
  final placesStats = monitoringState.placesStats;
  
  return {
    'hasData': true,
    'overall': {
      'successRate': monitoringState.overallSuccessRate,
      'totalRequests': monitoringState.totalDailyRequests,
      'totalErrors': (geminiStats?.failedRequests ?? 0) + (placesStats?.failedRequests ?? 0),
      'averageResponseTime': _calculateWeightedAverage(
        [geminiStats?.averageResponseTimeMs ?? 0.0, placesStats?.averageResponseTimeMs ?? 0.0],
        [geminiStats?.totalRequests ?? 0, placesStats?.totalRequests ?? 0],
      ),
    },
    'gemini': {
      'successRate': geminiStats?.successRate ?? 0.0,
      'averageResponseTimeMs': geminiStats?.averageResponseTimeMs ?? 0.0,
      'totalRequests': geminiStats?.totalRequests ?? 0,
      'errorCount': geminiStats?.failedRequests ?? 0,
      'rateLimitHits': geminiStats?.rateLimitHits.length ?? 0,
    },
    'google_places': {
      'successRate': placesStats?.successRate ?? 0.0,
      'averageResponseTimeMs': placesStats?.averageResponseTimeMs ?? 0.0,
      'totalRequests': placesStats?.totalRequests ?? 0,
      'errorCount': placesStats?.failedRequests ?? 0,
      'rateLimitHits': placesStats?.rateLimitHits.length ?? 0,
    },
  };
});

/// Calculate weighted average
double _calculateWeightedAverage(List<double> values, List<int> weights) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0.0;
  }
  
  double sum = 0.0;
  int totalWeight = 0;
  
  for (int i = 0; i < values.length; i++) {
    sum += values[i] * weights[i];
    totalWeight += weights[i];
  }
  
  return totalWeight > 0 ? sum / totalWeight : 0.0;
}