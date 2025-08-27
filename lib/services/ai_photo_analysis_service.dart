import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'photo_service.dart';

/// AI-powered photo analysis service for meal recognition and insights
class AIPhotoAnalysisService {
  final GenerativeModel _model;
  
  static const String _modelName = 'gemini-1.5-flash';
  
  AIPhotoAnalysisService(String apiKey) 
    : _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        systemInstruction: Content.system(
          'You are an expert food and restaurant analyst. When analyzing photos, provide detailed, helpful insights about meals, restaurants, and food experiences. Be encouraging and positive while being informative.',
        ),
      );

  /// Analyze a meal photo and extract information
  Future<MealAnalysisResult> analyzeMealPhoto(PhotoResult photo) async {
    try {
      final imageBytes = await _loadImageBytes(photo.localPath);
      if (imageBytes == null) {
        throw AIPhotoAnalysisException('Could not load image file');
      }

      final prompt = '''
      Please analyze this meal photo and provide the following information in JSON format:

      {
        "dishName": "Name of the main dish or meal",
        "cuisineType": "Type of cuisine (e.g., Italian, Mexican, Asian, American, etc.)",
        "mealType": "breakfast, lunch, dinner, or snack",
        "estimatedCost": "Estimated cost range in USD (e.g., 8-12)",
        "ingredients": ["list", "of", "visible", "ingredients"],
        "healthScore": "1-10 rating for healthiness",
        "description": "Brief description of what you see in the photo",
        "suggestions": ["helpful", "dining", "tips", "or", "observations"],
        "confidence": "0.0-1.0 confidence level in the analysis"
      }

      Be encouraging and focus on the positive aspects of the meal experience. If you can't identify something clearly, acknowledge that in your confidence score.
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw AIPhotoAnalysisException('Could not parse AI response');
      }

      final jsonData = json.decode(jsonMatch.group(0)!);
      return MealAnalysisResult.fromJson(jsonData);
    } catch (e) {
      if (e is AIPhotoAnalysisException) rethrow;
      throw AIPhotoAnalysisException('Failed to analyze meal photo: $e');
    }
  }

  /// Analyze a restaurant photo for ambiance and details
  Future<RestaurantAnalysisResult> analyzeRestaurantPhoto(PhotoResult photo) async {
    try {
      final imageBytes = await _loadImageBytes(photo.localPath);
      if (imageBytes == null) {
        throw AIPhotoAnalysisException('Could not load image file');
      }

      final prompt = '''
      Please analyze this restaurant photo and provide the following information in JSON format:

      {
        "restaurantType": "Type of establishment (casual dining, fast food, fine dining, cafe, etc.)",
        "ambiance": "Description of the atmosphere and mood",
        "priceRange": "Estimated price range (single, double, triple, quadruple dollar signs)",
        "diningStyle": "sit-down, counter service, food truck, etc.",
        "features": ["notable", "features", "you", "observe"],
        "cleanliness": "1-10 rating for apparent cleanliness",
        "crowdLevel": "empty, quiet, moderate, busy, or packed",
        "timeOfDay": "Estimated time based on lighting and atmosphere",
        "accessibility": "Any accessibility features you notice",
        "highlights": ["positive", "aspects", "of", "the", "establishment"],
        "confidence": "0.0-1.0 confidence level in the analysis"
      }

      Focus on helping the user understand what kind of dining experience they can expect.
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw AIPhotoAnalysisException('Could not parse AI response');
      }

      final jsonData = json.decode(jsonMatch.group(0)!);
      return RestaurantAnalysisResult.fromJson(jsonData);
    } catch (e) {
      if (e is AIPhotoAnalysisException) rethrow;
      throw AIPhotoAnalysisException('Failed to analyze restaurant photo: $e');
    }
  }

  /// Generate meal recommendations based on photo analysis
  Future<MealRecommendations> generateMealRecommendations(List<PhotoResult> mealPhotos) async {
    try {
      if (mealPhotos.isEmpty) {
        throw AIPhotoAnalysisException('No photos provided for analysis');
      }

      // Analyze multiple photos if provided
      final List<MealAnalysisResult> analyses = [];
      for (final photo in mealPhotos.take(3)) { // Limit to 3 photos for performance
        try {
          final analysis = await analyzeMealPhoto(photo);
          analyses.add(analysis);
        } catch (e) {
          // Skip failed analyses but continue with others
          continue;
        }
      }

      if (analyses.isEmpty) {
        throw AIPhotoAnalysisException('Could not analyze any of the provided photos');
      }

      final prompt = '''
      Based on the meal analysis data below, provide personalized dining recommendations in JSON format:

      Previous meals analyzed: ${json.encode(analyses.map((a) => a.toJson()).toList())}

      Please provide:

      {
        "cuisinePreferences": ["detected", "preferred", "cuisines"],
        "priceRange": "Estimated preferred price range based on history",
        "healthConsciousness": "1-10 rating based on meal choices",
        "adventurousness": "1-10 rating for trying new foods",
        "recommendations": [
          {
            "type": "cuisine_suggestion",
            "title": "Try This Cuisine",
            "description": "Why you might like it",
            "confidence": 0.8
          }
        ],
        "insights": [
          "Helpful insights about dining patterns",
          "Suggestions for balanced nutrition",
          "Tips for exploring new experiences"
        ],
        "nextMealSuggestion": {
          "mealType": "breakfast/lunch/dinner/snack",
          "cuisineType": "suggested cuisine",
          "reasoning": "why this would be a good choice"
        }
      }

      Be encouraging and focus on helping the user make positive dining choices.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw AIPhotoAnalysisException('Could not parse AI response');
      }

      final jsonData = json.decode(jsonMatch.group(0)!);
      return MealRecommendations.fromJson(jsonData);
    } catch (e) {
      if (e is AIPhotoAnalysisException) rethrow;
      throw AIPhotoAnalysisException('Failed to generate recommendations: $e');
    }
  }

  /// Get dining insights from photo analysis
  Future<DiningInsights> getDiningInsights(List<MealAnalysisResult> analyses) async {
    try {
      if (analyses.isEmpty) {
        return DiningInsights.empty();
      }

      final prompt = '''
      Based on this meal analysis data, provide dining insights in JSON format:

      Meal data: ${json.encode(analyses.map((a) => a.toJson()).toList())}

      Please provide:

      {
        "overallHealthScore": "Average health score with analysis",
        "diversityScore": "1-10 rating for cuisine diversity",
        "budgetAnalysis": {
          "averageSpending": "estimated average per meal",
          "costTrend": "increasing, decreasing, or stable",
          "suggestions": ["budget optimization tips"]
        },
        "nutritionInsights": {
          "strengths": ["positive nutritional aspects"],
          "areas_for_improvement": ["suggestions for balance"],
          "recommendations": ["specific nutrition advice"]
        },
        "experienceQuality": {
          "rating": "1-10 overall dining experience rating",
          "highlights": ["positive aspects of dining choices"],
          "suggestions": ["ways to enhance dining experiences"]
        },
        "patterns": [
          "Identified patterns in dining behavior",
          "Times of day preferences",
          "Cuisine preferences"
        ]
      }

      Be supportive and focus on positive reinforcement while providing helpful guidance.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw AIPhotoAnalysisException('Could not parse AI response');
      }

      final jsonData = json.decode(jsonMatch.group(0)!);
      return DiningInsights.fromJson(jsonData);
    } catch (e) {
      if (e is AIPhotoAnalysisException) rethrow;
      throw AIPhotoAnalysisException('Failed to generate dining insights: $e');
    }
  }

  /// Load image bytes from file path
  Future<Uint8List?> _loadImageBytes(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }
}

