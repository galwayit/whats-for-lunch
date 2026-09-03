/**
 * @file WeeklyBudgetStrip.kt
 * @description Compact weekly-budget summary for the Home screen: spent of capacity, a thin
 * progress bar in the capacity tone, and the experiences count.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.ripple
import androidx.compose.foundation.clickable
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.WeeklyBudget
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object WeeklyBudgetStripDefaults {
    val barHeight: Dp = TokenSpacing.sm
}

/**
 * @param formatAmount Currency formatter for the amounts; the shared module will supply one.
 * @param onClick Optional tap-through to the Track screen.
 */
@Composable
fun WeeklyBudgetStrip(
    budget: WeeklyBudget,
    modifier: Modifier = Modifier,
    formatAmount: (Double) -> String = PreviewData::currency,
    onClick: (() -> Unit)? = null,
) {
    val colors = LunchTheme.colors
    val progress = budget.capacityProgress.toFloat()
    val clamped = progress.coerceIn(0f, 1f)
    val animated by animateFloatAsState(
        targetValue = clamped,
        animationSpec = if (LunchTheme.reduceMotion) snap() else LunchMotion.fadeIn(),
        label = "budgetBar",
    )
    val tone = colors.toneColor(CapacityTone.from(progress))

    LunchCard(modifier = modifier, onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            LunchText(
                text = stringResource(R.string.track_ring_label, formatAmount(budget.currentSpent), formatAmount(budget.weeklyCapacity)),
                role = LunchTextRole.Body,
                modifier = Modifier.weight(1f),
            )
            LunchText(
                text = stringResource(R.string.track_ring_remaining, formatAmount(budget.remainingCapacity)),
                role = LunchTextRole.Caption,
                color = tone,
            )
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(WeeklyBudgetStripDefaults.barHeight)
                .clip(LunchTheme.shapes.chip)
                .background(colors.hairline)
                .semantics { progressBarRangeInfo = ProgressBarRangeInfo(clamped, 0f..1f) },
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(animated)
                    .fillMaxHeight()
                    .background(tone, LunchTheme.shapes.chip),
            )
        }
        LunchText(
            text = stringResource(R.string.track_experiences, budget.experiencesLogged, budget.targetExperiences),
            role = LunchTextRole.Caption,
            color = colors.textSecondary,
        )
    }
}

@LunchPreviews
@Composable
private fun WeeklyBudgetStripPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            WeeklyBudgetStrip(budget = PreviewData.weeklyBudget, modifier = Modifier.fillMaxWidth())
            WeeklyBudgetStrip(budget = PreviewData.weeklyBudgetOver, modifier = Modifier.fillMaxWidth())
        }
    }
}
