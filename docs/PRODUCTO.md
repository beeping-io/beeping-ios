# 🍎 beeping-ios — Documento de producto

> Source of truth del scope y timeline del SDK iOS del ecosistema Beeping.
> Vive junto al código (regla taxonomía global: code-adjacent docs → git).
> Cualquier cambio de scope dispara entrada en `docs/ROADMAP_CHANGELOG.md`.

---

## 1 · 📌 Información básica

| Campo | Valor |
|---|---|
| **Nombre** | `beeping-ios` |
| **Tag** | 🍎 |
| **Versión actual** | `0.0.0` (regla 0.x del ecosistema Beeping) |
| **Fecha de inicio** | 2026-04-28 |
| **License** | Apache-2.0 |
| **GitHub** | `beeping-io/beeping-ios` (público) |
| **Branch base** | `develop` |
| **Linear project** | 🔊 Beeping Platform · id `a83369a5-3cb8-4fca-932d-ee33f6a7a00e` |
| **Linear milestone** | 🍎 Phase 9 — beeping-ios (Swift 6) · id `3b2f36a8-b6e7-4202-8748-1a8c8ec65d21` |
| **Distribución primaria** | Swift Package Manager (`Package.swift` con `.binaryTarget`) |
| **Distribución secundaria** | CocoaPods podspec (`Beeping.podspec`) + GitHub Releases con XCFramework firmado |

---

## 2 · ❓ Qué es

**`beeping-ios` es el SDK oficial iOS del ecosistema Beeping**: una librería Swift 6 que permite a apps iOS **codificar y decodificar datos transmitidos por sonido** (audible + ultrasónico), usando el core C++ `beeping-core` via ObjC++ bridge o el servidor HTTP `beepbox-server` via URLSession.

Expone una API pública Swift moderna (actor-based, `AsyncStream`-based, strict concurrency) y se distribuye como Swift Package primario más CocoaPods secundario, con XCFramework firmado en GitHub Releases.

---

## 3 · 🎯 Objetivo medible

