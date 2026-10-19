package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.SubscriptionStatus
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Bind the receipt to a verified account BEFORE charging or restoring it.
 * A failed logIn must not silently purchase for the preceding/anonymous identity.
 */
internal class AccountEntitlementRepository(
    private val delegate: EntitlementRepository,
    scope: CoroutineScope,
    accountChanges: Flow<String?>,
    private val accountId: () -> String?,
) : EntitlementRepository by delegate {
    private val identityLock = Mutex()
    // A stale SDK customer cache never gives a signed-out or different account Pro.
    override val status = combine(accountChanges, delegate.appUserId, delegate.status) { account, billingId, status ->
        if (account != null && account == billingId) status else SubscriptionStatus(isPro = false)
    }.stateIn(scope, SharingStarted.Eagerly, SubscriptionStatus(isPro = false))
    override val isPro = status.map { it.isPro }.stateIn(scope, SharingStarted.Eagerly, false)

    override suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus> = withAccount {
        delegate.purchase(packageIdentifier).mapCatching { purchased ->
            // A completed transaction is not proof that the purchased product unlocked Pro.
            // This catches missing/mismatched RevenueCat entitlement mappings without granting access.
            if (!purchased.isPro) throw CoreError.Service(
                "PURCHASE_NOT_ACTIVATED",
                "The purchase completed but Lunch Pro was not activated. Restore purchases or contact support.",
            )
            purchased
        }
    }
    override suspend fun restore(): Result<SubscriptionStatus> = withAccount { delegate.restore() }
    override suspend fun logIn(userId: String): Result<Unit> = identityLock.withLock { delegate.logIn(userId) }
    override suspend fun logOut(): Result<Unit> = identityLock.withLock { delegate.logOut() }

    private suspend fun withAccount(action: suspend () -> Result<SubscriptionStatus>): Result<SubscriptionStatus> =
        identityLock.withLock {
            val id = accountId() ?: return@withLock Result.failure(CoreError.Gate(GateReason.SIGN_IN_REQUIRED))
            try {
                delegate.logIn(id).getOrThrow()
                if (delegate.appUserId.value != id || accountId() != id) {
                    return@withLock Result.failure(CoreError.Gate(GateReason.SIGN_IN_REQUIRED))
                }
                action()
            } catch (e: CancellationException) { throw e }
            catch (e: Throwable) { Result.failure(e) }
        }
}
