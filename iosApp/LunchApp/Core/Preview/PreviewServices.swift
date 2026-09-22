//
//  PreviewServices.swift
//  LunchApp
//
//  In-memory AI, entitlement, gate, auth, and group services for `PreviewLunchCore`.
//  Gate reasons match the backend codes: AI_DAILY_LIMIT, HOST_REQUIRES_PRO, SIGN_IN_REQUIRED.
//

import Foundation

final class PreviewAiService: AiRecommendationService {
    private var pastRecommendations: [AiRecommendation] = [PreviewData.aiRecommendation]
    private let engine: RecommendationEngine
    private let gates: PreviewGateService
    private let network: PreviewNetwork

    private static let thinkingLatency: Duration = .milliseconds(1200)

    init(engine: RecommendationEngine, gates: PreviewGateService, network: PreviewNetwork) {
        self.engine = engine
        self.gates = gates
        self.network = network
    }

    func recommend(cravings: String?, maxResults: Int, candidates: [Restaurant]) async throws -> AiRecommendation {
        let decision = await gates.canRequestAi()
        guard decision.allowed else { throw CoreError.gate(decision.reason) }
        try await network.roundTrip(Self.thinkingLatency)
        let pool = candidates.isEmpty ? PreviewData.restaurants : candidates
        let craving = cravings?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let matching = pool.filter { restaurant in
            craving.isEmpty || restaurant.name.lowercased().contains(craving) || restaurant.cuisineTypes.contains { craving.contains($0.lowercased()) || $0.lowercased().contains(craving) }
        }
        let ranked = engine.sort(restaurants: matching.isEmpty ? pool : matching, option: .relevance, prefs: PreviewData.user.preferences)
        let picks = Array(ranked.prefix(maxResults))
        let names = picks.map(\.name).joined(separator: ", ")
        let reasoning = craving.isEmpty
            ? "Based on your $$ budget and 5 km range, these are the strongest picks right now: \(names)."
            : "For \"\(cravings ?? "")\" within your budget and distance, the best fits are \(names)."
        gates.recordAiUsed()
        let recommendation = AiRecommendation(
            id: "ai_\(UUID().uuidString.prefix(8))",
            userId: PreviewData.userId,
            restaurants: picks,
            reasoning: reasoning,
            factorWeights: ["budget": 0.4, "distance": 0.3, "rating": 0.2, "cuisine": 0.1],
            overallConfidence: matching.isEmpty ? 0.62 : 0.86,
            investmentSummary: picks.first.flatMap(\.averageMealCost).map { "About \(LunchFormat.currency($0)) today keeps you inside this week's budget." },
            generatedAtEpochSeconds: Int64(Date().timeIntervalSince1970)
        )
        pastRecommendations.insert(recommendation, at: 0)
        return recommendation
    }

    func history(userId: Int64, limit: Int) async throws -> [AiRecommendation] {
        Array(pastRecommendations.prefix(limit))
    }

    func submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Bool) async throws {}

    func usedToday(userId: Int64) async -> Int { gates.aiRequestsToday }
}

final class PreviewEntitlementRepository: EntitlementRepository {
    private let current: Broadcast<SubscriptionStatus>
    private let network: PreviewNetwork
    let appUserId = "$RCAnonymousID:preview"

    init(isPro: Bool, network: PreviewNetwork) {
        current = Broadcast(isPro ? Self.proStatus(productId: PreviewData.yearlyPackage.productId) : .free)
        self.network = network
    }

