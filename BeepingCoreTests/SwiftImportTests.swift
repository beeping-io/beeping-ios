import XCTest
@testable import Beeping

final class SwiftImportTests: XCTestCase {
    func testCanCreateBeepingEventFromSwift() {
        let event = BeepingEvent(
            status: .endOk,
            key: "12345",
            decodedString: "12345abcd",
            mode: 1,
            timestamp: 42,
            confidence: 0.8,
            confidenceError: 0.1,
            confidenceNoise: 0.2,
            receivedBeepsVolume: -5
        )
        XCTAssertEqual(event.key, "12345")
        XCTAssertEqual(event.status, .endOk)
        XCTAssertEqual(event.decodedString, "12345abcd")
    }
}
