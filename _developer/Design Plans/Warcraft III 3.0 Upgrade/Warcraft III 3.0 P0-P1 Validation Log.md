# Warcraft III 3.0 P0/P1 Validation Log

Parent plan: [Warcraft III 3.0 Systems Upgrade Plan](Warcraft%20III%203.0%20Systems%20Upgrade%20Plan.md)  
Documentation home: [Warcraft III 3.0 Upgrade](README.md)

## Table of contents

- [Scope](#scope)
- [Build and test environment](#build-and-test-environment)
- [Repository implementation state](#repository-implementation-state)
- [Import and compilation gate](#import-and-compilation-gate)
- [Passive baseline](#passive-baseline)
- [Camera validation](#camera-validation)
- [Fog validation](#fog-validation)
- [Doodad validation](#doodad-validation)
- [Doodad authoring and creation-site review](#doodad-authoring-and-creation-site-review)
- [Result recording](#result-recording)
- [Rollback](#rollback)

## Scope

This log is the execution record for the current `W3-HL-HARNESS`,
`W3-HL-CAMERA`, `W3-HL-FOG`, and `W3-HL-DOODADS` P0/P1 queue. It separates
repository-complete implementation from tests that can only be established in
World Editor or the game client. A task is not recorded as passed merely because
the native exists or the source passes static inspection.

The harness is passive at startup. Camera orbit is disabled by default. Extended
fog is used only by an explicit debug command. Doodad enumeration and mutation
begin only through explicit debug commands.

## Build and test environment

| Field | Required value |
| --- | --- |
| Warcraft III / World Editor | `3.0.0.24268` |
| PotS map | Disposable full-map copy based on the current development map |
| Presentation | SD / Classic |
| Required clients | One client for smoke and visual checks; two clients for local-state checks |
| Source baseline | Active `_Blizzard/common.j` and `_Blizzard/blizzard.j` |

Repository-side baseline recorded on 17 September 2026:

- The generated 253,639-line `war3map.j` in
  `C:\Users\Valtteri\Documents\Warcraft III\Maps\EpicQuestsFolder40_test1\Epic Quests.w3x`
  parses successfully with `_JassHelper/pjass.exe` against the active 3.0
  `common.j` and `blizzard.j`.
- That generated script predates the changes listed below. It proves the
  disposable map snapshot baseline only; it does not close `W3-VAL-001`.
- A non-writing parser substitution replaced the generated map's old
  `CameraControl` globals/functions with the current source and passed `pjass`
  against the active 3.0 Blizzard API. `FogSystem` and the new harness also pass
  focused transformed-source `pjass` checks; the harness check used typed stubs
  for its PotS dependencies. These checks validate JASS/native structure but do
  not reproduce JassHelper dependency ordering or in-client behavior.
- The repository does not contain a current generated `war3map.j` or an automated
  full-map import/build command. Import and compilation must therefore use the
  normal World Editor/JassHelper workflow.

## Repository implementation state

| Workstream | Implemented and ready to import | Runtime-only evidence still required |
| --- | --- | --- |
| Harness | Explicit read-only self-test plus camera, fog, and doodad suites; reset commands; no startup mutation | Full-map compile/start and command output |
| Camera | Disabled bounded middle-drag orbit, reversible input-ownership and camera-type probes, cancellation paths, source-specific modal blockers | Camera-type meanings, ownership semantics, UI matrix, two-client safety |
| Fog | Complete legacy/extended current and target state, numeric interpolation, complete storm override restoration | Visual parity, zone/weather transitions, two-client locality |
| Doodads | Batched read-only scan, fingerprints, inspection, and one guarded hide/show instance probe | Index base/stability, scan cost, reviewed instance reset, authoring/persistence/pathing checks |

## Import and compilation gate

Task IDs: `W3-PH0-017`, `W3-PH0-045`, `W3-VAL-001`, `W3-VAL-004`.

1. Start from a disposable copy of the complete map that already contains the
   repaired 3.0-safe models.
2. Import the changed libraries in dependency order. In particular:
   `CameraControl` must precede `MasterUI`, `SharedDInvLib`, `DInventory`,
   `DEquipment`, `CraftingUI`, `ShopUI`, `QuestUI`, `TalentsUI`, `AbilitiesUI`,
   `GambleUI`, and `FullscreenUI`; `FogSystem` must precede `Storm`; and
   `Warcraft300TestHarness` must precede `DebugCommands`. The current
   `DebugCommands` also requires `Warcraft300P2TestHarness`, which must follow
   both `SpeciFX` and `DynamicMinimap`; importing it does not create a P2 effect
   probe or change the imported minimap default at startup.
3. Compile and save through World Editor/JassHelper 3.0.0.24268.
4. Start the map without entering a debug command.
5. Confirm no camera, fog, or doodad experiment activates automatically.
6. Record compile result, warnings, load time, initial FPS, and any changed
   initialization behavior under [Result recording](#result-recording).

Pass criteria:

- No JassHelper compile error or missing requirement.
- Map reaches normal gameplay.
- Orbit remains disabled.
- Legacy zone fog and storm behavior remain active.
- No doodad scan timer or mutation runs at startup.
- No P2 special-effect probe exists until `/debug wc3 effects create` is used.

## Passive baseline

Run on player 1, then player 2 in the two-client session:

```text
/debug wc3 status
/debug wc3 selftest
/debug wc3 camera
/debug wc3 fog
/debug wc3 doodads
```

The self-test is read-only and must report `7/7` before any mutating probe is
enabled. A failed check is evidence to investigate, not permission to relax the
invariant. Capture the complete output. Repeat in one outdoor zone, one dungeon, during a
storm, and during a camera-suspending dialog/cinematic. These commands must not
change the viewed state.

## Camera validation

### Camera type probe

Task ID: `W3-PH5-003`.

Use one integer at a time. Record the visual meaning and readback; reset between
values. A successful readback does not by itself mean a type is safe for PotS.

```text
/debug wc3 camera type
/debug wc3 camera type set 0
/debug wc3 camera type reset
```

Repeat `set` for values `0` through `16`. Reject a value if it breaks targeting,
camera restoration, SD rendering, or any existing mode. Do not select a
production default during this probe.

### Reversible camera input ownership

Task ID: `W3-PH5-004`.

Capture `/debug wc3 camera` before enabling the probe; its five `Engine input`
flags are the restoration baseline. Then run:

```text
/debug wc3 camera ownership on
/debug wc3 camera
/debug wc3 selftest
```

While enabled, `Input ownership` must report `enabled=true, applied=true`, all
five engine-input flags (distance, far Z, angle, field of view, and rotation)
must be `false`, and the self-test must still report `7/7`. Exercise Normal,
Advanced, Developer, dialog, death, travel, fullscreen cinematic, suspend/resume,
and each camera type retained from the camera-type probe. PotS camera behavior
must remain available while ordinary engine input cannot fight the owned fields.

Restore and verify the exact captured flags:

```text
/debug wc3 camera ownership off
/debug wc3 camera
```

Run this independently on both clients. Enabling or restoring one client must
not change the other client's camera or synchronized gameplay state. Never use
the local readback values for synchronized branching.

### Bounded middle-drag orbit

Task IDs: `W3-PH5-008` through `W3-PH5-010`, `W3-PH5-012`, `W3-PH5-013`,
`W3-PH5-017` through `W3-PH5-022`, `W3-PH5-025`, and `W3-PH5-029` through
`W3-PH5-034`.

```text
/debug wc3 camera orbit on
/debug wc3 camera
```

Test all of the following:

- Middle press without movement still performs the existing reset.
- Movement beyond the dead zone changes stored rotation and angle without a
  reset; fast movement remains clamped.
- Cursor remains visible and is never recentered.
- Releasing the button, leaving the client, Alt-Tab, focus loss, mode change,
  suspension, and orbit disable clear dragging.
- Normal mode permits orbit; Advanced, Developer, special-zone, dialog, death,
  travel, and fullscreen cinematic ownership suppresses it.
- The Game menu and its child panels, inventory, equipment, crafting, shop,
  quest journal, talents, ability trainers, gamble offers, and fullscreen UI
  block drag start. Closing one overlapping panel must not remove another
  panel's blocker.
- Terrain, units, minimap, command card, and the listed custom panels do not
  receive unintended orders or leave stuck input.
- DynamicMinimap does not fight rotation immediately after a drag.
- The existing shared camera input timer remains inactive when orbit and all
  keyboard input are inactive.

Disable after the test:

```text
/debug wc3 camera orbit off
/debug wc3 camera type reset
```

### Two-client camera gate

Task IDs: `W3-PH0-018`, `W3-PH5-020`, `W3-PH5-033`, and `W3-VAL-024`.

1. Put both clients at visibly different camera angles and positions.
2. Run `/debug wc3 camera` on both clients and save both outputs.
3. Enable orbit for both clients.
4. Drag simultaneously in opposite directions for at least 30 seconds.
5. Open inventory on one client and the Game menu on the other; confirm each
   client is blocked independently.
6. Continue normal synchronized gameplay for at least five minutes.

Pass criteria: no cross-player camera movement, gameplay-state change, handle
divergence, disconnect, or desync.

## Fog validation

Task IDs: `W3-PH6-001`, `W3-PH6-003` through `W3-PH6-007`, and `W3-VAL-006`.

### Legacy capture and parity

In each representative state, run `/debug wc3 fog`, take a screenshot, and
record current and target values:

- outdoor daytime and nighttime;
- dungeon;
- snow/rain weather if available;
- active storm before, during, and after a lightning flash;
- death/cinematic override;
- two players occupying different zones.

Then, without changing zone, run:

```text
/debug wc3 fog test parity
/debug wc3 fog
/debug wc3 fog reset
```

The parity preset must look identical to the captured legacy-linear state, and
reset must restore the complete previous target state.

### Extended presets

Run separately, resetting before changing zones or starting another test:

```text
/debug wc3 fog test height
/debug wc3 fog reset
/debug wc3 fog test exp
/debug wc3 fog reset
```

During each test, trigger a storm flash where possible. Confirm the override
restores style, height range, linear range, maximum density, draw-over-sky, RGB,
Z range, and density—not only the legacy fields.

Run the height or exponential preset on only one client in a two-client session.
The other client's presentation and both clients' synchronized gameplay must
remain unchanged.

## Doodad validation

Task IDs: `W3-PH7-001`, `W3-PH7-003`, `W3-PH7-004`, `W3-PH7-010` through
`W3-PH7-014`, and `W3-VAL-007`.

### Batched read-only scan

```text
/debug wc3 doodads scan
```

Record count, elapsed time, invalid-ID count, model-axis count, pitch/roll count,
non-uniform-scale count, and both fingerprints. The scan processes 256 entries
per 0.03-second tick and does not replace `DoodadRender`.

Repeat:

- on both clients in the same session;
- after a full map reload;
- after a no-op World Editor save/rebuild.

Matching count and fingerprints establish the first index-stability evidence.
If index `0` reports invalid while the last candidate appears valid, investigate
whether the build uses one-based indexing before running a mutation.

The scan can be aborted with:

```text
/debug wc3 doodads scan cancel
```

### Reviewed single-instance probe

Choose an ordinary, visible, static doodad outside any `DoodadManager` type and
away from quest/pathing interactions. Inspect it first:

```text
/debug wc3 doodads inspect <index>
/debug wc3 doodads probe hide <index>
/debug wc3 doodads probe reset
```

The harness rejects rawcodes owned by `DoodadRender`. The reviewed doodad alone
must hide, `show` must restore it, nearby same-type doodads must remain visible,
and pathing/selection must remain unchanged. Reload the disposable map if its
model does not implement a reversible `hide`/`show` pair.

## Doodad authoring and creation-site review

World Editor owns placed-doodad pitch, roll, local-axis scale, and pathing
verification. Make these changes only in the disposable full-map copy.
For each candidate, record rawcode, coordinates, old/new values, screenshot,
pathing result, selection result, save/reopen result, and game-client result.

The active repository creation-site review found five relevant procedural
destructible sites:

| File | Purpose | Pitch/roll decision |
| --- | --- | --- |
| `BridgesAndGates/BridgeSystem.j` | Invisible pathing blockers | Keep legacy creation; rotation has no visual benefit. |
| `GatherSystems/GatherNodes.j` | Water-depth platform | Keep legacy creation; large hidden platform must remain level. |
| `QuestsAndDialogs/QuestGivers/Troll/qOutcastJinzun.j` | Restored Mighty Tree | Keep legacy creation until a specific tilted tree placement is designed and pathing-tested. |
| `QuestsAndDialogs/QuestGivers/Orcs/qRagno.j` | Quest stash | Keep legacy creation; no current authored pitch/roll requirement. |
| `QuestsAndDialogs/QuestGivers/Orcs/qRagno.j` | Lumber blocker | Keep legacy creation; blocker should remain level. |

No active trap creation site requiring migration was found. Draft, unused,
archived, and Blizzard helper files were excluded. Therefore the first P1 pass
does not replace any `CreateDestructable*` call merely because a 3.0 overload is
available.

## Result recording

Fill one row per execution. Attach screenshots or logs next to this document if
needed.

| Date/time | Task ID(s) | Client/player | Zone/state | Command/action | Result | Evidence/notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-09-17 | Baseline only | Repository | Folder-map generated script | `pjass` with active 3.0 Blizzard API | PASS | Existing map snapshot parsed; new sources not imported |
| 2026-09-17 | Camera static structure | Repository | In-memory folder-map substitution | `pjass` with current `CameraControl` | PASS | No map file was changed |
| 2026-09-17 | Fog/harness static structure | Repository | Focused transformed sources | `pjass` with active 3.0 API and typed PotS stubs | PASS | Does not replace full-map import |
|  | `W3-PH0-017`, `W3-VAL-001` |  |  | World Editor/JassHelper compile | PENDING |  |
|  | `W3-VAL-004` |  |  | Passive smoke | PENDING |  |
|  | Camera task IDs |  |  |  | PENDING |  |
|  | Fog task IDs |  |  |  | PENDING |  |
|  | Doodad task IDs |  |  |  | PENDING |  |

## Rollback

- Camera: `/debug wc3 camera orbit off` and `/debug wc3 camera type reset`.
- Camera ownership: `/debug wc3 camera ownership off` restores the five captured
  engine-input flags; use it before ending every ownership test.
- Fog: `/debug wc3 fog reset`; reload the map if an interruption prevented reset.
- Doodads: `/debug wc3 doodads probe reset`; reload if the chosen model lacks a
  reversible `show` sequence.
- Full rollback: restore the previous versions of the changed libraries and
  reimport them into the disposable map. The map's Object Editor and placed
  doodads remain unchanged by repository source edits.
