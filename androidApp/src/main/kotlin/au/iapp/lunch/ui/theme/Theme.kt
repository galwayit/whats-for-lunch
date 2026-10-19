/**
 * @file Theme.kt
 * @description LunchTheme: maps the generated token palette to a Material 3 ColorScheme and
 * exposes the full palette through [LocalLunchColors]. Also carries the elevation values from
 * design/tokens.json that the token generator does not emit yet.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * The full token palette for one appearance. Components read colours from here (through
 * [LunchTheme.colors]) rather than from [MaterialTheme.colorScheme], so every colour on screen
 * traces back to design/tokens.json.
 */
@Immutable
data class LunchColors(
    val ground: Color,
    val surface: Color,
    val surfaceRaised: Color,
    val text: Color,
    val textSecondary: Color,
    val textOnPrimary: Color,
    val textOnAction: Color,
    val primary: Color,
    val primarySoft: Color,
    val action: Color,
    val actionSoft: Color,
    val accent: Color,
    val success: Color,
    val warning: Color,
    val danger: Color,
    val info: Color,
    val hairline: Color,
    val hairlineStrong: Color,
    val scrim: Color,
    /** True for the dark palette; lets components pick dark-specific behaviour if ever needed. */
    val isDark: Boolean,
) {
    companion object {
        /** The 10% tint level used by `primarySoft`, for tinting other palette colours the same way. */
        const val SOFT_TINT_ALPHA = 0.1f

        val Light = LunchColors(
            ground = TokenColors.Light.ground,
            surface = TokenColors.Light.surface,
            surfaceRaised = TokenColors.Light.surfaceRaised,
            text = TokenColors.Light.text,
            textSecondary = TokenColors.Light.textSecondary,
            textOnPrimary = TokenColors.Light.textOnPrimary,
            textOnAction = TokenColors.Light.textOnAction,
            primary = TokenColors.Light.primary,
            primarySoft = TokenColors.Light.primarySoft,
            action = TokenColors.Light.action,
            actionSoft = TokenColors.Light.actionSoft,
            accent = TokenColors.Light.accent,
            success = TokenColors.Light.success,
            warning = TokenColors.Light.warning,
            danger = TokenColors.Light.danger,
            info = TokenColors.Light.info,
            hairline = TokenColors.Light.hairline,
            hairlineStrong = TokenColors.Light.hairlineStrong,
            scrim = TokenColors.Light.scrim,
            isDark = false,
        )

        val Dark = LunchColors(
            ground = TokenColors.Dark.ground,
            surface = TokenColors.Dark.surface,
            surfaceRaised = TokenColors.Dark.surfaceRaised,
            text = TokenColors.Dark.text,
            textSecondary = TokenColors.Dark.textSecondary,
            textOnPrimary = TokenColors.Dark.textOnPrimary,
            textOnAction = TokenColors.Dark.textOnAction,
            primary = TokenColors.Dark.primary,
            primarySoft = TokenColors.Dark.primarySoft,
            action = TokenColors.Dark.action,
            actionSoft = TokenColors.Dark.actionSoft,
            accent = TokenColors.Dark.accent,
            success = TokenColors.Dark.success,
            warning = TokenColors.Dark.warning,
            danger = TokenColors.Dark.danger,
            info = TokenColors.Dark.info,
            hairline = TokenColors.Dark.hairline,
            hairlineStrong = TokenColors.Dark.hairlineStrong,
            scrim = TokenColors.Dark.scrim,
            isDark = true,
        )
    }
}

/** The current token palette. Provided by [LunchTheme]; defaults to light outside it. */
val LocalLunchColors = staticCompositionLocalOf { LunchColors.Light }

/**
 * Shadow values from design/tokens.json `elevation`, mirrored here until generate_tokens.py
 * emits them. [colorAlpha] is applied to the shadow colour (text, or action for the hero).
 */
@Immutable
data class LunchElevationSpec(val y: Dp, val blur: Dp, val colorAlpha: Float) {
    /** The Compose shadow elevation that approximates the blur radius. */
    val elevation: Dp get() = blur / 2
}

object LunchElevation {
    val card = LunchElevationSpec(y = 2.dp, blur = 8.dp, colorAlpha = 0.04f)
    val hero = LunchElevationSpec(y = 10.dp, blur = 25.dp, colorAlpha = 0.40f)
    val sheet = LunchElevationSpec(y = (-4).dp, blur = 24.dp, colorAlpha = 0.12f)
}

/** Accessors for the design-system values in scope, mirroring [MaterialTheme]. */
object LunchTheme {
    val colors: LunchColors
        @Composable @ReadOnlyComposable get() = LocalLunchColors.current

    val typography: LunchTypography
        @Composable @ReadOnlyComposable get() = LocalLunchTypography.current

    val shapes: LunchShapes
        @Composable @ReadOnlyComposable get() = LocalLunchShapes.current

    /** True when animations should be reduced to state changes only. */
    val reduceMotion: Boolean
        @Composable @ReadOnlyComposable get() = LocalReduceMotion.current
}

private fun LunchColors.toMaterialColorScheme(): ColorScheme {
    val base = if (isDark) darkColorScheme() else lightColorScheme()
    return base.copy(
        primary = primary,
        onPrimary = textOnPrimary,
        primaryContainer = primarySoft,
        onPrimaryContainer = primary,
        secondary = action,
        onSecondary = textOnAction,
        secondaryContainer = actionSoft,
        onSecondaryContainer = action,
        tertiary = info,
        background = ground,
        onBackground = text,
        surface = surface,
        onSurface = text,
        surfaceVariant = surfaceRaised,
        onSurfaceVariant = textSecondary,
        surfaceContainer = surfaceRaised,
        surfaceContainerLow = surface,
        surfaceContainerHigh = surfaceRaised,
        error = danger,
        onError = textOnAction,
        outline = hairlineStrong,
        outlineVariant = hairline,
        scrim = scrim,
    )
}

/**
 * Applies the design system: token palette, typography, shapes, and the reduced-motion flag,
 * and the matching Material 3 colour scheme for stock Material components (sheets, dialogs).
 *
 * @param darkTheme Overrides the system appearance; defaults to [isSystemInDarkTheme].
 * @param reduceMotion Overrides the reduced-motion detection; defaults to [rememberReduceMotion].
 * @param clampTextScale When true the content is wrapped in [ClampedTextScale] so font scaling
 * never leaves the token range.
 */
@Composable
fun LunchTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    reduceMotion: Boolean = rememberReduceMotion(),
    clampTextScale: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colors = if (darkTheme) LunchColors.Dark else LunchColors.Light
    val typography = rememberLunchTypography()
    CompositionLocalProvider(
        LocalLunchColors provides colors,
        LocalLunchTypography provides typography,
        LocalLunchShapes provides LunchShapes(),
        LocalReduceMotion provides reduceMotion,
    ) {
        MaterialTheme(
            colorScheme = colors.toMaterialColorScheme(),
            typography = typography.toMaterialTypography(),
            shapes = LunchTheme.shapes.toMaterialShapes(),
        ) {
            if (clampTextScale) ClampedTextScale(content) else content()
        }
    }
}
