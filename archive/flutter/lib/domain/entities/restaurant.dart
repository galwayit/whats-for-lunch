/// Restaurant review entity for Google Places API integration
class RestaurantReview {
  final String reviewId;
  final String authorName;
  final String? authorPhotoUrl;
  final int rating;
  final String? text;
  final DateTime time;
  final String? language;
  final bool isTranslated;
  final String relativeTimeDescription;

  const RestaurantReview({
    required this.reviewId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.rating,
    this.text,
    required this.time,
    this.language,
    this.isTranslated = false,
    required this.relativeTimeDescription,
  });

  factory RestaurantReview.fromGooglePlaces(Map<String, dynamic> json) {
    return RestaurantReview(
      reviewId: json['author_name'] + json['time'].toString(), // Simple ID
      authorName: json['author_name'] ?? 'Anonymous',
      authorPhotoUrl: json['profile_photo_url'],
      rating: json['rating']?.toInt() ?? 5,
      text: json['text'],
      time: DateTime.fromMillisecondsSinceEpoch((json['time'] ?? 0) * 1000),
      language: json['language'],
      isTranslated: json['translated'] ?? false,
      relativeTimeDescription: json['relative_time_description'] ?? 'Recently',
    );
  }

  /// Get sentiment analysis from review text
  ReviewSentiment getSentiment() {
    if (text == null || text!.isEmpty) return ReviewSentiment.neutral;
    
    final lowerText = text!.toLowerCase();
    final positiveWords = ['great', 'amazing', 'excellent', 'fantastic', 'delicious', 
                          'wonderful', 'love', 'perfect', 'awesome', 'outstanding'];
    final negativeWords = ['bad', 'terrible', 'awful', 'horrible', 'disgusting', 
                          'worst', 'hate', 'disappointing', 'poor', 'unacceptable'];
    
    int positiveCount = positiveWords.where((word) => lowerText.contains(word)).length;
    int negativeCount = negativeWords.where((word) => lowerText.contains(word)).length;
    
    if (positiveCount > negativeCount && rating >= 4) {
      return ReviewSentiment.positive;
    } else if (negativeCount > positiveCount && rating <= 2) {
      return ReviewSentiment.negative;
    }
    return ReviewSentiment.neutral;
  }
}

/// Review sentiment for AI analysis
enum ReviewSentiment {
  positive,
  neutral,
  negative,
}

/// Enhanced restaurant entity for Stage 3 discovery with GPS, dietary data, and community verification
class Restaurant {
  // Basic restaurant information
  final String placeId;
  final String name;
  final String location;
  final String? address;
  final String? phoneNumber;
  final String? website;
  
  // Location data
  final double? latitude;
  final double? longitude;
  final double? distanceFromUser; // in kilometers
  
  // Rating and pricing
  final double? rating;
  final int? reviewCount;
  final int? priceLevel; // 1-4 ($ to $$$$)
  final List<String> priceRanges; // ['$', '$$'], etc.
  
  // Cuisine and dietary information
  final String? cuisineType;
  final List<String> cuisineTypes; // multiple cuisine types
  final List<String> supportedDietaryRestrictions;
  final List<String> allergenInfo;
  final Map<String, double> dietaryCompatibilityScores; // 0.0-1.0
  final bool hasVerifiedDietaryInfo;
  final int communityVerificationCount;
  
  // Operational information
  final List<String> openingHours;
  final bool isOpenNow;
  final String? currentWaitTime;
  final List<String> features; // ['delivery', 'takeout', 'dine_in', 'wheelchair_accessible']
  
  // Investment mindset data
  final double? averageMealCost;
  final double? valueScore; // price-to-quality ratio
  final Map<String, double> mealTypeAverageCosts; // breakfast, lunch, dinner
  
  // Reviews and AI data
  final List<RestaurantReview> recentReviews;
  final DateTime? reviewsLastFetched;
  final String? aiSentimentSummary;
  
  // Caching and metadata
  final DateTime cachedAt;
  final DateTime? lastVerified;
  final String? photoReference;
  final List<String> photoReferences;

