//
//  SPMConsumer.swift
//
//  Smoke library that proves `import Beeping` resolves through SPM's
//  `.binaryTarget` and that the public API surface is reachable from
//  outside the host Xcode project (BEE-80). Compilation success is the
//  pass condition — there's no runtime test, since `BeepingClient`
//  needs an `AVAudioSession` we won't bring up here.
//

import Beeping

public enum SPMConsumer {
    /// References a handful of public symbols so the binary target
    /// can't be eliminated as dead code by the linker. Returns a
    /// debug string so callers can log it from an iOS app to verify
    /// the link succeeded at runtime too.
    public static func smokeCheck() -> String {
        let mode = BeepingMode.audible
        let level = BeepingLogLevel.info
        let err: any Error = BeepingError.audioSessionInterrupted
        return "SPMConsumer ok: mode=\(mode) level=\(level) errType=\(type(of: err))"
    }

    /// Builds a `BeepingClient` via the public factory. Intended to
    /// be called from an iOS host app where AVAudioSession is alive;
    /// here we just confirm the builder chain compiles.
    public static func buildClient() -> BeepingClient {
        BeepingClient
            .local()
            .mode(.audible)
            .logLevel(.info)
            .build()
    }
}
