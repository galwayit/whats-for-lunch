/**
 * @file AiRecommendationsScreen.kt
 * @description Screen 3 of design/screens.md: craving field, three ranked picks with the
 * reasoning and confidence, the free-tier gate row and earlier picks.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.ai

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTag
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.input.ImeAction
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.ui.components.AILoading
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.components.RestaurantCard
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.shared.ErrorStateView
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object AiDefaults {
    const val CRAVING_TEST_TAG = "craving_field"
    fun resultTag(index: Int) = "ai_result_$index"
}

@Composable
fun AiRecommendationsScreen(pickPlaceId: String?, modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: AiRecommendationsViewModel = viewModel(key = "ai:$pickPlaceId") { AiRecommendationsViewModel(app, pickPlaceId) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors

    ModalScreen(onBack = app::dismiss, modifier = modifier.imePadding()) {
        ScreenHeader(
            title = stringResource(if (state.pick != null) R.string.home_why_title else R.string.ai_title),
            onDismiss = app::dismiss,
        )
        LazyColumn(
            contentPadding = PaddingValues(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
        ) {
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
                    LunchTextField(
                        value = state.craving,
                        onValueChange = viewModel::setCraving,
                        placeholder = stringResource(R.string.ai_craving_placeholder),
                        leadingIcon = LunchIcon.AutoAwesome,
                        enabled = !state.isGated,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(onSearch = { viewModel.ask() }),
                        modifier = Modifier
                            .weight(1f)
                            .testTag(AiDefaults.CRAVING_TEST_TAG),
                    )
                    LunchButton(text = stringResource(R.string.ai_ask), onClick = viewModel::ask, enabled = state.canAsk)
                }
            }
            if (state.isGated) {
                item {
                    UpsellRow(
                        title = stringResource(R.string.gate_ai_title),
                        body = stringResource(R.string.gate_ai_body, LunchFormat.time(state.resetEpochSeconds)),
                        ctaLabel = stringResource(R.string.gate_ai_cta),
                        onCta = { app.present(AppRoute.Paywall) },
                    )
                }
            }
            when (val result = state.result) {
                LoadState.Idle -> if (!state.isGated && state.history.isEmpty()) {
                    item {
                        EmptyState(
                            variant = EmptyStateVariant.NothingHere,
                            title = stringResource(R.string.ai_empty_title),
                            message = stringResource(R.string.ai_empty_body),
                        )
                    }
                }
                LoadState.Loading -> item {
                    AILoading(title = stringResource(R.string.ai_thinking_title), subtitle = stringResource(R.string.ai_thinking_body), modifier = Modifier.fillMaxWidth())
                }
                is LoadState.Failed -> item { ErrorStateView(error = result.error, onRetry = viewModel::ask) }
                is LoadState.Loaded -> {
                    item { ReasoningCard(result.value) }
                    itemsIndexed(result.value.restaurants, key = { _, r -> r.placeId }) { index, restaurant ->
                        // mergeDescendants so the tag becomes one accessibility node, which is
                        // what testTagsAsResourceId exposes to Maestro.
                        Box(modifier = Modifier.semantics(mergeDescendants = true) { testTag = AiDefaults.resultTag(index) }) {
                            RestaurantCard(
                                restaurant = restaurant.toView(),
                                index = index,
                                isFavourite = false,
                                onClick = { app.logMeal(restaurant) },
                                onFavouriteClick = {},
                            )
                        }
                    }
                }
            }
            if (state.history.isNotEmpty()) {
                item { SectionTitle(text = stringResource(R.string.ai_history_title), modifier = Modifier.padding(top = TokenSpacing.sm)) }
                itemsIndexed(state.history, key = { _, h -> h.id }) { _, past ->
                    LunchCard(modifier = Modifier.fillMaxWidth()) {
                        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                            LunchText(text = past.restaurants.joinToString { it.name }, role = LunchTextRole.Heading)
                            LunchText(text = past.reasoning, role = LunchTextRole.BodySmall, color = colors.textSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
                            LunchText(text = LunchFormat.dayTime(past.generatedAtEpochSeconds), role = LunchTextRole.Caption, color = colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ReasoningCard(recommendation: AiRecommendation) {
    val colors = LunchTheme.colors
    LunchCard(modifier = Modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchText(text = stringResource(R.string.ai_confidence, recommendation.confidenceLevel), role = LunchTextRole.Label, color = colors.primary)
            LunchText(text = recommendation.reasoning, role = LunchTextRole.Body)
            recommendation.investmentSummary?.let {
                LunchText(text = it, role = LunchTextRole.BodySmall, color = colors.textSecondary)
            }
        }
    }
}
