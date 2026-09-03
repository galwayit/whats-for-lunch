/**
 * @file PreferencesView.swift
 * @description Screen 8 of design/screens.md: budget, location, restaurant, dietary and
 *              allergen preferences with a single Save affordance in the header.
 * @author AI Assistant
 * @date 2026-09-03
 */

import SwiftUI

struct PreferencesView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: PreferencesViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = PreferencesViewModel(core: app.core, prefs: app.user?.preferences) } }
    }

    private func content(_ model: PreferencesViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            ScreenHeader(title: Copy.Preferences.title, dismissal: .close, onDismiss: { app.dismiss() }) {
                LunchButton(title: Copy.Action.save, style: .text, isLoading: model.isSaving, isDisabled: app.user == nil, fillsWidth: false, identifier: "preferences_save") {
                    Task {
                        guard let user = app.user, await model.save(user: user) else { return }
                        app.showToast(Copy.Preferences.saved)
                        app.dismiss()
                    }
                }
            }
            ScrollView {
                VStack(spacing: Tokens.Spacing.lg) {
                    section(Copy.Preferences.sectionBudget) {
                        PriceLevelChips(selected: $model.budgetLevel)
                        Text(Copy.Preferences.weekly(LunchFormat.currency(model.weeklyBudget)))
                            .lunchText(.label)
                            .foregroundStyle(Tokens.Palette.text)
                        Slider(value: $model.weeklyBudget, in: PreferencesViewModel.weeklyRange, step: PreferencesViewModel.weeklyStep)
                            .tint(Tokens.Palette.primary)
                            .accessibilityLabel(Copy.Preferences.sectionBudget)
                            .accessibilityIdentifier("preferences_weekly_slider")
                    }
                    section(Copy.Preferences.sectionLocation) {
                        DistanceSlider(label: Copy.Preferences.distance(String(Int(model.maxTravelDistance))), value: $model.maxTravelDistance)
                    }
                    section(Copy.Preferences.sectionRestaurant) {
                        Toggle(isOn: $model.includeChains) {
                            Text(Copy.Profile.prefChains).lunchText(.body).foregroundStyle(Tokens.Palette.text)
                        }
                        .tint(Tokens.Palette.primary)
                        .accessibilityIdentifier("preferences_chains_toggle")
                    }
                    section(Copy.Preferences.sectionDietary) {
                        DietaryChipGrid(selected: model.dietary, onlyDiets: true) { model.toggleDietary($0) }
                    }
                    section(Copy.Preferences.sectionAllergens) {
                        DietaryChipGrid(selected: model.allergens, onlyAllergens: true) { model.toggleAllergen($0) }
                    }
                    if let error = model.error {
                        Text(error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
                            .lunchText(.bodySmall)
                            .foregroundStyle(Tokens.Palette.danger)
                    }
                }
                .padding(Tokens.Spacing.page)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(title).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PreferencesView().environment(AppEnvironment.preview())
}
