/**
 * @file LoadState.kt
 * @description The four states of anything a screen fetches, so every screen renders loading,
 * loaded, offline and service-problem the same way. Mirrors iosApp/.../Shared/LoadState.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import au.iapp.lunch.core.model.CoreError

sealed class LoadState<out T> {
    data object Idle : LoadState<Nothing>()
    data object Loading : LoadState<Nothing>()
    data class Loaded<T>(val value: T) : LoadState<T>()
    data class Failed(val error: CoreError) : LoadState<Nothing>()

    val isLoading: Boolean get() = this is Loading
    val valueOrNull: T? get() = (this as? Loaded<T>)?.value
}

/** Any failure the core hands back, normalised to a [CoreError]. */
fun Throwable.asCoreError(): CoreError = this as? CoreError ?: CoreError.Unknown(this)
