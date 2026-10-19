package au.iapp.lunch.core.data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.FavouritesRepository
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.db.toRestaurant
import au.iapp.lunch.core.model.GateDecision
import au.iapp.lunch.core.model.Restaurant
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * Favourites persisted as rows in `user_restaurant_interactions` (the Flutter app
 * kept them in memory). A place is a favourite when its latest 'favorited' /
 * 'unfavorited' row is 'favorited'; the free-tier cap is applied through [GateService].
 */
internal class FavouritesRepositoryImpl(
    private val db: LunchDatabase,
    private val gates: GateService,
    private val clock: Clock,
    private val restaurants: au.iapp.lunch.core.api.RestaurantRepository? = null,
) : FavouritesRepository {

    override fun observe(userId: Long): Flow<Set<String>> =
        db.userRestaurantInteractionsQueries.selectFavourites(userId)
            .asFlow()
            .mapToList(DbDispatcher)
            .map { rows -> rows.map { it.restaurant_place_id }.toSet() }

    override suspend fun toggle(userId: Long, placeId: String, restaurantName: String?): Result<GateDecision> = dbResult {
        db.transactionWithResult {
            val current = db.userRestaurantInteractionsQueries.selectFavourites(userId).executeAsList()
            val isFavourite = current.any { it.restaurant_place_id == placeId }
            if (isFavourite) {
                record(userId, placeId, restaurantName, UNFAVORITED)
                GateDecision.Allowed
            } else {
                val decision = gates.canAddFavourite(current.size)
                if (decision.allowed) record(userId, placeId, restaurantName, FAVORITED)
                decision
            }
        }
    }

    /** Favourites in most-recent-first order; places missing from the cache keep their stored name. */
    override suspend fun favouriteRestaurants(userId: Long): Result<List<Restaurant>> = coreResult {
        val favourites = dbRead { db.userRestaurantInteractionsQueries.selectFavourites(userId).executeAsList() }
        if (favourites.isEmpty()) return@coreResult emptyList()
        val cached = dbRead { db.restaurantsQueries.selectByPlaceIds(favourites.map { it.restaurant_place_id })
            .executeAsList().associateBy { it.place_id } }
        favourites.map { row ->
            val stored = cached[row.restaurant_place_id]?.toRestaurant()?.takeIf { it.name != "Saved place" }
            restaurants?.cached(row.restaurant_place_id) ?: stored
                ?: restaurants?.details(row.restaurant_place_id)?.getOrNull()
                ?: Restaurant(placeId = row.restaurant_place_id, name = row.restaurant_name ?: row.restaurant_place_id, location = "")
        }
    }

    private fun record(userId: Long, placeId: String, restaurantName: String?, type: String) {
        db.userRestaurantInteractionsQueries.insert(
            user_id = userId,
            restaurant_place_id = placeId,
            restaurant_name = restaurantName,
            interaction_type = type,
            interaction_date = clock.nowEpochSeconds(),
            context = null,
        )
    }

    companion object {
        const val FAVORITED = "favorited"
        const val UNFAVORITED = "unfavorited"
    }
}
