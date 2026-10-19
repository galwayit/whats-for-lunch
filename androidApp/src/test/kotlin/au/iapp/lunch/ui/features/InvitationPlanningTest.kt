package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.core.model.*
import au.iapp.lunch.ui.features.groups.GroupDetailsDraft
import au.iapp.lunch.ui.features.invitation.InvitationViewModel
import au.iapp.lunch.ui.features.shared.LoadState
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class InvitationPlanningTest {
    @get:Rule val main = MainDispatcherRule()
    @Test fun budgets_are_exact_optional_and_validated() {
        val draft = GroupDetailsDraft(hostName = "Sam")
        assertNull(draft.value()!!.budgetPerPersonMinor)
        assertEquals(2550L, draft.copy(budget = "25.50").value()!!.budgetPerPersonMinor)
        assertEquals(0L, draft.copy(budget = "0").value()!!.budgetPerPersonMinor)
        for (bad in listOf("-1", "2.999", "10000.01", "NaN", "1,000")) assertNull(draft.copy(budget = bad).value())
        assertNull(draft.copy(hostName = " ").value())
    }
    @Test fun guest_proposal_is_not_an_rsvp_or_a_plan_change() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(isSignedIn = false, latencyMs = 0))
        val group = app.core.groups.loadGroups().getOrThrow().first()
        val model = InvitationViewModel(app, group.inviteCode)
        advanceUntilIdle()
        model.setDisplayName("Fictional guest")
        model.showSuggestion(true)
        model.suggest(GroupSuggestionDraft("Test cafe", "10 Test Lane", group.scheduledAtEpochSeconds + 3600))
        advanceUntilIdle()
        val invite = (model.state.value.invitation as LoadState.Loaded).value
        assertEquals(group, invite.group)
        assertNull(invite.myStatus)
        assertEquals("pending", invite.mySuggestion!!.status)
        assertFalse(model.state.value.showSuggestion)
        val changed = app.core.groups.reviewSuggestion(group.id, invite.mySuggestion!!.id, true).getOrThrow()
        assertEquals("Test cafe", changed.placeName)
        assertNull(changed.placeId)
        assertEquals(group.scheduledAtEpochSeconds + 3600, changed.scheduledAtEpochSeconds)
    }
}
