//
//  BeepingCoreWrapper.swift
//  Beeping
//
//  Internal Swift wrapper around `BCNativeCore` (the C engine handle from
//  beeping-core) and `AudioEngine` (AVAudioSession + RemoteIO). Replaces
//  the legacy ObjC `BeepingCore` class while preserving the public API
//  surface used by `Beeping.m` (legacy singleton) and by the future
//  `Beeping.swift` (BEE-68 phase 5).
//
//  ## Concurrency model
//
//  `final class @unchecked Sendable`. `actor` is NOT viable here because
//  the audio render callback in `BCAudioUnitController` cannot `await` —
//  it must return synchronously to the AudioUnit. We use an `os_unfair_lock`
//  to serialize access to the small Swift-side mutable state shared
//  between caller threads (typically main) and the audio engine's serial
//  dispatch queue:
//
//    - `_decodedString`  — written by the audio path, read by callers
//    - `_isListening`    — written by `start/stopListening`, read by audio
//    - `_isEmitting`     — written by `play(...)`, read by audio
//
//  The `BCNativeCore` C handle is NOT locked here: the legacy ObjC
//  implementation never locked it either (the C API is implicitly
//  single-threaded by convention — once `startListening()` runs, the
//  caller does not re-`configure(...)`). Preserving legacy semantics is
//  a stated BEE-68 goal; locking the handle is deferred to the actor-based
//  redesign in BEE-70.
//

import Foundation
import os.lock

internal final class BeepingCoreWrapper: @unchecked Sendable {

    // MARK: - State

    private let _handle: BCNativeCore
    private var _audioEngine: AudioEngine?

    private var _decodedString: String?
    private var _isListening:   Bool = false
    private var _isEmitting:    Bool = false

    // os_unfair_lock back to iOS 10. iOS 16+ unlocks `OSAllocatedUnfairLock`,
    // a Swift-native API; we target iOS 15+ so we use the C primitive
    // through `withUnsafeMutablePointer` to take its address safely.
    private var _lock = os_unfair_lock_s()

    /// Closure invoked by the audio path when a token transition is
    /// received. Always called from the AudioEngine's serial dispatch
    /// queue (NOT the real-time audio thread). Set by the caller before
    /// `configure(...)`.
    internal var onEvent: (@Sendable (BeepingEvent) -> Void)?

    // MARK: - Init

    internal init() {
        self._handle = BCNativeCore()
    }

    // MARK: - Locking helper

    @inline(__always)
    private func withLock<T>(_ body: () -> T) -> T {
        withUnsafeMutablePointer(to: &_lock) { ptr in
            os_unfair_lock_lock(ptr)
            defer { os_unfair_lock_unlock(ptr) }
            return body()
        }
    }

    // MARK: - Configuration

    internal func configure(mode: BeepingMode,
                            sampleRate: Float = 44100,
                            bufferSize: Int32 = 1024) {
        let result = _handle.configure(withMode: mode.rawValue,
                                       sampleRate: sampleRate,
                                       bufferSize: bufferSize)
        if result != 0 {
            // Match legacy behavior: log + soldier on. Real diagnostics
            // surface in BEE-74 (os.Logger + trace-IDs).
            NSLog("[BeepingCoreWrapper] BEEPING_Configure failed (\(result))")
        }

        let engine = AudioEngine(core: _handle)
        engine.onAudioToken = { [weak self] token, decodedString in
            self?.handleAudioToken(token, decodedString: decodedString)
        }
        _audioEngine = engine
    }

    @discardableResult
    internal func setCustomBaseFreq(_ freq: Float, beepsSeparation: Int32) -> Int32 {
        return _handle.setCustomBaseFreq(freq, beepsSeparation: beepsSeparation)
    }

    // MARK: - Listen

    internal func startListening() {
        let shouldStart: Bool = withLock {
            guard !_isListening else { return false }
            _isListening = true
            return true
        }
        if shouldStart { _audioEngine?.start() }
    }

    internal func stopListening() {
        let shouldStop: Bool = withLock {
            guard _isListening else { return false }
            _isListening = false
            return true
        }
        if shouldStop { _audioEngine?.stop() }
    }

    // MARK: - Play

