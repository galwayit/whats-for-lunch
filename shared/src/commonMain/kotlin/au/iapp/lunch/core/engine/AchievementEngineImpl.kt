package au.iapp.lunch.core.engine

import au.iapp.lunch.core.api.AchievementEngine
import au.iapp.lunch.core.model.Achievement
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.WeeklyBudgetState
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.daysUntil
import kotlinx.datetime.toLocalDateTime

/**
 * Pure port of `AchievementNotifier` (budget_providers.dart): the catalogue,
 * the unlock rules in `checkAchievements`, and `_calculateLevel`.
 *
 * `smart_spender` has no unlock rule in the Flutter app either; it stays in
 * the catalogue but is never unlocked automatically.
 */
class AchievementEngineImpl : AchievementEngine {

    override val catalogue: List<Achievement> = listOf(
        Achievement("first_experience", "First Investment", "Log your first dining experience", "Getting Started", 10, "celebration"),
        Achievement("week_optimizer", "Weekly Optimizer", "Stay within 80% of weekly capacity for a full week", "Budget Management", 25, "eco"),
        Achievement("experience_explorer", "Experience Explorer", "Try 5 different types of dining experiences", "Diversity", 20, "explore"),
        Achievement("consistent_tracker", "Consistent Tracker", "Log experiences for 7 consecutive days", "Consistency", 30, "calendar_today"),
        Achievement("smart_spender", "Smart Investor", "Complete a month with optimal investment distribution", "Budget Management", 50, "psychology"),
    )

    override fun evaluate(
        unlockedIds: Set<String>,
        weekly: WeeklyBudgetState,
        allMeals: List<Meal>,
        nowEpochSeconds: Long,
        timeZoneId: String,
    ): List<Achievement> {
        val unlocked = ArrayList<Achievement>()
        fun unlock(id: String) {
            val template = catalogue.first { it.id == id }
            unlocked.add(template.copy(isUnlocked = true, unlockedAtEpochSeconds = nowEpochSeconds))
        }

        if ("first_experience" !in unlockedIds && allMeals.isNotEmpty()) {
            unlock("first_experience")
        }
        if ("week_optimizer" !in unlockedIds &&
            weekly.capacityProgress <= WEEK_OPTIMIZER_MAX_PROGRESS &&
            weekly.experiencesLogged >= WEEK_OPTIMIZER_MIN_EXPERIENCES
        ) {
            unlock("week_optimizer")
        }
        if ("experience_explorer" !in unlockedIds) {
            val uniqueTypes = allMeals.map { it.mealType }.toSet()
            if (uniqueTypes.size >= EXPLORER_UNIQUE_TYPES) unlock("experience_explorer")
        }
        if ("consistent_tracker" !in unlockedIds && hasConsecutiveDays(allMeals, CONSISTENT_DAYS, timeZoneId)) {
            unlock("consistent_tracker")
        }
        return unlocked
    }

    override fun level(points: Int): String = when {
        points < 50 -> "Beginner"
        points < 150 -> "Explorer"
        points < 300 -> "Optimizer"
        points < 500 -> "Expert"
        else -> "Master"
    }

    /** True when the meals cover [days] consecutive local calendar days. */
    private fun hasConsecutiveDays(meals: List<Meal>, days: Int, timeZoneId: String): Boolean {
        if (meals.size < days) return false
        val zone = TimeZone.of(timeZoneId)
        val dates: List<LocalDate> = meals
            .map { Instant.fromEpochSeconds(it.dateEpochSeconds).toLocalDateTime(zone).date }
            .toSet()
            .sorted()
        var consecutive = 1
        for (i in 1 until dates.size) {
            if (dates[i - 1].daysUntil(dates[i]) == 1) {
                consecutive++
                if (consecutive >= days) return true
            } else {
                consecutive = 1
            }
        }
        return false
    }

    private companion object {
        const val WEEK_OPTIMIZER_MAX_PROGRESS = 0.8
        const val WEEK_OPTIMIZER_MIN_EXPERIENCES = 5
        const val EXPLORER_UNIQUE_TYPES = 5
        const val CONSISTENT_DAYS = 7
    }
}
