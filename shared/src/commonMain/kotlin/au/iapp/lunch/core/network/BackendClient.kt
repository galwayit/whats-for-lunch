package au.iapp.lunch.core.network

import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.GroupDetails
import au.iapp.lunch.core.model.GroupSuggestion
import au.iapp.lunch.core.model.GroupSuggestionDraft
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.UserPreferences

/**
 * Typed access to the Supabase Edge Functions. Every call either returns the
 * decoded payload or throws a [au.iapp.lunch.core.model.CoreError]:
 * `Gate` for AI_DAILY_LIMIT / HOST_REQUIRES_PRO / SIGN_IN_REQUIRED,
 * `Service` for any other HTTP error, `Offline` when the request never completed.
 */
internal interface BackendClient {
    suspend fun aiConfiguration(): au.iapp.lunch.core.model.AiConfiguration
    suspend fun placesNearby(request: PlacesNearbyRequest): PlacesNearbyResponse
    suspend fun placesDetails(placeId: String): PlacesDetailsResponse
    suspend fun aiRecommend(request: AiRecommendRequest): AiRecommendation
    suspend fun groupsCreate(request: GroupsCreateRequest): LunchGroup
    suspend fun groupsPropose(groupId: String, hostPreferences: UserPreferences?, consentVersion: String?): List<GroupProposal>
    suspend fun groupsConfirm(request: GroupsConfirmRequest): LunchGroup
    suspend fun groupsCancel(groupId: String)
    suspend fun invitation(code: String): Invitation
    suspend fun invitationsRespond(code: String, status: RsvpStatus, displayName: String?): Invitation
    suspend fun invitationsSuggest(code: String, draft: GroupSuggestionDraft, displayName: String?): Invitation
    suspend fun groupSuggestions(groupId: String): List<GroupSuggestion>
    suspend fun reviewSuggestion(groupId: String, suggestionId: String, accept: Boolean): LunchGroup
    suspend fun updateGroupDetails(groupId: String, details: GroupDetails): LunchGroup
    suspend fun groupSafety(request: GroupSafetyRequest) { throw au.iapp.lunch.core.model.CoreError.Service("NOT_CONFIGURED", "Content safety is unavailable") }
    suspend fun pushRegister(token: String, platform: String)
    suspend fun pushUnregister(token: String, platform: String)
    /** POST /account-delete with the user's JWT; the backend removes the auth user and its rows. */
    suspend fun accountDelete(appleAuthorizationCode: String? = null)
}

/**
 * Per-request header values the client reads lazily so sign-in and RevenueCat
 * identity changes are picked up without rebuilding the client.
 */
internal class BackendHeaders(
    val anonKey: String,
    val accessToken: suspend () -> String?,
    val appUserId: () -> String,
    val timeZoneId: () -> String,
)
