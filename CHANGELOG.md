# 📝 Changelog

All notable changes to **`beeping-ios`** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **0.x rule** — While in `0.x` the public API may break between minor bumps.
> Coordinated bump to `1.0.0` happens once the Beeping Platform reaches
> launch readiness (Phase 21). See `docs/PRODUCTO.md`.

---

## [0.2.0](https://github.com/beeping-io/beeping-ios/compare/v0.1.2...v0.2.0) (2026-06-03)


### ⚠ BREAKING CHANGES

* BeepingMode.hidden is removed. Callers selecting .hidden must switch to .nonAudible or .all. Acceptable under the 0.x rule (minor bump).

### Features

* Phase 9 batch — typed errors, traceID, core pin, scheduler decode, full C API, sendScheduled, mode cleanup ([#22](https://github.com/beeping-io/beeping-ios/issues/22)) ([d04eca9](https://github.com/beeping-io/beeping-ios/commit/d04eca9f55692c4b15cdf5ecea51e633bb650264))

## [0.1.2](https://github.com/beeping-io/beeping-ios/compare/v0.1.1...v0.1.2) (2026-05-18)


### Features

* **release:** BEE-2259/2258/2257 Phase 9 stabilization batch ([#14](https://github.com/beeping-io/beeping-ios/issues/14)) ([82c3eba](https://github.com/beeping-io/beeping-ios/commit/82c3ebaaea6f78c15ea2aa8b3f9a9d61c0841e4e))

## [0.1.1](https://github.com/beeping-io/beeping-ios/compare/v0.1.0...v0.1.1) (2026-05-17)


### Bug Fixes

* **release:** Package.swift binaryTarget points at v0.1.0 artifact ([#11](https://github.com/beeping-io/beeping-ios/issues/11)) ([cae6353](https://github.com/beeping-io/beeping-ios/commit/cae63538d1c0f7c90bf082162dae576613a65076))

## [0.1.0](https://github.com/beeping-io/beeping-ios/compare/v0.0.0...v0.1.0) (2026-05-17)


### Features

* **scheduler:** BEE-2241 expose computeBeepSchedule + encodeWithSchedule ([#8](https://github.com/beeping-io/beeping-ios/issues/8)) ([52ed4db](https://github.com/beeping-io/beeping-ios/commit/52ed4db55a2ee6487f1cb4dc795d113e6de83532))


### Bug Fixes

* **ci:** release.yml trigger on push:tags + Package.swift url:checksum: v0.0.0 ([#6](https://github.com/beeping-io/beeping-ios/issues/6)) ([6bf312c](https://github.com/beeping-io/beeping-ios/commit/6bf312cc1486ea6eefd1d9cf9078da3cd18edde8))

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
