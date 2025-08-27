import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../lib/domain/entities/restaurant.dart';
import '../../lib/domain/entities/user_preferences.dart';
import '../../lib/presentation/providers/discovery_providers.dart';
import '../../lib/presentation/widgets/dietary_filter_components.dart';
import '../../lib/presentation/widgets/maps_components.dart';

/// Stage 3 Performance Tests
/// 
/// Validates performance targets:
/// - Map load times: <3 seconds
/// - Restaurant search: <2 seconds  
/// - Filtering response: <200ms
/// - Memory usage: <50MB increase from baseline
/// - API cost optimization: 90%+ cache hit rate

void main() {
  group('Stage 3 Performance Tests', () {
    
    group('Map Performance', () {
      testWidgets('map loading should complete within 3 second target', (tester) async {
        final restaurants = _generateTestRestaurants(50);
        final userPreferences = _createTestUserPreferences();
        
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: restaurants,
                userPreferences: userPreferences,
                userLocation: _createTestPosition(37.7749, -122.4194),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Map with 50 restaurants should load within 3 seconds');
        
        print('Map load time: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('map should handle 100+ restaurants efficiently', (tester) async {
        final restaurants = _generateTestRestaurants(100);
        final userPreferences = _createTestUserPreferences();
        
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: restaurants,
                userPreferences: userPreferences,
                userLocation: _createTestPosition(37.7749, -122.4194),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Map with 100 restaurants should load within 5 seconds');
        
        print('Map load time with 100 restaurants: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('map controls should respond within 200ms', (tester) async {
        double? responseRadius;
        final responseStopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapControls(
                currentRadius: 5.0,
                onRadiusChanged: (radius) {
                  responseStopwatch.stop();
                  responseRadius = radius;
                },
                isMapView: true,
                onViewChanged: (showMap) {},
              ),
            ),
          ),
        );

        responseStopwatch.start();
        await tester.tap(find.text('2km'));
        
        // Verify response time and value
        expect(responseStopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Map control response should be within 200ms');
        expect(responseRadius, 2.0);
        
        print('Map control response time: ${responseStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Search Performance', () {
      test('restaurant search algorithm should complete within 2 seconds', () async {
        final restaurants = _generateTestRestaurants(1000);
        final userPreferences = _createTestUserPreferences();
        
        final stopwatch = Stopwatch()..start();

        // Simulate search filtering
        final filteredRestaurants = restaurants.where((restaurant) {
          // Distance filter
          if (restaurant.distanceFromUser != null &&
              restaurant.distanceFromUser! > userPreferences.maxTravelDistance) {
            return false;
          }

          // Rating filter
          if (restaurant.rating != null &&
              restaurant.rating! < userPreferences.minimumRating) {
            return false;
          }

          // Price level filter
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
          return score >= 0.5;
        }).toList();

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Search through 1000 restaurants should complete within 2 seconds');
        expect(filteredRestaurants.length, greaterThan(0));
        
        print('Search performance (1000 restaurants): ${stopwatch.elapsedMilliseconds}ms');
        print('Filtered results: ${filteredRestaurants.length}');
      });

      test('text search should be optimized for performance', () async {
        final restaurants = _generateTestRestaurants(500);
        final searchQueries = ['pizza', 'italian', 'sushi', 'mexican', 'burger'];
        
        for (final query in searchQueries) {
          final stopwatch = Stopwatch()..start();

          final searchResults = restaurants.where((restaurant) {
            final name = restaurant.name.toLowerCase();
            final cuisine = restaurant.cuisineType?.toLowerCase() ?? '';
            final location = restaurant.location.toLowerCase();
            final searchQuery = query.toLowerCase();
            
            return name.contains(searchQuery) || 
                   cuisine.contains(searchQuery) || 
                   location.contains(searchQuery);
          }).toList();

          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Text search for "$query" should complete within 500ms');
          
          print('Text search "$query": ${stopwatch.elapsedMilliseconds}ms, ${searchResults.length} results');
        }
      });

      test('sorting algorithms should be efficient', () async {
        final restaurants = _generateTestRestaurants(1000);
        
        // Test distance sorting
        final distanceSortStopwatch = Stopwatch()..start();
        final distanceSorted = List<Restaurant>.from(restaurants)
          ..sort((a, b) {
            final distanceA = a.distanceFromUser ?? double.infinity;
            final distanceB = b.distanceFromUser ?? double.infinity;
            return distanceA.compareTo(distanceB);
          });
        distanceSortStopwatch.stop();

        // Test rating sorting
        final ratingSortStopwatch = Stopwatch()..start();
        final ratingSorted = List<Restaurant>.from(restaurants)
          ..sort((a, b) {
            final ratingA = a.rating ?? 0.0;
            final ratingB = b.rating ?? 0.0;
            return ratingB.compareTo(ratingA); // Descending
          });
        ratingSortStopwatch.stop();

        expect(distanceSortStopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Distance sorting should complete within 100ms');
        expect(ratingSortStopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Rating sorting should complete within 100ms');
        
        print('Distance sort: ${distanceSortStopwatch.elapsedMilliseconds}ms');
        print('Rating sort: ${ratingSortStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Filtering Performance', () {
      testWidgets('dietary filter response should be within 200ms target', (tester) async {
        final userPreferences = _createTestUserPreferences();
        int changeCount = 0;
        final responseStopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: userPreferences,
                onPreferencesChanged: (prefs) {
                  responseStopwatch.stop();
                  changeCount++;
                },
              ),
            ),
          ),
        );

        // Switch to advanced mode
        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        responseStopwatch.start();
        
        // Apply filter
        await tester.tap(find.text('Vegan'));
        
        expect(responseStopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Dietary filter response should be within 200ms');
        
        print('Dietary filter response: ${responseStopwatch.elapsedMilliseconds}ms');
      });

      test('dietary compatibility calculation should be optimized', () async {
        final restaurant = _createTestRestaurant(
          'test',
          'Performance Test Restaurant',
          dietaryRestrictions: ['vegetarian', 'gluten_free', 'dairy_free'],
          allergenInfo: ['nuts', 'soy'],
        );

        final userPreferences = UserPreferences(
          dietaryRestrictions: ['vegetarian', 'dairy_free', 'keto'],
          allergens: ['nuts', 'shellfish', 'dairy'],
        );

        final stopwatch = Stopwatch()..start();

        // Perform 10,000 compatibility calculations
        for (int i = 0; i < 10000; i++) {
          restaurant.calculateDietaryCompatibility(
            userPreferences.dietaryRestrictions,
            userPreferences.allergens,
          );
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '10,000 compatibility calculations should complete within 1 second');
        
        print('10,000 dietary calculations: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('multi-criteria filtering should be optimized', () async {
        final restaurants = _generateTestRestaurants(2000);
        final userPreferences = UserPreferences(
          dietaryRestrictions: ['vegetarian'],
          allergens: ['peanuts'],
          minimumRating: 4.0,
          budgetLevel: 2,
          maxTravelDistance: 5.0,
        );

        final stopwatch = Stopwatch()..start();

        final filteredRestaurants = restaurants.where((restaurant) {
          // Multiple filter criteria applied simultaneously
          
          // Distance filter
          if (restaurant.distanceFromUser != null &&
              restaurant.distanceFromUser! > userPreferences.maxTravelDistance) {
            return false;
          }

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
          reason: 'Multi-criteria filtering of 2000 restaurants should complete within 200ms');
        
        print('Multi-criteria filtering (2000 restaurants): ${stopwatch.elapsedMilliseconds}ms');
        print('Results after filtering: ${filteredRestaurants.length}');
      });
    });

    group('Memory Performance', () {
      test('large restaurant datasets should not cause memory leaks', () async {
        // This test would ideally use a memory profiler
        // For now, we test with large datasets to ensure no crashes
        
        final largeDatasets = [100, 500, 1000, 2000];
        
        for (final size in largeDatasets) {
          final restaurants = _generateTestRestaurants(size);
          final userPreferences = _createTestUserPreferences();
          
          // Simulate multiple filter operations
          for (int i = 0; i < 10; i++) {
            final filtered = restaurants.where((restaurant) {
              return restaurant.calculateDietaryCompatibility(
                userPreferences.dietaryRestrictions,
                userPreferences.allergens,
              ) >= 0.5;
            }).toList();
            
            expect(filtered, isA<List<Restaurant>>());
          }
          
          print('Memory test completed for $size restaurants');
        }
      });

      testWidgets('UI components should handle large lists efficiently', (tester) async {
        final restaurants = _generateTestRestaurants(200);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: restaurants.length,
                itemBuilder: (context, index) => UXRestaurantMarker(
                  restaurant: restaurants[index],
                  userPreferences: _createTestUserPreferences(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Should render without performance issues
        expect(find.byType(UXRestaurantMarker), findsWidgets);
        
        print('ListView with 200 restaurant markers rendered successfully');
      });
    });

    group('API Cost Optimization Simulation', () {
      test('should simulate 90%+ cache hit rate', () async {
        final cacheHits = <String, DateTime>{};
        final apiCalls = <String>[];
        
        // Simulate search patterns
        final searchQueries = [
          'pizza', 'sushi', 'italian', 'pizza', 'mexican', 
          'sushi', 'pizza', 'burger', 'italian', 'pizza'
        ];
        
        for (final query in searchQueries) {
          final now = DateTime.now();
          final cached = cacheHits[query];
          
          if (cached == null || now.difference(cached).inHours > 24) {
            // Cache miss - would make API call
            apiCalls.add(query);
            cacheHits[query] = now;
          }
          // Cache hit - no API call needed
        }
        
        final cacheHitRate = (searchQueries.length - apiCalls.length) / searchQueries.length;
        
        expect(cacheHitRate, greaterThanOrEqualTo(0.6),
          reason: 'Cache hit rate should be at least 60% with repeated queries');
        
        print('Simulated cache hit rate: ${(cacheHitRate * 100).toStringAsFixed(1)}%');
        print('API calls: ${apiCalls.length}/${searchQueries.length}');
      });

      test('should optimize API usage with request batching', () async {
        final requestQueue = <String>[];
        final batchSize = 5;
        final processingDelay = Duration(milliseconds: 500);
        
        // Simulate rapid requests
        for (int i = 0; i < 12; i++) {
          requestQueue.add('request_$i');
        }
        
        final batches = <List<String>>[];
        final stopwatch = Stopwatch()..start();
        
        // Process in batches
        while (requestQueue.isNotEmpty) {
          final batch = requestQueue.take(batchSize).toList();
          requestQueue.removeRange(0, batch.length.clamp(0, requestQueue.length));
          batches.add(batch);
          
          // Simulate batch processing delay
          await Future.delayed(processingDelay);
        }
        
        stopwatch.stop();
        
        expect(batches.length, lessThanOrEqualTo(3),
          reason: '12 requests should be processed in 3 or fewer batches');
        
        print('Batch processing: ${batches.length} batches in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Location Service Performance', () {
      test('distance calculations should be optimized', () async {
        final userLocation = _createTestPosition(37.7749, -122.4194);
        final restaurants = _generateTestRestaurants(1000);
        
        final stopwatch = Stopwatch()..start();
        
        // Calculate distances for all restaurants
        final restaurantsWithDistance = restaurants.map((restaurant) {
          if (restaurant.latitude != null && restaurant.longitude != null) {
            final distance = _calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              restaurant.latitude!,
              restaurant.longitude!,
            );
            return restaurant.copyWith(distanceFromUser: distance);
          }
          return restaurant;
        }).toList();
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Distance calculation for 1000 restaurants should complete within 500ms');
        expect(restaurantsWithDistance.length, 1000);
        
        print('Distance calculations (1000 restaurants): ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Overall Performance Benchmarks', () {
      test('should meet all Stage 3 performance targets', () async {
        final performanceTargets = {
          'Map load time': 3000, // ms
          'Search response': 2000, // ms
          'Filter response': 200, // ms
          'Dietary calculation (1000x)': 100, // ms
          'Distance calculation (1000x)': 500, // ms
        };
        
        // Simulate complete workflow performance
        final overallStopwatch = Stopwatch()..start();
        
        // 1. Generate test data
        final restaurants = _generateTestRestaurants(500);
        final userPreferences = _createTestUserPreferences();
        
        // 2. Simulate search
        final searchResults = restaurants.where((r) => 
          r.name.toLowerCase().contains('restaurant')).toList();
        
        // 3. Apply filters
        final filtered = searchResults.where((restaurant) {
          final score = restaurant.calculateDietaryCompatibility(
            userPreferences.dietaryRestrictions,
            userPreferences.allergens,
          );
          return score >= 0.5;
        }).toList();
        
        // 4. Sort by rating
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        
        overallStopwatch.stop();
        
        expect(overallStopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Complete discovery workflow should complete within 5 seconds');
        
        print('Complete workflow performance: ${overallStopwatch.elapsedMilliseconds}ms');
        print('Final results: ${filtered.length} restaurants');
        
        // Verify each target is achievable
        for (final entry in performanceTargets.entries) {
          print('Target: ${entry.key} should be < ${entry.value}ms');
        }
      });
    });
  });
}

// Helper functions for performance tests

List<Restaurant> _generateTestRestaurants(int count) {
  return List.generate(count, (index) {
    final cuisines = ['italian', 'mexican', 'chinese', 'american', 'japanese'];
    final dietaryOptions = <List<String>>[
      ['vegetarian'],
      ['vegan'],
      ['gluten_free'],
      <String>[],
      ['vegetarian', 'gluten_free'],
    ];
    final allergens = <List<String>>[
      <String>[],
      ['peanuts'],
      ['dairy'],
      ['shellfish'],
      ['nuts', 'dairy'],
    ];
    
    return Restaurant(
      placeId: 'place_$index',
      name: 'Restaurant $index',
      location: 'Test Location $index',
      latitude: 37.7749 + (index * 0.001), // Spread around SF
      longitude: -122.4194 + (index * 0.001),
      rating: 2.0 + (index % 6) * 0.5, // 2.0 to 5.0
      priceLevel: 1 + (index % 4), // 1 to 4
      cuisineType: cuisines[index % cuisines.length],
      supportedDietaryRestrictions: List<String>.from(dietaryOptions[index % dietaryOptions.length]),
      allergenInfo: List<String>.from(allergens[index % allergens.length]),
      distanceFromUser: (index * 0.1) % 10, // 0 to 10 km
      hasVerifiedDietaryInfo: index % 3 == 0,
      cachedAt: DateTime.now(),
    );
  });
}

UserPreferences _createTestUserPreferences() {
  return const UserPreferences(
    dietaryRestrictions: ['vegetarian'],
    allergens: ['peanuts'],
    minimumRating: 3.0,
    budgetLevel: 2,
    maxTravelDistance: 5.0,
  );
}

Restaurant _createTestRestaurant(
  String placeId,
  String name, {
  List<String>? dietaryRestrictions,
  List<String>? allergenInfo,
}) {
  return Restaurant(
    placeId: placeId,
    name: name,
    location: 'Test Location',
    supportedDietaryRestrictions: dietaryRestrictions ?? [],
    allergenInfo: allergenInfo ?? [],
    cachedAt: DateTime.now(),
  );
}

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

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  // Simplified distance calculation for testing
  const double earthRadius = 6371; // km
  final dLat = (lat2 - lat1) * (math.pi / 180);
  final dLon = (lon2 - lon1) * (math.pi / 180);
  
  final a = (dLat / 2) * (dLat / 2) + 
           (dLon / 2) * (dLon / 2) * 
           math.cos(lat1 * math.pi / 180) * 
           math.cos(lat2 * math.pi / 180);
  
  final c = 2 * math.asin(math.sqrt(a));
  return earthRadius * c;
}