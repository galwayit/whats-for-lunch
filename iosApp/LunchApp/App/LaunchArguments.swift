//
//  LaunchArguments.swift
//  LunchApp
//
//  Parses the launch arguments that pick the core implementation and seed the preview core.
//  Flags are `-name 1` / `-name 0`; a bare `-name` counts as on. Used by LunchApp.swift and
//  by Maestro / screenshot runs, e.g. `-previewCore -isPro 1 -signedIn 1 -onboarded 0`.
//  `-openRoute <name>` presents a route on start (preview core only) so screenshot runs can reach
//  screens that normally sit behind in-app navigation; names are listed on `AppRoute.init(launchName:)`.
//

import Foundation

nonisolated struct LaunchArguments: Equatable {
    let arguments: [String]

    init(_ arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.arguments = arguments
    }

    static let current = LaunchArguments()

    /// Use the in-memory `PreviewLunchCore` instead of the linked core.
    var usesPreviewCore: Bool { flag("previewCore") ?? false }
    /// Open the component gallery instead of the app.
    var showsGallery: Bool { flag("gallery") ?? false }
    var isPro: Bool { flag("isPro") ?? false }
    var isSignedIn: Bool { flag("signedIn") ?? false }
    var isOffline: Bool { flag("offline") ?? false }
    var aiUsedToday: Bool { flag("aiUsedToday") ?? false }
    /// Preview runs start past onboarding unless `-onboarded 0` is passed.
    var isOnboarded: Bool { flag("onboarded") ?? true }
    /// Invitation code to open on launch, as if the universal link had been tapped.
    var inviteCode: String? { value("openInvite") }
    /// Route to present after start, e.g. `-openRoute paywall` or `-openRoute groupDetail:grp_1`.
    /// Honoured only with `-previewCore`; production launches ignore it.
    var openRoute: AppRoute? {
        guard usesPreviewCore, let name = value("openRoute") else { return nil }
        return AppRoute(launchName: name)
    }
    /// Gallery section to open (`-gallerySection cards`).
    var gallerySection: String? { value("gallerySection") }

    /// nil when the flag is absent; `-name` alone or `-name 1` is true; `-name 0` is false.
    func flag(_ name: String) -> Bool? {
        guard let index = arguments.firstIndex(of: "-" + name) else { return nil }
        let next = arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
        switch next {
        case "0", "false", "NO": return false
        default: return true
        }
    }

    /// The token after `-name`, or nil when absent or when the next token is another flag.
    func value(_ name: String) -> String? {
        guard let index = arguments.firstIndex(of: "-" + name), arguments.indices.contains(index + 1) else { return nil }
        let next = arguments[index + 1]
        return next.hasPrefix("-") ? nil : next
    }
}
