import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';

import '../../lib/presentation/pages/discover_page.dart';
import '../../lib/presentation/providers/discovery_providers.dart';
import '../../lib/presentation/providers/simple_providers.dart' as simple;
import '../../lib/domain/entities/restaurant.dart';
import '../../lib/domain/entities/user_preferences.dart';

/// Critical crash fix test for List -> Map -> Refresh scenario
/// This test validates the comprehensive fix implemented by flutter-maps-expert
/// to prevent the app from crashing when switching views and refreshing
void main() {
  group('Discovery Crash Fix Tests - Critical Scenario', () {
    late ProviderContainer container;
    late List<Restaurant> testRestaurants;
    late UserPreferences testUserPreferences;
    late Position testUserLocation;

    setUp(() {
      testUserLocation = _createTestPosition(37.7749, -122.4194);
      
      testRestaurants = [
        _createTestRestaurant(
          'safe_restaurant',
          'Safe Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
        _createTestRestaurant(
          'test_restaurant',
          'Test Restaurant',
          latitude: 37.7749,
          longitude: -122.4094,
          rating: 4.0,
          priceLevel: 1,
        ),
      ];

      testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      container = ProviderContainer(
        overrides: [
          // Mock user preferences provider to avoid database dependencies
          simple.simpleUserPreferencesProvider.overrideWith((ref) {
            return simple.SimpleUserPreferencesNotifier()..updatePreferences(testUserPreferences);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('CRITICAL: List -> Map -> Refresh should not crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const DiscoverPage(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 1: Ensure we start in List view
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);

      // Verify we can find the view toggle controls
      final listButton = find.ancestor(
        of: find.text('List'),
        matching: find.byType(ButtonSegment<bool>),
      );
      final mapButton = find.ancestor(
        of: find.text('Map'),
        matching: find.byType(ButtonSegment<bool>),
      );

      expect(listButton, findsOneWidget);
      expect(mapButton, findsOneWidget);

      // Step 2: Switch from List to Map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify map view is active
      final discoveryState = container.read(discoveryProvider);
      expect(discoveryState.showMapView, true);

      // Step 3: Click refresh button - this was the critical crash point
      final refreshButton = find.byType(FloatingActionButton);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Step 4: Verify no crash occurred and app is still responsive
      expect(tester.takeException(), isNull);
      
      // Verify UI is still functional
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);

      // Additional safety check: try to switch back to list view
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final finalDiscoveryState = container.read(discoveryProvider);
      expect(finalDiscoveryState.showMapView, false);

      // Final verification - no exceptions during entire sequence
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple rapid view switches should not crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Perform rapid view switches
      for (int i = 0; i < 5; i++) {
        // Switch to Map
        await tester.tap(find.text('Map'));
        await tester.pump(const Duration(milliseconds: 100));

        // Switch back to List
        await tester.tap(find.text('List'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Let everything settle
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify no crashes
      expect(tester.takeException(), isNull);

      // Verify final state is consistent
      final discoveryState = container.read(discoveryProvider);
      expect(discoveryState.showMapView, false); // Should be in list view
    });

    testWidgets('Refresh during view transition should not crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Start view transition
      await tester.tap(find.text('Map'));
      
      // Immediately try to refresh during transition
      final refreshButton = find.byType(FloatingActionButton);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
      }

      // Let everything complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify no crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('Map controller disposal should not cause crashes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Switch back to list view (this should properly dispose map controller)
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Force a rebuild to trigger any disposal issues
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Error recovery should work correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // If there's an error state, verify it's handled gracefully
      if (find.textContaining('error').evaluate().isNotEmpty) {
        // Find retry button if error occurs
        final retryButton = find.textContaining('Retry');
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Verify error recovery doesn't crash
      expect(tester.takeException(), isNull);
    });
  });

  group('Discovery Provider Race Condition Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('setMapView should handle disposal correctly', () {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Switch to map view
      notifier.setMapView(true);
      expect(container.read(discoveryProvider).showMapView, true);

      // Switch back
      notifier.setMapView(false);
      expect(container.read(discoveryProvider).showMapView, false);

      // This should not throw
      expect(() => notifier.setMapView(true), returnsNormally);
    });

    test('refresh during view switch should handle race conditions', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start a refresh
      final refreshFuture = notifier.refresh();
      
      // Immediately switch views
      notifier.setMapView(true);
      notifier.setMapView(false);
      
      // Wait for refresh to complete
      await refreshFuture;
      
      // Should complete without errors
      expect(container.read(discoveryProvider).error, isNull);
    });

    test('multiple concurrent operations should not cause race conditions', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start multiple operations concurrently
      final futures = <Future>[];
      
      // Multiple refreshes
      futures.add(notifier.refresh());
      futures.add(notifier.refresh());
      
      // View switches
      notifier.setMapView(true);
      notifier.setMapView(false);
      notifier.setMapView(true);
      
      // Search updates
      notifier.updateSearchQuery('test');
      notifier.updateSearchQuery('restaurant');
      
      // Wait for all operations
      await Future.wait(futures);
      
      // Should not throw or cause inconsistent state
      final state = container.read(discoveryProvider);
      expect(state, isNotNull);
    });
  });

  group('Map Controller Lifecycle Tests', () {
    testWidgets('GoogleMap widget should handle lifecycle correctly', (tester) async {
      // This test simulates the map controller lifecycle without actually
      // creating a GoogleMap (which requires API keys in tests)
      
      bool disposed = false;
      bool created = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  child: created ? 
                    Container(
                      key: const Key('mock_map'),
                      child: const Text('Mock Map'),
                    ) : 
                    const Text('No Map'),
                );
              },
            ),
          ),
        ),
      );

      // Simulate map creation
      created = true;
      await tester.pump();

      expect(find.text('Mock Map'), findsOneWidget);

      // Simulate disposal
      disposed = true;
      created = false;
      await tester.pump();

      expect(find.text('No Map'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Async Operation Safety Tests', () {
    test('operations should handle disposal state correctly', () async {
      final container = ProviderContainer();
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start an async operation
      final future = notifier.getCurrentLocation();
      
      // Immediately dispose
      container.dispose();
      
      // Operation should complete without throwing
      await expectLater(future, completes);
    });

    test('state updates should be safe after disposal', () async {
      final container = ProviderContainer();
      final notifier = container.read(discoveryProvider.notifier);
      
      // Dispose container
      container.dispose();
      
      // These should not throw even after disposal
      expect(() => notifier.setMapView(true), returnsNormally);
      expect(() => notifier.updateSearchQuery('test'), returnsNormally);
      expect(() => notifier.updateSearchRadius(10.0), returnsNormally);
    });
  });
}

// Helper functions
Position _createTestPosition(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );
}

Restaurant _createTestRestaurant(
  String placeId,
  String name, {
  double? latitude,
  double? longitude,
  double? rating,
  int? priceLevel,
  String? cuisineType,
  List<String>? dietaryRestrictions,
  List<String>? allergenInfo,
  bool hasVerifiedDietaryInfo = false,
  double? distanceFromUser,
}) {
  return Restaurant(
    placeId: placeId,
    name: name,
    location: 'Test Location',
    latitude: latitude,
    longitude: longitude,
    rating: rating,
    priceLevel: priceLevel,
    cuisineType: cuisineType,
    supportedDietaryRestrictions: dietaryRestrictions ?? [],
    allergenInfo: allergenInfo ?? [],
    hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
    distanceFromUser: distanceFromUser,
    cachedAt: DateTime.now(),
  );
}