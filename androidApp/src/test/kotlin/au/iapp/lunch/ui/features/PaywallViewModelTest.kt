/**
 * @file PaywallViewModelTest.kt
 * @description Both Lunch Pro packages come from the core; yearly leads with the trial.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.paywall.PaywallViewModel
import au.iapp.lunch.ui.features.shared.LoadState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class PaywallViewModelTest {
    @get:Rule
    val main = MainDispatcherRule()

    @Test
    fun should_list_yearly_then_monthly_when_offerings_load() = runTest(main.dispatcher) {
        val viewModel = PaywallViewModel(AppEnvironment.preview(PreviewCoreOptions(latencyMs = 0)))
        advanceUntilIdle()
        val packages = (viewModel.state.value.packages as LoadState.Loaded).value
        assertEquals(listOf("year", "month"), packages.map { it.periodLabel })
        assertTrue(packages.first().hasFreeTrial)
        assertFalse(packages.last().hasFreeTrial)
        assertEquals("A\$19.99", packages.first().localizedPrice)
        assertEquals("A\$2.99", packages.last().localizedPrice)
        assertEquals(packages.first().identifier, viewModel.state.value.selectedIdentifier)
    }

    @Test
    fun should_become_pro_when_purchase_succeeds() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(latencyMs = 0))
        val viewModel = PaywallViewModel(app)
        advanceUntilIdle()
        viewModel.purchase()
        advanceUntilIdle()
        assertTrue(viewModel.state.value.isPro)
        assertTrue(app.isPro.value)
    }
}
