package au.iapp.lunch.core.support

import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Location
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Auth stand-in: tests set [sessions] directly; sign-in calls are not exercised here. */
class FakeAuthRepository(initial: AuthSession? = null) : AuthRepository {
    val sessions = MutableStateFlow(initial)
    override val session: StateFlow<AuthSession?> = sessions.asStateFlow()

    override suspend fun signInWithApple(idToken: String, nonce: String, fullName: String?): Result<AuthSession> = signIn()
    override suspend fun signInWithGoogle(idToken: String): Result<AuthSession> = signIn()
    override suspend fun signOut(): Result<Unit> { sessions.value = null; return Result.success(Unit) }
    override suspend fun deleteAccount(): Result<Unit> =
        if (sessions.value == null) Result.failure(CoreError.NotSignedIn) else signOut()

    private fun signIn(): Result<AuthSession> {
        val session = AuthSession(userId = "user-1", email = "sam@example.test", displayName = "Sam")
        sessions.value = session
        return Result.success(session)
    }
}

class FakeLocationProvider(private val location: Location?) : LocationProvider {
    override suspend fun current(): Result<Location> =
        location?.let { Result.success(it) } ?: Result.failure(CoreError.Service("NO_LOCATION", "Location unavailable"))
    override suspend fun hasPermission(): Boolean = location != null
}
