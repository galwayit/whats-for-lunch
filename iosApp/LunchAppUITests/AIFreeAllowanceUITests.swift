import XCTest

final class AIFreeAllowanceUITests: XCTestCase {
    @MainActor
    func testFirstFreeRequestThenSubscriptionPaywall() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "1", "-pro", "0", "-aiUsedToday", "0", "-openRoute", "ai"]
        app.launch()
        let ask = app.buttons["ai_ask_button"]
        XCTAssertTrue(ask.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["paywall_cta"].exists)
        ask.tap()
        let consent = app.buttons["ai_consent_agree"]
        if consent.waitForExistence(timeout: 3) { consent.tap() }
        let result = app.descendants(matching: .any)["ai_result_0"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["paywall_cta"].exists)
        ask.tap()
        XCTAssertTrue(app.buttons["paywall_cta"].waitForExistence(timeout: 10))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Subscription prompt after one free AI request"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
