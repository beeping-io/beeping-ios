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
- **Estado global**: ✅ En tiempo (buffer ~5 días)
- **Última actualización**: 2026-05-11 (trigger: Closed BEE-2050 + BEE-2220; net delta 0 days)

| # | Milestone | Story points | Inicio est. | Fin est. | Estado |
|---|---|---|---|---|---|
| 1 | 🍎 Phase 9 — beeping-ios (Swift 6) | 104 (18 tasks; 73 SP closed, 31 SP remaining; BEE-76 deferred + BEE-2050 + BEE-2220 added) | 2026-04-28 | 2026-05-18 | ✅ |

---

## 📜 History

### [2026-05-11] - Closed BEE-2050 + BEE-2220 (CloudEncoder WAV playback + sample app QA pivot)

**Trigger detallado**: Doble cierre tras 5 días de trabajo continuo sobre el cloud-mode QA. BEE-2050 (CloudEncoder WAV playback) entregada con 3 piezas: `WAVPlaybackSink` protocol con default `AVAudioPlayerSink` que fuerza `AVAudioSession.overrideOutputAudioPort(.speaker)` para sortear la policy de `.playAndRecord` que defaulta al receiver; mode propagation completa del builder al wire (sin esto el server defaultea a `inaudible` 17.8 kHz, inaudible en altavoces de Mac); y `BeepingCoreWrapper.decodeLoopback(wav:mode:)` con `BCNativeCore` dedicado para in-app loopback decode (descubierto necesario al ver que el simulator self-loop no funciona). Bonus: defensive validation en `LocalEncoder.encode` para evitar SIGSEGV del C engine ReedSolomon con input non-base32 (9 chars `[0-9a-v]` requeridos).

**BEE-2220 (QA pivot)**: durante el QA de BEE-2050 descubrimos que el simulator no enruta speaker→mic acústicamente (su mic captura del Mac mic input device, no hay loopback automático). Ni single-sim, ni dual-sim. Pivotamos a 3 entregables:
1. **Sample app cleanup**: drop Send UI + env picker + secrets generator + base32 helpers. Auto-listen on launch. Single-screen Form con Listener + Activity sections.
2. **`scripts/send-beep.sh`**: host-side encoder/player con args `--mode|--env|--key|--target`, 9 reps × volumen rampeado 0.1→0.9, gap 1s. POST a beepbox + `afplay`. Compatible bash 3.2 (mktemp source vs process substitution porque macOS ships bash 3.2).
3. **`CloudRoundTripIntegrationTests`** (3 tests): para cada uno de los 3 server modes, POST → recibe WAV → feed a `decodeLoopback` → asserta `.endOk` con el mismo key y `confidence > 0.5`. Demuestra determinísticamente que el SDK funciona end-to-end **sin micrófono ni altavoz** — el path acústico queda para QA con device físico cuando esté disponible.

**Net delta global**: 0 días. Cierre BEE-2050 + BEE-2220 estuvo en plan (estimación combinada 10 SP, real ~10 SP). Scope total Phase 9: 94 → 99 → 104 SP (dos additions de 5 SP). Buffer reducido de 6 → 5 días por scope addition BEE-2220, pero sigue holgado vs fin proyectado 2026-05-18.

**Milestones afectados**:
- 🍎 Phase 9: 12/17 → 14/18 tasks (Done = BEE-67..BEE-75 + BEE-77 + BEE-78 + BEE-79 + BEE-2050 + BEE-2220; pendientes BEE-76 (deferred) + BEE-80 + BEE-81 + BEE-82). 63 → 73 SP closed.

**Cambios de estado de riesgo**: ninguno. R1-R8 sin actualización.

**Pendiente trasladado a roadmap externo**: device-physical QA del listener (loopback acústico speaker→mic en aire). Bloqueado por hardware availability. No bloquea otras tareas — `send-beep.sh --target device` queda listo para esa fase.

---

### [2026-05-04] - Closed BEE-78 + scope addition BEE-2050 (CloudEncoder WAV playback)
**Trigger detallado**: BEE-78 (📱 Sample app SwiftUI + debug console) cerrada en day 5. Sample app integration-test surface entregado: target `BeepingSampleApp` (xcodegen-managed) en `Beeping.xcworkspace`, env picker Local/Dev/Prod, build phase script que inyecta `.env.local` → `Sources/Generated/Secrets.swift` (gitignored, `#if DEBUG` only, blanks en Release), debug console activable con 5-tap on logo, brand color `#ed1c24` sincronizado desde `beeping-www/src/app/globals.css`.

