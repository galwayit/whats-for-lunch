//
//  HomeViewModel.swift
//  LunchApp
//
//  Hero search state, the picks count, and the "Lunch together" groups for the Home tab.
//

import Foundation
import Observation

@Observable
final class HomeViewModel {
    enum HeroState: Equatable {
        case idle
        case searching
        case result(Restaurant, reasons: [String], confidence: Double)
        case empty
        case failed(CoreError)
    }

    private(set) var hero: HeroState = .idle
    private(set) var picksCount = 0
    private(set) var groups: [LunchGroup] = []
    private(set) var attendingCounts: [String: Int] = [:]
    var craving = ""

    private let core: LunchCoreClient
    private var rejected: Set<String> = []
    private var rsvpObservers: [String: Task<Void, Never>] = [:]
    private static let reasonCount = 3

    init(core: LunchCoreClient) {
        self.core = core
    }

    var isSearching: Bool { hero == .searching }

    func search(prefs: UserPreferences?) async {
        guard !isSearching else { return }
        hero = .searching
        do {
            let location = try await core.location.current()
            let radius = prefs?.maxTravelDistance ?? UserPreferences().maxTravelDistance
            let nearby = try await core.restaurants.searchNearby(location: location, radiusKm: radius, query: nil, forceRefresh: false)
            let candidates = core.recommendation.applyPreferenceFilters(restaurants: nearby, prefs: prefs)
            picksCount = candidates.filter { core.recommendation.compatibilityScore(restaurant: $0, prefs: prefs) > SwiftRecommendationEngine.scoreThreshold }.count
            if let best = core.recommendation.bestMatch(candidates: candidates, prefs: prefs, rejected: rejected) {
                let reasons = Array(core.recommendation.reasons(restaurant: best, prefs: prefs).prefix(Self.reasonCount))
                hero = .result(best, reasons: reasons, confidence: core.recommendation.compatibilityScore(restaurant: best, prefs: prefs))
            } else {
                hero = .empty
            }
        } catch {
            hero = .failed(CoreError.from(error))
        }
    }

    /// "Not this one": remember the rejection and search again.
    func reject(_ restaurant: Restaurant, prefs: UserPreferences?) async {
        rejected.insert(restaurant.placeId)
        await search(prefs: prefs)
    }

    func reset() {
        rejected = []
        hero = .idle
    }

    /// Keeps `groups` and the accepted counts current for the "Lunch together" row.
    func observeGroups() async {
        for await groups in core.groups.myGroups() {
            self.groups = groups.sorted { $0.scheduledAtEpochSeconds < $1.scheduledAtEpochSeconds }
            for group in groups where rsvpObservers[group.id] == nil {
                rsvpObservers[group.id] = Task { [core] in
                    for await rsvps in core.groups.rsvps(groupId: group.id) {
                        attendingCounts[group.id] = rsvps.filter { $0.status == .accepted }.count
                    }
                }
            }
            for id in rsvpObservers.keys where !groups.contains(where: { $0.id == id }) {
                rsvpObservers[id]?.cancel()
                rsvpObservers[id] = nil
            }
        }
    }
}
