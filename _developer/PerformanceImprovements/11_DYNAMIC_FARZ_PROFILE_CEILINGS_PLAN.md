# Dynamic Far Z Profile Ceiling Plan

## Metadata

- **Candidate ID:** PERF-002
- **Priority:** P1
- **Status:** planned; performance and visual limits `NOT_MEASURED`
- **Bundle ID:** CAMERA-01
- **Prerequisite:** shared benchmark protocol; fixed-value Far Z sweep
- **Hard dependencies:** `UI/DynamicFarZ.j`, `UI/CameraControl.j`
- **Behavioral dependencies:** `UI/CameraUI.j`, `Camera/DialogCamera.j`, `Camera/FreeCamera.j`, DynamicMinimap, DoodadRender, UnitHider and DestructableHider
- **Shared files:** camera test harness if diagnostics are added
- **Can ship independently:** yes, but only as the complete CAMERA-01 bundle

## Evidence and mechanism

`UI/DynamicFarZ.j:42-43` defines natural angle 310 and horizon angle 345. `GetEffectiveFarZ` at lines 170-201 interpolates from the selected profile minimum factor to factor `1.0`; every profile therefore reaches the entire base Far Z at or beyond the horizon angle.

`UI/CameraControl.j` stores a default base Far Z of 10000 and calls `DynamicFarZ_GetEffectiveFarZ`. Existing drift maintenance already compares the current field and writes only when the difference exceeds approximately 0.75, so redundant setter suppression is not the candidate.

This is a GPU/draw-distance and visual-quality candidate. It does not reduce AI, triggers, pathfinding or other simulation.

Relevant native contracts from active build 24342:

```jass
native SetCameraField takes camerafield whichField, real value, real duration returns nothing
native SetCameraFieldControlledByInput takes camerafield whichField, boolean controlled returns nothing
constant native GetCameraField takes camerafield whichField returns real
```

## Phase 1: measurement-only sweep

Before source implementation, capture fixed effective Far Z values of 10000, 8000, 6500 and 5000 in:

- dense forest, settlement, water and effect-heavy combat;
- normal gameplay pitch and horizon pitch;
- Light, Medium and Heavy user expectations;
- 4K DE primary, 1440p DE and SD compatibility.

Record clipping, sky/horizon gaps, large-object disappearance, weather cutoff, water artifacts and cinematic reveals alongside GPU frame time.

## Phase 2: minimal implementation

Proceed only when the sweep passes the candidate threshold.

1. Add private per-profile horizon-ceiling factors or maximums to DynamicFarZ.
2. Apply the selected ceiling after angle interpolation and before the existing context maximum.
3. Selection rule: choose the smallest tested value with zero visual failures and a passing external performance result; if none passes, reject the candidate.
4. Preserve Light at the current uncapped behavior unless its own sweep independently passes.
5. Preserve explicit special-area context maximums.
6. Preserve cinematic behavior: a scripted/suspended camera that currently receives base Far Z must not be capped unless the cinematic is explicitly opted into DynamicFarZ.
7. Keep the public API unchanged. CameraUI continues to expose Auto and profile selection without new controls.

Do not automatically tie camera Far Z to UnitHider, DoodadRender or DestructableHider distances. Their semantics and safety margins differ. Coordinated distances require a separate measured design.

## Instrumentation

Expose debug-only calculated factor, profile ceiling, context maximum, final effective Far Z and applied/avoided `SetCameraField` counts. Do not add synchronized state or network traffic; camera data remains per-player/local.

## Test plan

- Profile changes at natural and horizon angles.
- Mouse orbit, keyboard camera, zoom, developer/free camera and experimental input ownership.
- Boom Mine and Gnoll Hideout contexts plus an unconfigured special context.
- Dialog camera begin/end, scripted camera, cinematic resume and teleport.
- Sky, water, tall terrain, large doodads, weather and distant quest markers.
- Two clients using different profiles and camera angles without synchronized-state divergence.

## Acceptance criteria

- Zero visible clipping/pop-in failures in the approved scene matrix.
- No change to scripted/cinematic camera intent or player input ownership.
- At least 5% GPU frame-time or 1%-low improvement, or at least 10% p99 improvement, at 4K DE.
- The chosen ceiling remains beneficial and visually acceptable at 1440p; SD has no functional regression.
- Full CAMERA-01 compile and consumer regression pass.

## Rollback

Remove the profile ceiling from the final clamp so horizon interpolation returns to factor `1.0`. Keep unrelated existing DynamicFarZ contexts intact.

Suggested commit: `Add measured Dynamic Far Z profile ceilings`.

