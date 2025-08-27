import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Comprehensive error handling service for production readiness
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final List<AppError> _errorHistory = [];
  StreamController<AppError>? _errorStreamController;
  
  /// Stream of errors for global error handling
  Stream<AppError> get errorStream {
    _errorStreamController ??= StreamController<AppError>.broadcast();
    return _errorStreamController!.stream;
  }

  /// Initialize error handling service
  void initialize() {
    // Set up global error handling for uncaught exceptions
    FlutterError.onError = (FlutterErrorDetails details) {
      handleFlutterError(details);
    };

    // Handle platform dispatcher errors (Dart errors outside Flutter)
    PlatformDispatcher.instance.onError = (error, stack) {
      handleDartError(error, stack);
      return true;
    };

    if (kDebugMode) {
      developer.log('Error handling service initialized', name: 'ErrorHandler');
    }
  }

  /// Handle Flutter-specific errors
  void handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      type: AppErrorType.flutter,
      message: details.exception.toString(),
      stackTrace: details.stack,
      timestamp: DateTime.now(),
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );

    _recordError(error);

    // In debug mode, also use Flutter's default error handling
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handle Dart runtime errors
  void handleDartError(Object error, StackTrace? stackTrace) {
    final appError = AppError(
      type: AppErrorType.runtime,
      message: error.toString(),
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _recordError(appError);
  }

  /// Handle network errors with context
  AppError handleNetworkError(Object error, {
    String? endpoint,
    Map<String, dynamic>? requestData,
  }) {
    String userMessage;
    Map<String, dynamic> context = {
      'endpoint': endpoint,
      'request_data': requestData?.toString(),
    };

    AppErrorType errorType = AppErrorType.network;

    if (error is DioException) {
      context['response_code'] = error.response?.statusCode;
      context['response_data'] = error.response?.data?.toString();
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          userMessage = 'Connection timed out. Please check your internet connection.';
          errorType = AppErrorType.timeout;
          break;
        case DioExceptionType.connectionError:
          userMessage = 'Unable to connect to server. Please check your internet connection.';
          errorType = AppErrorType.connectivity;
          break;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode != null) {
            if (statusCode >= 500) {
              userMessage = 'Server error occurred. Please try again later.';
              errorType = AppErrorType.server;
            } else if (statusCode == 404) {
              userMessage = 'Requested resource not found.';
              errorType = AppErrorType.notFound;
            } else if (statusCode == 401) {
              userMessage = 'Authentication required. Please log in again.';
              errorType = AppErrorType.authentication;
            } else {
              userMessage = 'Request failed. Please try again.';
            }
          } else {
            userMessage = 'Network request failed. Please try again.';
          }
          break;
        default:
          userMessage = 'Network error occurred. Please try again.';
      }
    } else if (error is SocketException) {
      userMessage = 'No internet connection. Please check your network settings.';
      errorType = AppErrorType.connectivity;
    } else {
      userMessage = 'Network error occurred. Please try again.';
    }

    final appError = AppError(
      type: errorType,
      message: error.toString(),
      userMessage: userMessage,
      timestamp: DateTime.now(),
      context: context,
    );

    _recordError(appError);
    return appError;
  }

  /// Handle database errors
  AppError handleDatabaseError(Object error, {
    String? operation,
    String? table,
    Map<String, dynamic>? queryData,
  }) {
    String userMessage = 'Data operation failed. Please try again.';
    
    final context = {
      'operation': operation,
      'table': table,
      'query_data': queryData?.toString(),
    };

    final appError = AppError(
      type: AppErrorType.database,
      message: error.toString(),
      userMessage: userMessage,
      timestamp: DateTime.now(),
      context: context,
    );

    _recordError(appError);
    return appError;
  }

  /// Handle permission errors
  AppError handlePermissionError(String permission, {String? context}) {
    final userMessage = 'Permission required for $permission. Please grant access in settings.';
    
    final appError = AppError(
      type: AppErrorType.permission,
      message: 'Permission denied: $permission',
      userMessage: userMessage,
      timestamp: DateTime.now(),
      context: {'permission': permission, 'context': context},
    );

    _recordError(appError);
    return appError;
  }

  /// Handle validation errors
  AppError handleValidationError(String field, String message, {Map<String, dynamic>? data}) {
    final appError = AppError(
      type: AppErrorType.validation,
      message: 'Validation error: $field - $message',
      userMessage: message,
      timestamp: DateTime.now(),
      context: {'field': field, 'data': data},
    );

    _recordError(appError);
    return appError;
  }

  /// Handle general application errors
  AppError handleAppError(Object error, {
    String? userMessage,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final appError = AppError(
      type: AppErrorType.application,
      message: error.toString(),
      userMessage: userMessage ?? 'An error occurred. Please try again.',
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context,
    );

    _recordError(appError);
    return appError;
  }

  /// Record error and notify listeners
  void _recordError(AppError error) {
    _errorHistory.add(error);
    
    // Keep only last 500 errors to prevent memory issues
    if (_errorHistory.length > 500) {
      _errorHistory.removeRange(0, _errorHistory.length - 500);
    }

    // Notify listeners
    _errorStreamController?.add(error);

    // Log error
    if (kDebugMode) {
      developer.log(
        'Error recorded: ${error.type.name} - ${error.message}',
        name: 'ErrorHandler',
        error: error.message,
        stackTrace: error.stackTrace,
      );
    }

    // In production, you might want to send to crash reporting service
    // _sendToCrashlytics(error);
  }

  /// Get error history
  List<AppError> getErrorHistory({int? limit}) {
    if (limit != null && limit < _errorHistory.length) {
      return _errorHistory.reversed.take(limit).toList();
    }
    return _errorHistory.reversed.toList();
  }

  /// Get errors by type
  List<AppError> getErrorsByType(AppErrorType type) {
    return _errorHistory.where((error) => error.type == type).toList();
  }

  /// Get error statistics
  ErrorStatistics getErrorStatistics() {
    if (_errorHistory.isEmpty) {
      return ErrorStatistics(
        totalErrors: 0,
        errorsByType: {},
        recentErrorRate: 0.0,
        mostCommonError: null,
      );
    }

    final errorsByType = <AppErrorType, int>{};
    final errorsByMessage = <String, int>{};

    for (final error in _errorHistory) {
      errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
      errorsByMessage[error.message] = (errorsByMessage[error.message] ?? 0) + 1;
    }

    // Calculate recent error rate (errors in last hour)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentErrors = _errorHistory
        .where((error) => error.timestamp.isAfter(oneHourAgo))
        .length;

    // Find most common error
    final mostCommonEntry = errorsByMessage.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return ErrorStatistics(
      totalErrors: _errorHistory.length,
      errorsByType: errorsByType,
      recentErrorRate: recentErrors / 60.0, // errors per minute
      mostCommonError: mostCommonEntry.key,
    );
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController?.close();
    _errorStreamController = null;
  }
}

