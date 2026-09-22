/**
 * @file SignInViewModel.kt
 * @description Apple and Google sign-in through the token provider and the shared auth
 * repository, then links the entitlement identity. Mirrors iosApp/.../Auth/SignInViewModel.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SignInUiState(
    val busyProvider: SignInProvider? = null,
    val error: CoreError? = null,
    val isSignedIn: Boolean = false,
) {
    val isBusy: Boolean get() = busyProvider != null
}

class SignInViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(SignInUiState())
    val state: StateFlow<SignInUiState> = _state.asStateFlow()

    fun signIn(provider: SignInProvider) {
        if (_state.value.isBusy) return
        _state.update { it.copy(busyProvider = provider, error = null) }
        viewModelScope.launch {
            val result = app.signInTokens.token(provider).mapCatching { token ->
                when (provider) {
                    SignInProvider.Apple -> app.core.auth.signInWithApple(token.idToken, token.nonce, token.fullName)
                    SignInProvider.Google -> app.core.auth.signInWithGoogle(token.idToken)
                }.getOrThrow()
            }
            result.fold(
                onSuccess = { session ->
                    app.core.entitlements.logIn(session.userId)
                    _state.update { it.copy(busyProvider = null, isSignedIn = true) }
                },
                onFailure = { failure -> _state.update { it.copy(busyProvider = null, error = failure.asCoreError()) } },
            )
        }
    }
}
