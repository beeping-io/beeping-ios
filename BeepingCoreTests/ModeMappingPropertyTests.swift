//
//  ModeMappingPropertyTests.swift
//  BeepingTests
//
//  Property-style tests for the `BeepingMode` → `EncodeRequest.Mode`
//  mapping that lives on `CloudEncoder` (BEE-76). The mapping is a
//  finite, total function over the public enum; we exercise every
//  case to guarantee:
//
//    1. Totality: no case crashes / no missing branch.
//    2. Range: every output lies in the server's accepted enum
//       (`audible | inaudible | all`).
//    3. Semantic alignment: audible-family → `.audible`,
//       inaudible-family → `.inaudible`, all/custom → `.all`.
//
//  Beepbox-server defaults to `inaudible` when the field is omitted,
//  which means a missing mapping would silently produce an
//  ultrasonic beep — these tests are the regression guard.
//

import Testing
@testable import Beeping

@Suite("BeepingMode → EncodeRequest.Mode property tests (BEE-76)")
struct ModeMappingPropertyTests {

    @Test(
        "Mapping is total across every BeepingMode case",
        arguments: BeepingMode.allCases
    )
    func totalFunction(mode: BeepingMode) {
        // Must not crash; must produce a valid EncodeRequest.Mode.
        let result = CloudEncoder.serverMode(from: mode)
        let allowed: Set<EncodeRequest.Mode> = [.audible, .inaudible, .all]
        #expect(allowed.contains(result), "\(mode) → \(result) outside server enum")
    }

    @Test(
        "Audible-family modes map to .audible",
        arguments: [BeepingMode.audible, .audibleOld]
    )
    func audibleFamily(mode: BeepingMode) {
        #expect(CloudEncoder.serverMode(from: mode) == .audible)
    }

    @Test(
        "Inaudible-family modes map to .inaudible (server default — avoided)",
        arguments: [BeepingMode.nonAudible, .nonAudibleOld, .hidden]
    )
    func inaudibleFamily(mode: BeepingMode) {
        #expect(CloudEncoder.serverMode(from: mode) == .inaudible)
    }

    @Test(
        "all / custom map to .all (server picks all bands)",
        arguments: [BeepingMode.all, .custom]
    )
    func allFamily(mode: BeepingMode) {
        #expect(CloudEncoder.serverMode(from: mode) == .all)
    }
}

// `BeepingMode` is `public enum ... : Int32, Sendable` but does not
// conform to `CaseIterable` in the public surface. Synthesizing it
// internally for property iteration via `@testable import` avoids
// adding a new conformance to the SDK's external API.
extension BeepingMode: @retroactive CaseIterable {
    public static var allCases: [BeepingMode] {
        [.audibleOld, .nonAudibleOld, .audible, .nonAudible, .hidden, .all, .custom]
    }
}
