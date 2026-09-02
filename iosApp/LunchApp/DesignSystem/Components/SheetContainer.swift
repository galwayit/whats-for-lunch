//
//  SheetContainer.swift
//  LunchApp
//
//  Content wrapper for bottom sheets: drag handle, title, scrolling content, and an action row.
//  Use as the root of a `.sheet` together with `.presentationDetents`.
//

import SwiftUI

struct SheetContainer<Content: View>: View {
    let title: String
    var actionTitle: String? = nil
    var secondaryTitle: String? = nil
    var onAction: () -> Void = {}
    var onSecondary: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Tokens.Palette.hairlineStrong)
                .frame(width: SheetLayout.handleWidth, height: SheetLayout.handleHeight)
                .padding(.top, Tokens.Spacing.sm)
                .padding(.bottom, Tokens.Spacing.md)
                .accessibilityHidden(true)
            Text(title)
                .lunchText(.title)
                .foregroundStyle(Tokens.Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Tokens.Spacing.pageWide)
                .padding(.bottom, Tokens.Spacing.md)
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                content()
                    .padding(.horizontal, Tokens.Spacing.pageWide)
                    .padding(.bottom, Tokens.Spacing.md)
            }
            if actionTitle != nil || secondaryTitle != nil {
                actionRow
            }
        }
        .background(Tokens.Palette.surface)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.Radius.sheet)
        .presentationBackground(Tokens.Palette.surface)
    }

    private var actionRow: some View {
        VStack(spacing: Tokens.Spacing.sm) {
            Divider().overlay(Tokens.Palette.hairline)
            HStack(spacing: Tokens.Spacing.sm) {
                if let secondaryTitle {
                    LunchButton(title: secondaryTitle, style: .text, action: onSecondary)
                }
                if let actionTitle {
                    LunchButton(title: actionTitle, style: .primary, action: onAction)
                }
            }
            .padding(.horizontal, Tokens.Spacing.pageWide)
            .padding(.top, Tokens.Spacing.sm)
            .padding(.bottom, Tokens.Spacing.md)
        }
    }
}

/// Static layout values; generic views cannot hold static stored properties.
private enum SheetLayout {
    static let handleWidth = Tokens.Spacing.xl + Tokens.Spacing.sm
    static let handleHeight = Tokens.Spacing.xs + 1
}

#Preview("Sheet light") {
    SheetContainer(title: Copy.Discover.filterPriceTitle, actionTitle: Copy.Discover.filterApply, secondaryTitle: Copy.Discover.filterClear) {
        HStack {
            ForEach(1...4, id: \.self) { level in
                Chip(title: String(repeating: "$", count: level), isSelected: level == 2) {}
            }
        }
    }
}

#Preview("Sheet dark") {
    SheetContainer(title: Copy.Discover.filterPriceTitle, actionTitle: Copy.Discover.filterApply, secondaryTitle: Copy.Discover.filterClear) {
        HStack {
            ForEach(1...4, id: \.self) { level in
                Chip(title: String(repeating: "$", count: level), isSelected: level == 2) {}
            }
        }
    }
    .preferredColorScheme(.dark)
}
