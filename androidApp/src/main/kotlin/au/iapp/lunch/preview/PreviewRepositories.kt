/**
 * @file PreviewRepositories.kt
 * @description In-memory repositories for [PreviewLunchCore]: users, meals, restaurants,
 * favourites and achievements over the [PreviewCoreData] seed. Behaviour mirrors
 * iosApp/LunchApp/Core/Preview/PreviewRepositories.swift so the two apps demo identically.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.preview

import au.iapp.lunch.core.api.AchievementRepository
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.FavouritesRepository
import au.iapp.lunch.core.api.GateService
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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

/** Single demo user; `createUser` always yields [PreviewCoreData.USER_ID] like the iOS preview. */
class PreviewUserRepository(initial: UserProfile?, private val clock: Clock) : UserRepository {
    private val profile = MutableStateFlow(initial)
    override val current: StateFlow<UserProfile?> = profile.asStateFlow()
    override val hasCompletedOnboarding: StateFlow<Boolean>
        get() = onboarded
    private val onboarded = MutableStateFlow(initial != null)

    override suspend fun createUser(name: String, preferences: UserPreferences): Result<UserProfile> {
        val user = UserProfile(PreviewCoreData.USER_ID, name, preferences, clock.nowEpochSeconds())
        profile.value = user
        onboarded.value = true
        return Result.success(user)
    }

    override suspend fun updateName(name: String): Result<Unit> = mutate { it.copy(name = name) }

    override suspend fun updatePreferences(preferences: UserPreferences): Result<Unit> =
        mutate { it.copy(preferences = preferences) }

    private fun mutate(transform: (UserProfile) -> UserProfile): Result<Unit> {
        val user = profile.value ?: return Result.failure(CoreError.Service("NO_USER", "No user yet"))
        profile.value = transform(user)
        return Result.success(Unit)
    }
}

class PreviewMealRepository(seed: List<Meal>) : MealRepository {
    private val meals = MutableStateFlow(seed)

    /** Every meal, newest first; exposed for tests and the budget ring. */
    val all: StateFlow<List<Meal>> = meals.asStateFlow()

    override suspend fun log(meal: Meal): Result<Long> {
        val id = meal.id ?: ((meals.value.mapNotNull { it.id }.maxOrNull() ?: 0L) + 1)
        meals.update { it + meal.copy(id = id) }
        return Result.success(id)
    }

    override suspend fun update(meal: Meal): Result<Unit> {
        meals.update { list -> list.map { if (it.id == meal.id) meal else it } }
        return Result.success(Unit)
    }

    override suspend fun delete(id: Long): Result<Unit> {
        meals.update { list -> list.filterNot { it.id == id } }
        return Result.success(Unit)
    }

    override suspend fun inRange(userId: Long, start: Long, end: Long): Result<List<Meal>> =
        Result.success(
            meals.value
                .filter { it.userId == userId && it.dateEpochSeconds in start..<end }
                .sortedByDescending { it.dateEpochSeconds },
        )

    override fun observeRecent(userId: Long, limit: Int, windowDays: Int?): Flow<List<Meal>> = meals.map { list ->
        val cutoff = windowDays?.let { PreviewClockAccess.now() - it * SECONDS_PER_DAY }
        list.filter { it.userId == userId && (cutoff == null || it.dateEpochSeconds >= cutoff) }
            .sortedByDescending { it.dateEpochSeconds }
            .take(limit)
    }

    override suspend fun restaurantSuggestions(userId: Long): Result<List<String>> =
        Result.success(
            meals.value.filter { it.userId == userId }
                .sortedByDescending { it.dateEpochSeconds }
                .mapNotNull { it.restaurantName }
                .distinct(),
        )

    private companion object {
        const val SECONDS_PER_DAY = 86_400L
    }
}

/**
 * The preview meal repository needs "now" for the 30-day window without a clock in every
 * flow; [PreviewLunchCore] installs its clock here.
 */
internal object PreviewClockAccess {
    @Volatile
    var clock: Clock? = null

