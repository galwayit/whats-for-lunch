package au.iapp.lunch.core.engine

import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.SortOption
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.support.EngineVectors
import au.iapp.lunch.core.support.str
import au.iapp.lunch.core.support.strOrNull
import au.iapp.lunch.core.support.strings
import au.iapp.lunch.core.support.dbl
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecommendationEngineTest {
    private val vectors = EngineVectors.load()
    private val engine = RecommendationEngineImpl()

    @Test
    fun absent_allergen_data_is_unknown_and_conflicts_are_never_eligible() {
        val unknown = Restaurant(placeId = "x", name = "Cafe", location = "", hasVerifiedDietaryInfo = true)
        val strict = UserPreferences(allergens = listOf("nut_allergy"))
        assertEquals(0.0, engine.dietaryCompatibility(unknown, emptyList(), strict.allergens))
        assertTrue(engine.applyPreferenceFilters(listOf(unknown), strict).isEmpty())
        assertNull(engine.bestMatch(listOf(unknown), strict, emptySet()))
        val exploring = strict.copy(requireDietaryVerification = false)
        assertEquals(listOf(unknown), engine.applyPreferenceFilters(listOf(unknown), exploring))
        for (allergen in listOf("Peanuts", "tree-nuts", "nut_allergy")) {
            assertTrue(engine.applyPreferenceFilters(listOf(unknown.copy(allergenInfo = listOf(allergen))), exploring).isEmpty())
        }
    }

    private fun restaurant(id: String): Restaurant = vectors.restaurants.getValue(id)
    private fun prefs(key: String): UserPreferences? = vectors.prefs.getValue(key)

    @Test
    fun compatibilityScore_matchesDart() {
        val cases = vectors.cases("compatibilityScore")
        assertTrue(cases.size >= 50)
        for (case in cases) {
            val actual = engine.compatibilityScore(restaurant(case.str("placeId")), prefs(case.str("prefs")))
            assertEquals(case.dbl("expected"), actual, 1e-12, "score for ${case.str("placeId")} / ${case.str("prefs")}")
        }
    }

    @Test
    fun reasons_matchDartVerbatim() {
        for (case in vectors.cases("reasons")) {
            val actual = engine.reasons(restaurant(case.str("placeId")), prefs(case.str("prefs")))
            assertEquals(case.strings("expected"), actual, "reasons for ${case.str("placeId")} / ${case.str("prefs")}")
        }
    }

    @Test
    fun discoverReasons_matchDartVerbatim() {
        for (case in vectors.cases("discoverReasons")) {
            val actual = engine.discoverReasons(restaurant(case.str("placeId")), prefs(case.str("prefs")))
            assertEquals(case.strings("expected"), actual, "discover reasons for ${case.str("placeId")} / ${case.str("prefs")}")
        }
    }

    @Test
    fun bestMatch_matchesFixture() {
        // The legacy Dart vectors allowed chains in bestMatch. The no-chain cases now
        // select the highest remaining score after excluding r2 (Burger King) and r8 (McDonald's).
        val candidates = vectors.restaurantOrder.map(::restaurant)
        for (case in vectors.cases("bestMatch")) {
            val rejected = case.strings("rejected").toSet()
            val actual = engine.bestMatch(candidates, prefs(case.str("prefs")), rejected)?.placeId
            assertEquals(case.strOrNull("expected"), actual, "bestMatch for ${case.str("prefs")} rejecting $rejected")
        }
    }

    @Test
    fun bestMatch_returnsNullWhenNothingBeatsThreshold() {
        val weak = Restaurant(placeId = "w", name = "Weak", location = "", rating = 0.4)
        assertNull(engine.bestMatch(listOf(weak), null, emptySet()))
        assertNull(engine.bestMatch(emptyList(), UserPreferences(), emptySet()))
    }

    @Test
    fun sort_matchesDartForEveryOption() {
        val input = vectors.restaurantOrder.map(::restaurant)
        for (case in vectors.cases("sort")) {
            val option = SortOption.valueOf(case.str("option"))
            val actual = engine.sort(input, option, prefs(case.str("prefs"))).map { it.placeId }
            assertEquals(case.strings("expected"), actual, "sort $option / ${case.str("prefs")}")
        }
    }

    @Test
    fun sort_isStableAndDoesNotMutateInput() {
        val a = Restaurant(placeId = "a", name = "A", location = "", rating = 4.0)
        val b = Restaurant(placeId = "b", name = "B", location = "", rating = 4.0)
        val c = Restaurant(placeId = "c", name = "C", location = "", rating = 4.0)
        val input = listOf(c, a, b)
        val sorted = engine.sort(input, SortOption.RATING, null)
        assertEquals(listOf("c", "a", "b"), sorted.map { it.placeId })
        assertEquals(listOf("c", "a", "b"), input.map { it.placeId })
    }

    @Test
    fun applyPreferenceFilters_matchesDart() {
        val input = vectors.restaurantOrder.map(::restaurant)
        for (case in vectors.cases("applyPreferenceFilters")) {
            val actual = engine.applyPreferenceFilters(input, prefs(case.str("prefs"))).map { it.placeId }
            assertEquals(case.strings("expected"), actual, "filters for ${case.str("prefs")}")
        }
    }

    @Test
    fun dietaryCompatibility_matchesDart() {
        for (case in vectors.cases("dietaryCompatibility")) {
            val actual = engine.dietaryCompatibility(restaurant(case.str("placeId")), case.strings("restrictions"), case.strings("allergens"))
            assertEquals(case.dbl("expected"), actual, 1e-12, "dietary for ${case.str("placeId")}")
        }
    }
}
