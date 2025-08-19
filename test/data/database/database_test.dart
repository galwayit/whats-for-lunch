import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_we_have_for_lunch/data/database/database.dart';
import 'package:what_we_have_for_lunch/domain/entities/budget_tracking.dart' as entity;
import 'package:what_we_have_for_lunch/domain/entities/meal.dart' as entity;
import 'package:what_we_have_for_lunch/domain/entities/restaurant.dart' as entity;
import 'package:what_we_have_for_lunch/domain/entities/user.dart' as entity;
import 'package:what_we_have_for_lunch/domain/entities/user_preferences.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create an in-memory database for testing
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('User Operations', () {
    test('should create and retrieve user', () async {
      // Arrange
      final preferences = const UserPreferences(
        budgetLevel: 3,
        maxTravelDistance: 10.0,
        includeChains: false,
      );
      
      final user = entity.UserEntity(
        name: 'John Doe',
        preferences: preferences.toJson(),
        createdAt: DateTime.now(),
      );

      // Act
      final userId = await database.insertUser(database.userToCompanion(user));
      final retrievedUser = await database.getDatabaseUserById(userId);

      // Assert
      expect(retrievedUser, isA<Object>());
      expect(retrievedUser!.name, equals('John Doe'));
      expect(retrievedUser.id, equals(userId));
    });

    test('should update user preferences', () async {
      // Arrange
      final initialPreferences = const UserPreferences(budgetLevel: 2);
      final user = entity.UserEntity(
        name: 'Jane Doe',
        preferences: initialPreferences.toJson(),
        createdAt: DateTime.now(),
      );

      final userId = await database.insertUser(database.userToCompanion(user));

      // Act
      final updatedPreferences = const UserPreferences(budgetLevel: 4);
      final updatedUser = entity.UserEntity(
        id: userId,
        name: 'Jane Doe',
        preferences: updatedPreferences.toJson(),
        createdAt: DateTime.now(),
      );

      final success = await database.updateUser(database.userToCompanion(updatedUser));
      final retrievedUser = await database.getDatabaseUserById(userId);

      // Assert
      expect(success, isTrue);
      expect(retrievedUser, isA<Object>());
      final retrievedPreferences = UserPreferences.fromJson(
        database.userFromTable(retrievedUser!).preferences,
      );
      expect(retrievedPreferences.budgetLevel, equals(4));
    });

    test('should get all users', () async {
      // Arrange
      final user1 = entity.UserEntity(
        name: 'User 1',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );
      final user2 = entity.UserEntity(
        name: 'User 2',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );

      // Act
      await database.insertUser(database.userToCompanion(user1));
      await database.insertUser(database.userToCompanion(user2));
      final users = await database.getAllDatabaseUsers();

      // Assert
      expect(users, hasLength(2));
      expect(users.map((u) => u.name), containsAll(['User 1', 'User 2']));
    });
  });

  group('Meal Operations', () {
    late int userId;

    setUp(() async {
      // Create a test user
      final user = entity.UserEntity(
        name: 'Test User',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );
      userId = await database.insertUser(database.userToCompanion(user));
    });

    test('should create and retrieve meal', () async {
      // Arrange
      final meal = entity.Meal(
        userId: userId,
        restaurantId: 'test_restaurant_id',
        mealType: 'lunch',
        cost: 15.50,
        date: DateTime.now(),
        notes: 'Delicious burger',
      );

      // Act
      final mealId = await database.insertMeal(database.mealToCompanion(meal));
      final meals = await database.getMealsByUserId(userId);

      // Assert
      expect(meals, hasLength(1));
      expect(meals.first.id, equals(mealId));
      expect(meals.first.cost, equals(15.50));
      expect(meals.first.mealType, equals('lunch'));
    });

    test('should get meals by date range', () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final meal1 = entity.Meal(
        userId: userId,
        mealType: 'breakfast',
        cost: 10.0,
        date: yesterday,
      );
      final meal2 = entity.Meal(
        userId: userId,
        mealType: 'lunch',
        cost: 15.0,
        date: now,
      );
      final meal3 = entity.Meal(
        userId: userId,
        mealType: 'dinner',
        cost: 20.0,
        date: tomorrow,
      );

      // Act
      await database.insertMeal(database.mealToCompanion(meal1));
      await database.insertMeal(database.mealToCompanion(meal2));
      await database.insertMeal(database.mealToCompanion(meal3));

      final mealsInRange = await database.getMealsByDateRange(
        userId,
        yesterday.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );

      // Assert
      expect(mealsInRange, hasLength(2));
      expect(mealsInRange.map((m) => m.mealType), containsAll(['breakfast', 'lunch']));
    });
  });

  group('Budget Tracking Operations', () {
    late int userId;

    setUp(() async {
      // Create a test user
      final user = entity.UserEntity(
        name: 'Test User',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );
      userId = await database.insertUser(database.userToCompanion(user));
    });

    test('should create and retrieve budget tracking', () async {
      // Arrange
      final budgetEntry = entity.BudgetTracking(
        userId: userId,
        amount: 100.0,
        category: 'dining',
        date: DateTime.now(),
      );

      // Act
      final entryId = await database.insertBudgetTracking(
        database.budgetTrackingToCompanion(budgetEntry),
      );
      final entries = await database.getBudgetTrackingByUserId(userId);

      // Assert
      expect(entries, hasLength(1));
      expect(entries.first.id, equals(entryId));
      expect(entries.first.amount, equals(100.0));
      expect(entries.first.category, equals('dining'));
    });
  });

  group('Restaurant Operations', () {
    test('should cache and retrieve restaurant', () async {
      // Arrange
      final restaurant = entity.Restaurant(
        placeId: 'test_place_id',
        name: 'Test Restaurant',
        location: 'Test Location',
        priceLevel: 2,
        rating: 4.5,
        cuisineType: 'italian',
        cachedAt: DateTime.now(),
      );

      // Act
      await database.insertRestaurant(database.restaurantToCompanion(restaurant));
      final retrievedRestaurant = await database.getRestaurantByPlaceId('test_place_id');

      // Assert
      expect(retrievedRestaurant, isA<Object>());
      expect(retrievedRestaurant!.name, equals('Test Restaurant'));
      expect(retrievedRestaurant.priceLevel, equals(2));
      expect(retrievedRestaurant.rating, equals(4.5));
    });

    test('should handle insert or replace for restaurants', () async {
      // Arrange
      final restaurant1 = entity.Restaurant(
        placeId: 'test_place_id',
        name: 'Test Restaurant',
        location: 'Test Location',
        priceLevel: 2,
        rating: 4.5,
        cuisineType: 'italian',
        cachedAt: DateTime.now(),
      );

      final restaurant2 = entity.Restaurant(
        placeId: 'test_place_id', // Same place ID
        name: 'Updated Restaurant',
        location: 'Updated Location',
        priceLevel: 3,
        rating: 4.8,
        cuisineType: 'italian',
        cachedAt: DateTime.now(),
      );

      // Act
      await database.insertRestaurant(database.restaurantToCompanion(restaurant1));
      await database.insertRestaurant(database.restaurantToCompanion(restaurant2));
      
      final allRestaurants = await database.getAllRestaurants();
      final retrievedRestaurant = await database.getRestaurantByPlaceId('test_place_id');

      // Assert
      expect(allRestaurants, hasLength(1)); // Should only have one restaurant
      expect(retrievedRestaurant!.name, equals('Updated Restaurant'));
      expect(retrievedRestaurant.priceLevel, equals(3));
    });
  });

  group('Entity Conversion', () {
    test('should convert user entity to companion and back', () async {
      // Arrange
      final preferences = const UserPreferences(
        budgetLevel: 3,
        maxTravelDistance: 15.0,
        includeChains: true,
      );
      
      final originalUser = entity.UserEntity(
        name: 'Conversion Test',
        preferences: preferences.toJson(),
        createdAt: DateTime.now(),
      );

      // Act
      final companion = database.userToCompanion(originalUser);
      final userId = await database.insertUser(companion);
      final retrievedUser = await database.getDatabaseUserById(userId);
      final convertedUser = database.userFromTable(retrievedUser!);

      // Assert
      expect(convertedUser.name, equals(originalUser.name));
      expect(convertedUser.preferences, equals(originalUser.preferences));
    });

    test('should convert meal entity to companion and back', () async {
      // Arrange
      final user = entity.UserEntity(
        name: 'Test User',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );
      final userId = await database.insertUser(database.userToCompanion(user));

      final originalMeal = entity.Meal(
        userId: userId,
        restaurantId: 'restaurant_123',
        mealType: 'dinner',
        cost: 25.75,
        date: DateTime.now(),
        notes: 'Great pizza',
      );

      // Act
      final companion = database.mealToCompanion(originalMeal);
      final mealId = await database.insertMeal(companion);
      final retrievedMeals = await database.getMealsByUserId(userId);
      final convertedMeal = database.mealFromTable(retrievedMeals.first);

      // Assert
      expect(convertedMeal.userId, equals(originalMeal.userId));
      expect(convertedMeal.restaurantId, equals(originalMeal.restaurantId));
      expect(convertedMeal.mealType, equals(originalMeal.mealType));
      expect(convertedMeal.cost, equals(originalMeal.cost));
      expect(convertedMeal.notes, equals(originalMeal.notes));
    });
  });
}

// Helper function to create test database
AppDatabase createTestDatabase() {
  return AppDatabase.testInstance();
}