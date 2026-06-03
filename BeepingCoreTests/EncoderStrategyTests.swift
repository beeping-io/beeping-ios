//
//  EncoderStrategyTests.swift
//  BeepingTests
//
//  Tests for the BEE-71 strategy pattern (LocalEncoder + CloudEncoder),
//  updated in BEE-73 to match the actual `beepbox-server` OpenAPI spec
//  (Bearer auth, EncodeRequest body shape).
//

import Testing
import Foundation
@testable import Beeping

// MARK: - Serialization
//
// MockURLProtocol's responder is `nonisolated(unsafe) static var`
// (intentional — `URLProtocol` doesn't expose configuration to its
// instances, so per-test responders need shared state). With Swift
// Testing's default parallel execution, two suites sharing the responder
// race on it; one suite's `defer reset` can clear another suite's setup
// mid-flight, surfacing as "HTTP 400: key must be exactly 5..." in tests
// that never set a 400 responder. `.serialized` keeps tests within this
// suite running one at a time, and CI runs with
// `-parallel-testing-enabled NO` to also serialize across suites
// (documented in ci.yml). Together: stable test execution.
@Suite("Encoder strategies (BEE-71 + BEE-73 contract update)", .serialized)
struct EncoderStrategyTests {

    // MARK: - Helpers

    private func samplePayload(key: String = "12345", decoded: String = "12345abcd") -> BeepingPayload {
        BeepingPayload(
            key: key,
            decodedString: decoded,
            mode: 2,
            timestamp: 99,
            confidence: 0.8,
            confidenceError: 0.1,
            confidenceNoise: 0.2,
            receivedBeepsVolume: -5
        )
    }

    private func mockedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - LocalEncoder

    @Test("LocalEncoder is an actor + conforms to BeepingEncoder")
    func localEncoderTypeShape() async {
        let wrapper = BeepingCoreWrapper()
        let encoder: any BeepingEncoder = LocalEncoder(wrapper: wrapper)
        _ = encoder
    }

    @Test("LocalEncoder.encode does not throw on a benign payload")
    func localEncoderDoesNotThrow() async throws {
        let wrapper = BeepingCoreWrapper()
        // Wrapper must be configured before `play(code:)` reaches the
        // C engine — calling encode against an unconfigured handle
        // SIGSEGVs inside `BCNativeCore.encode(...:type:)`.
        wrapper.configure(mode: .all)
        let encoder = LocalEncoder(wrapper: wrapper)
        try await encoder.encode(samplePayload())
    }

    // MARK: - CloudEncoder type shape

    @Test("CloudEncoder is an actor + conforms to BeepingEncoder")
    func cloudEncoderTypeShape() {
        let url = URL(string: "https://api.beeping.io")!
        let encoder: any BeepingEncoder = CloudEncoder(apiKey: "test", endpoint: url)
        _ = encoder
    }

    // MARK: - CloudEncoder request shape (BEE-73 contract)

