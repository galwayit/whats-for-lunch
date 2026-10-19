package au.iapp.lunch.core.network

/** A guest capability is scoped to one invitation; never include it in logs or other requests. */
internal interface GuestTokenStore {
    fun get(code: String): String?
    fun put(code: String, token: String)
}
internal class MemoryGuestTokenStore : GuestTokenStore {
    private val values = mutableMapOf<String, String>()
    override fun get(code: String) = values[code]
    override fun put(code: String, token: String) { values[code] = token }
}
internal expect fun createGuestTokenStore(): GuestTokenStore
