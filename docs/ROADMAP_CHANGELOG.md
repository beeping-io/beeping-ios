# 📅 ROADMAP Changelog

> Historial completo de cambios en `docs/ROADMAP.md`.
> Mantenido automáticamente por el CLI: cada vez que el ROADMAP cambia,
> se añade una nueva entrada al inicio de la sección History con el diff
> versus la versión anterior.

---

## 🎯 Snapshot actual

- **Fecha de inicio del proyecto**: 2026-04-28
- **Fecha de fin estimada (con 20% margen)**: 2026-05-18
- **Velocidad asumida**: 8 story points / día
- **Estado global**: ✅ En tiempo
- **Última actualización**: 2026-04-30 (trigger: Closed BEE-71 — net delta 0 days)

| # | Milestone | Story points | Inicio est. | Fin est. | Estado |
|---|---|---|---|---|---|
| 1 | 🍎 Phase 9 — beeping-ios (Swift 6) | 94 (16 tasks; 34 SP closed, 60 SP remaining) | 2026-04-28 | 2026-05-18 | ✅ |

---

## 📜 History

### [2026-04-30] - Closed BEE-71
**Trigger detallado**: BEE-71 (🎭 Strategy pattern: `LocalEncoder` C++ via ObjC++ + `CloudEncoder` URLSession) cerrada en plan en day 3 del milestone (mismo día que BEE-69 + BEE-70 — sesión muy productiva). Single commit con:
- `BeepingEncoder.swift` (~30 líneas) — internal `protocol BeepingEncoder: Sendable`
- `LocalEncoder.swift` (~50 líneas) — `actor` wrapping `BeepingCoreWrapper.play(code:)`
- `CloudEncoder.swift` (~90 líneas) — `actor` con URLSession async POST a `/v1/encode`
- `BeepingClient.swift` modificado — `internal init(encoder:mode:)` permite inyección, `send` delega
- `EncoderStrategyTests.swift` (~150 líneas) + `MockURLProtocol.swift` (~50 líneas) — 6 tests cubriendo URL/headers/body shape

**Net delta global**: 0 días (cerramos en plan; SP planeado=8, SP real ~5 — fluido)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados (negativo = más pronto)
- (ninguno significativo a nivel milestone — buffer creciente queda en margen)

#### Retrasados (positivo = más tarde)
- (ninguno)

#### Sin cambio
- BEE-72..BEE-82 (11 tasks restantes, 60 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅; BEE-80/81/82 al final siguen ⚠️ por dependencia con R1)

#### Velocity actualizada
- Day 3 (2026-04-30): +24 SP cerrados en total (BEE-69 + BEE-70 + BEE-71) → cumulative **11.3 SP/día** across 3 working days
- 3.3 SP/día por encima del asumido 8 SP/día — buffer real de ~5 días si esta velocity se sostiene

#### Scope decisión documentada
- BEE-71 implementa strategy pattern SOLO para encode (transmit). Decode (mic capture + decoder) sigue local-only. Cloud-mode-decode requeriría rediseño grande del audio thread (chunked upload + async decoded responses); explícitamente fuera de scope para los 8 SP del task.
- CloudEncoder usa URLSession plain en BEE-71. La response body audio no se procesa todavía — BEE-73 (OpenAPI-generated client) refinará con type-safety + wirearáa playback.

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(strategy): BEE-71 add BeepingEncoder protocol + Local/Cloud strategies

---

### [2026-04-30] - Closed BEE-70
**Trigger detallado**: BEE-70 (🌊 API pública nueva: `BeepingClient` actor-based + `AsyncStream<BeepingEvent>`) cerrada en plan en day 3 del milestone (mismo día que BEE-69 — sesión productiva). Entregada en single commit con:
- `BeepingClient.swift` (~180 líneas) — `public actor` con nested `Event` enum, `init(mode:)` síncrono, `listen() -> AsyncStream<Event>` multi-listener, `send(_ payload:) async throws`, `close() async`
- `BeepingPayload.swift` (~75 líneas) — `public struct: Sendable, Equatable`
- `BeepingClientTests.swift` (~115 líneas) — 9 tests Swift Testing
- Promoción `BeepingError` + `BeepingMode` a `public`
- `BeepingError` añade `Equatable` (necesario para auto-synthesis de `Event.failed(BeepingError)`)

**Net delta global**: 0 días (cerramos en plan; SP planeado=8, SP real ~6 — la implementación se benefició del groundwork de BEE-68)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados (negativo = más pronto)
- (ninguno significativo a nivel milestone — ahorro implícito absorbido por margen)

#### Retrasados (positivo = más tarde)
- (ninguno)

