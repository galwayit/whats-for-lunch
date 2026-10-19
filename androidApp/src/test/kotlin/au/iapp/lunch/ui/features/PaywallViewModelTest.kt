/**
 * @file PaywallViewModelTest.kt
 * @description Both Lunch Pro packages come from the core; yearly leads with the trial.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.R
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.api.LunchCore
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.SubscriptionStatus
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.paywall.PaywallViewModel
import au.iapp.lunch.ui.features.paywall.purchaseErrorMessage
import au.iapp.lunch.ui.features.shared.LoadState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class PaywallViewModelTest {
    @get:Rule val main = MainDispatcherRule()

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
        val app = AppEnvironment.preview(PreviewCoreOptions(isSignedIn = true, latencyMs = 0))
        val viewModel = PaywallViewModel(app)
        advanceUntilIdle()
        viewModel.purchase()
        advanceUntilIdle()
        assertTrue(viewModel.state.value.isPro)
        assertTrue(app.isPro.value)
    }

    private fun model(result: Result<SubscriptionStatus>): PaywallViewModel {
        val base = AppEnvironment.preview(PreviewCoreOptions(isSignedIn = true, latencyMs = 0))
        val store = object : EntitlementRepository by base.core.entitlements {
            override suspend fun purchase(packageIdentifier: String) = result
            override suspend fun restore() = result
        }
        val core = object : LunchCore by base.core { override val entitlements = store }
        return PaywallViewModel(AppEnvironment(core, base.location))
    }

    @Test fun successful_transaction_without_pro_is_visible_and_does_not_unlock() = runTest(main.dispatcher) {
        val vm = model(Result.success(SubscriptionStatus(isPro = false)))
        advanceUntilIdle()
        vm.purchase()
        advanceUntilIdle()
        assertFalse(vm.state.value.isPro)
        assertFalse(vm.state.value.isPurchasing)
        assertEquals(R.string.paywall_error_activation, purchaseErrorMessage(vm.state.value.purchaseError!!))
    }

    @Test fun sdk_cancellation_is_quiet_for_purchase_and_restore() = runTest(main.dispatcher) {
        val vm = model(Result.failure(CoreError.Service("PURCHASE_CANCELLED", "cancelled")))
        advanceUntilIdle()
        vm.purchase()
        advanceUntilIdle()
        assertNull(vm.state.value.purchaseError)
        assertFalse(vm.state.value.isPurchasing)
        vm.restore()
        advanceUntilIdle()
        assertNull(vm.state.value.purchaseError)
        assertFalse(vm.state.value.isRestoring)
    }

    @Test fun failed_purchase_has_store_specific_feedback() = runTest(main.dispatcher) {
        val vm = model(Result.failure(CoreError.Service("StoreProblemError", "internal diagnostic")))
        advanceUntilIdle()
        vm.purchase()
        advanceUntilIdle()
        assertFalse(vm.state.value.isPro)
        assertFalse(vm.state.value.isPurchasing)
        assertEquals(R.string.paywall_error_purchase, purchaseErrorMessage(vm.state.value.purchaseError!!))
    }

    @Test fun active_pro_purchase_opens_success_state() = runTest(main.dispatcher) {
        val vm = model(Result.success(SubscriptionStatus(isPro = true)))
        advanceUntilIdle()
        vm.purchase()
        advanceUntilIdle()
        assertTrue(vm.state.value.isPro)
        assertNull(vm.state.value.purchaseError)
    }
}
