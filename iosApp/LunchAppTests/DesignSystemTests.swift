//
//  DesignSystemTests.swift
//  LunchAppTests
//
//  Guards the parts of the design system that are easy to break silently: the SF Symbol
//  stand-ins must resolve, the text-scale clamp must honour the tokens, and test identifiers
//  must match design/screens.md.
//

import Testing
import SwiftUI
import UIKit
@testable import LunchApp

struct DesignSystemTests {
    @Test func everySFSymbolStandInResolves() {
        for icon in LunchIcon.allCases {
            #expect(UIImage(systemName: icon.sfSymbolName) != nil, "Missing SF Symbol for \(icon.rawValue): \(icon.sfSymbolName)")
        }
    }

    @Test func iconSetMatchesTokenCount() {
        #expect(LunchIcon.allCases.count == 63)
    }

    @Test func textScaleClampHonoursTokens() {
        let range = LunchTextScale.allowedRange
        #expect(range.lowerBound == .xSmall)
        #expect(range.upperBound == .accessibility2)
    }

    @Test func fontFallsBackToSystemWhenNotBundled() {
        // The fonts are not bundled in this milestone; the stand-in must be in effect.
        #expect(LunchFont.isCustomFontAvailable == false)
        #expect(LunchFont.postScriptName(for: .heavy) == "PlusJakartaSans-ExtraBold")
    }

    @Test func testIdentifiersMatchScreensContract() {
        #expect(HeroHungryButton.identifier == "hero_hungry_button")
        #expect(RecommendationCard.identifier == "recommendation_card")
        #expect(PaywallView.ctaIdentifier == "paywall_cta")
        #expect(InviteShareRow.linkIdentifier == "invite_link_text")
        #expect(RestaurantCard.identifier(index: 2) == "restaurant_card_2")
        #expect(RestaurantCard.favouriteIdentifier(index: 2, selected: false) == "favourite_button_2")
        #expect(RestaurantCard.favouriteIdentifier(index: 2, selected: true) == "favourite_button_2_selected")
        #expect(ProposalCard.identifier(index: 0) == "proposal_card_0")
        #expect(ProposalCard.chooseIdentifier(index: 0) == "proposal_card_0_choose")
    }
}
