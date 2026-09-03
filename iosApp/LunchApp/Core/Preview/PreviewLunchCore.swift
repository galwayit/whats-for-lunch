//
//  PreviewLunchCore.swift
//  LunchApp
//
//  In-memory `LunchCoreClient` with realistic Sydney data, selected by `-previewCore`. Network
//  calls are simulated with short delays and honour `-offline 1`. Engines are the Swift ports.
//  The repositories live in PreviewRepositories.swift and PreviewServices.swift.
//

import Foundation

struct PreviewCoreOptions: Equatable {
    var isPro = false
    var isSignedIn = false
    var isOffline = false
    var aiUsedToday = false
    var isOnboarded = true

    init(isPro: Bool = false, isSignedIn: Bool = false, isOffline: Bool = false, aiUsedToday: Bool = false, isOnboarded: Bool = true) {
        self.isPro = isPro
        self.isSignedIn = isSignedIn
        self.isOffline = isOffline
        self.aiUsedToday = aiUsedToday
        self.isOnboarded = isOnboarded
    }

    init(arguments: LaunchArguments) {
        self.init(isPro: arguments.isPro, isSignedIn: arguments.isSignedIn, isOffline: arguments.isOffline, aiUsedToday: arguments.aiUsedToday, isOnboarded: arguments.isOnboarded)
    }
}

final class PreviewLunchCore: LunchCoreClient {
    let options: PreviewCoreOptions

    let recommendation: RecommendationEngine = SwiftRecommendationEngine()
    let budget: BudgetEngine = SwiftBudgetEngine()
    let achievementEngine: AchievementEngine = SwiftAchievementEngine()
    let mealDefaults: MealDefaults = SwiftMealDefaults()
    let clock: LunchClock = SystemLunchClock()
    let location: LocationProvider

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
    let push: PushRegistrar = PreviewPushRegistrar()

    init(options: PreviewCoreOptions = PreviewCoreOptions()) {
        self.options = options
        let engine = SwiftRecommendationEngine()
        let network = PreviewNetwork(isOffline: options.isOffline)
        let entitlements = PreviewEntitlementRepository(isPro: options.isPro, network: network)
        let auth = PreviewAuthRepository(isSignedIn: options.isSignedIn, network: network)
        let gates = PreviewGateService(entitlements: entitlements, auth: auth, aiUsedToday: options.aiUsedToday ? 1 : 0)
        let ai = PreviewAiService(engine: engine, gates: gates, network: network)
        self.location = PreviewLocationProvider()
        self.users = PreviewUserRepository(user: options.isOnboarded ? PreviewData.user : nil)
        self.meals = PreviewMealRepository(meals: options.isOnboarded ? PreviewData.meals : [])
        self.restaurants = PreviewRestaurantRepository(network: network)
        self.favourites = PreviewFavouritesRepository(initial: options.isOnboarded ? [PreviewData.greenGardenBowls.placeId, PreviewData.falafelRepublic.placeId] : [], gates: gates)
        self.achievements = PreviewAchievementRepository()
        self.ai = ai
        self.entitlements = entitlements
        self.gates = gates
        self.auth = auth
        self.groups = PreviewGroupRepository(engine: engine, network: network, auth: auth)
    }
}

/// Shared "are we offline" switch and the simulated latency for the preview repositories.
final class PreviewNetwork {
    let isOffline: Bool
    static let latency: Duration = .milliseconds(600)

    init(isOffline: Bool) {
        self.isOffline = isOffline
    }

    /// Waits the simulated latency, then throws `.offline` when the flag is set.
    func roundTrip(_ latency: Duration = PreviewNetwork.latency) async throws {
        try? await Task.sleep(for: latency)
        if isOffline { throw CoreError.offline }
    }
}

nonisolated struct SystemLunchClock: LunchClock {
    func nowEpochSeconds() -> Int64 { Int64(Date().timeIntervalSince1970) }
    func timeZoneId() -> String { TimeZone.current.identifier }
}

final class PreviewLocationProvider: LocationProvider {
    func current() async throws -> Location { PreviewData.userLocation }
    func hasPermission() async -> Bool { true }
}

final class PreviewPushRegistrar: PushRegistrar {
    func register(token: String, platform: String) async throws {}
}
