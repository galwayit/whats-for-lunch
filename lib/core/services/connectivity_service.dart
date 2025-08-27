import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Network connectivity service with offline capabilities
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  StreamController<ConnectivityStatus>? _statusController;
  Timer? _connectivityTimer;
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  final List<String> _testUrls = [
    'https://www.google.com',
    'https://www.cloudflare.com',
    'https://1.1.1.1',
  ];

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream {
    _statusController ??= StreamController<ConnectivityStatus>.broadcast();
    return _statusController!.stream;
  }

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Whether the device is currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Initialize connectivity monitoring
  void initialize() {
    _startMonitoring();
    _checkInitialConnectivity();
    
    if (kDebugMode) {
      print('Connectivity service initialized');
    }
  }

  /// Start monitoring connectivity
  void _startMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    await _checkConnectivity();
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      final status = await _performConnectivityTest();
      _updateStatus(status);
    } catch (e) {
      _updateStatus(ConnectivityStatus.offline);
    }
  }

  /// Perform actual connectivity test
  Future<ConnectivityStatus> _performConnectivityTest() async {
    // First, try a quick socket connection
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Perform HTTP test for more reliable check
        return await _performHttpTest();
      }
    } catch (e) {
      // Socket test failed, try HTTP test anyway
    }

    return await _performHttpTest();
  }

  /// Perform HTTP connectivity test
  Future<ConnectivityStatus> _performHttpTest() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    ));

    for (final url in _testUrls) {
      try {
        final response = await dio.head(url);
        if (response.statusCode != null && response.statusCode! < 400) {
          return ConnectivityStatus.online;
        }
      } catch (e) {
        // Try next URL
        continue;
      }
    }

    return ConnectivityStatus.offline;
  }

  /// Update connectivity status
  void _updateStatus(ConnectivityStatus newStatus) {
    if (newStatus != _currentStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;
      
      _statusController?.add(newStatus);
      
      if (kDebugMode) {
        print('Connectivity changed: ${oldStatus.name} -> ${newStatus.name}');
      }
    }
  }

  /// Test connection to specific endpoint
  Future<bool> testConnection(String endpoint) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.head(endpoint);
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }

  /// Wait for online status
  Future<void> waitForOnline({Duration timeout = const Duration(seconds: 30)}) async {
    if (isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;
    Timer? timeoutTimer;

    subscription = statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        timeoutTimer?.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    timeoutTimer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Waiting for online timeout', timeout));
      }
    });

    return completer.future;
  }

  /// Execute operation with connectivity check
  Future<T> executeWithConnectivity<T>(
    Future<T> Function() operation, {
    T? offlineResult,
    Duration retryDelay = const Duration(seconds: 2),
    int maxRetries = 3,
  }) async {
    if (isOffline) {
      if (offlineResult != null) {
        return offlineResult;
      }
      throw ConnectivityException('No internet connection');
    }

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (e is DioException && _isNetworkError(e)) {
          // Network error, check connectivity
          await _checkConnectivity();
          
          if (isOffline) {
            if (offlineResult != null) {
              return offlineResult;
            }
            throw ConnectivityException('Lost internet connection');
          }
          
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay * attempts);
            continue;
          }
        }
        
        rethrow;
      }
    }
    
    throw StateError('Should not reach here');
  }

  /// Check if error is network-related
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.connectionError ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout;
  }

  /// Get connectivity statistics
  ConnectivityStats getStats() {
    // In a real implementation, you'd track these over time
    return ConnectivityStats(
      currentStatus: _currentStatus,
      lastStatusChange: DateTime.now(),
      uptime: const Duration(hours: 1), // Mock data
      downtime: const Duration(minutes: 5), // Mock data
    );
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _statusController?.close();
    _statusController = null;
  }
}

/// Connectivity status enumeration
enum ConnectivityStatus {
  unknown,
  online,
  offline,
}

/// Connectivity exception
class ConnectivityException implements Exception {
  final String message;
  const ConnectivityException(this.message);
  
  @override
  String toString() => 'ConnectivityException: $message';
}

/// Connectivity statistics
class ConnectivityStats {
  final ConnectivityStatus currentStatus;
  final DateTime lastStatusChange;
  final Duration uptime;
  final Duration downtime;

  const ConnectivityStats({
    required this.currentStatus,
    required this.lastStatusChange,
    required this.uptime,
    required this.downtime,
  });

  double get uptimePercentage {
    final total = uptime + downtime;
    if (total.inMilliseconds == 0) return 100.0;
    return (uptime.inMilliseconds / total.inMilliseconds) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'current_status': currentStatus.name,
      'last_status_change': lastStatusChange.toIso8601String(),
      'uptime_minutes': uptime.inMinutes,
      'downtime_minutes': downtime.inMinutes,
      'uptime_percentage': uptimePercentage,
    };
  }
}

/// Network request wrapper with offline support
class NetworkRequest {
  final Dio _dio;
  final ConnectivityService _connectivity = ConnectivityService();

  NetworkRequest({Dio? dio}) : _dio = dio ?? Dio();

  /// GET request with connectivity handling
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T? offlineResult,
    bool requiresConnectivity = true,
  }) async {
    if (requiresConnectivity) {
      return await _connectivity.executeWithConnectivity(() =>
        _dio.get<T>(path, queryParameters: queryParameters, options: options),
        offlineResult: offlineResult != null
            ? Response<T>(
                data: offlineResult,
                statusCode: 200,
                requestOptions: RequestOptions(path: path),
              )
            : null,
      );
    }

    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  /// POST request with connectivity handling
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _connectivity.executeWithConnectivity(() =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }

  /// PUT request with connectivity handling
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _connectivity.executeWithConnectivity(() =>
      _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }

  /// DELETE request with connectivity handling
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _connectivity.executeWithConnectivity(() =>
      _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options),
    );
  }
}

/// Offline storage for network requests
abstract class OfflineStorage {
  Future<void> storeRequest(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getRequest(String key);
  Future<void> removeRequest(String key);
  Future<List<String>> getPendingRequests();
  Future<void> clearExpiredRequests();
}

/// Simple offline storage implementation
class SimpleOfflineStorage implements OfflineStorage {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<void> storeRequest(String key, Map<String, dynamic> data) async {
    _storage[key] = {
      ...data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<Map<String, dynamic>?> getRequest(String key) async {
    return _storage[key];
  }

  @override
  Future<void> removeRequest(String key) async {
    _storage.remove(key);
  }

  @override
  Future<List<String>> getPendingRequests() async {
    return _storage.keys.toList();
  }

  @override
  Future<void> clearExpiredRequests() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = _storage.entries
        .where((entry) {
          final timestamp = entry.value['timestamp'] as int?;
          return timestamp != null && (now - timestamp) > Duration(days: 1).inMilliseconds;
        })
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _storage.remove(key);
    }
  }
}