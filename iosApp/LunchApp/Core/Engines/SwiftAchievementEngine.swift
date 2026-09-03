//
//  SwiftAchievementEngine.swift
//  LunchApp
//
//  Pure Swift port of AchievementEngineImpl.kt: catalogue, unlock rules, and levels.
//  `smart_spender` has no automatic unlock rule, matching the Flutter app.
//

import Foundation

nonisolated struct SwiftAchievementEngine: AchievementEngine {
    private static let weekOptimizerMaxProgress = 0.8
    private static let weekOptimizerMinExperiences = 5
    private static let explorerUniqueTypes = 5
    private static let consistentDays = 7

    let catalogue: [Achievement] = [
        Achievement(id: "first_experience", title: "First Investment", description: "Log your first dining experience", category: "Getting Started", points: 10, iconName: "celebration"),
        Achievement(id: "week_optimizer", title: "Weekly Optimizer", description: "Stay within 80% of weekly capacity for a full week", category: "Budget Management", points: 25, iconName: "eco"),
        Achievement(id: "experience_explorer", title: "Experience Explorer", description: "Try 5 different types of dining experiences", category: "Diversity", points: 20, iconName: "explore"),
        Achievement(id: "consistent_tracker", title: "Consistent Tracker", description: "Log experiences for 7 consecutive days", category: "Consistency", points: 30, iconName: "calendar_today"),
        Achievement(id: "smart_spender", title: "Smart Investor", description: "Complete a month with optimal investment distribution", category: "Budget Management", points: 50, iconName: "psychology"),
    ]

    func evaluate(unlockedIds: Set<String>, weekly: WeeklyBudgetState, allMeals: [Meal], nowEpochSeconds: Int64, timeZoneId: String) -> [Achievement] {
        var unlocked: [Achievement] = []
        func unlock(_ id: String) {
            guard var template = catalogue.first(where: { $0.id == id }) else { return }
            template.isUnlocked = true
            template.unlockedAtEpochSeconds = nowEpochSeconds
            unlocked.append(template)
        }
        if !unlockedIds.contains("first_experience"), !allMeals.isEmpty {
            unlock("first_experience")
        }
        if !unlockedIds.contains("week_optimizer"),
           weekly.capacityProgress <= Self.weekOptimizerMaxProgress,
           weekly.experiencesLogged >= Self.weekOptimizerMinExperiences {
            unlock("week_optimizer")
        }
        if !unlockedIds.contains("experience_explorer"), Set(allMeals.map(\.mealType)).count >= Self.explorerUniqueTypes {
            unlock("experience_explorer")
        }
        if !unlockedIds.contains("consistent_tracker"), hasConsecutiveDays(allMeals, days: Self.consistentDays, timeZoneId: timeZoneId) {
            unlock("consistent_tracker")
        }
        return unlocked
    }

    func level(points: Int) -> String {
        if points < 50 { return "Beginner" }
        if points < 150 { return "Explorer" }
        if points < 300 { return "Optimizer" }
        if points < 500 { return "Expert" }
        return "Master"
    }

    /// True when the meals cover `days` consecutive local calendar days.
    private func hasConsecutiveDays(_ meals: [Meal], days: Int, timeZoneId: String) -> Bool {
        guard meals.count >= days else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneId) ?? .current
        let dayStarts = Set(meals.map { calendar.startOfDay(for: $0.date) }).sorted()
        var consecutive = 1
        for index in 1..<dayStarts.count {
            let gap = calendar.dateComponents([.day], from: dayStarts[index - 1], to: dayStarts[index]).day ?? 0
            if gap == 1 {
                consecutive += 1
                if consecutive >= days { return true }
            } else {
                consecutive = 1
            }
        }
        return false
    }
}
