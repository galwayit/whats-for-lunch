# Stage 3 Flutter Maps Expert - Technical Task Assignment

## Executive Summary

**Assignment**: Restaurant Discovery with Intelligent Dietary Filtering & Maps Integration  
**Timeline**: 4 weeks (28 development days)  
**Budget Target**: <$85/month API costs for 1000 users  
**Performance Target**: <2s restaurant search, <3s map load, 90%+ cache hit rates  
**Strategic Priority**: Transform app from tracking tool to discovery platform with cutting-edge dietary intelligence

## Project Context & Foundation Analysis

### Exceptional Stage 1-2 Foundation (65% Project Completion)

**Database Foundation Ready**:
- ✅ Drift ORM with 4 core tables (Users, Meals, BudgetTrackings, Restaurants)
- ✅ Type-safe entity conversion with comprehensive CRUD operations
- ✅ Foreign key relationships and data integrity constraints
- ✅ Restaurant entity ready for Google Places integration

**Architecture Assets**:
- ✅ Clean Architecture with clear domain/data/presentation separation
- ✅ Repository pattern implementation for all data access
- ✅ Riverpod state management providers configured
- ✅ UX component library with accessibility compliance (WCAG 2.1)

**Performance Baseline**:
- ✅ 18+ passing tests covering all database operations
- ✅ Sub-30-second meal logging achieved (production deployed)
- ✅ Investment mindset budget tracking with 99x performance targets exceeded
- ✅ 95% production confidence with comprehensive testing infrastructure

## Technical Implementation Roadmap

### Phase 3.1: Enhanced User Preferences & Google Maps Foundation (Week 1)

**Priority**: Critical Infrastructure  
**Duration**: 7 days  
**Success Criteria**: Map loads <3s, comprehensive dietary preference capture <3 minutes

#### Key Deliverable 1: Enhanced User Preferences System

**Task 1.1: Expand UserPreferences Entity**
```dart
// Target: /lib/domain/entities/user_preferences.dart
class EnhancedUserPreferences extends UserPreferences {
  // Expanded dietary restrictions (20+ categories)
  final List<DietaryRestriction> dietaryRestrictions;
  final List<FoodAllergy> allergies;
  final List<String> cuisinePreferences;
  final List<String> dislikedIngredients;
  
  // Contextual preferences
  final DiningStyle preferredDiningStyle;
  final List<String> moodBasedPreferences;
  final PricePreference pricePreference;
  final DistancePreference distancePreference;
  
  // Smart learning data
  final Map<String, double> cuisineAffinityScores;
  final Map<String, DateTime> lastVisitedRestaurants;
  final List<String> favoriteRestaurantTypes;
  final int dietaryStrictnessLevel; // 1-5 scale
  
  // Accessibility preferences
  final bool requiresAccessibility;
  final bool prefersFamilyFriendly;
  final bool avoidsChains;
  
  // Time-based preferences
  final Map<MealTime, List<String>> timeBasedCuisinePrefs;
  final Map<DayOfWeek, DietaryProfile> weeklyPatterns;
}

enum DietaryRestriction {
  vegetarian, vegan, pescatarian, flexitarian,
  glutenFree, dairyFree, nutFree, soyFree, eggFree,
  keto, paleo, lowCarb, lowFodmap, wholesome,
  halal, kosher, rawFood, lowSodium, diabeticFriendly
}

enum FoodAllergy {
  peanuts, treeNuts, shellfish, fish, eggs, dairy, 
  soy, wheat, sesame, sulfites, mustard, celery
}
```

**Task 1.2: Database Schema Migration**
```sql
-- Add to existing database migration
ALTER TABLE users ADD COLUMN enhanced_preferences TEXT;

CREATE TABLE user_dietary_restrictions (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  restriction_type TEXT,
  strictness_level INTEGER,
  verified_date DATETIME,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE user_food_allergies (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  allergen_type TEXT,
  severity_level INTEGER,
  verified_date DATETIME,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE user_preference_learning (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  preference_type TEXT,
  preference_value TEXT,
  confidence_score REAL,
  last_updated DATETIME,
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

**Task 1.3: Preference Learning Engine**
```dart
// Target: /lib/data/services/preference_learning_service.dart
class PreferenceLearningEngine {
  static Future<void> updatePreferencesFromMealHistory(
    int userId,
    List<Meal> recentMeals,
  ) async {
    // Analyze restaurant selection patterns
    final restaurantPatterns = _analyzeRestaurantPatterns(recentMeals);
    
    // Extract cuisine preference signals
    final cuisineSignals = _extractCuisinePreferences(recentMeals);
    
    // Identify price point comfort zone
    final pricePatterns = _analyzePricePatterns(recentMeals);
    
    // Update user preferences with learned data
    await _updateLearnedPreferences(userId, {
      'cuisineAffinityScores': cuisineSignals,
      'priceComfortZone': pricePatterns,
      'restaurantTypePreferences': restaurantPatterns,
    });
  }
  
  // Implementation methods for pattern analysis
  static Map<String, double> _analyzeRestaurantPatterns(List<Meal> meals) {
    // Analyze frequency of restaurant types, dining times, etc.
    // Return confidence scores for different restaurant patterns
  }
  
  static Map<String, double> _extractCuisinePreferences(List<Meal> meals) {
    // Build cuisine affinity scores from meal history
    // Weight recent meals more heavily than older ones
  }
}
```

#### Key Deliverable 2: Google Maps Flutter SDK Integration

**Task 1.4: Dependencies Setup**
```yaml
# Add to pubspec.yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0  # Re-enable for location services
  permission_handler: ^11.1.0  # Already present
  google_polyline_algorithm: ^3.1.0
```

**Task 1.5: Location Services Architecture**
```dart
// Target: /lib/data/services/location_service.dart
class LocationService {
  // Progressive permission requests
  static Future<LocationPermission> requestPermission() async {
    // Request "when in use" first
    var permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Handle denied permissions gracefully
      throw LocationPermissionException('Location permission permanently denied');
    }
    
    return permission;
  }
  
  // Battery-optimized location tracking
  static Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int distanceFilter = 50, // Update only when user moves 50m
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
  
  // Get single location with fallback
  static Future<Position?> getCurrentLocation() async {
    try {
      await requestPermission();
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.balanced,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      // Return cached location or default
      return await _getFallbackLocation();
    }
  }
}
```

**Task 1.6: Basic Map Display Implementation**
```dart
// Target: /lib/presentation/pages/discover_page.dart (enhance existing)
class DiscoverPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocation = ref.watch(userLocationProvider);
    final nearbyRestaurants = ref.watch(nearbyRestaurantsProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // Search and filter bar
          RestaurantSearchBar(),
          
          // Main map view
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                ref.read(mapControllerProvider.notifier).setController(controller);
              },
              initialCameraPosition: CameraPosition(
                target: userLocation.when(
                  data: (pos) => LatLng(pos.latitude, pos.longitude),
                  loading: () => LatLng(-37.8136, 144.9631), // Melbourne default
                  error: (_, __) => LatLng(-37.8136, 144.9631),
                ),
                zoom: 15.0,
              ),
              markers: nearbyRestaurants.when(
                data: (restaurants) => _buildRestaurantMarkers(restaurants),
                loading: () => {},
                error: (_, __) => {},
              ),
              onCameraMove: (CameraPosition position) {
                // Update search area when map moves
                ref.read(searchAreaProvider.notifier).updateCenter(position.target);
              },
            ),
          ),
          
          // Bottom sheet for restaurant details
          RestaurantDetailBottomSheet(),
        ],
      ),
    );
  }
  
  Set<Marker> _buildRestaurantMarkers(List<Restaurant> restaurants) {
    return restaurants.map((restaurant) {
      return Marker(
        markerId: MarkerId(restaurant.placeId),
        position: LatLng(restaurant.latitude!, restaurant.longitude!),
        icon: _getRestaurantIcon(restaurant),
        onTap: () {
          // Show restaurant details
          ref.read(selectedRestaurantProvider.notifier).select(restaurant);
        },
        infoWindow: InfoWindow(
          title: restaurant.name,
          snippet: '${restaurant.cuisineType} • ${'$' * (restaurant.priceLevel ?? 1)}',
        ),
      );
    }).toSet();
  }
}
```

#### Key Deliverable 3: Enhanced Restaurant Data Model

**Task 1.7: Expand Restaurant Entity**
```dart
// Target: /lib/domain/entities/restaurant.dart (enhance existing)
class EnhancedRestaurant extends Restaurant {
  // Existing fields from Stage 1 foundation
  final String placeId;
  final String name;
  final String location;
  final int? priceLevel;
  final double? rating;
  final String? cuisineType;
  final DateTime cachedAt;
  
