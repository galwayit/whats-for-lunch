package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.EntitlementRepository
import kotlinx.coroutines.CoroutineScope

/**
 * Android and iOS wrap the RevenueCat SDK; the desktop (JVM test) target has
 * no store and uses an in-memory fake.
 */
internal expect fun createEntitlementRepository(revenueCatApiKey: String, scope: CoroutineScope): EntitlementRepository
