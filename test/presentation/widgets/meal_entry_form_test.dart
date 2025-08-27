import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/presentation/widgets/meal_entry_form.dart';
import 'package:what_we_have_for_lunch/presentation/providers/meal_providers.dart';
import 'package:what_we_have_for_lunch/presentation/providers/simple_providers.dart' as simple_providers;
import 'package:what_we_have_for_lunch/presentation/providers/user_preferences_provider.dart' as prefs;
import 'package:what_we_have_for_lunch/presentation/widgets/ux_components.dart';
import 'package:what_we_have_for_lunch/domain/entities/user_preferences.dart';

void main() {
  group('MealEntryForm Widget Tests', () {
    Widget createTestWidget({VoidCallback? onSubmitted}) {
      return ProviderScope(
        overrides: [
          // Mock current user ID
          simple_providers.currentUserIdProvider.overrideWith((ref) => 1),
          // Mock user preferences notifier - using simple provider for tests
          simple_providers.simpleUserPreferencesProvider.overrideWith((ref) => 
            simple_providers.SimpleUserPreferencesNotifier()..state = const UserPreferences(
              weeklyBudget: 200.0,
              cuisinePreferences: [],
              dietaryRestrictions: [],
              budgetLevel: 2,
            )
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MealEntryForm(
              onSubmitted: onSubmitted,
              autofocus: false, // Disable autofocus for testing
            ),
          ),
        ),
      );
    }

    testWidgets('should render all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for main form elements
      expect(find.text('Log Your Experience'), findsOneWidget);
      expect(find.byType(UXRestaurantInput), findsOneWidget);
      expect(find.byType(UXCurrencyInput), findsOneWidget);
      expect(find.byType(UXMealCategorySelector), findsOneWidget);
      expect(find.byType(UXDateTimePicker), findsOneWidget);
      expect(find.byType(UXTextInput), findsOneWidget); // Notes input
      expect(find.text('Log Experience'), findsOneWidget); // Submit button
    });

    testWidgets('should validate restaurant name field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the restaurant input field
      final restaurantField = find.byType(TextFormField).first;
      
      // Leave field empty and trigger validation
      await tester.tap(restaurantField);
      await tester.enterText(restaurantField, '');
      await tester.pump();
      
      // Trigger form submission to see validation
      final submitButton = find.text('Log Experience');
      await tester.tap(submitButton);
      await tester.pump();
      
      // Should show validation error
      expect(find.text('Please tell us where you enjoyed this experience'), findsOneWidget);
    });

    testWidgets('should validate cost field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the cost input field
      final costField = find.byType(TextFormField).at(1); // Second TextFormField
      
      // Enter invalid cost
      await tester.tap(costField);
      await tester.enterText(costField, '0');
      await tester.pump();
      
      // Trigger form submission
      final submitButton = find.text('Log Experience');
      await tester.tap(submitButton);
      await tester.pump();
      
      // Should show validation error
      expect(find.text('Please enter a valid amount'), findsOneWidget);
    });

    testWidgets('should accept valid cost input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the cost input field
      final costField = find.byType(TextFormField).at(1);
      
      // Enter valid cost
      await tester.tap(costField);
      await tester.enterText(costField, '25.50');
      await tester.pump();
      
      // Should not show validation error
      expect(find.text('Please enter a valid amount'), findsNothing);
    });

    testWidgets('should show budget impact when cost is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter restaurant name and cost to make form valid
      final restaurantField = find.byType(TextFormField).first;
      await tester.tap(restaurantField);
      await tester.enterText(restaurantField, 'Test Restaurant');
      await tester.pump();

      final costField = find.byType(TextFormField).at(1);
      await tester.tap(costField);
      await tester.enterText(costField, '25.50');
      await tester.pump();

      // Budget impact card should appear
      expect(find.byType(UXBudgetImpactCard), findsOneWidget);
      expect(find.text('Investment Impact'), findsOneWidget);
    });

    testWidgets('should handle meal category selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find category selector
      expect(find.byType(UXMealCategorySelector), findsOneWidget);
      expect(find.text('Experience Type'), findsOneWidget);
      
      // Find and tap a category chip
      final deliveryChip = find.text('Delivery');
      expect(deliveryChip, findsOneWidget);
      
      await tester.tap(deliveryChip);
      await tester.pump();
      
      // Category should be selected (FilterChip should be selected)
      final filterChip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Delivery'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(filterChip.selected, isTrue);
    });

    testWidgets('should show positive psychology messaging', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for positive messaging in the header
      expect(find.text('Every meal is an investment in your happiness and well-being. Let\'s capture this moment!'), findsOneWidget);
      
      // Enter a cost to see budget impact messaging
      final costField = find.byType(TextFormField).at(1);
      await tester.tap(costField);
      await tester.enterText(costField, '15.00');
      await tester.pump();

      // Should show positive budget impact message
      expect(find.textContaining('Great choice'), findsOneWidget);
    });

    testWidgets('should handle date and time selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find date/time picker
      expect(find.byType(UXDateTimePicker), findsOneWidget);
      expect(find.text('Experience Date & Time'), findsOneWidget);
      
      // Should show "Today" by default
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should handle clear form button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill in some form data
      final restaurantField = find.byType(TextFormField).first;
      await tester.tap(restaurantField);
      await tester.enterText(restaurantField, 'Test Restaurant');
      await tester.pump();

      final costField = find.byType(TextFormField).at(1);
      await tester.tap(costField);
      await tester.enterText(costField, '25.00');
      await tester.pump();

      // Find and tap clear button
      final clearButton = find.text('Clear Form');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();

      // Fields should be cleared
      expect(find.text('Test Restaurant'), findsNothing);
      expect(find.text('25.00'), findsNothing);
    });

    testWidgets('should disable submit button when form is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Submit button should be disabled initially
      final submitButton = find.byType(UXPrimaryButton);
      final buttonWidget = tester.widget<UXPrimaryButton>(submitButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should enable submit button when form is valid', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill in required fields
      final restaurantField = find.byType(TextFormField).first;
      await tester.tap(restaurantField);
      await tester.enterText(restaurantField, 'Test Restaurant');
      await tester.pump();

      final costField = find.byType(TextFormField).at(1);
      await tester.tap(costField);
      await tester.enterText(costField, '25.50');
      await tester.pump();

      // Submit button should be enabled
      final submitButton = find.byType(UXPrimaryButton);
      final buttonWidget = tester.widget<UXPrimaryButton>(submitButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should handle notes input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find notes field (should be the last TextFormField)
      final notesField = find.byType(TextFormField).last;
      
      // Enter notes
      await tester.tap(notesField);
      await tester.enterText(notesField, 'Great dining experience!');
      await tester.pump();

      // Notes should be entered
      expect(find.text('Great dining experience!'), findsOneWidget);
    });

    testWidgets('should show auto-save indicator when form has draft data', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill in some data to trigger draft state
      final restaurantField = find.byType(TextFormField).first;
      await tester.tap(restaurantField);
      await tester.enterText(restaurantField, 'Test');
      await tester.pump();

      // Auto-save indicator should appear after some time
      // Note: This test may need adjustment based on auto-save timing
      await tester.pump(const Duration(seconds: 1));
      
      // Look for save indicator (cloud icon or save text)
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });
  });

  group('QuickActionButtons Widget Tests', () {
    testWidgets('should render quick action buttons', (WidgetTester tester) async {
      bool actionCalled = false;
      String? actionType;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickActionButtons(
                onQuickAction: (type) {
                  actionCalled = true;
                  actionType = type;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for quick action buttons
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Coffee Break'), findsOneWidget);
      expect(find.text('Quick Lunch'), findsOneWidget);
      expect(find.text('Grocery Run'), findsOneWidget);
      expect(find.text('Dinner Out'), findsOneWidget);
    });

    testWidgets('should handle quick action tap', (WidgetTester tester) async {
      bool actionCalled = false;
      String? actionType;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickActionButtons(
                onQuickAction: (type) {
                  actionCalled = true;
                  actionType = type;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap coffee break button
      await tester.tap(find.text('Coffee Break'));
      await tester.pump();

      expect(actionCalled, isTrue);
      expect(actionType, equals('coffee'));
    });
  });
}