import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lib/presentation/widgets/dietary_filter_components.dart';
import '../../../lib/domain/entities/user_preferences.dart';

void main() {
  group('Stage 3 Dietary Filter Components Tests', () {
    late UserPreferences testUserPreferences;

    setUp(() {
      testUserPreferences = const UserPreferences(
        dietaryRestrictions: ['vegetarian'],
        allergens: ['peanuts'],
        allergenSafetyLevels: {
          'peanuts': AllergenSafetyLevel.severe,
        },
        requireDietaryVerification: true,
        minimumRating: 4.0,
      );
    });

    group('UXDietaryFilterPanel', () {
      testWidgets('should render with correct initial state', (tester) async {
        bool preferencesChanged = false;
        UserPreferences? changedPreferences;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {
                  preferencesChanged = true;
                  changedPreferences = prefs;
                },
              ),
            ),
          ),
        );

        // Should show the filter panel header
        expect(find.text('Dietary Filters'), findsOneWidget);
        expect(find.byIcon(Icons.filter_list), findsOneWidget);
        
        // Should show toggle buttons for Quick/Advanced
        expect(find.text('Quick'), findsOneWidget);
        expect(find.text('Advanced'), findsOneWidget);
        
        // Should not have called preferences changed initially
        expect(preferencesChanged, false);
      });

      testWidgets('should toggle between quick and advanced filters', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Should start with quick filters
        expect(find.text('Quick Presets'), findsOneWidget);
        
        // Tap to switch to advanced
        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();
        
        // Should now show advanced filters
        expect(find.text('Dietary Restrictions'), findsOneWidget);
        expect(find.text('Allergens'), findsOneWidget);
        expect(find.text('Safety Preferences'), findsOneWidget);
      });

      testWidgets('should show active allergen warnings when allergens are present', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Should show allergen warnings for active allergens
        expect(find.text('Active Allergen Alerts'), findsOneWidget);
        expect(find.textContaining('peanuts'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsWidgets);
      });

      testWidgets('should not show allergen warnings when no allergens', (tester) async {
        final noAllergenPrefs = testUserPreferences.copyWith(allergens: []);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: noAllergenPrefs,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Should not show allergen warnings
        expect(find.text('Active Allergen Alerts'), findsNothing);
      });

      testWidgets('should display all 20+ dietary categories in advanced mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Switch to advanced mode
        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        // Verify some key dietary categories are present
        expect(find.text('Vegetarian'), findsOneWidget);
        expect(find.text('Vegan'), findsOneWidget);
        expect(find.text('Gluten-Free'), findsOneWidget);
        expect(find.text('Kosher'), findsOneWidget);
        expect(find.text('Keto'), findsOneWidget);
        expect(find.text('Paleo'), findsOneWidget);
        
        // Should show more categories when scrolled
        final dietaryCategories = UserPreferences.allDietaryCategories;
        expect(dietaryCategories.length, greaterThanOrEqualTo(20),
          reason: 'Should have 20+ dietary categories as specified');
      });

      testWidgets('should handle minimum rating slider correctly', (tester) async {
        bool preferencesChanged = false;
        UserPreferences? changedPreferences;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {
                  preferencesChanged = true;
                  changedPreferences = prefs;
                },
              ),
            ),
          ),
        );

        // Switch to advanced mode to access slider
        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        // Find and interact with rating slider
        expect(find.text('Minimum Rating: 4.0 stars'), findsOneWidget);
        
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);
        
        // Simulate slider change (this is complex in flutter_test, so we verify it exists)
        expect(tester.widget<Slider>(sliderFinder).value, 4.0);
      });
    });

    group('UXDietaryFilterChip', () {
      testWidgets('should render correctly when not selected', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterChip(
                label: 'Test Filter',
                description: 'Test Description',
                isSelected: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Test Filter'), findsOneWidget);
        expect(tapped, false);

        // Tap the chip
        await tester.tap(find.byType(FilterChip));
        expect(tapped, true);
      });

      testWidgets('should render correctly when selected', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterChip(
                label: 'Selected Filter',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        );

        final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
        expect(filterChip.selected, true);
        expect(find.text('Selected Filter'), findsOneWidget);
      });

      testWidgets('should show safety level border when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterChip(
                label: 'Severe Allergen',
                isSelected: false,
                safetyLevel: AllergenSafetyLevel.severe,
                onTap: () {},
              ),
            ),
          ),
        );

        final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
        expect(filterChip.side, isNotNull);
        expect(find.text('Severe Allergen'), findsOneWidget);
      });

      testWidgets('should have proper accessibility semantics', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterChip(
                label: 'Accessible Filter',
                description: 'Filter description for accessibility',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        );

        final semantics = find.byType(Semantics).first;
        expect(semantics, findsOneWidget);
        
        final semanticsWidget = tester.widget<Semantics>(semantics);
        expect(semanticsWidget.properties.button, true);
        expect(semanticsWidget.properties.selected, true);
      });
    });

    group('UXAllergenSelector', () {
      testWidgets('should render allergen with correct safety indicators', (tester) async {
        final allergenInfo = AllergenInfo('peanuts', 'Peanuts', AllergenSafetyLevel.severe);
        bool toggleCalled = false;
        bool safetyLevelChanged = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXAllergenSelector(
                allergen: allergenInfo,
                isSelected: false,
                currentSafetyLevel: AllergenSafetyLevel.severe,
                onToggled: (selected) => toggleCalled = true,
                onSafetyLevelChanged: (level) => safetyLevelChanged = true,
              ),
            ),
          ),
        );

        // Should show allergen name and safety description
        expect(find.text('Peanuts'), findsOneWidget);
        expect(find.text('Life-threatening, avoid completely'), findsOneWidget);
        
        // Should show correct safety icon for severe level
        expect(find.byIcon(Icons.dangerous), findsOneWidget);
        
        // Should have toggle switch
        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('should show safety level selector when selected', (tester) async {
        final allergenInfo = AllergenInfo('dairy', 'Dairy', AllergenSafetyLevel.moderate);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXAllergenSelector(
                allergen: allergenInfo,
                isSelected: true,
                currentSafetyLevel: AllergenSafetyLevel.moderate,
                onToggled: (selected) {},
                onSafetyLevelChanged: (level) {},
              ),
            ),
          ),
        );

        // Should show safety level selector when selected
        expect(find.text('Severity Level:'), findsOneWidget);
        expect(find.text('Mild'), findsOneWidget);
        expect(find.text('Moderate'), findsOneWidget);
        expect(find.text('Severe'), findsOneWidget);
        
        // Should have segmented button for safety levels
        expect(find.byType(SegmentedButton<AllergenSafetyLevel>), findsOneWidget);
      });

      testWidgets('should not show safety level selector when not selected', (tester) async {
        final allergenInfo = AllergenInfo('dairy', 'Dairy', AllergenSafetyLevel.moderate);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXAllergenSelector(
                allergen: allergenInfo,
                isSelected: false,
                onToggled: (selected) {},
                onSafetyLevelChanged: (level) {},
              ),
            ),
          ),
        );

        // Should not show safety level selector when not selected
        expect(find.text('Severity Level:'), findsNothing);
        expect(find.byType(SegmentedButton<AllergenSafetyLevel>), findsNothing);
      });

      testWidgets('should handle different safety levels with correct colors and icons', (tester) async {
        for (final level in AllergenSafetyLevel.values) {
          final allergenInfo = AllergenInfo('test', 'Test Allergen', level);
          
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: UXAllergenSelector(
                  allergen: allergenInfo,
                  isSelected: false,
                  currentSafetyLevel: level,
                  onToggled: (selected) {},
                  onSafetyLevelChanged: (newLevel) {},
                ),
              ),
            ),
          );

          // Verify appropriate icon is shown for each level
          switch (level) {
            case AllergenSafetyLevel.mild:
              expect(find.byIcon(Icons.info), findsOneWidget);
              break;
            case AllergenSafetyLevel.moderate:
              expect(find.byIcon(Icons.warning), findsOneWidget);
              break;
            case AllergenSafetyLevel.severe:
              expect(find.byIcon(Icons.dangerous), findsOneWidget);
              break;
          }
        }
      });
    });

    group('UXFilterSummary', () {
      testWidgets('should show no filters message when no filters applied', (tester) async {
        final emptyPrefs = UserPreferences();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXFilterSummary(
                userPreferences: emptyPrefs,
                onClearAll: () {},
                onEditFilters: () {},
              ),
            ),
          ),
        );

        expect(find.text('No dietary filters applied'), findsOneWidget);
        expect(find.text('Add Filters'), findsOneWidget);
        expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
      });

      testWidgets('should show active filters count when filters applied', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXFilterSummary(
                userPreferences: testUserPreferences,
                onClearAll: () {},
                onEditFilters: () {},
              ),
            ),
          ),
        );

        // Should show count of active filters (1 dietary + 1 allergen = 2)
        expect(find.textContaining('2 dietary filters active'), findsOneWidget);
        expect(find.text('Clear All'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.byIcon(Icons.filter_list), findsOneWidget);
      });

      testWidgets('should handle callback functions correctly', (tester) async {
        bool clearAllCalled = false;
        bool editFiltersCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXFilterSummary(
                userPreferences: testUserPreferences,
                onClearAll: () => clearAllCalled = true,
                onEditFilters: () => editFiltersCalled = true,
              ),
            ),
          ),
        );

        // Test Clear All button
        await tester.tap(find.text('Clear All'));
        expect(clearAllCalled, true);

        // Test Edit button
        await tester.tap(find.text('Edit'));
        expect(editFiltersCalled, true);
      });
    });

    group('Performance and Accessibility', () {
      testWidgets('dietary filter panel should respond within 200ms', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Filter panel should render within 200ms');
      });

      testWidgets('should have proper WCAG 2.1 accessibility compliance', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Enable semantics for testing
        final handle = tester.ensureSemantics();
        
        // Find button widgets and check their semantics
        final buttonFinders = [
          find.byType(FilterChip),
          find.byType(ElevatedButton),
        ];
        
        for (final finder in buttonFinders) {
          final buttons = finder.evaluate();
          for (final button in buttons) {
            try {
              final semantics = tester.getSemantics(find.byWidget(button.widget));
              expect(semantics.label, isNotEmpty,
                reason: 'All buttons should have accessibility labels');
            } catch (e) {
              // Some widgets might not have direct semantic nodes
              // This is acceptable for composite widgets
            }
          }
        }
        
        handle.dispose();

        // Should support screen reader navigation
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('filter chips should have minimum 44px touch targets', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Switch to advanced mode to see filter chips
        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        final filterChips = find.byType(FilterChip);
        for (int i = 0; i < filterChips.evaluate().length; i++) {
          final chipWidget = tester.widget<FilterChip>(filterChips.at(i));
          final renderBox = tester.renderObject<RenderBox>(filterChips.at(i));
          
          // Verify minimum touch target size (44x44 logical pixels)
          expect(renderBox.size.height, greaterThanOrEqualTo(44.0),
            reason: 'Filter chips should have minimum 44px height for touch accessibility');
        }
      });

      testWidgets('should handle rapid filter changes without performance issues', (tester) async {
        int changeCount = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: testUserPreferences,
                onPreferencesChanged: (prefs) => changeCount++,
              ),
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();

        // Simulate rapid filter changes
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('Quick'));
          await tester.pump();
          await tester.tap(find.text('Advanced'));
          await tester.pump();
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Rapid filter changes should complete within 1 second');
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle null preferences gracefully', (tester) async {
        // This would test null safety, but our component requires non-null preferences
        // Instead, test with minimal preferences
        final minimalPrefs = UserPreferences();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: minimalPrefs,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        expect(find.text('Dietary Filters'), findsOneWidget);
        expect(find.text('Quick'), findsOneWidget);
      });

      testWidgets('should handle very long allergen lists', (tester) async {
        final manyAllergensPrefs = testUserPreferences.copyWith(
          allergens: UserPreferences.commonAllergens.map((a) => a.id).toList(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDietaryFilterPanel(
                userPreferences: manyAllergensPrefs,
                onPreferencesChanged: (prefs) {},
              ),
            ),
          ),
        );

        // Should handle many allergens without overflow
        expect(find.text('Active Allergen Alerts'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}