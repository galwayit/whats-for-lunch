import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/presentation/widgets/ux_components.dart';

void main() {
  group('UX Components Tests', () {
    
    group('UXPrimaryButton', () {
      testWidgets('should render correctly with text and icon', (WidgetTester tester) async {
        bool buttonPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXPrimaryButton(
                onPressed: () => buttonPressed = true,
                text: 'Test Button',
                icon: Icons.star,
              ),
            ),
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);

        await tester.tap(find.byType(UXPrimaryButton));
        expect(buttonPressed, isTrue);
      });

      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXPrimaryButton(
                onPressed: () {},
                text: 'Test Button',
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Test Button'), findsNothing);
      });

      testWidgets('should be disabled when onPressed is null', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXPrimaryButton(
                onPressed: null,
                text: 'Disabled Button',
              ),
            ),
          ),
        );

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });
    });

    group('UXSecondaryButton', () {
      testWidgets('should render correctly', (WidgetTester tester) async {
        bool buttonPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXSecondaryButton(
                onPressed: () => buttonPressed = true,
                text: 'Secondary Button',
                icon: Icons.edit,
              ),
            ),
          ),
        );

        expect(find.text('Secondary Button'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);

        await tester.tap(find.byType(UXSecondaryButton));
        expect(buttonPressed, isTrue);
      });
    });

    group('UXTextInput', () {
      testWidgets('should render with label and hint', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXTextInput(
                controller: controller,
                label: 'Test Label',
                hint: 'Test Hint',
              ),
            ),
          ),
        );

        expect(find.text('Test Label'), findsOneWidget);
        expect(find.text('Test Hint'), findsOneWidget);

        controller.dispose();
      });

      testWidgets('should show validation error', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXTextInput(
                controller: controller,
                label: 'Test Label',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        );

        // Trigger validation by entering and clearing text
        await tester.enterText(find.byType(TextFormField), 'test');
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), '');
        await tester.pump();

        expect(find.text('Required'), findsOneWidget);

        controller.dispose();
      });
    });

    group('UXCurrencyInput', () {
      testWidgets('should render with currency icon', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXCurrencyInput(
                controller: controller,
                label: 'Investment Amount',
              ),
            ),
          ),
        );

        expect(find.text('Investment Amount'), findsOneWidget);
        expect(find.byIcon(Icons.attach_money), findsOneWidget);

        controller.dispose();
      });

      testWidgets('should show positive message when provided', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXCurrencyInput(
                controller: controller,
                label: 'Investment Amount',
                positiveMessage: 'Great choice!',
              ),
            ),
          ),
        );

        // Enter some text to trigger the positive message display
        await tester.enterText(find.byType(TextFormField), '25.00');
        await tester.pump();

        expect(find.text('Great choice!'), findsOneWidget);
        expect(find.byIcon(Icons.celebration), findsOneWidget);

        controller.dispose();
      });

      testWidgets('should only allow numeric input', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXCurrencyInput(
                controller: controller,
                label: 'Investment Amount',
              ),
            ),
          ),
        );

        // Try to enter non-numeric characters
        await tester.enterText(find.byType(TextFormField), 'abc123.45def');
        await tester.pump();

        // Should only allow numeric characters and decimal point
        expect(controller.text, equals('123.45'));

        controller.dispose();
      });
    });

    group('UXRestaurantInput', () {
      testWidgets('should render with restaurant icon and autocomplete', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: UXRestaurantInput(
                  controller: controller,
                  label: 'Restaurant',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Restaurant'), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

        controller.dispose();
      });

      testWidgets('should show autocomplete suggestions', (WidgetTester tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: UXRestaurantInput(
                  controller: controller,
                  label: 'Restaurant',
                ),
              ),
            ),
          ),
        );

        // Enter text to trigger autocomplete
        await tester.enterText(find.byType(TextFormField), 'Local');
        await tester.pump();

        // Should show Local Cafe suggestion
        expect(find.text('Local Cafe'), findsOneWidget);

        controller.dispose();
      });
    });

    group('UXMealCategorySelector', () {
      testWidgets('should render category options', (WidgetTester tester) async {
        const categories = [
          MealCategoryOption(
            id: 'dining_out',
            name: 'Dining Out',
            description: 'Restaurant experience',
            icon: Icons.restaurant,
            suggestedBudget: 25.0,
          ),
          MealCategoryOption(
            id: 'delivery',
            name: 'Delivery',
            description: 'Food delivered',
            icon: Icons.delivery_dining,
            suggestedBudget: 20.0,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMealCategorySelector(
                selectedCategory: 'dining_out',
                categories: categories,
                onChanged: (category) {},
              ),
            ),
          ),
        );

        expect(find.text('Experience Type'), findsOneWidget);
        expect(find.text('Dining Out'), findsOneWidget);
        expect(find.text('Delivery'), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.delivery_dining), findsOneWidget);
      });

      testWidgets('should handle category selection', (WidgetTester tester) async {
        String? selectedCategory;
        const categories = [
          MealCategoryOption(
            id: 'dining_out',
            name: 'Dining Out',
            description: 'Restaurant experience',
            icon: Icons.restaurant,
            suggestedBudget: 25.0,
          ),
          MealCategoryOption(
            id: 'delivery',
            name: 'Delivery',
            description: 'Food delivered',
            icon: Icons.delivery_dining,
            suggestedBudget: 20.0,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXMealCategorySelector(
                selectedCategory: 'dining_out',
                categories: categories,
                onChanged: (category) => selectedCategory = category,
              ),
            ),
          ),
        );

        // Tap delivery option
        await tester.tap(find.text('Delivery'));
        await tester.pump();

        expect(selectedCategory, equals('delivery'));
      });
    });

    group('UXDateTimePicker', () {
      testWidgets('should render with date and time selectors', (WidgetTester tester) async {
        final now = DateTime.now();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDateTimePicker(
                selectedDateTime: now,
                onChanged: (dateTime) {},
              ),
            ),
          ),
        );

        expect(find.text('Experience Date & Time'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('should show Yesterday for yesterday\'s date', (WidgetTester tester) async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXDateTimePicker(
                selectedDateTime: yesterday,
                onChanged: (dateTime) {},
              ),
            ),
          ),
        );

        expect(find.text('Yesterday'), findsOneWidget);
      });
    });

    group('UXBudgetImpactCard', () {
      testWidgets('should render budget impact with low impact', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXBudgetImpactCard(
                currentCost: 10.0,
                weeklyBudget: 200.0,
                impactMessage: 'Great choice!',
                impactLevel: 'low',
              ),
            ),
          ),
        );

        expect(find.text('Investment Impact'), findsOneWidget);
        expect(find.text('Great choice!'), findsOneWidget);
        expect(find.text('5.0%'), findsOneWidget); // 10/200 * 100
        expect(find.text('Remaining weekly budget: \$190.00'), findsOneWidget);
        expect(find.byIcon(Icons.eco), findsOneWidget); // Low impact icon
      });

      testWidgets('should render budget impact with high impact', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXBudgetImpactCard(
                currentCost: 50.0,
                weeklyBudget: 200.0,
                impactMessage: 'A special experience',
                impactLevel: 'high',
              ),
            ),
          ),
        );

        expect(find.text('A special experience'), findsOneWidget);
        expect(find.text('25.0%'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget); // High impact icon
      });
    });

    group('UXErrorState', () {
      testWidgets('should render error with retry button', (WidgetTester tester) async {
        bool retryPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXErrorState(
                title: 'Something went wrong',
                message: 'Please try again',
                onRetry: () => retryPressed = true,
              ),
            ),
          ),
        );

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Please try again'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        await tester.tap(find.text('Try Again'));
        expect(retryPressed, isTrue);
      });
    });

    group('UXLoadingOverlay', () {
      testWidgets('should show loading overlay when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXLoadingOverlay(
                isLoading: true,
                message: 'Loading...',
                child: Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
        expect(find.text('Content'), findsOneWidget);
      });

      testWidgets('should not show loading overlay when not loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXLoadingOverlay(
                isLoading: false,
                child: Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Content'), findsOneWidget);
      });
    });

    group('UXCard', () {
      testWidgets('should render card with content', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXCard(
                child: Text('Card Content'),
              ),
            ),
          ),
        );

        expect(find.text('Card Content'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should handle tap when onTap provided', (WidgetTester tester) async {
        bool cardTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UXCard(
                onTap: () => cardTapped = true,
                child: const Text('Tappable Card'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tappable Card'));
        expect(cardTapped, isTrue);
      });
    });

    group('UXFadeIn', () {
      testWidgets('should render child widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXFadeIn(
                child: Text('Fade In Content'),
              ),
            ),
          ),
        );

        // Allow animations to complete
        await tester.pumpAndSettle();
        expect(find.text('Fade In Content'), findsOneWidget);
      });

      testWidgets('should start with low opacity and animate to full opacity', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UXFadeIn(
                duration: Duration(milliseconds: 100),
                child: Text('Fade In Content'),
              ),
            ),
          ),
        );

        // Initially should have low opacity
        Opacity opacityWidget = tester.widget(find.byType(Opacity));
        expect(opacityWidget.opacity, equals(0.0));

        // After animation completes
        await tester.pumpAndSettle();
        opacityWidget = tester.widget(find.byType(Opacity));
        expect(opacityWidget.opacity, equals(1.0));
      });
    });
  });
}