    internal func play(code: String) {
        let _ = _handle.encode(code, type: 0)
        withLock { _isEmitting = true }
        _audioEngine?.markEmitting(true)
        _audioEngine?.start()
    }

    // MARK: - Decoded data getters (legacy API surface)

    internal var decodedString: String? { withLock { _decodedString } }

    internal var decodedKey: String? {
        guard let s = decodedString, s.count >= 5 else { return nil }
        return String(s.prefix(5))
    }

    internal var decodedTimestamp: Int {
        guard let s = decodedString, s.count >= 9 else { return 0 }
        return Self.fromBase32(s.dropFirst(5).prefix(4))
    }

    internal var decodedMode: Int           { Int(_handle.decodedMode) }
    internal var confidence: Float          { _handle.confidence }
    internal var confidenceError: Float     { _handle.confidenceError }
    internal var confidenceNoise: Float     { _handle.confidenceNoise }
    internal var receivedBeepsVolume: Float { _handle.receivedBeepsVolume }
    internal var decodingBeginFreq: Float   { _handle.decodingBeginFreq }
    internal var decodingEndFreq: Float     { _handle.decodingEndFreq }

    internal static var libraryVersion: String { BCNativeCore.version() }
    internal static var frameworkVersion: String {
        // Preserved literal from legacy `getVersionCoreFramework`.
        return "BeepingCore.framework version 1.0.4 [20012017]"
    }

    // MARK: - Audio token handling

    private func handleAudioToken(_ token: Int32, decodedString: String?) {
        // Runs on the AudioEngine's serial dispatch queue.
        if let str = decodedString {
            withLock { _decodedString = str }
        }
        let resolvedDecoded: String?
        if decodedString != nil {
            resolvedDecoded = decodedString
        } else {
            resolvedDecoded = withLock { _decodedString }
        }
        let event = Self.buildEvent(
            token: token,
            decoded: resolvedDecoded,
            mode: Int(_handle.decodedMode),
            confidence: _handle.confidence,
            confidenceError: _handle.confidenceError,
            confidenceNoise: _handle.confidenceNoise,
            volume: _handle.receivedBeepsVolume
        )
        if let event {
            onEvent?(event)
        }
    }

    private static func buildEvent(token: Int32,
                                   decoded: String?,
                                   mode: Int,
                                   confidence: Float,
                                   confidenceError: Float,
                                   confidenceNoise: Float,
                                   volume: Float) -> BeepingEvent? {
        // Token semantics from `BeepingCoreLib_api.h`:
        //   -2 = start, -3 = end (decoded data ready or invalid)
        // `decoded == nil` on -3 indicates the data was invalid (END_BAD).
        let key: String? = decoded.flatMap { $0.count >= 5 ? String($0.prefix(5)) : nil }
        let timestamp: Int
        if let d = decoded, d.count >= 9 {
            timestamp = fromBase32(d.dropFirst(5).prefix(4))
        } else {
            timestamp = 0
        }

        switch token {
        case -2:
            return BeepingEvent(status: .start, key: nil, decodedString: nil,
                                mode: 0, timestamp: 0,
                                confidence: 0, confidenceError: 0,
                                confidenceNoise: 0, receivedBeepsVolume: 0)
        case -3 where decoded != nil:
            return BeepingEvent(status: .endOk, key: key,
                                decodedString: decoded, mode: mode, timestamp: timestamp,
                                confidence: confidence, confidenceError: confidenceError,
                                confidenceNoise: confidenceNoise,
                                receivedBeepsVolume: volume)
        case -3:
            return BeepingEvent(status: .endBad, key: nil, decodedString: nil,
                                mode: mode, timestamp: 0,
                                confidence: confidence, confidenceError: confidenceError,
                                confidenceNoise: confidenceNoise,
                                receivedBeepsVolume: volume)
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private static let _base32Chars: [Character] =
        Array("0123456789abcdefghijklmnopqrstuv")

    private static func fromBase32<S: StringProtocol>(_ s: S) -> Int {
        var decimal = 0
        var factor = 1
        for ch in s.reversed() {
            guard let idx = _base32Chars.firstIndex(of: ch) else { return 0 }
            decimal += factor * idx
            factor *= 32
        }
        return decimal
    }
}
