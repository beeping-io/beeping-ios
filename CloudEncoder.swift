//
//  CloudEncoder.swift
//  Beeping
//
//  `BeepingEncoder` strategy that routes encoding through `beepbox-server`
//  via `URLSession`. Type-safe Codable types live in
//  `BeepboxAPITypes.swift` and mirror the OpenAPI spec at
//  `OpenAPI/openapi.yaml` (vendored from `beepbox-server`).
//
//  Endpoint contract (per spec):
//
//    POST {endpoint}/v1/encode
//    Headers:
//      Authorization: Bearer <apiKey>           (Apple HTTP scheme bearer)
//      Content-Type:  application/json
//    Body:
//      EncodeRequest { key, mode?, sampleRate?, duration?, start?,
//                      interval?, volumeBeeps? }
//    Responses:
//      200 audio/wav          → server accepted; body is the encoded WAV
//      400 ValidationErrorResponse
//      429/500 ErrorResponse
//
//  In BEE-73 we don't yet hand the response audio bytes to AudioEngine
//  for playback — that wiring is a follow-up task. BEE-71 documented the
//  intent; BEE-73 ships the corrected contract and Codable types so the
//  next step can plug in playback against the right shape.
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encodeBody(payload: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BeepingError.decoderInternal(reason: "Cloud encode: non-HTTP response")
        }

        guard (200..<300).contains(http.statusCode) else {
            throw Self.mapErrorResponse(status: http.statusCode, body: data)
        }

        // BEE-73 stops here — `data` holds the audio/wav bytes returned
        // by the server. Playing it back through AudioEngine is a
        // follow-up task; for now the contract is "the server accepted".
        _ = data
    }

    // MARK: - Helpers

    private static let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let jsonDecoder = JSONDecoder()

    private static func encodeBody(payload: BeepingPayload) throws -> Data {
        // The OpenAPI spec takes a 5-char `key`. BeepingPayload exposes
        // `key` directly; the 9-char `decodedString` is metadata-y (key
        // + 4-char base32 timestamp) used by the local engine but
        // server-side the timestamp is generated server-side.
        let body = EncodeRequest(key: payload.key)
        return try jsonEncoder.encode(body)
    }

    private static func mapErrorResponse(status: Int, body: Data) -> BeepingError {
        // 400 = validation; 429/500 = generic. Try the validation shape
        // first, fall back to the generic shape, fall back to a raw
        // status-code message.
        if let validation = try? jsonDecoder.decode(ValidationErrorResponse.self, from: body),
           validation.error != nil || (validation.errors?.isEmpty == false) {
            return .decoderInternal(reason: "Cloud encode HTTP \(status): \(validation.displayMessage)")
        }
        if let generic = try? jsonDecoder.decode(ErrorResponse.self, from: body) {
            let hint = generic.hint.map { " (\($0))" } ?? ""
            return .decoderInternal(reason: "Cloud encode HTTP \(status): \(generic.error)\(hint)")
        }
        return .decoderInternal(reason: "Cloud encode HTTP \(status): no parseable error body")
    }
}
