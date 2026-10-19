import XCTest

/// Runs against the installed app with in-memory fixtures, so screen interactions do not
/// change the phone owner's meals, favourites, preferences, or account.
final class RedesignSmokeUITests: XCTestCase {
    @MainActor
    func testMainScreensAndRecommendationInLightAppearance() {
        checkMainScreens(appearance: "Light")
    }

    @MainActor
    func testMainScreensAndRecommendationInDarkAppearance() {
        checkMainScreens(appearance: "Dark")
    }

    @MainActor
    private func checkMainScreens(appearance: String) {
        continueAfterFailure = false
        let app = launchPreview(appearance: appearance)
        let hungry = app.buttons["hero_hungry_button"]
        XCTAssertTrue(hungry.waitForExistence(timeout: 15))
        capture(app, "Home \(appearance)")
        reveal(hungry, in: app)
        hungry.tap()
        let recommendation = app.descendants(matching: .any)["recommendation_card"].firstMatch
        XCTAssertTrue(recommendation.waitForExistence(timeout: 15))
        capture(app, "Recommendation \(appearance)")

        app.buttons["tab_discover"].tap()
        XCTAssertTrue(app.textFields["discover_search_field"].waitForExistence(timeout: 10))
        let restaurant = app.descendants(matching: .any)["restaurant_card_0"].firstMatch
        XCTAssertTrue(restaurant.waitForExistence(timeout: 15))
        capture(app, "Discover \(appearance)")

        app.buttons["tab_track"].tap()
        XCTAssertTrue(app.buttons["capacity_ring"].waitForExistence(timeout: 10))
        capture(app, "Track \(appearance)")

        app.buttons["tab_profile"].tap()
        let preferences = app.buttons["profile_pref_budget"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 10))
        capture(app, "Profile \(appearance)")
        preferences.tap()
        XCTAssertTrue(app.buttons["preferences_save"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.sliders["preferences_weekly_slider"].exists)
        capture(app, "Preferences \(appearance)")
        app.buttons["header_close"].tap()
        XCTAssertTrue(app.buttons["tab_home"].waitForExistence(timeout: 5))
        app.buttons["tab_home"].tap()
        XCTAssertTrue(app.buttons["hero_hungry_button"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testRestaurantDetailsCanPrefillMealAndSplitBill() {
        continueAfterFailure = false
        let app = launchPreview(appearance: "Light")
        XCTAssertTrue(app.buttons["tab_discover"].waitForExistence(timeout: 15))
        app.buttons["tab_discover"].tap()
        let restaurant = app.descendants(matching: .any)["restaurant_card_0"].firstMatch
        XCTAssertTrue(restaurant.waitForExistence(timeout: 15))
        reveal(restaurant, in: app)
        restaurant.tap()
        let logMeal = app.buttons["detail_log_meal"]
        XCTAssertTrue(logMeal.waitForExistence(timeout: 10))
        capture(app, "Restaurant details")
        reveal(logMeal, in: app)
        logMeal.tap()
        let cost = app.textFields["meal_cost_field"]
        XCTAssertTrue(cost.waitForExistence(timeout: 10))
        let originalCost = cost.value as? String
        XCTAssertFalse((app.textFields["meal_place_field"].value as? String ?? "").isEmpty)
        let split = app.buttons["split_bill_button"]
        reveal(split, in: app)
        split.tap()
        let useShare = app.buttons["split_use_share_button"]
        XCTAssertTrue(useShare.waitForExistence(timeout: 10))
        XCTAssertTrue(useShare.isEnabled)
        XCTAssertTrue(app.staticTexts["split_total_line"].exists)
        capture(app, "Split bill with restaurant cost")
        useShare.tap()
        XCTAssertTrue(useShare.waitForNonExistence(timeout: 5))
        XCTAssertNotEqual(cost.value as? String, originalCost)
        XCTAssertTrue((app.textFields["meal_notes_field"].value as? String ?? "").contains("2"))
        capture(app, "Meal prefilled with my share")
    }

    @MainActor
    func testGroupSplitSheetOpensWithItsModelAndCanReopen() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "1", "-isPro", "1",
                               "-openRoute", "groupDetail:grp_1"]
        app.launch()
        let split = app.buttons["group_split_button"]
        XCTAssertTrue(split.waitForExistence(timeout: 15))
        reveal(split, in: app)
        split.tap()
        let bill = app.textFields["split_bill_field"]
        XCTAssertTrue(bill.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["split_use_share_button"].isEnabled)
        capture(app, "Group split bill")
        app.buttons["header_close"].tap()
        XCTAssertTrue(bill.waitForNonExistence(timeout: 5))
        split.tap()
        XCTAssertTrue(bill.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["split_use_share_button"].isEnabled)
    }

    @MainActor
    private func launchPreview(appearance: String) -> XCUIApplication {
        let previousAppearance = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in XCUIDevice.shared.appearance = previousAppearance }
        let requestedAppearance: XCUIDevice.Appearance = appearance == "Dark" ? .dark : .light
        XCUIDevice.shared.appearance = requestedAppearance
        XCTAssertEqual(XCUIDevice.shared.appearance, requestedAppearance)
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "1", "-isPro", "0"]
        app.launch()
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Redesign - \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
