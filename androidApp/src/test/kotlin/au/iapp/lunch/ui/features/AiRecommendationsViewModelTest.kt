/**
 * @file AiRecommendationsViewModelTest.kt
 * @description The AI gate over the preview core: one free request a day, unlimited for Pro.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.ai.AiRecommendationsViewModel
import au.iapp.lunch.ui.features.shared.LoadState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AiRecommendationsViewModelTest {
    @get:Rule
    val main = MainDispatcherRule()

    private fun environment(isPro: Boolean, aiUsedToday: Boolean) =
        AppEnvironment.preview(PreviewCoreOptions(isPro = isPro, aiUsedToday = aiUsedToday, latencyMs = 0))

    @Test
    fun should_gate_ai_request_when_free_user_already_asked_today() = runTest(main.dispatcher) {
        val viewModel = AiRecommendationsViewModel(environment(isPro = false, aiUsedToday = true), pickPlaceId = null)
        advanceUntilIdle()
        assertTrue(viewModel.state.value.isGated)
        assertFalse(viewModel.state.value.canAsk)

        viewModel.setCraving("ramen")
        viewModel.ask()
        advanceUntilIdle()
        assertTrue(viewModel.state.value.result !is LoadState.Loaded)
    }

    @Test
    fun should_return_recommendations_when_pro_user_asks_after_using_today() = runTest(main.dispatcher) {
        val viewModel = AiRecommendationsViewModel(environment(isPro = true, aiUsedToday = true), pickPlaceId = null)
        advanceUntilIdle()
        assertFalse(viewModel.state.value.isGated)

        viewModel.setCraving("something warm")
        viewModel.ask()
        advanceUntilIdle()
        val result = viewModel.state.value.result
        assertTrue("expected Loaded but was $result", result is LoadState.Loaded)
        assertTrue((result as LoadState.Loaded).value.restaurants.isNotEmpty())
    }

    @Test
    fun should_gate_after_first_request_when_free_user_has_not_asked_today() = runTest(main.dispatcher) {
        val viewModel = AiRecommendationsViewModel(environment(isPro = false, aiUsedToday = false), pickPlaceId = null)
        advanceUntilIdle()
        assertFalse(viewModel.state.value.isGated)

        viewModel.setCraving("noodles")
        viewModel.ask()
        advanceUntilIdle()
        assertTrue(viewModel.state.value.result is LoadState.Loaded)
        viewModel.ask()
        advanceUntilIdle()
        assertTrue(viewModel.state.value.isGated)
    }
}
