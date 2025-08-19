import '../../domain/entities/meal.dart' as entity;
import '../../domain/repositories/meal_repository.dart';
import '../database/database.dart';

class MealRepositoryImpl implements MealRepository {
  final AppDatabase _database;

  MealRepositoryImpl(this._database);

  @override
  Future<int> createMeal(entity.Meal meal) async {
    final companion = _database.mealToCompanion(meal);
    return await _database.insertMeal(companion);
  }

  @override
  Future<List<entity.Meal>> getMealsByUserId(int userId) async {
    final meals = await _database.getMealsByUserId(userId);
    return meals.map((meal) => _database.mealFromTable(meal)).toList();
  }

  @override
  Future<List<entity.Meal>> getMealsByDateRange(int userId, DateTime start, DateTime end) async {
    final meals = await _database.getMealsByDateRange(userId, start, end);
    return meals.map((meal) => _database.mealFromTable(meal)).toList();
  }

  @override
  Future<bool> updateMeal(entity.Meal meal) async {
    if (meal.id == null) return false;
    final companion = _database.mealToCompanion(meal);
    final updatedRows = await (_database.update(_database.meals)
          ..where((tbl) => tbl.id.equals(meal.id!)))
        .replace(companion);
    return updatedRows;
  }

  @override
  Future<bool> deleteMeal(int id) async {
    final deletedRows = await (_database.delete(_database.meals)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
    return deletedRows > 0;
  }
}