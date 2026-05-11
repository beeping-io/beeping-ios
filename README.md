# 🍎 Beeping iOS SDK

![License](https://img.shields.io/badge/License-Apache_2.0-blue)
![status](https://img.shields.io/badge/status-early_development-orange)
![platform](https://img.shields.io/badge/platform-Beeping-7C3AED)
![conventional commits](https://img.shields.io/badge/conventional_commits-1.0.0-yellow)
![Swift target](https://img.shields.io/badge/Swift_target-6.0+-F05138)
![Xcode target](https://img.shields.io/badge/Xcode_target-16+-1575F9)
![iOS target](https://img.shields.io/badge/iOS_target-15.0+-000000)

> 🔊 Swift SDK for **data over sound** (audible + ultrasonic) on iOS.
> Decode and emit short payloads via the device speaker/microphone, locally
> or through the Beeping Platform cloud.
> Part of the [Beeping Platform](https://github.com/beeping-io) ecosystem.

---

## 🚧 Status

**Early development — repository bootstrapped on 2026-04-28.**

The codebase currently contains **legacy ObjC sources** (Beeping wrapper,
BeepingCore, BeepingEvent, IosAudioController, vendored `libBeepingCoreUniversal.a`).
This is the starting point — **the modernized SDK is not yet consumable**.

The full migration to Swift 6 + Swift Package Manager + signed XCFramework
distribution is tracked in **Phase 9** of the Beeping Platform Linear project
(milestone 🍎 Phase 9, 16 tasks BEE-67..BEE-82, 94 story points). See
[`docs/PRODUCTO.md`](docs/PRODUCTO.md) for the full scope and
[`docs/ROADMAP.md`](docs/ROADMAP.md) for the live timeline.

The target public API is documented below for reference, but **not yet
implemented** — track Phase 9 progress for availability.

---

## 📦 Installing via Swift Package Manager

The SDK ships as a Swift Package primary distribution (BEE-80). The
package vends a single `Beeping` library backed by a pre-built
`.binaryTarget` — consumers don't need to compile the C engine or
ObjC++ bridge themselves.

For local development against this repository:

1. Clone the repo and build the XCFramework:

   ```bash
   ./build.sh
   ```

   That populates `dist/Beeping.xcframework` (gitignored, ~5 MB), which
   is what the root `Package.swift` resolves with its `.binaryTarget`.

2. Add a local-path dependency from your consumer:

   ```swift
   .package(path: "../beeping-ios")
   ```

   Then add `.product(name: "Beeping", package: "beeping-ios")` to your
   target's dependencies and `import Beeping`.

A minimal smoke consumer lives in [`Examples/SPMConsumer`](Examples/SPMConsumer) — run
`./scripts/test-spm-consumer.sh` from the repo root to build it end to end.

> Remote `url:checksum:` consumption (i.e. `.package(url: "https://github.com/beeping-io/beeping-ios", from: ...)`)
> lands in **BEE-82** once release-please publishes signed GitHub Releases.

---

## 🎯 Target API (post-Phase 9)

```swift
import Beeping

let client = BeepingClient(
    mode: .local                                    // or .cloud(apiKey: "...", endpoint: URL(...)!)
)

// Listen for incoming beeps
Task {
    for await event in await client.listen() {
        switch event {
        case .started:                              break  // session up
        case .decoded(let payload):                 handle(payload)
        case .failed(let reason):                   handle(reason)
        case .stopped:                              break  // session closed
        }
    }
}

// Encode + emit (async)
let pcm = try await client.encode("HOLA1")
try await client.play(pcm)

await client.stop()
```

See [`docs/PRODUCTO.md`](docs/PRODUCTO.md) section 10 for the full flow and
section 11 for state/error semantics.

---

## 📁 Repository structure

| Path | Purpose | Phase 9 owner |
|---|---|---|
| `Beeping.h` / `Beeping.m` | Legacy ObjC public wrapper (singleton + delegate) | BEE-68 (Swift 6 rewrite), BEE-70 (new actor API) |
| `BeepingCore/` | Legacy ObjC core wrapper (`BeepingCore.h/.m`, `AppDelegate.h/.m`) | BEE-68 (rewrite to internal `BeepingC` ObjC++ bridge), BEE-71 (strategy pattern) |
| `BeepingEvent.h` / `.m` | Legacy ObjC payload model | BEE-68 (Swift `BeepingPayload` struct) |
| `IosAudioController.h` / `.m` | Legacy ObjC audio session manager | BEE-68 (internal Swift actor) |
| `BeepingCoreLib_api.h` | C API of `beeping-core` (consumed by ObjC++ bridge) | preserved (consumed from `beeping-core` GH releases post-BEE-79) |
| `libBeepingCoreUniversal.a` | Vendored native lib (universal binary, **temporary**) | BEE-79 (drop, consume from `beeping-core` releases) |
| `Beeping.xcodeproj/` | Xcode project | BEE-69 (iOS 15 min + PrivacyInfo.xcprivacy), BEE-80 (SPM Package.swift) |
| `BeepingCoreTests/` | Legacy XCTest suite | BEE-76 (XCTest + Swift Testing + snapshot + property) |
| `build.sh` | Convenience build script (legacy → XCFramework) | superseded by BEE-80 (SPM-driven) |
| `Info.plist` | Bundle plist | BEE-69 (PrivacyInfo.xcprivacy companion) |
| `docs/PRODUCTO.md` | Product spec — source of truth for Phase 9 | — |
| `docs/ROADMAP.md` | Live timeline (recalculated on every closed task) | — |
| `docs/ROADMAP_CHANGELOG.md` | Append-only history of timeline changes | — |
| `docs/IDEAS.md` | Cross-project ideas capture | — |
| `docs/PENDING.md` | Cross-project pending capture | — |
| `scripts/` | Helper scripts (`validate_docs.sh`, `validate_repo.sh`) | preserved |
| `.github/workflows/` | CI/CD (added in Paso 5) | BEE-77 (lint), BEE-76 (tests), BEE-82 (release) |

---

## 🔧 Building (current legacy stack)

> Until BEE-80 introduces SPM as the primary build, the project uses Xcode + a
> convenience shell script.

```bash
# Generate Beeping.xcframework (Release, device + simulator)
./build.sh

# Variables opcionales
CONFIGURATION=Debug ./build.sh
PROJECT_PATH=/path/to/Beeping.xcodeproj ./build.sh
SCHEME=Beeping ./build.sh
FRAMEWORK_NAME=Beeping ./build.sh
```

Outputs:

- XCFramework: `dist/Beeping.xcframework`
- Test reports: via `xcodebuild test` (run `xcodebuild test -project Beeping.xcodeproj -scheme Beeping -destination 'platform=iOS Simulator,name=iPhone 15'`)

---

## 🧪 Development gates (target)

Real config lands in Phase 9. Targets per `docs/PRODUCTO.md` section 12:

- **Lint**: SwiftLint + swift-format strict, **0 warnings** (BEE-77)
- **Tests**: XCTest + Swift Testing + swift-snapshot-testing + SwiftCheck property (BEE-76)
- **Coverage**: ≥80% line on target `Beeping`
- **Strict concurrency**: 0 warnings with `-strict-concurrency=complete`
- **CI**: GitHub Actions, full pipeline < 12 min

---

## 🌐 Ecosystem

`beeping-ios` is one of ~18 components of the Beeping Platform.

| Component | Repo | Role |
|---|---|---|
| Core C++ library | [`beeping-core`](https://github.com/beeping-io/beeping-core) | Encoding/decoding C++ engine; emits XCFramework for iOS |
| Cloud HTTP server | [`beepbox`](https://github.com/beeping-io/beepbox) | Beeping Platform cloud API (consumed by Cloud mode) |
| Android SDK | [`beeping-android`](https://github.com/beeping-io/beeping-android) | Android counterpart (Phase 8) |
| Flutter plugin | (Phase 10) | Wraps both Android + iOS |
| React Native | (Phase 12) | Wraps both Android + iOS |
| Reference apps | [`beeply`](https://github.com/beeping-io/beeply) | Flutter reference app |
| Governance | [`beeping-meta`](https://github.com/beeping-io/beeping-meta) | Conventions, ADRs, brand, terraform |

---

## 🤝 Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Conventions, branch model and PR
rules are shared ecosystem-wide via
[`beeping-io/beeping-meta`](https://github.com/beeping-io/beeping-meta).

## 🔒 Security

See [`SECURITY.md`](SECURITY.md). **Do not open public issues for vulnerabilities.**

## 📜 License

Apache License 2.0 — see [`LICENSE`](LICENSE).
