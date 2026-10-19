/**
 * @file SplitBillViewModel.kt
 * @description State for the "Split the bill" sheet (screen 12 of design/screens.md): bill,
 * surcharge, people with adjusted amounts, the "Pay me at" note and the share text. All maths
 * comes from the shared `BillSplitEngine`; this file only parses input and words the result.
 * Owned by the host screen's ViewModel (Track or Group detail) so it survives rotation and is
 * dropped when the sheet closes. A calculator only: nothing here talks to the core or backend.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features.split

import au.iapp.lunch.core.engine.BillSplitEngine
import au.iapp.lunch.core.engine.BillSplitError
import au.iapp.lunch.core.engine.BillSplitRequest
import au.iapp.lunch.core.engine.BillSplitResult
import au.iapp.lunch.ui.features.shared.LunchFormat
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/** Test ids from design/screens.md section 12. */
object SplitBillDefaults {
    const val TRACK_BUTTON_TAG = "split_bill_button"
    const val GROUP_BUTTON_TAG = "group_split_button"
    const val BILL_FIELD_TAG = "split_bill_field"
    const val SURCHARGE_FIELD_TAG = "split_surcharge_field"
    const val PEOPLE_STEPPER_TAG = "split_people_stepper"
    const val PAYID_FIELD_TAG = "split_payid_field"
    const val SHARE_BUTTON_TAG = "split_share_button"
    const val USE_SHARE_BUTTON_TAG = "split_use_share_button"

    fun amountTag(index: Int): String = "split_person_${index}_amount"
    fun resetTag(index: Int): String = "split_person_${index}_reset"
}

/**
 * The `split.*` copy the sheet formats, as raw strings.xml templates. The screen reads it with
 * `rememberSplitCopy()`; the unit tests read the same file, so both word things identically.
 */
data class SplitCopy(
    val you: String,
    /** "Person %1$d". */
    val personNumbered: String,
    /** "Total %1$s". */
    val total: String,
    /** "Total %1$s incl. %2$s surcharge". */
    val totalWithSurcharge: String,
    val errorNoBill: String,
    val errorNoPeople: String,
    val errorTooMany: String,
    val errorSurcharge: String,
    /** "Adjusted amounts are %1$s over the bill". */
    val errorOver: String,
    /** "%1$s of the bill isn't covered yet". */
    val errorUnder: String,
    val placeFallback: String,
    /** "%1$s: bill %2$s split %3$d ways". */
    val messageHeader: String,
    /** "%1$s: %2$s". */
    val messageLine: String,
    /** "Pay me at: %1$s". */
    val messagePay: String,
    val messageFooter: String,
    /** "Split %1$d ways, bill %2$s". */
    val note: String,
)

/** One row of the people list; index 0 is always [You]. */
sealed interface SplitPerson {
    data object You : SplitPerson

    /** A placeholder name from the Track stepper: "Person 2", "Person 3", ... */
    data class Numbered(val number: Int) : SplitPerson

    /** A guest's display name from a group lunch. */
    data class Named(val name: String) : SplitPerson

    fun label(copy: SplitCopy): String = when (this) {
        You -> copy.you
        is Numbered -> copy.personNumbered.format(number)
        is Named -> name
    }
}

/** What "Use my share" hands back to the host screen. */
data class SplitShare(val myShareCents: Long, val note: String)

/** Text amounts as typed in the sheet's fields, to and from whole cents. */
object SplitMoney {
    /** "18.5" to 1850 through the engine's rounding; null unless a finite, non-negative number. */
    fun cents(text: String): Long? =
        text.trim().toDoubleOrNull()?.takeIf { it.isFinite() && it >= 0 }?.let(BillSplitEngine::dollarsToCents)

    /** 1850 to "18.50", the raw form the currency fields hold (no symbol, no grouping). */
    fun plain(cents: Long): String = "${cents / 100}.${(cents % 100).toString().padStart(2, '0')}"
}

