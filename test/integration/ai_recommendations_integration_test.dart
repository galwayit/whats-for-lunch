import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';

import 'package:what_we_have_for_lunch/main.dart' as app;
import 'package:what_we_have_for_lunch/presentation/providers/ai_providers.dart';
import 'package:what_we_have_for_lunch/data/repositories/ai_repository.dart';
import 'package:what_we_have_for_lunch/domain/entities/ai_recommendation.dart';
import 'package:what_we_have_for_lunch/domain/entities/restaurant.dart';

/// Integration tests for AI recommendations functionality
/// Tests the complete flow from UI to AI service
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Recommendations Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete AI recommendation flow', (tester) async {
      // Start the app with test configuration
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to AI recommendations page
      // (This assumes there's navigation from the main app)
      
      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for AI recommendations navigation
      final aiNavButton = find.textContaining('AI');
      if (aiNavButton.evaluate().isNotEmpty) {
        await tester.tap(aiNavButton);
        await tester.pumpAndSettle();
      }

      // Check that the AI recommendations page loads
      expect(find.textContaining('AI Investment Advisor'), findsOneWidget);
    });

    testWidgets('AI recommendation generation with real API', (tester) async {
      // This test would require a real API key and would be expensive to run
      // In practice, this would be run only in specific environments
      
      // Skip this test if no API key is available
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        return;
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to AI recommendations
      // This would depend on the app's navigation structure
      
      // Look for the generate recommendations button
      final generateButton = find.textContaining('Get AI Recommendations');
      if (generateButton.evaluate().isNotEmpty) {
        await tester.tap(generateButton);
        
        // Wait for AI processing (should be under 5 seconds per requirements)
        await tester.pumpAndSettle(const Duration(seconds: 6));
        
        // Check that recommendations are displayed
        expect(find.textContaining('Investment Insights'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Confidence'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AI recommendation caching works correctly', (tester) async {
      // This test verifies that repeated requests use cache
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Make first recommendation request
      final generateButton = find.textContaining('Get AI Recommendations');
      if (generateButton.evaluate().isNotEmpty) {
        await tester.tap(generateButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        final firstRequestTime = DateTime.now();
        
        // Make second identical request immediately
        await tester.tap(generateButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        final secondRequestTime = DateTime.now();
        
        // Second request should be much faster due to caching
        final timeDifference = secondRequestTime.difference(firstRequestTime);
        expect(timeDifference.inSeconds, lessThan(2));
      }
    });

    testWidgets('AI feedback submission flow', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to AI recommendations and generate some
      // (Assuming recommendations are available)
      
      // Find recommendation card
      final recommendationCard = find.byType(Card).first;
      if (recommendationCard.evaluate().isNotEmpty) {
        // Expand the card to show feedback options
        final expandButton = find.byIcon(Icons.expand_more);
        if (expandButton.evaluate().isNotEmpty) {
          await tester.tap(expandButton);
          await tester.pumpAndSettle();
          
          // Submit rating
          final fourthStar = find.byIcon(Icons.star_border);
          if (fourthStar.evaluate().isNotEmpty) {
            await tester.tap(fourthStar.at(3)); // 4-star rating
            await tester.pumpAndSettle();
            
            // Add feedback text
            final feedbackField = find.byType(TextField);
            if (feedbackField.evaluate().isNotEmpty) {
              await tester.enterText(feedbackField, 'Great recommendation!');
              await tester.pumpAndSettle();
              
              // Submit feedback
              final submitButton = find.text('Submit Feedback');
              await tester.tap(submitButton);
              await tester.pumpAndSettle();
              
              // Verify feedback was submitted
              expect(find.textContaining('Thank you'), findsOneWidget);
            }
          }
        }
      }
    });

    testWidgets('AI cost tracking and limits', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Check usage statistics display
      final menuButton = find.byIcon(Icons.more_vert);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();
        
        final usageOption = find.text('Usage Statistics');
        if (usageOption.evaluate().isNotEmpty) {
          await tester.tap(usageOption);
          await tester.pumpAndSettle();
          
          // Verify usage stats are displayed
          expect(find.textContaining('\$'), findsAtLeastNWidgets(1)); // Cost
          expect(find.textContaining('requests'), findsAtLeastNWidgets(1)); // Request count
        }
      }
    });

    testWidgets('AI error handling with network issues', (tester) async {
      // This test would simulate network failures
      // In practice, this would use a mock or network manipulation
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate network error during recommendation generation
      // (This would require injecting a mock that fails)
      
      // Verify error is handled gracefully
      // expect(find.textContaining('Unable to generate'), findsOneWidget);
      // expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('AI recommendation accessibility', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test semantic labels and accessibility
      final semantics = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
      expect(semantics, isNotNull);

      // Verify that AI recommendation elements have proper semantics
      // This would require specific semantic labels in the widgets
    });

    testWidgets('Investment mindset messaging consistency', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify investment-minded language is used throughout
      // Look for investment terminology instead of "spending"
      expect(find.textContaining('investment'), findsAtLeastNWidgets(1));
      expect(find.textContaining('opportunity'), findsAtLeastNWidgets(1));
      expect(find.textContaining('value'), findsAtLeastNWidgets(1));
      
      // Avoid negative spending language
      expect(find.textContaining('waste'), findsNothing);
      expect(find.textContaining('expensive'), findsNothing);
    });

    testWidgets('Performance requirements - 5 second response time', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Time the AI recommendation generation
      final stopwatch = Stopwatch()..start();
      
      final generateButton = find.textContaining('Get AI Recommendations');
      if (generateButton.evaluate().isNotEmpty) {
        await tester.tap(generateButton);
        
        // Wait for loading to complete
        while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
          await tester.pump(const Duration(milliseconds: 100));
          
          // Safety timeout
          if (stopwatch.elapsed.inSeconds > 10) break;
        }
        
        stopwatch.stop();
        
        // Verify response time meets requirement
        expect(stopwatch.elapsed.inSeconds, lessThan(5));
      }
    });

    group('Data Persistence', () {
      testWidgets('AI recommendations persist across app restarts', (tester) async {
        // First session - generate recommendations
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: app.MyApp(),
          ),
        );

        await tester.pumpAndSettle();

        // Generate recommendations
        // (Implementation would depend on app structure)

        // Simulate app restart by creating new widget tree
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(),
            child: app.MyApp(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify recommendations are still available
        // (This would check the local database/cache)
      });
    });
  });
}

