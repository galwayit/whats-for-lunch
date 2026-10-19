package au.iapp.lunch.core

import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.api.LunchCore
import au.iapp.lunch.core.di.coreModule
import au.iapp.lunch.core.platform.SystemClock
import au.iapp.lunch.core.platform.createHttpEngine
import au.iapp.lunch.core.service.validatePurchasesConfig
import io.ktor.client.engine.HttpClientEngine
import org.koin.dsl.koinApplication

/**
 * Entry point for both apps: `LunchCoreFactory.start(config, location)` once at
 * launch, then keep the returned [LunchCore]. Each call builds its own Koin
 * container, so the host app's Koin (if any) is untouched.
 */
object LunchCoreFactory {

    /** Starts a core with the platform clock. Swift-friendly: no default arguments. */
    fun start(config: CoreConfig, location: LocationProvider): LunchCore =
        start(config, location, SystemClock)

    /** Starts a core with an explicit [clock] (tests freeze time through it). */
    fun start(config: CoreConfig, location: LocationProvider, clock: Clock = SystemClock): LunchCore =
        start(config, location, clock, createHttpEngine())

    /** Test seam: the backend client uses [httpEngine] (e.g. Ktor's MockEngine). */
    internal fun start(config: CoreConfig, location: LocationProvider, clock: Clock, httpEngine: HttpClientEngine): LunchCore {
        validatePurchasesConfig(config)
        val app = koinApplication { modules(coreModule(config, location, clock, httpEngine)) }
        return LunchCoreImpl(app.koin)
    }
}
