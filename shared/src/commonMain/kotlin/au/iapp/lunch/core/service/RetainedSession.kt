package au.iapp.lunch.core.service

import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.user.UserSession
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.runningFold

/**
 * The signed-in session, kept while a token refresh is failing.
 *
 * The SDK reports no session while it retries a refresh that failed because the phone is
 * offline or the auth server returned an error. Treating that as a sign-out showed a subscriber
 * sign-in prompts and Free limits after an hour offline. This keeps the last known session, or
 * the stored one after a relaunch. The SDK itself moves to NotAuthenticated when the refresh
 * token is really revoked, and that still ends the session here.
 */
internal fun Auth.retainedSessions(): Flow<UserSession?> =
    sessionStatus.runningFold(currentSessionOrNull()) { last, status ->
        when (status) {
            is SessionStatus.Authenticated -> status.session
            is SessionStatus.RefreshFailure -> last ?: sessionManager.loadSession()
            is SessionStatus.Initializing -> last
            is SessionStatus.NotAuthenticated -> null
        }
    }