Publicar **`beeping-ios` v0.0.0` en GitHub Releases** (Swift Package + CocoaPods + XCFramework firmado) completando los 16 tasks de Phase 9 (BEE-67..BEE-82, 94 story points totales) con:

- ✅ Migración ObjC → Swift 6 completa con strict concurrency (Sendable, actors)
- ✅ iOS 15 mínimo + `PrivacyInfo.xcprivacy` con declared API reasons
- ✅ API pública nueva `BeepingClient` actor + `AsyncStream<BeepingEvent>`
- ✅ Strategy pattern dual-mode (`LocalEncoder` C++ via ObjC++ + `CloudEncoder` URLSession)
- ✅ Cliente HTTP generado vía swift-openapi-generator (Apple oficial)
- ✅ Tests: XCTest + Swift Testing + snapshot-testing + SwiftCheck property
- ✅ Sample app SwiftUI con debug console
- ✅ XCFramework firmado (GPG + cosign) publicado en GitHub Releases
- ✅ Lint strict (SwiftLint + swift-format) verde en CI

---

## 4 · 🚧 Restricciones clave

- **iOS 15.0 mínimo** (compat con `async/await`, actors, AsyncStream nativos)
- **Swift 6** con strict concurrency (Sendable obligatorio, actors para estado mutable)
- **Xcode 16+** para el build (Swift 6 requiere Xcode 16)
- **Architectures soportadas**: `arm64` (device + simulator Apple Silicon) + `x86_64` (simulator Intel legacy)
- **`PrivacyInfo.xcprivacy` obligatorio** con declared API reasons (regulación Apple desde mayo 2024)
- **Native binary NO vendoreado a partir de BEE-79**: `libBeepingCoreUniversal.a` actual es legacy; el target final consume `beeping-core` desde GitHub Releases
- **API pública estable a partir de 1.0.0**: en `0.x` la API puede romper entre minor bumps
- **Apache-2.0 obligatorio**: regla ecosistema, no negociable
- **Conventional Commits + commitlint preset compartido** (`@beeping-io/commitlint-config`)
- **Branch protection** en `develop` y `main`: PR + 1 review + linear history + signed commits + sin force push
- **Swift Package Manager primario, CocoaPods secundario**: SPM nativo Apple, CocoaPods sólo para compat con Flutter plugins / RN módulos legacy

---

## 5 · 🌐 Entorno y distribución

### Plataformas soportadas
- iOS 15.0+ (iPhone + iPad)
- iPadOS 15.0+
- macCatalyst 15.0+ (best-effort, sin tests dedicados)
- visionOS, watchOS, tvOS: **fuera de scope** Phase 9

### Modos runtime (dual-mode strategy)
- **`.local`** → encoding/decoding en el dispositivo via ObjC++ bridge a `libbeepingcore.a` (XCFramework). No requiere red. Latencia mínima. Privacy-first.
- **`.cloud(apiKey:endpoint:)`** → encoding/decoding via HTTP a `beepbox-server` (`POST /v1/encode`, `POST /v1/decode`). Requiere red + API key. Útil para devices low-end o feature gating.

### Canales de distribución
- **Primario**: Swift Package Manager → `Package.swift` con `.binaryTarget` apuntando a XCFramework firmado en GitHub Releases
- **Secundario**: CocoaPods (`Beeping.podspec`) — útil para Flutter plugins / React Native modules que aún no consumen SPM
- **GitHub Releases** con `Beeping.xcframework.zip` firmado (GPG + cosign keyless cuando esté disponible) + checksum SHA256
- **NO**: Carthage (deprecado), distribución manual via Drag & Drop como canal primario

---

## 6 · ✅ Alcance — qué incluye

Phase 9 (16 tasks, 94 SP). Orden por dependencia (sortOrder Linear ascendente):

| # | Linear | SP | Título |
|---|---|---|---|
| 1 | BEE-67 | 2 | 🏷️ Rename `sdk-iphone` → `beeping-ios` + Apache-2.0 + Conventional Commits |
| 2 | BEE-68 | 13 | 🔄 Migración completa ObjC → Swift 6 con strict concurrency (Sendable, actors) |
| 3 | BEE-69 | 3 | 🔒 iOS 15 mínimo + `PrivacyInfo.xcprivacy` con declared API reasons |
| 4 | BEE-70 | 8 | 🌊 API pública nueva: `BeepingClient` actor-based + `AsyncStream<BeepingEvent>` |
| 5 | BEE-71 | 8 | 🎭 Strategy pattern: `LocalEncoder` (C++ via ObjC++) + `CloudEncoder` (URLSession) |
| 6 | BEE-72 | 3 | 🛠️ Builder DSL: `.local()` / `.cloud(apiKey:endpoint:)` |
| 7 | BEE-73 | 3 | 🔌 Cliente HTTP generado desde OpenAPI (swift-openapi-generator de Apple) |
| 8 | BEE-74 | 3 | 🪵 Logging `os.Logger` (modern Apple) + custom wrapper + trace-ID + niveles |
| 9 | BEE-75 | 5 | 📡 Telemetry hook con opt-out + tests de privacy |
| 10 | BEE-76 | 13 | 🧪 Tests: XCTest + Swift Testing + snapshot-testing + SwiftCheck property |
| 11 | BEE-77 | 2 | 🧼 SwiftLint + swift-format en CI |
| 12 | BEE-78 | 8 | 📱 Sample app rewrite con SwiftUI + debug console |
| 13 | BEE-79 | 5 | 🔗 Consumir `beeping-core` via GitHub Releases (no `.a` vendoreado) |
| 14 | BEE-80 | 8 | 📦 Swift Package (`Package.swift` con `.binaryTarget`) + XCFramework firmado |
| 15 | BEE-81 | 5 | 🍫 CocoaPods podspec secundario (compat Flutter plugins) |
| 16 | BEE-82 | 5 | 🚀 release-please + cosign + GitHub Releases con XCFramework firmado |
|   | **Total** | **94** | |

---

## 7 · 🚫 Qué NO incluye

- ❌ App de producción end-user (eso es `beeply` Flutter / Phase 18)
- ❌ SDK Android (`beeping-android` / Phase 8)
- ❌ SDK Flutter (`beeping_flutter` / Phase 10)
- ❌ SDK React Native (`beeping-react-native` / Phase 12)
- ❌ Server-side SDK Node/Python (Phase 13)
- ❌ Web/WASM SDK (`beeping-web` / Phase 11)
- ❌ Backend HTTP server (`beepbox` / Phase 2)
- ❌ Core C++ (`beeping-core` / Phase 1)
- ❌ Marketing site (`beeping-www` / Phase 20)
- ❌ Docs hub (`beeping-docs` / Phase 19)
- ❌ Soporte iOS <15.0
- ❌ Soporte visionOS / watchOS / tvOS / macOS standalone (sólo macCatalyst best-effort)
- ❌ Distribución via Carthage o copy-paste manual como canal primario
- ❌ Backwards-compat con la API legacy `Beeping.instance` + `beepingDelegate` ObjC

---

## 8 · 🔁 Cambios de alcance

Cualquier alteración (añadir/quitar tarea de Phase 9, ajustar story points, recalibrar velocidad) **DEBE** disparar:

1. Edición de la descripción de Phase 9 en Linear (o issue/task individual).
2. Recálculo de `docs/ROADMAP.md`.
3. Nueva entrada al inicio de la sección History de `docs/ROADMAP_CHANGELOG.md` con trigger `Scope change` o `Velocity recalibration`.
4. Commit conjunto `ROADMAP.md` + `ROADMAP_CHANGELOG.md` en el mismo PR.

Regla canónica del ecosistema: **el ROADMAP y su CHANGELOG nunca van por separado.**

---

## 9 · 🧭 Principios de producto

1. **Public API actor-based, no singletons.** Lifecycle controlado por el consumer; testeable sin shenanigans; thread-safe by construction (Swift 6 strict concurrency).
2. **`AsyncStream<BeepingEvent>` first-class.** Callbacks delegate legacy quedan fuera; consumers ObjC acceden via interop bridges.
3. **Privacy-first.** Telemetry opt-out por defecto; cero PII en logs; redaction por contrato (BEE-75); `PrivacyInfo.xcprivacy` declarando uso de APIs sensibles.
4. **Dual-mode invisible al consumer.** Mismo `BeepingClient` API independientemente de Local vs Cloud — la decisión es declarativa al construir.
5. **Open source Apache-2.0.** Sin features behind closed source; pricing/auth se hace fuera (en `beepbox-server`).
6. **Distribución por package manager oficial.** SPM primario, CocoaPods secundario; cero `git+url://` en producción.
7. **Zero state global.** Cualquier estado vive en el actor `BeepingClient`.
8. **Strict mode por defecto en CI.** SwiftLint + swift-format con cero warnings — no "0 nuevos", sino **0 totales**.

