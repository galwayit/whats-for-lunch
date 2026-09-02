package au.iapp.lunch.core.api

import au.iapp.lunch.core.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/*
 * Public surface of the shared core. Both apps talk to these interfaces only.
 * Implementations live in au.iapp.lunch.core.* and are wired by Koin.
 * Every suspending call returns Result<T>; failures are CoreError subclasses.
 */

/* ---------- Pure engines (no I/O, fully unit tested against fixtures) ---------- */

interface RecommendationEngine {
    /** Ported from HomeSearchNotifier._calculateCompatibilityScore. */
    fun compatibilityScore(restaurant: Restaurant, prefs: UserPreferences?): Double
    /** Best candidate above the 0.1 threshold, ignoring rejected place ids. */
    fun bestMatch(candidates: List<Restaurant>, prefs: UserPreferences?, rejected: Set<String>): Restaurant?
    /** Ported from HomeSearchNotifier.getRecommendationReasons. */
    fun reasons(restaurant: Restaurant, prefs: UserPreferences?): List<String>
    /** Ported from DiscoverPage._sortRestaurants. Stable sort. */
    fun sort(restaurants: List<Restaurant>, option: SortOption, prefs: UserPreferences?): List<Restaurant>
    /** Dietary, allergen, rating, and price filtering as DiscoveryNotifier applied it. */
    fun applyPreferenceFilters(restaurants: List<Restaurant>, prefs: UserPreferences?): List<Restaurant>
}

interface BudgetEngine {
    /** Monday 00:00 local of the week containing [epochSeconds]. */
    fun weekStart(epochSeconds: Long, timeZoneId: String): Long
    fun targetExperiences(prefs: UserPreferences): Int
    fun weeklyState(prefs: UserPreferences, mealsThisWeek: List<Meal>, weekStartEpochSeconds: Long): WeeklyBudgetState
    fun capacityUsageLevel(state: WeeklyBudgetState): ImpactLevel
    fun guidanceLevel(state: WeeklyBudgetState): GuidanceLevel
    /** Ported from WeeklyInvestmentNotifier.calculateMealImpact. */
    fun mealImpact(state: WeeklyBudgetState, mealCost: Double): MealImpact
    /** Ported from budgetImpactProvider (percentage of weekly budget). */
    fun budgetImpact(prefs: UserPreferences, cost: Double?): BudgetImpact
}

interface AchievementEngine {
    val catalogue: List<Achievement>
    /** Returns newly unlocked achievements given what is already unlocked. */
    fun evaluate(unlockedIds: Set<String>, weekly: WeeklyBudgetState, allMeals: List<Meal>, nowEpochSeconds: Long, timeZoneId: String): List<Achievement>
    fun level(points: Int): String
}

interface MealDefaults {
    fun smartMealType(hourOfDay: Int): String
    val categories: List<MealCategory>
    fun displayName(mealType: String): String
}

/* ---------- Repositories (local SQLite, same file as the Flutter app) ---------- */

interface UserRepository {
    val current: StateFlow<UserProfile?>
    suspend fun createUser(name: String, preferences: UserPreferences): Result<UserProfile>
    suspend fun updateName(name: String): Result<Unit>
    suspend fun updatePreferences(preferences: UserPreferences): Result<Unit>
    /** True once a real user exists; drives the onboarding redirect. */
    val hasCompletedOnboarding: StateFlow<Boolean>
}

interface MealRepository {
    suspend fun log(meal: Meal): Result<Long>
    suspend fun update(meal: Meal): Result<Unit>
    suspend fun delete(id: Long): Result<Unit>
    /** Meals whose date is inside [startEpochSeconds, endEpochSeconds). */
    suspend fun inRange(userId: Long, startEpochSeconds: Long, endEpochSeconds: Long): Result<List<Meal>>
    fun observeRecent(userId: Long, limit: Int, windowDays: Int?): Flow<List<Meal>>
    suspend fun restaurantSuggestions(userId: Long): Result<List<String>>
}

interface RestaurantRepository {
    /** Backend-backed nearby search with a 24h local cache keyed by rounded coordinates and query. */
    suspend fun searchNearby(location: Location, radiusKm: Double, query: String?, forceRefresh: Boolean): Result<List<Restaurant>>
    suspend fun details(placeId: String): Result<Restaurant>
    suspend fun reviews(placeId: String): Result<List<RestaurantReview>>
    suspend fun cached(placeId: String): Restaurant?
    suspend fun cacheAll(restaurants: List<Restaurant>)
    suspend fun recordInteraction(userId: Long, placeId: String, restaurantName: String?, type: String, context: String?)
}

