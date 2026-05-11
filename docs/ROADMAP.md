# 📅 ROADMAP — `beeping-ios`

> **Living document.** Updated on every Linear task closure (per global methodology
> `~/.claude/CLAUDE.md` → `/worktree-start` Paso 7). Any edit here triggers a
> companion entry in [`docs/ROADMAP_CHANGELOG.md`](./ROADMAP_CHANGELOG.md).

---

## 🎯 Snapshot

| Field | Value |
|---|---|
| **Project start** | 2026-04-28 (Tue) |
| **Velocity assumed** | 8 story points / working day |
| **Risk margin** | 20% (i.e. 10 SP·days planned as 12 calendar days) |
| **Total SP committed** | 104 SP across 18 tasks (BEE-2050 + BEE-2220 scope additions) |
| **Raw effort** | 104 SP / 8 SP·day = ~13.0 working days |
| **Effort with margin** | ~15.6 working days → **16 working days rounded** |
| **Estimated end date** | **2026-05-18 (Mon)** |
| **Global status** | ✅ En tiempo (buffer ~5 días) |
| **Last update** | 2026-05-11 (Closed BEE-2050 + BEE-2220 — CloudEncoder WAV playback + sample app QA pivot; net delta 0 days) |

---

## 📍 Active milestone — 🍎 Phase 9 — beeping-ios (Swift 6)

- **Linear ID**: `3b2f36a8-b6e7-4202-8748-1a8c8ec65d21`
- **Story points**: 104 (18 tasks; **73 SP closed**, 31 SP remaining; BEE-2050 + BEE-2220 scope additions)
- **Start**: 2026-04-28 (Tue)
- **End estimate**: 2026-05-18 (Mon)
- **Status**: ✅ En tiempo (14/18 tasks closed — BEE-67..BEE-75 + BEE-77 + BEE-78 + BEE-79 + BEE-2050 + BEE-2220; BEE-76 deferred to end-of-milestone)

### Per-task projections

> Calendar dates assume a strict sequential lineal execution at 8 SP/day with 20% margin.
> When tasks run in parallel or out of order the actual dates will diverge —
> recalculation happens at every task closure.

| Order | Linear | SP | Title | Est. start | Est. end | Status |
|---|---|---|---|---|---|---|
| 1 | BEE-67 | 2 | 🏷️ Rename + Apache-2.0 + Conventional Commits | 2026-04-28 | 2026-04-28 | ✅ **DONE** |
| 2 | BEE-68 | 13 | 🔄 ObjC → Swift 6 + strict concurrency | 2026-04-28 | 2026-04-29 | ✅ **DONE** |
| 3 | BEE-69 | 3 | 🔒 iOS 15 min + PrivacyInfo.xcprivacy | 2026-04-30 | 2026-04-30 | ✅ **DONE** |
| 4 | BEE-70 | 8 | 🌊 BeepingClient actor + AsyncStream | 2026-04-30 | 2026-04-30 | ✅ **DONE** |
| 5 | BEE-71 | 8 | 🎭 Strategy: LocalEncoder + CloudEncoder | 2026-04-30 | 2026-04-30 | ✅ **DONE** |
| 6 | BEE-72 | 3 | 🛠️ Builder DSL `.local()` / `.cloud(...)` | 2026-04-30 | 2026-04-30 | ✅ **DONE** |
| 7 | BEE-73 | 3 | 🔌 Cliente HTTP via swift-openapi-generator | 2026-04-30 | 2026-04-30 | ✅ **DONE (partial — generator deferred to BEE-80)** |
| 8 | BEE-74 | 3 | 🪵 Logging os.Logger + trace-ID | 2026-05-01 | 2026-05-01 | ✅ **DONE** |
| 9 | BEE-75 | 5 | 📡 Telemetry hook + privacy tests | 2026-05-01 | 2026-05-01 | ✅ **DONE** |
| 10 | BEE-76 | 13 | 🧪 Tests XCTest + Swift Testing + snapshot + property | DEFERRED | (post BEE-79/80) | ⏸️ DEFERRED |
| 11 | BEE-77 | 2 | 🧼 SwiftLint + swift-format en CI | 2026-05-01 | 2026-05-01 | ✅ **DONE** |
| 12 | BEE-78 | 8 | 📱 Sample app SwiftUI + debug console | 2026-05-04 | 2026-05-04 | ✅ **DONE** |
| 13 | BEE-79 | 5 | 🔗 Consumir beeping-core via GH Releases | 2026-05-01 | 2026-05-01 | ✅ **DONE (partial — local rebuild bridge; full upstream fetch pending BEE-82)** |
| 14 | BEE-80 | 8 | 📦 SPM Package.swift + XCFramework firmado | 2026-05-15 | 2026-05-18 | ⚠️ |
| 15 | BEE-81 | 5 | 🍫 CocoaPods podspec | 2026-05-18 | 2026-05-18 | ⚠️ |
| 16 | BEE-82 | 5 | 🚀 release-please + cosign + GH Releases | 2026-05-18 | 2026-05-18 | ⚠️ |
| 17 | BEE-2050 | 5 | 🔊 CloudEncoder WAV playback (consume server response audio) | 2026-05-05 | 2026-05-06 | ✅ **DONE** |
| 18 | BEE-2220 | 5 | 🧪 QA pivot: listener-only sample app + send-beep.sh host-side encoder | 2026-05-07 | 2026-05-11 | ✅ **DONE** |
|   | **104** | | | | | |

