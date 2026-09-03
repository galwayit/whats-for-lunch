package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.EntitlementRepository
import com.revenuecat.purchases.kmp.Purchases
import com.revenuecat.purchases.kmp.PurchasesConfiguration
import kotlinx.coroutines.CoroutineScope

/**
 * Configures the RevenueCat SDK once per process (the host app may have done so
 * already, e.g. for a paywall SDK) and wraps the shared instance.
 */
internal actual fun createEntitlementRepository(revenueCatApiKey: String, scope: CoroutineScope): EntitlementRepository {
    val purchases = if (Purchases.isConfigured) {
        Purchases.sharedInstance
    } else {
        Purchases.configure(PurchasesConfiguration.Builder(revenueCatApiKey).build())
    }
    return RevenueCatEntitlementRepository(purchases, scope)
}
