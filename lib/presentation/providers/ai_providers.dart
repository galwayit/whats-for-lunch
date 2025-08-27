import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config/api_config.dart';
import '../../data/repositories/ai_repository.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/restaurant.dart';
import '../../services/ai_service.dart';
import '../../services/user_context_service.dart';
import 'database_provider.dart';
import 'simple_providers.dart';
import 'discovery_providers.dart';
import 'api_monitoring_providers.dart';

/// Provider for AI service configuration
final aiServiceConfigProvider = Provider<AIServiceConfig>((ref) {
  return AIServiceConfig(
    apiKey: ApiConfig.geminiApiKey,
    model: ApiConfig.geminiModel,
    temperature: ApiConfig.geminiTemperature,
    maxTokens: ApiConfig.geminiMaxTokens,
    requestTimeout: ApiConfig.apiTimeout,
    maxRetries: 3,
    costLimitPerDayDollars: ApiConfig.geminiDailyCostLimit,
    enableCaching: ApiConfig.geminiEnableCaching,
  );
});

/// Provider for AI availability
final aiAvailabilityProvider = Provider<bool>((ref) {
  // In development mode, allow demo functionality even without valid keys
  if (ApiConfig.isDevelopment && ApiConfig.enableFallbackMode) {
    return true; // Enable AI UI for demo purposes
  }
  return ApiConfig.hasValidGeminiKey;
});

/// Provider for AI service (nullable if not available)
final aiServiceProvider = Provider<AIService?>((ref) {
  if (!ref.watch(aiAvailabilityProvider)) {
    return null;
  }
  
  try {
    final config = ref.watch(aiServiceConfigProvider);
    final monitoringService = ApiConfig.enableUsageMonitoring 
        ? ref.watch(apiMonitoringServiceProvider)
        : null;
    return AIService.create(config, monitoringService: monitoringService);
  } catch (e) {
    // In development mode with demo keys, return a mock service for testing
    if (ApiConfig.isDevelopment && ApiConfig.enableFallbackMode) {
      if (kDebugMode) {
        print('AI service creation failed, creating demo service: $e');
      }
      return null; // UI will handle graceful fallback
    }
    return null;
  }
});

/// Provider for user context service
final userContextServiceProvider = Provider<UserContextService>((ref) {
  final database = ref.watch(databaseProvider);
  return UserContextService(database);
});

/// Provider for AI repository (nullable if AI service unavailable)
final aiRepositoryProvider = Provider<AIRepository?>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  if (aiService == null) {
    return null;
  }
  
  final database = ref.watch(databaseProvider);
  final contextService = ref.watch(userContextServiceProvider);
  
  return AIRepositoryImpl(database, aiService, contextService);
});

/// State for AI recommendation generation
class AIRecommendationState {
  final List<AIRecommendation> recommendations;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? usageStats;

  const AIRecommendationState({
    this.recommendations = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.lastUpdated,
    this.usageStats,
  });

  AIRecommendationState copyWith({
    List<AIRecommendation>? recommendations,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    DateTime? lastUpdated,
    Map<String, dynamic>? usageStats,
  }) {
    return AIRecommendationState(
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      usageStats: usageStats ?? this.usageStats,
    );
  }

  bool get hasRecommendations => recommendations.isNotEmpty;
  
  AIRecommendation? get primaryRecommendation => 
      recommendations.isNotEmpty ? recommendations.first : null;
  
  double get totalConfidence => recommendations.isNotEmpty
      ? recommendations.map((r) => r.overallConfidence).reduce((a, b) => a + b) / recommendations.length
      : 0.0;
}

/// AI recommendation state notifier
class AIRecommendationNotifier extends StateNotifier<AIRecommendationState> {
  AIRecommendationNotifier(this._repository, this._currentUserId) : super(const AIRecommendationState()) {
    if (_repository != null) {
      _loadRecentRecommendations();
      _loadUsageStatistics();
    }
  }

  final AIRepository? _repository;
  final int? _currentUserId;

