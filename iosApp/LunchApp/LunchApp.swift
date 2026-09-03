//
//  LunchApp.swift
//  LunchApp
//
//  SwiftUI entry point. Picks the core from the launch arguments (`-previewCore` selects the
//  in-memory core; otherwise the not-linked placeholder until the Kotlin framework arrives),
//  clamps text scale, paints the ground colour, and routes invitation links.
//

import SwiftUI

@main
struct LunchApp: App {
    @State private var app = LunchApp.makeEnvironment(LaunchArguments.current)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
                .lunchTextScaleClamped()
                .background(Tokens.Palette.ground.ignoresSafeArea())
                .onOpenURL { url in app.open(url: url) }
                .task {
                    app.start()
                    if let code = LaunchArguments.current.inviteCode { app.openInvitation(code: code) }
                }
        }
    }

    static func makeEnvironment(_ arguments: LaunchArguments) -> AppEnvironment {
        if arguments.usesPreviewCore || FeatureFlags.previewCoreByDefault {
            return AppEnvironment(core: PreviewLunchCore(options: PreviewCoreOptions(arguments: arguments)), isCoreLinked: true)
        }
        return AppEnvironment(core: NotConfiguredCore(), isCoreLinked: false)
    }
}
