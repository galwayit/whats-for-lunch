//
//  AppRoute.swift
//  LunchApp
//
//  Every destination in the app, per the navigation section of design/screens.md. Tabs host
//  their own stacks; the rest are pushed or presented modally from the tab noted.
//

import Foundation

enum AppRoute: Hashable {
    case onboarding
    case tab(LunchTab)
    // From Home
    case aiRecommendations(pickPlaceId: String?)
    case groupCreate
    case groupProposals(groupId: String)
    case groupDetail(groupId: String)
    case paywall
    // From Profile
    case preferences
    case signIn
    case privacy
    case help
    // From Track
    case budgetSetup
    // From anywhere (universal link)
    case invitation(code: String)
}

extension AppRoute {
    /// Parses the `-openRoute` launch argument. Plain names: `onboarding`, `ai`, `groupCreate`,
    /// `paywall`, `preferences`, `signIn`, `privacy`, `help`, `budgetSetup`. Names with a value use
    /// a colon: `tab:track`, `groupProposals:<id>`, `groupDetail:<id>`, `invitation:<code>`.
    nonisolated init?(launchName: String) {
        let parts = launchName.split(separator: ":", maxSplits: 1).map(String.init)
        let value = parts.count == 2 ? parts[1] : nil
        switch (parts.first ?? "", value) {
        case ("onboarding", nil): self = .onboarding
        case ("ai", nil): self = .aiRecommendations(pickPlaceId: nil)
        case ("groupCreate", nil): self = .groupCreate
        case ("paywall", nil): self = .paywall
        case ("preferences", nil): self = .preferences
        case ("signIn", nil): self = .signIn
        case ("privacy", nil): self = .privacy
        case ("help", nil): self = .help
        case ("budgetSetup", nil): self = .budgetSetup
        case ("tab", let name?):
            switch name {
            case "home": self = .tab(.home)
            case "discover": self = .tab(.discover)
            case "track": self = .tab(.track)
            case "profile": self = .tab(.profile)
            default: return nil
            }
        case ("groupProposals", let id?): self = .groupProposals(groupId: id)
        case ("groupDetail", let id?): self = .groupDetail(groupId: id)
        case ("invitation", let code?): self = .invitation(code: code)
        default: return nil
        }
    }
}
