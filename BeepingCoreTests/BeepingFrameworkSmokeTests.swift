//
//  BeepingFrameworkSmokeTests.swift
//  BeepingTests
//
//  Trivial framework-level smoke. Replaces the legacy
//  `BeepingCoreTests.m -testExample` (deleted in BEE-68 phase 6) with
//  Swift Testing equivalents.
//

import Testing
@testable import Beeping

@Suite("Framework smoke")
@MainActor
struct BeepingFrameworkSmokeTests {

    @Test("Framework imports cleanly")
    func frameworkImports() {
        // No-op: the import statement above is the assertion.
    }

    @Test("Singleton resolves to a non-nil instance")
    func singletonExists() {
        let instance = BeepingLegacy.shared()
        // `BeepingLegacy.shared()` returns `Beeping`, not `Beeping?` — there's
        // nothing to compare; reaching here without crashing is the test.
        _ = instance
    }

    @Test("Singleton is stable (same identity across calls)")
    func singletonIsStable() {
        let a = BeepingLegacy.shared()
        let b = BeepingLegacy.shared()
        #expect(a === b)
    }
}
