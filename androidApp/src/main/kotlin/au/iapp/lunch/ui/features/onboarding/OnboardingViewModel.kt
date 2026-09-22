/**
 * @file OnboardingViewModel.kt
 * @description Five-step onboarding state. Finishing creates the user through
 * `UserRepository.createUser` and asks Home to run the first search. Mirrors
 * iosApp/.../Onboarding/OnboardingViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.onboarding

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

data class OnboardingUiState(
    val step: Int = 1,
    val name: String = "",
    val budgetLevel: Int = 2,
    val maxTravelDistance: Double = 5.0,
    val includeChains: Boolean = true,
    val dietary: Set<String> = emptySet(),
    val isSubmitting: Boolean = false,
    val error: CoreError? = null,
) {
    val progress: Float get() = step.toFloat() / OnboardingViewModel.STEP_COUNT
    val trimmedName: String get() = name.trim()
    val canContinue: Boolean get() = step != 2 || trimmedName.isNotEmpty()

    /** The preferences the new user starts with. */
    val preferences: UserPreferences
        get() {
            val chosen = dietary - DietaryOptions.NONE
            return UserPreferences(
                budgetLevel = budgetLevel,
                maxTravelDistance = maxTravelDistance,
                includeChains = includeChains,
                preferredPriceRanges = (1..budgetLevel).map { "$".repeat(it) },
                dietaryRestrictions = chosen.filter { it !in DietaryOptions.allergenKeys }.sorted(),
                allergens = chosen.filter { it in DietaryOptions.allergenKeys }.sorted(),
            )
        }
}

class OnboardingViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(OnboardingUiState())
    val state: StateFlow<OnboardingUiState> = _state.asStateFlow()

    fun next() = _state.update { if (it.step < STEP_COUNT) it.copy(step = it.step + 1) else it }
    fun back() = _state.update { if (it.step > 1) it.copy(step = it.step - 1) else it }
    fun setName(value: String) = _state.update { it.copy(name = value) }
    fun setBudgetLevel(level: Int) = _state.update { it.copy(budgetLevel = level.coerceIn(PRICE_LEVELS)) }
    fun setMaxTravelDistance(km: Double) = _state.update { it.copy(maxTravelDistance = km.coerceIn(DISTANCE_MIN, DISTANCE_MAX)) }
    fun setIncludeChains(on: Boolean) = _state.update { it.copy(includeChains = on) }

    /** "None of these" clears the others; any other choice clears "None of these". */
    fun toggleDietary(key: String) = _state.update { current ->
        val next = when {
            key == DietaryOptions.NONE -> if (DietaryOptions.NONE in current.dietary) emptySet() else setOf(DietaryOptions.NONE)
            key in current.dietary -> current.dietary - key
            else -> current.dietary - DietaryOptions.NONE + key
        }
        current.copy(dietary = next)
    }

    /** Creates the user; on success Home runs the first search. [onDone] runs only on success. */
    fun finish(onDone: () -> Unit = {}) {
        if (_state.value.isSubmitting) return
        _state.update { it.copy(isSubmitting = true, error = null) }
        viewModelScope.launch {
            val current = _state.value
            val result = app.core.users.createUser(current.trimmedName, current.preferences)
            _state.update { it.copy(isSubmitting = false, error = result.exceptionOrNull()?.asCoreError()) }
            if (result.isSuccess) {
                app.shouldRunFirstSearch = true
                onDone()
            }
        }
    }

    companion object {
        const val STEP_COUNT = 5
        const val DISTANCE_MIN = 1.0
        const val DISTANCE_MAX = 20.0
        val PRICE_LEVELS = 1..4
    }
}
