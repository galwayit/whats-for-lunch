/**
 * @file SwiftFacadeTest.kt
 * @description Verifies the Result-to-exception bridge of the Swift facade on
 * SwiftMealRepository: values pass through, CoreError is rethrown unchanged,
 * foreign exceptions become CoreError.Unknown, cancellation is untouched and
 * Flow members are handed over as-is.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.api.MealRepository
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Meal
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertSame

class SwiftFacadeTest {

    /** Minimal scripted MealRepository: `log` answers with [logResult], `delete` throws [deleteThrows]. */
    private class ScriptedMeals(
        private val logResult: Result<Long>,
        private val deleteThrows: Throwable? = null,
        val recent: Flow<List<Meal>> = flowOf(emptyList()),
    ) : MealRepository {
        override suspend fun log(meal: Meal): Result<Long> = logResult
        override suspend fun update(meal: Meal): Result<Unit> = logResult.map { }
        override suspend fun delete(id: Long): Result<Unit> = throw checkNotNull(deleteThrows)
        override suspend fun inRange(userId: Long, startEpochSeconds: Long, endEpochSeconds: Long): Result<List<Meal>> =
            error("not scripted")
        override fun observeRecent(userId: Long, limit: Int, windowDays: Int?): Flow<List<Meal>> = recent
        override suspend fun restaurantSuggestions(userId: Long): Result<List<String>> = error("not scripted")
    }

    private val meal = Meal(userId = 1, restaurantName = "Bao Bar", mealType = "lunch", cost = 14.5, dateEpochSeconds = 0)

    @Test
    fun should_return_the_value_when_the_result_succeeds() = runTest {
        val facade = SwiftMealRepository(ScriptedMeals(Result.success(42L)))

        assertEquals(42L, facade.log(meal))
        facade.update(meal) // Result<Unit> success completes normally
    }

    @Test
    fun should_rethrow_the_same_CoreError_when_the_result_carries_one() = runTest {
        val gate = CoreError.Service("QUOTA", "Daily limit reached")
        val facade = SwiftMealRepository(ScriptedMeals(Result.failure(gate)))

        val thrown = assertFailsWith<CoreError.Service> { facade.log(meal) }
        assertSame(gate, thrown)
    }

    @Test
    fun should_wrap_a_foreign_exception_in_Unknown_when_the_result_carries_one() = runTest {
        val cause = IllegalStateException("driver closed")
        val facade = SwiftMealRepository(ScriptedMeals(Result.failure(cause)))

        val thrown = assertFailsWith<CoreError.Unknown> { facade.log(meal) }
        assertSame(cause, thrown.cause)
    }

    @Test
    fun should_wrap_a_directly_thrown_exception_in_Unknown_when_the_repository_throws() = runTest {
        val cause = IllegalArgumentException("bad id")
        val facade = SwiftMealRepository(ScriptedMeals(Result.success(0L), deleteThrows = cause))

        val thrown = assertFailsWith<CoreError.Unknown> { facade.delete(7) }
        assertSame(cause, thrown.cause)
    }

    @Test
    fun should_leave_a_directly_thrown_CoreError_untouched_when_the_repository_throws() = runTest {
        val facade = SwiftMealRepository(ScriptedMeals(Result.success(0L), deleteThrows = CoreError.Offline))

        val thrown = assertFailsWith<CoreError> { facade.delete(7) }
        assertIs<CoreError.Offline>(thrown)
    }

    @Test
    fun should_propagate_cancellation_unwrapped_when_the_call_is_cancelled() = runTest {
        val cancellation = CancellationException("scope closed")
        val facade = SwiftMealRepository(ScriptedMeals(Result.failure(cancellation)))

        val thrown = assertFailsWith<CancellationException> { facade.log(meal) }
        assertSame(cancellation, thrown)
    }

    @Test
    fun should_pass_the_flow_through_when_observing() {
        val meals = ScriptedMeals(Result.success(0L), recent = flowOf(listOf(meal)))
        val facade = SwiftMealRepository(meals)

        assertSame(meals.recent, facade.observeRecent(userId = 1, limit = 10, windowDays = null))
    }
}