  /// Generate new AI recommendations
  Future<void> generateRecommendations({
    List<Restaurant>? availableRestaurants,
    Position? userPosition,
    String? specificCravings,
    Map<String, dynamic>? additionalFilters,
  }) async {
    if (_repository == null) {
      // In development mode, provide demo recommendations
      if (ApiConfig.isDevelopment && ApiConfig.enableFallbackMode) {
        await _generateDemoRecommendations(
          availableRestaurants,
          specificCravings,
        );
        return;
      }
      
      state = state.copyWith(
        hasError: true,
        errorMessage: 'AI service is not available. Please check your configuration.',
        isLoading: false,
      );
      return;
    }

    if (_currentUserId == null) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Please log in to get AI recommendations',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);

    try {
      // Use provided restaurants or get from discovery service
      final restaurants = availableRestaurants ?? [];
      
      if (restaurants.isEmpty) {
        state = state.copyWith(
          hasError: true,
          errorMessage: 'No restaurants available for recommendations',
          isLoading: false,
        );
        return;
      }

      final recommendation = await _repository.generateRecommendations(
        _currentUserId!,
        restaurants,
        userPosition: userPosition,
        specificCravings: specificCravings,
        additionalFilters: additionalFilters,
      );

      // Add to existing recommendations (newest first)
      final updatedRecommendations = [recommendation, ...state.recommendations]
          .take(10) // Keep only the 10 most recent
          .toList();

      state = state.copyWith(
        recommendations: updatedRecommendations,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Reload usage statistics
      await _loadUsageStatistics();
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Load recent recommendations from cache
  Future<void> _loadRecentRecommendations() async {
    if (_repository == null || _currentUserId == null) return;

    try {
      final recommendations = await _repository.getRecentRecommendations(_currentUserId!);
      state = state.copyWith(recommendations: recommendations);
    } catch (e) {
      // Non-critical error - just log it
      if (kDebugMode) {
        print('Failed to load recent recommendations: $e');
      }
    }
  }

  /// Load usage statistics
  Future<void> _loadUsageStatistics() async {
    if (_repository == null || _currentUserId == null) return;

    try {
      final stats = await _repository.getUsageStatistics(_currentUserId!);
      state = state.copyWith(usageStats: stats);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load usage statistics: $e');
      }
    }
  }

  /// Submit feedback for a recommendation
  Future<void> submitFeedback(
    String recommendationId,
    int rating,
    String? feedback, {
    bool wasSelected = false,
  }) async {
    if (_repository == null) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'AI service is not available.',
      );
      return;
    }

    try {
      await _repository.submitFeedback(
        recommendationId,
        rating,
        feedback,
        wasSelected: wasSelected,
      );

      // Update the recommendation in state
      final updatedRecommendations = state.recommendations.map((rec) {
        if (rec.id == recommendationId) {
          return rec.copyWith(
            wasAccepted: wasSelected,
            userFeedback: feedback,
          );
        }
        return rec;
      }).toList();

      state = state.copyWith(recommendations: updatedRecommendations);
      
      // Reload usage statistics to reflect feedback submission
      await _loadUsageStatistics();
    } catch (e) {
      // Handle feedback submission error
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to submit feedback: ${e.toString()}',
      );
    }
  }

  /// Refresh recommendations and statistics
  Future<void> refresh() async {
    await _loadRecentRecommendations();
    await _loadUsageStatistics();
  }

  /// Clear current recommendations
  void clearRecommendations() {
    state = state.copyWith(
      recommendations: [],
      hasError: false,
      errorMessage: null,
      lastUpdated: null,
    );
  }

  /// Get daily cost usage
  double get dailyCostUsage {
    final costs = state.usageStats?['costs'] as Map<String, dynamic>?;
    return costs?['today'] ?? 0.0;
  }

  /// Check if user is near daily limits
  bool get isNearDailyLimits {
    final limits = state.usageStats?['limits'] as Map<String, dynamic>?;
    if (limits == null) return false;
    
    final remainingBudget = limits['remainingBudget'] ?? 5.0;
    final remainingRequests = limits['remainingRequests'] ?? 50;
    
    return remainingBudget < 1.0 || remainingRequests < 5;
  }

  /// Get usage summary for display
  Map<String, dynamic> get usageSummary {
    final stats = state.usageStats;
    if (stats == null) return {};
    
    final costs = stats['costs'] as Map<String, dynamic>? ?? {};
    final requests = stats['requests'] as Map<String, dynamic>? ?? {};
    final limits = stats['limits'] as Map<String, dynamic>? ?? {};
    final performance = stats['performance'] as Map<String, dynamic>? ?? {};
    
    return {
      'todayCost': costs['today'] ?? 0.0,
      'todayRequests': requests['today'] ?? 0,
      'remainingBudget': limits['remainingBudget'] ?? 5.0,
      'remainingRequests': limits['remainingRequests'] ?? 50,
      'successRate': performance['successRate'] ?? 1.0,
      'avgResponseTime': performance['avgResponseTimeMs'] ?? 0,
    };
  }

  /// Generate demo recommendations for development/testing
  Future<void> _generateDemoRecommendations(
    List<Restaurant>? availableRestaurants,
    String? specificCravings,
  ) async {
    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);

    // Simulate AI processing time
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final restaurants = availableRestaurants ?? [];
      if (restaurants.isEmpty) {
        state = state.copyWith(
          hasError: true,
          errorMessage: 'No restaurants available for recommendations',
          isLoading: false,
        );
        return;
      }

      // Create demo AI recommendation
      final topRestaurants = restaurants.take(3).toList();
      final demoRecommendation = AIRecommendation(
        id: 'demo_rec_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId ?? 1,
        recommendedRestaurants: topRestaurants,
        reasoning: _generateDemoReasoning(topRestaurants, specificCravings),
        factorWeights: {
          'budget': 0.85,
          'dietary': 0.75,
          'location': 0.90,
          'history': 0.60,
          'temporal': 0.80,
          'social': 0.70,
        },
        overallConfidence: 0.82,
        userContext: {
          'budgetRange': '15.0-35.0',
          'mealType': 'lunch',
          'dietaryPreferences': [],
          'locationContext': {'hasLocation': true},
          'demo': true,
        },
        generatedAt: DateTime.now(),
        metadata: {
          'responseTime': 1500,
          'investmentSummary': _generateInvestmentSummary(topRestaurants),
          'requestId': 'demo_request',
          'demo': true,
        },
      );

      // Add to existing recommendations (newest first)
      final updatedRecommendations = [demoRecommendation, ...state.recommendations]
          .take(10) // Keep only the 10 most recent
          .toList();

      state = state.copyWith(
        recommendations: updatedRecommendations,
        isLoading: false,
        lastUpdated: DateTime.now(),
        usageStats: {
          'costs': {'today': 0.02},
          'requests': {'today': 1},
          'limits': {'remainingBudget': 4.98, 'remainingRequests': 49},
          'performance': {'successRate': 1.0, 'avgResponseTimeMs': 1500},
        },
      );

    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Demo recommendation generation failed: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  String _generateDemoReasoning(List<Restaurant> restaurants, String? cravings) {
    if (restaurants.isEmpty) return 'No restaurants available for analysis.';
    
    final primary = restaurants.first;
    final craveText = cravings?.isNotEmpty == true ? ' matching your "$cravings" craving' : '';
    
    return 'Based on your dining patterns and investment preferences, ${primary.name} offers the optimal value proposition$craveText. '
           'With a ${((primary.valueScore ?? 0.7) * 100).round()}% value score and ${primary.rating?.toStringAsFixed(1) ?? "4.0"}★ rating, '
           'this represents a smart dining investment. The location is convenient and the price point aligns with your budget preferences. '
           '${restaurants.length > 1 ? "Alternative options are ranked by compatibility with your dining philosophy." : ""}';
  }

  String _generateInvestmentSummary(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) return 'No investment opportunities identified.';
    
    final primary = restaurants.first;
    final cost = primary.averageMealCost ?? 20.0;
    final value = ((primary.valueScore ?? 0.7) * 100).round();
    
    return 'Smart investment: \$${cost.toStringAsFixed(2)} delivers $value% value with high satisfaction potential';
  }
}

