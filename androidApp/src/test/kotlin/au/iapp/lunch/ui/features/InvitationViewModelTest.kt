/**
 * @file InvitationViewModelTest.kt
 * @description Guests who are signed out can accept an invitation with just a display name.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.preview.PreviewCoreData
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.invitation.InvitationViewModel
import au.iapp.lunch.ui.features.shared.LoadState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class InvitationViewModelTest {
    @get:Rule
    val main = MainDispatcherRule()

    @Test
    fun should_record_accepted_rsvp_when_guest_accepts_with_name() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(isPro = false, isSignedIn = false, latencyMs = 0))
        val viewModel = InvitationViewModel(app, PreviewCoreData.INVITE_CODE, prefs = null)
        advanceUntilIdle()
        assertTrue(viewModel.state.value.invitation is LoadState.Loaded)

        viewModel.setDisplayName("Sam")
        viewModel.accept()
        advanceUntilIdle()

        val invitation = (viewModel.state.value.invitation as LoadState.Loaded).value
        assertEquals(RsvpStatus.ACCEPTED, invitation.myStatus)
        assertTrue(invitation.attendees.any { it.displayName == "Sam" && it.status == RsvpStatus.ACCEPTED })
    }

    @Test
    fun should_show_missing_state_when_code_is_unknown() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(latencyMs = 0))
        val viewModel = InvitationViewModel(app, "NOPE00", prefs = null)
        advanceUntilIdle()
        assertTrue(viewModel.state.value.invitation is LoadState.Failed)
    }
}
