//
//  LunchConfig.swift
//  LunchApp
//
//  Reads the bundled Lunch.plist (see Config/Lunch.plist.example). The build script
//  scripts/copy_runtime_config.sh bundles Config/Lunch.plist for Debug and Config/Lunch.Release.plist
//  for Release. Both are git-ignored, so every value is optional and the app runs without them:
//  production features report that setup is required.
//

import Foundation

nonisolated struct LunchConfig: Equatable {
    var supabaseUrl: String?
    var supabaseAnonKey: String?
    var backendBaseUrl: String?
    var revenueCatApiKey: String?
    var inviteLinkBase: String

    static let defaultInviteLinkBase = "https://lunch.iapp.au/i"
    static let inviteHost = "lunch.iapp.au"
    static let privacyUrl = URL(string: "https://lunch.iapp.au/privacy/")!
    static let supportUrl = URL(string: "https://lunch.iapp.au/support/")!
    static let termsUrl = URL(string: "https://lunch.iapp.au/terms/")!
    static let appStoreUrl = URL(string: "https://apps.apple.com/app/id6808090102")!

    static let current = LunchConfig(bundle: .main)

    init(supabaseUrl: String? = nil, supabaseAnonKey: String? = nil, backendBaseUrl: String? = nil, revenueCatApiKey: String? = nil, inviteLinkBase: String = LunchConfig.defaultInviteLinkBase) {
        self.supabaseUrl = supabaseUrl
        self.supabaseAnonKey = supabaseAnonKey
        self.backendBaseUrl = backendBaseUrl
        self.revenueCatApiKey = revenueCatApiKey
        self.inviteLinkBase = inviteLinkBase
    }

    init(bundle: Bundle) {
        let values = bundle.url(forResource: "Lunch", withExtension: "plist")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? PropertyListSerialization.propertyList(from: $0, format: nil) as? [String: Any] } ?? [:]
        func string(_ key: String) -> String? {
            guard let value = values[key] as? String, !value.isEmpty, !value.contains("YOUR") else { return nil }
            return value
        }
        self.init(
            supabaseUrl: string("supabaseUrl"),
            supabaseAnonKey: string("supabaseAnonKey"),
            backendBaseUrl: string("backendBaseUrl"),
            revenueCatApiKey: Self.revenueCatKey(string("revenueCatApiKey"), allowingTestStore: Self.allowsTestStoreKey),
            inviteLinkBase: string("inviteLinkBase") ?? LunchConfig.defaultInviteLinkBase
        )
    }

    /// RevenueCat Test Store keys (`test_`) simulate purchases, so a Release build that carried one
    /// would never charge anyone. The build script refuses to bundle one; this is the runtime backstop.
    #if DEBUG
    static let allowsTestStoreKey = true
    #else
    static let allowsTestStoreKey = false
    #endif

    /// Drops a Test Store key when the build may not use one, which leaves the config incomplete
    /// and starts the "setup required" core instead of a store that silently never charges.
    static func revenueCatKey(_ key: String?, allowingTestStore: Bool) -> String? {
        guard let key else { return nil }
        return key.hasPrefix("test_") && !allowingTestStore ? nil : key
    }

    /// True once the backend values exist.
    var hasBackend: Bool { supabaseUrl != nil && supabaseAnonKey != nil }

    /// Debug builds may run against the real backend before a RevenueCat project exists;
    /// the core then turns purchases off and the user stays on the free tier.
    #if DEBUG
    static let allowsMissingPurchases = true
    #else
    static let allowsMissingPurchases = false
    #endif

    /// Every value required to start the production core. Keeping this stricter than
    /// `hasBackend` prevents a partially configured Release build from crashing later.
    var isComplete: Bool { isComplete(allowingMissingPurchases: Self.allowsMissingPurchases) }

    func isComplete(allowingMissingPurchases: Bool) -> Bool {
        hasBackend && backendBaseUrl != nil && (revenueCatApiKey != nil || allowingMissingPurchases)
    }

    func inviteUrl(code: String) -> String {
        inviteLinkBase.hasSuffix("/") ? inviteLinkBase + code : inviteLinkBase + "/" + code
    }

    /// Extracts the invitation code from `https://lunch.iapp.au/i/<code>` (or `/invite/<code>`).
    static func inviteCode(from url: URL) -> String? {
        guard url.host?.lowercased() == inviteHost else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, ["i", "invite"].contains(parts[0].lowercased()), !parts[1].isEmpty else { return nil }
        return parts[1]
    }
}
