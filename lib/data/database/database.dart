import 'dart:math' as math;
import 'package:drift/drift.dart';

// Import platform-specific database implementations
import 'database_connection.dart';

part 'database.g.dart';

// Define tables
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get preferences => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get restaurantId => text().nullable()();
  TextColumn get mealType => text()();
  RealColumn get cost => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoIds => text().withDefault(const Constant('[]'))(); // JSON array of photo IDs
}

class BudgetTrackings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
}

class Restaurants extends Table {
  // Basic information
  TextColumn get placeId => text()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get website => text().nullable()();
  
  // Location data
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get distanceFromUser => real().nullable()();
  
  // Rating and pricing
  RealColumn get rating => real().nullable()();
  IntColumn get reviewCount => integer().nullable()();
  IntColumn get priceLevel => integer().nullable()();
  TextColumn get priceRanges => text().withDefault(const Constant('[]'))(); // JSON array
  
  // Cuisine and dietary information
  TextColumn get cuisineType => text().nullable()();
  TextColumn get cuisineTypes => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get supportedDietaryRestrictions => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get allergenInfo => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get dietaryCompatibilityScores => text().withDefault(const Constant('{}'))(); // JSON object
  BoolColumn get hasVerifiedDietaryInfo => boolean().withDefault(const Constant(false))();
  IntColumn get communityVerificationCount => integer().withDefault(const Constant(0))();
  
  // Operational information
  TextColumn get openingHours => text().withDefault(const Constant('[]'))(); // JSON array
  BoolColumn get isOpenNow => boolean().withDefault(const Constant(false))();
  TextColumn get currentWaitTime => text().nullable()();
  TextColumn get features => text().withDefault(const Constant('[]'))(); // JSON array
  
  // Investment mindset data
  RealColumn get averageMealCost => real().nullable()();
  RealColumn get valueScore => real().nullable()();
  TextColumn get mealTypeAverageCosts => text().withDefault(const Constant('{}'))(); // JSON object
  
  // Caching and metadata
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastVerified => dateTime().nullable()();
  TextColumn get photoReference => text().nullable()();
  TextColumn get photoReferences => text().withDefault(const Constant('[]'))(); // JSON array

  @override
  Set<Column> get primaryKey => {placeId};
}

// Add new tables for enhanced caching and performance
class RestaurantCache extends Table {
  TextColumn get placeId => text()();
  TextColumn get searchQuery => text()();
  RealColumn get userLatitude => real()();
  RealColumn get userLongitude => real()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {placeId, searchQuery};
}

class DietaryCompatibility extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get placeId => text().references(Restaurants, #placeId)();
  TextColumn get dietaryRestriction => text()();
  RealColumn get compatibilityScore => real()();
  BoolColumn get isCommunityVerified => boolean().withDefault(const Constant(false))();
  IntColumn get verificationCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastVerified => dateTime().nullable()();
}

class UserDiscoveryHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get placeId => text().references(Restaurants, #placeId)();
  TextColumn get searchQuery => text().nullable()();
  TextColumn get appliedFilters => text().withDefault(const Constant('{}'))(); // JSON object
  BoolColumn get wasSelected => boolean().withDefault(const Constant(false))();
  DateTimeColumn get viewedAt => dateTime().withDefault(currentDateAndTime)();
}

class AIRecommendations extends Table {
  TextColumn get id => text()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get recommendedRestaurantIds => text()(); // JSON array of place IDs
  TextColumn get reasoning => text()();
  TextColumn get factorWeights => text().withDefault(const Constant('{}'))(); // JSON object
  RealColumn get overallConfidence => real()();
  TextColumn get userContext => text().withDefault(const Constant('{}'))(); // JSON object
  DateTimeColumn get generatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get wasAccepted => boolean().withDefault(const Constant(false))();
  TextColumn get userFeedback => text().nullable()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))(); // JSON object
  DateTimeColumn get expiresAt => dateTime()(); // For cache invalidation
  
  @override
  Set<Column> get primaryKey => {id};
}

