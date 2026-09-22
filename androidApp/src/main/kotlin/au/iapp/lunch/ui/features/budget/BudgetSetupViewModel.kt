/**
 * @file BudgetSetupViewModel.kt
 * @description Three-step weekly budget setup: amount, experience categories, celebrations.
 * Saves into `UserPreferences.weeklyBudget` and `contextualPreferences`. Mirrors
 * iosApp/.../Budget/BudgetSetupViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.budget

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.MealCategory
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class BudgetSetupUiState(
    val step: Int = 1,
    val weeklyBudget: Double = UserPreferences().weeklyBudget,
    val categories: List<MealCategory> = emptyList(),
    val selectedCategoryIds: Set<String> = emptySet(),
    val celebrations: Boolean = true,
    /** Lunches a week the budget engine targets for [weeklyBudget]. */
    val targetExperiences: Int = 0,
    val isSaving: Boolean = false,
    val error: CoreError? = null,
) {
    val progress: Float get() = step.toFloat() / BudgetSetupViewModel.STEP_COUNT
}

class BudgetSetupViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(BudgetSetupUiState())
    val state: StateFlow<BudgetSetupUiState> = _state.asStateFlow()

    init {
        val prefs = base()
        _state.update {
            it.copy(
                weeklyBudget = snap(prefs.weeklyBudget),
                categories = app.core.mealDefaults.categories,
                selectedCategoryIds = prefs.contextualPreferences[EXPERIENCES_KEY].orEmpty().toSet(),
                celebrations = prefs.contextualPreferences[CELEBRATIONS_KEY] != listOf(OFF),
            )
        }
        refreshTarget()
    }

    fun next() = _state.update { if (it.step < STEP_COUNT) it.copy(step = it.step + 1) else it }
    fun back() = _state.update { if (it.step > 1) it.copy(step = it.step - 1) else it }

    fun setWeeklyBudget(amount: Double) {
        _state.update { it.copy(weeklyBudget = snap(amount)) }
        refreshTarget()
    }

    fun toggleCategory(id: String) = _state.update {
        it.copy(selectedCategoryIds = if (id in it.selectedCategoryIds) it.selectedCategoryIds - id else it.selectedCategoryIds + id)
    }

    fun setCelebrations(on: Boolean) = _state.update { it.copy(celebrations = on) }

    /** The preferences this setup would save on top of [base]. */
    fun preferences(base: UserPreferences = base()): UserPreferences {
        val current = _state.value
        val contextual = base.contextualPreferences.toMutableMap()
        contextual[EXPERIENCES_KEY] = current.selectedCategoryIds.sorted()
        contextual[CELEBRATIONS_KEY] = listOf(if (current.celebrations) ON else OFF)
        return base.copy(weeklyBudget = current.weeklyBudget, contextualPreferences = contextual)
    }

    fun save(onSaved: () -> Unit = {}) {
        if (_state.value.isSaving) return
        _state.update { it.copy(isSaving = true, error = null) }
        viewModelScope.launch {
            val result = app.core.users.updatePreferences(preferences())
            _state.update { it.copy(isSaving = false, error = result.exceptionOrNull()?.asCoreError()) }
            if (result.isSuccess) onSaved()
        }
    }

    private fun base(): UserPreferences = app.user.value?.preferences ?: UserPreferences()

    private fun refreshTarget() = _state.update { it.copy(targetExperiences = app.core.budget.targetExperiences(preferences())) }

    companion object {
        const val STEP_COUNT = 3
        const val MIN = 50.0
        const val MAX = 500.0
        const val STEP = 45.0
        const val EXPERIENCES_KEY = "experiences"
        const val CELEBRATIONS_KEY = "celebrations"
        const val ON = "on"
        const val OFF = "off"

        /** Snaps to the slider's 45-dollar steps between 50 and 500. */
        fun snap(amount: Double): Double {
            val clamped = amount.coerceIn(MIN, MAX)
            return (MIN + Math.round((clamped - MIN) / STEP) * STEP).coerceIn(MIN, MAX)
        }
    }
}
