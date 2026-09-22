/**
 * @file InfoScreen.kt
 * @description Static text screen for Privacy and Help & support, reached from Profile.
 * Mirrors iosApp/.../Shared/InfoScreen.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun InfoScreen(title: String, body: String, onBack: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LunchTheme.colors.ground)
            .windowInsetsPadding(WindowInsets.safeDrawing),
    ) {
        ScreenHeader(title = title, onDismiss = onBack)
        LunchText(
            text = body,
            role = LunchTextRole.Body,
            color = LunchTheme.colors.textSecondary,
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(TokenSpacing.page),
        )
    }
}
