# Technical Specifications - What We Have For Lunch

## Architecture Overview

### Clean Architecture Implementation

```
Presentation Layer (UI)
├── Screens (login, home, map, profile)
├── Widgets (custom components)
└── Providers (Riverpod state management)

Domain Layer (Business Logic)
├── Entities (User, Restaurant, Meal, Budget)
├── Use Cases (GetRecommendations, TrackMeal, SearchRestaurants)
└── Repository Interfaces

Data Layer
├── Repositories (implementation)
├── Data Sources (local DB, APIs)
└── Models (data transfer objects)
```

### Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── network/
├── features/
│   ├── authentication/
│   ├── diet_tracking/
│   ├── restaurant_search/
│   ├── recommendations/
│   └── budget_management/
├── shared/
│   ├── widgets/
│   ├── providers/
│   └── services/
└── main.dart
```

## Database Design

### Drift Schema Implementation

```dart
// lib/core/database/database.dart
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().unique()();
  TextColumn get preferences => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get restaurantId => text().nullable()();
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack
  RealColumn get cost => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
}

class BudgetTracking extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get amount => real()();
  TextColumn get category => text()(); // dining, groceries, etc.
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
}

class Restaurants extends Table {
  TextColumn get placeId => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get priceLevel => integer().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get cuisineType => text().nullable()();
  TextColumn get photoReference => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {placeId};
}

class UserPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get dietaryRestrictions => text()(); // JSON array
  RealColumn get weeklyBudget => real()();
  IntColumn get maxTravelDistance => integer()(); // in meters
  TextColumn get favoriteRestaurants => text().nullable()(); // JSON array
  TextColumn get dislikedRestaurants => text().nullable()(); // JSON array
}

@DriftDatabase(tables: [Users, Meals, BudgetTracking, Restaurants, UserPreferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
}
```

## API Integration

### Google Maps Services

```dart
// lib/features/restaurant_search/data/google_places_service.dart
class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final Dio _dio;
  final String _apiKey;
  
  GooglePlacesService(this._dio, this._apiKey);
  
  Future<List<Restaurant>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    int radius = 1000,
    String type = 'restaurant',
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/nearbysearch/json',
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': radius,
          'type': type,
          'key': _apiKey,
        },
      );
      
      return (response.data['results'] as List)
          .map((json) => Restaurant.fromGooglePlaces(json))
          .toList();
    } catch (e) {
      throw RestaurantSearchException('Failed to search restaurants: $e');
    }
  }
  
  Future<RestaurantDetails> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'name,rating,formatted_phone_number,website,opening_hours,price_level,reviews',
          'key': _apiKey,
        },
      );
      
      return RestaurantDetails.fromGooglePlaces(response.data['result']);
    } catch (e) {
      throw RestaurantDetailsException('Failed to get restaurant details: $e');
    }
  }
}
```

### AI Recommendation Service

```dart
// lib/features/recommendations/data/gemini_service.dart
class GeminiRecommendationService {
  final GenerativeModel _model;
  
  GeminiRecommendationService(String apiKey) 
    : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  
  Future<List<RestaurantRecommendation>> getRecommendations({
    required List<Restaurant> restaurants,
    required UserPreferences preferences,
    required BudgetConstraints budget,
    required int partySize,
    required String mealType,
  }) async {
    final prompt = _buildRecommendationPrompt(
      restaurants, preferences, budget, partySize, mealType
    );
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseRecommendations(response.text ?? '');
    } catch (e) {
      throw AIRecommendationException('Failed to generate recommendations: $e');
    }
  }
  
  String _buildRecommendationPrompt(
    List<Restaurant> restaurants,
    UserPreferences preferences,
    BudgetConstraints budget,
    int partySize,
    String mealType,
  ) {
    return '''
    You are a food recommendation expert. Analyze these restaurants and recommend the top 3 for $mealType based on the user's criteria.

    Restaurants:
    ${restaurants.map((r) => 
      '- ${r.name}: ${r.cuisineType}, Price: ${r.priceLevel}/4, Rating: ${r.rating}/5, Distance: ${r.distance}m'
    ).join('\n')}

    User Preferences:
    - Dietary restrictions: ${preferences.dietaryRestrictions.join(', ')}
    - Budget: \$${budget.maxAmount} for $partySize people
    - Max travel distance: ${preferences.maxTravelDistance}m

    Please return exactly 3 recommendations in this JSON format:
    {
      "recommendations": [
        {
          "restaurant_id": "place_id",
          "rank": 1,
          "reasoning": "Brief explanation why this is recommended",
          "confidence_score": 0.95,
          "estimated_cost": 45.00
        }
      ]
    }
    
    Focus on:
    1. Dietary compatibility
    2. Budget appropriateness
    3. Quality indicators (rating, reviews)
    4. Convenience (distance, wait times if available)
    ''';
  }
  
  List<RestaurantRecommendation> _parseRecommendations(String response) {
    try {
      final jsonResponse = json.decode(response);
      return (jsonResponse['recommendations'] as List)
          .map((json) => RestaurantRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      throw AIParsingException('Failed to parse AI response: $e');
    }
  }
}
```

## State Management with Riverpod

### Core Providers

```dart
// lib/shared/providers/core_providers.dart

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(databaseProvider));
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(
    ref.read(databaseProvider),
    ref.read(googlePlacesServiceProvider),
  );
});

