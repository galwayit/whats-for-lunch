package au.iapp.lunch.core.service

import au.iapp.lunch.core.network.MemoryGuestTokenStore
import au.iapp.lunch.core.support.MockBackend
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PushRegistrarTest {
    @Test fun anonymous_token_survives_restart_and_registers_after_sign_in() = runTest {
        val backend = MockBackend().route("push-register", body = "{\"ok\":true}")
        val storage = MemoryGuestTokenStore()
        var signedIn = false
        PushRegistrarImpl(backend.client(), storage) { signedIn }.register("device-token", "ios").getOrThrow()
        assertTrue(backend.requests.isEmpty())
        signedIn = true
        val restarted = PushRegistrarImpl(backend.client(), storage) { signedIn }
        restarted.refresh().getOrThrow()
        assertTrue(backend.lastBody().contains("device-token"))
        restarted.signOut { signedIn = false }
        assertTrue(backend.lastBody().contains("unregister"))
        assertFalse(signedIn)
        restarted.register("device-token", "ios").getOrThrow()
        assertEquals(2, backend.requests.size, "a late token callback cannot re-register a signed-out account")
    }

    @Test fun failed_unregister_preserves_the_session_for_retry() = runTest {
        val backend = MockBackend().route("push-register", body = "{\"ok\":true}")
        var signedIn = true
        val registrar = PushRegistrarImpl(backend.client(), MemoryGuestTokenStore()) { signedIn }
        registrar.register("device-token", "ios").getOrThrow()
        backend.goOffline()
        assertTrue(runCatching { registrar.signOut { signedIn = false } }.isFailure)
        assertTrue(signedIn)
    }
}
