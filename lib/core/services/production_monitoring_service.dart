import 'dart:async';
import 'performance_monitoring_service.dart';
import 'error_handling_service.dart';
import 'connectivity_service.dart';
import 'logging_service.dart';
import 'optimized_image_service.dart';

/// Comprehensive production monitoring service
class ProductionMonitoringService {
  static final ProductionMonitoringService _instance = ProductionMonitoringService._internal();
  factory ProductionMonitoringService() => _instance;
  ProductionMonitoringService._internal();

  final PerformanceMonitoringService _performance = PerformanceMonitoringService();
  final ErrorHandlingService _errorHandler = ErrorHandlingService();
  final ConnectivityService _connectivity = ConnectivityService();
  final LoggingService _logging = LoggingService();

  Timer? _monitoringTimer;
  bool _isInitialized = false;

  /// Initialize production monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize all services
    _performance.initialize();
    _errorHandler.initialize();
    _connectivity.initialize();
    await _logging.initialize();

    // Start periodic monitoring
    _startPeriodicMonitoring();

    _isInitialized = true;
    await _logging.info('Production monitoring service initialized');
  }

  /// Start periodic health checks and monitoring
  void _startPeriodicMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 5), // Check every 5 minutes
      (_) => _performHealthCheck(),
    );
  }

  /// Perform comprehensive health check
  Future<void> _performHealthCheck() async {
    try {
      final healthReport = await getHealthReport();
      
      // Log health status
      if (healthReport.isHealthy) {
        await _logging.info(
          'System health check passed',
          tag: 'HealthCheck',
          extra: healthReport.toJson(),
        );
      } else {
        await _logging.warning(
          'System health check failed',
          tag: 'HealthCheck',
          extra: {
            'issues': healthReport.issues,
            'report': healthReport.toJson(),
          },
        );
      }

      // Perform cleanup if needed
      await _performCleanupTasks(healthReport);

    } catch (e, stackTrace) {
      await _logging.error(
        'Health check failed',
        tag: 'HealthCheck',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Perform cleanup tasks based on health report
  Future<void> _performCleanupTasks(HealthReport report) async {
    // Clean up image cache if it's too large
    if (report.imageCacheSize > 100) { // >100MB
      await OptimizedImageService.clearImageCache();
      await _logging.info('Image cache cleared due to size limit');
    }

    // Clean up old errors if there are too many
    if (report.errorStatistics.totalErrors > 500) {
      _errorHandler.clearErrorHistory();
      await _logging.info('Error history cleared due to size limit');
    }

    // Clean up old logs if there are too many
    if (report.logStatistics.totalLogs > 1000) {
      _logging.clearLogs();
      await _logging.info('Log history cleared due to size limit');
    }
  }

  /// Get comprehensive health report
  Future<HealthReport> getHealthReport() async {
    try {
      // Get performance metrics
      final performanceSummary = _performance.getPerformanceSummary();
      
      // Get error statistics
      final errorStats = _errorHandler.getErrorStatistics();
      
      // Get connectivity stats
      final connectivityStats = _connectivity.getStats();
      
      // Get logging statistics
      final logStats = _logging.getStatistics();
      
      // Get image cache info
      final imageCacheInfo = await OptimizedImageService.getCacheInfo();

      // Determine overall health
      final issues = <String>[];
      
      if (!performanceSummary.meetsPerformanceTargets) {
        issues.add('Performance targets not met');
      }
      
      if (!errorStats.isHealthy) {
        issues.add('High error rate detected');
      }
      
      if (!logStats.isHealthy) {
        issues.add('High log error rate');
      }
      
      if (connectivityStats.uptimePercentage < 95.0) {
        issues.add('Poor connectivity uptime');
      }

      return HealthReport(
        timestamp: DateTime.now(),
        isHealthy: issues.isEmpty,
        issues: issues,
        performanceSummary: performanceSummary,
        errorStatistics: errorStats,
        connectivityStatistics: connectivityStats,
        logStatistics: logStats,
        imageCacheSize: imageCacheInfo.diskCacheSizeMB,
        memoryCacheSize: imageCacheInfo.memoryCacheSizeMB,
      );
    } catch (e, stackTrace) {
      await _logging.error(
        'Failed to generate health report',
        tag: 'HealthReport',
        error: e,
        stackTrace: stackTrace,
      );
      
      return HealthReport(
        timestamp: DateTime.now(),
        isHealthy: false,
        issues: ['Failed to generate health report: $e'],
        performanceSummary: _performance.getPerformanceSummary(),
        errorStatistics: _errorHandler.getErrorStatistics(),
        connectivityStatistics: _connectivity.getStats(),
        logStatistics: _logging.getStatistics(),
        imageCacheSize: 0,
        memoryCacheSize: 0,
      );
    }
  }

  /// Record user journey for analytics
  Future<void> recordUserJourney(String screen, {
    Map<String, dynamic>? metadata,
    Duration? loadTime,
  }) async {
    await _logging.userAction(
      'screen_view',
      screen: screen,
      context: {
        'load_time_ms': loadTime?.inMilliseconds,
        ...?metadata,
      },
    );

    if (loadTime != null) {
      _performance.recordMetric(
        'screen_load_$screen',
        loadTime,
        metadata: metadata,
      );
    }
  }

  /// Record API usage for cost monitoring
  Future<void> recordAPIUsage(String endpoint, {
    required bool success,
    Duration? responseTime,
    int? statusCode,
    double? cost,
  }) async {
    await _logging.networkRequest(
      'API',
      endpoint,
      statusCode: statusCode,
      duration: responseTime,
      error: success ? null : 'API call failed',
    );

    if (responseTime != null) {
      _performance.recordNetworkOperation(
        endpoint,
        responseTime,
        wasSuccessful: success,
        statusCode: statusCode,
      );
    }

    // Log cost if provided (for AI services)
    if (cost != null && cost > 0) {
      await _logging.info(
        'API cost incurred',
        tag: 'APICosting',
        extra: {
          'endpoint': endpoint,
          'cost': cost,
          'success': success,
        },
      );
    }
  }

  /// Export comprehensive monitoring data
  Future<Map<String, dynamic>> exportMonitoringData() async {
    final healthReport = await getHealthReport();
    
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'health_report': healthReport.toJson(),
      'performance_metrics': _performance.exportMetrics(),
      'recent_errors': _errorHandler.getErrorHistory(limit: 50)
          .map((e) => e.toJson()).toList(),
      'connectivity_history': _connectivity.getStats().toJson(),
      'log_export': _logging.exportLogs(),
    };
  }

  /// Get user experience metrics
  UserExperienceMetrics getUserExperienceMetrics() {
    final performanceSummary = _performance.getPerformanceSummary();
    final errorStats = _errorHandler.getErrorStatistics();
    
    // Calculate user experience score (0-100)
    double uxScore = 100.0;
    
    // Penalize for slow startup (target: <3s)
    if (performanceSummary.appStartupTime.inMilliseconds > 3000) {
      uxScore -= 20;
    } else if (performanceSummary.appStartupTime.inMilliseconds > 2000) {
      uxScore -= 10;
    }
    
    // Penalize for slow average response time (target: <500ms)
    if (performanceSummary.averageResponseTime.inMilliseconds > 1000) {
      uxScore -= 20;
    } else if (performanceSummary.averageResponseTime.inMilliseconds > 500) {
      uxScore -= 10;
    }
    
    // Penalize for high error rate
    if (errorStats.recentErrorRate > 2.0) {
      uxScore -= 30;
    } else if (errorStats.recentErrorRate > 1.0) {
      uxScore -= 15;
    }
    
    // Penalize for slow operations
    final slowOperationsRatio = performanceSummary.slowOperations.length / 
        (performanceSummary.totalOperations > 0 ? performanceSummary.totalOperations : 1);
    if (slowOperationsRatio > 0.1) {
      uxScore -= 20;
    } else if (slowOperationsRatio > 0.05) {
      uxScore -= 10;
    }
    
    uxScore = uxScore.clamp(0.0, 100.0);
    
    return UserExperienceMetrics(
      score: uxScore,
      startupTime: performanceSummary.appStartupTime,
      averageResponseTime: performanceSummary.averageResponseTime,
      errorRate: errorStats.recentErrorRate,
      slowOperationsRatio: slowOperationsRatio,
    );
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _errorHandler.dispose();
    _connectivity.dispose();
  }
}

/// Comprehensive health report
class HealthReport {
  final DateTime timestamp;
  final bool isHealthy;
  final List<String> issues;
  final PerformanceSummary performanceSummary;
  final ErrorStatistics errorStatistics;
  final ConnectivityStats connectivityStatistics;
  final LogStatistics logStatistics;
  final double imageCacheSize;
  final double memoryCacheSize;

  const HealthReport({
    required this.timestamp,
    required this.isHealthy,
    required this.issues,
    required this.performanceSummary,
    required this.errorStatistics,
    required this.connectivityStatistics,
    required this.logStatistics,
    required this.imageCacheSize,
    required this.memoryCacheSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'is_healthy': isHealthy,
      'issues': issues,
      'performance_summary': performanceSummary.toJson(),
      'error_statistics': errorStatistics.toJson(),
      'connectivity_statistics': connectivityStatistics.toJson(),
      'log_statistics': logStatistics.toJson(),
      'image_cache_size_mb': imageCacheSize,
      'memory_cache_size_mb': memoryCacheSize,
    };
  }
}

/// User experience metrics
class UserExperienceMetrics {
  final double score; // 0-100
  final Duration startupTime;
  final Duration averageResponseTime;
  final double errorRate;
  final double slowOperationsRatio;

  const UserExperienceMetrics({
    required this.score,
    required this.startupTime,
    required this.averageResponseTime,
    required this.errorRate,
    required this.slowOperationsRatio,
  });

  String get scoreGrade {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Poor';
    return 'Critical';
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'grade': scoreGrade,
      'startup_time_ms': startupTime.inMilliseconds,
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'error_rate': errorRate,
      'slow_operations_ratio': slowOperationsRatio,
    };
  }
}