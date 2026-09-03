package au.iapp.lunch.core.engine

import au.iapp.lunch.core.api.BudgetEngine
import au.iapp.lunch.core.model.BudgetImpact
import au.iapp.lunch.core.model.GuidanceLevel
import au.iapp.lunch.core.model.ImpactLevel
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.MealImpact
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.model.WeeklyBudgetState
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.isoDayNumber
import kotlinx.datetime.minus
import kotlinx.datetime.toLocalDateTime
import kotlin.math.roundToInt

/**
 * Pure port of `WeeklyInvestmentNotifier` / `WeeklyInvestmentState`
 * (budget_providers.dart) and `budgetImpactProvider` (meal_providers.dart).
 *
 * Week math uses an explicit IANA zone; weeks start on Monday 00:00 local.
 * Unlike the Dart original (which subtracted 24h multiples), a DST change
 * inside the week still yields exactly local midnight.
 */
class BudgetEngineImpl : BudgetEngine {

    override fun weekStart(epochSeconds: Long, timeZoneId: String): Long {
        val zone = TimeZone.of(timeZoneId)
        val date = Instant.fromEpochSeconds(epochSeconds).toLocalDateTime(zone).date
        val monday = date.minus(date.dayOfWeek.isoDayNumber - 1, DateTimeUnit.DAY)
        return monday.atStartOfDayIn(zone).epochSeconds
    }

    override fun targetExperiences(prefs: UserPreferences): Int {
        val baseTarget = prefs.mealFrequencyPerDay * 7
        val budgetMultiplier = prefs.budgetLevel / 4.0
        return (baseTarget * budgetMultiplier).roundToInt().coerceIn(MIN_TARGET, MAX_TARGET)
    }

    override fun weeklyState(prefs: UserPreferences, mealsThisWeek: List<Meal>, weekStartEpochSeconds: Long): WeeklyBudgetState {
        var currentSpent = 0.0
        for (meal in mealsThisWeek) currentSpent += meal.cost
        val remaining = (prefs.weeklyBudget - currentSpent).coerceAtLeast(0.0)
        return WeeklyBudgetState(
            weeklyCapacity = prefs.weeklyBudget,
            currentSpent = currentSpent,
            remainingCapacity = remaining,
            experiencesLogged = mealsThisWeek.size,
            targetExperiences = targetExperiences(prefs),
            weekStartEpochSeconds = weekStartEpochSeconds,
        )
    }

    override fun capacityUsageLevel(state: WeeklyBudgetState): ImpactLevel {
        val progress = state.capacityProgress
        return when {
            progress < 0.3 -> ImpactLevel.LOW
            progress < 0.7 -> ImpactLevel.MODERATE
            progress < 0.9 -> ImpactLevel.HIGH
            else -> ImpactLevel.VERY_HIGH
        }
    }

    override fun guidanceLevel(state: WeeklyBudgetState): GuidanceLevel {
        val progress = state.capacityProgress
        return when {
            progress < 0.5 -> GuidanceLevel.EXCELLENT
            progress < 0.8 -> GuidanceLevel.GOOD
            progress < 0.95 -> GuidanceLevel.MODERATE
            else -> GuidanceLevel.HIGH
        }
    }

    override fun mealImpact(state: WeeklyBudgetState, mealCost: Double): MealImpact {
        val totalAfterMeal = state.currentSpent + mealCost
        val capacityAfterMeal = totalAfterMeal / state.weeklyCapacity
        val impactLevel: ImpactLevel
        val guidanceLevel: GuidanceLevel
        val message: String
        when {
            capacityAfterMeal < 0.3 -> {
                impactLevel = ImpactLevel.LOW
                guidanceLevel = GuidanceLevel.EXCELLENT
                message = "Perfect! This investment keeps you well within your comfort zone."
            }
            capacityAfterMeal < 0.7 -> {
                impactLevel = ImpactLevel.MODERATE
                guidanceLevel = GuidanceLevel.GOOD
                message = "Great balance between enjoyment and your weekly investment goals."
            }
            capacityAfterMeal < 0.9 -> {
                impactLevel = ImpactLevel.HIGH
                guidanceLevel = GuidanceLevel.MODERATE
                message = "This is a significant investment. Make sure it aligns with your priorities."
            }
            else -> {
                impactLevel = ImpactLevel.VERY_HIGH
                guidanceLevel = GuidanceLevel.HIGH
                message = "This investment will exceed your weekly capacity. Consider adjusting the amount."
            }
        }
        return MealImpact(
            mealCost = mealCost,
            projectedSpent = totalAfterMeal,
            projectedRemaining = (state.weeklyCapacity - totalAfterMeal).coerceAtLeast(0.0),
            impactLevel = impactLevel,
            guidanceLevel = guidanceLevel,
            message = message,
            exceedsCapacity = totalAfterMeal > state.weeklyCapacity,
        )
    }

    override fun budgetImpact(prefs: UserPreferences, cost: Double?): BudgetImpact {
        val weeklyBudget = prefs.weeklyBudget
        if (cost == null || weeklyBudget <= 0) return NO_IMPACT
        val percentage = (cost / weeklyBudget) * 100
        val impactLevel: ImpactLevel
        val message: String
        when {
            percentage < 5 -> {
                impactLevel = ImpactLevel.LOW
                message = "Great choice! This experience fits well within your weekly investment plan."
            }
            percentage < 15 -> {
                impactLevel = ImpactLevel.MODERATE
                message = "Nice balance between enjoyment and your weekly goals."
            }
            percentage < 25 -> {
                impactLevel = ImpactLevel.HIGH
                message = "A special experience - make sure it aligns with your priorities."
            }
            else -> {
                impactLevel = ImpactLevel.VERY_HIGH
                message = "This is a significant investment in your dining experience."
            }
        }
        return BudgetImpact(
            percentageOfWeeklyBudget = percentage,
            impactLevel = impactLevel,
            message = message,
            remainingBudget = weeklyBudget - cost,
        )
    }

    private companion object {
        const val MIN_TARGET = 5
        const val MAX_TARGET = 21
        val NO_IMPACT = BudgetImpact(percentageOfWeeklyBudget = 0.0, impactLevel = null, message = "", remainingBudget = 0.0)
    }
}