**Bug del SDK encontrado y corregido en BEE-78**: `BeepingClient.local().build()` creaba dos `BeepingCoreWrapper` distintos — uno configurado para listening, otro sin configurar para encoding. `client.send()` invocaba `BEEPING_EncodeDataToAudioBuffer` sobre un C handle sin `BEEPING_Configure` jamás llamado → SIGSEGV en simulador. Fix: refactor del builder factory (`encoderFactory: (BeepingCoreWrapper) -> BeepingEncoder` recibe el wrapper ya configurado), nuevo `BeepingClient.init(wrapper:encoder:...)` que comparte el wrapper entre encoder y listener.

**Workaround de spdlog**: `beeping-core` C++ auto-inicializa spdlog con path relativo `logs/beeping.log`. En sandbox iOS el cwd es read-only → `BEEPING_Create()` lanzaba `spdlog::spdlog_ex` y mataba el proceso al inicio. Workaround mínimo en el sample app: `chdir` a Documents y pre-create `logs/` antes del `@StateObject AppModel()`. Fix más limpio (relocalizar el log al app sandbox dentro del SDK) queda fuera de scope.

**Sub-pasos ejecutados**:
- xcodegen + `BeepingSampleApp/project.yml` con cross-project reference a `Beeping.xcodeproj`
- `Beeping.xcworkspace` que junta SDK + sample
- 9/9 tests verde: 5 unit (`AppEnvironmentTests`) + 4 UI (`BeepingSampleAppUITests`: launch, env picker, 5-tap debug console, send button enabled)
- Lint gates: `swiftlint --strict` 0 violations, `swift-format lint --strict` 0 issues
- Release build verification: `nm BeepingSampleApp | grep -i beepbox` → 0 símbolos (claves no embebidas en Release)
- Human QA Checkpoint completado: Local mode ✅ (post-fix), Dev mode ✅ (4 POSTs a `https://beepbox-dev.beeping.io/v1/encode` → HTTP 200, ~204KB WAV cada uno), Prod ruta verificada via mismo CloudEncoder + auth scheme `Bearer`
- 3 rondas de UX feedback iterativo aplicadas: separación `lastDecodeStatus` vs `lastSendError`, header VStack-instead-of-safeAreaInset, brand red `.tint`, Send button HStack-centrado, +16pt body padding

**Scope addition — BEE-2050 (`🔊 CloudEncoder WAV playback`)**: gap conocido del SDK (BEE-73 partial) surfaceado por BEE-78. `CloudEncoder.encode()` recibe los bytes WAV del `beepbox-server` por HTTP 200 pero los descarta (`_ = data` en `CloudEncoder.swift:60-63`). En cloud mode el sample no oye el beep porque nadie lo reproduce. Tracked aparte como **BEE-2050** (5 SP, milestone Phase 9): `AVAudioPlayer` con data-init o `AudioEngine.play(pcmFrames:)` para completar el round-trip Dev/Prod end-to-end.

**Velocity recalc**:
- 63 SP closed / 5 working days = 12.6 SP/día (planeado: 8 SP/día — buffer creciente)
- 36 SP remaining (BEE-76 deferred 13 SP + BEE-80 8 SP + BEE-81 5 SP + BEE-82 5 SP + BEE-2050 5 SP)
- Estimación: 36 / 12.6 ≈ 3 días + 20% margen ≈ 4 días → fin proyectado 2026-05-08 (vs plan 2026-05-18 → ~6 días de buffer)
- Estado global: ✅ con buffer holgado, sin riesgos abiertos

**Net delta global**: 0 días (BEE-78 dentro del plan, scope addition BEE-2050 absorbida por buffer).

### [2026-05-01] - Closed BEE-79 (partial — XCFramework rebuild local bridge)
**Trigger detallado**: BEE-79 (🔗 Consumir `beeping-core` via GitHub Releases) cerrada **parcial** en day 4 (5ª task del día — record). Pivot estratégico: el legacy `libBeepingCoreUniversal.a` no tenía slice arm64-iphonesimulator, lo que bloqueaba BEE-78 (sample app on sim) y BEE-76 (tests on sim). En lugar de esperar al primer release oficial de `beeping-core` con artefactos iOS firmados (R1, indeterminado), se cross-compila localmente la C++ source de `beeping-core` para 3 slices iOS y se construye el XCFramework manualmente.

