/**
 * @file PreferencesViewModel.kt
 * @description Editable copy of `UserPreferences` for the Preferences screen. Mirrors
 * iosApp/.../Preferences/PreferencesViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.preferences

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.ui.features.shared.DietaryOptions
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class PreferencesUiState(
    val weeklyBudget: Double = UserPreferences().weeklyBudget,
    val budgetLevel: Int = UserPreferences().budgetLevel,
    val maxTravelDistance: Double = UserPreferences().maxTravelDistance,
    val includeChains: Boolean = true,
    val dietary: Set<String> = emptySet(),
    val allergens: Set<String> = emptySet(),
    val isSaving: Boolean = false,
    val error: CoreError? = null,
)

class PreferencesViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(PreferencesUiState())
    val state: StateFlow<PreferencesUiState> = _state.asStateFlow()

    init {
        val prefs = base()
        _state.update {
            it.copy(
                weeklyBudget = prefs.weeklyBudget.coerceIn(BUDGET_MIN, BUDGET_MAX),
                budgetLevel = prefs.budgetLevel.coerceIn(PRICE_LEVELS),
                maxTravelDistance = prefs.maxTravelDistance.coerceIn(DISTANCE_MIN, DISTANCE_MAX),
                includeChains = prefs.includeChains,
                dietary = prefs.dietaryRestrictions.map(DietaryOptions::key).toSet(),
                allergens = prefs.allergens.map(DietaryOptions::key).toSet(),
            )
        }
    }

    fun setWeeklyBudget(value: Double) = _state.update { it.copy(weeklyBudget = value.coerceIn(BUDGET_MIN, BUDGET_MAX)) }
    fun setBudgetLevel(level: Int) = _state.update { it.copy(budgetLevel = level.coerceIn(PRICE_LEVELS)) }
    fun setMaxTravelDistance(value: Double) = _state.update { it.copy(maxTravelDistance = value.coerceIn(DISTANCE_MIN, DISTANCE_MAX)) }
    fun setIncludeChains(on: Boolean) = _state.update { it.copy(includeChains = on) }
    fun toggleDietary(key: String) = _state.update { it.copy(dietary = it.dietary.toggled(key)) }
    fun toggleAllergen(key: String) = _state.update { it.copy(allergens = it.allergens.toggled(key)) }

    fun preferences(base: UserPreferences = base()): UserPreferences {
        val current = _state.value
        return base.copy(
            weeklyBudget = current.weeklyBudget,
            budgetLevel = current.budgetLevel,
            preferredPriceRanges = (1..current.budgetLevel).map { "$".repeat(it) },
            maxTravelDistance = current.maxTravelDistance,
            includeChains = current.includeChains,
            dietaryRestrictions = current.dietary.sorted(),
            allergens = current.allergens.sorted(),
        )
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
    private fun Set<String>.toggled(key: String): Set<String> = if (key in this) this - key else this + key

    companion object {
        const val BUDGET_MIN = 50.0
        const val BUDGET_MAX = 500.0
        const val BUDGET_STEP = 10.0
        const val DISTANCE_MIN = 1.0
        const val DISTANCE_MAX = 20.0
        val PRICE_LEVELS = 1..4
    }
}
