package au.iapp.lunch.core.engine

import au.iapp.lunch.core.support.EngineVectors
import au.iapp.lunch.core.support.int
import au.iapp.lunch.core.support.str
import kotlin.test.Test
import kotlin.test.assertEquals

class MealDefaultsTest {
    private val defaults = MealDefaultsImpl()

    @Test
    fun smartMealType_matchesDartHourBands() {
        for (case in EngineVectors.load().cases("smartMealType")) {
            assertEquals(case.str("expected"), defaults.smartMealType(case.int("hour")), "hour ${case.int("hour")}")
        }
    }

    @Test
    fun categories_matchFlutterIdsBudgetsAndIcons() {
        assertEquals(
            listOf("dining_out" to 25.0, "delivery" to 20.0, "takeout" to 18.0, "groceries" to 15.0, "snack" to 8.0),
            defaults.categories.map { it.id to it.suggestedBudget },
        )
        assertEquals(listOf("restaurant", "delivery_dining", "takeout_dining", "shopping_cart", "local_cafe"), defaults.categories.map { it.icon })
        assertEquals("Restaurant, cafe, or food court experience", defaults.categories.first().description)
    }

    @Test
    fun displayName_matchesMealDart() {
        val expected = mapOf(
            "dining_out" to "Dining Out", "delivery" to "Delivery", "takeout" to "Takeout", "groceries" to "Groceries",
            "snack" to "Snack", "breakfast" to "Breakfast", "lunch" to "Lunch", "dinner" to "Dinner", "brunch" to "Experience", "" to "Experience",
        )
        for ((type, name) in expected) assertEquals(name, defaults.displayName(type), type)
    }
}
