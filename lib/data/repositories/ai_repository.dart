import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/ai_recommendation.dart' as entity;
import '../../domain/entities/restaurant.dart' as entity;
import '../../services/ai_service.dart';
import '../../services/user_context_service.dart';
import '../../core/services/logging_service.dart';
import '../database/database.dart';
import '../mappers/entity_mappers.dart';

/// Repository interface for AI recommendation operations
abstract class AIRepository {
  Future<entity.AIRecommendation> generateRecommendations(
    int userId,
    List<entity.Restaurant> availableRestaurants, {
    Position? userPosition,
    String? specificCravings,
    Map<String, dynamic>? additionalFilters,
  });

  Future<List<entity.AIRecommendation>> getRecentRecommendations(int userId);
  Future<void> submitFeedback(String recommendationId, int rating, String? feedback, {bool wasSelected = false});
  Future<double> getDailyCostUsage(int userId);
  Future<Map<String, dynamic>> getUsageStatistics(int userId);
  Future<void> cleanupExpiredRecommendations();
}

/// Implementation of AI repository with comprehensive cost monitoring and caching
class AIRepositoryImpl implements AIRepository {
  final AppDatabase _database;
  final AIService _aiService;
  final UserContextService _contextService;

  AIRepositoryImpl(
    this._database,
    this._aiService,
    this._contextService,
  );

  @override
  Future<entity.AIRecommendation> generateRecommendations(
    int userId,
    List<entity.Restaurant> availableRestaurants, {
    Position? userPosition,
    String? specificCravings,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      // Check if user has exceeded daily limits
      await _checkDailyLimits(userId);

      // Generate user context
      final context = await _contextService.generateUserContext(
        userId,
        userPosition: userPosition,
        additionalFilters: additionalFilters,
      );

      // Filter restaurants based on compatibility scores for better AI efficiency
      final compatibleRestaurants = _prefilterRestaurants(
        availableRestaurants,
        context,
        maxRestaurants: 20, // Limit to top 20 most compatible
      );

      // Create AI recommendation request
      final request = entity.AIRecommendationRequest(
        userId: userId,
        context: context,
        availableRestaurants: compatibleRestaurants,
        specificCravings: specificCravings,
        additionalFilters: additionalFilters ?? {},
        maxRecommendations: 5,
        includeReasoning: true,
      );

      // Check cache for similar recent requests
      final cachedRecommendation = await _checkCache(request);
      if (cachedRecommendation != null) {
        return cachedRecommendation;
      }

      // Generate AI recommendation with performance tracking
      final startTime = DateTime.now();
      final aiResponse = await _aiService.generateRecommendations(request);
      final endTime = DateTime.now();

      final recommendation = aiResponse.data;

      // Cache the recommendation
      await _cacheRecommendation(recommendation, aiResponse);

      // Log usage metrics
      await _logUsageMetrics(
        userId: userId,
        requestType: 'recommendation',
        tokensUsed: aiResponse.tokensUsed,
        costCents: aiResponse.estimatedCostCents,
        responseTime: aiResponse.responseTime,
        wasSuccessful: true,
      );

      return recommendation;
    } catch (e) {
      // Log failed request
      await _logUsageMetrics(
        userId: userId,
        requestType: 'recommendation',
        tokensUsed: 0,
        costCents: 0,
        responseTime: Duration.zero,
        wasSuccessful: false,
        errorMessage: e.toString(),
      );
      
      rethrow;
    }
  }

  @override
  Future<List<entity.AIRecommendation>> getRecentRecommendations(int userId) async {
    try {
      final recommendations = await _database.getRecentAIRecommendations(userId);
      
      // Convert database entities to domain entities
      final domainRecommendations = <entity.AIRecommendation>[];
      
      for (final rec in recommendations) {
        final restaurantIds = List<String>.from(json.decode(rec.recommendedRestaurantIds));
        final restaurants = <entity.Restaurant>[];
        
        // Fetch restaurant details
        for (final placeId in restaurantIds) {
          final restaurant = await _database.getRestaurantByPlaceId(placeId);
          if (restaurant != null) {
            restaurants.add(EntityMappers.restaurantFromDatabase(restaurant));
          }
        }
        
        final recommendation = await EntityMappers.aiRecommendationFromDatabase(rec, restaurants);
        
        domainRecommendations.add(recommendation);
      }
      
      return domainRecommendations;
    } catch (e) {
      throw Exception('Failed to get recent recommendations: $e');
    }
  }