/// Provider for AI recommendation state
final aiRecommendationProvider = StateNotifierProvider<AIRecommendationNotifier, AIRecommendationState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  return AIRecommendationNotifier(repository, currentUserId);
});

/// Provider for generating recommendations with discovery integration
final generateRecommendationsProvider = Provider<Future<void> Function({
  String? specificCravings,
  Map<String, dynamic>? additionalFilters,
})>((ref) {
  final aiNotifier = ref.read(aiRecommendationProvider.notifier);
  final discoveryState = ref.read(discoveryProvider);
  final userLocationAsync = ref.read(userLocationProvider);

  return ({
    String? specificCravings,
    Map<String, dynamic>? additionalFilters,
  }) async {
    // Get available restaurants from discovery
    final restaurants = discoveryState.restaurants;
    
    // Get user position
    final userPosition = userLocationAsync;

    await aiNotifier.generateRecommendations(
      availableRestaurants: restaurants,
      userPosition: userPosition,
      specificCravings: specificCravings,
      additionalFilters: additionalFilters,
    );
  };
});

/// Provider for AI recommendation feedback submission
final submitRecommendationFeedbackProvider = Provider<Future<void> Function(
  String recommendationId,
  int rating,
  String? feedback, {
  bool wasSelected,
})>((ref) {
  final aiNotifier = ref.read(aiRecommendationProvider.notifier);
  
  return (
    String recommendationId,
    int rating,
    String? feedback, {
    bool wasSelected = false,
  }) async {
    await aiNotifier.submitFeedback(
      recommendationId,
      rating,
      feedback,
      wasSelected: wasSelected,
    );
  };
});

