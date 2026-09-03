//
//  LunchApp.swift
//  LunchApp
//
//  SwiftUI entry point. Picks the core from the launch arguments (`-previewCore` selects the
//  in-memory core; normal launches use the linked Kotlin production core),
//  clamps text scale, paints the ground colour, and routes invitation links.
//

import SwiftUI

@main
struct LunchApp: App {
    @UIApplicationDelegateAdaptor(LunchAppDelegate.self) private var appDelegate
    @State private var app = LunchApp.makeEnvironment(LaunchArguments.current)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
                .lunchTextScaleClamped()
                .background(Tokens.Palette.ground.ignoresSafeArea())
                .onOpenURL { url in app.open(url: url) }
                .task {
                    appDelegate.pushRegistrar = app.core.push
                    app.start()
                    if let code = LaunchArguments.current.inviteCode { app.openInvitation(code: code) }
                    if let route = LaunchArguments.current.openRoute { app.present(route) }
                }
        }
    }

    static func makeEnvironment(_ arguments: LaunchArguments) -> AppEnvironment {
        if arguments.usesPreviewCore || FeatureFlags.previewCoreByDefault {
            return AppEnvironment(core: PreviewLunchCore(options: PreviewCoreOptions(arguments: arguments)), isCoreLinked: true)
        }
        guard LunchConfig.current.isComplete else {
            return AppEnvironment(core: NotConfiguredCore(), isCoreLinked: false)
        }
        do {
            return AppEnvironment(core: try KotlinLunchCore.make(config: .current), isCoreLinked: true)
        } catch {
            assertionFailure("Could not start LunchCore: \(error)")
            return AppEnvironment(core: NotConfiguredCore(), isCoreLinked: false)
        }
    }
}
