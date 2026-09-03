//
//  TrackView.swift
//  LunchApp
//
//  Screen 5 of design/screens.md: capacity ring, quick meal log, recent meals.
//

import SwiftUI

struct TrackView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: TrackViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = TrackViewModel(core: app.core) } }
    }

    private func content(_ model: TrackViewModel) -> some View {
        @Bindable var model = model
        return ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                Text(Copy.Track.title)
                    .lunchText(.display)
                    .foregroundStyle(Tokens.Palette.text)
                    .accessibilityAddTraits(.isHeader)
                ring(model)
                MealLogCard(model: model) {
                    guard let user = app.user else { return }
                    Task {
                        for toast in await model.log(user: user) {
                            app.showToast(toast)
                            try? await Task.sleep(for: .seconds(Tokens.Motion.achievementToastAutoDismissSeconds))
                        }
                    }
                }
                recentSection(model)
            }
            .padding(.horizontal, Tokens.Spacing.page)
            .padding(.top, Tokens.Spacing.sm)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .task(id: app.user?.preferences.weeklyBudget) {
            if let user = app.user { await model.refreshWeekly(user: user) }
        }
        .task(id: app.isPro) {
            if let userId = app.user?.id { await model.observeRecent(userId: userId) }
        }
        .onAppear { consumePrefill(model) }
        .onChange(of: app.mealPrefill) { consumePrefill(model) }
    }

    private func consumePrefill(_ model: TrackViewModel) {
        guard let prefill = app.mealPrefill else { return }
        model.applyPrefill(prefill)
        app.mealPrefill = nil
    }

    @ViewBuilder
    private func ring(_ model: TrackViewModel) -> some View {
        Button {
            app.present(.budgetSetup)
        } label: {
            if let weekly = model.weekly {
                CapacityRing(
                    progress: weekly.capacityProgress,
                    label: Copy.Track.ringLabel(spent: LunchFormat.currency(weekly.currentSpent), capacity: LunchFormat.currency(weekly.weeklyCapacity)),
                    sublabel: Copy.Track.ringRemaining(LunchFormat.currency(weekly.remainingCapacity)),
                    tone: model.ringTone
                )
                .animation(reduceMotion ? nil : .easeInOut(duration: Tokens.Motion.fadeInDurationSeconds), value: weekly.currentSpent)
            } else {
                CapacityRing(progress: 0, label: Copy.Track.ringSetup)
            }
        }
        .buttonStyle(.pressable)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("capacity_ring")
        .accessibilityHint(Copy.Track.ringSetup)
    }

    private func recentSection(_ model: TrackViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Track.recentTitle)
                .lunchText(.heading)
                .foregroundStyle(Tokens.Palette.text)
            HStack(spacing: Tokens.Spacing.sm) {
                Chip(title: Copy.Track.filterWeek, isSelected: model.historyFilter == .week, identifier: "history_week") { model.historyFilter = .week }
                Chip(title: Copy.Track.filterMonth, isSelected: model.historyFilter == .month, identifier: "history_month") { model.historyFilter = .month }
                Chip(title: Copy.Track.filterAll, isSelected: model.historyFilter == .all, identifier: "history_all") { model.historyFilter = .all }
            }
            if model.filteredRecent.isEmpty {
                EmptyState(variant: .nothingHere, title: Copy.Track.recentEmptyTitle, message: Copy.Track.recentEmptyBody)
            } else {
                ForEach(model.filteredRecent, id: \.self) { meal in
                    MealRow(meal: meal, typeName: app.core.mealDefaults.displayName(mealType: meal.mealType))
                }
            }
            if !app.isPro {
                UpsellRow(title: Copy.Track.historyGate, message: Copy.Track.historyGateBody, ctaTitle: Copy.Track.historyGateCta, icon: .history) {
                    app.present(.paywall)
                }
            }
        }
    }
}

/// One logged meal: place, type and date, cost.
private struct MealRow: View {
    let meal: Meal
    let typeName: String

    var body: some View {
        HStack(spacing: Tokens.Spacing.md) {
            IconView(icon: .restaurant, size: Tokens.Size.iconDefault)
                .foregroundStyle(Tokens.Palette.primary)
                .frame(width: Tokens.Size.touchTarget, height: Tokens.Size.touchTarget)
                .background(Tokens.Palette.primarySoft, in: Circle())
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(meal.restaurantName ?? typeName)
                    .lunchText(.label)
                    .foregroundStyle(Tokens.Palette.text)
                    .lineLimit(1)
                Text("\(typeName) · \(LunchFormat.relativeDay(meal.date))")
                    .lunchText(.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
            }
            Spacer()
            Text(LunchFormat.currencyExact(meal.cost))
                .lunchText(.label)
                .foregroundStyle(Tokens.Palette.text)
        }
        .padding(Tokens.Spacing.sm + Tokens.Spacing.xs)
        .background(Tokens.Palette.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        .lunchHairline(radius: Tokens.Radius.container)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Track") {
    TrackView().environment(AppEnvironment.preview())
}
