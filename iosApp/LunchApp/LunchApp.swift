//
//  LunchApp.swift
//  LunchApp
//
//  SwiftUI entry point. The whole hierarchy is clamped to the token text-scale range and
//  painted on the ground colour.
//

import SwiftUI

@main
struct LunchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .lunchTextScaleClamped()
                .background(Tokens.Palette.ground.ignoresSafeArea())
        }
    }
}
