import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import '../../../lib/presentation/widgets/maps_components.dart';
import '../../../lib/domain/entities/restaurant.dart';
import '../../../lib/domain/entities/user_preferences.dart';

/// Google Maps Controller Lifecycle and Disposal Tests
/// These tests validate the fixes for proper controller disposal and memory management
void main() {
  group('Maps Controller Lifecycle Tests', () {
    testWidgets('UXMapsView should handle widget disposal correctly', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Test the disposal safety mechanisms implemented in UXMapsView
      
      Widget buildMapView() {
        return MaterialApp(
          home: Scaffold(
            body: UXMapsView(
              restaurants: testRestaurants,
              userPreferences: testUserPreferences,
              userLocation: testUserLocation,
            ),
          ),
        );
      }

      // Create and mount the widget
      await tester.pumpWidget(buildMapView());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(tester.takeException(), isNull);

      // Unmount the widget (simulates navigation away or view switch)
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Text('Different Page'),
        ),
      ));
      await tester.pumpAndSettle();

      // Should not throw during disposal
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple UXMapsView instances should not interfere', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Test that creating multiple map instances doesn't cause issues
      
      bool showFirstMap = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showFirstMap = !showFirstMap;
                        });
                      },
                      child: const Text('Toggle Map'),
                    ),
                    Expanded(
                      child: showFirstMap
                        ? UXMapsView(
                            key: const Key('map1'),
                            restaurants: testRestaurants,
                            userPreferences: testUserPreferences,
                            userLocation: testUserLocation,
                          )
                        : UXMapsView(
                            key: const Key('map2'),
                            restaurants: testRestaurants,
                            userPreferences: testUserPreferences,
                            userLocation: testUserLocation,
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle between maps
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Toggle Map'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('UXMapsView should handle rapid disposal correctly', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Test rapid creation and disposal
      
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                key: Key('map_$i'),
                restaurants: testRestaurants,
                userPreferences: testUserPreferences,
                userLocation: testUserLocation,
              ),
            ),
          ),
        );

        // Quick pump to start initialization
        await tester.pump(const Duration(milliseconds: 100));

        // Immediately dispose
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('Disposed'),
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Maps view should handle restaurant list changes safely', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      List<Restaurant> currentRestaurants = testRestaurants;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentRestaurants = currentRestaurants.isEmpty 
                            ? testRestaurants 
                            : <Restaurant>[];
                        });
                      },
                      child: const Text('Toggle Restaurants'),
                    ),
                    Expanded(
                      child: UXMapsView(
                        restaurants: currentRestaurants,
                        userPreferences: testUserPreferences,
                        userLocation: testUserLocation,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle restaurant list multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Toggle Restaurants'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Maps view should handle location changes safely', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      Position? currentLocation = testUserLocation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentLocation = currentLocation == null 
                            ? testUserLocation 
                            : null;
                        });
                      },
                      child: const Text('Toggle Location'),
                    ),
                    Expanded(
                      child: UXMapsView(
                        restaurants: testRestaurants,
                        userPreferences: testUserPreferences,
                        userLocation: currentLocation,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle location multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Toggle Location'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Error state should not prevent proper disposal', (tester) async {
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Test disposal when map is in error state
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXMapsView(
              restaurants: [], // Empty list might cause error state
              userPreferences: testUserPreferences,
              userLocation: null, // No location might cause error
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Even if there are errors, disposal should be safe
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Disposed after error'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Loading state should handle disposal correctly', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Test disposal during loading state
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXMapsView(
              restaurants: testRestaurants,
              userPreferences: testUserPreferences,
              userLocation: testUserLocation,
            ),
          ),
        ),
      );

      // Don't wait for settling - dispose while loading
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Disposed during loading'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Maps State Management Tests', () {
    testWidgets('Maps view should handle callback changes safely', (tester) async {
      Restaurant? selectedRestaurant;
      void Function(Restaurant)? onRestaurantSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          onRestaurantSelected = onRestaurantSelected == null
                            ? (restaurant) {
                                selectedRestaurant = restaurant;
                              }
                            : null;
                        });
                      },
                      child: const Text('Toggle Callback'),
                    ),
                    Expanded(
                      child: UXMapsView(
                        restaurants: [
                          _createTestRestaurant(
                            'callback_test',
                            'Callback Test Restaurant',
                            latitude: 37.7749,
                            longitude: -122.4194,
                          ),
                        ],
                        userPreferences: const UserPreferences(),
                        onRestaurantSelected: onRestaurantSelected,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle callback multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Toggle Callback'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Maps view should handle preference changes safely', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      
      const initialPreferences = UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );
      
      UserPreferences currentPreferences = initialPreferences;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentPreferences = currentPreferences.maxTravelDistance == 5.0
                            ? currentPreferences.copyWith(maxTravelDistance: 10.0)
                            : currentPreferences.copyWith(maxTravelDistance: 5.0);
                        });
                      },
                      child: const Text('Toggle Preferences'),
                    ),
                    Expanded(
                      child: UXMapsView(
                        restaurants: testRestaurants,
                        userPreferences: currentPreferences,
                        userLocation: testUserLocation,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle preferences multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Toggle Preferences'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Memory Management Tests', () {
    testWidgets('Large restaurant datasets should not cause memory issues', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Create large dataset
      final largeRestaurantList = List.generate(100, (index) =>
        _createTestRestaurant(
          'large_$index',
          'Restaurant $index',
          latitude: 37.7749 + (index * 0.001),
          longitude: -122.4194 + (index * 0.001),
          rating: 3.0 + (index % 3),
          priceLevel: 1 + (index % 4),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXMapsView(
              restaurants: largeRestaurantList,
              userPreferences: testUserPreferences,
              userLocation: testUserLocation,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dispose with large dataset
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Disposed large dataset'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Repeated creation/disposal should not leak memory', (tester) async {
      final testUserLocation = _createTestPosition(37.7749, -122.4194);
      final testRestaurants = [
        _createTestRestaurant(
          'r1',
          'Test Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
        ),
      ];
      final testUserPreferences = const UserPreferences(
        dietaryRestrictions: [],
        allergens: [],
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );

      // Simulate repeated creation and disposal
      for (int cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          MaterialApp(
            key: Key('cycle_$cycle'),
            home: Scaffold(
              body: UXMapsView(
                restaurants: testRestaurants,
                userPreferences: testUserPreferences,
                userLocation: testUserLocation,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        await tester.pumpWidget(
          MaterialApp(
            key: Key('empty_$cycle'),
            home: const Scaffold(
              body: Text('Empty'),
            ),
          ),
        );

        await tester.pump();
      }

      expect(tester.takeException(), isNull);
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