  // New fields for Stage 3
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final List<String>? openingHours;
  final String? photoReference;
  final bool isOpen;
  final int? distanceMeters;
  final Map<String, dynamic>? metadata;
  
  // Dietary compatibility data
  final Map<DietaryRestriction, DietaryCompatibility> dietaryOptions;
  final Map<FoodAllergy, AllergySafety> allergyInformation;
  final List<String> verifiedDietaryTags;
  final double dietaryAccuracyScore;
  
  // Enhanced filtering attributes
  final RestaurantAmbience ambience;
  final List<MealTime> bestMealTimes;
  final bool hasKidsMenu;
  final bool isAccessible;
  final bool acceptsReservations;
  final bool hasParking;
  
  // Smart recommendation data
  final Map<String, double> moodCompatibilityScores;
  final List<String> popularDietaryDishes;
  final double valueForMoneyScore;
  final int averageWaitTime;
  
  // Community features
  final List<DietaryReview> dietaryReviews;
  final Map<DietaryRestriction, int> userVerificationCount;
  final DateTime lastDietaryInfoUpdate;
}

enum DietaryCompatibility {
  fullMenu,      // Entire menu accommodates restriction
  manyOptions,   // 50%+ of menu items work
  someOptions,   // 20-50% of menu items work
  fewOptions,    // <20% but viable options exist
  limitedOptions, // 1-2 safe options
  notSuitable    // No safe options
}

enum AllergySafety {
  allergenFree,     // No trace of allergen in facility
  dedicatedPrep,    // Separate prep areas for allergen-free items
  crossContamMgmt,  // Good cross-contamination procedures
  limitedSafety,    // Some options but cross-contamination risk
  notSafe          // High risk of cross-contamination
}
```

**Task 1.8: Database Migration for Enhanced Restaurant Data**
```sql
-- Enhance existing restaurants table
ALTER TABLE restaurants ADD COLUMN latitude REAL;
ALTER TABLE restaurants ADD COLUMN longitude REAL;
ALTER TABLE restaurants ADD COLUMN phone_number TEXT;
ALTER TABLE restaurants ADD COLUMN opening_hours TEXT;
ALTER TABLE restaurants ADD COLUMN photo_reference TEXT;
ALTER TABLE restaurants ADD COLUMN is_open BOOLEAN DEFAULT 0;
ALTER TABLE restaurants ADD COLUMN distance_meters INTEGER;
ALTER TABLE restaurants ADD COLUMN metadata TEXT;

-- New tables for dietary information
CREATE TABLE restaurant_dietary_options (
  id INTEGER PRIMARY KEY,
  restaurant_place_id TEXT,
  dietary_restriction TEXT,
  compatibility_level TEXT,
  verification_count INTEGER DEFAULT 0,
  last_verified DATETIME,
  FOREIGN KEY (restaurant_place_id) REFERENCES restaurants (place_id)
);

CREATE TABLE restaurant_allergy_safety (
  id INTEGER PRIMARY KEY,
  restaurant_place_id TEXT,
  allergen_type TEXT,
  safety_level TEXT,
  verification_count INTEGER DEFAULT 0,
  last_verified DATETIME,
  FOREIGN KEY (restaurant_place_id) REFERENCES restaurants (place_id)
);

CREATE TABLE search_cache (
  id INTEGER PRIMARY KEY,
  user_location TEXT,
  radius_meters INTEGER,
  cuisine_filter TEXT,
  price_filter INTEGER,
  search_results TEXT,
  cached_at DATETIME,
  expires_at DATETIME
);
```

### Phase 3.2: Restaurant Search with Intelligent Dietary Filtering (Week 2)

**Priority**: Core User Value  
**Duration**: 7 days  
**Success Criteria**: Search results <2s, filter usage >80%, dietary accuracy >90%

#### Key Deliverable 4: Google Places API Integration

**Task 2.1: Places API Service Implementation**
```dart
// Target: /lib/data/services/google_places_service.dart
class GooglePlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // Cost-optimized nearby search
  static Future<List<Restaurant>> searchNearbyRestaurants({
    required Position userLocation,
    required int radiusMeters,
    String? cuisineType,
    int? priceLevel,
    bool useCache = true,
  }) async {
    
    // Check cache first for cost optimization
    if (useCache) {
      final cachedResults = await _checkSearchCache(
        userLocation, 
        radiusMeters, 
        cuisineType, 
        priceLevel,
      );
      if (cachedResults != null) return cachedResults;
    }
    
    // API request with field masking for cost control
    final response = await dio.get(
      '$_baseUrl/nearbysearch/json',
      queryParameters: {
        'location': '${userLocation.latitude},${userLocation.longitude}',
        'radius': radiusMeters,
        'type': 'restaurant',
        'key': _apiKey,
        'fields': 'place_id,name,geometry,price_level,rating,types,opening_hours,photos',
        if (cuisineType != null) 'keyword': cuisineType,
        if (priceLevel != null) 'minprice': priceLevel,
      },
    );
    
    final restaurants = _parseRestaurantsFromResponse(response.data);
    
    // Cache results for 24 hours
    await _cacheSearchResults(
      userLocation, 
      radiusMeters, 
      cuisineType, 
      priceLevel, 
      restaurants,
    );
    
    // Track API usage for cost monitoring
    APIUsageTracker.incrementUsage();
    
    return restaurants;
  }
  
  // Get detailed restaurant information
  static Future<EnhancedRestaurant> getRestaurantDetails(String placeId) async {
    // Check cache first
    final cached = await restaurantRepository.getByPlaceId(placeId);
    if (cached != null && _isCacheValid(cached)) {
      return cached;
    }
    
    // API request with optimized field selection
    final response = await dio.get(
      '$_baseUrl/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields': 'name,formatted_address,geometry,price_level,rating,opening_hours,formatted_phone_number,photos,types',
        'key': _apiKey,
      },
    );
    
    final restaurant = _parseRestaurantDetails(response.data);
    
    // Update cache
    await restaurantRepository.update(restaurant);
    APIUsageTracker.incrementUsage();
    
    return restaurant;
  }
}
```

**Task 2.2: API Cost Optimization System**
```dart
// Target: /lib/data/services/api_usage_tracker.dart
class APIUsageTracker {
  static int dailyRequestCount = 0;
  static const int dailyLimit = 1000; // Budget target: ~$49/month
  static const int warningThreshold = 800; // 80% of budget
  