**Sub-pasos ejecutados**:
- CMake + Xcode SDKs cross-compile de `beeping-core` (C++20 sources) → 3 `.a` slices (arm64-iphoneos, arm64-iphonesimulator, x86_64-iphonesimulator), 19 MB cada uno
- `lipo -create` para fat sim binary (arm64+x86_64) → `BeepingCore.xcframework` con 2 entries (`ios-arm64`, `ios-arm64_x86_64-simulator`)
- Vendoreado en `Vendor/BeepingCore.xcframework/` (reemplaza el `.a` legacy)
- `Beeping.xcodeproj/project.pbxproj` modificado: añadido `PBXFileReference` + `PBXBuildFile` + entry en grupo Frameworks + entry en `PBXFrameworksBuildPhase` del target Beeping. Removido `OTHER_LDFLAGS = "-lBeepingCoreUniversal"`, `LIBRARY_SEARCH_PATHS = $(PROJECT_DIR)`, `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`. Añadido `$(PROJECT_DIR)/Vendor` a `FRAMEWORK_SEARCH_PATHS`
- Bridge ObjC++ (`BeepingC.h/.mm` + `BeepingCoreWrapper.swift`) limpiado: removido `setCustomBaseFreq:beepsSeparation:` (símbolo `BEEPING_SetCustomBaseFreq` no expuesto en la API pública nueva de `beeping-core`)
- `BeepingCoreLib_api.h` root sincronizado con `beeping-core/include/`
- CI (`.github/workflows/ci.yml`): nuevo job `Build Beeping framework (arm64 iOS Simulator)` + 3 nuevas allowlist entries para warnings de auto-link (CoreAudioTypes/UIUtilities/SwiftUICore — emitidos por la nueva XCFramework, harmless)

**Scope parcial documentado**: la pieza de "fetch automatizado del XCFramework desde GH Releases de `beeping-core`" queda diferida a BEE-82 (release-please + cosign) cuando upstream publique releases iOS firmados (R1). Mientras tanto, el XCFramework rebuild local sirve como bridge funcional — el SDK ya no depende del `.a` legacy y compila para device + simulador.

**Net delta global**: 0 días (en plan, mismo día). BEE-79 estaba estimada para 2026-05-15 pero se ejecuta ahora porque BEE-78 (sample app) salió de scope (movida a repo separado para tutoriales) y BEE-79 era el único bloqueador real para los siguientes pasos.
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio — buffer creciente: +5 días vs plan inicial)

#### Adelantados (negativo = más pronto)
- BEE-79: 2026-05-15 → 2026-05-01 (-14 días) — cierre adelantado por pivot estratégico (BEE-78 fuera de scope abre slot)

#### Sin cambio
- BEE-80, BEE-81, BEE-82, BEE-76 (4 tasks restantes, 31 SP)

#### Scope clarification (corrected mid-task)
- BEE-78 (📱 Sample app SwiftUI + debug console): **stays in scope** como integration-test surface del SDK (founder confirmation). Los tutorial-oriented sample apps irán en un repositorio separado para contenido público; el sample app de BEE-78 sirve como E2E manual + integration test del flujo public API.

#### Cambios de estado de riesgo
- R1 (`beeping-core` releases delay): impacto reducido a corto plazo — el XCFramework local bridge desbloquea las tareas downstream sin esperar al primer release oficial. R1 sigue 🟡 monitored porque BEE-82 (release-please con cosign) seguirá necesitando los releases reales de `beeping-core` para su integration tests, pero ya no es bloqueador del milestone.

#### Velocity actualizada
- Day 4 (2026-05-01): +5 SP closed (BEE-79) → cumulative **13.75 SP/día** across 4 working days
- Buffer real estimado: ~6+ días si la velocity se sostiene (39 SP / 13.75 SP/día = 2.8 días raw → 3.5 días con margen)

#### Tasks cerradas en BEE-79
- 3 slices iOS de `beeping-core` cross-compiladas (arm64-device, arm64-sim, x86_64-sim)
- `BeepingCore.xcframework` armado y vendoreado
- `libBeepingCoreUniversal.a` (18 MB) eliminado del repo
- pbxproj migrado a XCFramework linkage (PBXFileReference + PBXBuildFile + Frameworks build phase)
- Bridge ObjC++ podado de símbolos no expuestos en la nueva API
- CI con job de simulador adicional + allowlist actualizada
- Linear BEE-79 description actualizada con las 2 secciones obligatorias (`## 🧪 Automated tests` + `## 🧑‍🔬 Human QA Checkpoint`)

