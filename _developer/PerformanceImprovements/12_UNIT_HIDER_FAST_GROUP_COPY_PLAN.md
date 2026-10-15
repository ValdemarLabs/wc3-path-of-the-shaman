# UnitHider Fast Group Copy Plan

## Metadata

- **Candidate ID:** PERF-003
- **Priority:** P1
- **Status:** planned; performance `NOT_MEASURED`
- **Bundle ID:** UNIT-HIDER-01
- **Prerequisite:** fast-group semantic micro-test
- **Hard dependencies:** `UnitSystems/UnitHider4.j`, active `common.j` signature
- **Behavioral dependencies:** AI, AIRoutines, companions, cinematics, quests and direct GUI-global consumers
- **Shared files:** diagnostics harness only if counters are added
- **Can ship independently:** yes; preserve every UnitHider public API

## Evidence and mechanism

UnitHider 4.11 is already event-driven after its bootstrap, with 0.10-second updates and visible sweeps every five ticks. It is not a rewrite candidate.

The audited source contains recurring `GroupAddGroup` calls around `UnitHider4.j:148-155`, `309-367`, `576`, and `692`. The Blizzard wrapper at `_Blizzard/blizzard.j:5226-5238` iterates the source through `ForGroup` and can destroy it when `bj_wantDestroyGroup` is set.

Active build 24342 provides:

```jass
native BlzGroupAddGroupFast takes group whichGroup, group addGroup returns integer
native BlzGroupRemoveGroupFast takes group whichGroup, group removeGroup returns integer
native BlzGroupGetSize takes group whichGroup returns integer
native BlzGroupUnitAt takes group whichGroup, integer index returns unit
```

The native order is destination then source, the reverse of `GroupAddGroup(sourceGroup, destGroup)`. This candidate targets JASS callback/native-transition CPU cost, not rendering.

## Semantic micro-test

Before changing UnitHider, verify on retail 24342 and PTR 24360:

- destination/source argument order;
- returned size;
- duplicate membership behavior;
- empty groups;
- source equals destination;
- iteration stability after copying;
- behavior while `bj_wantDestroyGroup` is true.

Do not depend on aliasing if the test shows undefined or version-specific behavior.

## Minimal design

1. Add a private, clearly named helper before its callers, for example `CopyGroupFast(sourceGroup, destinationGroup)`.
2. Inside it, call `BlzGroupAddGroupFast(destinationGroup, sourceGroup)`.
3. Use it only where the current UnitHider code owns persistent groups and does not intentionally request `bj_wantDestroyGroup` destruction.
4. Preserve explicit `GroupClear` calls and whether each call is a copy or union.
5. Do not replace individual `GroupAddUnit`/`GroupRemoveUnit` operations.
6. Do not expose the helper publicly or change GUI globals.
7. If any call depends on BJ destruction or mutation during `ForGroup`, leave that call unchanged and document it.

## Tests

- Compare membership after every converted call using `BlzGroupGetSize`, `BlzGroupUnitAt` and `IsUnitInGroup` in a focused harness.
- Exercise empty, one-unit, duplicate and large groups.
- Bootstrap, reference registration/unregistration, cinematic references, relocation, system disable/enable and refresh.
- Quest NPCs, companions, tamed units, neutral units, AI hero revealers and direct modifications of `udg_UnitHider_ReferenceGroup`.
- Two-client visibility parity and a 30-minute hide/reveal soak.
- Microbenchmark many copies and scene-level village/camera traversal captures.

## Acceptance criteria

- Exact group membership and visibility parity at each tested phase.
- No persistent group is destroyed or aliased incorrectly.
- Fast copy is at least 10% faster in the operation microbenchmark.
- Scene-level CPU frame time or p99 improves by at least 2%; otherwise reject as a speculative micro-optimization despite the microbenchmark.
- Normal UnitHider runtime behavior and all public functions remain unchanged.

## Rollback

Replace the private fast helper calls with their original `GroupAddGroup(source, destination)` calls and remove candidate diagnostics. Re-run bootstrap and cinematic visibility tests.

Suggested commit: `Use native fast group copies in UnitHider`.

