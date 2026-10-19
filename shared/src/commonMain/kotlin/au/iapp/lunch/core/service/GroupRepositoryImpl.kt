package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.GroupRepository
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.data.coreResult
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.GroupDetails
import au.iapp.lunch.core.model.GroupSuggestion
import au.iapp.lunch.core.model.GroupSuggestionDraft
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.network.BackendClient
import au.iapp.lunch.core.network.GroupsConfirmRequest
import au.iapp.lunch.core.network.GroupsCreateRequest
import co.touchlab.kermit.Logger
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flow
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable

/**
 * Group lunches: writes go through the Edge Functions (which hold the Pro and
 * host checks); reads come straight from the `groups` / `rsvps` tables under
 * row-level security, fetched once per collection (the apps poll on resume).
 */
internal class GroupRepositoryImpl(
    private val backend: BackendClient,
    private val supabase: SupabaseClient,
    private val users: UserRepository,
) : GroupRepository {

    private val log = Logger.withTag("Groups")

    // Both flows reach the server, so they can fail. A flow must never throw here: SKIE's Swift
    // bridge and the Android collectors have no error channel, and an escaping exception
    // terminates the app. A failed read ends the flow without emitting; the screen keeps what
    // it had and re-collects when it reappears.

    override fun myGroups(): Flow<List<LunchGroup>> = flow { emit(loadGroups().getOrThrow()) }.catch { log.w(it) { "Reading groups failed" } }

    override suspend fun loadGroups(): Result<List<LunchGroup>> = coreResult {
        val rows = supabase.from("groups").select {
            filter { exact("cancelled_at", null) }
            order("scheduled_at", io.github.jan.supabase.postgrest.query.Order.ASCENDING)
        }.decodeList<GroupRow>()
        rows.map { it.toGroup() }
    }

    override suspend fun create(name: String, scheduledAtEpochSeconds: Long, area: Location, radiusKm: Double, details: GroupDetails): Result<LunchGroup> =
        coreResult { backend.groupsCreate(GroupsCreateRequest(name, scheduledAtEpochSeconds, area.latitude, area.longitude, radiusKm, details)) }

    override suspend fun propose(groupId: String, consentVersion: String?): Result<List<GroupProposal>> =
        coreResult {
            if (consentVersion.isNullOrBlank()) throw au.iapp.lunch.core.model.CoreError.Service("AI_CONSENT_REQUIRED", "AI data sharing consent is required")
            backend.groupsPropose(groupId, users.current.value?.preferences, consentVersion)
        }

    override suspend fun confirmPlace(groupId: String, restaurant: Restaurant): Result<LunchGroup> =
        coreResult { backend.groupsConfirm(GroupsConfirmRequest(groupId, restaurant.placeId, restaurant.name, restaurant.address)) }

    override suspend fun invitation(code: String): Result<Invitation> = coreResult { backend.invitation(code) }

    override suspend fun respond(code: String, status: RsvpStatus, displayName: String?): Result<Invitation> =
        coreResult { backend.invitationsRespond(code, status, displayName) }

    override suspend fun suggest(code: String, draft: GroupSuggestionDraft, displayName: String?): Result<Invitation> = coreResult { backend.invitationsSuggest(code, draft, displayName) }
    override suspend fun suggestions(groupId: String): Result<List<GroupSuggestion>> = coreResult { backend.groupSuggestions(groupId) }
    override suspend fun reviewSuggestion(groupId: String, suggestionId: String, accept: Boolean): Result<LunchGroup> = coreResult { backend.reviewSuggestion(groupId, suggestionId, accept) }
    override suspend fun updateDetails(groupId: String, details: GroupDetails): Result<LunchGroup> = coreResult { backend.updateGroupDetails(groupId, details) }
    override suspend fun safetyAction(code: String, targetKind: String, targetId: String?, action: String, reason: String): Result<Unit> =
        coreResult { backend.groupSafety(au.iapp.lunch.core.network.GroupSafetyRequest(code, targetKind, targetId, action, reason)) }

    override fun rsvps(groupId: String): Flow<List<Rsvp>> = flow { emit(loadRsvps(groupId).getOrThrow()) }.catch { log.w(it) { "Reading RSVPs failed" } }

    override suspend fun loadRsvps(groupId: String): Result<List<Rsvp>> = coreResult {
        val rows = supabase.from("rsvps").select { filter { eq("group_id", groupId) } }.decodeList<RsvpRow>()
        rows.map { it.toRsvp() }
    }

    override suspend fun cancel(groupId: String): Result<Unit> =
        coreResult { backend.groupsCancel(groupId) }

    @Serializable
    private data class GroupRow(
        val id: String,
        val host_id: String,
        val host_name: String? = null,
        val budget_per_person_minor: Long? = null,
        val currency_code: String = "AUD",
        val payment_arrangement: String = "undecided",
        val payment_method: String = "undecided",
        val name: String,
        val scheduled_at: String,
        val area_lat: Double,
        val area_lng: Double,
        val radius_km: Double,
        val place_id: String? = null,
        val place_name: String? = null,
        val place_address: String? = null,
        val invite_code: String,
        val created_at: String,
    ) {
        fun toGroup() = LunchGroup(
            id = id,
            hostId = host_id,
            hostName = host_name?.takeIf { it.isNotBlank() } ?: "Host name not provided",
            budgetPerPersonMinor = budget_per_person_minor,
            currencyCode = currency_code,
            paymentArrangement = payment_arrangement,
            paymentMethod = payment_method,
            name = name,
            scheduledAtEpochSeconds = epochSeconds(scheduled_at),
            areaLatitude = area_lat,
            areaLongitude = area_lng,
            radiusKm = radius_km,
            placeId = place_id,
            placeName = place_name,
            placeAddress = place_address,
            inviteCode = invite_code,
            createdAtEpochSeconds = epochSeconds(created_at),
        )
    }

    @Serializable
    private data class RsvpRow(
        val id: String,
        val group_id: String,
        val guest_user_id: String? = null,
        val display_name: String? = null,
        val status: RsvpStatus,
        val responded_at: String? = null,
    ) {
        fun toRsvp() = Rsvp(
            id = id,
            groupId = group_id,
            guestUserId = guest_user_id,
            displayName = display_name.orEmpty(),
            status = status,
            respondedAtEpochSeconds = responded_at?.let { epochSeconds(it) },
        )
    }

    companion object {
        /** PostgREST renders timestamptz as ISO-8601 with an offset. */
        private fun epochSeconds(timestamp: String): Long = Instant.parse(timestamp).epochSeconds
    }
}
