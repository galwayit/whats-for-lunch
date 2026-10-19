/**
 * @file InvitationCard.kt
 * @description The invitation landing card: who invited you, where and when, who is already
 * going, and the Decline / Accept actions.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchGroup
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.Rsvp
import au.iapp.lunch.ui.preview.RsvpStatus
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

object InvitationCardDefaults {
    val avatarSize: Dp = TokenSize.iconDefault + TokenSpacing.sm
    val avatarOverlap: Dp = TokenSpacing.sm
    const val MAX_AVATARS = 4
    val contentPadding: PaddingValues = PaddingValues(TokenSpacing.lg)
}

/**
 * @param rsvps Everyone invited; only accepted guests are counted and stacked.
 * @param responding True while an Accept is in flight: Accept spins, Decline disables.
 */
@Composable
fun InvitationCard(
    group: LunchGroup,
    rsvps: List<Rsvp>,
    onAccept: () -> Unit,
    onDecline: () -> Unit,
    modifier: Modifier = Modifier,
    responding: Boolean = false,
    formatTime: (Long) -> String = ::formatLunchTime,
    formatDate: (Long) -> String = ::formatLunchDate,
) {
    val colors = LunchTheme.colors
    val going = rsvps.filter { it.status == RsvpStatus.ACCEPTED }
    LunchCard(modifier = modifier, contentPadding = InvitationCardDefaults.contentPadding) {
        LunchText(text = stringResource(R.string.invite_title, group.hostName), role = LunchTextRole.Title)
        LunchText(
            text = group.name,
            role = LunchTextRole.Body,
            color = colors.textSecondary,
            modifier = Modifier.padding(top = TokenSpacing.xs),
        )
        Column(
            modifier = Modifier.padding(vertical = TokenSpacing.md),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        ) {
            group.placeName?.let { DetailRow(LunchIcon.Restaurant, it) }
            group.placeAddress?.let { DetailRow(LunchIcon.LocationOn, it) }
            DetailRow(
                LunchIcon.Schedule,
                listOf(formatDate(group.scheduledAtEpochSeconds), formatTime(group.scheduledAtEpochSeconds))
                    .joinToString(RestaurantCardDefaults.META_SEPARATOR),
            )
        }
        au.iapp.lunch.ui.features.groups.GroupPlanningSummary(group.details.copy(hostName = group.hostName))
        Row(
            modifier = Modifier.padding(bottom = TokenSpacing.md),
            horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AvatarStack(names = going.map { it.displayName })
            LunchText(text = stringResource(R.string.invite_attending, going.size), role = LunchTextRole.Caption, color = colors.primary)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchButton(
                text = stringResource(R.string.invite_decline),
                onClick = onDecline,
                modifier = Modifier.weight(1f),
                style = LunchButtonStyle.Secondary,
                enabled = !responding,
            )
            LunchButton(
                text = stringResource(R.string.invite_accept),
                onClick = onAccept,
                modifier = Modifier.weight(1f),
                style = LunchButtonStyle.Primary,
                loading = responding,
            )
        }
    }
}

@Composable
private fun DetailRow(icon: LunchIcon, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
        LunchIconView(icon = icon, size = TokenSize.iconDefault - TokenSpacing.xs, tint = LunchTheme.colors.textSecondary)
        LunchText(text = text, role = LunchTextRole.BodySmall)
    }
}

/** Up to four overlapping initial avatars. */
@Composable
fun AvatarStack(names: List<String>, modifier: Modifier = Modifier) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(-InvitationCardDefaults.avatarOverlap)) {
        names.take(InvitationCardDefaults.MAX_AVATARS).forEach { name ->
            InitialAvatar(
                name = name,
                size = InvitationCardDefaults.avatarSize,
                textRole = LunchTextRole.Caption,
            )
        }
    }
}

@LunchPreviews
@Composable
private fun InvitationCardPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            InvitationCard(PreviewData.group, PreviewData.rsvps, onAccept = {}, onDecline = {}, modifier = Modifier.fillMaxWidth())
            InvitationCard(PreviewData.group, PreviewData.rsvps, onAccept = {}, onDecline = {}, modifier = Modifier.fillMaxWidth(), responding = true)
        }
    }
}