---

## 10 · 🌊 Flujo principal

```swift
// 1) Consumer añade dependencia (Swift Package Manager)
// .package(url: "https://github.com/beeping-io/beeping-ios", from: "0.0.0")

import Beeping

// 2) Construye BeepingClient declarando el modo
let client = BeepingClient(
    mode: .local                                    // o .cloud(apiKey: "...", endpoint: URL(string: "https://api.beeping.io")!)
)

// 3) Listen — AsyncStream que emite eventos del decoder
Task {
    for await event in await client.listen() {
        switch event {
        case .started:
            // sesión arriba (mic permission OK, audio session ready)
            break
        case .decoded(let payload):
            handle(payload)
        case .failed(let reason):
            handle(reason)
        case .stopped:
            break
        }
    }
}

// 4) Encode + emit (async)
let pcm = try await client.encode("HOLA1")          // returns Data PCM
try await client.play(pcm)

// 5) Stop
await client.stop()
```

Internamente:
- **`.local`**: `LocalEncoder` invoca C++ via ObjC++ bridge a `libbeepingcore.a` (consumido desde GitHub Releases de `beeping-core` post-BEE-79).
- **`.cloud`**: `CloudEncoder` usa `URLSession` async + cliente generado por swift-openapi-generator a `POST /v1/encode` / `POST /v1/decode` con API key.

---

## 11 · ⚠️ Estados y errores

### Estados públicos (`enum BeepingEvent: Sendable`)

- `.started` — la sesión arrancó (mic permission, audio session active, ObjC++/HTTP listo).
- `.decoded(BeepingPayload)` — un beep válido se ha decodificado.
- `.failed(BeepingError)` — error recuperable o no recuperable.
- `.stopped` — sesión cerrada (manualmente o por error fatal).

### Tipos de error (`enum BeepingError: Error, Sendable`)

