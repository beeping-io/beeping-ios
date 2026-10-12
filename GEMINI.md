# 🧠 GEMINI.md — `beeping-ios`

> **Component Instructions for Antigravity CLI (`agy`).**
> Location: `/Users/fredi/Workspace/Beeping/beeping-ios/GEMINI.md`.
> Applies to the native iOS SDK (`beeping-ios`) written in Swift 6.

---

## 🎯 What this repo is

The iOS SDK component of the **Beeping Platform** ecosystem. A Swift 6 library exposing a modern actor-based API (`BeepingClient`) to encode and decode short payloads transmitted over sound (audible + ultrasonic), running locally via ObjC++ bridge to `beeping-core` or remotely via the `beepbox` HTTP server.

**Source of truth for scope and timeline**:
- 📄 `docs/PRODUCTO.md` — product specification
- 📅 `docs/ROADMAP.md` — live timeline
- 📜 `docs/ROADMAP_CHANGELOG.md` — append-only history of timeline changes
- 🚀 `docs/RELEASE.md` — release & branch synchronization workflow (BEE-2337 / Task #78)

---

## 🌳 Branch Model & Synchronization Invariants

- `develop` — base development branch.
- `main` — production release branch.
- **NEVER Squash-Merge `develop ↔ main` Sync PRs**: Always merge using **Merge Commit (`--no-ff`)** to maintain ancestor topology and conventional commits for Release Please.
- **Package.swift Dual-Mode**:
  - `develop`: keeps `.binaryTarget(name: "Beeping", path: "dist/Beeping.xcframework")` for zero-network local development and `Examples/SPMConsumer`.
  - `main`: points to `.binaryTarget(name: "Beeping", url: ..., checksum: ...)` for external consumers.

---

## ✏️ Commit Conventions

Conventional Commits with **task ID in the subject**:

```bash
feat(api): #70 BeepingClient actor + AsyncStream<BeepingEvent>
fix(audio): #80 retry on session interruption
chore(sync): #78 reconcile main into develop
docs: #82 document pod spec lint flow
```

---

## 🔨 Build & Test Commands

```bash
# Build framework
xcodebuild build -project Beeping.xcodeproj -scheme Beeping -destination 'generic/platform=iOS Simulator' -configuration Debug -quiet

# Run test suite
xcodebuild test -project Beeping.xcodeproj -scheme Beeping-Tests -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath build/DerivedData -quiet

# Swift format & lint
swift-format lint --recursive .
swiftlint lint --strict
```

---

## 🚫 Things to never do

- ❌ Squash-merge sync PRs between `develop` and `main`.
- ❌ Overwrite `Package.swift` `path:` on `develop` with `url:checksum:`.
- ❌ Use `@unchecked Sendable` to silence strict concurrency warnings — fix the actual data race.
- ❌ Vendor new binaries from anywhere except a pinned `beeping-core` release tag.
- ❌ Hardcode API keys or secrets — always `.env.local` or build args.
- ❌ Skip `🧑‍🔬 Human QA Checkpoint` for any task with observable user or hardware effect.
- ❌ Force-push to `develop` or `main`.