  const Restaurant({
    required this.placeId,
    required this.name,
    required this.location,
    this.address,
    this.phoneNumber,
    this.website,
    this.latitude,
    this.longitude,
    this.distanceFromUser,
    this.rating,
    this.reviewCount,
    this.priceLevel,
    this.priceRanges = const [],
    this.cuisineType,
    this.cuisineTypes = const [],
    this.supportedDietaryRestrictions = const [],
    this.allergenInfo = const [],
    this.dietaryCompatibilityScores = const {},
    this.hasVerifiedDietaryInfo = false,
    this.communityVerificationCount = 0,
    this.openingHours = const [],
    this.isOpenNow = false,
    this.currentWaitTime,
    this.features = const [],
    this.averageMealCost,
    this.valueScore,
    this.mealTypeAverageCosts = const {},
    this.recentReviews = const [],
    this.reviewsLastFetched,
    this.aiSentimentSummary,
    required this.cachedAt,
    this.lastVerified,
    this.photoReference,
    this.photoReferences = const [],
  });

  Restaurant copyWith({
    String? placeId,
    String? name,
    String? location,
    String? address,
    String? phoneNumber,
    String? website,
    double? latitude,
    double? longitude,
    double? distanceFromUser,
    double? rating,
    int? reviewCount,
    int? priceLevel,
    List<String>? priceRanges,
    String? cuisineType,
    List<String>? cuisineTypes,
    List<String>? supportedDietaryRestrictions,
    List<String>? allergenInfo,
    Map<String, double>? dietaryCompatibilityScores,
    bool? hasVerifiedDietaryInfo,
    int? communityVerificationCount,
    List<String>? openingHours,
    bool? isOpenNow,
    String? currentWaitTime,
    List<String>? features,
    double? averageMealCost,
    double? valueScore,
    Map<String, double>? mealTypeAverageCosts,
    List<RestaurantReview>? recentReviews,
    DateTime? reviewsLastFetched,
    String? aiSentimentSummary,
    DateTime? cachedAt,
    DateTime? lastVerified,
    String? photoReference,
    List<String>? photoReferences,
  }) {
    return Restaurant(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      priceRanges: priceRanges ?? this.priceRanges,
      cuisineType: cuisineType ?? this.cuisineType,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      supportedDietaryRestrictions: supportedDietaryRestrictions ?? this.supportedDietaryRestrictions,
      allergenInfo: allergenInfo ?? this.allergenInfo,
      dietaryCompatibilityScores: dietaryCompatibilityScores ?? this.dietaryCompatibilityScores,
      hasVerifiedDietaryInfo: hasVerifiedDietaryInfo ?? this.hasVerifiedDietaryInfo,
      communityVerificationCount: communityVerificationCount ?? this.communityVerificationCount,
      openingHours: openingHours ?? this.openingHours,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      currentWaitTime: currentWaitTime ?? this.currentWaitTime,
      features: features ?? this.features,
      averageMealCost: averageMealCost ?? this.averageMealCost,
      valueScore: valueScore ?? this.valueScore,
      mealTypeAverageCosts: mealTypeAverageCosts ?? this.mealTypeAverageCosts,
      recentReviews: recentReviews ?? this.recentReviews,
      reviewsLastFetched: reviewsLastFetched ?? this.reviewsLastFetched,
      aiSentimentSummary: aiSentimentSummary ?? this.aiSentimentSummary,
      cachedAt: cachedAt ?? this.cachedAt,
      lastVerified: lastVerified ?? this.lastVerified,
      photoReference: photoReference ?? this.photoReference,
      photoReferences: photoReferences ?? this.photoReferences,
    );
  }

  /// Calculate dietary compatibility score based on user preferences
  double calculateDietaryCompatibility(List<String> userDietaryRestrictions, List<String> userAllergens) {
    if (userDietaryRestrictions.isEmpty && userAllergens.isEmpty) return 1.0;
    
    double score = 0.0;
    int totalRequirements = userDietaryRestrictions.length + userAllergens.length;
    
    // Check dietary restrictions support
    for (String restriction in userDietaryRestrictions) {
      if (supportedDietaryRestrictions.contains(restriction)) {
        score += 1.0;
      } else if (dietaryCompatibilityScores.containsKey(restriction)) {
        score += dietaryCompatibilityScores[restriction]!;
      }
    }
    
    // Check allergen safety (inverse score - presence of allergen reduces score)
    for (String allergen in userAllergens) {
      if (!allergenInfo.contains(allergen)) {
        score += 1.0; // Safe if allergen not present
      } else {
        score += 0.1; // Heavily penalize if allergen is present
      }
    }
    
    return totalRequirements > 0 ? score / totalRequirements : 1.0;
  }

