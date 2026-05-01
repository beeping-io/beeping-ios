//
//  NativeBridgeSmokeTests.swift
//  BeepingTests
//
//  Swift Testing smoke for the ObjC++ bridge introduced in BEE-68 phase 2:
//  validates that `BCNativeCore` loads `libBeepingCoreUniversal.a` and
//  exposes the C API to Swift through the framework module.
//
//  These run on device only (the legacy static lib has no
//  arm64-simulator slice — fixed in BEE-79). When run on a simulator
//  the test bundle won't even link, so the Beeping-Tests scheme is the
//  surface we use locally; CI gates only the framework build until
//  BEE-79 unblocks the simulator.
//

import Testing
@testable import Beeping

@Suite("BCNativeCore (ObjC++ bridge smoke)")
struct NativeBridgeSmokeTests {

    @Test("Library version is non-empty")
    func libraryVersionNotEmpty() {
        let version = BCNativeCore.version()
        #expect(!version.isEmpty)
    }

    @Test("Init / dealloc cycle does not crash")
    func initDeallocCycle() {
        // Just creating + dropping the wrapper should run BEEPING_Create
        // and BEEPING_Destroy without aborting. ARC handles deallocation.
        var core: BCNativeCore? = BCNativeCore()
        #expect(core != nil)
        core = nil  // -> dealloc
        // No assertion needed; ASan / UBSan in Debug builds would catch
        // double-free or use-after-free if the C API is misbehaving.
    }

    @Test("Configure with default mode returns 0 (success)")
    func configureWithDefaultModeSucceeds() {
        let core = BCNativeCore()
        // BEEPING_MODE_ALL = 5 from BeepingCoreLib_api.h
        let result = core.configure(
            withMode: 5,
            sampleRate: 44100,
            bufferSize: 1024)
        #expect(result == 0)
    }
}
