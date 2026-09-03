/**
 * @file ProBadge.kt
 * @description The small "PRO" capsule that marks Lunch Pro features and subscribers.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

object ProBadgeDefaults {
    val iconSize: Dp = TokenSize.iconDefault - TokenSpacing.sm - TokenSpacing.xs
}

/** Announced as "Lunch Pro" rather than the letters. */
@Composable
fun ProBadge(modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val a11yLabel = stringResource(R.string.paywall_pro_badge_a11y)
    Row(
        modifier = modifier
            .background(colors.primarySoft, LunchTheme.shapes.chip)
            .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs)
            .clearAndSetSemantics { contentDescription = a11yLabel },
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        LunchIconView(icon = LunchIcon.WorkspacePremium, size = ProBadgeDefaults.iconSize, filled = true, tint = colors.primary)
        LunchText(text = stringResource(R.string.paywall_pro_badge), role = LunchTextRole.Label, color = colors.primary)
    }
}

@LunchPreviews
@Composable
private fun ProBadgePreview() {
    LunchPreviewSurface { ProBadge() }
}
