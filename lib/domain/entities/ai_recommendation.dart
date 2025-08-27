import '../entities/restaurant.dart';

/// AI-generated restaurant recommendation with confidence scoring and reasoning
class AIRecommendation {
  final String id;
  final int userId;
  final List<Restaurant> recommendedRestaurants;
  final String reasoning;
  final Map<String, double> factorWeights;
  final double overallConfidence;
  final Map<String, dynamic> userContext;
  final DateTime generatedAt;
  final bool wasAccepted;
  final String? userFeedback;
  final Map<String, dynamic> metadata;

  const AIRecommendation({
    required this.id,
    required this.userId,
    required this.recommendedRestaurants,
    required this.reasoning,
    required this.factorWeights,
    required this.overallConfidence,
    required this.userContext,
    required this.generatedAt,
    this.wasAccepted = false,
    this.userFeedback,
    this.metadata = const {},
  });

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

  /// Get confidence level as a human-readable string
  String get confidenceLevel {
    if (overallConfidence >= 0.8) return 'High';
    if (overallConfidence >= 0.6) return 'Medium';
    return 'Low';
  }

  /// Get confidence as a percentage
  String get confidencePercentage => '${(overallConfidence * 100).round()}%';

  /// Get the primary recommended restaurant
  Restaurant? get primaryRecommendation => 
    recommendedRestaurants.isNotEmpty ? recommendedRestaurants.first : null;

  /// Check if this recommendation is still relevant (not older than 1 hour)
  bool get isStillRelevant {
    final now = DateTime.now();
    final hourAgo = now.subtract(const Duration(hours: 1));
    return generatedAt.isAfter(hourAgo);
  }

  /// Get investment mindset summary of recommendation
  String get investmentSummary {
    if (recommendedRestaurants.isEmpty) return 'No investment opportunities found';
    
    final primary = recommendedRestaurants.first;
    final avgCost = primary.averageMealCost ?? 15.0;
    final valueScore = primary.valueScore ?? 0.7;
    
    return 'Investment opportunity: \$${avgCost.toStringAsFixed(2)} for ${(valueScore * 100).round()}% value score';
  }

  /// Get the main factors that influenced this recommendation
  List<String> get topInfluencingFactors {
    final sortedFactors = factorWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedFactors.take(3).map((entry) {
      final factor = entry.key;
      final weight = (entry.value * 100).round();
      return '$factor (${weight}%)';
    }).toList();
  }

  @override
  String toString() {
    return 'AIRecommendation(id: $id, userId: $userId, confidence: $overallConfidence, restaurants: ${recommendedRestaurants.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIRecommendation &&
        other.id == id &&
        other.userId == userId &&
        other.reasoning == reasoning &&
        other.overallConfidence == overallConfidence &&
        other.wasAccepted == wasAccepted;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, reasoning, overallConfidence, wasAccepted);
  }
}

/// User context for AI recommendations
class UserRecommendationContext {
  final int userId;
  final Map<String, dynamic> dietaryPreferences;
  final Map<String, double> budgetConstraints;
  final Map<String, dynamic> locationContext;
  final List<String> recentMealHistory;
  final Map<String, dynamic> temporalContext;
  final Map<String, double> preferenceScores;
  final DateTime contextGeneratedAt;

  const UserRecommendationContext({
    required this.userId,
    required this.dietaryPreferences,
    required this.budgetConstraints,
    required this.locationContext,
    required this.recentMealHistory,
    required this.temporalContext,
    required this.preferenceScores,
    required this.contextGeneratedAt,
  });

  /// Check if context is still fresh (less than 30 minutes old)
  bool get isFresh {
    final now = DateTime.now();
    final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
    return contextGeneratedAt.isAfter(thirtyMinutesAgo);
  }

  /// Get budget range for current context
  String get budgetRange {
    final minBudget = budgetConstraints['min'] ?? 0.0;
    final maxBudget = budgetConstraints['max'] ?? 50.0;
    return '\$${minBudget.toStringAsFixed(0)} - \$${maxBudget.toStringAsFixed(0)}';
  }

  /// Get current meal preference (breakfast, lunch, dinner)
  String get currentMealType {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 16) return 'lunch';
    return 'dinner';
  }

  @override
  String toString() {
    return 'UserRecommendationContext(userId: $userId, mealType: $currentMealType, budget: $budgetRange)';
  }
}

/// AI recommendation request parameters
class AIRecommendationRequest {
  final int userId;
  final UserRecommendationContext context;
  final List<Restaurant> availableRestaurants;
  final Map<String, dynamic> additionalFilters;
  final int maxRecommendations;
  final bool includeReasoning;
  final String? specificCravings;

  const AIRecommendationRequest({
    required this.userId,
    required this.context,
    required this.availableRestaurants,
    this.additionalFilters = const {},
    this.maxRecommendations = 5,
    this.includeReasoning = true,
    this.specificCravings,
  });

  @override
  String toString() {
    return 'AIRecommendationRequest(userId: $userId, restaurants: ${availableRestaurants.length}, maxRecs: $maxRecommendations)';
  }
}