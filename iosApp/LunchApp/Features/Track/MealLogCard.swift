//
//  MealLogCard.swift
//  LunchApp
//
//  The quick meal log form on Track: type chips, place with suggestions, cost with the impact
//  line, date, notes, and the Log this meal button.
//

import SwiftUI

struct MealLogCard: View {
    @Environment(AppEnvironment.self) private var app
    @Bindable var model: TrackViewModel
    let onLog: () -> Void
    @FocusState private var placeFocused: Bool
    @State private var splitModel: SplitBillViewModel?

    var body: some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(Copy.Track.logTitle)
                    .lunchText(.heading)
                    .foregroundStyle(Tokens.Palette.text)
                typeChips
                placeField
                HStack(spacing: Tokens.Spacing.sm) {
                    CurrencyField(amount: $model.cost, identifier: "meal_cost_field")
                    LunchButton(title: Copy.Split.open, style: .text, fillsWidth: false, identifier: "split_bill_button") {
                        splitModel = SplitBillViewModel(prefillBillDollars: model.cost)
                    }
                }
                if let impact = model.impact {
                    Text(impact.message)
                        .lunchText(.bodySmall)
                        .foregroundStyle(impactColour(impact.impactLevel))
                        .accessibilityIdentifier("meal_impact_line")
                }
                DatePicker(Copy.Track.logDate, selection: $model.date, in: ...Date())
                    .lunchText(.label)
                    .foregroundStyle(Tokens.Palette.text)
                    .tint(Tokens.Palette.primary)
                    .accessibilityIdentifier("meal_date_picker")
                LunchTextField(placeholder: Copy.Track.notesPlaceholder, text: $model.notes, icon: .edit, identifier: "meal_notes_field")
                LunchButton(title: Copy.Action.logThisMeal, style: .primary, icon: .check, isLoading: model.isLogging, isDisabled: !model.canLog, identifier: "log_meal_button", action: onLog)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $splitModel) { splitModel in
            SplitBillView(model: splitModel) { useSplitShare(splitModel) }
        }
    }

    /// "Use my share": fills the cost field, sets the notes only if they're empty, and closes
    /// the sheet; the user still logs the meal themselves.
    private func useSplitShare(_ splitModel: SplitBillViewModel) {
        guard let note = splitModel.useShareNote else { return }
        model.applySplitShare(cost: splitModel.myShareDollars, note: note)
        self.splitModel = nil
    }

    private var typeChips: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(Copy.Track.logType)
                .lunchText(.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Tokens.Spacing.sm) {
                    ForEach(TrackViewModel.mealTypes, id: \.self) { type in
                        Chip(title: app.core.mealDefaults.displayName(mealType: type), isSelected: model.mealType == type, identifier: "meal_type_\(type)") {
                            model.mealType = type
                        }
                    }
                }
            }
        }
    }

    private var placeField: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            LunchTextField(placeholder: Copy.Track.placePlaceholder, text: $model.place, icon: .restaurant, identifier: "meal_place_field", submitLabel: .next)
                .focused($placeFocused)
                .onChange(of: model.place) { model.restaurantId = nil }
            if placeFocused {
                ForEach(model.placeSuggestions(matching: model.place), id: \.self) { suggestion in
                    Button {
                        model.place = suggestion
                        placeFocused = false
                    } label: {
                        Label {
                            Text(suggestion).lunchText(.body).foregroundStyle(Tokens.Palette.text)
                        } icon: {
                            IconView(icon: .history, size: Tokens.Size.iconDefault - Tokens.Spacing.sm).foregroundStyle(Tokens.Palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: Tokens.Size.touchTarget, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }

    private func impactColour(_ level: ImpactLevel) -> Color {
        switch level {
        case .low: Tokens.Palette.success
        case .moderate: Tokens.Palette.info
        case .high: Tokens.Palette.warning
        case .veryHigh: Tokens.Palette.danger
        }
    }
}
