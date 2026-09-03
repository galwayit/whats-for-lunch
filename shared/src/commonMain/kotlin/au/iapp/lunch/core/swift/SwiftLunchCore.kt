/**
 * @file SwiftLunchCore.kt
 * @description Swift-facing facade over LunchCore: the same property names, but the
 * Result-returning repositories and services are replaced by their throwing wrappers.
 * GateService, the pure engines and the clock are exposed unchanged.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.api.AchievementEngine
import au.iapp.lunch.core.api.BudgetEngine
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.api.LunchCore
import au.iapp.lunch.core.api.MealDefaults
import au.iapp.lunch.core.api.RecommendationEngine

/**
 * Wraps a started [LunchCore] for Swift. Wrappers are created lazily so the
 * underlying core keeps its own lazy resolution: nothing opens the database or
 * configures the store SDK until a property is first read.
 *
 * There is no `close()` because [LunchCore] has none; keep one instance for the
 * life of the app, as the Kotlin apps do.
 */
class SwiftLunchCore(private val core: LunchCore) {
    val users: SwiftUserRepository by lazy { SwiftUserRepository(core.users) }
    val meals: SwiftMealRepository by lazy { SwiftMealRepository(core.meals) }
    val restaurants: SwiftRestaurantRepository by lazy { SwiftRestaurantRepository(core.restaurants) }
    val favourites: SwiftFavouritesRepository by lazy { SwiftFavouritesRepository(core.favourites) }
    val achievements: SwiftAchievementRepository by lazy { SwiftAchievementRepository(core.achievements) }
    val ai: SwiftAiRecommendationService by lazy { SwiftAiRecommendationService(core.ai) }
    val entitlements: SwiftEntitlementRepository by lazy { SwiftEntitlementRepository(core.entitlements) }
    val auth: SwiftAuthRepository by lazy { SwiftAuthRepository(core.auth) }
    val groups: SwiftGroupRepository by lazy { SwiftGroupRepository(core.groups) }
    val push: SwiftPushRegistrar by lazy { SwiftPushRegistrar(core.push) }

    /** No Result members: `canRequestAi` already comes out typed through SKIE. */
    val gates: GateService get() = core.gates
    val recommendation: RecommendationEngine get() = core.recommendation
    val budget: BudgetEngine get() = core.budget
    val achievementEngine: AchievementEngine get() = core.achievementEngine
    val mealDefaults: MealDefaults get() = core.mealDefaults
    val clock: Clock get() = core.clock
}
