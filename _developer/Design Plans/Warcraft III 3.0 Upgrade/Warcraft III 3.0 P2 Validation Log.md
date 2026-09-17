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
its production terrain source remains the established imported route. The first
full-map visual comparison rejected native generation because terrain and
destructibles alone were materially less detailed than the authored chunk art.
Native mode remains available only as a diagnostic comparison.

## Build and import gate

Task IDs: `W3-PH0-046`, `W3-PH0-047`, `W3-PH5-035` through `W3-PH5-042`,
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

Task IDs: `W3-PH0-047`, `W3-PH5-035` through `W3-PH5-042`.

World Editor's "generate dynamically within camera bounds" option is already
enabled in the map. `DynamicMinimap` now applies the same safe camera-bounds
transaction in both terrain modes:

- `imported` additionally calls `BlzChangeMinimapTerrainTex` for the current
  chunk or full-map texture;
- `native` does not replace the terrain texture and relies on the enabled map
  option to derive terrain from the current camera bounds.

There is no build-24268 native that explicitly says "regenerate native minimap
now." The first visual comparison already rejected native terrain as the PotS
production presentation. Switching from an applied custom texture back to native
terrain is therefore optional diagnostic evidence, not a remaining release gate.

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

### Optional diagnostic source switching

Repeat this sequence at least ten times without reloading:

```text
/debug wc3 minimap source imported
/debug wc3 minimap force
/debug wc3 minimap source native
/debug wc3 minimap force
```

If native terrain does not return after an imported texture was applied, record
that engine limitation and reset/reload to the imported source. This does not
block production because imported chunks remain the accepted default and no
imported assets will be removed.

### Ownership, suspension, and endurance

For the imported production source in both full/chunked views:

1. Cross chunk boundaries at safe and unsafe camera rotations and confirm the
   existing deferred safe-rotation path remains crash-free.
2. Enter and leave dialogs, travel, death cameras, and fullscreen cinematics;
   bounds and selected terrain source must restore correctly.
3. Toggle minimized/enlarged presentation and confirm it does not change the
   selected terrain source or world bounds.
4. Run at least 30 minutes with repeated transitions and watch for lag growth,
   stale terrain, stuck bounds, missing icons, or camera/minimap disagreement.
5. In two clients, select different full/chunked views while keeping the imported
   source. Each client must retain its local minimap and camera bounds without
   changing synchronized gameplay or the other client's presentation.

The same procedure may be repeated with native mode as a diagnostic, but native
results no longer gate the imported production route.

Native generation failed the production-quality gate in the first full-map
comparison: it showed terrain/destructibles but looked materially less detailed
than the custom chunks. Imported chunks and conversion tooling therefore remain
required production assets. Remaining minimap work is calibration rather than
source replacement: verify map-world/camera-world bounds directly from World
Editor, capture `View Entire Map` at the exact full extent, preserve the
uncropped source, regenerate chunks, and tune only documented art offsets.

Repository follow-up completed on 17 September 2026: the generated full-map
script confirms terrain bounds X `-29184..32256`, Y `-32256..29184`, matching
the previous library values. `DynamicMinimap` 1.7.0 now derives the terrain
bounds from `bj_mapInitialPlayableArea` and the authored full-camera limits from
the engine camera margins during initialization, so future World Editor size or
margin changes are not duplicated in source constants. Reimport/compile and
edge/corner runtime confirmation remain required.

## Two-client gate

1. Have player 1 create a probe at one camera target and player 2 at another.
2. Request different animations and blend times for each player-owned probe.
3. Confirm both clients see the same two effects and animation requests.
4. Destroy player 1's probe; player 2's probe must remain.
5. Destroy player 2's probe and continue synchronized gameplay for five minutes.
6. Run the minimap ownership/endurance procedure with the imported source and
   deliberately different full/chunked choices on the two clients.

Pass criteria: identical synchronized effects, no cross-player cleanup, no
disconnect/desync, and no camera or gameplay state derived from an unsynchronized
local coordinate. Only the camera target is local; `DebugCommands` synchronizes
that coordinate before effect creation. Each client's minimap view mode and camera
bounds must remain independent and must not affect synchronized state.

## Result recording

| Date/time | Task ID(s) | Client/player | Command/action | Result | Evidence/notes |
| --- | --- | --- | --- | --- | --- |
| 2026-09-17 | `W3-PH0-046`, `W3-PH0-047`, `W3-PH8-001` through `W3-PH8-004` | Player 1 | Initial P2 World Editor/JassHelper compile and startup | PASS | Runtime SpeciFX and minimap commands were available; later CameraControl 1.6.0, harness 0.7.0, and minimap 1.7.0 revisions still need the incremental source gate |
| 2026-09-17 | `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-003` | Repository | Focused transformed-source `pjass` | PASS | Active build-24268 API; not a full JassHelper/import test |
| 2026-09-17 | `W3-PH0-047`, `W3-PH5-036` through `W3-PH5-038` | Repository | Focused transformed-source `pjass` | PASS | DynamicMinimap and P2 harness structure; runtime terrain regeneration remains unproven |
| 2026-09-17 | `W3-PH8-001` | Player 1 | Named animation and queue | PASS (BASIC) | User reported the SpeciFX probes worked; model-variety and endurance checks remain |
| 2026-09-17 | `W3-PH8-002` | Player 1 | Blend-time probe | PASS (BASIC) | User reported the SpeciFX probes worked; full value/model matrix remains |
| 2026-09-17 | `W3-PH8-003` | Player 1 | Legacy animtype comparison | PASS (BASIC) | Existing compatibility path remained usable in the reported probe |
|  | `W3-PH8-004` |  | Invalid name and 100-cycle cleanup | PENDING |  |
|  | `W3-PH8-004` | Two clients | Independent probes and cleanup | PENDING |  |
|  | `W3-PH5-035` | World Editor | Dynamic-within-camera-bounds option enabled | PASS | Enabled by Valdemar; native rendering was later tested and rejected for production visual quality |
| 2026-09-17 | `W3-PH0-047`, `W3-PH5-036` | Player 1 | Imported/native visual comparison | NATIVE REJECTED | Native terrain/destructibles lacked the detail of custom chunk textures |
| 2026-09-17 | `W3-PH5-037` | Player 1 | Production source decision | PASS — IMPORTED | Imported chunks remain required; source-image and bounds calibration are the remaining work |
| 2026-09-17 | `W3-PH5-040` | Repository/generated full-map script | Bounds source audit and runtime derivation | PASS (SOURCE) | Exact map bounds confirmed; library now reads initialized map bounds and camera margins; runtime reimport pending |
|  | `W3-PH5-038` | Two clients | Imported full/chunked ownership and endurance | PENDING | Native mode is optional diagnostic evidence only |

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
