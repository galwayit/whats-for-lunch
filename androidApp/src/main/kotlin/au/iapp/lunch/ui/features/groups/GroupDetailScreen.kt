/**
 * @file GroupDetailScreen.kt
 * @description Screen 15 of design/screens.md: the confirmed place, invite link, guest list,
 * reminder switch, calendar and directions, and cancel. Once a place is confirmed, "Split the
 * bill" opens the split sheet; "Use my share" logs the host's share as a meal. "Show QR code"
 * opens the invite QR sheet.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.groups

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.AvatarStack
import au.iapp.lunch.ui.components.GuestRow
import au.iapp.lunch.ui.components.InviteShareRow
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.features.shared.lunchSwitchColors
import au.iapp.lunch.ui.features.split.SharedPreferencesPayIdStore
import au.iapp.lunch.ui.features.split.SplitBillDefaults
import au.iapp.lunch.ui.features.split.SplitBillSheet
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun GroupDetailScreen(groupId: String, modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: GroupDetailViewModel = viewModel(key = "group:$groupId") { GroupDetailViewModel(app, groupId) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val colors = LunchTheme.colors
    val cancelledText = stringResource(R.string.group_cancelled)
    val loggedText = stringResource(R.string.track_log_logged)
    val split by viewModel.split.collectAsStateWithLifecycle()
    var applyingSuggestionId by rememberSaveable { mutableStateOf<String?>(null) }
    var showsQr by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(state.didLogShare) {
        if (state.didLogShare) {
            app.showToast(loggedText)
            viewModel.consumeLoggedShare()
        }
    }

    LaunchedEffect(state.isCancelled) {
        if (state.isCancelled) {
            app.showToast(cancelledText)
            app.dismiss()
        }
    }

    ModalScreen(onBack = app::dismiss, modifier = modifier) {
        val group = state.group
        ScreenHeader(title = group?.name ?: stringResource(R.string.home_group_row_title), onDismiss = app::dismiss)
        if (group == null) return@ModalScreen
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
        ) {
            LunchCard(modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                    GroupPlanningSummary(group.details())
                    if (state.isHost) LunchButton("Edit invitation details", { viewModel.setEditing(true) }, style = LunchButtonStyle.Secondary)
                    LunchText(text = group.placeName ?: group.name, role = LunchTextRole.Heading)
                    group.placeAddress?.let { LunchText(text = it, role = LunchTextRole.BodySmall, color = colors.textSecondary) }
                    LunchText(text = LunchFormat.dayTime(group.scheduledAtEpochSeconds), role = LunchTextRole.BodySmall, color = colors.textSecondary)
                }
            }
            if (state.isHost) {
                SectionTitle("Guest suggestions")
                LunchButton("Refresh suggestions", viewModel::refresh, style = LunchButtonStyle.Secondary)
                state.suggestionsError?.let { LunchText(it.planningMessage(), role = LunchTextRole.BodySmall, color = colors.danger) }
                if (state.suggestions.isEmpty() && state.suggestionsError == null) LunchText("Guests can suggest a different place or time from their invitation.", role = LunchTextRole.BodySmall)
                state.suggestions.forEach { suggestion ->
                    LunchCard {
                        LunchText("From ${suggestion.displayName}", role = LunchTextRole.Heading)
                        SuggestionSummary(suggestion)
                        if (suggestion.status == "pending") {
                            LunchButton("Apply suggestion", { applyingSuggestionId = suggestion.id }, enabled = !state.reviewing)
                            LunchButton("Keep current plan", { viewModel.review(suggestion.id, false) }, enabled = !state.reviewing, style = LunchButtonStyle.Secondary)
                        } else LunchText(suggestion.status.replaceFirstChar { it.uppercase() }, role = LunchTextRole.Caption)
                    }
                }
            }
            if (state.canSplit) {
                LunchButton(
                    text = stringResource(R.string.split_group_open),
                    onClick = { viewModel.openSplit(SharedPreferencesPayIdStore.from(context)) },
                    icon = LunchIcon.Payments,
                    style = LunchButtonStyle.Secondary,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag(SplitBillDefaults.GROUP_BUTTON_TAG),
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                SectionTitle(text = stringResource(R.string.group_detail_invite))
                InviteShareRow(
                    inviteUrl = state.inviteUrl,
                    onShare = { Intents.share(context, state.inviteUrl, group.name) },
                    onShowQr = { showsQr = true }.takeIf { state.inviteUrl.isNotEmpty() },
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    SectionTitle(text = stringResource(R.string.group_detail_guests), modifier = Modifier.weight(1f))
                    AvatarStack(names = state.rsvps.filter { it.status.name == "ACCEPTED" }.map { it.displayName })
                }
                state.rsvps.forEach { rsvp -> GuestRow(rsvp = rsvp.toView()) }
            }
            LunchCard(modifier = Modifier.fillMaxWidth()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    LunchText(text = stringResource(R.string.group_detail_reminder), role = LunchTextRole.Body, modifier = Modifier.weight(1f))
                    Switch(checked = state.reminderOn, onCheckedChange = viewModel::setReminder, colors = lunchSwitchColors())
                }
            }
            // Full width each: "Add to calendar" does not fit half a phone screen.
            LunchButton(text = stringResource(R.string.action_add_to_calendar), onClick = { Intents.addToCalendar(context, group) }, icon = LunchIcon.CalendarToday, style = LunchButtonStyle.Secondary, modifier = Modifier.fillMaxWidth())
            LunchButton(text = stringResource(R.string.action_directions), onClick = { Intents.directions(context, group) }, icon = LunchIcon.Directions, style = LunchButtonStyle.Secondary, enabled = group.placeId != null, modifier = Modifier.fillMaxWidth())
            state.error?.let { LunchText(text = errorToast(it), role = LunchTextRole.Caption, color = colors.danger) }
            if (state.isHost) LunchButton(text = stringResource(R.string.group_detail_cancel), onClick = viewModel::cancel, style = LunchButtonStyle.Text, loading = state.isCancelling, modifier = Modifier.fillMaxWidth())
        }
    }
    applyingSuggestionId?.let { id ->
        androidx.compose.material3.AlertDialog(onDismissRequest = { applyingSuggestionId = null },
            title = { LunchText("Apply this suggestion?", role = LunchTextRole.Heading) },
            text = { LunchText("All guests will need to RSVP again. Share the updated invitation so they can check the new plan.", role = LunchTextRole.Body) },
            confirmButton = { androidx.compose.material3.TextButton(onClick = { viewModel.review(id, true); applyingSuggestionId = null }) { LunchText("Update lunch", role = LunchTextRole.Button) } },
            dismissButton = { androidx.compose.material3.TextButton(onClick = { applyingSuggestionId = null }) { LunchText("Cancel", role = LunchTextRole.Button) } })
    }
    if (state.editing) state.group?.let { GroupDetailsDialog(it.details(), state.saving, state.error, { viewModel.setEditing(false) }, viewModel::saveDetails) }
    split?.let { sheet ->
        SplitBillSheet(
            viewModel = sheet,
            onDismiss = viewModel::closeSplit,
            onUseShare = viewModel::logSplitShare,
            isUsingShare = state.isLoggingShare,
            hostError = state.error?.let { errorToast(it) },
        )
    }
    if (showsQr && state.inviteUrl.isNotEmpty()) {
        InviteQrSheet(inviteUrl = state.inviteUrl, onDismiss = { showsQr = false })
    }
}
