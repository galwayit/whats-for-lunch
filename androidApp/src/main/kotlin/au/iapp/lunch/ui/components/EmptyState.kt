/**
 * @file EmptyState.kt
 * @description Centred empty and error states: a tinted disc with an icon, title, message, and
 * an optional action button.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchColors
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

enum class EmptyStateVariant(val icon: LunchIcon) {
    NothingHere(LunchIcon.RestaurantMenu),
    Offline(LunchIcon.WifiOff),
    ServiceProblem(LunchIcon.CloudOff),
}

object EmptyStateDefaults {
    val discSize: Dp = TokenSize.touchTarget * 2
    val iconSize: Dp = TokenSize.iconDefault + TokenSpacing.sm
}

/** The variant's tint: `primary` for empty, `warning` offline, `danger` for service errors. */
@Composable
fun EmptyStateVariant.tint(): Color = when (this) {
    EmptyStateVariant.NothingHere -> LunchTheme.colors.primary
    EmptyStateVariant.Offline -> LunchTheme.colors.warning
    EmptyStateVariant.ServiceProblem -> LunchTheme.colors.danger
}

/**
 * @param actionLabel Button label; the button is omitted when null.
 */
@Composable
fun EmptyState(
    variant: EmptyStateVariant,
    title: String,
    message: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: () -> Unit = {},
) {
    val colors = LunchTheme.colors
    val tint = variant.tint()
    Column(
        modifier = modifier.padding(TokenSpacing.lg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        Box(
            modifier = Modifier
                .size(EmptyStateDefaults.discSize)
                .background(tint.copy(alpha = LunchColors.SOFT_TINT_ALPHA), LunchTheme.shapes.chip),
            contentAlignment = Alignment.Center,
        ) {
            LunchIconView(icon = variant.icon, size = EmptyStateDefaults.iconSize, tint = tint)
        }
        LunchText(text = title, role = LunchTextRole.Heading, textAlign = TextAlign.Center)
        LunchText(text = message, role = LunchTextRole.BodySmall, color = colors.textSecondary, textAlign = TextAlign.Center)
        if (actionLabel != null) {
            LunchButton(text = actionLabel, onClick = onAction, style = LunchButtonStyle.Secondary)
        }
    }
}

@LunchPreviews
@Composable
private fun EmptyStatePreview() {
    LunchPreviewSurface {
        Column(modifier = Modifier.fillMaxWidth()) {
            EmptyState(
                variant = EmptyStateVariant.NothingHere,
                title = stringResource(R.string.discover_empty_title),
                message = stringResource(R.string.discover_empty_body),
                modifier = Modifier.fillMaxWidth(),
            )
            EmptyState(
                variant = EmptyStateVariant.Offline,
                title = stringResource(R.string.error_offline_title),
                message = stringResource(R.string.error_offline_body),
                modifier = Modifier.fillMaxWidth(),
                actionLabel = stringResource(R.string.action_retry),
            )
            EmptyState(
                variant = EmptyStateVariant.ServiceProblem,
                title = stringResource(R.string.error_service_title),
                message = stringResource(R.string.error_service_body),
                modifier = Modifier.fillMaxWidth(),
                actionLabel = stringResource(R.string.action_retry),
            )
        }
    }
}
