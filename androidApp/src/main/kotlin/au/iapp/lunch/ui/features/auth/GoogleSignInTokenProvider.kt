package au.iapp.lunch.ui.features.auth

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import au.iapp.lunch.core.model.CoreError
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import java.security.MessageDigest
import java.security.SecureRandom
import kotlinx.coroutines.CancellationException

/** Uses the Activity context only for the lifetime of the sign-in sheet. */
class GoogleSignInTokenProvider(private val context: Context, private val serverClientId: String?) : SignInTokenProvider {
    override val supportedProviders = listOf(SignInProvider.Google)

    override suspend fun token(provider: SignInProvider): Result<SignInToken> {
        if (provider != SignInProvider.Google || serverClientId.isNullOrBlank()) {
            return Result.failure(CoreError.Service(UnavailableSignInTokenProvider.CODE, "Google sign-in is unavailable. Try email."))
        }
        return try {
            val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
            val nonce = bytes.joinToString("") { "%02x".format(it) }
            val hash = MessageDigest.getInstance("SHA-256").digest(nonce.toByteArray()).joinToString("") { "%02x".format(it) }
            val option = GetSignInWithGoogleOption.Builder(serverClientId).setNonce(hash).build()
            val result = CredentialManager.create(context).getCredential(context, GetCredentialRequest(listOf(option)))
            val credential = result.credential
            if (credential !is CustomCredential || credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                throw CoreError.Service("GOOGLE_TOKEN_MISSING", "Google did not return a sign-in credential.")
            }
            Result.success(SignInToken(GoogleIdTokenCredential.createFrom(credential.data).idToken, nonce))
        } catch (cancelled: GetCredentialCancellationException) {
            throw CancellationException("Google sign-in cancelled", cancelled)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (failure: Exception) {
            Result.failure(failure)
        }
    }
}