// Service providers
final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService(
    ref.read(dioProvider),
    ref.read(configProvider).googleMapsApiKey,
  );
});

final geminiServiceProvider = Provider<GeminiRecommendationService>((ref) {
  return GeminiRecommendationService(
    ref.read(configProvider).geminiApiKey,
  );
});

// Location provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentPosition();
});

// User state providers
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<User?>>((ref) {
  return CurrentUserNotifier(ref.read(userRepositoryProvider));
});

final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences?>((ref) {
  return UserPreferencesNotifier(ref.read(userRepositoryProvider));
});
```

### Feature-Specific Providers

```dart
// lib/features/recommendations/providers/recommendation_providers.dart

final restaurantSearchProvider = FutureProvider.family<List<Restaurant>, SearchParams>((ref, params) async {
  final repository = ref.read(restaurantRepositoryProvider);
  return await repository.searchNearby(params);
});

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  return RecommendationNotifier(
    ref.read(geminiServiceProvider),
    ref.read(restaurantRepositoryProvider),
    ref.read(userPreferencesProvider.notifier),
  );
});

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final GeminiRecommendationService _geminiService;
  final RestaurantRepository _restaurantRepository;
  final UserPreferencesNotifier _userPreferences;
  
  RecommendationNotifier(
    this._geminiService,
    this._restaurantRepository,
    this._userPreferences,
  ) : super(const RecommendationState.initial());
  
  Future<void> getRecommendations({
    required Position userLocation,
    required String mealType,
    int partySize = 1,
  }) async {
    state = const RecommendationState.loading();
    
    try {
      // Get nearby restaurants
      final restaurants = await _restaurantRepository.searchNearby(
        SearchParams(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          radius: _userPreferences.value?.maxTravelDistance ?? 1000,
        ),
      );
      
      if (restaurants.isEmpty) {
        state = const RecommendationState.error('No restaurants found nearby');
        return;
      }
      
      // Get AI recommendations
      final preferences = _userPreferences.value;
      if (preferences == null) {
        state = const RecommendationState.error('User preferences not set');
        return;
      }
      
      final recommendations = await _geminiService.getRecommendations(
        restaurants: restaurants,
        preferences: preferences,
        budget: BudgetConstraints(maxAmount: preferences.weeklyBudget / 7),
        partySize: partySize,
        mealType: mealType,
      );
      
      state = RecommendationState.success(recommendations);
    } catch (e) {
      state = RecommendationState.error(e.toString());
    }
  }
}
```

## UI Components

### Recommendation Card Widget

```dart
// lib/features/recommendations/presentation/widgets/recommendation_card.dart
class RecommendationCard extends ConsumerWidget {
  final RestaurantRecommendation recommendation;
  final bool isPrimary;
  
