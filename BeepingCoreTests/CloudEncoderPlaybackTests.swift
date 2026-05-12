//
//  CloudEncoderPlaybackTests.swift
//  BeepingTests
//
//  BEE-2050: assert `CloudEncoder` hands the response WAV bytes to the
//  injected `WAVPlaybackSink`, and that the sink is NOT invoked when the
//  HTTP request itself fails (4xx / 5xx). Sink errors propagate out as
//  `BeepingError`.
//
//  AVAudioPlayer is intentionally not exercised here — it needs a real
//  audio session and decodes synchronously, which is unsuitable for fast
//  CI. The default `AVAudioPlayerSink` is covered by the human QA pass
//  on the sample app (Send → audible beep).
//

import Foundation
import Testing
@testable import Beeping

@Suite("CloudEncoder WAV playback (BEE-2050)", .serialized)
struct CloudEncoderPlaybackTests {

    // MARK: - Helpers

    private func samplePayload() -> BeepingPayload {
        BeepingPayload(
            key: "abcde",
            decodedString: "abcde0001",
            mode: 2,
            timestamp: 0,
            confidence: 1.0,
            confidenceError: 0.0,
            confidenceNoise: 0.0,
            receivedBeepsVolume: 0
        )
    }

    private func mockedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// Synthetic WAV-shaped bytes. Not a real RIFF header — the test's
    /// playback sink is a spy, so the bytes only need to be identifiable.
    private func fakeWAVBytes() -> Data {
        var data = Data("RIFF".utf8)
        data.append(contentsOf: [0x24, 0x00, 0x00, 0x00])  // chunk size
        data.append(Data("WAVEbeeping-fixture".utf8))
        return data
    }

    // MARK: - Tests

    @Test("HTTP 200 hands the response body to the playback sink")
    func http200InvokesSink() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let wav = fakeWAVBytes()
        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "audio/wav"]
            )!
            return (wav, response)
        }

        let spy = SpyPlaybackSink()
        let encoder = CloudEncoder(
            apiKey: "bk_x",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession(),
            playbackSink: spy
        )

        try await encoder.encode(samplePayload())

        let captured = await spy.captured
        #expect(captured.count == 1)
        #expect(captured.first == wav)
    }

    @Test("HTTP 400 throws and does NOT invoke the playback sink")
    func http400DoesNotInvokeSink() async {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.responder = { request in
            let body = #"{"errors":["key must be exactly 5 base32 characters"]}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil
            )!
            return (body, response)
        }

        let spy = SpyPlaybackSink()
        let encoder = CloudEncoder(
            apiKey: "bk_x",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession(),
            playbackSink: spy
        )

        await #expect(throws: BeepingError.self) {
            try await encoder.encode(samplePayload())
        }
        let captured = await spy.captured
        #expect(captured.isEmpty, "Sink must not be called when the HTTP request fails")
    }

    @Test("Sink errors propagate as BeepingError out of encode")
    func sinkErrorPropagates() async {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "audio/wav"]
            )!
            return (Data([0xDE, 0xAD]), response)
        }

        let throwingSink = ThrowingPlaybackSink(
            error: BeepingError.decoderInternal(reason: "synthetic playback failure")
        )
        let encoder = CloudEncoder(
            apiKey: "bk_x",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession(),
            playbackSink: throwingSink
        )

        await #expect(throws: BeepingError.self) {
            try await encoder.encode(samplePayload())
        }
    }
}

// MARK: - Test sinks

/// Captures the bytes handed to it without any audio side-effect.
internal actor SpyPlaybackSink: WAVPlaybackSink {
    private(set) var captured: [Data] = []
    func play(wavData: Data) async throws {
        captured.append(wavData)
    }
}

/// Always rejects playback with the configured error. Used to assert
/// `CloudEncoder` propagates sink failures.
internal struct ThrowingPlaybackSink: WAVPlaybackSink {
    let error: any Error
    func play(wavData: Data) async throws {
        throw error
    }
}

/// No-op sink for tests that only care about the request shape and want
/// to swallow the response bytes silently.
internal struct NoopPlaybackSink: WAVPlaybackSink {
    func play(wavData: Data) async throws {}
}
