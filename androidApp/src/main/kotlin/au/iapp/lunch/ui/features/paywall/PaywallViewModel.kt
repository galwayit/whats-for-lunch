/**
 * @file PaywallViewModel.kt
 * @description Loads both Lunch Pro packages from the entitlement repository, purchases the
 * selected one and restores. Mirrors iosApp/.../Paywall/PaywallViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.paywall

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.R
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.ProPackage
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class PaywallUiState(
    /** Yearly first so the trial offer leads. */
    val packages: LoadState<List<ProPackage>> = LoadState.Idle,
    val selectedIdentifier: String = "",
    val isPurchasing: Boolean = false,
    val isRestoring: Boolean = false,
    val purchaseError: CoreError? = null,
    val isPro: Boolean = false,
    /** True after a restore that found nothing, so the screen can toast. */
    val restoredNothing: Boolean = false,
) {
    val selected: ProPackage? get() = packages.valueOrNull?.firstOrNull { it.identifier == selectedIdentifier }
}

class PaywallViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(PaywallUiState(isPro = app.isPro.value))
    val state: StateFlow<PaywallUiState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        _state.update { it.copy(packages = LoadState.Loading) }
        viewModelScope.launch {
            app.core.entitlements.offerings().fold(
                onSuccess = { offerings ->
                    val packages = listOfNotNull(offerings.yearly, offerings.monthly)
                    _state.update {
                        it.copy(packages = LoadState.Loaded(packages), selectedIdentifier = it.selectedIdentifier.ifEmpty { packages.firstOrNull()?.identifier.orEmpty() })
                    }
                },
                onFailure = { failure -> _state.update { it.copy(packages = LoadState.Failed(failure.asCoreError())) } },
            )
        }
    }

    fun select(pkg: ProPackage) = _state.update { it.copy(selectedIdentifier = pkg.identifier, purchaseError = null) }

    fun purchase() {
        val selected = _state.value.selected ?: return
        if (_state.value.isPurchasing || _state.value.isRestoring) return
        _state.update { it.copy(isPurchasing = true, purchaseError = null) }
        viewModelScope.launch {
            app.core.entitlements.purchase(selected.identifier).fold(
                onSuccess = { status -> _state.update {
                    it.copy(isPurchasing = false, isPro = status.isPro,
                        purchaseError = if (status.isPro) null else CoreError.Service("PURCHASE_NOT_ACTIVATED", "Lunch Pro was not activated"))
                } },
                onFailure = { failure -> _state.update { it.copy(isPurchasing = false, purchaseError = visiblePurchaseError(failure)) } },
            )
        }
    }

    fun restore() {
        if (_state.value.isRestoring || _state.value.isPurchasing) return
        _state.update { it.copy(isRestoring = true, purchaseError = null, restoredNothing = false) }
        viewModelScope.launch {
            app.core.entitlements.restore().fold(
                onSuccess = { status -> _state.update { it.copy(isRestoring = false, isPro = status.isPro, restoredNothing = !status.isPro) } },
                onFailure = { failure -> _state.update { it.copy(isRestoring = false, purchaseError = visiblePurchaseError(failure)) } },
            )
        }
    }

    fun consumeRestoredNothing() = _state.update { it.copy(restoredNothing = false) }
}

internal fun visiblePurchaseError(failure: Throwable): CoreError? = failure.asCoreError().let {
    if (it is CoreError.Service && it.code == "PURCHASE_CANCELLED") null else it
}

/** Store SDK diagnostics are not user-facing copy and can include implementation details. */
internal fun purchaseErrorMessage(error: CoreError): Int = when (error) {
    CoreError.Offline -> R.string.paywall_error_offline
    CoreError.NotSignedIn -> R.string.paywall_error_sign_in
    is CoreError.Gate -> if (error.reason == au.iapp.lunch.core.model.GateReason.SIGN_IN_REQUIRED)
        R.string.paywall_error_sign_in else R.string.paywall_error_purchase
    is CoreError.Service -> when (error.code) {
        "PURCHASE_NOT_ACTIVATED" -> R.string.paywall_error_activation
        "PaymentPendingError" -> R.string.paywall_error_pending
        "PurchaseNotAllowedError" -> R.string.paywall_error_not_allowed
        "ProductNotAvailableForPurchaseError", "PACKAGE_NOT_FOUND" -> R.string.paywall_error_unavailable
        else -> R.string.paywall_error_purchase
    }
    else -> R.string.paywall_error_purchase
}
