/**
 * @file GroupCreateViewModelTest.kt
 * @description Hosting a group requires Lunch Pro; Pro hosts land on the proposals route.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.groups.GroupCreateViewModel
import au.iapp.lunch.ui.navigation.AppRoute
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class GroupCreateViewModelTest {
    @get:Rule
    val main = MainDispatcherRule()

    @Test
    fun should_show_host_gate_when_free_user_opens_group_create() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(isPro = false, isSignedIn = true, latencyMs = 0))
        val viewModel = GroupCreateViewModel(app)
        advanceUntilIdle()
        assertTrue(viewModel.state.value.showHostGate)
        viewModel.setName("Friday lunch")
        assertFalse(viewModel.state.value.canCreate)
        viewModel.create()
        advanceUntilIdle()
        assertTrue(app.routes.value.isEmpty())
    }

    @Test
    fun should_open_proposals_when_pro_user_creates_group() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(isPro = true, isSignedIn = true, latencyMs = 0))
        app.present(AppRoute.GroupCreate)
        val viewModel = GroupCreateViewModel(app)
        advanceUntilIdle()
        assertFalse(viewModel.state.value.showHostGate)
        viewModel.setName("Friday lunch")
        assertTrue(viewModel.state.value.canCreate)
        viewModel.create()
        advanceUntilIdle()
        val top = app.routes.value.last()
        assertTrue("expected GroupProposals but was $top", top is AppRoute.GroupProposals)
        assertEquals(1, app.routes.value.size)
    }
}
