//
//  Models.swift
//  LunchApp
//
//  Swift value types mirroring shared/src/commonMain/kotlin/au/iapp/lunch/core/model/Models.kt
//  one-to-one (same type and field names, same defaults). Timestamps stay epoch SECONDS as
//  `Int64`; the `Date` conveniences at the bottom of each type are for the UI edge only. Kotlin
//  enum constants are SCREAMING_CASE; here they are lowerCamelCase with the same words, so the
//  SKIE adapter maps them mechanically (see Core/README.md). `LunchGroup` keeps the Kotlin name
//  rather than `Group` to avoid shadowing SwiftUI.Group.
//

import Foundation

nonisolated enum AllergenSafetyLevel: Int, Hashable, Codable {
    case strict, moderate, lenient
}

/// Mirrors the JSON stored in users.preferences by the Flutter app; keys and defaults are identical.
nonisolated struct UserPreferences: Hashable, Codable {
    var dietaryRestrictions: [String] = []
    var cuisinePreferences: [String] = []
    var allergens: [String] = []
    /// Stored as the enum index (0 strict, 1 moderate, 2 lenient).
    var allergenSafetyLevels: [String: Int] = [:]
    var contextualPreferences: [String: [String]] = [:]
    var cuisineRatings: [String: Double] = [:]
    var restaurantVisitCounts: [String: Int] = [:]
    var budgetLevel: Int = 2
    var maxTravelDistance: Double = 5.0
    var includeChains: Bool = true
    var mealFrequencyPerDay: Int = 3
    var weeklyBudget: Double = 200.0
    var enableLocationServices: Bool = true
    var showMapView: Bool = true
    var mapZoomLevel: Int = 14
    var lastKnownLocation: [Double]?
    var requireDietaryVerification: Bool = true
    var minimumRating: Double = 3.0
    var preferredPriceRanges: [String] = ["$", "$$"]
    var avoidBusyTimes: Bool = false
    var accessibilityRequirements: [String: Bool] = [:]
}

nonisolated struct UserProfile: Hashable, Codable, Identifiable {
    let id: Int64
    var name: String
    var preferences: UserPreferences
    let createdAtEpochSeconds: Int64
}

nonisolated struct Meal: Hashable, Codable {
    var id: Int64?
    var userId: Int64
    var restaurantId: String?
    var restaurantName: String?
    /// One of breakfast, lunch, dinner, snack, dining_out, delivery, takeout, groceries.
    var mealType: String
    var cost: Double
    var dateEpochSeconds: Int64
    var notes: String?
    var photoIds: [String] = []

    var date: Date { Date(timeIntervalSince1970: TimeInterval(dateEpochSeconds)) }
}

nonisolated struct BudgetEntry: Hashable, Codable {
    var id: Int64?
    var userId: Int64
    var amount: Double
    var category: String
    var dateEpochSeconds: Int64
}

nonisolated struct RestaurantReview: Hashable, Codable, Identifiable {
    let reviewId: String
    var authorName: String
    var authorPhotoUrl: String?
    var rating: Int
    var text: String?
    var timeEpochSeconds: Int64
    var relativeTimeDescription: String = ""

    var id: String { reviewId }
}

