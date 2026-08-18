//
//  Beeping.swift
//  Beeping
//
//  Public singleton facade. Replaces the legacy ObjC `Beeping.{h,m}` with
//  a Swift class isolated to the main actor (Swift 6 strict concurrency).
//  All consumer-facing dispatch happens on the main thread.
//
//  ## API stability (BEE-68)
//
//  Preserved 1:1 from the legacy ObjC class:
//    - ObjC class name `Beeping` (via @objc(Beeping))
//    - `+ (Beeping *)instance` (via @objc(instance) on `class func shared()`)
//    - `- (void)listen` / `- (void)stop` selectors
//    - `delegate` weak property of type `id<beepingDelegate>`
//
//  The actor-based redesign in BEE-70 introduces a separate
//  `BeepingClient` type with `AsyncStream<BeepingEvent>`; this class
//  persists alongside it for backward ObjC compat through 0.x.
//
//  ## Swift class name (BEE-80)
//
//  The Swift class is `BeepingLegacy`, not `Beeping`. A class whose
//  name matches its module breaks `library evolution` swiftinterface
//  generation in any consumer that does `import Beeping`: nested types
//  like `Beeping.TelemetryEvent.ErrorCategory` get reparsed as
//  *member type of class `Beeping`*, which fails. ObjC consumers still
//  see `Beeping` via `@objc(Beeping)`; Swift consumers transitioning
//  from the legacy singleton spell it `BeepingLegacy.shared()`.
//
//  ## Concurrency model
//
//  The class is `@MainActor`-isolated. Internally it owns a
//  `BeepingCoreWrapper` (BEE-68 phase 4) which surfaces audio-token
//  events on its own serial dispatch queue. We hop those events onto the
//  MainActor via `Task { @MainActor in ... }` before invoking the
//  delegate, so consumer callbacks are guaranteed to run on the main
//  thread — same contract the legacy `Beeping.m` provided via
//  `dispatch_async(dispatch_get_main_queue(), ...)`.
//

import Foundation

@MainActor
@objc(BeepingLegacy)
public final class BeepingLegacy: NSObject {

    // MARK: - Singleton

    private static let _shared = BeepingLegacy()

    /// The shared instance. ObjC: `[Beeping instance]`. Swift: `BeepingLegacy.shared()`.
    @objc(instance)
    public class func shared() -> BeepingLegacy {
        return _shared
    }

    // MARK: - Public API

    /// Object that receives decoded beep events. Held weakly.
    @objc public weak var delegate: (any BeepingDelegate)?

    /// Start listening for incoming beeps. The audio session is
    /// configured here; the user is prompted for microphone permission
    /// the first time `listen()` runs after install.
    /// - Note: BEE-2351 — this legacy entry point stays non-throwing to keep
    ///   its Objective-C selector (`listen`) stable; adding `throws` would
    ///   rename it to `listenAndReturnError:` and break ObjC callers. A
    ///   failure to activate the audio session is logged and listening
    ///   simply does not start. Consumers that need the error should use
    ///   `BeepingClient.listen()`, which reports it as `.failed`.
    @objc public func listen() {
        do {
            try wrapper.startListening()
        } catch {
            log.error("listen() could not start audio: \(error)")
        }
    }

    /// Stop listening.
    @objc public func stop() {
        wrapper.stopListening()
    }

    // MARK: - Internals

    private let wrapper: BeepingCoreWrapper

    /// BEE-2351: the legacy facade has no error channel of its own, so a
    /// failed audio start is reported here.
    private let log = BeepingLog(category: "legacy")

    private override init() {
        let w = BeepingCoreWrapper()
        self.wrapper = w
        super.init()

        // Wire the wrapper's serial-queue event callback onto the
        // MainActor before invoking the delegate. The closure is invoked
        // by `BeepingCoreWrapper.handleAudioToken(...)` from a serial
        // dispatch queue (already off the real-time audio thread).
        w.onEvent = { [weak self] event in
            Task { @MainActor [weak self] in
                self?.dispatch(event: event)
            }
        }

        // Default mode = decode any of audible / non-audible / hidden.
        // Custom modes / sample rates are not exposed on this legacy
        // facade; consumers wanting them go through the new actor API
        // landing in BEE-70.
        w.configure(mode: .all)
    }

    private func dispatch(event: BeepingEvent) {
        // Mirrors legacy `Beeping.m -onBeep:` dispatch pattern:
        //   - Always invoke beepingDidReceive(event:) (optional)
        //   - On endOk with a non-nil key, also invoke beepId(with:) (required)
        delegate?.beepingDidReceive?(event: event)
        if event.status == .endOk, let key = event.key {
            delegate?.beepId(with: key)
        }
    }

    // MARK: - Test seam

    /// Internal entry point for tests (`@testable import Beeping`). Replaces
    /// the legacy XCTest pattern of injecting a stub `BeepingCore` via KVC
    /// (`setValue:forKey:@"_beepingCore"`) — Swift's stored properties are
    /// not KVC-accessible, and this seam is more honest about the contract
    /// being tested: that an arbitrary `BeepingEvent` reaches the delegate
    /// per the dispatch rules.
    internal func _injectEventForTesting(_ event: BeepingEvent) {
        dispatch(event: event)
    }
}
