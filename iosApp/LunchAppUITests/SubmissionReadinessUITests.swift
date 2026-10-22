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

    /// A guest who installs from the invite link has never onboarded; the invitation must be the
    /// first screen, not buried behind five onboarding steps.
    @MainActor
    func testInvitationShowsBeforeOnboardingOnFreshInstall() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-onboarded", "0", "-signedIn", "0", "-openInvite", "K7P2QX"]
        app.launch()
        let invitation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'invited you to lunch'")).firstMatch
        XCTAssertTrue(invitation.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Accept"].exists)
        XCTAssertFalse(app.staticTexts["STEP 1 OF 5"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Invitation shown before onboarding"
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