  /// Get investment impact message based on budget and cost
  String getInvestmentImpactMessage(double weeklyBudget, double weeklySpent) {
    if (averageMealCost == null) return 'Investment impact unknown';
    
    final impactPercentage = (averageMealCost! / (weeklyBudget - weeklySpent)) * 100;
    
    if (impactPercentage <= 10) {
      return 'Excellent choice! Low impact on your weekly investment.';
    } else if (impactPercentage <= 25) {
      return 'Great balance of enjoyment and smart spending.';
    } else if (impactPercentage <= 50) {
      return 'Moderate investment - consider if it aligns with your priorities.';
    } else {
      return 'High investment impact - make sure this special experience is worth it!';
    }
  }

  /// Check if restaurant is currently open
  bool get isCurrentlyOpen {
    if (openingHours.isEmpty) return false;
    // Simplified implementation - would need proper time parsing
    return isOpenNow;
  }

  /// Get safety level based on allergen presence and community verification
  SafetyLevel getSafetyLevel(List<String> userAllergens) {
    if (userAllergens.isEmpty) return SafetyLevel.safe;
    
    bool hasAnyAllergen = userAllergens.any((allergen) => allergenInfo.contains(allergen));
    
    if (!hasAnyAllergen) {
      return hasVerifiedDietaryInfo ? SafetyLevel.verified : SafetyLevel.safe;
    } else {
      return hasVerifiedDietaryInfo ? SafetyLevel.caution : SafetyLevel.warning;
    }
  }

  /// Get overall review sentiment for AI analysis
  ReviewSentiment getOverallReviewSentiment() {
    if (recentReviews.isEmpty) return ReviewSentiment.neutral;
    
    int positiveCount = 0;
    int negativeCount = 0;
    int neutralCount = 0;
    
    for (final review in recentReviews) {
      switch (review.getSentiment()) {
        case ReviewSentiment.positive:
          positiveCount++;
          break;
        case ReviewSentiment.negative:
          negativeCount++;
          break;
        case ReviewSentiment.neutral:
          neutralCount++;
          break;
      }
    }
    
    if (positiveCount > negativeCount && positiveCount > neutralCount) {
      return ReviewSentiment.positive;
    } else if (negativeCount > positiveCount && negativeCount > neutralCount) {
      return ReviewSentiment.negative;
    }
    return ReviewSentiment.neutral;
  }

  /// Get review summary for AI decision making
  Map<String, dynamic> getReviewSummaryForAI() {
    if (recentReviews.isEmpty) {
      return {
        'has_reviews': false,
        'review_count': 0,
        'sentiment': 'neutral',
        'average_rating': rating ?? 0.0,
        'recent_review_count': 0,
      };
    }

    final sentiment = getOverallReviewSentiment();
    final averageRecentRating = recentReviews.isNotEmpty 
        ? recentReviews.map((r) => r.rating).reduce((a, b) => a + b) / recentReviews.length
        : 0.0;

    // Extract key themes from recent reviews
    final allReviewText = recentReviews
        .where((r) => r.text != null && r.text!.isNotEmpty)
        .map((r) => r.text!)
        .join(' ');

    return {
      'has_reviews': true,
      'review_count': reviewCount ?? 0,
      'recent_review_count': recentReviews.length,
      'sentiment': sentiment.toString().split('.').last,
      'average_rating': rating ?? 0.0,
      'recent_average_rating': averageRecentRating,
      'reviews_last_fetched': reviewsLastFetched?.toIso8601String(),
      'ai_sentiment_summary': aiSentimentSummary,
      'sample_review_text': allReviewText.length > 500 
          ? '${allReviewText.substring(0, 500)}...'
          : allReviewText,
    };
  }
}

/// Safety levels for dietary restrictions and allergens
enum SafetyLevel {
  safe,      // No known issues
  verified,  // Community verified as safe
  caution,   // Some concerns but manageable
  warning,   // High risk, avoid
}