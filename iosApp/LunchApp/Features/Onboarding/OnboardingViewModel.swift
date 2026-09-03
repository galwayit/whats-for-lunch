//
//  OnboardingViewModel.swift
//  LunchApp
//
//  Five-step onboarding state. Finishing creates the user through `UserRepository.createUser`
//  and asks Home to run the first search.
//

import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    static let stepCount = 5
    static let distanceRange: ClosedRange<Double> = 1...20
    static let priceLevels = 1...4

    private(set) var step = 1
    var name = ""
    var budgetLevel = 2
    var maxTravelDistance = 5.0
    var includeChains = true
    private(set) var dietary: Set<String> = []
    private(set) var isSubmitting = false
    private(set) var error: CoreError?

    private let core: LunchCoreClient
    private let permission = LocationPermission()

    init(core: LunchCoreClient) {
        self.core = core
    }

    var progress: Double { Double(step) / Double(Self.stepCount) }
    var canContinue: Bool { step != 2 || !trimmedName.isEmpty }
    var hasLocationPermission: Bool { permission.isGranted }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    func next() { if step < Self.stepCount { step += 1 } }
    func back() { if step > 1 { step -= 1 } }

    func toggleDietary(_ key: String) {
        if key == Copy.Dietary.none.key {
            dietary = dietary.contains(key) ? [] : [key]
            return
        }
        dietary.remove(Copy.Dietary.none.key)
        if dietary.contains(key) { dietary.remove(key) } else { dietary.insert(key) }
    }

    var preferences: UserPreferences {
        var prefs = UserPreferences()
        prefs.budgetLevel = budgetLevel
        prefs.maxTravelDistance = maxTravelDistance
        prefs.includeChains = includeChains
        prefs.preferredPriceRanges = (1...budgetLevel).map { String(repeating: "$", count: $0) }
        let chosen = dietary.subtracting([Copy.Dietary.none.key])
        prefs.dietaryRestrictions = chosen.filter { !Copy.Dietary.allergenKeys.contains($0) }.sorted()
        prefs.allergens = chosen.filter { Copy.Dietary.allergenKeys.contains($0) }.sorted()
        return prefs
    }

    /// Step 5 primary action: system prompt, then create the user.
    func allowLocation(app: AppEnvironment) async {
        _ = await permission.request()
        await finish(app: app)
    }

    func finish(app: AppEnvironment) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }
        do {
            _ = try await core.users.createUser(name: trimmedName, preferences: preferences)
            app.shouldRunFirstSearch = true
        } catch {
            self.error = CoreError.from(error)
        }
    }
}
