//
//  ProposalCard.swift
//  LunchApp
//
//  One of the three proposed places for a group lunch, with the engine reasons and a Choose
//  action. Test ids: proposal_card_{i} and proposal_card_{i}_choose.
//

import SwiftUI

struct ProposalCard: View {
    let restaurant: Restaurant
    let reasons: [String]
    let index: Int
    var isChoosing = false
    let onChoose: () -> Void

    private static let reasonIconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm
    private static let photoHeight = Tokens.Spacing.xxl * 3

    static func identifier(index: Int) -> String { "proposal_card_\(index)" }
    static func chooseIdentifier(index: Int) -> String { "proposal_card_\(index)_choose" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RestaurantPhoto(url: restaurant.photoURL, height: Self.photoHeight)
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text(restaurant.name).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                    Spacer(minLength: Tokens.Spacing.sm)
                    if let rating = restaurant.rating { RatingLabel(rating: rating) }
                }
                HStack(spacing: Tokens.Spacing.md) {
                    if let price = restaurant.priceLabel { Text(price) }
                    if let distance = restaurant.distanceFromUser { Text(RestaurantCard.distanceText(distance)) }
                    if !restaurant.cuisineTypes.isEmpty { Text(restaurant.cuisineTypes.joined(separator: " • ")).lineLimit(1) }
                }
                .lunchText(.bodySmall)
                .foregroundStyle(Tokens.Palette.textSecondary)
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    ForEach(reasons, id: \.self) { reason in
                        HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.sm) {
                            IconView(icon: .check, size: Self.reasonIconSize).foregroundStyle(Tokens.Palette.success)
                            Text(reason).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.text)
                        }
                    }
                }
                LunchButton(title: Copy.Group.proposalsChoose, style: .primary, isLoading: isChoosing, identifier: Self.chooseIdentifier(index: index), action: onChoose)
            }
            .padding(Tokens.Spacing.md)
        }
        .background(Tokens.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        .lunchHairline(radius: Tokens.Radius.container)
        .lunchShadow(LunchElevation.card)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(Self.identifier(index: index))
    }
}

#Preview("Proposals") {
    LunchPreview {
        ProposalCard(restaurant: PreviewData.greenGardenBowls, reasons: PreviewData.reasons, index: 0) {}
        ProposalCard(restaurant: PreviewData.pastaCorner, reasons: ["Great italian cuisine", "Within your preferred distance"], index: 1, isChoosing: true) {}
    }
}