- `.missingMicPermission` (recuperable: el consumer pide permission y reintenta)
- `.audioSessionInterrupted` (recuperable: el consumer espera fin de interrupción y reintenta)
- `.nativeLibraryNotLoaded` (no recuperable en `.local`: faltan binarios nativos)
- `.networkError(underlying:)` (recuperable en `.cloud`: retry con backoff)
- `.authenticationFailed` (no recuperable en `.cloud`: API key inválida)
- `.rateLimited(retryAfter:)` (recuperable en `.cloud`)
- `.decoderInternal(underlying:)` (no recuperable: bug del SDK)

### Throwing functions vs stream events

- **Stream events**: `.failed` se emite a través de `AsyncStream` para errores que ocurren durante la sesión `listen()`.
- **Throwing functions**: las funciones `async throws` (`encode`, `play`, `stop`) lanzan `BeepingError` directamente para errores síncronos al setup.

---

## 12 · 📐 Requisitos no funcionales

| Categoría | Requisito |
|---|---|
| **Tests cobertura** | ≥ 80% line coverage en target `Beeping` (BEE-76) |
| **Tests calidad** | snapshot-testing para SwiftUI sample app + property-based con SwiftCheck en encoder/decoder paths |
| **CI tiempo** | < 12 min build + test + lint full pipeline (más lento que Android por overhead Xcode) |
| **XCFramework tamaño** | XCFramework < 10 MB (legacy `libBeepingCoreUniversal.a` es 18 MB; BEE-79 lo reemplaza por slices delgadas por arch) |
| **Latencia decode** | < 200 ms desde fin de chirp hasta emisión de `.decoded` (`.local`) |
| **Latencia decode** | < 1500 ms (`.cloud`) — depende de RTT |
| **Memory** | Steady-state < 30 MB durante listen |
| **Privacy** | Cero PII en logs, telemetry opt-out por defecto, audit anual de eventos emitidos, `PrivacyInfo.xcprivacy` declarando APIs sensibles |
| **A11y** | Sample app pasa Accessibility Inspector sin issues bloqueantes |
| **i18n** | Sample app: EN + ES |
| **Reliability** | Maneja audio session interrupciones, mic permission revoked at runtime, network drop, app backgrounding |
| **Strict concurrency** | Cero `@unchecked Sendable`, cero data race warnings, todo el target compila con `-strict-concurrency=complete` |

---

## 13 · 🛠️ Stack técnico

### Build & toolchain
- **Swift 6** con strict concurrency
- **Xcode 16+**
- **`swift-tools-version:6.0`** en Package.swift
- **iOS 15.0** mínimo
- **AppleClang** + **ObjC++** (para bridge C++ ↔ Swift)
- **CMake** sólo en `beeping-core` upstream — aquí consumimos artefactos pre-built

### Runtime
- **Swift Concurrency** (actors, `async/await`, `AsyncStream`, `TaskGroup`)
- **AVFoundation** (audio session + capture)
- **swift-openapi-generator** + **URLSession transport** (CloudEncoder)
- **`os.Logger`** (structured logging Apple) + custom wrapper con trace-ID
- **ObjC++** → `libBeepingCoreUniversal.a` / XCFramework de `beeping-core` (post-BEE-79)

### Tests
- **XCTest** (legacy + integración)
- **Swift Testing** (`@Test`, parametrizado, framework moderno Apple a partir de Xcode 16)
- **swift-snapshot-testing** (PointFree) — snapshots de SwiftUI views + JSON
- **SwiftCheck** — property-based tests del encoder/decoder

### Lint & format
- **SwiftLint** (config en `.swiftlint.yml`, strict mode)
- **swift-format** (config en `.swift-format`)
- **0 warnings totales** en CI (gate)

### Publishing & release
- **Swift Package Manager** primario (`Package.swift` con `.binaryTarget` referenciando XCFramework remoto firmado)
- **CocoaPods** secundario (`Beeping.podspec` apuntando al mismo XCFramework de Releases)
- **XCFramework** generado desde Xcode + `xcodebuild -create-xcframework` (universal: device arm64 + simulator arm64 + simulator x86_64)
- **GPG signing** del .zip + checksum SHA256
- **release-please** (automated SemVer + changelog + tag + GH Release)
- **cosign keyless** (Sigstore) cuando esté disponible
- **GitHub Releases** con SBOM (CycloneDX) y SLSA L3 provenance

