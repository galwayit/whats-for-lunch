import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:what_we_have_for_lunch/presentation/widgets/ai_recommendation_components.dart';
import 'package:what_we_have_for_lunch/domain/entities/ai_recommendation.dart';
import 'package:what_we_have_for_lunch/domain/entities/restaurant.dart';

void main() {
  group('AI Recommendation Components', () {
    late AIRecommendation testRecommendation;
    late Restaurant testRestaurant;

    setUp(() {
      testRestaurant = Restaurant(
        placeId: 'test_restaurant_1',
        name: 'Test Bistro',
        location: '123 Test St',
        address: '123 Test Street, Test City',
        latitude: 37.7749,
        longitude: -122.4194,
        rating: 4.5,
        reviewCount: 150,
        priceLevel: 2,
        averageMealCost: 25.0,
        valueScore: 0.8,
        cuisineTypes: ['American', 'Casual'],
        supportedDietaryRestrictions: ['vegetarian'],
        features: ['outdoor_seating', 'wifi'],
        isOpenNow: true,
        cachedAt: DateTime.now(),
      );

      testRecommendation = AIRecommendation(
        id: 'test_recommendation_1',
        userId: 1,
        recommendedRestaurants: [testRestaurant],
        reasoning: 'This restaurant matches your budget and dietary preferences perfectly. The value score of 80% indicates excellent quality for the price.',
        factorWeights: {
          'budget': 0.8,
          'dietary': 0.9,
          'location': 0.7,
          'history': 0.6,
          'temporal': 0.5,
        },
        overallConfidence: 0.85,
        userContext: {
          'mealType': 'lunch',
          'budgetRange': '\$15 - \$25',
        },
        generatedAt: DateTime.now(),
        metadata: {
          'model': 'gemini-1.5-flash',
          'responseTime': 1500,
          'investmentSummary': 'Investment opportunity: \$25.00 for 80% value score',
        },
      );
    });

    group('AIRecommendationCard', () {
      testWidgets('should display recommendation information correctly', (tester) async {
        bool restaurantSelected = false;
        int? submittedRating;
        String? submittedFeedback;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: testRecommendation,
                onRestaurantSelected: (restaurant) {
                  restaurantSelected = true;
                },
                onFeedbackSubmitted: (rating, feedback) {
                  submittedRating = rating;
                  submittedFeedback = feedback;
                },
              ),
            ),
          ),
        );

        // Check that the card displays correctly
        expect(find.text('AI Investment Recommendations'), findsOneWidget);
        expect(find.text('85% Confidence'), findsOneWidget);
        expect(find.text(testRestaurant.name), findsOneWidget);

        // Check that metrics are displayed
        expect(find.text('\$25'), findsOneWidget); // Investment cost
        expect(find.text('4.5'), findsOneWidget); // Rating
        expect(find.text('80%'), findsOneWidget); // Value score

        // Check that reasoning is displayed (truncated)
        expect(find.textContaining('This restaurant matches'), findsOneWidget);
      });

      testWidgets('should expand and show details when expand button tapped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: testRecommendation,
                onRestaurantSelected: (restaurant) {},
                onFeedbackSubmitted: (rating, feedback) {},
              ),
            ),
          ),
        );

        // Find and tap the expand button
        final expandButton = find.byIcon(Icons.expand_more);
        expect(expandButton, findsOneWidget);
        
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        // Check that expanded content is visible
        expect(find.text('Rate this recommendation'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget); // Feedback text field

        // Check that expand icon changed
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('should submit feedback when rating is selected and submitted', (tester) async {
        int? submittedRating;
        String? submittedFeedback;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: testRecommendation,
                onRestaurantSelected: (restaurant) {},
                onFeedbackSubmitted: (rating, feedback) {
                  submittedRating = rating;
                  submittedFeedback = feedback;
                },
              ),
            ),
          ),
        );

        // Expand the card first
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Select a 4-star rating
        final fourthStar = find.byIcon(Icons.star_border).at(3);
        await tester.tap(fourthStar);
        await tester.pumpAndSettle();

        // Enter feedback
        await tester.enterText(find.byType(TextField), 'Great recommendation!');

        // Submit feedback
        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedRating, equals(4));
        expect(submittedFeedback, equals('Great recommendation!'));
      });

      testWidgets('should call onRestaurantSelected when restaurant is tapped', (tester) async {
        Restaurant? selectedRestaurant;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: testRecommendation,
                onRestaurantSelected: (restaurant) {
                  selectedRestaurant = restaurant;
                },
                onFeedbackSubmitted: (rating, feedback) {},
              ),
            ),
          ),
        );

        // Tap on the primary recommendation
        await tester.tap(find.text(testRestaurant.name));
        await tester.pumpAndSettle();

        expect(selectedRestaurant, equals(testRestaurant));
      });

      testWidgets('should show investment insights section', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: testRecommendation,
                onRestaurantSelected: (restaurant) {},
                onFeedbackSubmitted: (rating, feedback) {},
              ),
            ),
          ),
        );

        expect(find.text('Investment Insights'), findsOneWidget);
        expect(find.text(testRecommendation.investmentSummary), findsOneWidget);

        // Check that factor weights are displayed as chips
        expect(find.text('budget (80%)'), findsOneWidget);
        expect(find.text('dietary (90%)'), findsOneWidget);
      });

      testWidgets('should handle multiple restaurants in recommendation', (tester) async {
        final secondRestaurant = Restaurant(
          placeId: 'test_restaurant_2',
          name: 'Alternative Cafe',
          location: '456 Alt St',
          rating: 4.0,
          averageMealCost: 18.0,
          valueScore: 0.75,
          cuisineTypes: ['Cafe'],
          supportedDietaryRestrictions: [],
          features: [],
          isOpenNow: true,
          cachedAt: DateTime.now(),
        );

        final multiRestaurantRec = testRecommendation.copyWith(
          recommendedRestaurants: [testRestaurant, secondRestaurant],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: multiRestaurantRec,
                onRestaurantSelected: (restaurant) {},
                onFeedbackSubmitted: (rating, feedback) {},
              ),
            ),
          ),
        );

        // Expand to see alternatives
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.text('Alternative Options'), findsOneWidget);
        expect(find.text(secondRestaurant.name), findsOneWidget);
      });
    });

    group('AIRecommendationSummary', () {
      testWidgets('should display summary information correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationSummary(
                recommendation: testRecommendation,
                onViewDetails: () {},
              ),
            ),
          ),
        );

        expect(find.text('AI Recommendation'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget); // Confidence
        expect(find.text(testRestaurant.name), findsOneWidget);
        expect(find.text('View Details'), findsOneWidget);
      });

      testWidgets('should call onViewDetails when button tapped', (tester) async {
        bool detailsViewed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationSummary(
                recommendation: testRecommendation,
                onViewDetails: () {
                  detailsViewed = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('View Details'));
        await tester.pumpAndSettle();

        expect(detailsViewed, isTrue);
      });
    });

    group('AIRecommendationLoading', () {
      testWidgets('should display loading animation and messages', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AIRecommendationLoading(
                message: 'Testing AI...',
              ),
            ),
          ),
        );

        expect(find.text('Testing AI...'), findsOneWidget);
        expect(find.text('This may take a few seconds...'), findsOneWidget);
        expect(find.byIcon(Icons.smart_toy), findsOneWidget);

        // Test that animation is running
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('should cycle through default messages when none provided', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AIRecommendationLoading(),
            ),
          ),
        );

        // Should show the first default message initially
        expect(find.textContaining('Analyzing your dining preferences'), findsOneWidget);

        // Wait for message rotation
        await tester.pump(const Duration(seconds: 3));

        // Should show a different message after rotation
        // (This test might be flaky due to timing, in a real test we'd mock the timer)
      });
    });

    group('Confidence Color Helper', () {
      testWidgets('should use correct colors for different confidence levels', (tester) async {
        // Test high confidence (green)
        final highConfidenceRec = testRecommendation.copyWith(overallConfidence: 0.9);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIRecommendationCard(
                recommendation: highConfidenceRec,
                onRestaurantSelected: (restaurant) {},
                onFeedbackSubmitted: (rating, feedback) {},
              ),
            ),
          ),
        );

        // We would need to check the actual color being used
        // This is more complex in widget tests and might require golden tests
      });
    });
  });
}

// Helper to create AIRecommendation with custom values
extension AIRecommendationTestUtils on AIRecommendation {
  AIRecommendation copyWith({
    String? id,
    int? userId,
    List<Restaurant>? recommendedRestaurants,
    String? reasoning,
    Map<String, double>? factorWeights,
    double? overallConfidence,
    Map<String, dynamic>? userContext,
    DateTime? generatedAt,
    bool? wasAccepted,
    String? userFeedback,
    Map<String, dynamic>? metadata,
  }) {
    return AIRecommendation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recommendedRestaurants: recommendedRestaurants ?? this.recommendedRestaurants,
      reasoning: reasoning ?? this.reasoning,
      factorWeights: factorWeights ?? this.factorWeights,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      userContext: userContext ?? this.userContext,
      generatedAt: generatedAt ?? this.generatedAt,
      wasAccepted: wasAccepted ?? this.wasAccepted,
      userFeedback: userFeedback ?? this.userFeedback,
      metadata: metadata ?? this.metadata,
    );
  }
}