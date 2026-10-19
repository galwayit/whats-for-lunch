/**
 * @file AiRecommendationsViewModel.kt
 * @description Craving input, one free daily request, the upgrade prompt and recent history
 * for the AI recommendations screen. Mirrors iosApp/.../AI/AIRecommendationsViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.ai

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.AiConfiguration
import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.asCoreError
import au.iapp.lunch.ui.navigation.AppRoute
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId

data class AiUiState(
    val craving: String = "",
    val needsConsent: Boolean = false,
    val aiConfiguration: AiConfiguration? = null,
    val result: LoadState<AiRecommendation> = LoadState.Idle,
    val history: List<AiRecommendation> = emptyList(),
    val gateReason: GateReason? = null,
    val needsSubscription: Boolean = false,
    /** UTC midnight tomorrow, when the allowance resets. */
    val resetEpochSeconds: Long = 0L,
    /** The Home pick this screen explains, when opened through "Why this?". */
    val pick: Restaurant? = null,
) {
    val isGated: Boolean get() = gateReason == GateReason.AI_DAILY_LIMIT
    val canAsk: Boolean get() = !result.isLoading && !isGated
}

class AiRecommendationsViewModel(private val app: AppEnvironment, private val pickPlaceId: String?) : ViewModel() {
    private val _state = MutableStateFlow(AiUiState())
    val state: StateFlow<AiUiState> = _state.asStateFlow()
    private val core get() = app.core
    private var consentVersion: String? = null
    private var pendingCandidates: List<Restaurant>? = null
    fun allowAiSharing() {
        consentVersion = _state.value.aiConfiguration?.consentVersion ?: return
        _state.update { it.copy(needsConsent = false) }
        viewModelScope.launch { ask(pendingCandidates) }
    }
    fun declineAiSharing() { _state.update { it.copy(needsConsent = false) }; app.dismiss() }

    init {
        app.aiCravingDraft?.let { draft ->
            app.aiCravingDraft = null
            _state.update { it.copy(craving = draft) }
        }
        _state.update { it.copy(resetEpochSeconds = nextMidnight()) }
        load()
        viewModelScope.launch {
            combine(app.isPro, app.session) { _, _ -> Unit }.collect { refreshGate() }
        }
    }

    fun setCraving(value: String) = _state.update { it.copy(craving = value) }

    fun refreshAccess() { viewModelScope.launch { refreshGate() } }

    /** Pick mode explains one restaurant; otherwise the earlier picks load. */
    private fun load() {
        viewModelScope.launch {
            val pick = pickPlaceId?.let { core.restaurants.cached(it) }
            if (pick != null) {
                _state.update { it.copy(pick = pick) }
                ask(candidates = listOf(pick))
            } else if (_state.value.craving.isNotBlank()) {
                ask()
            } else {
                refreshGate()
                loadHistory()
            }
        }
    }

    fun ask() {
        if (!_state.value.canAsk) return
        viewModelScope.launch { ask(candidates = null) }
    }