---

## 14 · 🧩 Componentes principales

### Target `Beeping` (la SDK library, Swift)

| Tipo / clase | Rol | Tipo |
|---|---|---|
| `BeepingClient` | Punto de entrada público, actor-based | `actor` |
| `BeepingMode` | `.local` / `.cloud(apiKey:endpoint:)` | `enum` |
| `BeepingEvent` | `.started` / `.decoded` / `.failed` / `.stopped` | `enum` |
| `BeepingPayload` | Datos decodificados + metadata (mode, timestamp, confidence) | `struct: Sendable` |
| `BeepingError` | Jerarquía de errores | `enum: Error, Sendable` |
| `Encoder` | Protocol strategy | `protocol: Sendable` |
| `LocalEncoder` | Implementación ObjC++ a `libbeepingcore` | `internal struct` |
| `CloudEncoder` | Implementación URLSession a beepbox-server | `internal struct` |
| `BeepingAPI` (generated) | OpenAPI client para beepbox-server | generated por swift-openapi-generator |
| `TelemetryHook` | Hook opt-in con event emit | `protocol` |
| `AudioSessionManager` | Gestión `AVAudioSession` + interrupciones | `internal actor` |

### Target `BeepingC` (ObjC++ bridge, internal)

| Header | Rol |
|---|---|
| `BeepingCoreBridge.h` / `.mm` | Bridge ObjC++ a la API C de `BeepingCoreLib_api.h` |
| `module.modulemap` | Exposición Clang module para Swift |

### Target `BeepingSampleApp` (sample app SwiftUI)

App SwiftUI demostrativa que:
- Lista los modos (`.local` / `.cloud`) seleccionables.
- Muestra el debug console con eventos `BeepingEvent` en tiempo real.
- Permite simular permission denied / audio interruption / network drop.
- Tiene smoke E2E con XCUITest.
- **NO** es una app de producción (eso es `beeply` / Phase 18).

---

## 15 · 🔗 Integraciones externas

| Integración | Para qué | Cómo |
|---|---|---|
| **`beeping-core`** | Native lib `libbeepingcore.a` (XCFramework universal) | Download desde GitHub Releases por arch en build-time (BEE-79) |
| **`beepbox-server`** | Endpoints `/v1/encode`, `/v1/decode`, `/v1/healthz` | URLSession + cliente generado de OpenAPI 3.1 (BEE-73) |
| **swift-openapi-generator** | Generación cliente HTTP type-safe | Plugin SwiftPM (BEE-73) |
| **swift-snapshot-testing** | Snapshots SwiftUI + JSON | SPM dep en target de tests (BEE-76) |
| **SwiftCheck** | Property-based tests | SPM dep en target de tests (BEE-76) |
| **release-please** | Releases automatizados | GitHub Action |
| **GitHub Actions** | CI/CD | `.github/workflows/ci.yml` |
| **Sigstore (cosign)** | Firmado keyless | Step en release workflow (cuando SLSA L3 esté ready) |

---

## 16 · 🧪 Decisiones técnicas

### DT-01: API actor-based en vez de singleton ObjC
**Por qué**: La API legacy usaba `[Beeping instance]` con state interno y delegate ObjC. Frágil para tests, lifecycle confuso, no thread-safe por contrato. Actor-based + Swift 6 strict concurrency permite multi-session, testing puro, y elimina data races por construcción.

### DT-02: `AsyncStream<BeepingEvent>` en vez de delegate
**Por qué**: AsyncStream integra con structured concurrency y se cancela automáticamente con el `Task`. Los delegates ObjC requieren rebote manual a main queue, ciclo de retain/release error-prone, y no componen con `async/await`. Consumers ObjC pueden acceder via interop helper `@objc class BeepingClientObjC`.

### DT-03: Strategy pattern Local/Cloud transparente
**Por qué**: Permite switching declarativo via `BeepingMode` sin cambiar el código consumer. Local minimiza red + privacy; Cloud habilita feature gating, low-end devices, y telemetry centralizada. La factoría es interna; el consumer no instancia `Encoder` directamente.

