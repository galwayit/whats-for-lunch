import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/config/api_config.dart';
import '../core/services/api_monitoring_service.dart';
import '../domain/entities/ai_recommendation.dart';
import '../domain/entities/restaurant.dart';

/// Exception thrown when AI service encounters an error
class AIServiceException implements Exception {
  final String message;
  final String? errorCode;
  final bool isRetryable;

  const AIServiceException(this.message, {this.errorCode, this.isRetryable = false});

  @override
  String toString() => 'AIServiceException: $message ${errorCode != null ? '($errorCode)' : ''}';
}

/// Response from AI service with performance metrics
class AIServiceResponse<T> {
  final T data;
  final Duration responseTime;
  final int tokensUsed;
  final double estimatedCostCents;
  final Map<String, dynamic> metadata;

  const AIServiceResponse({
    required this.data,
    required this.responseTime,
    required this.tokensUsed,
    required this.estimatedCostCents,
    this.metadata = const {},
  });
}

/// Configuration for AI service behavior
class AIServiceConfig {
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final Duration requestTimeout;
  final int maxRetries;
  final double costLimitPerDayDollars;
  final bool enableCaching;

  const AIServiceConfig({
    required this.apiKey,
    this.model = 'gemini-1.5-flash',
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.requestTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.costLimitPerDayDollars = 5.0,
    this.enableCaching = true,
  });
}

/// Google Gemini AI service for restaurant recommendations
class AIService {
  final AIServiceConfig _config;
  final GenerativeModel _model;
  final ApiMonitoringService? _monitoringService;
  final Map<String, AIServiceResponse<AIRecommendation>> _cache = {};
  
  // Cost tracking
  double _dailyCostCents = 0.0;
  DateTime _lastCostReset = DateTime.now();
  
  // Request throttling
  final List<DateTime> _recentRequests = [];
  static const int _maxRequestsPerMinute = 10;

  AIService._(this._config, this._model, this._monitoringService);

  /// Factory constructor with API key validation and monitoring
  static AIService create(AIServiceConfig config, {ApiMonitoringService? monitoringService}) {
    if (config.apiKey.isEmpty) {
      throw const AIServiceException('API key cannot be empty');
    }

    try {
      final model = GenerativeModel(
        model: config.model,
        apiKey: config.apiKey,
        generationConfig: GenerationConfig(
          temperature: config.temperature,
          maxOutputTokens: config.maxTokens,
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.harassment,
            HarmBlockThreshold.high,
          ),
          SafetySetting(
            HarmCategory.hateSpeech,
            HarmBlockThreshold.high,
          ),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.high,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.high,
          ),
        ],
      );

