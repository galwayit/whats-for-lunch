//
//  GroupProposalsViewModel.swift
//  LunchApp
//
//  @file GroupProposalsViewModel.swift
//  @description Loads proposals for a group through GroupRepository.propose and confirms the chosen place.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Observation

@Observable
final class GroupProposalsViewModel {
    private(set) var proposals: [GroupProposal] = []
    private(set) var isLoading = false
    private(set) var choosingPlaceId: String?
    private(set) var error: CoreError?
    private(set) var needsConsent = false
    private(set) var aiConfiguration: AiConfiguration?
    private let consent: AIDataConsent

    private let core: LunchCoreClient
    private let groupId: String

    init(core: LunchCoreClient, groupId: String, consent: AIDataConsent = AIDataConsent()) {
        self.consent = consent
        self.core = core
        self.groupId = groupId
    }

    func load() async {
        guard !isLoading else { return }
        needsConsent = false
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let config = try await core.ai.configuration()
            aiConfiguration = config
            guard consent.isGranted(for: config.consentVersion) else { needsConsent = true; return }
            proposals = try await core.groups.propose(groupId: groupId, consentVersion: config.consentVersion)
        } catch CoreError.service(code: "AI_CONSENT_REQUIRED", message: _) {
            consent.revoke()
            do {
                aiConfiguration = try await core.ai.configuration()
                needsConsent = true
            } catch { self.error = CoreError.from(error) }
        } catch {
            self.error = CoreError.from(error)
        }
    }

    func grantConsent() async {
        guard let aiConfiguration else { return }
        consent.grant(version: aiConfiguration.consentVersion)
        await load()
    }
    func declineConsent() { needsConsent = false }

    func choose(_ restaurant: Restaurant) async -> LunchGroup? {
        guard choosingPlaceId == nil else { return nil }
        choosingPlaceId = restaurant.placeId
        error = nil
        defer { choosingPlaceId = nil }
        do {
            return try await core.groups.confirmPlace(groupId: groupId, restaurant: restaurant)
        } catch {
            self.error = CoreError.from(error)
            return nil
        }
    }
}
