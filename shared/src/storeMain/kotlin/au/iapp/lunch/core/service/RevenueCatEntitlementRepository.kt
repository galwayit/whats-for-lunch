package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.ProOfferings
import au.iapp.lunch.core.model.ProPackage
import au.iapp.lunch.core.model.SubscriptionStatus
import com.revenuecat.purchases.kmp.Purchases
import com.revenuecat.purchases.kmp.PurchasesDelegate
import com.revenuecat.purchases.kmp.ktx.awaitCustomerInfo
import com.revenuecat.purchases.kmp.ktx.awaitLogIn
import com.revenuecat.purchases.kmp.ktx.awaitLogOut
import com.revenuecat.purchases.kmp.ktx.awaitOfferings
import com.revenuecat.purchases.kmp.ktx.awaitPurchase
import com.revenuecat.purchases.kmp.ktx.awaitRestore
import com.revenuecat.purchases.kmp.models.CacheFetchPolicy
import com.revenuecat.purchases.kmp.models.CustomerInfo
import com.revenuecat.purchases.kmp.models.Package
import com.revenuecat.purchases.kmp.models.PeriodUnit
import com.revenuecat.purchases.kmp.models.PurchasesError
import com.revenuecat.purchases.kmp.models.PurchasesErrorCode
import com.revenuecat.purchases.kmp.models.PurchasesException
import com.revenuecat.purchases.kmp.models.PurchasesTransactionException
import com.revenuecat.purchases.kmp.models.StoreProduct
import com.revenuecat.purchases.kmp.models.StoreTransaction
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * [EntitlementRepository] over the RevenueCat KMP SDK (Android and iOS).
 *
 * The single `pro` entitlement (the id the backend webhook reads from
 * `entitlement_ids`) drives [isPro]. [status] is refreshed from the SDK's
 * customer-info delegate, so a renewal or expiry observed by RevenueCat is
 * reflected without the app polling.
 */
internal class RevenueCatEntitlementRepository(
    private val purchases: Purchases,
    scope: CoroutineScope,
) : EntitlementRepository {

    private val mutableStatus = MutableStateFlow(SubscriptionStatus(isPro = false))
    private val mutableIsPro = MutableStateFlow(false)
    private val mutableAppUserId = MutableStateFlow(purchases.appUserID)

    override val status: StateFlow<SubscriptionStatus> = mutableStatus.asStateFlow()
    /** Updated together with [status] in [publish] so gates never observe a stale value. */
    override val isPro: StateFlow<Boolean> = mutableIsPro.asStateFlow()
    override val appUserId: StateFlow<String> = mutableAppUserId.asStateFlow()

    init {
        purchases.delegate = object : PurchasesDelegate {
            override fun onCustomerInfoUpdated(customerInfo: CustomerInfo) = publish(customerInfo)

            // Promoted App Store purchases: let the SDK complete them and the
            // delegate above picks up the resulting customer info.
            override fun onPurchasePromoProduct(
                product: StoreProduct,
                startPurchase: (
                    onError: (error: PurchasesError, userCancelled: Boolean) -> Unit,
                    onSuccess: (storeTransaction: StoreTransaction, customerInfo: CustomerInfo) -> Unit,
                ) -> Unit,
            ) = startPurchase({ _, _ -> }, { _, info -> publish(info) })
        }
        scope.launch {
            runCatching { purchases.awaitCustomerInfo(CacheFetchPolicy.CACHED_OR_FETCHED) }
                .onSuccess(::publish)
        }
    }

    override suspend fun offerings(): Result<ProOfferings> = storeResult {
        val current = purchases.awaitOfferings().current
        ProOfferings(monthly = current?.monthly?.toProPackage(), yearly = current?.annual?.toProPackage())
    }

    override suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus> = storeResult {
        val pkg = purchases.awaitOfferings().current?.availablePackages
            ?.firstOrNull { it.identifier == packageIdentifier }
            ?: throw CoreError.Service("PACKAGE_NOT_FOUND", "Unknown package $packageIdentifier")
        publish(purchases.awaitPurchase(pkg).customerInfo)
        status.value
    }

    override suspend fun restore(): Result<SubscriptionStatus> = storeResult {
        publish(purchases.awaitRestore())
        status.value
    }

    override suspend fun logIn(userId: String): Result<Unit> = storeResult {
        publish(purchases.awaitLogIn(userId).customerInfo)
        mutableAppUserId.value = purchases.appUserID
    }

    override suspend fun logOut(): Result<Unit> = storeResult {
        // RevenueCat refuses logOut for an anonymous user; nothing to do then.
        if (!purchases.isAnonymous) publish(purchases.awaitLogOut())
        mutableAppUserId.value = purchases.appUserID
    }

    private fun publish(info: CustomerInfo) {
        val pro = info.entitlements.active[PRO_ENTITLEMENT]
        mutableStatus.value = SubscriptionStatus(
            isPro = pro?.isActive == true,
            productId = pro?.productIdentifier,
            expiresAtEpochSeconds = pro?.expirationDateMillis?.let { it / 1000 },
            willRenew = pro?.willRenew == true,
            managementUrl = info.managementUrlString,
        )
        mutableIsPro.value = mutableStatus.value.isPro
    }

    private inline fun <T> storeResult(block: () -> T): Result<T> = try {
        Result.success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: CoreError) {
        Result.failure(e)
    } catch (e: PurchasesException) {
        Result.failure(e.toCoreError())
    } catch (e: Throwable) {
        Result.failure(CoreError.Unknown(e))
    }

    private fun PurchasesException.toCoreError(): CoreError = when {
        this is PurchasesTransactionException && userCancelled -> CoreError.Service(PURCHASE_CANCELLED, message)
        code == PurchasesErrorCode.NetworkError || code == PurchasesErrorCode.OfflineConnectionError -> CoreError.Offline
        else -> CoreError.Service(code.name, underlyingErrorMessage ?: message)
    }

    private fun Package.toProPackage(): ProPackage {
        val product = storeProduct
        val trial = product.subscriptionOptions?.freeTrial?.pricingPhases?.firstOrNull()?.billingPeriod
            ?: product.introductoryDiscount?.takeIf { it.price.amountMicros == 0L }?.subscriptionPeriod
        return ProPackage(
            identifier = identifier,
            productId = product.id,
            localizedPrice = product.price.formatted,
            periodLabel = product.period?.label() ?: "",
            hasFreeTrial = trial != null,
            trialLabel = trial?.let { "${it.label(plural = true)} free trial" },
        )
    }

    private fun com.revenuecat.purchases.kmp.models.Period.label(plural: Boolean = false): String {
        val unit = when (this.unit) {
            PeriodUnit.DAY -> "day"
            PeriodUnit.WEEK -> "week"
            PeriodUnit.MONTH -> "month"
            PeriodUnit.YEAR -> "year"
            PeriodUnit.UNKNOWN -> "period"
        }
        return if (value == 1 && !plural) unit else "$value $unit${if (value == 1) "" else "s"}"
    }

    private companion object {
        const val PRO_ENTITLEMENT = "pro"
        const val PURCHASE_CANCELLED = "PURCHASE_CANCELLED"
    }
}
