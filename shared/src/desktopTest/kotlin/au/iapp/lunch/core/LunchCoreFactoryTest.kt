package au.iapp.lunch.core

import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.model.FreeLimits
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.service.FakeEntitlementRepository
import au.iapp.lunch.core.support.FakeLocationProvider
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

/** Starts a whole core against a fresh database file and walks onboarding -> meal log -> weekly budget. */
class LunchCoreFactoryTest {
    private val clock = TestClock()
    private val config = CoreConfig(
        supabaseUrl = "https://example.supabase.co",
        supabaseAnonKey = MockBackend.ANON_KEY,
        backendBaseUrl = MockBackend.BASE_URL,
        revenueCatApiKey = "rc-test-key",
        databasePath = TestDb.newPath(),
        isDebug = true,
    )

    @Test
    fun createUser_then_log_then_weeklyState() = runTest {
        val core = LunchCoreFactory.start(config, FakeLocationProvider(null), clock, MockBackend().engine)

        assertFalse(core.users.hasCompletedOnboarding.value)
        val user = core.users.createUser("Sam", UserPreferences(weeklyBudget = 150.0)).getOrThrow()
        core.users.hasCompletedOnboarding.first { it }

        core.meals.log(Meal(userId = user.id, mealType = "lunch", cost = 18.5, dateEpochSeconds = clock.now)).getOrThrow()

        val weekStart = core.budget.weekStart(clock.now, clock.timeZoneId())
        val thisWeek = core.meals.inRange(user.id, weekStart, weekStart + 7 * TestClock.DAY).getOrThrow()
        val state = core.budget.weeklyState(user.preferences, thisWeek, weekStart)

        assertEquals(1_788_098_400L, weekStart, "Monday 2026-08-31 00:00 AEST")
        assertEquals(150.0, state.weeklyCapacity)
        assertEquals(18.5, state.currentSpent)
        assertEquals(131.5, state.remainingCapacity)
        assertEquals(1, state.experiencesLogged)
    }

    @Test
    fun desktop_core_wires_the_fake_entitlements_and_free_gates() = runTest {
        val core = LunchCoreFactory.start(config, FakeLocationProvider(null), clock, MockBackend().engine)

        assertIs<au.iapp.lunch.core.service.AccountEntitlementRepository>(core.entitlements)
        assertFalse(core.entitlements.isPro.value)
        assertEquals(FreeLimits.HISTORY_DAYS, core.gates.historyWindowDays())
        assertEquals(au.iapp.lunch.core.model.GateReason.SIGN_IN_REQUIRED, core.gates.canRequestAi().reason)
        assertEquals(clock, core.clock)
    }
}
