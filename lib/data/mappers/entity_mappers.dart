import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../../domain/entities/ai_recommendation.dart' as domain;
import '../../domain/entities/budget_tracking.dart' as domain;
import '../../domain/entities/meal.dart' as domain;
import '../../domain/entities/restaurant.dart' as domain;
import '../../domain/entities/user.dart' as domain;

/// Entity mappers to convert between database and domain entities
class EntityMappers {
  EntityMappers._();
  
  // User mappings
  static domain.UserEntity userFromDatabase(db.User driftUser) {
    return domain.UserEntity(
      id: driftUser.id,
      name: driftUser.name,
      preferences: _safeDecode<Map<String, dynamic>>(driftUser.preferences, {}),
      createdAt: driftUser.createdAt,
    );
  }

  static db.UsersCompanion userToCompanion(domain.UserEntity user) {
    return db.UsersCompanion(
      id: user.id != null ? Value(user.id!) : const Value.absent(),
      name: Value(user.name),
      preferences: Value(json.encode(user.preferences)),
      createdAt: Value(user.createdAt),
    );
  }

  // Meal mappings
  static domain.Meal mealFromDatabase(db.Meal driftMeal) {
    return domain.Meal(
      id: driftMeal.id,
      userId: driftMeal.userId,
      restaurantId: driftMeal.restaurantId,
      mealType: driftMeal.mealType,
      cost: driftMeal.cost,
      date: driftMeal.date,
      notes: driftMeal.notes,
    );
  }

  static db.MealsCompanion mealToCompanion(domain.Meal meal) {
    return db.MealsCompanion(
      id: meal.id != null ? Value(meal.id!) : const Value.absent(),
      userId: Value(meal.userId),
      restaurantId: Value(meal.restaurantId),
      mealType: Value(meal.mealType),
      cost: Value(meal.cost),
      date: Value(meal.date),
      notes: Value(meal.notes),
    );
  }

  // Budget tracking mappings
  static domain.BudgetTracking budgetTrackingFromDatabase(db.BudgetTracking driftBudgetTracking) {
    return domain.BudgetTracking(
      id: driftBudgetTracking.id,
      userId: driftBudgetTracking.userId,
      amount: driftBudgetTracking.amount,
      category: driftBudgetTracking.category,
      date: driftBudgetTracking.date,
    );
  }

  static db.BudgetTrackingsCompanion budgetTrackingToCompanion(domain.BudgetTracking budgetTracking) {
    return db.BudgetTrackingsCompanion(
      id: budgetTracking.id != null ? Value(budgetTracking.id!) : const Value.absent(),
      userId: Value(budgetTracking.userId),
      amount: Value(budgetTracking.amount),
      category: Value(budgetTracking.category),
      date: Value(budgetTracking.date),
    );
  }