  @override
  Future<void> submitFeedback(
    String recommendationId,
    int rating,
    String? feedback, {
    bool wasSelected = false,
  }) async {
    try {
      // Update recommendation with user feedback
      await _database.updateAIRecommendationFeedback(
        recommendationId,
        wasSelected,
        feedback,
      );

      // Get the recommendation to extract restaurant info
      final recommendation = await _database.getAIRecommendation(recommendationId);
      if (recommendation == null) {
        throw Exception('Recommendation not found');
      }

      // Get the first restaurant for feedback logging
      final restaurantIds = List<String>.from(json.decode(recommendation.recommendedRestaurantIds));
      if (restaurantIds.isNotEmpty) {
        await _database.insertAIRecommendationFeedback(
          AIRecommendationFeedbackCompanion.insert(
            recommendationId: recommendationId,
            userId: recommendation.userId,
            placeId: restaurantIds.first,
            rating: rating,
            feedbackText: Value(feedback),
            wasSelected: Value(wasSelected),
          ),
        );

        // Log feedback submission metrics
        await _logUsageMetrics(
          userId: recommendation.userId,
          requestType: 'feedback',
          tokensUsed: 0,
          costCents: 0,
          responseTime: Duration.zero,
          wasSuccessful: true,
        );
      }
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  @override
  Future<double> getDailyCostUsage(int userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      return await _database.getTotalAICostForUser(userId, startDate: startOfDay);
    } catch (e) {
      throw Exception('Failed to get daily cost usage: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUsageStatistics(int userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: today.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);

      // Get metrics for different time periods
      final todayMetrics = await _database.getAIUsageMetrics(userId, startDate: today);
      final weekMetrics = await _database.getAIUsageMetrics(userId, startDate: thisWeek);
      final monthMetrics = await _database.getAIUsageMetrics(userId, startDate: thisMonth);

      // Calculate aggregated statistics
      final todayCost = todayMetrics.fold(0.0, (sum, m) => sum + m.costInCents) / 100;
      final weekCost = weekMetrics.fold(0.0, (sum, m) => sum + m.costInCents) / 100;
      final monthCost = monthMetrics.fold(0.0, (sum, m) => sum + m.costInCents) / 100;

      final todayRequests = todayMetrics.where((m) => m.requestType == 'recommendation').length;
      final weekRequests = weekMetrics.where((m) => m.requestType == 'recommendation').length;
      final monthRequests = monthMetrics.where((m) => m.requestType == 'recommendation').length;

      final avgResponseTime = weekMetrics.isNotEmpty
          ? weekMetrics
              .where((m) => m.responseTimeMs != null)
              .map((m) => m.responseTimeMs!)
              .fold(0, (sum, time) => sum + time) / 
            weekMetrics.where((m) => m.responseTimeMs != null).length
          : 0;

      final successRate = weekMetrics.isNotEmpty
          ? weekMetrics.where((m) => m.wasSuccessful).length / weekMetrics.length
          : 1.0;

      return {
        'costs': {
          'today': todayCost,
          'week': weekCost,
          'month': monthCost,
        },
        'requests': {
          'today': todayRequests,
          'week': weekRequests,
          'month': monthRequests,
        },
        'performance': {
          'avgResponseTimeMs': avgResponseTime.round(),
          'successRate': successRate,
        },
        'limits': {
          'dailyCostLimit': 5.0, // $5 daily limit
          'dailyRequestLimit': 50, // 50 requests per day
          'remainingBudget': (5.0 - todayCost).clamp(0.0, 5.0),
          'remainingRequests': (50 - todayRequests).clamp(0, 50),
        },
      };
    } catch (e) {
      throw Exception('Failed to get usage statistics: $e');
    }
  }

  @override
  Future<void> cleanupExpiredRecommendations() async {
    try {
      await _database.cleanupExpiredAIRecommendations();
    } catch (e) {
      throw Exception('Failed to cleanup expired recommendations: $e');
    }
  }

  /// Private helper methods

  Future<void> _checkDailyLimits(int userId) async {
    final stats = await getUsageStatistics(userId);
    final limits = stats['limits'] as Map<String, dynamic>;
    
    if (limits['remainingRequests'] <= 0) {
      throw Exception('Daily request limit exceeded. Please try again tomorrow.');
    }
    
    if (limits['remainingBudget'] <= 0.10) { // Less than 10 cents remaining
      throw Exception('Daily cost limit exceeded. Please try again tomorrow.');
    }
  }

  Future<entity.AIRecommendation?> _checkCache(entity.AIRecommendationRequest request) async {
    try {
      // Simple cache check - could be enhanced with more sophisticated matching
      final recent = await _database.getRecentAIRecommendations(request.userId, limit: 5);
      
      for (final rec in recent) {
        final context = json.decode(rec.userContext);
        
        // Check if context is similar enough (same meal type and similar budget)
        if (context['mealType'] == request.context.currentMealType &&
            DateTime.now().difference(rec.generatedAt).inMinutes < 30) {
          
          // Reconstruct the recommendation
          final restaurantIds = List<String>.from(json.decode(rec.recommendedRestaurantIds));
          final restaurants = <entity.Restaurant>[];
          
          for (final placeId in restaurantIds) {
            final restaurant = await _database.getRestaurantByPlaceId(placeId);
            if (restaurant != null) {
              restaurants.add(EntityMappers.restaurantFromDatabase(restaurant));
            }
          }
          
          return await EntityMappers.aiRecommendationFromDatabase(rec, restaurants);
        }
      }
      
      return null;
    } catch (e) {
      // If cache check fails, continue without cache
      return null;
    }
  }

  Future<void> _cacheRecommendation(
    entity.AIRecommendation recommendation,
    AIServiceResponse<entity.AIRecommendation> response,
  ) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      
      await _database.insertAIRecommendation(
        EntityMappers.aiRecommendationToCompanion(recommendation, expiresAt),
      );
    } catch (e) {
      // Non-critical error - log but don't fail the request
      LoggingService().warning('Failed to cache recommendation', tag: 'AIRepository', error: e);
    }
  }

