package au.iapp.lunch.core.data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToOneOrNull
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.db.Users
import au.iapp.lunch.core.db.toProfile
import au.iapp.lunch.core.json.UserPreferencesJson
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.model.UserProfile
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

/**
 * The single local user of the app (the Flutter app only ever created one),
 * read from the `users` table. [current] is the lowest-id row, as
 * `currentUserProvider` resolved it.
 */
internal class UserRepositoryImpl(
    private val db: LunchDatabase,
    private val clock: Clock,
    scope: CoroutineScope,
) : UserRepository {

    override val current: StateFlow<UserProfile?> = db.usersQueries.selectFirst()
        .asFlow()
        .mapToOneOrNull(DbDispatcher)
        .map { it?.toProfile() }
        .stateIn(scope, SharingStarted.Eagerly, db.usersQueries.selectFirst().executeAsOneOrNull()?.toProfile())

    override val hasCompletedOnboarding: StateFlow<Boolean> = current
        .map { it != null }
        .stateIn(scope, SharingStarted.Eagerly, current.value != null)

    override suspend fun createUser(name: String, preferences: UserPreferences): Result<UserProfile> = dbResult {
        db.transactionWithResult {
            db.usersQueries.insert(
                name = name,
                preferences = UserPreferencesJson.encode(preferences),
                created_at = clock.nowEpochSeconds(),
            )
            val id = db.usersQueries.selectLatestId().executeAsOne()
            db.usersQueries.selectById(id).executeAsOne().toProfile()
        }
    }

    override suspend fun updateName(name: String): Result<Unit> = dbResult {
        db.usersQueries.updateName(name = name, id = requireUser().id)
    }

    /** Re-encodes on top of the stored JSON so keys this model does not know (Flutter's or ours) survive. */
    override suspend fun updatePreferences(preferences: UserPreferences): Result<Unit> = dbResult {
        val user = requireUser()
        db.usersQueries.updatePreferences(
            preferences = UserPreferencesJson.encodePreserving(preferences, user.preferences),
            id = user.id,
        )
    }

    private fun requireUser(): Users =
        db.usersQueries.selectFirst().executeAsOneOrNull()
            ?: throw CoreError.Service(NO_USER, "No local user exists yet; complete onboarding first")

    companion object {
        const val NO_USER = "NO_USER"
    }
}
