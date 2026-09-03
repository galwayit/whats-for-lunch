//
//  PreviewRepositories.swift
//  LunchApp
//
//  In-memory user, meal, restaurant, favourites, and achievement repositories for
//  `PreviewLunchCore`. State lives in `Broadcast` values so screens see updates immediately.
//

import Foundation

final class PreviewUserRepository: UserRepository {
    private let user: Broadcast<UserProfile?>

    init(user initial: UserProfile?) {
        user = Broadcast(initial)
    }

    var current: UserProfile? { user.value }
    var currentUpdates: AsyncStream<UserProfile?> { user.stream() }
    var hasCompletedOnboarding: Bool { user.value != nil }
    var hasCompletedOnboardingUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task { [user] in
                for await profile in user.stream() { continuation.yield(profile != nil) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func createUser(name: String, preferences: UserPreferences) async throws -> UserProfile {
        let profile = UserProfile(id: PreviewData.userId, name: name, preferences: preferences, createdAtEpochSeconds: Int64(Date().timeIntervalSince1970))
        user.send(profile)
        return profile
    }

    func updateName(name: String) async throws {
        guard var profile = user.value else { throw CoreError.unknown("No user") }
        profile.name = name
        user.send(profile)
    }

    func updatePreferences(preferences: UserPreferences) async throws {
        guard var profile = user.value else { throw CoreError.unknown("No user") }
        profile.preferences = preferences
        user.send(profile)
    }
}

final class PreviewMealRepository: MealRepository {
    private let meals: Broadcast<[Meal]>
    private var nextId: Int64

    init(meals initial: [Meal]) {
        meals = Broadcast(initial)
        nextId = (initial.compactMap(\.id).max() ?? 0) + 1
    }

    func log(meal: Meal) async throws -> Int64 {
        var stored = meal
        let id = nextId
        nextId += 1
        stored.id = id
        meals.send(meals.value + [stored])
        return id
    }

    func update(meal: Meal) async throws {
        meals.send(meals.value.map { $0.id == meal.id ? meal : $0 })
    }

    func delete(id: Int64) async throws {
        meals.send(meals.value.filter { $0.id != id })
    }

    func inRange(userId: Int64, startEpochSeconds: Int64, endEpochSeconds: Int64) async throws -> [Meal] {
        meals.value.filter { $0.userId == userId && $0.dateEpochSeconds >= startEpochSeconds && $0.dateEpochSeconds < endEpochSeconds }
    }

    func observeRecent(userId: Int64, limit: Int, windowDays: Int?) -> AsyncStream<[Meal]> {
        AsyncStream { continuation in
            let task = Task { [meals] in
                for await all in meals.stream() {
                    let cutoff = windowDays.map { Int64(Date().timeIntervalSince1970) - Int64($0) * 86_400 }
                    let recent = all
                        .filter { meal in meal.userId == userId && (cutoff.map { meal.dateEpochSeconds >= $0 } ?? true) }
                        .sorted { $0.dateEpochSeconds > $1.dateEpochSeconds }
                        .prefix(limit)
                    continuation.yield(Array(recent))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func restaurantSuggestions(userId: Int64) async throws -> [String] {
        var seen = Set<String>()
        return meals.value
            .sorted { $0.dateEpochSeconds > $1.dateEpochSeconds }
            .compactMap(\.restaurantName)
            .filter { seen.insert($0).inserted }
    }
}

final class PreviewRestaurantRepository: RestaurantRepository {
    private let network: PreviewNetwork
    private var cache: [String: Restaurant] = Dictionary(uniqueKeysWithValues: PreviewData.restaurants.map { ($0.placeId, $0) })

    init(network: PreviewNetwork) {
        self.network = network
    }

    func searchNearby(location: Location, radiusKm: Double, query: String?, forceRefresh: Bool) async throws -> [Restaurant] {
        try await network.roundTrip()
        let needle = query?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        return PreviewData.restaurants
            .map { restaurant in
                var located = restaurant
                if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
                    located.distanceFromUser = Self.distanceKm(from: location, toLatitude: latitude, longitude: longitude)
                }
                return located
            }
            .filter { ($0.distanceFromUser ?? .infinity) <= radiusKm }
            .filter { needle.isEmpty || $0.name.lowercased().contains(needle) || $0.cuisineTypes.contains { $0.lowercased().contains(needle) } }
            .sorted { ($0.distanceFromUser ?? 0) < ($1.distanceFromUser ?? 0) }
    }

    func details(placeId: String) async throws -> Restaurant {
        try await network.roundTrip()
        guard let restaurant = cache[placeId] else { throw CoreError.service(code: "NOT_FOUND", message: "Unknown place \(placeId)") }
        return restaurant
    }

    func reviews(placeId: String) async throws -> [RestaurantReview] {
        try await network.roundTrip()
        return placeId == PreviewData.sakuraSushi.placeId ? [] : PreviewData.reviews
    }

    func cached(placeId: String) async -> Restaurant? { cache[placeId] }

    func cacheAll(restaurants: [Restaurant]) async {
        for restaurant in restaurants { cache[restaurant.placeId] = restaurant }
    }

    func recordInteraction(userId: Int64, placeId: String, restaurantName: String?, type: String, context: String?) async {}

    /// Haversine great-circle distance in kilometres.
    static func distanceKm(from location: Location, toLatitude latitude: Double, longitude: Double) -> Double {
        let earthRadiusKm = 6371.0
        let dLat = (latitude - location.latitude) * .pi / 180
        let dLon = (longitude - location.longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(location.latitude * .pi / 180) * cos(latitude * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        let distance = earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a))
        return (distance * 10).rounded() / 10
    }
}

final class PreviewFavouritesRepository: FavouritesRepository {
    private let favourites: Broadcast<Set<String>>
    private let gates: GateService

    init(initial: Set<String>, gates: GateService) {
        favourites = Broadcast(initial)
        self.gates = gates
    }

    func observe(userId: Int64) -> AsyncStream<Set<String>> { favourites.stream() }

    func toggle(userId: Int64, placeId: String, restaurantName: String?) async throws -> GateDecision {
        var current = favourites.value
        if current.contains(placeId) {
            current.remove(placeId)
        } else {
            let decision = gates.canAddFavourite(currentCount: current.count)
            guard decision.allowed else { return decision }
            current.insert(placeId)
        }
        favourites.send(current)
        return .allowed
    }

    func favouriteRestaurants(userId: Int64) async throws -> [Restaurant] {
        PreviewData.restaurants.filter { favourites.value.contains($0.placeId) }
    }
}

final class PreviewAchievementRepository: AchievementRepository {
    private let unlocked = Broadcast<[Achievement]>([])

    func observe(userId: Int64) -> AsyncStream<[Achievement]> { unlocked.stream() }

    func unlock(userId: Int64, achievements: [Achievement]) async {
        let known = Set(unlocked.value.map(\.id))
        unlocked.send(unlocked.value + achievements.filter { !known.contains($0.id) })
    }
}
