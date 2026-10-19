/**
 * @file TrackViewModel.kt
 * @description Weekly capacity ring, the quick meal log draft with its budget impact, and the
 * recent-meals list with the free-tier history window, plus the "Split the bill" sheet it opens.
 * Mirrors iosApp/.../Track/TrackViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.track

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.Achievement
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.MealImpact
import au.iapp.lunch.core.model.WeeklyBudgetState
import au.iapp.lunch.ui.features.shared.asCoreError
import au.iapp.lunch.ui.features.split.PayIdStore
import au.iapp.lunch.ui.features.split.SplitBillViewModel
import au.iapp.lunch.ui.features.split.SplitMoney
import au.iapp.lunch.ui.features.split.SplitShare
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.util.Locale

enum class HistoryFilter(val windowDays: Int?) { Week(7), Month(30), All(null) }

/** One-shot events the screen turns into localised toasts. */
sealed class TrackEvent {
    data object Logged : TrackEvent()
    data class Unlocked(val achievement: Achievement) : TrackEvent()
}

data class MealDraft(
    val mealType: String = "lunch",
    val restaurantId: String? = null,
    val restaurantName: String = "",
    val cost: String = "",
    val dateEpochSeconds: Long = 0L,
    val notes: String = "",
) {
    val costValue: Double? get() = cost.trim().removePrefix("$").toDoubleOrNull()?.takeIf { it >= 0 }
    val canLog: Boolean get() = costValue != null
}

data class TrackUiState(
    val weekly: WeeklyBudgetState? = null,
    val draft: MealDraft = MealDraft(),
    val impact: MealImpact? = null,
    val recent: List<Meal> = emptyList(),
    val filter: HistoryFilter = HistoryFilter.Week,
    val suggestions: List<String> = emptyList(),
    val isLogging: Boolean = false,
    val logError: CoreError? = null,
    /** Free tier keeps 30 days; null means the full history is visible. */
    val historyWindowDays: Int? = null,
)

class TrackViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(TrackUiState(draft = freshDraft(app)))
    val state: StateFlow<TrackUiState> = _state.asStateFlow()
    private val _events = MutableStateFlow<List<TrackEvent>>(emptyList())
    val events: StateFlow<List<TrackEvent>> = _events.asStateFlow()
    private val core get() = app.core
    private var recentJob: Job? = null

    /** The open "Split the bill" sheet, or null. Held here so it survives rotation. */
    private val _split = MutableStateFlow<SplitBillViewModel?>(null)
    val split: StateFlow<SplitBillViewModel?> = _split.asStateFlow()

    init {
        refresh()
        observeRecent()
        app.consumeMealPrefill()?.let { prefill ->
            _state.update {
                it.copy(draft = it.draft.copy(restaurantId = prefill.restaurantId, restaurantName = prefill.restaurantName, cost = prefill.cost?.let(::costText).orEmpty()))
            }
            recomputeImpact()
        }
    }

    fun refresh() {
        viewModelScope.launch {
            val user = app.user.value ?: return@launch
            val now = app.clock.nowEpochSeconds()
            val weekStart = core.budget.weekStart(now, app.clock.timeZoneId())
            val meals = core.meals.inRange(user.id, weekStart, now).getOrElse { emptyList() }
            val weekly = core.budget.weeklyState(user.preferences, meals, weekStart)
            val suggestions = core.meals.restaurantSuggestions(user.id).getOrElse { emptyList() }
            _state.update { it.copy(weekly = weekly, suggestions = suggestions, historyWindowDays = core.gates.historyWindowDays()) }
            recomputeImpact()
        }
    }

    fun setFilter(filter: HistoryFilter) {
        _state.update { it.copy(filter = filter) }
        observeRecent()
    }

    fun setMealType(type: String) = updateDraft { it.copy(mealType = type) }
    fun setPlace(name: String) = updateDraft { it.copy(restaurantName = name, restaurantId = null) }
    fun pickSuggestion(name: String) = updateDraft { it.copy(restaurantName = name) }
    fun setCost(value: String) = updateDraft { it.copy(cost = value) }
    fun setDate(epochSeconds: Long) = updateDraft { it.copy(dateEpochSeconds = epochSeconds) }
    fun setNotes(value: String) = updateDraft { it.copy(notes = value) }
    fun consumeEvent() = _events.update { it.drop(1) }

    /** Opens the split sheet with the bill from the cost field (when valid) and 2 people. */
    fun openSplit(payIds: PayIdStore) {
        val draft = _state.value.draft
        _split.value = SplitBillViewModel.forTrack(costText = draft.cost, placeName = draft.restaurantName, payIds = payIds)
    }

    fun closeSplit() {
        _split.value = null
    }

    /** "Use my share": my share into the cost field, the split note only if notes are empty. */
    fun useSplitShare(share: SplitShare) {
        updateDraft { draft ->
            draft.copy(cost = SplitMoney.plain(share.myShareCents), notes = draft.notes.ifBlank { share.note })
        }
        closeSplit()
    }

    private fun updateDraft(transform: (MealDraft) -> MealDraft) {
        _state.update { it.copy(draft = transform(it.draft), logError = null) }
        recomputeImpact()
    }

    /** The budget engine's read on what this cost does to the week. */
    private fun recomputeImpact() {
        val current = _state.value
        val cost = current.draft.costValue
        val weekly = current.weekly
        val impact = if (cost != null && cost > 0 && weekly != null) core.budget.mealImpact(weekly, cost) else null
        _state.update { it.copy(impact = impact) }
    }

    fun log() {
        val current = _state.value
        val user = app.user.value ?: return
        val cost = current.draft.costValue ?: return
        if (current.isLogging) return
        _state.update { it.copy(isLogging = true, logError = null) }
        viewModelScope.launch {
            val meal = Meal(
                userId = user.id,
                restaurantId = current.draft.restaurantId,
                restaurantName = current.draft.restaurantName.trim().ifEmpty { null },
                mealType = current.draft.mealType,
                cost = cost,
                dateEpochSeconds = current.draft.dateEpochSeconds,
                notes = current.draft.notes.trim().ifEmpty { null },
            )
            core.meals.log(meal).fold(
                onSuccess = {
                    _state.update { it.copy(isLogging = false, draft = freshDraft(app), impact = null) }
                    _events.update { it + TrackEvent.Logged }
                    refresh()
                    unlockAchievements(user.id)
                },
                onFailure = { failure -> _state.update { it.copy(isLogging = false, logError = failure.asCoreError()) } },
            )
        }
    }

    /** Re-evaluates the catalogue against the week and queues a toast per new unlock. */
    private suspend fun unlockAchievements(userId: Long) {
        val prefs = app.user.value?.preferences ?: return
        val now = app.clock.nowEpochSeconds()
        val zone = app.clock.timeZoneId()
        val weekStart = core.budget.weekStart(now, zone)
        val week = core.meals.inRange(userId, weekStart, now).getOrElse { emptyList() }
        val all = core.meals.inRange(userId, 0L, now).getOrElse { week }
        val weekly = core.budget.weeklyState(prefs, week, weekStart)
        val unlockedIds = core.achievements.observe(userId).first().filter { it.isUnlocked }.map { it.id }.toSet()
        val unlocked = core.achievementEngine.evaluate(unlockedIds, weekly, all, now, zone)
        if (unlocked.isEmpty()) return
        core.achievements.unlock(userId, unlocked)
        _events.update { it + unlocked.map(TrackEvent::Unlocked) }
    }

    private fun observeRecent() {
        recentJob?.cancel()
        recentJob = viewModelScope.launch {
            app.user.collect { user ->
                val id = user?.id ?: return@collect
                val gateWindow = core.gates.historyWindowDays()
                val window = listOfNotNull(_state.value.filter.windowDays, gateWindow).minOrNull()
                core.meals.observeRecent(id, RECENT_LIMIT, window).collect { meals ->
                    _state.update { it.copy(recent = meals, historyWindowDays = gateWindow) }
                }
            }
        }
    }

    companion object {
        const val RECENT_LIMIT = 50
        val MEAL_TYPES = listOf("breakfast", "lunch", "dinner", "snack")

        fun costText(value: Double): String =
            if (value == Math.floor(value)) value.toLong().toString() else String.format(Locale.ROOT, "%.2f", value)

        private fun freshDraft(app: AppEnvironment): MealDraft {
            val now = app.clock.nowEpochSeconds()
            val hour = Instant.ofEpochSecond(now).atZone(ZoneId.of(app.clock.timeZoneId())).hour
            return MealDraft(mealType = app.core.mealDefaults.smartMealType(hour), dateEpochSeconds = now)
        }
    }
}