  // Restaurant mappings
  static domain.Restaurant restaurantFromDatabase(db.Restaurant driftRestaurant) {
    return domain.Restaurant(
      placeId: driftRestaurant.placeId,
      name: driftRestaurant.name,
      location: driftRestaurant.location,
      address: driftRestaurant.address,
      phoneNumber: driftRestaurant.phoneNumber,
      website: driftRestaurant.website,
      latitude: driftRestaurant.latitude,
      longitude: driftRestaurant.longitude,
      distanceFromUser: driftRestaurant.distanceFromUser,
      rating: driftRestaurant.rating,
      reviewCount: driftRestaurant.reviewCount,
      priceLevel: driftRestaurant.priceLevel,
      priceRanges: _safeDecode<List>(driftRestaurant.priceRanges, []).cast<String>(),
      cuisineType: driftRestaurant.cuisineType,
      cuisineTypes: _safeDecode<List>(driftRestaurant.cuisineTypes, []).cast<String>(),
      supportedDietaryRestrictions: _safeDecode<List>(driftRestaurant.supportedDietaryRestrictions, []).cast<String>(),
      allergenInfo: _safeDecode<List>(driftRestaurant.allergenInfo, []).cast<String>(),
      dietaryCompatibilityScores: _safeDecode<Map<String, dynamic>>(driftRestaurant.dietaryCompatibilityScores, {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      hasVerifiedDietaryInfo: driftRestaurant.hasVerifiedDietaryInfo,
      communityVerificationCount: driftRestaurant.communityVerificationCount,
      openingHours: _safeDecode<List>(driftRestaurant.openingHours, []).cast<String>(),
      isOpenNow: driftRestaurant.isOpenNow,
      currentWaitTime: driftRestaurant.currentWaitTime,
      features: _safeDecode<List>(driftRestaurant.features, []).cast<String>(),
      averageMealCost: driftRestaurant.averageMealCost,
      valueScore: driftRestaurant.valueScore,
      mealTypeAverageCosts: _safeDecode<Map<String, dynamic>>(driftRestaurant.mealTypeAverageCosts, {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      cachedAt: driftRestaurant.cachedAt,
      lastVerified: driftRestaurant.lastVerified,
      photoReference: driftRestaurant.photoReference,
      photoReferences: _safeDecode<List>(driftRestaurant.photoReferences, []).cast<String>(),
    );
  }

  static db.RestaurantsCompanion restaurantToCompanion(domain.Restaurant restaurant) {
    return db.RestaurantsCompanion(
      placeId: Value(restaurant.placeId),
      name: Value(restaurant.name),
      location: Value(restaurant.location),
      address: Value(restaurant.address),
      phoneNumber: Value(restaurant.phoneNumber),
      website: Value(restaurant.website),
      latitude: Value(restaurant.latitude),
      longitude: Value(restaurant.longitude),
      distanceFromUser: Value(restaurant.distanceFromUser),
      rating: Value(restaurant.rating),
      reviewCount: Value(restaurant.reviewCount),
      priceLevel: Value(restaurant.priceLevel),
      priceRanges: Value(json.encode(restaurant.priceRanges)),
      cuisineType: Value(restaurant.cuisineType),
      cuisineTypes: Value(json.encode(restaurant.cuisineTypes)),
      supportedDietaryRestrictions: Value(json.encode(restaurant.supportedDietaryRestrictions)),
      allergenInfo: Value(json.encode(restaurant.allergenInfo)),
      dietaryCompatibilityScores: Value(json.encode(restaurant.dietaryCompatibilityScores)),
      hasVerifiedDietaryInfo: Value(restaurant.hasVerifiedDietaryInfo),
      communityVerificationCount: Value(restaurant.communityVerificationCount),
      openingHours: Value(json.encode(restaurant.openingHours)),
      isOpenNow: Value(restaurant.isOpenNow),
      currentWaitTime: Value(restaurant.currentWaitTime),
      features: Value(json.encode(restaurant.features)),
      averageMealCost: Value(restaurant.averageMealCost),
      valueScore: Value(restaurant.valueScore),
      mealTypeAverageCosts: Value(json.encode(restaurant.mealTypeAverageCosts)),
      cachedAt: Value(restaurant.cachedAt),
      lastVerified: Value(restaurant.lastVerified),
      photoReference: Value(restaurant.photoReference),
      photoReferences: Value(json.encode(restaurant.photoReferences)),
    );
  }

  // AI Recommendation mappings
  static Future<domain.AIRecommendation> aiRecommendationFromDatabase(
    db.AIRecommendation dbRec, 
    List<domain.Restaurant> restaurants,
  ) async {
    return domain.AIRecommendation(
      id: dbRec.id,
      userId: dbRec.userId,
      recommendedRestaurants: restaurants,
      reasoning: dbRec.reasoning,
      factorWeights: _safeDecode<Map<String, dynamic>>(dbRec.factorWeights, {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      overallConfidence: dbRec.overallConfidence,
      userContext: _safeDecode<Map<String, dynamic>>(dbRec.userContext, {}),
      generatedAt: dbRec.generatedAt,
      wasAccepted: dbRec.wasAccepted,
      userFeedback: dbRec.userFeedback,
      metadata: _safeDecode<Map<String, dynamic>>(dbRec.metadata, {}),
    );
  }

  static db.AIRecommendationsCompanion aiRecommendationToCompanion(
    domain.AIRecommendation recommendation,
    DateTime expiresAt,
  ) {
    return db.AIRecommendationsCompanion.insert(
      id: recommendation.id,
      userId: recommendation.userId,
      recommendedRestaurantIds: json.encode(
        recommendation.recommendedRestaurants.map((r) => r.placeId).toList()
      ),
      reasoning: recommendation.reasoning,
      factorWeights: Value(json.encode(recommendation.factorWeights)),
      overallConfidence: recommendation.overallConfidence,
      userContext: Value(json.encode(recommendation.userContext)),
      generatedAt: Value(recommendation.generatedAt),
      metadata: Value(json.encode(recommendation.metadata)),
      expiresAt: expiresAt,
      wasAccepted: Value(recommendation.wasAccepted),
      userFeedback: Value(recommendation.userFeedback),
    );
  }

  // Helper methods for bulk conversions
  static List<domain.Meal> mealsFromDatabase(List<db.Meal> dbMeals) {
    return dbMeals.map(mealFromDatabase).toList();
  }

  static List<domain.Restaurant> restaurantsFromDatabase(List<db.Restaurant> dbRestaurants) {
    return dbRestaurants.map(restaurantFromDatabase).toList();
  }

  static List<domain.BudgetTracking> budgetTrackingsFromDatabase(List<db.BudgetTracking> dbBudgetTrackings) {
    return dbBudgetTrackings.map(budgetTrackingFromDatabase).toList();
  }

  // Safe JSON decode helper to handle malformed JSON and provide fallbacks
  static T _safeDecode<T>(String jsonString, T fallback) {
    try {
      if (jsonString.isEmpty) return fallback;
      final decoded = json.decode(jsonString);
      return decoded is T ? decoded : fallback;
    } catch (e) {
      return fallback;
    }
  }
}