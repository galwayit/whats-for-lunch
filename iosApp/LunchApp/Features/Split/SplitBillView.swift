//
//  SplitBillView.swift
//  LunchApp
//
//  Screen 12 of design/screens.md: bill and surcharge fields, one row per person with live
//  rebalancing, the total line, an inline engine error, PayID (kept on this phone only), and
//  Share / Use my share. Presented as a sheet from Track's quick log card and from Group detail;
//  those own their own view model and "Use my share" behaviour.
//

import SwiftUI

struct SplitBillView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: SplitBillViewModel
    let onUseShare: () -> Void

    @FocusState private var surchargeFocused: Bool
    @State private var showsShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: Copy.Split.title, onDismiss: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    billSection
                    peopleSection
                    if let total = model.totalLine {
                        Text(total)
                            .lunchText(.heading)
                            .foregroundStyle(Tokens.Palette.text)
                            .accessibilityIdentifier("split_total_line")
                    }
                    if let error = model.errorMessage {
                        Text(error)
                            .lunchText(.bodySmall)
                            .foregroundStyle(Tokens.Palette.danger)
                            .accessibilityIdentifier("split_error_message")
                    }
                    payidSection
                }
                .padding(Tokens.Spacing.page)
            }
            .scrollDismissesKeyboard(.interactively)
            footer
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .sheet(isPresented: $showsShareSheet) {
            ShareSheet(items: [model.shareMessage])
        }
    }

    private var billSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(Copy.Split.billLabel).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            CurrencyField(amount: $model.bill, placeholder: Copy.Split.billPlaceholder, identifier: "split_bill_field")
            Text(Copy.Split.surchargeLabel).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            surchargeField
            Text(Copy.Split.surchargeHelp).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
        }
    }

    private var surchargeField: some View {
        HStack(spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
            IconView(icon: .payments).foregroundStyle(Tokens.Palette.textSecondary)
            TextField(Copy.Split.surchargePlaceholder, value: $model.surchargePercent, format: .number.precision(.fractionLength(0...2)))
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.text)
                .keyboardType(.decimalPad)
                .focused($surchargeFocused)
                .accessibilityIdentifier("split_surcharge_field")
            Text("%").lunchText(.body).foregroundStyle(Tokens.Palette.textSecondary)
        }
        .lunchInputChrome(isFocused: surchargeFocused)
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            HStack {
                Text(Copy.Split.peopleLabel).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
                Spacer()
                if let range = model.peopleStepperRange {
                    Stepper(value: peopleBinding, in: range) {
                        Text("\(model.peopleCount)").lunchText(.label).foregroundStyle(Tokens.Palette.text)
                    }
                    .fixedSize()
                    .accessibilityIdentifier("split_people_stepper")
                }
            }
            ForEach(model.people) { person in
                personRow(person.id)
            }
        }
    }

    private func personRow(_ index: Int) -> some View {
        let person = model.people[index]
        return VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            HStack(spacing: Tokens.Spacing.sm) {
                Text(person.name).lunchText(.label).foregroundStyle(Tokens.Palette.text)
                if person.isAdjusted {
                    BadgeLabel(text: Copy.Split.personAdjusted)
                    Button(Copy.Split.personReset) { model.reset(index) }
                        .buttonStyle(.plain)
                        .lunchText(.caption)
                        .foregroundStyle(Tokens.Palette.primary)
                        .accessibilityIdentifier("split_person_\(index)_reset")
                }
                Spacer()
            }
            CurrencyField(amount: shareBinding(index), identifier: "split_person_\(index)_amount")
        }
    }

    private func shareBinding(_ index: Int) -> Binding<Double?> {
        Binding(get: { model.shareDollars(for: index) }, set: { model.setShare($0, for: index) })
    }

    private var peopleBinding: Binding<Int> {
        Binding(get: { model.peopleCount }, set: { model.peopleCount = $0 })
    }

    private var payidSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(Copy.Split.payidLabel).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            LunchTextField(placeholder: Copy.Split.payidPlaceholder, text: $model.payId, identifier: "split_payid_field")
            Text(Copy.Split.payidNote).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
        }
    }

    private var footer: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            LunchButton(title: Copy.Split.share, style: .secondary, icon: .share, isDisabled: !model.isValid, identifier: "split_share_button") {
                showsShareSheet = true
            }
            LunchButton(title: Copy.Split.useShare, style: .primary, isDisabled: !model.isValid, identifier: "split_use_share_button", action: onUseShare)
        }
        .padding(.horizontal, Tokens.Spacing.page)
        .padding(.bottom, Tokens.Spacing.md)
    }
}

#Preview("Split bill") {
    SplitBillView(model: SplitBillViewModel(prefillBillDollars: 86.50), onUseShare: {})
}
