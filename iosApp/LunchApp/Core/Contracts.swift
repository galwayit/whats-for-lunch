//
//  Contracts.swift
//  LunchApp
//
//  Swift protocols mirroring shared/src/commonMain/kotlin/au/iapp/lunch/core/api/Contracts.kt
//  one-to-one. Mapping rules (also in Core/README.md):
//    - `suspend fun f(): Result<T>`  ->  `func f() async throws -> T` (throws CoreError)
//    - `val x: StateFlow<T>`         ->  `var x: T { get }` plus `var xUpdates: AsyncStream<T>`
//    - `fun f(): Flow<T>`            ->  `func f() -> AsyncStream<T>`
//    - plain `fun`                   ->  plain `func`
//  Implementations: `KotlinLunchCore` (production), `PreviewLunchCore` (in-memory), and
//  `NotConfiguredCore` (safe fallback when Lunch.plist has missing values).
//

import Foundation

// MARK: - Pure engines

nonisolated protocol RecommendationEngine {
    func compatibilityScore(restaurant: Restaurant, prefs: UserPreferences?) -> Double
    /// Best candidate above the 0.1 threshold, ignoring rejected place ids.
    func bestMatch(candidates: [Restaurant], prefs: UserPreferences?, rejected: Set<String>) -> Restaurant?
    func reasons(restaurant: Restaurant, prefs: UserPreferences?) -> [String]
    /// Stable sort.
    func sort(restaurants: [Restaurant], option: SortOption, prefs: UserPreferences?) -> [Restaurant]
    func applyPreferenceFilters(restaurants: [Restaurant], prefs: UserPreferences?) -> [Restaurant]
    /// Its count drives the RELEVANCE sort.
    func discoverReasons(restaurant: Restaurant, prefs: UserPreferences?) -> [String]
    /// 0..1, 1 when nothing is required.
    func dietaryCompatibility(restaurant: Restaurant, dietaryRestrictions: [String], allergens: [String]) -> Double
}

nonisolated protocol BudgetEngine {
    /// Monday 00:00 local of the week containing `epochSeconds`.
    func weekStart(epochSeconds: Int64, timeZoneId: String) -> Int64
    func targetExperiences(prefs: UserPreferences) -> Int
    func weeklyState(prefs: UserPreferences, mealsThisWeek: [Meal], weekStartEpochSeconds: Int64) -> WeeklyBudgetState
    func capacityUsageLevel(state: WeeklyBudgetState) -> ImpactLevel
    func guidanceLevel(state: WeeklyBudgetState) -> GuidanceLevel
    func mealImpact(state: WeeklyBudgetState, mealCost: Double) -> MealImpact
    func budgetImpact(prefs: UserPreferences, cost: Double?) -> BudgetImpact
}

nonisolated protocol AchievementEngine {
    var catalogue: [Achievement] { get }
    /// Returns newly unlocked achievements given what is already unlocked.
    func evaluate(unlockedIds: Set<String>, weekly: WeeklyBudgetState, allMeals: [Meal], nowEpochSeconds: Int64, timeZoneId: String) -> [Achievement]
    func level(points: Int) -> String
}

nonisolated protocol MealDefaults {
    func smartMealType(hourOfDay: Int) -> String
    var categories: [MealCategory] { get }
    func displayName(mealType: String) -> String
}

// MARK: - Repositories

protocol UserRepository {
    var current: UserProfile? { get }
    var currentUpdates: AsyncStream<UserProfile?> { get }
    func createUser(name: String, preferences: UserPreferences) async throws -> UserProfile
    func updateName(name: String) async throws
    func updatePreferences(preferences: UserPreferences) async throws
    /// True once a real user exists; drives the onboarding redirect.
    var hasCompletedOnboarding: Bool { get }
    var hasCompletedOnboardingUpdates: AsyncStream<Bool> { get }
}

protocol MealRepository {
    func log(meal: Meal) async throws -> Int64
    func update(meal: Meal) async throws
    func delete(id: Int64) async throws
    /// Meals whose date is inside [startEpochSeconds, endEpochSeconds).
    func inRange(userId: Int64, startEpochSeconds: Int64, endEpochSeconds: Int64) async throws -> [Meal]
    func observeRecent(userId: Int64, limit: Int, windowDays: Int?) -> AsyncStream<[Meal]>
    func restaurantSuggestions(userId: Int64) async throws -> [String]
}

