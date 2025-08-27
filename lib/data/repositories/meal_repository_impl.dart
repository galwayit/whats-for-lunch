import '../../domain/entities/meal.dart' as domain;
import '../../domain/repositories/meal_repository.dart';
import '../database/database.dart';
import '../mappers/entity_mappers.dart';
import '../../core/services/performance_monitoring_service.dart';
import '../../core/services/error_handling_service.dart';
import '../../core/services/logging_service.dart';

class MealRepositoryImpl implements MealRepository {
  final AppDatabase _database;
  final PerformanceMonitoringService _performance = PerformanceMonitoringService();
  final ErrorHandlingService _errorHandler = ErrorHandlingService();
  final LoggingService _logging = LoggingService();

  MealRepositoryImpl(this._database);

  @override
  Future<int> createMeal(domain.Meal meal) async {
    const operation = 'create_meal';
    _performance.startOperation(operation);
    
    try {
      final companion = EntityMappers.mealToCompanion(meal);
      final result = await _database.insertMealSafe(companion);
      
      await _logging.databaseOperation(
        'INSERT',
        'meals',
        duration: DateTime.now().difference(DateTime.now()),
        parameters: {'user_id': meal.userId, 'restaurant_id': meal.restaurantId},
      );
      
      _performance.endOperation(operation, metadata: {
        'user_id': meal.userId,
        'meal_id': result,
      });
      
      return result;
    } catch (e, stackTrace) {
      final error = _errorHandler.handleDatabaseError(
        e,
        operation: operation,
        table: 'meals',
        queryData: {'user_id': meal.userId, 'restaurant_id': meal.restaurantId},
      );
      
      await _logging.error(
        'Failed to create meal',
        tag: 'MealRepository',
        error: e,
        stackTrace: stackTrace,
        extra: {'user_id': meal.userId},
      );
      
      _performance.endOperation(operation, metadata: {'error': e.toString()});
      throw error;
    }
  }

  @override
  Future<List<domain.Meal>> getMealsByUserId(int userId) async {
    const operation = 'get_meals_by_user';
    _performance.startOperation(operation);
    
    try {
      final meals = await _database.getMealsByUserId(userId);
      final result = meals.map((meal) => EntityMappers.mealFromDatabase(meal)).toList();
      
      _performance.recordDatabaseOperation(
        'SELECT',
        DateTime.now().difference(DateTime.now()),
        recordCount: result.length,
        table: 'meals',
      );
      
      await _logging.databaseOperation(
        'SELECT',
        'meals',
        affectedRows: result.length,
        parameters: {'user_id': userId},
      );
      
      _performance.endOperation(operation, metadata: {
        'user_id': userId,
        'meal_count': result.length,
      });
      
      return result;
    } catch (e, stackTrace) {
      final error = _errorHandler.handleDatabaseError(
        e,
        operation: operation,
        table: 'meals',
        queryData: {'user_id': userId},
      );
      
      await _logging.error(
        'Failed to get meals by user ID',
        tag: 'MealRepository',
        error: e,
        stackTrace: stackTrace,
        extra: {'user_id': userId},
      );
      
      _performance.endOperation(operation, metadata: {'error': e.toString()});
      throw error;
    }
  }