### DT-04: SPM primario, CocoaPods secundario
**Por qué**: SPM es nativo Apple, integrado en Xcode, sin dependencias externas (Ruby/CocoaPods). CocoaPods sigue siendo necesario para Flutter plugins (BEE-81 — `beeping_flutter` lo consume) y RN modules legacy. Mantenemos ambos pero invertimos prioridad respecto al SDK legacy.

### DT-05: Native lib consumida, no vendoreada
**Por qué**: El `libBeepingCoreUniversal.a` (18 MB) actualmente vendoreado es de Apr 2025, sin trazabilidad de versión, y bloatea el repo. Consumirlo de releases firmadas de `beeping-core` da: trazabilidad (versión pin en `Package.swift`), seguridad (firma + SBOM), y workflow consistente con `beeping-android` (Phase 8).

### DT-06: Swift 6 sin compatibilidad ObjC legacy de la API pública
**Por qué**: La API actual ObjC usa `[Beeping instance].delegate = self` con un protocol no-Sendable. Refactor reescribe toda la capa pública en Swift 6. Consumers ObjC acceden via wrapper `@objc` opcional generado, no via la API "real". El bridge ObjC++ `BeepingC` sigue existiendo internamente sólo para llamar a la C API de `beeping-core`.

### DT-07: swift-openapi-generator (Apple) en vez de cliente HTTP custom
**Por qué**: Apple oficial, type-safe, mantenido, integrado con SPM. Genera tipos `Sendable` y funciones `async throws` automáticamente. Alternativas (Alamofire, Moya, manual URLSession) requieren mantener serialización a mano y rompen Sendable.

### DT-08: `os.Logger` (modern Apple) en vez de wrapper third-party
**Por qué**: Apple oficial, integrado con Console.app + Instruments, soporta privacy redaction declarativa (`\(value, privacy: .private)`), zero deps. Custom wrapper sólo para añadir trace-IDs y inyectar telemetry hook.

### DT-09: Telemetry opt-out con auditoría
**Por qué**: Privacy es principio del producto. Opt-out por defecto, tests automáticos verifican que ningún evento sale sin opt-in. Hook `TelemetryHook` permite al consumer inyectar su propio sink (Sentry, Firebase, Datadog, etc.).

### DT-10: `PrivacyInfo.xcprivacy` declared API reasons
**Por qué**: Apple lo exige desde mayo 2024 para apps que se publican en App Store. Aunque el SDK no se publica solo, las apps que lo integren lo necesitan en su bundle. Declaramos APIs sensibles usadas (audio capture timestamps) con la `reason code` correcta para no romper a los consumers.

---

## 17 · 👥 Usuarios target

### Primario
**Desarrolladores iOS Swift** integrando data-over-sound en sus apps. Casos de uso conocidos:
- Intercambio de tarjetas de contacto en eventos / conferencias / networking
- Pairing de devices (POS, kiosk, IoT)
- Watermarking de TV ads / second-screen experiences
- Proximity 2FA / unlock
- Multiplayer local sin red
- Cupones in-store / wallet / loyalty

### Secundario
**Desarrolladores iOS ObjC** legacy — acceso via wrapper `@objc class BeepingClientObjC` opcional. No prioritario.

### Terciario
**Maintainers de plugins cross-platform** (Flutter, React Native, Capacitor) — consumen `beeping-ios` via CocoaPods (BEE-81) o SPM (BEE-80) según su tooling.

### Anti-target
- Devs que necesitan transmisión de archivos grandes (Beeping es para payloads pequeños, ~5-9 chars).
- Apps requiriendo iOS <15.0.

---

## 18 · 📊 Métricas de éxito

| Métrica | Target | Cuándo medir |
|---|---|---|
| **Phase 9 completada** | 16/16 tasks closed | Fin de Phase 9 |
| **GitHub Release v0.0.0 live** | XCFramework + checksum + signature publicados | Tras BEE-82 |
| **SPM resoluble** | `swift package resolve` con URL del repo OK | Tras BEE-80 |
| **CocoaPods resoluble** | `pod lib lint Beeping.podspec` verde | Tras BEE-81 |
| **CI green ratio** | ≥ 95% en `develop` | Continuo |
| **Lint warnings** | 0 totales | Continuo (BEE-77) |
| **Coverage** | ≥ 80% line | Tras BEE-76 |
| **Sample app E2E** | Verde Local + Cloud | Tras BEE-78 |
| **XCFramework size** | < 10 MB | Tras BEE-79 |
| **Build time (cold)** | < 8 min en CI runner | Tras BEE-80 |
| **Build time (incremental)** | < 30 s local | Continuo |
| **Strict concurrency warnings** | 0 totales | Tras BEE-68 |

