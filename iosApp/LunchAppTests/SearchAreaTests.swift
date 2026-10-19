import Foundation
import Testing
@testable import LunchApp

struct SearchAreaTests {
    @Test func search_area_round_trips_and_can_be_cleared_without_device_permission() throws {
        let defaults = try #require(UserDefaults(suiteName: "lunch.search-area-tests.\(UUID().uuidString)"))
        let area = SearchArea(name: "Melbourne VIC", latitude: -37.81, longitude: 144.96)
        SearchArea.save(area, to: defaults)
        #expect(SearchArea.load(from: defaults) == area)
        SearchArea.save(nil, to: defaults)
        #expect(SearchArea.load(from: defaults) == nil)
    }

    @Test func invalid_coordinates_cannot_be_saved() throws {
        let defaults = try #require(UserDefaults(suiteName: "lunch.search-area-tests.\(UUID().uuidString)"))
        for area in [SearchArea(name: "Invalid", latitude: 91, longitude: 0), SearchArea(name: "Invalid", latitude: 0, longitude: .infinity), SearchArea(name: " ", latitude: 0, longitude: 0)] {
            SearchArea.save(area, to: defaults)
            #expect(SearchArea.load(from: defaults) == nil)
        }
    }
}
