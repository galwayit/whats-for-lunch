/**
 * @file GroupCreateViewModel.kt
 * @description Name, time, area and radius for a new lunch group; hosting is Pro-only through
 * the gate service. Mirrors iosApp/.../Groups/GroupCreateViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.groups

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.ui.features.shared.asCoreError
import au.iapp.lunch.ui.navigation.AppRoute
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId

data class GroupCreateUiState(
    val name: String = "",
    val details: GroupDetailsDraft = GroupDetailsDraft(),
    val scheduledAtEpochSeconds: Long = 0L,
    val area: Location? = null,
    val isLocating: Boolean = false,
    val radiusKm: Double = GroupCreateViewModel.DEFAULT_RADIUS_KM,
    val isCreating: Boolean = false,
    val error: CoreError? = null,
    /** True when the host gate said Pro is required; the screen shows the upsell. */
    val showHostGate: Boolean = false,
) {
    val canCreate: Boolean get() = name.isNotBlank() && details.value() != null && area != null && !isCreating && !showHostGate
}

class GroupCreateViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(GroupCreateUiState(scheduledAtEpochSeconds = defaultTime(app), details = GroupDetailsDraft(hostName = app.session.value?.displayName ?: app.user.value?.name.orEmpty())))
    val state: StateFlow<GroupCreateUiState> = _state.asStateFlow()

    init {
        checkGate()
        useCurrentLocation()
    }

    fun setDetails(value: GroupDetailsDraft) = _state.update { it.copy(details = value) }
    fun setName(value: String) = _state.update { it.copy(name = value, error = null) }
    fun setScheduledAt(epochSeconds: Long) = _state.update { it.copy(scheduledAtEpochSeconds = epochSeconds) }
    fun setRadius(km: Double) = _state.update { it.copy(radiusKm = km) }

    fun useCurrentLocation() {
        _state.update { it.copy(isLocating = true) }
        viewModelScope.launch {
            val result = app.location.current()
            _state.update { it.copy(isLocating = false, area = result.getOrNull() ?: it.area, error = result.exceptionOrNull()?.asCoreError()) }
        }
    }

    private fun checkGate() {
        viewModelScope.launch {
            val decision = app.core.gates.canHostGroup()
            if (!decision.allowed) handleGate(decision.reason)
        }
    }

    private fun handleGate(reason: GateReason) {
        if (reason == GateReason.HOST_REQUIRES_PRO) _state.update { it.copy(showHostGate = true) } else app.present(reason)
    }

    fun create() {
        val current = _state.value
        val area = current.area ?: return
        if (!current.canCreate) return
        _state.update { it.copy(isCreating = true, error = null) }
        viewModelScope.launch {
            val decision = app.core.gates.canHostGroup()
            if (!decision.allowed) {
                _state.update { it.copy(isCreating = false) }
                handleGate(decision.reason)
                return@launch
            }
            app.core.groups.create(current.name.trim(), current.scheduledAtEpochSeconds, area, current.radiusKm, current.details.value() ?: return@launch).fold(
                onSuccess = { group ->
                    _state.update { it.copy(isCreating = false) }
                    app.replaceTop(AppRoute.GroupProposals(group.id))
                },
                onFailure = { failure ->
                    val error = failure.asCoreError()
                    _state.update { it.copy(isCreating = false, error = error) }
                    if (error is CoreError.Gate) handleGate(error.reason)
                },
            )
        }
    }

    companion object {
        const val DEFAULT_RADIUS_KM = 2.0
        val RADIUS_OPTIONS_KM = listOf(1.0, 2.0, 5.0)
        val DEFAULT_LUNCH_TIME: LocalTime = LocalTime.of(12, 30)

        /** Next weekday at 12:30 local time (today if lunch is still ahead). */
        fun defaultTime(app: AppEnvironment): Long {
            val zone = ZoneId.of(app.clock.timeZoneId())
            val now = Instant.ofEpochSecond(app.clock.nowEpochSeconds()).atZone(zone)
            var candidate = now.toLocalDate().atTime(DEFAULT_LUNCH_TIME).atZone(zone)
            if (!candidate.isAfter(now)) candidate = candidate.plusDays(1)
            while (candidate.dayOfWeek == DayOfWeek.SATURDAY || candidate.dayOfWeek == DayOfWeek.SUNDAY) candidate = candidate.plusDays(1)
            return candidate.toEpochSecond()
        }
    }
}
