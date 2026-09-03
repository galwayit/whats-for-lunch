//
//  TrackViewModel.swift
//  LunchApp
//
//  Weekly capacity, the quick meal log form, and the recent meals list.
//

import Foundation
import Observation

@Observable
final class TrackViewModel {
    enum HistoryFilter: CaseIterable { case week, month, all }

    static let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    private static let recentLimit = 50
    private static let daysPerMonth = 30

    private(set) var weekly: WeeklyBudgetState?
    private(set) var recent: [Meal] = []
    private(set) var suggestions: [String] = []
    private(set) var isLogging = false
    var historyFilter: HistoryFilter = .week

    var mealType: String
    var place = ""
    var restaurantId: String?
    var cost: Double?
    var date = Date()
    var notes = ""

    private let core: LunchCoreClient
    private var timeZoneId: String { TimeZone.current.identifier }

    init(core: LunchCoreClient) {
        self.core = core
        let hour = Calendar.current.component(.hour, from: Date())
        mealType = core.mealDefaults.smartMealType(hourOfDay: hour)
    }

    var impact: MealImpact? {
        guard let weekly, let cost, cost > 0 else { return nil }
        return core.budget.mealImpact(state: weekly, mealCost: cost)
    }

    var ringTone: CapacityRing.Tone {
        guard let weekly else { return .healthy }
        if weekly.currentSpent > weekly.weeklyCapacity { return .over }
        switch core.budget.capacityUsageLevel(state: weekly) {
        case .low, .moderate: return .healthy
        case .high: return .caution
        case .veryHigh: return .over
        }
    }

    var filteredRecent: [Meal] {
        let now = Date()
        let cutoff: Date?
        switch historyFilter {
        case .week: cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now)
        case .month: cutoff = Calendar.current.date(byAdding: .day, value: -Self.daysPerMonth, to: now)
        case .all: cutoff = nil
        }
        guard let cutoff else { return recent }
        return recent.filter { $0.date >= cutoff }
    }

    var canLog: Bool { (cost ?? 0) > 0 && !isLogging }

    func placeSuggestions(matching text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return suggestions.filter { $0.localizedCaseInsensitiveContains(trimmed) && $0 != trimmed }
    }

    func applyPrefill(_ prefill: MealPrefill) {
        place = prefill.restaurantName
        restaurantId = prefill.restaurantId
        cost = prefill.cost
    }

    func refreshWeekly(user: UserProfile) async {
        let now = core.clock.nowEpochSeconds()
        let start = core.budget.weekStart(epochSeconds: now, timeZoneId: timeZoneId)
        let meals = (try? await core.meals.inRange(userId: user.id, startEpochSeconds: start, endEpochSeconds: now)) ?? []
        weekly = core.budget.weeklyState(prefs: user.preferences, mealsThisWeek: meals, weekStartEpochSeconds: start)
        suggestions = (try? await core.meals.restaurantSuggestions(userId: user.id)) ?? []
    }

    func observeRecent(userId: Int64) async {
        let window = core.gates.historyWindowDays()
        for await meals in core.meals.observeRecent(userId: userId, limit: Self.recentLimit, windowDays: window) {
            recent = meals
        }
    }

    /// Logs the meal, refreshes the ring, and evaluates achievements. Returns the toast messages to show.
    func log(user: UserProfile) async -> [String] {
        guard let cost, canLog else { return [] }
        isLogging = true
        defer { isLogging = false }
        let trimmedPlace = place.trimmingCharacters(in: .whitespaces)
        let meal = Meal(
            userId: user.id,
            restaurantId: restaurantId,
            restaurantName: trimmedPlace.isEmpty ? nil : trimmedPlace,
            mealType: mealType,
            cost: cost,
            dateEpochSeconds: Int64(date.timeIntervalSince1970),
            notes: notes.isEmpty ? nil : notes
        )
        do {
            _ = try await core.meals.log(meal: meal)
        } catch {
            return [CoreError.from(error) == .offline ? Copy.Error.offlineTitle : Copy.Error.serviceTitle]
        }
        reset()
        await refreshWeekly(user: user)
        var toasts = [Copy.Track.logged]
        if let weekly {
            let unlocked = await unlockedAchievements(user: user, weekly: weekly)
            toasts += unlocked.map { Copy.Track.achievementUnlocked($0.title) }
        }
        return toasts
    }

    private func unlockedAchievements(user: UserProfile, weekly: WeeklyBudgetState) async -> [Achievement] {
        let now = core.clock.nowEpochSeconds()
        let allMeals = (try? await core.meals.inRange(userId: user.id, startEpochSeconds: 0, endEpochSeconds: now)) ?? []
        var unlockedIds: Set<String> = []
        for await achievements in core.achievements.observe(userId: user.id) {
            unlockedIds = Set(achievements.filter(\.isUnlocked).map(\.id))
            break
        }
        let newlyUnlocked = core.achievementEngine.evaluate(unlockedIds: unlockedIds, weekly: weekly, allMeals: allMeals, nowEpochSeconds: now, timeZoneId: timeZoneId)
        if !newlyUnlocked.isEmpty {
            await core.achievements.unlock(userId: user.id, achievements: newlyUnlocked)
        }
        return newlyUnlocked
    }

    private func reset() {
        place = ""
        restaurantId = nil
        cost = nil
        date = Date()
        notes = ""
        let hour = Calendar.current.component(.hour, from: Date())
        mealType = core.mealDefaults.smartMealType(hourOfDay: hour)
    }
}
