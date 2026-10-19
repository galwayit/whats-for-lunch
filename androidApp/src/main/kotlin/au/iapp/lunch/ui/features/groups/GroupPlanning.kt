package au.iapp.lunch.ui.features.groups

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import au.iapp.lunch.core.model.*
import au.iapp.lunch.ui.components.*
import au.iapp.lunch.ui.features.shared.*
import au.iapp.lunch.ui.theme.*
import java.math.BigDecimal
import java.time.Instant
import java.time.ZoneId

val paymentArrangements = linkedMapOf("undecided" to "To be confirmed", "pay_own" to "Everyone pays their own", "split_equally" to "Split equally", "host_pays" to "Host's treat")
val paymentMethods = linkedMapOf("undecided" to "To be confirmed", "at_venue" to "Pay at the venue", "cash" to "Cash", "card" to "Card", "bank_transfer" to "Bank transfer")
fun LunchGroup.details() = GroupDetails(hostName, budgetPerPersonMinor, currencyCode, paymentArrangement, paymentMethod)
fun GroupDetails.budgetDescription(): String = budgetPerPersonMinor?.let { "Budget: $currencyCode ${BigDecimal.valueOf(it, 2)} per person" } ?: "Budget: to be confirmed"
@Composable fun CoreError.planningMessage(): String = if (this is CoreError.Service && code in setOf("BAD_REQUEST", "NAME_REQUIRED", "NOT_FOUND", "FORBIDDEN")) message else errorToast(this)

data class GroupDetailsDraft(val hostName: String = "", val budget: String = "", val arrangement: String = "undecided", val method: String = "undecided") {
    constructor(value: GroupDetails) : this(value.hostName, value.budgetPerPersonMinor?.let { BigDecimal.valueOf(it, 2).toPlainString() }.orEmpty(), value.paymentArrangement, value.paymentMethod)
    fun value(): GroupDetails? {
        val name = hostName.trim()
        if (name.isBlank() || name.length > 60) return null
        val text = budget.trim()
        val cents = if (text.isBlank()) null else {
            if (!text.matches(Regex("^[0-9]+([.,][0-9]{1,2})?$"))) return null
            val amount = text.replace(',', '.').toBigDecimalOrNull() ?: return null
            if (amount > BigDecimal(10000)) return null
            amount.movePointRight(2).longValueExact()
        }
        return GroupDetails(name, cents, "AUD", arrangement, method)
    }
}

@Composable fun GroupDetailsFields(draft: GroupDetailsDraft, onChange: (GroupDetailsDraft) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        LunchText("Invitation details", role = LunchTextRole.Heading)
        LunchTextField(draft.hostName, { onChange(draft.copy(hostName = it)) }, label = "Host name", placeholder = "Name shown to guests", modifier = Modifier.fillMaxWidth())
        LunchTextField(draft.budget, { onChange(draft.copy(budget = it)) }, label = "Budget per person (AUD)", placeholder = "Optional, e.g. 25.00", keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), modifier = Modifier.fillMaxWidth())
        LunchText("Leave the budget blank if it is still to be confirmed.", role = LunchTextRole.Caption)
        PlanningPicker("Who pays", draft.arrangement, paymentArrangements) { onChange(draft.copy(arrangement = it)) }
        PlanningPicker("How to pay", draft.method, paymentMethods) { onChange(draft.copy(method = it)) }
        LunchText("This records the plan for the meal. No money is collected here.", role = LunchTextRole.Caption)
    }
}
@Composable private fun PlanningPicker(label: String, value: String, options: Map<String, String>, onChange: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        TextButton(onClick = { expanded = true }) { LunchText("$label: ${options[value] ?: "To be confirmed"}", role = LunchTextRole.Body) }
        DropdownMenu(expanded, { expanded = false }) {
            options.forEach { (key, title) -> DropdownMenuItem(text = { Text(title) }, onClick = { onChange(key); expanded = false }) }
        }
    }
}
@Composable fun GroupPlanningSummary(details: GroupDetails) {
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        LunchText("Host: ${details.hostName.ifBlank { "Name not provided" }}", role = LunchTextRole.BodySmall)
        LunchText(details.budgetDescription(), role = LunchTextRole.BodySmall)
        LunchText("Who pays: ${paymentArrangements[details.paymentArrangement] ?: "To be confirmed"}", role = LunchTextRole.BodySmall)
        LunchText("Payment: ${paymentMethods[details.paymentMethod] ?: "To be confirmed"}", role = LunchTextRole.BodySmall)
    }
}
@Composable fun SuggestionSummary(suggestion: GroupSuggestion) {
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        suggestion.placeName?.let { LunchText(it, role = LunchTextRole.Heading) }
        suggestion.placeAddress?.let { LunchText(it, role = LunchTextRole.BodySmall) }
        suggestion.scheduledAtEpochSeconds?.let { LunchText(LunchFormat.dayTime(it), role = LunchTextRole.Body) }
        suggestion.note?.let { LunchText(it, role = LunchTextRole.BodySmall) }
    }
}
fun GroupSuggestion.statusLabel() = when(status) {
    "accepted" -> "Host applied your suggestion"
    "declined" -> "Host kept the current plan"
    "superseded" -> "The plan has changed — check the latest details"
    else -> "Waiting for the host to review"
}
@Composable fun GroupDetailsDialog(details: GroupDetails, saving: Boolean, error: CoreError?, onDismiss: () -> Unit, onSave: (GroupDetails) -> Unit) {
    var host by rememberSaveable { mutableStateOf(details.hostName) }
    var budget by rememberSaveable { mutableStateOf(GroupDetailsDraft(details).budget) }
    var arrangement by rememberSaveable { mutableStateOf(details.paymentArrangement) }
    var method by rememberSaveable { mutableStateOf(details.paymentMethod) }
    val draft = GroupDetailsDraft(host, budget, arrangement, method)
    Dialog(onDismissRequest = { if (!saving) onDismiss() }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        ModalScreen(onBack = { if (!saving) onDismiss() }) {
            ScreenHeader("Edit invitation", onDismiss = { if (!saving) onDismiss() })
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(TokenSpacing.page), verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg)) {
                GroupDetailsFields(draft) { host = it.hostName; budget = it.budget; arrangement = it.arrangement; method = it.method }
                LunchText("Changing the budget or payment plan resets RSVPs. Guests will need to respond again.", role = LunchTextRole.BodySmall)
                error?.let { LunchText(it.planningMessage(), role = LunchTextRole.BodySmall, color = LunchTheme.colors.danger) }
                LunchButton("Save details", { draft.value()?.let(onSave) }, loading = saving, enabled = draft.value() != null, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}
/** Date/time stays local to the device; only epoch seconds cross the API boundary. */
@Composable fun AlternativeTime(epochSeconds: Long, onChange: (Long) -> Unit) {
    val context = LocalContext.current
    val time = Instant.ofEpochSecond(epochSeconds).atZone(ZoneId.systemDefault())
    LunchButton(LunchFormat.dayTime(epochSeconds), {
        android.app.DatePickerDialog(context, { _, year, month, day ->
            android.app.TimePickerDialog(context, { _, hour, minute ->
                onChange(java.time.LocalDate.of(year, month + 1, day).atTime(hour, minute).atZone(ZoneId.systemDefault()).toEpochSecond())
            }, time.hour, time.minute, android.text.format.DateFormat.is24HourFormat(context)).show()
        }, time.year, time.monthValue - 1, time.dayOfMonth).show()
    }, style = LunchButtonStyle.Secondary)
}
