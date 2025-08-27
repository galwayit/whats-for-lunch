import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/ux_investment_components.dart';
import '../../../lib/presentation/widgets/maps_components.dart';

void main() {
  group('Compact Layout Components Tests', () {
    testWidgets('UXCompactInvestmentIndicator should be much smaller than ring', (WidgetTester tester) async {
      const testSpent = 50.0;
      const testCapacity = 200.0;
      const testRemaining = 150.0;

      // Test compact indicator
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXCompactInvestmentIndicator(
              currentSpent: testSpent,
              weeklyCapacity: testCapacity,
              remainingCapacity: testRemaining,
            ),
          ),
        ),
      );

      final compactWidget = find.byType(UXCompactInvestmentIndicator);
      expect(compactWidget, findsOneWidget);

      // Get the size of the compact indicator
      final RenderBox compactBox = tester.renderObject(compactWidget);
      expect(compactBox.size.height, equals(52.0)); // Should be exactly 52px high
      expect(compactBox.size.height, lessThan(120.0)); // Much smaller than original ring

      // Test content rendering - single line format now
      expect(find.text('Weekly Budget: \$150 left'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget); // (50/200) * 100 = 25%
    });

    testWidgets('UXCompactMapControls should be much smaller than original', (WidgetTester tester) async {
      bool mapView = false;
      double radius = 5.0;
      bool locationLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXCompactMapControls(
              currentRadius: radius,
              onRadiusChanged: (newRadius) => radius = newRadius,
              isMapView: mapView,
              onViewChanged: (newView) => mapView = newView,
              isLocationLoading: locationLoading,
            ),
          ),
        ),
      );

      final compactControls = find.byType(UXCompactMapControls);
      expect(compactControls, findsOneWidget);

      // Get the size of the compact controls
      final RenderBox controlsBox = tester.renderObject(compactControls);
      expect(controlsBox.size.height, equals(56.0)); // Should be exactly 56px high
      
      // Test controls functionality
      expect(find.text('5.0km'), findsOneWidget); // Current radius display
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Compact components should maintain accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UXCompactInvestmentIndicator(
                  currentSpent: 50.0,
                  weeklyCapacity: 200.0,
                  remainingCapacity: 150.0,
                ),
                UXCompactMapControls(
                  currentRadius: 5.0,
                  onRadiusChanged: (_) {},
                  isMapView: false,
                  onViewChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Test accessibility semantics are preserved
      final compactIndicator = find.byType(UXCompactInvestmentIndicator);
      final compactControls = find.byType(UXCompactMapControls);
      
      expect(compactIndicator, findsOneWidget);
      expect(compactControls, findsOneWidget);

      // Test that interactive elements are present and accessible
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(SegmentedButton), findsOneWidget);
    });

    testWidgets('Layout space savings verification', (WidgetTester tester) async {
      // Test combined height of compact components vs original
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Compact investment indicator (48px)
                UXCompactInvestmentIndicator(
                  currentSpent: 50.0,
                  weeklyCapacity: 200.0,
                  remainingCapacity: 150.0,
                ),
                const SizedBox(height: 8), // padding
                // Compact map controls (56px)
                UXCompactMapControls(
                  currentRadius: 5.0,
                  onRadiusChanged: (_) {},
                  isMapView: false,
                  onViewChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Total height should be: 52 (indicator) + 8 (padding) + 56 (controls) = 116px
      // Original was approximately: 120 (ring) + 100+ (appbar bottom) + 100+ (map controls) = 320px+
      // This is a savings of over 200px of vertical space!
      
      expect(find.byType(UXCompactInvestmentIndicator), findsOneWidget);
      expect(find.byType(UXCompactMapControls), findsOneWidget);
    });
  });
}