      return AIService._(config, model, monitoringService);
    } catch (e) {
      throw AIServiceException('Failed to initialize AI service: $e');
    }
  }

  /// Generate AI recommendations for restaurants
  Future<AIServiceResponse<AIRecommendation>> generateRecommendations(
    AIRecommendationRequest request,
  ) async {
    // Record request start
    await _recordRequest(request);
    
    try {
      // Check request throttling
      await _checkRequestThrottling();
      
      // Check daily cost limit
      _checkCostLimit();

      // Check cache first
      final cacheKey = _generateCacheKey(request);
      if (_config.enableCaching && _cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (cached.data.isStillRelevant) {
          await _recordCacheHit(request);
          return cached;
        } else {
          _cache.remove(cacheKey);
        }
      }

      final stopwatch = Stopwatch()..start();
      
      // Generate AI recommendation
      final prompt = _buildRecommendationPrompt(request);
      final response = await _makeRequest(prompt);
      
      stopwatch.stop();

      // Parse response
      final recommendation = _parseRecommendationResponse(
        response.text!,
        request,
        stopwatch.elapsed,
      );

      // Estimate tokens and cost
      final tokensUsed = _estimateTokens(prompt + (response.text ?? ''));
      final costCents = _calculateCost(tokensUsed);
      
      _updateDailyCost(costCents);

      final serviceResponse = AIServiceResponse<AIRecommendation>(
        data: recommendation,
        responseTime: stopwatch.elapsed,
        tokensUsed: tokensUsed,
        estimatedCostCents: costCents,
        metadata: {
          'model': _config.model,
          'temperature': _config.temperature,
          'cached': false,
        },
      );

      // Cache if enabled
      if (_config.enableCaching) {
        _cache[cacheKey] = serviceResponse;
      }

      // Record successful response
      await _recordSuccessfulResponse(request, stopwatch.elapsed, costCents);

      return serviceResponse;
    } on AIServiceException catch (e) {
      await _recordErrorResponse(request, e.toString(), e.errorCode);
      rethrow;
    } catch (e) {
      final errorMessage = 'Failed to generate recommendations: $e';
      await _recordErrorResponse(request, errorMessage, null);
      throw AIServiceException(
        errorMessage,
        isRetryable: _isRetryableError(e),
      );
    }
  }

  /// Build structured prompt for AI recommendations
  String _buildRecommendationPrompt(AIRecommendationRequest request) {
    final context = request.context;
    final restaurants = request.availableRestaurants;
    
    return '''
You are a food recommendation AI that helps users make investment-minded dining decisions. 
Your task is to recommend the best restaurants from the available options based on user context.

USER CONTEXT:
- User ID: ${request.userId}
- Current meal type: ${context.currentMealType}
- Budget range: ${context.budgetRange}
- Dietary preferences: ${json.encode(context.dietaryPreferences)}
- Recent meals: ${context.recentMealHistory.take(5).join(', ')}
- Location: ${json.encode(context.locationContext)}
- Time context: ${json.encode(context.temporalContext)}
- Preference scores: ${json.encode(context.preferenceScores)}
${request.specificCravings != null ? '- Specific cravings: ${request.specificCravings}' : ''}

AVAILABLE RESTAURANTS (${restaurants.length} options):
${restaurants.take(20).map((r) => '''
- ${r.name} (${r.placeId})
  Location: ${r.address ?? r.location}
  Rating: ${r.rating ?? 'N/A'}/5 (${r.reviewCount ?? 0} reviews)
  Price Level: ${_formatPriceLevel(r.priceLevel)}
  Average Cost: \$${r.averageMealCost?.toStringAsFixed(2) ?? 'N/A'}
  Value Score: ${((r.valueScore ?? 0.5) * 100).round()}%
  Cuisine: ${r.cuisineTypes.join(', ')}
  Dietary Support: ${r.supportedDietaryRestrictions.join(', ')}
  Features: ${r.features.join(', ')}
  Distance: ${r.distanceFromUser?.toStringAsFixed(1) ?? 'N/A'} km
''').join('\n')}

RECOMMENDATION CRITERIA (weighted importance):
1. Budget Compatibility (25%): Match user's budget range with restaurant pricing
2. Dietary Compatibility (25%): Match dietary restrictions and preferences  
3. Location Convenience (20%): Prefer closer restaurants, consider travel time
4. Historical Preferences (15%): Learn from past selections and ratings
5. Temporal Relevance (10%): Consider time of day, day of week patterns
6. Social Validation (5%): Factor in ratings and review counts

INVESTMENT MINDSET MESSAGING:
- Frame costs as "investment opportunities" not expenses
- Emphasize value scores and cost-effectiveness
- Highlight long-term satisfaction potential
- Use positive psychology in cost discussions

RESPONSE FORMAT (JSON):
{
  "recommendations": [
    {
      "placeId": "restaurant_place_id",
      "rank": 1,
      "confidenceScore": 0.85,
      "investmentScore": 0.90,
      "factorScores": {
        "budget": 0.9,
        "dietary": 0.8,
        "location": 0.7,
        "history": 0.6,
        "temporal": 0.8,
        "social": 0.7
      }
    }
  ],
  "reasoning": "Clear explanation of why these restaurants were selected, emphasizing investment mindset and value proposition",
  "overallConfidence": 0.82,
  "investmentSummary": "Brief summary of the investment opportunity and expected value"
}

Recommend up to ${request.maxRecommendations} restaurants, ranked by overall suitability.
Focus on providing clear reasoning that builds trust and explains the value proposition.
''';
  }

  /// Parse AI response into recommendation object
  AIRecommendation _parseRecommendationResponse(
    String responseText,
    AIRecommendationRequest request,
    Duration responseTime,
  ) {
    try {
      final jsonResponse = json.decode(responseText) as Map<String, dynamic>;
      final recommendations = jsonResponse['recommendations'] as List<dynamic>;
      
      // Get recommended restaurants from the original list
      final recommendedRestaurants = <Restaurant>[];
      final factorWeights = <String, double>{};
      
      for (final rec in recommendations) {
        final placeId = rec['placeId'] as String;
        final restaurant = request.availableRestaurants
            .firstWhere((r) => r.placeId == placeId);
        recommendedRestaurants.add(restaurant);
        
        // Extract factor weights from first recommendation
        if (factorWeights.isEmpty && rec['factorScores'] != null) {
          final factors = rec['factorScores'] as Map<String, dynamic>;
          factors.forEach((key, value) {
            factorWeights[key] = (value as num).toDouble();
          });
        }
      }

      return AIRecommendation(
        id: _generateRecommendationId(request.userId, DateTime.now()),
        userId: request.userId,
        recommendedRestaurants: recommendedRestaurants,
        reasoning: jsonResponse['reasoning'] as String,
        factorWeights: factorWeights,
        overallConfidence: (jsonResponse['overallConfidence'] as num).toDouble(),
        userContext: {
          'budgetRange': request.context.budgetRange,
          'mealType': request.context.currentMealType,
          'dietaryPreferences': request.context.dietaryPreferences,
          'locationContext': request.context.locationContext,
        },
        generatedAt: DateTime.now(),
        metadata: {
          'responseTime': responseTime.inMilliseconds,
          'investmentSummary': jsonResponse['investmentSummary'],
          'requestId': _generateRequestId(),
        },
      );
    } catch (e) {
      throw AIServiceException('Failed to parse AI response: $e');
    }
  }

  /// Make request to Gemini API with retries
  Future<GenerateContentResponse> _makeRequest(String prompt) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _config.maxRetries) {
      try {
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content)
            .timeout(_config.requestTimeout);
        
        if (response.text == null || response.text!.isEmpty) {
          throw const AIServiceException('Empty response from AI service');
        }

        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;
        
        if (attempts < _config.maxRetries && _isRetryableError(e)) {
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
          continue;
        }
        
        break;
      }
    }

    throw AIServiceException(
      'Failed after $attempts attempts: ${lastException?.toString()}',
      isRetryable: false,
    );
  }

  /// Check request rate limiting
  Future<void> _checkRequestThrottling() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old requests
    _recentRequests.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    if (_recentRequests.length >= _maxRequestsPerMinute) {
      final oldestRecent = _recentRequests.first;
      final waitTime = oldestRecent.add(const Duration(minutes: 1)).difference(now);
      
      if (waitTime.isNegative) {
        _recentRequests.clear();
      } else {
        throw AIServiceException(
          'Rate limit exceeded. Try again in ${waitTime.inSeconds} seconds.',
          isRetryable: true,
        );
      }
    }
    
    _recentRequests.add(now);
  }

  /// Check daily cost limit
  void _checkCostLimit() {
    final now = DateTime.now();
    
    // Reset daily cost if it's a new day
    if (!_isSameDay(_lastCostReset, now)) {
      _dailyCostCents = 0.0;
      _lastCostReset = now;
    }
    
    if (_dailyCostCents / 100 >= _config.costLimitPerDayDollars) {
      throw const AIServiceException(
        'Daily cost limit exceeded. AI recommendations will reset tomorrow.',
        isRetryable: false,
      );
    }
  }

  /// Utility methods
  String _generateCacheKey(AIRecommendationRequest request) {
    final keyData = {
      'userId': request.userId,
      'budgetRange': request.context.budgetRange,
      'mealType': request.context.currentMealType,
      'restaurantIds': request.availableRestaurants.map((r) => r.placeId).take(10).toList(),
      'cravings': request.specificCravings,
    };
    return json.encode(keyData).hashCode.toString();
  }

  String _generateRecommendationId(int userId, DateTime timestamp) {
    return 'ai_rec_${userId}_${timestamp.millisecondsSinceEpoch}';
  }

  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  String _formatPriceLevel(int? priceLevel) {
    switch (priceLevel) {
      case 1: return '\$ (Budget-friendly)';
      case 2: return '\$\$ (Moderate)';
      case 3: return '\$\$\$ (Upscale)';
      case 4: return '\$\$\$\$ (Premium)';
      default: return 'N/A';
    }
  }

  int _estimateTokens(String text) {
    // Rough estimation: 4 characters per token
    return (text.length / 4).ceil();
  }

  double _calculateCost(int tokens) {
    // Gemini Flash pricing: ~$0.075 per 1K input tokens, ~$0.30 per 1K output tokens
    // Assuming 70% input, 30% output
    const inputCostPer1k = 0.075;
    const outputCostPer1k = 0.30;
    
    final inputTokens = (tokens * 0.7).round();
    final outputTokens = (tokens * 0.3).round();
    
    final inputCostCents = (inputTokens / 1000) * inputCostPer1k * 100;
    final outputCostCents = (outputTokens / 1000) * outputCostPer1k * 100;
    
    return inputCostCents + outputCostCents;
  }

  void _updateDailyCost(double costCents) {
    _dailyCostCents += costCents;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('503') ||
           errorString.contains('rate limit');
  }

  /// Get current daily cost usage
  double get dailyCostDollars => _dailyCostCents / 100;
  
  /// Get remaining daily budget
  double get remainingDailyBudgetDollars => 
      (_config.costLimitPerDayDollars - dailyCostDollars).clamp(0.0, _config.costLimitPerDayDollars);

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'dailyCostDollars': dailyCostDollars,
      'remainingBudgetDollars': remainingDailyBudgetDollars,
      'recentRequestsCount': _recentRequests.length,
    };
  }

  // ========================================
  // Monitoring Integration Methods
  // ========================================

  /// Record API request for monitoring
  Future<void> _recordRequest(AIRecommendationRequest request) async {
    if (_monitoringService == null || !ApiConfig.enableUsageMonitoring) return;

    try {
      await _monitoringService!.recordRequest(
        service: 'gemini',
        endpoint: 'generateContent',
        requestData: {
          'model': _config.model,
          'userId': request.userId,
          'restaurantCount': request.availableRestaurants.length,
          'maxRecommendations': request.maxRecommendations,
          'hasCravings': request.specificCravings != null,
        },
        userId: request.userId.toString(),
      );
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('Failed to record AI request: $e');
      }
    }
  }

  /// Record successful API response
  Future<void> _recordSuccessfulResponse(
    AIRecommendationRequest request,
    Duration responseTime,
    double costCents,
  ) async {
    if (_monitoringService == null || !ApiConfig.enableUsageMonitoring) return;

    try {
      await _monitoringService!.recordResponse(
        service: 'gemini',
        endpoint: 'generateContent',
        success: true,
        responseTime: responseTime,
        costCents: costCents,
        responseData: {
          'recommendationCount': request.maxRecommendations,
          'cached': false,
        },
      );
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('Failed to record AI success response: $e');
      }
    }
  }

  /// Record error response
  Future<void> _recordErrorResponse(
    AIRecommendationRequest request,
    String error,
    String? errorCode,
  ) async {
    if (_monitoringService == null || !ApiConfig.enableUsageMonitoring) return;

    try {
      await _monitoringService!.recordError(
        service: 'gemini',
        endpoint: 'generateContent',
        error: error,
        errorCode: errorCode,
        context: {
          'userId': request.userId,
          'restaurantCount': request.availableRestaurants.length,
          'model': _config.model,
        },
      );
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('Failed to record AI error: $e');
      }
    }
  }

  /// Record cache hit for monitoring
  Future<void> _recordCacheHit(AIRecommendationRequest request) async {
    if (_monitoringService == null || !ApiConfig.enableUsageMonitoring) return;

    try {
      await _monitoringService!.recordResponse(
        service: 'gemini',
        endpoint: 'generateContent',
        success: true,
        responseTime: const Duration(milliseconds: 1), // Cache hit is instant
        costCents: 0.0, // No cost for cached responses
        responseData: {
          'recommendationCount': request.maxRecommendations,
          'cached': true,
        },
      );
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('Failed to record AI cache hit: $e');
      }
    }
  }

  /// Record rate limit hit
  Future<void> _recordRateLimitHit(String reason, Duration? retryAfter) async {
    if (_monitoringService == null || !ApiConfig.enableUsageMonitoring) return;

    try {
      await _monitoringService!.recordRateLimitHit(
        service: 'gemini',
        reason: reason,
        retryAfter: retryAfter,
      );
    } catch (e) {
      if (ApiConfig.enableDebugLogging) {
        print('Failed to record AI rate limit: $e');
      }
    }
  }
}