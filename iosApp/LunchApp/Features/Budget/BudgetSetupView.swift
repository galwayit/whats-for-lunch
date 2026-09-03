//
//  BudgetSetupView.swift
//  LunchApp
//
//  Screen 6 of design/screens.md, presented as a sheet from Track.
//

import SwiftUI

struct BudgetSetupView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: BudgetSetupViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = BudgetSetupViewModel(core: app.core, prefs: app.user?.preferences) } }
    }

    private func content(_ model: BudgetSetupViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            ScreenHeader(title: Copy.Budget.title, dismissal: model.step > 1 ? .back : .close) {
                if model.step > 1 { model.back() } else { app.dismiss() }
            }
            ProgressView(value: model.progress)
                .tint(Tokens.Palette.primary)
                .padding(.horizontal, Tokens.Spacing.page)
            ScrollView {
                LunchCard {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                        Text(Copy.Budget.step(model.step))
                            .lunchText(.caption)
                            .foregroundStyle(Tokens.Palette.primary)
                        switch model.step {
                        case 1: capacityStep(model)
                        case 2: experiencesStep(model)
                        default: celebrationsStep(model)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Tokens.Spacing.page)
            }
            footer(model)
        }
    }

    private func capacityStep(_ model: BudgetSetupViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Budget.step1Title).lunchText(.title).foregroundStyle(Tokens.Palette.text)
            Text(Copy.Budget.perWeek(LunchFormat.currency(model.weeklyBudget)))
                .lunchText(.display)
                .foregroundStyle(Tokens.Palette.primary)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("budget_amount")
            Slider(value: $model.weeklyBudget, in: BudgetSetupViewModel.minimumBudget...BudgetSetupViewModel.maximumBudget, step: BudgetSetupViewModel.budgetStep)
                .tint(Tokens.Palette.primary)
                .accessibilityLabel(Copy.Budget.title)
            HStack {
                Text(LunchFormat.currency(BudgetSetupViewModel.minimumBudget))
                Spacer()
                Text(LunchFormat.currency(BudgetSetupViewModel.maximumBudget))
            }
            .lunchText(.caption)
            .foregroundStyle(Tokens.Palette.textSecondary)
        }
    }

    private func experiencesStep(_ model: BudgetSetupViewModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Budget.step2Title).lunchText(.title).foregroundStyle(Tokens.Palette.text)
            FlowLayout(spacing: Tokens.Spacing.sm) {
                ForEach(model.categories) { category in
                    Chip(title: category.name, isSelected: model.experiences.contains(category.id), identifier: "experience_\(category.id)") {
                        model.toggleExperience(category.id)
                    }
                }
            }
        }
    }

    private func celebrationsStep(_ model: BudgetSetupViewModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Budget.step3Title).lunchText(.title).foregroundStyle(Tokens.Palette.text)
            Text(Copy.Budget.step3Body).lunchText(.body).foregroundStyle(Tokens.Palette.textSecondary)
            Toggle(isOn: $model.celebrations) {
                Text(Copy.Budget.celebrations).lunchText(.label).foregroundStyle(Tokens.Palette.text)
            }
            .tint(Tokens.Palette.primary)
            .accessibilityIdentifier("celebrations_toggle")
        }
    }

    private func footer(_ model: BudgetSetupViewModel) -> some View {
        VStack(spacing: Tokens.Spacing.sm) {
            if let error = model.error {
                Text(error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
                    .lunchText(.bodySmall)
                    .foregroundStyle(Tokens.Palette.danger)
            }
            if model.step < BudgetSetupViewModel.stepCount {
                LunchButton(title: Copy.Action.continue, style: .primary, identifier: "budget_next", action: model.next)
            } else {
                LunchButton(title: Copy.Budget.finish, style: .primary, isLoading: model.isSaving, identifier: "budget_save") {
                    guard let user = app.user else { return }
                    Task { if await model.save(user: user) { app.dismiss() } }
                }
            }
        }
        .padding(.horizontal, Tokens.Spacing.page)
        .padding(.bottom, Tokens.Spacing.md)
    }
}

#Preview("Budget setup") {
    BudgetSetupView().environment(AppEnvironment.preview())
}
