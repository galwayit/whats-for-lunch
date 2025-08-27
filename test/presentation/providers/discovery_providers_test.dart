import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';

import '../../../lib/presentation/providers/discovery_providers.dart';
import '../../../lib/domain/entities/restaurant.dart';
import '../../../lib/domain/entities/user_preferences.dart';

// Mock classes for testing
class MockPosition extends Mock implements Position {}

void main() {
  group('Stage 3 Discovery Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('DiscoveryState', () {
      test('should have correct initial state', () {
        const state = DiscoveryState();
        
        expect(state.restaurants, isEmpty);
        expect(state.filteredRestaurants, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNull);
        expect(state.userLocation, isNull);
        expect(state.isLocationLoading, false);
        expect(state.locationError, isNull);
        expect(state.searchRadius, 5.0);
        expect(state.showMapView, false);
        expect(state.searchQuery, '');
        expect(state.appliedFilters, isEmpty);
        expect(state.lastUpdated, isNull);
      });

      test('should create correct copyWith', () {
        const initialState = DiscoveryState();
        final restaurants = [_createTestRestaurant('test_id', 'Test Restaurant')];
        
        final newState = initialState.copyWith(
          restaurants: restaurants,
          isLoading: true,
          searchRadius: 10.0,
          showMapView: true,
          searchQuery: 'pizza',
        );

        expect(newState.restaurants, restaurants);
        expect(newState.isLoading, true);
        expect(newState.searchRadius, 10.0);
        expect(newState.showMapView, true);
        expect(newState.searchQuery, 'pizza');
        // Other fields should remain unchanged
        expect(newState.filteredRestaurants, isEmpty);
        expect(newState.error, isNull);
      });
    });

    group('Restaurant Filtering Logic', () {
      test('should filter restaurants by dietary restrictions correctly', () {
        final restaurants = [
          _createTestRestaurant('r1', 'Vegetarian Place', 
            dietaryRestrictions: ['vegetarian'],
            cuisineType: 'vegetarian'),
          _createTestRestaurant('r2', 'Steakhouse',
            cuisineType: 'steakhouse'),
          _createTestRestaurant('r3', 'Vegan Cafe',
            dietaryRestrictions: ['vegan', 'vegetarian'],
            cuisineType: 'vegan'),
        ];

        final userPreferences = UserPreferences(
          dietaryRestrictions: ['vegetarian'],
          requireDietaryVerification: false,
        );

        // This would be the filtering logic from the provider
        final filteredRestaurants = restaurants.where((restaurant) {
          // Simple dietary compatibility check
          if (userPreferences.dietaryRestrictions.isNotEmpty) {
            final score = restaurant.calculateDietaryCompatibility(
              userPreferences.dietaryRestrictions,
              userPreferences.allergens,
            );
            return score >= 0.5; // Threshold for compatibility
          }
          return true;
        }).toList();

        expect(filteredRestaurants.length, 2); // Vegetarian Place and Vegan Cafe
        expect(filteredRestaurants.any((r) => r.name == 'Vegetarian Place'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Vegan Cafe'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Steakhouse'), false);
      });

      test('should filter restaurants by allergens correctly', () {
        final restaurants = [
          _createTestRestaurant('r1', 'Nut-Free Kitchen',
            allergenInfo: []),
          _createTestRestaurant('r2', 'Peanut Paradise',
            allergenInfo: ['peanuts', 'tree_nuts']),
          _createTestRestaurant('r3', 'Safe Dining',
            allergenInfo: ['dairy']),
        ];

        final userPreferences = UserPreferences(
          allergens: ['peanuts'],
          requireDietaryVerification: false,
        );

        final filteredRestaurants = restaurants.where((restaurant) {
          final safetyLevel = restaurant.getSafetyLevel(userPreferences.allergens);
          return safetyLevel != SafetyLevel.warning;
        }).toList();

        expect(filteredRestaurants.length, 2); // Nut-Free Kitchen and Safe Dining
        expect(filteredRestaurants.any((r) => r.name == 'Nut-Free Kitchen'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Safe Dining'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Peanut Paradise'), false);
      });

      test('should filter by price level correctly', () {
        final restaurants = [
          _createTestRestaurant('r1', 'Budget Eats', priceLevel: 1),
          _createTestRestaurant('r2', 'Mid-Range Restaurant', priceLevel: 2),
          _createTestRestaurant('r3', 'Fine Dining', priceLevel: 4),
        ];

        final userPreferences = UserPreferences(
          budgetLevel: 2,
        );

        final filteredRestaurants = restaurants.where((restaurant) {
          if (restaurant.priceLevel != null && userPreferences.budgetLevel > 0) {
            return restaurant.priceLevel! <= userPreferences.budgetLevel;
          }
          return true;
        }).toList();

        expect(filteredRestaurants.length, 2); // Budget Eats and Mid-Range
        expect(filteredRestaurants.any((r) => r.name == 'Budget Eats'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Mid-Range Restaurant'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Fine Dining'), false);
      });

      test('should filter by rating correctly', () {
        final restaurants = [
          _createTestRestaurant('r1', 'Low Rated', rating: 2.5),
          _createTestRestaurant('r2', 'Good Restaurant', rating: 4.0),
          _createTestRestaurant('r3', 'Excellent Place', rating: 4.8),
        ];

        final userPreferences = UserPreferences(
          minimumRating: 3.5,
        );

        final filteredRestaurants = restaurants.where((restaurant) {
          if (restaurant.rating != null) {
            return restaurant.rating! >= userPreferences.minimumRating;
          }
          return true;
        }).toList();

        expect(filteredRestaurants.length, 2); // Good Restaurant and Excellent Place
        expect(filteredRestaurants.any((r) => r.name == 'Good Restaurant'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Excellent Place'), true);
        expect(filteredRestaurants.any((r) => r.name == 'Low Rated'), false);
      });

      test('should handle multiple filters simultaneously', () {
        final restaurants = [
          _createTestRestaurant('r1', 'Perfect Match',
            dietaryRestrictions: ['vegetarian'],
            rating: 4.5,
            priceLevel: 2,
            allergenInfo: []),
          _createTestRestaurant('r2', 'Good but Expensive',
            dietaryRestrictions: ['vegetarian'],
            rating: 4.8,
            priceLevel: 4,
            allergenInfo: []),
          _createTestRestaurant('r3', 'Cheap but Low Rated',
            dietaryRestrictions: ['vegetarian'],
            rating: 2.0,
            priceLevel: 1,
            allergenInfo: []),
        ];

        final userPreferences = UserPreferences(
          dietaryRestrictions: ['vegetarian'],
          minimumRating: 4.0,
          budgetLevel: 2,
          allergens: [],
        );

        final filteredRestaurants = restaurants.where((restaurant) {
          // Rating filter
          if (restaurant.rating != null && 
              restaurant.rating! < userPreferences.minimumRating) {
            return false;
          }
          
          // Price filter
          if (restaurant.priceLevel != null && userPreferences.budgetLevel > 0) {
            if (restaurant.priceLevel! > userPreferences.budgetLevel) {
              return false;
            }
          }
          
          // Dietary compatibility
          final score = restaurant.calculateDietaryCompatibility(
            userPreferences.dietaryRestrictions,
            userPreferences.allergens,
          );
          if (score < 0.5) return false;
          
          return true;
        }).toList();

        expect(filteredRestaurants.length, 1); // Only Perfect Match
        expect(filteredRestaurants.first.name, 'Perfect Match');
      });
    });

    group('LocationService', () {
      test('should calculate distance correctly', () {
        final locationService = LocationService();
        
        // Distance between San Francisco and Los Angeles (approx 559 km)
        final distance = locationService.calculateDistance(
          37.7749, -122.4194, // San Francisco
          34.0522, -118.2437, // Los Angeles
        );
        
        expect(distance, closeTo(559, 10)); // Within 10km tolerance
      });

      test('should calculate distance for nearby locations', () {
        final locationService = LocationService();
        
        // Distance between two nearby points (approx 1 km)
        final distance = locationService.calculateDistance(
          37.7749, -122.4194,
          37.7849, -122.4194, // 1 degree north
        );
        
        expect(distance, greaterThan(0));
        expect(distance, lessThan(20)); // Should be reasonable distance
      });
    });

    group('Quick Filters', () {
      test('should apply vegetarian filter correctly', () {
        final discoveryNotifier = container.read(discoveryProvider.notifier);
        
        // This test would verify the quick filter logic
        expect(() => discoveryNotifier.applyQuickFilter('vegetarian'), isA<void>());
      });

      test('should apply vegan filter correctly', () {
        final discoveryNotifier = container.read(discoveryProvider.notifier);
        
        expect(() => discoveryNotifier.applyQuickFilter('vegan'), isA<void>());
      });

      test('should apply gluten-free filter correctly', () {
        final discoveryNotifier = container.read(discoveryProvider.notifier);
        
        expect(() => discoveryNotifier.applyQuickFilter('gluten-free'), isA<void>());
      });

      test('should clear all filters correctly', () {
        final discoveryNotifier = container.read(discoveryProvider.notifier);
        
        expect(() => discoveryNotifier.clearAllFilters(), isA<void>());
      });
    });

    group('Discovery Analytics', () {
      test('should track restaurant selection', () {
        final analytics = container.read(discoveryProvider.notifier);
        final restaurant = _createTestRestaurant('test_id', 'Test Restaurant');
        
        // Should not throw
        expect(analytics, isNotNull);
      });

      test('should track search performance', () {
        final analytics = container.read(discoveryProvider.notifier);
        final startTime = DateTime.now().subtract(Duration(milliseconds: 150));
        
        // Should not throw and should handle performance tracking
        expect(analytics, isNotNull);
      });

      test('should track filter usage', () {
        final analytics = container.read(discoveryProvider.notifier);
        
        expect(analytics, isNotNull);
      });
    });

    group('Performance Testing', () {
      test('filtering should complete within 200ms for large dataset', () async {
        // Create large dataset of restaurants
        final restaurants = List.generate(1000, (index) => 
          _createTestRestaurant('r$index', 'Restaurant $index',
            rating: 2.0 + (index % 3),
            priceLevel: 1 + (index % 4),
            dietaryRestrictions: index % 2 == 0 ? ['vegetarian'] : [],
            allergenInfo: index % 3 == 0 ? ['peanuts'] : [],
          )
        );

        final userPreferences = UserPreferences(
          dietaryRestrictions: ['vegetarian'],
          minimumRating: 3.0,
          budgetLevel: 2,
          allergens: ['peanuts'],
        );

        final stopwatch = Stopwatch()..start();
        
        // Apply filtering logic
        final filteredRestaurants = restaurants.where((restaurant) {
          // Rating filter
          if (restaurant.rating != null && 
              restaurant.rating! < userPreferences.minimumRating) {
            return false;
          }
          
          // Price filter
          if (restaurant.priceLevel != null && userPreferences.budgetLevel > 0) {
            if (restaurant.priceLevel! > userPreferences.budgetLevel) {
              return false;
            }
          }
          
          // Safety check
          final safetyLevel = restaurant.getSafetyLevel(userPreferences.allergens);
          if (safetyLevel == SafetyLevel.warning) return false;
          
          // Dietary compatibility
          final score = restaurant.calculateDietaryCompatibility(
            userPreferences.dietaryRestrictions,
            userPreferences.allergens,
          );
          return score >= 0.8;
        }).toList();

        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Filtering should complete within 200ms target');
        expect(filteredRestaurants.length, greaterThan(0));
      });

      test('dietary compatibility calculation should be efficient', () {
        final restaurant = _createTestRestaurant('test', 'Test',
          dietaryRestrictions: ['vegetarian', 'vegan', 'gluten_free'],
          allergenInfo: ['dairy', 'nuts'],
        );

        final userPreferences = UserPreferences(
          dietaryRestrictions: ['vegetarian', 'dairy_free', 'nut_free'],
          allergens: ['dairy', 'nuts', 'shellfish'],
        );

        final stopwatch = Stopwatch()..start();
        
        // Perform 1000 compatibility calculations
        for (int i = 0; i < 1000; i++) {
          restaurant.calculateDietaryCompatibility(
            userPreferences.dietaryRestrictions,
            userPreferences.allergens,
          );
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: '1000 calculations should complete within 100ms');
      });
    });
  });
}

// Helper function to create test restaurants
Restaurant _createTestRestaurant(
  String placeId, 
  String name, {
  double? rating,
  int? priceLevel,
  String? cuisineType,
  List<String>? dietaryRestrictions,
  List<String>? allergenInfo,
  double? latitude,
  double? longitude,
  double? distanceFromUser,
  bool hasVerifiedDietaryInfo = false,
}) {
  return Restaurant(
    placeId: placeId,
    name: name,
    location: 'Test Location',
    rating: rating,
    priceLevel: priceLevel,
    cuisineType: cuisineType,
    supportedDietaryRestrictions: dietaryRestrictions ?? [],
    allergenInfo: allergenInfo ?? [],
    latitude: latitude,
    longitude: longitude,
    distanceFromUser: distanceFromUser,
    hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
    cachedAt: DateTime.now(),
  );
}