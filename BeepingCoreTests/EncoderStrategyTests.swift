//
//  EncoderStrategyTests.swift
//  BeepingTests
//
//  Tests for the BEE-71 strategy pattern: `BeepingEncoder` protocol +
//  `LocalEncoder` actor + `CloudEncoder` actor. Verifies the contract
//  shape, that LocalEncoder forwards to the wrapper, and that
//  CloudEncoder builds the right URLRequest (URLProtocol mock).
//

import Testing
import Foundation
@testable import Beeping

@Suite("Encoder strategies (BEE-71)")
struct EncoderStrategyTests {

    // MARK: - Helpers

    private func samplePayload(decoded: String = "12345abcd") -> BeepingPayload {
        BeepingPayload(
            key: String(decoded.prefix(5)),
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
        // Reaching here means: Sendable conformance compiles, actor
        // isolation compiles, protocol conformance compiles.
        _ = encoder
    }

    @Test("LocalEncoder.encode does not throw on a benign payload")
    func localEncoderDoesNotThrow() async throws {
        let wrapper = BeepingCoreWrapper()
        let encoder = LocalEncoder(wrapper: wrapper)
        try await encoder.encode(samplePayload())
        // Verifying actual playback would require microphone-permission
        // simulation — out of scope for this unit test. The wrapper
        // gracefully no-ops if the audio session can't be started.
    }

    // MARK: - CloudEncoder

    @Test("CloudEncoder is an actor + conforms to BeepingEncoder")
    func cloudEncoderTypeShape() {
        let url = URL(string: "https://api.beeping.io")!
        let encoder: any BeepingEncoder = CloudEncoder(
            apiKey: "test",
            endpoint: url
        )
        _ = encoder
    }

    @Test("CloudEncoder.encode POSTs to /v1/encode with the right URL + headers + body")
    func cloudEncoderRequestShape() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.responder = { request in
            // Echo a 200 with empty body — the audio response handling is BEE-73.
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (Data(), response)
        }

        let encoder = CloudEncoder(
            apiKey: "secret-key-123",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession()
        )
        try await encoder.encode(samplePayload(decoded: "abcdefghi"))

        let request = try #require(MockURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.beeping.io/v1/encode")
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == "secret-key-123")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        // URLSession with custom URLProtocol stashes httpBody on the
        // request stream rather than the request property — pull it from
        // the stream, falling back to the property for clarity.
        let body = request.httpBody ?? request.bodyStreamData()
        let json = try #require(body.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: String] })
        #expect(json["payload"] == "abcdefghi")
    }

    @Test("CloudEncoder.encode throws BeepingError.decoderInternal on non-2xx HTTP")
    func cloudEncoderThrowsOnNon200() async {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (Data(), response)
        }

        let encoder = CloudEncoder(
            apiKey: "wrong-key",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession()
        )

        await #expect(throws: BeepingError.self) {
            try await encoder.encode(samplePayload())
        }
    }

    // MARK: - BeepingClient.send delegation

    @Test("BeepingClient.send delegates to the encoder strategy")
    func clientDelegatesToEncoder() async throws {
        // Build a stub encoder that records calls.
        actor SpyEncoder: BeepingEncoder {
            var calledWith: [String] = []
            func encode(_ payload: BeepingPayload) async throws {
                calledWith.append(payload.decodedString)
            }
        }

        let spy = SpyEncoder()
        let client = BeepingClient(encoder: spy, mode: .all)
        try await client.send(samplePayload(decoded: "spy00abcd"))
        let recorded = await spy.calledWith
        #expect(recorded == ["spy00abcd"])
        await client.close()
    }
}

// MARK: - URLRequest body helper

private extension URLRequest {
    /// `URLProtocol` exposes the request body via `httpBodyStream` rather
    /// than `httpBody`. This helper reads the stream into Data when
    /// httpBody is nil but a stream was set.
    func bodyStreamData() -> Data? {
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
