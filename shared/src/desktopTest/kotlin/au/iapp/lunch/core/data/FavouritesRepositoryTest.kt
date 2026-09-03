package au.iapp.lunch.core.data

import au.iapp.lunch.core.db.upsert
import au.iapp.lunch.core.model.FreeLimits
import au.iapp.lunch.core.model.GateDecision
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.service.AiUsage
import au.iapp.lunch.core.service.FakeEntitlementRepository
import au.iapp.lunch.core.service.GateServiceImpl
import au.iapp.lunch.core.support.FakeAuthRepository
import au.iapp.lunch.core.support.Samples
import au.iapp.lunch.core.support.TestClock
import au.iapp.lunch.core.support.TestDb
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

class FavouritesRepositoryTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val clock = TestClock()
    private val db = TestDb.fixture()
    private val entitlements = FakeEntitlementRepository()
    private val gates = GateServiceImpl(entitlements, FakeAuthRepository(), UserRepositoryImpl(db, clock, scope), AiUsage(db, clock))
    private val repo = FavouritesRepositoryImpl(db, gates, clock)

    @AfterTest
    fun tearDown() = scope.cancel()

    @Test
    fun toggle_adds_then_removes_a_favourite() = runTest {
        assertEquals(GateDecision.Allowed, repo.toggle(1, "place-1", "Sample Sushi").getOrThrow())
        assertEquals(setOf("place-1"), repo.observe(1).first())

        clock.advance(1)
        assertEquals(GateDecision.Allowed, repo.toggle(1, "place-1", "Sample Sushi").getOrThrow())
        assertEquals(emptySet(), repo.observe(1).first())

        val types = db.userRestaurantInteractionsQueries.selectByUser(1, 10).executeAsList().map { it.interaction_type }
        assertEquals(listOf(FavouritesRepositoryImpl.UNFAVORITED, FavouritesRepositoryImpl.FAVORITED), types)
    }

    @Test
    fun free_tier_stops_at_the_favourites_limit_and_pro_lifts_it() = runTest {
        repeat(FreeLimits.FAVOURITES) { i ->
            clock.advance(1)
            assertEquals(GateDecision.Allowed, repo.toggle(1, "place-$i", null).getOrThrow())
        }

        val denied = repo.toggle(1, "place-extra", null).getOrThrow()
        assertEquals(GateDecision.denied(GateReason.FAVOURITES_LIMIT), denied)
        assertEquals(FreeLimits.FAVOURITES, repo.observe(1).first().size)

        entitlements.setPro(true)
        assertEquals(GateDecision.Allowed, repo.toggle(1, "place-extra", null).getOrThrow())
        assertEquals(FreeLimits.FAVOURITES + 1, repo.observe(1).first().size)
    }

    @Test
    fun favouriteRestaurants_uses_the_cache_and_falls_back_to_the_stored_name() = runTest {
        db.restaurantsQueries.upsert(Samples.restaurant("cached", "Cached Cafe"), clock.now)
        repo.toggle(1, "cached", "Old Name").getOrThrow()
        clock.advance(1)
        repo.toggle(1, "uncached", "Only In Interactions").getOrThrow()
        clock.advance(1)
        repo.toggle(1, "nameless", null).getOrThrow()

        val favourites = repo.favouriteRestaurants(1).getOrThrow()

        assertEquals(listOf("nameless", "uncached", "cached"), favourites.map { it.placeId })
        assertEquals(listOf("nameless", "Only In Interactions", "Cached Cafe"), favourites.map { it.name })
        assertEquals("1 George St", favourites.last().address)
    }
}
