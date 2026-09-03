/**
 * @file SwiftLunchCoreFactoryTest.kt
 * @description Starts a real desktop core (fresh SQLite file, mock backend) behind
 * the Swift facade and walks onboarding -> meal log -> weekly budget with typed
 * returns, then checks the Swift entry point wires an ExternalLocationProvider.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.LunchCoreFactory
import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.model.FreeLimits
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.model.UserProfile
import au.iapp.lunch.core.support.FakeLocationProvider
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue

class SwiftLunchCoreFactoryTest {
    private val clock = TestClock()

    private fun config() = CoreConfig(
        supabaseUrl = "https://example.supabase.co",
        supabaseAnonKey = MockBackend.ANON_KEY,
        backendBaseUrl = MockBackend.BASE_URL,
        revenueCatApiKey = "rc-test-key",
        databasePath = TestDb.newPath(),
        isDebug = true,
    )

    @Test
    fun should_return_typed_values_when_walking_onboarding_and_meal_log_through_the_facade() = runTest {
        val core = SwiftLunchCore(LunchCoreFactory.start(config(), FakeLocationProvider(null), clock, MockBackend().engine))

        assertFalse(core.users.hasCompletedOnboarding.value)
        val user: UserProfile = core.users.createUser("Sam", UserPreferences(weeklyBudget = 150.0))
        core.users.hasCompletedOnboarding.first { it }

        val mealId: Long = core.meals.log(Meal(userId = user.id, mealType = "lunch", cost = 18.5, dateEpochSeconds = clock.now))
        assertTrue(mealId > 0)

        val weekStart = core.budget.weekStart(clock.now, clock.timeZoneId())
        val thisWeek: List<Meal> = core.meals.inRange(user.id, weekStart, weekStart + 7 * TestClock.DAY)
        assertEquals(listOf(mealId), thisWeek.map { it.id })
        assertEquals(18.5, core.budget.weeklyState(user.preferences, thisWeek, weekStart).currentSpent)
        assertSame(clock, core.clock)
    }

    @Test
    fun should_wire_a_facade_when_started_through_the_swift_entry_point() = runTest {
        val core = SwiftLunchCoreFactory.start(config(), ExternalLocationProvider(), clock)

        assertFalse(core.entitlements.isPro.value)
        assertEquals(FreeLimits.HISTORY_DAYS, core.gates.historyWindowDays())
        assertEquals("Sam", core.users.createUser("Sam", UserPreferences(weeklyBudget = 150.0)).name)
        assertTrue(core.users.hasCompletedOnboarding.first { it })
    }
}
