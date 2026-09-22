/**
 * @file StepProgress.kt
 * @description Progress bar plus "STEP n OF m" eyebrow and step label shared by Onboarding and
 * Budget setup.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.layout
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun StepProgress(progress: Float, eyebrow: String, title: String, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val animated by animateFloatAsState(progress.coerceIn(0f, 1f), LunchMotion.state(), label = "stepProgress")
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(TokenSpacing.xs)
                .clip(LunchTheme.shapes.chip)
                .background(colors.hairline),
        ) {
            Box(
                modifier = Modifier
                    .layout { measurable, constraints ->
                        val width = (constraints.maxWidth * animated).toInt()
                        val placeable = measurable.measure(constraints.copy(minWidth = width, maxWidth = width))
                        layout(placeable.width, placeable.height) { placeable.place(0, 0) }
                    }
                    .height(TokenSpacing.xs)
                    .background(colors.primary, LunchTheme.shapes.chip),
            )
        }
        LunchText(text = eyebrow, role = LunchTextRole.Label, color = colors.primary)
        LunchText(text = title, role = LunchTextRole.Title)
    }
}
