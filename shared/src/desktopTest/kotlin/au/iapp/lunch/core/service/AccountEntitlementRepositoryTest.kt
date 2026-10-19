package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.SubscriptionStatus
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AccountEntitlementRepositoryTest {
    @Test fun signed_out_purchase_and_restore_never_reach_the_store() = runTest {
        val store = FakeEntitlementRepository()
        val repository = AccountEntitlementRepository(store, backgroundScope, kotlinx.coroutines.flow.flowOf("account-42")) { null }
        assertEquals(CoreError.Gate(GateReason.SIGN_IN_REQUIRED), repository.purchase("\$rc_monthly").exceptionOrNull())
        assertEquals(CoreError.Gate(GateReason.SIGN_IN_REQUIRED), repository.restore().exceptionOrNull())
        assertFalse(store.isPro.value)
    }

    @Test fun failed_identity_switch_cannot_charge_the_previous_account() = runTest {
        val underlying = FakeEntitlementRepository()
        underlying.logIn("previous-account")
        var purchases = 0
        val store = object : EntitlementRepository by underlying {
            override suspend fun logIn(userId: String): Result<Unit> = Result.failure(CoreError.Offline)
            override suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus> {
                purchases++
                return underlying.purchase(packageIdentifier)
            }
        }
        val repository = AccountEntitlementRepository(store, backgroundScope, kotlinx.coroutines.flow.flowOf("account-42")) { "current-account" }
        assertEquals(CoreError.Offline, repository.purchase("\$rc_monthly").exceptionOrNull())
        assertEquals(0, purchases)
        assertEquals("previous-account", store.appUserId.value)
    }

    @Test fun successful_purchase_binds_to_the_verified_account_first() = runTest {
        val store = FakeEntitlementRepository()
        val repository = AccountEntitlementRepository(store, backgroundScope, kotlinx.coroutines.flow.flowOf("account-42")) { "account-42" }
        assertTrue(repository.purchase("\$rc_monthly").getOrThrow().isPro)
        assertEquals("account-42", store.appUserId.value)
    }

    @Test fun account_switch_during_login_aborts_purchase() = runTest {
        val underlying = FakeEntitlementRepository()
        var current: String? = "account-42"
        val store = object : EntitlementRepository by underlying {
            override suspend fun logIn(userId: String): Result<Unit> {
                underlying.logIn(userId)
                current = null
                return Result.success(Unit)
            }
        }
        val repository = AccountEntitlementRepository(store, backgroundScope, kotlinx.coroutines.flow.flowOf("account-42")) { current }
        assertEquals(CoreError.Gate(GateReason.SIGN_IN_REQUIRED), repository.purchase("\$rc_monthly").exceptionOrNull())
        assertFalse(store.isPro.value)
    }

    @Test fun completed_purchase_without_pro_entitlement_reports_activation_failure() = runTest {
        val underlying = FakeEntitlementRepository()
        val store = object : EntitlementRepository by underlying {
            override suspend fun purchase(packageIdentifier: String) = Result.success(SubscriptionStatus(isPro = false))
        }
        val repository = AccountEntitlementRepository(store, backgroundScope, kotlinx.coroutines.flow.flowOf("account-42")) { "account-42" }
        val error = repository.purchase("\$rc_monthly").exceptionOrNull() as CoreError.Service
        assertEquals("PURCHASE_NOT_ACTIVATED", error.code)
        assertFalse(repository.isPro.value)
        // Restore with no subscription is a normal empty result, not a failed purchase.
        assertFalse(repository.restore().getOrThrow().isPro)
    }
}
