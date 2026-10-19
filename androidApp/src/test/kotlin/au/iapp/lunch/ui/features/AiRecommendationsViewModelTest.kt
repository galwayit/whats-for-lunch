/**
 * @file AiRecommendationsViewModelTest.kt
 * @description One free AI request, then an upgrade prompt; subscribers retain their allowance.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.features.ai.AiRecommendationsViewModel
import au.iapp.lunch.ui.features.shared.LoadState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertFalse
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AiRecommendationsViewModelTest {
    @get:Rule
    val main = MainDispatcherRule()

    private fun environment(isPro: Boolean, aiUsedToday: Boolean) =
        AppEnvironment.preview(PreviewCoreOptions(isPro = isPro, isSignedIn = true, aiUsedToday = aiUsedToday, latencyMs = 0))

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
        assertTrue(viewModel.state.value.needsConsent)
        viewModel.allowAiSharing()
        advanceUntilIdle()
        val result = viewModel.state.value.result
        assertTrue("expected Loaded but was $result", result is LoadState.Loaded)
        assertTrue((result as LoadState.Loaded).value.restaurants.isNotEmpty())
    }

    @Test
    fun first_free_request_succeeds_and_second_opens_paywall_without_losing_result() = runTest(main.dispatcher) {
        val app = environment(isPro = false, aiUsedToday = false)
        val viewModel = AiRecommendationsViewModel(app, pickPlaceId = null)
        advanceUntilIdle()
        assertFalse(viewModel.state.value.isGated)

        viewModel.setCraving("noodles")
        viewModel.ask()
        advanceUntilIdle()
        assertTrue(viewModel.state.value.needsConsent)
        viewModel.allowAiSharing()
        advanceUntilIdle()
        val first = viewModel.state.value.result
        assertTrue(first is LoadState.Loaded)
        assertTrue(app.routes.value.isEmpty())
        viewModel.ask()
        advanceUntilIdle()
        assertEquals(GateReason.AI_DAILY_LIMIT, viewModel.state.value.gateReason)
        assertTrue(viewModel.state.value.needsSubscription)
        assertEquals(first, viewModel.state.value.result)
        assertEquals(AppRoute.Paywall, app.routes.value.last())
        app.dismiss()
        viewModel.refreshAccess()
        advanceUntilIdle()
        assertTrue("Dismissing the paywall must not immediately reopen it", app.routes.value.isEmpty())
    }

    @Test fun subscribing_after_the_free_request_unlocks_the_same_screen() = runTest(main.dispatcher) {
        val app = environment(isPro = false, aiUsedToday = true)
        val model = AiRecommendationsViewModel(app, null)
        advanceUntilIdle()
        assertTrue(model.state.value.needsSubscription)
        app.core.entitlements.purchase("\$rc_monthly").getOrThrow()
        advanceUntilIdle()
        assertFalse(model.state.value.isGated)
        assertTrue(model.state.value.canAsk)
        model.ask()
        advanceUntilIdle()
        model.allowAiSharing()
        advanceUntilIdle()
        assertTrue(model.state.value.result is LoadState.Loaded)
    }

    @Test fun exhausted_subscriber_gets_daily_limit_instead_of_subscription_gate() = runTest(main.dispatcher) {
        val app = environment(isPro = true, aiUsedToday = false)
        val gates = app.core.gates as au.iapp.lunch.preview.PreviewGateService
        repeat(10) { gates.recordAiUsed() }
        val model = AiRecommendationsViewModel(app, null)
        advanceUntilIdle()
        assertEquals(GateReason.AI_DAILY_LIMIT, model.state.value.gateReason)
        assertFalse(model.state.value.needsSubscription)
        assertTrue(app.routes.value.isEmpty())
        assertNull(model.state.value.aiConfiguration)
    }

    @Test
    fun should_disclose_current_providers_before_sending_ai_context() = runTest(main.dispatcher) {
        val model = AiRecommendationsViewModel(environment(isPro = true, aiUsedToday = false), null)
        advanceUntilIdle()
        model.ask()
        advanceUntilIdle()
        assertTrue(model.state.value.needsConsent)
        assertTrue(model.state.value.aiConfiguration!!.providers.first().name == "Preview AI")
        assertTrue(model.state.value.result !is LoadState.Loaded)
    }

    @Test
    fun changed_provider_requires_new_permission() = runTest(main.dispatcher) {
        val app = environment(isPro = true, aiUsedToday = false)
        val model = AiRecommendationsViewModel(app, null)
        advanceUntilIdle()
        model.ask()
        advanceUntilIdle()
        model.allowAiSharing()
        advanceUntilIdle()
        assertTrue(model.state.value.result is LoadState.Loaded)
        val provider = app.core.ai as au.iapp.lunch.preview.PreviewAiService
        provider.aiConfiguration = provider.aiConfiguration.copy(consentVersion = "new-provider")
        model.ask()
        advanceUntilIdle()
        assertTrue(model.state.value.needsConsent)
        assertTrue(model.state.value.result !is LoadState.Loaded)
        model.allowAiSharing()
        advanceUntilIdle()
        assertTrue(model.state.value.result is LoadState.Loaded)
    }
}