  @override
  Future<List<domain.Meal>> getMealsByDateRange(int userId, DateTime start, DateTime end) async {
    const operation = 'get_meals_by_date_range';
    _performance.startOperation(operation);
    
    try {
      final meals = await _database.getMealsByDateRange(userId, start, end);
      final result = meals.map((meal) => EntityMappers.mealFromDatabase(meal)).toList();
      
      _performance.recordDatabaseOperation(
        'SELECT',
        DateTime.now().difference(DateTime.now()),
        recordCount: result.length,
        table: 'meals',
      );
      
      await _logging.databaseOperation(
        'SELECT',
        'meals',
        affectedRows: result.length,
        parameters: {
          'user_id': userId,
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );
      
      _performance.endOperation(operation, metadata: {
        'user_id': userId,
        'date_range_days': end.difference(start).inDays,
        'meal_count': result.length,
      });
      
      return result;
    } catch (e, stackTrace) {
      final error = _errorHandler.handleDatabaseError(
        e,
        operation: operation,
        table: 'meals',
        queryData: {
          'user_id': userId,
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );
      
      await _logging.error(
        'Failed to get meals by date range',
        tag: 'MealRepository',
        error: e,
        stackTrace: stackTrace,
        extra: {'user_id': userId, 'date_range_days': end.difference(start).inDays},
      );
      
      _performance.endOperation(operation, metadata: {'error': e.toString()});
      throw error;
    }
  }

  @override
  Future<bool> updateMeal(domain.Meal meal) async {
    if (meal.id == null) return false;
    
    const operation = 'update_meal';
    _performance.startOperation(operation);
    
    try {
      final companion = EntityMappers.mealToCompanion(meal);
      final updatedRows = await (_database.update(_database.meals)
            ..where((tbl) => tbl.id.equals(meal.id!)))
          .replace(companion);
      
      await _logging.databaseOperation(
        'UPDATE',
        'meals',
        affectedRows: updatedRows ? 1 : 0,
        parameters: {'meal_id': meal.id, 'user_id': meal.userId},
      );
      
      _performance.endOperation(operation, metadata: {
        'meal_id': meal.id,
        'success': updatedRows,
      });
      
      return updatedRows;
    } catch (e, stackTrace) {
      final error = _errorHandler.handleDatabaseError(
        e,
        operation: operation,
        table: 'meals',
        queryData: {'meal_id': meal.id, 'user_id': meal.userId},
      );
      
      await _logging.error(
        'Failed to update meal',
        tag: 'MealRepository',
        error: e,
        stackTrace: stackTrace,
        extra: {'meal_id': meal.id},
      );
      
      _performance.endOperation(operation, metadata: {'error': e.toString()});
      throw error;
    }
  }

  @override
  Future<bool> deleteMeal(int id) async {
    const operation = 'delete_meal';
    _performance.startOperation(operation);
    
    try {
      final deletedRows = await (_database.delete(_database.meals)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
      final success = deletedRows > 0;
      
      await _logging.databaseOperation(
        'DELETE',
        'meals',
        affectedRows: deletedRows,
        parameters: {'meal_id': id},
      );
      
      _performance.endOperation(operation, metadata: {
        'meal_id': id,
        'success': success,
        'deleted_rows': deletedRows,
      });
      
      return success;
    } catch (e, stackTrace) {
      final error = _errorHandler.handleDatabaseError(
        e,
        operation: operation,
        table: 'meals',
        queryData: {'meal_id': id},
      );
      
      await _logging.error(
        'Failed to delete meal',
        tag: 'MealRepository',
        error: e,
        stackTrace: stackTrace,
        extra: {'meal_id': id},
      );
      
      _performance.endOperation(operation, metadata: {'error': e.toString()});
      throw error;
    }
  }

  /// Get paginated meals for lazy loading
  Future<List<domain.Meal>> getMealsPaginated(int userId, {
    int page = 0,
    int limit = 20,
    String? sortBy = 'date',
    bool ascending = false,
  }) async {
    const operation = 'get_meals_paginated';
    _performance.startOperation(operation);
    
    try {
      final offset = page * limit;
      final meals = await _database.getRecentMeals(userId, limit: limit, offset: offset);
      final result = meals.map((meal) => EntityMappers.mealFromDatabase(meal)).toList();
      
      _performance.recordDatabaseOperation(
        'SELECT',
        DateTime.now().difference(DateTime.now()),
        recordCount: result.length,
        table: 'meals',
      );
      
      await _logging.databaseOperation(
        'SELECT',
        'meals',
        affectedRows: result.length,
        parameters: {
          'user_id': userId,
          'page': page,
          'limit': limit,
          'offset': offset,
        },
      );
      
      _performance.endOperation(operation, metadata: {
        'user_id': userId,
        'page': page,
        'limit': limit,
        'meal_count': result.length,
      });
      
      return result;
    } catch (e, stackTrace) {
      final error = _errorHandler.handleDatabaseError(
        e,
        operation: operation,
        table: 'meals',
        queryData: {'user_id': userId, 'page': page, 'limit': limit},
      );
      
      await _logging.error(
        'Failed to get paginated meals',
        tag: 'MealRepository',
        error: e,
        stackTrace: stackTrace,
        extra: {'user_id': userId, 'page': page},
      );
      
      _performance.endOperation(operation, metadata: {'error': e.toString()});
      throw error;
    }
  }
}