// aiAvailabilityProvider is already defined above - removing duplicate

/// Provider for AI usage summary
final aiUsageSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(aiRecommendationProvider.notifier);
  
  return notifier.usageSummary;
});

/// Provider for investment-minded AI recommendation analysis
final aiInvestmentAnalysisProvider = Provider<Map<String, dynamic>>((ref) {
  final aiState = ref.watch(aiRecommendationProvider);
  
  if (!aiState.hasRecommendations) {
    return {
      'hasAnalysis': false,
      'message': 'Generate recommendations to see investment analysis',
    };
  }

  final primary = aiState.primaryRecommendation!;
  final restaurants = primary.recommendedRestaurants;
  
  if (restaurants.isEmpty) {
    return {
      'hasAnalysis': false,
      'message': 'No restaurants available for analysis',
    };
  }

  final topRestaurant = restaurants.first;
  final avgCost = topRestaurant.averageMealCost ?? 20.0;
  final valueScore = topRestaurant.valueScore ?? 0.7;
  final confidence = primary.overallConfidence;

  // Calculate investment metrics
  final valueRating = valueScore > 0.8 ? 'Excellent' : 
                     valueScore > 0.6 ? 'Good' : 
                     valueScore > 0.4 ? 'Fair' : 'Poor';

  final confidenceLevel = confidence > 0.8 ? 'High' : 
                         confidence > 0.6 ? 'Medium' : 'Low';

  final investmentOpportunity = avgCost < 15 ? 'Budget-Friendly' :
                               avgCost < 30 ? 'Moderate Investment' :
                               avgCost < 50 ? 'Premium Experience' :
                               'Luxury Investment';

  return {
    'hasAnalysis': true,
    'topRecommendation': {
      'name': topRestaurant.name,
      'investmentCost': avgCost,
      'valueRating': valueRating,
      'valueScore': (valueScore * 100).round(),
      'confidenceLevel': confidenceLevel,
      'confidence': (confidence * 100).round(),
      'investmentOpportunity': investmentOpportunity,
    },
    'reasoning': primary.reasoning,
    'factors': primary.topInfluencingFactors,
    'summary': primary.investmentSummary,
    'totalOptions': restaurants.length,
  };
});

