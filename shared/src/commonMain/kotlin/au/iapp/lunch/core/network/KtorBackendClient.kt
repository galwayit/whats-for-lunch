package au.iapp.lunch.core.network

import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.UserPreferences
import co.touchlab.kermit.Logger
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.client.statement.request
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.serialization.ContentConvertException
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.CancellationException
import kotlinx.io.IOException
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

/** JSON settings shared by the backend client and the AI context column. */
internal object BackendJson {
    val json: Json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        explicitNulls = false
        encodeDefaults = true
    }
}

/**
 * Ktor implementation of [BackendClient]. The engine is injected so tests can
 * use `MockEngine` and each platform its native engine.
 */
internal class KtorBackendClient(
    baseUrl: String,
    private val backendHeaders: BackendHeaders,
    engine: HttpClientEngine,
) : BackendClient {

    private val log = Logger.withTag("Backend")

    private val http = HttpClient(engine) {
        expectSuccess = false
        install(ContentNegotiation) { json(BackendJson.json) }
        install(HttpTimeout) {
            requestTimeoutMillis = REQUEST_TIMEOUT_MS
            connectTimeoutMillis = CONNECT_TIMEOUT_MS
        }
        defaultRequest { url(baseUrl.trimEnd('/') + "/") }
    }

    override suspend fun placesNearby(request: PlacesNearbyRequest): PlacesNearbyResponse =
        post("places-nearby", request)

    override suspend fun placesDetails(placeId: String): PlacesDetailsResponse =
        post("places-details", PlacesDetailsRequest(placeId))

    override suspend fun aiRecommend(request: AiRecommendRequest): AiRecommendation =
        post<AiRecommendRequest, AiRecommendResponse>("ai-recommend", request).recommendation

    override suspend fun groupsCreate(request: GroupsCreateRequest): LunchGroup =
        post<GroupsCreateRequest, GroupResponse>("groups-create", request).group

    override suspend fun groupsPropose(groupId: String, hostPreferences: UserPreferences?): List<GroupProposal> =
        post<GroupsProposeRequest, GroupsProposeResponse>("groups-propose", GroupsProposeRequest(groupId, hostPreferences)).proposals

    override suspend fun groupsConfirm(request: GroupsConfirmRequest): LunchGroup =
        post<GroupsConfirmRequest, GroupResponse>("groups-confirm", request).group

    override suspend fun invitation(code: String): Invitation =
        execute<InvitationResponse> { http.get("invitations") { commonHeaders(); parameter("code", code) } }.invitation

    override suspend fun invitationsRespond(code: String, status: RsvpStatus, displayName: String?): Invitation =
        post<InvitationsRespondRequest, InvitationResponse>("invitations-respond", InvitationsRespondRequest(code, status, displayName)).invitation

    override suspend fun pushRegister(token: String, platform: String) {
        post<PushRegisterRequest, Unit>("push-register", PushRegisterRequest(token, platform))
    }

    override suspend fun accountDelete() {
        execute<Unit> { http.post("account-delete") { commonHeaders() } }
    }

    private suspend inline fun <reified B, reified T> post(path: String, body: B): T = execute {
        http.post(path) {
            commonHeaders()
            contentType(ContentType.Application.Json)
            setBody(body)
        }
    }

    private suspend fun HttpRequestBuilder.commonHeaders() {
        val token = backendHeaders.accessToken() ?: backendHeaders.anonKey
        header("apikey", backendHeaders.anonKey)
        header(HttpHeaders.Authorization, "Bearer $token")
        header("x-app-user-id", backendHeaders.appUserId())
        header("x-timezone", backendHeaders.timeZoneId())
    }

    /**
     * Runs the request and maps the outcome: transport failures become
     * [CoreError.Offline], error envelopes become [CoreError.Gate] or
     * [CoreError.Service], undecodable bodies become `Service(BAD_RESPONSE)`.
     */
    private suspend inline fun <reified T> execute(request: () -> HttpResponse): T {
        val response = try {
            request()
        } catch (e: CancellationException) {
            throw e
        } catch (e: IOException) {
            log.w(e) { "Request failed before a response arrived" }
            throw CoreError.Offline
        }
        if (!response.status.isSuccess()) throw errorFor(response)
        if (T::class == Unit::class) return Unit as T
        return try {
            response.body()
        } catch (e: SerializationException) {
            throw CoreError.Service(BAD_RESPONSE, e.message ?: "Could not read the response")
        } catch (e: ContentConvertException) {
            // ContentNegotiation wraps kotlinx.serialization failures (JsonConvertException).
            throw CoreError.Service(BAD_RESPONSE, e.message ?: "Could not read the response")
        } catch (e: IllegalArgumentException) {
            throw CoreError.Service(BAD_RESPONSE, e.message ?: "Could not read the response")
        }
    }

    private suspend fun errorFor(response: HttpResponse): CoreError {
        val text = response.bodyAsText()
        val body = try {
            BackendJson.json.decodeFromString(ErrorEnvelope.serializer(), text).error
        } catch (e: SerializationException) {
            null
        } catch (e: IllegalArgumentException) {
            null
        }
        val code = body?.code ?: "HTTP_${response.status.value}"
        val message = body?.message?.ifBlank { null } ?: response.status.description
        log.w { "${response.request.url.encodedPath} -> ${response.status.value} $code" }
        return gateFor(code)?.let { CoreError.Gate(it) } ?: CoreError.Service(code, message)
    }

    private fun gateFor(code: String): GateReason? = when (code) {
        "AI_DAILY_LIMIT" -> GateReason.AI_DAILY_LIMIT
        "HOST_REQUIRES_PRO" -> GateReason.HOST_REQUIRES_PRO
        "SIGN_IN_REQUIRED" -> GateReason.SIGN_IN_REQUIRED
        else -> null
    }

    companion object {
        const val BAD_RESPONSE = "BAD_RESPONSE"
        const val REQUEST_TIMEOUT_MS = 30_000L
        const val CONNECT_TIMEOUT_MS = 10_000L
    }
}
