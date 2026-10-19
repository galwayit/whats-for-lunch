import XCTest

final class SubmissionReadinessUITests: XCTestCase {
    @MainActor
    func testManualAreaIsAvailableWithoutRequestingDeviceLocation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-openRoute", "searchArea"]
        app.launch()
        let query = app.textFields["search_area_query"]
        XCTAssertTrue(query.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["search_area_find"].isEnabled)
        XCTAssertTrue(app.buttons["search_area_current"].exists)
        query.tap()
        query.typeText("Geelong VIC")
        XCTAssertTrue(app.buttons["search_area_find"].isEnabled)
        // Don't send the query: this verifies the alternative is usable without
        // an OS permission prompt; MapKit/provider acceptance is a separate check.
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Manual search area before submitting"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testGuestCanReachReportingAndBlockingFromInvitation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "0", "-openInvite", "K7P2QX"]
        app.launch()
        let report = app.buttons["Report invitation or block host"]
        XCTAssertTrue(report.waitForExistence(timeout: 10))
        for _ in 0..<5 { if report.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(report.isHittable)
        report.tap()
        XCTAssertTrue(app.buttons["Send report"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Report and block"].exists)
        XCTAssertTrue(app.buttons["Block without reporting"].exists)
        XCTAssertTrue(app.links["Contact support"].exists || app.buttons["Contact support"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Invitation report and block choices"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
