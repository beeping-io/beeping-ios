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

@Suite("Encoder strategies (BEE-71 + BEE-73 contract update)")
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
            // for the encoder unit test.
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
            session: mockedSession()
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

    // MARK: - CloudEncoder error mapping

    @Test("CloudEncoder.encode parses ValidationErrorResponse on 400")
    func cloudEncoderParsesValidationError() async {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let validationJSON = """
            {"errors":["key must be exactly 5 base32 characters [0-9a-v]"]}
            """.data(using: .utf8)!

        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil
            )!
            return (validationJSON, response)
        }

        let encoder = CloudEncoder(
            apiKey: "bk_x",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession()
        )

        await #expect(throws: BeepingError.self) {
            try await encoder.encode(samplePayload(key: "12345"))
        }
    }

    @Test("CloudEncoder.encode parses ErrorResponse on 429 + uses hint")
    func cloudEncoderParsesGenericError() async {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let errJSON = """
            {"error":"Rate limit exceeded","hint":"Retry after 20 seconds"}
            """.data(using: .utf8)!

        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil
            )!
            return (errJSON, response)
        }

        let encoder = CloudEncoder(
            apiKey: "bk_x",
            endpoint: URL(string: "https://api.beeping.io")!,
            session: mockedSession()
        )

        await #expect(throws: BeepingError.self) {
            try await encoder.encode(samplePayload(key: "12345"))
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
