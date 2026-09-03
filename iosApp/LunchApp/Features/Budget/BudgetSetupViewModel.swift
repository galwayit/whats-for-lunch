//
//  BudgetSetupViewModel.swift
//  LunchApp
//
//  Three-step weekly budget setup. Saves `weeklyBudget` (and the experience and celebration
//  choices under `contextualPreferences`) through `UserRepository.updatePreferences`.
//

import Foundation
import Observation

@Observable
final class BudgetSetupViewModel {
    static let stepCount = 3
    static let minimumBudget = 50.0
    static let maximumBudget = 500.0
    static let budgetStep = (maximumBudget - minimumBudget) / 10
    static let experiencesKey = "experiences"
    static let celebrationsKey = "celebrations"

    private(set) var step = 1
    var weeklyBudget: Double
    private(set) var experiences: Set<String>
    var celebrations: Bool
    private(set) var isSaving = false
    private(set) var error: CoreError?

    private let core: LunchCoreClient

    init(core: LunchCoreClient, prefs: UserPreferences?) {
        self.core = core
        let current = prefs?.weeklyBudget ?? UserPreferences().weeklyBudget
        weeklyBudget = min(max(current, Self.minimumBudget), Self.maximumBudget)
        experiences = Set(prefs?.contextualPreferences[Self.experiencesKey] ?? [])
        celebrations = prefs?.contextualPreferences[Self.celebrationsKey] != ["off"]
    }

    var progress: Double { Double(step) / Double(Self.stepCount) }
    var categories: [MealCategory] { core.mealDefaults.categories }

    func next() { if step < Self.stepCount { step += 1 } }
    func back() { if step > 1 { step -= 1 } }

    func toggleExperience(_ id: String) {
        if experiences.contains(id) { experiences.remove(id) } else { experiences.insert(id) }
    }

    /// Returns true when saved.
    func save(user: UserProfile) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        var prefs = user.preferences
        prefs.weeklyBudget = weeklyBudget
        prefs.contextualPreferences[Self.experiencesKey] = experiences.sorted()
        prefs.contextualPreferences[Self.celebrationsKey] = [celebrations ? "on" : "off"]
        do {
            try await core.users.updatePreferences(preferences: prefs)
            return true
        } catch {
            self.error = CoreError.from(error)
            return false
        }
    }
}
