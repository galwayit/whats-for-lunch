import Testing
@testable import LunchApp

struct KotlinBridgeTests {
    @Test
    func userPreferencesRoundTripAcrossKotlinBoundary() {
        let original = UserPreferences(
            dietaryRestrictions: ["vegetarian"],
            cuisinePreferences: ["Japanese"],
            allergens: ["peanut"],
            allergenSafetyLevels: ["peanut": 0],
            contextualPreferences: ["lunch": ["quick"]],
            cuisineRatings: ["Japanese": 4.5],
            restaurantVisitCounts: ["place-1": 2],
            budgetLevel: 3,
            maxTravelDistance: 7.5,
            includeChains: false,
            mealFrequencyPerDay: 2,
            weeklyBudget: 175,
            lastKnownLocation: [-37.81, 144.96],
            preferredPriceRanges: ["$$", "$$$"]
        )

        #expect(original.kotlin.app == original)
    }

    @Test
    func restaurantRoundTripPreservesOptionalAndNestedValues() {
        let review = RestaurantReview(
            reviewId: "review-1",
            authorName: "Sam",
            rating: 5,
            text: "Great lunch",
            timeEpochSeconds: 1_788_600_000
        )
        let original = Restaurant(
            placeId: "place-1",
            name: "Sample Sushi",
            location: "Melbourne",
            address: "1 Swanston Street",
            latitude: -37.81,
            longitude: 144.96,
            rating: 4.7,
            reviewCount: 120,
            priceLevel: 2,
            dietaryCompatibilityScores: ["vegetarian": 0.9],
            averageMealCost: 24,
            recentReviews: [review],
            lastVerifiedEpochSeconds: 1_788_600_001,
            photoReferences: ["photo-1"]
        )

        #expect(original.kotlin.app == original)
    }

    @Test
    func productionConfigurationRequiresEveryRuntimeDependency() {
        #expect(!LunchConfig(supabaseUrl: "https://example.supabase.co", supabaseAnonKey: "anon").isComplete)
        #expect(LunchConfig(
            supabaseUrl: "https://example.supabase.co",
            supabaseAnonKey: "anon",
            backendBaseUrl: "https://example.supabase.co/functions/v1",
            revenueCatApiKey: "appl_test"
        ).isComplete)
    }
}