#### Sin cambio
- BEE-71..BEE-82 (12 tasks restantes, 68 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅; BEE-80/81/82 al final siguen ⚠️ por dependencia con R1 — Phase 1 `beeping-core` releases)

#### Velocity actualizada
- Day 3 (2026-04-30): +8 SP closed (BEE-69 + BEE-70) → cumulative **8.7 SP/día** across 3 working days
- Por primera vez por encima del asumido 8 SP/día. Buffer creciente.

#### Auto-correction nota
Al cerrar BEE-69 anuncié que BEE-70 resolvería el warning "shadows module 'Beeping'". **Inexacto**: la descripción de BEE-70 no pide renombrar la legacy class. El warning sigue allowlisted; su resolución requiere deprecar la legacy `Beeping` ObjC class, que es scope independiente (posiblemente como parte del cleanup hacia 1.0). Documentado en el comment de cierre.

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(api): BEE-70 add BeepingClient actor + AsyncStream<Event>

---

### [2026-04-30] - Closed BEE-69
**Trigger detallado**: BEE-69 (🔒 iOS 15 mínimo + `PrivacyInfo.xcprivacy` con declared API reasons) cerrada en plan en day 3 del milestone. La mitad del work (iOS 15 deployment target) ya estaba cubierta por BEE-68 Fase 1; sólo el manifest de privacy fue trabajo nuevo: `/PrivacyInfo.xcprivacy` (4 claves obligatorias declarando "no tracking, no PII, no required-reason APIs"), wired into `project.pbxproj` Resources build phase del Beeping target.

**Net delta global**: 0 días (cerramos en plan; SP planeado=3 ≈ SP real ~1, pero al ritmo del milestone no afecta)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados (negativo = más pronto)
- (ninguno significativo — el "ahorro" implícito de tener iOS 15 ya hecho se absorbe en el margen del 20%)

#### Retrasados (positivo = más tarde)
- (ninguno)

#### Sin cambio
- BEE-70..BEE-82 (13 tasks restantes, 76 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅; BEE-80/81/82 al final siguen ⚠️ por dependencia con R1 — Phase 1 `beeping-core` releases)

#### Velocity actualizada
- Day 1 (2026-04-28): 2 SP closed → cumulative 2.0 SP/día
- Day 2 (2026-04-29): 13 SP closed → cumulative 7.5 SP/día
- Day 3 (2026-04-30): 3 SP closed → cumulative **6.0 SP/día** (debajo del asumido 8 pero dentro de margen)
- Re-evaluar tras BEE-70 (8 SP, prio 1) que será el siguiente test grande de velocity.

#### Aclaración técnica documentada
- `xcrun privacy_compliance` mencionado en la descripción original de BEE-69 NO existe como CLI público de Apple — investigado y confirmado. La validación canónica es `plutil -lint` (sintaxis) + Xcode archive validator + App Store Connect submission. Documentado en el comment de cierre de la tarea para que no se perpetúe el mito.

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(privacy): BEE-69 add PrivacyInfo.xcprivacy + iOS 15 confirmation

---

### [2026-04-29] - Closed BEE-68
**Trigger detallado**: BEE-68 (🔄 Migración completa ObjC → Swift 6 con strict concurrency, Sendable, actors) cerrada en plan en day 2 del milestone, después de una pausa de sesión entre fases 3 y 4. Entregada en 8 fases (10 commits): Xcode toolchain Swift 6, ObjC++ bridge `BeepingC.{h,mm}`, Swift Sendable types, Swift internal wrappers, public Beeping facade `@MainActor`, Swift Testing migration, legacy ObjC cleanup, ROADMAP recalc.
**Net delta global**: 0 días (cerramos en plan; 13 SP planeado ≈ 13 SP real)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio, antes: 2026-05-18)
**Nuevo estado global**: ✅ (sin cambio, antes: ✅)

#### Adelantados (negativo = más pronto)
- (ninguno)

#### Retrasados (positivo = más tarde)
- (ninguno)

#### Sin cambio
- BEE-69..BEE-82 (14 tasks restantes, 79 SP remaining; el cierre de BEE-68 en plan no afecta la cascada)

#### Cambios de estado de riesgo
- (ninguno — global se mantiene ✅; las tasks BEE-80/81/82 al final del milestone siguen en ⚠️ medio por dependencia con R1 — Phase 1 `beeping-core` releases)

#### Velocity actualizada
- Day 1 (2026-04-28): 2 SP closed → cumulative velocity 2.0 SP/day
- Day 2 (2026-04-29): 13 SP closed → cumulative velocity 7.5 SP/day across 2 working days
- Velocity asumida 8 SP/día se sostiene ligeramente por debajo (-0.5 SP/día) — tracking dentro de margen. Re-evaluar tras 3+ days de samples.

