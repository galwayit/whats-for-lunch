package au.iapp.lunch.core.network

import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.UserPreferences
import kotlinx.serialization.Serializable

/*
 * Wire shapes of the Edge Functions in backend/API.md. Field names are the
 * JSON keys; models reused from the domain already carry camelCase keys.
 */

@Serializable
internal data class PlacesNearbyRequest(
    val lat: Double,
    val lng: Double,
    val radiusKm: Double,
    val query: String? = null,
    val maxPrice: Int? = null,
    val minRating: Double? = null,
)

@Serializable
internal data class PlacesNearbyResponse(
    val restaurants: List<Restaurant>,
    val cached: Boolean = false,
    val fetchedAt: Long = 0,
)

@Serializable
internal data class PlacesDetailsRequest(val placeId: String)

@Serializable
internal data class PlacesDetailsResponse(
    val restaurant: Restaurant,
    val reviews: List<RestaurantReview> = emptyList(),
)

@Serializable
internal data class DietaryContext(
    val restrictions: List<String> = emptyList(),
    val allergies: List<String> = emptyList(),
)

@Serializable
internal data class LocationContext(
    val hasLocation: Boolean,
    val latitude: Double? = null,
    val longitude: Double? = null,
)

@Serializable
internal data class TemporalContext(
    val hour: Int,
    /** ISO weekday, Monday = 1 .. Sunday = 7. */
    val dayOfWeek: Int,
    val isWeekend: Boolean,
)

/** The `context` object of POST /ai-recommend; also persisted as `user_context`. */
@Serializable
internal data class AiContext(
    val mealType: String,
    val budgetRange: String,
    val dietaryPreferences: DietaryContext,
    val recentMeals: List<String>,
    val location: LocationContext,
    val temporal: TemporalContext,
    val preferenceScores: Map<String, Double>,
)

@Serializable
internal data class AiRecommendRequest(
    val cravings: String? = null,
    val maxResults: Int,
    val context: AiContext,
    val candidates: List<Restaurant>,
)

@Serializable
internal data class AiRecommendResponse(val recommendation: AiRecommendation)

@Serializable
internal data class GroupsCreateRequest(
    val name: String,
    val scheduledAt: Long,
    val lat: Double,
    val lng: Double,
    val radiusKm: Double,
)

@Serializable
internal data class GroupsProposeRequest(
    val groupId: String,
    val hostPreferences: UserPreferences? = null,
)

@Serializable
internal data class GroupsProposeResponse(val proposals: List<GroupProposal>)

@Serializable
internal data class GroupsConfirmRequest(
    val groupId: String,
    val placeId: String,
    val placeName: String,
    val placeAddress: String? = null,
)

@Serializable
internal data class GroupResponse(val group: LunchGroup)

@Serializable
internal data class InvitationResponse(
    val invitation: Invitation,
    /** Only for anonymous web guests; the apps are always signed in when they respond. */
    val guestToken: String? = null,
)

@Serializable
internal data class InvitationsRespondRequest(
    val code: String,
    val status: RsvpStatus,
    val displayName: String? = null,
)

@Serializable
internal data class PushRegisterRequest(val token: String, val platform: String)

@Serializable
internal data class ErrorEnvelope(val error: ErrorBody)

@Serializable
internal data class ErrorBody(
    val code: String,
    val message: String = "",
    /** Epoch seconds of the next local midnight, sent with AI_DAILY_LIMIT. */
    val resetsAt: Long? = null,
)