  const RecommendationCard({
    Key? key,
    required this.recommendation,
    this.isPrimary = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: isPrimary ? 8 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: CachedNetworkImage(
              imageUrl: recommendation.restaurant.photoUrl ?? '',
              height: isPrimary ? 200 : 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerPlaceholder(),
              errorWidget: (context, url, error) => const RestaurantPlaceholder(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant name and cuisine
                Text(
                  recommendation.restaurant.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.restaurant.cuisineType ?? 'Restaurant',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Rating and price
                Row(
                  children: [
                    RatingStars(rating: recommendation.restaurant.rating ?? 0),
                    const SizedBox(width: 8),
                    PriceIndicator(level: recommendation.restaurant.priceLevel ?? 1),
                    const Spacer(),
                    DistanceChip(distance: recommendation.restaurant.distance),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // AI reasoning
                if (isPrimary) ...[
                  ReasoningExpansionTile(
                    reasoning: recommendation.reasoning,
                    confidence: recommendation.confidenceScore,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Text(
                    recommendation.reasoning,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Action buttons
                if (isPrimary) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openDirections(context, recommendation.restaurant),
                          icon: const Icon(Icons.directions),
                          label: const Text('Let\'s Go'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _callRestaurant(recommendation.restaurant),
                        icon: const Icon(Icons.phone),
                      ),
                      IconButton(
                        onPressed: () => _saveForLater(ref, recommendation),
                        icon: const Icon(Icons.bookmark_border),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _promoteToTop(ref, recommendation),
                      child: const Text('See Details'),
                    ),
                  ),
                ],
                
                // Quick feedback
                const SizedBox(height: 8),
                QuickFeedbackRow(
                  onThumbsUp: () => _submitFeedback(ref, recommendation, true),
                  onThumbsDown: () => _submitFeedback(ref, recommendation, false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _openDirections(BuildContext context, Restaurant restaurant) {
    // Launch Google Maps or Apple Maps
  }
  
  void _callRestaurant(Restaurant restaurant) {
    // Launch phone app
  }
  
  void _saveForLater(WidgetRef ref, RestaurantRecommendation recommendation) {
    // Save to favorites
  }
  
  void _promoteToTop(WidgetRef ref, RestaurantRecommendation recommendation) {
    // Update recommendation state
  }
  
  void _submitFeedback(WidgetRef ref, RestaurantRecommendation recommendation, bool positive) {
    // Submit feedback for ML learning
  }
}
```

## Performance Optimization

### Caching Strategy

```dart
// lib/core/cache/cache_manager.dart
class AppCacheManager {
  static const Duration restaurantCacheExpiry = Duration(hours: 24);
  static const Duration aiResponseCacheExpiry = Duration(hours: 6);
  
  final Box<String> _restaurantCache;
  final Box<String> _aiResponseCache;
  
  AppCacheManager(this._restaurantCache, this._aiResponseCache);
  
  // Restaurant caching
  Future<List<Restaurant>?> getCachedRestaurants(Position location, int radius) async {
    final key = _generateLocationKey(location, radius);
    final cached = _restaurantCache.get(key);
    
    if (cached == null) return null;
    
    final cacheData = json.decode(cached);
    final cachedAt = DateTime.parse(cacheData['cached_at']);
    
    if (DateTime.now().difference(cachedAt) > restaurantCacheExpiry) {
      await _restaurantCache.delete(key);
      return null;
    }
    
    return (cacheData['restaurants'] as List)
        .map((json) => Restaurant.fromJson(json))
        .toList();
  }
  
  Future<void> cacheRestaurants(Position location, int radius, List<Restaurant> restaurants) async {
    final key = _generateLocationKey(location, radius);
    final cacheData = {
      'cached_at': DateTime.now().toIso8601String(),
      'restaurants': restaurants.map((r) => r.toJson()).toList(),
    };
    
    await _restaurantCache.put(key, json.encode(cacheData));
  }
  
  // AI response caching
  Future<List<RestaurantRecommendation>?> getCachedRecommendations(String queryHash) async {
    final cached = _aiResponseCache.get(queryHash);
    if (cached == null) return null;
    
    final cacheData = json.decode(cached);
    final cachedAt = DateTime.parse(cacheData['cached_at']);
    
    if (DateTime.now().difference(cachedAt) > aiResponseCacheExpiry) {
      await _aiResponseCache.delete(queryHash);
      return null;
    }
    
    return (cacheData['recommendations'] as List)
        .map((json) => RestaurantRecommendation.fromJson(json))
        .toList();
  }
  
  String _generateLocationKey(Position location, int radius) {
    return '${location.latitude.toStringAsFixed(3)}_${location.longitude.toStringAsFixed(3)}_$radius';
  }
}
```

### Memory Management

```dart
// lib/core/utils/memory_manager.dart
class MemoryManager {
  static const int maxImageCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxDatabaseCacheSize = 50 * 1024 * 1024; // 50MB
  
  static void configureImageCache() {
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxImageCacheSize;
  }
  
  static Future<void> clearExpiredCache() async {
    // Clear expired restaurant cache
    final cacheManager = GetIt.instance<AppCacheManager>();
    await cacheManager.clearExpired();
    
    // Clear old meal photos
    await _clearOldMealPhotos();
    
    // Compact database
    await _compactDatabase();
  }
  
  static Future<void> _clearOldMealPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final mealPhotosDir = Directory('${directory.path}/meal_photos');
    
    if (!mealPhotosDir.existsSync()) return;
    
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    
    await for (final file in mealPhotosDir.list()) {
      if (file is File) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
        }
      }
    }
  }
  
  static Future<void> _compactDatabase() async {
    final database = GetIt.instance<AppDatabase>();
    await database.customStatement('VACUUM');
  }
}
```

## Security Implementation

### API Key Management

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  String get googleMapsApiKey {
    if (_googleMapsApiKey.isEmpty) {
      throw ConfigurationException('Google Maps API key not configured');
    }
    return _googleMapsApiKey;
  }
  
  String get geminiApiKey {
    if (_geminiApiKey.isEmpty) {
      throw ConfigurationException('Gemini API key not configured');
    }
    return _geminiApiKey;
  }
}
```

### Data Encryption

```dart
// lib/core/security/encryption_service.dart
class EncryptionService {
  static const String _keyAlias = 'user_data_encryption_key';
  
  Future<String> encryptSensitiveData(String data) async {
    final key = await _getOrCreateKey();
    final encryptor = Encrypter(AES(key));
    final iv = IV.fromSecureRandom(16);
    
    final encrypted = encryptor.encrypt(data, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
  
  Future<String> decryptSensitiveData(String encryptedData) async {
    final parts = encryptedData.split(':');
    if (parts.length != 2) throw EncryptionException('Invalid encrypted data format');
    
    final key = await _getOrCreateKey();
    final encryptor = Encrypter(AES(key));
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    
    return encryptor.decrypt(encrypted, iv: iv);
  }
  
  Future<Key> _getOrCreateKey() async {
    // Implementation would use platform-specific secure storage
    // iOS: Keychain, Android: Android Keystore
    throw UnimplementedError('Platform-specific implementation required');
  }
}
```

This technical specification provides a comprehensive foundation for implementing the Flutter app with optimal performance, security, and maintainability.