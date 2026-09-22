/**
 * @file HomeScreen.kt
 * @description Screen 2 of design/screens.md: greeting header, Pro craving field, the hero
 * button with its searching, result, empty and error states, the picks badge and the "Lunch
 * together" row.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.home

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.AILoading
import au.iapp.lunch.ui.components.BadgeLabel
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant
import au.iapp.lunch.ui.components.GroupCard
import au.iapp.lunch.ui.components.HeroHungryButton
import au.iapp.lunch.ui.components.HeroState
import au.iapp.lunch.ui.components.InitialAvatar
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchTab
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.components.RecommendationCard
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.shared.ErrorStateView
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object HomeDefaults {
    const val CRAVING_TEST_TAG = "craving_field_home"
}

@Composable
fun HomeScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: HomeViewModel = viewModel { HomeViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val user by app.user.collectAsStateWithLifecycle()
    val isPro by app.isPro.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val colors = LunchTheme.colors
    val prefs = user?.preferences

    LaunchedEffect(Unit) {
        if (app.shouldRunFirstSearch) {
            app.shouldRunFirstSearch = false
            viewModel.search(prefs)
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = TokenSpacing.page)
            .padding(top = TokenSpacing.md, bottom = TokenSpacing.xl),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            InitialAvatar(name = user?.name.orEmpty())
            LunchText(text = stringResource(R.string.home_eyebrow), role = LunchTextRole.Label, color = colors.textSecondary)
        }
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
            LunchText(text = stringResource(R.string.home_greeting, user?.name.orEmpty()), role = LunchTextRole.Display)
            LunchText(text = stringResource(R.string.home_subtitle), role = LunchTextRole.Body, color = colors.textSecondary)
        }
        if (isPro) {
            LunchTextField(
                value = state.craving,
                onValueChange = viewModel::setCraving,
                placeholder = stringResource(R.string.home_craving_placeholder),
                leadingIcon = LunchIcon.AutoAwesome,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { viewModel.submitCraving() }),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(HomeDefaults.CRAVING_TEST_TAG),
            )
        }
        Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            if (state.hero !is HeroUiState.Result) {
                HeroHungryButton(
                    state = if (state.hero == HeroUiState.Searching) HeroState.Searching else HeroState.Idle,
                    onClick = { viewModel.search(prefs) },
                )
            }
            if (state.picksCount > 0) BadgeLabel(text = stringResource(R.string.home_picks_badge, state.picksCount))
        }
        AnimatedContent(
            targetState = state.hero,
            transitionSpec = { fadeIn(LunchMotion.fadeIn()) togetherWith fadeOut(LunchMotion.state()) },
            label = "hero",
        ) { hero ->
            when (hero) {
                HeroUiState.Idle -> Unit
                HeroUiState.Searching -> AILoading(
                    title = stringResource(R.string.home_searching_title),
                    subtitle = stringResource(R.string.home_searching_body),
                    modifier = Modifier.fillMaxWidth(),
                )
                is HeroUiState.Result -> RecommendationCard(
                    restaurant = hero.restaurant.toView(),
                    reasons = hero.reasons,
                    confidence = hero.confidence.toFloat(),
                    onDirections = { Intents.directions(context, hero.restaurant) },
                    onLogMeal = { app.logMeal(hero.restaurant) },
                    onWhy = { app.present(AppRoute.AiRecommendations(pickPlaceId = hero.restaurant.placeId)) },
                    onShowMore = { app.present(AppRoute.AiRecommendations(pickPlaceId = null)) },
                    onReject = { viewModel.reject(hero.restaurant, prefs) },
                    modifier = Modifier.fillMaxWidth(),
                )
                HeroUiState.Empty -> EmptyState(
                    variant = EmptyStateVariant.NothingHere,
                    title = stringResource(R.string.home_empty_title),
                    message = stringResource(R.string.home_empty_body),
                    actionLabel = stringResource(R.string.home_empty_discover),
                    onAction = { app.selectTab(LunchTab.Discover) },
                    modifier = Modifier.fillMaxWidth(),
                )
                is HeroUiState.Failed -> ErrorStateView(error = hero.error, onRetry = { viewModel.search(prefs) }, modifier = Modifier.fillMaxWidth())
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            SectionTitle(text = stringResource(R.string.home_group_row_title))
            if (state.groups.isEmpty()) {
                LunchText(text = stringResource(R.string.home_group_row_empty), role = LunchTextRole.BodySmall, color = colors.textSecondary)
            }
            state.groups.forEach { group ->
                GroupCard(
                    group = group.toView(),
                    attendingCount = state.attendingCounts[group.id] ?: 0,
                    onClick = { app.present(AppRoute.GroupDetail(group.id)) },
                    formatTime = { LunchFormat.dayTime(it) },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (state.showHostGate) {
                UpsellRow(
                    title = stringResource(R.string.gate_host_title),
                    body = stringResource(R.string.gate_host_body),
                    ctaLabel = stringResource(R.string.gate_host_cta),
                    onCta = {
                        viewModel.dismissHostGate()
                        app.present(AppRoute.Paywall)
                    },
                    modifier = Modifier.fillMaxWidth(),
                )
            } else {
                LunchButton(
                    text = stringResource(R.string.home_group_row_plan),
                    onClick = viewModel::planGroupLunch,
                    style = LunchButtonStyle.Secondary,
                    icon = LunchIcon.GroupAdd,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}
