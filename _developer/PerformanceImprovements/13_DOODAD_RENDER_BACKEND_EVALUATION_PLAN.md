# DoodadRender Backend Evaluation Plan

## Metadata

- **Candidate ID:** PERF-004
- **Priority:** P1 experiment
- **Status:** planned; previous informal comparison is not retained benchmark evidence
- **Bundle ID:** DOODAD-01
- **Prerequisite:** shared benchmark protocol; current doodad type and placement inventory
- **Hard dependencies:** `DoodadHider/DoodadManager.j`, `DoodadHider/DoodadRender.j`
- **Behavioral dependencies:** weather, seasonal animation, cinematics, camera traversal and asset models
- **Shared files:** `Debug/Warcraft300TestHarness.j`, optionally `Debug/DebugCommands.j`
- **Can ship independently:** yes as a complete DOODAD-01 bundle

## Current implementation

`DoodadRender` exists and is active; it is not missing or World Editor-only. It requires `DoodadManager` at `DoodadRender.j:48` and defaults to the AREA backend.

The INDEXED backend already:

- enumerates doodad indices and builds a spatial database at approximately lines 218-260;
- applies per-index hide/show animation around lines 363-451;
- updates entering/exiting strips with a full-jump fallback around lines 456-516;
- checks movement periodically at approximately lines 580-606;
- suspends/resumes for cinematics around lines 815-836.

`DoodadManager` currently configures 33 rawcodes covering 12,354 of 50,118 records in the available `war3map.doo` reference, approximately 24.65%.

Active build 24342 contracts:

```jass
native BlzSetSingleDoodadAnimation takes integer index, string animName, boolean animRandom returns nothing
native BlzGetDoodadX takes integer index returns real
native BlzGetDoodadY takes integer index returns real
native BlzGetDoodadId takes integer index returns integer
native BlzGetNumDoodads takes nothing returns integer
```

## Goal

Make a measured production-backend decision using the existing disabled, AREA and INDEXED modes. Do not create a third renderer or promote INDEXED merely because its algorithm is more selective.

## Implementation work for the experiment

1. Preserve AREA as the default throughout testing.
2. Reuse existing backend commands and diagnostics in `Warcraft300TestHarness`.
3. Add only missing counters needed for comparison: managed instances visited, actual animation calls, transition type, full refresh, database build time and peak transition time.
4. Record initialization cost separately from steady-state traversal.
5. Never serialize doodad indices or use them as durable saved identifiers.
6. Keep DoodadManager rawcode/distance configuration unchanged for the first comparison.

## Compatibility micro-tests

For every managed rawcode in both SD and DE:

- verify `show` and `hide` animation tokens;
- verify seasonal and manually assigned animations restore correctly;
- verify particles, lights and model variations;
- verify camera teleport, rapid pan, map edges and cinematic suspend/resume;
- confirm no pathing or interaction assumption depends on presentation state.

Record incompatible rawcodes rather than hiding them through a backend-specific exception without evidence.

## Benchmark

Compare disabled, AREA and INDEXED in separate map reloads for:

- empty/open control;
- dense wooded traversal at normal and horizon camera angles;
- rapid horizontal and vertical panning;
- teleport/full refresh;
- weather and seasonal animation;
- 30-minute movement soak.

Capture initialization hitch, p99 crossing frame time, 1% low, GPU/CPU frame time and native animation calls.

## Acceptance criteria

Promote INDEXED only when:

- every managed rawcode passes SD/DE visibility and restore checks;
- cinematic and seasonal behavior are identical;
- initialization cost is acceptable and produces no new load spike;
- p99 improves by at least 10% or 1% low improves by at least 5% in two doodad-heavy scenes;
- no control scene regresses over the shared 3% limit.

If the threshold is not met, retain AREA and keep INDEXED diagnostic. A result showing no meaningful difference is a completed, rejected experiment rather than unfinished work.

## Rollback

Keep or restore AREA as `DEFAULT_BACKEND`, remove experiment-only diagnostics not useful for maintenance, and verify all doodads are visible after disable/refresh/cinematic restore.

Suggested commit if promoted: `Use measured indexed doodad rendering backend`.

