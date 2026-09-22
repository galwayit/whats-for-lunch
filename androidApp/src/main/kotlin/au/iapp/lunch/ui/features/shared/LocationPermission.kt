/**
 * @file LocationPermission.kt
 * @description Runtime location permission for Compose: reports the current grant and requests
 * fine or coarse location through the system prompt. API 33+ only, so no legacy branches.
 * Mirrors iosApp/.../Shared/LocationPermission.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import au.iapp.lunch.app.AndroidLocationProvider

class LocationPermissionState(initial: Boolean, private val launch: () -> Unit) {
    var isGranted by mutableStateOf(initial)
        internal set

    /** Shows the system prompt; the result lands in [isGranted]. */
    fun request() = launch()
}

@Composable
fun rememberLocationPermission(onResult: (Boolean) -> Unit = {}): LocationPermissionState {
    val context = LocalContext.current
    var granted by remember { mutableStateOf(AndroidLocationProvider.isGranted(context)) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        granted = result.values.any { it }
        onResult(granted)
    }
    val state = remember { LocationPermissionState(granted) { launcher.launch(AndroidLocationProvider.PERMISSIONS) } }
    state.isGranted = granted
    return state
}
