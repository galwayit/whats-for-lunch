package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.PushRegistrar
import au.iapp.lunch.core.data.coreResult
import au.iapp.lunch.core.network.BackendClient

/** Registers the device token with POST /push-register. */
internal class PushRegistrarImpl(private val backend: BackendClient) : PushRegistrar {
    override suspend fun register(token: String, platform: String): Result<Unit> =
        coreResult { backend.pushRegister(token, platform) }
}
