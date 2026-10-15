# Performance Diagnostics Harness Plan

## Metadata

- **Candidate ID:** FOUNDATION-DIAG-001
- **Priority:** P0 enabling work
- **Status:** planned
- **Bundle ID:** DIAGNOSTICS-01
- **Hard dependencies:** the system API or counter exposed by the active candidate
- **Behavioral dependencies:** `Debug/DebugCommands.j`, `Debug/Warcraft300TestHarness.j`
- **Shared files:** both debug libraries; serialize edits from different candidate plans
- **Can ship independently:** only the stable generic harness; candidate commands land with their producer API

## Problem and evidence

`Debug/DebugCommands.j:780-819` disables AI, movement, terrain damage, quests, AIRoutines, companions, weather, floating text, gather nodes, UnitHider and DoodadRender sequentially at five-second intervals. This can locate gross offenders, but it changes multiple variables in a fixed order, lacks a matching restore path, and cannot produce valid isolated A/B evidence.

`Debug/Warcraft300TestHarness.j` already exposes useful DoodadRender backend and diagnostic commands. Preserve and extend this pattern instead of creating a second debug framework.

## Design

Add candidate controls only when implementing that candidate:

- one explicit control variant and one candidate variant;
- a status command printing the active variant and relevant counters;
- resettable counters that do not change gameplay state;
- no automatic cycling during a capture;
- no source API call from the harness unless the producing library lands in the same atomic bundle.

Prefer system-owned diagnostic getters. Do not make internal groups, handles or hashtables public solely for debug access.

Proposed command namespace:

```text
/debug perf status
/debug perf reset
/debug perf <candidate> control
/debug perf <candidate> candidate
```

Where switching safely at runtime is impossible, print that a map reload with the requested build is required. Do not simulate reversibility by partially reinitializing stateful systems.

## Candidate counters

- DestructableHider: tiles visited, destructables considered, actual `ShowDestructable` calls, large-jump fallbacks.
- DynamicFarZ: calculated value, applied value, profile/context, setter calls avoided/applied.
- DoodadRender: database build time/count, area/index calls, transitions, full refreshes and maximum transition time.
- UnitHider: group-copy calls, copied membership count, visible sweeps and hidden-cell visits.
- Storm/weather: idle/active timer callbacks, effect creates/destroys/replays, terrain samples and visible impacts.
- AIRoutines: units considered, skipped hidden units, orders and callbacks executed.

## Safety constraints

- Diagnostics must produce identical synchronized decisions on every client unless they are purely local camera/UI reads.
- Do not create, destroy, hide or mutate synchronized objects under `GetLocalPlayer`.
- Counter overflow is acceptable only if resettable and documented; prefer integers reset per capture.
- Debug commands remain developer-only and disabled from normal player workflows.
- Avoid per-event debug strings during captures; print summaries on demand.

## Tests

1. Compile focused and full maps with every command target present.
2. Verify control/candidate selection and status after map reload.
3. Reset counters before a run and confirm only the intended event increments them.
4. Compare a capture with counters enabled versus compiled out/disabled to ensure instrumentation overhead is below measurement noise.
5. Confirm two clients report consistent synchronized counters where expected.

## Acceptance and rollback

Accept only if each command changes one candidate, has an unambiguous status, and adds no measurable idle overhead. Remove candidate commands and their getters in the same rollback commit; never leave dangling harness references.

Suggested commit: `Add isolated performance diagnostics controls`.

