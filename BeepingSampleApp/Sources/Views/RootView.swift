import SwiftUI

/// Listener-only sample app (BEE-2220). Beeps are produced by a Mac-side
/// `scripts/send-beep.sh` that hits beepbox-server and plays the WAV
/// through the host speakers; this app just demonstrates the SDK's
/// decode pipeline picking them up via mic.
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var showingDebug = false
    @State private var logoTapCount = 0
    @State private var logoTapResetTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                listenerSection
                activitySection
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingDebug) { DebugConsole() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "wave.3.right")
                .font(.title2)
                .foregroundStyle(BeepingBrand.red)
                .accessibilityIdentifier("app_logo")
                .onTapGesture { handleLogoTap() }
            Text("Beeping Sample")
                .font(.headline)
            Spacer()
            Text("listener")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("mode_label")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
    }

    // MARK: - Listener

    private var listenerSection: some View {
        Section {
            HStack(spacing: 8) {
                Circle()
                    .fill(model.isListening ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(model.isListening ? "Listening" : "Idle")
                    .font(.subheadline)
                    .accessibilityIdentifier("listener_status")
                Spacer()
                Text(pipelineLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let payload = model.lastDecoded {
                LabeledContent("decoded", value: payload.decodedString)
                    .font(.system(.subheadline, design: .monospaced))
                    .accessibilityIdentifier("decoded_event_label")
                LabeledContent("key", value: payload.key)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                LabeledContent("confidence", value: String(format: "%.2f", payload.confidence))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else if case .noSignal(let reason) = model.lastDecodeStatus {
                Text(reason)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            } else {
                Text("(no decoded payload yet)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            sectionHeader(symbol: "ear", title: "Listener")
        }
    }

    private var pipelineLabel: String {
        switch model.lastDecodeStatus {
        case .idle:        return "idle"
        case .listening:   return "waiting for valid beep…"
        case .decoded:     return "decoded ✓"
        case .noSignal:    return "no valid signal"
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        Section {
            if model.logs.isEmpty {
                Text("(no events yet)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.logs.suffix(8).reversed()) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(Self.timeFormatter.string(from: entry.timestamp))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text(entry.message)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(entry.level == .error ? .red : .primary)
                            .lineLimit(2)
                    }
                }
            }
        } header: {
            HStack {
                sectionHeader(symbol: "list.bullet.rectangle", title: "Recent activity")
                Spacer()
                Button {
                    showingDebug = true
                } label: {
                    Text("Open console")
                        .font(.caption)
                }
                .accessibilityIdentifier("open_console_button")
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(symbol: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(BeepingBrand.red)
            Text(title)
        }
        .font(.footnote.weight(.semibold))
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private func handleLogoTap() {
        logoTapCount += 1
        logoTapResetTask?.cancel()
        if logoTapCount >= 5 {
            logoTapCount = 0
            showingDebug = true
            return
        }
        logoTapResetTask = Task { [count = logoTapCount] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled, logoTapCount == count {
                logoTapCount = 0
            }
        }
    }
}
