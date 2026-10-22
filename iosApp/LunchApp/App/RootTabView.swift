//
//  RootTabView.swift
//  LunchApp
//
//  Four tabs behind the custom tab bar. The route stack and toast host live in ContentView.
//

import SwiftUI

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
        @Bindable var app = app
        VStack(spacing: 0) {
            Group {
                switch app.selectedTab {
                case .home: HomeView()
                case .discover: DiscoverView()
                case .track: TrackView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            LunchTabBar(selection: $app.selectedTab)
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
    }
}

#Preview("Light") {
    RootTabView().environment(AppEnvironment.preview())
}

#Preview("Dark") {
    RootTabView().environment(AppEnvironment.preview())
        .preferredColorScheme(.dark)
}
