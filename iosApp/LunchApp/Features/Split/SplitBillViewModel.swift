//
//  SplitBillViewModel.swift
//  LunchApp
//
//  Drives the split-the-bill sheet (screen 12 of design/screens.md). Bill, surcharge and people
//  feed SwiftBillSplitEngine on every change; a person typed into becomes "fixed" and the rest
//  rebalance live. PayID is remembered in UserDefaults only, never sent anywhere. The share
//  message and the Track/Group "Use my share" results are built here so they are unit-testable.
//

import Foundation
import Observation

@Observable
final class SplitBillViewModel: Identifiable {
    /// One row. `You` is always index 0. `fixedDollars` is set once the person's amount is typed
    /// (or cleared back to nil, which is the same as Reset).
    struct Person: Identifiable, Equatable {
        let id: Int
        var name: String
        var fixedDollars: Double?
        var isAdjusted: Bool { fixedDollars != nil }
    }

    private static let payIdDefaultsKey = "split.payId"

    var bill: Double?
    var surchargePercent: Double?
    private(set) var people: [Person]
    var payId: String { didSet { defaults.set(payId, forKey: Self.payIdDefaultsKey) } }
    /// Non-nil only for the Track entry point, which lets the user pick 1 to 50 people. The Group
    /// entry point has a fixed guest list and no stepper.
    let peopleStepperRange: ClosedRange<Int>?
    /// Shown in the share message header, or `split.message.place_fallback` when nil.
    let placeName: String?

    private let defaults: UserDefaults

    /// Track entry: the bill prefilled from the cost field (if valid), `You` and `Person 2`, with
    /// a 1...50 stepper.
    init(prefillBillDollars: Double?, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bill = (prefillBillDollars ?? 0) > 0 ? prefillBillDollars : nil
        people = [
            Person(id: 0, name: Copy.Split.personYou, fixedDollars: nil),
            Person(id: 1, name: Copy.Split.personN(2), fixedDollars: nil),
        ]
        peopleStepperRange = 1...SwiftBillSplitEngine.maxPeople
        placeName = nil
        payId = defaults.string(forKey: Self.payIdDefaultsKey) ?? ""
    }

    /// Group entry: `You` then every accepted RSVP by display name, no stepper.
    init(guestNames: [String], placeName: String?, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bill = nil
        people = ([Copy.Split.personYou] + guestNames).enumerated().map { Person(id: $0.offset, name: $0.element, fixedDollars: nil) }
        peopleStepperRange = nil
        self.placeName = placeName
        payId = defaults.string(forKey: Self.payIdDefaultsKey) ?? ""
    }

    /// Only accepted RSVPs join the split; pending and declined guests don't. The core records the
    /// host as an accepted RSVP of their own group, so `hostId` is left out: the host is `You`.
    static func acceptedGuestNames(_ guests: [Rsvp], hostId: String) -> [String] {
        guests.filter { $0.status == .accepted && $0.guestUserId != hostId }.map(\.displayName)
    }

    var peopleCount: Int {
        get { people.count }
        set {
            guard let peopleStepperRange, peopleStepperRange.contains(newValue) else { return }
            if newValue > people.count {
                for index in people.count..<newValue {
                    people.append(Person(id: index, name: Copy.Split.personN(index + 1), fixedDollars: nil))
                }
            } else if newValue < people.count {
                people.removeLast(people.count - newValue)
            }
        }
    }

    private var request: BillSplitRequest {
        var fixed: [Int: Int64] = [:]
        for person in people {
            if let dollars = person.fixedDollars {
                fixed[person.id] = SwiftBillSplitEngine.dollarsToCents(max(0, dollars))
            }
        }
        return BillSplitRequest(
            billCents: SwiftBillSplitEngine.dollarsToCents(bill ?? 0),
            people: people.count,
            surchargeBps: SwiftBillSplitEngine.percentToBps(surchargePercent ?? 0),
            fixedCents: fixed
        )
    }

    var result: BillSplitResult { SwiftBillSplitEngine.split(request) }

