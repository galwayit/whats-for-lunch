//
//  AIRecommendationsViewModel.swift
//  LunchApp
//
//  Craving input, the AI request with its daily gate, and the history section.
//

import Foundation
import Observation

@Observable
final class AIRecommendationsViewModel {
    var craving = ""
    private(set) var state: LoadState<AiRecommendation> = .idle
    private(set) var isGated = false
    private(set) var history: [AiRecommendation] = []

    private let core: LunchCoreClient
    private let pickPlaceId: String?
    private static let maxResults = 3
    private static let historyLimit = 5

    init(core: LunchCoreClient, pickPlaceId: String?) {
        self.core = core
        self.pickPlaceId = pickPlaceId
    }

    /// Local midnight, when the free daily pick resets.
    var resetTime: String {
        let tomorrow = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400)
        return LunchFormat.time(tomorrow)
    }

    /// "Why this?" asks about the pick alone; otherwise the whole cached pool is the candidate set.
    func load(userId: Int64?, isPro: Bool) async {
        if let pickPlaceId, case .idle = state {
            let pick = await core.restaurants.cached(placeId: pickPlaceId)
            await ask(candidates: pick.map { [$0] } ?? [])
        }
        await loadHistory(userId: userId, isPro: isPro)
    }

    func ask(candidates: [Restaurant] = []) async {
        guard !state.isLoading else { return }
        state = .loading
        isGated = false
        let cravings = craving.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let result = try await core.ai.recommend(cravings: cravings.isEmpty ? nil : cravings, maxResults: Self.maxResults, candidates: candidates)
            state = .loaded(result)
        } catch CoreError.gate(.aiDailyLimit) {
            isGated = true
            state = .idle
        } catch {
            state = .failed(CoreError.from(error))
        }
    }

    private func loadHistory(userId: Int64?, isPro: Bool) async {
        guard let userId else { return }
        let all = (try? await core.ai.history(userId: userId, limit: Self.historyLimit)) ?? []
        let startOfDay = Int64(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
        history = isPro ? all : all.filter { $0.generatedAtEpochSeconds >= startOfDay }
    }

    func reasons(for restaurant: Restaurant, prefs: UserPreferences?) -> [String] {
        Array(core.recommendation.reasons(restaurant: restaurant, prefs: prefs).prefix(Self.maxResults))
    }
}