class AIRecommendationFeedback extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recommendationId => text().references(AIRecommendations, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get placeId => text().references(Restaurants, #placeId)();
  IntColumn get rating => integer()(); // 1-5 stars
  TextColumn get feedbackText => text().nullable()();
  BoolColumn get wasSelected => boolean().withDefault(const Constant(false))();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();
}

class AIUsageMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get requestType => text()(); // 'recommendation', 'feedback', etc.
  IntColumn get tokensUsed => integer().withDefault(const Constant(0))();
  RealColumn get costInCents => real().withDefault(const Constant(0.0))();
  IntColumn get responseTimeMs => integer().nullable()();
  BoolColumn get wasSuccessful => boolean().withDefault(const Constant(true))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class Photos extends Table {
  TextColumn get id => text()(); // UUID
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get fileName => text()();
  TextColumn get localPath => text()();
  TextColumn get cloudUrl => text().nullable()(); // For future cloud storage
  IntColumn get fileSizeBytes => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('image/jpeg'))();
  TextColumn get photoType => text()(); // 'meal', 'restaurant', 'receipt'
  TextColumn get associatedEntityId => text().nullable()(); // meal ID, restaurant place ID, etc.
  TextColumn get metadata => text().withDefault(const Constant('{}'))(); // JSON metadata (filters applied, etc.)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get uploadedAt => dateTime().nullable()();
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Meals, BudgetTrackings, Restaurants, RestaurantCache, DietaryCompatibility, UserDiscoveryHistory, AIRecommendations, AIRecommendationFeedback, AIUsageMetrics, Photos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDatabaseConnection());
  AppDatabase._(DatabaseConnection e) : super(e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // Add indexes for better query performance
      await _createOptimizedIndexes(migrator);
    },
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createOptimizedIndexes(migrator);
    },
  );

  /// Create optimized indexes for better query performance
  Future<void> _createOptimizedIndexes(Migrator migrator) async {
    // Index on frequently queried meal fields
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_meals_user_date ON meals(user_id, date DESC)'
    );
    
    // Index on restaurant location for geographic queries
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_restaurants_location ON restaurants(latitude, longitude)'
    );
    
    // Index on restaurant rating and price for filtering
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_restaurants_rating_price ON restaurants(rating DESC, price_level)'
    );
    
    // Index on budget tracking for date-based queries
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budget_user_date ON budget_trackings(user_id, date DESC)'
    );
    
    // Index on discovery history for user analytics
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_discovery_user_date ON user_discovery_history(user_id, viewed_at DESC)'
    );
    
    // Index on AI recommendations expiry for cleanup
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ai_recommendations_expires ON a_i_recommendations(expires_at)'
    );
    
    // Index on restaurant cache expiry
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_restaurant_cache_expires ON restaurant_cache(expires_at)'
    );
    
    // Composite index for restaurant filtering
    await migrator.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_restaurants_filter ON restaurants(is_open_now, has_verified_dietary_info, rating DESC)'
    );
  }

  // Factory method for testing
  static AppDatabase testInstance() {
    return AppDatabase._(createTestDatabaseConnection());
  }

  // User operations
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
  
  Future<User?> getDatabaseUserById(int id) => 
    (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Future<List<User>> getAllDatabaseUsers() => select(users).get();
  
  Future<bool> updateUser(UsersCompanion user) =>
    update(users).replace(user);

  // Meal operations
  Future<int> insertMeal(MealsCompanion meal) => into(meals).insert(meal);
  
  Future<List<Meal>> getMealsByUserId(int userId) =>
    (select(meals)..where((tbl) => tbl.userId.equals(userId))).get();
  
  Future<List<Meal>> getMealsByDateRange(int userId, DateTime start, DateTime end) =>
    (select(meals)
      ..where((tbl) => tbl.userId.equals(userId))
      ..where((tbl) => tbl.date.isBiggerOrEqual(Variable(start)) & tbl.date.isSmallerOrEqual(Variable(end)))).get();

  // Budget tracking operations
  Future<int> insertBudgetTracking(BudgetTrackingsCompanion budgetTracking) =>
    into(budgetTrackings).insert(budgetTracking);
  
  Future<List<BudgetTracking>> getBudgetTrackingByUserId(int userId) =>
    (select(budgetTrackings)..where((tbl) => tbl.userId.equals(userId))).get();

  // Restaurant operations
  Future<int> insertRestaurant(RestaurantsCompanion restaurant) =>
    into(restaurants).insert(restaurant, mode: InsertMode.insertOrReplace);
  
  Future<Restaurant?> getRestaurantByPlaceId(String placeId) =>
    (select(restaurants)..where((tbl) => tbl.placeId.equals(placeId))).getSingleOrNull();
  
  Future<List<Restaurant>> getAllRestaurants() => select(restaurants).get();

  // Entity conversion methods moved to EntityMappers class

  // Enhanced restaurant operations for discovery with optimized geographic queries
  Future<List<Restaurant>> getRestaurantsNearLocation(double latitude, double longitude, double radiusKm) async {
    // Optimized: Pre-filter using bounding box to reduce dataset before precise calculation
    final latDegreeRange = radiusKm / 111.0; // Approximate degrees per km
    final lngDegreeRange = radiusKm / (111.0 * math.cos(latitude * math.pi / 180));
    
    final query = select(restaurants)..where((tbl) => 
      tbl.latitude.isNotNull() & 
      tbl.longitude.isNotNull() &
      tbl.latitude.isBetween(Variable(latitude - latDegreeRange), Variable(latitude + latDegreeRange)) &
      tbl.longitude.isBetween(Variable(longitude - lngDegreeRange), Variable(longitude + lngDegreeRange))
    );
    
    final results = await query.get();
    
    // Final precise distance filtering for results within bounding box
    return results.where((restaurant) {
      if (restaurant.latitude == null || restaurant.longitude == null) return false;
      
      // Use Haversine formula for more accurate distance calculation
      final distance = _calculateHaversineDistance(
        latitude, longitude, 
        restaurant.latitude!, restaurant.longitude!
      );
      
      return distance <= radiusKm;
    }).toList();
  }

  Future<List<Restaurant>> getRestaurantsByDietaryRestrictions(List<String> restrictions) async {
    if (restrictions.isEmpty) return getAllRestaurants();
    
    // Optimized: Use database-level filtering with JSON queries instead of loading all data
    final query = select(restaurants);
    
    for (final restriction in restrictions) {
      query.where((tbl) => 
        tbl.supportedDietaryRestrictions.like('%"$restriction"%') |
        tbl.dietaryCompatibilityScores.like('%"$restriction"%')
      );
    }
    
    return await query.get();
  }

  // Cache operations for performance
  Future<void> insertRestaurantCache(RestaurantCacheCompanion cache) =>
    into(restaurantCache).insert(cache, mode: InsertMode.insertOrReplace);

  Future<List<RestaurantCacheData>> getCachedRestaurants(String searchQuery, double lat, double lng) =>
    (select(restaurantCache)
      ..where((tbl) => 
        tbl.searchQuery.equals(searchQuery) &
        tbl.userLatitude.equals(lat) &
        tbl.userLongitude.equals(lng) &
        tbl.expiresAt.isBiggerThan(Variable(DateTime.now()))
      )).get();

  // Discovery history tracking
  Future<int> insertDiscoveryHistory(UserDiscoveryHistoryCompanion history) =>
    into(userDiscoveryHistory).insert(history);

  Future<List<UserDiscoveryHistoryData>> getUserDiscoveryHistory(int userId, {int limit = 50}) =>
    (select(userDiscoveryHistory)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.viewedAt)])
      ..limit(limit)).get();

  // Dietary compatibility operations
  Future<int> insertDietaryCompatibility(DietaryCompatibilityCompanion compatibility) =>
    into(dietaryCompatibility).insert(compatibility, mode: InsertMode.insertOrReplace);

  Future<List<DietaryCompatibilityData>> getDietaryCompatibilityForRestaurant(String placeId) =>
    (select(dietaryCompatibility)..where((tbl) => tbl.placeId.equals(placeId))).get();

  // AI recommendation operations
  Future<void> insertAIRecommendation(AIRecommendationsCompanion recommendation) =>
    into(aIRecommendations).insert(recommendation, mode: InsertMode.insertOrReplace);

  Future<AIRecommendation?> getAIRecommendation(String id) =>
    (select(aIRecommendations)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<AIRecommendation>> getRecentAIRecommendations(int userId, {int limit = 10}) =>
    (select(aIRecommendations)
      ..where((tbl) => 
        tbl.userId.equals(userId) & 
        tbl.expiresAt.isBiggerThan(Variable(DateTime.now()))
      )
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.generatedAt)])
      ..limit(limit)).get();

  Future<void> updateAIRecommendationFeedback(String recommendationId, bool wasAccepted, String? feedback) =>
    (update(aIRecommendations)..where((tbl) => tbl.id.equals(recommendationId)))
      .write(AIRecommendationsCompanion(
        wasAccepted: Value(wasAccepted),
        userFeedback: Value(feedback),
      ));

  // AI recommendation feedback operations
  Future<int> insertAIRecommendationFeedback(AIRecommendationFeedbackCompanion feedback) =>
    into(aIRecommendationFeedback).insert(feedback);

  Future<List<AIRecommendationFeedbackData>> getAIRecommendationFeedback(String recommendationId) =>
    (select(aIRecommendationFeedback)..where((tbl) => tbl.recommendationId.equals(recommendationId))).get();

  Future<List<AIRecommendationFeedbackData>> getUserAIFeedbackHistory(int userId, {int limit = 50}) =>
    (select(aIRecommendationFeedback)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.submittedAt)])
      ..limit(limit)).get();

  // AI usage metrics operations
  Future<int> insertAIUsageMetric(AIUsageMetricsCompanion metric) =>
    into(aIUsageMetrics).insert(metric);

  Future<List<AIUsageMetric>> getAIUsageMetrics(int userId, {DateTime? startDate, DateTime? endDate}) {
    final query = select(aIUsageMetrics)..where((tbl) => tbl.userId.equals(userId));
    
    if (startDate != null) {
      query.where((tbl) => tbl.timestamp.isBiggerOrEqual(Variable(startDate)));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.timestamp.isSmallerOrEqual(Variable(endDate)));
    }
    
    return query.get();
  }

  Future<double> getTotalAICostForUser(int userId, {DateTime? startDate}) async {
    final query = select(aIUsageMetrics)..where((tbl) => tbl.userId.equals(userId));
    
    if (startDate != null) {
      query.where((tbl) => tbl.timestamp.isBiggerOrEqual(Variable(startDate)));
    }
    
    final results = await query.get();
    return results.fold(0.0, (sum, metric) => sum + metric.costInCents) / 100; // Convert cents to dollars
  }

  // Clean up expired AI recommendations
  Future<int> cleanupExpiredAIRecommendations() =>
    (delete(aIRecommendations)..where((tbl) => tbl.expiresAt.isSmallerThan(Variable(DateTime.now())))).go();

  // Optimized query methods for better performance
  
  /// Get meals with restaurant information using JOIN
  Future<List<MealWithRestaurant>> getMealsWithRestaurants(int userId) async {
    final query = select(meals).join([
      leftOuterJoin(restaurants, restaurants.placeId.equalsExp(meals.restaurantId))
    ])..where(meals.userId.equals(userId))
      ..orderBy([OrderingTerm.desc(meals.date)]);
    
    return query.map((row) {
      final meal = row.readTable(meals);
      final restaurant = row.readTableOrNull(restaurants);
      return MealWithRestaurant(meal, restaurant);
    }).get();
  }

  /// Get user budget summary with aggregations - optimized single query
  Future<BudgetSummary> getUserBudgetSummary(int userId, DateTime startDate, DateTime endDate) async {
    final totalSpentQuery = selectOnly(budgetTrackings)
      ..addColumns([budgetTrackings.amount.sum()])
      ..where(budgetTrackings.userId.equals(userId) & 
              budgetTrackings.date.isBetween(Variable(startDate), Variable(endDate)));
    
    final categoryBreakdownQuery = selectOnly(budgetTrackings)
      ..addColumns([budgetTrackings.category, budgetTrackings.amount.sum()])
      ..where(budgetTrackings.userId.equals(userId) & 
              budgetTrackings.date.isBetween(Variable(startDate), Variable(endDate)))
      ..groupBy([budgetTrackings.category]);
    
    final totalResult = await totalSpentQuery.getSingle();
    final categoryResults = await categoryBreakdownQuery.get();
    
    return BudgetSummary(
      totalSpent: totalResult.read(budgetTrackings.amount.sum()) ?? 0.0,
      categoryBreakdown: {
        for (final row in categoryResults)
          row.read(budgetTrackings.category)!: row.read(budgetTrackings.amount.sum()) ?? 0.0
      }
    );
  }

  /// Get recent meals with improved pagination and indexing
  Future<List<Meal>> getRecentMeals(int userId, {int limit = 20, int offset = 0}) async {
    return (select(meals)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
      ..limit(limit, offset: offset))
    .get();
  }

  /// Get restaurants with optimal filtering and sorting
  Future<List<Restaurant>> getFilteredRestaurants({
    double? minRating,
    int? maxPriceLevel,
    List<String>? cuisineTypes,
    bool? isOpenNow,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(restaurants);
    
    if (minRating != null) {
      query.where((tbl) => tbl.rating.isBiggerOrEqualValue(minRating));
    }
    
    if (maxPriceLevel != null) {
      query.where((tbl) => tbl.priceLevel.isSmallerOrEqualValue(maxPriceLevel));
    }
    
    if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
      query.where((tbl) {
        Expression<bool> condition = const Constant(false);
        for (final cuisine in cuisineTypes) {
          condition = condition | tbl.cuisineTypes.like('%"$cuisine"%');
        }
        return condition;
      });
    }
    
    if (isOpenNow != null) {
      query.where((tbl) => tbl.isOpenNow.equals(isOpenNow));
    }
    
    query.orderBy([(tbl) => OrderingTerm.desc(tbl.rating)]);
    query.limit(limit, offset: offset);
    
    return query.get();
  }

  /// Clean up expired cache entries for performance
  Future<int> cleanupExpiredCache() async {
    final now = DateTime.now();
    return (delete(restaurantCache)..where((tbl) => tbl.expiresAt.isSmallerThan(Variable(now)))).go();
  }

  /// Batch insert restaurants for better performance
  Future<void> batchInsertRestaurants(List<RestaurantsCompanion> restaurants) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(this.restaurants, restaurants);
    });
  }

  /// Get user activity statistics with single optimized query
  Future<UserActivityStats> getUserActivityStats(int userId, DateTime since) async {
    final mealCountQuery = selectOnly(meals)
      ..addColumns([meals.id.count()])
      ..where(meals.userId.equals(userId) & meals.date.isBiggerOrEqual(Variable(since)));
    
    final budgetSpentQuery = selectOnly(budgetTrackings)
      ..addColumns([budgetTrackings.amount.sum()])
      ..where(budgetTrackings.userId.equals(userId) & budgetTrackings.date.isBiggerOrEqual(Variable(since)));
    
    final discoveryCountQuery = selectOnly(userDiscoveryHistory)
      ..addColumns([userDiscoveryHistory.id.count()])
      ..where(userDiscoveryHistory.userId.equals(userId) & userDiscoveryHistory.viewedAt.isBiggerOrEqual(Variable(since)));
    
    final mealResult = await mealCountQuery.getSingle();
    final budgetResult = await budgetSpentQuery.getSingle();
    final discoveryResult = await discoveryCountQuery.getSingle();
    
    return UserActivityStats(
      mealCount: mealResult.read(meals.id.count()) ?? 0,
      totalSpent: budgetResult.read(budgetTrackings.amount.sum()) ?? 0.0,
      restaurantsDiscovered: discoveryResult.read(userDiscoveryHistory.id.count()) ?? 0,
    );
  }

  /// Calculate Haversine distance between two points
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  // Foreign Key Constraint Management

  /// Validate foreign key constraints before insert/update
  Future<bool> validateMealConstraints(MealsCompanion meal) async {
    // Check if user exists
    if (meal.userId.present) {
      final userExists = await (select(users)..where((tbl) => tbl.id.equals(meal.userId.value))).getSingleOrNull();
      if (userExists == null) {
        throw ArgumentError('User with id ${meal.userId.value} does not exist');
      }
    }

    // Check if restaurant exists (if specified)
    if (meal.restaurantId.present && meal.restaurantId.value != null) {
      final restaurantExists = await (select(restaurants)..where((tbl) => tbl.placeId.equals(meal.restaurantId.value!))).getSingleOrNull();
      if (restaurantExists == null) {
        throw ArgumentError('Restaurant with placeId ${meal.restaurantId.value} does not exist');
      }
    }

    return true;
  }

  /// Validate budget tracking constraints
  Future<bool> validateBudgetTrackingConstraints(BudgetTrackingsCompanion budgetTracking) async {
    if (budgetTracking.userId.present) {
      final userExists = await (select(users)..where((tbl) => tbl.id.equals(budgetTracking.userId.value))).getSingleOrNull();
      if (userExists == null) {
        throw ArgumentError('User with id ${budgetTracking.userId.value} does not exist');
      }
    }
    return true;
  }

  /// Safe insert meal with constraint validation
  Future<int> insertMealSafe(MealsCompanion meal) async {
    await validateMealConstraints(meal);
    return await insertMeal(meal);
  }

  /// Safe insert budget tracking with constraint validation  
  Future<int> insertBudgetTrackingSafe(BudgetTrackingsCompanion budgetTracking) async {
    await validateBudgetTrackingConstraints(budgetTracking);
    return await insertBudgetTracking(budgetTracking);
  }

  /// Clean up orphaned records (meals without valid restaurants)
  Future<int> cleanupOrphanedMeals() async {
    // Get list of valid restaurant place IDs
    final validRestaurantIds = await (selectOnly(restaurants)
      ..addColumns([restaurants.placeId])).map((row) => row.read(restaurants.placeId)!).get();

    // Find meals that reference non-existent restaurants
    final orphanedMeals = await (select(meals)
      ..where((tbl) => tbl.restaurantId.isNotNull() & tbl.restaurantId.isNotIn(validRestaurantIds))).get();

    if (orphanedMeals.isEmpty) return 0;

    // Update these meals to have null restaurant reference instead of deleting
    final orphanedIds = orphanedMeals.map((meal) => meal.id).toList();
    return await (update(meals)..where((tbl) => tbl.id.isIn(orphanedIds)))
        .write(const MealsCompanion(restaurantId: Value(null)));
  }

  /// Get referential integrity statistics
  Future<IntegrityStats> getReferentialIntegrityStats() async {
    final totalMeals = await (selectOnly(meals)..addColumns([meals.id.count()])).getSingle();
    final mealsWithRestaurants = await (select(meals)
      ..where((tbl) => tbl.restaurantId.isNotNull())).get();
    
    final validMealJoins = await (select(meals).join([
      innerJoin(restaurants, restaurants.placeId.equalsExp(meals.restaurantId))
    ])).get();
    final validMealsWithRestaurants = validMealJoins.length;

    final totalBudgetEntries = await (selectOnly(budgetTrackings)..addColumns([budgetTrackings.id.count()])).getSingle();
    
    return IntegrityStats(
      totalMeals: totalMeals.read(meals.id.count()) ?? 0,
      mealsWithRestaurants: mealsWithRestaurants.length,
      validMealRestaurantReferences: validMealsWithRestaurants,
      totalBudgetEntries: totalBudgetEntries.read(budgetTrackings.id.count()) ?? 0,
    );
  }
}

