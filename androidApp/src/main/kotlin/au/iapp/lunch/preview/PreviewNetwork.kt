/**
 * @file PreviewNetwork.kt
 * @description Simulated network for the preview core: a fixed latency per call and
 * [CoreError.Offline] when the preview was launched offline. Mirrors
 * iosApp/LunchApp/Core/Preview/PreviewServices.swift (`PreviewNetwork`).
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.preview

import au.iapp.lunch.core.model.CoreError
import kotlinx.coroutines.delay
import kotlin.coroutines.cancellation.CancellationException

class PreviewNetwork(
    private val isOffline: () -> Boolean,
    private val latencyMs: Long = DEFAULT_LATENCY_MS,
) {
    /** Waits for the simulated round trip and throws [CoreError.Offline] when offline. */
    suspend fun roundTrip(latencyMs: Long = this.latencyMs) {
        if (latencyMs > 0) delay(latencyMs)
        if (isOffline()) throw CoreError.Offline
    }

    /** [roundTrip] followed by [block], wrapped as the `Result` the core contracts return. */
    suspend fun <T> call(latencyMs: Long = this.latencyMs, block: suspend () -> T): Result<T> =
        coreResult {
            roundTrip(latencyMs)
            block()
        }

    companion object {
        const val DEFAULT_LATENCY_MS = 600L
        const val AI_LATENCY_MS = 1_200L
        const val PURCHASE_LATENCY_MS = 1_000L
    }
}

/**
 * `runCatching` that lets coroutine cancellation propagate and normalises other failures to
 * [CoreError], the only failure type the screens map to an empty state.
 */
suspend inline fun <T> coreResult(block: () -> T): Result<T> = try {
    Result.success(block())
} catch (cancelled: CancellationException) {
    throw cancelled
} catch (error: CoreError) {
    Result.failure(error)
} catch (error: Exception) {
    Result.failure(CoreError.Unknown(error))
}
