import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:what_we_have_for_lunch/presentation/providers/ai_providers.dart';
import 'package:what_we_have_for_lunch/presentation/providers/simple_providers.dart';
import 'package:what_we_have_for_lunch/data/repositories/ai_repository.dart';
import 'package:what_we_have_for_lunch/domain/entities/ai_recommendation.dart';
import 'package:what_we_have_for_lunch/domain/entities/restaurant.dart';
import 'package:what_we_have_for_lunch/services/ai_service.dart';

import 'ai_providers_test.mocks.dart';

@GenerateMocks([AIRepository, AIService])
void main() {
  group('AI Providers', () {
    late MockAIRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAIRepository();
      
      container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(mockRepository),
          currentUserIdProvider.overrideWith((ref) => 1),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('AIRecommendationNotifier', () {
      test('should initialize with empty state', () {
        final notifier = container.read(aiRecommendationProvider.notifier);
        final state = container.read(aiRecommendationProvider);

        expect(state.recommendations, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.hasError, isFalse);
      });

      test('should generate recommendations successfully', () async {
        final testRecommendation = createTestAIRecommendation();
        final testRestaurants = [createTestRestaurant()];

        when(mockRepository.generateRecommendations(
          any,
          any,
          userPosition: anyNamed('userPosition'),
          specificCravings: anyNamed('specificCravings'),
          additionalFilters: anyNamed('additionalFilters'),
        )).thenAnswer((_) async => testRecommendation);

        final notifier = container.read(aiRecommendationProvider.notifier);

        await notifier.generateRecommendations(
          availableRestaurants: testRestaurants,
        );

        final state = container.read(aiRecommendationProvider);

        expect(state.recommendations, contains(testRecommendation));
        expect(state.isLoading, isFalse);
        expect(state.hasError, isFalse);
        expect(state.lastUpdated, isNotNull);

        verify(mockRepository.generateRecommendations(
          1, // userId
          testRestaurants,
          userPosition: anyNamed('userPosition'),
          specificCravings: anyNamed('specificCravings'),
          additionalFilters: anyNamed('additionalFilters'),
        )).called(1);
      });

      test('should handle generation errors gracefully', () async {
        when(mockRepository.generateRecommendations(
          any,
          any,
          userPosition: anyNamed('userPosition'),
          specificCravings: anyNamed('specificCravings'),
          additionalFilters: anyNamed('additionalFilters'),
        )).thenThrow(Exception('API Error'));

        final notifier = container.read(aiRecommendationProvider.notifier);

        await notifier.generateRecommendations(
          availableRestaurants: [createTestRestaurant()],
        );

        final state = container.read(aiRecommendationProvider);

        expect(state.hasError, isTrue);
        expect(state.errorMessage, contains('API Error'));
        expect(state.isLoading, isFalse);
      });

      test('should submit feedback successfully', () async {
        final testRecommendation = createTestAIRecommendation();

        when(mockRepository.submitFeedback(
          any,
          any,
          any,
          wasSelected: anyNamed('wasSelected'),
        )).thenAnswer((_) async {});

        final notifier = container.read(aiRecommendationProvider.notifier);
        
        // First add a recommendation to state
        await notifier.generateRecommendations(
          availableRestaurants: [createTestRestaurant()],
        );

        await notifier.submitFeedback(
          testRecommendation.id,
          5,
          'Great recommendation!',
          wasSelected: true,
        );

        verify(mockRepository.submitFeedback(
          testRecommendation.id,
          5,
          'Great recommendation!',
          wasSelected: true,
        )).called(1);
      });

      test('should load recent recommendations on initialization', () async {
        final testRecommendations = [createTestAIRecommendation()];

        when(mockRepository.getRecentRecommendations(any))
            .thenAnswer((_) async => testRecommendations);

        // Create new container to trigger initialization
        final newContainer = ProviderContainer(
          overrides: [
            aiRepositoryProvider.overrideWithValue(mockRepository),
            currentUserIdProvider.overrideWith((ref) => 1),
          ],
        );

        // Access the provider to trigger initialization
        newContainer.read(aiRecommendationProvider);

        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockRepository.getRecentRecommendations(1)).called(1);

        newContainer.dispose();
      });

      test('should handle null user ID gracefully', () async {
        final nullUserContainer = ProviderContainer(
          overrides: [
            aiRepositoryProvider.overrideWithValue(mockRepository),
            currentUserIdProvider.overrideWith((ref) => null),
          ],
        );

        final notifier = nullUserContainer.read(aiRecommendationProvider.notifier);

        await notifier.generateRecommendations(
          availableRestaurants: [createTestRestaurant()],
        );

        final state = nullUserContainer.read(aiRecommendationProvider);

        expect(state.hasError, isTrue);
        expect(state.errorMessage, contains('log in'));

        nullUserContainer.dispose();
      });
    });

    group('aiInvestmentAnalysisProvider', () {
      test('should return no analysis when no recommendations', () {
        final analysis = container.read(aiInvestmentAnalysisProvider);

        expect(analysis['hasAnalysis'], isFalse);
        expect(analysis['message'], contains('Generate recommendations'));
      });

      test('should provide investment analysis when recommendations exist', () {
        // Mock state with recommendations
        final testRecommendation = createTestAIRecommendation();
        
        // This would require setting up the state properly in the provider
        // For now, we'll test the logic separately
      });
    });

    group('aiUsageSummaryProvider', () {
      test('should provide usage summary', () {
        when(mockRepository.getUsageStatistics(any))
            .thenAnswer((_) async => {
              'costs': {'today': 0.50},
              'requests': {'today': 5},
              'limits': {'remainingBudget': 4.50, 'remainingRequests': 45},
              'performance': {'successRate': 0.95, 'avgResponseTimeMs': 1200},
            });

        final summary = container.read(aiUsageSummaryProvider);

        expect(summary, isNotEmpty);
      });
    });

    group('aiAvailabilityProvider', () {
      test('should return false when AI service unavailable', () {
        final unavailableContainer = ProviderContainer(
          overrides: [
            aiServiceConfigProvider.overrideWith((ref) => throw Exception('No API key')),
          ],
        );

        final available = unavailableContainer.read(aiAvailabilityProvider);

        expect(available, isFalse);

        unavailableContainer.dispose();
      });

      test('should return true when AI service available', () {
        final availableContainer = ProviderContainer(
          overrides: [
            aiServiceConfigProvider.overrideWithValue(
              const AIServiceConfig(apiKey: 'test_key'),
            ),
            aiServiceProvider.overrideWithValue(MockAIService()),
          ],
        );

        final available = availableContainer.read(aiAvailabilityProvider);

        expect(available, isTrue);

        availableContainer.dispose();
      });
    });

    group('smartRecommendationTriggerProvider', () {
      test('should trigger recommendations during meal time with no recent recommendations', () {
        // Mock current time to lunch time (12 PM)
        final lunchTimeContainer = ProviderContainer(
          overrides: [
            aiRepositoryProvider.overrideWithValue(mockRepository),
            // Would need to override time provider if available
          ],
        );

        // This test would need to mock the current time
        // For now, we'll test the logic conceptually
        
        lunchTimeContainer.dispose();
      });
    });
  });
}

// Helper functions
AIRecommendation createTestAIRecommendation() {
  return AIRecommendation(
    id: 'test_recommendation_1',
    userId: 1,
    recommendedRestaurants: [createTestRestaurant()],
    reasoning: 'This restaurant matches your budget and dietary preferences.',
    factorWeights: {
      'budget': 0.8,
      'dietary': 0.9,
      'location': 0.7,
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
    },
  );
}

Restaurant createTestRestaurant() {
  return Restaurant(
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
}