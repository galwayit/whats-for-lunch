import Foundation
import Testing
@testable import LunchApp

@MainActor
struct InvitationPlanningTests {
    @Test func budget_input_preserves_exact_cents_and_rejects_invalid_values() {
        var draft = GroupDetailsDraft(GroupDetails(hostName: "Sam"))
        #expect(draft.value?.budgetPerPersonMinor == nil)
        draft.budget = "25.50"; #expect(draft.value?.budgetPerPersonMinor == 2550)
        draft.budget = "0"; #expect(draft.value?.budgetPerPersonMinor == 0)
        for invalid in ["-2", "2.999", "10000.01", "NaN", "1,000"] { draft.budget = invalid; #expect(draft.value == nil) }
        draft.budget = "25"; draft.hostName = "  "; #expect(draft.value == nil)
    }
    @Test func missing_plan_details_are_explicit_and_zero_is_not_missing() {
        var details = GroupDetails()
        #expect(details.budgetDescription == "Budget: to be confirmed")
        #expect(details.paymentDescription == "To be confirmed")
        details.budgetPerPersonMinor = 0
        #expect(details.budgetDescription.contains("0.00"))
    }
    @Test func guest_suggestion_keeps_rsvp_and_current_plan_until_host_applies() async throws {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isSignedIn: false))
        let model = InvitationViewModel(core: core, code: PreviewData.group.inviteCode)
        await model.load()
        let original = try #require(model.invitation?.group)
        model.guestName = "Fictional guest"
        let newTime = original.scheduledAtEpochSeconds + 3600
        #expect(await model.suggest(GroupSuggestionDraft(placeName: "Test cafe", placeAddress: "10 Test Lane", scheduledAt: newTime, note: "An alternative"), requiresName: true))
        let suggestion = try #require(model.invitation?.mySuggestion)
        #expect(model.invitation?.group == original)
        #expect(model.status == nil)
        #expect(suggestion.status == "pending")
        let updated = try await core.groups.reviewSuggestion(groupId: original.id, suggestionId: suggestion.id, accept: true)
        #expect(updated.placeName == "Test cafe")
        #expect(updated.placeId == nil)
        #expect(updated.scheduledAtEpochSeconds == newTime)
        let guests = try await core.groups.loadRsvps(groupId: original.id)
        #expect(guests.allSatisfy { $0.status == .pending })
    }
    @Test func suggestion_requires_guest_name() async {
        let model = InvitationViewModel(core: PreviewLunchCore(), code: PreviewData.group.inviteCode)
        await model.load()
        #expect(await model.suggest(GroupSuggestionDraft(placeName: "Cafe"), requiresName: true) == false)
        #expect(model.invitation?.mySuggestion == nil)
        #expect(model.actionError != nil)
    }
    @Test func create_saves_host_budget_and_payment_details() async throws {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = GroupCreateViewModel(core: core)
        model.name = "Fictional lunch"
        model.detailsDraft = GroupDetailsDraft(GroupDetails(hostName: "Sam", budgetPerPersonMinor: 2550, paymentArrangement: "split_equally", paymentMethod: "card"))
        await model.loadArea()
        let group = try #require(await model.create())
        #expect(group.hostName == "Sam")
        #expect(group.budgetPerPersonMinor == 2550)
        #expect(group.paymentArrangement == "split_equally")
        #expect(group.paymentMethod == "card")
        let invite = try await core.groups.invitation(code: group.inviteCode)
        #expect(invite.group.details == group.details)
    }
}