interface FavouritesRepository {
    fun observe(userId: Long): Flow<Set<String>>
    /** Applies the free-tier limit through GateService. */
    suspend fun toggle(userId: Long, placeId: String, restaurantName: String?): Result<GateDecision>
    suspend fun favouriteRestaurants(userId: Long): Result<List<Restaurant>>
}

interface AchievementRepository {
    fun observe(userId: Long): Flow<List<Achievement>>
    suspend fun unlock(userId: Long, achievements: List<Achievement>)
}

/* ---------- Services (backend, purchases, auth, social) ---------- */

interface AiRecommendationService {
    /**
     * Calls the backend, which enforces the daily quota and picks the model by tier.
     * The client also pre-checks GateService so the paywall shows without a round trip.
     */
    suspend fun recommend(cravings: String?, maxResults: Int, candidates: List<Restaurant>): Result<AiRecommendation>
    suspend fun history(userId: Long, limit: Int): Result<List<AiRecommendation>>
    suspend fun submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Boolean): Result<Unit>
    /** Requests made today by this user, for the gate row copy. */
    suspend fun usedToday(userId: Long): Int
}

interface EntitlementRepository {
    val isPro: StateFlow<Boolean>
    val status: StateFlow<SubscriptionStatus>
    suspend fun offerings(): Result<ProOfferings>
    suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus>
    suspend fun restore(): Result<SubscriptionStatus>
    /** Called after Supabase sign-in so purchases follow the account. */
    suspend fun logIn(userId: String): Result<Unit>
    suspend fun logOut(): Result<Unit>
    /** Stable RevenueCat app user id, anonymous until logIn. Sent to the backend as x-app-user-id. */
    val appUserId: StateFlow<String>
}

interface GateService {
    suspend fun canRequestAi(): GateDecision
    fun canAddFavourite(currentCount: Int): GateDecision
    /** null means unlimited history. */
    fun historyWindowDays(): Int?
    fun canHostGroup(): GateDecision
}

interface AuthRepository {
    val session: StateFlow<AuthSession?>
    suspend fun signInWithApple(idToken: String, nonce: String, fullName: String?): Result<AuthSession>
    suspend fun signInWithGoogle(idToken: String): Result<AuthSession>
    suspend fun signOut(): Result<Unit>
    suspend fun deleteAccount(): Result<Unit>
}

interface GroupRepository {
    fun myGroups(): Flow<List<LunchGroup>>
    /** Host only. Backend verifies the Pro entitlement. */
    suspend fun create(name: String, scheduledAtEpochSeconds: Long, area: Location, radiusKm: Double): Result<LunchGroup>
    suspend fun propose(groupId: String): Result<List<GroupProposal>>
    suspend fun confirmPlace(groupId: String, restaurant: Restaurant): Result<LunchGroup>
    suspend fun invitation(code: String): Result<Invitation>
    suspend fun respond(code: String, status: RsvpStatus, displayName: String?): Result<Invitation>
    fun rsvps(groupId: String): Flow<List<Rsvp>>
    suspend fun cancel(groupId: String): Result<Unit>
}

interface PushRegistrar {
    suspend fun register(token: String, platform: String): Result<Unit>
}

/* ---------- Platform-provided (expect/actual or injected by the app) ---------- */

interface LocationProvider {
    suspend fun current(): Result<Location>
    suspend fun hasPermission(): Boolean
}

interface Clock {
    fun nowEpochSeconds(): Long
    fun timeZoneId(): String
}

/* ---------- Facade ---------- */

data class CoreConfig(
    val supabaseUrl: String,
    val supabaseAnonKey: String,
    val backendBaseUrl: String,
    val revenueCatApiKey: String,
    /** Absolute path to diet_buddy.sqlite in the app documents directory. */
    val databasePath: String,
    val inviteLinkBase: String = "https://lunch.iapp.au/i/",
    val isDebug: Boolean = false,
)

/**
 * Entry point. Apps call LunchCore.start(config, locationProvider) once, then
 * resolve services through the properties. Implemented in au.iapp.lunch.core.LunchCoreImpl.
 */
interface LunchCore {
    val users: UserRepository
    val meals: MealRepository
    val restaurants: RestaurantRepository
    val favourites: FavouritesRepository
    val achievements: AchievementRepository
    val ai: AiRecommendationService
    val entitlements: EntitlementRepository
    val gates: GateService
    val auth: AuthRepository
    val groups: GroupRepository
    val push: PushRegistrar
    val recommendation: RecommendationEngine
    val budget: BudgetEngine
    val achievementEngine: AchievementEngine
    val mealDefaults: MealDefaults
    val clock: Clock
}