protocol RestaurantRepository {
    func searchNearby(location: Location, radiusKm: Double, query: String?, forceRefresh: Bool) async throws -> [Restaurant]
    func details(placeId: String) async throws -> Restaurant
    func reviews(placeId: String) async throws -> [RestaurantReview]
    func cached(placeId: String) async -> Restaurant?
    func cacheAll(restaurants: [Restaurant]) async
    func recordInteraction(userId: Int64, placeId: String, restaurantName: String?, type: String, context: String?) async
}

protocol FavouritesRepository {
    func observe(userId: Int64) -> AsyncStream<Set<String>>
    /// Applies the free-tier limit through GateService.
    func toggle(userId: Int64, placeId: String, restaurantName: String?) async throws -> GateDecision
    func favouriteRestaurants(userId: Int64) async throws -> [Restaurant]
}

protocol AchievementRepository {
    func observe(userId: Int64) -> AsyncStream<[Achievement]>
    func unlock(userId: Int64, achievements: [Achievement]) async
}

// MARK: - Services

protocol AiRecommendationService {
    func recommend(cravings: String?, maxResults: Int, candidates: [Restaurant]) async throws -> AiRecommendation
    func history(userId: Int64, limit: Int) async throws -> [AiRecommendation]
    func submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Bool) async throws
    /// Requests made today by this user, for the gate row copy.
    func usedToday(userId: Int64) async -> Int
}

protocol EntitlementRepository {
    var isPro: Bool { get }
    var isProUpdates: AsyncStream<Bool> { get }
    var status: SubscriptionStatus { get }
    var statusUpdates: AsyncStream<SubscriptionStatus> { get }
    func offerings() async throws -> ProOfferings
    func purchase(packageIdentifier: String) async throws -> SubscriptionStatus
    func restore() async throws -> SubscriptionStatus
    func logIn(userId: String) async throws
    func logOut() async throws
    /// Stable RevenueCat app user id, anonymous until logIn.
    var appUserId: String { get }
}

protocol GateService {
    func canRequestAi() async -> GateDecision
    func canAddFavourite(currentCount: Int) -> GateDecision
    /// nil means unlimited history.
    func historyWindowDays() -> Int?
    func canHostGroup() -> GateDecision
}

protocol AuthRepository {
    var session: AuthSession? { get }
    var sessionUpdates: AsyncStream<AuthSession?> { get }
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession
    func signInWithGoogle(idToken: String) async throws -> AuthSession
    func signOut() async throws
    func deleteAccount() async throws
}

protocol GroupRepository {
    func myGroups() -> AsyncStream<[LunchGroup]>
    /// Host only. Backend verifies the Pro entitlement.
    func create(name: String, scheduledAtEpochSeconds: Int64, area: Location, radiusKm: Double) async throws -> LunchGroup
    func propose(groupId: String) async throws -> [GroupProposal]
    func confirmPlace(groupId: String, restaurant: Restaurant) async throws -> LunchGroup
    func invitation(code: String) async throws -> Invitation
    func respond(code: String, status: RsvpStatus, displayName: String?) async throws -> Invitation
    func rsvps(groupId: String) -> AsyncStream<[Rsvp]>
    func cancel(groupId: String) async throws
}

protocol PushRegistrar {
    func register(token: String, platform: String) async throws
}

// MARK: - Platform-provided

protocol LocationProvider {
    func current() async throws -> Location
    func hasPermission() async -> Bool
}

protocol LunchClock {
    func nowEpochSeconds() -> Int64
    func timeZoneId() -> String
}

// MARK: - Facade

/// Mirrors `LunchCore`. Named `LunchCoreClient` so the Kotlin framework's own `LunchCore` symbol
/// can be imported alongside it later without a clash.
protocol LunchCoreClient {
    var users: UserRepository { get }
    var meals: MealRepository { get }
    var restaurants: RestaurantRepository { get }
    var favourites: FavouritesRepository { get }
    var achievements: AchievementRepository { get }
    var ai: AiRecommendationService { get }
    var entitlements: EntitlementRepository { get }
    var gates: GateService { get }
    var auth: AuthRepository { get }
    var groups: GroupRepository { get }
    var push: PushRegistrar { get }
    var recommendation: RecommendationEngine { get }
    var budget: BudgetEngine { get }
    var achievementEngine: AchievementEngine { get }
    var mealDefaults: MealDefaults { get }
    var clock: LunchClock { get }
    var location: LocationProvider { get }
}
