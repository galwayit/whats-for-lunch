package au.iapp.lunch.core.engine

import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.WeeklyBudgetState
import au.iapp.lunch.core.support.EngineVectors
import au.iapp.lunch.core.support.int
import au.iapp.lunch.core.support.str
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AchievementEngineTest {
    private val engine = AchievementEngineImpl()
    private val zone = "Australia/Sydney"
    private val now = 1712476800L // 2024-04-07T18:00+10:00

    @Test
    fun catalogue_matchesFlutterIdsPointsAndOrder() {
        assertEquals(
            listOf("first_experience" to 10, "week_optimizer" to 25, "experience_explorer" to 20, "consistent_tracker" to 30, "smart_spender" to 50),
            engine.catalogue.map { it.id to it.points },
        )
        assertEquals(listOf("celebration", "eco", "explore", "calendar_today", "psychology"), engine.catalogue.map { it.iconName })
        assertEquals(listOf("First Investment", "Weekly Optimizer", "Experience Explorer", "Consistent Tracker", "Smart Investor"), engine.catalogue.map { it.title })
        assertTrue(engine.catalogue.none { it.isUnlocked })
    }

    @Test
    fun evaluate_nothingWithoutMeals() {
        val weekly = WeeklyBudgetState(200.0, 0.0, 200.0, 0, 10, 0L)
        assertEquals(emptyList(), engine.evaluate(emptySet(), weekly, emptyList(), now, zone))
    }

    @Test
    fun evaluate_firstExperienceOnFirstMeal() {
        val weekly = WeeklyBudgetState(200.0, 20.0, 180.0, 1, 10, 0L)
        val unlocked = engine.evaluate(emptySet(), weekly, listOf(mealAt(day(1), "lunch")), now, zone)
        assertEquals(listOf("first_experience"), unlocked.map { it.id })
        assertTrue(unlocked.single().isUnlocked)
        assertEquals(now, unlocked.single().unlockedAtEpochSeconds)
        // Already unlocked ids are not returned again.
        assertEquals(emptyList(), engine.evaluate(setOf("first_experience"), weekly, listOf(mealAt(day(1), "lunch")), now, zone))
    }

    @Test
    fun evaluate_weekOptimizerNeedsFiveMealsWithinEightyPercent() {
        val meals = (1..5).map { mealAt(day(it), "lunch") }
        val ok = WeeklyBudgetState(200.0, 160.0, 40.0, 5, 10, 0L)
        assertEquals(listOf("week_optimizer"), engine.evaluate(setOf("first_experience"), ok, meals, now, zone).map { it.id })
        val tooExpensive = WeeklyBudgetState(200.0, 160.01, 39.99, 5, 10, 0L)
        assertEquals(emptyList(), engine.evaluate(setOf("first_experience"), tooExpensive, meals, now, zone))
        val tooFew = WeeklyBudgetState(200.0, 10.0, 190.0, 4, 10, 0L)
        assertEquals(emptyList(), engine.evaluate(setOf("first_experience"), tooFew, meals, now, zone))
    }

    @Test
    fun evaluate_experienceExplorerNeedsFiveDistinctTypes() {
        val weekly = WeeklyBudgetState(200.0, 190.0, 10.0, 5, 10, 0L)
        val fourTypes = listOf("breakfast", "lunch", "dinner", "snack", "snack").mapIndexed { i, t -> mealAt(day(1) + i, t) }
        assertEquals(emptyList(), engine.evaluate(setOf("first_experience", "week_optimizer"), weekly, fourTypes, now, zone))
        val fiveTypes = fourTypes + mealAt(day(1), "takeout")
        assertEquals(listOf("experience_explorer"), engine.evaluate(setOf("first_experience", "week_optimizer"), weekly, fiveTypes, now, zone).map { it.id })
    }

    @Test
    fun evaluate_consistentTrackerAcrossDstChange() {
        val weekly = WeeklyBudgetState(200.0, 190.0, 10.0, 7, 10, 0L)
        val already = setOf("first_experience", "week_optimizer", "experience_explorer")
        // 2024-04-03..2024-04-09 at 12:00 local; DST ends on 2024-04-07 in Sydney.
        val sevenDays = (3..9).map { mealAt(localNoon(2024, 4, it), "lunch") }
        assertEquals(listOf("consistent_tracker"), engine.evaluate(already, weekly, sevenDays.shuffled(), now, zone).map { it.id })
        // Two meals on one day do not count twice.
        val sixDaysWithDuplicate = sevenDays.dropLast(1) + mealAt(localNoon(2024, 4, 3) + 3600, "dinner")
        assertEquals(emptyList(), engine.evaluate(already, weekly, sixDaysWithDuplicate, now, zone))
        // A gap resets the streak.
        val gap = sevenDays.filterNot { it.dateEpochSeconds == localNoon(2024, 4, 6) } + mealAt(localNoon(2024, 4, 11), "lunch")
        assertEquals(emptyList(), engine.evaluate(already, weekly, gap, now, zone))
        // Fewer than seven meals can never qualify.
        assertEquals(emptyList(), engine.evaluate(already, weekly, sevenDays.take(6), now, zone))
    }

    @Test
    fun evaluate_returnsInCatalogueOrderAndNeverSmartSpender() {
        val weekly = WeeklyBudgetState(200.0, 100.0, 100.0, 7, 10, 0L)
        val meals = listOf("breakfast", "lunch", "dinner", "snack", "takeout", "delivery", "groceries").mapIndexed { i, t -> mealAt(localNoon(2024, 4, 3 + i), t) }
        val ids = engine.evaluate(emptySet(), weekly, meals, now, zone).map { it.id }
        assertEquals(listOf("first_experience", "week_optimizer", "experience_explorer", "consistent_tracker"), ids)
    }

    @Test
    fun level_matchesDartThresholds() {
        for (case in EngineVectors.load().cases("level")) {
            assertEquals(case.str("expected"), engine.level(case.int("points")), "level for ${case.int("points")}")
        }
    }

    private fun mealAt(epochSeconds: Long, type: String) = Meal(userId = 1, mealType = type, cost = 10.0, dateEpochSeconds = epochSeconds)

    /** 2024-04-01T00:00+11:00 plus whole days, avoiding kotlinx.datetime in the test itself. */
    private fun day(n: Int): Long = 1711890000L + (n - 1) * 86400L

    /** Noon local time in Sydney for 2024-04-dd, including the DST end on 04-07. */
    private fun localNoon(year: Int, month: Int, dayOfMonth: Int): Long {
        require(year == 2024 && month == 4)
        val offsetHours = if (dayOfMonth <= 6) 11 else 10
        val midnightUtcDay = 1711929600L + (dayOfMonth - 1) * 86400L // 2024-04-01T00:00Z
        return midnightUtcDay + (12 - offsetHours) * 3600L
    }
}
