/**
 * @file HeroHungryButton.kt
 * @description The Home screen's centrepiece: a 224dp orange disc with an 8dp cream border and
 * two soft rings behind it that breathe over 2.4 s. Pressing scales it to 0.95 in 100 ms and
 * releases with a haptic tick. Under reduced motion the rings hold still.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchColors
import au.iapp.lunch.ui.theme.LunchElevation
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenMotion
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing
import au.iapp.lunch.ui.theme.pressable

enum class HeroState { Idle, Searching }

object HeroHungryButtonDefaults {
    const val TEST_TAG = "hero_hungry_button"
    val iconSize: Dp = TokenSize.iconDefault * 2
    val progressStrokeWidth: Dp = TokenSpacing.xs
    /** The outer ring is the lighter of the two. */
    const val OUTER_RING_ALPHA = LunchColors.SOFT_TINT_ALPHA / 2
}

/**
 * @param state Idle shows the flame and label; Searching swaps the flame for a spinner and
 * blocks taps.
 */
@Composable
fun HeroHungryButton(
    state: HeroState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    val reduceMotion = LunchTheme.reduceMotion
    val haptics = LocalHapticFeedback.current
    val interactionSource = remember { MutableInteractionSource() }
    val label = stringResource(R.string.home_hero)
    val searchingLabel = stringResource(R.string.home_searching_title)
    val searching = state == HeroState.Searching

    val pulse = rememberInfiniteTransition(label = "heroPulse")
    val phase by pulse.animateFloat(
        initialValue = 0f,
        targetValue = if (reduceMotion) 0f else 1f,
        animationSpec = infiniteRepeatable(LunchMotion.heroPulse(), RepeatMode.Reverse),
        label = "phase",
    )
    val outerScale = 1f + (TokenMotion.heroPulseScaleOuter - 1f) * phase
    val innerScale = 1f + (TokenMotion.heroPulseScaleInner - 1f) * phase
    val shadowColor = colors.action.copy(alpha = LunchElevation.hero.colorAlpha)

    Box(modifier = modifier.size(TokenSize.heroRingOuter), contentAlignment = Alignment.Center) {
        Box(
            modifier = Modifier
                .size(TokenSize.heroRingOuter)
                .scale(outerScale)
                .background(colors.action.copy(alpha = HeroHungryButtonDefaults.OUTER_RING_ALPHA), LunchTheme.shapes.hero),
        )
        Box(
            modifier = Modifier
                .size(TokenSize.heroRingInner)
                .scale(innerScale)
                .background(colors.actionSoft, LunchTheme.shapes.hero),
        )
        Box(
            modifier = Modifier
                .pressable(interactionSource, enabled = !searching)
                .size(TokenSize.heroButton)
                .shadow(LunchElevation.hero.elevation, LunchTheme.shapes.hero, ambientColor = shadowColor, spotColor = shadowColor)
                .background(colors.action, LunchTheme.shapes.hero)
                .border(TokenSize.heroBorder, colors.surface, LunchTheme.shapes.hero)
                .clickable(
                    interactionSource = interactionSource,
                    indication = ripple(color = colors.textOnAction),
                    enabled = !searching,
                    role = Role.Button,
                    onClick = {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        onClick()
                    },
                )
                .semantics {
                    contentDescription = label
                    if (searching) stateDescription = searchingLabel
                }
                .testTag(HeroHungryButtonDefaults.TEST_TAG)
                .padding(TokenSize.heroBorder + TokenSpacing.md),
            contentAlignment = Alignment.Center,
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
            ) {
                if (searching) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(HeroHungryButtonDefaults.iconSize),
                        color = colors.textOnAction,
                        strokeWidth = HeroHungryButtonDefaults.progressStrokeWidth,
                    )
                } else {
                    LunchIconView(
                        icon = LunchIcon.LocalFireDepartment,
                        filled = true,
                        size = HeroHungryButtonDefaults.iconSize,
                        tint = colors.textOnAction,
                    )
                }
                LunchText(
                    text = label,
                    role = LunchTextRole.Title,
                    color = colors.textOnAction,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@LunchPreviews
@Composable
private fun HeroHungryButtonPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            HeroHungryButton(state = HeroState.Idle, onClick = {})
            HeroHungryButton(state = HeroState.Searching, onClick = {})
        }
    }
}
