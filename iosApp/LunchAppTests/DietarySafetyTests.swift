import Testing
@testable import LunchApp

struct DietarySafetyTests {
    let engine = SwiftRecommendationEngine()

    @Test func missing_allergen_evidence_is_not_a_match_even_with_a_general_verification_flag() {
        for verified in [false, true] {
            var place = Restaurant(placeId: "cafe", name: "Cafe", location: "")
            place.hasVerifiedDietaryInfo = verified
            let prefs = UserPreferences(allergens: ["nut_allergy"])
            #expect(engine.dietaryCompatibility(restaurant: place, dietaryRestrictions: [], allergens: prefs.allergens) == 0)
            #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: prefs).isEmpty)
            #expect(engine.bestMatch(candidates: [place], prefs: prefs, rejected: []) == nil)
        }
    }

    @Test func known_conflicts_are_rejected_even_when_unverified_places_are_allowed() {
        for allergen in ["Peanuts", "tree-nuts", "nut_allergy"] {
            var place = Restaurant(placeId: "cafe", name: "Cafe", location: "")
            place.allergenInfo = [allergen]
            place.hasVerifiedDietaryInfo = true
            let prefs = UserPreferences(allergens: ["nut_allergy"], requireDietaryVerification: false)
            #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: prefs).isEmpty)
        }
    }

    @Test func exploration_allows_unknown_places_only_when_the_user_turns_off_verification() {
        let place = Restaurant(placeId: "cafe", name: "Cafe", location: "")
        let prefs = UserPreferences(allergens: ["nut_allergy"], requireDietaryVerification: false)
        #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: prefs) == [place])
        #expect(engine.dietaryCompatibility(restaurant: place, dietaryRestrictions: [], allergens: prefs.allergens) == 0)
        #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: UserPreferences()) == [place])
    }

    @Test func a_verified_diet_requires_an_explicit_match() {
        var place = Restaurant(placeId: "cafe", name: "Cafe", location: "")
        place.hasVerifiedDietaryInfo = true
        place.supportedDietaryRestrictions = ["vegetarian"]
        #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: UserPreferences(dietaryRestrictions: ["vegetarian"])) == [place])
        #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: UserPreferences(dietaryRestrictions: ["vegan"])).isEmpty)
        place.dietaryCompatibilityScores["vegan"] = 1
        #expect(engine.applyPreferenceFilters(restaurants: [place], prefs: UserPreferences(dietaryRestrictions: ["vegan"])).isEmpty)
    }
}