### Risk indicators per task

- **✅** — within plan + margin, no immediate concerns.
- **⚠️** — scheduled at the tail of the milestone (consume the 20% margin); medium risk: a single overrun cascades.
- **❌** — overrun beyond margin, blocks downstream tasks or other phases.

The last 3 tasks (BEE-80, BEE-81, BEE-82) consume the final margin window and depend on **R1** (Phase 1 `beeping-core` releases) per `docs/PRODUCTO.md` section 19.

---

## ⚡ Risk register (live — synced with `docs/PRODUCTO.md` section 19)

| # | Risk | P | I | Status |
|---|---|---|---|---|
| R1 | `beeping-core` releases delay (BEE-79 dep) | 🟡 Media | 🔴 Alto | 🟢 Open, monitored |
| R2 | Apple notarization $99/year cost | 🔴 Alta | 🟢 Bajo | 🟢 Skip notarization for v0.x |
| R3 | Swift 6 strict concurrency refactors deeper than estimated | 🔴 Alta | 🟡 Medio | 🟢 BEE-68 spike planned |
| R4 | swift-openapi-generator API churn (still pre-1.0) | 🟡 Media | 🟡 Medio | 🟢 Pinned minor version |
| R5 | Telemetry opt-out edge cases leak data | 🟢 Baja | 🔴 Alto | 🟢 BEE-75 includes privacy tests |
| R6 | Legacy ObjC API consumers downstream break | 🟢 Baja | 🟢 Bajo | 🟢 No active downstream consumers |
| R7 | CocoaPods vs SPM XCFramework drift | 🟡 Media | 🟡 Medio | 🟢 Single-source XCFramework via GH Releases |
| R8 | Xcode 16 minimum excludes legacy dev environments | 🟢 Baja | 🟢 Bajo | 🟢 Documented in README |

P = probability · I = impact · 🟢 = on track · 🟡 = monitor · 🔴 = action required

---

## 📈 Velocity tracking

