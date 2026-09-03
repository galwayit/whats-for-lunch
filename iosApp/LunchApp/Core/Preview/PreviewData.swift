//
//  PreviewData.swift
//  LunchApp
//
//  Realistic sample data on the Core model types. Used by SwiftUI previews, the component
//  gallery, and `PreviewLunchCore` (the in-memory core selected with `-previewCore`).
//  Coordinates are real Sydney and Melbourne streets; distances are from Surry Hills.
//

import Foundation

enum PreviewData {
    // MARK: - Location and user

    /// Surry Hills, Sydney: the demo user's position.
    static let userLocation = Location(latitude: -33.8845, longitude: 151.2110, accuracyMetres: 25)
    static let userId: Int64 = 1
    static let userName = "Ray"

    static let user = UserProfile(
        id: userId,
        name: userName,
        preferences: UserPreferences(dietaryRestrictions: ["Vegetarian"], budgetLevel: 2, maxTravelDistance: 5.0, weeklyBudget: 200),
        createdAtEpochSeconds: 1_756_000_000
    )

    // MARK: - Restaurants

    static let greenGardenBowls = restaurant(
        id: "place_green_garden", name: "Green Garden Bowls", suburb: "Surry Hills", address: "12 Crown Street, Surry Hills NSW 2010",
        latitude: -33.8830, longitude: 151.2130, distance: 0.8, rating: 4.8, reviews: 214, price: 2,
        cuisines: ["Salads", "Healthy", "Vegan"], dietary: ["Vegan", "Vegetarian", "Gluten-free"], open: true, averageCost: 18.5
    )
    static let sakuraSushi = restaurant(
        id: "place_sakura", name: "Sakura Sushi", suburb: "Darlinghurst", address: "88 Oxford Street, Darlinghurst NSW 2010",
        latitude: -33.8785, longitude: 151.2155, distance: 1.4, rating: 4.6, reviews: 98, price: 3,
        cuisines: ["Japanese", "Seafood", "Sushi"], dietary: ["Pescatarian", "Gluten-free"], open: false, averageCost: 28
    )
    static let pastaCorner = restaurant(
        id: "place_pasta", name: "Pasta Corner", suburb: "Redfern", address: "3 Regent Street, Redfern NSW 2016",
        latitude: -33.8930, longitude: 151.2035, distance: 2.3, rating: 4.2, reviews: 61, price: 2,
        cuisines: ["Italian", "Pasta"], dietary: ["Vegetarian"], open: true, averageCost: 22
    )
    static let banhMiBay = restaurant(
        id: "place_banh_mi", name: "Banh Mi Bay", suburb: "Haymarket", address: "401 Sussex Street, Haymarket NSW 2000",
        latitude: -33.8790, longitude: 151.2040, distance: 1.1, rating: 4.5, reviews: 342, price: 1,
        cuisines: ["Vietnamese", "Sandwiches"], dietary: ["Vegetarian"], open: true, averageCost: 12
    )
    static let spiceRoute = restaurant(
        id: "place_spice_route", name: "The Spice Route", suburb: "Newtown", address: "250 King Street, Newtown NSW 2042",
        latitude: -33.8975, longitude: 151.1790, distance: 3.6, rating: 4.4, reviews: 187, price: 2,
        cuisines: ["Indian", "Curry"], dietary: ["Halal", "Vegetarian", "Vegan"], open: true, averageCost: 20
    )
    static let harbourFish = restaurant(
        id: "place_harbour_fish", name: "Harbour Fish Co.", suburb: "Circular Quay", address: "5 Alfred Street, Sydney NSW 2000",
        latitude: -33.8610, longitude: 151.2110, distance: 2.6, rating: 4.3, reviews: 520, price: 3,
        cuisines: ["Seafood", "Australian"], dietary: ["Pescatarian"], open: true, averageCost: 42
    )
    static let dumplingLane = restaurant(
        id: "place_dumpling_lane", name: "Dumpling Lane", suburb: "Chinatown", address: "66 Dixon Street, Haymarket NSW 2000",
        latitude: -33.8785, longitude: 151.2035, distance: 1.2, rating: 4.1, reviews: 410, price: 1,
        cuisines: ["Chinese", "Dumplings"], dietary: ["Vegetarian"], open: true, averageCost: 15
    )
    static let falafelRepublic = restaurant(
        id: "place_falafel", name: "Falafel Republic", suburb: "Surry Hills", address: "180 Bourke Street, Surry Hills NSW 2010",
        latitude: -33.8815, longitude: 151.2145, distance: 0.6, rating: 4.7, reviews: 156, price: 1,
        cuisines: ["Middle Eastern", "Vegan"], dietary: ["Vegan", "Vegetarian", "Halal", "Gluten-free"], open: true, averageCost: 14
    )
    static let burgerUnion = restaurant(
        id: "place_burger_union", name: "Burger Union", suburb: "Sydney CBD", address: "200 George Street, Sydney NSW 2000",
        latitude: -33.8665, longitude: 151.2075, distance: 2.0, rating: 3.9, reviews: 890, price: 2,
        cuisines: ["Burgers", "American"], dietary: [], open: true, averageCost: 19, features: ["chain"]
    )
    static let lanewayEspresso = restaurant(
        id: "place_laneway_espresso", name: "Laneway Espresso Kitchen", suburb: "Melbourne CBD", address: "12 Degraves Street, Melbourne VIC 3000",
        latitude: -37.8176, longitude: 144.9655, distance: 714, rating: 4.6, reviews: 275, price: 2,
        cuisines: ["Cafe", "Brunch"], dietary: ["Vegetarian", "Gluten-free"], open: true, averageCost: 21
    )

