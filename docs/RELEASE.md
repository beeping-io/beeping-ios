# 🚀 Release & Branch Synchronization Workflow (`beeping-ios`)

> **Normative reference for BEE-2337 / Task #78.**
> Governs git branch topology, release merges, and `Package.swift` distribution.

---

## 🧭 Branch Topology & Merge Invariants

The `beeping-ios` repository follows a strict dual-branch model:

| Branch | Purpose | Protection | Merge Strategy Allowed |
|---|---|---|---|
| `develop` | Active development and integration base | Branch protection + Lefthook | Merge commit / Rebase (feature PRs) |
| `main` | Production releases, tag base for Release Please | Branch protection + Lefthook | **Merge Commit (`--no-ff`) ONLY** |

### ⚠️ Invariant 1: NEVER Squash-Merge `develop ↔ main` Sync PRs
- **Rule**: When merging `develop → main` (release cut) or `main → develop` (back-sync after Release Please tag creation), **Squash Merge is strictly prohibited**.
- **Rationale**: Squash-merging destroys shared history and resets the merge base to early bootstrap, triggering mass false `add/add` conflicts on future merges.
- **Enforcement**: Always select **"Create a merge commit"** (`gh pr merge --merge`).

---

## 📦 Package.swift Dual-Mode Invariant

`Package.swift` operates under an intentional, permanent dual-mode pattern between branches:

### 1. `develop` (Local Development Mode)

```swift
targets: [
    .binaryTarget(
        name: "Beeping",
        path: "dist/Beeping.xcframework"
    )
]
```

- Used for zero-network local building, debugging, and testing in the repository and the in-tree `Examples/SPMConsumer/`.
- Generated locally via `./build.sh`.

### 2. `main` (Public Distribution Mode)

```swift
targets: [
    .binaryTarget(
        name: "Beeping",
        url: "https://github.com/beeping-io/beeping-ios/releases/download/v<version>/Beeping.xcframework.zip",
        checksum: "<sha256-hex>"
    )
]
```

- Managed and rewritten by `release.yml` on tag pushes.
- External Swift Package Manager consumers depend on this `url:checksum:` target.

### 3. Back-Sync Procedure (`main → develop`)

When bringing post-release commits (e.g., Release Please bump, CHANGELOG updates) back from `main` to `develop`:

```bash
git checkout -b chore/sync-vX.Y.Z-to-develop develop
git merge origin/main --no-commit
# Preserve develop's path-based target:
git checkout develop -- Package.swift
git commit -m "chore(sync): bring vX.Y.Z release files back to develop"
gh pr create --base develop --title "chore(sync): bring vX.Y.Z release files back to develop"
# Merge with MERGE COMMIT:
gh pr merge --merge
```