  static bool canMakeRequest() {
    return dailyRequestCount < dailyLimit;
  }
  
  static void incrementUsage() {
    dailyRequestCount++;
    
    // Log to analytics for monitoring
    AnalyticsService.trackAPIUsage(dailyRequestCount, dailyLimit);
    
    // Warning notifications
    if (dailyRequestCount >= warningThreshold) {
      _notifyApproachingLimit();
    }
    
    // Auto-throttle if approaching limit
    if (dailyRequestCount >= dailyLimit) {
      _enableCacheOnlyMode();
    }
  }
  
  static void _enableCacheOnlyMode() {
    // Switch to cached results only
    SearchCacheService.enableEmergencyMode();
    NotificationService.showBudgetLimitNotification();
  }
}

// Target: /lib/data/services/search_cache_service.dart
class SearchCacheService {
  static const Duration cacheExpiry = Duration(hours: 24);
  static bool emergencyModeEnabled = false;
  
  static Future<List<Restaurant>?> checkCache({
    required Position location,
    required int radius,
    String? cuisine,
    int? priceLevel,
  }) async {
    final cacheKey = _generateCacheKey(location, radius, cuisine, priceLevel);
    
    final cached = await database.select(database.searchCaches)
      .where((cache) => cache.userLocation.equals(cacheKey))
      .where((cache) => cache.expiresAt.isBiggerThanValue(DateTime.now()))
      .getSingleOrNull();
    
    if (cached != null) {
      final restaurantIds = json.decode(cached.searchResults) as List<String>;
      return await restaurantRepository.getByIds(restaurantIds);
    }
    
    return null;
  }
  
  static Future<void> cacheResults({
    required Position location,
    required int radius,
    String? cuisine,
    int? priceLevel,
    required List<Restaurant> restaurants,
  }) async {
    final cacheKey = _generateCacheKey(location, radius, cuisine, priceLevel);
    final restaurantIds = restaurants.map((r) => r.placeId).toList();
    
    await database.into(database.searchCaches).insert(
      SearchCachesCompanion.insert(
        userLocation: cacheKey,
        radiusMeters: radius,
        cuisineFilter: Value(cuisine),
        priceFilter: Value(priceLevel),
        searchResults: json.encode(restaurantIds),
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(cacheExpiry),
      ),
    );
  }
  
  static String _generateCacheKey(Position location, int radius, String? cuisine, int? priceLevel) {
    // Round to ~100m precision for cache efficiency
    final lat = (location.latitude * 1000).round() / 1000;
    final lng = (location.longitude * 1000).round() / 1000;
    return '$lat,$lng,$radius,${cuisine ?? "all"},${priceLevel ?? "all"}';
  }
}
```

#### Key Deliverable 5: Intelligent Dietary Filtering Engine

**Task 2.3: Multi-Criteria Filtering System**
```dart
// Target: /lib/data/services/dietary_filtering_service.dart
class DietaryFilteringEngine {
  static Future<List<EnhancedRestaurant>> filterRestaurants({
    required List<EnhancedRestaurant> restaurants,
    required EnhancedUserPreferences preferences,
    required FilterContext context,
  }) async {
    
    // Phase 1: Safety filtering (hard constraints)
    final safeRestaurants = await _applySafetyFilters(
      restaurants, 
      preferences.allergies,
      preferences.dietaryRestrictions.where((d) => d.isStrict).toList(),
    );
    
    // Phase 2: Compatibility scoring
    final scoredResults = await _calculateCompatibilityScores(
      safeRestaurants,
      preferences,
      context,
    );
    
    // Phase 3: Personalized ranking
    final rankedResults = await _applyPersonalizedRanking(
      scoredResults,
      preferences.cuisineAffinityScores,
      context,
    );
    
    // Phase 4: Contextual optimization
    final optimizedResults = await _optimizeForContext(
      rankedResults,
      context,
    );
    
    return optimizedResults.take(50).toList(); // Limit results for performance
  }
  
