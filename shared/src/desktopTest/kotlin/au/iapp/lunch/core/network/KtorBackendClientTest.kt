package au.iapp.lunch.core.network

import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.Samples
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

/** One success and one gate/error case per endpoint group, plus the cross-cutting header and failure mapping. */
class KtorBackendClientTest {
    private val backend = MockBackend()
    private val client = backend.client()

    private val nearbyRequest = PlacesNearbyRequest(lat = -33.87, lng = 151.21, radiusKm = 5.0, query = "sushi", maxPrice = 2, minRating = 4.0)
    private val aiRequest = AiRecommendRequest(
        cravings = "light",
        maxResults = 3,
        context = AiContext(
            mealType = "lunch",
            budgetRange = "$$",
            dietaryPreferences = DietaryContext(emptyList(), emptyList()),
            recentMeals = emptyList(),
            location = LocationContext(false, null, null),
            temporal = TemporalContext(12, 3, false),
            preferenceScores = emptyMap(),
        ),
        candidates = listOf(Samples.restaurant()),
    )

    // ---- headers and transport ----

    @Test
    fun anonymous_requests_carry_the_anon_key_app_user_id_and_time_zone() = runTest {
        backend.route("places-nearby", PlacesNearbyResponse.serializer(), PlacesNearbyResponse(emptyList()))

        client.placesNearby(nearbyRequest)

        val request = backend.requests.single()
        assertEquals(HttpMethod.Post, request.method)
        assertEquals("${MockBackend.BASE_URL}/places-nearby", request.url.toString())
        assertEquals(MockBackend.ANON_KEY, request.headers["apikey"])
        assertEquals("Bearer ${MockBackend.ANON_KEY}", request.headers["Authorization"])
        assertEquals(MockBackend.APP_USER_ID, request.headers["x-app-user-id"])
        assertEquals(MockBackend.TIME_ZONE, request.headers["x-timezone"])
        assertTrue(backend.lastBody().contains("\"radiusKm\":5.0"))
    }

    @Test
    fun signed_in_requests_send_the_user_jwt_as_bearer() = runTest {
        backend.route("push-register", body = """{"ok":true}""")

        val signedIn = backend.client(MockBackend.signedInHeaders("jwt-123", "user-1"))
        signedIn.pushRegister("token-1", "ios")

        val request = backend.requests.single()
        assertEquals("Bearer jwt-123", request.headers["Authorization"])
        assertEquals(MockBackend.ANON_KEY, request.headers["apikey"])
        assertEquals("user-1", request.headers["x-app-user-id"])
    }

    @Test
    fun network_failures_map_to_Offline() = runTest {
        backend.goOffline()

        val error = runCatching { client.placesDetails("p1") }.exceptionOrNull()

        assertIs<CoreError.Offline>(error)
    }

    @Test
    fun undecodable_bodies_map_to_BAD_RESPONSE() = runTest {
        backend.route("places-details", body = """{"unexpected":true}""")

        val error = runCatching { client.placesDetails("p1") }.exceptionOrNull()

        assertEquals(KtorBackendClient.BAD_RESPONSE, assertIs<CoreError.Service>(error).code)
    }

    @Test
    fun unknown_http_errors_use_the_status_as_code() = runTest {
        backend.route("places-details", HttpStatusCode.BadGateway, "upstream down")

        val error = assertIs<CoreError.Service>(runCatching { client.placesDetails("p1") }.exceptionOrNull())

        assertEquals("HTTP_502", error.code)
    }

    // ---- places ----

    @Test
    fun places_success() = runTest {
        backend.route("places-nearby", PlacesNearbyResponse.serializer(), PlacesNearbyResponse(listOf(Samples.restaurant()), cached = true, fetchedAt = 5))
        backend.route("places-details", PlacesDetailsResponse.serializer(), PlacesDetailsResponse(Samples.restaurant(), listOf(Samples.review())))

        val nearby = client.placesNearby(nearbyRequest)
        val details = client.placesDetails("place-1")

        assertEquals("Sample Sushi", nearby.restaurants.single().name)
        assertTrue(nearby.cached)
        assertEquals("r-1", details.reviews.single().reviewId)
        assertTrue(backend.lastBody().contains("\"placeId\":\"place-1\""))
    }

    @Test
    fun places_service_error() = runTest {
        backend.fail("places-nearby", HttpStatusCode.InternalServerError, "PLACES_UPSTREAM", "Places API failed")

        val error = runCatching { client.placesNearby(nearbyRequest) }.exceptionOrNull()

        assertEquals(CoreError.Service("PLACES_UPSTREAM", "Places API failed"), error)
    }

    // ---- ai ----

