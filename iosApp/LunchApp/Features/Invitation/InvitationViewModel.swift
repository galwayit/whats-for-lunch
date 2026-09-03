//
//  InvitationViewModel.swift
//  LunchApp
//
//  @file InvitationViewModel.swift
//  @description Loads and answers an invitation through GroupRepository and adds the accepted lunch to the calendar.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Observation

@Observable
final class InvitationViewModel {
    private(set) var invitation: Invitation?
    private(set) var isLoading = false
    private(set) var isResponding = false
    private(set) var isAddingToCalendar = false
    private(set) var loadError: CoreError?
    private(set) var actionError: CoreError?
    var guestName = ""
    /// True once, right after this device's second accepted invitation (design/screens.md section 11).
    private(set) var showsGuestOffer = false

    private let core: LunchCoreClient
    private let code: String
    private let defaults: UserDefaults

    static let acceptedCountKey = "invitation.acceptedCount"
    static let guestOfferShownKey = "invitation.guestOfferShown"
    static let guestOfferThreshold = 2

    init(core: LunchCoreClient, code: String, defaults: UserDefaults = .standard) {
        self.core = core
        self.code = code
        self.defaults = defaults
    }

    var status: RsvpStatus? { invitation?.myStatus }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            invitation = try await core.groups.invitation(code: code)
        } catch {
            loadError = CoreError.from(error)
        }
    }

    func respond(_ status: RsvpStatus, requiresName: Bool) async {
        let name = guestName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requiresName || !name.isEmpty else {
            actionError = .service(code: "NAME_REQUIRED", message: Copy.Group.inviteNamePrompt)
            return
        }
        guard !isResponding else { return }
        isResponding = true
        actionError = nil
        defer { isResponding = false }
        do {
            invitation = try await core.groups.respond(code: code, status: status, displayName: name.isEmpty ? nil : name)
            if status == .accepted { recordAcceptance() }
        } catch {
            actionError = CoreError.from(error)
        }
    }

    /// Counts accepted invitations on this device and arms the one-time guest offer at the threshold.
    private func recordAcceptance() {
        let count = defaults.integer(forKey: Self.acceptedCountKey) + 1
        defaults.set(count, forKey: Self.acceptedCountKey)
        guard count >= Self.guestOfferThreshold, !defaults.bool(forKey: Self.guestOfferShownKey) else { return }
        defaults.set(true, forKey: Self.guestOfferShownKey)
        showsGuestOffer = true
    }

    func addToCalendar() async -> Bool {
        guard let invitation, !isAddingToCalendar else { return false }
        isAddingToCalendar = true
        actionError = nil
        defer { isAddingToCalendar = false }
        do {
            try await GroupCalendar.add(invitation)
            return true
        } catch {
            actionError = CoreError.from(error)
            return false
        }
    }
}
