package au.iapp.lunch.core.service

import au.iapp.lunch.core.data.UserRepositoryImpl
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.FreeLimits
import au.iapp.lunch.core.model.GateDecision
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.support.FakeAuthRepository
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class GateServiceTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val clock = TestClock()
    private val db = TestDb.fixture()
    private val entitlements = FakeEntitlementRepository()
    private val auth = FakeAuthRepository()
    private val usage = AiUsage(db, clock)
    private val gates = GateServiceImpl(entitlements, auth, UserRepositoryImpl(db, clock, scope), usage)

    @AfterTest
    fun tearDown() = scope.cancel()

    @Test
    fun ai_allows_one_successful_free_request_per_utc_day() = runTest {
        auth.sessions.value = AuthSession("user-1", null, "Sam")
        assertEquals(GateDecision.Allowed, gates.canRequestAi())
        usage.record(1, AiUsage.RECOMMENDATION, 10, successful = false, errorMessage = "offline")
        assertEquals(GateDecision.Allowed, gates.canRequestAi(), "failed requests do not spend the free request")
        usage.record(1, AiUsage.RECOMMENDATION, 10, successful = true, errorMessage = null)
        assertEquals(GateDecision.denied(GateReason.AI_DAILY_LIMIT), gates.canRequestAi())
        clock.advance(TestClock.DAY)
        assertEquals(GateDecision.Allowed, gates.canRequestAi(), "the free request renews at UTC midnight")
    }

    @Test
    fun signed_out_requires_login_and_expired_subscriptions_return_to_free_allowance() = runTest {
        entitlements.setPro(true)
        assertEquals(GateDecision.denied(GateReason.SIGN_IN_REQUIRED), gates.canRequestAi())
        auth.sessions.value = AuthSession("user-1", null, "Sam")
        assertEquals(GateDecision.Allowed, gates.canRequestAi())
        entitlements.setPro(false)
        assertEquals(GateDecision.Allowed, gates.canRequestAi())
        usage.record(1, AiUsage.RECOMMENDATION, 10, successful = true, errorMessage = null)
        assertEquals(GateDecision.denied(GateReason.AI_DAILY_LIMIT), gates.canRequestAi())
    }

    @Test
    fun quota_day_uses_utc_regardless_of_device_time_zone() {
        // Daily quota is fixed to UTC so a device timezone change cannot reset usage.
        val (start, end) = usage.localDayBounds()

        assertEquals(1_788_393_600L, start)
        assertEquals(start + TestClock.DAY, end)
    }

    @Test
    fun pro_lifts_local_limits_after_sign_in() = runTest {
        auth.sessions.value = AuthSession("user-1", null, "Sam")
        usage.record(1, AiUsage.RECOMMENDATION, 10, successful = true, errorMessage = null)
        entitlements.setPro(true)

        assertEquals(GateDecision.Allowed, gates.canRequestAi())
        assertEquals(GateDecision.Allowed, gates.canAddFavourite(FreeLimits.FAVOURITES + 5))
        assertNull(gates.historyWindowDays())
    }

    @Test
    fun free_tier_limits_favourites_and_history() {
        assertEquals(GateDecision.Allowed, gates.canAddFavourite(FreeLimits.FAVOURITES - 1))
        assertEquals(GateDecision.denied(GateReason.FAVOURITES_LIMIT), gates.canAddFavourite(FreeLimits.FAVOURITES))
        assertEquals(FreeLimits.HISTORY_DAYS, gates.historyWindowDays())
    }

    @Test
    fun hosting_needs_a_session_and_then_pro() {
        assertEquals(GateDecision.denied(GateReason.SIGN_IN_REQUIRED), gates.canHostGroup())

        auth.sessions.value = AuthSession("user-1", "sam@example.test", "Sam")
        assertEquals(GateDecision.denied(GateReason.HOST_REQUIRES_PRO), gates.canHostGroup())

        entitlements.setPro(true)
        assertEquals(GateDecision.Allowed, gates.canHostGroup())
    }
}
