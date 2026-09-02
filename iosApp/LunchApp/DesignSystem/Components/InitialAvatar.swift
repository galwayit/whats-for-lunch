//
//  InitialAvatar.swift
//  LunchApp
//
//  Circular disc showing the first letter of a name; used for the profile header, guests, and
//  invitation attendees.
//

import SwiftUI

struct InitialAvatar: View {
    let name: String
    var size: CGFloat = Tokens.Size.touchTarget
    var tint: Color = Tokens.Palette.primary

    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).prefix(1).uppercased()
    }

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(Tokens.Palette.primarySoftOpacity))
            Circle().strokeBorder(tint.opacity(Tokens.Palette.primarySoftOpacity * 2), lineWidth: 1)
            Text(initial).lunchText(.heading).foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Avatars") {
    LunchPreview {
        HStack(spacing: Tokens.Spacing.md) {
            InitialAvatar(name: "Ray")
            InitialAvatar(name: "Mei", tint: Tokens.Palette.action)
            InitialAvatar(name: "  ")
        }
    }
}
