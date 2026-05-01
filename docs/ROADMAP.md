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
| **Total SP committed** | 94 SP across 16 tasks |
| **Raw effort** | 94 SP / 8 SP·day = ~11.75 working days |
| **Effort with margin** | ~14.1 working days → **15 working days rounded** |
| **Estimated end date** | **2026-05-18 (Mon)** |
| **Global status** | ✅ En tiempo |
| **Last update** | 2026-05-01 (Closed BEE-79 — partial XCFramework rebuild bridge; net delta 0 days; BEE-78 out of scope per founder) |

---

## 📍 Active milestone — 🍎 Phase 9 — beeping-ios (Swift 6)

- **Linear ID**: `3b2f36a8-b6e7-4202-8748-1a8c8ec65d21`
- **Story points**: 94 (16 tasks; **55 SP closed**, 39 SP remaining)
- **Start**: 2026-04-28 (Tue)
- **End estimate**: 2026-05-18 (Mon)
- **Status**: ✅ En tiempo (11/16 tasks closed — BEE-67..BEE-75 + BEE-77 + BEE-79; BEE-78 out of scope per founder — sample apps move to separate tutorials repo; BEE-76 deferred to end-of-milestone)

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
| 12 | BEE-78 | 8 | 📱 Sample app SwiftUI + debug console | OUT OF SCOPE | (separate tutorials repo) | ⏸️ MOVED |
| 13 | BEE-79 | 5 | 🔗 Consumir beeping-core via GH Releases | 2026-05-01 | 2026-05-01 | ✅ **DONE (partial — local rebuild bridge; full upstream fetch pending BEE-82)** |
| 14 | BEE-80 | 8 | 📦 SPM Package.swift + XCFramework firmado | 2026-05-15 | 2026-05-18 | ⚠️ |
| 15 | BEE-81 | 5 | 🍫 CocoaPods podspec | 2026-05-18 | 2026-05-18 | ⚠️ |
| 16 | BEE-82 | 5 | 🚀 release-please + cosign + GH Releases | 2026-05-18 | 2026-05-18 | ⚠️ |
|   | **94** | | | | | |

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

This table grows with every closed task. Velocity is recalculated as
`closed_SP / working_days_elapsed` and feeds the recalc of the table above.

---

## 📎 References

- `docs/PRODUCTO.md` — full product spec (sections 6 = scope, 19 = risks, 20 = timeline)
- `docs/ROADMAP_CHANGELOG.md` — append-only log of every change to this file
- `~/.claude/CLAUDE.md` — global methodology, branch model, ROADMAP rules
- Linear milestone Phase 9: `https://linear.app/me8/project/03da887d924e?selectedProjectMilestone=3b2f36a8-b6e7-4202-8748-1a8c8ec65d21`
