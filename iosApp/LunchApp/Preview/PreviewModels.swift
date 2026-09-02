//
//  PreviewModels.swift
//  LunchApp
//
//  Small view-facing value types used by the design-system components and their previews.
//  Field names follow the Kotlin contract in
//  shared/src/commonMain/kotlin/au/iapp/lunch/core/model/Models.kt so the mapping from the
//  shared framework is mechanical once it is linked. Only the fields components display are
//  included. `LunchGroup` keeps the Kotlin name instead of `Group` to avoid shadowing
//  SwiftUI.Group.
//

import Foundation

struct Restaurant: Identifiable, Hashable {
    let placeId: String
    let name: String
    let location: String
    var address: String?
    var distanceFromUser: Double?   // kilometres
    var rating: Double?
    var reviewCount: Int?
    var priceLevel: Int?            // 1...4, the number of dollar signs
    var cuisineTypes: [String] = []
    var isOpenNow: Bool = false
    var photoUrl: URL?

    var id: String { placeId }

    /// "$" to "$$$$"; nil when the price level is unknown.
    var priceLabel: String? {
        guard let priceLevel, priceLevel > 0 else { return nil }
        return String(repeating: "$", count: priceLevel)
    }
}

struct Meal: Identifiable, Hashable {
    let id: Int
    let restaurantName: String?
    let mealType: String
    let cost: Double
    let date: Date
    var notes: String?
}

struct WeeklyBudget: Hashable {
    let weeklyCapacity: Double
    let currentSpent: Double
    let experiencesLogged: Int
    let targetExperiences: Int

    var remainingCapacity: Double { max(0, weeklyCapacity - currentSpent) }
    var capacityProgress: Double { weeklyCapacity > 0 ? currentSpent / weeklyCapacity : 0 }
    var experienceProgress: Double { targetExperiences > 0 ? Double(experiencesLogged) / Double(targetExperiences) : 0 }
}

struct LunchGroup: Identifiable, Hashable {
    let id: String
    let hostName: String
    let name: String
    let scheduledAt: Date
    var placeName: String?
    var placeAddress: String?
    let inviteCode: String
}

enum RsvpStatus: Hashable {
    case pending, accepted, declined
}

struct Rsvp: Identifiable, Hashable {
    let id: String
    let displayName: String
    let status: RsvpStatus
}

struct ProPackage: Identifiable, Hashable {
    /// RevenueCat package identifier, e.g. "$rc_annual".
    let identifier: String
    let productId: String
    let localizedPrice: String
    let periodLabel: String
    let hasFreeTrial: Bool
    var trialLabel: String?

    var id: String { identifier }
}

// MARK: - Sample data

enum PreviewData {
    static let greenGardenBowls = Restaurant(
        placeId: "place_green_garden",
        name: "Green Garden Bowls",
        location: "Surry Hills",
        address: "12 Crown Street, Surry Hills NSW",
        distanceFromUser: 0.8,
        rating: 4.8,
        reviewCount: 214,
        priceLevel: 2,
        cuisineTypes: ["Salads", "Healthy", "Vegan"],
        isOpenNow: true
    )

    static let sakuraSushi = Restaurant(
        placeId: "place_sakura",
        name: "Sakura Sushi House",
        location: "Darlinghurst",
        address: "88 Oxford Street, Darlinghurst NSW",
        distanceFromUser: 1.4,
        rating: 4.6,
        reviewCount: 98,
        priceLevel: 3,
        cuisineTypes: ["Japanese", "Seafood", "Sushi"],
        isOpenNow: false
    )

    static let pastaCorner = Restaurant(
        placeId: "place_pasta",
        name: "Pasta Corner",
        location: "Redfern",
        address: "3 Regent Street, Redfern NSW",
        distanceFromUser: 2.3,
        rating: 4.2,
        reviewCount: 61,
        priceLevel: 2,
        cuisineTypes: ["Italian", "Pasta"],
        isOpenNow: true
    )

    static let restaurants = [greenGardenBowls, sakuraSushi, pastaCorner]

    /// Verbatim reason strings from the core `RecommendationEngine`.
    static let reasons = ["Perfect budget match ($$)", "Very close to you (0.8km)", "Open right now"]

    static let meals = [
        Meal(id: 1, restaurantName: "Green Garden Bowls", mealType: "lunch", cost: 18.5, date: .now),
        Meal(id: 2, restaurantName: "Sakura Sushi House", mealType: "dinner", cost: 42.0, date: .now.addingTimeInterval(-86_400)),
        Meal(id: 3, restaurantName: nil, mealType: "snack", cost: 6.0, date: .now.addingTimeInterval(-172_800), notes: "Flat white and a muffin"),
    ]

    static let weeklyBudget = WeeklyBudget(weeklyCapacity: 200, currentSpent: 124, experiencesLogged: 3, targetExperiences: 5)
    static let weeklyBudgetOver = WeeklyBudget(weeklyCapacity: 200, currentSpent: 231, experiencesLogged: 6, targetExperiences: 5)

    static let group = LunchGroup(
        id: "grp_1",
        hostName: "Ray",
        name: "Thursday team lunch",
        scheduledAt: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now,
        placeName: "Green Garden Bowls",
        placeAddress: "12 Crown Street, Surry Hills NSW",
        inviteCode: "K7P2QX"
    )

    static let rsvps = [
        Rsvp(id: "r1", displayName: "Ray", status: .accepted),
        Rsvp(id: "r2", displayName: "Mei", status: .accepted),
        Rsvp(id: "r3", displayName: "Tom", status: .pending),
        Rsvp(id: "r4", displayName: "Aisha", status: .declined),
    ]

    static let yearlyPackage = ProPackage(
        identifier: "$rc_annual",
        productId: "au.iapp.lunch.pro.yearly",
        localizedPrice: "A$19.99",
        periodLabel: "year",
        hasFreeTrial: true,
        trialLabel: "7 days"
    )

    static let monthlyPackage = ProPackage(
        identifier: "$rc_monthly",
        productId: "au.iapp.lunch.pro.monthly",
        localizedPrice: "A$4.99",
        periodLabel: "month",
        hasFreeTrial: false
    )

    static let inviteUrl = "https://lunch.iapp.au/invite/K7P2QX"

    /// Australian-dollar formatting shared by previews and the gallery.
    static func currency(_ amount: Double) -> String {
        amount.formatted(.currency(code: "AUD").precision(.fractionLength(0)))
    }
}
