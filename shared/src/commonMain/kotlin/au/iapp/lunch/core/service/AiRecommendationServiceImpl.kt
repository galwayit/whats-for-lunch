package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.AiRecommendationService
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.api.MealRepository
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.data.DbDispatcher
import au.iapp.lunch.core.data.coreResult
import au.iapp.lunch.core.data.dbResult
import au.iapp.lunch.core.data.dbRead
import au.iapp.lunch.core.db.DbJson
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.db.toRecommendation
import au.iapp.lunch.core.db.toRestaurant
import au.iapp.lunch.core.db.upsert
import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.UserProfile
import au.iapp.lunch.core.network.AiContext
import au.iapp.lunch.core.network.AiRecommendRequest
import au.iapp.lunch.core.network.BackendClient
import au.iapp.lunch.core.network.BackendJson
import kotlinx.coroutines.withContext
import kotlin.time.TimeSource

/**
 * AI recommendations through the backend, persisted like the Flutter
 * AIRepository did: the recommendation row (with its context and a 6 h
 * expiry), feedback rows, and a usage metric per request.
 */
internal class AiRecommendationServiceImpl(
    private val db: LunchDatabase,
    private val backend: BackendClient,
    private val gates: GateService,
    private val users: UserRepository,
    private val meals: MealRepository,
    private val location: LocationProvider,
    private val contextBuilder: AiContextBuilder,
    private val usage: AiUsage,
    private val clock: Clock,
    private val restaurants: au.iapp.lunch.core.api.RestaurantRepository? = null,
) : AiRecommendationService {

    override suspend fun configuration(): Result<au.iapp.lunch.core.model.AiConfiguration> = coreResult { backend.aiConfiguration() }

    override suspend fun recommend(cravings: String?, maxResults: Int, candidates: List<Restaurant>, consentVersion: String?): Result<AiRecommendation> {
        if (consentVersion.isNullOrBlank()) return Result.failure(CoreError.Service("AI_CONSENT_REQUIRED", "AI data sharing consent is required"))
        val user = users.current.value ?: return Result.failure(CoreError.Service(NO_USER, "No local user exists yet"))
        val gate = gates.canRequestAi()
        if (!gate.allowed) return Result.failure(CoreError.Gate(gate.reason))

        val pool = coreResult {
            if (candidates.isNotEmpty()) candidates else {
                val here = location.current().getOrThrow()
                val nearby = backend.placesNearby(au.iapp.lunch.core.network.PlacesNearbyRequest(
                    lat = here.latitude, lng = here.longitude, radiusKm = user.preferences.maxTravelDistance,
                )).restaurants
                au.iapp.lunch.core.engine.RecommendationEngineImpl().applyPreferenceFilters(nearby, user.preferences)
            }
        }.getOrElse { return Result.failure(it) }.let {
            // Explicit candidates (including an existing Home pick) must obey the
            // same current preferences as candidates fetched for this request.
            au.iapp.lunch.core.engine.RecommendationEngineImpl().applyPreferenceFilters(it, user.preferences)
        }
        if (pool.isEmpty()) return Result.failure(CoreError.Service("NO_CANDIDATES", "No nearby places match your preferences"))
        val context = buildContext(user)
        // Full objects stay here; the backend only needs the fields its prompt and dietary
        // filter read, and 20 full candidates (reviews, hours, photos) exceed its body limit.
        val chosen = pool.take(MAX_CANDIDATES)
        val request = AiRecommendRequest(
            cravings = cravings?.trim()?.ifEmpty { null },
            maxResults = maxResults,
            context = context,
            candidates = chosen.map { it.forAiRequest() },
            aiConsentVersion = consentVersion,
        )
        val started = TimeSource.Monotonic.markNow()
        val result = coreResult { backend.aiRecommend(request) }
        val elapsedMs = started.elapsedNow().inWholeMilliseconds

        return result.fold(
            onSuccess = { recommendation ->
                // The backend echoes the slim candidates it was given; put the full objects back.
                val byId = chosen.associateBy { it.placeId }
                val local = recommendation.copy(
                    userId = user.id,
                    restaurants = recommendation.restaurants.map { byId[it.placeId] ?: it },
                )
                restaurants?.cacheAll(chosen + local.restaurants)
                persist(local, chosen, context)
                usage.record(user.id, AiUsage.RECOMMENDATION, elapsedMs, successful = true, errorMessage = null)
                Result.success(local)
            },
            onFailure = { error ->
                usage.record(user.id, AiUsage.RECOMMENDATION, elapsedMs, successful = false, errorMessage = error.metricLabel())
                Result.failure(error)
            },
        )
    }

    override suspend fun history(userId: Long, limit: Int): Result<List<AiRecommendation>> = coreResult {
        val rows = dbRead { db.aiRecommendationsQueries.selectRecentByUser(userId, limit.toLong()).executeAsList() }
        val ids = rows.flatMap { DbJson.stringList(it.recommended_restaurant_ids) }.distinct()
        val stored = if (ids.isEmpty()) emptyMap() else
            dbRead { db.restaurantsQueries.selectByPlaceIds(ids).executeAsList().associate { it.place_id to it.toRestaurant() } }
        val restaurants = ids.mapNotNull { id ->
            val place = this@AiRecommendationServiceImpl.restaurants?.cached(id)
                ?: stored[id]?.takeIf { it.name != "Saved place" }
                ?: this@AiRecommendationServiceImpl.restaurants?.details(id)?.getOrNull()
            place?.let { id to it }
        }.toMap()
        rows.map { it.toRecommendation(restaurants) }
    }

    override suspend fun submitFeedback(
        recommendationId: String,
        placeId: String?,
        rating: Int,
        feedback: String?,
        wasSelected: Boolean,
    ): Result<Unit> {
        val stored = dbResult {
            db.transactionWithResult {
                val row = db.aiRecommendationsQueries.selectById(recommendationId).executeAsOneOrNull()
                    ?: throw CoreError.Service(RECOMMENDATION_NOT_FOUND, "Recommendation $recommendationId is not stored locally")
                db.aiRecommendationsQueries.updateFeedback(was_accepted = wasSelected, user_feedback = feedback, id = recommendationId)
                val target = placeId ?: DbJson.stringList(row.recommended_restaurant_ids).firstOrNull()
                if (target != null) {
                    db.aiRecommendationFeedbackQueries.insert(
                        recommendation_id = recommendationId,
                        user_id = row.user_id,
                        place_id = target,
                        rating = rating.toLong(),
                        feedback_text = feedback,
                        was_selected = wasSelected,
                        submitted_at = clock.nowEpochSeconds(),
                    )
                }
                row.user_id
            }
        }
        stored.onSuccess { userId -> usage.record(userId, AiUsage.FEEDBACK, 0, successful = true, errorMessage = null) }
        return stored.map { }
    }

    override suspend fun usedToday(userId: Long): Int = usage.usedToday(userId)

    private suspend fun buildContext(user: UserProfile): AiContext {
        val now = clock.nowEpochSeconds()
        val recent = meals.inRange(user.id, now - RECENT_MEALS_WINDOW_SECONDS, now + 1).getOrDefault(emptyList())
        val here = location.current().getOrNull()
        return contextBuilder.build(user.preferences, recent, here)
    }

    /** Stores the recommendation and makes sure every referenced restaurant is in the cache for [history]. */
    private suspend fun persist(recommendation: AiRecommendation, candidates: List<Restaurant>, context: AiContext) {
        withContext(DbDispatcher) {
            val now = clock.nowEpochSeconds()
            db.transaction {
                (candidates + recommendation.restaurants).distinctBy { it.placeId }.forEach { db.restaurantsQueries.upsert(it, now) }
                db.aiRecommendationsQueries.upsert(
                    id = recommendation.id,
                    user_id = recommendation.userId,
                    recommended_restaurant_ids = DbJson.encode(recommendation.restaurants.map { it.placeId }),
                    reasoning = recommendation.reasoning,
                    factor_weights = DbJson.encode(recommendation.factorWeights),
                    overall_confidence = recommendation.overallConfidence,
                    user_context = BackendJson.json.encodeToString(AiContext.serializer(), context),
                    generated_at = recommendation.generatedAtEpochSeconds.takeIf { it > 0 } ?: now,
                    was_accepted = recommendation.wasAccepted,
                    user_feedback = recommendation.userFeedback,
                    metadata = "{}",
                    expires_at = now + EXPIRY_SECONDS,
                )
            }
        }
    }

    /**
     * The subset of a restaurant the backend prompt (`prompt.ts`) and dietary filter (`dietary.ts`)
     * read. Reviews, opening hours, photo references and score maps are dropped: they are never
     * sent to an AI provider and twenty full candidates exceeded the backend's request body limit.
     */
    private fun Restaurant.forAiRequest(): Restaurant = Restaurant(
        placeId = placeId,
        name = name,
        location = location,
        address = address,
        distanceFromUser = distanceFromUser,
        rating = rating,
        reviewCount = reviewCount,
        priceLevel = priceLevel,
        cuisineType = cuisineType,
        cuisineTypes = cuisineTypes,
        supportedDietaryRestrictions = supportedDietaryRestrictions,
        allergenInfo = allergenInfo,
        hasVerifiedDietaryInfo = hasVerifiedDietaryInfo,
        features = features,
        averageMealCost = averageMealCost,
        valueScore = valueScore,
    )

    /** Short diagnostic stored in `a_i_usage_metrics.error_message`; gates have no message, only a reason. */
    private fun Throwable.metricLabel(): String = when (this) {
        is CoreError.Gate -> "GATE_${reason.name}"
        is CoreError.Offline -> "OFFLINE"
        is CoreError.Service -> "$code: $message"
        else -> message ?: this::class.simpleName ?: "UNKNOWN"
    }

    companion object {
        const val NO_USER = "NO_USER"
        const val RECOMMENDATION_NOT_FOUND = "RECOMMENDATION_NOT_FOUND"
        const val MAX_CANDIDATES = 20
        const val EXPIRY_SECONDS = 6 * 60 * 60L
        const val RECENT_MEALS_WINDOW_SECONDS = 7 * 86_400L
    }
}
