/**
 * @file RootScaffold.kt
 * @description Four placeholder tabs behind the custom tab bar. Screens replace the placeholders
 * in the next milestone. Mirrors iosApp/LunchApp/App/RootTabView.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import au.iapp.lunch.ui.components.LunchTab
import au.iapp.lunch.ui.components.LunchTabBar
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/**
 * The tab shell: the selected tab's content above the [LunchTabBar], painted on `ground` and
 * inset from the system bars.
 */
@Composable
fun RootScaffold(modifier: Modifier = Modifier) {
    var selected by rememberSaveable { mutableStateOf(LunchTab.Home) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LunchTheme.colors.ground)
            .windowInsetsPadding(WindowInsets.safeDrawing),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            contentAlignment = Alignment.Center,
        ) {
            TabPlaceholder(tab = selected)
        }
        LunchTabBar(selected = selected, onSelect = { selected = it }, modifier = Modifier.fillMaxWidth())
    }
}

@Composable
private fun TabPlaceholder(tab: LunchTab, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        LunchIconView(icon = tab.icon, size = TokenSize.iconDefault * 2, filled = true, tint = LunchTheme.colors.primary)
        LunchText(text = stringResource(tab.labelRes), role = LunchTextRole.Label, color = LunchTheme.colors.textSecondary)
    }
}

@LunchPreviews
@Composable
private fun RootScaffoldPreview() {
    LunchTheme { RootScaffold() }
}
