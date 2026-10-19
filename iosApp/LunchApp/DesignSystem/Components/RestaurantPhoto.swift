//
//  RestaurantPhoto.swift
//  LunchApp
//
//  Loads a restaurant photo from its backend URL with a tinted placeholder for missing images
//  and previews. Shared by the restaurant, recommendation, and proposal cards.
//

import SwiftUI

struct RestaurantPhoto: View {
    @Environment(\.scenePhase) private var scenePhase
    let url: URL?
    var height: CGFloat = LunchCard<EmptyView>.headerHeight
    @State private var loadedImage: UIImage?
    @State private var loadedURL: URL?

    private static let placeholderIconSize = Tokens.Size.iconDefault * 2

    var body: some View {
        ZStack {
            Tokens.Palette.surfaceRaised
            if let url, let image = loadedURL == url ? loadedImage : RestaurantPhotoStore.shared.cachedImage(for: url) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
        .task(id: scenePhase == .active ? url : nil) {
            guard scenePhase == .active else { return }
            loadedImage = nil
            loadedURL = nil
            guard let url else { return }
            let image = await RestaurantPhotoStore.shared.image(for: url)
            guard !Task.isCancelled else { return }
            loadedImage = image
            loadedURL = url
        }
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