    @Test
    fun ai_success() = runTest {
        backend.route("ai-recommend", AiRecommendResponse.serializer(), AiRecommendResponse(Samples.recommendation()))

        val recommendation = client.aiRecommend(aiRequest)

        assertEquals("rec-1", recommendation.id)
        assertEquals(listOf("place-1"), recommendation.restaurants.map { it.placeId })
        assertTrue(backend.lastBody().contains("\"cravings\":\"light\""))
    }

    @Test
    fun ai_daily_limit_is_a_gate() = runTest {
        backend.route("ai-recommend", HttpStatusCode.PaymentRequired, """{"error":{"code":"AI_DAILY_LIMIT","message":"Quota","resetsAt":1788393600}}""")

        val error = runCatching { client.aiRecommend(aiRequest) }.exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.AI_DAILY_LIMIT), error)
    }

    // ---- groups ----

    @Test
    fun groups_success() = runTest {
        backend.route("groups-create", GroupResponse.serializer(), GroupResponse(Samples.group()), HttpStatusCode.Created)
        backend.route("groups-propose", GroupsProposeResponse.serializer(), GroupsProposeResponse(listOf(GroupProposal(Samples.restaurant(), listOf("close")))))
        backend.route("groups-confirm", GroupResponse.serializer(), GroupResponse(Samples.group().copy(placeId = "place-1")))
        backend.route("groups-cancel", body = "")

        val created = client.groupsCreate(GroupsCreateRequest("Friday team lunch", 1_788_600_000, -33.87, 151.21, 2.0))
        val proposals = client.groupsPropose("group-1", hostPreferences = null, consentVersion = "preview-ai-v2")
        val confirmed = client.groupsConfirm(GroupsConfirmRequest("group-1", "place-1", "Sample Sushi", "1 George St"))
        client.groupsCancel("group-1")

        assertEquals("ABCD1234", created.inviteCode)
        assertEquals(listOf("close"), proposals.single().reasons)
        assertEquals("place-1", confirmed.placeId)
        assertTrue(backend.lastBody().contains("\"groupId\":\"group-1\""))
    }

    @Test
    fun groups_host_requires_pro_is_a_gate() = runTest {
        backend.fail("groups-create", HttpStatusCode.Forbidden, "HOST_REQUIRES_PRO")

        val error = runCatching { client.groupsCreate(GroupsCreateRequest("x", 1, 0.0, 0.0, 1.0)) }.exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.HOST_REQUIRES_PRO), error)
    }

    // ---- invitations ----

    @Test
    fun invitations_success() = runTest {
        backend.route("invitations", InvitationResponse.serializer(), InvitationResponse(Samples.invitation()))
        backend.route("invitations-respond", InvitationResponse.serializer(), InvitationResponse(Samples.invitation(RsvpStatus.ACCEPTED), guestToken = "guest-1"))

        val invitation = client.invitation("ABCD1234")
        val responded = client.invitationsRespond("ABCD1234", RsvpStatus.ACCEPTED, "Sam")

        val get = backend.requests.first()
        assertEquals(HttpMethod.Get, get.method)
        assertEquals("ABCD1234", get.url.parameters["code"])
        assertEquals("Kim", invitation.attendees.single().displayName)
        assertEquals(RsvpStatus.ACCEPTED, responded.myStatus)
        assertTrue(backend.lastBody().contains("\"status\":\"accepted\""))
    }

    @Test
    fun invitations_sign_in_required_is_a_gate() = runTest {
        backend.fail("invitations-respond", HttpStatusCode.Unauthorized, "SIGN_IN_REQUIRED")

        val error = runCatching { client.invitationsRespond("ABCD1234", RsvpStatus.DECLINED, null) }.exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.SIGN_IN_REQUIRED), error)
    }

    @Test
    fun guest_capability_survives_client_restart_and_is_scoped_to_invite_and_session() = runTest {
        val tokens = MemoryGuestTokenStore()
        val token = "a".repeat(64)
        backend.route("invitations-respond", InvitationResponse.serializer(), InvitationResponse(Samples.invitation(RsvpStatus.ACCEPTED), guestToken = token))
        backend.route("invitations", InvitationResponse.serializer(), InvitationResponse(Samples.invitation()))
        val initial = KtorBackendClient(MockBackend.BASE_URL, MockBackend.anonymousHeaders(), backend.engine, tokens)
        initial.invitationsRespond("ABCD1234", RsvpStatus.ACCEPTED, "Sam")
        val restarted = KtorBackendClient(MockBackend.BASE_URL, MockBackend.anonymousHeaders(), backend.engine, tokens)
        restarted.invitation("abcd1234")
        assertEquals(token, backend.requests.last().headers["x-guest-token"])
        restarted.invitation("EFGH5678")
        assertEquals(null, backend.requests.last().headers["x-guest-token"])
        val signedIn = KtorBackendClient(MockBackend.BASE_URL, MockBackend.signedInHeaders("jwt", "user-1"), backend.engine, tokens)
        signedIn.invitation("ABCD1234")
        assertEquals(null, backend.requests.last().headers["x-guest-token"])
    }

    @Test
    fun suggestions_preserve_guest_capability_and_planning_fields_through_json() = runTest {
        val tokens = MemoryGuestTokenStore()
        val token = "c".repeat(64)
        val group = Samples.invitation().group.copy(hostName = "Sam", budgetPerPersonMinor = 2550, paymentArrangement = "split_equally", paymentMethod = "card")
        val suggestion = au.iapp.lunch.core.model.GroupSuggestion("suggestion", group.id, "Guest", "Cafe", "10 Test Lane", 1900000000L, "Hi", "pending", 1800000000L)
        val invite = Samples.invitation().copy(group = group, mySuggestion = suggestion)
        backend.route("invitations-suggest", InvitationResponse.serializer(), InvitationResponse(invite, token))
        backend.route("invitations", InvitationResponse.serializer(), InvitationResponse(invite))
        val guest = KtorBackendClient(MockBackend.BASE_URL, MockBackend.anonymousHeaders(), backend.engine, tokens)
        val result = guest.invitationsSuggest("ABCD1234", au.iapp.lunch.core.model.GroupSuggestionDraft("Cafe", "10 Test Lane", 1900000000L, "Hi"), "Guest")
        assertEquals(invite, result)
        assertTrue(backend.lastBody().contains("\"suggestion\""))
        guest.invitation("ABCD1234")
        assertEquals(token, backend.requests.last().headers["x-guest-token"])
        guest.invitation("EFGH5678")
        assertEquals(null, backend.requests.last().headers["x-guest-token"])
    }

    @Test
    fun safety_report_uses_only_this_invitations_capability_and_preserves_failure() = runTest {
        val tokens = MemoryGuestTokenStore()
        val token = "d".repeat(64)
        backend.route("invitations", InvitationResponse.serializer(), InvitationResponse(Samples.invitation(), token))
        backend.route("groups-safety", body = """{"recorded":true,"reportId":null}""")
        val guest = KtorBackendClient(MockBackend.BASE_URL, MockBackend.anonymousHeaders(), backend.engine, tokens)
        guest.invitation("ABCD1234")
        val report = GroupSafetyRequest("ABCD1234", "group", null, "report_block", "spam")
        guest.groupSafety(report)
        assertEquals(token, backend.requests.last().headers["x-guest-token"])
        assertTrue(backend.lastBody().contains("\"action\":\"report_block\""))
        guest.groupSafety(report.copy(code = "EFGH5678"))
        assertEquals(null, backend.requests.last().headers["x-guest-token"])
        backend.fail("groups-safety", HttpStatusCode.ServiceUnavailable, "SERVICE_UNAVAILABLE")
        assertTrue(runCatching { guest.groupSafety(report) }.isFailure)
    }

    // ---- push and account ----

    @Test
    fun push_and_account_success() = runTest {
        backend.route("push-register", body = """{"ok":true}""")
        backend.route("account-delete", body = """{"deleted":true}""")

        client.pushRegister("token-1", "android")
        client.accountDelete()

        assertEquals(listOf("push-register", "account-delete"), backend.requests.map { it.url.encodedPath.substringAfterLast('/') })
        assertTrue((backend.requests.first().body as io.ktor.http.content.TextContent).text.contains("\"platform\":\"android\""))
    }

    @Test
    fun account_delete_without_a_session_is_a_gate() = runTest {
        backend.fail("account-delete", HttpStatusCode.Unauthorized, "SIGN_IN_REQUIRED")

        val error = runCatching { client.accountDelete() }.exceptionOrNull()

        assertEquals(CoreError.Gate(GateReason.SIGN_IN_REQUIRED), error)
    }

    @Test
    fun ai_configuration_returns_current_disclosure_and_group_request_carries_its_version() = runTest {
        backend.route("ai-config", body = """{"consentVersion":"ai-v2-new","providers":[{"name":"Example AI","privacyUrl":"https://example.com/privacy"}]}""")
        val config = client.aiConfiguration()
        assertEquals(HttpMethod.Get, backend.requests.single().method)
        assertEquals("ai-v2-new", config.consentVersion)
        assertEquals("Example AI", config.providers.single().name)
        backend.route("groups-propose", GroupsProposeResponse.serializer(), GroupsProposeResponse(emptyList()))
        client.groupsPropose("group-1", null, config.consentVersion)
        assertTrue(backend.lastBody().contains("\"aiConsentVersion\":\"ai-v2-new\""))
    }
}