    /// All ten sample restaurants, nearest first.
    static let restaurants: [Restaurant] = [
        falafelRepublic, greenGardenBowls, banhMiBay, dumplingLane, sakuraSushi,
        burgerUnion, pastaCorner, harbourFish, spiceRoute, lanewayEspresso,
    ]

    static let reasons = ["Perfect budget match ($)", "Very close to you (0.8km)", "Open right now"]

    static let reviews: [RestaurantReview] = [
        RestaurantReview(reviewId: "rev_1", authorName: "Mei L.", rating: 5, text: "Fresh, generous bowls and quick service at lunch. The miso dressing is worth the trip.", timeEpochSeconds: 1_756_300_000, relativeTimeDescription: "a week ago"),
        RestaurantReview(reviewId: "rev_2", authorName: "Tom H.", rating: 4, text: "Busy at 12:30 but the line moves fast. Great vegan options.", timeEpochSeconds: 1_755_600_000, relativeTimeDescription: "2 weeks ago"),
        RestaurantReview(reviewId: "rev_3", authorName: "Aisha K.", rating: 5, text: "My go-to for a healthy lunch near the office.", timeEpochSeconds: 1_754_000_000, relativeTimeDescription: "a month ago"),
    ]

    // MARK: - Meals and budget

    /// Five meals this week (A$124 in total) plus older history for the tracker list.
    static func meals(now: Date = Date()) -> [Meal] {
        let calendar = Calendar.current
        func at(daysAgo: Int, hour: Int) -> Int64 {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let date = calendar.date(bySettingHour: hour, minute: 30, second: 0, of: day) ?? day
            return Int64(date.timeIntervalSince1970)
        }
        return [
            Meal(id: 1, userId: userId, restaurantId: greenGardenBowls.placeId, restaurantName: greenGardenBowls.name, mealType: "lunch", cost: 18.5, dateEpochSeconds: at(daysAgo: 0, hour: 12)),
            Meal(id: 2, userId: userId, restaurantId: sakuraSushi.placeId, restaurantName: sakuraSushi.name, mealType: "lunch", cost: 24, dateEpochSeconds: at(daysAgo: 1, hour: 12)),
            Meal(id: 3, userId: userId, restaurantId: harbourFish.placeId, restaurantName: harbourFish.name, mealType: "dinner", cost: 45.5, dateEpochSeconds: at(daysAgo: 1, hour: 19), notes: "Team dinner"),
            Meal(id: 4, userId: userId, restaurantId: banhMiBay.placeId, restaurantName: banhMiBay.name, mealType: "lunch", cost: 16, dateEpochSeconds: at(daysAgo: 2, hour: 12)),
            Meal(id: 5, userId: userId, restaurantId: spiceRoute.placeId, restaurantName: spiceRoute.name, mealType: "lunch", cost: 20, dateEpochSeconds: at(daysAgo: 3, hour: 13)),
            Meal(id: 6, userId: userId, restaurantId: pastaCorner.placeId, restaurantName: pastaCorner.name, mealType: "lunch", cost: 22, dateEpochSeconds: at(daysAgo: 9, hour: 12)),
            Meal(id: 7, userId: userId, restaurantId: dumplingLane.placeId, restaurantName: dumplingLane.name, mealType: "lunch", cost: 15, dateEpochSeconds: at(daysAgo: 16, hour: 12)),
            Meal(id: 8, userId: userId, restaurantId: falafelRepublic.placeId, restaurantName: falafelRepublic.name, mealType: "snack", cost: 9, dateEpochSeconds: at(daysAgo: 40, hour: 15)),
        ]
    }

    static let meals: [Meal] = meals()

    static let weeklyBudget = WeeklyBudgetState(weeklyCapacity: 200, currentSpent: 124, experiencesLogged: 3, targetExperiences: 5)
    static let weeklyBudgetOver = WeeklyBudgetState(weeklyCapacity: 200, currentSpent: 231, experiencesLogged: 6, targetExperiences: 5)

    // MARK: - AI

