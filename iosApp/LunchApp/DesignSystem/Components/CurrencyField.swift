//
//  CurrencyField.swift
//  LunchApp
//
//  Decimal-pad input for a money amount, formatted in the given currency. The bound value is
//  nil while the field is empty.
//

import SwiftUI

struct CurrencyField: View {
    @Binding var amount: Double?
    var currencyCode = "AUD"
    var placeholder = Copy.Track.costPlaceholder
    var identifier: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
            IconView(icon: .attachMoney).foregroundStyle(Tokens.Palette.textSecondary)
            TextField(placeholder, value: $amount, format: .currency(code: currencyCode).precision(.fractionLength(2)))
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.text)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .accessibilityLabel("Cost")
                .accessibilityIdentifier(identifier ?? "")
        }
        .lunchInputChrome(isFocused: isFocused)
    }
}

#Preview("Currency field") {
    @Previewable @State var empty: Double? = nil
    @Previewable @State var filled: Double? = 18.5
    LunchPreview {
        CurrencyField(amount: $empty, identifier: "meal_cost_field")
        CurrencyField(amount: $filled)
    }
}
