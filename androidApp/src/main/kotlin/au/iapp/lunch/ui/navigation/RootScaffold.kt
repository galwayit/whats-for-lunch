/**
 * @file RootScaffold.kt
 * @description The app shell: onboarding until the profile exists, then the four tabs behind
 * the custom tab bar, the modal route stack from `AppEnvironment` drawn as full-screen
 * overlays (sign-in as a bottom sheet) and the toast host. Mirrors
 * iosApp/LunchApp/App/RootTabView.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import au.iapp.lunch.R
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.LunchTab
import au.iapp.lunch.ui.components.LunchTabBar
import au.iapp.lunch.ui.features.ai.AiRecommendationsScreen
import au.iapp.lunch.ui.features.auth.SignInSheet
import au.iapp.lunch.ui.features.budget.BudgetSetupScreen
import au.iapp.lunch.ui.features.discover.DiscoverScreen
import au.iapp.lunch.ui.features.groups.GroupCreateScreen
import au.iapp.lunch.ui.features.groups.GroupDetailScreen
import au.iapp.lunch.ui.features.groups.GroupProposalsScreen
import au.iapp.lunch.ui.features.home.HomeScreen
import au.iapp.lunch.ui.features.invitation.InvitationScreen
import au.iapp.lunch.ui.features.onboarding.OnboardingScreen
import au.iapp.lunch.ui.features.paywall.PaywallScreen
import au.iapp.lunch.ui.features.preferences.PreferencesScreen
import au.iapp.lunch.ui.features.profile.ProfileScreen
import au.iapp.lunch.ui.features.shared.InfoScreen
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ToastHost
import au.iapp.lunch.ui.features.track.TrackScreen
import au.iapp.lunch.ui.theme.LunchTheme

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun RootScaffold(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val onboarded by app.hasCompletedOnboarding.collectAsStateWithLifecycle()
    val tab by app.selectedTab.collectAsStateWithLifecycle()
    val routes by app.routes.collectAsStateWithLifecycle()

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LunchTheme.colors.ground)
            .semantics { testTagsAsResourceId = true },
    ) {
        if (!onboarded) {
            OnboardingScreen(modifier = Modifier.windowInsetsPadding(WindowInsets.safeDrawing))
        } else {
            Column(modifier = Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing)) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                ) {
                    when (tab) {
                        LunchTab.Home -> HomeScreen()
                        LunchTab.Discover -> DiscoverScreen()
                        LunchTab.Track -> TrackScreen()
                        LunchTab.Profile -> ProfileScreen()
                    }
                }
                LunchTabBar(selected = tab, onSelect = app::selectTab, modifier = Modifier.fillMaxWidth())
            }
        }
        routes.forEach { route -> RouteContent(route = route, app = app) }
        ToastHost()
    }
}

/** One entry of the modal stack; every screen handles its own back and header. */
@Composable
private fun RouteContent(route: AppRoute, app: AppEnvironment) {
    when (route) {
        AppRoute.Onboarding -> ModalScreen(onBack = app::dismiss) { OnboardingScreen() }
        is AppRoute.Tab -> LaunchedEffect(route) {
            app.dismiss()
            app.selectTab(route.tab)
        }
        is AppRoute.AiRecommendations -> AiRecommendationsScreen(pickPlaceId = route.pickPlaceId)
        AppRoute.GroupCreate -> GroupCreateScreen()
        is AppRoute.GroupProposals -> GroupProposalsScreen(groupId = route.groupId)
        is AppRoute.GroupDetail -> GroupDetailScreen(groupId = route.groupId)
        AppRoute.Paywall -> PaywallScreen()
        AppRoute.Preferences -> PreferencesScreen()
        AppRoute.SignIn -> SignInSheet(onDismiss = app::dismiss)
        AppRoute.Privacy -> ModalScreen(onBack = app::dismiss) {
            InfoScreen(title = stringResource(R.string.profile_settings_privacy), body = stringResource(R.string.info_privacy_body), onBack = app::dismiss)
        }
        AppRoute.Help -> ModalScreen(onBack = app::dismiss) {
            InfoScreen(title = stringResource(R.string.profile_settings_help), body = stringResource(R.string.info_help_body), onBack = app::dismiss)
        }
        AppRoute.BudgetSetup -> BudgetSetupScreen()
        is AppRoute.Invitation -> InvitationScreen(code = route.code)
    }
}
