//
//  SwiftMealDefaults.swift
//  LunchApp
//
//  Pure Swift port of MealDefaultsImpl.kt: smart meal type by hour, the meal categories, and
//  display names.
//

import Foundation

nonisolated struct SwiftMealDefaults: MealDefaults {
    func smartMealType(hourOfDay: Int) -> String {
        if hourOfDay < 10 { return "breakfast" }
        if hourOfDay < 15 { return "lunch" }
        if hourOfDay < 18 { return "snack" }
        return "dinner"
    }

    let categories: [MealCategory] = [
        MealCategory(id: "dining_out", name: "Dining Out", description: "Restaurant, cafe, or food court experience", icon: "restaurant", suggestedBudget: 25),
        MealCategory(id: "delivery", name: "Delivery", description: "Food delivered to your location", icon: "delivery_dining", suggestedBudget: 20),
        MealCategory(id: "takeout", name: "Takeout", description: "Picked up from restaurant", icon: "takeout_dining", suggestedBudget: 18),
        MealCategory(id: "groceries", name: "Groceries", description: "Ingredients for home cooking", icon: "shopping_cart", suggestedBudget: 15),
        MealCategory(id: "snack", name: "Snack", description: "Quick bite or beverage", icon: "local_cafe", suggestedBudget: 8),
    ]

    func displayName(mealType: String) -> String {
        switch mealType {
        case "dining_out": "Dining Out"
        case "delivery": "Delivery"
        case "takeout": "Takeout"
        case "groceries": "Groceries"
        case "snack": "Snack"
        case "breakfast": "Breakfast"
        case "lunch": "Lunch"
        case "dinner": "Dinner"
        default: "Experience"
        }
    }
}
