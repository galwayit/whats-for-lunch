import 'package:flutter_test/flutter_test.dart';

import 'package:what_we_have_for_lunch/services/ai_service.dart';
import 'package:what_we_have_for_lunch/domain/entities/ai_recommendation.dart';
import 'package:what_we_have_for_lunch/domain/entities/restaurant.dart';

void main() {
  group('AIService', () {
    late AIService aiService;
    late AIServiceConfig config;

    setUp(() {
      config = const AIServiceConfig(
        apiKey: 'test_api_key_123',
        model: 'gemini-1.5-flash',
        temperature: 0.7,
        maxTokens: 1000,
        costLimitPerDayDollars: 5.0,
        enableCaching: true,
      );
      
      // Note: In a real test, we would mock the GenerativeModel
      // For now, we'll test the configuration and error handling
    });

    group('Configuration', () {
      test('should create service with valid configuration', () {
        expect(() => AIService.create(config), returnsNormally);
      });

      test('should throw exception with empty API key', () {
        final invalidConfig = config.copyWith(apiKey: '');
        
        expect(
          () => AIService.create(invalidConfig),
          throwsA(isA<AIServiceException>()),
        );
      });

      test('should use default values for optional parameters', () {
        const minimalConfig = AIServiceConfig(apiKey: 'test_key');
        
        expect(minimalConfig.model, equals('gemini-1.5-flash'));
        expect(minimalConfig.temperature, equals(0.7));
        expect(minimalConfig.maxTokens, equals(1000));
      });
    });

    group('Cost Tracking', () {
      // These would be integration tests with a mock service
      testWidgets('should track daily cost usage', (tester) async {
        // Mock implementation would test cost tracking
      });

      testWidgets('should enforce daily cost limits', (tester) async {
        // Mock implementation would test cost limits
      });
    });

    group('Request Throttling', () {
      testWidgets('should throttle requests when limit exceeded', (tester) async {
        // Mock implementation would test throttling
      });

      testWidgets('should reset request counter after time window', (tester) async {
        // Mock implementation would test reset logic
      });
    });

    group('Error Handling', () {
      test('should handle configuration errors', () {
        expect(
          () => AIService.create(const AIServiceConfig(apiKey: '')),
          throwsA(isA<AIServiceException>()),
        );
      });
    });
  });
}

extension AIServiceTestUtils on AIServiceConfig {
  AIServiceConfig copyWith({
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    Duration? requestTimeout,
    int? maxRetries,
    double? costLimitPerDayDollars,
    bool? enableCaching,
  }) {
    return AIServiceConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      costLimitPerDayDollars: costLimitPerDayDollars ?? this.costLimitPerDayDollars,
      enableCaching: enableCaching ?? this.enableCaching,
    );
  }
}

// Helper function to create test restaurants
List<Restaurant> createTestRestaurants() {
  return [
    Restaurant(
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
    ),
    Restaurant(
      placeId: 'test_restaurant_2',
      name: 'Budget Eats',
      location: '456 Budget Ave',
      address: '456 Budget Avenue, Test City',
      latitude: 37.7849,
      longitude: -122.4094,
      rating: 4.0,
      reviewCount: 75,
      priceLevel: 1,
      averageMealCost: 12.0,
      valueScore: 0.9,
      cuisineTypes: ['Fast Food', 'American'],
      supportedDietaryRestrictions: ['vegetarian', 'vegan'],
      features: ['takeout', 'delivery'],
      isOpenNow: true,
      cachedAt: DateTime.now(),
    ),
  ];
}

// Helper function to create test user context
UserRecommendationContext createTestUserContext() {
  return UserRecommendationContext(
    userId: 1,
    dietaryPreferences: {
      'restrictions': ['vegetarian'],
      'preferences': ['healthy'],
    },
    budgetConstraints: {
      'min': 10.0,
      'max': 30.0,
      'preferred': 20.0,
    },
    locationContext: {
      'hasLocation': true,
      'latitude': 37.7749,
      'longitude': -122.4194,
    },
    recentMealHistory: ['lunch: \$15.00 (2d ago)', 'dinner: \$25.00 (1d ago)'],
    temporalContext: {
      'mealTime': 'lunch',
      'isWeekend': false,
    },
    preferenceScores: {
      'price_sensitivity': 0.7,
      'quality_over_price': 0.6,
    },
    contextGeneratedAt: DateTime.now(),
  );
}