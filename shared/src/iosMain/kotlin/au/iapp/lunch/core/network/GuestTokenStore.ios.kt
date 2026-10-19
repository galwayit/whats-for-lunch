package au.iapp.lunch.core.network

import com.russhwolf.settings.ExperimentalSettingsImplementation
import com.russhwolf.settings.KeychainSettings

@OptIn(ExperimentalSettingsImplementation::class)
internal actual fun createGuestTokenStore(): GuestTokenStore = object : GuestTokenStore {
    private val settings = KeychainSettings("au.iapp.lunch.invitation-capabilities")
    override fun get(code: String): String? = settings.getStringOrNull(code)
    override fun put(code: String, token: String) { settings.putString(code, token) }
}
