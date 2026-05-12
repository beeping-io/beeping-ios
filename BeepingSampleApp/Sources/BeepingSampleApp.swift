import SwiftUI
import Foundation

@main
struct BeepingSampleApp: App {
    @StateObject private var appModel: AppModel

    init() {
        Self.prepareWritableLogsDirectory()
        _appModel = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .tint(BeepingBrand.red)
        }
    }

    /// `beeping-core` (C++) auto-initializes spdlog with a relative path
    /// `logs/beeping.log` and crashes in the iOS sandbox. Workaround: chdir
    /// to a writable Documents-rooted location and pre-create `logs/`.
    private static func prepareWritableLogsDirectory() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logs = docs.appendingPathComponent("logs", isDirectory: true)
        try? fm.createDirectory(at: logs, withIntermediateDirectories: true)
        _ = fm.changeCurrentDirectoryPath(docs.path)
    }
}
