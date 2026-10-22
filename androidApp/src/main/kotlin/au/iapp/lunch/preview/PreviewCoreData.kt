/**
 * @file PreviewCoreData.kt
 * @description Realistic sample data on the shared core model types, used to seed
 * [PreviewLunchCore]. Mirrors iosApp/LunchApp/Core/Preview/PreviewData.swift so both platforms
 * show the same demo content: Sydney restaurants measured from Surry Hills, a week of meals,
 * one group lunch with four guests, and the two Lunch Pro packages.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.preview

import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.ProOfferings
import au.iapp.lunch.core.model.ProPackage
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.model.UserProfile
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId

object PreviewCoreData {
    /** Surry Hills, Sydney: the demo user's position. */
    val userLocation = Location(latitude = -33.8845, longitude = 151.2110, accuracyMetres = 25.0)
    const val USER_ID = 1L
    const val USER_NAME = "Ray"

    val user = UserProfile(
        id = USER_ID,
        name = USER_NAME,
        preferences = UserPreferences(
            dietaryRestrictions = listOf("Vegetarian"),
            budgetLevel = 2,
            maxTravelDistance = 5.0,
            weeklyBudget = 200.0,
        ),
        createdAtEpochSeconds = 1_756_000_000,
    )

    // Restaurants

    val greenGardenBowls = restaurant(
        id = "place_green_garden", name = "Green Garden Bowls", suburb = "Surry Hills",
        address = "12 Crown Street, Surry Hills NSW 2010", latitude = -33.8830, longitude = 151.2130,
        distance = 0.8, rating = 4.8, reviews = 214, price = 2,
        cuisines = listOf("Salads", "Healthy", "Vegan"), dietary = listOf("Vegan", "Vegetarian", "Gluten-free"),
        open = true, averageCost = 18.5,
    )
    val sakuraSushi = restaurant(
        id = "place_sakura", name = "Sakura Sushi", suburb = "Darlinghurst",
        address = "88 Oxford Street, Darlinghurst NSW 2010", latitude = -33.8785, longitude = 151.2155,
        distance = 1.4, rating = 4.6, reviews = 98, price = 3,
        cuisines = listOf("Japanese", "Seafood", "Sushi"), dietary = listOf("Pescatarian", "Gluten-free"),
        open = false, averageCost = 28.0,
    )
    val pastaCorner = restaurant(
        id = "place_pasta", name = "Pasta Corner", suburb = "Redfern",
        address = "3 Regent Street, Redfern NSW 2016", latitude = -33.8930, longitude = 151.2035,
        distance = 2.3, rating = 4.2, reviews = 61, price = 2,
        cuisines = listOf("Italian", "Pasta"), dietary = listOf("Vegetarian"), open = true, averageCost = 22.0,
    )
    val banhMiBay = restaurant(
        id = "place_banh_mi", name = "Banh Mi Bay", suburb = "Haymarket",
        address = "401 Sussex Street, Haymarket NSW 2000", latitude = -33.8790, longitude = 151.2040,
        distance = 1.1, rating = 4.5, reviews = 342, price = 1,
        cuisines = listOf("Vietnamese", "Sandwiches"), dietary = listOf("Vegetarian"), open = true, averageCost = 12.0,
    )
    val spiceRoute = restaurant(
        id = "place_spice_route", name = "The Spice Route", suburb = "Newtown",
        address = "250 King Street, Newtown NSW 2042", latitude = -33.8975, longitude = 151.1790,
        distance = 3.6, rating = 4.4, reviews = 187, price = 2,
        cuisines = listOf("Indian", "Curry"), dietary = listOf("Halal", "Vegetarian", "Vegan"), open = true, averageCost = 20.0,
    )
    val harbourFish = restaurant(
        id = "place_harbour_fish", name = "Harbour Fish Co.", suburb = "Circular Quay",
        address = "5 Alfred Street, Sydney NSW 2000", latitude = -33.8610, longitude = 151.2110,
        distance = 2.6, rating = 4.3, reviews = 520, price = 3,
        cuisines = listOf("Seafood", "Australian"), dietary = listOf("Pescatarian"), open = true, averageCost = 42.0,
    )
    val dumplingLane = restaurant(
        id = "place_dumpling_lane", name = "Dumpling Lane", suburb = "Chinatown",
        address = "66 Dixon Street, Haymarket NSW 2000", latitude = -33.8785, longitude = 151.2035,
        distance = 1.2, rating = 4.1, reviews = 410, price = 1,
        cuisines = listOf("Chinese", "Dumplings"), dietary = listOf("Vegetarian"), open = true, averageCost = 15.0,
    )
    val falafelRepublic = restaurant(
        id = "place_falafel", name = "Falafel Republic", suburb = "Surry Hills",
        address = "180 Bourke Street, Surry Hills NSW 2010", latitude = -33.8815, longitude = 151.2145,
        distance = 0.6, rating = 4.7, reviews = 156, price = 1,
        cuisines = listOf("Middle Eastern", "Vegan"), dietary = listOf("Vegan", "Vegetarian", "Halal", "Gluten-free"),
        open = true, averageCost = 14.0,
    )
    val burgerUnion = restaurant(
        id = "place_burger_union", name = "Burger Union", suburb = "Sydney CBD",
        address = "200 George Street, Sydney NSW 2000", latitude = -33.8665, longitude = 151.2075,
        distance = 2.0, rating = 3.9, reviews = 890, price = 2,
        cuisines = listOf("Burgers", "American"), dietary = emptyList(), open = true, averageCost = 19.0,
        features = listOf("chain"),
    )
    val lanewayEspresso = restaurant(
        id = "place_laneway_espresso", name = "Laneway Espresso Kitchen", suburb = "Melbourne CBD",
        address = "12 Degraves Street, Melbourne VIC 3000", latitude = -37.8176, longitude = 144.9655,
        distance = 714.0, rating = 4.6, reviews = 275, price = 2,
        cuisines = listOf("Cafe", "Brunch"), dietary = listOf("Vegetarian", "Gluten-free"), open = true, averageCost = 21.0,
    )

    /** All ten sample restaurants, nearest first. */
    val restaurants: List<Restaurant> = listOf(
        falafelRepublic, greenGardenBowls, banhMiBay, dumplingLane, sakuraSushi,
        burgerUnion, pastaCorner, harbourFish, spiceRoute, lanewayEspresso,
    )

    val reviews: List<RestaurantReview> = listOf(
        RestaurantReview(
            reviewId = "rev_1", authorName = "Mei L.", rating = 5,
            text = "Fresh, generous bowls and quick service at lunch. The miso dressing is worth the trip.",
            timeEpochSeconds = 1_756_300_000, relativeTimeDescription = "a week ago",
        ),
        RestaurantReview(
            reviewId = "rev_2", authorName = "Tom H.", rating = 4,
            text = "Busy at 12:30 but the line moves fast. Great vegan options.",
            timeEpochSeconds = 1_755_600_000, relativeTimeDescription = "2 weeks ago",
        ),
        RestaurantReview(
            reviewId = "rev_3", authorName = "Aisha K.", rating = 5,
            text = "My go-to for a healthy lunch near the office.",
            timeEpochSeconds = 1_754_000_000, relativeTimeDescription = "a month ago",
        ),
    )

    // Meals

    /** Five meals this week (A$124 in total) plus older history, dated relative to [nowEpochSeconds]. */
    fun meals(nowEpochSeconds: Long, zone: ZoneId = ZoneId.systemDefault()): List<Meal> {
        val today = Instant.ofEpochSecond(nowEpochSeconds).atZone(zone).toLocalDate()
        fun at(daysAgo: Long, hour: Int): Long =
            today.minusDays(daysAgo).atTime(LocalTime.of(hour, 30)).atZone(zone).toEpochSecond()
        fun meal(id: Long, restaurant: Restaurant, type: String, cost: Double, daysAgo: Long, hour: Int, notes: String? = null) =
            Meal(
                id = id, userId = USER_ID, restaurantId = restaurant.placeId, restaurantName = restaurant.name,
                mealType = type, cost = cost, dateEpochSeconds = at(daysAgo, hour), notes = notes,
            )
        return listOf(
            meal(1, greenGardenBowls, "lunch", 18.5, 0, 12),
            meal(2, sakuraSushi, "lunch", 24.0, 1, 12),
            meal(3, harbourFish, "dinner", 45.5, 1, 19, notes = "Team dinner"),
            meal(4, banhMiBay, "lunch", 16.0, 2, 12),
            meal(5, spiceRoute, "lunch", 20.0, 3, 13),
            meal(6, pastaCorner, "lunch", 22.0, 9, 12),
            meal(7, dumplingLane, "lunch", 15.0, 16, 12),
            meal(8, falafelRepublic, "snack", 9.0, 40, 15),
        )
    }

    // AI

    val aiRecommendation = AiRecommendation(
        id = "ai_1",
        userId = USER_ID,
        restaurants = listOf(greenGardenBowls, falafelRepublic, banhMiBay),
        reasoning = "You asked for something light and quick. Green Garden Bowls is 800 m away, fits your \$\$ budget, " +
            "and has verified vegan options; Falafel Republic and Banh Mi Bay are cheaper backups on the same walk.",
        factorWeights = mapOf("budget" to 0.4, "distance" to 0.3, "rating" to 0.2, "cuisine" to 0.1),
        overallConfidence = 0.86,
        investmentSummary = "About A\$18 today keeps you A\$58 under this week's budget.",
        generatedAtEpochSeconds = 1_756_800_000,
    )

    // Social

    const val GROUP_ID = "grp_1"
    const val INVITE_CODE = "K7P2QX"
    const val INVITE_LINK_BASE = "https://lunch.iapp.au/i/"

    /** "Thursday team lunch" at 12:30 today, already confirmed at Green Garden Bowls. */
    fun group(nowEpochSeconds: Long, zone: ZoneId = ZoneId.systemDefault()): LunchGroup {
        val today = Instant.ofEpochSecond(nowEpochSeconds).atZone(zone).toLocalDate()
        return LunchGroup(
            id = GROUP_ID,
            hostId = "user_ray",
            hostName = "Ray",
            name = "Thursday team lunch",
            scheduledAtEpochSeconds = today.atTime(LocalTime.of(12, 30)).atZone(zone).toEpochSecond(),
            areaLatitude = userLocation.latitude,
            areaLongitude = userLocation.longitude,
            radiusKm = 2.0,
            placeId = greenGardenBowls.placeId,
            placeName = greenGardenBowls.name,
            placeAddress = greenGardenBowls.address,
            inviteCode = INVITE_CODE,
            createdAtEpochSeconds = 1_756_700_000,
        )
    }

    val rsvps: List<Rsvp> = listOf(
        Rsvp("rsvp_1", GROUP_ID, "user_ray", "Ray", RsvpStatus.ACCEPTED, 1_756_700_100),
        Rsvp("rsvp_2", GROUP_ID, "user_mei", "Mei", RsvpStatus.ACCEPTED, 1_756_710_000),
        Rsvp("rsvp_3", GROUP_ID, null, "Tom", RsvpStatus.PENDING, null),
        Rsvp("rsvp_4", GROUP_ID, "user_aisha", "Aisha", RsvpStatus.DECLINED, 1_756_720_000),
    )

    // Monetisation (decided 2026-10-19: A$4.99 monthly, A$29.99 yearly, no introductory offer)

    val yearlyPackage = ProPackage(
        identifier = "\$rc_annual", productId = "au.iapp.lunch.pro.yearly", localizedPrice = "A\$29.99",
        periodLabel = "year", hasFreeTrial = false, trialLabel = null,
    )
    val monthlyPackage = ProPackage(
        identifier = "\$rc_monthly", productId = "au.iapp.lunch.pro.monthly", localizedPrice = "A\$4.99",
        periodLabel = "month", hasFreeTrial = false, trialLabel = null,
    )
    val offerings = ProOfferings(monthly = monthlyPackage, yearly = yearlyPackage)

    private fun restaurant(
        id: String, name: String, suburb: String, address: String, latitude: Double, longitude: Double,
        distance: Double, rating: Double, reviews: Int, price: Int, cuisines: List<String>, dietary: List<String>,
        open: Boolean, averageCost: Double, features: List<String> = emptyList(),
    ) = Restaurant(
        placeId = id,
        name = name,
        location = suburb,
        address = address,
        phoneNumber = "+61 2 9000 0000",
        website = "https://example.com/$id",
        latitude = latitude,
        longitude = longitude,
        distanceFromUser = distance,
        rating = rating,
        reviewCount = reviews,
        priceLevel = price,
        priceRanges = listOf("$".repeat(price)),
        cuisineType = cuisines.firstOrNull(),
        cuisineTypes = cuisines,
        supportedDietaryRestrictions = dietary,
        hasVerifiedDietaryInfo = dietary.isNotEmpty(),
        communityVerificationCount = if (dietary.isEmpty()) 0 else 12,
        openingHours = listOf("Mon-Fri 11:00-21:00", "Sat-Sun 11:30-21:30"),
        isOpenNow = open,
        features = features,
        averageMealCost = averageCost,
        cachedAtEpochSeconds = 1_756_800_000,
    )
}
