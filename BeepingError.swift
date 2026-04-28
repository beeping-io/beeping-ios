//
//  BeepingError.swift
//  Beeping
//
//  Internal error model. The public surface lands in BEE-71 (strategy
//  pattern) and BEE-72 (builder DSL); during BEE-68 we only keep the type
//  defined for the Swift internal layer to consume — legacy ObjC paths
//  (Beeping.m, BeepingCore.m, IosAudioController.m) still surface failures
//  via NSLog and OSStatus, untouched.
//

import Foundation

/// Errors surfaced by the SDK. `Sendable` so the future actor-based API
/// (BEE-70) can pass values across isolation domains without `@unchecked`.
internal enum BeepingError: Error, Sendable {
    /// `AVAudioSession` couldn't be activated — typically because the user
    /// denied microphone access or the session was claimed by another app.
    case missingMicrophonePermission

    /// The audio session was interrupted (incoming call, Siri, another
    /// foreground app starting playback). Recoverable: the caller waits
    /// for the interruption to end and restarts `listen()`.
    case audioSessionInterrupted

    /// `libBeepingCoreUniversal.a` failed to load (or post-BEE-79 the
    /// XCFramework binary target failed to resolve). Not recoverable from
    /// the SDK side — the app bundle is malformed.
    case nativeLibraryNotLoaded

    /// The decoder reported a non-recoverable internal failure. Carries a
    /// human-readable reason for diagnostics; not part of any public
    /// contract.
    case decoderInternal(reason: String)
}
