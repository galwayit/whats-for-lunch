//
//  DiscoverView.swift
//  LunchApp
//
//  Screen 4 of design/screens.md: sticky header with search, count, sort and filter chips, then
//  the restaurant list.
//

import SwiftUI

struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: DiscoverViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = DiscoverViewModel(core: app.core) } }
    }

    private func content(_ model: DiscoverViewModel) -> some View {
        @Bindable var model = model
        let prefs = app.user?.preferences
        return VStack(spacing: 0) {
            header(model)
            list(model)
        }
        .task { if case .idle = model.results { await model.search(prefs: prefs) } }
        .task { if let userId = app.user?.id { await model.observeFavourites(userId: userId) } }
        .onChange(of: model.query) { model.queryChanged(prefs: prefs) }
        .sheet(item: $model.sheet) { sheet in
            DiscoverFilterSheet(kind: sheet, model: model)
                .presentationDetents([.medium])
        }
        .sheet(item: $model.selected) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
                .presentationDetents([.large])
        }
    }

    private func header(_ model: DiscoverViewModel) -> some View {
        @Bindable var model = model
        let count = model.results.value?.count ?? 0
        return VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(Copy.Discover.title)
                .lunchText(.display)
                .foregroundStyle(Tokens.Palette.text)
                .accessibilityAddTraits(.isHeader)
            SearchField(text: $model.query, identifier: "discover_search_field") {
                Task { await model.search(prefs: app.user?.preferences) }
            }
            HStack {
                Text(Copy.Discover.count(count))
                    .lunchText(.bodySmall)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                    .accessibilityIdentifier("discover_count")
                Spacer()
                Chip(title: Copy.Discover.sort(model.sortLabel), icon: .tune, showsChevron: true, identifier: "sort_chip") { model.sheet = .sort }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Tokens.Spacing.sm) {
                    Chip(title: model.dietary.isEmpty ? Copy.Discover.filterDietary : Copy.Discover.chipDietary(model.dietary.count), icon: .eco, isSelected: !model.dietary.isEmpty, identifier: "filter_dietary") { model.sheet = .dietary }
                    Chip(title: model.maxPriceLevel.map { Copy.Discover.chipPrice(String(repeating: "$", count: $0)) } ?? Copy.Discover.filterPrice, icon: .payments, isSelected: model.maxPriceLevel != nil, identifier: "filter_price") { model.sheet = .price }
                    Chip(title: model.maxDistanceKm.map { Copy.Discover.chipDistance(LunchFormat.kilometres($0)) } ?? Copy.Discover.filterDistance, icon: .nearMe, isSelected: model.maxDistanceKm != nil, identifier: "filter_distance") { model.sheet = .distance }
                    Chip(title: model.minRating.map { Copy.Discover.chipRating($0.fixed1) } ?? Copy.Discover.filterRating, icon: .star, isSelected: model.minRating != nil, identifier: "filter_rating") { model.sheet = .rating }
                }
            }
        }
        .padding(.horizontal, Tokens.Spacing.page)
        .padding(.top, Tokens.Spacing.sm)
        .padding(.bottom, Tokens.Spacing.md)
        .background(Tokens.Palette.ground)
    }

    @ViewBuilder
    private func list(_ model: DiscoverViewModel) -> some View {
        let prefs = app.user?.preferences
        switch model.results {
        case .idle, .loading:
            ProgressView()
                .tint(Tokens.Palette.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorStateView(error: error) { Task { await model.search(prefs: prefs) } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let restaurants):
            if restaurants.isEmpty {
                EmptyState(variant: .nothingHere, title: Copy.Discover.emptyTitle, message: Copy.Discover.emptyBody, actionTitle: Copy.Action.searchAgain) {
                    model.clearFilters(prefs: prefs)
                    Task { await model.search(prefs: prefs) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Tokens.Spacing.md) {
                        if model.isFavouriteGated {
                            UpsellRow(title: Copy.Discover.favouriteLimitTitle, message: Copy.Discover.favouriteLimitBody, ctaTitle: Copy.Discover.favouriteLimitCta, icon: .favorite) {
                                app.present(.paywall)
                            }
                        }
                        ForEach(Array(restaurants.enumerated()), id: \.element.id) { index, restaurant in
                            RestaurantCard(
                                restaurant: restaurant,
                                index: index,
                                isFavourite: model.favourites.contains(restaurant.placeId),
                                badge: app.core.recommendation.discoverReasons(restaurant: restaurant, prefs: prefs).first,
                                onFavourite: {
                                    guard let userId = app.user?.id else { return }
                                    Task { await model.toggleFavourite(restaurant, userId: userId) }
                                },
                                onTap: { model.selected = restaurant }
                            )
                        }
                    }
                    .padding(.horizontal, Tokens.Spacing.page)
                    .padding(.bottom, Tokens.Spacing.xl)
                }
            }
        }
    }
}

#Preview("Discover") {
    DiscoverView().environment(AppEnvironment.preview())
}
