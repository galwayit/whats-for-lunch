/**
 * @file GuestRow.kt
 * @description One guest in a group's RSVP list: initial avatar, name, and a status capsule.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.Rsvp
import au.iapp.lunch.ui.preview.RsvpStatus
import au.iapp.lunch.ui.theme.LunchColors
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

object GuestRowDefaults {
    val avatarSize: Dp = TokenSize.touchTarget - TokenSpacing.sm
}

/** The status colour: `success` accepted, `danger` declined, `textSecondary` pending. */
@Composable
fun RsvpStatus.tint(): Color = when (this) {
    RsvpStatus.ACCEPTED -> LunchTheme.colors.success
    RsvpStatus.DECLINED -> LunchTheme.colors.danger
    RsvpStatus.PENDING -> LunchTheme.colors.textSecondary
}

@Composable
fun GuestRow(rsvp: Rsvp, modifier: Modifier = Modifier) {
    val tint = rsvp.status.tint()
    val statusLabel = stringResource(
        when (rsvp.status) {
            RsvpStatus.ACCEPTED -> R.string.group_detail_accepted
            RsvpStatus.DECLINED -> R.string.group_detail_declined
            RsvpStatus.PENDING -> R.string.group_detail_pending
        },
    )
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = TokenSpacing.sm)
            .semantics(mergeDescendants = true) {},
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm + TokenSpacing.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        InitialAvatar(name = rsvp.displayName, size = GuestRowDefaults.avatarSize)
        LunchText(text = rsvp.displayName, role = LunchTextRole.Body, modifier = Modifier.weight(1f), maxLines = 1)
        LunchText(
            text = statusLabel,
            role = LunchTextRole.Label,
            color = tint,
            modifier = Modifier
                .background(tint.copy(alpha = LunchColors.SOFT_TINT_ALPHA), LunchTheme.shapes.chip)
                .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs),
        )
    }
}

@LunchPreviews
@Composable
private fun GuestRowPreview() {
    LunchPreviewSurface {
        Column { PreviewData.rsvps.forEach { GuestRow(it) } }
    }
}