  Future<void> _logUsageMetrics({
    required int userId,
    required String requestType,
    required int tokensUsed,
    required double costCents,
    required Duration responseTime,
    required bool wasSuccessful,
    String? errorMessage,
  }) async {
    try {
      await _database.insertAIUsageMetric(
        AIUsageMetricsCompanion.insert(
          userId: userId,
          requestType: requestType,
          tokensUsed: Value(tokensUsed),
          costInCents: Value(costCents),
          responseTimeMs: Value(responseTime.inMilliseconds),
          wasSuccessful: Value(wasSuccessful),
          errorMessage: Value(errorMessage),
        ),
      );
    } catch (e) {
      // Non-critical error - log but don't fail the request
      LoggingService().warning('Failed to log usage metrics', tag: 'AIRepository', error: e);
    }
  }

  List<entity.Restaurant> _prefilterRestaurants(
    List<entity.Restaurant> restaurants,
    entity.UserRecommendationContext context,
    {int maxRestaurants = 20}
  ) {
    if (restaurants.length <= maxRestaurants) {
      return restaurants;
    }

    // Calculate compatibility scores for all restaurants
    final scoredRestaurants = restaurants.map((restaurant) {
      final score = _contextService.calculateRestaurantCompatibility(context, restaurant);
      return {'restaurant': restaurant, 'score': score};
    }).toList();

    // Sort by compatibility score and take top results
    scoredRestaurants.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return scoredRestaurants
        .take(maxRestaurants)
        .map((item) => item['restaurant'] as entity.Restaurant)
        .toList();
  }
}