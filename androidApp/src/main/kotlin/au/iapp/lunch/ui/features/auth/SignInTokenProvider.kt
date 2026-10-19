/**
 * @file SignInTokenProvider.kt
 * @description Obtains the identity token the shared `AuthRepository` exchanges for a session.
 * Production Google credentials come from Credential Manager. Preview tokens stay in previews.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.auth

import au.iapp.lunch.core.model.CoreError

enum class SignInProvider { Apple, Google }

data class SignInToken(val idToken: String, val nonce: String = "", val fullName: String? = null)

interface SignInTokenProvider {
    val supportedProviders: List<SignInProvider> get() = listOf(SignInProvider.Google)
    suspend fun token(provider: SignInProvider): Result<SignInToken>
}

/** Preview and test provider: every request produces a demo token. */
object PreviewSignInTokenProvider : SignInTokenProvider {
    const val TOKEN = "preview-id-token"
    override suspend fun token(provider: SignInProvider): Result<SignInToken> =
        Result.success(SignInToken(idToken = TOKEN, nonce = "preview-nonce", fullName = "Demo User"))
}

/** Real builds when no credentials are configured; the sheet shows `signin_unavailable`. */
object UnavailableSignInTokenProvider : SignInTokenProvider {
    const val CODE = "SIGN_IN_UNAVAILABLE"
    override suspend fun token(provider: SignInProvider): Result<SignInToken> =
        Result.failure(CoreError.Service(CODE, "Sign-in providers are not configured for Android yet"))
}
