/**
 * @file TrackScreen.kt
 * @description Screen 5 of design/screens.md: the capacity ring, the quick meal log card and
 * the recent meals list with the free-tier history gate. Hosts the "Split the bill" sheet.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.track

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.ui.components.CapacityRing
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.split.SplitBillSheet
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun TrackScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: TrackViewModel = viewModel { TrackViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val events by viewModel.events.collectAsStateWithLifecycle()
    val split by viewModel.split.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors
    val loggedToast = stringResource(R.string.track_log_logged)
    val unlockedTemplate = stringResource(R.string.track_achievement_unlocked, "%s")

    // Each queued event becomes one toast; consume so the next one shows after it.
    LaunchedEffect(events) {
        val event = events.firstOrNull() ?: return@LaunchedEffect
        app.showToast(
            when (event) {
                TrackEvent.Logged -> loggedToast
                is TrackEvent.Unlocked -> unlockedTemplate.format(event.achievement.title)
            },
        )
        viewModel.consumeEvent()
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .imePadding(),
        contentPadding = PaddingValues(horizontal = TokenSpacing.page, vertical = TokenSpacing.md),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
    ) {
        item { LunchText(text = stringResource(R.string.track_title), role = LunchTextRole.Title) }
        item { CapacitySection(state = state, onSetup = { app.present(AppRoute.BudgetSetup) }) }
        item { MealLogCard(state = state, viewModel = viewModel) }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                SectionTitle(text = stringResource(R.string.track_recent_title))
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    HistoryFilter.entries.forEach { filter ->
                        Chip(text = filterLabel(filter), selected = state.filter == filter, onClick = { viewModel.setFilter(filter) })
                    }
                }
            }
        }
        if (state.recent.isEmpty()) {
            item {
                EmptyState(
                    variant = EmptyStateVariant.NothingHere,
                    title = stringResource(R.string.track_recent_empty_title),
                    message = stringResource(R.string.track_recent_empty_body),
                )
            }
        }
        items(state.recent, key = { it.id ?: it.dateEpochSeconds }) { meal -> MealRow(meal, app.clock.nowEpochSeconds()) }
        if (state.historyWindowDays != null && state.filter == HistoryFilter.All) {
            item {
                UpsellRow(
                    title = stringResource(R.string.track_history_gate),
                    body = stringResource(R.string.track_history_gate_body),
                    ctaLabel = stringResource(R.string.track_history_gate_cta),
                    onCta = { app.present(AppRoute.Paywall) },
                )
            }
        }
    }
    split?.let { sheet ->
        SplitBillSheet(viewModel = sheet, onDismiss = viewModel::closeSplit, onUseShare = viewModel::useSplitShare)
    }
}

@Composable
private fun CapacitySection(state: TrackUiState, onSetup: () -> Unit) {
    val colors = LunchTheme.colors
    val weekly = state.weekly
    Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        CapacityRing(
            progress = weekly?.capacityProgress?.toFloat() ?: 0f,
            diameter = TokenSize.heroButton * 0.75f,
        ) {
            if (weekly != null) {
                LunchText(text = LunchFormat.currency(weekly.remainingCapacity.coerceAtLeast(0.0)), role = LunchTextRole.Display, textAlign = TextAlign.Center)
                LunchText(text = stringResource(R.string.track_ring_remaining_short), role = LunchTextRole.Caption, color = colors.textSecondary, textAlign = TextAlign.Center)
            }
        }
        if (weekly != null) {
            LunchText(
                text = stringResource(R.string.track_ring_label, LunchFormat.currency(weekly.currentSpent), LunchFormat.currency(weekly.weeklyCapacity)),
                role = LunchTextRole.Body,
            )
            LunchText(text = stringResource(R.string.track_experiences, weekly.experiencesLogged, weekly.targetExperiences), role = LunchTextRole.Caption, color = colors.textSecondary)
        }
        LunchButton(text = stringResource(R.string.track_ring_setup), onClick = onSetup, style = LunchButtonStyle.Text)
    }
}

@Composable
private fun filterLabel(filter: HistoryFilter): String = stringResource(
    when (filter) {
        HistoryFilter.Week -> R.string.track_filter_week
        HistoryFilter.Month -> R.string.track_filter_month
        HistoryFilter.All -> R.string.track_filter_all
    },
)

@Composable
fun mealTypeLabel(type: String): String = when (type) {
    "breakfast" -> stringResource(R.string.track_type_breakfast)
    "dinner" -> stringResource(R.string.track_type_dinner)
    "snack" -> stringResource(R.string.track_type_snack)
    else -> stringResource(R.string.track_type_lunch)
}

@Composable
private fun MealRow(meal: Meal, nowEpochSeconds: Long) {
    val colors = LunchTheme.colors
    LunchCard(modifier = Modifier.fillMaxWidth()) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                LunchText(text = meal.restaurantName ?: mealTypeLabel(meal.mealType), role = LunchTextRole.Heading)
                LunchText(
                    text = mealTypeLabel(meal.mealType) + SEPARATOR +
                        LunchFormat.relativeDay(meal.dateEpochSeconds, nowEpochSeconds, stringResource(R.string.date_today), stringResource(R.string.date_yesterday)),
                    role = LunchTextRole.Caption,
                    color = colors.textSecondary,
                )
                meal.notes?.let { LunchText(text = it, role = LunchTextRole.Caption, color = colors.textSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis) }
            }
            LunchText(text = LunchFormat.currency(meal.cost), role = LunchTextRole.Heading)
        }
    }
}

private const val SEPARATOR = " · "
