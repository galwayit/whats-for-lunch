package au.iapp.lunch.core.data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.MealRepository
import au.iapp.lunch.core.db.DbJson
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.db.toMeal
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Meal
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Meal log over the `meals` table; dates are epoch seconds like Drift wrote them. */
internal class MealRepositoryImpl(
    private val db: LunchDatabase,
    private val clock: Clock,
) : MealRepository {

    override suspend fun log(meal: Meal): Result<Long> = dbResult {
        db.transactionWithResult {
            db.mealsQueries.insert(
                user_id = meal.userId,
                restaurant_id = meal.restaurantId,
                meal_type = meal.mealType,
                cost = meal.cost,
                date = meal.dateEpochSeconds,
                restaurant_name = meal.restaurantName,
                notes = meal.notes,
                photo_ids = DbJson.encode(meal.photoIds),
            )
            db.mealsQueries.selectLatestId().executeAsOne()
        }
    }

    override suspend fun update(meal: Meal): Result<Unit> = dbResult {
        val id = meal.id ?: throw CoreError.Service(MEAL_NOT_SAVED, "Cannot update a meal that was never logged")
        db.mealsQueries.update(
            user_id = meal.userId,
            restaurant_id = meal.restaurantId,
            meal_type = meal.mealType,
            cost = meal.cost,
            date = meal.dateEpochSeconds,
            restaurant_name = meal.restaurantName,
            notes = meal.notes,
            photo_ids = DbJson.encode(meal.photoIds),
            id = id,
        )
    }

    override suspend fun delete(id: Long): Result<Unit> = dbResult { db.mealsQueries.deleteById(id) }

    override suspend fun inRange(userId: Long, startEpochSeconds: Long, endEpochSeconds: Long): Result<List<Meal>> = dbResult {
        db.mealsQueries.selectInRange(userId, startEpochSeconds, endEpochSeconds).executeAsList().map { it.toMeal() }
    }

    /** [windowDays] null means no lower bound (Pro); otherwise only meals inside the window. */
    override fun observeRecent(userId: Long, limit: Int, windowDays: Int?): Flow<List<Meal>> {
        val since = windowDays?.let { clock.nowEpochSeconds() - it * SECONDS_PER_DAY } ?: 0L
        return db.mealsQueries.selectRecent(userId, since, limit.toLong(), 0L)
            .asFlow()
            .mapToList(DbDispatcher)
            .map { rows -> rows.map { it.toMeal() } }
    }

    /**
     * Restaurant names logged in the last 30 days, most frequent first, at most ten.
     * The Flutter provider used the same shape but with placeholder names; here the
     * real `restaurant_name` column drives it (see BUILD_NOTES.md).
     */
    override suspend fun restaurantSuggestions(userId: Long): Result<List<String>> = dbResult {
        val since = clock.nowEpochSeconds() - SUGGESTION_WINDOW_DAYS * SECONDS_PER_DAY
        db.mealsQueries.restaurantNameFrequency(userId, since, SUGGESTION_LIMIT)
            .executeAsList()
            .mapNotNull { it.restaurant_name?.takeIf { name -> name.isNotBlank() } }
    }

    companion object {
        const val MEAL_NOT_SAVED = "MEAL_NOT_SAVED"
        const val SECONDS_PER_DAY = 86_400L
        const val SUGGESTION_WINDOW_DAYS = 30L
        const val SUGGESTION_LIMIT = 10L
    }
}
