/**
 * @file PurchasesDisabledEntitlementRepositoryTest.kt
 * @description Debug-only no-purchases mode: the core starts free with a stable backend id,
 * and refuses to start that way outside Debug builds.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.core.service

import au.iapp.lunch.core.LunchCoreFactory
import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.support.FakeLocationProvider
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class PurchasesDisabledEntitlementRepositoryTest {
    private val clock = TestClock()

    private fun config(revenueCatApiKey: String = "", isDebug: Boolean = true, anonymousAppUserId: String? = ID) =
        CoreConfig(
            supabaseUrl = "https://example.supabase.co",
            supabaseAnonKey = MockBackend.ANON_KEY,
            backendBaseUrl = MockBackend.BASE_URL,
            revenueCatApiKey = revenueCatApiKey,
            databasePath = TestDb.newPath(),
            isDebug = isDebug,
            anonymousAppUserId = anonymousAppUserId,
        )

    private fun start(config: CoreConfig) =
        LunchCoreFactory.start(config, FakeLocationProvider(null), clock, MockBackend().engine)

    @Test
    fun should_start_free_with_the_host_id_when_debug_has_no_revenuecat_key() = runTest {
        val core = start(config())

        assertIs<PurchasesDisabledEntitlementRepository>(core.entitlements)
        assertFalse(core.entitlements.isPro.value)
        assertEquals(ID, core.entitlements.appUserId.value)
        assertEquals(au.iapp.lunch.core.model.GateReason.SIGN_IN_REQUIRED, core.gates.canRequestAi().reason)
    }

    @Test
    fun should_use_the_real_store_repository_when_a_key_is_present() = runTest {
        val core = start(config(revenueCatApiKey = "rc-test-key", anonymousAppUserId = null))

        assertIs<AccountEntitlementRepository>(core.entitlements, "purchases require the signed-in account")
    }

    @Test
    fun should_refuse_to_start_when_a_release_build_has_no_revenuecat_key() {
        assertFailsWith<IllegalArgumentException> { start(config(isDebug = false)) }
    }

    @Test
    fun should_refuse_to_start_when_debug_has_no_key_and_no_host_id() {
        assertFailsWith<IllegalArgumentException> { start(config(anonymousAppUserId = null)) }
        assertFailsWith<IllegalArgumentException> { start(config(anonymousAppUserId = " ")) }
    }

    @Test
    fun should_fail_offerings_and_purchase_when_purchases_are_disabled() = runTest {
        val repository = PurchasesDisabledEntitlementRepository(ID)

        val offerings = repository.offerings().exceptionOrNull()
        val purchase = repository.purchase("\$rc_annual").exceptionOrNull()

        assertEquals(PurchasesDisabledEntitlementRepository.UNAVAILABLE_CODE, assertIs<CoreError.Service>(offerings).code)
        assertEquals(PurchasesDisabledEntitlementRepository.UNAVAILABLE_CODE, assertIs<CoreError.Service>(purchase).code)
        assertFalse(repository.restore().getOrThrow().isPro)
        assertFalse(repository.isPro.value)
    }

    @Test
    fun should_follow_the_account_and_return_to_the_host_id_when_signing_in_and_out() = runTest {
        val repository = PurchasesDisabledEntitlementRepository(ID)

        repository.logIn("user-42").getOrThrow()
        assertEquals("user-42", repository.appUserId.value)

        repository.logOut().getOrThrow()
        assertEquals(ID, repository.appUserId.value)
    }

    private companion object {
        const val ID = "debug-7b0c1f2e-4f7a-4d3e-9a51-0c6b2e8d9f10"
    }
}
