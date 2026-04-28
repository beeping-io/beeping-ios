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
- **Última actualización**: 2026-04-28 (trigger: Closed BEE-67 — net delta 0 days)

| # | Milestone | Story points | Inicio est. | Fin est. | Estado |
|---|---|---|---|---|---|
| 1 | 🍎 Phase 9 — beeping-ios (Swift 6) | 94 (16 tasks; 2 closed, 92 remaining) | 2026-04-28 | 2026-05-18 | ✅ |

---

## 📜 History

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
