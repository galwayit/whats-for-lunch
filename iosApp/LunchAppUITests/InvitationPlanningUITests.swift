import XCTest

final class InvitationPlanningUITests: XCTestCase {
    @MainActor
    func testFailedPlacePickerKeepsHeaderAtTopOfFullScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-isPro", "1", "-signedIn", "1", "-offline", "1", "-openRoute", "groupProposals:grp_1"]
        app.launch()
        let title = app.staticTexts["Pick a place"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        let consent = app.buttons["Agree and continue"]
        if consent.waitForExistence(timeout: 3) { consent.tap() }
        XCTAssertTrue(app.buttons["Try again"].waitForExistence(timeout: 10))
        XCTAssertLessThan(title.frame.minY, 160, "Error content must not vertically centre the entire screen header")
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Place picker full-screen error"; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor
    func testGuestCanSendAlternativeFromInvitation() {
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "0", "-openInvite", "K7P2QX"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Host: Ray"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Budget: to be confirmed"].exists)
        let suggest = app.buttons["invite_suggest_change"]
        for _ in 0..<3 { if suggest.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(suggest.isHittable)
        let before = XCTAttachment(screenshot: app.screenshot()); before.name = "Invitation details and three choices"; before.lifetime = .keepAlways; add(before)
        suggest.tap()
        let name = app.textFields["suggestion_guest_name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Fictional Sam")
        let place = app.textFields["suggestion_place"]
        place.tap(); place.typeText("Test cafe")
        let send = app.buttons["invite_suggestion_send"]
        for _ in 0..<3 { if send.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(send.isHittable)
        send.tap()
        XCTAssertTrue(app.staticTexts["Waiting for the host to review"].waitForExistence(timeout: 10))
        let after = XCTAttachment(screenshot: app.screenshot()); after.name = "Guest suggestion awaiting host"; after.lifetime = .keepAlways; add(after)
    }
}
