import Foundation
import SwiftUI
import Beeping

@MainActor
final class AppModel: ObservableObject {

    @Published var environment: AppEnvironment = .local {
        didSet { rebuildClient() }
    }

    @Published private(set) var client: BeepingClient?
    @Published private(set) var lastDecoded: BeepingPayload?
    @Published private(set) var lastSendError: String?
    @Published private(set) var lastDecodeStatus: DecodeStatus = .idle
    @Published private(set) var lastSent: String?
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
        client = environment.makeClient()
        isListening = false
        append(.info, "env=\(environment.rawValue) client=\(client == nil ? "nil" : "ok")")
        // Auto-start the listener — the test surface is "always listening".
        // Send-then-decode is the natural loop and the user shouldn't have
        // to toggle it manually.
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
        // happens in an idle simulator.
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

    func send(_ text: String) async {
        guard let client else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let payload = BeepingPayload(
            key: "samp1",
            decodedString: trimmed.padding(toLength: 9, withPad: " ", startingAt: 0),
            mode: Int(BeepingMode.audible.rawValue),
            timestamp: Int(Date().timeIntervalSince1970),
            confidence: 1.0,
            confidenceError: 0.0,
            confidenceNoise: 0.0,
            receivedBeepsVolume: 0.0
        )
        append(.info, "send → \"\(trimmed)\" via \(environment.rawValue)")
        do {
            try await client.send(payload)
            lastSent = trimmed
            lastSendError = nil
            append(.info, "sent OK")
        } catch {
            lastSendError = "\(error)"
            append(.error, "send failed: \(error)")
        }
    }

    private func handle(_ event: BeepingClient.Event) {
        switch event {
        case .started:
            lastDecodeStatus = .listening
            append(.info, "event: started")
        case .decoded(let payload):
            lastDecoded = payload
            lastDecodeStatus = .decoded
            append(.info, "event: decoded \"\(payload.decodedString)\" conf=\(String(format: "%.2f", payload.confidence))")
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
