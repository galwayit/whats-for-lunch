package au.iapp.lunch.core

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
import org.koin.core.Koin

/**
 * [LunchCore] backed by an isolated Koin container. Services are resolved
 * lazily so opening the database and configuring the store SDK happen on first
 * use rather than at construction.
 */
internal class LunchCoreImpl(private val koin: Koin) : LunchCore {
    override val users: UserRepository by lazy { koin.get() }
    override val meals: MealRepository by lazy { koin.get() }
    override val restaurants: RestaurantRepository by lazy { koin.get() }
    override val favourites: FavouritesRepository by lazy { koin.get() }
    override val achievements: AchievementRepository by lazy { koin.get() }
    override val ai: AiRecommendationService by lazy { koin.get() }
    override val entitlements: EntitlementRepository by lazy { koin.get() }
    override val gates: GateService by lazy { koin.get() }
    override val auth: AuthRepository by lazy { koin.get() }
    override val groups: GroupRepository by lazy { koin.get() }
    override val push: PushRegistrar by lazy { koin.get() }
    override val recommendation: RecommendationEngine by lazy { koin.get() }
    override val budget: BudgetEngine by lazy { koin.get() }
    override val achievementEngine: AchievementEngine by lazy { koin.get() }
    override val mealDefaults: MealDefaults by lazy { koin.get() }
    override val clock: Clock by lazy { koin.get() }
}