| Date | SP closed (cum.) | SP remaining | SP·day actual | Notes |
|---|---|---|---|---|
| 2026-04-28 | 0 / 94 | 94 | — | Initial bootstrap |
| 2026-04-28 | 2 / 94 | 92 | 2.0 (day 1) | BEE-67 closed in plan; cumulative velocity = 2.0 SP/day (single day, partial) |
| 2026-04-29 | 15 / 94 | 79 | 13.0 (day 2) | BEE-68 closed in plan in 8 phases over days 1-2; cumulative velocity = 7.5 SP/day across 2 working days |
| 2026-04-30 | 18 / 94 | 76 | 3.0 (day 3) | BEE-69 closed in plan (most work was already done by BEE-68 Fase 1 inheriting iOS 15 setting); cumulative velocity = 6.0 SP/day across 3 working days |
| 2026-04-30 | 26 / 94 | 68 | +8.0 (day 3 cont.) | BEE-70 closed in plan, same day as BEE-69; cumulative velocity = 8.7 SP/day across 3 working days — ahora ligeramente por encima del asumido 8 SP/día |
| 2026-04-30 | 34 / 94 | 60 | +8.0 (day 3 cont.) | BEE-71 closed in plan, same day as BEE-69+BEE-70 (productive day); cumulative velocity = 11.3 SP/day across 3 working days — buffer creciente |
| 2026-04-30 | 37 / 94 | 57 | +3.0 (day 3 cont.) | BEE-72 closed in plan, same day as BEE-69+70+71 (4 tasks day 3 — record); cumulative velocity = 12.3 SP/día — buffer ~5+ días |
| 2026-04-30 | 40 / 94 | 54 | +3.0 (day 3 cont.) | BEE-73 closed in plan, **5 tasks closed day 3** (BEE-69+70+71+72+73). Generator integration deferred to BEE-80 (requires Package.swift); BEE-73 entrega contrato corregido + Codable types hand-mirrored. Cumulative velocity = 13.3 SP/día |
| 2026-05-01 | 43 / 94 | 51 | 3.0 (day 4) | BEE-74 closed in plan — **half-milestone reached** (8/16 tasks). os.Logger wrapper + 7-level enum + trace-ID propagation. Cumulative velocity = 10.75 SP/día across 4 days |
| 2026-05-01 | 48 / 94 | 46 | +5.0 (day 4 cont.) | BEE-75 closed in plan — telemetry infrastructure (TelemetryClient actor + TelemetryHook protocol + 12 privacy tests). Cumulative velocity = 12.0 SP/día across 4 days |
| 2026-05-01 | 50 / 94 | 44 | +2.0 (day 4 cont.) | BEE-77 closed in plan — SwiftLint + swift-format CI gates. Auto-formatted 16 .swift files. BEE-76 reordered to **end-of-milestone** (after BEE-79+80 unblock SPM deps + simulator runs). Cumulative velocity = 12.5 SP/día |
| 2026-05-01 | 55 / 94 | 39 | +5.0 (day 4 cont.) | BEE-79 closed **partial** in day 4 (5ª task del día — record). Pivot estratégico: cross-compile local de `beeping-core` C++ → 3 slices iOS → `BeepingCore.xcframework` vendoreado en `Vendor/`, libBeepingCoreUniversal.a (18 MB) eliminada. Simulator arm64 unblocked. **BEE-78 (sample app) marked OUT OF SCOPE per founder — moves to separate tutorials repo.** Cumulative velocity = **13.75 SP/día across 4 working days** — buffer ~6+ días. |
| 2026-05-04 | 63 / 99 | 36 | 8.0 (day 5) | BEE-78 closed in day 5. Sample app SwiftUI + env picker Local/Dev/Prod + 5-tap debug console + brand red `#ed1c24`. **SDK builder bug found and fixed**: `BeepingClient.local().build()` creaba dos `BeepingCoreWrapper` distintos (encoder sin configurar → SIGSEGV). Fix: factory recibe el wrapper compartido. **Scope addition BEE-2050 (+5 SP)**: CloudEncoder WAV playback como follow-up para cerrar el gap de BEE-73 partial. Total SP went 94→99, tasks 16→17, closed 11→12. Cumulative velocity = **12.6 SP/día across 5 working days** — buffer ~6 días, fin proyectado 2026-05-08 (vs plan 2026-05-18). |
| 2026-05-06 | 68 / 99 | 31 | 5.0 (day 6) | BEE-2050 closed. **CloudEncoder WAV playback**: `WAVPlaybackSink` protocol + `AVAudioPlayerSink` default (forces `.overrideOutputAudioPort(.speaker)` to bypass `.playAndRecord` receiver policy), mode propagation through `BeepingClientBuilder` to server enum (otherwise defaults to inaudible 17.8 kHz), `BeepingCoreWrapper.decodeLoopback(wav:mode:)` with dedicated `BCNativeCore` for in-app loopback decode bypassing speaker→mic acoustic loop. **Defensive fix in `LocalEncoder.encode`**: validates 9 base32 chars before C engine (ReedSolomon SIGSEGVs on bad input). 3 new unit tests (`CloudEncoderPlaybackTests`). Cumulative velocity = **11.3 SP/día across 6 working days**, buffer ~7 días. |
| 2026-05-11 | 73 / 104 | 31 | 5.0 (day 9) | BEE-2220 closed. **QA pivot — listener-only sample app + `send-beep.sh` host-side encoder + cloud round-trip integration tests**. Sample app drops Send UI, env picker, secrets generator; auto-listens on launch. `scripts/send-beep.sh` (bash 3.2 compat) does 9 reps × volume 0.1→0.9 calling beepbox-server + afplay. Critical addition: 3 `CloudRoundTripIntegrationTests` that POST to `/v1/encode` for each of 3 modes (audible/inaudible/all) and assert `decodeLoopback` reconstructs the key — proves SDK end-to-end without microphone or speaker. Device QA deferred (no hardware available). Scope addition BEE-2220 (+5 SP): total 99→104, tasks 17→18, closed 13→14. Cumulative velocity = **8.1 SP/día across 9 working days**, buffer ~5 días (lost 1 day on mic permission debugging that turned out to be a sim limitation, not a SDK bug). |

This table grows with every closed task. Velocity is recalculated as
`closed_SP / working_days_elapsed` and feeds the recalc of the table above.

---

## 📎 References

- `docs/PRODUCTO.md` — full product spec (sections 6 = scope, 19 = risks, 20 = timeline)
- `docs/ROADMAP_CHANGELOG.md` — append-only log of every change to this file
- `~/.claude/CLAUDE.md` — global methodology, branch model, ROADMAP rules
- Linear milestone Phase 9: `https://linear.app/me8/project/03da887d924e?selectedProjectMilestone=3b2f36a8-b6e7-4202-8748-1a8c8ec65d21`
