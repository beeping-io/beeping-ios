import SwiftUI

struct ReceiveView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Form {
            Section("Listener") {
                HStack {
                    Circle()
                        .fill(model.isListening ? .green : .gray)
                        .frame(width: 10, height: 10)
                    Text(model.isListening ? "Listening…" : "Idle")
                        .accessibilityIdentifier("listener_status")
                    Spacer()
                    Button(model.isListening ? "Stop" : "Start") {
                        if model.isListening {
                            Task { await model.stopListening() }
                        } else {
                            model.startListening()
                        }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("listener_toggle")
                }
            }
            Section("Last decoded") {
                if let payload = model.lastDecoded {
                    LabeledContent("decoded", value: payload.decodedString)
                        .accessibilityIdentifier("decoded_event_label")
                    LabeledContent("key", value: payload.key)
                    LabeledContent("confidence", value: String(format: "%.2f", payload.confidence))
                    LabeledContent("mode", value: "\(payload.mode)")
                } else {
                    Text("(none yet)").foregroundStyle(.secondary)
                }
            }
            Section("Pipeline") {
                switch model.lastDecodeStatus {
                case .idle:
                    Text("Idle — tap Start to listen.")
                        .foregroundStyle(.secondary)
                case .listening:
                    Text("Listening — waiting for valid beep…")
                        .foregroundStyle(.secondary)
                case .decoded:
                    Text("Decoded ✓")
                        .foregroundStyle(.green)
                case .noSignal(let reason):
                    Text("No valid signal yet")
                        .foregroundStyle(.secondary)
                    Text(reason)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Receive")
    }
}
