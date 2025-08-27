import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';

import 'package:what_we_have_for_lunch/services/user_context_service.dart';
import 'package:what_we_have_for_lunch/domain/entities/ai_recommendation.dart';
import 'package:what_we_have_for_lunch/domain/entities/restaurant.dart' as entity;
import 'package:what_we_have_for_lunch/data/database/database.dart';

import 'user_context_service_test.mocks.dart';

@GenerateMocks([AppDatabase, User])
void main() {
  group('UserContextService', () {
    late UserContextService contextService;
    late MockAppDatabase mockDatabase;
    late MockUser mockUser;

    setUp(() {
      mockDatabase = MockAppDatabase();
      contextService = UserContextService(mockDatabase);
      mockUser = MockUser();
    });

    group('generateUserContext', () {
      test('should generate comprehensive user context', () async {
        const userId = 1;
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        
        // Mock database responses
        when(mockDatabase.getDatabaseUserById(userId))
            .thenAnswer((_) async => mockUser);
        
        when(mockUser.preferences).thenReturn('{"weeklyBudget": 200.0, "dietaryRestrictions": ["vegetarian"]}');
        
        when(mockDatabase.getMealsByDateRange(userId, any, any))
            .thenAnswer((_) async => [
              Meal(
                id: 1,
                userId: userId,
                mealType: 'lunch',
                cost: 15.0,
                date: now.subtract(const Duration(days: 1)),
                photoIds: '[]',
              ),
              Meal(
                id: 2,
                userId: userId,
                mealType: 'dinner',
                cost: 25.0,
                date: now.subtract(const Duration(days: 2)),
                photoIds: '[]',
              ),
            ]);

        final context = await contextService.generateUserContext(userId);

        expect(context.userId, equals(userId));
        expect(context.dietaryPreferences['restrictions'], contains('vegetarian'));
        expect(context.budgetConstraints['weeklyBudget'], equals(200.0));
        expect(context.recentMealHistory, isNotEmpty);
        expect(context.temporalContext['currentTime'], isNotNull);
        expect(context.contextGeneratedAt, isNotNull);
      });

      test('should handle user with no preferences', () async {
        const userId = 1;
        
        when(mockDatabase.getDatabaseUserById(userId))
            .thenAnswer((_) async => null);
        
        when(mockDatabase.getMealsByDateRange(userId, any, any))
            .thenAnswer((_) async => []);

        final context = await contextService.generateUserContext(userId);

        expect(context.userId, equals(userId));
        expect(context.dietaryPreferences['restrictions'], isEmpty);
        expect(context.budgetConstraints['weeklyBudget'], equals(200.0)); // Default
        expect(context.recentMealHistory, isEmpty);
      });

      test('should include location context when position provided', () async {
        const userId = 1;
        final position = Position(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        when(mockDatabase.getDatabaseUserById(userId))
            .thenAnswer((_) async => null);
        when(mockDatabase.getMealsByDateRange(userId, any, any))
            .thenAnswer((_) async => []);

        final context = await contextService.generateUserContext(
          userId,
          userPosition: position,
        );

        expect(context.locationContext['hasLocation'], isTrue);
        expect(context.locationContext['latitude'], equals(37.7749));
        expect(context.locationContext['longitude'], equals(-122.4194));
      });
    });

    group('calculateRestaurantCompatibility', () {
      test('should calculate compatibility score correctly', () {
        final context = createTestUserContext();
        final restaurant = createTestRestaurant();

        final score = contextService.calculateRestaurantCompatibility(context, restaurant);

        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('should prioritize budget compatibility', () {
        final context = createTestUserContext();
        
        // Restaurant within budget
        final budgetRestaurant = createTestRestaurant().copyWith(
          averageMealCost: 20.0, // Within preferred range
        );
        
        // Restaurant over budget
        final expensiveRestaurant = createTestRestaurant().copyWith(
          averageMealCost: 100.0, // Way over budget
        );

        final budgetScore = contextService.calculateRestaurantCompatibility(context, budgetRestaurant);
        final expensiveScore = contextService.calculateRestaurantCompatibility(context, expensiveRestaurant);

        expect(budgetScore, greaterThan(expensiveScore));
      });

      test('should consider dietary restrictions', () {
        final context = createTestUserContext();
        
        // Restaurant supporting dietary restrictions
        final compatibleRestaurant = createTestRestaurant().copyWith(
          supportedDietaryRestrictions: ['vegetarian', 'vegan'],
        );
        
        // Restaurant not supporting dietary restrictions
        final incompatibleRestaurant = createTestRestaurant().copyWith(
          supportedDietaryRestrictions: <String>[],
        );

        final compatibleScore = contextService.calculateRestaurantCompatibility(context, compatibleRestaurant);
        final incompatibleScore = contextService.calculateRestaurantCompatibility(context, incompatibleRestaurant);

        expect(compatibleScore, greaterThan(incompatibleScore));
      });

      test('should factor in location distance', () {
        final context = createTestUserContext();
        
        // Close restaurant
        final nearRestaurant = createTestRestaurant().copyWith(
          distanceFromUser: 0.5, // 0.5 km away
        );
        
        // Far restaurant
        final farRestaurant = createTestRestaurant().copyWith(
          distanceFromUser: 15.0, // 15 km away
        );

        final nearScore = contextService.calculateRestaurantCompatibility(context, nearRestaurant);
        final farScore = contextService.calculateRestaurantCompatibility(context, farRestaurant);

        expect(nearScore, greaterThan(farScore));
      });
    });

    group('getUserDiscoveryHistory', () {
      test('should retrieve user discovery history', () async {
        const userId = 1;
        
        when(mockDatabase.getUserDiscoveryHistory(userId, limit: anyNamed('limit')))
            .thenAnswer((_) async => []);

        final history = await contextService.getUserDiscoveryHistory(userId);

        expect(history, isNotNull);
        verify(mockDatabase.getUserDiscoveryHistory(userId, limit: anyNamed('limit'))).called(1);
      });
    });

    group('getUserFeedbackHistory', () {
      test('should retrieve user feedback history', () async {
        const userId = 1;
        
        when(mockDatabase.getUserAIFeedbackHistory(userId))
            .thenAnswer((_) async => []);

        final history = await contextService.getUserFeedbackHistory(userId);

        expect(history, isNotNull);
        verify(mockDatabase.getUserAIFeedbackHistory(userId)).called(1);
      });
    });

    group('Context Freshness', () {
      test('should consider context fresh when recent', () {
        final context = UserRecommendationContext(
          userId: 1,
          dietaryPreferences: {},
          budgetConstraints: {},
          locationContext: {},
          recentMealHistory: [],
          temporalContext: {},
          preferenceScores: {},
          contextGeneratedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        );

        expect(context.isFresh, isTrue);
      });

      test('should consider context stale when old', () {
        final context = UserRecommendationContext(
          userId: 1,
          dietaryPreferences: {},
          budgetConstraints: {},
          locationContext: {},
          recentMealHistory: [],
          temporalContext: {},
          preferenceScores: {},
          contextGeneratedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        expect(context.isFresh, isFalse);
      });
    });

    group('Temporal Context', () {
      test('should identify correct meal time for breakfast', () {
        // Mock current time to 8 AM
        final context = _createContextWithMockedTime(8);
        
        expect(context.currentMealType, equals('breakfast'));
      });

      test('should identify correct meal time for lunch', () {
        // Mock current time to 12 PM
        final context = _createContextWithMockedTime(12);
        
        expect(context.currentMealType, equals('lunch'));
      });

      test('should identify correct meal time for dinner', () {
        // Mock current time to 7 PM
        final context = _createContextWithMockedTime(19);
        
        expect(context.currentMealType, equals('dinner'));
      });
    });
  });
}

// Helper functions
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

entity.Restaurant createTestRestaurant() {
  return entity.Restaurant(
    placeId: 'test_restaurant_1',
    name: 'Test Bistro',
    location: '123 Test St',
    address: '123 Test Street, Test City',
    latitude: 37.7749,
    longitude: -122.4194,
    distanceFromUser: 1.0,
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

UserRecommendationContext _createContextWithMockedTime(int hour) {
  final now = DateTime.now();
  final mockedTime = DateTime(now.year, now.month, now.day, hour);
  
  return UserRecommendationContext(
    userId: 1,
    dietaryPreferences: {},
    budgetConstraints: {},
    locationContext: {},
    recentMealHistory: [],
    temporalContext: {
      'hour': hour,
      'currentTime': mockedTime.toIso8601String(),
    },
    preferenceScores: {},
    contextGeneratedAt: mockedTime,
  );
}

extension RestaurantTestUtils on Restaurant {
  Restaurant copyWith({
    String? placeId,
    String? name,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceFromUser,
    double? rating,
    int? reviewCount,
    int? priceLevel,
    double? averageMealCost,
    double? valueScore,
    List<String>? cuisineTypes,
    List<String>? supportedDietaryRestrictions,
    List<String>? features,
    bool? isOpenNow,
    DateTime? cachedAt,
  }) {
    return Restaurant(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      priceRanges: this.priceRanges,
      cuisineType: this.cuisineType,
      averageMealCost: averageMealCost ?? this.averageMealCost,
      valueScore: valueScore ?? this.valueScore,
      cuisineTypes: cuisineTypes != null ? jsonEncode(cuisineTypes) : this.cuisineTypes,
      supportedDietaryRestrictions: supportedDietaryRestrictions != null ? jsonEncode(supportedDietaryRestrictions) : this.supportedDietaryRestrictions,
      allergenInfo: this.allergenInfo,
      dietaryCompatibilityScores: this.dietaryCompatibilityScores,
      hasVerifiedDietaryInfo: this.hasVerifiedDietaryInfo,
      communityVerificationCount: this.communityVerificationCount,
      openingHours: this.openingHours,
      features: features != null ? jsonEncode(features) : this.features,
      mealTypeAverageCosts: this.mealTypeAverageCosts,
      photoReferences: this.photoReferences,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      cachedAt: cachedAt ?? this.cachedAt,
      phoneNumber: this.phoneNumber,
      website: this.website,
      currentWaitTime: this.currentWaitTime,
      lastVerified: this.lastVerified,
      photoReference: this.photoReference,
    );
  }
}