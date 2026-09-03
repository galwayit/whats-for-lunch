package au.iapp.lunch.core.data

import au.iapp.lunch.core.json.UserPreferencesJson
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class UserRepositoryTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val clock = TestClock()

    @AfterTest
    fun tearDown() = scope.cancel()

    @Test
    fun current_is_the_demo_user_of_the_fixture() {
        val repo = UserRepositoryImpl(TestDb.fixture(), clock, scope)

        val user = repo.current.value
        assertEquals("Demo User", user?.name)
        assertEquals(1L, user?.id)
        assertEquals(UserPreferences(), user?.preferences)
        assertTrue(repo.hasCompletedOnboarding.value)
    }

    @Test
    fun createUser_on_an_empty_database_completes_onboarding() = runTest {
        val repo = UserRepositoryImpl(TestDb.empty(), clock, scope)
        assertNull(repo.current.value)
        assertFalse(repo.hasCompletedOnboarding.value)

        val created = repo.createUser("Sam", UserPreferences(weeklyBudget = 150.0)).getOrThrow()

        assertEquals("Sam", created.name)
        assertEquals(150.0, created.preferences.weeklyBudget)
        assertEquals(clock.now, created.createdAtEpochSeconds)
        repo.hasCompletedOnboarding.first { it }
        assertEquals(created.id, repo.current.first { it != null }?.id)
    }

    @Test
    fun current_stays_the_lowest_id_when_a_second_user_is_created() = runTest {
        val repo = UserRepositoryImpl(TestDb.fixture(), clock, scope)

        val second = repo.createUser("Second", UserPreferences()).getOrThrow()

        assertEquals(2L, second.id)
        assertEquals(1L, repo.current.value?.id)
    }

    @Test
    fun updatePreferences_keeps_keys_this_model_does_not_know() = runTest {
        val db = TestDb.fixture()
        db.usersQueries.updatePreferences(preferences = """{"budgetLevel":3,"flutterOnlyKey":true}""", id = 1)
        val repo = UserRepositoryImpl(db, clock, scope)

        repo.updatePreferences(UserPreferences(budgetLevel = 4)).getOrThrow()

        val raw = Json.parseToJsonElement(db.usersQueries.selectById(1).executeAsOne().preferences).jsonObject
        assertEquals("4", raw["budgetLevel"]?.jsonPrimitive?.content)
        assertEquals("true", raw["flutterOnlyKey"]?.jsonPrimitive?.content)
        assertEquals(4, UserPreferencesJson.decode(raw.toString()).budgetLevel)
    }

    @Test
    fun updateName_writes_the_row() = runTest {
        val db = TestDb.fixture()
        val repo = UserRepositoryImpl(db, clock, scope)

        repo.updateName("Renamed").getOrThrow()

        assertEquals("Renamed", db.usersQueries.selectById(1).executeAsOne().name)
    }

    @Test
    fun updates_fail_with_NO_USER_before_onboarding() = runTest {
        val repo = UserRepositoryImpl(TestDb.empty(), clock, scope)

        val error = repo.updateName("Nobody").exceptionOrNull()

        assertEquals(UserRepositoryImpl.NO_USER, (error as CoreError.Service).code)
    }
}
