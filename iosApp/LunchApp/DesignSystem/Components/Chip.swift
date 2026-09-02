//
//  Chip.swift
//  LunchApp
//
//  Pill chip for filters, dietary options, and meal types. Selected fills with primary; an
//  optional leading icon and trailing chevron mark filter chips that open a sheet.
//

import SwiftUI

struct Chip: View {
    let title: String
    var icon: LunchIcon? = nil
    var showsChevron = false
    var isSelected = false
    var isDisabled = false
    var identifier: String? = nil
    let action: () -> Void

    private static let disabledOpacity = 0.4
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Spacing.sm) {
                if let icon {
                    IconView(icon: icon, size: Self.iconSize)
                }
                Text(title).lunchText(.body)
                if showsChevron {
                    IconView(icon: .expandMore, size: Self.iconSize)
                }
            }
            .padding(.horizontal, Tokens.Spacing.md)
            .frame(minHeight: Tokens.Size.touchTarget)
            .foregroundStyle(isSelected ? Tokens.Palette.textOnPrimary : Tokens.Palette.text)
            .background(isSelected ? Tokens.Palette.primary : Tokens.Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? .clear : Tokens.Palette.hairlineStrong, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.pressable)
        .disabled(isDisabled)
        .opacity(isDisabled ? Self.disabledOpacity : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier ?? "")
        .animation(.easeOut(duration: Tokens.Motion.stateDurationSeconds), value: isSelected)
    }
}

#Preview("Chips") {
    LunchPreview(alignment: .leading) {
        HStack {
            Chip(title: "Dietary", icon: .filterList, isSelected: true) {}
            Chip(title: "Price", showsChevron: true) {}
            Chip(title: "Distance", showsChevron: true) {}
        }
        HStack {
            Chip(title: "Vegan", isSelected: true) {}
            Chip(title: "Halal") {}
            Chip(title: "Kosher", isDisabled: true) {}
        }
    }
}
