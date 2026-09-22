/**
 * @file DietaryOptions.kt
 * @description The dietary and allergen chips from design/copy.md, keyed the way preferences
 * store them. Mirrors `Copy.Dietary` in iosApp/LunchApp/Copy/Copy.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.annotation.StringRes
import au.iapp.lunch.R

data class DietaryOption(val key: String, @StringRes val labelRes: Int)

object DietaryOptions {
    const val NONE = "none"
    val allergenKeys = setOf("nut_allergy", "shellfish_allergy")

    val all = listOf(
        DietaryOption("vegetarian", R.string.dietary_vegetarian),
        DietaryOption("vegan", R.string.dietary_vegan),
        DietaryOption("gluten_free", R.string.dietary_gluten_free),
        DietaryOption("dairy_free", R.string.dietary_dairy_free),
        DietaryOption("halal", R.string.dietary_halal),
        DietaryOption("kosher", R.string.dietary_kosher),
        DietaryOption("nut_allergy", R.string.dietary_nut_allergy),
        DietaryOption("shellfish_allergy", R.string.dietary_shellfish_allergy),
    )
    val dietary = all.filter { it.key !in allergenKeys }
    val allergens = all.filter { it.key in allergenKeys }
    val none = DietaryOption(NONE, R.string.dietary_none)

    /** Normalises stored labels such as "Gluten free" to the chip keys ("gluten_free"). */
    fun key(value: String): String = value.lowercase().replace(' ', '_').replace('-', '_')
}
