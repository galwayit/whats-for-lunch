//
//  EngineVectorTests.swift
//  LunchAppTests
//
//  @file EngineVectorTests.swift
//  @description The four pure Swift engines against the shared engine_vectors.json fixture, so the
//  Swift ports stay byte-for-byte with the Kotlin core (and the original Dart).
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Testing
@testable import LunchApp

struct RecommendationEngineVectorTests {
    let vectors = try! EngineVectors.load()
    let engine = SwiftRecommendationEngine()

    @Test func should_match_compatibility_scores_when_compared_with_fixture() {
        for c in vectors.compatibilityScore {
            let actual = engine.compatibilityScore(restaurant: vectors.restaurant(c.placeId), prefs: vectors.preferences(c.prefs))
            #expect(abs(actual - c.expected) < 0.0005, "\(c.prefs)/\(c.placeId): \(actual) vs \(c.expected)")
        }
    }

    @Test func should_match_reasons_when_compared_with_fixture() {
        for c in vectors.reasons {
            let actual = engine.reasons(restaurant: vectors.restaurant(c.placeId), prefs: vectors.preferences(c.prefs))
            #expect(actual == c.expected, "\(c.prefs)/\(c.placeId)")
        }
    }

    @Test func should_match_discover_reasons_when_compared_with_fixture() {
        for c in vectors.discoverReasons {
            let actual = engine.discoverReasons(restaurant: vectors.restaurant(c.placeId), prefs: vectors.preferences(c.prefs))
            #expect(actual == c.expected, "\(c.prefs)/\(c.placeId)")
        }
    }

    @Test func should_match_best_match_when_compared_with_fixture() {
        for c in vectors.bestMatch {
            let actual = engine.bestMatch(candidates: vectors.allRestaurants, prefs: vectors.preferences(c.prefs), rejected: Set(c.rejected))
            #expect(actual?.placeId == c.expected, "\(c.prefs) rejected \(c.rejected)")
        }
    }

    @Test func should_match_sort_order_when_compared_with_fixture() {
        for c in vectors.sort {
            let option = SortOption(rawValue: c.option.lowercased())!
            let actual = engine.sort(restaurants: vectors.allRestaurants, option: option, prefs: vectors.preferences(c.prefs)).map(\.placeId)
            #expect(actual == c.expected, "\(c.prefs)/\(c.option)")
        }
    }

    @Test func should_match_preference_filters_when_compared_with_fixture() {
        for c in vectors.applyPreferenceFilters {
            let actual = engine.applyPreferenceFilters(restaurants: vectors.allRestaurants, prefs: vectors.preferences(c.prefs)).map(\.placeId)
            #expect(actual == c.expected, Comment(rawValue: c.prefs))
        }
    }

    @Test func should_match_dietary_compatibility_when_compared_with_fixture() {
        for c in vectors.dietaryCompatibility {
            let actual = engine.dietaryCompatibility(restaurant: vectors.restaurant(c.placeId), dietaryRestrictions: c.restrictions, allergens: c.allergens)
            #expect(abs(actual - c.expected) < 0.0005, "\(c.placeId) \(c.restrictions) \(c.allergens)")
        }
    }
}

struct BudgetEngineVectorTests {
    let vectors = try! EngineVectors.load()
    let engine = SwiftBudgetEngine()

    @Test func should_match_target_experiences_when_compared_with_fixture() {
        for c in vectors.budget.targetExperiences {
            var prefs = UserPreferences()
            prefs.mealFrequencyPerDay = c.mealFrequencyPerDay
            prefs.budgetLevel = c.budgetLevel
            #expect(engine.targetExperiences(prefs: prefs) == c.expected, "\(c.mealFrequencyPerDay)/\(c.budgetLevel)")
        }
    }

    @Test func should_match_meal_impact_when_compared_with_fixture() {
        for c in vectors.budget.mealImpact {
            let state = WeeklyBudgetState(weeklyCapacity: c.weeklyCapacity, currentSpent: c.currentSpent, remainingCapacity: 0, experiencesLogged: 0, targetExperiences: 0)
            let actual = engine.mealImpact(state: state, mealCost: c.mealCost)
            #expect(actual.mealCost == c.expected.mealCost)
            #expect(abs(actual.projectedSpent - c.expected.projectedSpent) < 0.0005)
            #expect(abs(actual.projectedRemaining - c.expected.projectedRemaining) < 0.0005)
            #expect(actual.impactLevel.vectorName == c.expected.impactLevel.uppercased())
            #expect(actual.guidanceLevel.vectorName == c.expected.guidanceLevel.uppercased())
            #expect(actual.message == c.expected.message)
            #expect(actual.exceedsCapacity == c.expected.exceedsCapacity)
        }
    }

    @Test func should_match_budget_impact_when_compared_with_fixture() {
        for c in vectors.budget.budgetImpact {
            var prefs = UserPreferences()
            prefs.weeklyBudget = c.weeklyBudget
            let actual = engine.budgetImpact(prefs: prefs, cost: c.cost)
            #expect(abs(actual.percentageOfWeeklyBudget - c.expected.percentageOfWeeklyBudget) < 0.0005)
            #expect(actual.impactLevel?.vectorName == c.expected.impactLevel?.uppercased())
            #expect(actual.message == c.expected.message)
            #expect(abs(actual.remainingBudget - c.expected.remainingBudget) < 0.0005)
        }
    }

    @Test func should_match_usage_and_guidance_levels_when_compared_with_fixture() {
        for c in vectors.budget.levels {
            let state = WeeklyBudgetState(weeklyCapacity: 1, currentSpent: c.progress, remainingCapacity: 0, experiencesLogged: 0, targetExperiences: 0)
            #expect(engine.capacityUsageLevel(state: state).vectorName == c.capacityUsageLevel, "progress \(c.progress)")
            #expect(engine.guidanceLevel(state: state).vectorName == c.guidanceLevel, "progress \(c.progress)")
        }
    }
}

struct AchievementEngineVectorTests {
    let vectors = try! EngineVectors.load()

    @Test func should_match_level_names_when_compared_with_fixture() {
        let engine = SwiftAchievementEngine()
        for c in vectors.level {
            #expect(engine.level(points: c.points) == c.expected, "points \(c.points)")
        }
    }
}

struct MealDefaultsVectorTests {
    let vectors = try! EngineVectors.load()

    @Test func should_match_smart_meal_type_when_compared_with_fixture() {
        let defaults = SwiftMealDefaults()
        for c in vectors.smartMealType {
            #expect(defaults.smartMealType(hourOfDay: c.hour) == c.expected, "hour \(c.hour)")
        }
    }

    @Test func should_format_one_decimal_like_dart_when_compared_with_fixture() {
        for c in vectors.toStringAsFixed1 {
            #expect(c.value.fixed1 == c.expected, "value \(c.value)")
        }
    }
}
