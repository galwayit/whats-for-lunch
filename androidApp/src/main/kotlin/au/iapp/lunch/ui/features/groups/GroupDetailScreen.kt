/**
 * @file GroupDetailScreen.kt
 * @description Screen 15 of design/screens.md: the confirmed place, invite link, guest list,
 * reminder switch, calendar and directions, and cancel.
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
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
                    LunchText(text = group.placeName ?: group.name, role = LunchTextRole.Heading)
                    group.placeAddress?.let { LunchText(text = it, role = LunchTextRole.BodySmall, color = colors.textSecondary) }
                    LunchText(text = LunchFormat.dayTime(group.scheduledAtEpochSeconds), role = LunchTextRole.BodySmall, color = colors.textSecondary)
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                SectionTitle(text = stringResource(R.string.group_detail_invite))
                InviteShareRow(inviteUrl = state.inviteUrl, onShare = { Intents.share(context, state.inviteUrl, group.name) })
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
            LunchButton(text = stringResource(R.string.group_detail_cancel), onClick = viewModel::cancel, style = LunchButtonStyle.Text, loading = state.isCancelling, modifier = Modifier.fillMaxWidth())
        }
    }
}
