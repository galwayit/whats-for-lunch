import '../entities/meal.dart';

abstract class MealRepository {
  Future<int> createMeal(Meal meal);
  Future<List<Meal>> getMealsByUserId(int userId);
  Future<List<Meal>> getMealsByDateRange(int userId, DateTime start, DateTime end);
  Future<bool> updateMeal(Meal meal);
  Future<bool> deleteMeal(int id);
}