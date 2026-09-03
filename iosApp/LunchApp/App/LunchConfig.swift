//
//  LunchConfig.swift
//  LunchApp
//
//  Reads Config/Lunch.plist (see Lunch.plist.example). The file is git-ignored, so every value
//  is optional and the app runs without it: the core is simply reported as not linked.
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
            revenueCatApiKey: string("revenueCatApiKey"),
            inviteLinkBase: string("inviteLinkBase") ?? LunchConfig.defaultInviteLinkBase
        )
    }

    /// True once the backend values exist. The Kotlin core is still not linked in this build,
    /// so `LunchApp` shows the not-linked screen regardless; this is for the adapter milestone.
    var hasBackend: Bool { supabaseUrl != nil && supabaseAnonKey != nil }

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
