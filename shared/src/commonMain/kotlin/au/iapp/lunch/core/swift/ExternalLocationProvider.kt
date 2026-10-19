/**
 * @file ExternalLocationProvider.kt
 * @description LocationProvider that the host app feeds from its own location stack
 * (CoreLocation on iOS). Swift cannot implement a Kotlin `suspend` interface, so the
 * app pushes state in through plain setters and the core reads it through the
 * contract.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Location
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.cancellation.CancellationException

/**
 * [LocationProvider] backed by state the host app maintains.
 *
 * Protocol for the app:
 * 1. Call [setPermission] whenever the authorisation status changes
 *    (`CLLocationManager.authorizationStatus`: granted for `authorizedWhenInUse`
 *    and `authorizedAlways`, denied otherwise). Denying also drops the last fix,
 *    so a later grant waits for a fresh one instead of serving a stale point.
 * 2. Call [update] with every fix the location manager delivers. A negative
 *    [accuracyMetres] means unknown, matching `CLLocation.horizontalAccuracy`.
 * 3. Call [clear] when fixes stop being trustworthy (for example after the app
 *    returns from the background and a new request is in flight).
 *
 * Contract semantics, mirroring the desktop/Android providers:
 * - [hasPermission] is the last value passed to [setPermission] (false initially).
 * - [current] fails with `CoreError.Service(LOCATION_PERMISSION_DENIED)` while
 *   permission is denied. With permission it returns the latest fix; if none has
 *   arrived yet it waits up to [firstFixTimeoutMillis] for one and then fails with
 *   `CoreError.Service(NO_LOCATION)`, which the core treats as "no location
 *   context" rather than as an error.
 *
 * All mutators are non-suspending and thread-safe; call them from the main thread
 * or a delegate queue as convenient.
 *
 * @param firstFixTimeoutMillis how long [current] waits for the first fix; 0 never waits.
 */
class ExternalLocationProvider(private val firstFixTimeoutMillis: Long) : LocationProvider {

    /** Waits [DEFAULT_FIRST_FIX_TIMEOUT_MILLIS] for a first fix. */
    constructor() : this(DEFAULT_FIRST_FIX_TIMEOUT_MILLIS)

    private val fix = MutableStateFlow<Location?>(null)
    private val permission = MutableStateFlow(false)
    private val searchArea = MutableStateFlow<Location?>(null)

    /** Latest fix, null until [update] is called. Observable from Swift as well. */
    val location: StateFlow<Location?> = fix.asStateFlow()

    /** Last value passed to [setPermission]. */
    val permissionGranted: StateFlow<Boolean> = permission.asStateFlow()

    /** Records a fix with unknown accuracy. */
    fun update(latitude: Double, longitude: Double) = update(latitude, longitude, UNKNOWN_ACCURACY)

    /** Records a fix; a negative [accuracyMetres] is stored as unknown. */
    fun update(latitude: Double, longitude: Double, accuracyMetres: Double) {
        fix.value = Location(latitude, longitude, accuracyMetres.takeIf { it >= 0 })
    }

    /** Forgets the last fix; the next [current] waits for a new one. */
    fun clear() {
        fix.value = null
    }

    /** A user-selected search centre is independent of device-location permission. */
    fun setSearchArea(latitude: Double, longitude: Double) {
        require(latitude.isFinite() && latitude in -90.0..90.0)
        require(longitude.isFinite() && longitude in -180.0..180.0)
        searchArea.value = Location(latitude, longitude)
    }

    fun clearSearchArea() { searchArea.value = null }

    /** Records the authorisation status. Denying also clears the last fix. */
    fun setPermission(granted: Boolean) {
        permission.value = granted
        if (!granted) clear()
    }

    override suspend fun current(): Result<Location> {
        searchArea.value?.let { return Result.success(it) }
        if (!permission.value) {
            return Result.failure(CoreError.Service(LOCATION_PERMISSION_DENIED, "Location permission not granted"))
        }
        val location = fix.value ?: withTimeoutOrNull(firstFixTimeoutMillis) { fix.filterNotNull().first() }
        return if (location != null) Result.success(location)
        else Result.failure(CoreError.Service(NO_LOCATION, "Location unavailable"))
    }

    override suspend fun hasPermission(): Boolean = permission.value

    /** Swift-friendly typed counterpart to [current], whose Result would erase to Any?. */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun currentLocation(): Location = unwrap { current() }

    /** Swift-friendly Boolean counterpart that avoids the KotlinBoolean bridge wrapper. */
    suspend fun permissionIsGranted(): Boolean = hasPermission()

    companion object {
        const val DEFAULT_FIRST_FIX_TIMEOUT_MILLIS = 10_000L

        /** `CoreError.Service` code when permission is denied. */
        const val LOCATION_PERMISSION_DENIED = "LOCATION_PERMISSION_DENIED"

        /** `CoreError.Service` code when no fix arrived in time; same code as the desktop fake. */
        const val NO_LOCATION = "NO_LOCATION"

        private const val UNKNOWN_ACCURACY = -1.0
    }
}
