import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Comprehensive logging service for production debugging
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final List<LogEntry> _logs = [];
  File? _logFile;
  bool _isInitialized = false;

  /// Initialize logging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_logs.txt');
      
      // Create log file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      _isInitialized = true;
      await info('Logging service initialized');
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to initialize logging service: $e');
      }
    }
  }

  /// Log debug message
  Future<void> debug(String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _log(LogLevel.debug, message, tag: tag, extra: extra, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  Future<void> info(String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _log(LogLevel.info, message, tag: tag, extra: extra, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  Future<void> warning(String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _log(LogLevel.warning, message, tag: tag, extra: extra, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  Future<void> error(String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _log(LogLevel.error, message, tag: tag, extra: extra, error: error, stackTrace: stackTrace);
  }

  /// Log critical message
  Future<void> critical(String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _log(LogLevel.critical, message, tag: tag, extra: extra, error: error, stackTrace: stackTrace);
  }

  /// Log performance metrics
  Future<void> performance(String operation, Duration duration, {
    String? tag,
    Map<String, dynamic>? metrics,
  }) async {
    final message = '$operation completed in ${duration.inMilliseconds}ms';
    await _log(
      LogLevel.info, 
      message, 
      tag: tag ?? 'Performance',
      extra: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        ...?metrics,
      },
    );
  }

  /// Log network request
  Future<void> networkRequest(String method, String url, {
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? headers,
    dynamic requestBody,
    dynamic responseBody,
    Object? error,
  }) async {
    final message = '$method $url ${statusCode != null ? '($statusCode)' : ''}';
    await _log(
      error != null ? LogLevel.error : LogLevel.info,
      message,
      tag: 'Network',
      extra: {
        'method': method,
        'url': url,
        'status_code': statusCode,
        'duration_ms': duration?.inMilliseconds,
        'headers': headers,
        'request_body': requestBody?.toString(),
        'response_body': responseBody?.toString(),
      },
      error: error,
    );
  }

  /// Log database operation
  Future<void> databaseOperation(String operation, String table, {
    Duration? duration,
    int? affectedRows,
    Map<String, dynamic>? parameters,
    Object? error,
  }) async {
    final message = 'Database $operation on $table';
    await _log(
      error != null ? LogLevel.error : LogLevel.info,
      message,
      tag: 'Database',
      extra: {
        'operation': operation,
        'table': table,
        'duration_ms': duration?.inMilliseconds,
        'affected_rows': affectedRows,
        'parameters': parameters,
      },
      error: error,
    );
  }

  /// Log user action
  Future<void> userAction(String action, {
    String? screen,
    Map<String, dynamic>? context,
  }) async {
    final message = 'User action: $action${screen != null ? ' on $screen' : ''}';
    await _log(
      LogLevel.info,
      message,
      tag: 'UserAction',
      extra: {
        'action': action,
        'screen': screen,
        'context': context,
      },
    );
  }

  /// Private logging method
  Future<void> _log(LogLevel level, String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final logEntry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(logEntry);

    // Keep only last 1000 log entries in memory
    if (_logs.length > 1000) {
      _logs.removeRange(0, _logs.length - 1000);
    }

    // Log to console in debug mode
    if (kDebugMode) {
      final logMessage = _formatLogEntry(logEntry);
      switch (level) {
        case LogLevel.debug:
          developer.log(logMessage, name: tag ?? 'Debug');
          break;
        case LogLevel.info:
          developer.log(logMessage, name: tag ?? 'Info');
          break;
        case LogLevel.warning:
          developer.log(logMessage, name: tag ?? 'Warning');
          break;
        case LogLevel.error:
        case LogLevel.critical:
          developer.log(
            logMessage, 
            name: tag ?? 'Error',
            error: error,
            stackTrace: stackTrace,
          );
          break;
      }
    }

    // Write to file in production
    if (!kDebugMode && _isInitialized) {
      await _writeToFile(logEntry);
    }
  }

  /// Format log entry for display
  String _formatLogEntry(LogEntry entry) {
    final buffer = StringBuffer();
    buffer.write('[${entry.level.name.toUpperCase()}] ');
    buffer.write('${entry.timestamp.toIso8601String()} ');
    if (entry.tag != null) {
      buffer.write('[${entry.tag}] ');
    }
    buffer.write(entry.message);
    
    if (entry.extra != null && entry.extra!.isNotEmpty) {
      buffer.write(' | Extra: ${entry.extra}');
    }
    
    if (entry.error != null) {
      buffer.write(' | Error: ${entry.error}');
    }
    
    return buffer.toString();
  }

  /// Write log entry to file
  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFile == null) return;

    try {
      final logLine = '${_formatLogEntry(entry)}\n';
      await _logFile!.writeAsString(logLine, mode: FileMode.append);

      // Rotate log file if it gets too large (5MB)
      final stat = await _logFile!.stat();
      if (stat.size > 5 * 1024 * 1024) {
        await _rotateLogFile();
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to write to log file: $e');
      }
    }
  }

  /// Rotate log file
  Future<void> _rotateLogFile() async {
    if (_logFile == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final oldLogFile = File('${directory.path}/app_logs_old.txt');
      
      if (await oldLogFile.exists()) {
        await oldLogFile.delete();
      }
      
      await _logFile!.rename(oldLogFile.path);
      _logFile = File('${directory.path}/app_logs.txt');
      await _logFile!.create();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to rotate log file: $e');
      }
    }
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  /// Get logs in time range
  List<LogEntry> getLogsInTimeRange(DateTime start, DateTime end) {
    return _logs.where((log) => 
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs({int limit = 100}) {
    final sortedLogs = List<LogEntry>.from(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedLogs.take(limit).toList();
  }

  /// Get log statistics
  LogStatistics getStatistics() {
    final logsByLevel = <LogLevel, int>{};
    final logsByTag = <String, int>{};
    
    for (final log in _logs) {
      logsByLevel[log.level] = (logsByLevel[log.level] ?? 0) + 1;
      if (log.tag != null) {
        logsByTag[log.tag!] = (logsByTag[log.tag!] ?? 0) + 1;
      }
    }

    final recentLogs = _logs.where((log) => 
      log.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
    ).length;

    return LogStatistics(
      totalLogs: _logs.length,
      logsByLevel: logsByLevel,
      logsByTag: logsByTag,
      recentLogsCount: recentLogs,
    );
  }

  /// Export logs as string
  String exportLogs({LogLevel? level, String? tag}) {
    List<LogEntry> logsToExport = _logs;
    
    if (level != null) {
      logsToExport = logsToExport.where((log) => log.level == level).toList();
    }
    
    if (tag != null) {
      logsToExport = logsToExport.where((log) => log.tag == tag).toList();
    }

    return logsToExport.map(_formatLogEntry).join('\n');
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Get log file path
  String? get logFilePath => _logFile?.path;
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Log entry data class
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.extra,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'timestamp': timestamp.toIso8601String(),
      'extra': extra,
      'error': error?.toString(),
      'stack_trace': stackTrace?.toString(),
    };
  }
}

/// Log statistics
class LogStatistics {
  final int totalLogs;
  final Map<LogLevel, int> logsByLevel;
  final Map<String, int> logsByTag;
  final int recentLogsCount;

  const LogStatistics({
    required this.totalLogs,
    required this.logsByLevel,
    required this.logsByTag,
    required this.recentLogsCount,
  });

  int get errorCount => (logsByLevel[LogLevel.error] ?? 0) + (logsByLevel[LogLevel.critical] ?? 0);
  int get warningCount => logsByLevel[LogLevel.warning] ?? 0;
  double get errorRate => totalLogs > 0 ? (errorCount / totalLogs) * 100 : 0.0;

  bool get isHealthy => errorRate < 5.0; // Less than 5% errors

  Map<String, dynamic> toJson() {
    return {
      'total_logs': totalLogs,
      'logs_by_level': logsByLevel.map((k, v) => MapEntry(k.name, v)),
      'logs_by_tag': logsByTag,
      'recent_logs_count': recentLogsCount,
      'error_count': errorCount,
      'warning_count': warningCount,
      'error_rate': errorRate,
      'is_healthy': isHealthy,
    };
  }
}

/// Logger extension for easy access
extension Logger on Object {
  LoggingService get logger => LoggingService();
}