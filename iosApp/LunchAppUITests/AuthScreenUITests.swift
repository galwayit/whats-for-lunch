import XCTest

final class AuthScreenUITests: XCTestCase {
    @MainActor
    private func launchSignIn() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-previewCore", "-signedIn", "0", "-openRoute", "signIn"]
        app.launch()
        XCTAssertTrue(app.buttons["auth_register"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor
    func testRegistrationCanVerifyEmailAndDismiss() {
        let app = launchSignIn()
        app.buttons["auth_register"].tap()
        XCTAssertTrue(app.secureTextFields["auth_confirm_password"].waitForExistence(timeout: 5))

        app.textFields["auth_email"].tap()
        app.textFields["auth_email"].typeText("fictional@example.test")
        enterNewPassword(in: app)
        submitForm(in: app)

        XCTAssertTrue(app.textFields["auth_code"].waitForExistence(timeout: 5))
        let verification = XCTAttachment(screenshot: app.screenshot())
        verification.name = "Email verification form"
        verification.lifetime = .keepAlways
        add(verification)
        app.textFields["auth_code"].tap()
        app.textFields["auth_code"].typeText("12345678")
        submitForm(in: app)
        XCTAssertTrue(app.buttons["auth_submit"].waitForNonExistence(timeout: 5))
    }

    @MainActor
    func testPasswordRecoveryRequiresCode() {
        let app = launchSignIn()
        app.buttons["auth_forgot"].tap()
        app.textFields["auth_email"].tap()
        app.textFields["auth_email"].typeText("fictional@example.test")
        submitForm(in: app)
        XCTAssertTrue(app.textFields["auth_code"].waitForExistence(timeout: 5))
        enterNewPassword(in: app)
        submitForm(in: app)
        XCTAssertTrue(app.staticTexts["auth_error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["auth_error"].label.contains("code"))
    }

    @MainActor
    private func submitForm(in app: XCUIApplication) {
        // On a physical phone, the keyboard can partially cover the button even when
        // XCTest reports it as hittable. Bring the whole form action into view first.
        if app.keyboards.firstMatch.exists {
            app.scrollViews.containing(.button, identifier: "auth_submit").firstMatch.swipeUp()
        }
        let submit = app.buttons["auth_submit"]
        submit.tap()
    }

    @MainActor
    private func enterNewPassword(in app: XCUIApplication) {
        app.secureTextFields["auth_password"].tap()
        // iOS can offer a generated password on first focus. Exercise manual entry.
        if app.staticTexts["Use Strong Password?"].waitForExistence(timeout: 2) {
            app.buttons["xmark"].tap()
        }
        app.secureTextFields["auth_password"].typeText("fictional-password8")
        app.secureTextFields["auth_confirm_password"].tap()
        app.secureTextFields["auth_confirm_password"].typeText("fictional-password8")
    }
}
