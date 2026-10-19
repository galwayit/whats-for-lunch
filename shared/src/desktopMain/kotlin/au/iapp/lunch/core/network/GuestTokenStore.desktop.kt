package au.iapp.lunch.core.network
// Desktop is the test harness; no production guest credentials are stored here.
internal actual fun createGuestTokenStore(): GuestTokenStore = MemoryGuestTokenStore()
