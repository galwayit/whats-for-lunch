/**
 * @file DiscoverScreen.kt
 * @description Screen 4 of design/screens.md: search field, sort and filter chips, the result
 * count and restaurant cards, with the restaurant detail bottom sheet and the filter sheets.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.discover

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.core.model.SortOption
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant
import au.iapp.lunch.ui.components.RestaurantCard
import au.iapp.lunch.ui.components.SearchField
import au.iapp.lunch.ui.components.SheetAction
import au.iapp.lunch.ui.components.SheetContainer
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.shared.ChipGrid
import au.iapp.lunch.ui.features.shared.DietaryOptions
import au.iapp.lunch.ui.features.shared.ErrorStateView
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiscoverScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: DiscoverViewModel = viewModel { DiscoverViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val colors = LunchTheme.colors

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier.padding(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        ) {
            LunchText(text = stringResource(R.string.discover_title), role = LunchTextRole.Title)
            SearchField(value = state.query, onValueChange = viewModel::setQuery, onSearch = viewModel::search, modifier = Modifier.fillMaxWidth())
            FilterChips(state, viewModel)
        }
        when (val results = state.results) {
            LoadState.Idle, LoadState.Loading -> LoadingList()
            is LoadState.Failed -> ErrorStateView(error = results.error, onRetry = viewModel::search, modifier = Modifier.fillMaxWidth())
            is LoadState.Loaded -> LazyColumn(
                contentPadding = PaddingValues(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
            ) {
                item {
                    LunchText(text = stringResource(R.string.discover_count, state.visible.size), role = LunchTextRole.Label, color = colors.textSecondary)
                }
                if (state.isFavouriteGated) {
                    item {
                        UpsellRow(
                            title = stringResource(R.string.discover_favourite_limit_title),
                            body = stringResource(R.string.discover_favourite_limit_body),
                            ctaLabel = stringResource(R.string.discover_favourite_limit_cta),
                            onCta = {
                                viewModel.dismissFavouriteGate()
                                app.present(AppRoute.Paywall)
                            },
                        )
                    }
                }
                if (state.visible.isEmpty()) {
                    item {
                        EmptyState(
                            variant = EmptyStateVariant.NothingHere,
                            title = stringResource(R.string.discover_empty_title),
                            message = stringResource(R.string.discover_empty_body),
                            actionLabel = if (state.filters.isActive) stringResource(R.string.discover_filter_clear) else null,
                            onAction = viewModel::clearFilters,
                        )
                    }
                }
                itemsIndexed(state.visible, key = { _, r -> r.placeId }) { index, restaurant ->
                    RestaurantCard(
                        restaurant = restaurant.toView(),
                        index = index,
                        isFavourite = restaurant.placeId in state.favourites,
                        onClick = { viewModel.select(restaurant) },
                        onFavouriteClick = { viewModel.toggleFavourite(restaurant) },
                    )
                }
            }
        }
    }

    state.selected?.let { restaurant ->
        ModalBottomSheet(onDismissRequest = viewModel::closeDetail, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true), containerColor = colors.surface) {
            RestaurantDetailSheet(
                restaurant = restaurant,
                reviews = state.reviews,
                isFavourite = restaurant.placeId in state.favourites,
                onFavourite = { viewModel.toggleFavourite(restaurant) },
                onDirections = { Intents.directions(context, restaurant) },
                onOpenMaps = { Intents.showOnMap(context, restaurant) },
                onLogMeal = {
                    viewModel.closeDetail()
                    app.logMeal(restaurant)
                },
            )
        }
    }
    state.sheet?.let { sheet ->
        // The filter sheets use SheetContainer, which draws its own handle.
        ModalBottomSheet(onDismissRequest = viewModel::closeSheet, containerColor = colors.surface, dragHandle = null) {
            FilterSheet(sheet, state, viewModel)
        }
    }
}

@Composable
private fun FilterChips(state: DiscoverUiState, viewModel: DiscoverViewModel) {
    val filters = state.filters
    val prefs = LocalAppEnvironment.current.user.collectAsStateWithLifecycle().value?.preferences
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        Chip(text = stringResource(R.string.discover_sort, sortLabel(state.sort)), selected = state.sort != SortOption.RELEVANCE, onClick = { viewModel.openSheet(DiscoverSheet.Sort) }, trailingChevron = true)
        Chip(
            text = filters.maxPriceLevel?.let { stringResource(R.string.discover_chip_price, "$".repeat(it)) } ?: stringResource(R.string.discover_filter_price),
            selected = filters.maxPriceLevel != null,
            onClick = { viewModel.openSheet(DiscoverSheet.Price) },
            trailingChevron = true,
        )
        Chip(
            text = filters.maxDistanceKm?.let { stringResource(R.string.discover_chip_distance, LunchFormat.compact(it)) } ?: stringResource(R.string.discover_filter_distance),
            selected = filters.maxDistanceKm != null,
            onClick = { viewModel.openSheet(DiscoverSheet.Distance) },
            trailingChevron = true,
        )
        Chip(
            text = filters.minRating?.let { stringResource(R.string.discover_chip_rating, LunchFormat.compact(it)) } ?: stringResource(R.string.discover_filter_rating),
            selected = filters.minRating != null,
            onClick = { viewModel.openSheet(DiscoverSheet.Rating) },
            trailingChevron = true,
        )
        val dietaryCount = (prefs?.dietaryRestrictions.orEmpty() + prefs?.allergens.orEmpty()).size
        Chip(
            text = if (filters.dietaryOnly) stringResource(R.string.discover_chip_dietary, dietaryCount) else stringResource(R.string.discover_filter_dietary),
            selected = filters.dietaryOnly,
            onClick = { viewModel.openSheet(DiscoverSheet.Dietary) },
            trailingChevron = true,
        )
    }
}

@Composable
private fun sortLabel(sort: SortOption): String = stringResource(
    when (sort) {
        SortOption.RELEVANCE -> R.string.discover_sort_relevance
        SortOption.PRICE -> R.string.discover_sort_price
        SortOption.DISTANCE -> R.string.discover_sort_distance
        SortOption.RATING -> R.string.discover_sort_rating
    },
)

@Composable
private fun LoadingList() {
    val colors = LunchTheme.colors
    Column(modifier = Modifier.padding(TokenSpacing.page), verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        repeat(3) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(TokenSize.touchTarget * 2)
                    
                    .background(colors.surface, LunchTheme.shapes.container),
            )
        }
    }
}

/** Sort, price, distance, rating and dietary sheets share one container. */
@Composable
private fun FilterSheet(sheet: DiscoverSheet, state: DiscoverUiState, viewModel: DiscoverViewModel) {
    val app = LocalAppEnvironment.current
    val prefs = app.user.collectAsStateWithLifecycle().value?.preferences
    var draft by remember(sheet) { mutableStateOf(state.filters) }
    val apply = SheetAction(label = stringResource(R.string.discover_filter_apply), onClick = { viewModel.setFilters(draft) })
    val clear = SheetAction(label = stringResource(R.string.discover_filter_clear), onClick = viewModel::clearFilters)
    when (sheet) {
        DiscoverSheet.Sort -> SheetContainer(title = stringResource(R.string.discover_sort_title)) {
            ChipGrid(
                options = SortOption.entries.map { it.name to sortLabel(it) },
                selected = setOf(state.sort.name),
                onToggle = { viewModel.setSort(SortOption.valueOf(it)) },
            )
        }
        DiscoverSheet.Price -> SheetContainer(title = stringResource(R.string.discover_filter_price_title), primaryAction = apply, secondaryAction = clear) {
            ChipGrid(
                options = DiscoverViewModel.PRICE_LEVELS.map { it.toString() to "$".repeat(it) },
                selected = setOfNotNull(draft.maxPriceLevel?.toString()),
                onToggle = { draft = draft.copy(maxPriceLevel = it.toInt().takeIf { level -> level != draft.maxPriceLevel }) },
            )
        }
        DiscoverSheet.Distance -> SheetContainer(title = stringResource(R.string.discover_filter_distance_title), primaryAction = apply, secondaryAction = clear) {
            ChipGrid(
                options = DiscoverViewModel.DISTANCE_STEPS.map { it.toString() to stringResource(R.string.discover_chip_distance, LunchFormat.compact(it)) },
                selected = setOfNotNull(draft.maxDistanceKm?.toString()),
                onToggle = { draft = draft.copy(maxDistanceKm = it.toDouble().takeIf { km -> km != draft.maxDistanceKm }) },
            )
        }
        DiscoverSheet.Rating -> SheetContainer(title = stringResource(R.string.discover_filter_rating_title), primaryAction = apply, secondaryAction = clear) {
            ChipGrid(
                options = DiscoverViewModel.RATING_STEPS.map { it.toString() to stringResource(R.string.discover_chip_rating, LunchFormat.compact(it)) },
                selected = setOfNotNull(draft.minRating?.toString()),
                onToggle = { draft = draft.copy(minRating = it.toDouble().takeIf { r -> r != draft.minRating }) },
            )
        }
        DiscoverSheet.Dietary -> SheetContainer(title = stringResource(R.string.discover_filter_dietary_title), primaryAction = apply, secondaryAction = clear) {
            val needs = (prefs?.dietaryRestrictions.orEmpty() + prefs?.allergens.orEmpty()).map(DietaryOptions::key)
            val labels = DietaryOptions.all.filter { it.key in needs }.map { it.key to stringResource(it.labelRes) }
            if (labels.isEmpty()) {
                LunchText(text = stringResource(R.string.preferences_section_dietary), role = LunchTextRole.BodySmall, color = LunchTheme.colors.textSecondary)
            } else {
                ChipGrid(options = labels, selected = if (draft.dietaryOnly) needs.toSet() else emptySet(), onToggle = { draft = draft.copy(dietaryOnly = !draft.dietaryOnly) })
            }
        }
    }
}
