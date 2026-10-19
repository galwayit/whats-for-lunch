import Foundation
import Testing
@testable import LunchApp

@MainActor
struct ChainPreferenceTests {
    @Test func regional_chain_aliases_and_punctuation_are_excluded() {
        let names = ["Hungry Jack's Burgers Melbourne Central", "HUNGRY JACK’S", "Hungry Jacks", "Hungry-Jack’s", "HungryJacks", "Burger King", "McDonald’s", "Domino's Pizza", "Grill’d", "KFC Swanston Street"]
        let engine = SwiftRecommendationEngine()
        var prefs = UserPreferences()
        prefs.includeChains = false
        for name in names {
            var restaurant = PreviewData.restaurants[0]
            restaurant.name = name
            #expect(RestaurantChains.matches(name), "\(name) must be recognised")
            #expect(engine.applyPreferenceFilters(restaurants: [restaurant], prefs: prefs).isEmpty)
            #expect(engine.bestMatch(candidates: [restaurant], prefs: prefs, rejected: []) == nil)
        }
    }

    @Test func unrelated_names_are_not_rejected_by_substring() {
        for name in ["Jack’s Corner Cafe", "The Hungry Hippo", "Burger Kingdom", "Subwayman Coffee", "Local Pizza Kitchen"] {
            #expect(!RestaurantChains.matches(name), "\(name) should not match a brand")
        }
    }

    @Test func enabling_chains_allows_hungry_jacks_again() {
        var restaurant = PreviewData.restaurants[0]
        restaurant.name = "Hungry Jack’s"
        var prefs = UserPreferences()
        prefs.includeChains = true
        #expect(SwiftRecommendationEngine().bestMatch(candidates: [restaurant], prefs: prefs, rejected: []) != nil)
    }

    @Test func preference_change_clears_old_home_pick_and_count() async {
        let core = PreviewLunchCore()
        let model = HomeViewModel(core: core)
        await model.search(prefs: nil)
        #expect(model.picksCount > 0)
        model.reset()
        #expect(model.hero == .idle)
        #expect(model.picksCount == 0)
    }

    @Test func old_search_cannot_restore_pick_after_preferences_change() async {
        let core = PreviewLunchCore()
        let model = HomeViewModel(core: core)
        let search = Task { await model.search(prefs: nil) }
        while !model.isSearching { await Task.yield() }
        model.reset()
        await search.value
        #expect(model.hero == .idle)
        #expect(model.picksCount == 0)
    }
}
