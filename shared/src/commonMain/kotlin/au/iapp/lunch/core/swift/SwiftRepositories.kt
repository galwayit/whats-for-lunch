/**
 * @file SwiftRepositories.kt
 * @description Throwing wrappers over the repository contracts (users, meals,
 * restaurants, favourites, achievements). Each `suspend fun f(): Result<T>` of the
 * wrapped interface becomes `@Throws suspend fun f(): T`; Flow members and plain
 * members pass straight through. Names and parameter names match the contract.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.api.AchievementRepository
import au.iapp.lunch.core.api.FavouritesRepository
import au.iapp.lunch.core.api.MealRepository
import au.iapp.lunch.core.api.RestaurantRepository
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.model.Achievement
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateDecision
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.model.UserProfile
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/** Swift view of [UserRepository]. */
class SwiftUserRepository(private val users: UserRepository) {
    val current: StateFlow<UserProfile?> get() = users.current

    /** True once a real user exists; drives the onboarding redirect. */
    val hasCompletedOnboarding: StateFlow<Boolean> get() = users.hasCompletedOnboarding

    @Throws(CoreError::class, CancellationException::class)
    suspend fun createUser(name: String, preferences: UserPreferences): UserProfile =
        unwrap { users.createUser(name, preferences) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun updateName(name: String) {
        unwrap { users.updateName(name) }
    }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun updatePreferences(preferences: UserPreferences) {
        unwrap { users.updatePreferences(preferences) }
    }
}

/** Swift view of [MealRepository]. */
class SwiftMealRepository(private val meals: MealRepository) {
    @Throws(CoreError::class, CancellationException::class)
    suspend fun log(meal: Meal): Long = unwrap { meals.log(meal) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun update(meal: Meal) {
        unwrap { meals.update(meal) }
    }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun delete(id: Long) {
        unwrap { meals.delete(id) }
    }

    /** Meals whose date is inside [startEpochSeconds, endEpochSeconds). */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun inRange(userId: Long, startEpochSeconds: Long, endEpochSeconds: Long): List<Meal> =
        unwrap { meals.inRange(userId, startEpochSeconds, endEpochSeconds) }

    fun observeRecent(userId: Long, limit: Int, windowDays: Int?): Flow<List<Meal>> =
        meals.observeRecent(userId, limit, windowDays)

    @Throws(CoreError::class, CancellationException::class)
    suspend fun restaurantSuggestions(userId: Long): List<String> = unwrap { meals.restaurantSuggestions(userId) }
}

/** Swift view of [RestaurantRepository]. */
class SwiftRestaurantRepository(private val restaurants: RestaurantRepository) {
    /** Backend-backed nearby search with a 24h local cache keyed by rounded coordinates and query. */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun searchNearby(location: Location, radiusKm: Double, query: String?, forceRefresh: Boolean): List<Restaurant> =
        unwrap { restaurants.searchNearby(location, radiusKm, query, forceRefresh) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun details(placeId: String): Restaurant = unwrap { restaurants.details(placeId) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun reviews(placeId: String): List<RestaurantReview> = unwrap { restaurants.reviews(placeId) }

    suspend fun cached(placeId: String): Restaurant? = restaurants.cached(placeId)

    suspend fun cacheAll(restaurants: List<Restaurant>) = this.restaurants.cacheAll(restaurants)

    suspend fun recordInteraction(userId: Long, placeId: String, restaurantName: String?, type: String, context: String?) =
        restaurants.recordInteraction(userId, placeId, restaurantName, type, context)
}

/** Swift view of [FavouritesRepository]. */
class SwiftFavouritesRepository(private val favourites: FavouritesRepository) {
    fun observe(userId: Long): Flow<Set<String>> = favourites.observe(userId)

    /** Applies the free-tier limit through GateService. */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun toggle(userId: Long, placeId: String, restaurantName: String?): GateDecision =
        unwrap { favourites.toggle(userId, placeId, restaurantName) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun favouriteRestaurants(userId: Long): List<Restaurant> = unwrap { favourites.favouriteRestaurants(userId) }
}

/** Swift view of [AchievementRepository]. */
class SwiftAchievementRepository(private val achievements: AchievementRepository) {
    fun observe(userId: Long): Flow<List<Achievement>> = achievements.observe(userId)

    suspend fun unlock(userId: Long, achievements: List<Achievement>) = this.achievements.unlock(userId, achievements)
}
