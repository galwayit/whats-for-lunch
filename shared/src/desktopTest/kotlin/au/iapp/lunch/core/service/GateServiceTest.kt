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
    fun ai_gate_allows_one_successful_request_per_local_day() = runTest {
        assertEquals(GateDecision.Allowed, gates.canRequestAi())

        usage.record(1, AiUsage.RECOMMENDATION, 10, successful = false, errorMessage = "boom")
        assertEquals(GateDecision.Allowed, gates.canRequestAi(), "failed requests do not count")

        usage.record(1, AiUsage.RECOMMENDATION, 10, successful = true, errorMessage = null)
        assertEquals(GateDecision.denied(GateReason.AI_DAILY_LIMIT), gates.canRequestAi())
        assertEquals(FreeLimits.AI_REQUESTS_PER_DAY, usage.usedToday(1))

        clock.advance(TestClock.DAY)
        assertEquals(GateDecision.Allowed, gates.canRequestAi(), "a new local day resets the quota")
    }

    @Test
    fun local_day_bounds_follow_the_clock_time_zone() {
        // 1_788_400_000 is 2026-09-03 11:46:40 AEST; that Sydney day starts at 2026-09-02 14:00:00 UTC.
        val (start, end) = usage.localDayBounds()

        assertEquals(1_788_357_600L, start)
        assertEquals(start + TestClock.DAY, end)
    }

    @Test
    fun pro_lifts_every_limit() = runTest {
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
