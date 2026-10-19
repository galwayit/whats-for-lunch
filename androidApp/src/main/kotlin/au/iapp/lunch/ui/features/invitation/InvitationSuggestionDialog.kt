package au.iapp.lunch.ui.features.invitation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import au.iapp.lunch.core.model.*
import au.iapp.lunch.ui.components.*
import au.iapp.lunch.ui.features.groups.*
import au.iapp.lunch.ui.features.shared.*
import au.iapp.lunch.ui.theme.*

@Composable fun InvitationSuggestionDialog(state: InvitationUiState, onName: (String) -> Unit, onDismiss: () -> Unit, onSend: (GroupSuggestionDraft) -> Unit) {
    var place by rememberSaveable { mutableStateOf("") }
    var address by rememberSaveable { mutableStateOf("") }
    var note by rememberSaveable { mutableStateOf("") }
    var changeTime by rememberSaveable { mutableStateOf(false) }
    var time by rememberSaveable { mutableStateOf(maxOf(state.invitation.valueOrNull()?.group?.scheduledAtEpochSeconds ?: 0L, System.currentTimeMillis() / 1000 + 3600)) }
    Dialog(onDismissRequest = { if (!state.isResponding) onDismiss() }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        ModalScreen(onBack = { if (!state.isResponding) onDismiss() }, modifier = Modifier.imePadding()) {
            ScreenHeader("Suggest a change", onDismiss = { if (!state.isResponding) onDismiss() })
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(TokenSpacing.page), verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg)) {
                LunchText("Suggest another place, time, or both. The host decides whether to change the plan. Your RSVP stays the same until then.", role = LunchTextRole.Body)
                LunchTextField(state.displayName, onName, label = "Your name", modifier = Modifier.fillMaxWidth())
                LunchTextField(place, { place = it }, label = "Alternative place (optional)", modifier = Modifier.fillMaxWidth())
                LunchTextField(address, { address = it }, label = "Address (optional)", modifier = Modifier.fillMaxWidth())
                Row { LunchText("Suggest another time", role = LunchTextRole.Body, modifier = Modifier.weight(1f)); Switch(changeTime, { changeTime = it }) }
                if (changeTime) AlternativeTime(time) { time = it }
                LunchTextField(note, { note = it }, label = "Note for the host (optional)", modifier = Modifier.fillMaxWidth())
                state.respondError?.let { LunchText(it.planningMessage(), role = LunchTextRole.BodySmall, color = LunchTheme.colors.danger) }
                LunchButton("Send suggestion", { onSend(GroupSuggestionDraft(place.trim().ifBlank { null }, address.trim().ifBlank { null }, time.takeIf { changeTime }, note.trim().ifBlank { null })) }, enabled = state.displayName.isNotBlank() && (place.isNotBlank() || changeTime), loading = state.isResponding, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}
private fun LoadState<Invitation>.valueOrNull(): Invitation? = (this as? LoadState.Loaded)?.value