    static let aiRecommendation = AiRecommendation(
        id: "ai_1",
        userId: userId,
        restaurants: [greenGardenBowls, falafelRepublic, banhMiBay],
        reasoning: "You asked for something light and quick. Green Garden Bowls is 800 m away, fits your $$ budget, and has verified vegan options; Falafel Republic and Banh Mi Bay are cheaper backups on the same walk.",
        factorWeights: ["budget": 0.4, "distance": 0.3, "rating": 0.2, "cuisine": 0.1],
        overallConfidence: 0.86,
        investmentSummary: "About A$18 today keeps you A$58 under this week's budget.",
        generatedAtEpochSeconds: 1_756_800_000
    )

    // MARK: - Social

    static let group = LunchGroup(
        id: "grp_1",
        hostId: "user_ray",
        hostName: "Ray",
        name: "Thursday team lunch",
        scheduledAtEpochSeconds: {
            let calendar = Calendar.current
            let today = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: Date()) ?? Date()
            return Int64(today.timeIntervalSince1970)
        }(),
        areaLatitude: userLocation.latitude,
        areaLongitude: userLocation.longitude,
        radiusKm: 2,
        placeId: greenGardenBowls.placeId,
        placeName: greenGardenBowls.name,
        placeAddress: greenGardenBowls.address,
        inviteCode: "K7P2QX",
        createdAtEpochSeconds: 1_756_700_000
    )

    static let rsvps: [Rsvp] = [
        Rsvp(id: "rsvp_1", groupId: group.id, guestUserId: "user_ray", displayName: "Ray", status: .accepted, respondedAtEpochSeconds: 1_756_700_100),
        Rsvp(id: "rsvp_2", groupId: group.id, guestUserId: "user_mei", displayName: "Mei", status: .accepted, respondedAtEpochSeconds: 1_756_710_000),
        Rsvp(id: "rsvp_3", groupId: group.id, guestUserId: nil, displayName: "Tom", status: .pending),
        Rsvp(id: "rsvp_4", groupId: group.id, guestUserId: "user_aisha", displayName: "Aisha", status: .declined, respondedAtEpochSeconds: 1_756_720_000),
    ]

    static let inviteLinkBase = "https://lunch.iapp.au/i/"
    static let inviteUrl = inviteLinkBase + group.inviteCode

    // MARK: - Monetisation

    static let yearlyPackage = ProPackage(identifier: "$rc_annual", productId: "au.iapp.lunch.pro.yearly", localizedPrice: "A$19.99", periodLabel: "year", hasFreeTrial: true, trialLabel: "7 days")
    static let monthlyPackage = ProPackage(identifier: "$rc_monthly", productId: "au.iapp.lunch.pro.monthly", localizedPrice: "A$2.99", periodLabel: "month", hasFreeTrial: false)
    static let offerings = ProOfferings(monthly: monthlyPackage, yearly: yearlyPackage)

    // MARK: - Formatting

    /// Australian dollars without cents, e.g. "$124". Whole-dollar amounts are the norm in the copy deck.
    static func currency(_ amount: Double) -> String {
        LunchFormat.currency(amount)
    }

    // MARK: - Builder

    private static func restaurant(
        id: String, name: String, suburb: String, address: String, latitude: Double, longitude: Double, distance: Double,
        rating: Double, reviews: Int, price: Int, cuisines: [String], dietary: [String], open: Bool, averageCost: Double, features: [String] = []
    ) -> Restaurant {
        Restaurant(
            placeId: id,
            name: name,
            location: suburb,
            address: address,
            phoneNumber: "+61 2 9000 0000",
            website: "https://example.com/\(id)",
            latitude: latitude,
            longitude: longitude,
            distanceFromUser: distance,
            rating: rating,
            reviewCount: reviews,
            priceLevel: price,
            priceRanges: [String(repeating: "$", count: price)],
            cuisineType: cuisines.first,
            cuisineTypes: cuisines,
            supportedDietaryRestrictions: dietary,
            hasVerifiedDietaryInfo: !dietary.isEmpty,
            communityVerificationCount: dietary.isEmpty ? 0 : 12,
            openingHours: ["Mon-Fri 11:00-21:00", "Sat-Sun 11:30-21:30"],
            isOpenNow: open,
            features: features,
            averageMealCost: averageCost,
            cachedAtEpochSeconds: 1_756_800_000
        )
    }
}

/// Shared number formatting for money and distances; the UI edge of the AUD-only v1.
enum LunchFormat {
    static let currencyCode = "AUD"

    /// Whole dollars, e.g. "$124". Used for budgets and ring labels.
    static func currency(_ amount: Double) -> String {
        amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(Locale(identifier: "en_AU")))
    }

    /// Dollars and cents, e.g. "$18.50". Used for individual meals.
    static func currencyExact(_ amount: Double) -> String {
        amount.formatted(.currency(code: currencyCode).precision(.fractionLength(2)).locale(Locale(identifier: "en_AU")))
    }
}