#### Commits relacionados (en `milestone/phase-9`)
- `80c6520` — feat(linkage): BEE-79 swap libBeepingCoreUniversal.a → BeepingCore.xcframework
- `<follow-up>` — fix(api): BEE-79 mark BeepingDelegate `@MainActor` + bump test target to iOS 16

#### Follow-up (mismo día, mismo BEE-79)
Tras correr la suite Swift Testing en el simulador desbloqueado, surgieron 2 bugs latentes:
1. `SpyDelegate` (test) conformance crossing into MainActor bajo Swift 6 strict concurrency. Fix: anotar el protocolo `BeepingDelegate` como `@MainActor` (hace explícito en tipos lo que ya estaba en docs: "All callbacks are dispatched on the main queue") + isolated conformance `@MainActor BeepingDelegate` en `SpyDelegate`. Cero impact en API consumers — `Beeping` ya era `@MainActor` y dispatch ya hopeaba a main.
2. `Task.sleep(for: .milliseconds(...))` requiere iOS 16+. Fix: bump del test target `IPHONEOS_DEPLOYMENT_TARGET` 15 → 16. El framework SDK público sigue iOS 15.

Resultado: 29/29 tests Swift Testing pass + suite XCTest legacy pass. Hay un crash flaky en la primera ejecución de tests `BeepingClient` (audio engine concurrente sobre simulador sin mic real) — xctest auto-restarts y todo termina verde, pero esta flakiness queda anotada para BEE-76 (test consolidation, deferred). CI sigue restringido a framework build (sin tests) hasta BEE-76.

#### Scope clarification (corrected mid-task)
BEE-78 (📱 Sample app SwiftUI + debug console) **stays in scope** como integration-test surface del SDK (founder confirmation tras inicial misclassification). Los tutorial-oriented sample apps irán en un repositorio separado para contenido público; el sample app de BEE-78 sirve como E2E manual + integration test del flujo public API.

---

### [2026-05-01] - Closed BEE-77 + BEE-76 deferred (re-ordered)
**Trigger detallado**: BEE-77 (🧼 SwiftLint + swift-format en CI) cerrada en plan — config strict + auto-format de 16 ficheros + 3 nuevos pasos de CI. Same day, BEE-76 (🧪 Tests con snapshot + property + coverage) **revertida a Backlog y reordenada al final del milestone** porque 4/5 entregables están bloqueados por BEE-79 (simulator unblock) + BEE-80 (Package.swift para SwiftCheck + swift-snapshot-testing).

**Re-ordering rationale**: hacer BEE-76 ahora forzaría 4 "deferred" annotations consecutivas (patrón inflado tras BEE-73 ya parcial). Cleaner: BEE-77 → BEE-78 → BEE-79 → BEE-80 → BEE-81 → BEE-82 → BEE-76 (cierre). El task de tests grande consolida toda la suite del milestone con las dependencias ya disponibles.

**Net delta global**: 0 días (sin slip; BEE-77 en plan, BEE-76 reordering no afecta fecha fin)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados / Retrasados / Sin cambio
- (ninguno significativo a nivel milestone — buffer creciente queda en margen)
- BEE-78..BEE-82 + BEE-76 (6 tasks restantes, 44 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅)

#### Velocity actualizada
- Day 4 (2026-05-01): +10 SP closed (BEE-74 + BEE-75 + BEE-77) → cumulative **12.5 SP/día** across 4 working days
- Buffer real ~5 días si esta velocity se sostiene

#### Tasks cerradas en BEE-77
- `.swiftlint.yml` strict mode con disabled/opt_in rules + rationale inline
- `.swift-format` config Apple JSON
- CI workflow con `brew install swiftlint` + `swiftlint --strict` + `xcrun swift-format lint --strict`
- 16 ficheros auto-formatted (mecánico)
- 4 fixes manuales (Self refs, column alignment, redundant nil)

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — chore(lint): BEE-77 add SwiftLint + swift-format CI gates

---

