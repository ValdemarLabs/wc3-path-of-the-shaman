# Weather Rain-Effect Budget Plan

## Metadata

- **Candidate ID:** PERF-006
- **Priority:** P2 conditional
- **Status:** planned; implementation blocked on isolated evidence
- **Bundle ID:** WEATHER-01
- **Prerequisite:** measure existing ripple on/off control before changing allocation
- **Hard dependencies:** `EnvironmentSystems/WeatherSystemV4.j`; `SpeciFX`, Storm or SteamBreath only if their interfaces change
- **Behavioral dependencies:** local camera, terrain/water sampling, DoodadRender, seasonal weather and multiplayer synchronization
- **Shared files:** weather diagnostics and debug controls
- **Can ship independently:** yes as a complete WEATHER-01 bundle

## Evidence and mechanism

`WeatherSystemV4.j:104-116` configures rain impacts at 0.15 seconds with a 16-slot ring. `RainImpactCallback` around lines 526-579 destroys the selected slot and creates one land or water effect every tick. Even when the local impact should not be shown, an effect is created and hidden with alpha zero so clients preserve identical effect-handle allocation despite different local cameras.

The callback performs camera-based placement, a rain-intensity lookup, a water pathability check, and conditional terrain/slope work. `UpdateRainImpactTimer` already pauses and clears the system when ripples or master optimization disable it.

The public controls around lines 1688 onward include `SetFPSOptimization`, `SetCloudsEnabled`, `SetRipplesEnabled`, `SetThunderEnabled` and `SetSteamBreathEnabled`. The master setter immediately updates rain impacts but does not itself remove every already-active optional visual, so its documented “all optional effects disabled” behavior must be verified separately from this performance candidate.

Relevant natives:

```jass
native BlzSetSpecialEffectAlpha takes effect whichEffect, integer alpha returns nothing
native BlzSetSpecialEffectPosition takes effect whichEffect, real x, real y, real z returns nothing
native DestroyEffect takes effect whichEffect returns nothing
native BlzRemoveEffect takes effect whichEffect returns nothing
```

`BlzRemoveEffect` is not an approved substitute until its semantics are tested.

## Phase 1: existing-control isolation

Capture the same active rain scene with ripples enabled and disabled through the existing public API. Record:

- effect creation/destruction count;
- terrain, slope and water samples;
- CPU/GPU frame time and p99;
- visual contribution at light, medium and heavy intensity.

Reject further work if disabling impacts does not meet the shared performance threshold.

## Phase 2: deterministic pool prototype

Only after Phase 1 passes:

1. Build fixed land and water effect rings during synchronized initialization so every client creates the same count in the same order.
2. On each tick, choose the appropriate local presentation, reposition its slot, reset scale/orientation/alpha and replay the animation if supported.
3. Hide the unused model for the selected slot without creating or destroying handles.
4. Preserve the deterministic sequence and avoid any synchronized game-object mutation inside a local-player branch.
5. Clear/destroy both rings only in synchronized shutdown/rollback paths.
6. If the models cannot be reliably replayed or hidden effects still cost as much as visible ones, reject pooling.

The prototype must compare current create/destroy behavior against pooling. Pooling is not assumed faster, especially for particle models whose replay or hidden draw state may remain costly.

## Multiplayer and visual constraints

- Local camera coordinates may differ; synchronized handle allocation/order may not.
- Rain intensity, weather state and timers remain synchronized.
- Land slope alignment, water scale, map-bound clamping and light/medium sampling cadence remain visually equivalent.
- No change to narrative weather intensity, thunder, clouds, snow or steam in this plan.

## Acceptance criteria

- Phase 1 ripple disabling meets at least 5% CPU/GPU frame-time or 1%-low improvement, or 10% p99 improvement.
- A pool proceeds only if it improves on the current enabled implementation by the same threshold.
- Stable effect-handle count and no growth across a 30-minute storm soak.
- Identical two-client synchronized weather progression with independent camera positions.
- No dead effects, stale alpha, model mismatch, slope artifact or animation that fails to replay.

## Rollback

Restore the current 16-slot destroy/create ring and existing timer controls. Destroy prototype pools in synchronized cleanup and verify zero retained handles after rain ends.

Suggested commit if accepted: `Reuse deterministic rain impact effects`.

