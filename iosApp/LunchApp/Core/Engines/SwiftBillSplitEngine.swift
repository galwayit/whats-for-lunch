//
//  SwiftBillSplitEngine.swift
//  LunchApp
//
//  Pure Swift port of BillSplitEngine.kt. Whole cents, surcharge in basis points rounded half up
//  with integer maths, leftover cents to the earliest people who were not adjusted. Pinned to
//  shared/src/commonTest/resources/fixtures/bill_split_vectors.json like the Kotlin original.
//

import Foundation

/// What the user entered. `fixedCents` maps a person index to the final amount (after surcharge)
/// they chose to pay.
nonisolated struct BillSplitRequest: Equatable, Sendable {
    var billCents: Int64
    var people: Int
    var surchargeBps: Int = 0
    var fixedCents: [Int: Int64] = [:]
}

nonisolated enum BillSplitError: String, Equatable, Sendable {
    case noBill = "NO_BILL"
    case noPeople = "NO_PEOPLE"
    case tooManyPeople = "TOO_MANY_PEOPLE"
    case surchargeOutOfRange = "SURCHARGE_OUT_OF_RANGE"
    /// The adjusted amounts add up to more than the bill; the difference is the excess.
    case overAllocated = "OVER_ALLOCATED"
    /// Everyone was adjusted and together they fall short; the difference is left unpaid.
    case underAllocated = "UNDER_ALLOCATED"
}

nonisolated enum BillSplitResult: Equatable, Sendable {
    /// `sharesCents` has one entry per person, in order, and always sums to `totalCents`.
    case split(totalCents: Int64, surchargeCents: Int64, sharesCents: [Int64])
    case invalid(BillSplitError, differenceCents: Int64)
}

nonisolated enum SwiftBillSplitEngine {
    static let maxPeople = 50
    /// 50%: well above any real surcharge, low enough to catch a mistyped amount.
    static let maxSurchargeBps = 5000

    /// Splits `request`. A fixed index outside the people list or a negative fixed amount is a
    /// caller bug and traps, matching the Kotlin `require`.
    static func split(_ request: BillSplitRequest) -> BillSplitResult {
        let fixed = request.fixedCents
        guard request.billCents > 0 else { return .invalid(.noBill, differenceCents: 0) }
        guard request.people >= 1 else { return .invalid(.noPeople, differenceCents: 0) }
        guard request.people <= maxPeople else { return .invalid(.tooManyPeople, differenceCents: 0) }
        guard (0...maxSurchargeBps).contains(request.surchargeBps) else {
            return .invalid(.surchargeOutOfRange, differenceCents: 0)
        }
        precondition(fixed.keys.allSatisfy { (0..<request.people).contains($0) }, "fixed index outside the people list")
        precondition(fixed.values.allSatisfy { $0 >= 0 }, "fixed amounts must not be negative")

        // Integer half-up rounding: + 5000 before dividing by 10000 basis points.
        let surchargeCents = (request.billCents * Int64(request.surchargeBps) + 5_000) / 10_000
        let totalCents = request.billCents + surchargeCents
        let remainingCents = totalCents - fixed.values.reduce(0, +)
        let open = (0..<request.people).filter { fixed[$0] == nil }

        if remainingCents < 0 { return .invalid(.overAllocated, differenceCents: -remainingCents) }
        if open.isEmpty && remainingCents > 0 { return .invalid(.underAllocated, differenceCents: remainingCents) }

        var shares = (0..<request.people).map { fixed[$0] ?? 0 }
        if !open.isEmpty {
            let base = remainingCents / Int64(open.count)
            let leftover = Int(remainingCents % Int64(open.count))
            for (position, person) in open.enumerated() {
                shares[person] = base + (position < leftover ? 1 : 0)
            }
        }
        return .split(totalCents: totalCents, surchargeCents: surchargeCents, sharesCents: shares)
    }

    /// Dollars as typed (e.g. 18.5) to cents, rounding half up.
    static func dollarsToCents(_ dollars: Double) -> Int64 { Int64((dollars * 100).rounded()) }

    /// A percent as typed (e.g. 1.5) to basis points.
    static func percentToBps(_ percent: Double) -> Int { Int((percent * 100).rounded()) }
}
