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

@MainActor
struct AIGateViewModelTests {
    @Test func should_gate_second_request_when_free_user_already_used_today() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: false, isSignedIn: true, aiUsedToday: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil)
        model.craving = "something light"

        await model.ask()

        #expect(model.isGated)
        #expect(model.state.value == nil)
    }

    @Test func should_return_recommendation_when_pro_user_already_used_today() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true, aiUsedToday: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil)

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
    @Test func should_list_both_products_when_offerings_load() async {
        let model = PaywallViewModel(core: PreviewLunchCore())

        await model.load()

        #expect(model.yearly?.productId == "au.iapp.lunch.pro.yearly")
        #expect(model.yearly?.hasFreeTrial == true)
        #expect(model.yearly?.localizedPrice == "A$19.99")
        #expect(model.monthly?.productId == "au.iapp.lunch.pro.monthly")
        #expect(model.monthly?.hasFreeTrial == false)
        #expect(model.monthly?.localizedPrice == "A$2.99")
    }

    @Test func should_report_subscribed_when_purchase_succeeds() async {
        let core = PreviewLunchCore()
        let model = PaywallViewModel(core: core)
        await model.load()

        await model.purchase(model.yearly!)

        #expect(model.isSubscribed)
        #expect(core.entitlements.isPro)
    }

    @Test func should_report_nothing_to_restore_when_free_user_restores() async {
        let model = PaywallViewModel(core: PreviewLunchCore())

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
