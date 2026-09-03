package au.iapp.lunch.core.data

import au.iapp.lunch.core.engine.AchievementEngineImpl
import au.iapp.lunch.core.json.UserPreferencesJson
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AchievementRepositoryTest {
    private val clock = TestClock()
    private val db = TestDb.fixture()
    private val engine = AchievementEngineImpl()
    private val repo = AchievementRepositoryImpl(db, engine, clock)

    @Test
    fun observe_emits_the_whole_catalogue_locked_for_a_fresh_user() = runTest {
        val achievements = repo.observe(1).first()

        assertEquals(engine.catalogue.map { it.id }, achievements.map { it.id })
        assertTrue(achievements.none { it.isUnlocked })
    }

    @Test
    fun unlock_stores_under_nativeAchievements_without_breaking_flutter_preferences() = runTest {
        val first = engine.catalogue[0]

        repo.unlock(1, listOf(first))

        val unlocked = repo.observe(1).first().single { it.isUnlocked }
        assertEquals(first.id, unlocked.id)
        assertEquals(clock.now, unlocked.unlockedAtEpochSeconds)

        val raw = db.usersQueries.selectById(1).executeAsOne().preferences
        val stored = Json.parseToJsonElement(raw).jsonObject[UserPreferencesJson.NATIVE_ACHIEVEMENTS_KEY]!!.jsonObject
        assertEquals(clock.now.toString(), stored[first.id]?.jsonPrimitive?.content)
        assertEquals(UserPreferences(), UserPreferencesJson.decode(raw), "the extra key must be invisible to the preferences model")
    }

    @Test
    fun unlock_keeps_the_first_timestamp_and_ignores_unknown_users() = runTest {
        val first = engine.catalogue[0]
        val second = engine.catalogue[1]
        repo.unlock(1, listOf(first))
        clock.advance(TestClock.DAY)

        repo.unlock(1, listOf(first, second.copy(unlockedAtEpochSeconds = 1_700_000_000)))
        repo.unlock(999, listOf(first))

        val byId = repo.observe(1).first().associateBy { it.id }
        assertEquals(TestClock.DEFAULT_NOW, byId.getValue(first.id).unlockedAtEpochSeconds)
        assertEquals(1_700_000_000, byId.getValue(second.id).unlockedAtEpochSeconds)
        assertEquals(1, db.usersQueries.selectAll().executeAsList().size)
    }
}
