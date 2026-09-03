package au.iapp.lunch.core.engine

import au.iapp.lunch.core.model.GuidanceLevel
import au.iapp.lunch.core.model.ImpactLevel
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.model.WeeklyBudgetState
import au.iapp.lunch.core.support.EngineVectors
import au.iapp.lunch.core.support.bool
import au.iapp.lunch.core.support.dbl
import au.iapp.lunch.core.support.dblOrNull
import au.iapp.lunch.core.support.int
import au.iapp.lunch.core.support.obj
import au.iapp.lunch.core.support.str
import au.iapp.lunch.core.support.strOrNull
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class BudgetEngineTest {
    private val vectors = EngineVectors.load()
    private val engine = BudgetEngineImpl()

    @Test
    fun weekStart_isMondayMidnightInTheGivenZone() {
        // Wed 2024-01-03T10:00+11:00 (Sydney) -> Mon 2024-01-01T00:00+11:00.
        assertEquals(1704027600L, engine.weekStart(1704236400L, "Australia/Sydney"))
        // Sunday 23:30 local still belongs to the same week.
        assertEquals(1704027600L, engine.weekStart(1704027600L + 6 * 86400 + 23 * 3600 + 1800, "Australia/Sydney"))
        // Monday 00:00 maps to itself.
        assertEquals(1704027600L, engine.weekStart(1704027600L, "Australia/Sydney"))
        // The same instant in UTC is Tue 2024-01-02T23:00Z -> Mon 2024-01-01T00:00Z.
        assertEquals(1704067200L, engine.weekStart(1704236400L, "UTC"))
        // Week containing the London DST switch (Sun 2024-03-31): Sunday 12:00 BST -> Mon 2024-03-25T00:00Z.
        assertEquals(1711324800L, engine.weekStart(1711882800L, "Europe/London"))
        // Sunday 2024-04-07 in Sydney is the day DST ends; Monday is 2024-04-01T00:00+11:00.
        assertEquals(1711890000L, engine.weekStart(1711890000L + 6 * 86400 + 12 * 3600, "Australia/Sydney"))
    }

    @Test
    fun targetExperiences_matchesDartAndClamps() {
        for (case in vectors.budgetCases("targetExperiences")) {
            val prefs = UserPreferences(mealFrequencyPerDay = case.int("mealFrequencyPerDay"), budgetLevel = case.int("budgetLevel"))
            assertEquals(case.int("expected"), engine.targetExperiences(prefs), "target for $prefs")
        }
        assertEquals(5, engine.targetExperiences(UserPreferences(mealFrequencyPerDay = 0, budgetLevel = 4)))
        assertEquals(21, engine.targetExperiences(UserPreferences(mealFrequencyPerDay = 9, budgetLevel = 4)))
    }

    @Test
    fun weeklyState_sumsCostsAndClampsRemaining() {
        val prefs = UserPreferences(weeklyBudget = 100.0, mealFrequencyPerDay = 3, budgetLevel = 2)
        val meals = listOf(meal(30.0, 1L), meal(45.5, 2L), meal(40.0, 3L))
        val state = engine.weeklyState(prefs, meals, 1000L)
        assertEquals(100.0, state.weeklyCapacity)
        assertEquals(115.5, state.currentSpent, 1e-9)
        assertEquals(0.0, state.remainingCapacity)
        assertEquals(3, state.experiencesLogged)
        assertEquals(11, state.targetExperiences)
        assertEquals(1000L, state.weekStartEpochSeconds)
        assertEquals(1.155, state.capacityProgress, 1e-9)
        assertEquals(3.0 / 11, state.experienceProgress, 1e-9)

        val empty = engine.weeklyState(prefs, emptyList(), 1000L)
        assertEquals(0.0, empty.currentSpent)
        assertEquals(100.0, empty.remainingCapacity)
    }

    @Test
    fun usageAndGuidanceLevels_matchDartThresholds() {
        for (case in vectors.budgetCases("levels")) {
            val progress = case.dbl("progress")
            val state = WeeklyBudgetState(1.0, progress, 0.0, 0, 0, 0L)
            assertEquals(ImpactLevel.valueOf(case.str("capacityUsageLevel")), engine.capacityUsageLevel(state), "usage at $progress")
            assertEquals(GuidanceLevel.valueOf(case.str("guidanceLevel")), engine.guidanceLevel(state), "guidance at $progress")
        }
    }

    @Test
    fun mealImpact_matchesDart() {
        for (case in vectors.budgetCases("mealImpact")) {
            val state = WeeklyBudgetState(case.dbl("weeklyCapacity"), case.dbl("currentSpent"), 0.0, 0, 0, 0L)
            val expected = case.obj("expected")
            val actual = engine.mealImpact(state, case.dbl("mealCost"))
            assertEquals(expected.dbl("mealCost"), actual.mealCost)
            assertEquals(expected.dbl("projectedSpent"), actual.projectedSpent, 1e-12)
            assertEquals(expected.dbl("projectedRemaining"), actual.projectedRemaining, 1e-12)
            assertEquals(ImpactLevel.valueOf(expected.str("impactLevel").uppercase()), actual.impactLevel)
            assertEquals(GuidanceLevel.valueOf(expected.str("guidanceLevel").uppercase()), actual.guidanceLevel)
            assertEquals(expected.str("message"), actual.message)
            assertEquals(expected.bool("exceedsCapacity"), actual.exceedsCapacity)
        }
    }

    @Test
    fun budgetImpact_matchesDart() {
        for (case in vectors.budgetCases("budgetImpact")) {
            val prefs = UserPreferences(weeklyBudget = case.dbl("weeklyBudget"))
            val expected = case.obj("expected")
            val actual = engine.budgetImpact(prefs, case.dblOrNull("cost"))
            assertEquals(expected.dbl("percentageOfWeeklyBudget"), actual.percentageOfWeeklyBudget, 1e-12)
            val level = expected.strOrNull("impactLevel")
            if (level == null) assertNull(actual.impactLevel) else assertEquals(ImpactLevel.valueOf(level.uppercase()), actual.impactLevel)
            assertEquals(expected.str("message"), actual.message)
            assertEquals(expected.dbl("remainingBudget"), actual.remainingBudget, 1e-12)
        }
    }

    private fun meal(cost: Double, date: Long) = Meal(userId = 1, mealType = "lunch", cost = cost, dateEpochSeconds = date)
}