---

## 19 · ⚡ Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R1 | **`beeping-core` releases delay** — BEE-79 depende de que Phase 1 entregue XCFramework firmado en GH Releases | Media | Alto (bloquea Phase 9) | Fallback temporal: usar `libBeepingCoreUniversal.a` actual hasta que Phase 1 entregue. Documentar versión pin con `// TODO BEE-79: replace with release pin`. |
| R2 | **Sonatype / Apple notarization** del XCFramework requerirá Apple Developer ID $99/año | Alta | Bajo (sólo notarización) | Notarización es opcional para distribución por SPM/CocoaPods (sólo App Store la exige). Skip notarización en v0.x; revisar para v1.0. |
| R3 | **Swift 6 strict concurrency** podría requerir refactors profundos del bridge ObjC++ | Alta | Medio | BEE-68 incluye spike de strict concurrency mode. Si bloquea, marcar el target ObjC++ con `@preconcurrency import` temporal y abrir BEE follow-up. |
| R4 | **swift-openapi-generator API churn** (proyecto < 1.0 todavía) | Media | Medio | Pin minor version en Package.swift. Si breaking change, evaluar URLSession manual + Codable como fallback. |
| R5 | **Telemetry opt-out edge cases** filtran datos por error | Baja | Alto (privacy breach) | BEE-75 incluye tests automáticos de privacy: assertion de zero events sin opt-in. |
| R6 | **API legacy consumers downstream** rompen con el rewrite | Baja | Bajo | No hay consumers downstream activos del SDK legacy publicados. Nuevo SDK = nuevo coordinates `beeping-io/beeping-ios`. |
| R7 | **CocoaPods vs SPM XCFramework dual-distribution drift** | Media | Medio | Pipeline de release single-source: el `Beeping.xcframework.zip` de GitHub Releases lo consumen ambos. Test en CI que ambos resuelven la misma URL. |
| R8 | **Xcode 16 mínimo excluye dev environments legacy** | Baja | Bajo | Documentar Xcode 16 requisito en `README.md`; CI matrix sólo Xcode 16. |

---

## 20 · 📅 Timeline

Detalle vivo en `docs/ROADMAP.md` (snapshot fechado por el motor de scheduler) + history en `docs/ROADMAP_CHANGELOG.md`.

**Resumen al 2026-04-28** (init):
- **1 milestone**: Phase 9 — beeping-ios (Swift 6)
- **16 tasks**: BEE-67..BEE-82
- **94 story points** totales
- **Velocidad asumida**: 8 SP/día (default ecosistema)
- **Esfuerzo bruto**: 94 / 8 = ~11.75 días hábiles
- **Con 20% margen de riesgo**: ~14 días hábiles → **15 días redondeado**
- **Fecha fin estimada**: 2026-05-18 (lun) si arrancamos hoy y trabajamos lineal

Estado al init: **✅ En tiempo** (sin tareas cerradas todavía).

Cualquier task que se cierre antes/después de su SP estimado **dispara recálculo** del ROADMAP + entrada en CHANGELOG (regla canónica `/worktree-start` Paso 7).

---

## 📎 Referencias

- Global methodology: `~/.claude/CLAUDE.md`
- Beeping Platform Linear project: `https://linear.app/me8/project/03da887d924e`
- Phase 9 milestone: `https://linear.app/me8/project/03da887d924e?selectedProjectMilestone=3b2f36a8-b6e7-4202-8748-1a8c8ec65d21`
- Sister SDK Android (Phase 8): `beeping-io/beeping-android`
- Conventions (commit + branch + PR + Renovate): `beeping-io/beeping-meta` → `CONVENTIONS.md`
- Brand kit: `beeping-io/beeping-meta` → `brand/`
- Code of Conduct + Security: `beeping-io/beeping-meta` → `CODE_OF_CONDUCT.md`, `SECURITY.md`
