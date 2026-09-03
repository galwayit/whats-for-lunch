/**
 * @file PreferencesViewModel.swift
 * @description State for screen 8 (Preferences): edits a working copy of the user's
 *              preferences and saves it through `UserRepository.updatePreferences`.
 * @author AI Assistant
 * @date 2026-09-03
 */

import Foundation

@Observable
final class PreferencesViewModel {
    var budgetLevel: Int
    var weeklyBudget: Double
    var maxTravelDistance: Double
    var includeChains: Bool
    private(set) var dietary: Set<String>
    private(set) var allergens: Set<String>
    private(set) var isSaving = false
    private(set) var error: CoreError?

    private let core: LunchCoreClient

    static let weeklyRange = BudgetSetupViewModel.minimumBudget...BudgetSetupViewModel.maximumBudget
    static let weeklyStep = BudgetSetupViewModel.budgetStep

    init(core: LunchCoreClient, prefs: UserPreferences?) {
        self.core = core
        let prefs = prefs ?? UserPreferences()
        budgetLevel = prefs.budgetLevel
        weeklyBudget = prefs.weeklyBudget
        maxTravelDistance = prefs.maxTravelDistance
        includeChains = prefs.includeChains
        dietary = Set(prefs.dietaryRestrictions.map(Self.key))
        allergens = Set(prefs.allergens.map(Self.key))
    }

    func toggleDietary(_ key: String) {
        if dietary.contains(key) { dietary.remove(key) } else { dietary.insert(key) }
    }

    func toggleAllergen(_ key: String) {
        if allergens.contains(key) { allergens.remove(key) } else { allergens.insert(key) }
    }

    /// Writes the edited fields onto the user's stored preferences. Returns false after setting `error`.
    func save(user: UserProfile) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        error = nil
        var prefs = user.preferences
        prefs.budgetLevel = budgetLevel
        prefs.preferredPriceRanges = (1...budgetLevel).map { String(repeating: "$", count: $0) }
        prefs.weeklyBudget = weeklyBudget
        prefs.maxTravelDistance = maxTravelDistance
        prefs.includeChains = includeChains
        prefs.dietaryRestrictions = dietary.sorted()
        prefs.allergens = allergens.sorted()
        do {
            try await core.users.updatePreferences(preferences: prefs)
            return true
        } catch {
            self.error = CoreError.from(error)
            return false
        }
    }

    /// Normalises stored labels such as "Gluten free" to the copy-deck chip keys ("gluten_free").
    nonisolated static func key(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
    }
}
