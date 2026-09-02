//
//  LunchButton.swift
//  LunchApp
//
//  The standard button in four styles. `action` is reserved for the Hungry hero and the
//  paywall CTA per the palette rules; everything else uses primary, secondary, or text.
//

import SwiftUI

struct LunchButton: View {
    enum Style {
        case action, primary, secondary, text
    }

    let title: String
    var style: Style = .primary
    var icon: LunchIcon? = nil
    var isLoading = false
    var isDisabled = false
    var fillsWidth = true
    var identifier: String? = nil
    let action: () -> Void

    private static let disabledOpacity = 0.4
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        Button(action: action) {
            ZStack {
                label.opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(foreground)
                }
            }
            .padding(.horizontal, style == .text ? Tokens.Spacing.sm : Tokens.Spacing.md)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(minWidth: Tokens.Size.buttonMinWidth, minHeight: style == .text ? Tokens.Size.touchTarget : Tokens.Size.buttonHeight)
            .background(background, in: RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous)
                        .strokeBorder(Tokens.Palette.primary.opacity(Self.disabledOpacity), lineWidth: 1)
                }
            }
            .foregroundStyle(foreground)
            .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
        }
        .buttonStyle(.pressable)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? Self.disabledOpacity : 1)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "Loading" : "")
        .accessibilityIdentifier(identifier ?? "")
    }

    private var label: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            if let icon {
                IconView(icon: icon, size: Self.iconSize)
            }
            Text(title).lunchText(.button)
        }
    }

    private var background: Color {
        switch style {
        case .action: return Tokens.Palette.action
        case .primary: return Tokens.Palette.primary
        case .secondary: return Tokens.Palette.primarySoft
        case .text: return .clear
        }
    }

    private var foreground: Color {
        switch style {
        case .action: return Tokens.Palette.textOnAction
        case .primary: return Tokens.Palette.textOnPrimary
        case .secondary, .text: return Tokens.Palette.primary
        }
    }
}

#Preview("Buttons") {
    LunchPreview {
        LunchButton(title: "Start free trial", style: .action) {}
        LunchButton(title: "Get Started", style: .primary, icon: .chevronRight) {}
        LunchButton(title: "Directions", style: .secondary, icon: .directions) {}
        LunchButton(title: "Not this one", style: .text) {}
        LunchButton(title: "Saving", style: .primary, isLoading: true) {}
        LunchButton(title: "Continue", style: .primary, isDisabled: true) {}
    }
}
