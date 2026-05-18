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

### ⏳ pending-001 — release.yml debe reescribir Package.swift por release

- 🆔 ID: pending-001
- 📅 Fecha: 2026-05-18
- 🏷️ Tipo: `infra`
- 🚦 Estado: 🆕 Nuevo

**Contexto / trigger**: Tras shipping de v0.1.0 + v0.1.1, vemos que `Package.swift` en main / en el tag ship con el URL+checksum del release ANTERIOR — no del propio. Workaround actual: bump manual con `Release-As:` para sincronizar (ver PR #11 → v0.1.1). Consumidores pinning a `from: "0.X.0"` resuelven el tag más reciente y obtienen la `Package.swift` apuntando al binario un release atrás. Funcional, pero requiere un release de fix después de cada release "real".

**Acción**: añadir step en `.github/workflows/release.yml` después de `cosign sign-blob` + `sha256` que:

1. Calcule la URL del asset (`https://github.com/beeping-io/beeping-ios/releases/download/${TAG}/Beeping.xcframework.zip`)
2. Compute el sha256 del zip recién creado (ya disponible en `Beeping.xcframework.zip.sha256`)
3. `sed`-reescriba `Package.swift` en main para que `binaryTarget(url:checksum:)` coincida
4. Commit + push a main con mensaje `chore(release): pin Package.swift to ${TAG} assets`
5. Force-recree el tag `${TAG}` sobre el nuevo commit
6. Push del tag (`git push origin --force-with-lease ${TAG}`)

Resultado: cada tag `vX.Y.Z` apunta a su PROPIO binario, no al del release anterior. Elimina el `Release-As:` ping-pong.

**Notas**:
- Force-tag-update es destructive y debe documentarse en el workflow
- Alternativa: usar `release-please`'s `extra-files` con substitución por marcador (`# x-release-please-version`), pero solo permite la versión, no el checksum (que no se conoce hasta el build)
- Validar el flow end-to-end con un consumidor SPM antes de cerrar

