//
//  RootTabView.swift
//  LunchApp
//
//  Four placeholder tabs behind the custom tab bar. Screens replace the placeholders in the
//  next milestone.
//

import SwiftUI

struct RootTabView: View {
    @State private var selection = LunchTab.home

    var body: some View {
        VStack(spacing: 0) {
            placeholder(for: selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            LunchTabBar(selection: $selection)
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
    }

    private func placeholder(for tab: LunchTab) -> some View {
        VStack(spacing: Tokens.Spacing.md) {
            IconView(icon: tab.icon, size: Tokens.Size.iconDefault * 2, filled: true)
                .foregroundStyle(Tokens.Palette.primary)
            Text(tab.title).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
        }
    }
}

#Preview("Light") {
    RootTabView()
}

#Preview("Dark") {
    RootTabView()
        .preferredColorScheme(.dark)
}
