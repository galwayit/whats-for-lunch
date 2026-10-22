//
//  ViewModelTests.swift
//  LunchAppTests
//
//  @file ViewModelTests.swift
//  @description View-model behaviour over the in-memory PreviewLunchCore: the free AI gate, Pro-only
//  group hosting, guest invitation acceptance and paywall product listing.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import Testing
@testable import LunchApp

/// Consent already given, so these tests exercise the daily gate rather than the consent card.
@MainActor
private func grantedAIConsent() -> AIDataConsent {
    let suite = "ViewModelTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let consent = AIDataConsent(defaults: defaults)
    consent.grant(version: "preview-ai-v2")
    return consent
}

@MainActor
struct AIGateViewModelTests {
    @Test func used_free_request_prompts_for_subscription_before_provider_configuration() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false, isSignedIn: true, aiUsedToday: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: grantedAIConsent())
        await model.ask()
        #expect(model.isGated)
        #expect(model.requiresSubscription)
        #expect(model.aiConfiguration == nil)
        #expect(!model.needsConsent)
    }

    @Test func first_free_request_succeeds_and_second_prompts_without_losing_result() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false, isSignedIn: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: grantedAIConsent())
        await model.ask()
        let first = model.state.value
        #expect(first != nil)
        #expect(!model.requiresSubscription)
        await model.ask()
        #expect(model.requiresSubscription)
        #expect(model.state.value?.id == first?.id)
        #expect(await core.ai.usedToday(userId: PreviewData.user.id) == 1)
    }

    @Test func quota_routes_free_users_to_paywall_but_does_not_upsell_subscribers() {
        let free = AppEnvironment.preview(PreviewCoreOptions(isPro: false, isSignedIn: true))
        #expect(free.present(gate: .aiDailyLimit))
        #expect(free.routes.last == .paywall)
        let pro = AppEnvironment.preview(PreviewCoreOptions(isPro: true, isSignedIn: true))
        #expect(!pro.present(gate: .aiDailyLimit))
        #expect(pro.routes.isEmpty)
    }

    @Test func subscribing_after_free_request_unlocks_the_same_ai_screen() async throws {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false, isSignedIn: true, aiUsedToday: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: grantedAIConsent())
        await model.ask()
        #expect(model.requiresSubscription)
        _ = try await core.entitlements.purchase(packageIdentifier: "$rc_monthly")
        await model.ask()
        #expect(!model.isGated)
        #expect(model.state.value != nil)
    }

    @Test func exhausted_subscriber_gets_reset_message_instead_of_upgrade() async throws {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let gates = try #require(core.gates as? PreviewGateService)
        for _ in 0..<10 { gates.recordAiUsed() }
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: grantedAIConsent())
        await model.ask()
        #expect(model.isGated)
        #expect(!model.requiresSubscription)
        #expect(model.aiConfiguration == nil)
    }

    @Test func should_return_recommendation_when_pro_user_already_used_today() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true, aiUsedToday: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: grantedAIConsent())
        await model.ask()
        #expect(!model.isGated)
        #expect(model.state.value != nil)
    }
}

@MainActor
struct GroupHostGateTests {
    @Test func should_deny_hosting_when_user_is_free() {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false, isSignedIn: true))
        #expect(core.gates.canHostGroup() == .denied(.hostRequiresPro))
    }

    @Test func should_require_sign_in_when_pro_user_is_signed_out() {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: false))
        #expect(core.gates.canHostGroup() == .denied(.signInRequired))
    }

    @Test func should_present_paywall_when_free_user_taps_plan_group() {
        let app = AppEnvironment.preview(PreviewCoreOptions(isPro: false, isSignedIn: true))
        let decision = app.core.gates.canHostGroup()

        #expect(!decision.allowed)
        #expect(app.present(gate: decision.reason))
        #expect(app.routes.last == .paywall)
    }

    @Test func should_create_group_when_user_is_pro_and_signed_in() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        #expect(core.gates.canHostGroup().allowed)
        let model = GroupCreateViewModel(core: core)
        model.name = "Friday team lunch"
        await model.loadArea()

        let group = await model.create()

        #expect(group?.name == "Friday team lunch")
        #expect(group?.hostName == PreviewData.userName)
    }

    @Test func should_not_create_group_when_name_is_blank() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = GroupCreateViewModel(core: core)
        model.name = "   "
        await model.loadArea()

        #expect(await model.create() == nil)
    }
}