    var isValid: Bool {
        if case .split = result { return true }
        return false
    }

    /// The inline error under the rows, mapped from the engine's `BillSplitError`.
    var errorMessage: String? {
        guard case let .invalid(error, differenceCents) = result else { return nil }
        switch error {
        case .noBill: return Copy.Split.errorNoBill
        case .noPeople: return Copy.Split.errorNoPeople
        case .tooManyPeople: return Copy.Split.errorTooMany
        case .surchargeOutOfRange: return Copy.Split.errorSurcharge
        case .overAllocated: return Copy.Split.errorOver(LunchFormat.currencyExact(cents: differenceCents))
        case .underAllocated: return Copy.Split.errorUnder(LunchFormat.currencyExact(cents: differenceCents))
        }
    }

    /// `split.total` or, when there's a surcharge, `split.total.surcharge`.
    var totalLine: String? {
        guard case let .split(totalCents, surchargeCents, _) = result else { return nil }
        let total = LunchFormat.currencyExact(cents: totalCents)
        guard surchargeCents > 0 else { return Copy.Split.total(total) }
        return Copy.Split.totalSurcharge(total, LunchFormat.currencyExact(cents: surchargeCents))
    }

    /// What a row's amount field shows: what was typed, or the engine's computed share.
    func shareDollars(for personId: Int) -> Double? {
        if let person = people.first(where: { $0.id == personId }), let fixed = person.fixedDollars { return fixed }
        guard case let .split(_, _, shares) = result, shares.indices.contains(personId) else { return nil }
        return Double(shares[personId]) / 100
    }

    /// Typing in a row fixes it; `nil` (an emptied field) is the same as Reset.
    func setShare(_ dollars: Double?, for personId: Int) {
        guard let index = people.firstIndex(where: { $0.id == personId }) else { return }
        people[index].fixedDollars = dollars
    }

    func reset(_ personId: Int) {
        setShare(nil, for: personId)
    }

    private var myShareCents: Int64 {
        guard case let .split(_, _, shares) = result, let mine = shares.first else { return 0 }
        return mine
    }

    var myShareDollars: Double { Double(myShareCents) / 100 }

    /// `split.note`: what Track and Group's "Use my share" set as the meal's notes. Nil while the
    /// split is invalid (both buttons are disabled then, so callers never see this).
    var useShareNote: String? {
        guard case let .split(totalCents, _, _) = result else { return nil }
        return Copy.Split.note(people: people.count, bill: LunchFormat.currencyExact(cents: totalCents))
    }

    /// The meal Group's "Use my share" logs directly: type lunch, the group's place, its
    /// scheduled time, my share as cost, and `split.note`.
    func buildGroupMeal(userId: Int64, group: LunchGroup) -> Meal? {
        guard let note = useShareNote else { return nil }
        return Meal(
            userId: userId,
            restaurantId: group.placeId,
            restaurantName: group.placeName,
            mealType: "lunch",
            cost: myShareDollars,
            dateEpochSeconds: group.scheduledAtEpochSeconds,
            notes: note
        )
    }

    // MARK: Share message

    /// Plain text for the system share sheet: header, one line per person, the pay line when set,
    /// then the footer. Empty while the split is invalid.
    var shareMessage: String {
        guard case let .split(totalCents, _, shares) = result else { return "" }
        var lines = [Copy.Split.messageHeader(
            place: placeName ?? Copy.Split.messagePlaceFallback,
            total: LunchFormat.currencyExact(cents: totalCents),
            people: people.count
        )]
        for (index, person) in people.enumerated() {
            lines.append(Copy.Split.messageLine(name: person.name, amount: LunchFormat.currencyExact(cents: shares[index])))
        }
        let trimmedPayId = payId.trimmingCharacters(in: .whitespaces)
        if !trimmedPayId.isEmpty {
            lines.append(Copy.Split.messagePay(trimmedPayId))
        }
        lines.append(Copy.Split.messageFooter)
        return lines.joined(separator: "\n")
    }
}
