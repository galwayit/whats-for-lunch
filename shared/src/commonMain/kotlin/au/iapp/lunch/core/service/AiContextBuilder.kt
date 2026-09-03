package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.MealDefaults
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.network.AiContext
import au.iapp.lunch.core.network.DietaryContext
import au.iapp.lunch.core.network.LocationContext
import au.iapp.lunch.core.network.TemporalContext
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.isoDayNumber
import kotlinx.datetime.toLocalDateTime
import kotlin.math.roundToLong

/**
 * Builds the `context` object of POST /ai-recommend the way
 * UserContextService did in the Flutter app: budget as dollar signs, recent
 * meals as one-line summaries with relative times, and a couple of preference
 * scores derived from spending.
 */
internal class AiContextBuilder(
    private val mealDefaults: MealDefaults,
    private val clock: Clock,
) {

    fun build(prefs: UserPreferences, recentMeals: List<Meal>, location: Location?): AiContext {
        val now = clock.nowEpochSeconds()
        val zone = TimeZone.of(clock.timeZoneId())
        val local = Instant.fromEpochSeconds(now).toLocalDateTime(zone)
        val dayOfWeek = local.dayOfWeek.isoDayNumber
        return AiContext(
            mealType = mealDefaults.smartMealType(local.hour),
            budgetRange = "$".repeat(prefs.budgetLevel.coerceIn(1, 4)),
            dietaryPreferences = DietaryContext(prefs.dietaryRestrictions, prefs.allergens),
            recentMeals = recentMeals.take(MAX_RECENT_MEALS).map { summarise(it, now) },
            location = LocationContext(location != null, location?.latitude, location?.longitude),
            temporal = TemporalContext(local.hour, dayOfWeek, dayOfWeek >= 6),
            preferenceScores = preferenceScores(recentMeals),
        )
    }

    /** e.g. "Lunch: $18.50 (1d ago)". */
    private fun summarise(meal: Meal, nowEpochSeconds: Long): String =
        "${mealDefaults.displayName(meal.mealType)}: $${formatCost(meal.cost)} (${relativeTime(nowEpochSeconds - meal.dateEpochSeconds)})"

    private fun relativeTime(ageSeconds: Long): String {
        val age = ageSeconds.coerceAtLeast(0)
        return when {
            age >= SECONDS_PER_DAY -> "${age / SECONDS_PER_DAY}d ago"
            age >= SECONDS_PER_HOUR -> "${age / SECONDS_PER_HOUR}h ago"
            else -> "${age / 60}m ago"
        }
    }

    private fun formatCost(cost: Double): String {
        val cents = (cost * 100).roundToLong()
        return "${cents / 100}.${(cents % 100).toString().padStart(2, '0')}"
    }

    /** price_sensitivity rises when the user usually spends well under their own maximum. */
    private fun preferenceScores(meals: List<Meal>): Map<String, Double> {
        val costs = meals.map { it.cost }.filter { it > 0 }
        val sensitivity = if (costs.isEmpty()) DEFAULT_PRICE_SENSITIVITY else {
            val max = costs.max()
            (max - costs.average()) / max
        }
        return mapOf("price_sensitivity" to sensitivity, "quality_over_price" to 1.0 - sensitivity)
    }

    companion object {
        const val MAX_RECENT_MEALS = 10
        const val DEFAULT_PRICE_SENSITIVITY = 0.7
        private const val SECONDS_PER_HOUR = 3_600L
        private const val SECONDS_PER_DAY = 86_400L
    }
}