    private suspend fun ask(candidates: List<Restaurant>?) {
        if (_state.value.result.isLoading) return
        val decision = core.gates.canRequestAi()
        if (!decision.allowed) {
            when (decision.reason) {
                GateReason.AI_DAILY_LIMIT -> showDailyLimit()
                else -> app.present(decision.reason)
            }
            return
        }
        _state.update { it.copy(result = LoadState.Loading, gateReason = null, needsSubscription = false) }
        val config = core.ai.configuration().getOrElse {
            _state.update { state -> state.copy(result = LoadState.Failed(it.asCoreError())) }
            return
        }
        _state.update { it.copy(aiConfiguration = config) }
        if (consentVersion != config.consentVersion) {
            pendingCandidates = candidates
            _state.update { it.copy(needsConsent = true, result = LoadState.Idle) }
            return
        }
        _state.update { it.copy(needsConsent = false) }
        val prefs = app.user.value?.preferences
        val outcome = runCatching {
            val pool = candidates ?: nearbyCandidates(prefs)
            core.ai.recommend(_state.value.craving.trim().ifEmpty { null }, MAX_RESULTS, pool, consentVersion = consentVersion).getOrThrow()
        }
        outcome.fold(
            onSuccess = { recommendation -> _state.update { it.copy(result = LoadState.Loaded(recommendation)) } },
            onFailure = { failure ->
                val error = failure.asCoreError()
                if (error is CoreError.Service && error.code == "AI_CONSENT_REQUIRED") {
                    consentVersion = null
                    pendingCandidates = candidates
                    val fresh = core.ai.configuration()
                    fresh.fold(
                        onSuccess = { config -> _state.update { it.copy(aiConfiguration = config, needsConsent = true, result = LoadState.Idle) } },
                        onFailure = { failure -> _state.update { it.copy(result = LoadState.Failed(failure.asCoreError())) } },
                    )
                } else if (error.isDailyLimit()) {
                    _state.update { it.copy(result = LoadState.Idle) }
                    showDailyLimit()
                } else if (error is CoreError.Gate && error.reason == GateReason.SIGN_IN_REQUIRED) {
                    _state.update { it.copy(result = LoadState.Idle) }
                    app.present(GateReason.SIGN_IN_REQUIRED)
                } else {
                    _state.update { it.copy(result = LoadState.Failed(error)) }
                }
            },
        )
        loadHistory()
    }

    private suspend fun nearbyCandidates(prefs: UserPreferences?): List<Restaurant> {
        val location = app.location.current().getOrThrow()
        val radius = prefs?.maxTravelDistance ?: UserPreferences().maxTravelDistance
        val nearby = core.restaurants.searchNearby(location, radius, query = null, forceRefresh = false).getOrThrow()
        return core.recommendation.applyPreferenceFilters(nearby, prefs)
    }

    private suspend fun refreshGate() {
        val decision = core.gates.canRequestAi()
        if (decision.reason == GateReason.AI_DAILY_LIMIT) { showDailyLimit(prompt = false); return }
        _state.update {
            it.copy(gateReason = decision.reason.takeUnless { decision.allowed },
                needsSubscription = false, resetEpochSeconds = nextMidnight(),
                needsConsent = it.needsConsent && decision.allowed)
        }
    }

    private fun showDailyLimit(prompt: Boolean = true) {
        val subscribe = !app.isPro.value
        val shouldPrompt = subscribe && (prompt || !_state.value.needsSubscription)
        _state.update { it.copy(gateReason = GateReason.AI_DAILY_LIMIT, needsSubscription = subscribe, needsConsent = false, resetEpochSeconds = nextMidnight()) }
        if (shouldPrompt) app.present(AppRoute.Paywall)
    }

    /** Free users see today's picks; Pro sees the last five. */
    private suspend fun loadHistory() {
        val userId = app.user.value?.id ?: return
        val history = core.ai.history(userId, HISTORY_LIMIT).getOrElse { emptyList() }
        val visible = if (app.isPro.value) history else history.filter { it.generatedAtEpochSeconds >= startOfToday() }
        _state.update { it.copy(history = visible) }
    }

    private fun zone(): ZoneId = ZoneId.of("UTC")
    private fun startOfToday(): Long = Instant.ofEpochSecond(app.clock.nowEpochSeconds()).atZone(zone()).toLocalDate().atStartOfDay(zone()).toEpochSecond()
    private fun nextMidnight(): Long = Instant.ofEpochSecond(app.clock.nowEpochSeconds()).atZone(zone()).toLocalDate().plusDays(1).atStartOfDay(zone()).toEpochSecond()

    private fun CoreError.isDailyLimit(): Boolean =
        (this is CoreError.Gate && reason == GateReason.AI_DAILY_LIMIT) || (this is CoreError.Service && code == DAILY_LIMIT_CODE)

    companion object {
        const val MAX_RESULTS = 3
        const val HISTORY_LIMIT = 5
        const val DAILY_LIMIT_CODE = "AI_DAILY_LIMIT"
    }
}
