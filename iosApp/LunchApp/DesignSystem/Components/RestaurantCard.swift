//
//  RestaurantCard.swift
//  LunchApp
//
//  Discover list card: photo with a favourite button, name and rating, cuisine tags, the
//  price and distance row, and an optional badge. Test ids follow design/screens.md.
//

import SwiftUI

struct RestaurantCard: View {
    let restaurant: Restaurant
    let index: Int
    var isFavourite = false
    var badge: String? = nil
    let onFavourite: () -> Void
    let onTap: () -> Void

    private static let favouriteDiscSize = Tokens.Size.touchTarget
    private static let smallIconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm
    private static let favouriteDiscOpacity = 0.85

    static func identifier(index: Int) -> String { "restaurant_card_\(index)" }

    static func favouriteIdentifier(index: Int, selected: Bool) -> String {
        selected ? "favourite_button_\(index)_selected" : "favourite_button_\(index)"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                RestaurantPhoto(url: restaurant.photoURL)
                    .overlay(alignment: .topTrailing) { favouriteButton.padding(Tokens.Spacing.md) }
                details.padding(Tokens.Spacing.md)
                GoogleMapsAttribution(restaurant: restaurant).padding(.horizontal, Tokens.Spacing.md).padding(.bottom, Tokens.Spacing.sm)
            }
            .background(Tokens.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
            .lunchHairline(radius: Tokens.Radius.container)
            .lunchShadow(LunchElevation.card)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier(Self.identifier(index: index))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(restaurant.name)
                    .lunchText(.title)
                    .foregroundStyle(Tokens.Palette.text)
                    .lineLimit(2)
                Spacer(minLength: Tokens.Spacing.sm)
                if let rating = restaurant.rating {
                    RatingLabel(rating: rating)
                }
            }
            if !restaurant.cuisineTypes.isEmpty {
                Text(restaurant.cuisineTypes.joined(separator: " • "))
                    .lunchText(.body)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                    .lineLimit(1)
            }
            HStack(spacing: Tokens.Spacing.md) {
                if let price = restaurant.priceLabel {
                    metric(icon: .payments, text: price)
                }
                if let distance = restaurant.distanceFromUser {
                    metric(icon: .nearMe, text: Self.distanceText(distance))
                }
                Spacer()
                if let badge {
                    BadgeLabel(text: badge)
                }
            }
        }
    }

    private var favouriteButton: some View {
        Button(action: onFavourite) {
            IconView(icon: .favorite, size: Self.smallIconSize, filled: isFavourite)
                .foregroundStyle(isFavourite ? Tokens.Palette.primary : Tokens.Palette.textSecondary)
                .frame(width: Self.favouriteDiscSize, height: Self.favouriteDiscSize)
                .background(Tokens.Palette.surface.opacity(Self.favouriteDiscOpacity), in: Circle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
        .accessibilityAddTraits(isFavourite ? .isSelected : [])
        .accessibilityIdentifier(Self.favouriteIdentifier(index: index, selected: isFavourite))
    }

    private func metric(icon: LunchIcon, text: String) -> some View {
        HStack(spacing: Tokens.Spacing.xs) {
            IconView(icon: icon, size: Self.smallIconSize)
            Text(text).lunchText(.bodySmall)
        }
        .foregroundStyle(Tokens.Palette.textSecondary)
    }

    private var accessibilitySummary: String {
        var parts = [restaurant.name]
        if let rating = restaurant.rating { parts.append("rated \(rating.formatted(.number.precision(.fractionLength(1)))) out of 5") }
        if let price = restaurant.priceLabel { parts.append("price \(price)") }
        if let distance = restaurant.distanceFromUser { parts.append(Self.distanceText(distance)) }
        return parts.joined(separator: ", ")
    }

    static func distanceText(_ kilometres: Double) -> String {
        "\(kilometres.formatted(.number.precision(.fractionLength(1)))) km"
    }
}

/// Star plus one-decimal rating, used wherever a restaurant rating appears.
struct RatingLabel: View {
    let rating: Double
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm

    var body: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            IconView(icon: .star, size: Self.iconSize, filled: true).foregroundStyle(Tokens.Palette.accent)
            Text(rating.formatted(.number.precision(.fractionLength(1)))).lunchText(.heading)
        }
        .foregroundStyle(Tokens.Palette.text)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(rating.formatted(.number.precision(.fractionLength(1)))) out of 5")
    }
}

/// Uppercase tinted badge, e.g. OPEN NOW.
struct BadgeLabel: View {
    let text: String
    var tint: Color = Tokens.Palette.primary
    var background: Color = Tokens.Palette.primarySoft

    var body: some View {
        Text(text)
            .lunchText(.label)
            .foregroundStyle(tint)
            .padding(.horizontal, Tokens.Spacing.sm + Tokens.Spacing.xs)
            .padding(.vertical, Tokens.Spacing.sm)
            .background(background, in: Capsule())
    }
}

#Preview("Restaurant cards") {
    LunchPreview {
        RestaurantCard(restaurant: PreviewData.greenGardenBowls, index: 0, isFavourite: true, badge: "OPEN NOW", onFavourite: {}, onTap: {})
        RestaurantCard(restaurant: PreviewData.sakuraSushi, index: 1, onFavourite: {}, onTap: {})
    }
}
