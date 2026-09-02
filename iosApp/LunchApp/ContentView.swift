//
//  ContentView.swift
//  LunchApp
//
//  Root switch. The component gallery is the entry for this milestone; the tab shell is
//  reachable behind `FeatureFlags.showsRootTabs` (launch argument `-rootTabs`).
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        if FeatureFlags.showsRootTabs {
            RootTabView()
        } else {
            ComponentGallery()
        }
    }
}

#Preview("Light") {
    ContentView()
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