    fun now(): Long = clock?.nowEpochSeconds() ?: (System.currentTimeMillis() / 1_000)
}

class PreviewRestaurantRepository(seed: List<Restaurant>, private val network: PreviewNetwork) : RestaurantRepository {
    private val cache = MutableStateFlow(seed.associateBy { it.placeId })

    /** Everything in the cache, in seed order first. */
    val all: List<Restaurant> get() = cache.value.values.toList()

    override suspend fun searchNearby(
        location: Location,
        radiusKm: Double,
        query: String?,
        forceRefresh: Boolean,
    ): Result<List<Restaurant>> = network.call {
        val needle = query?.trim()?.lowercase().orEmpty()
        all.map { it.copy(distanceFromUser = distanceKm(location, it)) }
            .filter { (it.distanceFromUser ?: Double.MAX_VALUE) <= radiusKm }
            .filter { needle.isEmpty() || it.name.lowercase().contains(needle) || it.cuisineTypes.any { c -> c.lowercase().contains(needle) } }
            .sortedBy { it.distanceFromUser }
    }

    override suspend fun details(placeId: String): Result<Restaurant> = network.call {
        cache.value[placeId] ?: throw CoreError.Service("NOT_FOUND", "No restaurant $placeId")
    }

    override suspend fun reviews(placeId: String): Result<List<RestaurantReview>> = network.call {
        if (placeId == PreviewCoreData.sakuraSushi.placeId) emptyList() else PreviewCoreData.reviews
    }

    override suspend fun cached(placeId: String): Restaurant? = cache.value[placeId]

    override suspend fun cacheAll(restaurants: List<Restaurant>) {
        cache.update { it + restaurants.associateBy { r -> r.placeId } }
    }

    override suspend fun recordInteraction(userId: Long, placeId: String, restaurantName: String?, type: String, context: String?) = Unit

    /** Haversine distance from [from] to the restaurant, rounded to one decimal like the real core. */
    private fun distanceKm(from: Location, restaurant: Restaurant): Double? {
        val lat = restaurant.latitude ?: return restaurant.distanceFromUser
        val lng = restaurant.longitude ?: return restaurant.distanceFromUser
        val dLat = Math.toRadians(lat - from.latitude)
        val dLng = Math.toRadians(lng - from.longitude)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(Math.toRadians(from.latitude)) * cos(Math.toRadians(lat)) * sin(dLng / 2) * sin(dLng / 2)
        val km = 2 * EARTH_RADIUS_KM * asin(sqrt(a))
        return (km * 10).roundToInt() / 10.0
    }

    private companion object {
        const val EARTH_RADIUS_KM = 6_371.0
    }
}

class PreviewFavouritesRepository(
    private val restaurants: PreviewRestaurantRepository,
    private val gates: () -> GateService,
) : FavouritesRepository {
    private val ids = MutableStateFlow<Set<String>>(emptySet())

    override fun observe(userId: Long): Flow<Set<String>> = ids

    override suspend fun toggle(userId: Long, placeId: String, restaurantName: String?): Result<GateDecision> {
        if (placeId in ids.value) {
            ids.update { it - placeId }
            return Result.success(GateDecision.Allowed)
        }
        val decision = gates().canAddFavourite(ids.value.size)
        if (decision.allowed) ids.update { it + placeId }
        return Result.success(decision)
    }

    override suspend fun favouriteRestaurants(userId: Long): Result<List<Restaurant>> =
        Result.success(ids.value.mapNotNull { restaurants.cached(it) })
}

class PreviewAchievementRepository : AchievementRepository {
    private val unlocked = MutableStateFlow<List<Achievement>>(emptyList())

    override fun observe(userId: Long): Flow<List<Achievement>> = unlocked

    override suspend fun unlock(userId: Long, achievements: List<Achievement>) {
        unlocked.update { current ->
            val known = current.map { it.id }.toSet()
            current + achievements.filterNot { it.id in known }
        }
    }
}
