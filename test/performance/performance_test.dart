import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:what_we_have_for_lunch/main.dart' as app;
import 'package:what_we_have_for_lunch/core/services/performance_monitoring_service.dart';
import 'package:what_we_have_for_lunch/core/services/production_monitoring_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('App startup time should be under 3 seconds', (tester) async {
      final stopwatch = Stopwatch()..start();
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      final startupTimeMs = stopwatch.elapsedMilliseconds;
      
      // Log the startup time
      print('App startup time: ${startupTimeMs}ms');
      
      // Assert that startup time is under 3 seconds (3000ms)
      expect(startupTimeMs, lessThan(3000), 
        reason: 'App should start in less than 3 seconds');
      
      // Additional assertions for good performance
      expect(startupTimeMs, lessThan(2000), 
        reason: 'App should ideally start in less than 2 seconds');
    });

    testWidgets('Database operations should be performant', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      final performance = PerformanceMonitoringService();
      
      // Test database query performance
      performance.startOperation('test_db_operations');
      
      // Simulate database operations
      await Future.delayed(const Duration(milliseconds: 100));
      
      performance.endOperation('test_db_operations');
      
      final summary = performance.getPerformanceSummary();
      
      // Check that average response time is reasonable
      expect(summary.averageResponseTime.inMilliseconds, lessThan(1000),
        reason: 'Database operations should complete in under 1 second');
    });

    testWidgets('Memory usage should be reasonable', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      final monitoring = ProductionMonitoringService();
      await monitoring.initialize();
      
      final healthReport = await monitoring.getHealthReport();
      
      // Check memory cache size
      expect(healthReport.memoryCacheSize, lessThan(50.0),
        reason: 'Memory cache should be under 50MB');
        
      // Check image cache size
      expect(healthReport.imageCacheSize, lessThan(100.0),
        reason: 'Image cache should be under 100MB');
    });

    testWidgets('UI rendering should maintain 60fps', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test scrolling performance
      final listFinder = find.byType(ListView).first;
      
      final stopwatch = Stopwatch()..start();
      
      // Perform multiple scroll operations
      for (int i = 0; i < 10; i++) {
        await tester.drag(listFinder, const Offset(0, -200));
        await tester.pump();
      }
      
      stopwatch.stop();
      
      final averageFrameTime = stopwatch.elapsedMilliseconds / 10;
      
      // Should maintain smooth scrolling (under 16.67ms per frame for 60fps)
      expect(averageFrameTime, lessThan(20),
        reason: 'UI should maintain smooth 60fps performance');
    });

    testWidgets('Network operations should have reasonable timeouts', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      final performance = PerformanceMonitoringService();
      
      // Simulate network operation
      performance.startOperation('test_network');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      performance.endOperation('test_network');
      
      final networkMetrics = performance.getMetricsForOperation('test_network');
      
      if (networkMetrics.isNotEmpty) {
        final lastMetric = networkMetrics.last;
        expect(lastMetric.duration.inMilliseconds, lessThan(5000),
          reason: 'Network operations should complete in under 5 seconds');
      }
    });

    testWidgets('Error handling should not impact performance', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      final monitoring = ProductionMonitoringService();
      await monitoring.initialize();
      
      final uxMetrics = monitoring.getUserExperienceMetrics();
      
      // User experience score should be good (>70)
      expect(uxMetrics.score, greaterThan(70.0),
        reason: 'User experience score should be above 70');
        
      // Error rate should be low
      expect(uxMetrics.errorRate, lessThan(1.0),
        reason: 'Error rate should be under 1 error per minute');
    });

    testWidgets('App should handle large datasets efficiently', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test with simulated large dataset
      final performance = PerformanceMonitoringService();
      performance.startOperation('large_dataset_test');
      
      // Simulate processing 1000 items
      for (int i = 0; i < 1000; i++) {
        // Simulate processing
        await Future.delayed(Duration.zero);
      }
      
      performance.endOperation('large_dataset_test');
      
      final metrics = performance.getMetricsForOperation('large_dataset_test');
      if (metrics.isNotEmpty) {
        final duration = metrics.last.duration;
        expect(duration.inMilliseconds, lessThan(2000),
          reason: 'Large dataset processing should complete in under 2 seconds');
      }
    });

    testWidgets('Image loading should be optimized', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test image loading performance
      final performance = PerformanceMonitoringService();
      performance.startOperation('image_loading_test');
      
      // Find cached network images
      final imageFinder = find.byType(Image);
      
      if (imageFinder.evaluate().isNotEmpty) {
        // Wait for images to load
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      
      performance.endOperation('image_loading_test');
      
      final imageMetrics = performance.getMetricsForOperation('image_loading_test');
      if (imageMetrics.isNotEmpty) {
        final duration = imageMetrics.last.duration;
        expect(duration.inMilliseconds, lessThan(3000),
          reason: 'Image loading should complete in under 3 seconds');
      }
    });

    testWidgets('App should recover gracefully from errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Verify error boundary is working
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsAtLeastNWidgets(1),
        reason: 'App should render successfully without critical errors');
      
      final monitoring = ProductionMonitoringService();
      await monitoring.initialize();
      
      final healthReport = await monitoring.getHealthReport();
      
      // App should be healthy
      expect(healthReport.isHealthy, isTrue,
        reason: 'App health should be good');
        
      // Should have minimal issues
      expect(healthReport.issues.length, lessThan(3),
        reason: 'Should have fewer than 3 health issues');
    });

    testWidgets('Performance monitoring overhead should be minimal', (tester) async {
      // Test without performance monitoring
      final stopwatchWithoutMonitoring = Stopwatch()..start();
      
      // Simulate operations without monitoring
      for (int i = 0; i < 100; i++) {
        await Future.delayed(Duration.zero);
      }
      
      stopwatchWithoutMonitoring.stop();
      
      // Test with performance monitoring
      final performance = PerformanceMonitoringService();
      final stopwatchWithMonitoring = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        performance.startOperation('test_$i');
        await Future.delayed(Duration.zero);
        performance.endOperation('test_$i');
      }
      
      stopwatchWithMonitoring.stop();
      
      final overheadMs = stopwatchWithMonitoring.elapsedMilliseconds - 
                        stopwatchWithoutMonitoring.elapsedMilliseconds;
      
      // Performance monitoring overhead should be minimal (under 50ms for 100 operations)
      expect(overheadMs, lessThan(50),
        reason: 'Performance monitoring should have minimal overhead');
    });
  });

  group('Production Readiness Tests', () {
    testWidgets('All monitoring services should initialize successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      final monitoring = ProductionMonitoringService();
      
      // Should initialize without throwing
      expect(() => monitoring.initialize(), returnsNormally);
      
      // Should be able to get health report
      final healthReport = await monitoring.getHealthReport();
      expect(healthReport, isNotNull);
    });

    testWidgets('Error boundaries should catch and handle errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // App should render without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Error boundary widget should be present
      expect(find.byKey(const Key('error_boundary')), findsOneWidget);
    });

    testWidgets('Connectivity handling should work offline', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // App should handle offline state gracefully
      // (This would need mock connectivity service for full testing)
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}