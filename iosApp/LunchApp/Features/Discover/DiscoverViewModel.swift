//
//  DiscoverViewModel.swift
//  LunchApp
//
//  Search, sort, filters, favourites, and the selected restaurant for the Discover tab.
//

import Foundation
import Observation

@Observable
final class DiscoverViewModel {
    enum Sheet: String, Identifiable {
        case sort, dietary, price, distance, rating
        var id: String { rawValue }
    }

    static let debounceNanoseconds: UInt64 = 400_000_000
    static let ratingRange: ClosedRange<Double> = 3...5
    static let ratingStep = 0.5

    var query = ""
    private(set) var results: LoadState<[Restaurant]> = .idle
    private(set) var favourites: Set<String> = []
    private(set) var isFavouriteGated = false
    var sortOption: SortOption = .relevance
    var dietary: Set<String> = []
    var maxPriceLevel: Int?
    var maxDistanceKm: Double?
    var minRating: Double?
    var sheet: Sheet?
    var selected: Restaurant?

    private let core: LunchCoreClient
    private var debounce: Task<Void, Never>?
    private var unfiltered: [Restaurant] = []
    private var activePreferences: UserPreferences?

    init(core: LunchCoreClient) {
        self.core = core
    }

    var hasFilters: Bool { !dietary.isEmpty || maxPriceLevel != nil || maxDistanceKm != nil || minRating != nil }

    var sortLabel: String {
        switch sortOption {
        case .relevance: Copy.Discover.sortRelevance
        case .price: Copy.Discover.sortPrice
        case .distance: Copy.Discover.sortDistance
        case .rating: Copy.Discover.sortRating
        }
    }

    /// Runs the search 400 ms after the last keystroke.
    func queryChanged(prefs: UserPreferences?) {
        activePreferences = prefs
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await search(prefs: activePreferences)
        }
    }

    func search(prefs: UserPreferences?) async {
        activePreferences = prefs
        results = .loading
        do {
            let location = try await core.location.current()
            let radius = maxDistanceKm ?? prefs?.maxTravelDistance ?? UserPreferences().maxTravelDistance
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            unfiltered = try await core.restaurants.searchNearby(location: location, radiusKm: radius, query: trimmed.isEmpty ? nil : trimmed, forceRefresh: false)
            applyFilters(prefs: activePreferences)
        } catch {
            results = .failed(CoreError.from(error))
        }
    }

    /// Filters and sorts the last fetched list without another network call.
    func applyFilters(prefs: UserPreferences?) {
        activePreferences = prefs
        let eligible = core.recommendation.applyPreferenceFilters(restaurants: unfiltered, prefs: prefs)
        let filtered = eligible.filter { restaurant in
            if prefs?.includeChains == false, RestaurantChains.matches(restaurant.name) { return false }
            if let maxPriceLevel, let level = restaurant.priceLevel, level > maxPriceLevel { return false }
            if let maxDistanceKm, let distance = restaurant.distanceFromUser, distance > maxDistanceKm { return false }
            if let minRating, (restaurant.rating ?? 0) < minRating { return false }
            if !dietary.isEmpty {
                let compatibility = core.recommendation.dietaryCompatibility(restaurant: restaurant, dietaryRestrictions: Array(dietary), allergens: [])
                if compatibility < 1 { return false }
            }
            return true
        }
        results = .loaded(core.recommendation.sort(restaurants: filtered, option: sortOption, prefs: prefs))
    }

    func clearFilters(prefs: UserPreferences?) {
        dietary = []
        maxPriceLevel = nil
        maxDistanceKm = nil
        minRating = nil
        applyFilters(prefs: prefs)
    }

    func observeFavourites(userId: Int64) async {
        for await ids in core.favourites.observe(userId: userId) {
            favourites = ids
        }
    }

    /// Returns false when the free favourites limit blocks the add.
    @discardableResult
    func toggleFavourite(_ restaurant: Restaurant, userId: Int64) async -> Bool {
        do {
            let decision = try await core.favourites.toggle(userId: userId, placeId: restaurant.placeId, restaurantName: restaurant.name)
            isFavouriteGated = !decision.allowed
            return decision.allowed
        } catch {
            return false
        }
    }
}
