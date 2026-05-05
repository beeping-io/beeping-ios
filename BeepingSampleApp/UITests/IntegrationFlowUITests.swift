import XCTest

/// Drives the app through the 3 environments (Local / Dev / Prod) and
/// asserts that each one reaches a usable state without crashing.
///
/// Each test launches a fresh app instance, switches env via the picker,
/// taps Send, and verifies the UI side-effects (Last sent populated, no
/// red error, listener active). The cloud round-trip body bytes are NOT
/// checked here (that needs network log inspection); the UI assertions
/// only ensure the encode call dispatched without throwing.
final class IntegrationFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Local

    func testLocalSendShowsLastSent() throws {
        let app = launchApp()
        assertListenerOn(app)

        tapSend(app, payload: "hello")

        // Local encoder is fire-and-forget; "Last sent" reflects success.
        XCTAssertTrue(
            app.staticTexts["last_sent_label"].waitForExistence(timeout: 5),
            "Local Send should populate Last sent"
        )
        assertNoSendError(app)

        attachScreenshot(app, name: "local_after_send")
    }

    // MARK: - Dev

    func testDevSendRoundTrip() throws {
        let app = launchApp()
        switchEnv(app, to: "Dev")
        assertListenerOn(app)

        tapSend(app, payload: "dev-test")

        XCTAssertTrue(
            app.staticTexts["last_sent_label"].waitForExistence(timeout: 12),
            "Dev cloud Send should populate Last sent within 12s"
        )
        assertNoSendError(app)

        attachScreenshot(app, name: "dev_after_send")
    }

    // MARK: - Prod

    func testProdSendRoundTrip() throws {
        let app = launchApp()
        switchEnv(app, to: "Prod")
        assertListenerOn(app)

        tapSend(app, payload: "prod-test")

        XCTAssertTrue(
            app.staticTexts["last_sent_label"].waitForExistence(timeout: 12),
            "Prod cloud Send should populate Last sent within 12s"
        )
        assertNoSendError(app)

        attachScreenshot(app, name: "prod_after_send")
    }

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(
            app.textFields["send_text_field"].waitForExistence(timeout: 5),
            "App should launch and present send_text_field"
        )
        return app
    }

    private func assertListenerOn(_ app: XCUIApplication) {
        let status = app.staticTexts["listener_status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "Listening", "Listener should auto-start after env binding")
    }

    private func switchEnv(_ app: XCUIApplication, to name: String) {
        app.buttons["env_picker"].tap()
        let id = "env_option_\(name.lowercased())"
        let option = app.buttons[id]
        XCTAssertTrue(
            option.waitForExistence(timeout: 3),
            "Env picker should expose \(id)"
        )
        XCTAssertTrue(option.isEnabled, "\(name) option must be enabled (key+endpoint present)")
        option.tap()
    }

    private func tapSend(_ app: XCUIApplication, payload: String) {
        let field = app.textFields["send_text_field"]
        field.tap()
        // Replace existing text by selecting all and pasting.
        field.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 1.5) {
            app.menuItems["Select All"].tap()
        }
        field.typeText(payload)

        let send = app.buttons["send_button"]
        XCTAssertTrue(send.waitForExistence(timeout: 3))
        XCTAssertTrue(send.isEnabled, "Send button must be enabled when text is non-empty")
        send.tap()
    }

    private func assertNoSendError(_ app: XCUIApplication) {
        // Last send error label only renders when AppModel.lastSendError != nil.
        let err = app.staticTexts["last_error_label"]
        XCTAssertFalse(
            err.exists,
            "Send should not produce an error (label visible: '\(err.label)')"
        )
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
