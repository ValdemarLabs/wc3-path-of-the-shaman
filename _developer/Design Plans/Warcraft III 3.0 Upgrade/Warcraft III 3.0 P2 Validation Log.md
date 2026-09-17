# Warcraft III 3.0 P2 Validation Log

Parent plan: [Warcraft III 3.0 Systems Upgrade Plan](Warcraft%20III%203.0%20Systems%20Upgrade%20Plan.md)  
Documentation home: [Warcraft III 3.0 Upgrade](README.md)

## Table of contents

- [Scope](#scope)
- [Build and import gate](#build-and-import-gate)
- [Special-effect animation validation](#special-effect-animation-validation)
- [Dynamic minimap validation](#dynamic-minimap-validation)
- [Two-client gate](#two-client-gate)
- [Result recording](#result-recording)
- [Rollback](#rollback)

## Scope

This log covers the first `W3-HL-EFFECTS` and `W3-HL-MINIMAP` P2 slices. The
effect slice adds named animation, animation queuing, and blend-time controls
without migrating any production caller. The minimap slice retains the existing
camera-bounds transaction and full/chunked modes while allowing each local
client to select imported chunk textures or Warcraft III 3.0 native terrain
generation. Cooldown adjustment remains a separate combat-semantics workstream.

The effect probe is disabled at startup. It creates one synchronized test effect
per triggering player only after `/debug wc3 effects create`, and it has an
explicit destroy/reset command. DynamicMinimap still initializes normally, but
its default terrain source remains the established imported route until the
native matrix passes.

## Build and import gate

Task IDs: `W3-PH0-046`, `W3-PH0-047`, `W3-PH5-035` through `W3-PH5-038`,
and `W3-PH8-001` through `W3-PH8-004`.

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
- Build 24268 has `BlzChangeMinimapTerrainTex` and camera-bounds APIs, but no
  separate script native that requests native minimap terrain regeneration.
  World Editor's enabled "generate dynamically within camera bounds" map option
  supplies that behavior; the library selects whether to override it with an
  imported texture.
- The transformed new `SpeciFX` API slice, `DynamicMinimap`, and P2 harness pass
  `pjass` against active `_Blizzard/common.j` and `_Blizzard/blizzard.j`.
- These focused checks establish JASS/native structure only. They do not replace
  JassHelper library processing, model-animation semantics, or in-game cleanup
  and multiplayer tests.

Import order:

1. Import the updated `SpecialEffects/SpeciFX.j` after `Table`.
2. Import the updated `DynamicMinimap/DynamicMinimap_lastWorking.j` after
   `Interface`; keep its existing relationship with `CameraControl`.
3. Import `Debug/Warcraft300P2TestHarness.j` after `SpeciFX` and
   `DynamicMinimap`.
4. Import the updated `Debug/DebugCommands.j` after both Warcraft 3.0 harnesses.
5. Compile and save through World Editor/JassHelper.
6. Start the map and confirm no test effect exists before a debug command and
   the minimap reports `source=imported`.

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

## Dynamic minimap validation

Task IDs: `W3-PH0-047`, `W3-PH5-035` through `W3-PH5-038`.

World Editor's "generate dynamically within camera bounds" option is already
enabled in the map. `DynamicMinimap` now applies the same safe camera-bounds
transaction in both terrain modes:

- `imported` additionally calls `BlzChangeMinimapTerrainTex` for the current
  chunk or full-map texture;
- `native` does not replace the terrain texture and relies on the enabled map
  option to derive terrain from the current camera bounds.

There is no build-24268 native that explicitly says "regenerate native minimap
now." Therefore switching from an already applied custom texture back to native
terrain is a required runtime experiment, not an assumed guarantee.

### Baseline and source matrix

Start in an outdoor area whose imported chunk is well understood:

```text
/debug wc3 minimap help
/debug wc3 minimap status
/debug wc3 minimap source imported
/debug wc3 minimap view chunked
/debug wc3 minimap force
```

Record terrain resolution, painted minimap colors, fog of war, unit/hero icons,
pings, quest markers, chunk transitions, camera movement limits, and frame cost.
Move across at least four adjacent chunk boundaries and repeat with the enlarged
and minimized minimap layouts.

Then run the native matrix:

```text
/debug wc3 minimap source native
/debug wc3 minimap view chunked
/debug wc3 minimap force
/debug wc3 minimap view full
/debug wc3 minimap force
/debug wc3 minimap status
```

The chunked native view must still show the bounded portion of the full world;
this is why the camera-bounds transaction remains part of the implementation.
Full view must restore the full PotS world bounds. Repeat the same terrain,
icons, pings, markers, fog, transition, layout, and performance observations.

### Runtime source switching

Repeat this sequence at least ten times without reloading:

```text
/debug wc3 minimap source imported
/debug wc3 minimap force
/debug wc3 minimap source native
/debug wc3 minimap force
```

If native terrain does not return after an imported texture was applied, record
that engine limitation. In that case native mode must be selected as the
library's initial configuration before the first imported swap, and switching
back to native at runtime must be disabled or documented as reload-only. Do not
remove imported assets on the strength of a native-first startup test alone.

### Ownership, suspension, and endurance

For both sources and both full/chunked views:

1. Cross chunk boundaries at safe and unsafe camera rotations and confirm the
   existing deferred safe-rotation path remains crash-free.
2. Enter and leave dialogs, travel, death cameras, and fullscreen cinematics;
   bounds and selected terrain source must restore correctly.
3. Toggle minimized/enlarged presentation and confirm it does not change the
   selected terrain source or world bounds.
4. Run at least 30 minutes with repeated transitions and watch for lag growth,
   stale terrain, stuck bounds, missing icons, or camera/minimap disagreement.
5. In two clients, select different sources and views. Each client must retain
   its local minimap and camera bounds without changing synchronized gameplay or
   the other client's presentation.

Acceptance for replacing imported chunks requires native mode to meet or exceed
the imported route for legibility and stability, survive runtime switching or
have an accepted startup-only constraint, and pass the long-session/two-client
gate. Imported chunks and conversion tooling remain rollback assets until then.

## Two-client gate

1. Have player 1 create a probe at one camera target and player 2 at another.
2. Request different animations and blend times for each player-owned probe.
3. Confirm both clients see the same two effects and animation requests.
4. Destroy player 1's probe; player 2's probe must remain.
5. Destroy player 2's probe and continue synchronized gameplay for five minutes.
6. Run the minimap ownership/endurance procedure with deliberately different
   source and full/chunked choices on the two clients.

Pass criteria: identical synchronized effects, no cross-player cleanup, no
disconnect/desync, and no camera or gameplay state derived from an unsynchronized
local coordinate. Only the camera target is local; `DebugCommands` synchronizes
that coordinate before effect creation. Each client's minimap source, view mode,
and camera bounds must remain independent and must not affect synchronized state.

## Result recording

| Date/time | Task ID(s) | Client/player | Command/action | Result | Evidence/notes |
| --- | --- | --- | --- | --- | --- |
|  | `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-004` |  | World Editor/JassHelper compile | PENDING |  |
| 2026-09-17 | `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-003` | Repository | Focused transformed-source `pjass` | PASS | Active build-24268 API; not a full JassHelper/import test |
| 2026-09-17 | `W3-PH0-047`, `W3-PH5-036` through `W3-PH5-038` | Repository | Focused transformed-source `pjass` | PASS | DynamicMinimap and P2 harness structure; runtime terrain regeneration remains unproven |
|  | `W3-PH8-001` |  | Named animation and queue | PENDING |  |
|  | `W3-PH8-002` |  | Blend-time matrix | PENDING |  |
|  | `W3-PH8-003` |  | Legacy animtype comparison | PENDING |  |
|  | `W3-PH8-004` |  | Invalid name and 100-cycle cleanup | PENDING |  |
|  | `W3-PH8-004` | Two clients | Independent probes and cleanup | PENDING |  |
|  | `W3-PH5-035` | World Editor | Dynamic-within-camera-bounds option enabled | PASS | Enabled by Valdemar; runtime behavior not yet validated |
|  | `W3-PH0-047`, `W3-PH5-036` |  | Imported/native source and visual matrix | PENDING |  |
|  | `W3-PH5-037` |  | Native return after imported override; bounds requirement | PENDING |  |
|  | `W3-PH5-038` | Two clients | Full/chunked ownership and endurance | PENDING |  |

## Rollback

- Runtime probe: `/debug wc3 effects destroy` for every player who created one.
- Minimap runtime rollback: `/debug wc3 minimap source imported`, followed by
  `/debug wc3 minimap view chunked` or the previously used full-map mode and
  `/debug wc3 minimap force`.
- Source rollback: restore the previous `SpeciFX`, P2 harness, and debug-command
  versions plus the previous `DynamicMinimap`, then reimport them into the
  disposable map.
- No production effect call site was migrated, so rollback does not require an
  Object Editor, map-placement, or gameplay-data change.
