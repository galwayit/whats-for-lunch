/**
 * @file InvitationViewModel.kt
 * @description Loads an invitation by code and records the guest's RSVP; guests may only view
 * and respond. After two accepted lunches a guest sees the Pro offer once. Mirrors
 * iosApp/.../Invitation/InvitationViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.invitation

import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class InvitationUiState(
    val invitation: LoadState<Invitation> = LoadState.Idle,
    val displayName: String = "",
    val isResponding: Boolean = false,
    val respondError: CoreError? = null,
    val showGuestOffer: Boolean = false,
    val showSuggestion: Boolean = false,
) {
    val needsName: Boolean get() = displayName.isBlank()
}

class InvitationViewModel(
    private val app: AppEnvironment,
    private val code: String,
    /** Counts accepted invitations across launches; null in unit tests. */
    private val prefs: SharedPreferences? = null,
) : ViewModel() {
    private val _state = MutableStateFlow(InvitationUiState())
    val state: StateFlow<InvitationUiState> = _state.asStateFlow()

    init {
        app.session.value?.displayName?.let { name -> _state.update { it.copy(displayName = name) } }
        if (_state.value.displayName.isBlank()) app.user.value?.name?.let { name -> _state.update { it.copy(displayName = name) } }
        load()
    }

    fun load() {
        _state.update { it.copy(invitation = LoadState.Loading) }
        viewModelScope.launch {
            app.core.groups.invitation(code).fold(
                onSuccess = { invitation -> _state.update { it.copy(invitation = LoadState.Loaded(invitation)) } },
                onFailure = { failure -> _state.update { it.copy(invitation = LoadState.Failed(failure.asCoreError())) } },
            )
        }
    }

    fun setDisplayName(value: String) = _state.update { it.copy(displayName = value, respondError = null) }
    fun accept() = respond(RsvpStatus.ACCEPTED)
    fun decline() = respond(RsvpStatus.DECLINED)
    fun dismissGuestOffer() = _state.update { it.copy(showGuestOffer = false) }

    fun showSuggestion(show: Boolean) = _state.update { it.copy(showSuggestion = show, respondError = null) }
    fun suggest(draft: au.iapp.lunch.core.model.GroupSuggestionDraft) {
        val current = _state.value
        if (current.isResponding || current.needsName) return
        _state.update { it.copy(isResponding = true, respondError = null) }
        viewModelScope.launch {
            app.core.groups.suggest(code, draft, current.displayName.trim()).fold(
                onSuccess = { invitation -> _state.update { it.copy(isResponding = false, showSuggestion = false, invitation = LoadState.Loaded(invitation)) } },
                onFailure = { failure -> _state.update { it.copy(isResponding = false, respondError = failure.asCoreError()) } },
            )
        }
    }

    private fun respond(status: RsvpStatus) {
        val current = _state.value
        if (current.isResponding || current.needsName) return
        _state.update { it.copy(isResponding = true, respondError = null) }
        viewModelScope.launch {
            val name = if (app.session.value == null) current.displayName.trim() else null
            app.core.groups.respond(code, status, name).fold(
                onSuccess = { invitation ->
                    val offer = status == RsvpStatus.ACCEPTED && countAccept() >= GUEST_OFFER_AFTER
                    _state.update { it.copy(isResponding = false, invitation = LoadState.Loaded(invitation), showGuestOffer = offer) }
                },
                onFailure = { failure -> _state.update { it.copy(isResponding = false, respondError = failure.asCoreError()) } },
            )
        }
    }

    /** Increments the accepted-invitation counter and returns the new total. */
    private fun countAccept(): Int {
        val store = prefs ?: return 0
        val total = store.getInt(ACCEPTED_KEY, 0) + 1
        store.edit().putInt(ACCEPTED_KEY, total).apply()
        return total
    }

    companion object {
        const val PREFS_NAME = "lunch_invitations"
        const val ACCEPTED_KEY = "accepted_count"
        const val GUEST_OFFER_AFTER = 2
    }
}
