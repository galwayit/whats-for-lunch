//
//  ContentView.swift
//  LunchApp
//
//  Root switch: gallery (`-gallery`), not-linked screen, onboarding, or the tab shell.
//  The modal route stack and the toast host sit here, above the switch, so an invitation
//  link opened on a fresh install is shown before onboarding rather than hidden behind it.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
        Group {
            if FeatureFlags.showsGallery {
                ComponentGallery()
            } else if !app.isCoreLinked {
                NotLinkedView()
            } else if !app.hasCompletedOnboarding {
                OnboardingView()
            } else {
                RootTabView()
            }
        }
        .toastHost()
        .routePresenter(level: 0)
    }
}

#Preview("Light") {
    ContentView().environment(AppEnvironment.preview())
}

#Preview("Dark") {
    ContentView().environment(AppEnvironment.preview())
        .preferredColorScheme(.dark)
}