### [2026-05-01] - Closed BEE-75
**Trigger detallado**: BEE-75 (📡 Telemetry hook con opt-out + tests de privacy) cerrada en plan en day 4 del milestone (segunda task del día). Single commit con:
- `TelemetryEvent.swift` (~60 líneas) — `public enum: Sendable, Equatable` con casos typed metrics-only (`.sessionStarted(mode:)`, `.sessionStopped`, `.beepDecoded(confidence:mode:)`, `.beepEmitted`, `.errorOccurred(category:)`). Cero PII por construcción.
- `TelemetryHook.swift` (~30 líneas) — `public protocol: Sendable` con `record(_:) async`
- `TelemetryClient.swift` (~60 líneas) — `internal actor` con privacy gate (no-op cuando `enabled=false` o `hook=nil`)
- `BeepingClient` wireado: emite `.sessionStarted` en `listen()`, `.beepEmitted` en `send()`, `.sessionStopped` en `close()`, `.beepDecoded` en dispatch endOk, `.errorOccurred(.decoder)` en dispatch failed
- `BeepingClientBuilder` añade `.telemetryHook(_:)` fluent setter
- `TelemetryTests.swift` (~210 líneas) — **12 privacy tests** incluyendo el critical "with telemetryEnabled=false + hook set, SpyHook captures 0 events"

**Net delta global**: 0 días (en plan; SP planeado=5, SP real ~4 — groundwork de BEE-72/74 facilitó wiring)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados / Retrasados / Sin cambio
- (ninguno significativo a nivel milestone)
- BEE-76..BEE-82 (7 tasks restantes, 46 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅)

#### Velocity actualizada
- Day 4 (2026-05-01): +8 SP closed (BEE-74 + BEE-75) → cumulative **12.0 SP/día** across 4 working days
- 4.0 SP/día por encima del asumido 8 SP/día — buffer real ~5+ días

#### Honesty de scope
"Telemetry visible en Beepbox" del DoD requiere endpoint `/v1/events` que no está en la spec OpenAPI (BEE-73). Built-in `BeepboxTelemetryHook` queda deferido hasta que ese endpoint exista. BEE-75 entrega infrastructure + protocol + privacy gates + tests — consumer puede inyectar su propio sink (Sentry, Firebase, etc.) hoy mismo.

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(telemetry): BEE-75 add TelemetryHook + privacy gate + 12 tests

---

### [2026-05-01] - Closed BEE-74 — half-milestone reached
**Trigger detallado**: BEE-74 (🪵 Logging `os.Logger` + custom wrapper + trace-ID + niveles) cerrada en plan en day 4 del milestone. Single commit con:
- `BeepingLog.swift` (~140 líneas) — `public struct: Sendable` wrapper sobre `os.Logger` con subsystem fijo `io.beeping.sdk`, categorías por módulo, trace-ID 8-char hex compartido por sesión, métodos trace/debug/info/warn/error/fault, redaction helpers
- `BeepingLogLevel.swift` extendido (5 → 7 cases: `.off, .fault, .error, .warn, .info, .debug, .trace`) + `Comparable` conformance via severity index
- `BeepingCoreWrapper` + `AudioEngine` reemplazan `NSLog` por `BeepingLog`
- `BeepingClient` propaga logLevel + traceID a wrapper + audio engine (mismo trace-ID compartido)
- `BeepingLogTests.swift` (13 tests) cubriendo redaction, generación trace-ID, level gating, sendable

**Hito alcanzado**: **8/16 tasks closed = 50% del milestone**. Half-way point.

**Net delta global**: 0 días (cerramos en plan; SP planeado=3, SP real ~3 — autoclosure fix + propagation chain)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados / Retrasados / Sin cambio
- (ninguno significativo a nivel milestone)
- BEE-75..BEE-82 (8 tasks restantes, 51 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅)

#### Velocity actualizada
- Day 4 (2026-05-01): +3 SP closed → cumulative **10.75 SP/día** across 4 working days
- 2.75 SP/día por encima del asumido 8 SP/día — buffer real ~5 días

#### Issue menor durante implementación
Primera versión usaba `@autoclosure () -> String` para evitar string construction si el log está gated, pero `os.Logger` rechaza `escaping autoclosure captures non-escaping parameter` (su interpolation evalúa lazily). Cambié a `String` plain — gating sigue funcionando, micro-perf perdida pero correctness ganada.

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(log): BEE-74 add BeepingLog wrapper + 7-level enum + trace-ID

---

### [2026-04-30] - Closed BEE-73 (partial: generator integration deferred to BEE-80)
**Trigger detallado**: BEE-73 (🔌 Cliente HTTP generado desde OpenAPI / swift-openapi-generator de Apple) cerrada en day 3 del milestone — 5ª task del día. Single commit con:
- `OpenAPI/openapi.yaml` (vendored copy del beepbox spec, 427 líneas, OpenAPI 3.1)
- `BeepboxAPITypes.swift` (~110 líneas) — Codable types **manually mirrored** matching la spec
- `CloudEncoder.swift` refactorizado a la spec REAL (auth `Authorization: Bearer` no X-API-Key, body `EncodeRequest{key}` no `{payload}`)
- `EncoderStrategyTests.swift` reescrito al contrato corregido + Codable round-trip tests
- `.github/workflows/ci.yml` con step "Validate vendored OpenAPI spec" (`ruby -ryaml`)

