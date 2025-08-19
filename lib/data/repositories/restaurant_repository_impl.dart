import 'package:drift/drift.dart';

import '../../domain/entities/restaurant.dart' as entity;
import '../../domain/repositories/restaurant_repository.dart';
import '../database/database.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final AppDatabase _database;

  RestaurantRepositoryImpl(this._database);

  @override
  Future<int> cacheRestaurant(entity.Restaurant restaurant) async {
    final companion = _database.restaurantToCompanion(restaurant);
    return await _database.insertRestaurant(companion);
  }

  @override
  Future<entity.Restaurant?> getRestaurantByPlaceId(String placeId) async {
    final restaurant = await _database.getRestaurantByPlaceId(placeId);
    if (restaurant == null) return null;
    return _database.restaurantFromTable(restaurant);
  }

  @override
  Future<List<entity.Restaurant>> getAllCachedRestaurants() async {
    final restaurants = await _database.getAllRestaurants();
    return restaurants.map((restaurant) => _database.restaurantFromTable(restaurant)).toList();
  }

  @override
  Future<bool> updateRestaurant(entity.Restaurant restaurant) async {
    final companion = _database.restaurantToCompanion(restaurant);
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
}