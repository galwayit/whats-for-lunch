import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service for monitoring app performance and collecting metrics
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final List<PerformanceMetric> _metrics = [];
  final Map<String, DateTime> _operationStartTimes = {};
  late DateTime _appStartTime;
  bool _isInitialized = false;

  /// Initialize the performance monitoring service
  void initialize() {
    if (_isInitialized) return;
    
    _appStartTime = DateTime.now();
    _isInitialized = true;
    
    // Start monitoring memory usage periodically
    _startMemoryMonitoring();
    
    if (kDebugMode) {
      developer.log('Performance monitoring initialized', name: 'PerformanceMonitor');
    }
  }

  /// Start tracking an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End tracking an operation and record the metric
  void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      if (kDebugMode) {
        developer.log('Operation $operationName was not started', name: 'PerformanceMonitor');
      }
      return;
    }

    final duration = DateTime.now().difference(startTime);
    final metric = PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: startTime,
      metadata: metadata,
    );

    _metrics.add(metric);
    
    // Log slow operations in debug mode
    if (kDebugMode && duration.inMilliseconds > 100) {
      developer.log(
        'Slow operation: $operationName took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor'
      );
    }

    // Keep only last 1000 metrics to prevent memory leaks
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }
  }

  /// Record app startup completion
  void recordAppStartup() {
    final startupDuration = DateTime.now().difference(_appStartTime);
    final metric = PerformanceMetric(
      operationName: 'app_startup',
      duration: startupDuration,
      timestamp: _appStartTime,
      metadata: {'target_ms': 3000},
    );
    
    _metrics.add(metric);
    
    if (kDebugMode) {
      developer.log(
        'App startup completed in ${startupDuration.inMilliseconds}ms',
        name: 'PerformanceMonitor'
      );
    }
  }

  /// Record a custom metric
  void recordMetric(String name, Duration duration, {Map<String, dynamic>? metadata}) {
    final metric = PerformanceMetric(
      operationName: name,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _metrics.add(metric);
  }

  /// Record network operation metrics
  void recordNetworkOperation(String endpoint, Duration duration, {
    bool wasSuccessful = true,
    int? statusCode,
    int? responseSize,
  }) {
    final metric = PerformanceMetric(
      operationName: 'network_$endpoint',
      duration: duration,
      timestamp: DateTime.now(),
      metadata: {
        'successful': wasSuccessful,
        'status_code': statusCode,
        'response_size': responseSize,
      },
    );
    
    _metrics.add(metric);
    
    // Log slow network operations
    if (kDebugMode && duration.inMilliseconds > 5000) {
      developer.log(
        'Slow network operation: $endpoint took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor'
      );
    }
  }

  /// Record database operation metrics
  void recordDatabaseOperation(String operation, Duration duration, {
    int? recordCount,
    String? table,
  }) {
    final metric = PerformanceMetric(
      operationName: 'db_$operation',
      duration: duration,
      timestamp: DateTime.now(),
      metadata: {
        'record_count': recordCount,
        'table': table,
      },
    );
    
    _metrics.add(metric);
    
    // Log slow database operations
    if (kDebugMode && duration.inMilliseconds > 1000) {
      developer.log(
        'Slow database operation: $operation took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor'
      );
    }
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    if (_metrics.isEmpty) {
      return PerformanceSummary(
        totalOperations: 0,
        averageResponseTime: Duration.zero,
        slowOperations: [],
        appStartupTime: DateTime.now().difference(_appStartTime),
        memoryUsage: 0,
      );
    }

    final totalDuration = _metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.duration.inMilliseconds,
    );

    final avgResponseTime = Duration(
      milliseconds: totalDuration ~/ _metrics.length,
    );

    final slowOperations = _metrics
        .where((metric) => metric.duration.inMilliseconds > 1000)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));

    return PerformanceSummary(
      totalOperations: _metrics.length,
      averageResponseTime: avgResponseTime,
      slowOperations: slowOperations.take(10).toList(),
      appStartupTime: DateTime.now().difference(_appStartTime),
      memoryUsage: _currentMemoryUsage,
    );
  }

  /// Get metrics for a specific operation type
  List<PerformanceMetric> getMetricsForOperation(String operationName) {
    return _metrics.where((metric) => metric.operationName == operationName).toList();
  }

  /// Get metrics within a time range
  List<PerformanceMetric> getMetricsInTimeRange(DateTime start, DateTime end) {
    return _metrics
        .where((metric) => 
          metric.timestamp.isAfter(start) && 
          metric.timestamp.isBefore(end))
        .toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _operationStartTimes.clear();
  }

  /// Get current memory usage (approximate)
  int _currentMemoryUsage = 0;
  
  void _startMemoryMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMemoryUsage();
    });
  }

  void _updateMemoryUsage() {
    // This is an approximation since Dart doesn't provide direct memory access
    // In production, you might want to use platform channels to get actual memory usage
    _currentMemoryUsage = _metrics.length * 200; // Rough estimate
  }

  /// Export metrics to JSON for analysis
  Map<String, dynamic> exportMetrics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'app_startup_time': DateTime.now().difference(_appStartTime).inMilliseconds,
      'total_operations': _metrics.length,
      'memory_usage_estimate': _currentMemoryUsage,
      'metrics': _metrics.map((metric) => metric.toJson()).toList(),
    };
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation_name': operationName,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Performance summary data class
class PerformanceSummary {
  final int totalOperations;
  final Duration averageResponseTime;
  final List<PerformanceMetric> slowOperations;
  final Duration appStartupTime;
  final int memoryUsage;

  const PerformanceSummary({
    required this.totalOperations,
    required this.averageResponseTime,
    required this.slowOperations,
    required this.appStartupTime,
    required this.memoryUsage,
  });

  /// Check if app performance meets targets
  bool get meetsPerformanceTargets {
    return appStartupTime.inMilliseconds < 3000 && // Under 3 seconds startup
           averageResponseTime.inMilliseconds < 500 && // Under 500ms average response
           slowOperations.length < (totalOperations * 0.05); // Less than 5% slow operations
  }

  Map<String, dynamic> toJson() {
    return {
      'total_operations': totalOperations,
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'slow_operations_count': slowOperations.length,
      'app_startup_time_ms': appStartupTime.inMilliseconds,
      'memory_usage': memoryUsage,
      'meets_targets': meetsPerformanceTargets,
    };
  }
}

/// Extension to easily wrap functions with performance monitoring
extension PerformanceMonitoring on Function {
  Future<T> monitoredCall<T>(String operationName) async {
    final monitor = PerformanceMonitoringService();
    monitor.startOperation(operationName);
    try {
      final result = await (this as Future<T> Function())();
      return result;
    } finally {
      monitor.endOperation(operationName);
    }
  }
}