    @Test("CloudEncoder.encode POSTs to /v1/encode with Bearer auth + EncodeRequest body")
    func cloudEncoderRequestShape() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.responder = { request in
            // 200 with empty audio body. Audio playback is out of scope
            // for this request-shape test — the spy sink absorbs the
            // bytes without invoking AVAudioPlayer.
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "audio/wav", "X-Beeps-Generated": "3"]
            )!
            return (Data(), response)
        }

        let encoder = CloudEncoder(
            apiKey: "bk_secret_abc",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession(),
            playbackSink: NoopPlaybackSink()
        )
        try await encoder.encode(samplePayload(key: "abcde", decoded: "abcde0001"))

        let request = try #require(MockURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.beeping.io/v1/encode")

        // BEE-73 contract: Authorization: Bearer (NOT X-API-Key)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer bk_secret_abc")
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == nil)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        // BEE-73 contract: body is EncodeRequest with `key` (5 chars), not `payload`
        let body = request.httpBody ?? request.bodyStreamData()
        let json = try #require(body.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(json["key"] as? String == "abcde")
        #expect(json["payload"] == nil)  // old shape gone
    }

    // MARK: - CloudEncoder error mapping (BEE-2308 typed errors)

    /// Runs `encode` against a mocked response and returns the thrown
    /// `BeepingError`, or `nil` if the call unexpectedly succeeded. A
    /// `nil` `status` leaves the responder unset so the URL loading
    /// system fails the request — simulating a transport-level error.
    private func capturedCloudError(
        status: Int?,
        headers: [String: String]? = nil,
        body: Data = Data()
    ) async -> BeepingError? {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        if let status {
            MockURLProtocol.responder = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: status,
                    httpVersion: "HTTP/1.1", headerFields: headers
                )!
                return (body, response)
            }
        }

        let encoder = CloudEncoder(
            apiKey: "bk_x",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession()
        )

        do {
            try await encoder.encode(samplePayload(key: "12345"))
            return nil
        } catch let error as BeepingError {
            return error
        } catch {
            return .decoderInternal(reason: "unexpected non-BeepingError: \(error)")
        }
    }

    @Test("401 maps to authenticationFailed")
    func cloudEncoder401() async {
        #expect(await capturedCloudError(status: 401) == .authenticationFailed)
    }

    @Test("403 maps to authenticationFailed")
    func cloudEncoder403() async {
        #expect(await capturedCloudError(status: 403) == .authenticationFailed)
    }

    @Test("429 with Retry-After: 30 maps to rateLimited(30)")
    func cloudEncoder429WithRetryAfter() async {
        let error = await capturedCloudError(status: 429, headers: ["Retry-After": "30"])
        #expect(error == .rateLimited(retryAfter: 30))
    }

    @Test("429 without Retry-After maps to rateLimited(0)")
    func cloudEncoder429NoRetryAfter() async {
        #expect(await capturedCloudError(status: 429) == .rateLimited(retryAfter: 0))
    }

    @Test("400 maps to networkError(400) — no longer decoderInternal")
    func cloudEncoder400() async {
        let validationJSON = """
            {"errors":["key must be exactly 5 base32 characters [0-9a-v]"]}
            """.data(using: .utf8)!
        #expect(
            await capturedCloudError(status: 400, body: validationJSON)
                == .networkError(statusCode: 400))
    }

    @Test("500 maps to networkError(500)")
    func cloudEncoder500() async {
        #expect(await capturedCloudError(status: 500) == .networkError(statusCode: 500))
    }

    @Test("Transport failure maps to networkError(nil)")
    func cloudEncoderTransportFailure() async {
        #expect(await capturedCloudError(status: nil) == .networkError(statusCode: nil))
    }

    @Test("HTTP error path never produces decoderInternal")
    func cloudEncoderHTTPNeverDecoderInternal() async {
        // Sweep the mapped status codes and assert none collapse into
        // `decoderInternal`, which is reserved for real decoder failures.
        for status in [400, 401, 403, 429, 500, 503] {
            let error = await capturedCloudError(status: status)
            if case .decoderInternal = error {
                Issue.record("status \(status) produced decoderInternal")
            }
        }
    }

    // MARK: - Codable round-trips for the BEE-73 hand-written types

    @Test("EncodeRequest Codable round-trip preserves all fields")
    func encodeRequestRoundTrip() throws {
        let original = EncodeRequest(
            key: "00000",
            mode: .inaudible,
            sampleRate: 44100,
            duration: 2.3,
            start: 0,
            interval: 2.3,
            volumeBeeps: -3
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EncodeRequest.self, from: data)
        #expect(decoded == original)
    }

    @Test("EncodeRequest with only key (minimal shape per spec)")
    func encodeRequestMinimal() throws {
        let req = EncodeRequest(key: "12345")
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["key"] as? String == "12345")
        // Optional fields not emitted when nil (default JSONEncoder behavior).
        #expect(json?["mode"] == nil)
    }

    @Test("ErrorResponse Codable round-trip")
    func errorResponseRoundTrip() throws {
        let original = ErrorResponse(error: "Boom", hint: "Try later")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ErrorResponse.self, from: data)
        #expect(decoded == original)
    }

    @Test("ValidationErrorResponse displayMessage prefers errors[] over error")
    func validationDisplayMessage() throws {
        let multi = ValidationErrorResponse(error: nil, errors: ["a", "b"])
        #expect(multi.displayMessage == "a; b")

        let single = ValidationErrorResponse(error: "single", errors: nil)
        #expect(single.displayMessage == "single")

        let empty = ValidationErrorResponse(error: nil, errors: [])
        #expect(empty.displayMessage == "Validation failed")
    }

    // MARK: - BeepingClient.send delegation

    @Test("BeepingClient.send delegates to the encoder strategy")
    func clientDelegatesToEncoder() async throws {
        actor SpyEncoder: BeepingEncoder {
            var calledWith: [String] = []
            func encode(_ payload: BeepingPayload) async throws {
                calledWith.append(payload.key)  // BEE-73: key, not decodedString
            }
        }

        let spy = SpyEncoder()
        let client = BeepingClient(encoder: spy, mode: .all)
        try await client.send(samplePayload(key: "spy00", decoded: "spy00abcd"))
        let recorded = await spy.calledWith
        #expect(recorded == ["spy00"])
        await client.close()
    }
}

// MARK: - URLRequest body helper

extension URLRequest {
    fileprivate func bodyStreamData() -> Data? {
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 { data.append(buffer, count: read) } else { break }
        }
        return data
    }
}
