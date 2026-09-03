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

    private let core: LunchCoreClient
    private let groupId: String

    init(core: LunchCoreClient, groupId: String) {
        self.core = core
        self.groupId = groupId
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            proposals = try await core.groups.propose(groupId: groupId)
        } catch {
            self.error = CoreError.from(error)
        }
    }

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