  static List<EnhancedRestaurant> _applySafetyFilters(
    List<EnhancedRestaurant> restaurants,
    List<FoodAllergy> allergies,
    List<DietaryRestriction> strictRestrictions,
  ) {
    return restaurants.where((restaurant) {
      // Check allergy safety
      for (final allergy in allergies) {
        final safety = restaurant.allergyInformation[allergy];
        if (safety == AllergySafety.notSafe || safety == AllergySafety.limitedSafety) {
          return false;
        }
      }
      
      // Check strict dietary restrictions
      for (final restriction in strictRestrictions) {
        final compatibility = restaurant.dietaryOptions[restriction];
        if (compatibility == DietaryCompatibility.notSuitable || 
            compatibility == DietaryCompatibility.limitedOptions) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  static Map<String, double> _calculateCompatibilityScores(
    List<EnhancedRestaurant> restaurants,
    EnhancedUserPreferences preferences,
    FilterContext context,
  ) {
    return restaurants.asMap().map((index, restaurant) {
      double score = 0.0;
      
      // Dietary compatibility (40% weight)
      score += _scoreDietaryCompatibility(restaurant, preferences) * 0.4;
      
      // Cuisine preference match (25% weight)
      score += _scoreCuisineMatch(restaurant, preferences) * 0.25;
      
      // Price preference match (15% weight)
      score += _scorePriceMatch(restaurant, preferences) * 0.15;
      
      // Distance preference (10% weight)
      score += _scoreDistanceMatch(restaurant, preferences, context) * 0.1;
      
      // Contextual factors (10% weight)
      score += _scoreContextualMatch(restaurant, context) * 0.1;
      
      return MapEntry(restaurant.placeId, score);
    });
  }
  
  static double _scoreDietaryCompatibility(
    EnhancedRestaurant restaurant, 
    EnhancedUserPreferences preferences,
  ) {
    double totalScore = 0.0;
    int restrictionCount = preferences.dietaryRestrictions.length;
    
    if (restrictionCount == 0) return 1.0;
    
    for (final restriction in preferences.dietaryRestrictions) {
      final compatibility = restaurant.dietaryOptions[restriction];
      switch (compatibility) {
        case DietaryCompatibility.fullMenu:
          totalScore += 1.0;
          break;
        case DietaryCompatibility.manyOptions:
          totalScore += 0.8;
          break;
        case DietaryCompatibility.someOptions:
          totalScore += 0.6;
          break;
        case DietaryCompatibility.fewOptions:
          totalScore += 0.4;
          break;
        case DietaryCompatibility.limitedOptions:
          totalScore += 0.2;
          break;
        case DietaryCompatibility.notSuitable:
          totalScore += 0.0;
          break;
      }
    }
    
    return totalScore / restrictionCount;
  }
}

class FilterContext {
  final DateTime currentTime;
  final Position? userLocation;
  final MealTime mealTime;
  final String? mood; // "quick", "relaxed", "celebratory", "healthy"
  final int? groupSize;
  final bool isSpecialOccasion;
  final double? budgetConstraint;
  final int? timeConstraint; // minutes available
  
  factory FilterContext.current() {
    final now = DateTime.now();
    return FilterContext(
      currentTime: now,
      userLocation: null, // Will be filled by location service
      mealTime: MealTimeHelper.fromDateTime(now),
      mood: null,
      groupSize: 1,
      isSpecialOccasion: false,
      budgetConstraint: null,
      timeConstraint: null,
    );
  }
}
```

#### Key Deliverable 6: Progressive Filter Interface

**Task 2.4: Filter UI Components**
```dart
// Target: /lib/presentation/widgets/dietary_filter_widget.dart
class DietaryFilterWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<DietaryFilterWidget> createState() => _DietaryFilterWidgetState();
}

class _DietaryFilterWidgetState extends ConsumerState<DietaryFilterWidget> {
  List<DietaryPreset> selectedPresets = [];
  List<DietaryRestriction> selectedRestrictions = [];
  List<FoodAllergy> selectedAllergies = [];
  bool showAdvanced = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userPrefs = ref.watch(userPreferencesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Preset Filters (Top Priority)
        _buildQuickPresets(),
        
        SizedBox(height: 16),
        
        // Primary Dietary Restrictions
        _buildPrimaryDietarySection(),
        
        SizedBox(height: 16),
        
        // Allergy Safety Section
        _buildAllergySafetySection(),
        
        // Advanced Preferences (Collapsible)
        if (showAdvanced) ...[
          SizedBox(height: 16),
          _buildAdvancedPreferences(),
        ],
        
        // Show/Hide Advanced Toggle
        TextButton.icon(
          onPressed: () => setState(() => showAdvanced = !showAdvanced),
          icon: Icon(showAdvanced ? Icons.expand_less : Icons.expand_more),
          label: Text(showAdvanced ? 'Hide Advanced' : 'Show Advanced'),
        ),
        
        SizedBox(height: 24),
        
        // Apply Filters Button with Result Count
        _buildApplyFiltersButton(),
      ],
    );
  }
  
  Widget _buildQuickPresets() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: DietaryPreset.values.length,
        itemBuilder: (context, index) {
          final preset = DietaryPreset.values[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(preset.displayName),
              avatar: Icon(preset.icon, size: 16),
              selected: selectedPresets.contains(preset),
              onSelected: (selected) => _togglePreset(preset),
              backgroundColor: preset.color.withOpacity(0.1),
              selectedColor: preset.color.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPrimaryDietarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Preferences',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DietaryRestriction.primary.map((restriction) {
            return FilterChip(
              label: Text(restriction.displayName),
              selected: selectedRestrictions.contains(restriction),
              onSelected: (selected) => _toggleRestriction(restriction),
              avatar: Icon(restriction.icon, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildAllergySafetySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Allergy Safety',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FoodAllergy.common.map((allergy) {
            return FilterChip(
              label: Text(allergy.displayName),
              selected: selectedAllergies.contains(allergy),
              onSelected: (selected) => _toggleAllergy(allergy),
              backgroundColor: Colors.red.withOpacity(0.1),
              selectedColor: Colors.red.withOpacity(0.3),
              avatar: Icon(Icons.warning, size: 16, color: Colors.red),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildApplyFiltersButton() {
    final resultCount = ref.watch(filteredRestaurantCountProvider);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _applyFilters,
        icon: Icon(Icons.search),
        label: resultCount.when(
          data: (count) => Text('Show $count Restaurants'),
          loading: () => Text('Searching...'),
          error: (_, __) => Text('Apply Filters'),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
  
  void _togglePreset(DietaryPreset preset) {
    setState(() {
      if (selectedPresets.contains(preset)) {
        selectedPresets.remove(preset);
        // Remove associated restrictions
        selectedRestrictions.removeWhere((r) => preset.restrictions.contains(r));
        selectedAllergies.removeWhere((a) => preset.allergies.contains(a));
      } else {
        selectedPresets.add(preset);
        // Add associated restrictions
        selectedRestrictions.addAll(preset.restrictions);
        selectedAllergies.addAll(preset.allergies);
      }
    });
    
    // Update filter in real-time
    _updateFilters();
  }
  
  void _updateFilters() {
    final filterSelection = DietaryFilterSelection(
      dietaryRestrictions: selectedRestrictions,
      allergies: selectedAllergies,
      appliedPresets: selectedPresets,
    );
    
    ref.read(dietaryFilterSelectionProvider.notifier).update(filterSelection);
  }
}

enum DietaryPreset {
  veganFriendly("Vegan", Icons.local_florist, Colors.green),
  glutenFree("Gluten-Free", Icons.grain, Colors.orange),
  vegetarianPlus("Vegetarian+", Icons.eco, Colors.lightGreen),
  allergyConscious("Allergy Safe", Icons.shield, Colors.red),
  ketoLowCarb("Keto/Low-Carb", Icons.fitness_center, Colors.purple),
  healthyEating("Healthy Options", Icons.favorite, Colors.pink),
  familyFriendly("Family Style", Icons.family_restroom, Colors.blue),
  quickBite("Quick & Easy", Icons.fast_forward, Colors.amber);
  
  const DietaryPreset(this.displayName, this.icon, this.color);
  
  final String displayName;
  final IconData icon;
  final Color color;
  
  List<DietaryRestriction> get restrictions {
    switch (this) {
      case DietaryPreset.veganFriendly:
        return [DietaryRestriction.vegan];
      case DietaryPreset.glutenFree:
        return [DietaryRestriction.glutenFree];
      case DietaryPreset.vegetarianPlus:
        return [DietaryRestriction.vegetarian];
      case DietaryPreset.ketoLowCarb:
        return [DietaryRestriction.keto, DietaryRestriction.lowCarb];
      case DietaryPreset.healthyEating:
        return [DietaryRestriction.wholesome];
      default:
        return [];
    }
  }
  
  List<FoodAllergy> get allergies {
    switch (this) {
      case DietaryPreset.allergyConscious:
        return [FoodAllergy.peanuts, FoodAllergy.treeNuts, FoodAllergy.shellfish];
      default:
        return [];
    }
  }
}
```

### Phase 3.3: Context-Aware Discovery with Budget Integration (Week 3)

**Priority**: High User Value  
**Duration**: 7 days  
**Success Criteria**: Investment mindset adoption >70%, recommendation relevance >80%

#### Key Deliverable 7: Investment-Mindset Restaurant Recommendations

**Task 3.1: Budget-Integrated Discovery Experience**
```dart
// Target: /lib/data/services/investment_mindset_service.dart
class InvestmentMindsetRecommendations {
  static List<RestaurantRecommendation> enhanceWithInvestmentContext(
    List<RestaurantRecommendation> recommendations,
    BudgetTrackingData budgetData,
    EnhancedUserPreferences preferences,
  ) {
    
    return recommendations.map((recommendation) {
      final budgetImpact = _calculateBudgetImpact(
        restaurant: recommendation.restaurant,
        currentBudget: budgetData,
        userPrefs: preferences,
      );
      
      final investmentMessage = _generateInvestmentMessage(
        budgetImpact: budgetImpact,
        restaurantType: recommendation.restaurant.ambience,
        userGoals: preferences.investmentGoals,
      );
      
      return recommendation.copyWith(
        budgetImpact: budgetImpact,
        investmentRationale: investmentMessage,
        valueProposition: _calculateValueProposition(
          recommendation.restaurant,
          budgetImpact,
        ),
      );
    }).toList();
  }
  
  static String _generateInvestmentMessage(
    BudgetImpact budgetImpact,
    RestaurantAmbience ambience,
    List<String> userGoals,
  ) {
    if (budgetImpact.isWithinBudget) {
      switch (ambience) {
        case RestaurantAmbience.healthy:
          return "Smart investment in your health and wellness goals";
        case RestaurantAmbience.social:
          return "Valuable investment in relationships and social connections";
        case RestaurantAmbience.quick:
          return "Efficient investment in convenience and time savings";
        case RestaurantAmbience.experiential:
          return "Meaningful investment in memorable dining experiences";
        default:
          return "Smart investment in your dining satisfaction";
      }
    } else if (budgetImpact.overBudgetBy < 5.0) {
      return "Small stretch for a valuable ${_getExperienceType(ambience)} experience";
    } else {
      return "Consider for special occasions - save up for this experience";
    }
  }
  
  static BudgetImpact _calculateBudgetImpact(
    EnhancedRestaurant restaurant,
    BudgetTrackingData budgetData,
    EnhancedUserPreferences userPrefs,
  ) {
    final estimatedCost = _estimateRestaurantCost(restaurant, userPrefs);
    final remainingBudget = budgetData.weeklyBudget - budgetData.currentWeekSpent;
    final dailyAllowance = remainingBudget / budgetData.daysRemainingInWeek;
    
    return BudgetImpact(
      estimatedCost: estimatedCost,
      remainingBudget: remainingBudget,
      dailyAllowance: dailyAllowance,
      isWithinBudget: estimatedCost <= dailyAllowance,
      overBudgetBy: estimatedCost > dailyAllowance ? estimatedCost - dailyAllowance : 0,
      investmentValue: _calculateInvestmentValue(restaurant, estimatedCost),
    );
  }
}
```

**Task 3.2: Context-Aware Recommendation Engine**
```dart
// Target: /lib/data/services/contextual_recommendation_service.dart
class ContextualRecommendationEngine {
  static Future<List<RestaurantRecommendation>> generateRecommendations({
    required EnhancedUserPreferences preferences,
    required FilterContext context,
    required List<EnhancedRestaurant> availableRestaurants,
  }) async {
    
    // Analyze current context for recommendation strategy
    final strategy = _determineRecommendationStrategy(context);
    
    switch (strategy) {
      case RecommendationStrategy.quickMeal:
        return _generateQuickMealRecommendations(
          restaurants: availableRestaurants,
          preferences: preferences,
          timeConstraint: context.timeConstraint!,
        );
        
      case RecommendationStrategy.healthyFocus:
        return _generateHealthyRecommendations(
          restaurants: availableRestaurants,
          preferences: preferences,
          dietaryGoals: preferences.currentDietaryGoals,
        );
        
      case RecommendationStrategy.budgetConscious:
        return _generateBudgetOptimizedRecommendations(
          restaurants: availableRestaurants,
          preferences: preferences,
          budgetConstraint: context.budgetConstraint!,
        );
        
      case RecommendationStrategy.exploration:
        return _generateExploratoryRecommendations(
          restaurants: availableRestaurants,
          preferences: preferences,
          explorationRadius: preferences.explorationRadius,
        );
    }
  }
  
  static RecommendationStrategy _determineRecommendationStrategy(
    FilterContext context,
  ) {
    // Time pressure indicates quick meal need
    if (context.timeConstraint != null && context.timeConstraint! < 30) {
      return RecommendationStrategy.quickMeal;
    }
    
    // Health-focused times (morning, post-workout)
    if (context.mood == "healthy" || context.mealTime == MealTime.breakfast) {
      return RecommendationStrategy.healthyFocus;
    }
    
    // Budget constraints
    if (context.budgetConstraint != null) {
      return RecommendationStrategy.budgetConscious;
    }
    
    // Default to exploration for discovery
    return RecommendationStrategy.exploration;
  }
  
  static Future<List<RestaurantRecommendation>> _generateQuickMealRecommendations({
    required List<EnhancedRestaurant> restaurants,
    required EnhancedUserPreferences preferences,
    required int timeConstraint,
  }) async {
    
    // Filter for quick service restaurants
    final quickRestaurants = restaurants.where((r) => 
      r.averageWaitTime <= timeConstraint &&
      r.ambience == RestaurantAmbience.quick
    ).toList();
    
    // Sort by dietary compatibility and distance
    quickRestaurants.sort((a, b) {
      final aScore = _calculateQuickMealScore(a, preferences);
      final bScore = _calculateQuickMealScore(b, preferences);
      return bScore.compareTo(aScore);
    });
    
    return quickRestaurants.take(5).map((restaurant) => 
      RestaurantRecommendation(
        restaurant: restaurant,
        reasons: [
          "Quick service (${restaurant.averageWaitTime} min wait)",
          "Matches your dietary preferences",
          "Close to your location",
        ],
        confidenceScore: _calculateQuickMealScore(restaurant, preferences),
        recommendationType: RecommendationType.quickMeal,
      )
    ).toList();
  }
}
```

#### Key Deliverable 8: Restaurant Detail Integration

**Task 3.3: Enhanced Restaurant Detail Bottom Sheet**
```dart
// Target: /lib/presentation/widgets/restaurant_detail_bottom_sheet.dart
class RestaurantDetailBottomSheet extends ConsumerWidget {
  final EnhancedRestaurant restaurant;
  
  const RestaurantDetailBottomSheet({
    Key? key,
    required this.restaurant,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(userPreferencesProvider);
    final budgetData = ref.watch(currentBudgetProvider);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with basic info
                      _buildRestaurantHeader(),
                      
                      SizedBox(height: 16),
                      
                      // Dietary compatibility badges
                      _buildDietaryCompatibilitySection(userPrefs),
                      
                      SizedBox(height: 16),
                      
                      // Budget impact section
                      _buildBudgetImpactSection(budgetData),
                      
                      SizedBox(height: 16),
                      
                      // Restaurant details
                      _buildRestaurantDetails(),
                      
                      SizedBox(height: 24),
                      
                      // Action buttons
                      _buildActionButtons(context, ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRestaurantHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Restaurant photo
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: restaurant.photoReference != null
            ? CachedNetworkImage(
                imageUrl: _buildPhotoUrl(restaurant.photoReference!),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: Icon(Icons.restaurant),
                ),
              )
            : Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: Icon(Icons.restaurant, size: 40),
              ),
        ),
        
        SizedBox(width: 16),
        
        // Restaurant info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.local_dining, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    restaurant.cuisineType ?? 'Restaurant',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              Row(
                children: [
                  // Rating
                  if (restaurant.rating != null) ...[
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 2),
                    Text(
                      restaurant.rating!.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(width: 8),
                  ],
                  
                  // Price level
                  Text(
                    '$' * (restaurant.priceLevel ?? 1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // Distance
                  if (restaurant.distanceMeters != null) ...[
                    Icon(Icons.directions_walk, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 2),
                    Text(
                      _formatDistance(restaurant.distanceMeters!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: 4),
              
              // Open status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: restaurant.isOpen ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    restaurant.isOpen ? 'Open now' : 'Closed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: restaurant.isOpen ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDietaryCompatibilitySection(EnhancedUserPreferences userPrefs) {
    if (userPrefs.dietaryRestrictions.isEmpty && userPrefs.allergies.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Compatibility',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Dietary restriction badges
            ...userPrefs.dietaryRestrictions.map((restriction) {
              final compatibility = restaurant.dietaryOptions[restriction];
              return DietaryBadge(
                restriction: restriction,
                compatibility: compatibility,
                verificationCount: restaurant.userVerificationCount[restriction] ?? 0,
              );
            }),
            
            // Allergy safety badges
            ...userPrefs.allergies.map((allergy) {
              final safety = restaurant.allergyInformation[allergy];
              return AllergySafetyBadge(
                allergy: allergy,
                safety: safety,
                verificationCount: restaurant.userVerificationCount[allergy] ?? 0,
              );
            }),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBudgetImpactSection(BudgetTrackingData? budgetData) {
    if (budgetData == null) return SizedBox.shrink();
    
    final estimatedCost = _estimateRestaurantCost(restaurant);
    final budgetImpact = BudgetCalculator.calculateImpact(
      mealCost: estimatedCost,
      userBudget: budgetData,
    );
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: budgetImpact.isWithinBudget ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: budgetImpact.isWithinBudget ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: budgetImpact.isWithinBudget ? Colors.green[700] : Colors.orange[700],
              ),
              SizedBox(width: 8),
              Text(
                'Investment Impact',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: budgetImpact.isWithinBudget ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Estimated cost: \$${estimatedCost.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          Text(
            budgetImpact.isWithinBudget 
              ? 'Smart investment within your daily allowance'
              : 'Consider for special occasions - \$${budgetImpact.overBudgetBy.toStringAsFixed(2)} over daily budget',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Primary action: Log meal here
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _logMealHere(context, ref),
            icon: Icon(Icons.restaurant_menu),
            label: Text('Log Meal Here'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _getDirections(),
                icon: Icon(Icons.directions),
                label: Text('Directions'),
              ),
            ),
            
            SizedBox(width: 12),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: restaurant.phoneNumber != null ? () => _callRestaurant() : null,
                icon: Icon(Icons.phone),
                label: Text('Call'),
              ),
            ),
            
            SizedBox(width: 12),
            
            OutlinedButton(
              onPressed: () => _saveForLater(ref),
              child: Icon(Icons.bookmark_border),
            ),
          ],
        ),
      ],
    );
  }
  
  void _logMealHere(BuildContext context, WidgetRef ref) {
    // Pre-populate meal form with restaurant data
    final mealDraft = MealDraft(
      restaurantId: restaurant.placeId,
      restaurantName: restaurant.name,
      estimatedCost: _estimateRestaurantCost(restaurant),
      mealType: MealTypeHelper.suggestFromTime(DateTime.now()),
    );
    
    // Navigate to meal logging with context
    context.push('/track/log', extra: {
      'preFilled': mealDraft,
      'source': 'discovery',
    });
  }
}
```

### Phase 3.4: Performance Optimization & Accessibility Testing (Week 4)

**Priority**: Production Readiness  
**Duration**: 7 days  
**Success Criteria**: <200ms filter performance, 100% WCAG 2.1 compliance, memory usage <30MB increase

#### Key Deliverable 9: Performance Optimization

**Task 4.1: Filtering Performance Optimization**
```dart
// Target: /lib/data/services/performance_optimizer.dart
class FilteringPerformanceOptimizer {
  static Future<void> optimizeFilteringPipeline() async {
    
    // Pre-compute common filter combinations
    await _precomputePopularFilters();
    
    // Implement intelligent caching
    await _setupMultiLayerCaching();
    
    // Optimize database queries
    await _createOptimizedIndices();
    
    // Implement background prefetching
    await _setupPredictivePrefetching();
  }
  
  static Future<void> _precomputePopularFilters() async {
    final popularCombinations = [
      [DietaryRestriction.vegetarian],
      [DietaryRestriction.vegan],
      [DietaryRestriction.glutenFree],
      [DietaryRestriction.vegetarian, DietaryRestriction.glutenFree],
      [DietaryRestriction.vegan, DietaryRestriction.glutenFree],
    ];
    
    for (final combination in popularCombinations) {
      await _cacheFilterResults(combination);
    }
  }
  
  static Future<void> _setupMultiLayerCaching() async {
    // Level 1: In-memory cache for immediate results
    await InMemoryCache.initialize(maxSize: 50); // 50 recent searches
    
    // Level 2: Database cache for persistent results
    await DatabaseCache.initialize();
    
    // Level 3: Predictive cache for anticipated searches
    await PredictiveCache.initialize();
  }
  
  static Future<void> _createOptimizedIndices() async {
    final database = GetIt.instance<AppDatabase>();
    
    // Create composite indices for common query patterns
    await database.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_restaurants_location_cuisine 
      ON restaurants(latitude, longitude, cuisine_type);
    ''');
    
    await database.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_restaurants_dietary_price 
      ON restaurants(price_level, dietary_accuracy_score);
    ''');
    
    await database.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_user_preferences_learning 
      ON user_preference_learning(user_id, preference_type, last_updated);
    ''');
  }
}

// Target: /lib/data/services/performance_monitor.dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final List<PerformanceMetric> _metrics = [];
  
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }
  
  static void endTimer(String operation) {
    final stopwatch = _timers[operation];
    if (stopwatch != null) {
      stopwatch.stop();
      _recordMetric(operation, stopwatch.elapsedMilliseconds);
      _timers.remove(operation);
    }
  }
  
  static void _recordMetric(String operation, int durationMs) {
    _metrics.add(PerformanceMetric(
      operation: operation,
      duration: Duration(milliseconds: durationMs),
      timestamp: DateTime.now(),
    ));
    
    // Alert if performance degrades
    if (durationMs > _getThreshold(operation)) {
      _sendPerformanceAlert(operation, durationMs);
    }
    
    // Keep only recent metrics
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, 500);
    }
  }
  
  static int _getThreshold(String operation) {
    switch (operation) {
      case 'filter_application':
        return 200; // 200ms threshold
      case 'map_load':
        return 3000; // 3s threshold
      case 'restaurant_search':
        return 2000; // 2s threshold
      default:
        return 1000; // 1s default
    }
  }
  
  static Future<PerformanceReport> generateReport() async {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));
    
    final recentMetrics = _metrics.where(
      (metric) => metric.timestamp.isAfter(last24Hours),
    ).toList();
    
    return PerformanceReport(
      totalOperations: recentMetrics.length,
      averageFilterTime: _calculateAverage(recentMetrics, 'filter_application'),
      averageSearchTime: _calculateAverage(recentMetrics, 'restaurant_search'),
      averageMapLoadTime: _calculateAverage(recentMetrics, 'map_load'),
      slowOperations: recentMetrics.where(
        (metric) => metric.duration.inMilliseconds > _getThreshold(metric.operation),
      ).toList(),
    );
  }
}
```

#### Key Deliverable 10: Accessibility Compliance

**Task 4.2: WCAG 2.1 Accessibility Implementation**
```dart
// Target: /lib/presentation/widgets/accessible_filter_interface.dart
class AccessibilityEnhancedFiltering extends StatelessWidget {
  final List<DietaryRestriction> restrictions;
  final Function(List<DietaryRestriction>) onChanged;
  
  const AccessibilityEnhancedFiltering({
    Key? key,
    required this.restrictions,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // High contrast toggle
        AccessibilityToggle(
          label: "High Contrast Mode",
          semanticLabel: "Toggle high contrast mode for better visibility",
          value: AccessibilityPreferences.isHighContrast,
          onChanged: AccessibilityPreferences.setHighContrast,
        ),
        
        // Font size adjustment
        Semantics(
          label: "Adjust text size for better readability",
          child: FontSizeSlider(
            value: AccessibilityPreferences.fontSize,
            onChanged: AccessibilityPreferences.setFontSize,
          ),
        ),
        
        // Voice-controlled filtering
        Semantics(
          label: "Use voice commands to set dietary filters",
          button: true,
          child: VoiceFilterButton(
            onVoiceCommand: (command) => _processVoiceFilter(command, onChanged),
          ),
        ),
        
        // Semantic filter selection
        SemanticFilterGrid(
          restrictions: restrictions,
          onSelectionChanged: onChanged,
          semanticLabels: _generateSemanticLabels(restrictions),
        ),
      ],
    );
  }
  
  static Map<DietaryRestriction, String> _generateSemanticLabels(
    List<DietaryRestriction> restrictions,
  ) {
    return {
      DietaryRestriction.vegetarian: "Vegetarian diet - excludes meat and fish. Safe for vegetarians.",
      DietaryRestriction.vegan: "Vegan diet - excludes all animal products including dairy and eggs. Suitable for vegans.",
      DietaryRestriction.glutenFree: "Gluten-free options - safe for people with celiac disease or gluten sensitivity.",
      DietaryRestriction.nutFree: "Nut allergy safe - no tree nuts or peanuts. Safe for people with nut allergies.",
      DietaryRestriction.dairyFree: "Dairy-free options - no milk, cheese, or dairy products. Safe for lactose intolerant individuals.",
      DietaryRestriction.keto: "Ketogenic diet friendly - low carbohydrate, high fat options suitable for keto diet.",
      DietaryRestriction.halal: "Halal certified - prepared according to Islamic dietary laws.",
      DietaryRestriction.kosher: "Kosher certified - prepared according to Jewish dietary laws.",
    };
  }
  
  void _processVoiceFilter(String command, Function(List<DietaryRestriction>) onChanged) {
    // Parse voice commands like "I need gluten free and vegetarian options"
    final words = command.toLowerCase().split(' ');
    final detectedRestrictions = <DietaryRestriction>[];
    
    if (words.contains('vegetarian') || words.contains('veggie')) {
      detectedRestrictions.add(DietaryRestriction.vegetarian);
    }
    if (words.contains('vegan')) {
      detectedRestrictions.add(DietaryRestriction.vegan);
    }
    if (words.contains('gluten') && words.contains('free')) {
      detectedRestrictions.add(DietaryRestriction.glutenFree);
    }
    if (words.contains('dairy') && words.contains('free')) {
      detectedRestrictions.add(DietaryRestriction.dairyFree);
    }
    if (words.contains('nut') && (words.contains('free') || words.contains('allergy'))) {
      detectedRestrictions.add(DietaryRestriction.nutFree);
    }
    
    if (detectedRestrictions.isNotEmpty) {
      onChanged(detectedRestrictions);
      
      // Provide voice feedback
      TextToSpeech.speak(
        "Applied filters: ${detectedRestrictions.map((r) => r.displayName).join(', ')}"
      );
    }
  }
}

// Target: /lib/presentation/widgets/semantic_filter_grid.dart
class SemanticFilterGrid extends StatelessWidget {
  final List<DietaryRestriction> restrictions;
  final Function(List<DietaryRestriction>) onSelectionChanged;
  final Map<DietaryRestriction, String> semanticLabels;
  
  const SemanticFilterGrid({
    Key? key,
    required this.restrictions,
    required this.onSelectionChanged,
    required this.semanticLabels,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3,
      ),
      itemCount: DietaryRestriction.values.length,
      itemBuilder: (context, index) {
        final restriction = DietaryRestriction.values[index];
        final isSelected = restrictions.contains(restriction);
        
        return Semantics(
          label: semanticLabels[restriction] ?? restriction.displayName,
          button: true,
          selected: isSelected,
          onTap: () => _toggleRestriction(restriction),
          child: FilterChip(
            label: Text(
              restriction.displayName,
              style: TextStyle(
                fontSize: AccessibilityPreferences.fontSize,
                fontWeight: AccessibilityPreferences.isHighContrast 
                  ? FontWeight.bold 
                  : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _toggleRestriction(restriction),
            backgroundColor: AccessibilityPreferences.isHighContrast 
              ? Colors.white 
              : null,
            selectedColor: AccessibilityPreferences.isHighContrast 
              ? Colors.black 
              : Theme.of(context).primaryColor.withOpacity(0.3),
            labelStyle: TextStyle(
              color: AccessibilityPreferences.isHighContrast
                ? (isSelected ? Colors.white : Colors.black)
                : null,
            ),
          ),
        );
      },
    );
  }
  
  void _toggleRestriction(DietaryRestriction restriction) {
    final newRestrictions = List<DietaryRestriction>.from(restrictions);
    
    if (newRestrictions.contains(restriction)) {
      newRestrictions.remove(restriction);
    } else {
      newRestrictions.add(restriction);
    }
    
    onSelectionChanged(newRestrictions);
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Announce change to screen readers
    Semantics.announce(
      "${restriction.displayName} ${newRestrictions.contains(restriction) ? 'selected' : 'deselected'}",
      TextDirection.ltr,
    );
  }
}
```

## Integration with Existing Stage 1-2 Foundation

### Seamless Meal Logging Integration

**Task**: Enhance existing meal logging flow with discovery context
```dart
// Target: /lib/presentation/pages/track_page.dart (enhance existing)
class DiscoveryToLoggingFlow {
  static Future<void> logMealFromRestaurant(
    EnhancedRestaurant restaurant,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Pre-populate meal form with restaurant data
    final mealDraft = MealDraft(
      restaurantId: restaurant.placeId,
      restaurantName: restaurant.name,
      estimatedCost: _estimateRestaurantCost(restaurant),
      mealType: MealTypeHelper.suggestFromTime(DateTime.now()),
    );
    
    // Get current budget for impact calculation
    final budgetData = await ref.read(budgetRepositoryProvider).getCurrentBudget();
    
    // Show budget impact preview
    final budgetImpact = BudgetCalculator.calculateImpact(
      mealCost: mealDraft.estimatedCost,
      userBudget: budgetData,
    );
    
    // Navigate to enhanced meal logging with context
    context.push('/track/log', extra: {
      'preFilled': mealDraft,
      'budgetContext': budgetImpact,
      'source': 'discovery',
      'restaurant': restaurant,
    });
  }
}
```

### Budget Integration Enhancement

**Task**: Integrate dietary discovery with investment mindset budget tracking
```dart
// Target: /lib/data/services/budget_dietary_integration.dart
class DietaryBudgetAnalytics {
  static Future<DietaryBudgetInsights> analyzeDietarySpending(
    int userId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    
    final meals = await mealRepository.getMealsByDateRange(
      userId, 
      periodStart, 
      periodEnd,
    );
    
    final dietaryMeals = meals.where((meal) => 
      meal.dietaryRestrictionsApplied?.isNotEmpty ?? false
    ).toList();
    
    final insights = DietaryBudgetInsights(
      totalDietarySpending: dietaryMeals.fold(0.0, (sum, meal) => sum + meal.cost),
      dietaryPremiumPercentage: _calculateDietaryPremium(dietaryMeals, meals),
      mostCostEffectiveDietaryChoices: _findCostEffectiveChoices(dietaryMeals),
      dietaryBudgetTrends: _analyzeDietaryTrends(dietaryMeals),
      investmentROI: _calculateDietaryInvestmentROI(dietaryMeals, userId),
    );
    
    return insights;
  }
  
  static double _calculateDietaryPremium(List<Meal> dietaryMeals, List<Meal> allMeals) {
    if (dietaryMeals.isEmpty || allMeals.isEmpty) return 0.0;
    
    final dietaryAverage = dietaryMeals.fold(0.0, (sum, meal) => sum + meal.cost) / dietaryMeals.length;
    final overallAverage = allMeals.fold(0.0, (sum, meal) => sum + meal.cost) / allMeals.length;
    
    return ((dietaryAverage - overallAverage) / overallAverage) * 100;
  }
}
```

## Success Metrics & Monitoring

### Technical Performance KPIs

**Real-time Monitoring Dashboard**:
```dart
// Target: /lib/data/services/metrics_collector.dart
class MetricsCollector {
  static Future<void> trackFilteringPerformance({
    required String operation,
    required Duration duration,
    required int resultCount,
    required List<DietaryRestriction> appliedFilters,
  }) async {
    await AnalyticsService.track('filtering_performance', {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'result_count': resultCount,
      'filter_count': appliedFilters.length,
      'filter_types': appliedFilters.map((f) => f.name).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Alert if performance degrades
    if (duration.inMilliseconds > 500) {
      await AlertService.sendPerformanceAlert({
        'operation': operation,
        'duration': duration.inMilliseconds,
        'threshold': 500,
      });
    }
  }
  
  static Future<void> trackUserEngagement({
    required String action,
    required String screen,
    Map<String, dynamic>? additionalData,
  }) async {
    await AnalyticsService.track('user_engagement', {
      'action': action,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }
}
```

### Target Performance Benchmarks

**Critical Success Criteria**:
- **Map Load Time**: <3 seconds (target: <2 seconds)
- **Restaurant Search Response**: <2 seconds (target: <1 second)
- **Filter Application**: <200ms for complex multi-criteria searches
- **Cache Hit Rate**: >90% (budget target requires >80%)
- **API Cost per User**: <$0.08/month (budget: <$0.085/month)
- **Memory Usage**: <30MB increase from Stage 2 baseline
- **Battery Impact**: <5% per 30-minute discovery session

**User Experience KPIs**:
- **Filter Usage Rate**: >85% of discovery sessions use dietary filters
- **Dietary Match Accuracy**: >90% of filtered restaurants match user's actual needs
- **Discovery to Logging Conversion**: >65% of users log meals from discovered restaurants
- **Investment Mindset Adoption**: >70% positive response to budget-integrated messaging
- **Accessibility Compliance**: 100% WCAG 2.1 AA compliance

## Risk Mitigation & Contingency Plans

### High-Priority Risk Controls

**API Cost Overruns**:
- Implement real-time usage monitoring with automatic throttling at 80% of budget
- Emergency cache-only mode activation when daily limits approached
- Alternative data sources prepared for high-usage scenarios

**Performance Degradation**:
- Multi-layered caching strategy with 90%+ hit rates
- Progressive loading and background prefetching
- Graceful degradation for older devices

**Filter Complexity Overwhelm**:
- Progressive disclosure with smart defaults based on user patterns
- Quick preset filters for common dietary combinations
- AI-suggested filter combinations based on meal logging history

## Testing & Quality Assurance Strategy

### Comprehensive Testing Plan

**Performance Testing**:
```dart
// Target: /test/performance/filtering_performance_test.dart
void main() {
  group('Filtering Performance Tests', () {
    testWidgets('Filter application completes within 200ms for 100+ restaurants', (tester) async {
      final restaurants = generateTestRestaurants(count: 150);
      final preferences = generateTestPreferences();
      
      final stopwatch = Stopwatch()..start();
      
      final results = await DietaryFilteringEngine.filterRestaurants(
        restaurants: restaurants,
        preferences: preferences,
        context: FilterContext.current(),
      );
      
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(results.length, greaterThan(0));
    });
    
    testWidgets('Cache hit rate exceeds 90% for repeated searches', (tester) async {
      // Test caching effectiveness
    });
    
    testWidgets('Memory usage stays within 30MB increase', (tester) async {
      // Test memory consumption
    });
  });
}
```

**Accessibility Testing**:
```dart
// Target: /test/accessibility/filter_accessibility_test.dart
void main() {
  group('Filter Accessibility Tests', () {
    testWidgets('All filter elements have proper semantic labels', (tester) async {
      await tester.pumpWidget(TestApp(
        child: DietaryFilterWidget(),
      ));
      
      // Verify semantic labels for screen readers
      final semanticsHandle = tester.binding.pipelineOwner.semanticsOwner!;
      expect(semanticsHandle.rootSemanticsNode, hasSemanticLabel);
    });
    
    testWidgets('Voice commands correctly apply filters', (tester) async {
      // Test voice control functionality
    });
    
    testWidgets('High contrast mode works correctly', (tester) async {
      // Test accessibility visual modes
    });
  });
}
```

## Timeline & Deliverable Schedule

### Week 1: Enhanced Preferences & Maps Foundation
- **Days 1-2**: Enhanced UserPreferences entity and database migration
- **Days 3-4**: Google Maps SDK integration and location services
- **Days 5-7**: Basic map display and restaurant marker system

### Week 2: Intelligent Filtering Engine
- **Days 8-9**: Google Places API integration with cost optimization
- **Days 10-11**: Multi-criteria dietary filtering system
- **Days 12-14**: Progressive filter UI and real-time application

### Week 3: Context-Aware Discovery
- **Days 15-16**: Investment-mindset recommendation engine
- **Days 17-18**: Restaurant detail integration with meal logging
- **Days 19-21**: Context-aware discovery and learning system

### Week 4: Performance & Accessibility
- **Days 22-23**: Performance optimization and caching improvements
- **Days 24-25**: Accessibility compliance and testing
- **Days 26-28**: Integration testing and production readiness

## Next Steps & Coordination Requirements

### Immediate Actions Required

1. **Google Cloud Setup**: Configure Google Places API with billing alerts at $40 threshold
2. **Database Migration**: Apply enhanced schema changes to development environment
3. **Dependency Updates**: Add Google Maps and related packages to pubspec.yaml
4. **Testing Environment**: Prepare device testing suite for performance benchmarking

### Coordination with Mobile UX Advisor

**UX Validation Needed**:
- Progressive filter interface design review
- Investment mindset messaging validation  
- Accessibility compliance verification
- Context-aware recommendation UI/UX

**User Testing Plan**:
- Filter usability testing with 10+ dietary restriction combinations
- Discovery flow validation from filter to meal logging
- Investment mindset messaging resonance testing
- Accessibility testing with assistive technology users

This comprehensive task assignment leverages the exceptional Stage 1-2 foundation to implement cutting-edge restaurant discovery with intelligent dietary filtering. The focus on performance optimization, accessibility compliance, and seamless integration with existing meal logging and budget tracking ensures that Stage 3 will significantly enhance user value while maintaining the app's investment mindset philosophy.