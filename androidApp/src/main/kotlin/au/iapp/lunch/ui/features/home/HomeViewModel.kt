/**
 * @file HomeViewModel.kt
 * @description Hero search state, the picks count, the "Lunch together" groups and the host gate
 * for the Home tab. Mirrors iosApp/.../Home/HomeViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.ui.features.shared.asCoreError
import au.iapp.lunch.ui.navigation.AppRoute
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch

sealed class HeroUiState {
    data object Idle : HeroUiState()
    data object Searching : HeroUiState()
    data class Result(val restaurant: Restaurant, val reasons: List<String>, val confidence: Double) : HeroUiState()
    data object Empty : HeroUiState()
    data class Failed(val error: CoreError) : HeroUiState()
}

data class HomeUiState(
    val hero: HeroUiState = HeroUiState.Idle,
    val picksCount: Int = 0,
    val groups: List<LunchGroup> = emptyList(),
    val attendingCounts: Map<String, Int> = emptyMap(),
    val craving: String = "",
    /** True after a free user tapped "Plan a group lunch"; renders the host upsell. */
    val showHostGate: Boolean = false,
)

class HomeViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    private val rejected = mutableSetOf<String>()
    private val rsvpJobs = mutableMapOf<String, Job>()
    private var searchJob: Job? = null
    private var searchRevision = 0
    private val core get() = app.core

    init {
        observeGroups()
        viewModelScope.launch {
            app.user.map { it?.preferences }.distinctUntilChanged().drop(1).collect { reset() }
        }
    }

    fun setCraving(value: String) = _state.update { it.copy(craving = value) }

    fun search(prefs: UserPreferences?) {
        if (_state.value.hero == HeroUiState.Searching) return
        val revision = ++searchRevision
        _state.update { it.copy(hero = HeroUiState.Searching) }
        searchJob = viewModelScope.launch {
            val result = runCatching { performSearch(prefs) }
                .getOrElse { HeroUiState.Failed(it.asCoreError()) to 0 }
            if (revision == searchRevision) _state.update { it.copy(hero = result.first, picksCount = result.second) }
        }
    }

    private suspend fun performSearch(prefs: UserPreferences?): Pair<HeroUiState, Int> {
        val location = app.location.current().getOrThrow()
        val radius = prefs?.maxTravelDistance ?: UserPreferences().maxTravelDistance
        val nearby = core.restaurants.searchNearby(location, radius, query = null, forceRefresh = false).getOrThrow()
        val engine = core.recommendation
        val candidates = engine.applyPreferenceFilters(nearby, prefs)
        val picks = candidates.count { engine.compatibilityScore(it, prefs) > SCORE_THRESHOLD }
        val best = engine.bestMatch(candidates, prefs, rejected) ?: return HeroUiState.Empty to picks
        return HeroUiState.Result(
            restaurant = best,
            reasons = engine.reasons(best, prefs).take(REASON_COUNT),
            confidence = engine.compatibilityScore(best, prefs),
        ) to picks
    }

    /** "Not this one": remember the rejection and search again. */
    fun reject(restaurant: Restaurant, prefs: UserPreferences?) {
        rejected += restaurant.placeId
        search(prefs)
    }

    fun reset() {
        searchRevision++
        searchJob?.cancel()
        rejected.clear()
        _state.update { it.copy(hero = HeroUiState.Idle, picksCount = 0) }
    }

    /** Pro users route a typed craving straight to the AI screen. */
    fun submitCraving() {
        val craving = _state.value.craving.trim()
        if (craving.isEmpty()) return
        app.aiCravingDraft = craving
        _state.update { it.copy(craving = "") }
        app.present(AppRoute.AiRecommendations(pickPlaceId = null))
    }

    /** Host flow: Pro and signed in → create; free → inline upsell; signed out → sign-in sheet. */
    fun planGroupLunch() {
        val decision = core.gates.canHostGroup()
        when (decision.reason) {
            GateReason.OK -> app.present(AppRoute.GroupCreate)
            GateReason.HOST_REQUIRES_PRO -> _state.update { it.copy(showHostGate = true) }
            else -> app.present(decision.reason)
        }
    }

    fun dismissHostGate() = _state.update { it.copy(showHostGate = false) }

    private fun observeGroups() {
        viewModelScope.launch {
            core.groups.myGroups().collect { groups ->
                val sorted = groups.sortedBy { it.scheduledAtEpochSeconds }
                _state.update { it.copy(groups = sorted) }
                sorted.forEach { group -> if (group.id !in rsvpJobs) rsvpJobs[group.id] = observeRsvps(group.id) }
                (rsvpJobs.keys - sorted.map { it.id }.toSet()).forEach { id -> rsvpJobs.remove(id)?.cancel() }
            }
        }
    }

    private fun observeRsvps(groupId: String): Job = viewModelScope.launch {
        core.groups.rsvps(groupId).collect { rsvps ->
            val accepted = rsvps.count { it.status == RsvpStatus.ACCEPTED }
            _state.update { it.copy(attendingCounts = it.attendingCounts + (groupId to accepted)) }
        }
    }

    private companion object {
        const val REASON_COUNT = 3
        /** Same floor as RecommendationEngineImpl.SCORE_THRESHOLD (private there). */
        const val SCORE_THRESHOLD = 0.1
    }
}
