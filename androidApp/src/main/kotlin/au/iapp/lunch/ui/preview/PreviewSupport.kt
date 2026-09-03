/**
 * @file PreviewSupport.kt
 * @description Shared preview scaffolding: the light+dark multipreview annotation and the
 * themed surface every component preview renders inside.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.preview

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

/** Renders the annotated composable once in light and once in dark appearance. */
@Preview(name = "Light", showBackground = false)
@Preview(name = "Dark", uiMode = Configuration.UI_MODE_NIGHT_YES, showBackground = false)
annotation class LunchPreviews

/** Wraps [content] in [LunchTheme] on the `ground` colour with page padding, as a screen would. */
@Composable
fun LunchPreviewSurface(content: @Composable () -> Unit) {
    LunchTheme {
        Box(
            modifier = Modifier
                .background(LunchTheme.colors.ground)
                .padding(TokenSpacing.page),
        ) {
            content()
        }
    }
}
