//
//  LunchTextField.swift
//  LunchApp
//
//  Single-line text input: surface fill, input radius, hairline at rest and a 2pt primary
//  border when focused. Optional leading icon and a test identifier.
//

import SwiftUI

struct LunchTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: LunchIcon? = nil
    var identifier: String? = nil
    var keyboard: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool

    static let focusBorderWidth: CGFloat = Tokens.Spacing.xs / 2

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
            if let icon {
                IconView(icon: icon).foregroundStyle(Tokens.Palette.textSecondary)
            }
            TextField(placeholder, text: $text)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.text)
                .keyboardType(keyboard)
                .submitLabel(submitLabel)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .accessibilityIdentifier(identifier ?? "")
        }
        .lunchInputChrome(isFocused: isFocused)
    }
}

extension View {
    /// The shared input container used by every field type.
    func lunchInputChrome(isFocused: Bool) -> some View {
        padding(.horizontal, Tokens.Spacing.md)
            .frame(minHeight: Tokens.Size.buttonHeight)
            .background(Tokens.Palette.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.input, style: .continuous))
            .lunchHairline(
                radius: Tokens.Radius.input,
                color: isFocused ? Tokens.Palette.primary : Tokens.Palette.hairlineStrong,
                width: isFocused ? LunchTextField.focusBorderWidth : 1
            )
            .animation(.easeOut(duration: Tokens.Motion.stateDurationSeconds), value: isFocused)
    }
}

#Preview("Text fields") {
    @Previewable @State var name = ""
    @Previewable @State var place = "Green Garden Bowls"
    LunchPreview {
        LunchTextField(placeholder: "Your first name", text: $name, identifier: "onboarding_name_field")
        LunchTextField(placeholder: Copy.Track.placePlaceholder, text: $place, icon: .locationOn)
    }
}
