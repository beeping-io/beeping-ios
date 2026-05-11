//
//  PodConsumerApp.swift
//
//  Minimal SwiftUI app that proves `import Beeping` resolves through
//  the CocoaPods `Beeping.podspec` (BEE-81). Build success of the
//  workspace is the pass condition — no runtime gating, since the
//  smoke check just constructs a client and closes it without taking
//  the mic.
//

import SwiftUI
import Beeping

@main
struct PodConsumerApp: App {

    init() {
        Self.runSmokeCheck()
    }

    var body: some Scene {
        WindowGroup {
            VStack {
                Image(systemName: "wave.3.right")
                    .font(.largeTitle)
                Text("Pod Consumer")
                    .font(.headline)
                Text("Beeping pod resolved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    /// Reach into the SDK's public surface so the linker has to actually
    /// resolve the vendored framework — otherwise dead-code elimination
    /// could let a broken pod still build.
    private static func runSmokeCheck() {
        let client = BeepingClient
            .local()
            .mode(.audible)
            .logLevel(.info)
            .build()
        Task { await client.close() }
    }
}
