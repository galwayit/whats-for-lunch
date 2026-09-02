import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/repositories/restaurant_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../../domain/repositories/user_repository.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final database = ref.read(databaseProvider);
  return UserRepositoryImpl(database);
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final database = ref.read(databaseProvider);
  return MealRepositoryImpl(database);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final database = ref.read(databaseProvider);
  return BudgetRepositoryImpl(database);
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final database = ref.read(databaseProvider);
  return RestaurantRepositoryImpl(database);
});