/**
 * @file PurchasesDisabledEntitlementRepository.kt
 * @description Free-tier [EntitlementRepository] for Debug builds that run against the
 * real backend before a RevenueCat project exists.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.ProOfferings
import au.iapp.lunch.core.model.SubscriptionStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Always free: offerings and purchases fail with [UNAVAILABLE_CODE], restore reports the
 * free status. The user is identified to the backend by the host's [anonymousAppUserId],
 * which the host persists, so per-user limits such as the daily AI allowance survive
 * relaunches the way RevenueCat's anonymous id would.
 */
internal class PurchasesDisabledEntitlementRepository(
    private val anonymousAppUserId: String,
) : EntitlementRepository {

    private val freeStatus = SubscriptionStatus(isPro = false)
    private val mutableAppUserId = MutableStateFlow(anonymousAppUserId)

    override val isPro: StateFlow<Boolean> = MutableStateFlow(false).asStateFlow()
    override val status: StateFlow<SubscriptionStatus> = MutableStateFlow(freeStatus).asStateFlow()
    override val appUserId: StateFlow<String> = mutableAppUserId.asStateFlow()

    override suspend fun offerings(): Result<ProOfferings> = Result.failure(unavailable())

    override suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus> =
        Result.failure(unavailable())

    override suspend fun restore(): Result<SubscriptionStatus> = Result.success(freeStatus)

    /** Mirrors RevenueCat: after sign-in the backend sees the account id. */
    override suspend fun logIn(userId: String): Result<Unit> {
        mutableAppUserId.value = userId
        return Result.success(Unit)
    }

    override suspend fun logOut(): Result<Unit> {
        mutableAppUserId.value = anonymousAppUserId
        return Result.success(Unit)
    }

    private fun unavailable() =
        CoreError.Service(UNAVAILABLE_CODE, "Purchases are turned off in this Debug build (no RevenueCat key)")

    companion object {
        const val UNAVAILABLE_CODE = "PURCHASES_UNAVAILABLE"
    }
}

/** True when the host supplied no RevenueCat key. Only [validatePurchasesConfig] allows it. */
internal val CoreConfig.purchasesDisabled: Boolean get() = revenueCatApiKey.isBlank()

/**
 * Fails at start rather than on first use: a Release build must never run without
 * purchases, and a Debug build without them needs a stable id for the backend.
 *
 * @throws IllegalArgumentException when either rule is broken.
 */
internal fun validatePurchasesConfig(config: CoreConfig) {
    if (!config.purchasesDisabled) return
    require(config.isDebug) { "revenueCatApiKey is required outside Debug builds" }
    require(!config.anonymousAppUserId.isNullOrBlank()) {
        "anonymousAppUserId is required when revenueCatApiKey is empty"
    }
}
