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
//  BEE-2050 wires the response WAV through `WAVPlaybackSink` so the
//  bytes are actually rendered to the speaker — that completes the
//  Send → audio → Receive round-trip for cloud mode. The sink defaults
//  to `AVAudioPlayerSink`; tests inject a spy.
//

import Foundation

internal actor CloudEncoder: BeepingEncoder {
    private let apiKey: String
    private let endpoint: URL
    private let session: URLSession
    private let playbackSink: any WAVPlaybackSink
    private let mode: BeepingMode
    /// Optional in-app loopback decoder. When set, the WAV bytes are
    /// fed through it after playback so the listener emits a `.decoded`
    /// event for the cloud-emitted beep without needing speaker→mic
    /// acoustic round-trip (which doesn't loop on iOS Simulator).
    /// `BeepingClientBuilder` wires this up automatically with the
    /// listener's wrapper so events flow through the same stream.
    private let loopbackWrapper: BeepingCoreWrapper?

    internal init(
        apiKey: String,
        endpoint: URL,
        session: URLSession = .shared,
        playbackSink: (any WAVPlaybackSink)? = nil,
        mode: BeepingMode = .all,
        loopbackWrapper: BeepingCoreWrapper? = nil
    ) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.session = session
        self.playbackSink = playbackSink ?? AVAudioPlayerSink()
        self.mode = mode
        self.loopbackWrapper = loopbackWrapper
    }

    func encode(_ payload: BeepingPayload) async throws {
        let url = endpoint.appendingPathComponent("v1/encode")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encodeBody(payload: payload, mode: mode)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BeepingError.decoderInternal(reason: "Cloud encode: non-HTTP response")
        }

        guard (200..<300).contains(http.statusCode) else {
            throw Self.mapErrorResponse(status: http.statusCode, body: data)
        }

        // BEE-2050: hand the response WAV to the playback sink so the
        // device renders it through the speaker. Default sink is
        // `AVAudioPlayerSink`; tests inject a spy.
        try await playbackSink.play(wavData: data)

        // BEE-2050: feed the same WAV through a dedicated decoder on
        // the listener's wrapper so the local stream emits a `.decoded`
        // event in the same app, even on iOS Simulator where the mic
        // doesn't loop back from the speaker. On a physical device this
        // also fires synchronously alongside whatever the mic decodes
        // through the air — both arrive at the consumer's stream.
        loopbackWrapper?.decodeLoopback(wav: data, mode: mode)
    }

    // MARK: - Helpers

    private static let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let jsonDecoder = JSONDecoder()

    private static func encodeBody(payload: BeepingPayload, mode: BeepingMode) throws -> Data {
        // The OpenAPI spec takes a 5-char `key`. BeepingPayload exposes
        // `key` directly; the 9-char `decodedString` is metadata-y (key
        // + 4-char base32 timestamp) used by the local engine but
        // server-side the timestamp is generated server-side.
        //
        // Mode propagation: server defaults to `inaudible` if the field
        // is omitted (~17.8 kHz carrier), which most laptop speakers
        // can't reproduce. Map the SDK's `BeepingMode` to the server's
        // smaller enum so the builder's `.mode(...)` reaches the wire.
        let body = EncodeRequest(key: payload.key, mode: serverMode(from: mode))
        return try jsonEncoder.encode(body)
    }

    private static func serverMode(from mode: BeepingMode) -> EncodeRequest.Mode {
        switch mode {
        case .audible, .audibleOld:    return .audible
        case .nonAudible, .nonAudibleOld, .hidden: return .inaudible
        case .all, .custom:            return .all
        }
    }

    private static func mapErrorResponse(status: Int, body: Data) -> BeepingError {
        // 400 = validation; 429/500 = generic. Try the validation shape
        // first, fall back to the generic shape, fall back to a raw
        // status-code message.
        if let validation = try? jsonDecoder.decode(ValidationErrorResponse.self, from: body),
            validation.error != nil || (validation.errors?.isEmpty == false)
        {
            return .decoderInternal(reason: "Cloud encode HTTP \(status): \(validation.displayMessage)")
        }
        if let generic = try? jsonDecoder.decode(ErrorResponse.self, from: body) {
            let hint = generic.hint.map { " (\($0))" } ?? ""
            return .decoderInternal(reason: "Cloud encode HTTP \(status): \(generic.error)\(hint)")
        }
        return .decoderInternal(reason: "Cloud encode HTTP \(status): no parseable error body")
    }
}
