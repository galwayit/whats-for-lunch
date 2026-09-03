//
//  RoutePresenter.swift
//  LunchApp
//
//  Presents `AppEnvironment.routes` as nested sheets. Level n presents the route at index n and
//  attaches level n+1 to its content, so AI -> Paywall or Group -> Sign in stack naturally.
//

import SwiftUI

struct RoutePresenter: ViewModifier {
    @Environment(AppEnvironment.self) private var app
    let level: Int

    func body(content: Content) -> some View {
        content.sheet(item: binding) { route in
            RouteView(route: route)
                .lunchTextScaleClamped()
                .toastHost()
                .modifier(RoutePresenter(level: level + 1))
        }
    }

    private var binding: Binding<AppRoute?> {
        Binding(
            get: { app.route(at: level) },
            set: { route in if route == nil { app.dismiss(toLevel: level) } }
        )
    }
}

extension View {
    func routePresenter(level: Int) -> some View {
        modifier(RoutePresenter(level: level))
    }
}

/// Maps a route to its screen. Tabs and onboarding are hosted by the root, not presented.
struct RouteView: View {
    @Environment(AppEnvironment.self) private var app
    let route: AppRoute

    var body: some View {
        switch route {
        case .aiRecommendations(let pickPlaceId): AIRecommendationsView(pickPlaceId: pickPlaceId)
        case .groupCreate: GroupCreateView()
        case .groupProposals(let groupId): GroupProposalsView(groupId: groupId)
        case .groupDetail(let groupId): GroupDetailView(groupId: groupId)
        case .paywall: PaywallScreen()
        case .preferences: PreferencesView()
        case .signIn: SignInSheet()
        case .privacy: InfoScreen(kind: .privacy)
        case .help: InfoScreen(kind: .help)
        case .budgetSetup: BudgetSetupView()
        case .invitation(let code): InvitationView(code: code)
        case .onboarding: OnboardingView()
        case .tab(let tab):
            Color.clear.onAppear {
                app.dismissAll()
                app.selectedTab = tab
            }
        }
    }
}
