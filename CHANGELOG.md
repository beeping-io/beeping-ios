# 📝 Changelog

All notable changes to **`beeping-ios`** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **0.x rule** — While in `0.x` the public API may break between minor bumps.
> Coordinated bump to `1.0.0` happens once the Beeping Platform reaches
> launch readiness (Phase 21). See `docs/PRODUCTO.md`.

---

## 0.0.0 (2026-05-12)


### Features

* **milestone:** Phase 9 — beeping-ios (Swift 6) — 18 tasks, 104 SP ([#2](https://github.com/beeping-io/beeping-ios/issues/2)) ([9cbe017](https://github.com/beeping-io/beeping-ios/commit/9cbe0179327e98cd9c19b4f50f87899c6d445855))


### Bug Fixes

* **ci:** pin release-please target-branch to main ([#4](https://github.com/beeping-io/beeping-ios/issues/4)) ([28225e1](https://github.com/beeping-io/beeping-ios/commit/28225e1baaf1a33dc1609399e43ac971186f1838))

## [Unreleased]

### Added

- Bootstrap of the repository under `beeping-io/beeping-ios` (2026-04-28).
- `docs/PRODUCTO.md` — product spec, scope of Phase 9 (16 tasks, 94 SP).
- `docs/ROADMAP.md` + `docs/ROADMAP_CHANGELOG.md` — live timeline.
- `docs/IDEAS.md` + `docs/PENDING.md` — cross-project capture (canonical template).
- Apache-2.0 LICENSE.
- Conventional Commits + Keep a Changelog conventions adopted.

### Notes

- Repository starts at version `0.0.0` per the Beeping ecosystem `0.x` rule.
- Existing source is **legacy ObjC SDK** (Beeping wrapper + BeepingCore + BeepingEvent
  + IosAudioController + vendored `libBeepingCoreUniversal.a` 18 MB) preserved
  as starting point.
- Modernization to Swift 6 + SPM primary + signed XCFramework happens task-by-task
  in Phase 9 (BEE-67..BEE-82).
