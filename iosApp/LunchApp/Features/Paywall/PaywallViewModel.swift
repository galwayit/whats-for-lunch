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

    private let entitlements: EntitlementRepository
    private let auth: AuthRepository

    convenience init(core: LunchCoreClient) {
        self.init(entitlements: core.entitlements, auth: core.auth)
    }

    init(entitlements: EntitlementRepository, auth: AuthRepository) {
        self.entitlements = entitlements
        self.auth = auth
    }

    var errorTitle: String {
        if case .service(code: "PaymentPendingError", message: _) = error { return Copy.Paywall.paymentPendingTitle }
        if case .service(code: "PURCHASE_NOT_ACTIVATED", message: _) = error { return Copy.Paywall.activationTitle }
        return Copy.Paywall.purchaseErrorTitle
    }

    var errorMessage: String {
        switch error {
        case .offline: return Copy.Paywall.offlineBody
        case .notSignedIn, .gate(.signInRequired): return Copy.Paywall.signInRequiredBody
        case .service(code: "PURCHASE_NOT_ACTIVATED", message: _): return Copy.Paywall.activationBody
        case .service(code: "PaymentPendingError", message: _): return Copy.Paywall.paymentPendingBody
        case .service(code: "PurchaseNotAllowedError", message: _): return Copy.Paywall.purchaseNotAllowedBody
        case .service(code: "ProductNotAvailableForPurchaseError", message: _),
             .service(code: "PACKAGE_NOT_FOUND", message: _): return Copy.Paywall.productUnavailableBody
        default: return Copy.Paywall.purchaseErrorBody
        }
    }

    var yearly: ProPackage? { offerings.value?.yearly }
    var monthly: ProPackage? { offerings.value?.monthly }

    func load() async {
        guard !offerings.isLoading else { return }
        offerings = .loading
        do {
            let available = try await entitlements.offerings()
            guard available.monthly != nil || available.yearly != nil else {
                throw CoreError.service(code: "NO_PRODUCTS", message: "Subscriptions are not available right now. Please try again later.")
            }
            offerings = .loaded(available)
        } catch {
            offerings = .failed(CoreError.from(error))
        }
    }

    /// Buys `package` through the core; a store cancellation is not an error.
    func purchase(_ package: ProPackage) async {
        guard !isPurchasing else { return }
        guard auth.session != nil else { error = .gate(.signInRequired); return }
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }
        do {
            let status = try await entitlements.purchase(packageIdentifier: package.identifier)
            isSubscribed = status.isPro
            if !status.isPro { error = .service(code: "PURCHASE_NOT_ACTIVATED", message: Copy.Paywall.activationBody) }
        } catch is CancellationError {
            // The user backed out of the store sheet; nothing to report.
        } catch {
            let failure = CoreError.from(error)
            if case .service(code: "PURCHASE_CANCELLED", message: _) = failure { return }
            self.error = failure
        }
    }

    func restore() async -> RestoreOutcome? {
        guard !isPurchasing else { return nil }
        guard auth.session != nil else { error = .gate(.signInRequired); return nil }
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }
        do {
            let status = try await entitlements.restore()
            isSubscribed = status.isPro
            return status.isPro ? .subscribed : .nothingToRestore
        } catch is CancellationError {
            return nil
        } catch {
            let failure = CoreError.from(error)
            if case .service(code: "PURCHASE_CANCELLED", message: _) = failure { return nil }
            self.error = failure
            return nil
        }
    }
}
