//
//  LunchCard.swift
//  LunchApp
//
//  The base card: surface fill, 16pt continuous radius, hairline border, card elevation, and an
//  optional full-bleed image header.
//

import SwiftUI

struct LunchCard<Content: View>: View {
    var headerImage: Image? = nil
    var padding: CGFloat = Tokens.Spacing.md
    @ViewBuilder let content: () -> Content

    static var headerHeight: CGFloat { Tokens.Spacing.xxl * 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let headerImage {
                headerImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.headerHeight)
                    .clipped()
            }
            content()
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Tokens.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        .lunchHairline(radius: Tokens.Radius.container)
        .lunchShadow(LunchElevation.card)
    }
}

#Preview("Cards") {
    LunchPreview {
        LunchCard {
            Text("Plain card").lunchText(.heading).foregroundStyle(Tokens.Palette.text)
        }
        LunchCard(headerImage: Image(systemName: "photo")) {
            Text("Card with image header").lunchText(.heading).foregroundStyle(Tokens.Palette.text)
        }
    }
}
