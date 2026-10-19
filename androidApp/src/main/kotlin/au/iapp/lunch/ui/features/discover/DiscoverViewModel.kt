/**
 * @file DiscoverViewModel.kt
 * @description Search, filters, sort, favourites and the detail sheet for the Discover tab.
 * Mirrors iosApp/.../Discover/DiscoverViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.discover

import androidx.lifecycle.ViewModel
import au.iapp.lunch.core.engine.RestaurantChains
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.core.model.SortOption
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

enum class DiscoverSheet { Sort, Price, Distance, Rating, Dietary }

data class DiscoverFilters(
    val maxPriceLevel: Int? = null,
    val maxDistanceKm: Double? = null,
    val minRating: Double? = null,
    /** Hide places that fail the user's dietary needs. */
    val dietaryOnly: Boolean = false,
) {
    val isActive: Boolean get() = maxPriceLevel != null || maxDistanceKm != null || minRating != null || dietaryOnly
}

data class DiscoverUiState(
    val query: String = "",
    val results: LoadState<List<Restaurant>> = LoadState.Idle,
    /** [results] after filters and sort; what the list shows. */
    val visible: List<Restaurant> = emptyList(),
    val favourites: Set<String> = emptySet(),
    val sort: SortOption = SortOption.RELEVANCE,
    val filters: DiscoverFilters = DiscoverFilters(),
    val sheet: DiscoverSheet? = null,
    val selected: Restaurant? = null,
    val reviews: LoadState<List<RestaurantReview>> = LoadState.Idle,
    /** True after the free favourites cap blocked a toggle. */
    val isFavouriteGated: Boolean = false,
    val locationDenied: Boolean = false,
)

class DiscoverViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(DiscoverUiState())
    val state: StateFlow<DiscoverUiState> = _state.asStateFlow()
    private val core get() = app.core
    private var searchJob: Job? = null
    private var favouritesJob: Job? = null

    init {
        observeFavourites()
        viewModelScope.launch {
            app.user.map { it?.preferences }.distinctUntilChanged().collect { prefs ->
                _state.update { it.copy(visible = arrange(it.results.valueOrNull.orEmpty(), it.filters, it.sort, prefs)) }
            }
        }
        search()
    }

    fun setQuery(value: String) {
        _state.update { it.copy(query = value) }
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(DEBOUNCE_MS)
            runSearch()
        }
    }

    fun search() {
        searchJob?.cancel()
        searchJob = viewModelScope.launch { runSearch() }
    }

    private suspend fun runSearch() {
        _state.update { it.copy(results = LoadState.Loading, locationDenied = false) }
        val prefs = app.user.value?.preferences
        val outcome = runCatching {
            val location = app.location.current().getOrThrow()
            val radius = _state.value.filters.maxDistanceKm ?: prefs?.maxTravelDistance ?: UserPreferences().maxTravelDistance
            core.restaurants.searchNearby(location, radius, _state.value.query.trim().ifEmpty { null }, forceRefresh = false).getOrThrow()
        }
        outcome.fold(
            onSuccess = { list -> _state.update { it.copy(results = LoadState.Loaded(list), visible = arrange(list, it.filters, it.sort, app.user.value?.preferences)) } },
            onFailure = { failure -> _state.update { it.copy(results = LoadState.Failed(failure.asCoreError()), visible = emptyList()) } },
        )
    }

    fun setSort(sort: SortOption) = _state.update { it.copy(sort = sort, sheet = null, visible = arrange(it.results.valueOrNull.orEmpty(), it.filters, sort, prefs())) }

    fun setFilters(filters: DiscoverFilters) {
        val distanceChanged = filters.maxDistanceKm != _state.value.filters.maxDistanceKm
        _state.update { it.copy(filters = filters, sheet = null, visible = arrange(it.results.valueOrNull.orEmpty(), filters, it.sort, prefs())) }
        if (distanceChanged) search()
    }

    fun clearFilters() = setFilters(DiscoverFilters())
    fun openSheet(sheet: DiscoverSheet) = _state.update { it.copy(sheet = sheet) }
    fun closeSheet() = _state.update { it.copy(sheet = null) }

    /** Filters then sorts through the recommendation engine so Discover ranks like Home. */
    private fun arrange(list: List<Restaurant>, filters: DiscoverFilters, sort: SortOption, prefs: UserPreferences?): List<Restaurant> {
        val engine = core.recommendation
        val filtered = engine.applyPreferenceFilters(list, prefs).filter { r ->
            (prefs?.includeChains != false || !RestaurantChains.matches(r.name)) &&
                (filters.maxPriceLevel == null || (r.priceLevel ?: 0) <= filters.maxPriceLevel) &&
                (filters.maxDistanceKm == null || (r.distanceFromUser ?: 0.0) <= filters.maxDistanceKm) &&
                (filters.minRating == null || (r.rating ?: 0.0) >= filters.minRating) &&
                (!filters.dietaryOnly || prefs == null || engine.dietaryCompatibility(r, prefs.dietaryRestrictions, prefs.allergens) >= 1.0)
        }
        return engine.sort(filtered, sort, prefs)
    }

    fun select(restaurant: Restaurant) {
        _state.update { it.copy(selected = restaurant, reviews = LoadState.Loading) }
        viewModelScope.launch {
            app.user.value?.id?.let { core.restaurants.recordInteraction(it, restaurant.placeId, restaurant.name, INTERACTION_VIEW, null) }
            val reviews = core.restaurants.reviews(restaurant.placeId)
            _state.update { current ->
                if (current.selected?.placeId != restaurant.placeId) current
                else current.copy(reviews = reviews.fold({ LoadState.Loaded(it) }, { LoadState.Failed(it.asCoreError()) }))
            }
        }
    }

    fun closeDetail() = _state.update { it.copy(selected = null, reviews = LoadState.Idle) }

    fun toggleFavourite(restaurant: Restaurant) {
        val userId = app.user.value?.id ?: return
        viewModelScope.launch {
            val decision = core.favourites.toggle(userId, restaurant.placeId, restaurant.name).getOrNull() ?: return@launch
            if (!decision.allowed && decision.reason == GateReason.FAVOURITES_LIMIT) _state.update { it.copy(isFavouriteGated = true) }
        }
    }

    fun dismissFavouriteGate() = _state.update { it.copy(isFavouriteGated = false) }

    private fun observeFavourites() {
        favouritesJob?.cancel()
        favouritesJob = viewModelScope.launch {
            app.user.collect { user ->
                val id = user?.id ?: return@collect
                core.favourites.observe(id).collect { set -> _state.update { it.copy(favourites = set) } }
            }
        }
    }

    private fun prefs(): UserPreferences? = app.user.value?.preferences

    companion object {
        const val DEBOUNCE_MS = 400L
        const val INTERACTION_VIEW = "view"
        val RATING_STEPS: List<Double> = generateSequence(3.0) { it + 0.5 }.takeWhile { it <= 5.0 }.toList()
        val PRICE_LEVELS = 1..4
        val DISTANCE_STEPS = listOf(1.0, 2.0, 5.0, 10.0, 20.0)
    }
}
