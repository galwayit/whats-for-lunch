//
//  PaywallViewModel.swift
//  LunchApp
//
//  @file PaywallViewModel.swift
//  @description Loads Lunch Pro offerings and runs purchase / restore through the core
//  EntitlementRepository. StoreKit is never touched here; the core owns the store.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Observation

@Observable
final class PaywallViewModel {
    /// Feedback after a restore that found no subscription; the view shows it as a toast.
    enum RestoreOutcome { case subscribed, nothingToRestore }

    private(set) var offerings: LoadState<ProOfferings> = .idle
    private(set) var isPurchasing = false
    /// Set once a purchase or restore returns an active entitlement; the view swaps to the success state.
    private(set) var isSubscribed = false
    var error: CoreError?

    private let core: LunchCoreClient

    init(core: LunchCoreClient) { self.core = core }

    var yearly: ProPackage? { offerings.value?.yearly }
    var monthly: ProPackage? { offerings.value?.monthly }

    func load() async {
        guard !offerings.isLoading else { return }
        offerings = .loading
        do {
            offerings = .loaded(try await core.entitlements.offerings())
        } catch {
            offerings = .failed(CoreError.from(error))
        }
    }

    /// Buys `package` through the core; a store cancellation is not an error.
    func purchase(_ package: ProPackage) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }
        do {
            let status = try await core.entitlements.purchase(packageIdentifier: package.identifier)
            isSubscribed = status.isPro
        } catch is CancellationError {
            // The user backed out of the store sheet; nothing to report.
        } catch {
            self.error = CoreError.from(error)
        }
    }

    func restore() async -> RestoreOutcome? {
        guard !isPurchasing else { return nil }
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }
        do {
            let status = try await core.entitlements.restore()
            isSubscribed = status.isPro
            return status.isPro ? .subscribed : .nothingToRestore
        } catch {
            self.error = CoreError.from(error)
            return nil
        }
    }
}
