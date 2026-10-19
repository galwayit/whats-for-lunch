package au.iapp.lunch.ui.features.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.ui.features.shared.asCoreError
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class EmailAuthStep { SignIn, Register, Verify, ForgotPassword, ResetPassword }

data class SignInUiState(
    val busyProvider: SignInProvider? = null,
    val emailBusy: Boolean = false,
    val error: CoreError? = null,
    val isSignedIn: Boolean = false,
    val emailStep: EmailAuthStep = EmailAuthStep.SignIn,
    val email: String = "",
    val notice: String? = null,
) {
    val isBusy: Boolean get() = busyProvider != null || emailBusy
    val needsPassword: Boolean get() = emailStep in listOf(EmailAuthStep.SignIn, EmailAuthStep.Register, EmailAuthStep.ResetPassword)
    val needsNewPassword: Boolean get() = emailStep in listOf(EmailAuthStep.Register, EmailAuthStep.ResetPassword)
    val needsCode: Boolean get() = emailStep in listOf(EmailAuthStep.Verify, EmailAuthStep.ResetPassword)
}

class SignInViewModel(private val app: AppEnvironment) : ViewModel() {
    private val _state = MutableStateFlow(SignInUiState())
    val state: StateFlow<SignInUiState> = _state.asStateFlow()

    fun signIn(provider: SignInProvider, tokens: SignInTokenProvider = app.signInTokens) {
        if (_state.value.isBusy) return
        _state.update { it.copy(busyProvider = provider, error = null, notice = null) }
        viewModelScope.launch {
            try {
                val token = tokens.token(provider).getOrThrow()
                when (provider) {
                    SignInProvider.Apple -> app.core.auth.signInWithApple(token.idToken, token.nonce, token.fullName)
                    SignInProvider.Google -> app.core.auth.signInWithGoogle(token.idToken, token.nonce, null)
                }.getOrThrow()
                // The shared auth repository binds purchases and push exactly once.
                _state.update { it.copy(isSignedIn = true) }
            } catch (cancelled: CancellationException) {
                // Dismissing the account chooser is not an authentication error.
            } catch (failure: Exception) {
                _state.update { it.copy(error = failure.asCoreError()) }
            } finally { _state.update { it.copy(busyProvider = null) } }
        }
    }

    fun setEmail(email: String) {
        if (!_state.value.isBusy && !_state.value.needsCode) _state.update { it.copy(email = email) }
    }

    fun changeEmailStep(step: EmailAuthStep) {
        if (!_state.value.isBusy) _state.update { it.copy(emailStep = step, error = null, notice = null) }
    }

    fun submitEmail(password: String, confirmation: String, code: String) {
        val current = _state.value
        if (current.isBusy) return
        val email = current.email.trim()
        val validation = when {
            email.count { it == '@' } != 1 || email.startsWith('@') || email.endsWith('@') || email.any { it.isWhitespace() } -> "Enter a valid email address."
            current.needsPassword && password.isEmpty() -> "Enter your password."
            current.needsNewPassword && (password.length < 8 || password != confirmation) -> "Use at least 8 characters and make sure both passwords match."
            current.needsCode && (code.length !in 6..10 || !code.all { it in '0'..'9' }) -> "Enter the verification code from your email."
            else -> null
        }
        if (validation != null) {
            _state.update { it.copy(error = CoreError.Service("AUTH_VALIDATION", validation)) }
            return
        }
        _state.update { it.copy(emailBusy = true, email = email, error = null, notice = null) }
        viewModelScope.launch {
            try {
                val signedIn = when (current.emailStep) {
                    EmailAuthStep.SignIn -> { app.core.auth.signInWithEmail(email, password).getOrThrow(); true }
                    EmailAuthStep.Register -> {
                        val complete = app.core.auth.registerWithEmail(email, password).getOrThrow()
                        if (!complete) _state.update { it.copy(emailStep = EmailAuthStep.Verify,
                            notice = "Check your email for a verification code. If you already have an account, sign in or reset your password.") }
                        complete
                    }
                    EmailAuthStep.Verify -> { app.core.auth.verifyEmail(email, code).getOrThrow(); true }
                    EmailAuthStep.ForgotPassword -> {
                        app.core.auth.requestPasswordReset(email).getOrThrow()
                        _state.update { it.copy(emailStep = EmailAuthStep.ResetPassword,
                            notice = "If an account exists for this email, a reset code is on its way.") }
                        false
                    }
                    EmailAuthStep.ResetPassword -> { app.core.auth.resetPassword(email, code, password).getOrThrow(); true }
                }
                _state.update { it.copy(isSignedIn = signedIn) }
            } catch (cancelled: CancellationException) {
            } catch (failure: Exception) {
                val error = failure.asCoreError()
                _state.update { it.copy(error = error, emailStep = if (error is CoreError.Service && error.code == "email_not_confirmed") EmailAuthStep.Verify else it.emailStep) }
            } finally { _state.update { it.copy(emailBusy = false) } }
        }
    }

    fun resendCode() {
        val current = _state.value
        if (current.isBusy || !current.needsCode) return
        _state.update { it.copy(emailBusy = true, error = null) }
        viewModelScope.launch {
            try {
                if (current.emailStep == EmailAuthStep.ResetPassword) app.core.auth.requestPasswordReset(current.email).getOrThrow()
                else app.core.auth.resendVerification(current.email).getOrThrow()
                _state.update { it.copy(notice = "If eligible, a new code has been sent. Check your inbox and spam folder.") }
            } catch (cancelled: CancellationException) {
            } catch (failure: Exception) {
                _state.update { it.copy(error = failure.asCoreError()) }
            } finally { _state.update { it.copy(emailBusy = false) } }
        }
    }
}

fun authErrorMessage(error: CoreError): String = when {
    error == CoreError.Offline -> "You're offline. Check your connection and try again."
    error is CoreError.Service -> when (error.code) {
        "AUTH_VALIDATION", "PASSWORD_RESET_RETRY" -> error.message.orEmpty()
        "invalid_credentials" -> "The email or password is incorrect. Try again or reset your password."
        "email_not_confirmed" -> "Verify your email first. You can request another code below."
        "otp_expired" -> "That code is invalid or expired. Request a new code and try again."
        "over_email_send_rate_limit", "over_request_rate_limit" -> "Please wait a minute before requesting another code."
        "weak_password" -> "Choose a stronger password with at least 8 characters."
        UnavailableSignInTokenProvider.CODE -> "Google sign-in is unavailable right now. Try email."
        else -> "Sign-in could not finish. Please try again."
    }
    else -> "Sign-in could not finish. Please try again."
}
