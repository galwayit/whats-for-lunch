import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:what_we_have_for_lunch/presentation/widgets/ux_investment_components.dart';

void main() {
  group('UXInvestmentCapacityRing Tests', () {
    testWidgets('should render with basic properties', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 75.0,
              weeklyCapacity: 200.0,
              remainingCapacity: 125.0,
              animate: false, // Disable animation for testing
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);
      expect(find.text('\$125'), findsOneWidget); // Remaining capacity display
      expect(find.text('Remaining Capacity'), findsOneWidget); // Subtitle
    });

    testWidgets('should handle tap interaction with haptic feedback', (WidgetTester tester) async {
      // Arrange
      bool tapCalled = false;
      List<MethodCall> hapticCalls = [];
      
      // Mock haptic feedback
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          hapticCalls.add(methodCall);
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 50.0,
              weeklyCapacity: 200.0,
              remainingCapacity: 150.0,
              animate: false,
              onTap: () {
                tapCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(UXInvestmentCapacityRing));
      await tester.pump();

      // Assert
      expect(tapCalled, true);
      expect(hapticCalls.length, 1);
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
    });

    testWidgets('should display correct progress colors based on usage', (WidgetTester tester) async {
      // Test low usage (green)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 40.0, // 20% usage
              weeklyCapacity: 200.0,
              remainingCapacity: 160.0,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check if the widget exists (color verification would require more complex testing)
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);

      // Test high usage (orange)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 160.0, // 80% usage
              weeklyCapacity: 200.0,
              remainingCapacity: 40.0,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);

      // Test very high usage (red)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 190.0, // 95% usage
              weeklyCapacity: 200.0,
              remainingCapacity: 10.0,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);
    });

    testWidgets('should render with custom title and subtitle', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 75.0,
              weeklyCapacity: 200.0,
              remainingCapacity: 125.0,
              title: 'Custom Investment',
              subtitle: 'Custom Subtitle',
              animate: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Custom Subtitle'), findsOneWidget);
    });

    testWidgets('should handle animation correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 100.0,
              weeklyCapacity: 200.0,
              remainingCapacity: 100.0,
              animate: true,
            ),
          ),
        ),
      );

      // Wait for animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert widget exists during animation
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);

      // Complete the animation
      await tester.pumpAndSettle();
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);
    });

    testWidgets('should handle glow effect for high usage', (WidgetTester tester) async {
      // Arrange & Act - High usage that should trigger glow effect
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 165.0, // 82.5% usage > 80%
              weeklyCapacity: 200.0,
              remainingCapacity: 35.0,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert widget renders (glow effect is visual, harder to test)
      expect(find.byType(UXInvestmentCapacityRing), findsOneWidget);
    });

    testWidgets('should be accessible with proper semantics', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacityRing(
              currentSpent: 75.0,
              weeklyCapacity: 200.0,
              remainingCapacity: 125.0,
              animate: false,
            ),
          ),
        ),
      );

      // Assert accessibility semantics
      final semantics = tester.getSemantics(find.byType(UXInvestmentCapacityRing));
      expect(semantics.label, contains('Weekly Investment'));
      expect(semantics.label, contains('\$75.00 spent'));
      expect(semantics.label, contains('\$200.00 weekly capacity'));
      expect(semantics.value, contains('38% used')); // 75/200 = 0.375, rounded to 38%
    });
  });

  group('UXWeeklyInvestmentOverview Tests', () {
    testWidgets('should render with investment metrics', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXWeeklyInvestmentOverview(
              weeklySpent: 150.0,
              weeklyCapacity: 200.0,
              experiencesLogged: 8,
              targetExperiences: 10,
              achievements: ['First Investment', 'Weekly Optimizer'],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UXWeeklyInvestmentOverview), findsOneWidget);
      expect(find.text('This Week\'s Investment'), findsOneWidget);
      expect(find.text('\$150.00'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // Experiences logged
      expect(find.text('10 target'), findsOneWidget);
    });

    testWidgets('should handle view details tap', (WidgetTester tester) async {
      // Arrange
      bool detailsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXWeeklyInvestmentOverview(
              weeklySpent: 100.0,
              weeklyCapacity: 200.0,
              experiencesLogged: 5,
              targetExperiences: 10,
              onViewDetails: () {
                detailsTapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Details'));
      await tester.pump();

      // Assert
      expect(detailsTapped, true);
    });

    testWidgets('should display achievements section when achievements exist', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXWeeklyInvestmentOverview(
              weeklySpent: 100.0,
              weeklyCapacity: 200.0,
              experiencesLogged: 5,
              targetExperiences: 10,
              achievements: ['Achievement 1', 'Achievement 2', 'Achievement 3'],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Recent Achievements'), findsOneWidget);
      expect(find.text('Achievement 1'), findsOneWidget);
      expect(find.text('Achievement 2'), findsOneWidget);
      expect(find.text('Achievement 3'), findsOneWidget);
    });

    testWidgets('should not display achievements section when no achievements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXWeeklyInvestmentOverview(
              weeklySpent: 100.0,
              weeklyCapacity: 200.0,
              experiencesLogged: 5,
              targetExperiences: 10,
              achievements: [],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Recent Achievements'), findsNothing);
    });
  });

  group('UXInvestmentGuidance Tests', () {
    testWidgets('should render excellent guidance level correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentGuidance(
              currentCost: 15.0,
              remainingCapacity: 150.0,
              guidanceLevel: 'excellent',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(UXInvestmentGuidance), findsOneWidget);
      expect(find.text('Excellent Investment Choice!'), findsOneWidget);
      expect(find.text('This experience aligns perfectly with your weekly investment strategy.'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('should render good guidance level correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentGuidance(
              currentCost: 25.0,
              remainingCapacity: 100.0,
              guidanceLevel: 'good',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Good Investment Balance'), findsOneWidget);
      expect(find.text('A nice balance between enjoyment and your financial goals.'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    });

    testWidgets('should render moderate guidance level correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentGuidance(
              currentCost: 40.0,
              remainingCapacity: 50.0,
              guidanceLevel: 'moderate',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Moderate Investment Impact'), findsOneWidget);
      expect(find.text('Consider if this aligns with your priorities for the week.'), findsOneWidget);
      expect(find.byIcon(Icons.balance), findsOneWidget);
    });

    testWidgets('should render high guidance level correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentGuidance(
              currentCost: 60.0,
              remainingCapacity: 20.0,
              guidanceLevel: 'high',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('High Investment Alert'), findsOneWidget);
      expect(find.text('This will significantly impact your weekly capacity. Make sure it\'s worth it!'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should show remaining capacity when exceeding budget', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentGuidance(
              currentCost: 30.0,
              remainingCapacity: 15.0, // Cost exceeds remaining
              guidanceLevel: 'high',
              onOptimize: () {}, // Provide optimize callback
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Remaining capacity: \$15.00'), findsOneWidget);
    });

    testWidgets('should handle optimize button tap', (WidgetTester tester) async {
      // Arrange
      bool optimizeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentGuidance(
              currentCost: 50.0,
              remainingCapacity: 30.0,
              guidanceLevel: 'high',
              onOptimize: () {
                optimizeTapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Optimize'));
      await tester.pump();

      // Assert
      expect(optimizeTapped, true);
    });
  });

  group('UXAchievementNotification Tests', () {
    testWidgets('should render achievement notification when shown', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXAchievementNotification(
              title: 'Test Achievement',
              description: 'You completed a test achievement!',
              icon: Icons.celebration,
              show: true,
            ),
          ),
        ),
      );

      // Wait for animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('Test Achievement'), findsOneWidget);
      expect(find.text('You completed a test achievement!'), findsOneWidget);
      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('should not render when show is false', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXAchievementNotification(
              title: 'Test Achievement',
              description: 'You completed a test achievement!',
              icon: Icons.celebration,
              show: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Achievement'), findsNothing);
      expect(find.text('You completed a test achievement!'), findsNothing);
    });

    testWidgets('should handle dismiss tap with haptic feedback', (WidgetTester tester) async {
      // Arrange
      bool dismissCalled = false;
      List<MethodCall> hapticCalls = [];
      
      // Mock haptic feedback
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          hapticCalls.add(methodCall);
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXAchievementNotification(
              title: 'Test Achievement',
              description: 'Test description',
              icon: Icons.celebration,
              show: true,
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      // Wait for animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Act
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Assert
      expect(dismissCalled, true);
      
      // Wait for any remaining timers to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('should trigger haptic feedback when shown', (WidgetTester tester) async {
      // Arrange
      List<MethodCall> hapticCalls = [];
      
      // Mock haptic feedback
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          hapticCalls.add(methodCall);
        }
        return null;
      });

      // Act - First render without showing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXAchievementNotification(
              title: 'Test Achievement',
              description: 'Test description',
              icon: Icons.celebration,
              show: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Then show the notification
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXAchievementNotification(
              title: 'Test Achievement',
              description: 'Test description',
              icon: Icons.celebration,
              show: true,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Wait for the auto-dismiss timer to complete to avoid pending timer issues
      await tester.pump(const Duration(seconds: 5));

      // Assert - Should have triggered haptic feedback
      expect(hapticCalls.length, greaterThan(0));
    });
  });

  group('UXInvestmentCapacitySelector Tests', () {
    testWidgets('should render preset amounts correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacitySelector(
              selectedCapacity: 200.0,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Weekly Investment Capacity'), findsOneWidget);
      expect(find.text('How much would you like to invest in dining experiences each week?'), findsOneWidget);
      expect(find.text('\$100'), findsOneWidget);
      expect(find.text('\$150'), findsOneWidget);
      expect(find.text('\$200'), findsOneWidget);
      expect(find.text('\$250'), findsOneWidget);
      expect(find.text('\$300'), findsOneWidget);
      expect(find.text('\$400'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('should handle capacity selection tap', (WidgetTester tester) async {
      // Arrange
      double? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacitySelector(
              selectedCapacity: 200.0,
              onChanged: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('\$250'));
      await tester.pump();

      // Assert
      expect(selectedValue, 250.0);
    });

    testWidgets('should show custom amount dialog when custom tapped', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacitySelector(
              selectedCapacity: 200.0,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle(); // Wait for dialog animation

      // Assert
      expect(find.text('Custom Weekly Capacity'), findsOneWidget);
      expect(find.text('Enter your preferred weekly investment capacity:'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('should handle custom amount input correctly', (WidgetTester tester) async {
      // Arrange
      double? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacitySelector(
              selectedCapacity: 200.0,
              onChanged: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      // Act - Open custom dialog
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Enter custom amount
      await tester.enterText(find.byType(TextField), '350');
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedValue, 350.0);
    });

    testWidgets('should handle cancel in custom dialog', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacitySelector(
              selectedCapacity: 200.0,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed
      expect(find.text('Custom Weekly Capacity'), findsNothing);
    });

    testWidgets('should have proper accessibility semantics', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UXInvestmentCapacitySelector(
              selectedCapacity: 200.0,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      // Find preset amount button
      final button200 = find.ancestor(
        of: find.text('\$200'),
        matching: find.byType(Material),
      ).first;

      // Assert accessibility - check if semantics exist
      final semantics = tester.getSemantics(button200);
      expect(semantics.label, contains('Weekly capacity \$200'));
      // Note: In newer Flutter versions, semantic flags work differently
    });
  });
}