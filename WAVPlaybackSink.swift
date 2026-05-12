//
//  WAVPlaybackSink.swift
//  Beeping
//
//  Sink that plays back the `audio/wav` blob returned by `beepbox-server`
//  through the device speaker. Introduced in BEE-2050 to close the gap
//  left by BEE-73 partial: `CloudEncoder` previously discarded the WAV
//  bytes, which broke the round-trip Send → audio → Receive in cloud mode.
//
//  ## Why a protocol
//
//  Decoupling lets `CloudEncoder` unit tests inject a spy and assert that
//  the bytes flow through, without bringing up a real `AVAudioSession` or
//  AVAudioPlayer in CI. Production wiring uses the default
//  `AVAudioPlayerSink`.
//
//  ## Why `AVAudioPlayer` (Option A)
//
//  Smallest possible diff: `AVAudioPlayer(data:)` ingests the server's
//  `audio/wav` bytes directly, no manual header parsing, no `AUGraph`
//  scheduling. Latency (~300 ms init + buffering) is acceptable for this
//  use case because the server-side encode is already on the order of
//  100s of ms. Option B (push PCM frames into `AudioEngine`) is left as
//  a follow-up if/when latency becomes load-bearing.
//
//  ## Audio session
//
//  When the same `BeepingClient` is also listening, `AudioEngine` has
//  already activated an `AVAudioSession` configured for `.playAndRecord`
//  with `defaultToSpeaker` — `AVAudioPlayer` mixes into that session.
//  In cloud-only / non-listening scenarios, iOS falls back to the app's
//  default session category, which is sufficient for plain playback.
//

import AVFoundation
import Foundation

internal protocol WAVPlaybackSink: Sendable {
    /// Plays the given `audio/wav` payload. Throws `BeepingError` if the
    /// bytes can't be initialized as an `AVAudioPlayer` (corrupt header,
    /// unsupported format, etc.).
    func play(wavData: Data) async throws
}

/// Default `WAVPlaybackSink` used by `CloudEncoder` in production. Wraps
/// `AVAudioPlayer(data:)` and retains the player for the lifetime of the
/// playback so the deinit doesn't fire mid-render.
internal actor AVAudioPlayerSink: WAVPlaybackSink {

    /// Strong ref to the most recent player. Each `play(wavData:)` replaces
    /// it; the previous one is released and stops playing. That tradeoff
    /// matches the SDK's "single in-flight encode" expectation — a cloud
    /// `send(_:)` call is effectively serialized through the encoder actor.
    private var current: AVAudioPlayer?
    private let log = BeepingLog(category: "playback")

    func play(wavData: Data) async throws {
        log.info("received \(wavData.count) bytes")

        // Force the session's output route to the device speaker. With
        // `.playAndRecord` the default policy is the receiver (earpiece),
        // even when the listener was configured with `.defaultToSpeaker`
        // — that flag is consulted at category-set time only, and a
        // subsequent AVAudioPlayer can land on the receiver. Overriding
        // here puts the cloud beep on the same speaker the local-mode
        // path already drives.
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            log.error("overrideOutputAudioPort failed: \(error.localizedDescription)")
        }

        do {
            let player = try AVAudioPlayer(data: wavData)
            player.volume = 1.0
            player.prepareToPlay()
            guard player.play() else {
                log.error("AVAudioPlayer.play() returned false")
                throw BeepingError.decoderInternal(reason: "AVAudioPlayer.play() returned false")
            }
            log.info(
                "playing: duration=\(player.duration)s "
                    + "channels=\(player.numberOfChannels) "
                    + "vol=\(player.volume)"
            )
            self.current = player
        } catch let error as BeepingError {
            throw error
        } catch {
            log.error("AVAudioPlayer init failed: \(error.localizedDescription)")
            throw BeepingError.decoderInternal(
                reason: "AVAudioPlayer init failed: \(error.localizedDescription)"
            )
        }
    }
}
