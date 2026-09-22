/**
 * @file PreviewLocationProvider.kt
 * @description Location for preview runs: always Surry Hills, permission always granted, so
 * Home and Discover work on an emulator without a GPS fix. Mirrors the iOS preview provider.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.preview

import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.model.Location

class PreviewLocationProvider(private val location: Location = PreviewCoreData.userLocation) : LocationProvider {
    override suspend fun current(): Result<Location> = Result.success(location)
    override suspend fun hasPermission(): Boolean = true
}
