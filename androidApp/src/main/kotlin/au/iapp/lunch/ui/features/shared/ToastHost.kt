/**
 * @file ToastHost.kt
 * @description Shows the environment's toast message as a pill above the tab bar and clears it
 * after `TokenMotion.achievementToastAutoDismissMs`. Mirrors iosApp/.../Shared/ToastHost.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenMotion
import au.iapp.lunch.ui.theme.TokenSpacing
import kotlinx.coroutines.delay

@Composable
fun BoxScope.ToastHost(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val message by app.toast.collectAsStateWithLifecycle()
    LaunchedEffect(message) {
        if (message != null) {
            delay(TokenMotion.achievementToastAutoDismissMs.toLong())
            app.clearToast()
        }
    }
    AnimatedVisibility(
        visible = message != null,
        enter = fadeIn(LunchMotion.fadeIn()),
        exit = fadeOut(LunchMotion.state()),
        modifier = modifier
            .align(Alignment.BottomCenter)
            .padding(horizontal = TokenSpacing.page, vertical = TokenSpacing.xl * 3),
    ) {
        val colors = LunchTheme.colors
        Box(
            modifier = Modifier
                .background(colors.text, LunchTheme.shapes.toast)
                .padding(horizontal = TokenSpacing.md, vertical = TokenSpacing.sm + TokenSpacing.xs)
                .semantics { liveRegion = LiveRegionMode.Polite },
        ) {
            LunchText(text = message.orEmpty(), role = LunchTextRole.Body, color = colors.ground)
        }
    }
}