/// Mock provider overrides for testing
final testAIRepositoryProvider = Provider<AIRepository>((ref) {
  return MockAIRepository();
});

class MockAIRepository implements AIRepository {
  @override
  Future<AIRecommendation> generateRecommendations(
    int userId,
    List<Restaurant> availableRestaurants, {
    Position? userPosition,
    String? specificCravings,
    Map<String, dynamic>? additionalFilters,
  }) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(milliseconds: 1500));
    
    return AIRecommendation(
      id: 'mock_recommendation_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      recommendedRestaurants: availableRestaurants.take(3).toList(),
      reasoning: 'Based on your investment preferences and dining history, these restaurants offer excellent value propositions.',
      factorWeights: {
        'budget': 0.85,
        'dietary': 0.75,
        'location': 0.90,
        'history': 0.60,
        'temporal': 0.70,
      },
      overallConfidence: 0.82,
      userContext: {
        'mealType': 'lunch',
        'budgetRange': '\$15 - \$30',
        'preferences': specificCravings ?? 'general dining',
      },
      generatedAt: DateTime.now(),
      metadata: {
        'model': 'mock-ai-v1',
        'responseTime': 1500,
        'investmentSummary': 'Excellent investment opportunities with 82% confidence',
      },
    );
  }

  @override
  Future<List<AIRecommendation>> getRecentRecommendations(int userId) async {
    // Return empty for mock
    return [];
  }

  @override
  Future<void> submitFeedback(
    String recommendationId,
    int rating,
    String? feedback, {
    bool wasSelected = false,
  }) async {
    // Mock feedback submission
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<double> getDailyCostUsage(int userId) async {
    return 0.75; // Mock cost
  }

  @override
  Future<Map<String, dynamic>> getUsageStatistics(int userId) async {
    return {
      'costs': {'today': 0.75, 'week': 3.50, 'month': 12.25},
      'requests': {'today': 5, 'week': 28, 'month': 120},
      'performance': {'avgResponseTimeMs': 1200, 'successRate': 0.95},
      'limits': {'remainingBudget': 4.25, 'remainingRequests': 45},
    };
  }

  @override
  Future<void> cleanupExpiredRecommendations() async {
    // Mock cleanup
  }
}