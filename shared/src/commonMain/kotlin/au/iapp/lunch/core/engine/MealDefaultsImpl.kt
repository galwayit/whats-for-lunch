package au.iapp.lunch.core.engine

import au.iapp.lunch.core.api.MealDefaults
import au.iapp.lunch.core.model.MealCategory

/**
 * Pure port of `MealFormNotifier.applySmartDefaults`, `mealCategoriesProvider`
 * (meal_providers.dart) and `Meal.displayMealType` (meal.dart).
 */
class MealDefaultsImpl : MealDefaults {

    override fun smartMealType(hourOfDay: Int): String = when {
        hourOfDay < 10 -> "breakfast"
        hourOfDay < 15 -> "lunch"
        hourOfDay < 18 -> "snack"
        else -> "dinner"
    }

    override val categories: List<MealCategory> = listOf(
        MealCategory("dining_out", "Dining Out", "Restaurant, cafe, or food court experience", "restaurant", 25.0),
        MealCategory("delivery", "Delivery", "Food delivered to your location", "delivery_dining", 20.0),
        MealCategory("takeout", "Takeout", "Picked up from restaurant", "takeout_dining", 18.0),
        MealCategory("groceries", "Groceries", "Ingredients for home cooking", "shopping_cart", 15.0),
        MealCategory("snack", "Snack", "Quick bite or beverage", "local_cafe", 8.0),
    )

    override fun displayName(mealType: String): String = when (mealType) {
        "dining_out" -> "Dining Out"
        "delivery" -> "Delivery"
        "takeout" -> "Takeout"
        "groceries" -> "Groceries"
        "snack" -> "Snack"
        "breakfast" -> "Breakfast"
        "lunch" -> "Lunch"
        "dinner" -> "Dinner"
        else -> "Experience"
    }
}