/// Application error types for categorization
enum AppErrorType {
  network,
  database,
  permission,
  validation,
  authentication,
  server,
  connectivity,
  timeout,
  notFound,
  flutter,
  runtime,
  application,
}

/// Application error data class
class AppError {
  final AppErrorType type;
  final String message;
  final String? userMessage;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const AppError({
    required this.type,
    required this.message,
    this.userMessage,
    required this.timestamp,
    this.stackTrace,
    this.context,
  });

  /// Get user-friendly error message
  String get displayMessage => userMessage ?? _getDefaultUserMessage();

  String _getDefaultUserMessage() {
    switch (type) {
      case AppErrorType.network:
        return 'Network error occurred. Please check your connection.';
      case AppErrorType.database:
        return 'Data error occurred. Please try again.';
      case AppErrorType.permission:
        return 'Permission required. Please check app settings.';
      case AppErrorType.validation:
        return 'Invalid input. Please check your data.';
      case AppErrorType.authentication:
        return 'Authentication required. Please log in.';
      case AppErrorType.server:
        return 'Server error. Please try again later.';
      case AppErrorType.connectivity:
        return 'No internet connection. Please check your network.';
      case AppErrorType.timeout:
        return 'Request timed out. Please try again.';
      case AppErrorType.notFound:
        return 'Resource not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'user_message': userMessage,
      'timestamp': timestamp.toIso8601String(),
      'stack_trace': stackTrace?.toString(),
      'context': context,
    };
  }
}

/// Error statistics for monitoring
class ErrorStatistics {
  final int totalErrors;
  final Map<AppErrorType, int> errorsByType;
  final double recentErrorRate; // errors per minute
  final String? mostCommonError;

  const ErrorStatistics({
    required this.totalErrors,
    required this.errorsByType,
    required this.recentErrorRate,
    this.mostCommonError,
  });

  /// Check if error rate is healthy (less than 1 error per minute)
  bool get isHealthy => recentErrorRate < 1.0;

  Map<String, dynamic> toJson() {
    return {
      'total_errors': totalErrors,
      'errors_by_type': errorsByType.map((k, v) => MapEntry(k.name, v)),
      'recent_error_rate': recentErrorRate,
      'most_common_error': mostCommonError,
      'is_healthy': isHealthy,
    };
  }
}

/// Helper class for retry logic
class RetryHelper {
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Object)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempts++;
        
        if (attempts >= maxRetries || (shouldRetry != null && !shouldRetry(error))) {
          rethrow;
        }
        
        // Exponential backoff
        final backoffDelay = Duration(
          milliseconds: delay.inMilliseconds * (1 << (attempts - 1)),
        );
        
        await Future.delayed(backoffDelay);
      }
    }
    
    throw StateError('Retry operation should not reach this point');
  }
}