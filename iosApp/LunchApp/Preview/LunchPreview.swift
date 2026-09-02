//
//  LunchPreview.swift
//  LunchApp
//
//  Preview container that renders its content twice, once in light and once in dark, each on
//  the ground colour, so every component preview shows both appearances in one canvas.
//  The dark panel forces `colorScheme` through the environment, which is what the dynamic
//  `Tokens.Palette` colours resolve against.
//

import SwiftUI

struct LunchPreview<Content: View>: View {
    var padding: CGFloat = Tokens.Spacing.page
    var alignment: HorizontalAlignment = .center
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                panel(.light)
                panel(.dark)
            }
        }
    }

    private func panel(_ scheme: ColorScheme) -> some View {
        VStack(alignment: alignment, spacing: Tokens.Spacing.sm) {
            Text(scheme == .dark ? "Dark" : "Light")
                .lunchText(.label)
                .foregroundStyle(Tokens.Palette.textSecondary)
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .background(Tokens.Palette.ground)
        .environment(\.colorScheme, scheme)
    }
}

#Preview("Preview container") {
    LunchPreview {
        LunchButton(title: Copy.Action.continue) {}
    }
}
