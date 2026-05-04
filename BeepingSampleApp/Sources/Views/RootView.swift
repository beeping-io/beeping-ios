import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var showingDebug = false
    @State private var logoTapCount = 0
    @State private var logoTapResetTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView {
                SendView()
                    .tabItem { Label("Send", systemImage: "paperplane") }
                    .accessibilityIdentifier("send_tab")
                ReceiveView()
                    .tabItem { Label("Receive", systemImage: "ear") }
                    .accessibilityIdentifier("receive_tab")
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingDebug) { DebugConsole() }
    }

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
            EnvPicker()
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
