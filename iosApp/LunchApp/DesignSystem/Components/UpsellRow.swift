//
//  UpsellRow.swift
//  LunchApp
//
//  Inline gate card: lock icon, title, body, and a CTA that opens the paywall.
//

import SwiftUI

struct UpsellRow: View {
    let title: String
    let message: String
    let ctaTitle: String
    var icon: LunchIcon = .lock
    let action: () -> Void

    private static let discSize = Tokens.Size.touchTarget
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            HStack(alignment: .top, spacing: Tokens.Spacing.md) {
                ZStack {
                    Circle().fill(Tokens.Palette.surface)
                    IconView(icon: icon, size: Self.iconSize).foregroundStyle(Tokens.Palette.primary)
                }
                .frame(width: Self.discSize, height: Self.discSize)
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    HStack(spacing: Tokens.Spacing.sm) {
                        Text(title).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                        ProBadge()
                    }
                    Text(message).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
            LunchButton(title: ctaTitle, style: .primary, action: action)
        }
        .padding(Tokens.Spacing.md)
        .background(Tokens.Palette.primarySoft, in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        .lunchHairline(radius: Tokens.Radius.container)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Upsell rows") {
    LunchPreview {
        UpsellRow(title: Copy.Gate.aiTitle, message: Copy.Gate.aiBody(resetTime: "midnight"), ctaTitle: Copy.Gate.aiCta, icon: .autoAwesome) {}
        UpsellRow(title: Copy.Gate.hostTitle, message: Copy.Gate.hostBody, ctaTitle: Copy.Gate.hostCta, icon: .group) {}
    }
}
