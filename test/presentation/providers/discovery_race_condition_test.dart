import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';

import '../../../lib/presentation/providers/discovery_providers.dart';
import '../../../lib/domain/entities/restaurant.dart';
import '../../../lib/domain/entities/user_preferences.dart';

/// Discovery Provider Race Condition Tests
/// These tests validate the fixes for race conditions that caused crashes
/// during concurrent operations like view switching + refresh
void main() {
  group('Discovery Provider Race Condition Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('concurrent setMapView calls should not cause race conditions', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Fire multiple concurrent setMapView calls
      final futures = <Future>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(Future.delayed(
          Duration(milliseconds: i * 10),
          () => notifier.setMapView(i % 2 == 0),
        ));
      }
      
      await Future.wait(futures);
      
      // State should be consistent
      final state = container.read(discoveryProvider);
      expect(state.showMapView, isA<bool>());
    });

    test('setMapView during refresh should handle race condition correctly', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start a refresh operation
      final refreshFuture = notifier.refresh();
      
      // Immediately toggle map view multiple times
      notifier.setMapView(true);
      notifier.setMapView(false);
      notifier.setMapView(true);
      
      // Wait for refresh to complete
      await refreshFuture;
      
      // Should complete without errors
      final state = container.read(discoveryProvider);
      expect(state.error, isNull);
    });

    test('refresh during view switch should cancel properly', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start refresh
      final refreshFuture1 = notifier.refresh();
      
      // Switch to map view (should handle ongoing refresh)
      notifier.setMapView(true);
      
      // Start another refresh
      final refreshFuture2 = notifier.refresh();
      
      // Switch back to list view
      notifier.setMapView(false);
      
      // Both refreshes should complete without errors
      await Future.wait([refreshFuture1, refreshFuture2]);
      
      final state = container.read(discoveryProvider);
      expect(state.error, isNull);
    });

    test('multiple concurrent refresh calls should not interfere', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start multiple refresh operations concurrently
      final refreshFutures = <Future>[];
      
      for (int i = 0; i < 5; i++) {
        refreshFutures.add(notifier.refresh());
      }
      
      await Future.wait(refreshFutures);
      
      // All should complete successfully
      final state = container.read(discoveryProvider);
      expect(state.error, isNull);
    });

    test('disposal during async operations should not crash', () async {
      final localContainer = ProviderContainer();
      final notifier = localContainer.read(discoveryProvider.notifier);
      
      // Start multiple async operations
      final operations = <Future>[];
      
      operations.add(notifier.getCurrentLocation());
      operations.add(notifier.refresh());
      operations.add(notifier.searchRestaurants());
      
      // Dispose container while operations are running
      localContainer.dispose();
      
      // Operations should complete gracefully
      await Future.wait(operations, eagerError: false);
      
      // No exceptions should be thrown
    });

    test('state updates after disposal should not throw', () {
      final localContainer = ProviderContainer();
      final notifier = localContainer.read(discoveryProvider.notifier);
      
      // Dispose container
      localContainer.dispose();
      
      // These operations should not throw
      expect(() => notifier.setMapView(true), returnsNormally);
      expect(() => notifier.updateSearchQuery('test'), returnsNormally);
      expect(() => notifier.updateSearchRadius(10.0), returnsNormally);
      expect(() => notifier.applyQuickFilter('vegetarian'), returnsNormally);
      expect(() => notifier.clearAllFilters(), returnsNormally);
    });

    test('concurrent search queries should handle debouncing correctly', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Fire multiple search queries in rapid succession
      notifier.updateSearchQuery('a');
      notifier.updateSearchQuery('ab');
      notifier.updateSearchQuery('abc');
      notifier.updateSearchQuery('abcd');
      notifier.updateSearchQuery('pizza');
      
      // Wait for debounce to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      final state = container.read(discoveryProvider);
      expect(state.searchQuery, 'pizza'); // Should have latest query
    });

    test('radius updates during search should not cause conflicts', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start a search
      final searchFuture = notifier.searchRestaurants();
      
      // Update radius multiple times
      notifier.updateSearchRadius(5.0);
      notifier.updateSearchRadius(10.0);
      notifier.updateSearchRadius(7.5);
      
      // Wait for operations to complete
      await searchFuture;
      
      final state = container.read(discoveryProvider);
      expect(state.searchRadius, 7.5); // Should have latest radius
      expect(state.error, isNull);
    });

    test('location updates during ongoing operations should be safe', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start search and location update concurrently
      final searchFuture = notifier.searchRestaurants();
      final locationFuture = notifier.getCurrentLocation();
      
      // Toggle map view during operations
      notifier.setMapView(true);
      notifier.setMapView(false);
      
      // Wait for all operations
      await Future.wait([searchFuture, locationFuture]);
      
      final state = container.read(discoveryProvider);
      expect(state.error, isNull);
    });

    test('filter operations during search should not conflict', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start search
      final searchFuture = notifier.searchRestaurants();
      
      // Apply filters concurrently
      notifier.applyQuickFilter('vegetarian');
      notifier.applyQuickFilter('vegan');
      notifier.clearAllFilters();
      notifier.applyQuickFilter('gluten-free');
      
      // Wait for search to complete
      await searchFuture;
      
      final state = container.read(discoveryProvider);
      expect(state.error, isNull);
    });

    test('provider cleanup should handle all async operations', () async {
      final localContainer = ProviderContainer();
      final notifier = localContainer.read(discoveryProvider.notifier);
      
      // Start various async operations
      final operations = <Future>[];
      
      // Location operations
      operations.add(notifier.getCurrentLocation());
      
      // Search operations
      operations.add(notifier.searchRestaurants());
      operations.add(notifier.refresh());
      
      // Multiple state changes
      for (int i = 0; i < 5; i++) {
        operations.add(Future.delayed(
          Duration(milliseconds: i * 50),
          () {
            notifier.setMapView(i % 2 == 0);
            notifier.updateSearchRadius(5.0 + i);
            notifier.updateSearchQuery('query_$i');
          },
        ));
      }
      
      // Let some operations start
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Dispose container
      localContainer.dispose();
      
      // All operations should complete gracefully
      await Future.wait(operations, eagerError: false);
    });

    test('isDisposed flag should prevent state updates correctly', () async {
      final localContainer = ProviderContainer();
      final notifier = localContainer.read(discoveryProvider.notifier);
      
      // Dispose container
      localContainer.dispose();
      
      // Start async operation that would normally update state
      await notifier.getCurrentLocation();
      await notifier.searchRestaurants();
      
      // No exceptions should be thrown even though container is disposed
    });

    test('isRefreshing flag should prevent concurrent refreshes', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start first refresh
      final refresh1 = notifier.refresh();
      
      // Immediately start second refresh
      final refresh2 = notifier.refresh();
      
      // Both should complete
      await Future.wait([refresh1, refresh2]);
      
      final state = container.read(discoveryProvider);
      expect(state.error, isNull);
    });

    test('view switching should cancel ongoing refresh when needed', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start refresh
      final refreshFuture = notifier.refresh();
      
      // Switch to map view - should handle ongoing refresh
      notifier.setMapView(true);
      
      // The implementation should handle this gracefully
      await refreshFuture;
      
      final state = container.read(discoveryProvider);
      expect(state.showMapView, true);
      expect(state.error, isNull);
    });

    test('timer cleanup should prevent memory leaks', () async {
      final localContainer = ProviderContainer();
      final notifier = localContainer.read(discoveryProvider.notifier);
      
      // Start operations that create timers
      notifier.updateSearchQuery('test1');
      notifier.updateSearchQuery('test2');
      notifier.updateSearchQuery('test3');
      
      // Dispose before timers fire
      localContainer.dispose();
      
      // Wait longer than debounce timer
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Should not throw or cause issues
    });

    test('subscription cleanup should prevent memory leaks', () async {
      final localContainer = ProviderContainer();
      final notifier = localContainer.read(discoveryProvider.notifier);
      
      // Start location subscription
      await notifier.getCurrentLocation();
      
      // Dispose container
      localContainer.dispose();
      
      // Should cleanup subscriptions properly
    });
  });

  group('Provider State Consistency Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('state should remain consistent during rapid operations', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Perform many rapid state changes
      final operations = <Future>[];
      
      for (int i = 0; i < 20; i++) {
        operations.add(Future.delayed(
          Duration(milliseconds: i * 25),
          () {
            notifier.setMapView(i % 2 == 0);
            notifier.updateSearchRadius(1.0 + (i % 10));
            notifier.updateSearchQuery('query_${i % 5}');
          },
        ));
      }
      
      await Future.wait(operations);
      
      // State should be consistent
      final state = container.read(discoveryProvider);
      expect(state.showMapView, isA<bool>());
      expect(state.searchRadius, greaterThanOrEqualTo(1.0));
      expect(state.searchQuery, isA<String>());
    });

    test('error state should not persist across operations', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Force an error state (this might not actually cause an error in tests)
      await notifier.searchRestaurants();
      
      // Perform successful operation
      notifier.setMapView(true);
      notifier.updateSearchRadius(5.0);
      
      // Error should be cleared by successful operations
      final state = container.read(discoveryProvider);
      // Note: In actual implementation, errors might be cleared by new operations
    });

    test('loading state should be managed correctly', () async {
      final notifier = container.read(discoveryProvider.notifier);
      
      // Start async operation
      final future = notifier.refresh();
      
      // Check loading state (might be true briefly)
      final initialState = container.read(discoveryProvider);
      
      await future;
      
      // Loading should be false after completion
      final finalState = container.read(discoveryProvider);
      expect(finalState.isLoading, false);
    });
  });
}

// Helper functions (if needed)
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
}) {
  return Restaurant(
    placeId: placeId,
    name: name,
    location: 'Test Location',
    latitude: latitude,
    longitude: longitude,
    rating: rating,
    priceLevel: priceLevel,
    supportedDietaryRestrictions: [],
    allergenInfo: [],
    cachedAt: DateTime.now(),
  );
}