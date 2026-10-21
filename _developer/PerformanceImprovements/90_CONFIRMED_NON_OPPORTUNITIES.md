# Confirmed Non-Opportunities and Deferred Hypotheses

This register prevents repeated speculative work. Reopen an item only with new current-source evidence or an isolated profile identifying it as material.

## Confirmed non-opportunities

### Recurring UnitStats whole-map scan

Historical analysis describes a repeated three-second full-map scan. Current `UnitSystems/UnitStats.j` performs a one-time initialization scan followed by event-driven updates. Do not disable, slow or rewrite UnitStats based on the stale report.

### UnitHider3 world-scan rewrite

Current `UnitSystems/UnitHider4.j` is v4.12, performs a one-time bootstrap and then uses event-driven tracking with localized periodic work. UnitHider-owned hidden units are paused until their visibility ownership is released, with their prior pause state restored. Old UnitHider3 recommendations do not describe the active system.

### Allocation-heavy GetUnits BJ replacement

No active gameplay use of `GetUnitsInRectMatching`, `GetUnitsInRangeOfLocMatching`, `GetUnitsInRangeOfLocAll` or `GetUnitsInRectAll` was found outside Blizzard helpers during the audit. Active systems already favor direct enumeration and reusable groups. Reopen only for a newly introduced hot callsite.

### Blind camera setter caching

`CameraControl` already compares effective Far Z against the current field and avoids writes within its tolerance. Dynamic Far Z ceiling measurement is valid; a generic “cache every SetCameraField” rewrite is not currently justified.

### Broad special-effect transform conversion

Combined position/orientation natives are already used in active code. One-time configuration setters are not established hot paths. Follow `18_EFFECT_NATIVE_LIFECYCLE_FOLLOWUP_PLAN.md` only for a measured high-frequency family.

### Terrain hiding as ordinary culling

`BlzShowTerrain` changes visible world state. It is not a safe general FPS system and can expose sky/water/scene artifacts. Do not use it as a substitute for measured object visibility controls.

### Fog as geometry culling

Fog style/density changes appearance; they do not prove reduced object submission, animation or simulation. Do not describe fog as frustum or distance culling.

### Frame visibility as proof of stopped work

`BlzFrameSetVisible(frame, false)` does not stop timers, string formatting or backing update code. Gate a profiled update loop by panel state; do not claim a benefit from frame hiding alone.

### Alpha zero as proof of zero effect cost

An alpha-zero effect can retain animation, particle, handle and renderer costs. Weather intentionally creates hidden effects for deterministic allocation. Benchmark the exact model and lifecycle before changing it.

### `BlzRemoveEffect` as a drop-in `DestroyEffect`

The 24342 declaration exists, but semantics are not established. Do not substitute it until the micro-tests in the effect follow-up plan pass on retail and PTR.

### Counted group enumeration in gameplay mechanics

Do not cap enumeration counts for combat, quests, auras or other completeness-sensitive logic merely to reduce cost. Counted enumeration is acceptable only when the gameplay design explicitly defines a cap.

## Deferred, evidence-gated hypotheses

### HD water controls

`SetHDWaterParamsEx`, `BlzSetHDWaterReflectivity`, `BlzSetHDWaterWaveStrength` and `SetWaterDeforms` are quality/state controls, not documented performance switches. Test only as an explicit graphics-profile experiment with screenshots and GPU frame times.

### UI and floating-text cadence

FloatingTT updates active tags at 0.03125 seconds but pauses when no tags exist. Several UI systems already gate work while hidden. Profile burst scenes before changing cadence, text, motion or lifetime.

### Dynamic minimap updates

Historical/draft minimap variants are not active optimization targets. Identify the exact imported version and reproduce a current cost before planning changes.

### Unified visibility distance

Far Z, units, doodads and destructables have different gameplay and presentation semantics. Do not bind their distances to one value until each system's safety margin and transition behavior is measured. Any later unified policy is a separate CAMERA-01/DOODAD-01/UNIT-HIDER-01 integration bundle.

### General simulation LOD

Off-screen units can still drive quests, pathfinding, combat, vendors, escorts and world continuity. Only the opt-in decorative AIRoutines design is in scope. A broader simulation LOD requires its own gameplay specification.

## Reopening rule

To reopen an item, add:

1. current source location and call frequency;
2. an isolated disable/simplification comparison;
3. the expected CPU, GPU, allocation or simulation mechanism;
4. a correctness boundary and rollback;
5. an owner plan in `00_IMPLEMENTATION_INDEX.md`.

