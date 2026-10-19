package au.iapp.lunch.core.data

import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.RestaurantRepository
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.db.toRestaurant
import au.iapp.lunch.core.db.upsert
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.core.network.BackendClient
import au.iapp.lunch.core.network.PlacesNearbyRequest
import kotlinx.coroutines.withContext

/**
 * Nearby search through the backend with the Flutter app's 24 h local cache:
 * `restaurant_cache` rows keyed by (query, lat, lng) rounded to three decimals
 * point at rows in `restaurants`. When the network is down, stale cache rows for
 * the same key are served instead of failing.
 */
internal class RestaurantRepositoryImpl(
    private val db: LunchDatabase,
    private val backend: BackendClient,
    private val clock: Clock,
) : RestaurantRepository {
    // Transient display state only; Google fields never enter the on-disk cache.
    private val visiblePlaces = mutableMapOf<String, Restaurant>()


    override suspend fun searchNearby(
        location: Location,
        radiusKm: Double,
        query: String?,
        forceRefresh: Boolean,
    ): Result<List<Restaurant>> {
        val key = CacheKey(query, location)
        if (!forceRefresh) {
            val fresh = dbRead { cachedFor(key, freshOnly = true) }
            if (fresh.isNotEmpty()) return Result.success(withDistances(fresh, location, radiusKm))
        }
        val fetched = coreResult {
            backend.placesNearby(PlacesNearbyRequest(location.latitude, location.longitude, radiusKm, query?.trim()?.ifEmpty { null }))
        }
        fetched.onSuccess { response -> dbRead { store(key, response.restaurants) } }
        if (fetched.coreError is CoreError.Offline) {
            val stale = dbRead { cachedFor(key, freshOnly = false) }
            if (stale.isNotEmpty()) return Result.success(withDistances(stale, location, radiusKm))
        }
        return fetched.map { it.restaurants }
    }

    override suspend fun details(placeId: String): Result<Restaurant> {
        val fetched = coreResult { backend.placesDetails(placeId).restaurant }
        fetched.onSuccess { cacheAll(listOf(it)) }
        if (fetched.coreError is CoreError.Offline) cached(placeId)?.let { return Result.success(it) }
        return fetched
    }

    override suspend fun reviews(placeId: String): Result<List<RestaurantReview>> =
        coreResult { backend.placesDetails(placeId).reviews }

    override suspend fun cached(placeId: String): Restaurant? = dbRead {
        visiblePlaces[placeId] ?: db.restaurantsQueries.selectByPlaceId(placeId).executeAsOneOrNull()?.toRestaurant()?.takeIf { it.name != "Saved place" }
    }

    override suspend fun cacheAll(restaurants: List<Restaurant>) {
        if (restaurants.isEmpty()) return
        withContext(DbDispatcher) {
            val now = clock.nowEpochSeconds()
            db.transaction { restaurants.forEach { remember(it); db.restaurantsQueries.upsert(it, now) } }
        }
    }

    override suspend fun recordInteraction(userId: Long, placeId: String, restaurantName: String?, type: String, context: String?) {
        withContext(DbDispatcher) {
            db.userRestaurantInteractionsQueries.insert(
                user_id = userId,
                restaurant_place_id = placeId,
                restaurant_name = restaurantName,
                interaction_type = type,
                interaction_date = clock.nowEpochSeconds(),
                context = context,
            )
        }
    }

    /** Restaurants for the cache key in stored order; `freshOnly` honours `expires_at`. */
    private fun cachedFor(key: CacheKey, freshOnly: Boolean): List<Restaurant> {
        val ids = if (freshOnly) {
            db.restaurantCacheQueries.selectFresh(key.query, key.latitude, key.longitude, clock.nowEpochSeconds()).executeAsList()
        } else {
            db.restaurantCacheQueries.selectAny(key.query, key.latitude, key.longitude).executeAsList()
        }
        if (ids.isEmpty()) return emptyList()
        val byId = db.restaurantsQueries.selectByPlaceIds(ids).executeAsList().associateBy { it.place_id }
        return ids.mapNotNull { byId[it]?.toRestaurant()?.takeIf { place -> place.name != "Saved place" } }
    }

    private fun store(key: CacheKey, restaurants: List<Restaurant>) {
        val now = clock.nowEpochSeconds()
        db.transaction {
            db.restaurantCacheQueries.deleteForKey(key.query, key.latitude, key.longitude)
            restaurants.forEach { restaurant ->
                remember(restaurant)
                db.restaurantsQueries.upsert(restaurant, now)
                if (restaurant.googleMapsUri == null) db.restaurantCacheQueries.upsert(
                    place_id = restaurant.placeId,
                    search_query = key.query,
                    user_latitude = key.latitude,
                    user_longitude = key.longitude,
                    cached_at = now,
                    expires_at = now + CACHE_TTL_SECONDS,
                )
            }
        }
    }

    private fun remember(restaurant: Restaurant) {
        visiblePlaces[restaurant.placeId] = restaurant
        while (visiblePlaces.size > 100) visiblePlaces.remove(visiblePlaces.keys.first())
    }

    /** Cached rows carry the distance from an older request point; recompute and re-apply the radius. */
    private fun withDistances(restaurants: List<Restaurant>, location: Location, radiusKm: Double): List<Restaurant> =
        restaurants.mapNotNull { restaurant ->
            val lat = restaurant.latitude
            val lng = restaurant.longitude
            if (lat == null || lng == null) return@mapNotNull restaurant
            val distance = Geo.distanceKm(location.latitude, location.longitude, lat, lng)
            if (distance <= radiusKm) restaurant.copy(distanceFromUser = distance) else null
        }

    private class CacheKey(query: String?, location: Location) {
        val query: String = query?.trim()?.lowercase().orEmpty()
        val latitude: Double = Geo.roundCoordinate(location.latitude)
        val longitude: Double = Geo.roundCoordinate(location.longitude)
    }

    companion object {
        const val CACHE_TTL_SECONDS = 24 * 60 * 60L
    }
}
