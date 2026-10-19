package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.auth.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SignInViewModelTest {
    @get:Rule val main = MainDispatcherRule()
    private fun environment() = AppEnvironment.preview(PreviewCoreOptions(isSignedIn = false, latencyMs = 0))

    @Test fun registration_waits_for_verification_before_signing_in() = runTest(main.dispatcher) {
        val app = environment()
        val model = SignInViewModel(app)
        model.setEmail("sam@example.test")
        model.changeEmailStep(EmailAuthStep.Register)
        model.submitEmail("password8", "password8", "")
        advanceUntilIdle()
        assertEquals(EmailAuthStep.Verify, model.state.value.emailStep)
        assertNull(app.core.auth.session.value)
        assertFalse(model.state.value.isSignedIn)
        model.submitEmail("", "", "12345678")
        advanceUntilIdle()
        assertTrue(model.state.value.isSignedIn)
    }

    @Test fun short_or_mismatched_password_never_starts_registration() = runTest(main.dispatcher) {
        val app = environment()
        val model = SignInViewModel(app)
        model.setEmail("sam@example.test")
        model.changeEmailStep(EmailAuthStep.Register)
        model.submitEmail("short", "short", "")
        advanceUntilIdle()
        assertNotNull(model.state.value.error)
        assertNull(app.core.auth.session.value)
        model.submitEmail("password8", "different", "")
        advanceUntilIdle()
        assertEquals(EmailAuthStep.Register, model.state.value.emailStep)
        assertNull(app.core.auth.session.value)
    }

    @Test fun recovery_request_keeps_user_signed_out_until_code_and_password_submitted() = runTest(main.dispatcher) {
        val app = environment()
        val model = SignInViewModel(app)
        model.setEmail("sam@example.test")
        model.changeEmailStep(EmailAuthStep.ForgotPassword)
        model.submitEmail("", "", "")
        advanceUntilIdle()
        assertEquals(EmailAuthStep.ResetPassword, model.state.value.emailStep)
        assertNull(app.core.auth.session.value)
        model.submitEmail("password8", "password8", "12345678")
        advanceUntilIdle()
        assertTrue(model.state.value.isSignedIn)
    }

    @Test fun cancelling_google_does_not_report_an_error_or_leave_spinner_running() = runTest(main.dispatcher) {
        val model = SignInViewModel(environment())
        val cancelled = object : SignInTokenProvider {
            override suspend fun token(provider: SignInProvider): Result<SignInToken> = throw CancellationException()
        }
        model.signIn(SignInProvider.Google, cancelled)
        advanceUntilIdle()
        assertFalse(model.state.value.isBusy)
        assertNull(model.state.value.error)
        assertFalse(model.state.value.isSignedIn)
    }

    @Test fun verification_rejects_bad_codes_without_signing_in() = runTest(main.dispatcher) {
        val app = environment()
        val model = SignInViewModel(app)
        model.setEmail("sam@example.test")
        model.changeEmailStep(EmailAuthStep.Verify)
        model.submitEmail("", "", "abcdef")
        advanceUntilIdle()
        assertNull(app.core.auth.session.value)
        assertNotNull(model.state.value.error)
    }
}
