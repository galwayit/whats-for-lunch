//
//  AIRecommendationsViewModel.swift
//  LunchApp
//
//  Craving input, the AI request with its consent step and daily gate, and the history section.
//  Nothing is sent to the AI until AIDataConsent is granted (App Review 5.1.2(i)).
//

import Foundation
import Observation

@Observable
final class AIRecommendationsViewModel {
    var craving = ""
    private(set) var state: LoadState<AiRecommendation> = .idle
    private(set) var gateReason: GateReason?
    var isGated: Bool { gateReason == .aiDailyLimit }
    var requiresSubscription: Bool { isGated && !core.entitlements.isPro }
    /// True while the consent card is waiting for an answer; the request is held until then.
    private(set) var needsConsent = false
    private(set) var aiConfiguration: AiConfiguration?
    private(set) var needsSignIn = false
    private(set) var history: [AiRecommendation] = []

    private let core: LunchCoreClient
    private let pickPlaceId: String?
    private let consent: AIDataConsent
    /// Candidates of the request that is waiting for consent ("Why this?" asks about one pick).
    private var pendingCandidates: [Restaurant] = []
    private static let maxResults = 3
    private static let historyLimit = 5

    init(core: LunchCoreClient, pickPlaceId: String?, consent: AIDataConsent = AIDataConsent()) {
        self.core = core
        self.pickPlaceId = pickPlaceId
        self.consent = consent
    }

    /// The server uses UTC midnight so changing the device zone cannot reset usage.
    var resetTime: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let tomorrow = calendar.startOfDay(for: Date()).addingTimeInterval(86_400)
        return LunchFormat.time(tomorrow)
    }

    /// "Why this?" asks about the pick alone; otherwise the whole cached pool is the candidate set.
    func load(userId: Int64?, isPro: Bool) async {
        await refreshGate()
        guard !needsSignIn else { return }
        guard !isGated else { await loadHistory(userId: userId, isPro: isPro); return }
        if let pickPlaceId, case .idle = state {
            let pick = await core.restaurants.cached(placeId: pickPlaceId)
            await ask(candidates: pick.map { [$0] } ?? [])
        }
        await loadHistory(userId: userId, isPro: isPro)
    }

    func ask(candidates: [Restaurant] = []) async {
        guard !state.isLoading else { return }
        await refreshGate()
        guard !isGated, !needsSignIn else { return }
        state = .loading
        do {
            let config = try await core.ai.configuration()
            aiConfiguration = config
            guard consent.isGranted(for: config.consentVersion) else {
                pendingCandidates = candidates
                needsConsent = true
                state = .idle
                return
            }
            needsConsent = false
            let cravings = craving.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = try await core.ai.recommend(cravings: cravings.isEmpty ? nil : cravings, maxResults: Self.maxResults, candidates: candidates, consentVersion: config.consentVersion)
            state = .loaded(result)
        } catch CoreError.service(code: "AI_CONSENT_REQUIRED", message: _) {
            consent.revoke()
            state = .idle
            await ask(candidates: candidates)
        } catch CoreError.gate(.signInRequired) {
            needsSignIn = true
            state = .idle
        } catch CoreError.gate(.aiDailyLimit) {
            gateReason = .aiDailyLimit
            state = .idle
        } catch {
            state = .failed(CoreError.from(error))
        }
    }

    /// "Agree and continue": remembers the answer and sends the request that was held.
    func grantConsent() async {
        guard let aiConfiguration else { return }
        consent.grant(version: aiConfiguration.consentVersion)
        needsConsent = false
        let candidates = pendingCandidates
        pendingCandidates = []
        await ask(candidates: candidates)
    }

    /// "Not now": drops the held request; the next Ask shows the card again.
    func declineConsent() {
        needsConsent = false
        pendingCandidates = []
    }

    private func refreshGate() async {
        let decision = await core.gates.canRequestAi()
        gateReason = decision.allowed ? nil : decision.reason
        needsSignIn = decision.reason == .signInRequired
        if !decision.allowed {
            if state.isLoading { state = .idle }
            needsConsent = false
            pendingCandidates = []
        }
    }

    private func loadHistory(userId: Int64?, isPro: Bool) async {
        guard let userId else { return }
        let all = (try? await core.ai.history(userId: userId, limit: Self.historyLimit)) ?? []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDay = Int64(calendar.startOfDay(for: Date()).timeIntervalSince1970)
        history = isPro ? all : all.filter { $0.generatedAtEpochSeconds >= startOfDay }
    }

    func reasons(for restaurant: Restaurant, prefs: UserPreferences?) -> [String] {
        Array(core.recommendation.reasons(restaurant: restaurant, prefs: prefs).prefix(Self.maxResults))
    }
}
