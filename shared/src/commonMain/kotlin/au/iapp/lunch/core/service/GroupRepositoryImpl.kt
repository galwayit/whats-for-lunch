package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.GroupRepository
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.data.coreResult
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.network.BackendClient
import au.iapp.lunch.core.network.GroupsConfirmRequest
import au.iapp.lunch.core.network.GroupsCreateRequest
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.flow.Flow
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

    override fun myGroups(): Flow<List<LunchGroup>> = flow {
        val rows = supabase.from("groups").select {
            filter { exact("cancelled_at", null) }
            order("scheduled_at", io.github.jan.supabase.postgrest.query.Order.ASCENDING)
        }.decodeList<GroupRow>()
        emit(rows.map { it.toGroup() })
    }

    override suspend fun create(name: String, scheduledAtEpochSeconds: Long, area: Location, radiusKm: Double): Result<LunchGroup> =
        coreResult { backend.groupsCreate(GroupsCreateRequest(name, scheduledAtEpochSeconds, area.latitude, area.longitude, radiusKm)) }

    override suspend fun propose(groupId: String): Result<List<GroupProposal>> =
        coreResult { backend.groupsPropose(groupId, users.current.value?.preferences) }

    override suspend fun confirmPlace(groupId: String, restaurant: Restaurant): Result<LunchGroup> =
        coreResult { backend.groupsConfirm(GroupsConfirmRequest(groupId, restaurant.placeId, restaurant.name, restaurant.address)) }

    override suspend fun invitation(code: String): Result<Invitation> = coreResult { backend.invitation(code) }

    override suspend fun respond(code: String, status: RsvpStatus, displayName: String?): Result<Invitation> =
        coreResult { backend.invitationsRespond(code, status, displayName) }

    override fun rsvps(groupId: String): Flow<List<Rsvp>> = flow {
        val rows = supabase.from("rsvps").select { filter { eq("group_id", groupId) } }.decodeList<RsvpRow>()
        emit(rows.map { it.toRsvp() })
    }

    /** No cancel function exists yet and the tables are read-only for clients; see BUILD_NOTES.md. */
    override suspend fun cancel(groupId: String): Result<Unit> =
        Result.failure(CoreError.Service(CANCEL_UNSUPPORTED, "Cancelling a group is not supported by the backend yet"))

    @Serializable
    private data class GroupRow(
        val id: String,
        val host_id: String,
        val host_name: String? = null,
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
            hostName = host_name.orEmpty(),
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
        const val CANCEL_UNSUPPORTED = "GROUP_CANCEL_UNSUPPORTED"

        /** PostgREST renders timestamptz as ISO-8601 with an offset. */
        private fun epochSeconds(timestamp: String): Long = Instant.parse(timestamp).epochSeconds
    }
}
