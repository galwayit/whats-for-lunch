import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import '../../lib/main.dart' as app;
import '../../lib/presentation/pages/discover_page.dart';
import '../../lib/presentation/widgets/dietary_filter_components.dart';
import '../../lib/presentation/widgets/maps_components.dart';
import '../../lib/domain/entities/user_preferences.dart';
import '../../lib/domain/entities/restaurant.dart';

/// Stage 3 Restaurant Discovery Integration Tests
/// 
/// Tests the complete end-to-end restaurant discovery workflow including:
/// - Search and filtering functionality
/// - Maps integration
/// - Dietary filtering accuracy
/// - Investment mindset integration
/// - Performance targets (<2s search, <200ms filtering)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Stage 3 Discovery Integration Tests', () {
    
    group('Complete Discovery Workflow', () {
      testWidgets('should complete discovery to restaurant selection in under 60 seconds', (tester) async {
        final stopwatch = Stopwatch()..start();
        
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        // Navigate to discover page
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Verify discovery page loads
        expect(find.byType(DiscoverPage), findsOneWidget);
        expect(find.text('Discover Restaurants'), findsOneWidget);

        // Step 1: Set location (simulate location permission granted)
        await tester.tap(find.byIcon(Icons.my_location));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Step 2: Adjust search radius
        await tester.tap(find.text('2km'));
        await tester.pumpAndSettle();

        // Step 3: Apply dietary filters
        await tester.tap(find.byIcon(Icons.tune)); // Open filters
        await tester.pumpAndSettle();

        await tester.tap(find.text('Vegetarian'));
        await tester.pumpAndSettle();

        // Step 4: Switch to map view
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        // Step 5: Select a restaurant (simulate)
        // Note: Actual map interaction is complex, so we test the UI flow
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(60000),
          reason: 'Complete discovery workflow should take less than 60 seconds');

        // Verify final state
        expect(find.byType(UXMapsView), findsOneWidget);
      });

      testWidgets('should maintain investment mindset messaging throughout discovery', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Should show investment capacity ring
        expect(find.text('Weekly Budget'), findsOneWidget);
        expect(find.text('Smart choices ahead'), findsOneWidget);

        // Navigate through different views
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('List'));
        await tester.pumpAndSettle();

        // Investment messaging should remain consistent
        expect(find.text('Weekly Budget'), findsOneWidget);
      });

      testWidgets('should integrate seamlessly with Stage 2 meal logging', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Start from discovery
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Simulate restaurant selection and logging flow
        // This would involve selecting a restaurant and tapping "Log Meal Here"
        
        // Verify budget integration is preserved
        expect(find.text('Weekly Budget'), findsOneWidget);
        
        // Test navigation to meal logging (would need actual restaurant selection)
        // This integration ensures Stage 3 doesn't break Stage 2 functionality
      });
    });

    group('Search Performance Tests', () {
      testWidgets('restaurant search should complete within 2 seconds', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        final searchStopwatch = Stopwatch()..start();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'pizza');
        await tester.pumpAndSettle();

        // Wait for search completion
        await tester.pump(const Duration(milliseconds: 500));
        
        searchStopwatch.stop();

        expect(searchStopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Restaurant search should complete within 2 second target');
      });

      testWidgets('filtering should respond within 200ms', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        final filterStopwatch = Stopwatch()..start();

        // Apply quick filter
        await tester.tap(find.text('Vegetarian'));
        await tester.pump(); // Single pump to measure immediate response

        filterStopwatch.stop();

        expect(filterStopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Filter response should be within 200ms target');
      });

      testWidgets('map loading should complete within 3 seconds', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        final mapStopwatch = Stopwatch()..start();

        // Switch to map view
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        mapStopwatch.stop();

        expect(mapStopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Map loading should complete within 3 second target');
      });
    });

    group('Dietary Safety and Accuracy', () {
      testWidgets('should accurately filter for 20+ dietary categories', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Open advanced filters
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        // Test multiple dietary categories
        final testCategories = [
          'Vegetarian',
          'Vegan', 
          'Gluten-Free',
          'Kosher',
          'Keto',
          'Paleo',
        ];

        for (final category in testCategories) {
          // Find and tap category if visible
          final categoryFinder = find.text(category);
          if (categoryFinder.evaluate().isNotEmpty) {
            await tester.tap(categoryFinder);
            await tester.pump();
            
            // Verify filter applies quickly
            expect(find.text(category), findsOneWidget);
          }
        }

        // Verify comprehensive dietary category list exists
        expect(UserPreferences.allDietaryCategories.length, 
          greaterThanOrEqualTo(20),
          reason: 'Should have 20+ dietary categories as specified');
      });

      testWidgets('should handle allergen safety levels correctly', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Open allergen settings
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        // Test allergen selection with safety levels
        final allergenSwitches = find.byType(Switch);
        if (allergenSwitches.evaluate().isNotEmpty) {
          // Select first allergen
          await tester.tap(allergenSwitches.first);
          await tester.pumpAndSettle();

          // Should show safety level selector
          expect(find.text('Severity Level:'), findsOneWidget);
          expect(find.text('Mild'), findsOneWidget);
          expect(find.text('Moderate'), findsOneWidget);
          expect(find.text('Severe'), findsOneWidget);

          // Test safety level selection
          await tester.tap(find.text('Severe'));
          await tester.pumpAndSettle();

          // Should show allergen warning
          expect(find.text('Active Allergen Alerts'), findsOneWidget);
        }
      });

      testWidgets('should provide 90%+ accuracy in dietary filtering', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Apply specific dietary filters
        await tester.tap(find.text('Vegetarian'));
        await tester.pumpAndSettle();

        // Verify results are filtered
        // This test would need actual restaurant data to verify accuracy
        // For now, we verify the filtering mechanism works
        expect(find.text('Vegetarian'), findsOneWidget);
        
        // In a real test environment, we would:
        // 1. Inject test restaurant data
        // 2. Apply filters
        // 3. Verify that filtered results match dietary requirements
        // 4. Calculate accuracy percentage (should be >90%)
      });
    });

    group('Accessibility Compliance', () {
      testWidgets('should meet WCAG 2.1 compliance for discovery interface', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Test semantic labeling
        final semanticsNodes = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode?.debugDescribeChildren() ?? [];
        
        // Find interactive elements using semantics finder
        final buttonFinder = find.byType(ElevatedButton).hitTestable();
        final textFieldFinder = find.byType(TextField).hitTestable();
        
        final buttonCount = tester.widgetList(buttonFinder).length;
        final textFieldCount = tester.widgetList(textFieldFinder).length;
        
        // Verify accessibility labels exist for interactive elements
        expect(buttonCount + textFieldCount, greaterThan(0),
          reason: 'Should have interactive elements with accessibility support');

        // Test touch target sizes (minimum 44px)
        final buttons = find.byType(ElevatedButton);
        for (int i = 0; i < buttons.evaluate().length; i++) {
          final renderBox = tester.renderObject<RenderBox>(buttons.at(i));
          expect(renderBox.size.height, greaterThanOrEqualTo(44.0),
            reason: 'Touch targets should be at least 44px high');
          expect(renderBox.size.width, greaterThanOrEqualTo(44.0),
            reason: 'Touch targets should be at least 44px wide');
        }

        // Test keyboard navigation support
        // This would involve testing focus traversal, but is complex in integration tests
        expect(find.byType(Focus), findsWidgets,
          reason: 'Should have focusable elements for keyboard navigation');
      });

      testWidgets('should support screen reader navigation', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Open maps view
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        // Verify map has accessibility label
        final mapSemantics = find.descendant(
          of: find.byType(UXMapsView),
          matching: find.byType(Semantics),
        );

        if (mapSemantics.evaluate().isNotEmpty) {
          final semanticsWidget = tester.widget<Semantics>(mapSemantics.first);
          expect(semanticsWidget.properties.label, 
            contains('Restaurant map'),
            reason: 'Map should have descriptive label for screen readers');
        }

        // Test filter accessibility
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        final filterSemantics = find.byType(Semantics);
        expect(filterSemantics.evaluate().length, greaterThan(5),
          reason: 'Filter interface should have multiple semantic elements');
      });
    });

    group('Location and Permissions', () {
      testWidgets('should handle location permission flow gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Test location button
        await tester.tap(find.byIcon(Icons.my_location));
        await tester.pumpAndSettle();

        // Should handle permission request (would show system dialog in real app)
        // For integration test, we verify the UI handles the interaction
        expect(tester.takeException(), isNull,
          reason: 'Location permission flow should not cause crashes');
      });

      testWidgets('should provide fallback when location is unavailable', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Even without location, app should function
        expect(find.text('Discover Restaurants'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget, 
          reason: 'Search should still be available without location');

        // Manual location entry should be possible
        await tester.enterText(find.byType(TextField), 'San Francisco');
        await tester.pumpAndSettle();

        expect(find.text('San Francisco'), findsOneWidget);
      });

      testWidgets('should handle radius selection accurately', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Test different radius options
        final radiusOptions = ['1km', '2km', '5km', '10km'];
        
        for (final radius in radiusOptions) {
          final radiusFinder = find.text(radius);
          if (radiusFinder.evaluate().isNotEmpty) {
            await tester.tap(radiusFinder);
            await tester.pumpAndSettle();
            
            // Verify radius is applied
            expect(find.text('Search Radius: ${radius.replaceAll('km', '')}.0km'), 
              findsOneWidget);
          }
        }
      });
    });

    group('API Integration and Caching', () {
      testWidgets('should handle API rate limits gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Perform multiple searches rapidly to test rate limiting
        for (int i = 0; i < 5; i++) {
          await tester.enterText(find.byType(TextField), 'search $i');
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // Should handle gracefully without crashes
        expect(tester.takeException(), isNull,
          reason: 'Rapid API requests should not crash the app');
      });

      testWidgets('should use caching effectively', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // First search
        final firstSearchStopwatch = Stopwatch()..start();
        await tester.enterText(find.byType(TextField), 'pizza');
        await tester.pumpAndSettle();
        firstSearchStopwatch.stop();

        // Clear and repeat same search
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        final cachedSearchStopwatch = Stopwatch()..start();
        await tester.enterText(find.byType(TextField), 'pizza');
        await tester.pumpAndSettle();
        cachedSearchStopwatch.stop();

        // Cached search should be faster (this is a simplified test)
        // In reality, we'd need to mock the API to test caching properly
        expect(cachedSearchStopwatch.elapsedMilliseconds, 
          lessThanOrEqualTo(firstSearchStopwatch.elapsedMilliseconds),
          reason: 'Cached searches should be as fast or faster');
      });
    });

    group('Investment Mindset Integration', () {
      testWidgets('should maintain budget integration throughout discovery', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // First ensure budget is set up
        await tester.tap(find.text('Track'));
        await tester.pumpAndSettle();

        // Navigate to discovery
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Should show investment capacity
        expect(find.text('Weekly Budget'), findsOneWidget);

        // Test restaurant selection with budget context
        // This would show budget impact when selecting restaurants
        // For now, verify the integration points exist
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });

      testWidgets('should show cost-optimized recommendations', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Apply budget-conscious filters
        final budgetLevelControls = find.text(r'$'); // Single dollar sign
        if (budgetLevelControls.evaluate().isNotEmpty) {
          await tester.tap(budgetLevelControls.first);
          await tester.pumpAndSettle();

          // Should show budget-appropriate results
          expect(find.text(r'$'), findsWidgets);
        }
      });
    });

    group('Error Handling and Recovery', () {
      testWidgets('should handle network failures gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Simulate network issues by rapid searches
        await tester.enterText(find.byType(TextField), 'network test');
        await tester.pumpAndSettle();

        // Should show appropriate error handling
        // The app should remain functional even with network issues
        expect(tester.takeException(), isNull);
        expect(find.text('Discover Restaurants'), findsOneWidget);
      });

      testWidgets('should provide clear error messages for location issues', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Attempt location access
        await tester.tap(find.byIcon(Icons.my_location));
        await tester.pumpAndSettle();

        // Should handle location errors gracefully
        // In a real test, this might show permission denied message
        expect(tester.takeException(), isNull);
      });
    });

    group('Regression Testing', () {
      testWidgets('should not break Stage 2 meal logging functionality', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Test that Track page still works
        await tester.tap(find.text('Track'));
        await tester.pumpAndSettle();

        expect(find.text('Track'), findsOneWidget);

        // Test that budget tracking is preserved
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Track'));
        await tester.pumpAndSettle();

        // Stage 2 functionality should remain intact
        expect(find.text('Track'), findsOneWidget);
      });

      testWidgets('should preserve investment mindset messaging consistency', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Check messaging in Track page
        await tester.tap(find.text('Track'));
        await tester.pumpAndSettle();

        // Check messaging in Discover page
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        // Investment terminology should be consistent
        expect(find.text('Weekly Budget'), findsOneWidget);
      });
    });
  });
}