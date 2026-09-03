//
//  AppEnvironment.swift
//  LunchApp
//
//  App-wide observable state: the core client, the signed-in user, entitlement and session
//  state mirrored from the core's streams, the selected tab, and the modal route stack.
//  Injected once from `LunchApp` with `.environment(app)`.
//

import Foundation
import Observation

@Observable
final class AppEnvironment {
    let core: LunchCoreClient
    /// False when running on `NotConfiguredCore`; the root shows the not-linked screen.
    let isCoreLinked: Bool

    private(set) var user: UserProfile?
    private(set) var hasCompletedOnboarding: Bool
    private(set) var isPro: Bool
    private(set) var session: AuthSession?

    var selectedTab: LunchTab = .home
    /// Modal stack. Index 0 is presented over the tabs, index 1 over that sheet, and so on.
    private(set) var routes: [AppRoute] = []
    /// Set by onboarding so Home runs the first search automatically.
    var shouldRunFirstSearch = false
    /// Transient message shown by `ToastHost`; cleared automatically.
    var toast: String?
    /// Filled by "Log this meal" on Home, Discover, or AI; Track consumes it when it appears.
    var mealPrefill: MealPrefill?
    /// Craving typed on Home (Pro only); the AI screen consumes it when it appears.
    var aiCravingDraft: String?

    private var observers: [Task<Void, Never>] = []

    init(core: LunchCoreClient, isCoreLinked: Bool = true) {
        self.core = core
        self.isCoreLinked = isCoreLinked
        user = core.users.current
        hasCompletedOnboarding = core.users.hasCompletedOnboarding
        isPro = core.entitlements.isPro
        session = core.auth.session
    }

    /// Mirrors the core's streams into observable state. Safe to call more than once.
    func start() {
        guard observers.isEmpty else { return }
        observers = [
            Task { for await profile in core.users.currentUpdates { user = profile } },
            Task { for await done in core.users.hasCompletedOnboardingUpdates { hasCompletedOnboarding = done } },
            Task { for await pro in core.entitlements.isProUpdates { isPro = pro } },
            Task { for await session in core.auth.sessionUpdates { self.session = session } },
        ]
    }

    // MARK: Routes

    func present(_ route: AppRoute) {
        guard routes.last != route else { return }
        routes.append(route)
    }

    /// Dismisses the topmost modal.
    func dismiss() {
        guard !routes.isEmpty else { return }
        routes.removeLast()
    }

    /// Keeps `level` modals; used by the sheet binding when a sheet is swiped away.
    func dismiss(toLevel level: Int) {
        guard routes.count > level else { return }
        routes = Array(routes.prefix(level))
    }

    func dismissAll() { routes = [] }

    func route(at level: Int) -> AppRoute? {
        routes.indices.contains(level) ? routes[level] : nil
    }

    /// Replaces the top modal, so a gate can swap itself for the Paywall or Sign in sheet.
    func replaceTop(with route: AppRoute) {
        if routes.isEmpty { routes = [route] } else { routes[routes.count - 1] = route }
    }

    /// Presents the screen a gate denial asks for; returns false for reasons handled inline.
    @discardableResult
    func present(gate reason: GateReason) -> Bool {
        switch reason {
        case .hostRequiresPro, .aiDailyLimit, .favouritesLimit, .historyWindow:
            present(.paywall)
            return true
        case .signInRequired:
            present(.signIn)
            return true
        case .ok:
            return false
        }
    }

    /// Handles `https://lunch.iapp.au/i/<code>`; returns false for unrelated URLs.
    @discardableResult
    func open(url: URL) -> Bool {
        guard let code = LunchConfig.inviteCode(from: url) else { return false }
        openInvitation(code: code)
        return true
    }

    func openInvitation(code: String) {
        dismissAll()
        present(.invitation(code: code))
    }

    func showToast(_ message: String) { toast = message }

    /// "Log this meal" from any screen: dismisses modals and opens Track with the form filled.
    func logMeal(at restaurant: Restaurant) {
        mealPrefill = MealPrefill(restaurant: restaurant)
        dismissAll()
        selectedTab = .track
    }

    // MARK: Previews and tests

    static func preview(_ options: PreviewCoreOptions = PreviewCoreOptions()) -> AppEnvironment {
        let environment = AppEnvironment(core: PreviewLunchCore(options: options))
        environment.start()
        return environment
    }
}

/// A restaurant handed to the Track tab so the quick log form starts filled in.
nonisolated struct MealPrefill: Hashable {
    var restaurantId: String?
    var restaurantName: String
    var cost: Double?

    init(restaurant: Restaurant) {
        restaurantId = restaurant.placeId
        restaurantName = restaurant.name
        cost = restaurant.averageMealCost
    }
}

extension AppRoute: Identifiable {
    var id: String { String(describing: self) }
}
