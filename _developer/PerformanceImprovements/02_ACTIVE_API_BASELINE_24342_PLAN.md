# Active API Baseline 24342 Plan

## Metadata

- **Candidate ID:** FOUNDATION-API-001
- **Priority:** P0 documentation prerequisite
- **Status:** planned
- **Bundle ID:** FOUNDATION-01
- **Hard dependencies:** active `_Blizzard/common.j`, `_Blizzard/blizzard.j`, installed retail build
- **Behavioral dependencies:** every plan using post-classic natives
- **Shared files:** `AGENTS.md`, performance plan documentation
- **Can ship independently:** yes

## Evidence

The active declaration files are byte-identical to `_Blizzard/Archive/3_0_24342/common.j` and `blizzard.j`, while the repository guideline currently labels them build 24268. The installed retail executable is 3.0.1.24342; PTR is 3.0.1.24360.

Relevant active declarations include:

```jass
native BlzGroupAddGroupFast takes group whichGroup, group addGroup returns integer
native BlzGroupRemoveGroupFast takes group whichGroup, group removeGroup returns integer
native BlzGroupGetSize takes group whichGroup returns integer
native BlzGroupUnitAt takes group whichGroup, integer index returns unit
native SetCameraField takes camerafield whichField, real value, real duration returns nothing
constant native GetCameraField takes camerafield whichField returns real
native BlzRemoveEffect takes effect whichEffect returns nothing
native BlzSetSingleDoodadAnimation takes integer index, string animName, boolean animRandom returns nothing
native BlzGetDoodadX takes integer index returns real
native BlzGetDoodadY takes integer index returns real
native BlzGetDoodadId takes integer index returns integer
native BlzGetNumDoodads takes nothing returns integer
native BlzSetSpecialEffectAlpha takes effect whichEffect, integer alpha returns nothing
native BlzSetSpecialEffectPosition takes effect whichEffect, real x, real y, real z returns nothing
native BlzSetSpecialEffectOrientation takes effect whichEffect, real yaw, real pitch, real roll returns nothing
```

The active definitions are at `_Blizzard/common.j:2449-2453`, `3814-3878`, `3982`, `4072-4088`, and `4188-4194` in the audited snapshot.

## Implementation design

1. Reconfirm hashes and installed retail version immediately before the documentation change.
2. Update the API-baseline paragraph in `AGENTS.md` from 24268 to 24342 and state that 24360 PTR is a compatibility target, not the production minimum.
3. Do not edit the active Blizzard declaration files or the original audit JSON.
4. In every native-dependent plan and handoff, state minimum version 3.0.1.24342 and require retail plus PTR semantic testing where the API is new or synchronization-sensitive.
5. Treat declaration presence as availability evidence only; retain micro-tests for doodad animation tokens, fast-group ordering, effect removal semantics and local-camera behavior.

## Non-goals

- Do not upgrade the project to PTR declarations.
- Do not copy PTR-only natives into the active snapshot.
- Do not claim that `BlzRemoveEffect` is interchangeable with `DestroyEffect`.
- Do not rewrite the original audit JSON; its 24268 statement remains a dated audit input.

## Validation

- Hash active files against archive 24342.
- Compile an unchanged full map after the eventual guideline edit.
- For each used 24342 native, confirm exact spelling, parameter order and return type in active `common.j`.
- Run the candidate-specific runtime tests on retail 24342 and a compatibility pass on PTR 24360.

## Acceptance and rollback

Accept when the guideline accurately identifies 24342, no declaration source changed, and native-dependent plans reference the corrected minimum. Roll back the documentation commit if the active files or retail installation no longer match 24342; replace it with the newly verified baseline rather than guessing.

Suggested commit: `Correct active Warcraft API baseline to 24342`.

