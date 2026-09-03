//
//  SwiftRecommendationEngine.swift
//  LunchApp
//
//  Pure Swift port of RecommendationEngineImpl.kt (itself a port of the Flutter rules). Weights
//  0.4 / 0.3 / 0.2 / 0.1, best-match threshold 0.1, reason strings verbatim.
//

import Foundation

nonisolated struct SwiftRecommendationEngine: RecommendationEngine {
    static let scoreThreshold = 0.1
    private static let dietaryScoreThreshold = 0.8
    private static let chainIndicators = ["McDonald", "Subway", "Starbucks", "KFC", "Pizza Hut"]
    private static let discoverChainKeywords = ["mcdonalds", "subway", "kfc", "burger king", "pizza hut", "dominos"]

    func compatibilityScore(restaurant: Restaurant, prefs: UserPreferences?) -> Double {
        var score = 0.0
        guard let prefs else {
            return restaurant.rating.map { $0 / 5.0 } ?? 0.5
        }
        // Budget level matching (weight: 40%)
        if let priceLevel = restaurant.priceLevel {
            let priceDiff = abs(priceLevel - prefs.budgetLevel)
            score += Double(4 - priceDiff) * 0.4
        } else {
            score += 2.0 * 0.4
        }
        // Distance preference (weight: 30%)
        if let distance = restaurant.distanceFromUser {
            if distance <= prefs.maxTravelDistance {
                score += (1.0 - distance / prefs.maxTravelDistance) * 0.3
            }
        } else {
            score += 0.5 * 0.3
        }
        // Rating (weight: 20%)
        if let rating = restaurant.rating, rating > 0 {
            score += (rating / 5.0) * 0.2
        } else {
            score += 0.5 * 0.2
        }
        // Open now bonus (weight: 10%)
        if restaurant.isOpenNow {
            score += 0.1
        }
        return score
    }

    func bestMatch(candidates: [Restaurant], prefs: UserPreferences?, rejected: Set<String>) -> Restaurant? {
        var best: Restaurant?
        var bestScore = -1.0
        for restaurant in candidates where !rejected.contains(restaurant.placeId) {
            let score = compatibilityScore(restaurant: restaurant, prefs: prefs)
            if score > bestScore {
                bestScore = score
                best = restaurant
            }
        }
        return bestScore > Self.scoreThreshold ? best : nil
    }

    func reasons(restaurant: Restaurant, prefs: UserPreferences?) -> [String] {
        var reasons: [String] = []
        if let prefs {
            if let priceLevel = restaurant.priceLevel {
                if priceLevel == prefs.budgetLevel {
                    reasons.append("Perfect budget match (\(String(repeating: "$", count: prefs.budgetLevel)))")
                } else if abs(priceLevel - prefs.budgetLevel) <= 1 {
                    reasons.append("Close to your budget range")
                }
            }
            if let distance = restaurant.distanceFromUser {
                if distance <= prefs.maxTravelDistance * 0.5 {
                    reasons.append("Very close to you (\(distance.fixed1)km)")
                } else if distance <= prefs.maxTravelDistance {
                    reasons.append("Within your preferred distance")
                }
            }
            if let rating = restaurant.rating, rating >= 4.0 {
                reasons.append("Highly rated (\(rating.fixed1)/5)")
            }
            if restaurant.isOpenNow {
                reasons.append("Open right now")
            }
            if let cuisine = restaurant.cuisineType {
                reasons.append("Great \(cuisine.lowercased()) cuisine")
            }
        }
        if reasons.isEmpty {
            if let rating = restaurant.rating, rating > 0 {
                reasons.append("Good ratings (\(rating.fixed1)/5)")
            }
            if let cuisine = restaurant.cuisineType {
                reasons.append("\(cuisine) cuisine")
            }
            if reasons.isEmpty {
                reasons.append("Popular choice in your area")
            }
        }
        return reasons
    }

    func discoverReasons(restaurant: Restaurant, prefs: UserPreferences?) -> [String] {
        guard let prefs else { return ["Great choice for a delicious meal!"] }
        var reasons: [String] = []
        if let priceLevel = restaurant.priceLevel, priceLevel <= prefs.budgetLevel {
            reasons.append("Fits your \(String(repeating: "$", count: prefs.budgetLevel)) budget perfectly")
        }
        if let distance = restaurant.distanceFromUser, distance <= prefs.maxTravelDistance {
            reasons.append("Only \(distance.fixed1)km away - perfect distance")
        }
        if let rating = restaurant.rating, rating >= 4.0 {
            reasons.append("Highly rated (\(rating.fixed1)) by other diners")
        }
        if restaurant.isOpenNow {
            reasons.append("Open right now - ready when you are")
        }
        if let cuisine = restaurant.cuisineType {
            reasons.append("Delicious \(cuisine.lowercased()) cuisine")
        }
        if !isChainRestaurant(restaurant) {
            reasons.append("Local favorite - unique dining experience")
        }
        if reasons.isEmpty {
            reasons.append("Great choice for a satisfying meal")
        }
        return reasons
    }

    func sort(restaurants: [Restaurant], option: SortOption, prefs: UserPreferences?) -> [Restaurant] {
        // `sorted(by:)` is not guaranteed stable, so sort indexed pairs and break ties on position.
        let indexed = Array(restaurants.enumerated())
        let sorted = indexed.sorted { lhs, rhs in
            let order = compare(lhs.element, rhs.element, option: option, prefs: prefs)
            return order == 0 ? lhs.offset < rhs.offset : order < 0
        }
        return sorted.map(\.element)
    }

    private func compare(_ a: Restaurant, _ b: Restaurant, option: SortOption, prefs: UserPreferences?) -> Int {
        switch option {
        case .relevance:
            let reasonsA = discoverReasons(restaurant: a, prefs: prefs).count
            let reasonsB = discoverReasons(restaurant: b, prefs: prefs).count
            if reasonsA != reasonsB { return reasonsB < reasonsA ? -1 : 1 }
            return compareDoubles(b.rating ?? 0, a.rating ?? 0)
        case .price:
            let pa = a.priceLevel ?? 0, pb = b.priceLevel ?? 0
            return pa == pb ? 0 : (pa < pb ? -1 : 1)
        case .distance:
            return compareDoubles(a.distanceFromUser ?? .infinity, b.distanceFromUser ?? .infinity)
        case .rating:
            return compareDoubles(b.rating ?? 0, a.rating ?? 0)
        }
    }

    private func compareDoubles(_ a: Double, _ b: Double) -> Int {
        a == b ? 0 : (a < b ? -1 : 1)
    }

    func applyPreferenceFilters(restaurants: [Restaurant], prefs: UserPreferences?) -> [Restaurant] {
        guard let prefs else { return restaurants }
        return restaurants.filter { restaurant in
            if let distance = restaurant.distanceFromUser, distance > prefs.maxTravelDistance { return false }
            if let rating = restaurant.rating, rating < prefs.minimumRating { return false }
            if let priceLevel = restaurant.priceLevel, prefs.budgetLevel > 0, priceLevel > prefs.budgetLevel { return false }
            if prefs.requireDietaryVerification, !restaurant.hasVerifiedDietaryInfo {
                let score = dietaryCompatibility(restaurant: restaurant, dietaryRestrictions: prefs.dietaryRestrictions, allergens: prefs.allergens)
                if score < Self.dietaryScoreThreshold { return false }
            }
            if !prefs.includeChains {
                let name = restaurant.name.lowercased()
                if Self.chainIndicators.contains(where: { name.contains($0.lowercased()) }) { return false }
            }
            return true
        }
    }

    func dietaryCompatibility(restaurant: Restaurant, dietaryRestrictions: [String], allergens: [String]) -> Double {
        if dietaryRestrictions.isEmpty, allergens.isEmpty { return 1.0 }
        var score = 0.0
        let total = dietaryRestrictions.count + allergens.count
        for restriction in dietaryRestrictions {
            if restaurant.supportedDietaryRestrictions.contains(restriction) {
                score += 1.0
            } else if let partial = restaurant.dietaryCompatibilityScores[restriction] {
                score += partial
            }
        }
        for allergen in allergens {
            score += restaurant.allergenInfo.contains(allergen) ? 0.1 : 1.0
        }
        return total > 0 ? score / Double(total) : 1.0
    }

    private func isChainRestaurant(_ restaurant: Restaurant) -> Bool {
        let name = restaurant.name.lowercased()
        return Self.discoverChainKeywords.contains(where: { name.contains($0) })
    }
}

nonisolated extension Double {
    /// Kotlin `toFixed1()`: one decimal, dot separator, no grouping (e.g. "0.8", "4.6").
    var fixed1: String { String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), self) }
}
