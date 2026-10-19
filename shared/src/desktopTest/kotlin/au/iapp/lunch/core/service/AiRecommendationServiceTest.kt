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
import kotlinx.coroutines.flow.first
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
    private val gates = GateServiceImpl(entitlements, FakeAuthRepository(au.iapp.lunch.core.model.AuthSession("user-1", null, "Sam")), users, usage)
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
    fun declining_consent_makes_no_provider_requests() = runTest {
        val error = service.recommend("lunch", 3, emptyList(), consentVersion = null).exceptionOrNull()
        assertEquals("AI_CONSENT_REQUIRED", assertIs<CoreError.Service>(error).code)
        assertTrue(backend.requests.isEmpty())
    }

    @Test
    fun asking_without_candidates_fetches_places_before_ai() = runTest {
        backend.route("places-nearby", au.iapp.lunch.core.network.PlacesNearbyResponse.serializer(),
            au.iapp.lunch.core.network.PlacesNearbyResponse(candidates))
        serveRecommendation()
        service.recommend("lunch", 3, emptyList(), consentVersion = "preview-ai-v2").getOrThrow()
        assertEquals(listOf("places-nearby", "ai-recommend"), backend.requests.map { it.url.encodedPath.substringAfterLast('/') })
        assertTrue(backend.lastBody().contains("\"aiConsentVersion\":\"preview-ai-v2\""))
        assertTrue(backend.lastBody().contains("place-1"))
    }

    @Test
    fun saved_chain_preference_filters_explicit_candidates_before_ai() = runTest {
        val prefs = users.current.value!!.preferences.copy(includeChains = false)
        users.updatePreferences(prefs).getOrThrow()
        users.current.first { it?.preferences?.includeChains == false }
        serveRecommendation()

        service.recommend("lunch", 3, candidates + Samples.restaurant("hungry-jacks", "Hungry Jack’s"), consentVersion = "preview-ai-v2").getOrThrow()

        assertFalse(backend.lastBody().contains("hungry-jacks"))
        assertTrue(backend.lastBody().contains("place-1"))
        assertTrue(backend.lastBody().contains("\"includeChains\":false"))
    }

    @Test
    fun only_excluded_chains_does_not_call_ai_or_consume_allowance() = runTest {
        users.updatePreferences(users.current.value!!.preferences.copy(includeChains = false)).getOrThrow()
        users.current.first { it?.preferences?.includeChains == false }

        val error = service.recommend(null, 3, listOf(Samples.restaurant("hungry-jacks", "Hungry Jack's Burgers")), consentVersion = "preview-ai-v2").exceptionOrNull()

        assertEquals("NO_CANDIDATES", assertIs<CoreError.Service>(error).code)
        assertTrue(backend.requests.isEmpty())
        assertEquals(0, service.usedToday(1))
    }

    @Test
    fun recommend_persists_the_row_context_usage_and_restaurants() = runTest {
        serveRecommendation()
        meals.log(Meal(userId = 1, mealType = "lunch", cost = 18.5, dateEpochSeconds = clock.now - TestClock.DAY)).getOrThrow()

        val recommendation = service.recommend("light", 3, candidates, consentVersion = "preview-ai-v2").getOrThrow()

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
    fun second_free_request_is_gated_before_places_or_ai_requests() = runTest {
        serveRecommendation()
        service.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").getOrThrow()
        for (pool in listOf(emptyList(), candidates)) {
            val error = service.recommend(null, 3, pool, consentVersion = "preview-ai-v2").exceptionOrNull()
            assertEquals(CoreError.Gate(GateReason.AI_DAILY_LIMIT), error)
        }
        assertEquals(1, backend.requests.size)
        assertEquals(1, service.usedToday(1))
    }

    @Test
    fun server_quota_denial_is_a_gate_even_when_local_usage_is_empty() = runTest {
        backend.fail("ai-recommend", HttpStatusCode.PaymentRequired, "AI_DAILY_LIMIT", "Quota")
        val error = service.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").exceptionOrNull()
        assertEquals(CoreError.Gate(GateReason.AI_DAILY_LIMIT), error)
        assertEquals(0, service.usedToday(1))
    }

    @Test
    fun pro_skips_the_local_gate_and_backend_denials_are_recorded_as_failures() = runTest {
        entitlements.setPro(true)
        usage.record(1, AiUsage.RECOMMENDATION, 1, successful = true, errorMessage = null)
        clock.advance(1)
        backend.fail("ai-recommend", HttpStatusCode.PaymentRequired, "AI_DAILY_LIMIT", "Quota")

        val error = service.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.AI_DAILY_LIMIT), error)
        assertEquals(1, backend.requests.size)
        val failed = db.aiUsageMetricsQueries.selectByUser(1, 10).executeAsList().first()
        assertFalse(failed.was_successful)
        assertEquals("GATE_AI_DAILY_LIMIT", failed.error_message)
    }

    @Test
    fun pro_provider_failure_preserves_access_and_allowance_and_allows_retry() = runTest {
        entitlements.setPro(true)
        backend.fail("ai-recommend", HttpStatusCode.ServiceUnavailable, "AI_UNAVAILABLE", "AI unavailable")

        val error = service.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").exceptionOrNull()

        assertEquals("AI_UNAVAILABLE", assertIs<CoreError.Service>(error).code)
        assertTrue(entitlements.isPro.value)
        assertEquals(0, service.usedToday(1))
        assertTrue(service.history(1, 10).getOrThrow().isEmpty())

        serveRecommendation()
        service.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").getOrThrow()
        assertEquals(1, service.usedToday(1))
        assertEquals(1, service.history(1, 10).getOrThrow().size)
    }

    @Test
    fun history_and_feedback_round_trip_through_the_local_tables() = runTest {
        serveRecommendation()
        service.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").getOrThrow()

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

        val error = noUser.recommend(null, 3, candidates, consentVersion = "preview-ai-v2").exceptionOrNull()

        assertEquals(AiRecommendationServiceImpl.NO_USER, assertIs<CoreError.Service>(error).code)
    }
}
