//
//  KotlinLunchCore.swift
//  LunchApp
//
//  Production adapter from the linked Kotlin Multiplatform framework to the
//  Swift-only contracts consumed by the views.
//

import CoreLocation
import Foundation
@preconcurrency import LunchCore

final class KotlinLunchCore: LunchCoreClient {
    let users: UserRepository
    let meals: MealRepository
    let restaurants: RestaurantRepository
    let favourites: FavouritesRepository
    let achievements: AchievementRepository
    let ai: AiRecommendationService
    let entitlements: EntitlementRepository
    let gates: GateService
    let auth: AuthRepository
    let groups: GroupRepository
    let push: PushRegistrar
    let recommendation: RecommendationEngine = SwiftRecommendationEngine()
    let budget: BudgetEngine = SwiftBudgetEngine()
    let achievementEngine: AchievementEngine = SwiftAchievementEngine()
    let mealDefaults: MealDefaults = SwiftMealDefaults()
    let clock: LunchClock
    let location: LocationProvider

    private let coreLocation: KotlinLocationProvider
    private let kotlinCore: LunchCore.SwiftLunchCore

    private init(core: LunchCore.SwiftLunchCore, location: KotlinLocationProvider) {
        kotlinCore = core
        coreLocation = location
        self.location = location
        users = KotlinUserRepository(core.users)
        meals = KotlinMealRepository(core.meals)
        restaurants = KotlinRestaurantRepository(core.restaurants)
        favourites = KotlinFavouritesRepository(core.favourites)
        achievements = KotlinAchievementRepository(core.achievements)
        ai = KotlinAiRecommendationService(core.ai)
        entitlements = KotlinEntitlementRepository(core.entitlements)
        gates = KotlinGateService(core.gates)
        auth = KotlinAuthRepository(core.auth)
        groups = KotlinGroupRepository(core.groups)
        push = KotlinPushRegistrar(core.push)
        clock = KotlinClock(core.clock)
    }

    static func make(config: LunchConfig) throws -> KotlinLunchCore {
        guard
            let supabaseUrl = config.supabaseUrl,
            let supabaseAnonKey = config.supabaseAnonKey,
            let backendBaseUrl = config.backendBaseUrl,
            config.revenueCatApiKey != nil || LunchConfig.allowsMissingPurchases
        else { throw CoreError.service(code: "CONFIG_MISSING", message: "Lunch.plist is incomplete") }
        // An empty key tells the core to run without purchases (Debug only, enforced there too).
        let revenueCatApiKey = config.revenueCatApiKey ?? ""

        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let databaseDirectory = support.appendingPathComponent("Lunch", isDirectory: true)
        try FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)
        let databasePath = databaseDirectory.appendingPathComponent("diet_buddy.sqlite").path

        #if DEBUG
        let isDebug = true
        #else
        let isDebug = false
        #endif

        let location = KotlinLocationProvider()
        let coreConfig = LunchCore.CoreConfig(
            supabaseUrl: supabaseUrl,
            supabaseAnonKey: supabaseAnonKey,
            backendBaseUrl: backendBaseUrl,
            revenueCatApiKey: revenueCatApiKey,
            databasePath: databasePath,
            inviteLinkBase: config.inviteLinkBase,
            isDebug: isDebug,
            anonymousAppUserId: revenueCatApiKey.isEmpty ? debugAppUserId() : nil
        )
        let core = LunchCore.SwiftLunchCoreFactory.shared.start(config: coreConfig, location: location.external)
        return KotlinLunchCore(core: core, location: location)
    }

    /// The backend's x-app-user-id while purchases are off. Kept in user defaults so per-user
    /// limits such as the daily AI allowance survive relaunches; a reinstall starts fresh.
    static func debugAppUserId(defaults: UserDefaults = .standard) -> String {
        let key = "lunch.debugAppUserId"
        if let existing = defaults.string(forKey: key) { return existing }
        let created = "debug-" + UUID().uuidString.lowercased()
        defaults.set(created, forKey: key)
        return created
    }
}

// MARK: - Location and clock

