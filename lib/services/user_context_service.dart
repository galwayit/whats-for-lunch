import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import '../domain/entities/ai_recommendation.dart' as entity;
import '../domain/entities/meal.dart' as entity;
import '../domain/entities/user_preferences.dart' as entity;
import '../domain/entities/restaurant.dart' as entity;
import '../data/database/database.dart';
import '../data/mappers/entity_mappers.dart';

/// Service for aggregating comprehensive user context for AI recommendations
class UserContextService {
  final AppDatabase _database;

  UserContextService(this._database);

  /// Generate comprehensive user context for AI recommendations
  Future<entity.UserRecommendationContext> generateUserContext(
    int userId, {
    Position? userPosition,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      // Get user preferences
      final user = await _database.getDatabaseUserById(userId);
      final userPreferences = user != null 
          ? Map<String, dynamic>.from(json.decode(user.preferences))
          : <String, dynamic>{};

      // Get dietary preferences
      final dietaryPreferences = await _extractDietaryPreferences(userId, userPreferences);

      // Get budget constraints
      final budgetConstraints = await _extractBudgetConstraints(userId, userPreferences);

      // Get location context
      final locationContext = await _extractLocationContext(userPosition);

      // Get recent meal history
      final recentMealHistory = await _extractRecentMealHistory(userId);

      // Get temporal context
      final temporalContext = _extractTemporalContext();

      // Generate preference scores
      final preferenceScores = await _generatePreferenceScores(userId);

      return entity.UserRecommendationContext(
        userId: userId,
        dietaryPreferences: dietaryPreferences,
        budgetConstraints: budgetConstraints,
        locationContext: locationContext,
        recentMealHistory: recentMealHistory,
        temporalContext: temporalContext,
        preferenceScores: preferenceScores,
        contextGeneratedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate user context: $e');
    }
  }

  /// Extract dietary preferences from user data
  Future<Map<String, dynamic>> _extractDietaryPreferences(
    int userId,
    Map<String, dynamic> userPreferences,
  ) async {
    final preferences = <String, dynamic>{
      'restrictions': userPreferences['dietaryRestrictions'] ?? [],
      'preferences': userPreferences['dietaryPreferences'] ?? [],
      'allergies': userPreferences['allergies'] ?? [],
    };

    // Analyze recent meal patterns for implicit preferences
    final recentMeals = await _database.getMealsByDateRange(
      userId,
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    // Extract cuisine preferences from meal history
    final Map<String, int> cuisineFrequency = {};
    final Map<String, int> mealTypeFrequency = {};

    for (final meal in recentMeals) {
      mealTypeFrequency[meal.mealType] = (mealTypeFrequency[meal.mealType] ?? 0) + 1;
    }

    preferences['preferredCuisines'] = cuisineFrequency.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();
    
    preferences['preferredMealTypes'] = mealTypeFrequency.entries
        .map((e) => {'type': e.key, 'frequency': e.value})
        .toList();

    return preferences;
  }

  /// Extract budget constraints and spending patterns
  Future<Map<String, double>> _extractBudgetConstraints(
    int userId,
    Map<String, dynamic> userPreferences,
  ) async {
    final weeklyBudget = (userPreferences['weeklyBudget'] as num?)?.toDouble() ?? 200.0;
    
    // Calculate current week spending
    final weekStart = _getWeekStartDate(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    final weeklyMeals = await _database.getMealsByDateRange(userId, weekStart, weekEnd);
    final currentWeekSpending = weeklyMeals.fold(0.0, (sum, meal) => sum + meal.cost);
    
    // Analyze spending patterns
    final last30DaysMeals = await _database.getMealsByDateRange(
      userId,
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    final avgMealCost = last30DaysMeals.isNotEmpty
        ? last30DaysMeals.fold(0.0, (sum, meal) => sum + meal.cost) / last30DaysMeals.length
        : 20.0;

    final maxMealCost = last30DaysMeals.isNotEmpty
        ? last30DaysMeals.map((m) => m.cost).reduce((a, b) => a > b ? a : b)
        : 50.0;

    return {
      'weeklyBudget': weeklyBudget,
      'currentWeekSpent': currentWeekSpending,
      'remainingWeeklyBudget': weeklyBudget - currentWeekSpending,
      'avgMealCost': avgMealCost,
      'maxMealCost': maxMealCost,
      'min': (avgMealCost * 0.5).clamp(5.0, 100.0), // 50% of average, minimum $5
      'max': (weeklyBudget * 0.4).clamp(avgMealCost, 100.0), // 40% of weekly budget
      'preferred': avgMealCost,
    };
  }

  /// Extract location context and preferences
  Future<Map<String, dynamic>> _extractLocationContext(Position? position) async {
    if (position == null) {
      return {
        'hasLocation': false,
        'searchRadius': 5.0, // Default 5km radius
        'transportMode': 'walking',
      };
    }

    // Get user discovery history to understand location preferences
    final locationContext = <String, dynamic>{
      'hasLocation': true,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': position.timestamp?.toIso8601String(),
      'searchRadius': 5.0, // Default radius
      'preferredDistanceThreshold': 2.0, // Prefer restaurants within 2km
      'maxDistanceThreshold': 10.0, // Don't recommend beyond 10km
      'transportMode': 'walking',
    };

    return locationContext;
  }

  /// Extract recent meal history for pattern analysis
  Future<List<String>> _extractRecentMealHistory(int userId) async {
    final recentMeals = await _database.getMealsByDateRange(
      userId,
      DateTime.now().subtract(const Duration(days: 7)),
      DateTime.now(),
    );

    return recentMeals
        .map((meal) {
          final domainMeal = EntityMappers.mealFromDatabase(meal);
          return '${domainMeal.displayMealType}: \$${meal.cost.toStringAsFixed(2)} (${_formatRelativeTime(meal.date)})';
        })
        .toList();
  }

  /// Extract temporal context (time of day, day of week patterns)
  Map<String, dynamic> _extractTemporalContext() {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday;
    
    String mealTime;
    List<String> appropriateMealTypes;
    
    if (hour >= 6 && hour < 10) {
      mealTime = 'breakfast';
      appropriateMealTypes = ['breakfast', 'snack'];
    } else if (hour >= 10 && hour < 15) {
      mealTime = 'lunch';
      appropriateMealTypes = ['lunch', 'dining_out'];
    } else if (hour >= 15 && hour < 18) {
      mealTime = 'afternoon';
      appropriateMealTypes = ['snack', 'takeout'];
    } else if (hour >= 18 && hour < 22) {
      mealTime = 'dinner';
      appropriateMealTypes = ['dinner', 'dining_out'];
    } else {
      mealTime = 'late_night';
      appropriateMealTypes = ['takeout', 'delivery'];
    }

    return {
      'currentTime': now.toIso8601String(),
      'hour': hour,
      'dayOfWeek': dayOfWeek,
      'mealTime': mealTime,
      'appropriateMealTypes': appropriateMealTypes,
      'isWeekend': dayOfWeek >= 6,
      'isBusinessHours': hour >= 9 && hour < 18,
      'isRushHour': (hour >= 7 && hour < 10) || (hour >= 17 && hour < 20),
    };
  }

  /// Generate preference scores based on user behavior
  Future<Map<String, double>> _generatePreferenceScores(int userId) async {
    final preferences = <String, double>{};
    
    // Get user's meal history for the last 90 days
    final mealHistory = await _database.getMealsByDateRange(
      userId,
      DateTime.now().subtract(const Duration(days: 90)),
      DateTime.now(),
    );

    if (mealHistory.isEmpty) {
      // Default preferences for new users
      return {
        'quality_over_price': 0.7,
        'convenience_over_distance': 0.6,
        'familiarity_over_novelty': 0.5,
        'health_consciousness': 0.6,
        'price_sensitivity': 0.7,
        'variety_seeking': 0.5,
        'time_sensitivity': 0.6,
      };
    }

    // Analyze spending patterns for price sensitivity
    final costs = mealHistory.map((m) => m.cost).toList()..sort();
    final avgCost = costs.fold(0.0, (sum, cost) => sum + cost) / costs.length;
    final medianCost = costs[costs.length ~/ 2];
    final maxCost = costs.last;

    preferences['price_sensitivity'] = (maxCost - avgCost) / maxCost; // High if user avoids expensive options
    preferences['quality_over_price'] = 1.0 - preferences['price_sensitivity']!;

    // Analyze meal type diversity for variety seeking
    final mealTypes = mealHistory.map((m) => m.mealType).toSet();
    preferences['variety_seeking'] = (mealTypes.length / 8).clamp(0.0, 1.0); // 8 possible meal types

    // Analyze timing patterns for convenience
    final rushHourMeals = mealHistory.where((m) {
      final hour = m.date.hour;
      return (hour >= 7 && hour < 10) || (hour >= 17 && hour < 20);
    }).length;
    preferences['time_sensitivity'] = rushHourMeals / mealHistory.length;
    preferences['convenience_over_distance'] = preferences['time_sensitivity']!;

    // Default values for other preferences
    preferences['familiarity_over_novelty'] = 0.6; // Slightly prefer familiar options
    preferences['health_consciousness'] = 0.6; // Moderate health consciousness

    return preferences;
  }

  /// Get user's discovery history for location and cuisine preferences
  Future<List<Map<String, dynamic>>> getUserDiscoveryHistory(int userId, {int days = 30}) async {
    final history = await _database.getUserDiscoveryHistory(userId, limit: 100);
    
    return history
        .where((h) => h.viewedAt.isAfter(DateTime.now().subtract(Duration(days: days))))
        .map((h) => {
          'placeId': h.placeId,
          'wasSelected': h.wasSelected,
          'filters': json.decode(h.appliedFilters),
          'viewedAt': h.viewedAt,
        })
        .toList();
  }

  /// Get user's feedback history for preference learning
  Future<List<Map<String, dynamic>>> getUserFeedbackHistory(int userId) async {
    final feedback = await _database.getUserAIFeedbackHistory(userId);
    
    return feedback.map((f) => {
      'placeId': f.placeId,
      'rating': f.rating,
      'wasSelected': f.wasSelected,
      'feedback': f.feedbackText,
      'submittedAt': f.submittedAt,
    }).toList();
  }

  /// Calculate compatibility score between user context and restaurant
  double calculateRestaurantCompatibility(
    entity.UserRecommendationContext context,
    entity.Restaurant restaurant,
  ) {
    double score = 0.0;
    
    // Budget compatibility (25% weight)
    final budgetScore = _calculateBudgetCompatibility(context.budgetConstraints, restaurant);
    score += budgetScore * 0.25;
    
    // Dietary compatibility (25% weight)
    final dietaryScore = _calculateDietaryCompatibility(context.dietaryPreferences, restaurant);
    score += dietaryScore * 0.25;
    
    // Location compatibility (20% weight)
    final locationScore = _calculateLocationCompatibility(context.locationContext, restaurant);
    score += locationScore * 0.20;
    
    // Rating and quality (15% weight)
    final qualityScore = (restaurant.rating ?? 3.0) / 5.0;
    score += qualityScore * 0.15;
    
    // Temporal relevance (10% weight)
    final temporalScore = _calculateTemporalCompatibility(context.temporalContext, restaurant);
    score += temporalScore * 0.10;
    
    // Price level appropriateness (5% weight)
    final priceLevelScore = _calculatePriceLevelCompatibility(context.budgetConstraints, restaurant.priceLevel);
    score += priceLevelScore * 0.05;
    
    return score.clamp(0.0, 1.0);
  }

  /// Helper methods for compatibility calculations
  double _calculateBudgetCompatibility(Map<String, double> budget, entity.Restaurant restaurant) {
    final avgCost = restaurant.averageMealCost ?? budget['preferred'] ?? 20.0;
    final minBudget = budget['min'] ?? 5.0;
    final maxBudget = budget['max'] ?? 50.0;
    
    if (avgCost >= minBudget && avgCost <= maxBudget) {
      // Perfect fit - highest score for preferred range
      final preferredCost = budget['preferred'] ?? 20.0;
      final distance = (avgCost - preferredCost).abs() / preferredCost;
      return (1.0 - distance).clamp(0.0, 1.0);
    } else if (avgCost < minBudget) {
      // Too cheap might indicate lower quality
      return 0.7;
    } else {
      // Too expensive
      final overBudgetRatio = (avgCost - maxBudget) / maxBudget;
      return (1.0 - overBudgetRatio).clamp(0.0, 0.5);
    }
  }

  double _calculateDietaryCompatibility(Map<String, dynamic> dietary, entity.Restaurant restaurant) {
    final restrictions = List<String>.from(dietary['restrictions'] ?? []);
    if (restrictions.isEmpty) return 1.0; // No restrictions
    
    double score = 0.0;
    for (final restriction in restrictions) {
      if (restaurant.supportedDietaryRestrictions.contains(restriction)) {
        score += 1.0;
      } else if (restaurant.dietaryCompatibilityScores.containsKey(restriction)) {
        score += restaurant.dietaryCompatibilityScores[restriction]!;
      }
    }
    
    return restrictions.isNotEmpty ? score / restrictions.length : 1.0;
  }

  double _calculateLocationCompatibility(Map<String, dynamic> location, entity.Restaurant restaurant) {
    if (!location['hasLocation'] || restaurant.distanceFromUser == null) {
      return 0.5; // Neutral score if no location data
    }
    
    final distance = restaurant.distanceFromUser!;
    final preferredDistance = location['preferredDistanceThreshold'] ?? 2.0;
    final maxDistance = location['maxDistanceThreshold'] ?? 10.0;
    
    if (distance <= preferredDistance) {
      return 1.0;
    } else if (distance <= maxDistance) {
      return 1.0 - ((distance - preferredDistance) / (maxDistance - preferredDistance));
    } else {
      return 0.0;
    }
  }

  double _calculateTemporalCompatibility(Map<String, dynamic> temporal, entity.Restaurant restaurant) {
    // Check if restaurant is open now
    if (!restaurant.isOpenNow) return 0.0;
    
    // Basic temporal compatibility - can be enhanced with more sophisticated logic
    return 1.0;
  }

  double _calculatePriceLevelCompatibility(Map<String, double> budget, int? priceLevel) {
    if (priceLevel == null) return 0.5;
    
    final avgCost = budget['preferred'] ?? 20.0;
    
    // Map price levels to typical cost ranges
    final expectedCost = switch (priceLevel) {
      1 => 10.0,  // $
      2 => 20.0,  // $$
      3 => 40.0,  // $$$
      4 => 70.0,  // $$$$
      _ => 20.0,
    };
    
    final distance = (expectedCost - avgCost).abs() / avgCost;
    return (1.0 - distance).clamp(0.0, 1.0);
  }

  /// Utility methods
  DateTime _getWeekStartDate(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}