nonisolated struct Restaurant: Hashable, Codable, Identifiable {
    let placeId: String
    var name: String
    var location: String
    var address: String?
    var phoneNumber: String?
    var website: String?
    var latitude: Double?
    var longitude: Double?
    /// Kilometres from the user at fetch time.
    var distanceFromUser: Double?
    var rating: Double?
    var reviewCount: Int?
    /// 1..4, matching the number of dollar signs.
    var priceLevel: Int?
    var priceRanges: [String] = []
    var cuisineType: String?
    var cuisineTypes: [String] = []
    var supportedDietaryRestrictions: [String] = []
    var allergenInfo: [String] = []
    var dietaryCompatibilityScores: [String: Double] = [:]
    var hasVerifiedDietaryInfo: Bool = false
    var communityVerificationCount: Int = 0
    var openingHours: [String] = []
    var isOpenNow: Bool = false
    var currentWaitTime: String?
    var features: [String] = []
    var averageMealCost: Double?
    var valueScore: Double?
    var mealTypeAverageCosts: [String: Double] = [:]
    var recentReviews: [RestaurantReview] = []
    var cachedAtEpochSeconds: Int64 = 0
    var lastVerifiedEpochSeconds: Int64?
    var photoReference: String?
    var photoReferences: [String] = []
    /// Absolute URL served by the backend for the first photo, when available.
    var photoUrl: String?

    var id: String { placeId }

    /// "$" to "$$$$"; nil when the price level is unknown.
    var priceLabel: String? {
        guard let priceLevel, priceLevel > 0 else { return nil }
        return String(repeating: "$", count: priceLevel)
    }

    /// `photoUrl` parsed for `AsyncImage`.
    var photoURL: URL? { photoUrl.flatMap(URL.init(string:)) }
}

nonisolated enum SortOption: String, CaseIterable, Hashable {
    case relevance, price, distance, rating
}

nonisolated struct AiRecommendation: Hashable, Codable, Identifiable {
    let id: String
    var userId: Int64
    var restaurants: [Restaurant]
    var reasoning: String
    var factorWeights: [String: Double] = [:]
    var overallConfidence: Double
    var investmentSummary: String?
    var generatedAtEpochSeconds: Int64
    var wasAccepted: Bool = false
    var userFeedback: String?

    var confidenceLevel: String {
        if overallConfidence >= 0.8 { return "High" }
        if overallConfidence >= 0.6 { return "Medium" }
        return "Low"
    }
}

// MARK: - Budget and achievements

nonisolated struct WeeklyBudgetState: Hashable {
    var weeklyCapacity: Double
    var currentSpent: Double
    var remainingCapacity: Double
    var experiencesLogged: Int
    var targetExperiences: Int
    var weekStartEpochSeconds: Int64

    init(weeklyCapacity: Double, currentSpent: Double, remainingCapacity: Double? = nil, experiencesLogged: Int, targetExperiences: Int, weekStartEpochSeconds: Int64 = 0) {
        self.weeklyCapacity = weeklyCapacity
        self.currentSpent = currentSpent
        self.remainingCapacity = remainingCapacity ?? max(0, weeklyCapacity - currentSpent)
        self.experiencesLogged = experiencesLogged
        self.targetExperiences = targetExperiences
        self.weekStartEpochSeconds = weekStartEpochSeconds
    }

    var capacityProgress: Double { weeklyCapacity > 0 ? currentSpent / weeklyCapacity : 0 }
    var experienceProgress: Double { targetExperiences > 0 ? Double(experiencesLogged) / Double(targetExperiences) : 0 }
}

nonisolated enum ImpactLevel: Hashable { case low, moderate, high, veryHigh }
nonisolated enum GuidanceLevel: Hashable { case excellent, good, moderate, high }

nonisolated struct MealImpact: Hashable {
    var mealCost: Double
    var projectedSpent: Double
    var projectedRemaining: Double
    var impactLevel: ImpactLevel
    var guidanceLevel: GuidanceLevel
    var message: String
    var exceedsCapacity: Bool
}

nonisolated struct BudgetImpact: Hashable {
    var percentageOfWeeklyBudget: Double
    var impactLevel: ImpactLevel?
    var message: String
    var remainingBudget: Double
}

nonisolated struct Achievement: Hashable, Codable, Identifiable {
    let id: String
    var title: String
    var description: String
    var category: String
    var points: Int
    var iconName: String
    var isUnlocked: Bool = false
    var unlockedAtEpochSeconds: Int64?
}

nonisolated struct MealCategory: Hashable, Identifiable {
    let id: String
    var name: String
    var description: String
    var icon: String
    var suggestedBudget: Double
}

// MARK: - Monetisation

nonisolated enum Tier: Hashable { case free, pro }

