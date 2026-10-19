/**
 * @file SplitBillViewModelTest.kt
 * @description The split sheet's state: Track prefill and stepper, adjusting and resetting rows,
 * every engine error with both actions disabled, the total line, the share message and the
 * device-only "Pay me at" store. Amounts follow the engine vectors (A$100 three ways is
 * 33.34 / 33.33 / 33.33).
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.split.SplitBillUiState
import au.iapp.lunch.ui.features.split.SplitBillViewModel
import au.iapp.lunch.ui.features.split.SplitPerson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SplitBillViewModelTest {
    private val copy = SplitTestCopy.copy

    private fun track(cost: String = "100", place: String? = null, store: InMemoryPayIdStore = InMemoryPayIdStore()) =
        SplitBillViewModel.forTrack(costText = cost, placeName = place, payIds = store)

    private val SplitBillViewModel.now: SplitBillUiState get() = state.value

    private fun SplitBillUiState.amounts(): List<String> = people.indices.map(::amountText)

    private fun assertInvalid(state: SplitBillUiState, message: String) {
        assertEquals(message, state.errorText(copy))
        assertFalse("both buttons are disabled while invalid", state.canAct)
        assertNull(state.shareMessage(copy))
        assertNull(state.myShare(copy))
        assertNull(state.totalText(copy))
    }

    @Test
    fun should_prefill_bill_and_two_people_when_opened_from_track_with_valid_cost() {
        val state = track(cost = "18.50").now
        assertEquals("18.50", state.billText)
        assertTrue(state.showsStepper)
        assertEquals(listOf(SplitPerson.You, SplitPerson.Numbered(2)), state.people)
        assertEquals(listOf("You", "Person 2"), state.people.map { it.label(copy) })
        assertEquals(listOf("9.25", "9.25"), state.amounts())
        assertTrue(state.canAct)
    }

    @Test
    fun should_leave_bill_empty_when_track_cost_is_empty_or_zero() {
        listOf("", "0", "0.00", ".").forEach { cost ->
            val state = track(cost = cost).now
            assertEquals("cost '$cost'", "", state.billText)
            assertInvalid(state, "Enter the bill total")
        }
    }

    @Test
    fun should_keep_people_between_1_and_50_when_stepping() {
        val split = track()
        split.setPeopleCount(0)
        assertEquals(1, split.now.people.size)
        assertEquals(listOf("100.00"), split.now.amounts())
        split.setPeopleCount(51)
        assertEquals(50, split.now.people.size)
        assertEquals(SplitPerson.Numbered(50), split.now.people.last())
        assertTrue(split.now.canAct)
        split.setPeopleCount(3)
        assertEquals(listOf("33.34", "33.33", "33.33"), split.now.amounts())
    }

    @Test
    fun should_drop_the_adjustment_when_the_stepper_removes_that_row() {
        val split = track()
        split.setPeopleCount(3)
        split.setAmount(2, "10")
        split.setPeopleCount(2)
        assertFalse(split.now.isAdjusted(2))
        assertEquals(listOf("50.00", "50.00"), split.now.amounts())
    }

    @Test
    fun should_rebalance_other_rows_when_a_row_is_adjusted() {
        val split = track()
        split.setPeopleCount(3)
        split.setAmount(1, "50")
        val state = split.now
        assertTrue(state.isAdjusted(1))
        assertFalse(state.isAdjusted(0))
        assertEquals(listOf("25.00", "50", "25.00"), state.amounts())
        assertEquals("Total $100.00", state.totalText(copy))
    }

    @Test
    fun should_restore_the_even_split_when_a_row_is_reset() {
        val split = track()
        split.setPeopleCount(3)
        split.setAmount(1, "50")
        split.reset(1)
        assertFalse(split.now.isAdjusted(1))
        assertEquals(listOf("33.34", "33.33", "33.33"), split.now.amounts())
    }

    @Test
    fun should_count_an_emptied_adjusted_row_as_zero_when_rebalancing() {
        val split = track()
        split.setAmount(1, "")
        assertTrue(split.now.isAdjusted(1))
        assertEquals(listOf("100.00", ""), split.now.amounts())
    }

    @Test
    fun should_show_no_bill_error_and_disable_actions_when_bill_is_cleared() {
        val split = track()
        split.setBill("")
        assertInvalid(split.now, "Enter the bill total")
    }

    @Test
    fun should_show_surcharge_error_and_disable_actions_when_surcharge_is_over_50_percent() {
        val split = track()
        split.setSurcharge("50.01")
        assertInvalid(split.now, "Surcharge must be 50% or less")
        split.setSurcharge("50")
        assertTrue(split.now.canAct)
    }

    @Test
    fun should_show_the_excess_and_disable_actions_when_adjusted_amounts_are_over_the_bill() {
        val split = track()
        split.setAmount(0, "80")
        split.setAmount(1, "30")
        assertInvalid(split.now, "Adjusted amounts are $10.00 over the bill")
    }

    @Test
    fun should_show_the_shortfall_and_disable_actions_when_everyone_is_adjusted_under_the_bill() {
        val split = track()
        split.setAmount(0, "40")
        split.setAmount(1, "40.5")
        assertInvalid(split.now, "$19.50 of the bill isn't covered yet")
    }

    @Test
    fun should_show_too_many_error_and_disable_actions_when_a_group_has_more_than_50_people() {
        val split = SplitBillViewModel.forGroup("Sakura Sushi", (1..50).map { "Guest $it" }, InMemoryPayIdStore())
        split.setBill("100")
        assertEquals(51, split.now.people.size)
        assertInvalid(split.now, "Up to 50 people")
    }

    @Test
    fun should_show_no_people_error_and_disable_actions_when_nobody_is_splitting() {
        val split = SplitBillViewModel(SplitBillUiState(billText = "100", people = emptyList()), InMemoryPayIdStore())
        assertInvalid(split.now, "Add at least one person")
    }

    @Test
    fun should_mention_the_surcharge_in_the_total_when_one_is_set() {
        val split = track()
        split.setSurcharge("10")
        assertEquals("Total $110.00 incl. $10.00 surcharge", split.now.totalText(copy))
        assertEquals(listOf("55.00", "55.00"), split.now.amounts())
    }

    @Test
    fun should_build_the_share_message_with_place_and_pay_me_at_when_both_are_set() {
        val store = InMemoryPayIdStore()
        val split = track(place = "Sakura Sushi", store = store)
        split.setPeopleCount(3)
        split.setPayId("PayID 0400 000 000")
        assertEquals(
            """
            Sakura Sushi: bill $100.00 split 3 ways
            You: $33.34
            Person 2: $33.33
            Person 3: $33.33
            Pay me at: PayID 0400 000 000
            Split with What We Have For Lunch
            """.trimIndent(),
            split.now.shareMessage(copy),
        )
    }

    @Test
    fun should_use_the_fallback_place_and_skip_pay_me_at_when_neither_is_set() {
        val split = track(place = "  ")
        split.setSurcharge("10")
        split.setAmount(1, "60")
        assertEquals(
            """
            Lunch: bill $110.00 split 2 ways
            You: $50.00
            Person 2: $60.00
            Split with What We Have For Lunch
            """.trimIndent(),
            split.now.shareMessage(copy),
        )
    }

    @Test
    fun should_use_guest_names_in_the_share_message_when_opened_from_a_group() {
        val split = SplitBillViewModel.forGroup("Green Garden Bowls", listOf("Mei"), InMemoryPayIdStore())
        split.setBill("37")
        assertEquals(
            """
            Green Garden Bowls: bill $37.00 split 2 ways
            You: $18.50
            Mei: $18.50
            Split with What We Have For Lunch
            """.trimIndent(),
            split.now.shareMessage(copy),
        )
        assertFalse(split.now.showsStepper)
    }

    @Test
    fun should_remember_pay_me_at_on_the_device_when_it_is_typed() {
        val store = InMemoryPayIdStore()
        track(store = store).setPayId("cash")
        assertEquals("cash", store.saved)
        assertEquals("cash", track(store = store).now.payId)
        track(store = store).setPayId(" ")
        assertEquals("", store.saved)
    }

    @Test
    fun should_return_my_share_and_note_when_use_my_share_is_valid() {
        val split = track()
        split.setPeopleCount(3)
        val share = split.now.myShare(copy)!!
        assertEquals(3334L, share.myShareCents)
        assertEquals("Split 3 ways, bill $100.00", share.note)
    }

    @Test
    fun should_print_two_decimals_when_formatting_cents() {
        assertEquals("$200.00", LunchFormat.cents(20_000))
        assertEquals("$33.34", LunchFormat.cents(3_334))
        assertEquals("$0.05", LunchFormat.cents(5))
        assertEquals("$1,234.56", LunchFormat.cents(123_456))
    }
}
