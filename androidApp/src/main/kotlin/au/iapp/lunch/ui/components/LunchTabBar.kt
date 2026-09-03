/**
 * @file LunchTabBar.kt
 * @description The four-tab bottom bar: raised surface, hairline top divider, and a soft pill
 * behind the selected tab with its filled icon. Labels are the 11sp uppercase label role.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/** The root tabs, in bar order. [testTag] matches design/screens.md and the Maestro flows. */
enum class LunchTab(val icon: LunchIcon, val labelRes: Int, val testTag: String) {
    Home(LunchIcon.Home, R.string.tab_home, "tab_home"),
    Discover(LunchIcon.Explore, R.string.tab_discover, "tab_discover"),
    Track(LunchIcon.Analytics, R.string.tab_track, "tab_track"),
    Profile(LunchIcon.Person, R.string.tab_profile, "tab_profile"),
}

/**
 * @param selected The active tab; the bar is stateless.
 */
@Composable
fun LunchTabBar(
    selected: LunchTab,
    onSelect: (LunchTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    Column(modifier = modifier.background(colors.surfaceRaised)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(ComponentDefaults.hairlineWidth)
                .background(colors.hairline),
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs)
                .selectableGroup(),
            horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
        ) {
            LunchTab.entries.forEach { tab ->
                TabItem(
                    tab = tab,
                    selected = tab == selected,
                    onClick = { onSelect(tab) },
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun TabItem(tab: LunchTab, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val label = stringResource(tab.labelRes)
    val tint by animateColorAsState(
        targetValue = if (selected) colors.primary else colors.textSecondary,
        animationSpec = LunchMotion.state(),
        label = "tabTint",
    )
    val pill by animateColorAsState(
        targetValue = if (selected) colors.primarySoft else Color.Transparent,
        animationSpec = LunchMotion.state(),
        label = "tabPill",
    )
    Column(
        modifier = modifier
            .defaultMinSize(minHeight = TokenSize.buttonHeight)
            .clip(LunchTheme.shapes.container)
            .background(pill)
            .selectable(
                selected = selected,
                role = Role.Tab,
                indication = ripple(color = colors.primary),
                interactionSource = null,
                onClick = onClick,
            )
            .testTag(tab.testTag)
            .padding(vertical = TokenSpacing.xs),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs, Alignment.CenterVertically),
    ) {
        LunchIconView(icon = tab.icon, size = TokenSize.tabIcon, filled = selected, tint = tint)
        LunchText(text = label, role = LunchTextRole.Label, color = tint, maxLines = 1)
    }
}

@LunchPreviews
@Composable
private fun LunchTabBarPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            LunchTabBar(selected = LunchTab.Home, onSelect = {})
            LunchTabBar(selected = LunchTab.Track, onSelect = {})
        }
    }
}
