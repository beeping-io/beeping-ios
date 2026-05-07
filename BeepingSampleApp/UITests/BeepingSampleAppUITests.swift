import XCTest

/// Smoke tests for the listener-only sample app (BEE-2220). The app
/// auto-starts the listener on launch and surfaces decoded payloads
/// from beeps emitted by `scripts/send-beep.sh` running on the host.
/// The send pipeline lives outside the app, so there is nothing to
/// drive from XCUITest beyond verifying the listener boots and the
/// debug console hatch still works.
final class BeepingSampleAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesAndStartsListening() throws {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["listener_status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(
            status.label, "Listening",
            "Listener should auto-start on launch — sample app has no Send UI"
        )
    }

    func testHeaderShowsListenerLabel() throws {
        let app = XCUIApplication()
        app.launch()
        let mode = app.staticTexts["mode_label"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        XCTAssertEqual(mode.label, "listener")
    }

    func testDebugConsoleOpensAfterFiveTaps() throws {
        let app = XCUIApplication()
        app.launch()
        let logo = app.images["app_logo"]
        XCTAssertTrue(logo.waitForExistence(timeout: 5))
        for _ in 0..<5 { logo.tap() }
        XCTAssertTrue(app.otherElements["debug_console_sheet"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["debug_close"].exists)
    }
}