/// Provider for AI recommendation history
final aiRecommendationHistoryProvider = FutureProvider<List<AIRecommendation>>((ref) async {
  final repository = ref.read(aiRepositoryProvider);
  final currentUserId = ref.read(currentUserIdProvider);
  
  if (repository == null || currentUserId == null) return [];
  
  try {
    return await repository.getRecentRecommendations(currentUserId);
  } catch (e) {
    return [];
  }
});

/// Provider for periodic cleanup of expired recommendations
final aiCleanupProvider = Provider<void>((ref) {
  final repository = ref.read(aiRepositoryProvider);
  
  if (repository == null) return;
  
  // Schedule periodic cleanup (could be enhanced with background tasks)
  Timer.periodic(const Duration(hours: 1), (_) async {
    try {
      await repository.cleanupExpiredRecommendations();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup expired recommendations: $e');
      }
    }
  });
});

/// State for AI onboarding and feature introduction
class AIOnboardingState {
  final bool hasSeenIntroduction;
  final bool hasGeneratedFirstRecommendation;
  final bool hasSubmittedFirstFeedback;
  final bool hasCompletedOnboarding;
  final int tutorialStep;

  const AIOnboardingState({
    this.hasSeenIntroduction = false,
    this.hasGeneratedFirstRecommendation = false,
    this.hasSubmittedFirstFeedback = false,
    this.hasCompletedOnboarding = false,
    this.tutorialStep = 0,
  });

  AIOnboardingState copyWith({
    bool? hasSeenIntroduction,
    bool? hasGeneratedFirstRecommendation,
    bool? hasSubmittedFirstFeedback,
    bool? hasCompletedOnboarding,
    int? tutorialStep,
  }) {
    return AIOnboardingState(
      hasSeenIntroduction: hasSeenIntroduction ?? this.hasSeenIntroduction,
      hasGeneratedFirstRecommendation: hasGeneratedFirstRecommendation ?? this.hasGeneratedFirstRecommendation,
      hasSubmittedFirstFeedback: hasSubmittedFirstFeedback ?? this.hasSubmittedFirstFeedback,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      tutorialStep: tutorialStep ?? this.tutorialStep,
    );
  }

  bool get isOnboardingComplete => 
      hasSeenIntroduction && hasGeneratedFirstRecommendation && hasSubmittedFirstFeedback;
}

/// Simple AI onboarding notifier
class AIOnboardingNotifier extends StateNotifier<AIOnboardingState> {
  AIOnboardingNotifier() : super(const AIOnboardingState());

  void completeOnboarding() {
    state = state.copyWith(hasCompletedOnboarding: true);
  }
}

/// Provider for AI onboarding state
final aiOnboardingProvider = StateNotifierProvider<AIOnboardingNotifier, AIOnboardingState>((ref) {
  return AIOnboardingNotifier();
});

/// Provider for smart recommendation triggers
final smartRecommendationTriggerProvider = Provider<bool>((ref) {
  final aiState = ref.watch(aiRecommendationProvider);
  
  // Trigger recommendations when:
  // 1. No recent recommendations
  // 2. User is in discovery mode
  // 3. It's meal time
  
  final hasRecentRecommendations = aiState.lastUpdated != null &&
      DateTime.now().difference(aiState.lastUpdated!).inMinutes < 60;
  
  final currentHour = DateTime.now().hour;
  final isMealTime = (currentHour >= 7 && currentHour < 10) || // Breakfast
                     (currentHour >= 11 && currentHour < 14) || // Lunch
                     (currentHour >= 17 && currentHour < 21);   // Dinner
  
  return !hasRecentRecommendations && isMealTime;
});