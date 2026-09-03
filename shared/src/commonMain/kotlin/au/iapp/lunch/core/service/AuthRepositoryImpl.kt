package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.network.BackendClient
import co.touchlab.kermit.Logger
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.SignOutScope
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Apple
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.user.UserSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.serialization.json.jsonPrimitive

/**
 * Supabase Auth via native ID tokens (Sign in with Apple, Google Sign-In).
 * After a successful sign-in the RevenueCat identity is aliased to the
 * Supabase user id so purchases follow the account.
 */
internal class AuthRepositoryImpl(
    private val supabase: SupabaseClient,
    private val backend: BackendClient,
    private val entitlements: EntitlementRepository,
    scope: CoroutineScope,
) : AuthRepository {

    private val log = Logger.withTag("Auth")

    override val session: StateFlow<AuthSession?> = supabase.auth.sessionStatus
        .map { status -> (status as? SessionStatus.Authenticated)?.session?.toAuthSession() }
        .stateIn(scope, SharingStarted.Eagerly, supabase.auth.currentSessionOrNull()?.toAuthSession())

    override suspend fun signInWithApple(idToken: String, nonce: String, fullName: String?): Result<AuthSession> =
        signIn {
            supabase.auth.signInWith(IDToken) {
                this.idToken = idToken
                this.provider = Apple
                this.nonce = nonce
            }
        }.map { session -> if (session.displayName == null && !fullName.isNullOrBlank()) session.copy(displayName = fullName) else session }

    override suspend fun signInWithGoogle(idToken: String): Result<AuthSession> = signIn {
        supabase.auth.signInWith(IDToken) {
            this.idToken = idToken
            this.provider = Google
        }
    }

    override suspend fun signOut(): Result<Unit> = SupabaseErrors.result {
        supabase.auth.signOut(SignOutScope.LOCAL)
        entitlements.logOut().onFailure { log.w(it) { "RevenueCat logOut failed" } }
    }

    /** Calls the account-delete function with the user's JWT, then clears the local session. */
    override suspend fun deleteAccount(): Result<Unit> {
        if (supabase.auth.currentSessionOrNull() == null) return Result.failure(CoreError.NotSignedIn)
        return SupabaseErrors.result {
            backend.accountDelete()
            supabase.auth.signOut(SignOutScope.LOCAL)
            entitlements.logOut().onFailure { log.w(it) { "RevenueCat logOut failed" } }
        }
    }

    private suspend inline fun signIn(crossinline call: suspend () -> Unit): Result<AuthSession> = SupabaseErrors.result {
        call()
        val session = supabase.auth.currentSessionOrNull()?.toAuthSession()
            ?: throw CoreError.Service(NO_SESSION, "Sign-in completed without a session")
        entitlements.logIn(session.userId).onFailure { log.w(it) { "RevenueCat logIn failed" } }
        session
    }

    private fun UserSession.toAuthSession(): AuthSession? {
        val user = user ?: return null
        val metadata = user.userMetadata
        val name = listOf("full_name", "name").firstNotNullOfOrNull { key ->
            metadata?.get(key)?.jsonPrimitive?.content?.takeIf { it.isNotBlank() }
        }
        return AuthSession(userId = user.id, email = user.email, displayName = name)
    }

    companion object {
        const val NO_SESSION = "NO_SESSION"
    }
}
