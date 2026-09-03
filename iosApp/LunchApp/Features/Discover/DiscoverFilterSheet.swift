//
//  DiscoverFilterSheet.swift
//  LunchApp
//
//  The sort sheet and the four filter sheets. Edits are staged locally and applied on Apply.
//

import SwiftUI

struct DiscoverFilterSheet: View {
    @Environment(AppEnvironment.self) private var app
    let kind: DiscoverViewModel.Sheet
    let model: DiscoverViewModel

    @State private var sort: SortOption = .relevance
    @State private var dietary: Set<String> = []
    @State private var priceLevel = 4
    @State private var distance = UserPreferences().maxTravelDistance
    @State private var rating = DiscoverViewModel.ratingRange.lowerBound

    private static let stepperIconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        SheetContainer(title: title, actionTitle: Copy.Discover.filterApply, secondaryTitle: kind == .sort ? nil : Copy.Discover.filterClear, onAction: apply, onSecondary: clear) {
            switch kind {
            case .sort: sortOptions
            case .dietary: DietaryChipGrid(selected: dietary) { key in
                if dietary.contains(key) { dietary.remove(key) } else { dietary.insert(key) }
            }
            case .price: PriceLevelChips(selected: $priceLevel, identifierPrefix: "filter_price")
            case .distance: DistanceSlider(label: Copy.Discover.chipDistance(LunchFormat.kilometres(distance)), value: $distance)
            case .rating: ratingStepper
            }
        }
        .onAppear(perform: stage)
    }

    private var title: String {
        switch kind {
        case .sort: Copy.Discover.sortTitle
        case .dietary: Copy.Discover.filterDietaryTitle
        case .price: Copy.Discover.filterPriceTitle
        case .distance: Copy.Discover.filterDistanceTitle
        case .rating: Copy.Discover.filterRatingTitle
        }
    }

    private var sortOptions: some View {
        VStack(spacing: Tokens.Spacing.sm) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    sort = option
                } label: {
                    HStack {
                        Text(label(option)).lunchText(.body).foregroundStyle(Tokens.Palette.text)
                        Spacer()
                        if sort == option {
                            IconView(icon: .check, size: Tokens.Size.iconDefault).foregroundStyle(Tokens.Palette.primary)
                        }
                    }
                    .frame(minHeight: Tokens.Size.touchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(sort == option ? .isSelected : [])
                .accessibilityIdentifier("sort_\(option.rawValue)")
            }
        }
    }

    private var ratingStepper: some View {
        HStack(spacing: Tokens.Spacing.md) {
            RatingLabel(rating: rating)
            Spacer()
            Stepper(value: $rating, in: DiscoverViewModel.ratingRange, step: DiscoverViewModel.ratingStep) {
                Text(Copy.Discover.chipRating(rating.fixed1)).lunchText(.label).foregroundStyle(Tokens.Palette.text)
            }
            .fixedSize()
        }
    }

    private func label(_ option: SortOption) -> String {
        switch option {
        case .relevance: Copy.Discover.sortRelevance
        case .price: Copy.Discover.sortPrice
        case .distance: Copy.Discover.sortDistance
        case .rating: Copy.Discover.sortRating
        }
    }

    private func stage() {
        sort = model.sortOption
        dietary = model.dietary
        priceLevel = model.maxPriceLevel ?? OnboardingViewModel.priceLevels.upperBound
        distance = model.maxDistanceKm ?? app.user?.preferences.maxTravelDistance ?? UserPreferences().maxTravelDistance
        rating = model.minRating ?? DiscoverViewModel.ratingRange.lowerBound
    }

    private func apply() {
        let prefs = app.user?.preferences
        switch kind {
        case .sort:
            model.sortOption = sort
            model.applyFilters(prefs: prefs)
        case .dietary:
            model.dietary = dietary
            model.applyFilters(prefs: prefs)
        case .price:
            model.maxPriceLevel = priceLevel
            model.applyFilters(prefs: prefs)
        case .distance:
            model.maxDistanceKm = distance
            Task { await model.search(prefs: prefs) }
        case .rating:
            model.minRating = rating
            model.applyFilters(prefs: prefs)
        }
        model.sheet = nil
    }

    private func clear() {
        model.clearFilters(prefs: app.user?.preferences)
        model.sheet = nil
    }
}
