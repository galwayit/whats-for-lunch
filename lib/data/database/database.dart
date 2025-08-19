import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../domain/entities/budget_tracking.dart' as entity;
import '../../domain/entities/meal.dart' as entity;
import '../../domain/entities/restaurant.dart' as entity;
import '../../domain/entities/user.dart' as entity;

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
}

class BudgetTrackings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
}

class Restaurants extends Table {
  TextColumn get placeId => text()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  IntColumn get priceLevel => integer().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get cuisineType => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {placeId};
}

@DriftDatabase(tables: [Users, Meals, BudgetTrackings, Restaurants])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase._(DatabaseConnection e) : super(e);

  @override
  int get schemaVersion => 1;

  // Factory method for testing
  static AppDatabase testInstance() {
    return AppDatabase._(DatabaseConnection(NativeDatabase.memory()));
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

  // Helper methods to convert between entity and table classes
  entity.UserEntity userFromTable(User driftUser) {
    return entity.UserEntity(
      id: driftUser.id,
      name: driftUser.name,
      preferences: json.decode(driftUser.preferences) as Map<String, dynamic>,
      createdAt: driftUser.createdAt,
    );
  }

  UsersCompanion userToCompanion(entity.UserEntity user) {
    return UsersCompanion(
      id: user.id != null ? Value(user.id!) : const Value.absent(),
      name: Value(user.name),
      preferences: Value(json.encode(user.preferences)),
      createdAt: Value(user.createdAt),
    );
  }

  entity.Meal mealFromTable(Meal meal) {
    return entity.Meal(
      id: meal.id,
      userId: meal.userId,
      restaurantId: meal.restaurantId,
      mealType: meal.mealType,
      cost: meal.cost,
      date: meal.date,
      notes: meal.notes,
    );
  }

  MealsCompanion mealToCompanion(entity.Meal meal) {
    return MealsCompanion(
      id: meal.id != null ? Value(meal.id!) : const Value.absent(),
      userId: Value(meal.userId),
      restaurantId: Value(meal.restaurantId),
      mealType: Value(meal.mealType),
      cost: Value(meal.cost),
      date: Value(meal.date),
      notes: Value(meal.notes),
    );
  }

  entity.BudgetTracking budgetTrackingFromTable(BudgetTracking budgetTracking) {
    return entity.BudgetTracking(
      id: budgetTracking.id,
      userId: budgetTracking.userId,
      amount: budgetTracking.amount,
      category: budgetTracking.category,
      date: budgetTracking.date,
    );
  }

  BudgetTrackingsCompanion budgetTrackingToCompanion(entity.BudgetTracking budgetTracking) {
    return BudgetTrackingsCompanion(
      id: budgetTracking.id != null ? Value(budgetTracking.id!) : const Value.absent(),
      userId: Value(budgetTracking.userId),
      amount: Value(budgetTracking.amount),
      category: Value(budgetTracking.category),
      date: Value(budgetTracking.date),
    );
  }

  entity.Restaurant restaurantFromTable(Restaurant restaurant) {
    return entity.Restaurant(
      placeId: restaurant.placeId,
      name: restaurant.name,
      location: restaurant.location,
      priceLevel: restaurant.priceLevel,
      rating: restaurant.rating,
      cuisineType: restaurant.cuisineType,
      cachedAt: restaurant.cachedAt,
    );
  }

  RestaurantsCompanion restaurantToCompanion(entity.Restaurant restaurant) {
    return RestaurantsCompanion(
      placeId: Value(restaurant.placeId),
      name: Value(restaurant.name),
      location: Value(restaurant.location),
      priceLevel: Value(restaurant.priceLevel),
      rating: Value(restaurant.rating),
      cuisineType: Value(restaurant.cuisineType),
      cachedAt: Value(restaurant.cachedAt),
    );
  }
}

DatabaseConnection _openConnection() {
  return DatabaseConnection(NativeDatabase.memory());
}