**Discovery importante durante el task**: BEE-71 implementó el CloudEncoder con un contrato preliminar que NO matcheaba la spec real de beepbox-server. El "escape hatch" de BEE-71 ("if CloudEncoder revela mismatch, ajustar contracto") se disparó. BEE-73 corrige.

**Scope honesty**: `swift-openapi-generator` como SwiftPM build plugin NO se integra en BEE-73 — requiere Package.swift (BEE-80). Lo que entrega BEE-73 es la **fundación**: spec vendoreada, Codable types hand-mirrored matching exactamente lo que el generator produciría, cliente HTTP type-safe + spec-correcto. BEE-80 hará el swap por generación automática.

**Net delta global**: 0 días (cerramos en plan; SP planeado=3, SP real=~3 — discovery+fix tomó la mitad)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados / Retrasados / Sin cambio
- (ninguno significativo a nivel milestone — buffer creciente queda en margen)
- BEE-74..BEE-82 (9 tasks restantes, 54 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅)

#### Velocity actualizada
- Day 3 (2026-04-30): +30 SP cerrados en total (BEE-69+70+71+72+73 = 5 tasks day 3)
- Cumulative velocity: **13.3 SP/día** across 3 working days
- 5.3 SP/día por encima del asumido 8 SP/día — buffer real de ~6 días si esta velocity se sostiene

#### Drift detection nota
La spec vendoreada es un snapshot. Sin generación automática, NO hay drift detection entre la spec y los Codable types hand-written. BEE-80 lo arregla. Mientras tanto: re-sync manual cuando beepbox actualice + revisar Codable types.

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(http): BEE-73 vendor openapi.yaml + Codable types + correct CloudEncoder contract

---

### [2026-04-30] - Closed BEE-72
**Trigger detallado**: BEE-72 (🛠️ Builder DSL: `.local()` / `.cloud(apiKey:endpoint:)`) cerrada en plan en day 3 del milestone (cuarta tarea del día — sesión muy productiva). Single commit con:
- `BeepingLogLevel.swift` (~25 líneas) — `public enum: Sendable, Equatable` placeholder, BEE-74 lo wireea a os.Logger
- `BeepingClientBuilder.swift` (~100 líneas) — `public struct: Sendable` fluent con `.mode/.logLevel/.telemetryEnabled/.build()`
- `BeepingClient` extended — internal init añade `logLevel` + `telemetryEnabled` parameters (defaults backwards-compat); `static func local()` + `static func cloud(apiKey:endpoint:)` factory methods
- `BuilderDSLTests.swift` (~120 líneas) — 9 Swift Testing tests cubriendo factories, build path, fluent chain preservation, defaults, Sendable, LogLevel cases

**Net delta global**: 0 días (cerramos en plan; SP planeado=3, SP real ~2 — groundwork de BEE-71 hizo trivial el wiring)
**Nueva fecha fin estimada**: 2026-05-18 (sin cambio)
**Nuevo estado global**: ✅ (sin cambio)

#### Adelantados (negativo = más pronto)
- (ninguno significativo a nivel milestone — buffer creciente queda en margen)

#### Retrasados (positivo = más tarde)
- (ninguno)

#### Sin cambio
- BEE-73..BEE-82 (10 tasks restantes, 57 SP remaining)

#### Cambios de estado de riesgo
- (ninguno — global ✅; BEE-80/81/82 al final siguen ⚠️ por dependencia con R1)

#### Velocity actualizada
- Day 3 (2026-04-30): +27 SP cerrados en total (BEE-69 + BEE-70 + BEE-71 + BEE-72) → cumulative **12.3 SP/día** across 3 working days
- 4.3 SP/día por encima del asumido 8 SP/día — buffer ~5+ días si esta velocity se sostiene

#### Stub features documentadas (no actuadas en BEE-72)
- `BeepingLogLevel` settings se guardan en el actor pero no se actúan; wiring real en BEE-74 (os.Logger + custom wrapper + trace-IDs)
- `telemetryEnabled` flag se guarda pero no se actúa; wiring real en BEE-75 (telemetry hook)

#### Commits relacionados (en `milestone/phase-9`)
- `<este commit>` — feat(api): BEE-72 add BeepingClientBuilder fluent DSL + factory methods

---

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
