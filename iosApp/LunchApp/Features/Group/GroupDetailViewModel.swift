//
//  GroupDetailViewModel.swift
//  LunchApp
//
//  @file GroupDetailViewModel.swift
//  @description Observes a group and its RSVPs through GroupRepository, schedules the local reminder and cancels the lunch.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Observation

@Observable
final class GroupDetailViewModel {
    private(set) var group: LunchGroup?
    private(set) var guests: [Rsvp] = []
    private(set) var error: CoreError?
    var actionError: CoreError?
    private(set) var reminderEnabled = false
    private(set) var isCancelling = false

    private let core: LunchCoreClient
    private let groupId: String

    init(core: LunchCoreClient, groupId: String) {
        self.core = core
        self.groupId = groupId
    }

    var inviteUrl: String {
        group.map { LunchConfig.current.inviteUrl(code: $0.inviteCode) } ?? LunchConfig.defaultInviteLinkBase
    }

    func observeGroup() async {
        error = nil
        for await groups in core.groups.myGroups() {
            guard !Task.isCancelled else { return }
            if let group = groups.first(where: { $0.id == groupId }) {
                self.group = group
            } else {
                error = .service(code: "NOT_FOUND", message: "Group not found")
                return
            }
        }
    }

    func observeGuests() async {
        for await guests in core.groups.rsvps(groupId: groupId) {
            guard !Task.isCancelled else { return }
            self.guests = guests
        }
    }

    func setReminder(_ enabled: Bool) async {
        guard let group else { return }
        if enabled {
            do {
                try await GroupReminder.schedule(group)
                reminderEnabled = true
            } catch {
                reminderEnabled = false
                actionError = CoreError.from(error)
            }
        } else {
            GroupReminder.cancel(groupId: group.id)
            reminderEnabled = false
        }
    }

    func cancel() async -> Bool {
        guard !isCancelling else { return false }
        isCancelling = true
        defer { isCancelling = false }
        do {
            try await core.groups.cancel(groupId: groupId)
            GroupReminder.cancel(groupId: groupId)
            return true
        } catch {
            actionError = CoreError.from(error)
            return false
        }
    }
}
