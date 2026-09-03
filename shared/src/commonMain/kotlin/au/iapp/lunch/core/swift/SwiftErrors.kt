/**
 * @file SwiftErrors.kt
 * @description Result-to-exception bridge used by every Swift facade class: unwraps
 * kotlin.Result so that Swift sees typed values and a CoreError, never `Any?`.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.model.CoreError
import kotlinx.coroutines.CancellationException

/**
 * Runs [block] and unwraps its [Result] for a Swift caller.
 *
 * - success -> the value is returned;
 * - failure carrying a [CoreError] -> rethrown unchanged, so Swift can switch on
 *   the sealed subclass (`onEnum(of:)`);
 * - [CancellationException] (thrown or carried) -> propagated untouched so
 *   structured cancellation keeps working through SKIE;
 * - any other throwable, whether carried by the Result or thrown directly ->
 *   wrapped in [CoreError.Unknown] with the original as its cause.
 *
 * `kotlin.Result` is a value class and erases to `Any?` in the Objective-C export,
 * which is why the facade never lets one cross the boundary.
 */
internal inline fun <T> unwrap(block: () -> Result<T>): T = try {
    block().getOrThrow()
} catch (e: CoreError) {
    throw e
} catch (e: CancellationException) {
    throw e
} catch (e: Throwable) {
    throw CoreError.Unknown(e)
}
