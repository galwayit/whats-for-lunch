//
//  RecommendationCard.swift
//  LunchApp
//
//  The Home result card: photo, TODAY'S PICK eyebrow, name and rating, confidence chip, the
//  three engine reasons, Directions and Log this meal, then Why this? / Show me more /
//  Not this one.
//

import SwiftUI

struct RecommendationCard: View {
    let restaurant: Restaurant
    /// 0...1 from `AiRecommendation.overallConfidence`.
    let confidence: Double
    let reasons: [String]
    let onDirections: () -> Void
    let onLogMeal: () -> Void
    let onWhy: () -> Void
    let onMore: () -> Void
    let onReject: () -> Void

    static let identifier = "recommendation_card"
    private static let reasonIconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm
    private static let highThreshold = 0.8
    private static let mediumThreshold = 0.6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RestaurantPhoto(url: restaurant.photoURL)
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                header
                reasonList
                actions
                footerLinks
            }
            .padding(Tokens.Spacing.md)
        }
        .background(Tokens.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        .lunchHairline(radius: Tokens.Radius.container)
        .lunchShadow(LunchElevation.card)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(Self.identifier)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(Copy.Home.resultEyebrow)
                .lunchText(.label)
                .foregroundStyle(Tokens.Palette.primary)
            HStack(alignment: .firstTextBaseline) {
                Text(restaurant.name)
                    .lunchText(.title)
                    .foregroundStyle(Tokens.Palette.text)
                Spacer(minLength: Tokens.Spacing.sm)
                if let rating = restaurant.rating {
                    RatingLabel(rating: rating)
                }
            }
            HStack(spacing: Tokens.Spacing.sm) {
                BadgeLabel(text: "\(confidenceLabel) confidence")
                if let price = restaurant.priceLabel {
                    Text(price).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                }
                if let distance = restaurant.distanceFromUser {
                    Text(RestaurantCard.distanceText(distance)).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
        }
    }

    private var reasonList: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            ForEach(reasons.prefix(3), id: \.self) { reason in
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.sm) {
                    IconView(icon: .check, size: Self.reasonIconSize).foregroundStyle(Tokens.Palette.success)
                    Text(reason).lunchText(.body).foregroundStyle(Tokens.Palette.text)
                }
            }
        }
    }

    /// Side by side at default text sizes, stacked when the labels no longer fit.
    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Tokens.Spacing.sm) { actionButtons }
            VStack(spacing: Tokens.Spacing.sm) { actionButtons }
        }
    }

    @ViewBuilder private var actionButtons: some View {
        LunchButton(title: Copy.Action.directions, style: .secondary, action: onDirections)
        LunchButton(title: Copy.Action.logThisMeal, style: .primary, action: onLogMeal)
    }

    private var footerLinks: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Tokens.Spacing.sm) { footerButtons }
            VStack(alignment: .leading, spacing: 0) { footerButtons }
        }
    }

    @ViewBuilder private var footerButtons: some View {
        LunchButton(title: Copy.Home.resultWhy, style: .text, fillsWidth: false, action: onWhy)
        Spacer(minLength: 0)
        LunchButton(title: Copy.Home.resultMore, style: .text, fillsWidth: false, action: onMore)
        Spacer(minLength: 0)
        LunchButton(title: Copy.Home.resultReject, style: .text, fillsWidth: false, action: onReject)
    }

    /// Mirrors `AiRecommendation.confidenceLevel` in the shared core.
    private var confidenceLabel: String {
        if confidence >= Self.highThreshold { return "High" }
        if confidence >= Self.mediumThreshold { return "Medium" }
        return "Low"
    }
}

#Preview("Recommendation") {
    LunchPreview {
        RecommendationCard(
            restaurant: PreviewData.greenGardenBowls,
            confidence: 0.86,
            reasons: PreviewData.reasons,
            onDirections: {}, onLogMeal: {}, onWhy: {}, onMore: {}, onReject: {}
        )
    }
}
