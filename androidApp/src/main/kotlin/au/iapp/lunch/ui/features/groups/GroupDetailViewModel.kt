/**
 * @file GroupDetailViewModel.kt
 * @description A hosted group's place, invite link, guests and the cancel action. The reminder
 * switch is local screen state only; the core has no reminder API yet. Mirrors
 * iosApp/.../Groups/GroupDetailViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.groups

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.app.LunchConfig
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class GroupDetailUiState(
    val group: LunchGroup? = null,
    val rsvps: List<Rsvp> = emptyList(),
    val reminderOn: Boolean = false,
    val isCancelling: Boolean = false,
    val isCancelled: Boolean = false,
    val error: CoreError? = null,
) {
    val inviteUrl: String get() = group?.let { LunchConfig.current.inviteUrl(it.inviteCode) }.orEmpty()
    val acceptedCount: Int get() = rsvps.count { it.status == RsvpStatus.ACCEPTED }
}

class GroupDetailViewModel(private val app: AppEnvironment, private val groupId: String) : ViewModel() {
    private val _state = MutableStateFlow(GroupDetailUiState())
    val state: StateFlow<GroupDetailUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            app.core.groups.myGroups().collect { groups -> _state.update { it.copy(group = groups.firstOrNull { g -> g.id == groupId }) } }
        }
        viewModelScope.launch {
            app.core.groups.rsvps(groupId).collect { rsvps -> _state.update { it.copy(rsvps = rsvps) } }
        }
    }

    fun setReminder(on: Boolean) = _state.update { it.copy(reminderOn = on) }

    fun cancel() {
        if (_state.value.isCancelling) return
        _state.update { it.copy(isCancelling = true, error = null) }
        viewModelScope.launch {
            app.core.groups.cancel(groupId).fold(
                onSuccess = { _state.update { it.copy(isCancelling = false, isCancelled = true) } },
                onFailure = { failure -> _state.update { it.copy(isCancelling = false, error = failure.asCoreError()) } },
            )
        }
    }
}
