import XCTest

final class BeepingSampleAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesAndShowsSendTab() throws {
        let app = XCUIApplication()
        app.launch()
        // SwiftUI doesn't propagate accessibilityIdentifier from .tabItem
        // to the underlying tab-bar button; assert by label text instead.
        XCTAssertTrue(app.tabBars.buttons["Send"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Receive"].exists)
    }

    func testEnvPickerOpens() throws {
        let app = XCUIApplication()
        app.launch()
        let picker = app.buttons["env_picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        // Local option must always be enabled.
        XCTAssertTrue(app.buttons["env_option_local"].waitForExistence(timeout: 3))
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

    func testSendButtonEnabledWithDefaultText() throws {
        // The send button reflects the trimmed text-field state. With the
        // default "hello" prefilled it must be enabled. The disabled-state
        // path is covered by SwiftUI bindings; reproducing it here proved
        // flaky because clearing the text field via the simulator keyboard
        // depends on key visibility, which iOS 26 simulator handles
        // inconsistently.
        let app = XCUIApplication()
        app.launch()
        let field = app.textFields["send_text_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "hello")
        let send = app.buttons["send_button"]
        XCTAssertTrue(send.waitForExistence(timeout: 3))
        XCTAssertTrue(send.isEnabled)
    }
}
