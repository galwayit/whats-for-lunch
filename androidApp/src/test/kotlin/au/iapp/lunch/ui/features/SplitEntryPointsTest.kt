/**
 * @file SplitEntryPointsTest.kt
 * @description The two ways into the split sheet, on the preview core: the Track meal log card
 * (prefill from the cost field, "Use my share" fills cost and notes) and a hosted group's detail
 * screen (accepted guests only, "Use my share" logs the meal straight away).
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.preview.PreviewCoreData
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.groups.GroupDetailViewModel
import au.iapp.lunch.ui.features.split.SplitPerson
import au.iapp.lunch.ui.features.track.TrackViewModel
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
class SplitEntryPointsTest {
    @get:Rule
    val main = MainDispatcherRule()

    private val copy = SplitTestCopy.copy

    private fun previewApp(isPro: Boolean = false) =
        AppEnvironment.preview(PreviewCoreOptions(isPro = isPro, isSignedIn = isPro, latencyMs = 0))

    @Test
    fun should_open_split_with_the_cost_field_bill_when_track_cost_is_valid() = runTest(main.dispatcher) {
        val track = TrackViewModel(previewApp())
        advanceUntilIdle()
        track.setPlace("Sakura Sushi")
        track.setCost("64.20")
        track.openSplit(InMemoryPayIdStore())

        val split = track.split.value!!.state.value
        assertEquals("64.20", split.billText)
        assertEquals(2, split.people.size)
        assertEquals("Sakura Sushi", split.placeName)

        track.closeSplit()
        assertNull(track.split.value)
    }

    @Test
    fun should_fill_cost_and_empty_notes_when_track_uses_my_share() = runTest(main.dispatcher) {
        val track = TrackViewModel(previewApp())
        advanceUntilIdle()
        track.setCost("100")
        track.openSplit(InMemoryPayIdStore())
        val split = track.split.value!!
        split.setPeopleCount(3)

        track.useSplitShare(split.state.value.myShare(copy)!!)

        val draft = track.state.value.draft
        assertEquals("33.34", draft.cost)
        assertEquals("Split 3 ways, bill $100.00", draft.notes)
        assertTrue(draft.canLog)
        assertNull("the sheet closes", track.split.value)
    }

    @Test
    fun should_keep_existing_notes_when_track_uses_my_share() = runTest(main.dispatcher) {
        val track = TrackViewModel(previewApp())
        advanceUntilIdle()
        track.setNotes("Team lunch")
        track.openSplit(InMemoryPayIdStore())
        val split = track.split.value!!
        assertEquals("", split.state.value.billText)
        split.setBill("40")

        track.useSplitShare(split.state.value.myShare(copy)!!)

        assertEquals("20.00", track.state.value.draft.cost)
        assertEquals("Team lunch", track.state.value.draft.notes)
    }

    @Test
    fun should_list_you_then_accepted_guests_when_host_opens_split_from_group() = runTest(main.dispatcher) {
        val group = GroupDetailViewModel(previewApp(isPro = true), PreviewCoreData.GROUP_ID)
        advanceUntilIdle()
        assertTrue(group.state.value.canSplit)

        group.openSplit(InMemoryPayIdStore())

        // Seed RSVPs: Ray (the host, accepted), Mei (accepted), Tom (pending), Aisha (declined).
        val split = group.split.value!!.state.value
        assertEquals(listOf(SplitPerson.You, SplitPerson.Named("Mei")), split.people)
        assertFalse(split.showsStepper)
        assertEquals("Green Garden Bowls", split.placeName)
        assertEquals("", split.billText)
    }

    @Test
    fun should_log_my_share_as_a_lunch_when_host_uses_my_share() = runTest(main.dispatcher) {
        val app = previewApp(isPro = true)
        val group = GroupDetailViewModel(app, PreviewCoreData.GROUP_ID)
        advanceUntilIdle()
        group.openSplit(InMemoryPayIdStore())
        val split = group.split.value!!
        split.setBill("37")

        group.logSplitShare(split.state.value.myShare(copy)!!)
        advanceUntilIdle()

        val lunch = group.state.value.group!!
        val userId = app.user.value!!.id
        val logged = app.core.meals.inRange(userId, 0, Long.MAX_VALUE).getOrThrow().single { it.notes == "Split 2 ways, bill $37.00" }
        assertEquals("lunch", logged.mealType)
        assertEquals(lunch.placeId, logged.restaurantId)
        assertEquals("Green Garden Bowls", logged.restaurantName)
        assertEquals(lunch.scheduledAtEpochSeconds, logged.dateEpochSeconds)
        assertEquals(18.5, logged.cost, 0.0)
        assertTrue("the Logged toast is due", group.state.value.didLogShare)
        assertNull("the sheet closes", group.split.value)

        group.consumeLoggedShare()
        assertFalse(group.state.value.didLogShare)
    }

    @Test
    fun should_not_offer_split_when_group_has_no_confirmed_place() = runTest(main.dispatcher) {
        val app = previewApp(isPro = true)
        val created = app.core.groups.create("Friday lunch", app.clock.nowEpochSeconds(), Location(-33.88, 151.21), 2.0).getOrThrow()
        val group = GroupDetailViewModel(app, created.id)
        advanceUntilIdle()

        assertFalse(group.state.value.canSplit)
        group.openSplit(InMemoryPayIdStore())
        assertNull(group.split.value)
    }
}
