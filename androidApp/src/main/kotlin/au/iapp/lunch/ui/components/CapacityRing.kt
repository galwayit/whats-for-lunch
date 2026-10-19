/**
 * @file CapacityRing.kt
 * @description The Track screen's weekly-budget ring: a 12dp stroke that fills clockwise from
 * twelve o'clock, coloured by how much of the budget is used, with a centre label slot.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchColors
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing
import kotlin.math.roundToInt

/** Colour bands for budget progress. */
enum class CapacityTone {
    Healthy, Caution, Over;

    companion object {
        const val CAUTION_FROM = 0.8f
        const val OVER_FROM = 1f

        fun from(progress: Float): CapacityTone = when {
            progress >= OVER_FROM -> Over
            progress >= CAUTION_FROM -> Caution
            else -> Healthy
        }
    }
}

/** The palette colour for a tone. */
fun LunchColors.toneColor(tone: CapacityTone): Color = when (tone) {
    CapacityTone.Healthy -> success
    CapacityTone.Caution -> warning
    CapacityTone.Over -> danger
}

object CapacityRingDefaults {
    val diameter: Dp = TokenSize.heroButton - TokenSpacing.xl
    val strokeWidth: Dp = TokenSize.capacityRingStroke
    const val START_ANGLE = -90f
    const val FULL_SWEEP = 360f
    const val PERCENT = 100f
}

/**
 * @param progress Spent over capacity; values above 1 fill the ring completely in `danger`.
 * @param label Centre content, e.g. the amount left.
 */
@Composable
fun CapacityRing(
    progress: Float,
    modifier: Modifier = Modifier,
    diameter: Dp = CapacityRingDefaults.diameter,
    strokeWidth: Dp = CapacityRingDefaults.strokeWidth,
    label: @Composable ColumnScope.() -> Unit,
) {
    val colors = LunchTheme.colors
    val reduceMotion = LunchTheme.reduceMotion
    val clamped = progress.coerceIn(0f, 1f)
    val animatedProgress by animateFloatAsState(
        targetValue = clamped,
        animationSpec = if (reduceMotion) snap() else LunchMotion.fadeIn(),
        label = "ringProgress",
    )
    val toneColor by animateColorAsState(
        targetValue = colors.toneColor(CapacityTone.from(progress)),
        animationSpec = LunchMotion.state(),
        label = "ringTone",
    )
    val track = colors.hairline
    val percent = (progress * CapacityRingDefaults.PERCENT).roundToInt()
    val a11y = stringResource(R.string.a11y_percent, percent)

    Box(
        modifier = modifier
            .size(diameter)
            .semantics {
                progressBarRangeInfo = ProgressBarRangeInfo(clamped, 0f..1f)
                contentDescription = a11y
            },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.size(diameter)) {
            val stroke = Stroke(width = strokeWidth.toPx(), cap = StrokeCap.Round)
            val inset = strokeWidth.toPx() / 2
            val arcSize = Size(size.width - strokeWidth.toPx(), size.height - strokeWidth.toPx())
            val topLeft = Offset(inset, inset)
            drawArc(track, CapacityRingDefaults.START_ANGLE, CapacityRingDefaults.FULL_SWEEP, false, topLeft, arcSize, style = stroke)
            if (animatedProgress > 0f) {
                drawArc(
                    toneColor,
                    CapacityRingDefaults.START_ANGLE,
                    CapacityRingDefaults.FULL_SWEEP * animatedProgress,
                    false,
                    topLeft,
                    arcSize,
                    style = stroke,
                )
            }
        }
        Column(
            modifier = Modifier.padding(strokeWidth + TokenSpacing.sm),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = label,
        )
    }
}

@LunchPreviews
@Composable
private fun CapacityRingPreview() {
    LunchPreviewSurface {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            CapacityRing(progress = 0.62f, diameter = TokenSize.heroButton / 2) {
                LunchText("$76", LunchTextRole.Heading)
            }
            CapacityRing(progress = 0.9f, diameter = TokenSize.heroButton / 2) {
                LunchText("$20", LunchTextRole.Heading)
            }
            CapacityRing(progress = 1.15f, diameter = TokenSize.heroButton / 2) {
                LunchText("$0", LunchTextRole.Heading)
            }
        }
    }
}
