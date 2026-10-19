package au.iapp.lunch.core.data

import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.network.PlacesDetailsResponse
import au.iapp.lunch.core.network.PlacesNearbyResponse
import au.iapp.lunch.core.support.MockBackend
import au.iapp.lunch.core.support.Samples
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RestaurantRepositoryTest {
    private val clock = TestClock()
    private val db = TestDb.fixture()
    private val backend = MockBackend()
    private val repo = RestaurantRepositoryImpl(db, backend.client(), clock)

    private val near = Samples.restaurant("near", "Near Sushi", latitude = -33.8700, longitude = 151.2100)
    private val far = Samples.restaurant("far", "Far Sushi", latitude = -33.9000, longitude = 151.3000)

    private fun serveNearby(vararg restaurants: au.iapp.lunch.core.model.Restaurant) =
        backend.route("places-nearby", PlacesNearbyResponse.serializer(), PlacesNearbyResponse(restaurants.toList()))

    @Test
    fun searchNearby_fetches_then_caches_for_24_hours() = runTest {
        serveNearby(near, far)

        val first = repo.searchNearby(Samples.sydney, radiusKm = 20.0, query = " Sushi ", forceRefresh = false).getOrThrow()
        assertEquals(listOf("near", "far"), first.map { it.placeId })
        assertTrue(backend.lastBody().contains("\"query\":\"Sushi\""))

        val cached = db.restaurantCacheQueries.selectFresh("sushi", -33.869, 151.209, clock.now + TestClock.DAY - 1).executeAsList()
        assertEquals(listOf("near", "far"), cached)
        assertEquals(emptyList(), db.restaurantCacheQueries.selectFresh("sushi", -33.869, 151.209, clock.now + TestClock.DAY).executeAsList())
        assertNotNull(repo.cached("near"))

        val second = repo.searchNearby(Samples.sydney, radiusKm = 20.0, query = "sushi", forceRefresh = false).getOrThrow()
        assertEquals(1, backend.requests.size, "second search must be served from the cache")
        assertEquals(listOf("near", "far"), second.map { it.placeId })
        assertTrue(second.first().distanceFromUser!! < 0.5)
    }

    @Test
    fun cached_results_are_re_filtered_by_radius_from_the_new_point() = runTest {
        serveNearby(near, far)
        repo.searchNearby(Samples.sydney, radiusKm = 20.0, query = "sushi", forceRefresh = false).getOrThrow()

        val tight = repo.searchNearby(Samples.sydney, radiusKm = 1.0, query = "sushi", forceRefresh = false).getOrThrow()

        assertEquals(listOf("near"), tight.map { it.placeId })
        assertEquals(1, backend.requests.size)
    }

    @Test
    fun forceRefresh_and_expiry_go_back_to_the_backend() = runTest {
        serveNearby(near)
        repo.searchNearby(Samples.sydney, 5.0, "sushi", forceRefresh = false).getOrThrow()

        repo.searchNearby(Samples.sydney, 5.0, "sushi", forceRefresh = true).getOrThrow()
        assertEquals(2, backend.requests.size)

        clock.advance(25 * TestClock.HOUR)
        repo.searchNearby(Samples.sydney, 5.0, "sushi", forceRefresh = false).getOrThrow()
        assertEquals(3, backend.requests.size)
    }

    @Test
    fun offline_falls_back_to_stale_rows_for_the_same_key_only() = runTest {
        serveNearby(near)
        repo.searchNearby(Samples.sydney, 5.0, "sushi", forceRefresh = false).getOrThrow()
        clock.advance(25 * TestClock.HOUR)
        backend.goOffline()

        val stale = repo.searchNearby(Samples.sydney, 5.0, "sushi", forceRefresh = false).getOrThrow()
        assertEquals(listOf("near"), stale.map { it.placeId })

        val other = repo.searchNearby(Location(-33.0, 151.0), 5.0, "sushi", forceRefresh = false)
        assertIs<CoreError.Offline>(other.exceptionOrNull())
    }

    @Test
    fun backend_errors_other_than_offline_surface_as_service_errors() = runTest {
        backend.fail("places-nearby", io.ktor.http.HttpStatusCode.InternalServerError, "PLACES_FAILED", "upstream")

        val error = repo.searchNearby(Samples.sydney, 5.0, null, forceRefresh = false).exceptionOrNull()

        assertEquals(CoreError.Service("PLACES_FAILED", "upstream"), error)
    }

    @Test
    fun details_caches_the_restaurant_and_serves_it_offline() = runTest {
        backend.route("places-details", PlacesDetailsResponse.serializer(), PlacesDetailsResponse(near, listOf(Samples.review())))

        assertEquals("Near Sushi", repo.details("near").getOrThrow().name)
        assertEquals(listOf("r-1"), repo.reviews("near").getOrThrow().map { it.reviewId })

        backend.goOffline()
        assertEquals("Near Sushi", repo.details("near").getOrThrow().name)
        assertIs<CoreError.Offline>(repo.details("unknown").exceptionOrNull())
    }

    @Test
    fun google_content_is_displayed_with_attribution_but_only_ids_are_persisted() = runTest {
        val google = near.copy(googleMapsUri = "https://maps.google.com/?q=fixture", photoUrl = "https://example.test/photo")
        serveNearby(google)
        val result = repo.searchNearby(Samples.sydney, 5.0, null, forceRefresh = false).getOrThrow().single()
        assertEquals(google.googleMapsUri, result.googleMapsUri)
        assertEquals("Near Sushi", repo.cached("near")?.name)
        val stored = db.restaurantsQueries.selectByPlaceId("near").executeAsOne()
        assertEquals("Saved place", stored.name)
        assertEquals(null, stored.address)
        assertEquals(null, stored.rating)
        assertEquals(null, stored.photo_reference)
        repo.searchNearby(Samples.sydney, 5.0, null, forceRefresh = false).getOrThrow()
        assertEquals(2, backend.requests.size, "Google searches must fetch current provider data")
        val restarted = RestaurantRepositoryImpl(db, backend.client(), clock)
        assertEquals(null, restarted.cached("near"), "stale provider content must not return after restart")
    }

    @Test
    fun recordInteraction_writes_a_row_with_the_clock_time() = runTest {
        repo.recordInteraction(1, "near", "Near Sushi", "viewed", "discover")

        val row = db.userRestaurantInteractionsQueries.selectByUser(1, 10).executeAsList().single()
        assertEquals("viewed", row.interaction_type)
        assertEquals(clock.now, row.interaction_date)
        assertEquals("discover", row.context)
    }
}
