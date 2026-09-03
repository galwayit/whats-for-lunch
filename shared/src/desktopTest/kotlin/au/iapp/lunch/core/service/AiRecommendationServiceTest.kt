package au.iapp.lunch.core.service

import au.iapp.lunch.core.data.MealRepositoryImpl
import au.iapp.lunch.core.data.UserRepositoryImpl
import au.iapp.lunch.core.db.DbJson
import au.iapp.lunch.core.engine.MealDefaultsImpl
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.network.AiContext
import au.iapp.lunch.core.network.AiRecommendResponse
import au.iapp.lunch.core.network.BackendJson
import au.iapp.lunch.core.support.FakeAuthRepository
import au.iapp.lunch.core.support.FakeLocationProvider
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.Samples
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class AiRecommendationServiceTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val clock = TestClock()
    private val db = TestDb.fixture()
    private val backend = MockBackend()
    private val entitlements = FakeEntitlementRepository()
    private val users = UserRepositoryImpl(db, clock, scope)
    private val meals = MealRepositoryImpl(db, clock)
    private val usage = AiUsage(db, clock)
    private val gates = GateServiceImpl(entitlements, FakeAuthRepository(), users, usage)
    private val service = AiRecommendationServiceImpl(
        db = db,
        backend = backend.client(),
        gates = gates,
        users = users,
        meals = meals,
        location = FakeLocationProvider(Samples.sydney),
        contextBuilder = AiContextBuilder(MealDefaultsImpl(), clock),
        usage = usage,
        clock = clock,
    )

    private val candidates = listOf(Samples.restaurant("place-1", "Sample Sushi"), Samples.restaurant("place-2", "Second Salad"))

    @AfterTest
    fun tearDown() = scope.cancel()

    private fun serveRecommendation() =
        backend.route("ai-recommend", AiRecommendResponse.serializer(), AiRecommendResponse(Samples.recommendation(restaurants = listOf(candidates[1]))))

    @Test
    fun recommend_persists_the_row_context_usage_and_restaurants() = runTest {
        serveRecommendation()
        meals.log(Meal(userId = 1, mealType = "lunch", cost = 18.5, dateEpochSeconds = clock.now - TestClock.DAY)).getOrThrow()

        val recommendation = service.recommend("light", 3, candidates).getOrThrow()

        assertEquals(1L, recommendation.userId, "the backend's userId 0 is replaced by the local id")
        val row = db.aiRecommendationsQueries.selectById("rec-1").executeAsOne()
        assertEquals(1L, row.user_id)
        assertEquals(listOf("place-2"), DbJson.stringList(row.recommended_restaurant_ids))
        assertEquals(clock.now + AiRecommendationServiceImpl.EXPIRY_SECONDS, row.expires_at)
        assertEquals(clock.now, row.generated_at, "a zero generatedAt falls back to the clock")

        val context = BackendJson.json.decodeFromString(AiContext.serializer(), row.user_context)
        assertEquals("$$", context.budgetRange)
        assertTrue(context.location.hasLocation)
        assertEquals(listOf("Lunch: $18.50 (1d ago)"), context.recentMeals)
        assertTrue(backend.lastBody().contains("\"cravings\":\"light\""))

        assertNotNull(db.restaurantsQueries.selectByPlaceId("place-1").executeAsOneOrNull())
        assertNotNull(db.restaurantsQueries.selectByPlaceId("place-2").executeAsOneOrNull())
        val metric = db.aiUsageMetricsQueries.selectByUser(1, 10).executeAsList().single()
        assertEquals(AiUsage.RECOMMENDATION, metric.request_type)
        assertTrue(metric.was_successful)
        assertEquals(1, service.usedToday(1))
    }

    @Test
    fun second_free_request_of_the_day_is_gated_locally_without_a_round_trip() = runTest {
        serveRecommendation()
        service.recommend(null, 3, candidates).getOrThrow()

        val error = service.recommend(null, 3, candidates).exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.AI_DAILY_LIMIT), error)
        assertEquals(1, backend.requests.size)
    }

    @Test
    fun pro_skips_the_local_gate_and_backend_denials_are_recorded_as_failures() = runTest {
        entitlements.setPro(true)
        usage.record(1, AiUsage.RECOMMENDATION, 1, successful = true, errorMessage = null)
        clock.advance(1)
        backend.fail("ai-recommend", HttpStatusCode.PaymentRequired, "AI_DAILY_LIMIT", "Quota")

        val error = service.recommend(null, 3, candidates).exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.AI_DAILY_LIMIT), error)
        assertEquals(1, backend.requests.size)
        val failed = db.aiUsageMetricsQueries.selectByUser(1, 10).executeAsList().first()
        assertFalse(failed.was_successful)
        assertEquals("GATE_AI_DAILY_LIMIT", failed.error_message)
    }

    @Test
    fun history_and_feedback_round_trip_through_the_local_tables() = runTest {
        serveRecommendation()
        service.recommend(null, 3, candidates).getOrThrow()

        val history = service.history(1, 10).getOrThrow()
        assertEquals("rec-1", history.single().id)
        assertEquals("Second Salad", history.single().restaurants.single().name)

        clock.advance(1)
        service.submitFeedback("rec-1", placeId = null, rating = 4, feedback = "good", wasSelected = true).getOrThrow()

        val updated = db.aiRecommendationsQueries.selectById("rec-1").executeAsOne()
        assertTrue(updated.was_accepted)
        assertEquals("good", updated.user_feedback)
        val feedback = db.aiRecommendationFeedbackQueries.selectByRecommendation("rec-1").executeAsList().single()
        assertEquals("place-2", feedback.place_id, "no placeId means the first recommended place")
        assertEquals(4L, feedback.rating)
        assertEquals(listOf(AiUsage.FEEDBACK, AiUsage.RECOMMENDATION), db.aiUsageMetricsQueries.selectByUser(1, 10).executeAsList().map { it.request_type })
        assertTrue(service.history(1, 10).getOrThrow().single().wasAccepted)
    }

    @Test
    fun feedback_for_an_unknown_recommendation_fails_without_writing() = runTest {
        val error = service.submitFeedback("missing", "place-1", 1, null, false).exceptionOrNull()

        assertEquals(AiRecommendationServiceImpl.RECOMMENDATION_NOT_FOUND, assertIs<CoreError.Service>(error).code)
        assertTrue(db.aiUsageMetricsQueries.selectByUser(1, 10).executeAsList().isEmpty())
    }

    @Test
    fun recommend_without_a_local_user_fails_with_NO_USER() = runTest {
        val emptyDb = TestDb.empty()
        val noUser = AiRecommendationServiceImpl(
            emptyDb, backend.client(), gates, UserRepositoryImpl(emptyDb, clock, scope), MealRepositoryImpl(emptyDb, clock),
            FakeLocationProvider(null), AiContextBuilder(MealDefaultsImpl(), clock), AiUsage(emptyDb, clock), clock,
        )

        val error = noUser.recommend(null, 3, candidates).exceptionOrNull()

        assertEquals(AiRecommendationServiceImpl.NO_USER, assertIs<CoreError.Service>(error).code)
    }
}