// Helper classes for optimized query results
class MealWithRestaurant {
  final Meal meal;
  final Restaurant? restaurant;
  
  MealWithRestaurant(this.meal, this.restaurant);
}

class BudgetSummary {
  final double totalSpent;
  final Map<String, double> categoryBreakdown;
  
  BudgetSummary({required this.totalSpent, required this.categoryBreakdown});
}

class UserActivityStats {
  final int mealCount;
  final double totalSpent;
  final int restaurantsDiscovered;
  
  UserActivityStats({
    required this.mealCount,
    required this.totalSpent,
    required this.restaurantsDiscovered,
  });
}

class IntegrityStats {
  final int totalMeals;
  final int mealsWithRestaurants;
  final int validMealRestaurantReferences;
  final int totalBudgetEntries;
  
  IntegrityStats({
    required this.totalMeals,
    required this.mealsWithRestaurants,
    required this.validMealRestaurantReferences,
    required this.totalBudgetEntries,
  });

  /// Get the percentage of meals with valid restaurant references
  double get validRestaurantReferencePercentage {
    if (mealsWithRestaurants == 0) return 100.0;
    return (validMealRestaurantReferences / mealsWithRestaurants) * 100.0;
  }

  /// Check if referential integrity is healthy (>95% valid references)
  bool get isHealthy => validRestaurantReferencePercentage >= 95.0;
}

