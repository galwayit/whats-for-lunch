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
    private(set) var suggestions: [GroupSuggestion] = []
    private(set) var suggestionsError: CoreError?
    private(set) var reviewingId: String?
    var isHost: Bool {
        guard let group, let session = core.auth.session else { return false }
        return group.hostId == session.userId
    }
    func loadSuggestions() async {
        guard isHost else { return }
        do { suggestions = try await core.groups.suggestions(groupId: groupId); suggestionsError = nil }
        catch { suggestionsError = CoreError.from(error) }
    }
    func review(_ suggestion: GroupSuggestion, accept: Bool) async {
        guard reviewingId == nil else { return }
        reviewingId = suggestion.id
        defer { reviewingId = nil }
        do {
            group = try await core.groups.reviewSuggestion(groupId: groupId, suggestionId: suggestion.id, accept: accept)
            await refresh()
        } catch { actionError = CoreError.from(error); await loadSuggestions() }
    }
    func updateDetails(_ details: GroupDetails) async throws {
        group = try await core.groups.updateDetails(groupId: groupId, details: details)
    }
    private(set) var error: CoreError?
    var actionError: CoreError?
    private(set) var guestsError: CoreError?
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
        do {
            let groups = try await core.groups.loadGroups()
            guard !Task.isCancelled else { return }
            group = groups.first { $0.id == groupId }
            error = group == nil ? .service(code: "NOT_FOUND", message: "This lunch was cancelled or is no longer available.") : nil
            if group != nil { reminderEnabled = await GroupReminder.isScheduled(groupId: groupId) }
        } catch is CancellationError { return }
        catch { self.error = CoreError.from(error) }
    }

    func observeGuests() async {
        do {
            let guests = try await core.groups.loadRsvps(groupId: groupId)
            guard !Task.isCancelled else { return }
            self.guests = guests
            guestsError = nil
        } catch is CancellationError { return }
        catch { guestsError = CoreError.from(error) }
    }

    func refresh() async {
        async let groupLoad: () = observeGroup()
        async let guestLoad: () = observeGuests()
        _ = await (groupLoad, guestLoad)
        await loadSuggestions()
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