    var isPro: Bool { current.value.isPro }
    var isProUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task { [current] in
                for await status in current.stream() { continuation.yield(status.isPro) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    var status: SubscriptionStatus { current.value }
    var statusUpdates: AsyncStream<SubscriptionStatus> { current.stream() }

    func offerings() async throws -> ProOfferings {
        try await network.roundTrip()
        return PreviewData.offerings
    }

    func purchase(packageIdentifier: String) async throws -> SubscriptionStatus {
        try await network.roundTrip(.seconds(1))
        let package = packageIdentifier == PreviewData.monthlyPackage.identifier ? PreviewData.monthlyPackage : PreviewData.yearlyPackage
        let status = Self.proStatus(productId: package.productId)
        current.send(status)
        return status
    }

    func restore() async throws -> SubscriptionStatus {
        try await network.roundTrip()
        return current.value
    }

    func logIn(userId: String) async throws {}
    func logOut() async throws {}

    private static func proStatus(productId: String) -> SubscriptionStatus {
        let days: Double = productId.hasSuffix("yearly") ? 365 : 30
        return SubscriptionStatus(
            isPro: true,
            productId: productId,
            expiresAtEpochSeconds: Int64(Date().addingTimeInterval(days * 86_400).timeIntervalSince1970),
            willRenew: true,
            managementUrl: "https://apps.apple.com/account/subscriptions"
        )
    }
}

final class PreviewGateService: GateService {
    private let entitlements: EntitlementRepository
    private let auth: AuthRepository
    private(set) var aiRequestsToday: Int

    init(entitlements: EntitlementRepository, auth: AuthRepository, aiUsedToday: Int = 0) {
        self.entitlements = entitlements
        self.auth = auth
        aiRequestsToday = aiUsedToday
    }

    /// Checks only; `PreviewAiService` calls `recordAiUsed()` after a successful request.
    func canRequestAi() async -> GateDecision {
        if entitlements.isPro { return .allowed }
        return aiRequestsToday < FreeLimits.aiRequestsPerDay ? .allowed : .denied(.aiDailyLimit)
    }

    func recordAiUsed() { aiRequestsToday += 1 }

    func canAddFavourite(currentCount: Int) -> GateDecision {
        entitlements.isPro || currentCount < FreeLimits.favourites ? .allowed : .denied(.favouritesLimit)
    }

    func historyWindowDays() -> Int? { entitlements.isPro ? nil : FreeLimits.historyDays }

    func canHostGroup() -> GateDecision {
        if !entitlements.isPro { return .denied(.hostRequiresPro) }
        if auth.session == nil { return .denied(.signInRequired) }
        return .allowed
    }
}

final class PreviewAuthRepository: AuthRepository {
    private let current: Broadcast<AuthSession?>
    private let network: PreviewNetwork
    static let demoSession = AuthSession(userId: "user_ray", email: "ray@example.com", displayName: PreviewData.userName)

    init(isSignedIn: Bool, network: PreviewNetwork) {
        current = Broadcast(isSignedIn ? Self.demoSession : nil)
        self.network = network
    }

    var session: AuthSession? { current.value }
    var sessionUpdates: AsyncStream<AuthSession?> { current.stream() }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        try await network.roundTrip()
        let session = AuthSession(userId: "user_ray", email: "ray@privaterelay.appleid.com", displayName: fullName ?? PreviewData.userName)
        current.send(session)
        return session
    }

    func signInWithGoogle(idToken: String) async throws -> AuthSession {
        try await network.roundTrip()
        let session = AuthSession(userId: "user_ray", email: "ray@gmail.com", displayName: PreviewData.userName)
        current.send(session)
        return session
    }

    func signOut() async throws { current.send(nil) }

    func deleteAccount() async throws {
        try await network.roundTrip()
        current.send(nil)
    }
}

final class PreviewGroupRepository: GroupRepository {
    private let groups: Broadcast<[LunchGroup]>
    private var rsvpsByGroup: [String: Broadcast<[Rsvp]>]
    private let engine: RecommendationEngine
    private let network: PreviewNetwork
    private let auth: AuthRepository
    private let locales: PreviewLocaleResolver
    private static let proposalCount = 3

    init(engine: RecommendationEngine, network: PreviewNetwork, auth: AuthRepository, locales: PreviewLocaleResolver) {
        self.locales = locales
        groups = Broadcast([PreviewData.group])
        rsvpsByGroup = [PreviewData.group.id: Broadcast(PreviewData.rsvps)]
        self.engine = engine
        self.network = network
        self.auth = auth
    }

    func myGroups() -> AsyncStream<[LunchGroup]> { groups.stream() }

    func create(name: String, scheduledAtEpochSeconds: Int64, area: Location, radiusKm: Double) async throws -> LunchGroup {
        try await network.roundTrip()
        let hostName = auth.session?.displayName ?? PreviewData.userName
        let group = LunchGroup(
            id: "grp_\(UUID().uuidString.prefix(6))",
            hostId: auth.session?.userId ?? "user_ray",
            hostName: hostName,
            name: name,
            scheduledAtEpochSeconds: scheduledAtEpochSeconds,
            areaLatitude: area.latitude,
            areaLongitude: area.longitude,
            radiusKm: radiusKm,
            inviteCode: String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased(),
            createdAtEpochSeconds: Int64(Date().timeIntervalSince1970)
        )
        rsvpsByGroup[group.id] = Broadcast([Rsvp(id: "rsvp_\(group.id)_host", groupId: group.id, guestUserId: group.hostId, displayName: hostName, status: .accepted, respondedAtEpochSeconds: group.createdAtEpochSeconds)])
        groups.send(groups.value + [group])
        return group
    }

