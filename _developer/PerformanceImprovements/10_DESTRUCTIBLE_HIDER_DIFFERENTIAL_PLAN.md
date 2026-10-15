# DestructibleHider Differential Tile Update Plan

## Metadata

- **Candidate ID:** PERF-001
- **Priority:** P0
- **Status:** planned; performance `NOT_MEASURED`
- **Bundle ID:** DESTRUCTABLE-01
- **Prerequisite:** shared benchmark protocol and candidate counters
- **Hard dependencies:** `_CoreSystems/Imported/DestructibleHider.j`
- **Behavioral dependencies:** quests and systems that call `ShowDestructable` directly
- **Shared files:** diagnostics harness only if commands are added
- **Can ship independently:** yes

## Evidence and mechanism

The audited implementation uses `INTERVAL = 0.2`, `DRAW_DISTANCE = 5120`, `TILE_RESOLUTION = 10`, and therefore 512-unit tiles at `_CoreSystems/Imported/DestructibleHider.j:18-29`.

`EnumGrid` at lines 77-118 visits every tile in a requested rectangle. `ChangeTiles` at lines 121-124 hides the complete old 21x21 window and then shows the complete new 21x21 window. A one-cell horizontal move visits 441 old plus 441 new tiles; the 20x21 overlap is hidden and immediately shown. The minimal difference is 21 exiting plus 21 entering tiles.

This candidate targets JASS/native CPU work and movement-related frame spikes. It does not claim lower GPU draw cost beyond preserving the same final visibility set.

Relevant active build 24342 contract:

```jass
native ShowDestructable takes destructable d, boolean flag returns nothing
```

## Minimal design

Preserve the public API, hashtable layout, registration behavior, draw distance, timer interval and final visible rectangle.

For each movement update:

1. Build clamped inclusive rectangles for the old and new windows.
2. If the cells are unchanged, return without enumeration.
3. Compute their intersection.
4. If no intersection exists, enumerate the old rectangle hidden and the new rectangle shown.
5. Otherwise enumerate `old - intersection` as non-overlapping left, right, bottom and top strips.
6. Enumerate `new - intersection` using the same strip construction.
7. Skip every empty strip before calling `EnumGrid`.

Use full-height left/right strips and intersection-width bottom/top strips so corners are visited once. Keep helper declarations before callers for JassHelper compatibility.

Large teleports naturally use the non-overlap fallback. Map-edge clamping must occur before intersection math. Initial state continues to use the existing registration/bootstrap behavior rather than inventing a synthetic old window.

## Instrumentation

Add debug-only/resettable counters for:

- tile cells passed through `EnumGrid`;
- destructables considered;
- actual `ShowDestructable` calls;
- no-op same-cell updates;
- overlapping versus non-overlapping transitions.

Counters must not add strings or per-object logging to the hot path.

## Correctness constraints

- Preserve runtime register/unregister and saved boolean visibility state.
- Preserve dead-tree, harvested-tree, resurrected destructable, bridge and gate behavior.
- Do not alter pathing, invulnerability, life, animation or ownership.
- Audit direct `ShowDestructable` users, including quest-specific object control, for ownership conflicts.
- No local-player guard: destructable visibility/state changes remain synchronized.

## Test plan

Functional cases:

1. Initial bootstrap at map center and each map edge/corner.
2. Repeated update in the same cell.
3. One-cell horizontal and vertical movement.
4. One-cell diagonal movement.
5. Multi-cell movement with partial overlap.
6. Teleport with no overlap.
7. Runtime register/unregister before, inside and outside the visible window.
8. Death, harvest, resurrection and gate interactions.
9. Cinematic/teleport transition and save/load recovery where applicable.

Benchmark the current algorithm against the differential implementation in the dense-destructable traversal scene using the shared AB/BA procedure.

## Acceptance criteria

- Final visibility matches control after every tested transition.
- A one-cell horizontal or vertical move visits at most 42 tile cells.
- No visibility native is called for an overlapping-cell destructable solely because the window moved.
- Large jumps visit each old/new tile at most once.
- Median p99 frame time improves by at least 10% or 1% low improves by at least 5% in the dense crossing scene.
- Full-map World Editor/JassHelper compile and multiplayer regression pass.

Reject the performance candidate if work counters improve but external frame-time results remain below threshold. The algorithm may be reconsidered only with a separately justified maintainability benefit.

## Rollback

Restore the original two `EnumGrid` calls in `ChangeTiles`, remove candidate-only helpers/counters and verify the old window behavior in a focused map and the full map.

Suggested commit: `Use differential destructable visibility updates`.