#### Commits relacionados (en `milestone/phase-9`, en orden)
- `5c6d5a7` — chore(xcode): enable Swift 6 + strict concurrency + iOS 15 minimum
- `76ca303` — fix(xcode): add shared Beeping.xcscheme for CI
- `5464dca` — chore(legacy): silence pre-existing warnings on legacy ObjC sources
- `66fb7a2` — feat(bridge): add BeepingC ObjC++ bridge for C API + AudioUnit
- `669d6d1` — feat(api): add Swift Sendable types (Mode, Event, Error, Delegate)
- `801e98b` — feat(internal): Swift wrappers for core + audio
- `0f2340f` — fix(ci): use legacy allowBluetooth (Xcode 16 SDK lacks new symbol)
- `e863bb1` — refactor(api): swap ObjC Beeping → Swift @MainActor facade
- `e3d0994` — test: migrate XCTest → Swift Testing + add Sendable + native smoke
- `7ebe26f` — chore: delete legacy ObjC sources after Swift 6 migration

#### Known-allowlisted warnings (cleanup tracked)
- `class 'Beeping.Beeping' shadows module 'Beeping'` → resuelve en BEE-70
- `'allowBluetooth' was deprecated` → resuelve en BEE-69 / BEE-79
- `BeepingC.h` Public visibility temporal → resuelve en BEE-80 (Package.swift private submodule)

---

### [2026-04-28] - Closed BEE-67
**Trigger detallado**: BEE-67 (🏷️ Rename `sdk-iphone` → `beeping-ios` + Apache-2.0 + Conventional Commits) cerrada en plan en day 1 del milestone. SP planeado = 2, SP real ≈ 1 (la mayor parte del trabajo ya quedó cubierta por el commit de bootstrap `/worktree-init`).
**Net delta global**: 0 días (cerramos en plan; sin slip ni adelanto)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio, antes: 2026-05-18)
**Nuevo estado global**: ✅ (sin cambio, antes: ✅)

#### Adelantados (negativo = más pronto)
- (ninguno)

#### Retrasados (positivo = más tarde)
- (ninguno)

#### Sin cambio
- BEE-68..BEE-82 (15 tasks restantes, 92 SP remaining; el cierre de BEE-67 en plan no afecta la cascada)

#### Cambios de estado de riesgo
- (ninguno — global se mantiene ✅; las tasks BEE-80/81/82 al final del milestone siguen en ⚠️ medio por dependencia con R1 — Phase 1 `beeping-core` releases)

#### Velocity actualizada
- Day 1 (2026-04-28): 2 SP closed → cumulative velocity 2.0 SP/day (parcial, single day)
- Velocity asumida 8 SP/día sigue siendo el supuesto base; se recalibrará tras cerrar más tasks (target: re-evaluar con ≥3 days closed para muestra significativa).

#### Commits relacionados (en `milestone/phase-9`)
- `e7729e6` — `chore(ci): BEE-67 add commitlint + smoke CI + PR template + lefthook`

---

### [2026-04-28] - Initial ROADMAP creation
**Trigger**: `/worktree-init` bootstrap of `beeping-io/beeping-ios`
**Estado global inicial**: ✅
**Fecha fin estimada**: 2026-05-18 (Mon)

Snapshot inicial — ver tabla de arriba.

#### Milestones registrados
- 🍎 Phase 9 — beeping-ios (Swift 6) · 94 SP · 16 tasks (BEE-67..BEE-82)
  - Linear ID: `3b2f36a8-b6e7-4202-8748-1a8c8ec65d21`
  - Linear project: 🔊 Beeping Platform · `a83369a5-3cb8-4fca-932d-ee33f6a7a00e`

#### Cálculo inicial
- **Total SP**: 94
- **Velocidad**: 8 SP/día (default ecosistema Beeping)
- **Esfuerzo bruto**: 94 / 8 = ~11.75 días hábiles
- **Margen riesgo**: 20%
- **Esfuerzo con margen**: ~14.1 → **15 días hábiles**
- **Inicio**: 2026-04-28 (martes)
- **Fin estimado**: 2026-05-18 (lunes)

#### Tareas marcadas como ⚠️ riesgo medio (consumen el margen final)
- BEE-80 — SPM Package.swift + XCFramework firmado (depende de R1)
- BEE-81 — CocoaPods podspec (depende de BEE-80)
- BEE-82 — release-please + cosign + GH Releases (depende de BEE-80 + BEE-81)

Ningún milestone cerrado todavía. Velocity histórica = 0 (placeholder).
