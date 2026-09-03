package au.iapp.lunch.core.data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToOneOrNull
import au.iapp.lunch.core.api.AchievementEngine
import au.iapp.lunch.core.api.AchievementRepository
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.json.UserPreferencesJson
import au.iapp.lunch.core.model.Achievement
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull

/**
 * Unlocked achievements stored as `{ "<id>": unlockedAtEpochSeconds }` under the
 * `nativeAchievements` key of `users.preferences`. Flutter ignores unknown keys, so
 * the Drift schema stays at v6. [observe] emits the whole catalogue with unlock state.
 */
internal class AchievementRepositoryImpl(
    private val db: LunchDatabase,
    private val engine: AchievementEngine,
    private val clock: Clock,
) : AchievementRepository {

    override fun observe(userId: Long): Flow<List<Achievement>> =
        db.usersQueries.selectById(userId)
            .asFlow()
            .mapToOneOrNull(DbDispatcher)
            .map { user -> merge(unlockedFrom(user?.preferences ?: "")) }

    override suspend fun unlock(userId: Long, achievements: List<Achievement>) {
        if (achievements.isEmpty()) return
        withContext(DbDispatcher) {
            db.transaction {
                val user = db.usersQueries.selectById(userId).executeAsOneOrNull() ?: return@transaction
                val unlocked = unlockedFrom(user.preferences).toMutableMap()
                val now = clock.nowEpochSeconds()
                achievements.forEach { unlocked.putIfAbsent(it.id, it.unlockedAtEpochSeconds ?: now) }
                val value = JsonObject(unlocked.mapValues { JsonPrimitive(it.value) })
                db.usersQueries.updatePreferences(
                    preferences = UserPreferencesJson.withExtra(user.preferences, UserPreferencesJson.NATIVE_ACHIEVEMENTS_KEY, value),
                    id = userId,
                )
            }
        }
    }

    private fun merge(unlocked: Map<String, Long>): List<Achievement> = engine.catalogue.map { achievement ->
        val at = unlocked[achievement.id]
        if (at == null) achievement else achievement.copy(isUnlocked = true, unlockedAtEpochSeconds = at)
    }

    private fun unlockedFrom(preferencesText: String): Map<String, Long> {
        val stored = UserPreferencesJson.extra(preferencesText, UserPreferencesJson.NATIVE_ACHIEVEMENTS_KEY) as? JsonObject
            ?: return emptyMap()
        return stored.mapNotNull { (id, value) -> value.jsonPrimitive.longOrNull?.let { id to it } }.toMap()
    }
}
