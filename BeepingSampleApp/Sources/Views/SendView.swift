import SwiftUI

struct SendView: View {
    @EnvironmentObject var model: AppModel
    @State private var text: String = "hello"

    var body: some View {
        Form {
            Section("Payload") {
                TextField("Text to encode", text: $text)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("send_text_field")
            }
            Section {
                Button {
                    Task { await model.send(text) }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.client == nil || text.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("send_button")
            }
            if let last = model.lastSent {
                Section("Last sent") {
                    Text(last)
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("last_sent_label")
                }
            }
            if let err = model.lastSendError {
                Section("Last send error") {
                    Text(err)
                        .foregroundStyle(.red)
                        .font(.system(.caption, design: .monospaced))
                        .accessibilityIdentifier("last_error_label")
                }
            }
        }
        .navigationTitle("Send")
    }
}
