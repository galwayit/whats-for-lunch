//
//  RestaurantPhoto.swift
//  LunchApp
//
//  Loads a restaurant photo from its backend URL with a tinted placeholder for missing images
//  and previews. Shared by the restaurant, recommendation, and proposal cards.
//

import SwiftUI

struct RestaurantPhoto: View {
    let url: URL?
    var height: CGFloat = LunchCard<EmptyView>.headerHeight

    private static let placeholderIconSize = Tokens.Size.iconDefault * 2

    var body: some View {
        ZStack {
            Tokens.Palette.primarySoft
            if let url {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        IconView(icon: .restaurant, size: Self.placeholderIconSize)
            .foregroundStyle(Tokens.Palette.primary)
    }
}

#Preview("Placeholder") {
    LunchPreview {
        RestaurantPhoto(url: nil)
    }
}
