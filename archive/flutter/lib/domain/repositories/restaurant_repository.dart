import '../entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<int> cacheRestaurant(Restaurant restaurant);
  Future<Restaurant?> getRestaurantByPlaceId(String placeId);
  Future<List<Restaurant>> getAllCachedRestaurants();
  Future<bool> updateRestaurant(Restaurant restaurant);
  Future<bool> deleteRestaurant(String placeId);
  Future<bool> clearExpiredCache(Duration maxAge);
}