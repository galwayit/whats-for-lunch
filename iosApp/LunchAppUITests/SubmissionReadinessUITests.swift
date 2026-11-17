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

    /// Only a signed-in user has a server account, so a signed-out user must not be offered a
    /// deletion that can only fail (App Review 5.1.1(v) expects the flow to work when shown).
    @MainActor
    func testDeleteAccountIsHiddenWhenSignedOut() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "0"]
        app.launch()
        XCTAssertTrue(app.buttons["tab_profile"].waitForExistence(timeout: 15))
        app.buttons["tab_profile"].tap()
        XCTAssertTrue(app.buttons["profile_export"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["profile_delete"].exists)
    }

    /// Apple's name may only label the real Sign in with Apple control. The paywall's sign-in
    /// prompt opens the general sheet, so it must carry a neutral title.
    @MainActor
    func testPaywallSignInPromptDoesNotUseApplesName() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "0", "-openRoute", "paywall"]
        app.launch()
        XCTAssertTrue(app.buttons["Sign in"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["Continue with Apple"].exists)
    }

    @MainActor
    func testSignedInUserCanDeleteAccountAndSeesConfirmation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "1"]
        app.launch()
        XCTAssertTrue(app.buttons["tab_profile"].waitForExistence(timeout: 15))
        app.buttons["tab_profile"].tap()
        let delete = app.buttons["profile_delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 10))
        for _ in 0..<5 { if delete.isHittable { break }; app.swipeUp() }
        delete.tap()
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["Your account is deleted. Meals on this device are kept."].waitForExistence(timeout: 10))
        XCTAssertFalse(delete.exists)
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
