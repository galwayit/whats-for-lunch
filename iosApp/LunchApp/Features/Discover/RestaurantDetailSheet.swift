//
//  RestaurantDetailSheet.swift
//  LunchApp
//
//  Large-detent detail for a Discover result; reviews load lazily.
//

import SwiftUI

struct RestaurantDetailSheet: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    @State private var reviews: LoadState<[RestaurantReview]> = .idle

    private static let metricIconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm

    var body: some View {
        SheetContainer(title: restaurant.name) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                RestaurantPhoto(url: restaurant.photoURL)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
                HStack(spacing: Tokens.Spacing.md) {
                    if let rating = restaurant.rating { RatingLabel(rating: rating) }
                    if let price = restaurant.priceLabel { Text(price).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary) }
                    if let distance = restaurant.distanceFromUser {
                        Text(RestaurantCard.distanceText(distance)).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
                    }
                    BadgeLabel(
                        text: restaurant.isOpenNow ? Copy.Discover.openNow : Copy.Discover.closed,
                        tint: restaurant.isOpenNow ? Tokens.Palette.success : Tokens.Palette.textSecondary,
                        background: restaurant.isOpenNow ? Tokens.Palette.actionSoft : Tokens.Palette.surfaceRaised
                    )
                }
                if let address = restaurant.address {
                    Label {
                        Text(address).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                    } icon: {
                        IconView(icon: .locationOn, size: Self.metricIconSize).foregroundStyle(Tokens.Palette.primary)
                    }
                }
                HStack(spacing: Tokens.Spacing.sm) {
                    LunchButton(title: Copy.Action.directions, style: .secondary, icon: .directions) { MapsLauncher.openDirections(to: restaurant) }
                    LunchButton(title: Copy.Discover.detailOpenMaps, style: .secondary, icon: .map) { MapsLauncher.openPlace(restaurant) }
                }
                GoogleMapsAttribution(restaurant: restaurant)
                Text("Dietary and allergen information may be unavailable or out of date. Confirm ingredients and cross-contact risks directly with the venue before ordering. A recommendation is not an allergy-safety assessment.")
                    .lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                reviewsSection
                LunchButton(title: Copy.Action.logThisMeal, style: .primary, icon: .restaurantMenu, identifier: "detail_log_meal") {
                    dismiss()
                    app.logMeal(at: restaurant)
                }
            }
        }
        .task { await loadReviews() }
    }

    @ViewBuilder
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(Copy.Discover.detailReviews)
                .lunchText(.heading)
                .foregroundStyle(Tokens.Palette.text)
            switch reviews {
            case .idle, .loading:
                ProgressView().tint(Tokens.Palette.primary)
            case .failed(let error):
                ErrorStateView(error: error) { Task { await loadReviews() } }
            case .loaded(let list):
                if list.isEmpty {
                    Text(Copy.Discover.detailNoReviews).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                } else {
                    ForEach(list) { review in
                        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                            HStack {
                                AttributionCredit(credit: PlaceAttribution(name: review.authorName, uri: review.authorUri, photoUri: review.authorPhotoUrl))
                                Spacer()
                                RatingLabel(rating: Double(review.rating))
                            }
                            if let text = review.text {
                                Text(text).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                            }
                            if let uri = review.sourceUri, let url = URL(string: uri) { Link("View review on Google Maps", destination: url).font(.caption) }
                            Text(review.relativeTimeDescription).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
                        }
                        .padding(Tokens.Spacing.sm + Tokens.Spacing.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Tokens.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
                    }
                }
            }
        }
    }

    private func loadReviews() async {
        reviews = .loading
        do {
            let fetched = try await app.core.restaurants.reviews(placeId: restaurant.placeId)
            reviews = .loaded(restaurant.googleMapsUri == nil ? fetched : fetched.filter { $0.sourceUri != nil })
        } catch {
            reviews = .failed(CoreError.from(error))
        }
    }
}
