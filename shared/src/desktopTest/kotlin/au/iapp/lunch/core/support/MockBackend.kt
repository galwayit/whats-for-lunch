package au.iapp.lunch.core.support

import au.iapp.lunch.core.network.BackendHeaders
import au.iapp.lunch.core.network.BackendJson
import au.iapp.lunch.core.network.KtorBackendClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import io.ktor.http.headersOf
import kotlinx.serialization.KSerializer
import java.io.IOException

/**
 * Ktor MockEngine wrapper standing in for the Edge Functions. Routes are keyed by
 * the function name (last path segment); unrouted calls answer 404. Every request
 * is recorded so tests can assert headers and bodies.
 */
internal class MockBackend {
    class Reply(val status: HttpStatusCode, val body: String)

    val requests = mutableListOf<HttpRequestData>()
    private val routes = mutableMapOf<String, (HttpRequestData) -> Reply>()
    private var offline = false

    val engine = MockEngine { request ->
        requests += request
        if (offline) throw IOException("Simulated network failure")
        val name = request.url.encodedPath.substringAfterLast('/')
        val reply = routes[name]?.invoke(request) ?: Reply(HttpStatusCode.NotFound, error("NOT_FOUND", "No route for $name"))
        respond(reply.body, reply.status, headersOf(HttpHeaders.ContentType, "application/json"))
    }

    fun route(name: String, status: HttpStatusCode = HttpStatusCode.OK, body: String) = apply {
        routes[name] = { Reply(status, body) }
    }

    fun <T> route(name: String, serializer: KSerializer<T>, value: T, status: HttpStatusCode = HttpStatusCode.OK) =
        route(name, status, BackendJson.json.encodeToString(serializer, value))

    fun fail(name: String, status: HttpStatusCode, code: String, message: String = "denied") =
        route(name, status, error(code, message))

    /** Every request from now on fails before a response arrives. */
    fun goOffline() = apply { offline = true }
    fun goOnline() = apply { offline = false }

    fun client(headers: BackendHeaders = anonymousHeaders()) = KtorBackendClient(BASE_URL, headers, engine)

    /** Decoded JSON body of the last request, for asserting what the client sent. */
    fun lastBody(): String = (requests.last().body as TextContent).text

    companion object {
        const val BASE_URL = "https://example.test/functions/v1"
        const val ANON_KEY = "anon-key"
        const val APP_USER_ID = "\$RCAnonymousID:test"
        const val TIME_ZONE = "Australia/Sydney"

        fun error(code: String, message: String) = """{"error":{"code":"$code","message":"$message"}}"""

        fun anonymousHeaders() = BackendHeaders(
            anonKey = ANON_KEY,
            accessToken = { null },
            appUserId = { APP_USER_ID },
            timeZoneId = { TIME_ZONE },
        )

        fun signedInHeaders(jwt: String, userId: String) = BackendHeaders(
            anonKey = ANON_KEY,
            accessToken = { jwt },
            appUserId = { userId },
            timeZoneId = { TIME_ZONE },
        )
    }
}