@MainActor
struct InvitationViewModelTests {
    private func freshDefaults() -> UserDefaults {
        let suite = "InvitationViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func should_accept_as_guest_when_signed_out_and_name_given() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false, isSignedIn: false))
        let model = InvitationViewModel(core: core, code: PreviewData.group.inviteCode, defaults: freshDefaults())
        await model.load()
        #expect(model.invitation?.myStatus == nil)

        model.guestName = "Sam"
        await model.respond(.accepted, requiresName: true)

        #expect(model.status == .accepted)
        #expect(model.actionError == nil)
        #expect(model.invitation?.attendees.contains { $0.displayName == "Sam" && $0.status == .accepted } == true)
    }

    @Test func should_reject_accept_when_guest_name_is_missing() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: false))
        let model = InvitationViewModel(core: core, code: PreviewData.group.inviteCode, defaults: freshDefaults())
        await model.load()

        await model.respond(.accepted, requiresName: true)

        #expect(model.status == nil)
        #expect(model.actionError == .service(code: "NAME_REQUIRED", message: Copy.Group.inviteNamePrompt))
    }

    @Test func should_load_missing_error_when_code_is_unknown() async {
        let core = PreviewLunchCore()
        let model = InvitationViewModel(core: core, code: "NOPE00", defaults: freshDefaults())

        await model.load()

        #expect(model.invitation == nil)
        #expect(model.loadError != nil)
    }

    @Test func should_show_guest_offer_once_when_second_invitation_accepted() async {
        let defaults = freshDefaults()
        let core = PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: false))
        let first = InvitationViewModel(core: core, code: PreviewData.group.inviteCode, defaults: defaults)
        await first.load()
        first.guestName = "Sam"
        await first.respond(.accepted, requiresName: true)
        #expect(!first.showsGuestOffer)

        let second = InvitationViewModel(core: core, code: PreviewData.group.inviteCode, defaults: defaults)
        await second.load()
        second.guestName = "Sam"
        await second.respond(.accepted, requiresName: true)
        #expect(second.showsGuestOffer)

        let third = InvitationViewModel(core: core, code: PreviewData.group.inviteCode, defaults: defaults)
        await third.load()
        third.guestName = "Sam"
        await third.respond(.accepted, requiresName: true)
        #expect(!third.showsGuestOffer)
    }
}

