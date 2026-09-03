//
//  NotConfiguredCore.swift
//  LunchApp
//
//  Placeholder `LunchCoreClient` used when the shared Kotlin framework is not linked. Every
//  call fails with `CoreError.service(code: "CORE_NOT_LINKED")` and every stream finishes at
//  once, so the app boots and shows the not-linked screen. It also doubles as the checklist of
//  members the `KotlinLunchCore` adapter must implement.
//

import Foundation

enum NotConfigured {
    static let code = "CORE_NOT_LINKED"
    static let error = CoreError.service(code: code, message: "The shared core is not linked in this build.")
    static func empty<T>() -> AsyncStream<T> { AsyncStream { $0.finish() } }
}

final class NotConfiguredCore: LunchCoreClient {
    let users: UserRepository = NotConfiguredUsers()
    let meals: MealRepository = NotConfiguredMeals()
    let restaurants: RestaurantRepository = NotConfiguredRestaurants()
    let favourites: FavouritesRepository = NotConfiguredFavourites()
    let achievements: AchievementRepository = NotConfiguredAchievements()
    let ai: AiRecommendationService = NotConfiguredAi()
    let entitlements: EntitlementRepository = NotConfiguredEntitlements()
    let gates: GateService = NotConfiguredGates()
    let auth: AuthRepository = NotConfiguredAuth()
    let groups: GroupRepository = NotConfiguredGroups()
    let push: PushRegistrar = NotConfiguredPush()
    let recommendation: RecommendationEngine = SwiftRecommendationEngine()
    let budget: BudgetEngine = SwiftBudgetEngine()
    let achievementEngine: AchievementEngine = SwiftAchievementEngine()
    let mealDefaults: MealDefaults = SwiftMealDefaults()
    let clock: LunchClock = SystemLunchClock()
    let location: LocationProvider = NotConfiguredLocation()
}

private final class NotConfiguredUsers: UserRepository {
    var current: UserProfile? { nil }
    var currentUpdates: AsyncStream<UserProfile?> { NotConfigured.empty() }
    var hasCompletedOnboarding: Bool { false }
    var hasCompletedOnboardingUpdates: AsyncStream<Bool> { NotConfigured.empty() }
    func createUser(name: String, preferences: UserPreferences) async throws -> UserProfile { throw NotConfigured.error }
    func updateName(name: String) async throws { throw NotConfigured.error }
    func updatePreferences(preferences: UserPreferences) async throws { throw NotConfigured.error }
}

private final class NotConfiguredMeals: MealRepository {
    func log(meal: Meal) async throws -> Int64 { throw NotConfigured.error }
    func update(meal: Meal) async throws { throw NotConfigured.error }
    func delete(id: Int64) async throws { throw NotConfigured.error }
    func inRange(userId: Int64, startEpochSeconds: Int64, endEpochSeconds: Int64) async throws -> [Meal] { throw NotConfigured.error }
    func observeRecent(userId: Int64, limit: Int, windowDays: Int?) -> AsyncStream<[Meal]> { NotConfigured.empty() }
    func restaurantSuggestions(userId: Int64) async throws -> [String] { throw NotConfigured.error }
}

private final class NotConfiguredRestaurants: RestaurantRepository {
    func searchNearby(location: Location, radiusKm: Double, query: String?, forceRefresh: Bool) async throws -> [Restaurant] { throw NotConfigured.error }
    func details(placeId: String) async throws -> Restaurant { throw NotConfigured.error }
    func reviews(placeId: String) async throws -> [RestaurantReview] { throw NotConfigured.error }
    func cached(placeId: String) async -> Restaurant? { nil }
    func cacheAll(restaurants: [Restaurant]) async {}
    func recordInteraction(userId: Int64, placeId: String, restaurantName: String?, type: String, context: String?) async {}
}

private final class NotConfiguredFavourites: FavouritesRepository {
    func observe(userId: Int64) -> AsyncStream<Set<String>> { NotConfigured.empty() }
    func toggle(userId: Int64, placeId: String, restaurantName: String?) async throws -> GateDecision { throw NotConfigured.error }
    func favouriteRestaurants(userId: Int64) async throws -> [Restaurant] { throw NotConfigured.error }
}

private final class NotConfiguredAchievements: AchievementRepository {
    func observe(userId: Int64) -> AsyncStream<[Achievement]> { NotConfigured.empty() }
    func unlock(userId: Int64, achievements: [Achievement]) async {}
}

private final class NotConfiguredAi: AiRecommendationService {
    func recommend(cravings: String?, maxResults: Int, candidates: [Restaurant]) async throws -> AiRecommendation { throw NotConfigured.error }
    func history(userId: Int64, limit: Int) async throws -> [AiRecommendation] { throw NotConfigured.error }
    func submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Bool) async throws { throw NotConfigured.error }
    func usedToday(userId: Int64) async -> Int { 0 }
}

private final class NotConfiguredEntitlements: EntitlementRepository {
    var isPro: Bool { false }
    var isProUpdates: AsyncStream<Bool> { NotConfigured.empty() }
    var status: SubscriptionStatus { .free }
    var statusUpdates: AsyncStream<SubscriptionStatus> { NotConfigured.empty() }
    var appUserId: String { "" }
    func offerings() async throws -> ProOfferings { throw NotConfigured.error }
    func purchase(packageIdentifier: String) async throws -> SubscriptionStatus { throw NotConfigured.error }
    func restore() async throws -> SubscriptionStatus { throw NotConfigured.error }
    func logIn(userId: String) async throws { throw NotConfigured.error }
    func logOut() async throws { throw NotConfigured.error }
}

private final class NotConfiguredGates: GateService {
    func canRequestAi() async -> GateDecision { .denied(.aiDailyLimit) }
    func canAddFavourite(currentCount: Int) -> GateDecision { .denied(.favouritesLimit) }
    func historyWindowDays() -> Int? { FreeLimits.historyDays }
    func canHostGroup() -> GateDecision { .denied(.hostRequiresPro) }
}

private final class NotConfiguredAuth: AuthRepository {
    var session: AuthSession? { nil }
    var sessionUpdates: AsyncStream<AuthSession?> { NotConfigured.empty() }
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession { throw NotConfigured.error }
    func signInWithGoogle(idToken: String) async throws -> AuthSession { throw NotConfigured.error }
    func signOut() async throws { throw NotConfigured.error }
    func deleteAccount() async throws { throw NotConfigured.error }
}

private final class NotConfiguredGroups: GroupRepository {
    func myGroups() -> AsyncStream<[LunchGroup]> { NotConfigured.empty() }
    func create(name: String, scheduledAtEpochSeconds: Int64, area: Location, radiusKm: Double) async throws -> LunchGroup { throw NotConfigured.error }
    func propose(groupId: String) async throws -> [GroupProposal] { throw NotConfigured.error }
    func confirmPlace(groupId: String, restaurant: Restaurant) async throws -> LunchGroup { throw NotConfigured.error }
    func invitation(code: String) async throws -> Invitation { throw NotConfigured.error }
    func respond(code: String, status: RsvpStatus, displayName: String?) async throws -> Invitation { throw NotConfigured.error }
    func rsvps(groupId: String) -> AsyncStream<[Rsvp]> { NotConfigured.empty() }
    func cancel(groupId: String) async throws { throw NotConfigured.error }
}

private final class NotConfiguredPush: PushRegistrar {
    func register(token: String, platform: String) async throws { throw NotConfigured.error }
}

private final class NotConfiguredLocation: LocationProvider {
    func current() async throws -> Location { throw NotConfigured.error }
    func hasPermission() async -> Bool { false }
}
