//
//  SwiftBudgetEngine.swift
//  LunchApp
//
//  Pure Swift port of BudgetEngineImpl.kt. Weeks start Monday 00:00 in the given IANA zone; meal
//  impact bands at 0.3 / 0.7 / 0.9 of capacity; budget impact bands at 5 / 15 / 25 percent.
//

import Foundation

nonisolated struct SwiftBudgetEngine: BudgetEngine {
    private static let minTarget = 5
    private static let maxTarget = 21

    func weekStart(epochSeconds: Int64, timeZoneId: String) -> Int64 {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: timeZoneId) ?? .current
        calendar.firstWeekday = 2
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        let dayStart = calendar.startOfDay(for: date)
        // ISO weekday: Monday == 2 in Calendar terms (Sunday == 1).
        let weekday = calendar.component(.weekday, from: dayStart)
        let daysSinceMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: dayStart) ?? dayStart
        return Int64(calendar.startOfDay(for: monday).timeIntervalSince1970)
    }

    func targetExperiences(prefs: UserPreferences) -> Int {
        let baseTarget = Double(prefs.mealFrequencyPerDay * 7)
        let multiplier = Double(prefs.budgetLevel) / 4.0
        let target = Int((baseTarget * multiplier).rounded())
        return min(max(target, Self.minTarget), Self.maxTarget)
    }

    func weeklyState(prefs: UserPreferences, mealsThisWeek: [Meal], weekStartEpochSeconds: Int64) -> WeeklyBudgetState {
        let spent = mealsThisWeek.reduce(0.0) { $0 + $1.cost }
        return WeeklyBudgetState(
            weeklyCapacity: prefs.weeklyBudget,
            currentSpent: spent,
            remainingCapacity: max(0, prefs.weeklyBudget - spent),
            experiencesLogged: mealsThisWeek.count,
            targetExperiences: targetExperiences(prefs: prefs),
            weekStartEpochSeconds: weekStartEpochSeconds
        )
    }

    func capacityUsageLevel(state: WeeklyBudgetState) -> ImpactLevel {
        let progress = state.capacityProgress
        if progress < 0.3 { return .low }
        if progress < 0.7 { return .moderate }
        if progress < 0.9 { return .high }
        return .veryHigh
    }

    func guidanceLevel(state: WeeklyBudgetState) -> GuidanceLevel {
        let progress = state.capacityProgress
        if progress < 0.5 { return .excellent }
        if progress < 0.8 { return .good }
        if progress < 0.95 { return .moderate }
        return .high
    }

    func mealImpact(state: WeeklyBudgetState, mealCost: Double) -> MealImpact {
        let total = state.currentSpent + mealCost
        let capacityAfter = state.weeklyCapacity > 0 ? total / state.weeklyCapacity : .infinity
        let impact: ImpactLevel
        let guidance: GuidanceLevel
        let message: String
        if capacityAfter < 0.3 {
            impact = .low; guidance = .excellent
            message = "Perfect! This investment keeps you well within your comfort zone."
        } else if capacityAfter < 0.7 {
            impact = .moderate; guidance = .good
            message = "Great balance between enjoyment and your weekly investment goals."
        } else if capacityAfter < 0.9 {
            impact = .high; guidance = .moderate
            message = "This is a significant investment. Make sure it aligns with your priorities."
        } else {
            impact = .veryHigh; guidance = .high
            message = "This investment will exceed your weekly capacity. Consider adjusting the amount."
        }
        return MealImpact(
            mealCost: mealCost,
            projectedSpent: total,
            projectedRemaining: max(0, state.weeklyCapacity - total),
            impactLevel: impact,
            guidanceLevel: guidance,
            message: message,
            exceedsCapacity: total > state.weeklyCapacity
        )
    }

    func budgetImpact(prefs: UserPreferences, cost: Double?) -> BudgetImpact {
        let weeklyBudget = prefs.weeklyBudget
        guard let cost, weeklyBudget > 0 else {
            return BudgetImpact(percentageOfWeeklyBudget: 0, impactLevel: nil, message: "", remainingBudget: 0)
        }
        let percentage = (cost / weeklyBudget) * 100
        let impact: ImpactLevel
        let message: String
        if percentage < 5 {
            impact = .low; message = Copy.Track.impactLow
        } else if percentage < 15 {
            impact = .moderate; message = Copy.Track.impactModerate
        } else if percentage < 25 {
            impact = .high; message = Copy.Track.impactHigh
        } else {
            impact = .veryHigh; message = Copy.Track.impactVeryHigh
        }
        return BudgetImpact(percentageOfWeeklyBudget: percentage, impactLevel: impact, message: message, remainingBudget: weeklyBudget - cost)
    }
}
