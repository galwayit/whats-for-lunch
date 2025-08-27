import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/connectivity_service.dart';
import 'core/services/error_handling_service.dart';
import 'core/services/performance_monitoring_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/router_provider.dart';
import 'presentation/widgets/error_boundary_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance monitoring
  final performanceMonitor = PerformanceMonitoringService();
  performanceMonitor.initialize();
  performanceMonitor.startOperation('app_startup');

  // Initialize error handling
  final errorHandler = ErrorHandlingService();
  errorHandler.initialize();

  // Initialize connectivity monitoring
  final connectivity = ConnectivityService();
  connectivity.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ProviderScope(
      child: ErrorBoundaryWidget(
        child: MyApp(),
      ),
    ),
  );

  // Record startup completion
  performanceMonitor.endOperation('app_startup');
  performanceMonitor.recordAppStartup();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // title: 'What We Have For Lunch',
      theme: AppTheme.getLightTheme(
        highContrast:
            MediaQuery.platformBrightnessOf(context) == Brightness.light
                ? MediaQuery.highContrastOf(context)
                : false,
      ),
      darkTheme: AppTheme.getDarkTheme(
        highContrast:
            MediaQuery.platformBrightnessOf(context) == Brightness.dark
                ? MediaQuery.highContrastOf(context)
                : false,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Add accessibility support
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final textScaler = mediaQuery.textScaler;
        final clampedScaler =
            TextScaler.linear(textScaler.scale(1.0).clamp(0.8, 2.0));

        return MediaQuery(
          data: mediaQuery.copyWith(
            // Ensure text scaling doesn't break layouts
            textScaler: clampedScaler,
          ),
          child: child!,
        );
      },
    );
  }
}
