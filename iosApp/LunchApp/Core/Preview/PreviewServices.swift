//
//  PreviewServices.swift
//  LunchApp
//
//  In-memory AI, entitlement, gate, auth, and group services for `PreviewLunchCore`.
//  Gate reasons match the backend codes: AI_DAILY_LIMIT, HOST_REQUIRES_PRO, SIGN_IN_REQUIRED.
//

import Foundation

final class PreviewAiService: AiRecommendationService {
    var aiConfiguration = AiConfiguration(consentVersion: "preview-ai-v2", providers: [AiProviderDisclosure(name: "Preview AI", privacyUrl: "https://example.com/privacy")])
    func configuration() async throws -> AiConfiguration { aiConfiguration }
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

    func recommend(cravings: String?, maxResults: Int, candidates: [Restaurant], consentVersion: String) async throws -> AiRecommendation {
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
        guard auth.session != nil else { return .denied(.signInRequired) }
        let limit = entitlements.isPro ? 10 : FreeLimits.aiRequestsPerDay
        return aiRequestsToday < limit ? .allowed : .denied(.aiDailyLimit)
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
        let session = AuthSession(userId: "user_ray", email: "ray@privaterelay.appleid.com", displayName: fullName ?? PreviewData.userName, requiresAppleReauthentication: true)
        current.send(session)
        return session
    }

    func signInWithGoogle(idToken: String, nonce: String, accessToken: String?) async throws -> AuthSession {
        try await network.roundTrip()
        let session = AuthSession(userId: "user_ray", email: "ray@gmail.com", displayName: PreviewData.userName)
        current.send(session)
        return session
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        try await network.roundTrip()
        let session = AuthSession(userId: "user_ray", email: email, displayName: PreviewData.userName)
        current.send(session)
        return session
    }
    func registerWithEmail(email: String, password: String) async throws -> Bool { try await network.roundTrip(); return false }
    func verifyEmail(email: String, code: String) async throws -> AuthSession { try await signInWithEmail(email: email, password: "") }
    func resendVerification(email: String) async throws { try await network.roundTrip() }
    func requestPasswordReset(email: String) async throws { try await network.roundTrip() }
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthSession { try await signInWithEmail(email: email, password: newPassword) }

    func signOut() async throws { current.send(nil) }

    func deleteAccount(appleAuthorizationCode: String?) async throws {
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
    private var suggestionRows: [GroupSuggestion] = []

    init(engine: RecommendationEngine, network: PreviewNetwork, auth: AuthRepository, locales: PreviewLocaleResolver) {
        self.locales = locales
        groups = Broadcast([PreviewData.group])
        rsvpsByGroup = [PreviewData.group.id: Broadcast(PreviewData.rsvps)]
        self.engine = engine
        self.network = network
        self.auth = auth
    }

    func myGroups() -> AsyncStream<[LunchGroup]> { groups.stream() }

    func create(name: String, scheduledAtEpochSeconds: Int64, area: Location, radiusKm: Double, details: GroupDetails) async throws -> LunchGroup {
        try await network.roundTrip()
        let hostName = details.hostName.isEmpty ? (auth.session?.displayName ?? PreviewData.userName) : details.hostName
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
            createdAtEpochSeconds: Int64(Date().timeIntervalSince1970), budgetPerPersonMinor: details.budgetPerPersonMinor, currencyCode: details.currencyCode, paymentArrangement: details.paymentArrangement, paymentMethod: details.paymentMethod
        )
        rsvpsByGroup[group.id] = Broadcast([Rsvp(id: "rsvp_\(group.id)_host", groupId: group.id, guestUserId: group.hostId, displayName: hostName, status: .accepted, respondedAtEpochSeconds: group.createdAtEpochSeconds)])
        groups.send(groups.value + [group])
        return group
    }

    func propose(groupId: String, consentVersion: String) async throws -> [GroupProposal] {
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
        return Invitation(group: group, attendees: attendees, myStatus: mine?.status, inviteUrl: LunchConfig.current.inviteUrl(code: group.inviteCode), mySuggestion: suggestionRows.last { $0.groupId == group.id })
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
        return Invitation(group: group, attendees: attendees, myStatus: status, inviteUrl: LunchConfig.current.inviteUrl(code: group.inviteCode), mySuggestion: suggestionRows.last { $0.groupId == group.id })
    }

    func suggest(code: String, draft: GroupSuggestionDraft, displayName: String?) async throws -> Invitation {
        var invite = try await invitation(code: code)
        let suggestion = GroupSuggestion(id: UUID().uuidString, groupId: invite.group.id, displayName: displayName ?? auth.session?.displayName ?? "Guest", placeName: draft.placeName, placeAddress: draft.placeAddress, scheduledAtEpochSeconds: draft.scheduledAt, note: draft.note, status: "pending", createdAtEpochSeconds: Int64(Date().timeIntervalSince1970))
        suggestionRows.append(suggestion)
        invite.mySuggestion = suggestion
        return invite
    }
    func suggestions(groupId: String) async throws -> [GroupSuggestion] { suggestionRows.filter { $0.groupId == groupId } }
    func reviewSuggestion(groupId: String, suggestionId: String, accept: Bool) async throws -> LunchGroup {
        guard let index = suggestionRows.firstIndex(where: { $0.id == suggestionId && $0.groupId == groupId }), var group = groups.value.first(where: { $0.id == groupId }) else { throw Self.notFound(groupId) }
        suggestionRows[index].status = accept ? "accepted" : "declined"
        let suggestion = suggestionRows[index]
        if accept {
            if let time = suggestion.scheduledAtEpochSeconds { group.scheduledAtEpochSeconds = time }
            if let place = suggestion.placeName { group.placeName = place; group.placeAddress = suggestion.placeAddress; group.placeId = nil }
            let pending = rsvpsByGroup[groupId]?.value.map { row -> Rsvp in var row = row; row.status = .pending; return row } ?? []
            rsvpsByGroup[groupId]?.send(pending)
        }
        groups.send(groups.value.map { $0.id == groupId ? group : $0 })
        return group
    }
    func updateDetails(groupId: String, details: GroupDetails) async throws -> LunchGroup {
        guard var group = groups.value.first(where: { $0.id == groupId }) else { throw Self.notFound(groupId) }
        group.hostName = details.hostName; group.budgetPerPersonMinor = details.budgetPerPersonMinor
        group.currencyCode = details.currencyCode; group.paymentArrangement = details.paymentArrangement; group.paymentMethod = details.paymentMethod
        groups.send(groups.value.map { $0.id == groupId ? group : $0 })
        return group
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
