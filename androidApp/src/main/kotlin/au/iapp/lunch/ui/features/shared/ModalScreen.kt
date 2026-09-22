/**
 * @file ModalScreen.kt
 * @description Full-screen container for every modal route: paints `ground`, insets from the
 * system bars and wires the system back gesture to the environment's dismiss.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import au.iapp.lunch.ui.theme.LunchTheme

@Composable
fun ModalScreen(onBack: () -> Unit, modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    BackHandler(onBack = onBack)
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LunchTheme.colors.ground)
            .windowInsetsPadding(WindowInsets.safeDrawing),
        content = content,
    )
}
