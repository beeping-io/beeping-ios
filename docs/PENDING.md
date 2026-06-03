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

### ⏳ pending-002 — Exponer métodos C menores no bridgeados de beeping-core

- 📅 **Fecha añadida**: 2026-06-02
- 🏷️ **Tipo**: feat
- 🧭 **Trigger**: Auditoría 2026-06-02 del C API de `beeping-core` v0.8.1 — el bridge `BeepingC.mm` envuelve 18/24 funciones. El gap serio (scheduler decode) se promovió a BEE-2312; estos son los restantes menores, sin demanda concreta todavía.
- ⚙️ **Acción requerida**: evaluar/exponer según se necesite:
  - `BEEPING_GetVersionInfo` — version/build extendida (hoy solo `BEEPING_GetVersion` está expuesto vía `BCNativeCore.version`).
  - `BEEPING_SetAudioSignature` — custom audio signature / watermark; feature no expuesta en el SDK.
  - `BEEPING_ResetEncodedAudioBuffer` — helper de lifecycle del buffer de encode.
  - `BEEPING_SetLogPath` — **descartado a propósito**: iOS usa `os.Logger` (BEE-74), no log a fichero. Documentar el skip si se formaliza.
- 🚦 **Estado**: 🆕 Nuevo

