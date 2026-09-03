/**
 * @file PreviewModels.kt
 * @description View-facing value types used by the design-system components, their previews,
 * and the gallery. Field names follow the shared contract in
 * shared/src/commonMain/kotlin/au/iapp/lunch/core/model/Models.kt so the mapping from the
 * shared module is mechanical once the UI is wired to it. Only the fields components display
 * are included.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.preview

import androidx.compose.runtime.Immutable
import java.text.NumberFormat
import java.util.Currency
import java.util.Locale

@Immutable
data class Restaurant(
    val placeId: String,
    val name: String,
    val location: String,
    val address: String? = null,
    /** Kilometres from the user at fetch time. */
    val distanceFromUser: Double? = null,
    val rating: Double? = null,
    val reviewCount: Int? = null,
    /** 1..4, the number of dollar signs. */
    val priceLevel: Int? = null,
    val cuisineTypes: List<String> = emptyList(),
    val isOpenNow: Boolean = false,
    val photoUrl: String? = null,
) {
    /** "$" to "$$$$"; null when the price level is unknown. */
    val priceLabel: String?
        get() = priceLevel?.takeIf { it > 0 }?.let { "$".repeat(it) }
}

@Immutable
data class Meal(
    val id: Long,
    val restaurantName: String?,
    val mealType: String,
    val cost: Double,
    val dateEpochSeconds: Long,
    val notes: String? = null,
)

@Immutable
data class WeeklyBudget(
    val weeklyCapacity: Double,
    val currentSpent: Double,
    val experiencesLogged: Int,
    val targetExperiences: Int,
) {
    val remainingCapacity: Double get() = (weeklyCapacity - currentSpent).coerceAtLeast(0.0)
    val capacityProgress: Double get() = if (weeklyCapacity > 0) currentSpent / weeklyCapacity else 0.0
}

/** Named after the shared `LunchGroup` rather than `Group` to avoid shadowing the icon. */
@Immutable
data class LunchGroup(
    val id: String,
    val hostName: String,
    val name: String,
    val scheduledAtEpochSeconds: Long,
    val placeName: String? = null,
    val placeAddress: String? = null,
    val inviteCode: String,
)

enum class RsvpStatus { PENDING, ACCEPTED, DECLINED }

@Immutable
data class Rsvp(val id: String, val displayName: String, val status: RsvpStatus)

@Immutable
data class ProPackage(
    /** RevenueCat package identifier, e.g. "$rc_annual". */
    val identifier: String,
    val productId: String,
    val localizedPrice: String,
    val periodLabel: String,
    val hasFreeTrial: Boolean,
    val trialLabel: String? = null,
)

/** Sample data shared by previews and the gallery. */
object PreviewData {
    private const val SECONDS_PER_DAY = 86_400L

    /** A fixed instant (2026-09-03 12:30 AEST) so previews and screenshots are stable. */
    const val SAMPLE_NOON_EPOCH_SECONDS = 1_788_402_600L

    val greenGardenBowls = Restaurant(
        placeId = "place_green_garden",
        name = "Green Garden Bowls",
        location = "Surry Hills",
        address = "12 Crown Street, Surry Hills NSW",
        distanceFromUser = 0.8,
        rating = 4.8,
        reviewCount = 214,
        priceLevel = 2,
        cuisineTypes = listOf("Salads", "Healthy", "Vegan"),
        isOpenNow = true,
    )

    val sakuraSushi = Restaurant(
        placeId = "place_sakura",
        name = "Sakura Sushi House",
        location = "Darlinghurst",
        address = "88 Oxford Street, Darlinghurst NSW",
        distanceFromUser = 1.4,
        rating = 4.6,
        reviewCount = 98,
        priceLevel = 3,
        cuisineTypes = listOf("Japanese", "Seafood", "Sushi"),
        isOpenNow = false,
    )

    val pastaCorner = Restaurant(
        placeId = "place_pasta",
        name = "Pasta Corner",
        location = "Redfern",
        address = "3 Regent Street, Redfern NSW",
        distanceFromUser = 2.3,
        rating = 4.2,
        reviewCount = 61,
        priceLevel = 2,
        cuisineTypes = listOf("Italian", "Pasta"),
        isOpenNow = true,
    )

    val restaurants = listOf(greenGardenBowls, sakuraSushi, pastaCorner)

    /** Verbatim reason strings from the core `RecommendationEngine`. */
    val reasons = listOf("Perfect budget match ($$)", "Very close to you (0.8km)", "Open right now")
    val pastaReasons = listOf("Great italian cuisine", "Within your preferred distance")

    val meals = listOf(
        Meal(1, "Green Garden Bowls", "lunch", 18.5, SAMPLE_NOON_EPOCH_SECONDS),
        Meal(2, "Sakura Sushi House", "dinner", 42.0, SAMPLE_NOON_EPOCH_SECONDS - SECONDS_PER_DAY),
        Meal(3, null, "snack", 6.0, SAMPLE_NOON_EPOCH_SECONDS - 2 * SECONDS_PER_DAY, "Flat white and a muffin"),
    )

    val weeklyBudget = WeeklyBudget(weeklyCapacity = 200.0, currentSpent = 124.0, experiencesLogged = 3, targetExperiences = 5)
    val weeklyBudgetOver = WeeklyBudget(weeklyCapacity = 200.0, currentSpent = 231.0, experiencesLogged = 6, targetExperiences = 5)

    val group = LunchGroup(
        id = "grp_1",
        hostName = "Ray",
        name = "Thursday team lunch",
        scheduledAtEpochSeconds = SAMPLE_NOON_EPOCH_SECONDS,
        placeName = "Green Garden Bowls",
        placeAddress = "12 Crown Street, Surry Hills NSW",
        inviteCode = "K7P2QX",
    )

    val rsvps = listOf(
        Rsvp("r1", "Ray", RsvpStatus.ACCEPTED),
        Rsvp("r2", "Mei", RsvpStatus.ACCEPTED),
        Rsvp("r3", "Tom", RsvpStatus.PENDING),
        Rsvp("r4", "Aisha", RsvpStatus.DECLINED),
    )

    val yearlyPackage = ProPackage(
        identifier = "\$rc_annual",
        productId = "au.iapp.lunch.pro.yearly",
        localizedPrice = "A$19.99",
        periodLabel = "year",
        hasFreeTrial = true,
        trialLabel = "7 days",
    )

    val monthlyPackage = ProPackage(
        identifier = "\$rc_monthly",
        productId = "au.iapp.lunch.pro.monthly",
        localizedPrice = "A$4.99",
        periodLabel = "month",
        hasFreeTrial = false,
    )

    const val INVITE_URL = "https://lunch.iapp.au/i/K7P2QX"

    private val australianDollars: NumberFormat = NumberFormat.getCurrencyInstance(Locale("en", "AU")).apply {
        currency = Currency.getInstance("AUD")
        maximumFractionDigits = 0
    }

    /** Australian-dollar formatting shared by previews and the gallery, e.g. "$124". */
    fun currency(amount: Double): String = australianDollars.format(amount)
}
