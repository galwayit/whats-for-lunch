import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/error_handling_service.dart';
import '../../core/services/connectivity_service.dart';

/// Global error boundary widget that catches and handles all app errors
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  final ErrorHandlingService _errorHandler = ErrorHandlingService();
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<AppError>? _errorSubscription;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  
  AppError? _currentError;
  bool _showConnectivityBanner = false;

  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
    _setupConnectivityHandling();
  }

  void _setupErrorHandling() {
    _errorSubscription = _errorHandler.errorStream.listen((error) {
      if (mounted) {
        _handleError(error);
      }
    });
  }

  void _setupConnectivityHandling() {
    _connectivitySubscription = _connectivity.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _showConnectivityBanner = status == ConnectivityStatus.offline;
        });
      }
    });
  }

  void _handleError(AppError error) {
    // Only show user-facing errors in production
    if (_shouldShowErrorToUser(error)) {
      setState(() {
        _currentError = error;
      });

      // Show error snackbar for non-critical errors
      if (error.type != AppErrorType.flutter && error.type != AppErrorType.runtime) {
        _showErrorSnackBar(error);
      }
    }
  }

  bool _shouldShowErrorToUser(AppError error) {
    // Don't show internal errors to users in production
    switch (error.type) {
      case AppErrorType.flutter:
      case AppErrorType.runtime:
        return false; // These should be caught by crash reporting
      case AppErrorType.network:
      case AppErrorType.connectivity:
      case AppErrorType.timeout:
      case AppErrorType.server:
      case AppErrorType.authentication:
      case AppErrorType.validation:
      case AppErrorType.permission:
        return true; // These can be shown to users with friendly messages
      default:
        return false;
    }
  }

  void _showErrorSnackBar(AppError error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.displayMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: error.type == AppErrorType.validation ? 3 : 4),
        action: error.type == AppErrorType.network ||
                error.type == AppErrorType.connectivity ||
                error.type == AppErrorType.timeout
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  _clearCurrentError();
                  // You might want to add a retry mechanism here
                },
              )
            : null,
      ),
    );
  }

  IconData _getErrorIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.connectivity:
        return Icons.wifi_off;
      case AppErrorType.timeout:
        return Icons.access_time;
      case AppErrorType.server:
        return Icons.error_outline;
      case AppErrorType.authentication:
        return Icons.lock;
      case AppErrorType.permission:
        return Icons.security;
      case AppErrorType.validation:
        return Icons.warning;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.connectivity:
        return Colors.orange;
      case AppErrorType.timeout:
        return Colors.amber;
      case AppErrorType.server:
        return Colors.red;
      case AppErrorType.authentication:
        return Colors.deepPurple;
      case AppErrorType.permission:
        return Colors.indigo;
      case AppErrorType.validation:
        return Colors.orange.shade700;
      default:
        return Colors.red;
    }
  }

  void _clearCurrentError() {
    setState(() {
      _currentError = null;
    });
  }

  Widget _buildConnectivityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange,
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No internet connection. Some features may not work.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                // Force connectivity check
                setState(() {
                  _showConnectivityBanner = false;
                });
              },
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorFallback() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _currentError?.displayMessage ?? 
                'An unexpected error occurred. Please restart the app.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _clearCurrentError,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Close app or navigate to safe screen
                      SystemNavigator.pop();
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Restart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_currentError != null)
                ExpansionTile(
                  title: const Text('Error Details'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type: ${_currentError!.type.name}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Time: ${_currentError!.timestamp}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          if (_currentError!.context != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Context: ${_currentError!.context}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show error fallback for critical errors
    if (_currentError != null && 
        (_currentError!.type == AppErrorType.flutter || 
         _currentError!.type == AppErrorType.runtime)) {
      return MaterialApp(
        home: _buildErrorFallback(),
        debugShowCheckedModeBanner: false,
      );
    }

    return Column(
      children: [
        if (_showConnectivityBanner) _buildConnectivityBanner(),
        Expanded(child: widget.child),
      ],
    );
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Global error reporting widget for debugging
class ErrorReportingButton extends StatelessWidget {
  const ErrorReportingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ErrorReportScreen(),
          ),
        );
      },
      backgroundColor: Colors.red,
      child: const Icon(Icons.bug_report, color: Colors.white),
    );
  }
}

/// Screen for viewing error reports (debug only)
class ErrorReportScreen extends StatelessWidget {
  const ErrorReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final errorHandler = ErrorHandlingService();
    final errors = errorHandler.getErrorHistory(limit: 50);
    final stats = errorHandler.getErrorStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Reports'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              errorHandler.clearErrorHistory();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Total Errors: ${stats.totalErrors}'),
                Text('Recent Error Rate: ${stats.recentErrorRate.toStringAsFixed(2)}/min'),
                Text('Health Status: ${stats.isHealthy ? "Healthy" : "Unhealthy"}'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: errors.length,
              itemBuilder: (context, index) {
                final error = errors[index];
                return ExpansionTile(
                  title: Text(
                    '${error.type.name.toUpperCase()}: ${error.message}',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    error.timestamp.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (error.userMessage != null) ...[
                            Text('User Message: ${error.userMessage}'),
                            const SizedBox(height: 8),
                          ],
                          if (error.context != null) ...[
                            Text('Context: ${error.context}'),
                            const SizedBox(height: 8),
                          ],
                          if (error.stackTrace != null) ...[
                            const Text('Stack Trace:'),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                error.stackTrace.toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}