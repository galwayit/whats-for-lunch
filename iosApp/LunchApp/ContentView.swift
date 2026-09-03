//
//  ContentView.swift
//  LunchApp
//
//  Root switch: gallery (`-gallery`), not-linked screen, onboarding, or the tab shell.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
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
}

#Preview("Light") {
    ContentView().environment(AppEnvironment.preview())
}

#Preview("Dark") {
    ContentView().environment(AppEnvironment.preview())
        .preferredColorScheme(.dark)
}
