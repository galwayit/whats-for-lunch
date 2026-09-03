//
//  HomeView.swift
//  LunchApp
//
//  Screen 2 of design/screens.md: header, greeting, hero button and its result, picks badge,
//  and the "Lunch together" row.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: HomeViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = HomeViewModel(core: app.core) } }
    }

    private func content(_ model: HomeViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                header
                greeting
                if app.isPro {
                    LunchTextField(placeholder: Copy.Home.cravingPlaceholder, text: $model.craving, icon: .autoAwesome, identifier: "craving_field_home", submitLabel: .search) {
                        app.aiCravingDraft = model.craving
                        model.craving = ""
                        app.present(.aiRecommendations(pickPlaceId: nil))
                    }
                }
                heroSection(model)
                groupsSection(model)
            }
            .padding(.horizontal, Tokens.Spacing.page)
            .padding(.top, Tokens.Spacing.sm)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .task { await model.observeGroups() }
        .task {
            if app.shouldRunFirstSearch {
                app.shouldRunFirstSearch = false
                await model.search(prefs: app.user?.preferences)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            InitialAvatar(name: app.user?.name ?? "")
            Text(Copy.Home.eyebrow)
                .lunchText(.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
            Spacer()
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(Copy.Home.greeting(app.user?.name ?? ""))
                .lunchText(.display)
                .foregroundStyle(Tokens.Palette.text)
            Text(Copy.Home.subtitle)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
        }
    }

    @ViewBuilder
    private func heroSection(_ model: HomeViewModel) -> some View {
        let prefs = app.user?.preferences
        VStack(spacing: Tokens.Spacing.md) {
            if model.picksCount > 0 {
                BadgeLabel(text: Copy.Home.picksBadge(model.picksCount))
                    .accessibilityIdentifier("picks_badge")
            }
            switch model.hero {
            case .idle:
                HeroHungryButton(state: .idle) { Task { await model.search(prefs: prefs) } }
            case .searching:
                HeroHungryButton(state: .searching) {}
                VStack(spacing: Tokens.Spacing.xs) {
                    Text(Copy.Home.searchingTitle).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                    Text(Copy.Home.searchingBody).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                }
                .multilineTextAlignment(.center)
            case .result(let restaurant, let reasons, let confidence):
                Text(Copy.Home.resultEyebrow)
                    .lunchText(.caption)
                    .foregroundStyle(Tokens.Palette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                RecommendationCard(
                    restaurant: restaurant,
                    confidence: confidence,
                    reasons: reasons,
                    onDirections: { MapsLauncher.openDirections(to: restaurant) },
                    onLogMeal: { app.logMeal(at: restaurant) },
                    onWhy: { app.present(.aiRecommendations(pickPlaceId: restaurant.placeId)) },
                    onMore: { app.present(.aiRecommendations(pickPlaceId: nil)) },
                    onReject: { Task { await model.reject(restaurant, prefs: prefs) } }
                )
            case .empty:
                EmptyState(variant: .nothingHere, title: Copy.Home.emptyTitle, message: Copy.Home.emptyBody, actionTitle: Copy.Home.emptyDiscover) {
                    model.reset()
                    app.selectedTab = .discover
                }
            case .failed(let error):
                ErrorStateView(error: error) { Task { await model.search(prefs: prefs) } }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Tokens.Spacing.md)
    }

    private func groupsSection(_ model: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Home.groupRowTitle)
                .lunchText(.heading)
                .foregroundStyle(Tokens.Palette.text)
            if model.groups.isEmpty {
                Text(Copy.Home.groupRowEmpty)
                    .lunchText(.bodySmall)
                    .foregroundStyle(Tokens.Palette.textSecondary)
            } else {
                ForEach(model.groups) { group in
                    GroupCard(group: group, attendingCount: model.attendingCounts[group.id] ?? 0) {
                        app.present(.groupDetail(groupId: group.id))
                    }
                }
            }
            LunchButton(title: Copy.Home.groupRowPlan, style: .secondary, icon: .groupAdd, identifier: "plan_group_button") {
                let decision = app.core.gates.canHostGroup()
                if decision.allowed {
                    app.present(.groupCreate)
                } else {
                    app.present(gate: decision.reason)
                }
            }
        }
    }
}

#Preview("Home") {
    HomeView().environment(AppEnvironment.preview())
}
