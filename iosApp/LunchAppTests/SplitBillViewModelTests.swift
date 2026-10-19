//
//  SplitBillViewModelTests.swift
//  LunchAppTests
//
//  @file SplitBillViewModelTests.swift
//  @description The split-the-bill sheet: Track/Group prefill, the stepper, live rebalancing,
//  Reset, every engine error, the share message, and the two "Use my share" results.
//  @author AI Assistant
//  @date 2026-09-23
//

import Foundation
import Testing
@testable import LunchApp

@MainActor
private func freshDefaults() -> UserDefaults {
    let suite = "SplitBillViewModelTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

@MainActor
struct SplitBillViewModelPrefillTests {
    @Test func should_prefill_bill_and_two_people_when_track_cost_is_valid() {
        let model = SplitBillViewModel(prefillBillDollars: 42.0, defaults: freshDefaults())

        #expect(model.bill == 42.0)
        #expect(model.people.map(\.name) == [Copy.Split.personYou, Copy.Split.personN(2)])
        #expect(model.peopleStepperRange == 1...SwiftBillSplitEngine.maxPeople)
    }

    @Test func should_leave_bill_empty_when_track_cost_is_invalid() {
        #expect(SplitBillViewModel(prefillBillDollars: nil, defaults: freshDefaults()).bill == nil)
        #expect(SplitBillViewModel(prefillBillDollars: 0, defaults: freshDefaults()).bill == nil)
        #expect(SplitBillViewModel(prefillBillDollars: -5, defaults: freshDefaults()).bill == nil)
    }

    @Test func should_list_you_first_and_only_accepted_guests_when_building_group_people() {
        let names = SplitBillViewModel.acceptedGuestNames(PreviewData.rsvps, hostId: PreviewData.group.hostId)
        #expect(names == ["Mei"], "the host's own RSVP is not listed a second time")

        let model = SplitBillViewModel(guestNames: names, placeName: PreviewData.group.placeName, defaults: freshDefaults())

        #expect(model.people.map(\.name) == ["You", "Mei"])
        #expect(model.peopleStepperRange == nil)
    }
}

@MainActor
struct SplitBillViewModelStepperTests {
    @Test func should_add_person_with_next_default_name_when_stepper_increases() {
        let model = SplitBillViewModel(prefillBillDollars: nil, defaults: freshDefaults())

        model.peopleCount = 3

        #expect(model.people.map(\.name) == ["You", "Person 2", "Person 3"])
    }

    @Test func should_remove_trailing_people_when_stepper_decreases() {
        let model = SplitBillViewModel(prefillBillDollars: nil, defaults: freshDefaults())
        model.peopleCount = 4

        model.peopleCount = 2

        #expect(model.people.map(\.name) == ["You", "Person 2"])
    }

    @Test func should_ignore_out_of_range_values_when_setting_people_count() {
        let model = SplitBillViewModel(prefillBillDollars: nil, defaults: freshDefaults())

        model.peopleCount = 0
        #expect(model.people.count == 2)

        model.peopleCount = SwiftBillSplitEngine.maxPeople + 1
        #expect(model.people.count == 2)
    }
}

@MainActor
struct SplitBillViewModelRebalanceTests {
    @Test func should_rebalance_other_rows_when_one_row_is_adjusted() {
        let model = SplitBillViewModel(prefillBillDollars: 90.0, defaults: freshDefaults())
        model.peopleCount = 3

        model.setShare(50.0, for: 0)

        #expect(model.people[0].isAdjusted)
        #expect(model.shareDollars(for: 0) == 50.0)
        #expect(model.shareDollars(for: 1) == 20.0)
        #expect(model.shareDollars(for: 2) == 20.0)
        #expect(model.isValid)
    }

    @Test func should_unadjust_row_when_reset_is_called() {
        let model = SplitBillViewModel(prefillBillDollars: 90.0, defaults: freshDefaults())
        model.setShare(70.0, for: 0)
        #expect(model.people[0].isAdjusted)

        model.reset(0)

        #expect(!model.people[0].isAdjusted)
        #expect(model.shareDollars(for: 0) == 45.0)
    }

    @Test func should_unadjust_row_when_the_field_is_cleared() {
        let model = SplitBillViewModel(prefillBillDollars: 90.0, defaults: freshDefaults())
        model.setShare(70.0, for: 0)

        model.setShare(nil, for: 0)

        #expect(!model.people[0].isAdjusted)
    }
}

@MainActor
struct SplitBillViewModelErrorTests {
    @Test func should_show_no_bill_error_and_disable_actions_when_bill_is_empty() {
        let model = SplitBillViewModel(prefillBillDollars: nil, defaults: freshDefaults())
        #expect(model.errorMessage == Copy.Split.errorNoBill)
        #expect(!model.isValid)
    }

    @Test func should_stay_valid_at_the_stepper_maximum_of_fifty_people() {
        let model = SplitBillViewModel(prefillBillDollars: 100, defaults: freshDefaults())

        model.peopleCount = SwiftBillSplitEngine.maxPeople

        #expect(model.peopleCount == 50)
        #expect(model.isValid)
    }

    @Test func should_show_surcharge_error_when_surcharge_exceeds_fifty_percent() {
        let model = SplitBillViewModel(prefillBillDollars: 100, defaults: freshDefaults())
        model.surchargePercent = 60

        #expect(model.errorMessage == Copy.Split.errorSurcharge)
        #expect(!model.isValid)
    }

    @Test func should_show_over_allocated_error_with_the_difference_when_fixed_amounts_exceed_the_bill() {
        let model = SplitBillViewModel(prefillBillDollars: 50, defaults: freshDefaults())
        model.setShare(30, for: 0)
        model.setShare(30, for: 1)

        #expect(model.errorMessage == Copy.Split.errorOver(LunchFormat.currencyExact(10)))
        #expect(!model.isValid)
    }

    @Test func should_show_under_allocated_error_with_the_difference_when_fixed_amounts_fall_short() {
        let model = SplitBillViewModel(prefillBillDollars: 50, defaults: freshDefaults())
        model.setShare(10, for: 0)
        model.setShare(10, for: 1)

        #expect(model.errorMessage == Copy.Split.errorUnder(LunchFormat.currencyExact(30)))
        #expect(!model.isValid)
    }
}

@MainActor
struct SplitBillViewModelShareMessageTests {
    @Test func should_build_message_with_place_and_payid_when_both_are_set() {
        let model = SplitBillViewModel(guestNames: ["Mei"], placeName: "Green Garden Bowls", defaults: freshDefaults())
        model.bill = 40
        model.payId = "ray@bank"

        let message = model.shareMessage

        #expect(message.hasPrefix("Green Garden Bowls: bill $40.00 split 2 ways"))
        #expect(message.contains("You: $20.00"))
        #expect(message.contains("Mei: $20.00"))
        #expect(message.contains("Pay me at: ray@bank"))
        #expect(message.hasSuffix(Copy.Split.messageFooter))
    }

    @Test func should_use_place_fallback_and_omit_pay_line_when_place_and_payid_are_unset() {
        let model = SplitBillViewModel(prefillBillDollars: 40, defaults: freshDefaults())

        let message = model.shareMessage

        #expect(message.hasPrefix("Lunch: bill $40.00 split 2 ways"))
        #expect(!message.contains("Pay me at"))
    }

    @Test func should_be_empty_when_the_split_is_invalid() {
        let model = SplitBillViewModel(prefillBillDollars: nil, defaults: freshDefaults())
        #expect(model.shareMessage.isEmpty)
    }
}

@MainActor
struct SplitBillViewModelUseShareTests {
    @Test func should_fill_cost_and_default_notes_when_track_notes_are_empty() {
        let core = PreviewLunchCore()
        let track = TrackViewModel(core: core)
        let split = SplitBillViewModel(prefillBillDollars: 40, defaults: freshDefaults())

        track.applySplitShare(cost: split.myShareDollars, note: split.useShareNote!)

        #expect(track.cost == 20.0)
        #expect(track.notes == "Split 2 ways, bill $40.00")
    }

    @Test func should_keep_existing_notes_when_track_notes_are_not_empty() {
        let core = PreviewLunchCore()
        let track = TrackViewModel(core: core)
        track.notes = "Team lunch"
        let split = SplitBillViewModel(prefillBillDollars: 40, defaults: freshDefaults())

        track.applySplitShare(cost: split.myShareDollars, note: split.useShareNote!)

        #expect(track.cost == 20.0)
        #expect(track.notes == "Team lunch")
    }

    @Test func should_build_a_lunch_meal_at_the_groups_place_and_time_when_group_uses_their_share() {
        let split = SplitBillViewModel(guestNames: ["Ray", "Mei"], placeName: PreviewData.group.placeName, defaults: freshDefaults())
        split.bill = 60

        let meal = split.buildGroupMeal(userId: PreviewData.userId, group: PreviewData.group)

        #expect(meal?.userId == PreviewData.userId)
        #expect(meal?.mealType == "lunch")
        #expect(meal?.restaurantId == PreviewData.group.placeId)
        #expect(meal?.restaurantName == PreviewData.group.placeName)
        #expect(meal?.cost == 20.0)
        #expect(meal?.dateEpochSeconds == PreviewData.group.scheduledAtEpochSeconds)
        #expect(meal?.notes == "Split 3 ways, bill $60.00")
    }

    @Test func should_return_nil_meal_when_the_split_is_invalid() {
        let split = SplitBillViewModel(guestNames: ["Ray"], placeName: nil, defaults: freshDefaults())
        #expect(split.buildGroupMeal(userId: PreviewData.userId, group: PreviewData.group) == nil)
    }
}

/// Consistency with the Android core: the "bill" in `split.note` and `split.message.header` is
/// the total including surcharge, and `split.total.surcharge`'s second value is the surcharge in
/// dollars, not the percent typed.
@MainActor
struct SplitBillViewModelSurchargeConsistencyTests {
    @Test func should_use_the_total_including_surcharge_as_the_bill_in_note_and_message_header() {
        let split = SplitBillViewModel(prefillBillDollars: 100, defaults: freshDefaults())
        split.surchargePercent = 10

        #expect(split.useShareNote == "Split 2 ways, bill $110.00")
        #expect(split.shareMessage.hasPrefix("Lunch: bill $110.00 split 2 ways"))
    }

    @Test func should_show_the_surcharge_in_dollars_not_percent_on_the_total_line() {
        let split = SplitBillViewModel(prefillBillDollars: 100, defaults: freshDefaults())
        split.surchargePercent = 10

        #expect(split.totalLine == "Total $110.00 incl. $10.00 surcharge")
    }

    @Test func should_omit_the_surcharge_clause_when_there_is_no_surcharge() {
        let split = SplitBillViewModel(prefillBillDollars: 100, defaults: freshDefaults())
        #expect(split.totalLine == "Total $100.00")
    }
}

/// Android found their currency helper dropping decimals for whole amounts; guards the iOS
/// exact-cents formatter against the same regression.
struct LunchFormatCentsTests {
    @Test func should_always_show_two_decimals_even_for_whole_dollar_amounts() {
        #expect(LunchFormat.currencyExact(cents: 20_000) == "$200.00")
        #expect(LunchFormat.currencyExact(cents: 4_000) == "$40.00")
        #expect(LunchFormat.currencyExact(cents: 150) == "$1.50")
        #expect(LunchFormat.currencyExact(cents: 0) == "$0.00")
    }
}
