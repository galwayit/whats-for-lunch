//
//  LunchTabBar.swift
//  LunchApp
//
//  Custom four-tab bar. The selected tab sits on a soft pill with the filled icon; labels are
//  the 11pt uppercase tracked `label` role.
//

import SwiftUI

enum LunchTab: CaseIterable, Hashable {
    case home, discover, track, profile

    var title: String {
        switch self {
        case .home: return Copy.Tab.home
        case .discover: return Copy.Tab.discover
        case .track: return Copy.Tab.track
        case .profile: return Copy.Tab.profile
        }
    }

    var icon: LunchIcon {
        switch self {
        case .home: return .home
        case .discover: return .explore
        case .track: return .analytics
        case .profile: return .person
        }
    }

    var identifier: String {
        switch self {
        case .home: return "tab_home"
        case .discover: return "tab_discover"
        case .track: return "tab_track"
        case .profile: return "tab_profile"
        }
    }
}

struct LunchTabBar: View {
    @Binding var selection: LunchTab

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            ForEach(LunchTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, Tokens.Spacing.md)
        .padding(.top, Tokens.Spacing.sm)
        .padding(.bottom, Tokens.Spacing.sm)
        .background(Tokens.Palette.surfaceRaised)
        .overlay(alignment: .top) { Divider().overlay(Tokens.Palette.hairline) }
        .accessibilityElement(children: .contain)
    }

    private func tabItem(_ tab: LunchTab) -> some View {
        let isSelected = tab == selection
        return Button {
            withAnimation(.easeOut(duration: Tokens.Motion.stateDurationSeconds)) {
                selection = tab
            }
        } label: {
            VStack(spacing: Tokens.Spacing.xs) {
                IconView(icon: tab.icon, size: Tokens.Size.tabIcon, filled: isSelected)
                Text(tab.title).lunchText(.label)
            }
            .foregroundStyle(isSelected ? Tokens.Palette.primary : Tokens.Palette.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Tokens.Size.buttonHeight)
            .padding(.vertical, Tokens.Spacing.xs)
            .background(
                isSelected ? Tokens.Palette.primarySoft : .clear,
                in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier(tab.identifier)
    }
}

#Preview("Tab bar") {
    @Previewable @State var selection = LunchTab.home
    LunchPreview(padding: 0) {
        LunchTabBar(selection: $selection)
    }
}