/// Result of meal photo analysis
class MealAnalysisResult {
  final String dishName;
  final String cuisineType;
  final String mealType;
  final String estimatedCost;
  final List<String> ingredients;
  final int healthScore;
  final String description;
  final List<String> suggestions;
  final double confidence;

  const MealAnalysisResult({
    required this.dishName,
    required this.cuisineType,
    required this.mealType,
    required this.estimatedCost,
    required this.ingredients,
    required this.healthScore,
    required this.description,
    required this.suggestions,
    required this.confidence,
  });

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResult(
      dishName: json['dishName']?.toString() ?? 'Unknown Dish',
      cuisineType: json['cuisineType']?.toString() ?? 'Unknown',
      mealType: json['mealType']?.toString() ?? 'meal',
      estimatedCost: json['estimatedCost']?.toString() ?? '10-15',
      ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? [],
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 5,
      description: json['description']?.toString() ?? 'A delicious meal',
      suggestions: (json['suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dishName': dishName,
      'cuisineType': cuisineType,
      'mealType': mealType,
      'estimatedCost': estimatedCost,
      'ingredients': ingredients,
      'healthScore': healthScore,
      'description': description,
      'suggestions': suggestions,
      'confidence': confidence,
    };
  }
}

/// Result of restaurant photo analysis
class RestaurantAnalysisResult {
  final String restaurantType;
  final String ambiance;
  final String priceRange;
  final String diningStyle;
  final List<String> features;
  final int cleanliness;
  final String crowdLevel;
  final String timeOfDay;
  final String accessibility;
  final List<String> highlights;
  final double confidence;

