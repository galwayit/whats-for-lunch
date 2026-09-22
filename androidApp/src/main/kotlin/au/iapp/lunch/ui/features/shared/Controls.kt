/**
 * @file Controls.kt
 * @description Material sliders and switches painted with the Lunch tokens. Without these the
 * controls fall back to the default Material palette, which is not the app's colour scheme.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.material3.SliderColors
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.SwitchColors
import androidx.compose.material3.SwitchDefaults
import androidx.compose.runtime.Composable
import au.iapp.lunch.ui.theme.LunchTheme

/** Primary thumb and active track, hairline for the rest; ticks stay invisible. */
@Composable
fun lunchSliderColors(): SliderColors {
    val colors = LunchTheme.colors
    return SliderDefaults.colors(
        thumbColor = colors.primary,
        activeTrackColor = colors.primary,
        activeTickColor = colors.primary,
        inactiveTrackColor = colors.hairline,
        inactiveTickColor = colors.hairline,
        disabledThumbColor = colors.hairlineStrong,
        disabledActiveTrackColor = colors.hairlineStrong,
        disabledInactiveTrackColor = colors.hairline,
    )
}

/** Primary when on, surface over a hairline track when off. */
@Composable
fun lunchSwitchColors(): SwitchColors {
    val colors = LunchTheme.colors
    return SwitchDefaults.colors(
        checkedThumbColor = colors.textOnPrimary,
        checkedTrackColor = colors.primary,
        checkedBorderColor = colors.primary,
        uncheckedThumbColor = colors.textSecondary,
        uncheckedTrackColor = colors.surface,
        uncheckedBorderColor = colors.hairlineStrong,
    )
}
