import SwiftUI

struct DebugConsole: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.logs.reversed()) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Text(Self.timeFormatter.string(from: entry.timestamp))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text(entry.level.rawValue.uppercased())
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(entry.level == .error ? .red : .blue)
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("debug_close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Clear", role: .destructive) { model.clearLogs() }
                        ShareLink(item: dumpedLogs())
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("debug_menu")
                }
            }
        }
        .accessibilityIdentifier("debug_console_sheet")
    }

    private func dumpedLogs() -> String {
        model.logs
            .map { "\(Self.timeFormatter.string(from: $0.timestamp)) [\($0.level.rawValue)] \($0.message)" }
            .joined(separator: "\n")
    }
}
