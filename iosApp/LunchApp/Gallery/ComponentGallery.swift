//
//  ComponentGallery.swift
//  LunchApp
//
//  Every design-system component in every state, so the whole system can be reviewed on a
//  device. A chip row at the top filters to one section (also selectable at launch with
//  `-gallerySection <name>`); the controls card switches appearance and steps the text size.
//  The text-scale clamp sits inside the stepped size so stepping past the token range shows
//  the clamp in effect.
//

import SwiftUI

/// The gallery sections. Raw values are the names accepted by the `-gallerySection` launch argument.
enum GallerySection: String, CaseIterable, Identifiable {
    case all, typography, buttons, hero, chips, cards, fields, budget, recommendation
    case loading, sheet, tabBar = "tabbar", pro, paywall, social, icons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .typography: return "Typography"
        case .buttons: return "Buttons"
        case .hero: return "Hero"
        case .chips: return "Chips"
        case .cards: return "Cards"
        case .fields: return "Fields"
        case .budget: return "Budget"
        case .recommendation: return "Recommendation"
        case .loading: return "Loading and empty"
        case .sheet: return "Sheet"
        case .tabBar: return "Tab bar"
        case .pro: return "Pro"
        case .paywall: return "Paywall"
        case .social: return "Social"
        case .icons: return "Icons"
        }
    }

    /// The section named by the launch argument, or `.all` when absent or unknown.
    static var launched: GallerySection {
        FeatureFlags.gallerySectionName.flatMap(GallerySection.init(rawValue:)) ?? .all
    }
}

struct ComponentGallery: View {
    private enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @State private var selectedSection = GallerySection.launched
    @State private var appearance = Appearance.system
    @State private var textSize = DynamicTypeSize.large
    @State private var selectedTab = LunchTab.home
    @State private var heroState = HeroHungryButton.State.idle
    @State private var favourites: Set<String> = [PreviewData.greenGardenBowls.id]
    @State private var selectedChips: Set<String> = ["Vegan"]
    @State private var name = ""
    @State private var place = "Green Garden Bowls"
    @State private var cost: Double? = nil
    @State private var query = ""
    @State private var showsSheet = false
    @State private var showsPaywall = false

