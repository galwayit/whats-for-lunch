package au.iapp.lunch.core.data

import au.iapp.lunch.core.model.CoreError
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext

/** Dispatcher for SQLite work; every SQLDelight call in the repositories runs here. */
internal val DbDispatcher = Dispatchers.IO

/**
 * Runs [block] and folds the outcome into a [Result] whose failure is always a
 * [CoreError]: errors the core raised pass through, anything else becomes
 * [CoreError.Unknown]. Cancellation is never swallowed.
 */
internal inline fun <T> coreResult(block: () -> T): Result<T> = try {
    Result.success(block())
} catch (e: CoreError) {
    Result.failure(e)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Result.failure(CoreError.Unknown(e))
}

/** [coreResult] on the database dispatcher. */
internal suspend inline fun <T> dbResult(crossinline block: () -> T): Result<T> =
    withContext(DbDispatcher) { coreResult { block() } }

/** Non-Result database read on the database dispatcher. */
internal suspend inline fun <T> dbRead(crossinline block: () -> T): T = withContext(DbDispatcher) { block() }

/** The [CoreError] carried by a failed [Result], if any. */
internal val <T> Result<T>.coreError: CoreError? get() = exceptionOrNull() as? CoreError
