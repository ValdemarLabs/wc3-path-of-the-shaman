# Warcraft III 3.0 P2 Validation Log

Parent plan: [Warcraft III 3.0 Systems Upgrade Plan](Warcraft%20III%203.0%20Systems%20Upgrade%20Plan.md)  
Documentation home: [Warcraft III 3.0 Upgrade](README.md)

## Table of contents

- [Scope](#scope)
- [Build and import gate](#build-and-import-gate)
- [Special-effect animation validation](#special-effect-animation-validation)
- [Two-client gate](#two-client-gate)
- [Result recording](#result-recording)
- [Rollback](#rollback)

## Scope

This log begins P2 with `W3-HL-EFFECTS`. The first slice adds named special-
effect animation, animation queuing, and blend-time controls without migrating
any production caller. Dynamic minimap generation, cooldown adjustment, and
doodad color remain separate workstreams with their own semantic or manual
World Editor gates.

The probe is disabled at startup. It creates one synchronized test effect per
triggering player only after `/debug wc3 effects create`, and it has an explicit
destroy/reset command.

## Build and import gate

Task IDs: `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-004`.

Required environment:

| Field | Required value |
| --- | --- |
| Warcraft III / World Editor | `3.0.0.24268` |
| PotS map | Disposable copy of the complete current map |
| Presentation | SD / Classic |
| Required clients | One client for semantics; two clients for synchronization |

Repository-side checks recorded on 17 September 2026:

- Exact build-24268 declarations and parameter order were confirmed for
  `BlzSetSpecialEffectAnimation`, `BlzQueueSpecialEffectAnimation`,
  `BlzSetSpecialEffectAnimationBlendTime`, and `BlzPlaySpecialEffect`.
- The transformed new `SpeciFX` API slice and P2 harness both pass `pjass`
  against active `_Blizzard/common.j` and `_Blizzard/blizzard.j`.
- These focused checks establish JASS/native structure only. They do not replace
  JassHelper library processing, model-animation semantics, or in-game cleanup
  and multiplayer tests.

Import order:

1. Import the updated `SpecialEffects/SpeciFX.j` after `Table`.
2. Import `Debug/Warcraft300P2TestHarness.j` after `SpeciFX`.
3. Import the updated `Debug/DebugCommands.j` after both Warcraft 3.0 harnesses.
4. Compile and save through World Editor/JassHelper.
5. Start the map and confirm no test effect exists before a debug command.

Pass criteria: no compile error, no initialization change, no automatically
created effect, and the existing P0/P1 harness commands remain available.

## Special-effect animation validation

Aim the camera at an empty, visible development area and run:

```text
/debug wc3 effects help
/debug wc3 effects create
/debug wc3 effects status
```

The create command synchronizes the triggering player's camera target and
creates a Grunt-model effect there. It starts with animation `stand` and blend
time `0.15`.

### Named animation and queue

Run each command separately and record the visible transition:

```text
/debug wc3 effects animation stand
/debug wc3 effects animation attack
/debug wc3 effects queue stand
/debug wc3 effects status
```

The attack must play and the queued stand animation must follow it. Repeat with
`walk`, `death`, and an invalid name such as `pots_invalid_animation`. An invalid
name may be ignored by the model, but it must not crash, leak another effect, or
prevent the explicit destroy command.

### Blend time

Compare the same `stand` to `attack` transition after each value:

```text
/debug wc3 effects blend 0.00
/debug wc3 effects blend 0.15
/debug wc3 effects blend 1.00
/debug wc3 effects blend -1.00
```

Zero should be immediate, positive values should remain stable, and negative
input must normalize to zero. Declaration presence does not establish whether
every model visibly implements blending; record model-specific behavior rather
than treating an invisible difference as an API failure.

### Legacy compatibility and cleanup

```text
/debug wc3 effects legacy
/debug wc3 effects destroy
/debug wc3 effects status
```

The legacy command exercises `BlzPlaySpecialEffect(..., ANIM_TYPE_ATTACK)`, the
same animtype path retained by `SpeciFX_ConfigureEffect`. Destroy must remove the
owned probe and clear its recorded animation, queue, and blend state. Repeat at
least 100 create/animate/queue/destroy cycles and watch for persistent models,
handle growth symptoms, or increasing frame cost.

The managed-tag APIs require a focused caller test when the first production
candidate is selected. Verify that two effects sharing a reviewed tag both
receive set/queue/blend requests and that `SpeciFX_RemoveByTag` still removes
both. Do not migrate a production effect merely to satisfy this test.

## Two-client gate

1. Have player 1 create a probe at one camera target and player 2 at another.
2. Request different animations and blend times for each player-owned probe.
3. Confirm both clients see the same two effects and animation requests.
4. Destroy player 1's probe; player 2's probe must remain.
5. Destroy player 2's probe and continue synchronized gameplay for five minutes.

Pass criteria: identical synchronized effects, no cross-player cleanup, no
disconnect/desync, and no camera or gameplay state derived from an unsynchronized
local coordinate. Only the camera target is local; `DebugCommands` synchronizes
that coordinate before effect creation.

## Result recording

| Date/time | Task ID(s) | Client/player | Command/action | Result | Evidence/notes |
| --- | --- | --- | --- | --- | --- |
|  | `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-004` |  | World Editor/JassHelper compile | PENDING |  |
| 2026-09-17 | `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-003` | Repository | Focused transformed-source `pjass` | PASS | Active build-24268 API; not a full JassHelper/import test |
|  | `W3-PH8-001` |  | Named animation and queue | PENDING |  |
|  | `W3-PH8-002` |  | Blend-time matrix | PENDING |  |
|  | `W3-PH8-003` |  | Legacy animtype comparison | PENDING |  |
|  | `W3-PH8-004` |  | Invalid name and 100-cycle cleanup | PENDING |  |
|  | `W3-PH8-004` | Two clients | Independent probes and cleanup | PENDING |  |

## Rollback

- Runtime probe: `/debug wc3 effects destroy` for every player who created one.
- Source rollback: restore the previous `SpeciFX`, P2 harness, and debug-command
  versions and reimport them into the disposable map.
- No production effect call site was migrated, so rollback does not require an
  Object Editor, map-placement, or gameplay-data change.
