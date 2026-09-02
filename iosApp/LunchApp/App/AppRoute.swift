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