    /// Ring fill levels shown in the budget section: empty, healthy, at the caution threshold, full.
    private static let ringLevels: [Double] = [0, 0.45, 0.8, 1]
    /// Fill level from which the ring turns to the caution tone (the budget engine owns the real threshold).
    private static let ringCautionLevel = 0.8

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sectionPicker
                if selectedSection == .paywall {
                    paywall
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.xl) {
                            controls
                            section(.typography) { typography }
                            section(.buttons) { buttons }
                            section(.hero) { hero }
                            section(.chips) { chips }
                            section(.cards) { cards }
                            section(.fields) { fields }
                            section(.budget) { budget }
                            section(.recommendation) { recommendation }
                            section(.loading) { loadingAndEmpty }
                            section(.sheet) { sheet }
                            section(.tabBar) { LunchTabBar(selection: $selectedTab) }
                            section(.pro) { pro }
                            section(.social) { social }
                            section(.icons) { icons }
                        }
                        .padding(Tokens.Spacing.page)
                    }
                }
            }
            .lunchTextScaleClamped()
            .dynamicTypeSize(textSize)
            .background(Tokens.Palette.ground)
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Tokens.Palette.surfaceRaised, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(appearance.colorScheme)
        .sheet(isPresented: $showsSheet) {
            SheetContainer(title: Copy.Discover.filterPriceTitle, actionTitle: Copy.Discover.filterApply, secondaryTitle: Copy.Discover.filterClear, onAction: { showsSheet = false }, onSecondary: { showsSheet = false }) {
                HStack {
                    ForEach(1...4, id: \.self) { level in
                        Chip(title: String(repeating: "$", count: level), isSelected: level == 2) {}
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallView(yearly: PreviewData.yearlyPackage, monthly: PreviewData.monthlyPackage, onPurchase: { _ in showsPaywall = false }, onRestore: {}, onTerms: {}, onPrivacy: {})
                .presentationDetents([.large])
        }
    }

    // MARK: Sections

    private var sectionPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Tokens.Spacing.xs) {
                    ForEach(GallerySection.allCases) { item in
                        Chip(title: item.title, isSelected: selectedSection == item, identifier: "gallery_section_\(item.rawValue)") {
                            selectedSection = item
                        }
                        .id(item)
                    }
                }
                .padding(.horizontal, Tokens.Spacing.page)
                .padding(.vertical, Tokens.Spacing.sm)
            }
            .background(Tokens.Palette.surfaceRaised)
            .onAppear { proxy.scrollTo(selectedSection, anchor: .center) }
            .onChange(of: selectedSection) { _, item in
                withAnimation { proxy.scrollTo(item, anchor: .center) }
            }
        }
    }

    private var controls: some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
                HStack {
                    Text("Text size: \(String(describing: textSize))")
                        .lunchText(.caption)
                        .foregroundStyle(Tokens.Palette.textSecondary)
                    Spacer()
                    Stepper("Text size", onIncrement: { stepTextSize(1) }, onDecrement: { stepTextSize(-1) })
                        .labelsHidden()
                }
                Text(LunchFont.isCustomFontAvailable ? "Plus Jakarta Sans loaded" : "System rounded stand-in (fonts not bundled)")
                    .lunchText(.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
            }
        }
        .accessibilityIdentifier("gallery_controls")
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            ForEach(LunchTextRole.allCases, id: \.self) { role in
                Text("\(String(describing: role)) \(Int(role.token.size))/\(Int(role.token.lineHeight))")
                    .lunchText(role)
                    .foregroundStyle(Tokens.Palette.text)
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: Tokens.Spacing.sm) {
            LunchButton(title: Copy.Paywall.ctaTrial, style: .action) {}
            LunchButton(title: "Get Started", style: .primary, icon: .chevronRight) {}
            LunchButton(title: Copy.Action.directions, style: .secondary, icon: .directions) {}
            LunchButton(title: Copy.Home.resultReject, style: .text) {}
            LunchButton(title: Copy.Action.save, style: .primary, isLoading: true) {}
            LunchButton(title: Copy.Action.continue, style: .primary, isDisabled: true) {}
        }
    }

    private var hero: some View {
        VStack(spacing: Tokens.Spacing.md) {
            HeroHungryButton(state: heroState) {
                heroState = .searching
                Task {
                    try? await Task.sleep(for: .seconds(Tokens.Motion.heroPulseDurationSeconds))
                    heroState = .idle
                }
            }
            .frame(maxWidth: .infinity)
            Text("Tap to see the searching state").lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            BadgeLabel(text: Copy.Home.picksBadge(3))
        }
        .frame(maxWidth: .infinity)
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Chip(title: "Dietary", icon: .filterList, isSelected: true) {}
                    Chip(title: "Price: $$", showsChevron: true) {}
                    Chip(title: "Distance", showsChevron: true) {}
                    Chip(title: "Rating", showsChevron: true, isDisabled: true) {}
                }
            }
            HStack {
                ForEach(["Vegetarian", "Vegan", "Halal"], id: \.self) { option in
                    Chip(title: option, isSelected: selectedChips.contains(option)) {
                        if selectedChips.contains(option) { selectedChips.remove(option) } else { selectedChips.insert(option) }
                    }
                }
            }
        }
    }

    private var cards: some View {
        VStack(spacing: Tokens.Spacing.md) {
            LunchCard {
                Text("Plain LunchCard").lunchText(.heading).foregroundStyle(Tokens.Palette.text)
            }
            ForEach(Array(PreviewData.restaurants.prefix(2).enumerated()), id: \.element.id) { index, restaurant in
                RestaurantCard(
                    restaurant: restaurant,
                    index: index,
                    isFavourite: favourites.contains(restaurant.id),
                    badge: restaurant.isOpenNow ? Copy.Discover.openNow.uppercased() : nil,
                    onFavourite: {
                        if favourites.contains(restaurant.id) { favourites.remove(restaurant.id) } else { favourites.insert(restaurant.id) }
                    },
                    onTap: {}
                )
            }
        }
    }

    private var fields: some View {
        VStack(spacing: Tokens.Spacing.md) {
            LunchTextField(placeholder: "Your first name", text: $name, identifier: "onboarding_name_field")
            LunchTextField(placeholder: Copy.Track.placePlaceholder, text: $place, icon: .locationOn, identifier: "meal_place_field")
            CurrencyField(amount: $cost, identifier: "meal_cost_field")
            SearchField(text: $query)
        }
    }

    private var budget: some View {
        let capacity = PreviewData.weeklyBudget.weeklyCapacity
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return VStack(spacing: Tokens.Spacing.lg) {
            LazyVGrid(columns: columns, spacing: Tokens.Spacing.lg) {
                ForEach(Self.ringLevels, id: \.self) { level in
                    VStack(spacing: Tokens.Spacing.xs) {
                        CapacityRing(
                            progress: level,
                            label: PreviewData.currency(capacity * level),
                            sublabel: Copy.Track.ringRemaining(PreviewData.currency(max(0, capacity - capacity * level))),
                            tone: ringTone(for: level),
                            diameter: Tokens.Size.heroRingOuter / 2
                        )
                        Text(level.formatted(.percent))
                            .lunchText(.caption)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                    }
                }
            }
            WeeklyBudgetStrip(budget: PreviewData.weeklyBudget) {}
            WeeklyBudgetStrip(budget: PreviewData.weeklyBudgetOver, tone: .over) {}
        }
    }

    private var recommendation: some View {
        RecommendationCard(restaurant: PreviewData.greenGardenBowls, confidence: 0.86, reasons: PreviewData.reasons, onDirections: {}, onLogMeal: {}, onWhy: {}, onMore: {}, onReject: {})
    }

    private var loadingAndEmpty: some View {
        VStack(spacing: Tokens.Spacing.lg) {
            AILoading()
            EmptyState(variant: .nothingHere, title: Copy.Home.emptyTitle, message: Copy.Home.emptyBody, actionTitle: Copy.Home.emptyDiscover)
            EmptyState.offline {}
            EmptyState.serviceProblem {}
        }
    }

    private var sheet: some View {
        LunchButton(title: "Open filter sheet", style: .secondary) { showsSheet = true }
    }

    private var pro: some View {
        VStack(spacing: Tokens.Spacing.md) {
            HStack { ProBadge(); Spacer() }
            UpsellRow(title: Copy.Gate.aiTitle, message: Copy.Gate.aiBody(resetTime: "midnight"), ctaTitle: Copy.Gate.aiCta, icon: .autoAwesome) { showsPaywall = true }
            UpsellRow(title: Copy.Gate.hostTitle, message: Copy.Gate.hostBody, ctaTitle: Copy.Gate.hostCta, icon: .group) { showsPaywall = true }
            SubscriptionRow(planName: Copy.Paywall.planYearly, renewal: .renews("12 October 2026"), onManage: {}, onRestore: {})
            SubscriptionRow(planName: Copy.Paywall.planMonthly, renewal: .ends("30 September 2026"), onManage: {}, onRestore: {})
            LunchButton(title: "Open paywall", style: .primary) { showsPaywall = true }
        }
    }

    /// The paywall is a full screen with its own scroll view, so it replaces the gallery scroll view.
    private var paywall: some View {
        PaywallView(yearly: PreviewData.yearlyPackage, monthly: PreviewData.monthlyPackage, onPurchase: { _ in }, onRestore: {}, onTerms: {}, onPrivacy: {})
    }

    private var social: some View {
        VStack(spacing: Tokens.Spacing.md) {
            GroupCard(group: PreviewData.group, attendingCount: 2) {}
            InvitationCard(group: PreviewData.group, attendees: PreviewData.rsvps, onAccept: {}, onDecline: {})
            InvitationCard(group: PreviewData.group, attendees: PreviewData.rsvps, isResponding: true, onAccept: {}, onDecline: {})
            LunchCard {
                VStack(spacing: 0) {
                    ForEach(PreviewData.rsvps) { GuestRow(rsvp: $0) }
                }
            }
            ProposalCard(restaurant: PreviewData.greenGardenBowls, reasons: PreviewData.reasons, index: 0) {}
            ProposalCard(restaurant: PreviewData.pastaCorner, reasons: ["Great italian cuisine", "Within your preferred distance"], index: 1, isChoosing: true) {}
            InviteShareRow(inviteUrl: PreviewData.inviteUrl) {}
        }
    }

    private var icons: some View {
        let columns = [GridItem(.adaptive(minimum: Tokens.Size.touchTarget), spacing: Tokens.Spacing.sm)]
        return LazyVGrid(columns: columns, spacing: Tokens.Spacing.md) {
            ForEach(LunchIcon.allCases, id: \.self) { icon in
                IconView(icon: icon)
                    .foregroundStyle(Tokens.Palette.primary)
                    .accessibilityLabel(icon.rawValue)
            }
        }
    }

    // MARK: Helpers

    /// Renders a titled section when it is selected, or when the whole gallery is shown.
    @ViewBuilder
    private func section<Content: View>(_ item: GallerySection, @ViewBuilder content: () -> Content) -> some View {
        if selectedSection == .all || selectedSection == item {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(item.title)
                    .lunchText(.label)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                content()
            }
        }
    }

    private func ringTone(for level: Double) -> CapacityRing.Tone {
        if level >= 1 { return .over }
        return level >= Self.ringCautionLevel ? .caution : .healthy
    }

    private func stepTextSize(_ delta: Int) {
        let all = DynamicTypeSize.allCases
        guard let index = all.firstIndex(of: textSize) else { return }
        let next = min(max(index + delta, 0), all.count - 1)
        textSize = all[next]
    }
}

#Preview("Light") {
    ComponentGallery()
}

#Preview("Dark") {
    ComponentGallery()
        .preferredColorScheme(.dark)
}
