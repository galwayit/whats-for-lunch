package au.iapp.lunch.auth

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.auth.SignInSheet
import au.iapp.lunch.ui.theme.LunchTheme
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import java.util.concurrent.atomic.AtomicBoolean

/** UI navigation against the in-memory core; never creates a real user or sends email. */
class AuthScreenTest {
    @get:Rule val compose = createComposeRule()

    @Test fun registration_form_reaches_verification_then_dismisses_after_code() {
        val app = AppEnvironment.preview(PreviewCoreOptions(isSignedIn = false, latencyMs = 0))
        val dismissed = AtomicBoolean(false)
        compose.setContent {
            CompositionLocalProvider(LocalAppEnvironment provides app) {
                LunchTheme { SignInSheet(onDismiss = { dismissed.set(true) }) }
            }
        }
        compose.onNodeWithTag("sign_in_google").assertExists()
        compose.onNodeWithText("Create account").performScrollTo().performClick()
        compose.onNodeWithTag("auth_email").performTextInput("fictional@example.test")
        compose.onNodeWithTag("auth_password").performTextInput("fictional-password8")
        compose.onNodeWithTag("auth_confirm_password").performTextInput("fictional-password8")
        compose.onNodeWithTag("auth_submit").performScrollTo().performClick()
        compose.onNodeWithText("Verify your email").assertIsDisplayed()
        assertNull(app.core.auth.session.value)
        compose.onNodeWithTag("auth_code").performTextInput("12345678")
        compose.onNodeWithTag("auth_submit").performScrollTo().performClick()
        compose.waitUntil(5_000) { dismissed.get() }
    }

    @Test fun password_reset_is_reachable_and_rejects_a_missing_code() {
        val app = AppEnvironment.preview(PreviewCoreOptions(isSignedIn = false, latencyMs = 0))
        compose.setContent {
            CompositionLocalProvider(LocalAppEnvironment provides app) {
                LunchTheme { SignInSheet(onDismiss = {}) }
            }
        }
        compose.onNodeWithText("Forgot password?").performScrollTo().performClick()
        compose.onNodeWithTag("auth_email").performTextInput("fictional@example.test")
        compose.onNodeWithTag("auth_submit").performScrollTo().performClick()
        compose.onNodeWithText("Choose a new password").assertIsDisplayed()
        compose.onNodeWithTag("auth_password").performTextInput("new-fictional-password8")
        compose.onNodeWithTag("auth_confirm_password").performTextInput("new-fictional-password8")
        compose.onNodeWithTag("auth_submit").performScrollTo().performClick()
        compose.onNodeWithTag("auth_error").assertTextEquals("Enter the verification code from your email.")
        assertNull(app.core.auth.session.value)
    }
}
