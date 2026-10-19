/**
 * @file InvitationScreen.kt
 * @description Screen 16 of design/screens.md: the invitation card with accept and decline,
 * the name prompt for guests who are signed out, the accepted and declined states and the
 * one-time Pro offer for repeat guests.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.invitation

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.ui.components.AILoading
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant
import au.iapp.lunch.ui.components.InvitationCard
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.groups.*
import au.iapp.lunch.ui.features.shared.ErrorStateView
import au.iapp.lunch.ui.features.shared.HeaderDismiss
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun InvitationScreen(code: String, modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val context = LocalContext.current
    val viewModel: InvitationViewModel = viewModel(key = "invitation:$code") {
        InvitationViewModel(app, code, context.getSharedPreferences(InvitationViewModel.PREFS_NAME, Context.MODE_PRIVATE))
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors

    ModalScreen(onBack = app::dismiss, modifier = modifier.imePadding()) {
        ScreenHeader(title = stringResource(R.string.invitation_title), dismiss = HeaderDismiss.Close, onDismiss = app::dismiss)
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
        ) {
            when (val invitation = state.invitation) {
                LoadState.Idle, LoadState.Loading -> AILoading(title = stringResource(R.string.a11y_loading), modifier = Modifier.fillMaxWidth())
                is LoadState.Failed -> if (invitation.error.isMissing()) {
                    EmptyState(
                        variant = EmptyStateVariant.NothingHere,
                        title = stringResource(R.string.invitation_missing_title),
                        message = stringResource(R.string.invitation_missing_body),
                        actionLabel = stringResource(R.string.action_close),
                        onAction = app::dismiss,
                    )
                } else {
                    ErrorStateView(error = invitation.error, onRetry = viewModel::load)
                }
                is LoadState.Loaded -> when (invitation.value.myStatus) {
                    RsvpStatus.ACCEPTED -> Responded(invitation.value, accepted = true, showOffer = state.showGuestOffer, onOffer = { app.present(AppRoute.Paywall) }, onCalendar = { Intents.addToCalendar(context, invitation.value.group) }, onDirections = { Intents.directions(context, invitation.value.group) })
                    RsvpStatus.DECLINED -> Responded(invitation.value, accepted = false, showOffer = false, onOffer = {}, onCalendar = {}, onDirections = {})
                    else -> {
                        if (app.session.collectAsStateWithLifecycle().value == null) {
                            LunchTextField(
                                value = state.displayName,
                                onValueChange = viewModel::setDisplayName,
                                placeholder = stringResource(R.string.invite_name_prompt),
                                // The field is pre-filled with the local profile name, so the prompt
                                // has to be a label as well or a guest never sees what it is for.
                                label = stringResource(R.string.invite_name_prompt),
                                leadingIcon = LunchIcon.Person,
                                modifier = Modifier.fillMaxWidth(),
                            )
                        }
                        InvitationCard(
                            group = invitation.value.group.toView(),
                            rsvps = invitation.value.attendees.map { it.toView() },
                            onAccept = viewModel::accept,
                            onDecline = viewModel::decline,
                            responding = state.isResponding,
                            formatTime = LunchFormat::time,
                            formatDate = LunchFormat::day,
                        )
                        state.respondError?.let { LunchText(text = it.planningMessage(), role = LunchTextRole.Caption, color = colors.danger) }
                    }
                }
            }
            (state.invitation as? LoadState.Loaded)?.value?.let { invitation ->
                LunchButton("Refresh invitation", viewModel::load, style = LunchButtonStyle.Secondary, enabled = !state.isResponding)
                invitation.mySuggestion?.let { suggestion ->
                    LunchCard {
                        LunchText(suggestion.statusLabel(), role = LunchTextRole.Heading)
                        SuggestionSummary(suggestion)
                    }
                }
                if (invitation.mySuggestion?.status != "pending") {
                    LunchButton("Suggest another place or time", { viewModel.showSuggestion(true) }, style = LunchButtonStyle.Secondary, enabled = !state.isResponding, modifier = Modifier.fillMaxWidth())
                }
            }
        }
    }
    if (state.showSuggestion) InvitationSuggestionDialog(state, viewModel::setDisplayName, { viewModel.showSuggestion(false) }, viewModel::suggest)
}

@Composable
private fun Responded(
    invitation: Invitation,
    accepted: Boolean,
    showOffer: Boolean,
    onOffer: () -> Unit,
    onCalendar: () -> Unit,
    onDirections: () -> Unit,
) {
    val colors = LunchTheme.colors
    val group = invitation.group
    LunchCard(modifier = Modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchText(text = stringResource(if (accepted) R.string.invite_accepted_title else R.string.invite_declined_title), role = LunchTextRole.Title, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
            GroupPlanningSummary(group.details())
            LunchText(text = stringResource(R.string.invite_title, group.hostName), role = LunchTextRole.Body, color = colors.textSecondary)
            LunchText(text = (group.placeName ?: group.name) + "\n" + LunchFormat.dayTime(group.scheduledAtEpochSeconds), role = LunchTextRole.BodySmall)
            LunchText(text = stringResource(R.string.invite_attending, invitation.attendees.count { it.status == RsvpStatus.ACCEPTED }), role = LunchTextRole.Caption, color = colors.textSecondary)
            if (accepted) {
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    LunchButton(text = stringResource(R.string.action_add_to_calendar), onClick = onCalendar, icon = LunchIcon.CalendarToday, style = LunchButtonStyle.Secondary, modifier = Modifier.weight(1f))
                    LunchButton(text = stringResource(R.string.action_directions), onClick = onDirections, icon = LunchIcon.Directions, style = LunchButtonStyle.Secondary, enabled = group.placeId != null, modifier = Modifier.weight(1f))
                }
            }
        }
    }
    if (showOffer) {
        UpsellRow(
            title = stringResource(R.string.gate_guest_offer_title),
            body = stringResource(R.string.gate_guest_offer_body),
            ctaLabel = stringResource(R.string.invite_get_app),
            onCta = onOffer,
        )
    }
}

private fun au.iapp.lunch.core.model.CoreError.isMissing(): Boolean =
    this is au.iapp.lunch.core.model.CoreError.Service && (code == "NOT_FOUND" || code == "INVITATION_NOT_FOUND" || code == "GROUP_CANCELLED")
