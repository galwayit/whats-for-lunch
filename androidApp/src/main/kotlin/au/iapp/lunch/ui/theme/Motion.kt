/**
 * @file Motion.kt
 * @description Durations and easings from TokenMotion, reduced-motion detection, and the shared
 * press-feedback modifier used by every tappable design-system component.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.theme

import android.content.Context
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.interaction.InteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalInspectionMode

/** Motion values from design/tokens.json as Compose animation specs. */
object LunchMotion {
    /** `motion.state`: easeOut over 200 ms. */
    val stateEasing: Easing = LinearOutSlowInEasing
    fun <T> state() = tween<T>(durationMillis = TokenMotion.stateDurationMs, easing = stateEasing)

    /** `motion.press`: 100 ms scale to 0.95. */
    fun <T> press() = tween<T>(durationMillis = TokenMotion.pressDurationMs, easing = stateEasing)

    /** `motion.sheet` and `motion.fadeIn`: easeInOut. */
    val inOutEasing: Easing = FastOutSlowInEasing
    fun <T> sheet() = tween<T>(durationMillis = TokenMotion.sheetDurationMs, easing = inOutEasing)
    fun <T> fadeIn() = tween<T>(durationMillis = TokenMotion.fadeInDurationMs, easing = inOutEasing)

    /** `motion.heroPulse`: one half of the pulse; the caller reverses it. */
    val pulseEasing: Easing = CubicBezierEasing(0.45f, 0f, 0.55f, 1f)
    fun <T> heroPulse() = tween<T>(durationMillis = TokenMotion.heroPulseDurationMs, easing = pulseEasing)

    /** Opacity used instead of the press scale when motion is reduced. */
    const val PRESSED_OPACITY = 0.7f
}

/** True when animations should collapse to state changes. Provided by [LunchTheme]. */
val LocalReduceMotion = staticCompositionLocalOf { false }

/**
 * Detects the user's reduced-motion preference: the developer/accessibility "Remove animations"
 * setting sets [Settings.Global.ANIMATOR_DURATION_SCALE] to 0, and some devices expose it
 * through [AccessibilityManager]'s reduce-motion style flags. Previews report false.
 */
@Composable
fun rememberReduceMotion(): Boolean {
    if (LocalInspectionMode.current) return false
    val context = LocalContext.current
    return remember(context) { isReduceMotionEnabled(context) }
}

private const val ANIMATIONS_OFF_SCALE = 0f

/** Non-composable check, for the same rule outside composition. */
fun isReduceMotionEnabled(context: Context): Boolean {
    val scale = Settings.Global.getFloat(
        context.contentResolver,
        Settings.Global.ANIMATOR_DURATION_SCALE,
        1f,
    )
    if (scale == ANIMATIONS_OFF_SCALE) return true
    val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
    // Screen readers move focus themselves; pulsing decoration is noise for them.
    return manager?.isTouchExplorationEnabled == true
}

/**
 * The shared press feedback: scale to [TokenMotion.pressScale] over [TokenMotion.pressDurationMs].
 * Reduced motion swaps the scale for an opacity dip. Pass the same [interactionSource] that the
 * clickable uses so the two agree on the pressed state.
 */
@Composable
fun Modifier.pressable(interactionSource: InteractionSource, enabled: Boolean = true): Modifier {
    val pressed by interactionSource.collectIsPressedAsState()
    val reduceMotion = LocalReduceMotion.current
    val isPressed = pressed && enabled
    val scale by animateFloatAsState(
        targetValue = if (isPressed && !reduceMotion) TokenMotion.pressScale else 1f,
        animationSpec = LunchMotion.press(),
        label = "pressScale",
    )
    val alpha by animateFloatAsState(
        targetValue = if (isPressed && reduceMotion) LunchMotion.PRESSED_OPACITY else 1f,
        animationSpec = LunchMotion.press(),
        label = "pressAlpha",
    )
    return this.scale(scale).alpha(alpha)
}
