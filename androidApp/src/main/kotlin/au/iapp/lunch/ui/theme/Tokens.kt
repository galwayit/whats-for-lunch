// GENERATED FROM design/tokens.json BY design/generate_tokens.py. DO NOT EDIT BY HAND.
package au.iapp.lunch.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object TokenColors {
    object Light {
        /** Screen background. Warm cream; espresso in dark, never green-black. */
        val ground = Color(0XFFFFF6EC)
        /** Cards, inputs, sheets. */
        val surface = Color(0XFFFFFFFF)
        /** Nested cards, tab bar, tags. */
        val surfaceRaised = Color(0XFFFFF0E0)
        /** Body text. */
        val text = Color(0XFF3A2218)
        /** Captions, hints, unselected tabs. */
        val textSecondary = Color(0XFF7A5A48)
        /** Text on primary fills. */
        val textOnPrimary = Color(0XFFFFFFFF)
        /** Text on the action fill. Large bold labels only in light (3.7:1). */
        val textOnAction = Color(0XFFFFFFFF)
        /** Paprika. Structure, selected states, primary buttons. */
        val primary = Color(0XFFC63D17)
        /** Tinted fills (10% / 16%). */
        val primarySoft = Color(0X1AC63D17)
        /** The Hungry button and the paywall button only. */
        val action = Color(0XFFEC4E14)
        /** Rings and glows around the action. */
        val actionSoft = Color(0X1FEC4E14)
        /** Saffron. Rating stars; decorative, always next to the rating number. */
        val accent = Color(0XFFD98A00)
        /** Positive badges and a healthy budget. The only green in the palette. */
        val success = Color(0XFF2E7D4F)
        /** Caution badges. */
        val warning = Color(0XFFA85A00)
        /** Errors, destructive actions. Berry, so it never reads as the paprika brand colour. */
        val danger = Color(0XFFA8123E)
        /** Neutral information badges. */
        val info = Color(0XFF1F5F8B)
        /** Card borders, dividers (14% / 12%). */
        val hairline = Color(0X243A2218)
        /** Focused borders, strong dividers. */
        val hairlineStrong = Color(0X473A2218)
        /** Behind sheets and dialogs. */
        val scrim = Color(0X992A1810)
    }
    object Dark {
        val ground = Color(0XFF1A1310)
        val surface = Color(0XFF261C17)
        val surfaceRaised = Color(0XFF33261F)
        val text = Color(0XFFF5E9DD)
        val textSecondary = Color(0XFFC4AE9C)
        val textOnPrimary = Color(0XFF3A1206)
        val textOnAction = Color(0XFF2A0E03)
        val primary = Color(0XFFFF8A5B)
        val primarySoft = Color(0X29FF8A5B)
        val action = Color(0XFFFF6B35)
        val actionSoft = Color(0X29FF6B35)
        val accent = Color(0XFFFFC154)
        val success = Color(0XFF7FD19B)
        val warning = Color(0XFFFFB868)
        val danger = Color(0XFFFF8FA8)
        val info = Color(0XFF8CC8F2)
        val hairline = Color(0X1FFFFFFF)
        val hairlineStrong = Color(0X3DFFFFFF)
        val scrim = Color(0XA6000000)
    }
}

/** [display] is true for roles set in the bundled display family; false for the system text face. */
data class TextRole(val size: Int, val weight: Int, val lineHeight: Int, val tracking: Double, val uppercase: Boolean, val display: Boolean)

object TokenType {
    const val FAMILY = "Bricolage Grotesque"
    const val TEXT_SCALE_MIN = 0.8f
    const val TEXT_SCALE_MAX = 2.0f
    val display = TextRole(32, 800, 38, -0.5, false, true)
    val title = TextRole(22, 700, 28, -0.2, false, true)
    val heading = TextRole(17, 700, 22, 0.0, false, true)
    val body = TextRole(16, 500, 24, 0.15, false, false)
    val bodySmall = TextRole(14, 400, 20, 0.25, false, false)
    val caption = TextRole(13, 500, 18, 0.2, false, false)
    val label = TextRole(11, 700, 16, 1.2, true, false)
    val button = TextRole(16, 700, 20, 0.1, false, false)
}

object TokenSpacing {
    val unit = 4.dp
    val xs = 4.dp
    val sm = 8.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp
    val xxl = 48.dp
    val page = 16.dp
    val pageWide = 24.dp
}

object TokenRadius {
    val container = 16.dp
    val chip = 9999.dp
    val toast = 12.dp
    val sheet = 24.dp
    val hero = 9999.dp
    val input = 16.dp
    val button = 16.dp
}

object TokenSize {
    val touchTarget = 44.dp
    val buttonHeight = 52.dp
    val buttonMinWidth = 48.dp
    val heroButton = 224.dp
    val heroRingInner = 256.dp
    val heroRingOuter = 288.dp
    val heroBorder = 8.dp
    val tabIcon = 24.dp
    val iconDefault = 24.dp
    val capacityRingStroke = 12.dp
}

object TokenMotion {
    const val stateDurationMs = 200
    const val pressDurationMs = 100
    const val pressScale = 0.95f
    const val heroPulseDurationMs = 2400
    const val heroPulseScaleOuter = 1.04f
    const val heroPulseScaleInner = 1.025f
    const val heroPulseRespectsReducedMotion = true
    const val sheetDurationMs = 300
    const val fadeInDurationMs = 300
    const val achievementToastAutoDismissMs = 4000
}