final class KotlinLocationProvider: NSObject, LocationProvider, CLLocationManagerDelegate {
    fileprivate let external = LunchCore.ExternalLocationProvider()
    private let manager = CLLocationManager()
    private var searchArea: SearchArea?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        syncAuthorization(manager.authorizationStatus)
    }

    func current() async throws -> Location {
        if let searchArea { return searchArea.location }
        guard authorizationGranted(manager.authorizationStatus) else {
            throw CoreError.service(code: "LOCATION_PERMISSION_DENIED", message: "Location permission not granted")
        }
        manager.requestLocation()
        return try await rethrowCoreError { try await self.external.currentLocation().app }
    }

    func hasPermission() async -> Bool { authorizationGranted(manager.authorizationStatus) }

    func setSearchArea(_ area: SearchArea?) {
        searchArea = area
        if let area {
            external.setSearchArea(latitude: area.latitude, longitude: area.longitude)
        } else {
            external.clearSearchArea()
            external.clear()
            if authorizationGranted(manager.authorizationStatus) { manager.requestLocation() }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        syncAuthorization(manager.authorizationStatus)
        if authorizationGranted(manager.authorizationStatus) { manager.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        external.update(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracyMetres: location.horizontalAccuracy
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code != .locationUnknown { external.clear() }
    }

    private func syncAuthorization(_ status: CLAuthorizationStatus) {
        external.setPermission(granted: authorizationGranted(status))
    }

    private func authorizationGranted(_ status: CLAuthorizationStatus) -> Bool {
        status == .authorizedAlways || status == .authorizedWhenInUse
    }
}

private struct KotlinClock: LunchClock {
    let source: LunchCore.Clock
    init(_ source: LunchCore.Clock) { self.source = source }
    func nowEpochSeconds() -> Int64 { source.nowEpochSeconds() }
    func timeZoneId() -> String { source.timeZoneId() }
}

// MARK: - Flow bridge

private func mappedStream<S: AsyncSequence, T: Sendable>(
    _ source: S,
    transform: @escaping (S.Element) -> T
) -> AsyncStream<T> {
    AsyncStream { continuation in
        let task = Task {
            do {
                for try await value in source { continuation.yield(transform(value)) }
            } catch is CancellationError {
                // Normal AsyncStream termination.
            } catch {
                // Repository operation errors are surfaced by explicit calls. A flow can
                // be recreated when its owning screen reappears.
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

// MARK: - Repositories

private final class KotlinUserRepository: UserRepository {
    private let source: LunchCore.SwiftUserRepository
    init(_ source: LunchCore.SwiftUserRepository) { self.source = source }

    var current: UserProfile? { source.current.value?.app }
    var currentUpdates: AsyncStream<UserProfile?> {
        mappedStream(source.current) { $0?.app }
    }
    var hasCompletedOnboarding: Bool { source.hasCompletedOnboarding.value.boolValue }
    var hasCompletedOnboardingUpdates: AsyncStream<Bool> {
        mappedStream(source.hasCompletedOnboarding) { $0.boolValue }
    }
    func createUser(name: String, preferences: UserPreferences) async throws -> UserProfile {
        try await rethrowCoreError { try await self.source.createUser(name: name, preferences: preferences.kotlin).app }
    }
    func updateName(name: String) async throws {
        try await rethrowCoreError { try await self.source.updateName(name: name) }
    }
    func updatePreferences(preferences: UserPreferences) async throws {
        try await rethrowCoreError { try await self.source.updatePreferences(preferences: preferences.kotlin) }
    }
}

private final class KotlinMealRepository: MealRepository {
    private let source: LunchCore.SwiftMealRepository
    init(_ source: LunchCore.SwiftMealRepository) { self.source = source }

    func log(meal: Meal) async throws -> Int64 {
        try await rethrowCoreError { try await self.source.log(meal: meal.kotlin).int64Value }
    }
    func update(meal: Meal) async throws {
        try await rethrowCoreError { try await self.source.update(meal: meal.kotlin) }
    }
    func delete(id: Int64) async throws {
        try await rethrowCoreError { try await self.source.delete(id: id) }
    }
    func inRange(userId: Int64, startEpochSeconds: Int64, endEpochSeconds: Int64) async throws -> [Meal] {
        try await rethrowCoreError {
            try await self.source.inRange(userId: userId, startEpochSeconds: startEpochSeconds, endEpochSeconds: endEpochSeconds).map(\.app)
        }
    }
    func observeRecent(userId: Int64, limit: Int, windowDays: Int?) -> AsyncStream<[Meal]> {
        mappedStream(
            source.observeRecent(
                userId: userId,
                limit: Int32(limit),
                windowDays: windowDays.map { LunchCore.KotlinInt(int: Int32($0)) }
            )
        ) { $0.map(\.app) }
    }
    func restaurantSuggestions(userId: Int64) async throws -> [String] {
        try await rethrowCoreError { try await self.source.restaurantSuggestions(userId: userId) }
    }
}

private final class KotlinRestaurantRepository: RestaurantRepository {
    private let source: LunchCore.SwiftRestaurantRepository
    init(_ source: LunchCore.SwiftRestaurantRepository) { self.source = source }

    func searchNearby(location: Location, radiusKm: Double, query: String?, forceRefresh: Bool) async throws -> [Restaurant] {
        try await rethrowCoreError {
            try await self.source.searchNearby(location: location.kotlin, radiusKm: radiusKm, query: query, forceRefresh: forceRefresh).map(\.app)
        }
    }
    func details(placeId: String) async throws -> Restaurant {
        try await rethrowCoreError { try await self.source.details(placeId: placeId).app }
    }
    func reviews(placeId: String) async throws -> [RestaurantReview] {
        try await rethrowCoreError { try await self.source.reviews(placeId: placeId).map(\.app) }
    }
    func cached(placeId: String) async -> Restaurant? {
        (try? await source.cached(placeId: placeId))?.app
    }
    func cacheAll(restaurants: [Restaurant]) async {
        try? await source.cacheAll(restaurants: restaurants.map(\.kotlin))
    }
    func recordInteraction(userId: Int64, placeId: String, restaurantName: String?, type: String, context: String?) async {
        try? await source.recordInteraction(userId: userId, placeId: placeId, restaurantName: restaurantName, type: type, context: context)
    }
}

private final class KotlinFavouritesRepository: FavouritesRepository {
    private let source: LunchCore.SwiftFavouritesRepository
    init(_ source: LunchCore.SwiftFavouritesRepository) { self.source = source }

    func observe(userId: Int64) -> AsyncStream<Set<String>> {
        mappedStream(source.observe(userId: userId)) { Set($0) }
    }
    func toggle(userId: Int64, placeId: String, restaurantName: String?) async throws -> GateDecision {
        try await rethrowCoreError {
            try await self.source.toggle(userId: userId, placeId: placeId, restaurantName: restaurantName).app
        }
    }
    func favouriteRestaurants(userId: Int64) async throws -> [Restaurant] {
        try await rethrowCoreError { try await self.source.favouriteRestaurants(userId: userId).map(\.app) }
    }
}

private final class KotlinAchievementRepository: AchievementRepository {
    private let source: LunchCore.SwiftAchievementRepository
    init(_ source: LunchCore.SwiftAchievementRepository) { self.source = source }

    func observe(userId: Int64) -> AsyncStream<[Achievement]> {
        mappedStream(source.observe(userId: userId)) { $0.map(\.app) }
    }
    func unlock(userId: Int64, achievements: [Achievement]) async {
        try? await source.unlock(userId: userId, achievements: achievements.map(\.kotlin))
    }
}

// MARK: - Services

private final class KotlinAiRecommendationService: AiRecommendationService {
    private let source: LunchCore.SwiftAiRecommendationService
    init(_ source: LunchCore.SwiftAiRecommendationService) { self.source = source }
    func configuration() async throws -> AiConfiguration {
        try await rethrowCoreError {
            let config = try await self.source.configuration()
            return AiConfiguration(consentVersion: config.consentVersion, providers: config.providers.map { AiProviderDisclosure(name: $0.name, privacyUrl: $0.privacyUrl) })
        }
    }

    func recommend(cravings: String?, maxResults: Int, candidates: [Restaurant], consentVersion: String) async throws -> AiRecommendation {
        try await rethrowCoreError {
            try await self.source.recommend(cravings: cravings, maxResults: Int32(maxResults), candidates: candidates.map(\.kotlin), consentVersion: consentVersion).app
        }
    }
    func history(userId: Int64, limit: Int) async throws -> [AiRecommendation] {
        try await rethrowCoreError { try await self.source.history(userId: userId, limit: Int32(limit)).map(\.app) }
    }
    func submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Bool) async throws {
        try await rethrowCoreError {
            try await self.source.submitFeedback(
                recommendationId: recommendationId,
                placeId: placeId,
                rating: Int32(rating),
                feedback: feedback,
                wasSelected: wasSelected
            )
        }
    }
    func usedToday(userId: Int64) async -> Int {
        Int((try? await source.usedToday(userId: userId).int32Value) ?? 0)
    }
}

private final class KotlinEntitlementRepository: EntitlementRepository {
    private let source: LunchCore.SwiftEntitlementRepository
    init(_ source: LunchCore.SwiftEntitlementRepository) { self.source = source }

    var isPro: Bool { source.isPro.value.boolValue }
    var isProUpdates: AsyncStream<Bool> { mappedStream(source.isPro) { $0.boolValue } }
    var status: SubscriptionStatus { source.status.value.app }
    var statusUpdates: AsyncStream<SubscriptionStatus> { mappedStream(source.status) { $0.app } }
    var appUserId: String { source.appUserId.value }
    func offerings() async throws -> ProOfferings {
        try await rethrowCoreError { try await self.source.offerings().app }
    }
    func purchase(packageIdentifier: String) async throws -> SubscriptionStatus {
        try await rethrowCoreError { try await self.source.purchase(packageIdentifier: packageIdentifier).app }
    }
    func restore() async throws -> SubscriptionStatus {
        try await rethrowCoreError { try await self.source.restore().app }
    }
    func logIn(userId: String) async throws {
        try await rethrowCoreError { try await self.source.logIn(userId: userId) }
    }
    func logOut() async throws {
        try await rethrowCoreError { try await self.source.logOut() }
    }
}

private final class KotlinGateService: GateService {
    private let source: LunchCore.GateService
    init(_ source: LunchCore.GateService) { self.source = source }

    func canRequestAi() async -> GateDecision {
        (try? await source.canRequestAi().app) ?? .denied(.aiDailyLimit)
    }
    func canAddFavourite(currentCount: Int) -> GateDecision {
        source.canAddFavourite(currentCount: Int32(currentCount)).app
    }
    func historyWindowDays() -> Int? { source.historyWindowDays()?.intValue }
    func canHostGroup() -> GateDecision { source.canHostGroup().app }
}

private final class KotlinAuthRepository: AuthRepository {
    private let source: LunchCore.SwiftAuthRepository
    init(_ source: LunchCore.SwiftAuthRepository) { self.source = source }

    var session: AuthSession? { source.session.value?.app }
    var sessionUpdates: AsyncStream<AuthSession?> { mappedStream(source.session) { $0?.app } }
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        try await rethrowCoreError {
            try await self.source.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName).app
        }
    }
    func signInWithGoogle(idToken: String, nonce: String, accessToken: String?) async throws -> AuthSession {
        try await rethrowCoreError { try await self.source.signInWithGoogle(idToken: idToken, nonce: nonce, accessToken: accessToken).app }
    }
    func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        try await rethrowCoreError { try await self.source.signInWithEmail(email: email, password: password).app }
    }
    func registerWithEmail(email: String, password: String) async throws -> Bool {
        try await rethrowCoreError { try await self.source.registerWithEmail(email: email, password: password).boolValue }
    }
    func verifyEmail(email: String, code: String) async throws -> AuthSession {
        try await rethrowCoreError { try await self.source.verifyEmail(email: email, code: code).app }
    }
    func resendVerification(email: String) async throws {
        try await rethrowCoreError { try await self.source.resendVerification(email: email) }
    }
    func requestPasswordReset(email: String) async throws {
        try await rethrowCoreError { try await self.source.requestPasswordReset(email: email) }
    }
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthSession {
        try await rethrowCoreError { try await self.source.resetPassword(email: email, code: code, newPassword: newPassword).app }
    }
    func signOut() async throws { try await rethrowCoreError { try await self.source.signOut() } }
    func deleteAccount(appleAuthorizationCode: String?) async throws { try await rethrowCoreError { try await self.source.deleteAccount(appleAuthorizationCode: appleAuthorizationCode) } }
}

private final class KotlinGroupRepository: GroupRepository {
    private let source: LunchCore.SwiftGroupRepository
    init(_ source: LunchCore.SwiftGroupRepository) { self.source = source }
    func loadGroups() async throws -> [LunchGroup] {
        try await rethrowCoreError { try await self.source.loadGroups().map(\.app) }
    }
    func loadRsvps(groupId: String) async throws -> [Rsvp] {
        try await rethrowCoreError { try await self.source.loadRsvps(groupId: groupId).map(\.app) }
    }

    func myGroups() -> AsyncStream<[LunchGroup]> {
        mappedStream(source.myGroups()) { $0.map(\.app) }
    }
    func create(name: String, scheduledAtEpochSeconds: Int64, area: Location, radiusKm: Double, details: GroupDetails) async throws -> LunchGroup {
        try await rethrowCoreError {
            try await self.source.create(name: name, scheduledAtEpochSeconds: scheduledAtEpochSeconds, area: area.kotlin, radiusKm: radiusKm, details: details.kotlin).app
        }
    }
    func propose(groupId: String, consentVersion: String) async throws -> [GroupProposal] {
        try await rethrowCoreError { try await self.source.propose(groupId: groupId, consentVersion: consentVersion).map(\.app) }
    }
    func confirmPlace(groupId: String, restaurant: Restaurant) async throws -> LunchGroup {
        try await rethrowCoreError {
            try await self.source.confirmPlace(groupId: groupId, restaurant: restaurant.kotlin).app
        }
    }
    func invitation(code: String) async throws -> Invitation {
        try await rethrowCoreError { try await self.source.invitation(code: code).app }
    }
    func respond(code: String, status: RsvpStatus, displayName: String?) async throws -> Invitation {
        try await rethrowCoreError {
            try await self.source.respond(code: code, status: status.kotlin, displayName: displayName).app
        }
    }
    func suggest(code: String, draft: GroupSuggestionDraft, displayName: String?) async throws -> Invitation {
        try await rethrowCoreError { try await self.source.suggest(code: code, draft: draft.kotlin, displayName: displayName).app }
    }
    func suggestions(groupId: String) async throws -> [GroupSuggestion] {
        try await rethrowCoreError { try await self.source.suggestions(groupId: groupId).map(\.app) }
    }
    func reviewSuggestion(groupId: String, suggestionId: String, accept: Bool) async throws -> LunchGroup {
        try await rethrowCoreError { try await self.source.reviewSuggestion(groupId: groupId, suggestionId: suggestionId, accept: accept).app }
    }
    func updateDetails(groupId: String, details: GroupDetails) async throws -> LunchGroup {
        try await rethrowCoreError { try await self.source.updateDetails(groupId: groupId, details: details.kotlin).app }
    }
    func safetyAction(code: String, targetKind: String, targetId: String?, action: String, reason: String) async throws {
        try await rethrowCoreError { try await self.source.safetyAction(code: code, targetKind: targetKind, targetId: targetId, action: action, reason: reason) }
    }
    func rsvps(groupId: String) -> AsyncStream<[Rsvp]> {
        mappedStream(source.rsvps(groupId: groupId)) { $0.map(\.app) }
    }
    func cancel(groupId: String) async throws {
        try await rethrowCoreError { try await self.source.cancel(groupId: groupId) }
    }
}

private final class KotlinPushRegistrar: PushRegistrar {
    private let source: LunchCore.SwiftPushRegistrar
    init(_ source: LunchCore.SwiftPushRegistrar) { self.source = source }
    func register(token: String, platform: String) async throws {
        try await rethrowCoreError { try await self.source.register(token: token, platform: platform) }
    }
}
