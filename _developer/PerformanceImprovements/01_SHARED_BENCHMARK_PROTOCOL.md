# Shared DE Performance Benchmark Protocol

## Metadata

- **Bundle ID:** FOUNDATION-01
- **Status:** planned; runtime metrics are `NOT_MEASURED`
- **Purpose:** provide one reproducible acceptance protocol for every performance candidate
- **Can ship independently:** documentation only

## Known baseline

Repository audit snapshot:

- Branch: `dev`; audit HEAD was `3ee2d133`.
- Active `_Blizzard/common.j` and `_Blizzard/blizzard.j` match archived build 24342 rather than 24268.
- Installed retail executable: Warcraft III `3.0.1.24342`.
- Installed PTR executable: Warcraft III `3.0.1.24360`.
- Test host: AMD Ryzen 9 5900XT, AMD Radeon RX 9060 XT driver `32.0.32015.2008`, 64 GB RAM, Windows 11 build 26200.
- Current display/preferences: 3840x2160, DE/Reforged assets enabled, VSync disabled, maximum FPS 200, high foliage and water settings.
- Active DX11/DX12 renderer: unknown and must be recorded at capture time.
- PresentMon/CapFrameX: not found during the audit; install or otherwise make an external frame-time recorder available before accepting a candidate.

The local test W3X observed during the audit predates current source. Record the exact map build hash/date for every capture rather than treating that archive as canonical.

## Controlled variables

For an A/B pair, keep these identical:

- map build, Warcraft build, renderer, driver, resolution, SD/DE mode and Rebirth state;
- VSync, FPS limit and every graphics-quality setting;
- scene, unit population, doodad/destructable state, weather, time of day and random seed where controllable;
- camera target, path, distance, pitch, Far Z and input timing;
- capture duration, warm-up duration and background applications.

Record any unavoidable mismatch next to the result and invalidate the pair when it can plausibly dominate the candidate.

## Capture procedure

1. Build a control map and one candidate map differing only by the candidate.
2. Restart or reload the map between variants; do not use a progressively disabled session as an A/B result.
3. Warm the scene for two minutes.
4. Capture three AB/BA pairs, 60 seconds per variant, alternating the starting variant to reduce thermal and order bias.
5. Preserve the raw CSV and a small metadata sidecar for every run.
6. Report the median of the six captures per variant and the spread across runs.
7. Use the in-game FPS counter only for smoke testing; acceptance requires external frame-time data.

## Required metrics

- average FPS and median frame time;
- p95 and p99 frame time;
- 1% low FPS;
- spike magnitude and count during camera tile crossings or the candidate-specific event;
- GPU utilization/frame time and CPU main-thread utilization/frame time when exposed by the recorder;
- candidate counters such as active/visible objects, native calls, toggles, group copies, effect creation/destruction, or timer callbacks.

## Standard scenes

1. Empty/open terrain control.
2. Densely wooded camera traversal.
3. High-density destructables with one-cell, diagonal, edge and teleport movement.
4. Village with ambient moving units.
5. Combat with many effects and projectiles.
6. Rain, storm and snow variants.
7. Horizon camera and normal gameplay pitch.
8. Cinematic begin/end and teleport transition.
9. Thirty-minute representative gameplay soak.

Run the candidate-specific subset first. Run all scenes only after acceptance or when a regression is plausible.

## General decision gate

A candidate passes performance only when the median of six captures achieves at least one predeclared target:

- at least 5% improvement in the targeted CPU or GPU frame time;
- at least 5% improvement in 1% low FPS; or
- at least 10% improvement in p99 frame time for a spike-oriented candidate.

No more than one of six captures may regress by more than 3% in the target metric. A candidate-specific document may impose a stricter threshold. Correctness, multiplayer, visual, save/load and cinematic gates are zero-tolerance and override a performance pass.

Microbenchmarks may prove that an operation is cheaper, but they do not justify integration without a measurable scene-level improvement unless the candidate fixes a separately demonstrated frame spike.

## Compatibility passes

- Primary performance decision: retail 24342, DE at 4K.
- Resolution check: 1440p DE.
- Graphics compatibility: SD mode.
- Renderer check: DX11 and DX12 when both are selectable.
- Version compatibility: PTR 24360 after a candidate passes retail.
- Synchronization check: at least two clients for any local-camera, weather, object-visibility, AI or effect-lifecycle change.

## Result record template

```text
Candidate:
Commit/build:
Map build:
Warcraft build:
Renderer/driver:
Resolution and graphics mode:
Scene and scripted path:
Variant A:
Variant B:
Raw capture files:
Average FPS A/B:
Median frame time A/B:
p95 A/B:
p99 A/B:
1% low A/B:
CPU/GPU frame time A/B:
Candidate counters A/B:
Correctness/regression results:
Measurement limitations:
Decision: accepted | rejected | rolled back | blocked
Reason:
```

## Rollback

Every candidate must be reversible by one cohesive commit or compile-time/internal configuration switch. After rollback, repeat the functional smoke test and verify that candidate-specific timers, handles, groups, saved data and debug controls no longer remain.

