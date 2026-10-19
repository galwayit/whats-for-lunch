/**
 * @file GroupRepositoryFlowTest.kt
 * @description The server-backed group flows must end quietly on a failed read: SKIE's Swift
 * bridge and the Android collectors have no error channel, so a thrown exception kills the app.
 * Reproduces the 2026-09-23 start-up crash (Postgres "infinite recursion detected in policy").
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.core.service

import au.iapp.lunch.core.LunchCoreFactory
import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.support.FakeLocationProvider
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class GroupRepositoryFlowTest {
    private val config = CoreConfig(
        supabaseUrl = "https://example.supabase.co",
        supabaseAnonKey = MockBackend.ANON_KEY,
        backendBaseUrl = MockBackend.BASE_URL,
        revenueCatApiKey = "rc-test-key",
        databasePath = TestDb.newPath(),
        isDebug = true,
    )

    private val recursion =
        """{"code":"42P17","details":null,"hint":null,"message":"infinite recursion detected in policy for relation \"groups\""}"""

    private fun core(backend: MockBackend) =
        LunchCoreFactory.start(config, FakeLocationProvider(null), TestClock(), backend.engine)

    @Test
    fun should_end_without_emitting_when_reading_groups_fails() = runTest {
        val backend = MockBackend().route("groups", HttpStatusCode.InternalServerError, recursion)

        val emitted = core(backend).groups.myGroups().toList()

        assertEquals(emptyList(), emitted, "no crash and no fake 'no groups' emission")
    }

    @Test
    fun should_end_without_emitting_when_reading_rsvps_fails() = runTest {
        val backend = MockBackend().route("rsvps", HttpStatusCode.InternalServerError, recursion)

        val emitted = core(backend).groups.rsvps("group-1").toList()

        assertEquals(emptyList(), emitted)
    }

    @Test
    fun should_emit_the_groups_when_the_read_succeeds() = runTest {
        val backend = MockBackend().route(
            "groups",
            body = """[{"id":"g1","host_id":"u1","host_name":"Ray","name":"Friday lunch",
                "scheduled_at":"2026-09-25T02:30:00+00:00","area_lat":-33.87,"area_lng":151.21,
                "radius_km":2.0,"invite_code":"ABC123","created_at":"2026-09-23T02:00:00+00:00"}]""",
        )

        val emitted = core(backend).groups.myGroups().toList()

        assertEquals(listOf("Friday lunch"), emitted.single().map { it.name })
    }
}
