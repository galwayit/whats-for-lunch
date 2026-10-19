//
//  AIRecommendationsView.swift
//  LunchApp
//
//  Screen 3 of design/screens.md. Presented as a sheet from Home.
//

import SwiftUI

struct AIRecommendationsView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.openURL) private var openURL
    let pickPlaceId: String?
    @State private var model: AIRecommendationsViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            guard model == nil else { return }
            let created = AIRecommendationsViewModel(core: app.core, pickPlaceId: pickPlaceId)
            if let draft = app.aiCravingDraft {
                created.craving = draft
                app.aiCravingDraft = nil
            }
            model = created
        }
    }

    private func content(_ model: AIRecommendationsViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            ScreenHeader(title: Copy.AI.title, dismissal: .back) { app.dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    SearchAreaButton()
                    DietaryNotice()
                    HStack(spacing: Tokens.Spacing.sm) {
                        LunchTextField(placeholder: Copy.AI.cravingPlaceholder, text: $model.craving, icon: .autoAwesome, identifier: "craving_field", submitLabel: .search) {
                            Task { await model.ask() }
                        }
                        LunchButton(title: Copy.AI.ask, style: .primary, isLoading: model.state.isLoading, fillsWidth: false, identifier: "ai_ask_button") {
                            Task { await model.ask() }
                        }
                    }
                    if model.needsSignIn {
                        LunchButton(title: Copy.Profile.signInApple, style: .primary) { app.present(.signIn) }
                        Text("Sign in for one free AI request a day, or use your Lunch Pro subscription.").lunchText(.bodySmall)
                    }
                    if model.needsConsent {
                        AIConsentCard(providers: model.aiConfiguration?.providers ?? []) {
                            Task { await model.grantConsent() }
                        } onDecline: {
                            model.declineConsent()
                        } onPrivacy: {
                            openURL(LunchConfig.privacyUrl)
                        }
                    }
                    if model.isGated {
                        if !model.requiresSubscription {
                            Text("You’ve used your 10 Pro AI requests today, including group suggestions. Your allowance resets at \(model.resetTime).")
                                .lunchText(.bodySmall)
                        } else {
                            UpsellRow(title: Copy.Gate.aiTitle, message: Copy.Gate.aiBody(resetTime: model.resetTime), ctaTitle: Copy.Gate.aiCta) {
                                app.present(.paywall)
                            }
                        }
                    }
                    results(model)
                    if !model.history.isEmpty {
                        historySection(model)
                    }
                }
                .padding(.horizontal, Tokens.Spacing.page)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .task(id: "\(app.isPro)-\(app.session?.userId ?? "guest")") {
            let draft = model.craving
            await model.load(userId: app.user?.id, isPro: app.isPro)
            if !draft.isEmpty, case .idle = model.state, !model.isGated { await model.ask() }
        }
        .onChange(of: model.requiresSubscription, initial: true) { _, needed in
            if needed { app.present(.paywall) }
        }
    }

    @ViewBuilder
    private func results(_ model: AIRecommendationsViewModel) -> some View {
        switch model.state {
        case .idle:
            if !model.isGated && !model.needsConsent {
                EmptyState(variant: .nothingHere, title: Copy.AI.emptyTitle, message: Copy.AI.emptyBody)
            }
        case .loading:
            AILoading(title: Copy.AI.thinkingTitle, subtitle: Copy.AI.thinkingBody)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.Spacing.xl)
        case .failed(let error):
            AIErrorStateView(error: error) { Task { await model.ask() } }
        case .loaded(let recommendation):
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                LunchCard {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        BadgeLabel(text: Copy.AI.confidence(recommendation.confidenceLevel))
                        Text(recommendation.reasoning)
                            .lunchText(.body)
                            .foregroundStyle(Tokens.Palette.text)
                        if let summary = recommendation.investmentSummary {
                            Label {
                                Text(summary).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                            } icon: {
                                IconView(icon: .payments, size: Tokens.Size.iconDefault - Tokens.Spacing.sm).foregroundStyle(Tokens.Palette.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(Array(recommendation.restaurants.enumerated()), id: \.element.id) { index, restaurant in
                    AIResultCard(index: index, restaurant: restaurant, reasons: model.reasons(for: restaurant, prefs: app.user?.preferences)) {
                        MapsLauncher.openDirections(to: restaurant)
                    } onLogMeal: {
                        app.logMeal(at: restaurant)
                    }
                }
            }
        }
    }

    private func historySection(_ model: AIRecommendationsViewModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(Copy.AI.historyTitle)
                .lunchText(.heading)
                .foregroundStyle(Tokens.Palette.text)
            ForEach(model.history) { item in
                LunchCard(padding: Tokens.Spacing.sm + Tokens.Spacing.xs) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text(item.restaurants.map(\.name).joined(separator: " · "))
                            .lunchText(.label)
                            .foregroundStyle(Tokens.Palette.text)
                            .lineLimit(1)
                        Text(item.reasoning)
                            .lunchText(.bodySmall)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                            .lineLimit(2)
                        Text(LunchFormat.relativeDay(Date(timeIntervalSince1970: TimeInterval(item.generatedAtEpochSeconds))))
                            .lunchText(.caption)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

/// Asks before anything is sent to the configured AI providers (App Review 5.1.2(i)): what is sent, to whom,
/// a link to the privacy policy, and the two answers.
struct AIConsentCard: View {
    let providers: [AiProviderDisclosure]
    let onAgree: () -> Void
    let onDecline: () -> Void
    let onPrivacy: () -> Void

    var body: some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                Label {
                    Text(Copy.AIConsent.title).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                } icon: {
                    IconView(icon: .autoAwesome, size: Tokens.Size.iconDefault).foregroundStyle(Tokens.Palette.primary)
                }
                Text(Copy.AIConsent.body(providers: providers.map(\.name).joined(separator: ", ")))
                    .lunchText(.body)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(providers, id: \.privacyUrl) { provider in
                    if let url = URL(string: provider.privacyUrl) {
                        Link("\(provider.name) privacy policy", destination: url).lunchText(.bodySmall)
                    }
                }
                LunchButton(title: Copy.AIConsent.privacy, style: .text, fillsWidth: false, identifier: "ai_consent_privacy", action: onPrivacy)
                LunchButton(title: Copy.AIConsent.agree, style: .primary, identifier: "ai_consent_agree", action: onAgree)
                LunchButton(title: Copy.AIConsent.decline, style: .secondary, identifier: "ai_consent_decline", action: onDecline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ai_consent_card")
    }
}

/// One AI result: name, rating and distance, the engine's reasons, and the two actions.
private struct AIResultCard: View {
    let index: Int
    let restaurant: Restaurant
    let reasons: [String]
    let onDirections: () -> Void
    let onLogMeal: () -> Void
    private static let reasonIconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm

    var body: some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text(restaurant.name).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                        HStack(spacing: Tokens.Spacing.sm) {
                            if let rating = restaurant.rating { RatingLabel(rating: rating) }
                            if let price = restaurant.priceLabel { Text(price).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary) }
                            if let distance = restaurant.distanceFromUser {
                                Text(RestaurantCard.distanceText(distance)).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
                            }
                        }
                    }
                    Spacer()
                    BadgeLabel(text: "#\(index + 1)")
                }
                GoogleMapsAttribution(restaurant: restaurant, includesPhoto: false)
                ForEach(reasons, id: \.self) { reason in
                    Label {
                        Text(reason).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                    } icon: {
                        IconView(icon: .check, size: Self.reasonIconSize).foregroundStyle(Tokens.Palette.success)
                    }
                }
                HStack(spacing: Tokens.Spacing.sm) {
                    LunchButton(title: Copy.Action.directions, style: .secondary, icon: .directions, action: onDirections)
                    LunchButton(title: Copy.Action.logThisMeal, style: .primary, icon: .restaurantMenu, action: onLogMeal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ai_result_\(index)")
    }
}

#Preview("AI") {
    AIRecommendationsView(pickPlaceId: nil).environment(AppEnvironment.preview())
}
