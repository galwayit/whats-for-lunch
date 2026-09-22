/**
 * @file GroupProposalsViewModel.kt
 * @description Asks the backend for three places for a group and confirms the host's choice.
 * Mirrors iosApp/.../Groups/GroupProposalsViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.groups

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.asCoreError
import au.iapp.lunch.ui.navigation.AppRoute
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class GroupProposalsUiState(
    val proposals: LoadState<List<GroupProposal>> = LoadState.Idle,
    val choosingPlaceId: String? = null,
    val chooseError: CoreError? = null,
)

class GroupProposalsViewModel(private val app: AppEnvironment, private val groupId: String) : ViewModel() {
    private val _state = MutableStateFlow(GroupProposalsUiState())
    val state: StateFlow<GroupProposalsUiState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        _state.update { it.copy(proposals = LoadState.Loading) }
        viewModelScope.launch {
            app.core.groups.propose(groupId).fold(
                onSuccess = { list -> _state.update { it.copy(proposals = LoadState.Loaded(list)) } },
                onFailure = { failure -> _state.update { it.copy(proposals = LoadState.Failed(failure.asCoreError())) } },
            )
        }
    }

    fun choose(restaurant: Restaurant) {
        if (_state.value.choosingPlaceId != null) return
        _state.update { it.copy(choosingPlaceId = restaurant.placeId, chooseError = null) }
        viewModelScope.launch {
            app.core.groups.confirmPlace(groupId, restaurant).fold(
                onSuccess = { group ->
                    _state.update { it.copy(choosingPlaceId = null) }
                    app.replaceTop(AppRoute.GroupDetail(group.id))
                },
                onFailure = { failure -> _state.update { it.copy(choosingPlaceId = null, chooseError = failure.asCoreError()) } },
            )
        }
    }
}
