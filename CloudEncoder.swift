//
//  CloudEncoder.swift
//  Beeping
//
//  `BeepingEncoder` strategy that routes encoding through `beepbox-server`
//  via a plain `URLSession`. The server returns audio bytes that a future
//  task (BEE-73 OpenAPI-generated client) will hand to `AudioEngine` for
//  playback; for BEE-71 we only verify the request succeeded.
//
//  Endpoint contract (preliminary, refined by `beepbox` OpenAPI spec in BEE-73):
//
//    POST {endpoint}/v1/encode
//    Headers:
//      X-API-Key:    <apiKey>
//      Content-Type: application/json
//    Body:
//      { "payload": "<9-char decodedString>" }
//    Response:
//      200 OK + audio/wav body  (BEE-73 will play this)
//      4xx/5xx                  → throws BeepingError.decoderInternal
//
//  `URLSession` is injectable to enable URLProtocol-based mocking in tests
//  without standing up a real backend.
//

import Foundation

internal actor CloudEncoder: BeepingEncoder {
    private let apiKey: String
    private let endpoint: URL
    private let session: URLSession

    internal init(apiKey: String, endpoint: URL, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.session = session
    }

    func encode(_ payload: BeepingPayload) async throws {
        let url = endpoint.appendingPathComponent("v1/encode")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encodeBody(payload: payload)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BeepingError.decoderInternal(reason: "Cloud encode: non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw BeepingError.decoderInternal(
                reason: "Cloud encode: HTTP \(http.statusCode)"
            )
        }
        // BEE-73 will receive the audio bytes here and forward them to
        // AudioEngine for playback. For BEE-71 the contract is just
        // "the server accepted the payload"; the audio path is local-only.
    }

    // MARK: - JSON body

    private static func encodeBody(payload: BeepingPayload) throws -> Data {
        let object: [String: String] = ["payload": payload.decodedString]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
