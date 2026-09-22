/**
 * @file ProfileViewModel.kt
 * @description Profile tab state: user, subscription, session, and the restore, sign-out,
 * export and delete actions. Mirrors iosApp/.../Profile/ProfileViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.SubscriptionStatus
import au.iapp.lunch.core.model.UserProfile
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

enum class ProfilePlan { Monthly, Yearly }

/** One-shot outcomes the screen turns into toasts or a share sheet. */
sealed class ProfileEvent {
    data object Restored : ProfileEvent()
    data object NothingToRestore : ProfileEvent()
    data class Export(val json: String) : ProfileEvent()
    data class Failed(val error: CoreError) : ProfileEvent()
}

data class ProfileUiState(
    val user: UserProfile? = null,
    val status: SubscriptionStatus = SubscriptionStatus(isPro = false),
    val session: AuthSession? = null,
    val isBusy: Boolean = false,
    val showDeleteConfirm: Boolean = false,
) {
    val isPro: Boolean get() = status.isPro
    val plan: ProfilePlan
        get() {
            val id = status.productId.orEmpty().lowercase()
            return if (id.contains("year") || id.contains("annual")) ProfilePlan.Yearly else ProfilePlan.Monthly
        }
}

class ProfileViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(ProfileUiState())
    val state: StateFlow<ProfileUiState> = _state.asStateFlow()
    private val _events = MutableStateFlow<List<ProfileEvent>>(emptyList())
    val events: StateFlow<List<ProfileEvent>> = _events.asStateFlow()
    private val core get() = app.core

    init {
        viewModelScope.launch {
            combine(app.user, core.entitlements.status, app.session) { user, status, session -> Triple(user, status, session) }
                .collect { (user, status, session) -> _state.update { it.copy(user = user, status = status, session = session) } }
        }
    }

    fun consumeEvent() = _events.update { it.drop(1) }
    fun askDelete() = _state.update { it.copy(showDeleteConfirm = true) }
    fun cancelDelete() = _state.update { it.copy(showDeleteConfirm = false) }

    fun restore() = busy {
        core.entitlements.restore().fold(
            onSuccess = { status -> emit(if (status.isPro) ProfileEvent.Restored else ProfileEvent.NothingToRestore) },
            onFailure = { emit(ProfileEvent.Failed(it.asCoreError())) },
        )
    }

    fun signOut() = busy {
        core.auth.signOut().fold(
            onSuccess = { core.entitlements.logOut() },
            onFailure = { emit(ProfileEvent.Failed(it.asCoreError())) },
        )
    }

    fun deleteAccount() = busy {
        _state.update { it.copy(showDeleteConfirm = false) }
        core.auth.deleteAccount().fold(
            onSuccess = { core.entitlements.logOut() },
            onFailure = { emit(ProfileEvent.Failed(it.asCoreError())) },
        )
    }

    /** Everything stored for this user as one JSON document to share. */
    fun export() = busy {
        val user = app.user.value ?: return@busy
        val meals = core.meals.inRange(user.id, 0L, app.clock.nowEpochSeconds()).getOrElse { emptyList() }
        val json = JSONObject().apply {
            put("name", user.name)
            put("createdAtEpochSeconds", user.createdAtEpochSeconds)
            put(
                "preferences",
                JSONObject().apply {
                    put("weeklyBudget", user.preferences.weeklyBudget)
                    put("budgetLevel", user.preferences.budgetLevel)
                    put("maxTravelDistance", user.preferences.maxTravelDistance)
                    put("includeChains", user.preferences.includeChains)
                    put("dietaryRestrictions", JSONArray(user.preferences.dietaryRestrictions))
                    put("allergens", JSONArray(user.preferences.allergens))
                },
            )
            put(
                "meals",
                JSONArray(
                    meals.map { meal ->
                        JSONObject().apply {
                            put("restaurantName", meal.restaurantName ?: JSONObject.NULL)
                            put("mealType", meal.mealType)
                            put("cost", meal.cost)
                            put("dateEpochSeconds", meal.dateEpochSeconds)
                            put("notes", meal.notes ?: JSONObject.NULL)
                        }
                    },
                ),
            )
        }
        emit(ProfileEvent.Export(json.toString(2)))
    }

    private fun emit(event: ProfileEvent) = _events.update { it + event }

    private fun busy(block: suspend () -> Unit) {
        if (_state.value.isBusy) return
        _state.update { it.copy(isBusy = true) }
        viewModelScope.launch {
            try {
                block()
            } finally {
                _state.update { it.copy(isBusy = false) }
            }
        }
    }

    companion object {
        /** Play's subscription centre; RevenueCat's `managementUrl` wins when present. */
        const val PLAY_SUBSCRIPTIONS_URL = "https://play.google.com/store/account/subscriptions"
    }
}
