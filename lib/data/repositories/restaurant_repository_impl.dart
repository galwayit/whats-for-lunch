import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config/api_config.dart';
import '../../domain/entities/restaurant.dart' as domain;
import '../../domain/repositories/restaurant_repository.dart';
import '../database/database.dart';
import '../mappers/entity_mappers.dart';

/// Enhanced restaurant repository with Google Places API integration
/// Optimized for <$85/month cost and intelligent caching
class RestaurantRepositoryImpl implements RestaurantRepository {
  final AppDatabase _database;
  final Dio _dio;
  static const Duration _cacheExpiryDuration = Duration(hours: 24);

  RestaurantRepositoryImpl(this._database) : _dio = Dio() {
    _dio.options.baseUrl = ApiConfig.googlePlacesBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  @override
  Future<int> cacheRestaurant(domain.Restaurant restaurant) async {
    final companion = EntityMappers.restaurantToCompanion(restaurant);
    return await _database.insertRestaurant(companion);
  }

  @override
  Future<domain.Restaurant?> getRestaurantByPlaceId(String placeId) async {
    final restaurant = await _database.getRestaurantByPlaceId(placeId);
    if (restaurant == null) return null;
    return EntityMappers.restaurantFromDatabase(restaurant);
  }

  @override
  Future<List<domain.Restaurant>> getAllCachedRestaurants() async {
    final restaurants = await _database.getAllRestaurants();
    return restaurants
        .map((restaurant) => EntityMappers.restaurantFromDatabase(restaurant))
        .toList();
  }

  @override
  Future<bool> updateRestaurant(domain.Restaurant restaurant) async {
    final companion = EntityMappers.restaurantToCompanion(restaurant);
    final updatedRows = await (_database.update(_database.restaurants)
          ..where((tbl) => tbl.placeId.equals(restaurant.placeId)))
        .replace(companion);
    return updatedRows;
  }

  @override
  Future<bool> deleteRestaurant(String placeId) async {
    final deletedRows = await (_database.delete(_database.restaurants)
          ..where((tbl) => tbl.placeId.equals(placeId)))
        .go();
    return deletedRows > 0;
  }

  @override
  Future<bool> clearExpiredCache(Duration maxAge) async {
    final cutoffTime = DateTime.now().subtract(maxAge);
    final deletedRows = await (_database.delete(_database.restaurants)
          ..where((tbl) => tbl.cachedAt.isSmallerThan(Variable(cutoffTime))))
        .go();
    return deletedRows > 0;
  }

  /// Search restaurants near location using Google Places API with caching
  Future<List<domain.Restaurant>> searchRestaurantsNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? query,
    List<String>? cuisineTypes,
    int? priceLevel,
    double? minRating,
    bool forceRefresh = false,
  }) async {
    try {
      // Check if valid API key is configured
      if (!ApiConfig.hasValidGooglePlacesKey) {
        return [];
      }

      // Check cache first
      if (!forceRefresh) {
        final cachedResults = await _getCachedResults(
          latitude: latitude,
          longitude: longitude,
          query: query ?? '',
          radiusKm: radiusKm,
        );

        if (cachedResults.isNotEmpty) {
          return cachedResults;
        }
      }

      // Search using Google Places API
      final placesResults = await _searchPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        query: query,
        priceLevel: priceLevel,
        minRating: minRating,
      );

      // Enhance with local data and dietary information
      final enhancedRestaurants = await _enhanceWithLocalData(placesResults);

      // Cache results for future use
      await _cacheResults(
        latitude: latitude,
        longitude: longitude,
        query: query ?? '',
        restaurants: enhancedRestaurants,
      );

      // Apply cuisine type filters
      if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
        return enhancedRestaurants.where((restaurant) {
          return cuisineTypes.any((cuisine) =>
              restaurant.cuisineType
                      ?.toLowerCase()
                      .contains(cuisine.toLowerCase()) ==
                  true ||
              restaurant.cuisineTypes.any((type) =>
                  type.toLowerCase().contains(cuisine.toLowerCase())));
        }).toList();
      }

      return enhancedRestaurants;
    } catch (e) {
      // Fallback to local database
      final localResults = await _database.getRestaurantsNearLocation(
        latitude,
        longitude,
        radiusKm,
      );

      return EntityMappers.restaurantsFromDatabase(localResults);
    }
  }

  /// Search places using Google Places API with cost optimization
  Future<List<domain.Restaurant>> _searchPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? query,
    int? priceLevel,
    double? minRating,
  }) async {
    try {
      final restaurants = <domain.Restaurant>[];

      // Use Nearby Search for better cost efficiency than Text Search
      final response = await _dio.get(
        '/nearbysearch/json',
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': (radiusKm * 1000).round(), // Convert to meters
          'type': 'restaurant',
          'key': ApiConfig.googlePlacesApiKey,
          'fields':
              'place_id,name,geometry,rating,price_level,types,vicinity,photos',
          if (query != null && query.isNotEmpty) 'keyword': query,
          if (minRating != null) 'min_rating': minRating,
          if (priceLevel != null) 'max_price': priceLevel,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        for (final result in results) {
          final restaurant =
              _parseGooglePlaceResult(result, latitude, longitude);
          if (restaurant != null) {
            restaurants.add(restaurant);
          }
        }

        // Handle pagination if needed (cost-conscious approach)
        if (data['next_page_token'] != null && restaurants.length < 20) {
          // Only fetch next page if we have fewer than 20 results
          await Future.delayed(
              const Duration(seconds: 2)); // Required delay for next_page_token

          final nextPageResponse = await _dio.get(
            '/nearbysearch/json',
            queryParameters: {
              'pagetoken': data['next_page_token'],
              'key': ApiConfig.googlePlacesApiKey,
            },
          );

          if (nextPageResponse.statusCode == 200) {
            final nextData = nextPageResponse.data as Map<String, dynamic>;
            final nextResults = nextData['results'] as List<dynamic>? ?? [];

            for (final result in nextResults) {
              final restaurant =
                  _parseGooglePlaceResult(result, latitude, longitude);
              if (restaurant != null) {
                restaurants.add(restaurant);
              }
            }
          }
        }
      }

      return restaurants;
    } catch (e) {
      return [];
    }
  }

  /// Parse Google Places API result into Restaurant entity
  domain.Restaurant? _parseGooglePlaceResult(
    Map<String, dynamic> result,
    double userLat,
    double userLng,
  ) {
    try {
      final placeId = result['place_id'] as String?;
      final name = result['name'] as String?;
      final vicinity = result['vicinity'] as String?;

      if (placeId == null || name == null) {
        return null;
      }

      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = location?['lat'] as double?;
      final lng = location?['lng'] as double?;

      final rating = (result['rating'] as num?)?.toDouble();
      final priceLevel = result['price_level'] as int?;
      final types = List<String>.from(result['types'] as List? ?? []);
      final photos = result['photos'] as List<dynamic>? ?? [];

      // Calculate distance
      double? distance;
      if (lat != null && lng != null) {
        distance =
            Geolocator.distanceBetween(userLat, userLng, lat, lng) / 1000;
      }

      // Extract cuisine types from Google types
      final cuisineTypes = _extractCuisineTypes(types);
      final features = _extractFeatures(types);

      // Get photo reference
      String? photoReference;
      if (photos.isNotEmpty) {
        photoReference = photos.first['photo_reference'] as String?;
      }

      return domain.Restaurant(
        placeId: placeId,
        name: name,
        location: vicinity ?? 'Unknown location',
        latitude: lat,
        longitude: lng,
        distanceFromUser: distance,
        rating: rating,
        priceLevel: priceLevel,
        priceRanges: priceLevel != null ? [r'$' * priceLevel] : [],
        cuisineTypes: cuisineTypes,
        cuisineType: cuisineTypes.isNotEmpty ? cuisineTypes.first : null,
        features: features,
        cachedAt: DateTime.now(),
        photoReference: photoReference,
        photoReferences:
            photos.map((p) => p['photo_reference'] as String).toList(),

        // Default values for dietary information (would be enhanced with additional data)
        supportedDietaryRestrictions: [],
        allergenInfo: [],
        dietaryCompatibilityScores: {},
        hasVerifiedDietaryInfo: false,
        communityVerificationCount: 0,
        openingHours: [],
        isOpenNow: result['opening_hours']?['open_now'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Extract cuisine types from Google Places types
  List<String> _extractCuisineTypes(List<String> types) {
    final cuisineMap = {
      'italian': 'Italian',
      'chinese': 'Chinese',
      'japanese': 'Japanese',
      'mexican': 'Mexican',
      'indian': 'Indian',
      'thai': 'Thai',
      'french': 'French',
      'american': 'American',
      'mediterranean': 'Mediterranean',
      'korean': 'Korean',
      'vietnamese': 'Vietnamese',
      'seafood': 'Seafood',
      'steakhouse': 'Steakhouse',
      'pizza': 'Pizza',
      'burger': 'Burgers',
      'sushi': 'Sushi',
      'bakery': 'Bakery',
      'cafe': 'Cafe',
      'fast_food': 'Fast Food',
      'fine_dining': 'Fine Dining',
    };

    final cuisines = <String>[];
    for (final type in types) {
      final cuisine = cuisineMap[type.toLowerCase()];
      if (cuisine != null && !cuisines.contains(cuisine)) {
        cuisines.add(cuisine);
      }
    }

    // Fallback to general classification
    if (cuisines.isEmpty) {
      if (types.contains('restaurant')) {
        cuisines.add('Restaurant');
      } else if (types.contains('food')) {
        cuisines.add('Food');
      }
    }

    return cuisines;
  }

  /// Extract features from Google Places types
  List<String> _extractFeatures(List<String> types) {
    final features = <String>[];

    if (types.contains('meal_delivery')) features.add('delivery');
    if (types.contains('meal_takeaway')) features.add('takeout');
    if (types.contains('dine_in')) features.add('dine_in');
    if (types.contains('wheelchair_accessible')) {
      features.add('wheelchair_accessible');
    }
    if (types.contains('outdoor_seating')) features.add('outdoor_seating');
    if (types.contains('wifi')) features.add('wifi');

    return features;
  }

  /// Enhance Google Places results with local dietary and preference data
  Future<List<domain.Restaurant>> _enhanceWithLocalData(
      List<domain.Restaurant> restaurants) async {
    final enhancedRestaurants = <domain.Restaurant>[];

    for (final restaurant in restaurants) {
      try {
        // Check if we have local dietary data for this restaurant
        final localRestaurant =
            await _database.getRestaurantByPlaceId(restaurant.placeId);

        if (localRestaurant != null) {
          final localData =
              EntityMappers.restaurantFromDatabase(localRestaurant);

          // Merge Google Places data with local dietary data
          final enhanced = restaurant.copyWith(
            supportedDietaryRestrictions:
                localData.supportedDietaryRestrictions,
            allergenInfo: localData.allergenInfo,
            dietaryCompatibilityScores: localData.dietaryCompatibilityScores,
            hasVerifiedDietaryInfo: localData.hasVerifiedDietaryInfo,
            communityVerificationCount: localData.communityVerificationCount,
            averageMealCost: localData.averageMealCost,
            valueScore: localData.valueScore,
            mealTypeAverageCosts: localData.mealTypeAverageCosts,
          );

          enhancedRestaurants.add(enhanced);
        } else {
          // No local data available, use Google Places data with defaults
          enhancedRestaurants.add(restaurant);
        }

        // Save/update in local database for future caching
        await cacheRestaurant(restaurant);
      } catch (e) {
        enhancedRestaurants.add(restaurant);
      }
    }

    return enhancedRestaurants;
  }

  /// Get cached restaurant results to optimize API costs
  Future<List<domain.Restaurant>> _getCachedResults({
    required double latitude,
    required double longitude,
    required String query,
    required double radiusKm,
  }) async {
    try {
      final cacheEntries =
          await _database.getCachedRestaurants(query, latitude, longitude);

      if (cacheEntries.isEmpty) {
        return [];
      }

      // Check if cache is still valid
      final latestEntry = cacheEntries.first;
      if (DateTime.now().isAfter(latestEntry.expiresAt)) {
        return [];
      }

      // Get restaurants from cache
      final restaurants = <domain.Restaurant>[];
      for (final entry in cacheEntries) {
        final restaurant =
            await _database.getRestaurantByPlaceId(entry.placeId);
        if (restaurant != null) {
          final restaurantEntity =
              EntityMappers.restaurantFromDatabase(restaurant);

          // Verify restaurant is still within radius
          if (restaurantEntity.latitude != null &&
              restaurantEntity.longitude != null) {
            final distance = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  restaurantEntity.latitude!,
                  restaurantEntity.longitude!,
                ) /
                1000;

            if (distance <= radiusKm) {
              restaurants
                  .add(restaurantEntity.copyWith(distanceFromUser: distance));
            }
          }
        }
      }

      return restaurants;
    } catch (e) {
      return [];
    }
  }

  /// Cache restaurant search results for cost optimization
  Future<void> _cacheResults({
    required double latitude,
    required double longitude,
    required String query,
    required List<domain.Restaurant> restaurants,
  }) async {
    try {
      final expiresAt = DateTime.now().add(_cacheExpiryDuration);

      for (final restaurant in restaurants) {
        // Insert cache entry
        await _database.insertRestaurantCache(
          RestaurantCacheCompanion.insert(
            placeId: restaurant.placeId,
            searchQuery: query,
            userLatitude: latitude,
            userLongitude: longitude,
            expiresAt: expiresAt,
          ),
        );
      }
    } catch (e) {
      // Cache error is not critical, continue silently
    }
  }

  /// Get photo URL from photo reference
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '${ApiConfig.googlePlacesBaseUrl}/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=${ApiConfig.googlePlacesApiKey}';
  }

  /// Fetch recent reviews for a restaurant using Google Places API
  Future<List<domain.RestaurantReview>> fetchRestaurantReviews(
    String placeId, {
    int maxReviews = 10,
  }) async {
    try {
      if (!ApiConfig.hasValidGooglePlacesKey) {
        return [];
      }

      // Use Place Details API to get reviews
      final response = await _dio.get(
        '/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'reviews',
          'key': ApiConfig.googlePlacesApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        final reviews = result?['reviews'] as List<dynamic>? ?? [];

        final restaurantReviews = <domain.RestaurantReview>[];
        
        for (final reviewData in reviews.take(maxReviews)) {
          try {
            final review = domain.RestaurantReview.fromGooglePlaces(
              reviewData as Map<String, dynamic>
            );
            restaurantReviews.add(review);
          } catch (e) {
            // Skip invalid review data
          }
        }

        // Sort by most recent first
        restaurantReviews.sort((a, b) => b.time.compareTo(a.time));

        return restaurantReviews;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Update restaurant with fresh reviews data
  Future<domain.Restaurant?> updateRestaurantWithReviews(
    String placeId, {
    bool forceRefresh = false,
  }) async {
    try {
      final restaurant = await getRestaurantByPlaceId(placeId);
      if (restaurant == null) {
        return null;
      }

      // Check if we need to refresh reviews (cache for 6 hours)
      final needsRefresh = forceRefresh ||
          restaurant.reviewsLastFetched == null ||
          DateTime.now().difference(restaurant.reviewsLastFetched!).inHours >= 6;

      if (!needsRefresh) {
        return restaurant;
      }

      // Fetch fresh reviews
      final reviews = await fetchRestaurantReviews(placeId);
      
      // Generate AI sentiment summary
      String? aiSentimentSummary;
      if (reviews.isNotEmpty) {
        final sentiment = _generateSentimentSummary(reviews);
        aiSentimentSummary = sentiment;
      }

      // Update restaurant with reviews
      final updatedRestaurant = restaurant.copyWith(
        recentReviews: reviews,
        reviewsLastFetched: DateTime.now(),
        aiSentimentSummary: aiSentimentSummary,
      );

      // Save updated restaurant
      await updateRestaurant(updatedRestaurant);

      return updatedRestaurant;
    } catch (e) {
      return null;
    }
  }

  /// Generate AI sentiment summary from reviews
  String _generateSentimentSummary(List<domain.RestaurantReview> reviews) {
    if (reviews.isEmpty) return 'No recent reviews available';

    final positiveReviews = reviews.where((r) => r.getSentiment() == domain.ReviewSentiment.positive).length;
    final negativeReviews = reviews.where((r) => r.getSentiment() == domain.ReviewSentiment.negative).length;

    final totalReviews = reviews.length;
    final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

    // Extract common themes
    final allReviewText = reviews
        .where((r) => r.text != null && r.text!.isNotEmpty)
        .map((r) => r.text!.toLowerCase())
        .join(' ');

    final commonPositiveWords = ['great', 'excellent', 'delicious', 'amazing', 'wonderful', 'love', 'perfect'];
    final commonNegativeWords = ['bad', 'terrible', 'awful', 'disappointing', 'poor', 'worst'];
    
    final positiveThemes = commonPositiveWords.where((word) => allReviewText.contains(word)).toList();
    final negativeThemes = commonNegativeWords.where((word) => allReviewText.contains(word)).toList();

    String summary = 'Recent reviews ($totalReviews): ';
    
    if (positiveReviews > negativeReviews) {
      summary += 'Mostly positive sentiment. ';
      if (positiveThemes.isNotEmpty) {
        summary += 'Customers praise: ${positiveThemes.take(3).join(', ')}. ';
      }
    } else if (negativeReviews > positiveReviews) {
      summary += 'Mixed sentiment with some concerns. ';
      if (negativeThemes.isNotEmpty) {
        summary += 'Issues mentioned: ${negativeThemes.take(3).join(', ')}. ';
      }
    } else {
      summary += 'Balanced customer feedback. ';
    }

    summary += 'Average recent rating: ${averageRating.toStringAsFixed(1)}/5.0';

    return summary;
  }

  /// Update dietary information for a restaurant (community contribution)
  Future<void> updateDietaryInfo({
    required String placeId,
    List<String>? supportedDietaryRestrictions,
    List<String>? allergenInfo,
    Map<String, double>? compatibilityScores,
    bool? isVerified,
  }) async {
    try {
      final restaurant = await getRestaurantByPlaceId(placeId);
      if (restaurant == null) return;

      final updatedRestaurant = restaurant.copyWith(
        supportedDietaryRestrictions: supportedDietaryRestrictions ??
            restaurant.supportedDietaryRestrictions,
        allergenInfo: allergenInfo ?? restaurant.allergenInfo,
        dietaryCompatibilityScores:
            compatibilityScores ?? restaurant.dietaryCompatibilityScores,
        hasVerifiedDietaryInfo: isVerified ?? restaurant.hasVerifiedDietaryInfo,
        communityVerificationCount: restaurant.communityVerificationCount + 1,
        lastVerified: DateTime.now(),
      );

      await updateRestaurant(updatedRestaurant);
    } catch (e) {
      // Update failed, continue silently
    }
  }
}
