package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.PushRegistrar
import au.iapp.lunch.core.data.coreResult
import au.iapp.lunch.core.network.BackendClient
import au.iapp.lunch.core.network.GuestTokenStore
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** The token survives launch and is rebound on sign-in. Registration and sign-out
 * share a lock so a late FCM callback cannot reattach a signed-out account.
 */
internal class PushRegistrarImpl(
    private val backend: BackendClient,
    private val storage: GuestTokenStore,
    private val signedIn: () -> Boolean,
) : PushRegistrar {
    private val lock = Mutex()
    override suspend fun register(token: String, platform: String): Result<Unit> = coreResult {
        lock.withLock {
            val old = storage.get(TOKEN)
            val oldPlatform = storage.get(PLATFORM)
            if (signedIn() && old != null && old != token && oldPlatform != null) {
                backend.pushUnregister(old, oldPlatform)
            }
            storage.put(TOKEN, token)
            storage.put(PLATFORM, platform)
            if (signedIn()) backend.pushRegister(token, platform)
        }
    }

    suspend fun refresh(): Result<Unit> = coreResult {
        lock.withLock {
            val token = storage.get(TOKEN)
            val platform = storage.get(PLATFORM)
            if (signedIn() && token != null && platform != null) backend.pushRegister(token, platform)
        }
    }

    suspend fun signOut(clearSession: suspend () -> Unit) = lock.withLock {
        val token = storage.get(TOKEN)
        val platform = storage.get(PLATFORM)
        if (signedIn() && token != null && platform != null) backend.pushUnregister(token, platform)
        clearSession()
    }

    private companion object {
        const val TOKEN = "push-token"
        const val PLATFORM = "push-platform"
    }
}