  const RestaurantAnalysisResult({
    required this.restaurantType,
    required this.ambiance,
    required this.priceRange,
    required this.diningStyle,
    required this.features,
    required this.cleanliness,
    required this.crowdLevel,
    required this.timeOfDay,
    required this.accessibility,
    required this.highlights,
    required this.confidence,
  });

  factory RestaurantAnalysisResult.fromJson(Map<String, dynamic> json) {
    return RestaurantAnalysisResult(
      restaurantType: json['restaurantType']?.toString() ?? 'Restaurant',
      ambiance: json['ambiance']?.toString() ?? 'Pleasant atmosphere',
      priceRange: json['priceRange']?.toString() ?? 'moderate',
      diningStyle: json['diningStyle']?.toString() ?? 'sit-down',
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      cleanliness: (json['cleanliness'] as num?)?.toInt() ?? 7,
      crowdLevel: json['crowdLevel']?.toString() ?? 'moderate',
      timeOfDay: json['timeOfDay']?.toString() ?? 'daytime',
      accessibility: json['accessibility']?.toString() ?? 'Standard accessibility',
      highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantType': restaurantType,
      'ambiance': ambiance,
      'priceRange': priceRange,
      'diningStyle': diningStyle,
      'features': features,
      'cleanliness': cleanliness,
      'crowdLevel': crowdLevel,
      'timeOfDay': timeOfDay,
      'accessibility': accessibility,
      'highlights': highlights,
      'confidence': confidence,
    };
  }
}

/// Meal recommendations based on photo analysis
class MealRecommendations {
  final List<String> cuisinePreferences;
  final String priceRange;
  final int healthConsciousness;
  final int adventurousness;
  final List<Recommendation> recommendations;
  final List<String> insights;
  final NextMealSuggestion nextMealSuggestion;

  const MealRecommendations({
    required this.cuisinePreferences,
    required this.priceRange,
    required this.healthConsciousness,
    required this.adventurousness,
    required this.recommendations,
    required this.insights,
    required this.nextMealSuggestion,
  });

