import XCTest
@testable import BeepingSampleApp
import Beeping

final class AppEnvironmentTests: XCTestCase {

    func testEnumCasesCoverThree() {
        XCTAssertEqual(AppEnvironment.allCases.count, 3)
        XCTAssertEqual(Set(AppEnvironment.allCases.map(\.rawValue)), ["local", "dev", "prod"])
    }

    func testLocalIsAlwaysAvailable() {
        XCTAssertTrue(AppEnvironment.local.isAvailable)
    }

    func testDisplayNamesAreCapitalized() {
        XCTAssertEqual(AppEnvironment.local.displayName, "Local")
        XCTAssertEqual(AppEnvironment.dev.displayName, "Dev")
        XCTAssertEqual(AppEnvironment.prod.displayName, "Prod")
    }

    @MainActor
    func testMakeClientLocalReturnsNonNil() {
        XCTAssertNotNil(AppEnvironment.local.makeClient())
    }

    @MainActor
    func testMakeClientReturnsNilWhenUnavailable() {
        // Best-effort: if envs are configured we just assert local works.
        if !AppEnvironment.dev.isAvailable {
            XCTAssertNil(AppEnvironment.dev.makeClient())
        }
        if !AppEnvironment.prod.isAvailable {
            XCTAssertNil(AppEnvironment.prod.makeClient())
        }
    }
}
