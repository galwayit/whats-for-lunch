package au.iapp.lunch.core.engine

import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.UserPreferences
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RestaurantChainsTest {
    private val names = listOf("Hungry Jack's Burgers Melbourne Central", "HUNGRY JACK’S", "Hungry Jacks", "Hungry-Jack’s", "HungryJacks", "Burger King", "McDonald’s", "Domino's Pizza", "Grill’d", "KFC Swanston Street")

    @Test fun excludesRegionalAliasesEvenWhenBestMatchGetsAnUnfilteredPool() {
        val engine = RecommendationEngineImpl()
        val prefs = UserPreferences(includeChains = false)
        for (name in names) {
            val restaurant = Restaurant(placeId = name, name = name, location = "", rating = 4.8)
            assertTrue(RestaurantChains.matches(name), name)
            assertTrue(engine.applyPreferenceFilters(listOf(restaurant), prefs).isEmpty(), name)
            assertNull(engine.bestMatch(listOf(restaurant), prefs, emptySet()), name)
        }
    }

    @Test fun avoidsSubstringMatchesAgainstUnrelatedNames() {
        listOf("Jack’s Corner Cafe", "The Hungry Hippo", "Burger Kingdom", "Subwayman Coffee", "Local Pizza Kitchen").forEach {
            assertFalse(RestaurantChains.matches(it), it)
        }
    }

    @Test fun enablingChainsAllowsHungryJacks() {
        val restaurant = Restaurant(placeId = "hj", name = "Hungry Jack’s", location = "", rating = 4.8)
        assertEquals(restaurant, RecommendationEngineImpl().bestMatch(listOf(restaurant), UserPreferences(includeChains = true), emptySet()))
    }
}