  factory MealRecommendations.fromJson(Map<String, dynamic> json) {
    return MealRecommendations(
      cuisinePreferences: (json['cuisinePreferences'] as List?)?.map((e) => e.toString()).toList() ?? [],
      priceRange: json['priceRange']?.toString() ?? 'moderate',
      healthConsciousness: (json['healthConsciousness'] as num?)?.toInt() ?? 5,
      adventurousness: (json['adventurousness'] as num?)?.toInt() ?? 5,
      recommendations: (json['recommendations'] as List?)
        ?.map((e) => Recommendation.fromJson(e))
        .toList() ?? [],
      insights: (json['insights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nextMealSuggestion: NextMealSuggestion.fromJson(json['nextMealSuggestion'] ?? {}),
    );
  }
}

/// Individual recommendation
class Recommendation {
  final String type;
  final String title;
  final String description;
  final double confidence;

  const Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? 'Suggestion',
      description: json['description']?.toString() ?? 'Try something new!',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Next meal suggestion
class NextMealSuggestion {
  final String mealType;
  final String cuisineType;
  final String reasoning;

  const NextMealSuggestion({
    required this.mealType,
    required this.cuisineType,
    required this.reasoning,
  });

  factory NextMealSuggestion.fromJson(Map<String, dynamic> json) {
    return NextMealSuggestion(
      mealType: json['mealType']?.toString() ?? 'lunch',
      cuisineType: json['cuisineType']?.toString() ?? 'variety',
      reasoning: json['reasoning']?.toString() ?? 'Based on your dining patterns',
    );
  }
}

/// Dining insights from analysis
class DiningInsights {
  final String overallHealthScore;
  final int diversityScore;
  final BudgetAnalysis budgetAnalysis;
  final NutritionInsights nutritionInsights;
  final ExperienceQuality experienceQuality;
  final List<String> patterns;

  const DiningInsights({
    required this.overallHealthScore,
    required this.diversityScore,
    required this.budgetAnalysis,
    required this.nutritionInsights,
    required this.experienceQuality,
    required this.patterns,
  });

  factory DiningInsights.fromJson(Map<String, dynamic> json) {
    return DiningInsights(
      overallHealthScore: json['overallHealthScore']?.toString() ?? 'Good choices overall',
      diversityScore: (json['diversityScore'] as num?)?.toInt() ?? 5,
      budgetAnalysis: BudgetAnalysis.fromJson(json['budgetAnalysis'] ?? {}),
      nutritionInsights: NutritionInsights.fromJson(json['nutritionInsights'] ?? {}),
      experienceQuality: ExperienceQuality.fromJson(json['experienceQuality'] ?? {}),
      patterns: (json['patterns'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static DiningInsights empty() {
    return const DiningInsights(
      overallHealthScore: 'No data available yet',
      diversityScore: 5,
      budgetAnalysis: BudgetAnalysis(
        averageSpending: 'N/A',
        costTrend: 'stable',
        suggestions: [],
      ),
      nutritionInsights: NutritionInsights(
        strengths: [],
        areasForImprovement: [],
        recommendations: [],
      ),
      experienceQuality: ExperienceQuality(
        rating: 7,
        highlights: [],
        suggestions: [],
      ),
      patterns: [],
    );
  }
}

/// Budget analysis
class BudgetAnalysis {
  final String averageSpending;
  final String costTrend;
  final List<String> suggestions;

  const BudgetAnalysis({
    required this.averageSpending,
    required this.costTrend,
    required this.suggestions,
  });

  factory BudgetAnalysis.fromJson(Map<String, dynamic> json) {
    return BudgetAnalysis(
      averageSpending: json['averageSpending']?.toString() ?? 'N/A',
      costTrend: json['costTrend']?.toString() ?? 'stable',
      suggestions: (json['suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Nutrition insights
class NutritionInsights {
  final List<String> strengths;
  final List<String> areasForImprovement;
  final List<String> recommendations;

  const NutritionInsights({
    required this.strengths,
    required this.areasForImprovement,
    required this.recommendations,
  });

  factory NutritionInsights.fromJson(Map<String, dynamic> json) {
    return NutritionInsights(
      strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      areasForImprovement: (json['areas_for_improvement'] as List?)?.map((e) => e.toString()).toList() ?? [],
      recommendations: (json['recommendations'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Experience quality analysis
class ExperienceQuality {
  final int rating;
  final List<String> highlights;
  final List<String> suggestions;

  const ExperienceQuality({
    required this.rating,
    required this.highlights,
    required this.suggestions,
  });

  factory ExperienceQuality.fromJson(Map<String, dynamic> json) {
    return ExperienceQuality(
      rating: (json['rating'] as num?)?.toInt() ?? 7,
      highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      suggestions: (json['suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Exception for AI photo analysis errors
class AIPhotoAnalysisException implements Exception {
  final String message;
  const AIPhotoAnalysisException(this.message);
  
  @override
  String toString() => 'AIPhotoAnalysisException: $message';
}