/**
 * @file GroupDetailViewModel.kt
 * @description A hosted group's place, invite link, guests and the cancel action. The reminder
 * switch is local screen state only; the core has no reminder API yet. Once a place is
 * confirmed the host can split the bill and log their share as a meal. Mirrors
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
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.ui.features.shared.asCoreError
import au.iapp.lunch.ui.features.split.PayIdStore
import au.iapp.lunch.ui.features.split.SplitBillViewModel
import au.iapp.lunch.ui.features.split.SplitShare
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class GroupDetailUiState(
    val group: LunchGroup? = null,
    val isHost: Boolean = false,
    val suggestions: List<au.iapp.lunch.core.model.GroupSuggestion> = emptyList(),
    val suggestionsError: CoreError? = null,
    val reviewing: Boolean = false,
    val editing: Boolean = false,
    val saving: Boolean = false,
    val rsvps: List<Rsvp> = emptyList(),
    val reminderOn: Boolean = false,
    val isCancelling: Boolean = false,
    val isCancelled: Boolean = false,
    val error: CoreError? = null,
    /** "Use my share" is logging the host's meal. */
    val isLoggingShare: Boolean = false,
    /** The share was logged; the screen shows the `Logged` toast and clears this. */
    val didLogShare: Boolean = false,
) {
    val inviteUrl: String get() = group?.let { LunchConfig.current.inviteUrl(it.inviteCode) }.orEmpty()
    val acceptedCount: Int get() = rsvps.count { it.status == RsvpStatus.ACCEPTED }

    /** Splitting needs a restaurant, so it waits until the host has confirmed a place. */
    val canSplit: Boolean get() = group?.placeName != null

    /**
     * Everyone accepted, by display name, except the host's own RSVP: the host is "You" (row 0)
     * and the core records the host as an accepted guest of their own group.
     */
    val splitGuestNames: List<String>
        get() = rsvps.filter { it.status == RsvpStatus.ACCEPTED && it.guestUserId != group?.hostId }.map { it.displayName }
}

class GroupDetailViewModel(private val app: AppEnvironment, private val groupId: String) : ViewModel() {
    private val _state = MutableStateFlow(GroupDetailUiState())
    val state: StateFlow<GroupDetailUiState> = _state.asStateFlow()

    /** The open "Split the bill" sheet, or null. Held here so it survives rotation. */
    private val _split = MutableStateFlow<SplitBillViewModel?>(null)
    val split: StateFlow<SplitBillViewModel?> = _split.asStateFlow()

    init {
        refresh()
    }

    fun refresh() { viewModelScope.launch { refreshNow() } }
    private suspend fun refreshNow() {
        app.core.groups.loadGroups().fold(
            onSuccess = { groups -> val group = groups.firstOrNull { it.id == groupId }; _state.update { it.copy(group = group, isHost = group != null && group.hostId == app.session.value?.userId) } },
            onFailure = { failure -> _state.update { it.copy(error = failure.asCoreError()) } },
        )
        app.core.groups.loadRsvps(groupId).onSuccess { rows -> _state.update { it.copy(rsvps = rows) } }
        if (_state.value.isHost) app.core.groups.suggestions(groupId).fold(
            onSuccess = { rows -> _state.update { it.copy(suggestions = rows, suggestionsError = null) } },
            onFailure = { failure -> _state.update { it.copy(suggestionsError = failure.asCoreError()) } },
        )
    }
    fun setEditing(editing: Boolean) = _state.update { it.copy(editing = editing, error = null) }
    fun saveDetails(details: au.iapp.lunch.core.model.GroupDetails) {
        if (_state.value.saving) return
        _state.update { it.copy(saving = true, error = null) }
        viewModelScope.launch {
            app.core.groups.updateDetails(groupId, details).fold(
                onSuccess = { group -> _state.update { it.copy(group = group, editing = false, saving = false) } },
                onFailure = { failure -> _state.update { it.copy(error = failure.asCoreError(), saving = false) } },
            )
        }
    }
    fun review(suggestionId: String, accept: Boolean) {
        if (_state.value.reviewing) return
        _state.update { it.copy(reviewing = true, error = null) }
        viewModelScope.launch {
            app.core.groups.reviewSuggestion(groupId, suggestionId, accept).fold(
                onSuccess = { group -> _state.update { it.copy(group = group) } },
                onFailure = { failure -> _state.update { it.copy(error = failure.asCoreError()) } },
            )
            refreshNow()
            _state.update { it.copy(reviewing = false) }
        }
    }

    fun setReminder(on: Boolean) = _state.update { it.copy(reminderOn = on) }

    fun openSplit(payIds: PayIdStore) {
        val current = _state.value
        if (!current.canSplit) return
        _state.update { it.copy(error = null) }
        _split.value = SplitBillViewModel.forGroup(current.group?.placeName, current.splitGuestNames, payIds)
    }

    fun closeSplit() {
        _split.value = null
    }

    /** "Use my share": logs my share as today's group lunch through the meal repository. */
    fun logSplitShare(share: SplitShare) {
        val current = _state.value
        val group = current.group ?: return
        val user = app.user.value ?: return
        if (current.isLoggingShare) return
        _state.update { it.copy(isLoggingShare = true, error = null) }
        viewModelScope.launch {
            val meal = Meal(
                userId = user.id,
                restaurantId = group.placeId,
                restaurantName = group.placeName,
                mealType = SPLIT_MEAL_TYPE,
                cost = share.myShareCents / CENTS_PER_DOLLAR,
                dateEpochSeconds = group.scheduledAtEpochSeconds,
                notes = share.note,
            )
            app.core.meals.log(meal).fold(
                onSuccess = {
                    _state.update { it.copy(isLoggingShare = false, didLogShare = true) }
                    closeSplit()
                },
                // The sheet stays open with the error so the host can retry without retyping.
                onFailure = { failure -> _state.update { it.copy(isLoggingShare = false, error = failure.asCoreError()) } },
            )
        }
    }

    fun consumeLoggedShare() = _state.update { it.copy(didLogShare = false) }

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

    private companion object {
        const val SPLIT_MEAL_TYPE = "lunch"
        const val CENTS_PER_DOLLAR = 100.0
    }
}
