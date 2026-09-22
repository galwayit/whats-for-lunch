/**
 * @file SignInTokenProvider.kt
 * @description Obtains the identity token the shared `AuthRepository` exchanges for a session.
 * The preview provider hands back a fixed token; the real provider is a product decision
 * (Credential Manager for Google, a web flow for Apple) and reports "unavailable" until then.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.auth

import au.iapp.lunch.core.model.CoreError

enum class SignInProvider { Apple, Google }

data class SignInToken(val idToken: String, val nonce: String = "", val fullName: String? = null)

interface SignInTokenProvider {
    suspend fun token(provider: SignInProvider): Result<SignInToken>
}

/** Preview and test provider: every request produces a demo token. */
object PreviewSignInTokenProvider : SignInTokenProvider {
    const val TOKEN = "preview-id-token"
    override suspend fun token(provider: SignInProvider): Result<SignInToken> =
        Result.success(SignInToken(idToken = TOKEN, nonce = "preview-nonce", fullName = "Demo User"))
}

/** Real builds until the provider decision lands; the sheet shows `signin_unavailable`. */
object UnavailableSignInTokenProvider : SignInTokenProvider {
    const val CODE = "SIGN_IN_UNAVAILABLE"
    override suspend fun token(provider: SignInProvider): Result<SignInToken> =
        Result.failure(CoreError.Service(CODE, "Sign-in providers are not configured for Android yet"))
}
