package au.iapp.lunch.core.service

import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.network.MemoryGuestTokenStore
import au.iapp.lunch.core.support.MockBackend
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.minimalSettings
import io.github.jan.supabase.createSupabaseClient
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.*

/** Exercises the actual pinned Supabase SDK over HTTP fixtures, never a live account. */
class AuthRepositoryTest {
    private fun TestScope.fixture(provider: String = "email"): Fixture = Fixture(this, provider)

    @Test fun confirmation_required_signup_cannot_bind_a_paid_identity() = runTest {
        val f = fixture()
        f.backend.route("signup", body = f.user)
        assertFalse(f.auth.registerWithEmail(" sam@example.test ", " password8 ").getOrThrow())
        assertNull(f.client.auth.currentSessionOrNull())
        assertTrue(f.entitlements.appUserId.value.startsWith("\$RCAnonymousID:"))
        assertTrue(f.backend.lastBody().contains("sam@example.test"))
        assertTrue(f.backend.lastBody().contains(" password8 "), "Passwords must not be trimmed")
        f.client.close()
    }

    @Test fun verification_binds_the_verified_user_and_refreshes_push() = runTest {
        val f = fixture()
        f.backend.route("verify", body = f.session)
        f.push.register("fictional-device-token", "ios").getOrThrow()
        assertTrue(f.backend.requests.isEmpty())
        val session = f.auth.verifyEmail("sam@example.test", "12345678").getOrThrow()
        assertEquals("user-1", session.userId)
        assertFalse(session.requiresAppleReauthentication)
        assertEquals("user-1", f.entitlements.appUserId.value)
        assertTrue(f.backend.requests.any { it.url.encodedPath.endsWith("/push-register") })
        f.client.close()
    }

    @Test fun password_login_uses_password_grant_and_binds_purchases() = runTest {
        val f = fixture()
        f.backend.route("token", body = f.session)
        f.auth.signInWithEmail(" sam@example.test ", " password8 ").getOrThrow()
        assertEquals("password", f.backend.requests.single().url.parameters["grant_type"])
        assertEquals("user-1", f.entitlements.appUserId.value)
        assertTrue(f.backend.lastBody().contains(" password8 "))
        f.client.close()
    }

    @Test fun google_exchange_keeps_nonce_and_access_token_for_server_validation() = runTest {
        val f = fixture("google")
        f.backend.route("token", body = f.session)
        val session = f.auth.signInWithGoogle("fictional-id-token", "raw-nonce", "fictional-access-token").getOrThrow()
        val body = f.backend.lastBody()
        assertTrue(body.contains("\"nonce\":\"raw-nonce\""))
        assertTrue(body.contains("\"access_token\":\"fictional-access-token\""))
        assertTrue(body.contains("\"provider\":\"google\""))
        assertFalse(session.requiresAppleReauthentication)
        assertEquals("user-1", f.entitlements.appUserId.value)
        f.client.close()
    }

    @Test fun linked_apple_identity_requires_reauthentication_for_deletion() = runTest {
        val f = fixture("apple")
        f.backend.route("token", body = f.session)
        assertTrue(f.auth.signInWithApple("fictional", "nonce", null).getOrThrow().requiresAppleReauthentication)
        f.client.close()
    }

    @Test fun bad_credentials_never_create_a_session_or_link_purchases() = runTest {
        val f = fixture()
        f.backend.route("token", HttpStatusCode.BadRequest, """{"error_code":"invalid_credentials","msg":"Invalid login credentials"}""")
        val error = f.auth.signInWithEmail("sam@example.test", "bad-password").exceptionOrNull()
        assertIs<CoreError.Service>(error)
        assertEquals("invalid_credentials", error.code)
        assertNull(f.client.auth.currentSessionOrNull())
        assertTrue(f.entitlements.appUserId.value.startsWith("\$RCAnonymousID:"))
        f.client.close()
    }

    @Test fun recovery_verifies_code_before_updating_password() = runTest {
        val f = fixture()
        f.backend.route("verify", body = f.session).route("user", body = f.user)
        f.auth.resetPassword("sam@example.test", "12345678", "new-password8").getOrThrow()
        assertEquals(listOf("verify", "user"), f.backend.requests.map { it.url.encodedPath.substringAfterLast('/') })
        assertTrue((f.backend.requests.first().body as io.ktor.http.content.TextContent).text.contains("\"type\":\"recovery\""))
        assertTrue(f.backend.lastBody().contains("new-password8"))
        assertEquals("user-1", f.entitlements.appUserId.value)
        f.client.close()
    }

    @Test fun failed_password_update_clears_recovery_session_and_requires_new_code() = runTest {
        val f = fixture()
        f.backend.route("verify", body = f.session).route("user", HttpStatusCode.InternalServerError, """{"error_code":"unexpected_failure","msg":"Try later"}""")
        val error = f.auth.resetPassword("sam@example.test", "12345678", "new-password8").exceptionOrNull()
        assertIs<CoreError.Service>(error)
        assertEquals("PASSWORD_RESET_RETRY", error.code)
        assertNull(f.client.auth.currentSessionOrNull())
        assertTrue(f.entitlements.appUserId.value.startsWith("\$RCAnonymousID:"))
        f.client.close()
    }

    @Test fun resend_and_recovery_requests_do_not_authenticate() = runTest {
        val f = fixture()
        f.backend.route("resend", body = "{}").route("recover", body = "{}")
        f.auth.resendVerification("sam@example.test").getOrThrow()
        assertTrue(f.backend.lastBody().contains("\"type\":\"signup\""))
        f.auth.requestPasswordReset("sam@example.test").getOrThrow()
        assertNull(f.client.auth.currentSessionOrNull())
        f.client.close()
    }

    private class Fixture(scope: TestScope, provider: String) {
        val user = """{"id":"user-1","aud":"authenticated","email":"sam@example.test","identities":[{"id":"identity-1","user_id":"user-1","provider":"$provider","identity_data":{}}]}"""
        val session = """{"access_token":"fixture-access","refresh_token":"fixture-refresh","expires_in":3600,"token_type":"bearer","user":$user}"""
        val backend = MockBackend().route("push-register", body = "{\"ok\":true}")
        val client = createSupabaseClient("https://example.test", "fixture-anon") {
            httpEngine = backend.engine
            install(Auth) { minimalSettings() }
        }
        val entitlements = FakeEntitlementRepository()
        val push = PushRegistrarImpl(backend.client(), MemoryGuestTokenStore()) { client.auth.currentSessionOrNull() != null }
        val auth = AuthRepositoryImpl(client, backend.client(), entitlements, scope.backgroundScope, push)
    }
}
