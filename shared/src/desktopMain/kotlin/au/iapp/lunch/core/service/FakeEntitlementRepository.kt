package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.ProOfferings
import au.iapp.lunch.core.model.ProPackage
import au.iapp.lunch.core.model.SubscriptionStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * In-memory stand-in for RevenueCat on the JVM, where there is no app store.
 *
 * Purchases and restores succeed immediately so desktop tests can exercise the
 * Pro and free paths of [au.iapp.lunch.core.api.GateService] without a store.
 * The anonymous id follows RevenueCat's `$RCAnonymousID:` convention and matches
 * the backend's `APP_USER_ID_PATTERN` (`^[A-Za-z0-9._:$@-]{1,128}$`).
 */
class FakeEntitlementRepository(
    initialStatus: SubscriptionStatus = SubscriptionStatus(isPro = false),
) : EntitlementRepository {

    private val mutableStatus = MutableStateFlow(initialStatus)
    private val mutableIsPro = MutableStateFlow(initialStatus.isPro)
    private val mutableAppUserId = MutableStateFlow(ANONYMOUS_ID)

    override val status: StateFlow<SubscriptionStatus> = mutableStatus.asStateFlow()
    /** Updated in the same call as [status] so gates never observe a stale value. */
    override val isPro: StateFlow<Boolean> = mutableIsPro.asStateFlow()
    override val appUserId: StateFlow<String> = mutableAppUserId.asStateFlow()

    /** Test hook: flip the entitlement without going through [purchase]. */
    fun setPro(isPro: Boolean, productId: String? = if (isPro) YEARLY.productId else null) {
        mutableStatus.value = SubscriptionStatus(isPro = isPro, productId = productId, willRenew = isPro)
        mutableIsPro.value = isPro
    }

    override suspend fun offerings(): Result<ProOfferings> =
        Result.success(ProOfferings(monthly = MONTHLY, yearly = YEARLY))

    override suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus> {
        val pkg = listOf(MONTHLY, YEARLY).firstOrNull { it.identifier == packageIdentifier }
            ?: return Result.failure(CoreError.Service("PACKAGE_NOT_FOUND", "Unknown package $packageIdentifier"))
        setPro(true, pkg.productId)
        return Result.success(status.value)
    }

    override suspend fun restore(): Result<SubscriptionStatus> = Result.success(status.value)

    override suspend fun logIn(userId: String): Result<Unit> {
        mutableAppUserId.value = userId
        return Result.success(Unit)
    }

    override suspend fun logOut(): Result<Unit> {
        mutableAppUserId.value = ANONYMOUS_ID
        setPro(false)
        return Result.success(Unit)
    }

    private companion object {
        const val ANONYMOUS_ID = "\$RCAnonymousID:desktop-fake"
        val MONTHLY = ProPackage(
            identifier = "\$rc_monthly",
            productId = "lunch_pro_monthly",
            localizedPrice = "A$4.99",
            periodLabel = "month",
            hasFreeTrial = false,
        )
        val YEARLY = ProPackage(
            identifier = "\$rc_annual",
            productId = "lunch_pro_yearly",
            localizedPrice = "A$29.99",
            periodLabel = "year",
            hasFreeTrial = false,
        )
    }
}

internal actual fun createEntitlementRepository(revenueCatApiKey: String, scope: CoroutineScope): EntitlementRepository =
    FakeEntitlementRepository()
