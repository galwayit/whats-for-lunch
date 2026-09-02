//
//  SearchField.swift
//  LunchApp
//
//  Search input with a leading search icon, a clear button while text is present, and the
//  search keyboard action. Debouncing belongs to the screen, not the field.
//

import SwiftUI

struct SearchField: View {
    @Binding var text: String
    var placeholder = Copy.Discover.searchPlaceholder
    var identifier: String? = nil
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool
    private static let clearIconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
            IconView(icon: .search).foregroundStyle(Tokens.Palette.textSecondary)
            TextField(placeholder, text: $text)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.text)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onSubmit(onSubmit)
                .accessibilityLabel("Search")
                .accessibilityIdentifier(identifier ?? "")
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    IconView(icon: .close, size: Self.clearIconSize)
                        .foregroundStyle(Tokens.Palette.textSecondary)
                        .frame(width: Tokens.Size.touchTarget, height: Tokens.Size.touchTarget)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Clear search")
            }
        }
        .lunchInputChrome(isFocused: isFocused)
    }
}

#Preview("Search field") {
    @Previewable @State var empty = ""
    @Previewable @State var query = "sushi"
    LunchPreview {
        SearchField(text: $empty)
        SearchField(text: $query)
    }
}
