/**
 * @file NotConfiguredScreen.kt
 * @description Shown instead of the app when the backend values are missing from BuildConfig.
 * Names the launch flag that explores the app with sample data. Mirrors
 * iosApp/LunchApp/Features/Shared/NotLinkedView.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun NotConfiguredScreen(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LunchTheme.colors.ground)
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .padding(TokenSpacing.pageWide),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md, Alignment.CenterVertically),
    ) {
        LunchIconView(icon = LunchIcon.CloudOff, size = TokenSize.iconDefault * 2, tint = LunchTheme.colors.textSecondary)
        LunchText(text = stringResource(R.string.error_not_linked_title), role = LunchTextRole.Title, textAlign = TextAlign.Center)
        LunchText(
            text = stringResource(R.string.error_not_linked_body),
            role = LunchTextRole.Body,
            color = LunchTheme.colors.textSecondary,
            textAlign = TextAlign.Center,
        )
    }
}

@LunchPreviews
@Composable
private fun NotConfiguredScreenPreview() {
    LunchTheme { NotConfiguredScreen() }
}
