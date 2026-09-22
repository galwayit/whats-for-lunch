/**
 * @file PreviewLunchCore.kt
 * @description An in-memory [LunchCore] seeded with [PreviewCoreData] and driven by launch flags.
 * Selected with `--ez previewCore true`; also the core under the view-model unit tests and the
 * screenshot runs. Uses the real shared engines (recommendation, budget, achievements, meal
 * defaults) so only network-backed behaviour is simulated. Mirrors
 * iosApp/LunchApp/Core/Preview/PreviewLunchCore.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.preview

import au.iapp.lunch.core.api.AchievementEngine
import au.iapp.lunch.core.api.AchievementRepository
import au.iapp.lunch.core.api.AiRecommendationService
import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.BudgetEngine
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.api.FavouritesRepository
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.api.GroupRepository
import au.iapp.lunch.core.api.LunchCore
import au.iapp.lunch.core.api.MealDefaults
import au.iapp.lunch.core.api.MealRepository
import au.iapp.lunch.core.api.PushRegistrar
import au.iapp.lunch.core.api.RecommendationEngine
import au.iapp.lunch.core.api.RestaurantRepository
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.engine.AchievementEngineImpl
import au.iapp.lunch.core.engine.BudgetEngineImpl
import au.iapp.lunch.core.engine.MealDefaultsImpl
import au.iapp.lunch.core.engine.RecommendationEngineImpl
import au.iapp.lunch.core.platform.SystemClock
import java.time.ZoneId

/** What the preview core starts as; every flag maps to a launch extra of the same name. */
data class PreviewCoreOptions(
    val isPro: Boolean = false,
    val isSignedIn: Boolean = false,
    val isOffline: Boolean = false,
    val aiUsedToday: Boolean = false,
    val isOnboarded: Boolean = true,
    /** Simulated latency per call; tests pass 0. */
    val latencyMs: Long = PreviewNetwork.DEFAULT_LATENCY_MS,
)

class PreviewLunchCore(
    options: PreviewCoreOptions = PreviewCoreOptions(),
    override val clock: Clock = SystemClock,
) : LunchCore {
    /** Flip at runtime to simulate losing or regaining connectivity. */
    @Volatile
    var isOffline: Boolean = options.isOffline

    private val network = PreviewNetwork(isOffline = { isOffline }, latencyMs = options.latencyMs)
    private val zone: ZoneId = runCatching { ZoneId.of(clock.timeZoneId()) }.getOrDefault(ZoneId.systemDefault())

    override val recommendation: RecommendationEngine = RecommendationEngineImpl()
    override val budget: BudgetEngine = BudgetEngineImpl()
    override val achievementEngine: AchievementEngine = AchievementEngineImpl()
    override val mealDefaults: MealDefaults = MealDefaultsImpl()

    override val users: UserRepository = PreviewUserRepository(if (options.isOnboarded) PreviewCoreData.user else null, clock)
    override val meals: MealRepository = PreviewMealRepository(PreviewCoreData.meals(clock.nowEpochSeconds(), zone))
    override val entitlements: EntitlementRepository = PreviewEntitlementRepository(network, options.isPro, clock)
    override val auth: AuthRepository = PreviewAuthRepository(network, options.isSignedIn)
    private val gateService = PreviewGateService(
        isPro = { entitlements.isPro.value },
        session = { auth.session.value },
        aiUsedToday = options.aiUsedToday,
    )
    override val gates: GateService = gateService
    private val restaurantRepository = PreviewRestaurantRepository(PreviewCoreData.restaurants, network)
    override val restaurants: RestaurantRepository = restaurantRepository
    override val favourites: FavouritesRepository = PreviewFavouritesRepository(restaurantRepository) { gates }
    override val achievements: AchievementRepository = PreviewAchievementRepository()
    override val ai: AiRecommendationService = PreviewAiService(
        network = network,
        gates = gateService,
        engine = recommendation,
        allRestaurants = { restaurantRepository.all },
        preferences = { users.current.value?.preferences },
        clock = clock,
    )
    override val groups: GroupRepository = PreviewGroupRepository(
        network = network,
        session = { auth.session.value },
        engine = recommendation,
        preferences = { users.current.value?.preferences },
        searchNearby = { area, radius -> restaurantRepository.searchNearby(area, radius, null, false).getOrThrow() },
        clock = clock,
        seedGroup = PreviewCoreData.group(clock.nowEpochSeconds(), zone),
        seedRsvps = PreviewCoreData.rsvps,
    )
    override val push: PushRegistrar = PreviewPushRegistrar()

    init {
        PreviewClockAccess.clock = clock
    }
}
