//
//  BillSplitEngineTests.swift
//  LunchAppTests
//
//  @file BillSplitEngineTests.swift
//  @description SwiftBillSplitEngine against the shared bill_split_vectors.json, the same cases
//  the Kotlin BillSplitEngine is tested with.
//  @author AI Assistant
//  @date 2026-09-23
//

import Foundation
import Testing
@testable import LunchApp

struct BillSplitEngineTests {
    struct Vectors: Decodable { let cases: [Case] }

    struct Case: Decodable {
        let name: String
        let billCents: Int64
        let surchargeBps: Int
        let people: Int
        let fixed: [String: Int64]
        let totalCents: Int64?
        let surchargeCents: Int64?
        let shares: [Int64]?
        let error: String?
        let differenceCents: Int64?

        var request: BillSplitRequest {
            BillSplitRequest(
                billCents: billCents,
                people: people,
                surchargeBps: surchargeBps,
                fixedCents: Dictionary(uniqueKeysWithValues: fixed.map { (Int($0.key)!, $0.value) })
            )
        }

        var expected: BillSplitResult {
            if let error {
                return .invalid(BillSplitError(rawValue: error)!, differenceCents: differenceCents ?? 0)
            }
            return .split(totalCents: totalCents!, surchargeCents: surchargeCents!, sharesCents: shares!)
        }
    }

    static func load() throws -> Vectors {
        try JSONDecoder().decode(Vectors.self, from: TestFixtures.data(named: "bill_split_vectors"))
    }

    @Test func should_match_every_vector_when_splitting() throws {
        let vectors = try Self.load()
        #expect(vectors.cases.count >= 17)
        for c in vectors.cases {
            #expect(SwiftBillSplitEngine.split(c.request) == c.expected, "\(c.name)")
        }
    }

    @Test func should_always_add_up_to_the_total_when_the_split_is_valid() {
        for bill: Int64 in [1, 99, 1_000, 12_345, 99_999] {
            for people in 1...12 {
                for bps in [0, 150, 1000, 1500] {
                    guard case let .split(total, _, shares) = SwiftBillSplitEngine.split(
                        BillSplitRequest(billCents: bill, people: people, surchargeBps: bps)
                    ) else {
                        Issue.record("bill=\(bill) people=\(people) bps=\(bps) was invalid")
                        continue
                    }
                    #expect(shares.reduce(0, +) == total, "bill=\(bill) people=\(people) bps=\(bps)")
                    #expect(shares.max()! - shares.min()! <= 1)
                }
            }
        }
    }

    @Test func should_convert_typed_values_when_parsing_dollars_and_percent() {
        #expect(SwiftBillSplitEngine.dollarsToCents(18.5) == 1_850)
        #expect(SwiftBillSplitEngine.dollarsToCents(0.29) == 29)
        #expect(SwiftBillSplitEngine.percentToBps(1.5) == 150)
        #expect(SwiftBillSplitEngine.percentToBps(10) == 1_000)
    }
}
