# ⏳ Pending

Captura **trabajo conocido pero aún sin fecha** — el "lo haremos algún día pero
no ahora".

🎯 **Aquí entra**: deuda detectada, follow-ups de incidentes, feedback accionable,
"esto hay que hacerlo pero no hemos decidido cuándo".
🚫 **Aquí NO entra**: trabajo ya agendado a un milestone (eso va a Linear).

🪄 **Promoción**: ponerle un milestone a un pending lo convierte en task Linear
`BEE-XXXX` y se elimina automáticamente de este fichero.

---

## 📋 Cómo añadir un pending

Usa el skill `/pending` (recomendado). O copia este bloque al final del fichero:

```markdown
### ⏳ pending-NNN — [Título corto]

- 📅 **Fecha añadida**: YYYY-MM-DD
- 🏷️ **Tipo**: feat | fix | docs | refactor | chore | infra | security | test
- 🧭 **Trigger**: por qué se añadió (incidente, feedback, deuda)
- ⚙️ **Acción requerida**: qué hay que hacer concretamente
- 🚧 **Bloqueado por**: (si aplica) algo o alguien que retrasa
- 🚦 **Estado**: 🆕 Nuevo
```

### 🏷️ Tipos disponibles

| Tipo | Cuándo usarlo |
|------|---------------|
| `feat` | Funcionalidad nueva |
| `fix` | Bug fix |
| `docs` | Solo documentación |
| `refactor` | Refactor sin cambio de comportamiento |
| `chore` | Mantenimiento, deps, config |
| `infra` | Infraestructura, CI/CD |
| `security` | Cuestiones de seguridad |
| `test` | Solo tests |

### 🚦 Estados posibles

| Iconito | Estado | Significado |
|---------|--------|-------------|
| 🆕 | Nuevo | Recién capturado, sin triage |
| 🔍 | En triage | Decidiendo prioridad / scope |
| 📋 | Promovido | Ya es task Linear (`BEE-XXXX`) — debería haberse eliminado de aquí |
| 🚧 | Bloqueado | Esperando algo externo (especificar) |
| ❌ | No procede | Decidido no avanzar (apuntar el porqué) |

---

## 🗂️ Pendientes registrados

> _pending-001 promovida a BEE-2259 (Done en v0.1.2)._
> _pending-002 promovida a BEE-2327 (Phase 9)._

### ⏳ pending-003 — 💥 `AudioEngine.start()` aborta el proceso si la sesión de audio no activa

- 📅 **Fecha añadida**: 2026-07-22
- 🏷️ **Tipo**: fix
- 🧭 **Trigger**: encontrado durante el Human QA Checkpoint de BEE-92 (`beeping_flutter`), intentando usar el Simulador de iOS como segundo dispositivo. La app crashea de forma reproducible a los ~14 s con `SIGABRT`:

  ```text
  AURemoteIO::Start() → _ReportRPCTimeout → abort
  BCAudioUnitController start
  ```

- ⚙️ **Acción requerida**: en `AudioEngine.swift`,

  ```swift
  internal func start() {
      configureAudioSession()   // el catch solo hace log.error y sigue
      _ = _controller.start()   // arranca igual y descarta el OSStatus
  }
  ```

  1. `configureAudioSession()` pasa a `throws` y relanza como `BeepingError.missingMicrophonePermission` — el caso **ya está declarado** en `BeepingError.swift`, documentado exactamente para esto, y nadie lo lanza.
  2. `start()` pasa a `throws` y **no llama a `_controller.start()`** si la sesión no activó. Este es el paso que evita el `abort()`: la llamada aborta desde dentro (código de Apple), así que comprobar su retorno a posteriori no sirve.
  3. Dejar de descartar el `OSStatus` de `_controller.start()`; añadir un caso `audioUnitStartFailed(OSStatus)` para fallos que no sean de permisos.

  Nota: `BCAudioUnitController.start` (ObjC++) **sí** comprueba y devuelve el `OSStatus` correctamente. El defecto está solo en la capa Swift.

- 🚧 **Bloqueado por**: nada técnico. Al arreglarlo hace falta release de `beeping-ios`, porque `beeping_flutter_ios` fija `Beeping ~> 0.2.0` desde CocoaPods y no vería el cambio; para validar antes, apuntar el pod a un `:path` local.
- 🚦 **Estado**: 🆕 Nuevo

**Impacto en hardware**: con el permiso concedido en un iPhone real no se manifiesta (verificado: la app aguanta estable en `listening…`). Sigue latente si otra app se queda la sesión de audio, entra una llamada, o se revoca el micro con la app en segundo plano — casos que en producción acabarían apareciendo como crash en vez de como error mostrable.