/// Free-tier allowances. Single source of truth for gates on the client.
nonisolated enum FreeLimits {
    static let aiRequestsPerDay = 1
    static let favourites = 10
    static let historyDays = 30
}

nonisolated enum GateReason: Hashable {
    case ok, aiDailyLimit, favouritesLimit, historyWindow, hostRequiresPro, signInRequired
}

nonisolated struct GateDecision: Hashable {
    var allowed: Bool
    var reason: GateReason

    static let allowed = GateDecision(allowed: true, reason: .ok)
    static func denied(_ reason: GateReason) -> GateDecision { GateDecision(allowed: false, reason: reason) }
}

nonisolated struct ProPackage: Hashable, Identifiable {
    /// RevenueCat package identifier, e.g. "$rc_annual".
    let identifier: String
    var productId: String
    var localizedPrice: String
    var periodLabel: String
    var hasFreeTrial: Bool
    var trialLabel: String?

    var id: String { identifier }
}

nonisolated struct ProOfferings: Hashable {
    var monthly: ProPackage?
    var yearly: ProPackage?
}

nonisolated struct SubscriptionStatus: Hashable {
    var isPro: Bool
    var productId: String?
    var expiresAtEpochSeconds: Int64?
    var willRenew: Bool = false
    var managementUrl: String?

    static let free = SubscriptionStatus(isPro: false)

    var expiresAt: Date? { expiresAtEpochSeconds.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
}

// MARK: - Auth and social

nonisolated struct AuthSession: Hashable {
    var userId: String
    var email: String?
    var displayName: String?
}

/// Wire form is lowercase (`pending`, `accepted`, `declined`), matching the backend.
nonisolated enum RsvpStatus: String, Hashable, Codable {
    case pending, accepted, declined
}

nonisolated struct LunchGroup: Hashable, Codable, Identifiable {
    let id: String
    var hostId: String
    var hostName: String
    var name: String
    var scheduledAtEpochSeconds: Int64
    var areaLatitude: Double
    var areaLongitude: Double
    var radiusKm: Double
    var placeId: String?
    var placeName: String?
    var placeAddress: String?
    var inviteCode: String
    var createdAtEpochSeconds: Int64

    var scheduledAt: Date { Date(timeIntervalSince1970: TimeInterval(scheduledAtEpochSeconds)) }
}

nonisolated struct Rsvp: Hashable, Codable, Identifiable {
    let id: String
    var groupId: String
    var guestUserId: String?
    var displayName: String
    var status: RsvpStatus
    var respondedAtEpochSeconds: Int64?
}

nonisolated struct GroupProposal: Hashable, Codable, Identifiable {
    var restaurant: Restaurant
    var reasons: [String]

    var id: String { restaurant.placeId }
}

/// What a guest sees when opening an invitation link.
nonisolated struct Invitation: Hashable, Codable {
    var group: LunchGroup
    var attendees: [Rsvp]
    var myStatus: RsvpStatus?
    var inviteUrl: String
}

nonisolated struct Location: Hashable, Codable {
    var latitude: Double
    var longitude: Double
    var accuracyMetres: Double?
}

// MARK: - Errors

/// Mirrors the sealed `CoreError`. Every throwing call in the contracts throws one of these.
nonisolated enum CoreError: Error, Hashable {
    case offline
    case service(code: String, message: String)
    case gate(GateReason)
    case notSignedIn
    case unknown(String)
}

// These are value-only transfer objects used by AsyncStream. Codable collections
// and Foundation scalar values are immutable across each yielded copy.
extension UserPreferences: @unchecked Sendable {}
extension UserProfile: @unchecked Sendable {}
extension Meal: @unchecked Sendable {}
extension RestaurantReview: @unchecked Sendable {}
extension Restaurant: @unchecked Sendable {}
extension Achievement: @unchecked Sendable {}
extension GateDecision: @unchecked Sendable {}
extension SubscriptionStatus: @unchecked Sendable {}
extension AuthSession: @unchecked Sendable {}
extension LunchGroup: @unchecked Sendable {}
extension Rsvp: @unchecked Sendable {}