    func propose(groupId: String) async throws -> [GroupProposal] {
        try await network.roundTrip(.seconds(1))
        guard let group = groups.value.first(where: { $0.id == groupId }) else { throw Self.notFound(groupId) }
        // The group's area moves with the sample data, so proposals stay near the user too.
        let locale = locales.current
        let area = Location(
            latitude: group.areaLatitude + locale.offsetLatitude,
            longitude: group.areaLongitude + locale.offsetLongitude
        )
        let nearby = locale.relocate(PreviewData.restaurants, from: area)
            .filter { ($0.distanceFromUser ?? .infinity) <= group.radiusKm }
        let ranked = engine.sort(restaurants: nearby, option: .relevance, prefs: PreviewData.user.preferences)
        return ranked.prefix(Self.proposalCount).map { GroupProposal(restaurant: $0, reasons: Array(engine.reasons(restaurant: $0, prefs: PreviewData.user.preferences).prefix(3))) }
    }

    func confirmPlace(groupId: String, restaurant: Restaurant) async throws -> LunchGroup {
        try await network.roundTrip()
        guard var group = groups.value.first(where: { $0.id == groupId }) else { throw Self.notFound(groupId) }
        group.placeId = restaurant.placeId
        group.placeName = restaurant.name
        group.placeAddress = restaurant.address
        groups.send(groups.value.map { $0.id == groupId ? group : $0 })
        return group
    }

    func invitation(code: String) async throws -> Invitation {
        try await network.roundTrip()
        guard let group = groups.value.first(where: { $0.inviteCode.caseInsensitiveCompare(code) == .orderedSame }) else {
            throw CoreError.service(code: "NOT_FOUND", message: "No invitation \(code)")
        }
        let attendees = rsvpsByGroup[group.id]?.value ?? []
        let mine = auth.session.flatMap { session in attendees.first { $0.guestUserId == session.userId } }
        return Invitation(group: group, attendees: attendees, myStatus: mine?.status, inviteUrl: LunchConfig.current.inviteUrl(code: group.inviteCode))
    }

    func respond(code: String, status: RsvpStatus, displayName: String?) async throws -> Invitation {
        try await network.roundTrip()
        guard let group = groups.value.first(where: { $0.inviteCode.caseInsensitiveCompare(code) == .orderedSame }),
              let broadcast = rsvpsByGroup[group.id] else {
            throw CoreError.service(code: "NOT_FOUND", message: "No invitation \(code)")
        }
        let guestId = auth.session?.userId ?? "guest_\(displayName ?? "anonymous")"
        let name = displayName ?? auth.session?.displayName ?? "Guest"
        var attendees = broadcast.value
        let now = Int64(Date().timeIntervalSince1970)
        if let index = attendees.firstIndex(where: { $0.guestUserId == guestId }) {
            attendees[index].status = status
            attendees[index].respondedAtEpochSeconds = now
        } else {
            attendees.append(Rsvp(id: "rsvp_\(UUID().uuidString.prefix(6))", groupId: group.id, guestUserId: guestId, displayName: name, status: status, respondedAtEpochSeconds: now))
        }
        broadcast.send(attendees)
        return Invitation(group: group, attendees: attendees, myStatus: status, inviteUrl: LunchConfig.current.inviteUrl(code: group.inviteCode))
    }

    func rsvps(groupId: String) -> AsyncStream<[Rsvp]> {
        if rsvpsByGroup[groupId] == nil { rsvpsByGroup[groupId] = Broadcast([]) }
        return rsvpsByGroup[groupId]?.stream() ?? AsyncStream { $0.finish() }
    }

    func cancel(groupId: String) async throws {
        try await network.roundTrip()
        groups.send(groups.value.filter { $0.id != groupId })
        rsvpsByGroup[groupId] = nil
    }

    private static func notFound(_ groupId: String) -> CoreError {
        .service(code: "NOT_FOUND", message: "Unknown group \(groupId)")
    }
}