@MainActor
struct PaywallViewModelTests {
    @Test func completed_transaction_without_pro_shows_restore_guidance() async {
        let store = PurchaseOutcomeStub(result: .success(.free))
        let model = PaywallViewModel(entitlements: store, auth: PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true)).auth)
        await model.purchase(PreviewData.monthlyPackage)
        #expect(!model.isSubscribed)
        #expect(!model.isPurchasing)
        #expect(model.error != nil)
        #expect(model.errorTitle == Copy.Paywall.activationTitle)
        #expect(model.errorMessage.contains("Restore purchases"))
    }

    @Test func sdk_cancellation_is_quiet_and_stops_the_spinner() async {
        let store = PurchaseOutcomeStub(result: .failure(CoreError.service(code: "PURCHASE_CANCELLED", message: "User cancelled")))
        let model = PaywallViewModel(entitlements: store, auth: PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true)).auth)
        await model.purchase(PreviewData.monthlyPackage)
        #expect(!model.isSubscribed)
        #expect(!model.isPurchasing)
        #expect(model.error == nil)
        #expect(await model.restore() == nil)
        #expect(model.error == nil)
    }

    @Test func failed_payment_has_store_guidance_and_retry_can_succeed() async {
        let store = PurchaseOutcomeStub(result: .failure(CoreError.service(code: "StoreProblemError", message: "internal store diagnostic")))
        let model = PaywallViewModel(entitlements: store, auth: PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true)).auth)
        await model.purchase(PreviewData.monthlyPackage)
        #expect(!model.isSubscribed)
        #expect(!model.isPurchasing)
        #expect(model.errorMessage == Copy.Paywall.purchaseErrorBody)
        #expect(!model.errorMessage.contains("internal store diagnostic"))
        store.result = .success(SubscriptionStatus(isPro: true, productId: "monthly", expiresAtEpochSeconds: nil, willRenew: true, managementUrl: nil))
        await model.purchase(PreviewData.monthlyPackage)
        #expect(model.isSubscribed)
        #expect(model.error == nil)
    }

    @Test func pending_payment_does_not_unlock_pro_or_ask_to_pay_again() async {
        let store = PurchaseOutcomeStub(result: .failure(CoreError.service(code: "PaymentPendingError", message: "Pending")))
        let model = PaywallViewModel(entitlements: store, auth: PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true)).auth)
        await model.purchase(PreviewData.monthlyPackage)
        #expect(!model.isSubscribed)
        #expect(!model.isPurchasing)
        #expect(model.errorTitle == Copy.Paywall.paymentPendingTitle)
        #expect(model.errorMessage == Copy.Paywall.paymentPendingBody)
    }

    @Test func should_list_both_products_when_offerings_load() async {
        let model = PaywallViewModel(core: PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true)))

        await model.load()

        #expect(model.yearly?.productId == "au.iapp.lunch.pro.yearly")
        #expect(model.yearly?.hasFreeTrial == false)
        #expect(model.yearly?.localizedPrice == "A$29.99")
        #expect(model.monthly?.productId == "au.iapp.lunch.pro.monthly")
        #expect(model.monthly?.hasFreeTrial == false)
        #expect(model.monthly?.localizedPrice == "A$4.99")
    }

    @Test func should_report_subscribed_when_purchase_succeeds() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true))
        let model = PaywallViewModel(core: core)
        await model.load()

        await model.purchase(model.yearly!)

        #expect(model.isSubscribed)
        #expect(core.entitlements.isPro)
    }

    @Test func should_report_nothing_to_restore_when_free_user_restores() async {
        let model = PaywallViewModel(core: PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: true)))

        let outcome = await model.restore()

        #expect(outcome == .nothingToRestore)
        #expect(!model.isSubscribed)
    }

    @Test func should_fail_offerings_when_offline() async {
        let model = PaywallViewModel(core: PreviewLunchCore(options: PreviewCoreOptions(isOffline: true)))

        await model.load()

        #expect(model.yearly == nil)
        if case .failed = model.offerings {} else { Issue.record("expected failed state") }
    }
}

@MainActor
private final class PurchaseOutcomeStub: EntitlementRepository {
    var result: Result<SubscriptionStatus, Error>
    var status = SubscriptionStatus.free
    let appUserId = "fictional-purchase-test"
    var isPro: Bool { status.isPro }
    var isProUpdates: AsyncStream<Bool> { AsyncStream { $0.yield(isPro); $0.finish() } }
    var statusUpdates: AsyncStream<SubscriptionStatus> { AsyncStream { $0.yield(status); $0.finish() } }

    init(result: Result<SubscriptionStatus, Error>) { self.result = result }
    func offerings() async throws -> ProOfferings { PreviewData.offerings }
    func purchase(packageIdentifier: String) async throws -> SubscriptionStatus {
        status = try result.get()
        return status
    }
    func restore() async throws -> SubscriptionStatus { try result.get() }
    func logIn(userId: String) async throws {}
    func logOut() async throws {}
}
