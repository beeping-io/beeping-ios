import SwiftUI

struct EnvPicker: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Menu {
            ForEach(AppEnvironment.allCases) { env in
                Button {
                    model.environment = env
                } label: {
                    HStack {
                        Text(env.displayName)
                        if model.environment == env {
                            Image(systemName: "checkmark")
                        }
                        if !env.isAvailable {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!env.isAvailable)
                .accessibilityIdentifier("env_option_\(env.rawValue)")
            }
        } label: {
            Label(model.environment.displayName, systemImage: "network")
                .labelStyle(.titleAndIcon)
        }
        .accessibilityIdentifier("env_picker")
    }
}
