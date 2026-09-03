/**
 * @file SwiftLunchCoreFactory.kt
 * @description Single entry point for the iOS app: starts the core through
 * LunchCoreFactory and returns it wrapped in the Swift facade.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.LunchCoreFactory
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.CoreConfig

/**
 * Swift calls `SwiftLunchCoreFactory.shared.start(config:location:)` once at
 * launch with an [ExternalLocationProvider] it keeps feeding, then holds the
 * returned [SwiftLunchCore] for the life of the process. Keeping the concrete
 * type here avoids asking Swift to implement a Kotlin suspend interface.
 */
object SwiftLunchCoreFactory {

    /** Starts a core with the platform clock. */
    fun start(config: CoreConfig, location: ExternalLocationProvider): SwiftLunchCore =
        SwiftLunchCore(LunchCoreFactory.start(config, location))

    /** Starts a core with an explicit [clock] (UI tests freeze time through it). */
    fun start(config: CoreConfig, location: ExternalLocationProvider, clock: Clock): SwiftLunchCore =
        SwiftLunchCore(LunchCoreFactory.start(config, location, clock))
}
