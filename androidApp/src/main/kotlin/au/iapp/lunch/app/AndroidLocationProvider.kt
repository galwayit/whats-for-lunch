/**
 * @file AndroidLocationProvider.kt
 * @description [LocationProvider] for the real core over Play Services' fused location client.
 * Permission prompts stay in the UI (onboarding step 5 and Home); this only reports the current
 * grant and fetches a fix. Mirrors `KotlinLocationProvider` in iosApp/.../KotlinLunchCore.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Location
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class AndroidLocationProvider(context: Context) : LocationProvider {
    private val appContext = context.applicationContext
    private val client = LocationServices.getFusedLocationProviderClient(appContext)

    override suspend fun hasPermission(): Boolean = isGranted(appContext)

    override suspend fun current(): Result<Location> {
        if (!isGranted(appContext)) return Result.failure(CoreError.Service(PERMISSION_DENIED, "Location permission not granted"))
        return try {
            val fix = fetch() ?: return Result.failure(CoreError.Service(UNAVAILABLE, "No location fix"))
            Result.success(Location(fix.latitude, fix.longitude, fix.accuracy.toDouble()))
        } catch (security: SecurityException) {
            Result.failure(CoreError.Service(PERMISSION_DENIED, security.message ?: "Location permission not granted"))
        }
    }

    @Suppress("MissingPermission") // Checked in [current] before this is called.
    private suspend fun fetch(): android.location.Location? = suspendCancellableCoroutine { continuation ->
        val cancellation = CancellationTokenSource()
        client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, cancellation.token)
            .addOnSuccessListener { continuation.resume(it) }
            .addOnFailureListener { continuation.resume(null) }
            .addOnCanceledListener { continuation.resume(null) }
        continuation.invokeOnCancellation { cancellation.cancel() }
    }

    companion object {
        const val PERMISSION_DENIED = "LOCATION_PERMISSION_DENIED"
        const val UNAVAILABLE = "LOCATION_UNAVAILABLE"

        val PERMISSIONS = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)

        fun isGranted(context: Context): Boolean = PERMISSIONS.any {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }
}
