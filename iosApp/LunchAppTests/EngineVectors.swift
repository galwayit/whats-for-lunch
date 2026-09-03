//
//  EngineVectors.swift
//  LunchAppTests
//
//  @file EngineVectors.swift
//  @description Loads shared/src/commonTest/resources/fixtures/engine_vectors.json, the Dart-derived
//  vectors every engine port (Kotlin and Swift) must reproduce, and maps them onto the Swift models.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
@testable import LunchApp

nonisolated struct EngineVectors: Decodable {
    struct RestaurantVector: Decodable {
        var placeId: String
        var name: String
        var location: String
        var priceLevel: Int?
        var distanceFromUser: Double?
        var rating: Double?
        var isOpenNow: Bool
        var cuisineType: String?
        var supportedDietaryRestrictions: [String]
        var allergenInfo: [String]
        var dietaryCompatibilityScores: [String: Double]
        var hasVerifiedDietaryInfo: Bool

        var restaurant: Restaurant {
            Restaurant(
                placeId: placeId,
                name: name,
                location: location,
                distanceFromUser: distanceFromUser,
                rating: rating,
                priceLevel: priceLevel,
                cuisineType: cuisineType,
                supportedDietaryRestrictions: supportedDietaryRestrictions,
                allergenInfo: allergenInfo,
                dietaryCompatibilityScores: dietaryCompatibilityScores,
                hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
                isOpenNow: isOpenNow
            )
        }
    }

    struct PrefsVector: Decodable {
        var budgetLevel: Int
        var maxTravelDistance: Double
        var includeChains: Bool
        var minimumRating: Double
        var requireDietaryVerification: Bool
        var dietaryRestrictions: [String]
        var allergens: [String]
        var mealFrequencyPerDay: Int
        var weeklyBudget: Double

        var preferences: UserPreferences {
            var prefs = UserPreferences()
            prefs.budgetLevel = budgetLevel
            prefs.maxTravelDistance = maxTravelDistance
            prefs.includeChains = includeChains
            prefs.minimumRating = minimumRating
            prefs.requireDietaryVerification = requireDietaryVerification
            prefs.dietaryRestrictions = dietaryRestrictions
            prefs.allergens = allergens
            prefs.mealFrequencyPerDay = mealFrequencyPerDay
            prefs.weeklyBudget = weeklyBudget
            return prefs
        }
    }

    struct ScoreCase: Decodable { var prefs: String; var placeId: String; var expected: Double }
    struct ReasonsCase: Decodable { var prefs: String; var placeId: String; var expected: [String] }
    struct BestMatchCase: Decodable { var prefs: String; var rejected: [String]; var expected: String? }
    struct SortCase: Decodable { var prefs: String; var option: String; var expected: [String] }
    struct FilterCase: Decodable { var prefs: String; var expected: [String] }
    struct DietaryCase: Decodable { var placeId: String; var restrictions: [String]; var allergens: [String]; var expected: Double }
    struct HourCase: Decodable { var hour: Int; var expected: String }
    struct LevelCase: Decodable { var points: Int; var expected: String }
    struct FixedCase: Decodable { var value: Double; var expected: String }

    struct Budget: Decodable {
        struct TargetCase: Decodable { var mealFrequencyPerDay: Int; var budgetLevel: Int; var expected: Int }
        struct MealImpactCase: Decodable {
            struct Expected: Decodable {
                var mealCost: Double
                var projectedSpent: Double
                var projectedRemaining: Double
                var impactLevel: String
                var guidanceLevel: String
                var message: String
                var exceedsCapacity: Bool
            }
            var currentSpent: Double
            var weeklyCapacity: Double
            var mealCost: Double
            var expected: Expected
        }
        struct BudgetImpactCase: Decodable {
            struct Expected: Decodable {
                var percentageOfWeeklyBudget: Double
                var impactLevel: String?
                var message: String
                var remainingBudget: Double
            }
            var weeklyBudget: Double
            var cost: Double?
            var expected: Expected
        }
        struct LevelsCase: Decodable { var progress: Double; var capacityUsageLevel: String; var guidanceLevel: String }

        var targetExperiences: [TargetCase]
        var mealImpact: [MealImpactCase]
        var budgetImpact: [BudgetImpactCase]
        var levels: [LevelsCase]
    }

    var restaurants: [RestaurantVector]
    var prefs: [String: PrefsVector?]
    var compatibilityScore: [ScoreCase]
    var reasons: [ReasonsCase]
    var discoverReasons: [ReasonsCase]
    var bestMatch: [BestMatchCase]
    var sort: [SortCase]
    var applyPreferenceFilters: [FilterCase]
    var dietaryCompatibility: [DietaryCase]
    var budget: Budget
    var smartMealType: [HourCase]
    var level: [LevelCase]
    var toStringAsFixed1: [FixedCase]

    /// The fixture lives in the shared Kotlin module; resolve it from this file's location so the
    /// test needs no bundle resource wiring.
    static func load() throws -> EngineVectors {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // LunchAppTests
            .deletingLastPathComponent() // iosApp
            .deletingLastPathComponent() // repo
        let url = repoRoot.appending(path: "shared/src/commonTest/resources/fixtures/engine_vectors.json")
        return try JSONDecoder().decode(EngineVectors.self, from: Data(contentsOf: url))
    }

    func restaurant(_ placeId: String) -> Restaurant {
        restaurants.first { $0.placeId == placeId }!.restaurant
    }

    var allRestaurants: [Restaurant] { restaurants.map(\.restaurant) }

    /// `"none"` is stored as JSON null and means "no preferences".
    func preferences(_ key: String) -> UserPreferences? {
        prefs[key].flatMap { $0 }?.preferences
    }
}

/// Fixture spelling of the impact and guidance enums (`LOW`, `VERY_HIGH`, `excellent`, …).
nonisolated extension ImpactLevel {
    var vectorName: String {
        switch self {
        case .low: return "LOW"
        case .moderate: return "MODERATE"
        case .high: return "HIGH"
        case .veryHigh: return "VERY_HIGH"
        }
    }
}

nonisolated extension GuidanceLevel {
    var vectorName: String {
        switch self {
        case .excellent: return "EXCELLENT"
        case .good: return "GOOD"
        case .moderate: return "MODERATE"
        case .high: return "HIGH"
        }
    }
}
