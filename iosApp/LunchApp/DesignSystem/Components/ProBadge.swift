//
//  ProBadge.swift
//  LunchApp
//
//  Small PRO marker for gated rows and the profile header.
//

import SwiftUI

struct ProBadge: View {
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm - Tokens.Spacing.xs

    var body: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            IconView(icon: .workspacePremium, size: Self.iconSize)
            Text(Copy.Paywall.proBadge).lunchText(.label)
        }
        .foregroundStyle(Tokens.Palette.primary)
        .padding(.horizontal, Tokens.Spacing.sm)
        .padding(.vertical, Tokens.Spacing.xs)
        .background(Tokens.Palette.primarySoft, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lunch Pro")
    }
}

#Preview("Pro badge") {
    LunchPreview {
        ProBadge()
    }
}
