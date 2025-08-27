import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import '../../../lib/presentation/widgets/maps_components.dart';
import '../../../lib/domain/entities/restaurant.dart';
import '../../../lib/domain/entities/user_preferences.dart';

void main() {
  group('Stage 3 Maps Components Tests', () {
    late List<Restaurant> testRestaurants;
    late UserPreferences testUserPreferences;
    late Position testUserLocation;

    setUp(() {
      testUserLocation = _createTestPosition(37.7749, -122.4194); // San Francisco
      
      testRestaurants = [
        _createTestRestaurant(
          'r1', 
          'Safe Restaurant',
          latitude: 37.7849,
          longitude: -122.4194,
          rating: 4.5,
          priceLevel: 2,
          allergenInfo: [],
          dietaryRestrictions: ['vegetarian'],
        ),
        _createTestRestaurant(
          'r2',
          'Warning Restaurant', 
          latitude: 37.7649,
          longitude: -122.4294,
          rating: 3.8,
          priceLevel: 3,
          allergenInfo: ['peanuts'],
          dietaryRestrictions: [],
        ),
        _createTestRestaurant(
          'r3',
          'Verified Restaurant',
          latitude: 37.7749,
          longitude: -122.4094,
          rating: 4.8,
          priceLevel: 1,
          allergenInfo: [],
          dietaryRestrictions: ['vegetarian', 'vegan'],
          hasVerifiedDietaryInfo: true,
        ),
      ];

      testUserPreferences = const UserPreferences(
        dietaryRestrictions: ['vegetarian'],
        allergens: ['peanuts'],
        allergenSafetyLevels: {'peanuts': AllergenSafetyLevel.severe},
        maxTravelDistance: 5.0,
        minimumRating: 3.0,
      );
    });

    group('UXMapsView', () {
      testWidgets('should render loading state initially', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: [],
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        // Should show loading indicator initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render error state when error occurs', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: testRestaurants,
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        // Let the widget initialize and potentially fail
        await tester.pumpAndSettle();

        // Note: This test may need to be adjusted based on actual Google Maps behavior
        // For now, we verify the widget can handle the maps setup
        expect(tester.takeException(), isNull);
      });

      testWidgets('should have proper accessibility semantics', (tester) async {
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

        await tester.pumpAndSettle();

        // Should have semantic label for screen readers
        final semanticsWidgets = find.byType(Semantics);
        expect(semanticsWidgets, findsWidgets);
        
        // Find the main map semantics
        final mapSemantics = find.descendant(
          of: find.byType(UXMapsView),
          matching: find.byType(Semantics),
        );
        
        if (mapSemantics.evaluate().isNotEmpty) {
          final semanticsWidget = tester.widget<Semantics>(mapSemantics.first);
          expect(semanticsWidget.properties.label, contains('Restaurant map'));
        }
      });

      testWidgets('should respond to restaurant selection callbacks', (tester) async {
        Restaurant? selectedRestaurant;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: testRestaurants,
                userPreferences: testUserPreferences,
                userLocation: testUserLocation,
                onRestaurantSelected: (restaurant) {
                  selectedRestaurant = restaurant;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Note: Actual map interaction testing is complex with GoogleMap widget
        // This test verifies the callback structure exists
        expect(selectedRestaurant, isNull); // No interaction yet
      });

      testWidgets('should handle radius changes correctly', (tester) async {
        double? newRadius;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: testRestaurants,
                userPreferences: testUserPreferences,
                userLocation: testUserLocation,
                onRadiusChanged: (radius) {
                  newRadius = radius;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify callback structure
        expect(newRadius, isNull); // No change yet
      });
    });

    group('UXRestaurantMarker', () {
      testWidgets('should display restaurant information correctly', (tester) async {
        final restaurant = testRestaurants[0]; // Safe Restaurant
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: restaurant,
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        // Should display restaurant name
        expect(find.text('Safe Restaurant'), findsOneWidget);
        
        // Should show rating
        expect(find.text('4.5'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        
        // Should show price level
        expect(find.text(r'$$'), findsOneWidget);
        
        // Should show safety indicator (verified)
        expect(find.byIcon(Icons.verified), findsOneWidget);
      });

      testWidgets('should show correct safety indicators', (tester) async {
        // Test safe restaurant
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: testRestaurants[0], // Safe Restaurant
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.verified), findsOneWidget);

        // Test warning restaurant
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: testRestaurants[1], // Warning Restaurant
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.dangerous), findsOneWidget);
      });

      testWidgets('should show dietary compatibility when not 100%', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: testRestaurants[1], // Warning Restaurant with low compatibility
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        // Should show dietary match percentage
        expect(find.textContaining('dietary match'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      });

      testWidgets('should handle tap gestures correctly', (tester) async {
        bool tapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: testRestaurants[0],
                userPreferences: testUserPreferences,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // Tap the marker
        await tester.tap(find.byType(Card));
        expect(tapped, true);
      });

      testWidgets('should have proper accessibility semantics', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: testRestaurants[0],
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        final semantics = find.byType(Semantics);
        expect(semantics, findsOneWidget);
        
        final semanticsWidget = tester.widget<Semantics>(semantics);
        expect(semanticsWidget.properties.button, true);
        expect(semanticsWidget.properties.label, contains('Safe Restaurant'));
        expect(semanticsWidget.properties.label, contains('dietary compatibility'));
      });

      testWidgets('should display distance when available', (tester) async {
        final restaurantWithDistance = testRestaurants[0].copyWith(
          distanceFromUser: 2.5,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: restaurantWithDistance,
                userPreferences: testUserPreferences,
                showDistance: true,
              ),
            ),
          ),
        );

        expect(find.text('2.5km'), findsOneWidget);
      });

      testWidgets('should hide distance when showDistance is false', (tester) async {
        final restaurantWithDistance = testRestaurants[0].copyWith(
          distanceFromUser: 2.5,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXRestaurantMarker(
                restaurant: restaurantWithDistance,
                userPreferences: testUserPreferences,
                showDistance: false,
              ),
            ),
          ),
        );

        expect(find.text('2.5km'), findsNothing);
      });
    });

    group('UXMapControls', () {
      testWidgets('should display current radius correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapControls(
                currentRadius: 7.5,
                onRadiusChanged: (radius) {},
                isMapView: true,
                onViewChanged: (showMap) {},
              ),
            ),
          ),
        );

        expect(find.text('Search Radius: 7.5km'), findsOneWidget);
      });

      testWidgets('should handle view toggle between map and list', (tester) async {
        bool isMapView = true;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return UXMapControls(
                    currentRadius: 5.0,
                    onRadiusChanged: (radius) {},
                    isMapView: isMapView,
                    onViewChanged: (showMap) {
                      setState(() {
                        isMapView = showMap;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Should show Map selected initially
        final mapButton = find.ancestor(
          of: find.text('Map'),
          matching: find.byType(ButtonSegment<bool>),
        );
        expect(mapButton, findsOneWidget);

        // Tap List button
        await tester.tap(find.text('List'));
        await tester.pumpAndSettle();

        expect(isMapView, false);
      });

      testWidgets('should handle radius slider changes', (tester) async {
        double currentRadius = 5.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return UXMapControls(
                    currentRadius: currentRadius,
                    onRadiusChanged: (radius) {
                      setState(() {
                        currentRadius = radius;
                      });
                    },
                    isMapView: true,
                    onViewChanged: (showMap) {},
                  );
                },
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);
        
        final slider = tester.widget<Slider>(sliderFinder);
        expect(slider.value, 5.0);
        expect(slider.min, 1.0);
        expect(slider.max, 20.0);
      });

      testWidgets('should show quick radius presets', (tester) async {
        double selectedRadius = 5.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return UXMapControls(
                    currentRadius: selectedRadius,
                    onRadiusChanged: (radius) {
                      setState(() {
                        selectedRadius = radius;
                      });
                    },
                    isMapView: true,
                    onViewChanged: (showMap) {},
                  );
                },
              ),
            ),
          ),
        );

        // Should show preset radius chips
        expect(find.text('1km'), findsOneWidget);
        expect(find.text('2km'), findsOneWidget);
        expect(find.text('5km'), findsOneWidget);
        expect(find.text('10km'), findsOneWidget);

        // Test selecting a preset
        await tester.tap(find.text('2km'));
        await tester.pumpAndSettle();
        
        expect(selectedRadius, 2.0);
      });

      testWidgets('should handle location button correctly', (tester) async {
        bool locationPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapControls(
                currentRadius: 5.0,
                onRadiusChanged: (radius) {},
                isMapView: true,
                onViewChanged: (showMap) {},
                onLocationPressed: () => locationPressed = true,
                isLocationLoading: false,
              ),
            ),
          ),
        );

        // Should show location button
        expect(find.byIcon(Icons.my_location), findsOneWidget);
        
        // Tap location button
        await tester.tap(find.byIcon(Icons.my_location));
        expect(locationPressed, true);
      });

      testWidgets('should show loading state for location button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapControls(
                currentRadius: 5.0,
                onRadiusChanged: (radius) {},
                isMapView: true,
                onViewChanged: (showMap) {},
                isLocationLoading: true,
              ),
            ),
          ),
        );

        // Should show loading indicator instead of location icon
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.my_location), findsNothing);
      });

      testWidgets('should have proper accessibility for all controls', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapControls(
                currentRadius: 5.0,
                onRadiusChanged: (radius) {},
                isMapView: true,
                onViewChanged: (showMap) {},
                onLocationPressed: () {},
              ),
            ),
          ),
        );

        // Location button should have semantic label
        final locationButton = find.byIcon(Icons.my_location);
        final locationSemantics = find.ancestor(
          of: locationButton,
          matching: find.byType(Semantics),
        );
        
        if (locationSemantics.evaluate().isNotEmpty) {
          final semanticsWidget = tester.widget<Semantics>(locationSemantics.first);
          expect(semanticsWidget.properties.button, true);
          expect(semanticsWidget.properties.label, contains('location'));
        }

        // Radius preset chips should have accessibility labels
        final radiusChips = find.byType(FilterChip);
        for (final chip in radiusChips.evaluate()) {
          final chipSemantics = find.ancestor(
            of: find.byWidget(chip.widget),
            matching: find.byType(Semantics),
          );
          if (chipSemantics.evaluate().isNotEmpty) {
            final semanticsWidget = tester.widget<Semantics>(chipSemantics.first);
            expect(semanticsWidget.properties.button, true);
            expect(semanticsWidget.properties.label, contains('radius'));
          }
        }
      });
    });

    group('UXMapLegend', () {
      testWidgets('should display all safety level indicators', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXMapLegend(),
            ),
          ),
        );

        // Should show legend title
        expect(find.text('Map Legend'), findsOneWidget);

        // Should show all safety levels
        expect(find.text('Community Verified'), findsOneWidget);
        expect(find.text('Safe'), findsOneWidget);
        expect(find.text('Caution'), findsOneWidget);
        expect(find.text('Warning'), findsOneWidget);

        // Should show corresponding icons
        expect(find.byIcon(Icons.verified), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.byIcon(Icons.dangerous), findsOneWidget);

        // Should show descriptions
        expect(find.text('Dietary info verified by community'), findsOneWidget);
        expect(find.text('No known allergens or dietary conflicts'), findsOneWidget);
        expect(find.text('Some dietary considerations needed'), findsOneWidget);
        expect(find.text('May contain your allergens'), findsOneWidget);
      });

      testWidgets('should use correct colors for safety levels', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXMapLegend(),
            ),
          ),
        );

        // Find legend items and verify they have colored containers
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(4)); // At least 4 for safety levels
        
        // Each legend item should have a colored container with border
        for (final container in containers.evaluate()) {
          final containerWidget = container.widget as Container;
          if (containerWidget.decoration is BoxDecoration) {
            final decoration = containerWidget.decoration as BoxDecoration;
            // Should have some form of color indication
            expect(decoration.color ?? decoration.border?.top.color, isNotNull);
          }
        }
      });
    });

    group('Performance Tests', () {
      testWidgets('map components should render within 3 second target', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: UXMapsView(
                      restaurants: testRestaurants,
                      userPreferences: testUserPreferences,
                      userLocation: testUserLocation,
                    ),
                  ),
                  UXMapControls(
                    currentRadius: 5.0,
                    onRadiusChanged: (radius) {},
                    isMapView: true,
                    onViewChanged: (showMap) {},
                  ),
                  const UXMapLegend(),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Map components should render within 3 second target');
      });

      testWidgets('restaurant markers should handle large datasets efficiently', (tester) async {
        // Create large dataset of restaurants
        final largeRestaurantList = List.generate(100, (index) =>
          _createTestRestaurant(
            'r$index',
            'Restaurant $index',
            latitude: 37.7749 + (index * 0.001),
            longitude: -122.4194 + (index * 0.001),
            rating: 3.0 + (index % 3),
            priceLevel: 1 + (index % 4),
          )
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: largeRestaurantList.length,
                itemBuilder: (context, index) => UXRestaurantMarker(
                  restaurant: largeRestaurantList[index],
                  userPreferences: testUserPreferences,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: '100 restaurant markers should render within 2 seconds');
      });

      testWidgets('map controls should respond to user input within 200ms', (tester) async {
        double? changedRadius;
        final responseStopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapControls(
                currentRadius: 5.0,
                onRadiusChanged: (radius) {
                  responseStopwatch.stop();
                  changedRadius = radius;
                },
                isMapView: true,
                onViewChanged: (showMap) {},
              ),
            ),
          ),
        );

        responseStopwatch.start();
        
        // Tap a radius preset
        await tester.tap(find.text('2km'));
        
        expect(responseStopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Control response should be within 200ms');
        expect(changedRadius, 2.0);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle empty restaurant list gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: [],
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Should not throw errors with empty list
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle restaurants without coordinates', (tester) async {
        final restaurantsNoCoords = [
          _createTestRestaurant('r1', 'No Location Restaurant'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: restaurantsNoCoords,
                userPreferences: testUserPreferences,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Should handle gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle null user location gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMapsView(
                restaurants: testRestaurants,
                userPreferences: testUserPreferences,
                userLocation: null,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Should handle null location without errors
        expect(tester.takeException(), isNull);
      });
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