data class SplitBillUiState(
    val billText: String = "",
    val surchargeText: String = "",
    val people: List<SplitPerson> = listOf(SplitPerson.You),
    /** Track shows a people stepper; a group's people come from its RSVPs. */
    val showsStepper: Boolean = false,
    /** Rows the user typed into, by index, holding the text exactly as typed. */
    val adjustedText: Map<Int, String> = emptyMap(),
    val payId: String = "",
    /** Restaurant for the share message; null falls back to `split.message.place_fallback`. */
    val placeName: String? = null,
    val result: BillSplitResult = BillSplitResult.Invalid(BillSplitError.NO_BILL),
) {
    private val split: BillSplitResult.Split? get() = result as? BillSplitResult.Split

    /** Both actions need a valid split. */
    val canAct: Boolean get() = split != null

    fun isAdjusted(index: Int): Boolean = index in adjustedText

    /** What the row's field shows: the typed text when adjusted, else the computed share. */
    fun amountText(index: Int): String =
        adjustedText[index] ?: split?.sharesCents?.getOrNull(index)?.let(SplitMoney::plain).orEmpty()

    fun errorText(copy: SplitCopy): String? {
        val invalid = result as? BillSplitResult.Invalid ?: return null
        return when (invalid.error) {
            BillSplitError.NO_BILL -> copy.errorNoBill
            BillSplitError.NO_PEOPLE -> copy.errorNoPeople
            BillSplitError.TOO_MANY_PEOPLE -> copy.errorTooMany
            BillSplitError.SURCHARGE_OUT_OF_RANGE -> copy.errorSurcharge
            BillSplitError.OVER_ALLOCATED -> copy.errorOver.format(LunchFormat.cents(invalid.differenceCents))
            BillSplitError.UNDER_ALLOCATED -> copy.errorUnder.format(LunchFormat.cents(invalid.differenceCents))
        }
    }

    /** "Total $110.00" or "Total $110.00 incl. $10.00 surcharge"; null while invalid. */
    fun totalText(copy: SplitCopy): String? {
        val split = split ?: return null
        return if (split.surchargeCents > 0) {
            copy.totalWithSurcharge.format(LunchFormat.cents(split.totalCents), LunchFormat.cents(split.surchargeCents))
        } else {
            copy.total.format(LunchFormat.cents(split.totalCents))
        }
    }

    /** The plain-text message for the system share sheet; null while invalid. */
    fun shareMessage(copy: SplitCopy): String? {
        val split = split ?: return null
        val place = placeName?.trim()?.takeIf { it.isNotEmpty() } ?: copy.placeFallback
        val lines = buildList {
            add(copy.messageHeader.format(place, LunchFormat.cents(split.totalCents), people.size))
            people.forEachIndexed { index, person ->
                add(copy.messageLine.format(person.label(copy), LunchFormat.cents(split.sharesCents[index])))
            }
            payId.trim().takeIf { it.isNotEmpty() }?.let { add(copy.messagePay.format(it)) }
            add(copy.messageFooter)
        }
        return lines.joinToString("\n")
    }

    /** My share (row 0) and the `split.note` text; null while invalid. */
    fun myShare(copy: SplitCopy): SplitShare? {
        val split = split ?: return null
        return SplitShare(split.sharesCents[0], copy.note.format(people.size, LunchFormat.cents(split.totalCents)))
    }
}

/**
 * @param payIds Where "Pay me at" is remembered; on this device only.
 */
class SplitBillViewModel(initial: SplitBillUiState, private val payIds: PayIdStore) {
    private val _state = MutableStateFlow(initial.copy(payId = payIds.load()).recomputed())
    val state: StateFlow<SplitBillUiState> = _state.asStateFlow()

    fun setBill(text: String) = update { it.copy(billText = text) }
    fun setSurcharge(text: String) = update { it.copy(surchargeText = text) }

    /** Track only: 1 to 50 people; rows beyond the new count lose their adjustment. */
    fun setPeopleCount(count: Int) = update { current ->
        if (!current.showsStepper) return@update current
        val clamped = count.coerceIn(1, BillSplitEngine.MAX_PEOPLE)
        current.copy(
            people = numberedPeople(clamped),
            adjustedText = current.adjustedText.filterKeys { it < clamped },
        )
    }

    /** Typing in a row fixes that person's amount; the engine rebalances everyone else. */
    fun setAmount(index: Int, text: String) = update { current ->
        if (index !in current.people.indices) current else current.copy(adjustedText = current.adjustedText + (index to text))
    }

    fun reset(index: Int) = update { it.copy(adjustedText = it.adjustedText - index) }

    fun setPayId(text: String) {
        payIds.save(text)
        _state.update { it.copy(payId = text) }
    }

    private fun update(transform: (SplitBillUiState) -> SplitBillUiState) = _state.update { transform(it).recomputed() }

    companion object {
        const val DEFAULT_PEOPLE = 2

        /** From Track: bill from the cost field when it holds a valid amount, 2 people. */
        fun forTrack(costText: String, placeName: String?, payIds: PayIdStore): SplitBillViewModel {
            val bill = costText.trim().takeIf { (SplitMoney.cents(it) ?: 0L) > 0L }.orEmpty()
            return SplitBillViewModel(
                SplitBillUiState(billText = bill, people = numberedPeople(DEFAULT_PEOPLE), showsStepper = true, placeName = placeName),
                payIds,
            )
        }

        /** From Group detail: "You" then each accepted guest, no stepper. */
        fun forGroup(placeName: String?, guestNames: List<String>, payIds: PayIdStore): SplitBillViewModel =
            SplitBillViewModel(
                SplitBillUiState(people = listOf(SplitPerson.You) + guestNames.map(SplitPerson::Named), placeName = placeName),
                payIds,
            )

        private fun numberedPeople(count: Int): List<SplitPerson> =
            listOf(SplitPerson.You) + (2..count).map(SplitPerson::Numbered)

        /** Runs the engine over the typed values. An empty adjusted row counts as $0.00. */
        private fun SplitBillUiState.recomputed(): SplitBillUiState {
            val request = BillSplitRequest(
                billCents = SplitMoney.cents(billText) ?: 0L,
                people = people.size,
                surchargeBps = surchargeText.trim().toDoubleOrNull()?.let(BillSplitEngine::percentToBps) ?: 0,
                fixedCents = adjustedText.mapValues { (_, text) -> SplitMoney.cents(text) ?: 0L },
            )
            return copy(result = BillSplitEngine.split(request))
        }
    }
}
