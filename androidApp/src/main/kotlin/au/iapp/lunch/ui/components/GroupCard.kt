/**
 * @file GroupCard.kt
 * @description Home and Profile row for a group lunch: group disc, name, place and time, the
 * going count, and a chevron.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchGroup
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/**
 * @param attendingCount Number of accepted RSVPs.
 * @param formatTime Formats the scheduled time; defaults to the device time zone.
 */
@Composable
fun GroupCard(
    group: LunchGroup,
    attendingCount: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    formatTime: (Long) -> String = ::formatLunchTime,
) {
    val colors = LunchTheme.colors
    val subtitle = listOfNotNull(group.placeName, formatTime(group.scheduledAtEpochSeconds))
        .joinToString(RestaurantCardDefaults.META_SEPARATOR)
    LunchCard(modifier = modifier, onClick = onClick) {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm + TokenSpacing.xs), verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(TokenSize.touchTarget)
                    .background(colors.primarySoft, LunchTheme.shapes.chip),
                contentAlignment = Alignment.Center,
            ) {
                LunchIconView(icon = LunchIcon.Group, tint = colors.primary)
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                LunchText(text = group.name, role = LunchTextRole.Heading, maxLines = 1)
                LunchText(text = subtitle, role = LunchTextRole.Caption, color = colors.textSecondary, maxLines = 1)
                LunchText(text = stringResource(R.string.invite_attending, attendingCount), role = LunchTextRole.Caption, color = colors.primary)
            }
            LunchIconView(icon = LunchIcon.ChevronRight, tint = colors.textSecondary)
        }
    }
}

@LunchPreviews
@Composable
private fun GroupCardPreview() {
    LunchPreviewSurface {
        GroupCard(group = PreviewData.group, attendingCount = 2, onClick = {}, modifier = Modifier.fillMaxWidth())
    }
}
