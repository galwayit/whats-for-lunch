/**
 * @file ProfileViewModel.swift
 * @description Subscription status, restore, sign-out, account deletion and the data export
 *              for the Profile tab. Profile fields themselves come from `AppEnvironment`.
 * @author AI Assistant
 * @date 2026-09-03
 */

import Foundation

@Observable
final class ProfileViewModel {
    private(set) var status: SubscriptionStatus
    private(set) var isRestoring = false
    private(set) var isSigningOut = false
    private(set) var isDeleting = false
    private(set) var isExporting = false
    private(set) var error: CoreError?

    private let core: LunchCoreClient

    init(core: LunchCoreClient) {
        self.core = core
        status = core.entitlements.status
    }

    /// Plan label derived from the store product id (`...yearly` / `...annual` versus monthly).
    var planName: String {
        let productId = status.productId?.lowercased() ?? ""
        let isYearly = productId.contains("year") || productId.contains("annual")
        return isYearly ? Copy.Profile.planYearly : Copy.Profile.planMonthly
    }

    var renewal: SubscriptionRow.Renewal {
        let date = status.expiresAt.map(LunchFormat.day) ?? ""
        return status.willRenew ? .renews(date) : .ends(date)
    }

    func observeStatus() async {
        for await status in core.entitlements.statusUpdates { self.status = status }
    }

    func restore() async -> Bool {
        isRestoring = true
        defer { isRestoring = false }
        return await perform { status = try await core.entitlements.restore() }
    }

    func signOut() async -> Bool {
        isSigningOut = true
        defer { isSigningOut = false }
        return await perform { try await core.auth.signOut() }
    }

    func deleteAccount() async -> Bool {
        isDeleting = true
        defer { isDeleting = false }
        return await perform { try await core.auth.deleteAccount() }
    }

    /// Writes the profile and every logged meal as JSON to a temporary file for the share sheet.
    func exportData(user: UserProfile, now: Date = .now) async -> URL? {
        isExporting = true
        defer { isExporting = false }
        error = nil
        do {
            let meals = try await core.meals.inRange(userId: user.id, startEpochSeconds: 0, endEpochSeconds: Int64(now.timeIntervalSince1970))
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DataExport(exportedAt: now, profile: user, meals: meals))
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("lunch-export.json")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            self.error = CoreError.from(error)
            return nil
        }
    }

    private func perform(_ work: () async throws -> Void) async -> Bool {
        error = nil
        do {
            try await work()
            return true
        } catch {
            self.error = CoreError.from(error)
            return false
        }
    }
}

/// Shape of the "Export my data" file.
nonisolated struct DataExport: Encodable {
    let exportedAt: Date
    let profile: UserProfile
    let meals: [Meal]
}
