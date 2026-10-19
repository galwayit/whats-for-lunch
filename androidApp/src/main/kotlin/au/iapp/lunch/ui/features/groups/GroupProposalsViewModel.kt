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
import au.iapp.lunch.core.model.AiConfiguration
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
    val needsConsent: Boolean = false,
    val aiConfiguration: AiConfiguration? = null,
    val chooseError: CoreError? = null,
)

class GroupProposalsViewModel(private val app: AppEnvironment, private val groupId: String) : ViewModel() {
    private val _state = MutableStateFlow(GroupProposalsUiState())
    val state: StateFlow<GroupProposalsUiState> = _state.asStateFlow()

    private var consentVersion: String? = null
    fun allowAiSharing() {
        consentVersion = _state.value.aiConfiguration?.consentVersion ?: return
        _state.update { it.copy(needsConsent = false) }
        load()
    }
    fun declineAiSharing() { _state.update { it.copy(needsConsent = false) }; app.dismiss() }

    init {
        load()
    }

    fun load() {
        if (_state.value.proposals.isLoading) return
        _state.update { it.copy(proposals = LoadState.Loading) }
        viewModelScope.launch {
            val config = app.core.ai.configuration().getOrElse {
                _state.update { state -> state.copy(proposals = LoadState.Failed(it.asCoreError())) }
                return@launch
            }
            _state.update { it.copy(aiConfiguration = config) }
            if (consentVersion != config.consentVersion) {
                _state.update { it.copy(needsConsent = true, proposals = LoadState.Idle) }
                return@launch
            }
            _state.update { it.copy(needsConsent = false) }
            app.core.groups.propose(groupId, consentVersion = consentVersion).fold(
                onSuccess = { list -> _state.update { it.copy(proposals = LoadState.Loaded(list)) } },
                onFailure = { failure ->
                    val error = failure.asCoreError()
                    if (error is CoreError.Service && error.code == "AI_CONSENT_REQUIRED") {
                        consentVersion = null
                        app.core.ai.configuration().fold(
                            onSuccess = { config -> _state.update { it.copy(aiConfiguration = config, needsConsent = true, proposals = LoadState.Idle) } },
                            onFailure = { cause -> _state.update { it.copy(proposals = LoadState.Failed(cause.asCoreError())) } },
                        )
                    } else _state.update { it.copy(proposals = LoadState.Failed(error)) }
                },
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
