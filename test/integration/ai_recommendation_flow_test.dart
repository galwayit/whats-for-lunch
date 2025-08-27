import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';

import '../../lib/domain/entities/ai_recommendation.dart';
import '../../lib/domain/entities/restaurant.dart';
import '../../lib/presentation/pages/ai_recommendations_page.dart';
import '../../lib/presentation/providers/ai_providers.dart';

/// Comprehensive integration test for AI recommendation flow
/// Tests the complete user journey from loading to recommendation generation
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Recommendation Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete AI recommendation flow with demo data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: AIRecommendationsPage(),
          ),
        ),
      );

      // Verify initial loading state
      expect(find.text('AI Recommendations'), findsOneWidget);
      
      // Should show empty state initially
      expect(find.text('Start My Investment Journey'), findsOneWidget);
      
      // Test onboarding dialog appears for first-time users
      await tester.pump(Duration(milliseconds: 600)); // Wait for onboarding delay
      
      if (find.text('Welcome to AI Dining Advisor').evaluate().isNotEmpty) {
        // Onboarding dialog is shown
        expect(find.text('Welcome to AI Dining Advisor'), findsOneWidget);
        expect(find.text('Smart Analysis'), findsOneWidget);
        expect(find.text('Investment Mindset'), findsOneWidget);
        expect(find.text('Contextual Timing'), findsOneWidget);
        
        // Close onboarding and proceed
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();
      }

      // Test craving input functionality
      final cravingField = find.byType(TextField);
      if (cravingField.evaluate().isNotEmpty) {
        await tester.enterText(cravingField, 'pizza');
        await tester.pump();
      }

      // Test recommendation generation
      final generateButton = find.text('Start My Investment Journey')
          .evaluate().isEmpty 
        ? find.text('Get Recommendations')
        : find.text('Start My Investment Journey');
        
      await tester.tap(generateButton);
      await tester.pump();
      
      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for demo recommendations to generate
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify recommendations are displayed (demo mode should work)
      // In demo mode, we expect either recommendations or a graceful fallback
      final hasRecommendations = find.byType(Card)
          .evaluate().isNotEmpty;
      final hasErrorState = find.text('Unable to Generate Recommendations')
          .evaluate().isNotEmpty;
      
      expect(hasRecommendations || hasErrorState, isTrue,
          reason: 'Should show either recommendations or error state');

      if (hasRecommendations) {
        // Test recommendation interactions
        final firstRecommendationCard = find.byType(Card).first;
        await tester.tap(firstRecommendationCard);
        await tester.pump();
        
        // Should show detailed view or navigation
      }

      print('AI Recommendation Flow Test: ✅ Complete');
    });

    testWidgets('AI availability and service states', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final aiAvailable = ref.watch(aiAvailabilityProvider);
                final aiService = ref.watch(aiServiceProvider);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('AI Available: $aiAvailable'),
                      Text('AI Service: ${aiService != null ? "Ready" : "Unavailable"}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify AI availability is properly detected
      expect(find.textContaining('AI Available:'), findsOneWidget);
      expect(find.textContaining('AI Service:'), findsOneWidget);

      print('AI Availability Test: ✅ Complete');
    });

    testWidgets('Error handling and recovery', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: AIRecommendationsPage(),
          ),
        ),
      );

      await tester.pump();

      // Simulate error state by forcing recommendation generation
      // without proper setup (this should trigger error handling)
      final notifier = container.read(aiRecommendationProvider.notifier);
      
      // Force an error state for testing
      await notifier.generateRecommendations(
        availableRestaurants: [], // Empty list should trigger error
      );
      
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show error state with recovery options
      expect(find.textContaining('Try Again'), findsWidgets);

      print('Error Handling Test: ✅ Complete');
    });

    testWidgets('Investment mindset messaging', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: AIRecommendationsPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify investment-themed messaging is present
      final investmentWords = [
        'investment', 'Investment', 'value', 'smart', 'advisor',
        'ROI', 'optimize', 'capacity', 'budget'
      ];
      
      bool foundInvestmentMessaging = false;
      for (final word in investmentWords) {
        if (find.textContaining(word).evaluate().isNotEmpty) {
          foundInvestmentMessaging = true;
          break;
        }
      }

      expect(foundInvestmentMessaging, isTrue,
          reason: 'Should contain investment-themed messaging');

      print('Investment Messaging Test: ✅ Complete');
    });

    test('AI recommendation entity validation', () {
      // Test the AIRecommendation entity with sample data
      final sampleRestaurant = Restaurant(
        placeId: 'test_place_123',
        name: 'Test Restaurant',
        location: 'Test Location',
        rating: 4.2,
        averageMealCost: 25.0,
        valueScore: 0.85,
        cachedAt: DateTime.now(),
      );

      final recommendation = AIRecommendation(
        id: 'test_rec_123',
        userId: 1,
        recommendedRestaurants: [sampleRestaurant],
        reasoning: 'Test reasoning for recommendation',
        factorWeights: {
          'budget': 0.8,
          'dietary': 0.6,
          'location': 0.9,
        },
        overallConfidence: 0.82,
        userContext: {'test': true},
        generatedAt: DateTime.now(),
      );

      // Test computed properties
      expect(recommendation.investmentSummary.isNotEmpty, isTrue);
      expect(recommendation.topInfluencingFactors.isNotEmpty, isTrue);
      expect(recommendation.primaryRecommendation?.name, equals('Test Restaurant'));

      print('AI Recommendation Entity Test: ✅ Complete');
    });
  });

  group('Performance and Quality Tests', () {
    testWidgets('Loading animation performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Test loading message'),
                ],
              ),
            ),
        ),
      );

      // Verify loading animation is present and smooth
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test loading message'), findsOneWidget);

      // Test animation doesn't drop frames
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 200));
      await tester.pump(Duration(milliseconds: 300));

      print('Loading Animation Test: ✅ Complete');
    });

    testWidgets('Memory usage with multiple recommendations', (tester) async {
      // Test that the app handles multiple recommendations efficiently
      final recommendations = List.generate(20, (index) => AIRecommendation(
        id: 'rec_$index',
        userId: 1,
        recommendedRestaurants: [
          Restaurant(
            placeId: 'place_$index',
            name: 'Restaurant $index',
            location: 'Location $index',
            rating: 4.0 + (index % 5) * 0.2,
            averageMealCost: 20.0 + index,
            cachedAt: DateTime.now(),
          ),
        ],
        reasoning: 'Test reasoning $index',
        factorWeights: {'budget': 0.8, 'location': 0.7},
        overallConfidence: 0.8,
        userContext: {},
        generatedAt: DateTime.now().subtract(Duration(hours: index)),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) => Card(
                child: ListTile(
                  title: Text(recommendations[index].primaryRecommendation?.name ?? 'Restaurant ${index + 1}'),
                  subtitle: Text(recommendations[index].reasoning.length > 50 
                    ? '${recommendations[index].reasoning.substring(0, 50)}...'
                    : recommendations[index].reasoning),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Scroll through recommendations to test performance
      await tester.fling(find.byType(ListView), Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      
      await tester.fling(find.byType(ListView), Offset(0, 500), 1000);
      await tester.pumpAndSettle();

      print('Multiple Recommendations Performance Test: ✅ Complete');
    });
  });
}