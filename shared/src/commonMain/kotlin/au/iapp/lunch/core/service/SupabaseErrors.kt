package au.iapp.lunch.core.service

import au.iapp.lunch.core.model.CoreError
import io.github.jan.supabase.exceptions.HttpRequestException
import io.github.jan.supabase.exceptions.RestException
import kotlinx.coroutines.CancellationException

/** Maps supabase-kt failures onto [CoreError]. */
internal object SupabaseErrors {
    fun toCoreError(e: Throwable): CoreError = when (e) {
        is CoreError -> e
        is RestException -> CoreError.Service(e.error, e.description ?: e.error)
        is HttpRequestException -> CoreError.Offline
        else -> CoreError.Unknown(e)
    }

    /** Like `coreResult` but with the supabase mapping applied first. */
    suspend inline fun <T> result(block: () -> T): Result<T> = try {
        Result.success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Result.failure(toCoreError(e))
    }
}
