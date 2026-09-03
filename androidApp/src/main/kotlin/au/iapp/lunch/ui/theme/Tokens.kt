// GENERATED FROM design/tokens.json BY design/generate_tokens.py. DO NOT EDIT BY HAND.
package au.iapp.lunch.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object TokenColors {
    object Light {
        /** Screen background. One value; Discover's #FDFAF3 is retired. */
        val ground = Color(0XFFFFF8E7)
        /** Cards, inputs, sheets. */
        val surface = Color(0XFFFFFFFF)
        /** Nested cards, tab bar. */
        val surfaceRaised = Color(0XFFFDFAF3)
        /** Body text. */
        val text = Color(0XFF4A3527)
        /** Captions, hints, unselected tabs. */
        val textSecondary = Color(0XFF8B6F47)
        /** Text on primary fills. */
        val textOnPrimary = Color(0XFFFFFFFF)
        /** Text on the action fill. */
        val textOnAction = Color(0XFFFFFFFF)
        /** Structure, selected states, primary buttons. */
        val primary = Color(0XFF2F7F3F)
        /** Tinted fills (10% / 14%). */
        val primarySoft = Color(0X1A2F7F3F)
        /** The Hungry button and the paywall button only. */
        val action = Color(0XFFFF6B35)
        /** Rings and glows around the action. */
        val actionSoft = Color(0X1FFF6B35)
        /** Positive badges. */
        val success = Color(0XFF2E7D32)
        /** Caution badges. */
        val warning = Color(0XFFB85300)
        /** Errors, destructive actions. */
        val danger = Color(0XFFB71C1C)
        /** Neutral information badges. */
        val info = Color(0XFF1B5E8A)
        /** Card borders, dividers (14% / 10%). */
        val hairline = Color(0X246B4E3D)
        /** Focused borders, strong dividers. */
        val hairlineStrong = Color(0X476B4E3D)
        /** Behind sheets and dialogs. */
        val scrim = Color(0X993E2B20)
    }
    object Dark {
        val ground = Color(0XFF141E16)
        val surface = Color(0XFF1A2B1E)
        val surfaceRaised = Color(0XFF22382A)
        val text = Color(0XFFEAE4D8)
        val textSecondary = Color(0XFFB5A88F)
        val textOnPrimary = Color(0XFF0E1A10)
        val textOnAction = Color(0XFFFFFFFF)
        val primary = Color(0XFF5FC172)
        val primarySoft = Color(0X245FC172)
        val action = Color(0XFFFF8A5C)
        val actionSoft = Color(0X29FF8A5C)
        val success = Color(0XFF6FCF80)
        val warning = Color(0XFFFFB067)
        val danger = Color(0XFFFF8A80)
        val info = Color(0XFF7CC4F5)
        val hairline = Color(0X1AFFFFFF)
        val hairlineStrong = Color(0X38FFFFFF)
        val scrim = Color(0XA6000000)
    }
}

data class TextRole(val size: Int, val weight: Int, val lineHeight: Int, val tracking: Double, val uppercase: Boolean)

object TokenType {
    const val FAMILY = "Plus Jakarta Sans"
    const val TEXT_SCALE_MIN = 0.8f
    const val TEXT_SCALE_MAX = 2.0f
    val display = TextRole(32, 800, 38, -0.5, false)
    val title = TextRole(22, 700, 28, 0.0, false)
    val heading = TextRole(17, 700, 22, 0.0, false)
    val body = TextRole(16, 500, 24, 0.15, false)
    val bodySmall = TextRole(14, 400, 20, 0.25, false)
    val caption = TextRole(13, 500, 18, 0.2, false)
    val label = TextRole(11, 700, 16, 1.2, true)
    val button = TextRole(16, 700, 20, 0.1, false)
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
