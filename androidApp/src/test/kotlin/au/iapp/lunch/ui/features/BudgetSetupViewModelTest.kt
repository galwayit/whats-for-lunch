/**
 * @file BudgetSetupViewModelTest.kt
 * @description Budget setup maths: slider snapping and the weekly target from the engine.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.budget.BudgetSetupViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class BudgetSetupViewModelTest {
    @get:Rule
    val main = MainDispatcherRule()

    @Test
    fun should_snap_to_slider_steps_when_amount_is_between_stops() {
        assertEquals(50.0, BudgetSetupViewModel.snap(10.0), 0.0)
        assertEquals(95.0, BudgetSetupViewModel.snap(100.0), 0.0)
        assertEquals(140.0, BudgetSetupViewModel.snap(130.0), 0.0)
        assertEquals(500.0, BudgetSetupViewModel.snap(900.0), 0.0)
    }

    @Test
    fun should_match_engine_target_when_weekly_budget_changes() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(latencyMs = 0))
        val viewModel = BudgetSetupViewModel(app)
        advanceUntilIdle()
        viewModel.setWeeklyBudget(275.0)
        val state = viewModel.state.value
        assertEquals(275.0, state.weeklyBudget, 0.0)
        assertEquals(app.core.budget.targetExperiences(viewModel.preferences(UserPreferences())), state.targetExperiences)
        assertEquals(275.0, viewModel.preferences(UserPreferences()).weeklyBudget, 0.0)
    }

    @Test
    fun should_report_remaining_capacity_when_meals_are_logged_this_week() {
        val engine = AppEnvironment.preview(PreviewCoreOptions(latencyMs = 0)).core.budget
        val prefs = UserPreferences(weeklyBudget = 200.0)
        val meals = listOf(meal(18.5), meal(22.0))
        val state = engine.weeklyState(prefs, meals, weekStartEpochSeconds = 0L)
        assertEquals(200.0, state.weeklyCapacity, 0.0)
        assertEquals(40.5, state.currentSpent, 0.001)
        assertEquals(159.5, state.remainingCapacity, 0.001)
        assertEquals(2, state.experiencesLogged)
    }

    private fun meal(cost: Double) = au.iapp.lunch.core.model.Meal(
        id = null, userId = 1L, restaurantId = null, restaurantName = "Cafe", mealType = "lunch", cost = cost, dateEpochSeconds = 0L, notes = null,
    )
}
