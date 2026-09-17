# Warcraft III 3.0 Systems Upgrade Plan

Status: P2 in progress — first SpeciFX slice implemented; manual World Editor and runtime validation pending
Target baseline: Warcraft III 3.0.0, build 24268  
Primary API references: [`_Blizzard/common.j`](../../../_Blizzard/common.j) and [`_Blizzard/blizzard.j`](../../../_Blizzard/blizzard.j)  
Patch reference: [Warcraft III: Reforged - Forsaken Kingdom Patch Notes](https://us.forums.blizzard.com/en/warcraft3/t/warcraft-iii-reforged-forsaken-kingdom-patch-notes/38400)
Native-diff reference: [lep/jassdoc pull request 236](https://github.com/lep/jassdoc/pull/236/files#diff-972de25e121d897d9b087487ceba8b77a107067083654ca45e39ae119324e1f6)  
Stat-carrier discussion: [PurgeandFire on the new 3.0 Object Editor abilities](https://www.hiveworkshop.com/threads/what-new-world-editor-natives-did-we-actually-get-from-the-update.374314/#post-3739349)

## Purpose

Evaluate and adopt Warcraft III 3.0 World Editor features and natives where they materially simplify PotS systems, improve player experience, or remove fragile workarounds. Adoption must be incremental: declaration presence in `common.j` does not prove runtime behavior, save/load behavior, multiplayer safety, or compatibility with PotS custom UI.

The separate 16-bit launcher and World Editor crash investigation is intentionally outside this plan.

## Decisions and constraints

- Warcraft III 3.0.0 becomes the minimum version for code that uses these APIs.
- PotS data and gameplay rules remain authoritative until a native replacement has demonstrated feature parity.
- Do not replace the current inventory and equipment system wholesale. Blizzard exposes a 30-slot extended bag and 9 loadout slots, while PotS supports 12-80 stored-item slots and 20 equipment positions.
- Introduce a bridge around native equipment instead of spreading direct native calls across gameplay systems.
- Keep existing implementations as rollback paths until their replacements pass full-map and multiplayer testing.
- Do not create or maintain separate PotS test maps for this work. The systems under review depend on the real map's rects, placed objects, Object Editor data, initialization order, imports, UI, heroes, and generated data; reproducing that environment would create redundant work and misleading results.
- Run 3.0 probes in a disposable copy of the complete PotS map through a disabled-by-default developer harness. Small code-only tests remain useful for parsers, database migrations, and other logic that does not depend on map state.
- PotS targets the SD/Classic presentation. HD water and other HD-only authoring features are outside this upgrade plan unless that presentation policy changes later.
- PotS remains Orc-themed. Keep the existing Orc/default HUD identity and treat the new race-skin API only as a compatibility concern; do not pursue a Forsaken HUD or per-player race-skin selection.
- The current PotS Game Data Version is `The Frozen Throne`. A manual World Editor check on 17 September 2026 found that at least the newly added abilities are not available there and become visible only after changing Game Data Version to `Forsaken Kingdom`.
- Do not change the production map to `Forsaken Kingdom` merely to gain access to a 3.0 stat carrier. This is a map-wide inherited-data migration for an old, heavily customized map, not a local DEquipment feature toggle, and it may change stock abilities, units, items, upgrades, metadata, defaults, and serialization behavior.
- Treat Ability Vamp, Resolve, Magic Resistance, Ability Amp, Ability Speed, and the related native Stat Details presentation as Object Editor ability/data features unless an exact build-24268 declaration proves otherwise. The active API and the linked jassdoc 3.0 diff contain no dedicated stat getter or setter for them.
- Do not assume that copying a Forsaken carrier into PotS bypasses the Game Data Version requirement. Its parent ability, hardcoded backend, metadata, fields, or assets may still depend on the Forsaken data version. A PotS-owned custom copy is acceptable only after it works under the intended production data version and its dependencies are proven.
- Do not convert the project to Lua. Use the new GUI-to-Lua and Copy As Script tools only for investigation; converted PotS triggers should continue to target maintained JASS/vJASS libraries.
- Treat Object Editor, terrain, placed-object, minimap-paint, lighting, water, fog, sound-variable, and post-processing edits as manual World Editor work.
- Use the exact native spellings from the 3.0 scripts, including `UnitHasAnyItemEquiped` and the `envMapStrengthy` parameter typo where applicable.

## Priority overview

| Priority | High-level ID | Capability | PotS targets | Expected value |
| --- | --- | --- | --- | --- |
| Foundation | `W3-HL-API` | Active 3.0 API, Object Editor carrier, and data-version compatibility audit | `_Blizzard`, full-map object data, upgrade documentation | Prevents native/data-version assumptions before implementation |
| P0 | `W3-HL-CAMERA` | Free-camera ownership and input queries | `CameraControl`, `DialogCamera` | High and independently reversible |
| P0 | `W3-HL-FOG` | Expanded fog controls with legacy-default parity | `FogSystem`, `Storm`, `WeatherSystemV4`, zones | High and visually testable |
| P1 | `W3-HL-DOODADS` | Doodad renderer performance, runtime indexing, rotation/local axes, enumeration, and instance animation | `DoodadManager`, `DoodadRender`, procedural destructibles | High when introduced behind the legacy default |
| P2 | `W3-HL-MINIMAP` | Dynamic minimap generation within camera bounds | `DynamicMinimap` | Potentially very high but camera-bound sensitive |
| P2 | `W3-HL-COMBAT` | Remaining/percentage ability cooldown control | `ShamanCommon`, talent-driven cooldowns | High but combat-sensitive |
| P2 | `W3-HL-EFFECTS` | Special-effect animation queue and blend control | `SpeciFX`, ability visuals | Medium |
| Excluded | `W3-HL-DOODADS` | Doodad and destructible team color | None | Not relevant to PotS; do not implement |
| P3 | `W3-HL-COMBAT` | Attack cooldown reset and global aura toggling | Selected combat/state transitions | Situational |
| P3 | `W3-HL-LIGHTING` | Lighting editor, omni lights, decals, shadow blockers, post processing | Environment authoring | Visual/optimization work |
| P4 / LAST | `W3-HL-ITEMDATA`, `W3-HL-EQUIPMENT`, `W3-HL-ITEMECO` | Game-data migration, equipment classification/type/tag, extended bag, equip events, native-colored bonuses, 3.0 RPG stats, and item team color | `WC3ItemManager`, `DInventory`, `DEquipment`, `SharedDInvLib`, `ItemHook`, `UnitStats`, `StatsUI` | Highest-risk cross-system migration; do last or not at all |

## Task IDs, ownership, and status

Every assignable checklist item has an immutable task ID. Use the ID in chat, commits, changelog entries, test notes, and status updates so a task remains identifiable even when headings or surrounding text change.

| Element | Convention |
| --- | --- |
| High-level workstream | `W3-HL-<descriptive name>`, for example `W3-HL-CAMERA` |
| Phase task | `W3-PH<phase>-<three-digit number>`, for example `W3-PH5-012` |
| Cross-phase validation gate | `W3-VAL-<three-digit number>` |
| Not started | Unchecked checkbox with no inline status |
| In progress | Unchecked checkbox plus `_(Status: IN PROGRESS; Owner: name; Updated: YYYY-MM-DD)_` |
| Ready for runtime test | Unchecked checkbox plus `_(Status: READY FOR TEST; Owner: name; Updated: YYYY-MM-DD)_` |
| Blocked or deferred | Unchecked checkbox plus `_(Status: BLOCKED or DEFERRED; Reason: ...; Updated: YYYY-MM-DD)_` |
| Complete | Checked checkbox; completion evidence belongs in the task text, developer notes, or changelog |

Rules:

- Never renumber or reuse an existing ID. Add a new task with the next unused number in that phase, even if the new task is inserted between older tasks.
- A `W3-HL-*` status summarizes its child tasks; it never replaces their individual statuses or validation evidence.
- Phase numbers describe the implementation area; they are not priority labels. Continue using P0-P3 from the priority table independently.
- Keep the checkbox unchecked for every non-complete state. `BLOCKED`, `DEFERRED`, and `NOT ADOPTED` are not completion.
- Add `Depends on: W3-...` to the inline metadata when a dependency is not obvious from the section order.
- When work spans several tasks, report each ID separately instead of assigning one combined status to an entire phase.

Example assignment:

```markdown
`W3-PH5-NNN` — Status: IN PROGRESS; Owner: name; Updated: YYYY-MM-DD; Depends on: `W3-PH0-NNN`.
```

### High-level workstream register

| High-level ID | Scope | Priority | Status | Child task IDs |
| --- | --- | --- | --- | --- |
| `W3-HL-HARNESS` | Full-map 3.0 harness and semantic probes | Foundation | INITIAL FULL-MAP GATE PASSED — EXTENDED VALIDATION PENDING | `W3-PH0-*` |
| `W3-HL-API` | Active native diff, Object Editor stat carriers, and Game Data Version compatibility | Foundation | BASELINE COMPLETE — P4 CARRIER RESEARCH DEFERRED | `W3-PH0-038` through `W3-PH0-044` |
| `W3-HL-ITEMDATA` | WC3ItemManager schema, UI, W3T, and backfill | P4 / LAST | DEFERRED — DATA-VERSION MIGRATION RISK | `W3-PH1-*` |
| `W3-HL-EQUIPMENT` | Native inventory bridge, equipment bonuses, stats, and UI | P4 / LAST | DEFERRED — DATA-VERSION MIGRATION RISK | `W3-PH2-*` |
| `W3-HL-ITEMECO` | Item consumers, loot, quests, random items, and item color | P4 / LAST | DEFERRED — DATA-VERSION MIGRATION RISK | `W3-PH3-*` |
| `W3-HL-COMBAT` | Cooldown, aura, and attack-reset APIs | P2/P3 | NOT STARTED | `W3-PH4-*` |
| `W3-HL-CAMERA` | Camera ownership, local input, and bounded mouse-look | P0 | DIRECT LOCAL POLLING IMPLEMENTED — MANUAL VALIDATION PENDING | `W3-PH5-001` through `W3-PH5-034` |
| `W3-HL-MINIMAP` | Dynamic minimap generation | P2 | IMPORTED CHUNKS RETAINED — CALIBRATION PENDING | `W3-PH0-047`, `W3-PH5-035` through `W3-PH5-042` |
| `W3-HL-FOG` | Fog state, presets, parity, and restoration | P0 | HEIGHT CANDIDATE CONFIRMED — PARITY/MULTIPLAYER VALIDATION PENDING | `W3-PH6-001` through `W3-PH6-008` |
| `W3-HL-LIGHTING` | SD lighting, omni lights, shadows, and post processing | P3 | NOT STARTED | `W3-PH6-009` through `W3-PH6-014` |
| `W3-HL-DOODADS` | Doodad renderer performance, enumeration, instances, rotation, and axes | P1 | LEGACY RENDERER RETAINED — OPTIONAL TESTS DEFERRED | `W3-PH7-*` |
| `W3-HL-EFFECTS` | Special-effect animation and blending | P2 | BASIC SINGLE-CLIENT PROBE PASSED — EXTENDED VALIDATION PENDING | `W3-PH8-001` through `W3-PH8-005` |
| `W3-HL-HUD` | Orc HUD and hero-presentation compatibility | P2 | NOT STARTED | `W3-PH8-006` through `W3-PH8-009` |
| `W3-HL-SOUND` | Editable sound-variable paths and exports | P3 | NOT STARTED | `W3-PH8-010` through `W3-PH8-012` |
| `W3-HL-WORKFLOW` | Trigger authoring and World Editor workflow | P3 | NOT STARTED | `W3-PH8-013` through `W3-PH8-017` |
| `W3-HL-ROLLOUT` | Ordered adoption and rollback milestones | Cross-phase | IN PROGRESS | `W3-PH9-*` |
| `W3-HL-VALIDATION` | Compilation, parity, multiplayer, and performance gates | Cross-phase | IN PROGRESS | `W3-VAL-*` |

### Current P0/P1 focus queue

| Order | Priority | High-level ID | Task IDs | Deliverable | State |
| ---: | --- | --- | --- | --- | --- |
| 1 | P0 | `W3-HL-HARNESS` | `W3-PH0-017`, `W3-PH0-045`, `W3-VAL-001`, `W3-VAL-004` | Compile the passive harness, run its read-only self-test, and record an unchanged full-map baseline. | FULL-MAP COMPILE/START AND 7/7 SELF-TEST PASSED; BROADER BASELINE PENDING |
| 2 | P0 | `W3-HL-CAMERA` | `W3-PH0-018`, `W3-PH5-008` through `W3-PH5-010`, `W3-VAL-024` | Establish the two-client local-input safety baseline. | READY FOR TWO-CLIENT TEST |
| 3 | P0 | `W3-HL-CAMERA` | `W3-PH5-003`, `W3-PH5-004`, `W3-PH5-012`, `W3-PH5-013`, `W3-PH5-022` | Implement reversible camera-type/input-ownership probes and production middle-drag mouse-look. | DIRECT POLLING IMPLEMENTED; READY FOR PLAY TEST |
| 4 | P0 | `W3-HL-CAMERA` | `W3-PH5-017` through `W3-PH5-021`, `W3-PH5-025`, `W3-PH5-029` through `W3-PH5-034` | Validate camera ownership, cancellation, UI suppression, suspension, performance, and multiplayer behavior. | IMPLEMENTED; READY FOR MATRIX TEST |
| 5 | P0 | `W3-HL-FOG` | `W3-PH6-001`, `W3-PH6-003` through `W3-PH6-007`, `W3-VAL-006` | Capture legacy fog parity, introduce the complete preset state, and validate restoration/locality. | READY FOR CAPTURE AND TEST |
| 6 | P1 | `W3-HL-DOODADS` | `W3-PH7-001`, `W3-PH7-004` through `W3-PH7-009`, `W3-PH7-015`, `W3-PH7-016`, `W3-VAL-007` | Retain the legacy rawcode/rect renderer; reopen indexed or static `dvis` experiments only for a measured performance need. | LEGACY AREA BACKEND ACCEPTED; OPTIONAL TESTS DEFERRED |

The planned repository probes for every row are now present. Runtime-only evidence and exact commands are tracked in [`Warcraft III 3.0 P0-P1 Validation Log.md`](Warcraft%20III%203.0%20P0-P1%20Validation%20Log.md); `W3-HL-DOODADS` remains in progress because its authoring, persistence, pathing, and conditional optimization tasks are intentionally manual or evidence-gated.

### Foundation/P0/P1 completion boundary

P2 may proceed without waiting for manual P0/P1 evidence, but that does not mark every P1 task complete. The remaining unchecked Foundation/P0/P1 tasks fall into one of three explicit categories:

- **Manual validation:** World Editor/JassHelper compilation, SD visual review, authored doodad checks, and one-/two-client runtime evidence. These remain open and are owned by Valdemar.
- **Conditional optimization:** global doodad indexing/render replacement and pathing-native replacement proceed only if the recorded benchmarks and equivalence tests justify them. They are not prerequisites for P2.
- **Deferred optional experiments:** captured cursor mode, right-drag, local yaw/pitch, cinematic depth of field, and camera blockers are outside the accepted bounded-camera scope. They remain documented but do not block P2.

The Foundation API baseline is complete for current work. Tasks `W3-PH0-041` through `W3-PH0-044` belong to the separately deferred P4 Forsaken Game Data Version/carrier investigation and are not hidden P0/P1 blockers.

### Current P2 focus queue

| Order | Priority | High-level ID | Task IDs | Deliverable | State |
| ---: | --- | --- | --- | --- | --- |
| 1 | P2 | `W3-HL-EFFECTS` | `W3-PH0-046`, `W3-PH8-001` through `W3-PH8-004` | Add backward-compatible named animation, queue, and blend APIs with a resettable full-map probe. | BASIC SINGLE-CLIENT PROBE PASSED; ENDURANCE/TWO-CLIENT TESTS PENDING |
| 2 | P2 | `W3-HL-MINIMAP` | `W3-PH0-047`, `W3-PH5-035` through `W3-PH5-042` | Retain imported chunks and calibrate their world/camera bounds plus full-map source image against the authored map. | NATIVE VISUAL ROUTE REJECTED; IMPORTED CALIBRATION PENDING |
| 3 | P2 | `W3-HL-COMBAT` | `W3-PH4-001` through `W3-PH4-006` | Establish cooldown-adjustment semantics, then migrate only proven Shaman use cases. | NOT STARTED — COMBAT SEMANTICS GATE |

`W3-HL-EFFECTS` starts P2 because it can be added without changing existing effect call sites. The map's native camera-bounds minimap option remains available for diagnostics, but the full-map visual comparison selected imported chunks as the production source. Doodad/destructible team coloring is excluded from the PotS upgrade, while cooldown migration remains blocked on combat-semantics evidence. Exact effect and minimap commands and acceptance criteria are recorded in [`Warcraft III 3.0 P2 Validation Log.md`](Warcraft%20III%203.0%20P2%20Validation%20Log.md).

## W3-HL-HARNESS — Phase 0 - Full-map 3.0 validation harness

PotS integration tests must run in the complete map. A reduced map would omit the rects, zones, placed objects, generated Object Editor data, initialization order, custom frames, imports, and cross-system state that are most likely to expose failures. Use a disposable development copy of the full map rather than maintaining a parallel test environment.

### Harness structure

- [x] **W3-PH0-001** — Add a small coordinating `Debug/Warcraft300TestHarness.j` library and expose its entry points through the existing centralized `/debug` command dispatcher in `Debug/DebugCommands.j`.
- [x] **W3-PH0-002** — Keep the harness disabled by default and prevent automatic probes during normal map initialization. Tests begin only through explicit `/debug wc3 ...` commands; version 0.1.0 has no initializer and no mutating probe.
- [x] **W3-PH0-003** — Divided the current P0/P1 probes into independently runnable camera, fog, and doodad suites; future equipment, inventory, cooldown, and minimap workstreams retain separate command namespaces.
- [ ] **W3-PH0-004** — Reuse the real PotS heroes, existing stat-specific TEST items, Object Editor data, UI, zones, and systems. Add temporary test objects only where existing data cannot express a required positive, negative, or boundary case.
- [ ] **W3-PH0-005** — Run position-dependent probes at the selected hero, current camera target, or a deliberately chosen existing development area. Do not add artificial rect duplicates merely to make a test self-contained.
- [x] **W3-PH0-006** — Every current mutating probe has an explicit off/reset command; the doodad ledger also requires a map reload when a reviewed model lacks a reversible `hide`/`show` pair.
- [x] **W3-PH0-007** — Feature flags remain separate from the harness: production middle-drag mouse-look starts enabled but remains idle until local input, camera-type/input-ownership experiments remain disabled, extended fog requires an explicit test command, and doodad mutation is never part of startup.
- [ ] **W3-PH0-008** — Print concise before/after values and PASS/FAIL invariants in game, then record the exact editor/client build, map build, SD graphics settings, suite, player, and feature-flag state in the associated developer notes. The read-only PASS/FAIL command is implemented; environment/evidence recording remains manual. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH0-009** — Test host and second player, full map reload, hero death/revival, morphing, item transfer, and item destruction where relevant.
- [x] **W3-PH0-010** — Camera/input and fog presentation calls are locally guarded; the harness does not write local query results into synchronized gameplay state.
- [ ] **W3-PH0-011** — Verify behavior in the supported SD/Classic presentation at representative low and high settings where applicable.
- [ ] **W3-PH0-012** — Do not merge a production migration based only on successful compilation or a single-player harness pass.

### Implementation progress - 17 September 2026

- [x] **W3-PH0-013** — Added `/debug wc3 status`, `/debug wc3 camera`, `/debug wc3 fog`, and `/debug wc3 doodads` as the first read-only full-map baseline suite.
- [x] **W3-PH0-014** — Camera diagnostics report the existing `CameraControl` mode and stored fields plus 3.0 camera type, local-client state, resolution, mouse pixels/frame coordinates, and middle-button state. All local input/camera queries are guarded for the triggering local player.
- [x] **W3-PH0-015** — Fog diagnostics report the effective current values, transition targets, fade state, and override depth without changing the existing linear fog path.
- [x] **W3-PH0-016** — Passive doodad diagnostics call only `BlzGetNumDoodads`. Index enumeration and the single-instance animation probe require explicit commands; global renderer ownership remains disabled and coloring is excluded.
- [x] **W3-PH0-017** — Compile the imported harness in World Editor/JassHelper 3.0.0.24268 and capture the first full-map baseline. The map started and `/debug wc3 selftest` reported `7/7`; the wider representative-zone and two-client baseline remains under the applicable validation tasks. _(Status: PASSED INITIAL FULL-MAP GATE; Reported by: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH0-018** — Repeat the camera check with two clients at different camera positions and use the enabled middle-drag mouse-look independently. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17; Depends on: `W3-PH0-017`)_
- [x] **W3-PH0-045** — Added `/debug wc3 selftest`, a read-only local baseline that reports PASS/FAIL for client dimensions, camera type range, fog state invariants, full-map doodad visibility, and optional camera-ownership persistence without changing state.
- [x] **W3-PH0-046** — Added `Debug/Warcraft300P2TestHarness.j` with an explicit, synchronized, resettable `wc3 effects` suite. It owns at most one probe effect per triggering player and performs no startup mutation.
- [x] **W3-PH0-047** — Extended the P2 harness with local-only native/imported terrain-source selection, full/chunked view selection, force refresh, and status commands for `DynamicMinimap`; imported terrain remains the rollback default.
- [x] **W3-PH0-048** — A temporary single-doodad color probe was added, then removed after doodad/destructible team coloring was excluded from PotS. No color command or color-native call remains. _(Status: RETIRED; Updated: 2026-09-17)_

### Full-map test workflow

1. Make or restore a disposable copy of the current full map and confirm that its unmodified baseline loads, compiles, and starts normally.
2. Import the current source changes and the disabled harness, compile through the normal World Editor/JassHelper workflow, and run a smoke session with no test suite activated.
3. Enable exactly one experimental path and execute its `/debug` suite using controlled items/units. Save the output and compare it with the baseline.
4. Restart the map between tests that alter initialization state, Object Editor-derived state, terrain/environment state, or undocumented native state.
5. Repeat synchronization-sensitive suites with at least two players and different selected heroes/camera positions.
6. Disable the experiment and confirm the legacy path still works before changing the production default.

Separate executable or code-only tests remain appropriate for `WC3ItemManager`, SQL migrations, W3T import/export, binary assets, and other tooling whose correctness does not depend on the live map.

### Inventory probe matrix

- [ ] **W3-PH0-019** — Determine which Object Editor unit ability or field enables the native extended bag and equipment panel.
- [ ] **W3-PH0-020** — Reproduce the behavior of Garek's Backpack in the disposable full-map copy with a reviewed test item/unit and document all required object data.
- [ ] **W3-PH0-021** — Confirm that `UnitExtendedInventorySize` reports actual capacity and whether capacity can vary by unit.
- [ ] **W3-PH0-022** — Confirm bag slot indexing and bounds for `UnitItemInBagSlot`.
- [ ] **W3-PH0-023** — Confirm `UnitEquipItem`, `UnitUnequipItem`, and `UnitUnequipItemFromSlot` ownership and failure behavior.
- [ ] **W3-PH0-024** — Confirm `EVENT_PLAYER_UNIT_EQUIP_ITEM` and `EVENT_PLAYER_UNIT_UNEQUIP_ITEM` event order, `GetTriggerUnit`, `GetEquippedItem`, and `GetUnequippedItem`.
- [ ] **W3-PH0-025** — Confirm whether `UnitUseItem`, `UnitUseItemPoint`, and `UnitUseItemTarget` work directly on bagged items.
- [ ] **W3-PH0-026** — Confirm direct bag use fires `EVENT_PLAYER_UNIT_USE_ITEM`, consumes charges, observes cooldown groups, and destroys perishable zero-charge items normally.
- [ ] **W3-PH0-027** — Confirm behavior when an item is transferred, pawned, dropped on death, removed with `RemoveItem`, or destroyed while equipped.
- [ ] **W3-PH0-028** — Confirm the native 3D equipment character display works for both PotS heroes, alternate unit skins, morphs, hero glow settings, and local selection changes.
- [ ] **W3-PH0-029** — Record how the native unit panel colors positive and negative Strength, Agility, Intelligence, damage, and armor changes from native equipped items: positive equipment deltas should be green and negative deltas red while the permanent value remains white.
- [ ] **W3-PH0-030** — Compare actual native equipped-item abilities, hidden unit abilities, `SetHeroStr/Agi/Int`, `BlzSetUnitBaseDamage`, `BlzSetUnitArmor`, and the 3.0 `UNIT_IF_*`, `UNIT_IF_*_PERMANENT`, and `UNIT_IF_*_WITH_BONUS` fields. Determine which approaches change gameplay, which change the displayed base, and which produce a genuine colored bonus.
- [ ] **W3-PH0-031** — Test whether writing `UNIT_IF_*_WITH_BONUS` is supported and persistent in 3.0.0.24268; declaration and a successful boolean return are insufficient without level-up, morph, save/load, and UI-refresh tests.

### Warcraft III 3.0 stat and ability probe matrix

The [HiveWorkshop 3.0 equipment, stat, and talent guide](https://www.hiveworkshop.com/threads/reforged-3-0-new-equipment-stats-and-talent-system.374193/#post-3739263) identifies `[ASde]` Stat Details (Hero), its configurable `Data - Supported stat modifiers` flags, `[ASpc]` as the shared native UI entry point, and `[AGsv]` Warcry Ability Vamp as a 20% spell-vamp example. [PurgeandFire's follow-up](https://www.hiveworkshop.com/threads/what-new-world-editor-natives-did-we-actually-get-from-the-update.374314/#post-3739349) makes the key distinction: the new statistics appear to be implemented through abilities under Object Editor > Abilities > Special rather than dedicated stat natives. This is valuable discovery evidence, but it is a community Object Editor investigation rather than a runtime contract. These object abilities are not declarations in `common.j`; verify their parent rawcodes, fields, Game Data Version visibility, and behavior in the current World Editor and in an exported 3.0 W3A before designing around them.

Audit every modifier exposed by `[ASde]`, not only the three newly noticed labels:

| Native Stat Details label | Closest current PotS concept | Initial policy |
| --- | --- | --- |
| Health Regeneration | Stat 5 flat and stat 6 percent regeneration | Verify which component or combined value the native panel reports. |
| Mana Regeneration | Stat 8 flat and stat 9 percent regeneration | Verify behavior for Mana, Rage, Energy, and units without mana. |
| Attack Speed | Stat 20 | Compare caps, sign convention, and displayed total with `DQAS`. |
| Critical Chance % | Stat 10 and `udg_Stats_Crit` | Determine whether the native modifier affects attacks, abilities, or only native systems. |
| Critical Damage % | Stat 11 | Determine the baseline multiplier and whether PotS damage code can share it safely. |
| Spell Crit Chance % | No distinct PotS equipment stat | Keep separate from attack critical chance unless tests prove identical semantics. |
| Spell Crit Damage % | No distinct PotS equipment stat | Define which triggered and native spells qualify before adoption. |
| Ability Speed | No current direct equivalent | Determine units, scale, cooldown classes, and active-cooldown behavior. |
| Ability Speed % | No current direct equivalent | Do not merge flat and percentage forms or assume both mean cooldown reduction. |
| Ability Amp | Possible relationship to stat 38 Spell Power | Treat as a candidate relationship only; test damage, healing, triggered spells, and flat-versus-percent math. |
| Ability Amp % | Possible relationship to stat 37 Spell Power % | Do not alias until its formula and affected abilities match PotS spell-power semantics. |
| Lifesteal % | Stat 22 | Confirm attack/damage-type coverage and stacking with `DQLS`. |
| Ability Vamp | New concept; `[AGsv]` is one known carrier | Keep distinct from Lifesteal and test native versus triggered ability damage and healing. |
| Resolve | No current equivalent | Do not assign gameplay meaning until its exact formula and affected mechanics are measured. |
| Resolve % | No current equivalent | Keep separate from flat Resolve and test caps, negative values, and stacking order. |
| Magic Resistance % | Candidate presentation for inverse stat 28 Spell Damage Taken % | Reconcile formulas and caps; do not store both if they describe the same effective modifier. |

- [ ] **W3-PH0-032** — Export the relevant stock 3.0 abilities from World Editor and catalogue rawcode, parent ability, data fields, value scale, negative-value support, stacking rule, caps, UI refresh behavior, and whether the ability is safe to clone and modify dynamically.
- [ ] **W3-PH0-033** — Include the known framework abilities `[AIni]` Expanded Inventory, `[AEqu]` Equipment Slots, `[ASde]` Stat Details, `[ASpc]` shared UI entry point, `[ATua]` talent controller, `[ATap]` talent-point grant, and `[AGsv]` Ability Vamp in the catalogue, plus every additional 3.0 stat carrier discovered in the installed Object Editor data. Treat Forsaken campaign examples as discovery material, not an automatic production dependency.
- [ ] **W3-PH0-034** — Use `[ASde]` as a diagnostic reference for native values during probes. Do not add its panel to production beside `StatsUI` unless it offers a confirmed benefit that cannot be presented cleanly in the PotS UI.
- [ ] **W3-PH0-035** — For each combat stat, test base ability, cloned ability, direct item ability, aggregate hidden carrier, ability-level change, runtime field write, ability remove/re-add, death/revive, morph, dispel, save/load, and 100 equip/unequip cycles.
- [ ] **W3-PH0-036** — Test mixed native and triggered damage separately. Record attack damage, spell damage, periodic damage, reflected damage, summoned-unit damage, healing, overheal, immunities, zero damage, fatal damage, and attribution behavior where relevant.
- [ ] **W3-PH0-037** — Treat an unknown semantic result as a blocker for that individual stat, not as a reason to guess or to block unrelated proven stats.

## W3-HL-API — Phase 0 - 3.0 API and Object Editor data baseline

The linked jassdoc pull request is a useful categorized discovery index, but `_Blizzard/common.j` and `_Blizzard/blizzard.j` remain the PotS signature authority. A 17 September 2026 comparison found 130 unique native declarations added by the pull-request diff and zero missing from the active PotS `common.j`. The diff contains no dedicated Ability Vamp, Resolve, Magic Resistance, Stat Details, `[AGsv]`, or `[ASde]` API. Consequently, DEquipment and WC3Manager must model the new statistics as verified ability-backed providers unless later scripts expose an exact native.

**Observed Game Data Version boundary:** Valdemar's 17 September 2026 World Editor check supersedes the earlier working inference. With Game Data Version set to `The Frozen Throne`, the newly added abilities could not be found; changing it to `Forsaken Kingdom` exposed them. Patch 3.0 installs the editor/runtime support, but an old map's selected data version still controls whether at least these stock ability definitions are available. It remains unproven whether a copied custom carrier can function after reverting to `The Frozen Throne`, and it must not be assumed that a custom object contains the carrier's hardcoded backend or complete metadata.

The production policy is therefore **defer, do not migrate now**. DEquipment, WC3Manager, native equipment, and new-stat adoption are the final P4 workstream and begin only after the lower-risk 3.0 upgrades are complete, the feature value still justifies the risk, and a disposable full-map migration proves that switching to `Forsaken Kingdom` does not alter existing gameplay or data unexpectedly. Remaining on `The Frozen Throne` with the current PotS systems is the approved rollback and may become the permanent decision.

| jassdoc 3.0 area | PotS disposition |
| --- | --- |
| Extended inventory, equipment slots/events, classification, type, tag, and filtered random items | Planned under `W3-HL-ITEMDATA`, `W3-HL-EQUIPMENT`, and `W3-HL-ITEMECO`; remains behind semantic probes. |
| Cooldown remaining/percent adjustment, attack reset, and aura enablement | Planned under `W3-HL-COMBAT`; gameplay-sensitive and not implied by the new stat carriers. |
| Camera type/input ownership, held input, mouse screen coordinates, and pixel/frame conversion | Camera type/ownership remain disabled probes; direct local middle-drag polling is implemented as production input under `W3-HL-CAMERA`; runtime and two-client gates remain open. |
| Extended fog controls | Implemented with legacy-default parity under `W3-HL-FOG`; visual/locality gates remain open. |
| Doodad enumeration/animation and destructable pitch/roll creation | Enumeration, a resettable per-instance animation probe, and an opt-in indexed `DoodadRender` backend are implemented under `W3-HL-DOODADS`; production migration remains open until initialization, transition-stutter, steady-FPS, correctness, and multiplayer gates pass. Doodad/destructible coloring is excluded. |
| Special-effect named animation, queue, and blend time | Implemented behind explicit P2 probes under `W3-HL-EFFECTS`; production migration remains evidence-gated. |
| HD water | Not adopted because PotS targets SD/Classic presentation. |
| Race skin, hero glow, model cinematics, shadow-casting light count, pathability, text-area autoscroll, trigger state/interrupt, thematic-music focus, and animation-duration helpers | Keep in the API backlog. Adopt only for a concrete PotS use case with an exact local signature check and a focused runtime test. |

- [x] **W3-PH0-038** — Compare every native added by the linked jassdoc pull-request diff with active `_Blizzard/common.j`. Result: 130 unique diff natives, all 130 present in build-24268 `common.j`; no stat-specific native was found.
- [x] **W3-PH0-039** — Classify the diff by existing PotS workstream and explicitly retain low-priority or unsupported areas in the API backlog instead of treating every new declaration as an adoption requirement.
- [x] **W3-PH0-040** — Record the current PotS Game Data Version and check new-ability visibility. Result reported from World Editor on 17 September 2026: `The Frozen Throne` does not expose at least the newly added abilities; `Forsaken Kingdom` does. This establishes a real data-version dependency for the stock definitions.
- [ ] **W3-PH0-041** — If P4 is eventually authorized, catalogue every candidate carrier as Forsaken-version data: parent rawcode, custom rawcode, fields, hardcoded behavior, icon/model/sound paths, SD availability, and behavior after returning a disposable copy to `The Frozen Throne`. _(Status: DEFERRED; Reason: final-priority migration research; Updated: 2026-09-17)_
- [ ] **W3-PH0-042** — If P4 is eventually authorized, clone only one reviewed carrier in a disposable copy of the complete PotS map, export `war3map.w3a`, test both data versions, and prove through before/after object-data comparison that no unrelated stock or custom object changed. _(Status: DEFERRED; Depends on: `W3-PH0-041`; Updated: 2026-09-17)_
- [ ] **W3-PH0-043** — Before any production data-version change, switch only a disposable full-map copy to `Forsaken Kingdom`, save/reopen/export it, and produce a complete inherited/custom object and map-file diff with an independent rollback. Treat any unexplained change as a migration blocker. _(Status: DEFERRED; Reason: final-priority migration gate; Updated: 2026-09-17)_
- [ ] **W3-PH0-044** — Validate any adopted carrier in SD/Classic on every supported ownership/installation profile available for PotS distribution. Do not depend on a Forsaken-specific asset or campaign entitlement unless that requirement is intentionally added and documented.

### Recommended first upgrade sequence

Begin with camera, fog, and narrowly scoped doodad work. These systems are reversible presentation changes that can be compared directly against the current behavior and disabled without migrating items, combat math, database rows, save-sensitive equipment state, or quest ownership rules. This visual-first decision supersedes the earlier recommendation to begin with `DEquipment`; the equipment/stat work remains planned but is deliberately postponed.

Recommended order:

1. Add the minimum full-map harness commands and baseline capture needed for camera, fog, and doodad probes.
2. Upgrade camera ownership and input handling first. Use direct local middle-button polling for bounded mouse-look and write only through the existing `CameraControl` state; keep camera-type and field-ownership experiments disabled.
3. Extend fog storage and restoration while reproducing the current visuals exactly. Enable one new fog mode in one reviewed area only after legacy linear fog, storms, dungeons, and split-party presentation remain unchanged.
4. Apply safe World Editor doodad authoring improvements to a small reviewed set, then test read-only doodad enumeration and one resettable single-instance animation probe. Do not replace global doodad rendering in this first pass.
5. Compare performance, multiplayer behavior, and rollback results before expanding any of the three workstreams.

The first pass explicitly excludes native inventory/equipment adoption, DEquipment stat migration, cooldown changes, dynamic minimap replacement, global doodad-index ownership, and broad lighting/post-processing changes. DEquipment/WC3Manager/native-equipment/stat work is now P4 and must remain the final migration workstream because it requires evaluating a `The Frozen Throne` to `Forsaken Kingdom` Game Data Version change. The other deferred systems can follow after the visual-first work establishes a stable 3.0 development and validation routine.

## W3-HL-ITEMDATA — Phase 1 - Extend WC3ItemManager and W3T round trips

This phase is P4 / LAST and remains deferred with the equipment/stat migration. Do not add Forsaken-only stat mappings or change production item data while PotS remains on Game Data Version `The Frozen Throne`. Tool-only parsing research may proceed later against copies, but it must not imply approval to migrate the map or production database.

### Data model

- [ ] **W3-PH1-001** — Add `Equipment` to every `wc3_classification` selector and normalizer. It maps to Object Editor field `icla` and runtime `ITEM_TYPE_EQUIPMENT`.
- [ ] **W3-PH1-002** — Add a dedicated `wc3_item_tag` column instead of overloading PotS item class, rarity, drop source, or notes.
- [ ] **W3-PH1-003** — Support `Undefined`, `Droppable`, `Quest Reward`, `Boss Drop`, `Secret`, `Puzzle`, `World`, and `Shop`, matching `ITEMTAG_TYPE_*`.
- [ ] **W3-PH1-004** — Add a dedicated `wc3_equipment_type` column for `None`, `Head`, `Chest`, `Gloves`, `Boots`, `Ring`, `Primary`, `Offhand`, and `Trinket`.
- [ ] **W3-PH1-005** — Keep `equipment_slot` as the richer PotS `DEquipment` slot. Native equipment type and PotS equipment slot are related but not interchangeable.
- [ ] **W3-PH1-006** — Add a numbered SQL migration after the current migration set, then update `database/schema.sql`, `database/schema_wc3_full_support.sql`, and configuration labels.
- [ ] **W3-PH1-007** — Add database constraints or centralized normalization so UI, import, batch edit, and scripts use identical values.

### Item editor and batch editor

- [ ] **W3-PH1-008** — Update `WC3ItemManager/ItemEditForm.cs` with Equipment classification, native equipment type, and item tag controls.
- [ ] **W3-PH1-009** — Update `WC3ItemManager/BatchItemEditDialog.cs` with the same fields and mixed-value behavior.
- [ ] **W3-PH1-010** — Update `WC3ItemManager/ConfigurationForm.cs` and the main item grid/filter configuration.
- [ ] **W3-PH1-011** — Show a warning when `deq_compatible` is enabled but native classification/type is inconsistent.
- [ ] **W3-PH1-012** — Add an explicit "native inventory compatible" preview rather than silently changing existing items.

### Combat-stat schema and authoring

- [ ] **W3-PH1-013** — Preserve existing item-stat IDs 1-49 and their meanings. Add any genuinely new 3.0 stats after the current range; never insert or renumber IDs because generated JASS, saved database rows, exports, and runtime arrays depend on stable identifiers.
- [ ] **W3-PH1-014** — Add rows only for distinct PotS gameplay concepts confirmed by the probe matrix. Expected candidates include Spell Critical Chance, Spell Critical Damage, Ability Speed flat/percent, Ability Amp flat/percent, Ability Vamp, Resolve flat/percent, and Magic Resistance only if it is not simply a presentation transform of stat 28.
- [ ] **W3-PH1-015** — Store canonical name, short UI label, category, display order, flat/percent scale, sign convention, minimum/maximum, runtime provider, carrier rawcode/field, and whether the stat is valid as an item affix. Avoid scattering these decisions across `ItemEditForm.cs`, exporters, `DEquipment.j`, and `StatsUI.j`.
- [ ] **W3-PH1-016** — Update the stat picker, filters, batch editor, tooltip preview, random-stat generation, help text, DEquipment export, and test-item creation together. Group new stats under understandable Offense/Defense/Utility categories rather than adding an unstructured tail to every selector.
- [ ] **W3-PH1-017** — Audit `StatAbilityMapper.cs` and `ItemEditForm.cs` before enabling new mappings. `ItemEditForm.cs` currently aliases `Magic Resistance` and `Spell Resistance` to the `Spell` mapping, while that mapping represents Spell Power %. Remove this semantic collision; resistance must never generate spell-power abilities.
- [ ] **W3-PH1-018** — Generate one reviewed positive test item and, where supported, one negative test item for every adopted stat. Multi-stat test items must verify stacking and presentation but must not replace the single-stat diagnosis set.
- [ ] **W3-PH1-019** — Keep existing production items and generated ability lists unchanged by default. New fields and mappings require explicit opt-in; do not automatically convert Spell Power, Spell Damage Taken, Lifesteal, or critical stats based only on similar labels.
- [ ] **W3-PH1-020** — Add database/export golden comparisons proving that opening and saving an old item without selecting a 3.0 stat does not change its rows, tooltip, generated abilities, W3T data, or DEquipment JASS definition.

### W3T import/export

- [ ] **W3-PH1-021** — Update `core/wc3_w3t_exporter.py`, `core/wc3_w3t_importer.py`, `parsers/wc3_w3t_parser.py`, and the active v2 importer.
- [ ] **W3-PH1-022** — Export/import `icla = Equipment` without falling back to Permanent or Miscellaneous.
- [ ] **W3-PH1-023** — Export/import `itag` and preserve unknown values through `original_modifications`.
- [ ] **W3-PH1-024** — Determine the native equipment-type Object Editor raw field by round-tripping a hand-authored 3.0 test item; do not guess it from the display name `equipment`.
- [ ] **W3-PH1-025** — Update W3T coverage and diagnostic scripts to report the three native classification fields separately.
- [ ] **W3-PH1-026** — Add byte-level golden tests for old and 3.0 W3T samples, including empty/default values.
- [ ] **W3-PH1-027** — Verify that an old W3T can still be imported and re-exported without adding unintended 3.0 fields to every item.

### Backfill policy

Use an audit report before changing production rows. A Warcraft item can have only one native tag, while PotS loot metadata can describe several roles.

- [ ] **W3-PH1-028** — Propose `Equipment` only for items already marked `deq_compatible`; do not apply automatically without review.
- [ ] **W3-PH1-029** — Map exact PotS equipment slots to the closest native equipment type and list unsupported slots.
- [ ] **W3-PH1-030** — Prefer explicit tags. Suggested inference priority is Secret/Puzzle, Quest Reward, Boss Drop, Shop, World, Droppable, then Undefined.
- [ ] **W3-PH1-031** — Never replace PotS rarity, loot-tier, quest gating, or specific-drop metadata with the single native tag.
- [ ] **W3-PH1-032** — Generate before/after SQL reports listing every inferred value and ambiguity.

## W3-HL-EQUIPMENT — Phase 2 - Native inventory and DEquipment bridge

This entire phase is P4 / LAST and remains deferred until a Forsaken Game Data Version migration is explicitly authorized and passes its independent full-map diff. If that gate ever passes, create a small bridge library, tentatively `DestroyerInventoryAndEquipmentSystem/PoTs/DNativeInventoryBridge.j`, only after the probe matrix is complete. The native inventory/equipment API does not imply native setters for Ability Vamp, Resolve, Magic Resistance, Ability Amp, or Ability Speed; those remain independently validated ability-backed providers.

### Slot mapping

| Native loadout slot | PotS `DEquipment` slot | Policy |
| --- | ---: | --- |
| Head | 1 | Direct candidate |
| Chest | 5 | Direct candidate |
| Gloves | 7 | Direct candidate |
| Boots | 12 | Direct candidate |
| Ring | 8 | Direct candidate |
| RingAlt | 9 | Direct candidate |
| Primary | 19 | Direct candidate |
| Offhand | 20 | Direct candidate |
| Trinket | 17 | Primary trinket only |
| No native equivalent | 2, 3, 4, 6, 10, 11, 18 | Keep custom: Neck, Shoulder, Back, Bracers, Belt, Legs, second Trinket |

PotS slots 13-16 are currently unused and must not be repurposed implicitly.

### Authority and event flow

- [ ] **W3-PH2-001** — Choose one authoritative location for every item handle. Never mirror one handle into native and custom slots simultaneously.
- [ ] **W3-PH2-002** — Route native equip/unequip events into existing `AddDEqStatsOfItemToUnit`, `RemoveDEqStatsOfItemFromUnit`, frame refresh, set bonus, and item-handle tracking paths.
- [ ] **W3-PH2-003** — Add re-entrancy guards so a bridge-triggered native event cannot equip or unequip the same item twice.
- [ ] **W3-PH2-004** — Preserve two-handed Primary/Offhand rules and PotS dual-wield abilities.
- [ ] **W3-PH2-005** — Preserve item-set counts, named items, growth items, requirements, item score, and tooltip generation.
- [ ] **W3-PH2-006** — Decide whether native slots are authoritative for the nine mapped positions or only a presentation layer. Do not support both modes concurrently in one release.
- [ ] **W3-PH2-007** — Keep the PotS UI for unsupported slots and capacities above the native 30-slot limit.

### Native-style equipment bonus presentation

This is the recommended first runtime upgrade. It can be implemented and validated before the native inventory bridge because it operates on the existing PotS equipment ledger and does not require changing item storage authority.

`DEquipment.j` defines the equipment-facing system, while the current runtime stat mutation is primarily implemented by `AddDEqStatsOfItemToUnit` and `RemoveDEqStatsOfItemFromUnit` in `SharedDInvLib.j`. The system already maintains equipment totals in `EQIDDB[eqid][5].real[statid]`, and `UpdateDEqCSheet` lists those totals separately. However, several native-visible stats are applied by rewriting the unit's existing value:

- Strength, Agility, and Intelligence call `SetHeroStr/Agi/Int` with `permanent = true`;
- flat Damage calls `BlzSetUnitBaseDamage` for both weapon indices;
- flat and percentage Armor recompute through `BlzSetUnitArmor`;
- repeated add/remove operations therefore treat equipment as changes to the unit's current base instead of an engine-recognized bonus source.

The target behavior is the same visual contract as native item bonuses:

- permanent hero growth, Object Editor values, level gains, tomes, scripted permanent rewards, and morph-specific bases remain part of the white/base value;
- the aggregate contribution of equipped items and active equipment sets appears as a green positive or red negative delta for native-displayable Strength, Agility, Intelligence, damage, and armor;
- unequipping returns the colored delta toward zero without rewriting legitimate base progression;
- PotS-only values such as critical statistics, spell power, profession skills, block, lifesteal, and custom damage modifiers remain in the custom character sheet, with consistent signed green/red formatting where Warcraft has no native display field.

Implementation requirements:

- [ ] **W3-PH2-008** — Preserve `EQIDDB[eqid][5]` as the authoritative aggregate equipment ledger, but stop using permanent/base setters as the normal equipment application path for native-displayable stats.
- [ ] **W3-PH2-009** — Add a single refresh entry point that recomputes native-displayable equipment bonuses from the ledger after equip, unequip, swap, set activation/deactivation, rarity change, item-level change, named-item mutation, load, revive, and morph. Prefer recomputation over accumulating inverse deltas so repeated operations cannot drift.
- [ ] **W3-PH2-010** — Prototype one aggregate hidden bonus ability per semantic group/unit rather than one ability per equipped item. Native-equipped item abilities and the aggregate PotS carrier must never apply the same bonus simultaneously.
- [ ] **W3-PH2-011** — Test `Attribute Bonus` (`Aamk`) as the primary aggregate carrier for Strength, Agility, and Intelligence. The Ability Insight reference reports that it accepts negative bonuses and reacts to ability-level changes, but its behavior and native green/red presentation must be revalidated in Warcraft III 3.0.0.24268.
- [ ] **W3-PH2-012** — Test `Item Damage Bonus` (`AIt*`, field `ABILITY_ILF_ATTACK_BONUS`) and `Item Armor Bonus` (`AId*`, field `ABILITY_ILF_DEFENSE_BONUS_IDEF`) as aggregate carriers. Confirm dynamic field updates, refresh requirements, negative coloring, stacking with actual native items, minimum-damage clamping, and behavior for both weapon indices.
- [ ] **W3-PH2-013** — Do not choose `Item Hero Stat Bonus` (`AIs*`, `AIa*`, `AIi*`, `AIx*`) for a dynamic aggregate without a successful current-patch probe. The Ability Insight reference reports that changing its level or integer field does not apply the new value even when the field reads back correctly.
- [ ] **W3-PH2-014** — Compare the ability-carrier approach with `BlzSetUnitIntegerField` on `UNIT_IF_STRENGTH_WITH_BONUS`, `UNIT_IF_AGILITY_WITH_BONUS`, and `UNIT_IF_INTELLIGENCE_WITH_BONUS`. Adopt direct field writes only if they produce correct native coloring and survive every lifecycle test without modifying the permanent fields.
- [ ] **W3-PH2-015** — Treat `BlzSetUnitBaseDamage`, `BlzSetUnitArmor`, and `SetHeroStr/Agi/Int(..., true)` as base/permanent-authoring APIs, not equipment-bonus APIs, unless a narrowly scoped compatibility fallback is documented.
- [ ] **W3-PH2-016** — Add explicit signed formatting helpers to `UpdateDEqCSheet`: positive totals use green with `+`, negative totals use red with `-`, and zero totals are omitted. Do not emit strings such as `+-5`.
- [ ] **W3-PH2-017** — Keep percentage and flat values semantically separate. For example, do not collapse flat armor and armor percent into one displayed bonus unless the native panel's exact resulting delta can be reconciled with the custom sheet.
- [ ] **W3-PH2-018** — Define how item-set bonuses participate. Native-displayable set bonuses should use the same aggregate carrier and color rules; custom-only set bonuses remain in the PotS character sheet.

Required lifecycle tests:

- [ ] **W3-PH2-019** — Capture base, bonus, and total values before equipment; after each equip/unequip/swap; and after 100 repeated cycles. The final base and total must exactly match the initial state.
- [ ] **W3-PH2-020** — Test positive, negative, fractional, and zero-crossing aggregates, including mixed items whose total changes from green to red.
- [ ] **W3-PH2-021** — Test hero level-up, tome/stat reward, respec, morph, skin change, death/revive, load, ownership transfer, and equipment restoration while bonuses are active.
- [ ] **W3-PH2-022** — Test primary-stat-derived damage separately from flat equipment Damage so the native damage panel does not double-count attribute growth.
- [ ] **W3-PH2-023** — Test heroes with only weapon index 0, both weapon indices, disabled attacks, melee/ranged transformations, and dual-wield/two-handed transitions.
- [ ] **W3-PH2-024** — Verify synchronized gameplay values on at least two clients. Coloring is presentation, but the abilities/fields producing the bonus affect synchronized combat state and must not be changed only inside `GetLocalPlayer` branches.
- [ ] **W3-PH2-025** — Retain the current mutation path behind a temporary rollback flag until the aggregate bonus implementation passes its full-map harness suite and normal full-map regression tests; never enable both paths together.

### 3.0 combat-stat integration

Adopt the new stats individually after the probe matrix establishes their semantics. Availability in the native Stat Details panel does not by itself make a stat appropriate for PotS items, and a visually updated value does not prove that PotS triggered combat uses it.

- [ ] **W3-PH2-026** — Keep Lifesteal and Ability Vamp separate. Lifesteal remains attack-oriented stat 22 unless current-patch testing proves broader behavior; Ability Vamp must have its own ledger entry and must define which ability-damage events can heal.
- [ ] **W3-PH2-027** — Do not repurpose a legacy lifesteal carrier as Ability Vamp without proof. The Ability Insight reference records `AUav` Vampiric Aura as melee-only, `SCva` Life Steal as healing from final attack damage while altering ranged projectile art, and `AIva` Item Life Steal as failing against buildings and behaving unusually with invulnerable targets. Revalidate the current PotS `DQLS` path separately from `[AGsv]`.
- [ ] **W3-PH2-028** — Probe `[AGsv]` as the first Ability Vamp carrier, then clone a PotS-owned hidden aggregate carrier only if dynamic values, negative values, stacking, removal, morphs, and synchronized combat all behave correctly.
- [ ] **W3-PH2-029** — Define Ability Vamp safeguards for self-damage, reflected damage, damage-over-time, summoned units, zero damage, invulnerable targets, overheal, fatal damage, recursion, and damage already credited to Lifesteal. A single damage event must never heal through both systems accidentally.
- [ ] **W3-PH2-030** — Define Resolve and Resolve % only after measuring their native effect. Document the exact affected control/debuff categories, duration formula, order of operations, caps, immunity interactions, dispels, and whether existing PotS timers or buffs bypass the native mechanic.
- [ ] **W3-PH2-031** — Reconcile Magic Resistance with stat 28. If native Magic Resistance is mathematically the inverse presentation of `Spell Damage Taken Pct`, retain one authoritative stored value and expose conversion helpers; do not apply both modifiers. Preserve deliberate vulnerabilities and the existing low cap.
- [ ] **W3-PH2-032** — Do not use Anti-Magic Shell as a resistance carrier based on its label. The Ability Insight reference reports that its legacy `Magic Reduction` field did nothing in tested versions; only a successful Warcraft III 3.0 probe may overturn that warning.
- [ ] **W3-PH2-033** — Reconcile Ability Amp/Ability Amp % with stats 38/37 and `UnitStats`. Adopt aliases only if native and PotS damage/healing coverage, flat/percentage ordering, critical interaction, and triggered-spell behavior are equivalent. Otherwise preserve them as distinct stats with distinct labels.
- [ ] **W3-PH2-034** — Define Ability Speed flat/percent against the Phase 4 cooldown APIs. Test currently cooling abilities, item abilities, charges, zero cooldown, channeling, morphs, ability replacement, and shared cooldown groups. Do not let UI report cooldown speed that PotS abilities do not actually observe.
- [ ] **W3-PH2-035** — Decide whether Spell Critical Chance/Damage belong in the shared damage system before exposing them as item affixes. They must not reuse `udg_Stats_Crit` if that would cause attack and spell criticals to double count or share unintended caps.
- [ ] **W3-PH2-036** — Route every adopted stat through the same aggregate recomputation entry point as existing equipment bonuses. Do not add a second incremental add/subtract path for 3.0 stats.
- [ ] **W3-PH2-037** — Add per-stat feature flags during development. A failed or uncertain carrier must be individually disableable without reverting unrelated equipment fixes.

### DEquipment and StatsUI layout

The UI has no spare implicit capacity. `StatsUI.j` currently defines 3 columns by 13 rows and therefore renders at most 39 detailed stats, exactly the current non-profession range. `UpdateDEqCSheet` builds one unbounded multiline string of nonzero equipment contributions. Appending stat IDs alone would either hide new values in `StatsUI` or risk overflowing the equipment panel.

- [ ] **W3-PH2-038** — Decouple stat display order from numeric stat ID. Add a presentation registry/list so stable append-only IDs can be grouped, reordered, hidden for inapplicable units, or placed on another page without changing database or runtime identity.
- [ ] **W3-PH2-039** — Prefer category pages or tabs within the existing StatsUI panel, such as Core, Offense, Defense, and Utility, while retaining the current 3-by-13 grid and readable 0.68 scale. Do not solve capacity by globally shrinking text unless SD screenshots prove that the result remains legible.
- [ ] **W3-PH2-040** — Keep labels and values aligned in every category. Define compact labels centrally (`Ability Speed`, `Ability Amp`, `Ability Vamp`, `Resolve`, `Magic Resist`, and spell-critical variants), reserve value width for signed percentages, and prevent clipping at 4:3, 16:9, 16:10, and 21:9.
- [ ] **W3-PH2-041** — Preserve the current default page and current stat order during the compatibility phase. Existing players should see the same information in the same places until the replacement layout is approved.
- [ ] **W3-PH2-042** — Replace or bound `UpdateDEqCSheet`'s multiline output before enabling more stats. Prefer a reusable row renderer, category page, or scrollable region that shows only nonzero equipment contributions and supports green positive, red negative, and neutral zero states without overlap.
- [ ] **W3-PH2-043** — Keep the DEquipment contribution view and StatsUI total view semantically distinct: DEquipment shows what equipped items/sets add, while StatsUI shows the unit's effective total and may include talents, buffs, permanent rewards, and class mechanics.
- [ ] **W3-PH2-044** — Add a tooltip or concise description for unfamiliar stats rather than making labels longer. Resolve and Ability Speed especially must not be exposed without an in-game explanation of their proven behavior.
- [ ] **W3-PH2-045** — Produce SD screenshots for empty, ordinary, and worst-case populated layouts before merging. Check long values, negatives, localization-length risk, disabled-resource units, dead heroes, pets, companions, and both main heroes.
- [ ] **W3-PH2-046** — Regression-test focus, clicking, scrolling/page selection, fullscreen ownership, cinematic hide/restore, and return paths between `StatsLiteUI`, `StatsUI`, DEquipment, Abilities, and Professions.

### Direct consumable use

- [ ] **W3-PH2-047** — If the probe succeeds, add one `DInventory` action that calls the appropriate `UnitUseItem*` native on the stored handle.
- [ ] **W3-PH2-048** — Support immediate, point-target, unit-target, and destructible-target items without first moving them through the six quick slots.
- [ ] **W3-PH2-049** — Refresh charge text, stack state, cooldown display, `ItemHook`, `UnitStats`, Resource Energy/Rage, cooking, and quest state after use.
- [ ] **W3-PH2-050** — Define failure behavior when the target is invalid, the item is cooling down, or the hero cannot use the item.
- [ ] **W3-PH2-051** — Keep the existing six-slot transfer route as a fallback until all target modes pass testing.

### Native 3D equipment presentation

- [ ] **W3-PH2-052** — Determine whether the native character display can be opened or embedded without replacing PotS fullscreen frames.
- [ ] **W3-PH2-053** — Test it after `Interface`, `FullscreenUI`, `MasterUI`, and `DEquipment` initialization.
- [ ] **W3-PH2-054** — Verify portrait/model updates after morph, revive, skin change, equipment change, and hero selection.
- [ ] **W3-PH2-055** — If the native display cannot coexist cleanly, retain the PotS equipment UI and prototype a separate visual-only model panel rather than coupling gameplay state to undocumented frames.

## W3-HL-ITEMECO — Phase 3 - Update every item consumer

This phase is P4 / LAST and remains deferred with the native equipment bridge. Inventory support is incomplete until systems stop assuming that all usable items live in six native slots or only in PotS tables, but those consumers must not be changed speculatively before the Game Data Version and storage-authority decisions pass.

- [ ] **W3-PH3-001** — `ItemSystems/ItemHook.j`: register equip/unequip responses and validate create/destroy tracking for bagged and equipped items.
- [ ] **W3-PH3-002** — `UnitSystems/UnitStats.j`: recalculate on native equip/unequip, consume the separated base/equipment totals where appropriate, and prevent duplicate stat application when the bridge or aggregate bonus carriers are active.
- [ ] **W3-PH3-003** — `DestroyerInventoryAndEquipmentSystem/PoTs/HeroItemCheck.j`: search/remove across quick slots, native bag, native equipment, and PotS storage according to category policy.
- [ ] **W3-PH3-004** — `Death/Death.j` and `Death/Revival.j`: include native bag/equipment in difficulty-based loss and exact restoration.
- [ ] **W3-PH3-005** — `Professions/Professions.j` and `Professions/ProfessionsCooking.j`: locate ingredients/tools and process direct consumable-use events safely.
- [ ] **W3-PH3-006** — `AI/AI.j`: teach inventory helpers about bagged/equipped state before AI heroes use or transfer items.
- [ ] **W3-PH3-007** — `PlayerHome/PlayerHome.j`: find the Traveler's Journal without assuming a quick-inventory slot.
- [ ] **W3-PH3-008** — `Resources/ResourceEnergy.j` and `Resources/ResourceRage.j`: refresh resource state after native equip, unequip, and bag use.
- [ ] **W3-PH3-009** — `ItemSystems/ItemCleanup.j`: treat native bagged/equipped items as owned and protected from ground cleanup.
- [ ] **W3-PH3-010** — `ItemLootSystems/ItemLootSystem.j`, `UI/ShopUI.j`, and vendor delivery: choose a deterministic destination and full-inventory fallback.
- [ ] **W3-PH3-011** — `QuestsAndDialogs/QuestGiver.j`: include native inventory categories in quest-item checks without changing quest ownership rules.

### Filtered random items

- [ ] **W3-PH3-012** — Prototype `ChooseRandomItemExWithFilter` using level, `itemtype`, `equipmentType`, and `itemTag`.
- [ ] **W3-PH3-013** — Use it only where engine-side random selection is desirable. PotS loot tables retain authority over rarity, weights, quantities, quest gates, zones, bosses, and specific sources.
- [ ] **W3-PH3-014** — Confirm deterministic synchronized results in multiplayer before using it for gameplay drops.

### Team-colored items

- [ ] **W3-PH3-015** — Prototype `SetItemColor` for ownership or faction communication, not rarity coloring; it accepts a `playercolor`, not arbitrary RGB.
- [ ] **W3-PH3-016** — Test ground, bag, equipment, native 3D display, transfer, and neutral ownership behavior.
- [ ] **W3-PH3-017** — Do not enable globally unless the visual language is understandable in the supported SD/Classic presentation.

## W3-HL-COMBAT — Phase 4 - Ability cooldowns, aura state, and attack resets

### Cooldown API

Target natives:

- `BlzGetUnitAbilityCooldownPercent`
- `BlzSetUnitAbilityCooldownRemaining`
- `BlzSetUnitAbilityCooldownPercent`
- `BlzAdjustUnitAbilityCooldownRemaining`
- `BlzAdjustUnitAbilityCooldownPercent`

Implementation work:

- [ ] **W3-PH4-001** — Build a semantics test for positive/negative adjustment, values outside 0-100%, abilities not cooling down, charge-based abilities, transformed units, and ability level changes.
- [ ] **W3-PH4-002** — Refactor `Abilities/Shaman/ShamanCommon.j` so talent cooldown reduction adjusts the active cooldown instead of restarting it through `BlzStartUnitAbilityCooldown`.
- [ ] **W3-PH4-003** — Update `ShamanAncestralWard.j` to set remaining cooldown explicitly where its scripted cast requires a fixed value.
- [ ] **W3-PH4-004** — Review `ShamanSummonElemental.j` cooldown gating and all future talent effects against the shared helper.
- [ ] **W3-PH4-005** — Add focused tests proving repeated callbacks cannot apply the same reduction more than once.
- [ ] **W3-PH4-006** — Keep UI cooldown display consistent with the actual engine cooldown.

### Aura toggling

- [ ] **W3-PH4-007** — Test `BlzUnitEnableAuras(unit, enable, affectsUI)` with learned auras, item auras, hidden spellbook auras, totems, dead units, morphs, and illusions.
- [ ] **W3-PH4-008** — Use it only for states that intentionally suppress every aura on a unit, such as controlled transitions or special encounter states.
- [ ] **W3-PH4-009** — Do not replace the targeted buff cleanup in `ResourceEnergy` or `ResourceRage`; removing received mana-regeneration buffs is not equivalent to disabling all aura abilities emitted by that unit.
- [ ] **W3-PH4-010** — Verify that UI state restoration is exact after nested disable/enable requests.

### Attack cooldown reset

- [ ] **W3-PH4-011** — Test `BlzResetUnitAttack(unit, weaponIndex)` with weapon indices 0 and 1, melee/ranged heroes, attack-speed bonuses, and interrupted attacks.
- [ ] **W3-PH4-012** — Adopt only for an explicitly designed "immediate next swing" mechanic. Do not replace generic `IssueImmediateOrder(..., "stop")` calls.
- [ ] **W3-PH4-013** — Consider `ShamanStormstrike` or a future windfury-style proc only after combat design approves the behavioral change.

## W3-HL-CAMERA — Phase 5 - Camera, input, and minimap

### CameraControl

- [x] **W3-PH5-001** — Camera ownership diagnostics remain behind developer commands. Bounded middle-drag mouse-look is production input enabled by default, remains idle without local input, and can still be disabled through the existing API/debug override.
- [x] **W3-PH5-002** — Add the non-mutating camera/input baseline command used for supporting evidence and ownership experiments; it is not required to activate production mouse-look.
- [ ] **W3-PH5-003** — Prototype `BlzCameraSetCameraType`/`BlzCameraGetCameraType` and document valid integer camera types. The guarded `0`–`16` probe and reset are implemented; visual meanings require client testing. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH5-004** — Added a disabled local `SetCameraFieldControlledByInput` ownership probe for distance, far Z, angle, field of view, and rotation. It snapshots every engine flag, gives PotS exclusive ownership while enabled, reapplies after mode/type changes, and restores the exact snapshot on reset; mode-matrix behavior remains a manual test.
- [ ] **W3-PH5-005** — Evaluate `CAMERA_FIELD_ZABSOLUTE`, depth-of-field distance, and depth-of-field scale for cinematic presets only. _(Status: DEFERRED OPTIONAL EXPERIMENT; not required before P2; Updated: 2026-09-17)_
- [ ] **W3-PH5-006** — Evaluate `EnableCameraBlocker` and `AddCameraBlocker` for authored zone restrictions instead of repeated corrective camera movement. _(Status: DEFERRED UNTIL AN AUTHORED ZONE NEED EXISTS; not required before P2; Updated: 2026-09-17)_
- [x] **W3-PH5-007** — Existing `CameraControl_Suspend*`, resume state, `DialogCamera`, death camera, travel camera, and DynamicMinimap source contracts were retained; the validation matrix remains open for in-client equivalence.

### Input and coordinate APIs

- [x] **W3-PH5-008** — `BlzIsMouseButtonPressed` now drives mouse-look directly from the existing always-running local camera tick. The implementation no longer depends on a mouse-down event to start a second timer. `BlzIsKeyPressed` and `BlzIsMetaKeyPressed` remain optional because the adopted gesture requires no modifier. _(Status: IMPLEMENTED FOR ADOPTED INPUT; Updated: 2026-09-17)_
- [x] **W3-PH5-009** — `BlzGetMouseScreenPosX/Y` plus `BlzPixelToFrameX/Y` now establish the local press anchor and resolution-aware held-drag deltas. Cursor bounds, dead zone, and per-tick clamps remain in the production path. _(Status: IMPLEMENTED; Updated: 2026-09-17)_
- [x] **W3-PH5-010** — Local input and camera results remain local presentation state and are not written into synchronized gameplay state.
- [ ] **W3-PH5-011** — Replace `CameraControl`'s hidden item pathing probe with `BlzIsTerrainPathableEx` only if it matches the current collision behavior around items, cliffs, destructibles, water, and narrow passages. _(Status: CONDITIONAL EQUIVALENCE TEST; legacy path retained; not required before P2; Updated: 2026-09-17)_

### WoW-style mouse-drag free camera

The 3.0 input queries make a resolution-aware local mouse-drag camera practical without deriving movement from terrain mouse coordinates or synchronizing camera state between players.

Verified declarations in the active 3.0.0.24268 `common.j`:

| Native | Exact signature | Intended camera use |
| --- | --- | --- |
| `BlzIsMouseButtonPressed` | `takes mousebuttontype mouseButtonType returns boolean` | Poll whether the configured drag button remains held. |
| `BlzGetMouseScreenPosX` | `takes nothing returns integer` | Read the local cursor's horizontal screen-pixel position. |
| `BlzGetMouseScreenPosY` | `takes nothing returns integer` | Read the local cursor's vertical screen-pixel position. |
| `BlzPixelToFrameX` | `takes integer pixelX returns real` | Convert horizontal cursor coordinates/deltas to frame space. |
| `BlzPixelToFrameY` | `takes integer pixelY returns real` | Convert vertical cursor coordinates/deltas to frame space. |
| `BlzGetLocalClientWidth/Height` | `takes nothing returns integer` | Detect client bounds, resolution changes, and edge proximity. |
| `BlzIsLocalClientActive` | `takes nothing returns boolean` | Cancel or pause dragging when the local client loses focus. |
| `BlzSetMousePos` | `takes integer x, integer y returns nothing` | Optional later cursor recentering for an unbounded drag. |
| `BlzEnableCursor` | `takes boolean enable returns nothing` | Optional cursor hiding while captured; always restore it on exit. |

Initial behavior decision:

- [x] **W3-PH5-012** — Implemented production bounded mouse-look around `CameraControl`'s current target: horizontal drag updates rotation and vertical drag updates angle through the existing stored-state application path.
- [x] **W3-PH5-013** — Middle mouse is the production-safe drag button because it does not conflict with Warcraft smart orders. Movement beyond the dead zone rotates the camera, while a short click preserves the existing reset behavior.
- [ ] **W3-PH5-014** — Keep right-drag as an optional experiment only. Warcraft III uses right-click for smart orders, so it must not become the default unless testing proves that dragging can avoid accidental unit orders and ground commands. _(Status: DEFERRED; bounded middle-drag is the adopted production-safe input; not required before P2; Updated: 2026-09-17)_
- [ ] **W3-PH5-015** — Compare this custom orbit behavior with valid `BlzCameraSetCameraType` values before deciding whether PotS should implement every free-camera field itself. _(Status: READY FOR MANUAL TEST; no further repository implementation required; Updated: 2026-09-17)_
- [ ] **W3-PH5-016** — Prototype `CAMERA_FIELD_ROTATION`/`CAMERA_FIELD_ANGLE_OF_ATTACK` first, then compare `CAMERA_FIELD_LOCAL_YAW`/`CAMERA_FIELD_LOCAL_PITCH` only where the selected camera type gives useful free-look behavior. _(Status: ROTATION/ANGLE IMPLEMENTED; LOCAL YAW/PITCH DEFERRED; not required before P2; Updated: 2026-09-17)_

Local drag loop:

1. During the existing 0.03-second camera tick, detect the local middle-button transition from released to held through `BlzIsMouseButtonPressed`, then store the converted frame X/Y anchor and clear accumulated drag distance.
2. While held, read the new screen position only for the local active client; no mouse event is required to start sampling.
3. Calculate resolution-aware deltas as the difference between successive `BlzPixelToFrameX/Y` results. Verify the Y-axis sign experimentally rather than assuming pixel and frame origins match.
4. Apply sensitivity, dead-zone, and maximum-per-tick clamps so focus changes, cursor warps, or a stalled frame cannot cause a camera jump.
5. Write through `CC_Rotation` and `CC_Angle` plus the existing camera-application path. Do not set camera fields behind `CameraControl`'s stored state, or its drift correction, resume logic, and DynamicMinimap safety rotation will fight the drag.
6. Mark rotation input grace for DynamicMinimap in the same way as keyboard rotation.
7. On release, focus loss, camera suspension, mode change, cinematic start, death camera, travel camera, or fullscreen UI takeover, clear the drag state.
8. If total movement remained below the dead zone, execute the existing middle-click camera reset; otherwise consume the gesture only as a camera drag.

Local/multiplayer safety requirements:

- [x] **W3-PH5-017** — Button state, cursor/frame coordinates, drag anchors, accumulated deltas, and resulting camera fields are stored and applied only for the local player.
- [x] **W3-PH5-018** — Drag values never move/order units, select gameplay targets, choose random results, or branch around synchronized handle operations.
- [x] **W3-PH5-019** — Ordinary drag samples are not synchronized or transmitted.
- [ ] **W3-PH5-020** — Camera calls are locally guarded; confirm two simultaneous independent drags and synchronized gameplay stability. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH5-021** — Source-specific blockers suppress drag for FullscreenUI, the centralized Game menu and child panels, inventory, equipment, crafting, shops, quest journal, talents, ability trainers, and gamble offers; existing camera suspension suppresses dialog, death, travel, and cinematic modes. No active edit-box/text-entry frame was found.

Cursor policy:

- [x] **W3-PH5-022** — The adopted mouse-look is bounded, leaves the cursor visible, and never calls `BlzSetMousePos` or `BlzEnableCursor`.
- [ ] **W3-PH5-023** — Evaluate an optional captured mode that hides and recenters the cursor only after bounded dragging is stable. _(Status: DEFERRED; bounded visible-cursor policy retained; not required before P2; Updated: 2026-09-17)_
- [ ] **W3-PH5-024** — If recentering is adopted, warp to the local client center before the cursor reaches an edge, ignore the synthetic post-warp delta, and restore the cursor on every exit path. _(Status: DEFERRED WITH `W3-PH5-023`; not required before P2; Updated: 2026-09-17)_
- [x] **W3-PH5-025** — Drag state cancels when `BlzIsLocalClientActive()` is false; bounded mouse-look never hides the cursor.

Prototype and regression matrix:

- [ ] **W3-PH5-026** — Test 16:9, 16:10, 21:9, and 4:3 aspect ratios where available, plus windowed/fullscreen modes and Windows DPI scaling.
- [ ] **W3-PH5-027** — Verify frame-space sensitivity is comparable across resolutions and UI scales.
- [ ] **W3-PH5-028** — Test press without movement, small jitter, fast flicks, edge contact, focus loss, Alt-Tab, and release outside the client.
- [ ] **W3-PH5-029** — Confirm middle click still restores stored camera fields and middle drag changes rotation/angle without resetting; no right-drag mode is implemented because it would conflict with smart orders. CameraControl 1.6.0 removes the failed event-start dependency and enables direct polling by default. _(Status: READY FOR PLAY TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH5-030** — Test over terrain, units, minimap, command card, inventory, equipment, shops, dialogue, quest UI, and fullscreen custom frames. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH5-031** — Test Normal, Advanced, Developer, special-zone, dialog, death, travel, and fullscreen cinematic camera transitions. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH5-032** — Verify suspend/resume restores the pre-interruption camera state exactly and never leaves camera fields controlled by the wrong owner. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH5-033** — Run a two-player test with deliberately different simultaneous drags and confirm no desync or cross-player camera movement. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH5-034** — Mouse-look reuses the existing always-running 0.03-second drift/camera-maintenance timer, performs one local button query per client tick, and does not keep the separate keyboard-input timer active. This removes the mouse-event/timer-start dead path without adding another timer.

### W3-HL-MINIMAP — Dynamic minimap

- [x] **W3-PH5-035** — Enabled World Editor's "generate dynamically within camera bounds" option in the PotS map. The option is the native terrain-generation mechanism; build 24268 exposes no separate script call that regenerates it on demand. _(Completed by: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH5-036** — Compared native generation against the imported chunks in the full map. Native generation showed terrain/destructibles but lacked the authored detail of the custom minimap art, so it is rejected as the PotS production presentation. _(Result: IMPORTED CHUNKS WIN ON VISUAL QUALITY; Reported by: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH5-037** — Determined that native generation cannot eliminate the imported chunk textures without a visible quality loss. The minimized/chunked minimap continues using the existing safe camera-bounds transaction. _(Status: CLOSED — KEEP IMPORTED CHUNKS; Updated: 2026-09-17)_
- [x] **W3-PH5-038** — Retained imported/native terrain sources and chunked/full-map modes behind reversible APIs and local debug commands. Imported terrain is the accepted production source; native mode remains diagnostic only.
- [x] **W3-PH5-039** — Retired the conditional native-wins cleanup. Imported textures and their conversion workflow remain required PotS assets. _(Status: NOT APPLICABLE — NATIVE ROUTE REJECTED; Updated: 2026-09-17)_
- [x] **W3-PH5-040** — Replaced duplicated minimap map-world and camera-world constants with runtime values from `bj_mapInitialPlayableArea` and `GetCameraMargin`. The generated full-map script independently confirms terrain bounds X `-29184..32256`, Y `-32256..29184`; authored camera limits remain those bounds reduced by the engine margins. _(Status: IMPLEMENTED; runtime reimport check pending; Updated: 2026-09-17)_
- [ ] **W3-PH5-041** — Recapture the World Editor `View Entire Map` source at the exact full map extent, with no extra border and no missing terrain, before resizing or chunking. Archive the uncropped source and document every crop/resize dimension. _(Status: MANUAL WORLD EDITOR/ART STEP; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH5-042** — Regenerate the imported full-map and chunk textures from the verified source, then calibrate `MINIMAP_ART_OFFSET_X/Y` and test edge/corner alignment, adjacent chunk seams, camera limits, icons, and pings in minimized and enlarged layouts. _(Status: DEPENDS ON `W3-PH5-040` AND `W3-PH5-041`; Updated: 2026-09-17)_

## W3-HL-FOG — Phase 6 - Fog, lighting, and weather

### FogSystem state model

Extend `EnvironmentSystems/FogSystem.j` and zone data from the current start/end/RGB model to a complete preset:

- Fog style (`FOG_STYLE_LINEAR`, `EXP`, `EXP2`, `HEIGHT`, `NEW_EXP`, `NEW_EXP_2`)
- Z start and end
- Density
- Height start and end
- Linear start and end
- Maximum linear density/opacity
- Draw over sky
- RGB color

Tasks:

- [ ] **W3-PH6-001** — Make fog-state parity the second visual-first workstream. Capture the effective legacy values for representative outdoor, dungeon, storm, death/cinematic, and split-party states before adding fields. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH6-002** — Expose current/target values, fade state, and override depth through read-only `FogSystem` getters and `/debug wc3 fog`; the representative-state capture itself remains pending.
- [x] **W3-PH6-003** — Added explicit per-player current/target arrays with copy, apply, numeric interpolation, discrete-style switching, and complete override restoration.
- [x] **W3-PH6-004** — Preserved the legacy `AddFogForPlayer` signature and exact linear defaults, so `ZoneEvent` and existing zone configuration require no data migration and retain current visuals by default.
- [x] **W3-PH6-005** — `Stormv2.j` lightning flashes now preserve and restore legacy/extended mode, style, height, linear range, maximum density, draw-over-sky, Z range, density, and RGB.
- [ ] **W3-PH6-006** — Reconcile `WeatherSystemV4`, `DNC`, fullscreen UI fog overrides, dungeon transitions, and per-selected-hero zone presentation. Active source audit found zone fog routed through `FogSystem` and no competing active 3.0 setter, but transitions require full-map testing. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH6-007** — Test which fog setters are safe as local visual calls and document the multiplayer rule. All setters are locally guarded in code; two-client behavior remains to be established. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH6-008** — Author representative linear, height, dungeon, snow, rain, and storm presets in the World Editor with live preview. The first height-fog probe looked good and remains a candidate. The `NEW_EXP` probe at density `0.0015` visually removed the fog and is rejected; the harness refuses to reapply it until a separately reviewed visible preset is authored in World Editor. _(Status: HEIGHT CANDIDATE; CURRENT NEW_EXP PRESET DISABLED; Updated: 2026-09-17)_

### Excluded HD water

Do not add an `HDWater` controller or adopt the `BlzSetHDWater*`/`SetHDWaterParamsEx` APIs. PotS is SD-only, so this would add code and testing burden for an unsupported presentation mode. Continue using the current terrain-water, weather, and rain-ripple behavior.

### W3-HL-LIGHTING — Lighting and post processing

- [ ] **W3-PH6-009** — Use SD-compatible lighting controls to establish baseline day, night, dungeon, storm, and special-area profiles.
- [ ] **W3-PH6-010** — Replace suitable decorative emissive effects with editable omni lights where this reduces model/effect overhead.
- [ ] **W3-PH6-011** — Test shadow-casting omni lights against `DoodadRender` and graphics quality settings.
- [ ] **W3-PH6-012** — Use `BlzSetMinShadowCastingPointLightCount` only through a graphics preset; benchmark GPU cost before raising it.
- [ ] **W3-PH6-013** — Create map-level post-processing presets only if they affect the supported SD presentation, and verify readability of PotS UI, fog, terrain water, and cinematics.
- [ ] **W3-PH6-014** — Document all manual values so the World Editor remains the source of truth.

## W3-HL-DOODADS — Phase 7 - Doodads, destructibles, decals, and shadows

### DoodadRender modernization

Target natives include `BlzGetNumDoodads`, doodad index getters, and `BlzSetSingleDoodadAnimation`.

- [ ] **W3-PH7-001** — Keep the first doodad pass observational and resettable: count/enumerate without taking ownership, record initialization cost, and modify only one known test instance through the full-map debug harness. Batched scan and guarded hide/show probe are implemented. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH7-002** — Add the first observational step: `/debug wc3 doodads` reports `BlzGetNumDoodads()` without enumerating or mutating instances.
- [x] **W3-PH7-003** — The first pass does not replace `DoodadRender`; the probe rejects its managed rawcodes and the batched scan remains explicit and read-only.
- [ ] **W3-PH7-004** — Test whether doodad indices are stable across clients, map saves, variations, and editor rebuilds. Count plus rawcode/position fingerprints are implemented for comparison. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH7-005** — Added a lazy runtime spatial index from the 3.0 doodad index, X/Y, and rawcode natives. Hashtable-backed type/cell lists avoid JASS array-capacity dependence; build time, source count, and managed-instance count are exposed for the full-map benchmark.
- [ ] **W3-PH7-006** — Compare the indexed `BlzSetSingleDoodadAnimation` backend against legacy `SetDoodadAnimationRect` for initialization cost, native-call count, transition stutter, correctness, and steady FPS on the current approximately 50,000 placements. An initial full-map check found no meaningful reason to replace the original renderer; run the detailed matrix only if a concrete doodad-performance problem justifies reopening it. _(Status: DEFERRED — NO OBSERVED BENEFIT; Updated: 2026-09-17)_
- [x] **W3-PH7-007** — Both renderer backends reuse `DoodadManager` per-type distances and preserve enable/disable, refresh, cinematic suspension depth, and full-show restoration contracts. The legacy area backend remains the default.
- [x] **W3-PH7-008** — The guarded test mutation uses `BlzSetSingleDoodadAnimation` for one reviewed index, so nearby same-type doodads are not intentionally included; runtime confirmation remains in `W3-VAL-007`.
- [x] **W3-PH7-009** — Retain the generated `war3map.doo` reference workflow and legacy area backend. The initial runtime check did not show a meaningful reason to replace it; the indexed implementation remains an optional diagnostic prototype. _(Status: LEGACY AREA BACKEND ACCEPTED; Updated: 2026-09-17)_
- [x] **W3-PH7-015** — Added synchronized debug controls for area/indexed backend selection, enable/disable, refresh, status, and diagnostic reset. No indexed enumeration runs while the legacy default remains selected.
- [ ] **W3-PH7-016** — If doodad rendering performance becomes a measured problem, A/B test static Object Editor `dvis`/Art - Visibility Radius values on high-count small decorative rawcodes. Build 24268 exposes no runtime doodad-field API, so this is a per-type map-data experiment rather than a dynamic JASS feature; preserve landmarks and reject visible pop-in. _(Status: OPTIONAL STATIC AUTHORING TEST; Updated: 2026-09-17)_

### Rotation and local axes

- [ ] **W3-PH7-010** — Use World Editor pitch/roll and local-axis scaling for environmental art that currently needs pre-rotated models. Candidate recording and checks are defined in the validation log. _(Status: READY FOR AUTHORING; Owner: Valdemar; Updated: 2026-09-17)_
- [x] **W3-PH7-011** — Reviewed active procedural destructible creation. The five sites are hidden blockers/platforms or currently level quest scenery; no safe non-zero pitch/roll migration is justified in this pass, and no active trap creation site was found.
- [x] **W3-PH7-012** — Excluded doodad and destructible team-color APIs from the PotS 3.0 upgrade. No color probe, authored-color migration, or runtime color ownership will be added. _(Status: EXCLUDED BY DESIGN; Updated: 2026-09-17)_
- [ ] **W3-PH7-013** — Confirm orientation survives death, revival, replacement, hiding, and save/load-equivalent recreation. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17; Depends on: `W3-PH7-010`)_
- [ ] **W3-PH7-014** — Verify pathing and selection remain aligned with rotated visuals. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17; Depends on: `W3-PH7-010`)_

### Excluded HD-only authoring features

Do not schedule HD water doodads, HD decals, HD shadow blockers, or per-doodad HD-shadow work while PotS remains SD-only. The light-range visualization and editable lights may still be used only where they demonstrably affect and improve the supported SD presentation.

## Phase 8 - Special effects, HUD, sound, and editor workflow

### W3-HL-EFFECTS — SpeciFX

- [x] **W3-PH8-001** — Added direct-effect and managed-tag named-animation APIs using `BlzSetSpecialEffectAnimation` and `BlzQueueSpecialEffectAnimation`; blank names and null effects are ignored safely.
- [x] **W3-PH8-002** — Added direct-effect and managed-tag blend-time APIs using `BlzSetSpecialEffectAnimationBlendTime`; negative input is normalized to zero.
- [x] **W3-PH8-003** — Existing `animtype` support through `BlzPlaySpecialEffect` remains unchanged in `SpeciFX_ConfigureEffect`; the P2 harness includes a legacy attack-animation comparison.
- [ ] **W3-PH8-004** — Test queued animation cleanup, invalid animation names, time scale, looping models, and effect destruction. The basic single-client named-animation, queue, blend, legacy, and cleanup probes worked; invalid-name, 100-cycle endurance, model-variety, and two-client checks remain. _(Status: BASIC PROBE PASSED; EXTENDED MATRIX PENDING; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-PH8-005** — Migrate only effects that currently require recreation or timers solely to sequence animations. _(Status: CONDITIONAL; no production effect call site is migrated in the first P2 slice; Updated: 2026-09-17)_

### W3-HL-HUD — Orc HUD compatibility and hero presentation

- [ ] **W3-PH8-006** — Keep the current Orc/default HUD identity fixed; do not expose Human/Forsaken HUD selection or make HUD skin a per-player gameplay option.
- [ ] **W3-PH8-007** — Confirm Warcraft III 3.0 does not change the expected origin-frame names, sizes, or anchors used by `Interface`, `MasterUI`, `FullscreenUI`, `UIChanges`, quest UI, stats UI, abilities UI, shops, and inventory/equipment.
- [ ] **W3-PH8-008** — Use `SetPlayerRaceSkin` only if a narrowly scoped compatibility fix is required to preserve the Orc HUD, and validate the call before custom UI frame discovery.
- [ ] **W3-PH8-009** — Evaluate `UNIT_BF_FORCE_DISPLAY_HP` for invulnerable buildings that should retain visible health; make the actual object-data choice manually in World Editor.

### W3-HL-SOUND — Sound variables

- [ ] **W3-PH8-010** — Use the editable sound-variable path feature to repair paths without recreating GUI sound variables.
- [ ] **W3-PH8-011** — Re-export or refresh `SoundAndMusic/SoundEditorSounds.json` and `ExSoundEditorSounds.j` after approved changes.
- [ ] **W3-PH8-012** — Confirm `ExSound` path lookup, labels, 3D settings, durations, and imported-file registration remain correct.

### W3-HL-WORKFLOW — Trigger-authoring workflow

- [ ] **W3-PH8-013** — Use Copy As Script to capture remaining GUI behavior before converting it into maintained PotS libraries.
- [ ] **W3-PH8-014** — Use the new GUI leak-cleaning actions for GUI triggers that will remain GUI.
- [ ] **W3-PH8-015** — Do not accept automatic Lua conversion as a final PotS implementation.
- [ ] **W3-PH8-016** — Increase the editor undo-stack limit after measuring memory use on the full map.
- [ ] **W3-PH8-017** — Use the string-ID adjustment tool only with a saved backup and a before/after reference audit.

## W3-HL-ROLLOUT — Phase 9 - Rollout order

These IDs are rollout milestones. Close a milestone only when its underlying implementation tasks and applicable `W3-VAL-*` gates are complete.

- [ ] **W3-PH9-001** — Add the disabled full-map 3.0 harness to the existing `/debug` workflow and record baseline semantics without changing production behavior.
- [ ] **W3-PH9-002** — Validate the adopted direct-polling middle-drag mouse-look across every camera mode, UI blocker, suspension path, resolution, and two-client session; retain its runtime disable API as rollback.
- [ ] **W3-PH9-003** — Extend the fog state model with exact legacy-default parity, then enable one reviewed 3.0 fog preset at a time.
- [ ] **W3-PH9-004** — Apply small World Editor pitch/roll and local-axis improvements, run read-only doodad enumeration, and test one resettable instance-level animation probe.
- [ ] **W3-PH9-005** — Benchmark the visual-first changes in long sessions and two-player tests before changing their production defaults.
- [ ] **W3-PH9-006** — Evaluate dynamic minimap generation only after camera ownership is stable; keep the current minimap implementation as the default and rollback path.
- [ ] **W3-PH9-007** — Modernize global doodad handling only if read-only enumeration and approximately 50,000-placement benchmarks beat the current implementation.
- [ ] **W3-PH9-008** — Extend SpeciFX and cooldown helpers as separate workstreams.
- [ ] **W3-PH9-009** — As the final P4 migration only, implement the native-style aggregate `DEquipment` bonus layer and append-only 3.0 stat registry behind mutually exclusive per-stat rollback flags. _(Status: DEFERRED; Depends on: approved `W3-PH0-043` migration gate and completion of lower-priority adopted workstreams; Updated: 2026-09-17)_
- [ ] **W3-PH9-010** — As the final P4 migration only, add ItemManager schema/UI/W3T support and backfill only a small reviewed equipment/tag test set. _(Status: DEFERRED; Depends on: `W3-PH9-009`; Updated: 2026-09-17)_
- [ ] **W3-PH9-011** — As the final P4 migration only, implement the native inventory bridge and item-consumer integration after equipment-bonus semantics, database round trips, and the Forsaken data-version regression pass are stable. _(Status: DEFERRED; Depends on: `W3-PH9-010`; Updated: 2026-09-17)_
- [ ] **W3-PH9-012** — Enable every feature independently, with one changelog entry and rollback path per workstream.

## W3-HL-VALIDATION — Validation gates

### Compilation

- [x] **W3-VAL-001** — Full map compiles through the normal World Editor/JassHelper workflow with the harness present but disabled. The imported runtime build started and the read-only self-test reported `7/7`. CameraControl 1.6.0, harness 0.7.0, and DynamicMinimap 1.7.0 were added afterward and still require an incremental compile/start smoke check. _(Status: INITIAL SINGLE-CLIENT FULL-MAP GATE PASSED; Reported by: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-VAL-002** — Full map compiles and starts with the selected experimental path enabled; activating its suite is not required for an ordinary smoke session.
- [ ] **W3-VAL-003** — No archived Blizzard script is accidentally used by JassHelper or editor tooling.

### Visual-first upgrades

- [ ] **W3-VAL-004** — With experimental probes disabled and mouse-look idle, camera, fog, doodad behavior, initialization time, and normal gameplay match the pre-upgrade baseline. Then exercise the enabled middle drag separately. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17; Depends on: `W3-VAL-001`)_
- [ ] **W3-VAL-005** — Camera input remains local presentation state, middle-click reset still works, every cinematic/dialog/death/travel suspension restores correctly, and simultaneous two-player camera use produces no desync or cross-player movement.
- [ ] **W3-VAL-006** — Fog defaults remain visually identical until a reviewed preset is explicitly assigned; storm flashes and every override restore all old and new fields exactly. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-VAL-007** — Initial doodad enumeration is read-only, the test-instance mutation has a reliable reset, pathing and selection remain unchanged, and no global `DoodadRender` replacement occurs without a favorable full-map performance comparison. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-VAL-008** — Camera, fog, and doodad changes can be disabled independently so troubleshooting one workstream never requires reverting the other two.

### Inventory and equipment

- [ ] **W3-VAL-009** — No item duplication, disappearance, handle reuse, or zero-charge resurrection.
- [ ] **W3-VAL-010** — Stats and set bonuses apply exactly once and are removed exactly once.
- [ ] **W3-VAL-011** — Native Strength, Agility, Intelligence, damage, and armor show equipment increases in green and decreases in red without converting those changes into permanent/base values.
- [ ] **W3-VAL-012** — Level gains, tomes, scripted permanent rewards, morphs, and respecs modify only the base layer; equipment remains an independently removable bonus layer.
- [ ] **W3-VAL-013** — Repeated equip/unequip, item mutation, set activation, death/revive, and load cycles produce no base-stat drift or `+-value` character-sheet text.
- [ ] **W3-VAL-014** — Native-equipped item abilities and PotS aggregate bonus carriers never double-apply the same stat.
- [ ] **W3-VAL-015** — Two-handed/offhand and dual-wield restrictions remain correct.
- [ ] **W3-VAL-016** — Quest items, profession ingredients, shops, loot, death loss, revival restoration, and cleanup see the correct storage categories.
- [ ] **W3-VAL-017** — Directly used consumables support all target modes and share cooldowns correctly.
- [ ] **W3-VAL-018** — Native and PotS UI stay synchronized after every operation.
- [ ] **W3-VAL-019** — Existing stat IDs, item definitions, tooltips, generated abilities, and effective values remain unchanged unless an item is explicitly migrated to a reviewed 3.0 stat.
- [ ] **W3-VAL-020** — Ability Vamp cannot double-heal with Lifesteal; Magic Resistance cannot double-apply with Spell Damage Taken; Ability Amp cannot silently duplicate Spell Power.
- [ ] **W3-VAL-021** — Every adopted 3.0 stat has a verified runtime source, formula, scale, cap, stacking rule, lifecycle result, and synchronized two-client result.
- [ ] **W3-VAL-022** — `StatsUI` exposes every adopted combat stat through a readable category/page layout without truncating the current 39-stat view, while DEquipment remains bounded and readable with a worst-case set of nonzero bonuses.

### Multiplayer and local presentation

- [ ] **W3-VAL-023** — Equip, unequip, item use, random selection, fog, camera, and UI tests run with at least two players.
- [ ] **W3-VAL-024** — Local camera/input/HUD calls do not create synchronized state divergence. _(Status: READY FOR TEST; Owner: Valdemar; Updated: 2026-09-17)_
- [ ] **W3-VAL-025** — Selected heroes may occupy different zones without applying another player's fog or camera state.

### Performance and visual modes

- [ ] **W3-VAL-026** — Compare long-session FPS and memory before/after doodad, minimap, SD-compatible lighting, and post-processing changes.
- [ ] **W3-VAL-027** — Verify the supported SD/Classic presentation at low and high graphics settings.
- [ ] **W3-VAL-028** — Verify all new SD-compatible model, texture, sound, and light assets resolve without editor-log warnings.

### API, Object Editor, and Game Data Version compatibility

- [ ] **W3-VAL-029** — The production PotS Game Data Version remains `The Frozen Throne` unless a separately reviewed disposable-copy migration, complete object/map-data diff, save/reopen cycle, full-map regression, and explicit approval accept the switch to `Forsaken Kingdom`.
- [ ] **W3-VAL-030** — Every adopted 3.0 stat carrier is a PotS-owned custom object with a recorded parent, rawcode, fields, source Game Data Version, runtime formula, stacking behavior, and removal behavior; no implementation assumes a nonexistent stat native.
- [ ] **W3-VAL-031** — A map containing each adopted carrier opens, saves, reloads, compiles, and runs in SD/Classic without unknown-field warnings, missing assets, changed unrelated objects, or a Forsaken campaign-map dependency.

## Completion criteria

This plan is complete when each adopted workstream has documented runtime semantics, full-map harness and normal full-map compile/runtime results, multiplayer validation where relevant, an explicit rollback route, updated developer documentation, and a current-date changelog entry. Features that fail parity or safety testing should remain documented prototypes rather than production dependencies.
