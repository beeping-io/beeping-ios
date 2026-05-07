import Foundation
import SwiftUI
import Beeping

/// Listener-only state for the sample app. The send path moved out of
/// the app entirely (BEE-2220): a Mac-side `scripts/send-beep.sh` calls
/// `beepbox-server`, gets a WAV, and plays it through the host speakers.
/// The simulator/device's mic captures it and the SDK's `BeepingClient`
/// decodes — that's the round-trip we demonstrate. The SDK still ships
/// the encode side (`BeepingClient.local()` / `.cloud(...)` factories
/// remain in the public API) — this sample just exercises decode.
@MainActor
final class AppModel: ObservableObject {

    @Published private(set) var client: BeepingClient?
    @Published private(set) var lastDecoded: BeepingPayload?
    @Published private(set) var lastDecodeStatus: DecodeStatus = .idle
    @Published private(set) var isListening: Bool = false
    @Published private(set) var logs: [LogEntry] = []

    private var listenTask: Task<Void, Never>?

    init() {
        rebuildClient()
    }

    func rebuildClient() {
        listenTask?.cancel()
        listenTask = nil
        if let oldClient = client {
            Task { await oldClient.close() }
        }
        client = BeepingClient.local().build()
        isListening = false
        append(.info, "client=\(client == nil ? "nil" : "ok")")
        if client != nil {
            startListening()
        }
    }

    func startListening() {
        guard let client else { return }
        guard listenTask == nil else { return }
        isListening = true
        // Optimistically reflect the listening state. The C engine only
        // emits `.started` once it processes its first token, which never
        // happens in an idle simulator without input.
        if lastDecodeStatus == .idle { lastDecodeStatus = .listening }
        append(.info, "listening started")
        listenTask = Task { [weak self, client] in
            let stream = await client.listen()
            for await event in stream {
                await MainActor.run { self?.handle(event) }
            }
        }
    }

    func stopListening() async {
        listenTask?.cancel()
        listenTask = nil
        if let client { await client.close() }
        isListening = false
        append(.info, "listening stopped")
    }

    private func handle(_ event: BeepingClient.Event) {
        switch event {
        case .started:
            lastDecodeStatus = .listening
            append(.info, "event: started")
        case .decoded(let payload):
            lastDecoded = payload
            lastDecodeStatus = .decoded
            append(
                .info,
                "event: decoded \"\(payload.decodedString)\" "
                    + "conf=\(String(format: "%.2f", payload.confidence))")
        case .failed(let err):
            // The decoder emits endBad whenever the mic captures audio with
            // valid start/end markers but invalid payload (very common in
            // simulator with no real mic). Surface as "no signal", not as
            // a fatal error.
            lastDecodeStatus = .noSignal(reason: "\(err)")
            append(.info, "event: failed \(err)")
        case .stopped:
            lastDecodeStatus = .idle
            append(.info, "event: stopped")
        @unknown default:
            append(.info, "event: unknown")
        }
    }

    private func append(_ level: LogEntry.Level, _ message: String) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        logs.append(entry)
        if logs.count > 500 { logs.removeFirst(logs.count - 500) }
    }

    func clearLogs() { logs.removeAll() }
}

struct LogEntry: Identifiable, Sendable {
    enum Level: String, Sendable { case info, error }
    let id = UUID()
    let timestamp: Date
    let level: Level
    let message: String
}

/// Status of the receive pipeline. `noSignal` is the common case in the
/// simulator (mic captures silence + noise → decoder fails parity → endBad)
/// and is shown as muted info, not a red error.
enum DecodeStatus: Equatable, Sendable {
    case idle
    case listening
    case decoded
    case noSignal(reason: String)
}