// Photo operations - add these methods to AppDatabase class
extension PhotoOperations on AppDatabase {
  // Photo CRUD operations
  Future<String> insertPhoto(PhotosCompanion photo) async {
    await into(photos).insert(photo);
    return photo.id.value; // Return the photo ID
  }
  
  Future<Photo?> getPhotoById(String id) =>
    (select(photos)..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false))).getSingleOrNull();
  
  Future<List<Photo>> getPhotosByUserId(int userId, {int limit = 50}) =>
    (select(photos)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(limit)).get();

  Future<List<Photo>> getPhotosByMealId(String mealId) =>
    (select(photos)..where((tbl) => 
      tbl.associatedEntityId.equals(mealId) & 
      tbl.photoType.equals('meal') &
      tbl.isDeleted.equals(false)
    )).get();

  Future<List<Photo>> getPhotosByRestaurantId(String restaurantId) =>
    (select(photos)..where((tbl) => 
      tbl.associatedEntityId.equals(restaurantId) & 
      tbl.photoType.equals('restaurant') &
      tbl.isDeleted.equals(false)
    )).get();

  Future<List<Photo>> getPhotosByType(String photoType, int userId) =>
    (select(photos)
      ..where((tbl) => 
        tbl.photoType.equals(photoType) & 
        tbl.userId.equals(userId) &
        tbl.isDeleted.equals(false)
      )
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();

  Future<bool> updatePhoto(PhotosCompanion photo) =>
    update(photos).replace(photo);

  Future<int> markPhotoAsDeleted(String photoId) =>
    (update(photos)..where((tbl) => tbl.id.equals(photoId)))
      .write(const PhotosCompanion(isDeleted: Value(true)));

  Future<int> markPhotoAsUploaded(String photoId, String cloudUrl) =>
    (update(photos)..where((tbl) => tbl.id.equals(photoId)))
      .write(PhotosCompanion(
        isUploaded: const Value(true),
        cloudUrl: Value(cloudUrl),
        uploadedAt: Value(DateTime.now()),
      ));

  // Cleanup operations
  Future<int> deleteOldPhotos(Duration maxAge) {
    final cutoffDate = DateTime.now().subtract(maxAge);
    return (delete(photos)..where((tbl) => 
      tbl.isDeleted.equals(true) & 
      tbl.createdAt.isSmallerThan(Variable(cutoffDate))
    )).go();
  }

  Future<List<Photo>> getUnuploadedPhotos(int userId) =>
    (select(photos)..where((tbl) => 
      tbl.userId.equals(userId) &
      tbl.isUploaded.equals(false) &
      tbl.isDeleted.equals(false)
    )).get();

  // Statistics
  Future<PhotoStats> getPhotoStats(int userId) async {
    final totalPhotosQuery = selectOnly(photos)
      ..addColumns([photos.id.count()])
      ..where(photos.userId.equals(userId) & photos.isDeleted.equals(false));
    
    final totalSizeQuery = selectOnly(photos)
      ..addColumns([photos.fileSizeBytes.sum()])
      ..where(photos.userId.equals(userId) & photos.isDeleted.equals(false));
    
    final uploadedPhotosQuery = selectOnly(photos)
      ..addColumns([photos.id.count()])
      ..where(photos.userId.equals(userId) & photos.isUploaded.equals(true) & photos.isDeleted.equals(false));
    
    final totalResult = await totalPhotosQuery.getSingle();
    final sizeResult = await totalSizeQuery.getSingle();
    final uploadedResult = await uploadedPhotosQuery.getSingle();
    
    return PhotoStats(
      totalPhotos: totalResult.read(photos.id.count()) ?? 0,
      totalSizeBytes: (sizeResult.read(photos.fileSizeBytes.sum()) ?? 0).toInt(),
      uploadedPhotos: uploadedResult.read(photos.id.count()) ?? 0,
    );
  }
}

class PhotoStats {
  final int totalPhotos;
  final int totalSizeBytes;
  final int uploadedPhotos;
  
  PhotoStats({
    required this.totalPhotos,
    required this.totalSizeBytes,
    required this.uploadedPhotos,
  });
  
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);
  int get pendingUploads => totalPhotos - uploadedPhotos;
}

