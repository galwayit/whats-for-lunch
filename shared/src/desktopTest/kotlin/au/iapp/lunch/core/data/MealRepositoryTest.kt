package au.iapp.lunch.core.data

import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class MealRepositoryTest {
    private val clock = TestClock()
    private val db = TestDb.fixture()
    private val repo = MealRepositoryImpl(db, clock)

    private fun meal(cost: Double, daysAgo: Long, name: String? = "Fixture Cafe", type: String = "lunch") = Meal(
        userId = 1,
        restaurantId = "place-${name.orEmpty().hashCode()}",
        restaurantName = name,
        mealType = type,
        cost = cost,
        dateEpochSeconds = clock.now - daysAgo * TestClock.DAY,
        photoIds = listOf("photo-1"),
    )

    @Test
    fun log_returns_the_new_id_and_round_trips_the_row() = runTest {
        val id = repo.log(meal(18.5, daysAgo = 0)).getOrThrow()

        val stored = repo.inRange(1, clock.now - 1, clock.now + 1).getOrThrow().single()
        assertEquals(id, stored.id)
        assertEquals(18.5, stored.cost)
        assertEquals(listOf("photo-1"), stored.photoIds)
        assertEquals("Fixture Cafe", stored.restaurantName)
    }

    @Test
    fun inRange_is_half_open_and_newest_first() = runTest {
        repo.log(meal(10.0, daysAgo = 2)).getOrThrow()
        repo.log(meal(20.0, daysAgo = 1)).getOrThrow()
        repo.log(meal(30.0, daysAgo = 0)).getOrThrow()

        val meals = repo.inRange(1, clock.now - 2 * TestClock.DAY, clock.now).getOrThrow()

        assertEquals(listOf(20.0, 10.0), meals.map { it.cost })
    }

    @Test
    fun observeRecent_applies_the_free_tier_window_and_limit() = runTest {
        repo.log(meal(40.0, daysAgo = 40)).getOrThrow()
        repo.log(meal(5.0, daysAgo = 5)).getOrThrow()
        repo.log(meal(1.0, daysAgo = 1)).getOrThrow()

        assertEquals(listOf(1.0, 5.0), repo.observeRecent(1, limit = 10, windowDays = 30).first().map { it.cost })
        assertEquals(listOf(1.0, 5.0, 40.0), repo.observeRecent(1, limit = 10, windowDays = null).first().map { it.cost })
        assertEquals(listOf(1.0), repo.observeRecent(1, limit = 1, windowDays = null).first().map { it.cost })
    }

    @Test
    fun update_and_delete_change_the_stored_row() = runTest {
        val id = repo.log(meal(18.5, daysAgo = 0)).getOrThrow()
        val logged = repo.inRange(1, 0, Long.MAX_VALUE).getOrThrow().single()

        repo.update(logged.copy(cost = 22.0, notes = "extra miso")).getOrThrow()
        val updated = db.mealsQueries.selectById(id).executeAsOne()
        assertEquals(22.0, updated.cost)
        assertEquals("extra miso", updated.notes)

        repo.delete(id).getOrThrow()
        assertEquals(emptyList(), repo.inRange(1, 0, Long.MAX_VALUE).getOrThrow())
    }

    @Test
    fun update_of_an_unsaved_meal_fails_with_MEAL_NOT_SAVED() = runTest {
        val error = repo.update(meal(1.0, daysAgo = 0)).exceptionOrNull()

        assertEquals(MealRepositoryImpl.MEAL_NOT_SAVED, (error as CoreError.Service).code)
    }

    @Test
    fun restaurantSuggestions_rank_last_30_days_by_frequency() = runTest {
        repeat(2) { repo.log(meal(12.0, daysAgo = it.toLong(), name = "Twice")).getOrThrow() }
        repo.log(meal(9.0, daysAgo = 3, name = "Once")).getOrThrow()
        repo.log(meal(9.0, daysAgo = 45, name = "Too Old")).getOrThrow()
        repo.log(meal(9.0, daysAgo = 1, name = null)).getOrThrow()

        assertEquals(listOf("Twice", "Once"), repo.restaurantSuggestions(1).getOrThrow())
    }
}
