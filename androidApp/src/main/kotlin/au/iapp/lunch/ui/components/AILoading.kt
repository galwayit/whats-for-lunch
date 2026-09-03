/**
 * @file AILoading.kt
 * @description The "finding your perfect meal" state: a sparkle in a soft disc and three dots
 * that breathe in sequence. Under reduced motion the dots sit still at full opacity.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenMotion
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

object AILoadingDefaults {
    val discSize: Dp = TokenSize.touchTarget * 2
    val dotSize: Dp = TokenSpacing.sm + TokenSpacing.xs
    const val DOT_COUNT = 3
    const val DOT_STAGGER_MS = 150
    const val DOT_REST_SCALE = 0.6f
    const val DOT_REST_ALPHA = 0.4f
    const val BREATHE_SCALE = 1.1f
    val breatheDurationMs = TokenMotion.fadeInDurationMs * 2
}

/**
 * @param title The headline, e.g. "Finding your perfect meal…"; also announced as a live region.
 */
@Composable
fun AILoading(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
) {
    val colors = LunchTheme.colors
    val reduceMotion = LunchTheme.reduceMotion
    val loading = stringResource(R.string.a11y_loading)
    val transition = rememberInfiniteTransition(label = "aiLoading")
    val sparkleScale by transition.animateFloat(
        initialValue = 1f,
        targetValue = if (reduceMotion) 1f else AILoadingDefaults.BREATHE_SCALE,
        animationSpec = infiniteRepeatable(
            tween(AILoadingDefaults.breatheDurationMs, easing = LunchMotion.inOutEasing),
            RepeatMode.Reverse,
        ),
        label = "sparkle",
    )

    Column(
        modifier = modifier.semantics(mergeDescendants = true) {
            liveRegion = LiveRegionMode.Polite
            contentDescription = "$loading. $title"
        },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        Box(
            modifier = Modifier
                .size(AILoadingDefaults.discSize)
                .scale(sparkleScale)
                .background(colors.primarySoft, LunchTheme.shapes.chip),
            contentAlignment = Alignment.Center,
        ) {
            LunchIconView(icon = LunchIcon.AutoAwesome, filled = true, size = TokenSize.iconDefault + TokenSpacing.sm, tint = colors.primary)
        }
        LunchText(text = title, role = LunchTextRole.Heading, textAlign = TextAlign.Center)
        if (subtitle != null) {
            LunchText(text = subtitle, role = LunchTextRole.BodySmall, color = colors.textSecondary, textAlign = TextAlign.Center)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            repeat(AILoadingDefaults.DOT_COUNT) { index ->
                val phase by transition.animateFloat(
                    initialValue = 0f,
                    targetValue = 1f,
                    animationSpec = infiniteRepeatable(
                        tween(AILoadingDefaults.breatheDurationMs, easing = LunchMotion.inOutEasing),
                        RepeatMode.Reverse,
                        initialStartOffset = StartOffset(index * AILoadingDefaults.DOT_STAGGER_MS),
                    ),
                    label = "dot$index",
                )
                val active = if (reduceMotion) 1f else phase
                Box(
                    modifier = Modifier
                        .size(AILoadingDefaults.dotSize)
                        .scale(AILoadingDefaults.DOT_REST_SCALE + (1f - AILoadingDefaults.DOT_REST_SCALE) * active)
                        .alpha(AILoadingDefaults.DOT_REST_ALPHA + (1f - AILoadingDefaults.DOT_REST_ALPHA) * active)
                        .background(colors.primary, LunchTheme.shapes.chip),
                )
            }
        }
    }
}

@LunchPreviews
@Composable
private fun AILoadingPreview() {
    LunchPreviewSurface {
        AILoading(
            title = stringResource(R.string.home_searching_title),
            subtitle = stringResource(R.string.home_searching_body),
        )
    }
}
