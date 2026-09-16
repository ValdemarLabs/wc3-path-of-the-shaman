# Warcraft III 3.0 Systems Upgrade Plan

Status: Proposed  
Target baseline: Warcraft III 3.0.0, build 24268  
Primary API references: [`_Blizzard/common.j`](../../_Blizzard/common.j) and [`_Blizzard/blizzard.j`](../../_Blizzard/blizzard.j)  
Patch reference: [Warcraft III: Reforged - Forsaken Kingdom Patch Notes](https://us.forums.blizzard.com/en/warcraft3/t/warcraft-iii-reforged-forsaken-kingdom-patch-notes/38400)

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
- Do not convert the project to Lua. Use the new GUI-to-Lua and Copy As Script tools only for investigation; converted PotS triggers should continue to target maintained JASS/vJASS libraries.
- Treat Object Editor, terrain, placed-object, minimap-paint, lighting, water, fog, sound-variable, and post-processing edits as manual World Editor work.
- Use the exact native spellings from the 3.0 scripts, including `UnitHasAnyItemEquiped` and the `envMapStrengthy` parameter typo where applicable.

## Priority overview

| Priority | Capability | PotS targets | Expected value |
| --- | --- | --- | --- |
| P0 | Equipment classification, equipment type, item tag, extended bag, equip events, native-colored bonus stats | `WC3ItemManager`, `DInventory`, `DEquipment`, `SharedDInvLib`, `ItemHook`, `UnitStats` | Very high |
| P0 | Remaining/percentage ability cooldown control | `ShamanCommon`, talent-driven cooldowns | High |
| P1 | Expanded fog controls | `FogSystem`, `Storm`, `WeatherSystemV4`, zones | High |
| P1 | Doodad enumeration, instance animation, rotation, and color | `DoodadManager`, `DoodadRender`, procedural destructibles | High |
| P1 | Free-camera ownership and input queries | `CameraControl`, `DialogCamera`, `DynamicMinimap` | High |
| P1 | Dynamic minimap generation within camera bounds | `DynamicMinimap` | Potentially very high |
| P2 | Special-effect animation queue and blend control | `SpeciFX`, ability visuals | Medium |
| P2 | Item, doodad, and destructible team color | Loot ownership and environment presentation | Medium |
| P3 | Attack cooldown reset and global aura toggling | Selected combat/state transitions | Situational |
| P3 | Lighting editor, omni lights, decals, shadow blockers, post processing | Environment authoring | Visual/optimization work |

## Phase 0 - Full-map 3.0 validation harness

PotS integration tests must run in the complete map. A reduced map would omit the rects, zones, placed objects, generated Object Editor data, initialization order, custom frames, imports, and cross-system state that are most likely to expose failures. Use a disposable development copy of the full map rather than maintaining a parallel test environment.

### Harness structure

- [ ] Add a small coordinating `Debug/Warcraft300TestHarness.j` library and expose its entry points through the existing centralized `/debug` command dispatcher in `Debug/DebugCommands.j`.
- [ ] Keep the harness disabled by default and prevent automatic probes during normal map initialization. Tests must begin only through an explicit developer command and must not ship enabled in a release build.
- [ ] Divide probes into independently runnable suites such as equipment bonuses, native inventory, cooldowns, camera/input, minimap, environment, and doodads. Run one stateful suite at a time so failures are attributable.
- [ ] Reuse the real PotS heroes, existing stat-specific TEST items, Object Editor data, UI, zones, and systems. Add temporary test objects only where existing data cannot express a required positive, negative, or boundary case.
- [ ] Run position-dependent probes at the selected hero, current camera target, or a deliberately chosen existing development area. Do not add artificial rect duplicates merely to make a test self-contained.
- [ ] Give every mutating probe an explicit cleanup/reset command. Snapshot values before a test, remove temporary handles and abilities afterward, and report when a full map restart is required instead of pretending state was restored.
- [ ] Keep feature flags separate from the harness. A probe may enable one experimental implementation for the current test, but it must not silently change the production default or enable two competing stat/inventory paths together.
- [ ] Print concise before/after values and PASS/FAIL invariants in game, then record the exact editor/client build, map build, SD graphics settings, suite, player, and feature-flag state in the associated developer notes.
- [ ] Test host and second player, full map reload, hero death/revival, morphing, item transfer, and item destruction where relevant.
- [ ] Separate synchronized gameplay state from local visual and camera calls. Camera/input probes must support two clients observing different local states without changing shared gameplay state.
- [ ] Verify behavior in the supported SD/Classic presentation at representative low and high settings where applicable.
- [ ] Do not merge a production migration based only on successful compilation or a single-player harness pass.

### Full-map test workflow

1. Make or restore a disposable copy of the current full map and confirm that its unmodified baseline loads, compiles, and starts normally.
2. Import the current source changes and the disabled harness, compile through the normal World Editor/JassHelper workflow, and run a smoke session with no test suite activated.
3. Enable exactly one experimental path and execute its `/debug` suite using controlled items/units. Save the output and compare it with the baseline.
4. Restart the map between tests that alter initialization state, Object Editor-derived state, terrain/environment state, or undocumented native state.
5. Repeat synchronization-sensitive suites with at least two players and different selected heroes/camera positions.
6. Disable the experiment and confirm the legacy path still works before changing the production default.

Separate executable or code-only tests remain appropriate for `WC3ItemManager`, SQL migrations, W3T import/export, binary assets, and other tooling whose correctness does not depend on the live map.

### Inventory probe matrix

- [ ] Determine which Object Editor unit ability or field enables the native extended bag and equipment panel.
- [ ] Reproduce the behavior of Garek's Backpack in the disposable full-map copy with a reviewed test item/unit and document all required object data.
- [ ] Confirm that `UnitExtendedInventorySize` reports actual capacity and whether capacity can vary by unit.
- [ ] Confirm bag slot indexing and bounds for `UnitItemInBagSlot`.
- [ ] Confirm `UnitEquipItem`, `UnitUnequipItem`, and `UnitUnequipItemFromSlot` ownership and failure behavior.
- [ ] Confirm `EVENT_PLAYER_UNIT_EQUIP_ITEM` and `EVENT_PLAYER_UNIT_UNEQUIP_ITEM` event order, `GetTriggerUnit`, `GetEquippedItem`, and `GetUnequippedItem`.
- [ ] Confirm whether `UnitUseItem`, `UnitUseItemPoint`, and `UnitUseItemTarget` work directly on bagged items.
- [ ] Confirm direct bag use fires `EVENT_PLAYER_UNIT_USE_ITEM`, consumes charges, observes cooldown groups, and destroys perishable zero-charge items normally.
- [ ] Confirm behavior when an item is transferred, pawned, dropped on death, removed with `RemoveItem`, or destroyed while equipped.
- [ ] Confirm the native 3D equipment character display works for both PotS heroes, alternate unit skins, morphs, hero glow settings, and local selection changes.
- [ ] Record how the native unit panel colors positive and negative Strength, Agility, Intelligence, damage, and armor changes from native equipped items: positive equipment deltas should be green and negative deltas red while the permanent value remains white.
- [ ] Compare actual native equipped-item abilities, hidden unit abilities, `SetHeroStr/Agi/Int`, `BlzSetUnitBaseDamage`, `BlzSetUnitArmor`, and the 3.0 `UNIT_IF_*`, `UNIT_IF_*_PERMANENT`, and `UNIT_IF_*_WITH_BONUS` fields. Determine which approaches change gameplay, which change the displayed base, and which produce a genuine colored bonus.
- [ ] Test whether writing `UNIT_IF_*_WITH_BONUS` is supported and persistent in 3.0.0.24268; declaration and a successful boolean return are insufficient without level-up, morph, save/load, and UI-refresh tests.

### Recommended first upgrade

After the minimal harness command and reset support exists, implement the `DEquipment` native-style bonus presentation described in Phase 2 as the first runtime upgrade. It is the best starting point because it fixes an existing base-versus-bonus correctness problem, has immediate visible value, can reuse the present PotS inventory and equipment authority, and can be compared against the legacy mutation path without first migrating item storage.

Suggested first vertical slice:

1. Add signed green/red formatting and base/bonus/total diagnostics without changing gameplay values.
2. Add a recomputation entry point for the aggregate equipment ledger and drift assertions for repeated equip/unequip cycles.
3. Prototype aggregate Strength, Agility, Intelligence, damage, and armor carriers on one hero using existing positive and negative TEST items.
4. Validate level-up, permanent rewards, morph, death/revival, load, set bonuses, and 100 equip/unequip cycles in the full-map harness.
5. Keep the existing permanent/base mutation implementation behind a mutually exclusive rollback flag until multiplayer and full-map regression tests pass.

Do not begin with the native extended bag/loadout bridge. That work changes item ownership, storage authority, events, UI, death/restoration, cleanup, quests, professions, AI, and shops simultaneously. Likewise, camera, minimap, lighting, and fog are valuable but are less suitable as the first upgrade because their validation is more subjective and more sensitive to local-player and graphics-setting behavior.

## Phase 1 - Extend WC3ItemManager and W3T round trips

### Data model

- [ ] Add `Equipment` to every `wc3_classification` selector and normalizer. It maps to Object Editor field `icla` and runtime `ITEM_TYPE_EQUIPMENT`.
- [ ] Add a dedicated `wc3_item_tag` column instead of overloading PotS item class, rarity, drop source, or notes.
- [ ] Support `Undefined`, `Droppable`, `Quest Reward`, `Boss Drop`, `Secret`, `Puzzle`, `World`, and `Shop`, matching `ITEMTAG_TYPE_*`.
- [ ] Add a dedicated `wc3_equipment_type` column for `None`, `Head`, `Chest`, `Gloves`, `Boots`, `Ring`, `Primary`, `Offhand`, and `Trinket`.
- [ ] Keep `equipment_slot` as the richer PotS `DEquipment` slot. Native equipment type and PotS equipment slot are related but not interchangeable.
- [ ] Add a numbered SQL migration after the current migration set, then update `database/schema.sql`, `database/schema_wc3_full_support.sql`, and configuration labels.
- [ ] Add database constraints or centralized normalization so UI, import, batch edit, and scripts use identical values.

### Item editor and batch editor

- [ ] Update `WC3ItemManager/ItemEditForm.cs` with Equipment classification, native equipment type, and item tag controls.
- [ ] Update `WC3ItemManager/BatchItemEditDialog.cs` with the same fields and mixed-value behavior.
- [ ] Update `WC3ItemManager/ConfigurationForm.cs` and the main item grid/filter configuration.
- [ ] Show a warning when `deq_compatible` is enabled but native classification/type is inconsistent.
- [ ] Add an explicit "native inventory compatible" preview rather than silently changing existing items.

### W3T import/export

- [ ] Update `core/wc3_w3t_exporter.py`, `core/wc3_w3t_importer.py`, `parsers/wc3_w3t_parser.py`, and the active v2 importer.
- [ ] Export/import `icla = Equipment` without falling back to Permanent or Miscellaneous.
- [ ] Export/import `itag` and preserve unknown values through `original_modifications`.
- [ ] Determine the native equipment-type Object Editor raw field by round-tripping a hand-authored 3.0 test item; do not guess it from the display name `equipment`.
- [ ] Update W3T coverage and diagnostic scripts to report the three native classification fields separately.
- [ ] Add byte-level golden tests for old and 3.0 W3T samples, including empty/default values.
- [ ] Verify that an old W3T can still be imported and re-exported without adding unintended 3.0 fields to every item.

### Backfill policy

Use an audit report before changing production rows. A Warcraft item can have only one native tag, while PotS loot metadata can describe several roles.

- [ ] Propose `Equipment` only for items already marked `deq_compatible`; do not apply automatically without review.
- [ ] Map exact PotS equipment slots to the closest native equipment type and list unsupported slots.
- [ ] Prefer explicit tags. Suggested inference priority is Secret/Puzzle, Quest Reward, Boss Drop, Shop, World, Droppable, then Undefined.
- [ ] Never replace PotS rarity, loot-tier, quest gating, or specific-drop metadata with the single native tag.
- [ ] Generate before/after SQL reports listing every inferred value and ambiguity.

## Phase 2 - Native inventory and DEquipment bridge

Create a small bridge library, tentatively `DestroyerInventoryAndEquipmentSystem/PoTs/DNativeInventoryBridge.j`, only after the probe matrix is complete.

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

- [ ] Choose one authoritative location for every item handle. Never mirror one handle into native and custom slots simultaneously.
- [ ] Route native equip/unequip events into existing `AddDEqStatsOfItemToUnit`, `RemoveDEqStatsOfItemFromUnit`, frame refresh, set bonus, and item-handle tracking paths.
- [ ] Add re-entrancy guards so a bridge-triggered native event cannot equip or unequip the same item twice.
- [ ] Preserve two-handed Primary/Offhand rules and PotS dual-wield abilities.
- [ ] Preserve item-set counts, named items, growth items, requirements, item score, and tooltip generation.
- [ ] Decide whether native slots are authoritative for the nine mapped positions or only a presentation layer. Do not support both modes concurrently in one release.
- [ ] Keep the PotS UI for unsupported slots and capacities above the native 30-slot limit.

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

- [ ] Preserve `EQIDDB[eqid][5]` as the authoritative aggregate equipment ledger, but stop using permanent/base setters as the normal equipment application path for native-displayable stats.
- [ ] Add a single refresh entry point that recomputes native-displayable equipment bonuses from the ledger after equip, unequip, swap, set activation/deactivation, rarity change, item-level change, named-item mutation, load, revive, and morph. Prefer recomputation over accumulating inverse deltas so repeated operations cannot drift.
- [ ] Prototype one aggregate hidden bonus ability per semantic group/unit rather than one ability per equipped item. Native-equipped item abilities and the aggregate PotS carrier must never apply the same bonus simultaneously.
- [ ] Test `Attribute Bonus` (`Aamk`) as the primary aggregate carrier for Strength, Agility, and Intelligence. The Ability Insight reference reports that it accepts negative bonuses and reacts to ability-level changes, but its behavior and native green/red presentation must be revalidated in Warcraft III 3.0.0.24268.
- [ ] Test `Item Damage Bonus` (`AIt*`, field `ABILITY_ILF_ATTACK_BONUS`) and `Item Armor Bonus` (`AId*`, field `ABILITY_ILF_DEFENSE_BONUS_IDEF`) as aggregate carriers. Confirm dynamic field updates, refresh requirements, negative coloring, stacking with actual native items, minimum-damage clamping, and behavior for both weapon indices.
- [ ] Do not choose `Item Hero Stat Bonus` (`AIs*`, `AIa*`, `AIi*`, `AIx*`) for a dynamic aggregate without a successful current-patch probe. The Ability Insight reference reports that changing its level or integer field does not apply the new value even when the field reads back correctly.
- [ ] Compare the ability-carrier approach with `BlzSetUnitIntegerField` on `UNIT_IF_STRENGTH_WITH_BONUS`, `UNIT_IF_AGILITY_WITH_BONUS`, and `UNIT_IF_INTELLIGENCE_WITH_BONUS`. Adopt direct field writes only if they produce correct native coloring and survive every lifecycle test without modifying the permanent fields.
- [ ] Treat `BlzSetUnitBaseDamage`, `BlzSetUnitArmor`, and `SetHeroStr/Agi/Int(..., true)` as base/permanent-authoring APIs, not equipment-bonus APIs, unless a narrowly scoped compatibility fallback is documented.
- [ ] Add explicit signed formatting helpers to `UpdateDEqCSheet`: positive totals use green with `+`, negative totals use red with `-`, and zero totals are omitted. Do not emit strings such as `+-5`.
- [ ] Keep percentage and flat values semantically separate. For example, do not collapse flat armor and armor percent into one displayed bonus unless the native panel's exact resulting delta can be reconciled with the custom sheet.
- [ ] Define how item-set bonuses participate. Native-displayable set bonuses should use the same aggregate carrier and color rules; custom-only set bonuses remain in the PotS character sheet.

Required lifecycle tests:

- [ ] Capture base, bonus, and total values before equipment; after each equip/unequip/swap; and after 100 repeated cycles. The final base and total must exactly match the initial state.
- [ ] Test positive, negative, fractional, and zero-crossing aggregates, including mixed items whose total changes from green to red.
- [ ] Test hero level-up, tome/stat reward, respec, morph, skin change, death/revive, load, ownership transfer, and equipment restoration while bonuses are active.
- [ ] Test primary-stat-derived damage separately from flat equipment Damage so the native damage panel does not double-count attribute growth.
- [ ] Test heroes with only weapon index 0, both weapon indices, disabled attacks, melee/ranged transformations, and dual-wield/two-handed transitions.
- [ ] Verify synchronized gameplay values on at least two clients. Coloring is presentation, but the abilities/fields producing the bonus affect synchronized combat state and must not be changed only inside `GetLocalPlayer` branches.
- [ ] Retain the current mutation path behind a temporary rollback flag until the aggregate bonus implementation passes its full-map harness suite and normal full-map regression tests; never enable both paths together.

### Direct consumable use

- [ ] If the probe succeeds, add one `DInventory` action that calls the appropriate `UnitUseItem*` native on the stored handle.
- [ ] Support immediate, point-target, unit-target, and destructible-target items without first moving them through the six quick slots.
- [ ] Refresh charge text, stack state, cooldown display, `ItemHook`, `UnitStats`, Resource Energy/Rage, cooking, and quest state after use.
- [ ] Define failure behavior when the target is invalid, the item is cooling down, or the hero cannot use the item.
- [ ] Keep the existing six-slot transfer route as a fallback until all target modes pass testing.

### Native 3D equipment presentation

- [ ] Determine whether the native character display can be opened or embedded without replacing PotS fullscreen frames.
- [ ] Test it after `Interface`, `FullscreenUI`, `MasterUI`, and `DEquipment` initialization.
- [ ] Verify portrait/model updates after morph, revive, skin change, equipment change, and hero selection.
- [ ] If the native display cannot coexist cleanly, retain the PotS equipment UI and prototype a separate visual-only model panel rather than coupling gameplay state to undocumented frames.

## Phase 3 - Update every item consumer

Inventory support is incomplete until systems stop assuming that all usable items live in six native slots or only in PotS tables.

- [ ] `ItemSystems/ItemHook.j`: register equip/unequip responses and validate create/destroy tracking for bagged and equipped items.
- [ ] `UnitSystems/UnitStats.j`: recalculate on native equip/unequip, consume the separated base/equipment totals where appropriate, and prevent duplicate stat application when the bridge or aggregate bonus carriers are active.
- [ ] `DestroyerInventoryAndEquipmentSystem/PoTs/HeroItemCheck.j`: search/remove across quick slots, native bag, native equipment, and PotS storage according to category policy.
- [ ] `Death/Death.j` and `Death/Revival.j`: include native bag/equipment in difficulty-based loss and exact restoration.
- [ ] `Professions/Professions.j` and `Professions/ProfessionsCooking.j`: locate ingredients/tools and process direct consumable-use events safely.
- [ ] `AI/AI.j`: teach inventory helpers about bagged/equipped state before AI heroes use or transfer items.
- [ ] `PlayerHome/PlayerHome.j`: find the Traveler's Journal without assuming a quick-inventory slot.
- [ ] `Resources/ResourceEnergy.j` and `Resources/ResourceRage.j`: refresh resource state after native equip, unequip, and bag use.
- [ ] `ItemSystems/ItemCleanup.j`: treat native bagged/equipped items as owned and protected from ground cleanup.
- [ ] `ItemLootSystems/ItemLootSystem.j`, `UI/ShopUI.j`, and vendor delivery: choose a deterministic destination and full-inventory fallback.
- [ ] `QuestsAndDialogs/QuestGiver.j`: include native inventory categories in quest-item checks without changing quest ownership rules.

### Filtered random items

- [ ] Prototype `ChooseRandomItemExWithFilter` using level, `itemtype`, `equipmentType`, and `itemTag`.
- [ ] Use it only where engine-side random selection is desirable. PotS loot tables retain authority over rarity, weights, quantities, quest gates, zones, bosses, and specific sources.
- [ ] Confirm deterministic synchronized results in multiplayer before using it for gameplay drops.

### Team-colored items

- [ ] Prototype `SetItemColor` for ownership or faction communication, not rarity coloring; it accepts a `playercolor`, not arbitrary RGB.
- [ ] Test ground, bag, equipment, native 3D display, transfer, and neutral ownership behavior.
- [ ] Do not enable globally unless the visual language is understandable in the supported SD/Classic presentation.

## Phase 4 - Ability cooldowns, aura state, and attack resets

### Cooldown API

Target natives:

- `BlzGetUnitAbilityCooldownPercent`
- `BlzSetUnitAbilityCooldownRemaining`
- `BlzSetUnitAbilityCooldownPercent`
- `BlzAdjustUnitAbilityCooldownRemaining`
- `BlzAdjustUnitAbilityCooldownPercent`

Implementation work:

- [ ] Build a semantics test for positive/negative adjustment, values outside 0-100%, abilities not cooling down, charge-based abilities, transformed units, and ability level changes.
- [ ] Refactor `Abilities/Shaman/ShamanCommon.j` so talent cooldown reduction adjusts the active cooldown instead of restarting it through `BlzStartUnitAbilityCooldown`.
- [ ] Update `ShamanAncestralWard.j` to set remaining cooldown explicitly where its scripted cast requires a fixed value.
- [ ] Review `ShamanSummonElemental.j` cooldown gating and all future talent effects against the shared helper.
- [ ] Add focused tests proving repeated callbacks cannot apply the same reduction more than once.
- [ ] Keep UI cooldown display consistent with the actual engine cooldown.

### Aura toggling

- [ ] Test `BlzUnitEnableAuras(unit, enable, affectsUI)` with learned auras, item auras, hidden spellbook auras, totems, dead units, morphs, and illusions.
- [ ] Use it only for states that intentionally suppress every aura on a unit, such as controlled transitions or special encounter states.
- [ ] Do not replace the targeted buff cleanup in `ResourceEnergy` or `ResourceRage`; removing received mana-regeneration buffs is not equivalent to disabling all aura abilities emitted by that unit.
- [ ] Verify that UI state restoration is exact after nested disable/enable requests.

### Attack cooldown reset

- [ ] Test `BlzResetUnitAttack(unit, weaponIndex)` with weapon indices 0 and 1, melee/ranged heroes, attack-speed bonuses, and interrupted attacks.
- [ ] Adopt only for an explicitly designed "immediate next swing" mechanic. Do not replace generic `IssueImmediateOrder(..., "stop")` calls.
- [ ] Consider `ShamanStormstrike` or a future windfury-style proc only after combat design approves the behavioral change.

## Phase 5 - Camera, input, and minimap

### CameraControl

- [ ] Prototype `BlzCameraSetCameraType`/`BlzCameraGetCameraType` and document valid integer camera types.
- [ ] Use `SetCameraFieldControlledByInput` to give the engine or PotS exclusive ownership of each camera field during Normal, Advanced, Developer, dialog, death, travel, and fullscreen cinematic modes.
- [ ] Evaluate `CAMERA_FIELD_ZABSOLUTE`, depth-of-field distance, and depth-of-field scale for cinematic presets only.
- [ ] Evaluate `EnableCameraBlocker` and `AddCameraBlocker` for authored zone restrictions instead of repeated corrective camera movement.
- [ ] Preserve `CameraControl_Suspend*`, resume state, `DialogCamera`, death camera, travel camera, and DynamicMinimap contracts.

### Input and coordinate APIs

- [ ] Evaluate `BlzIsKeyPressed`, `BlzIsMetaKeyPressed`, and `BlzIsMouseButtonPressed` for robust modifier and held-input state.
- [ ] Evaluate `BlzGetMouseScreenPosX/Y` plus pixel/frame conversion for UI hit testing and drag interactions.
- [ ] Keep local input and camera results out of synchronized gameplay writes unless explicitly synchronized.
- [ ] Replace `CameraControl`'s hidden item pathing probe with `BlzIsTerrainPathableEx` only if it matches the current collision behavior around items, cliffs, destructibles, water, and narrow passages.

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

- [ ] Prototype an orbit camera around `CameraControl`'s current target: horizontal drag changes rotation and vertical drag changes angle of attack.
- [ ] Use middle mouse as the initial drag button. `CameraControl` already uses middle click to reset stored camera state, so preserve a short click as reset and interpret movement beyond a configurable dead zone as a drag.
- [ ] Keep right-drag as an optional experiment only. Warcraft III uses right-click for smart orders, so it must not become the default unless testing proves that dragging can avoid accidental unit orders and ground commands.
- [ ] Compare this custom orbit behavior with valid `BlzCameraSetCameraType` values before deciding whether PotS should implement every free-camera field itself.
- [ ] Prototype `CAMERA_FIELD_ROTATION`/`CAMERA_FIELD_ANGLE_OF_ATTACK` first, then compare `CAMERA_FIELD_LOCAL_YAW`/`CAMERA_FIELD_LOCAL_PITCH` only where the selected camera type gives useful free-look behavior.

Local drag loop:

1. On mouse-down, store the initial pixel X/Y, converted frame X/Y, current `CC_Rotation`, current `CC_Angle`, and accumulated drag distance.
2. During the existing `CameraControl` update loop, poll `BlzIsMouseButtonPressed` and read the new screen position only for the local active client.
3. Calculate resolution-aware deltas as the difference between successive `BlzPixelToFrameX/Y` results. Verify the Y-axis sign experimentally rather than assuming pixel and frame origins match.
4. Apply sensitivity, dead-zone, and maximum-per-tick clamps so focus changes, cursor warps, or a stalled frame cannot cause a camera jump.
5. Write through `CC_Rotation` and `CC_Angle` plus the existing camera-application path. Do not set camera fields behind `CameraControl`'s stored state, or its drift correction, resume logic, and DynamicMinimap safety rotation will fight the drag.
6. Mark rotation input grace for DynamicMinimap in the same way as keyboard rotation.
7. On release, focus loss, camera suspension, mode change, cinematic start, death camera, travel camera, or fullscreen UI takeover, clear the drag state and restore any cursor/input ownership changed by the prototype.
8. If total movement remained below the dead zone, execute the existing middle-click camera reset; otherwise consume the gesture only as a camera drag.

Local/multiplayer safety requirements:

- [ ] Treat button state, cursor pixels, converted frame coordinates, drag anchors, accumulated deltas, and resulting camera fields as local presentation state.
- [ ] Never use these values to move or order units, select gameplay targets, choose random results, modify synchronized camera-mode authority, or branch around synchronized handle creation/destruction.
- [ ] Do not transmit ordinary drag samples. Add explicit synchronization only if a future spectator or replay feature genuinely needs another player's camera orientation.
- [ ] Keep camera calls local to the player whose client supplied the cursor state. Two players must be able to drag to different angles without affecting each other or synchronized gameplay.
- [ ] Suppress drag start while a modal PotS frame, dialogue, shop, inventory, equipment screen, or text-entry interaction owns mouse input.

Cursor policy:

- [ ] Begin with a bounded drag that leaves the cursor visible and does not call `BlzSetMousePos`; this has the lowest interaction risk.
- [ ] Evaluate an optional captured mode that hides and recenters the cursor only after bounded dragging is stable.
- [ ] If recentering is adopted, warp to the local client center before the cursor reaches an edge, ignore the synthetic post-warp delta, and restore the cursor on every exit path.
- [ ] Cancel capture when `BlzIsLocalClientActive()` is false to prevent a stuck button or hidden cursor after Alt-Tab.

Prototype and regression matrix:

- [ ] Test 16:9, 16:10, 21:9, and 4:3 aspect ratios where available, plus windowed/fullscreen modes and Windows DPI scaling.
- [ ] Verify frame-space sensitivity is comparable across resolutions and UI scales.
- [ ] Test press without movement, small jitter, fast flicks, edge contact, focus loss, Alt-Tab, and release outside the client.
- [ ] Confirm middle click still resets, middle drag does not reset, and an optional right-drag mode does not issue orders.
- [ ] Test over terrain, units, minimap, command card, inventory, equipment, shops, dialogue, quest UI, and fullscreen custom frames.
- [ ] Test Normal, Advanced, Developer, special-zone, dialog, death, travel, and fullscreen cinematic camera transitions.
- [ ] Verify suspend/resume restores the pre-interruption orbit exactly and never leaves camera fields controlled by the wrong owner.
- [ ] Run a two-player test with deliberately different simultaneous drags and confirm no desync or cross-player camera movement.
- [ ] Reuse the existing camera update timer if profiling permits; avoid a second permanent high-frequency timer and avoid polling every inactive player when nobody is dragging.

### Dynamic minimap

- [ ] Enable the new "generate dynamically within camera bounds" option in a copy of the map.
- [ ] Compare it against `DynamicMinimap/DynamicMinimap_lastWorking.j` for resolution, painted colors, fog-of-war behavior, pings, quest icons, camera-bound transitions, and performance.
- [ ] Determine whether native generation eliminates the imported chunk textures and the risky `SetCameraBounds` transaction.
- [ ] Keep chunked/full-map modes until the native option passes long-session and multiplayer testing.
- [ ] If native generation wins, remove imports and conversion tooling in a separate cleanup commit after rollback assets are archived.

## Phase 6 - Fog, lighting, and weather

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

- [ ] Add a `FogPreset`-style data structure or equivalent explicit arrays with copy/apply/interpolate operations.
- [ ] Update `Zones/ZonesCore.j` and zone configuration without changing current visuals by default.
- [ ] Update `Stormv2.j` so lightning flashes save, modify, and restore every fog field rather than only legacy fields.
- [ ] Reconcile `WeatherSystemV4`, `DNC`, fullscreen UI fog overrides, dungeon transitions, and per-selected-hero zone presentation.
- [ ] Test which fog setters are safe as local visual calls and document the multiplayer rule.
- [ ] Author representative linear, height, exponential, dungeon, snow, rain, and storm presets in the World Editor with live preview.

### Excluded HD water

Do not add an `HDWater` controller or adopt the `BlzSetHDWater*`/`SetHDWaterParamsEx` APIs. PotS is SD-only, so this would add code and testing burden for an unsupported presentation mode. Continue using the current terrain-water, weather, and rain-ripple behavior.

### Lighting and post processing

- [ ] Use SD-compatible lighting controls to establish baseline day, night, dungeon, storm, and special-area profiles.
- [ ] Replace suitable decorative emissive effects with editable omni lights where this reduces model/effect overhead.
- [ ] Test shadow-casting omni lights against `DoodadRender` and graphics quality settings.
- [ ] Use `BlzSetMinShadowCastingPointLightCount` only through a graphics preset; benchmark GPU cost before raising it.
- [ ] Create map-level post-processing presets only if they affect the supported SD presentation, and verify readability of PotS UI, fog, terrain water, and cinematics.
- [ ] Document all manual values so the World Editor remains the source of truth.

## Phase 7 - Doodads, destructibles, decals, and shadows

### DoodadRender modernization

Target natives include `BlzGetNumDoodads`, doodad index getters, `BlzSetSingleDoodadAnimation`, and single/area color setters.

- [ ] Test whether doodad indices are stable across clients, map saves, variations, and editor rebuilds.
- [ ] Build a runtime spatial index from doodad X/Y/rawcode only if initialization time and memory beat the current rect-by-rawcode approach.
- [ ] Compare single-instance hide/show against `SetDoodadAnimationRect` for call count, correctness, and FPS on the current approximately 50,000 placements.
- [ ] Preserve `DoodadManager` per-type render distances and fullscreen cinematic suspension.
- [ ] Use exact instance animation to avoid hiding nearby same-type doodads outside the intended cell.
- [ ] Retain the generated `war3map.doo` reference workflow if runtime enumeration is slower or index behavior is unstable.

### Rotation, local axes, and colors

- [ ] Use World Editor pitch/roll and local-axis scaling for environmental art that currently needs pre-rotated models.
- [ ] Review procedural creation in `BridgesAndGates/BridgeSystem.j`, traps, and scripted scenery for `BlzCreateDestructable*PitchRoll*` opportunities.
- [ ] Use `SetDoodadColor`, `BlzSetSingleDoodadColor`, `SetDestructableColor`, and `SetDestructableVertexColor` only for clear faction/state communication.
- [ ] Confirm color and orientation survive death, revival, replacement, hiding, and save/load-equivalent recreation.
- [ ] Verify pathing and selection remain aligned with rotated visuals.

### Excluded HD-only authoring features

Do not schedule HD water doodads, HD decals, HD shadow blockers, or per-doodad HD-shadow work while PotS remains SD-only. The light-range visualization and editable lights may still be used only where they demonstrably affect and improve the supported SD presentation.

## Phase 8 - Special effects, HUD, sound, and editor workflow

### SpeciFX

- [ ] Add named-animation APIs using `BlzSetSpecialEffectAnimation` and `BlzQueueSpecialEffectAnimation`.
- [ ] Add an optional blend-time API using `BlzSetSpecialEffectAnimationBlendTime`.
- [ ] Keep existing `animtype` support through `BlzPlaySpecialEffect` for backward compatibility.
- [ ] Test queued animation cleanup, invalid animation names, time scale, looping models, and effect destruction.
- [ ] Migrate only effects that currently require recreation or timers solely to sequence animations.

### Orc HUD compatibility and hero presentation

- [ ] Keep the current Orc/default HUD identity fixed; do not expose Human/Forsaken HUD selection or make HUD skin a per-player gameplay option.
- [ ] Confirm Warcraft III 3.0 does not change the expected origin-frame names, sizes, or anchors used by `Interface`, `MasterUI`, `FullscreenUI`, `UIChanges`, quest UI, stats UI, abilities UI, shops, and inventory/equipment.
- [ ] Use `SetPlayerRaceSkin` only if a narrowly scoped compatibility fix is required to preserve the Orc HUD, and validate the call before custom UI frame discovery.
- [ ] Evaluate `UNIT_BF_FORCE_DISPLAY_HP` for invulnerable buildings that should retain visible health; make the actual object-data choice manually in World Editor.

### Sound variables

- [ ] Use the editable sound-variable path feature to repair paths without recreating GUI sound variables.
- [ ] Re-export or refresh `SoundAndMusic/SoundEditorSounds.json` and `ExSoundEditorSounds.j` after approved changes.
- [ ] Confirm `ExSound` path lookup, labels, 3D settings, durations, and imported-file registration remain correct.

### Trigger-authoring workflow

- [ ] Use Copy As Script to capture remaining GUI behavior before converting it into maintained PotS libraries.
- [ ] Use the new GUI leak-cleaning actions for GUI triggers that will remain GUI.
- [ ] Do not accept automatic Lua conversion as a final PotS implementation.
- [ ] Increase the editor undo-stack limit after measuring memory use on the full map.
- [ ] Use the string-ID adjustment tool only with a saved backup and a before/after reference audit.

## Phase 9 - Rollout order

1. Add the disabled full-map 3.0 harness to the existing `/debug` workflow and record baseline semantics without changing production behavior.
2. Implement the native-style aggregate `DEquipment` bonus layer behind a mutually exclusive rollback flag; make this the first runtime upgrade.
3. Add ItemManager schema/UI/W3T support without changing production item behavior.
4. Backfill a small reviewed equipment/tag test set.
5. Implement the native inventory bridge behind a disabled configuration flag only after equipment-bonus semantics are stable.
6. Integrate equip/unequip and direct bag-use events with item consumers.
7. Convert cooldown helpers and extend SpeciFX.
8. Prototype camera and dynamic-minimap replacements.
9. Extend fog state, then evaluate only SD-compatible lighting/post-processing presets.
10. Modernize doodad handling only after performance comparison.
11. Enable features independently, with one changelog entry and rollback path per workstream.

## Validation gates

### Compilation

- [ ] Full map compiles through the normal World Editor/JassHelper workflow with the harness present but disabled.
- [ ] Full map compiles and starts with the selected experimental path enabled; activating its suite is not required for an ordinary smoke session.
- [ ] No archived Blizzard script is accidentally used by JassHelper or editor tooling.

### Inventory and equipment

- [ ] No item duplication, disappearance, handle reuse, or zero-charge resurrection.
- [ ] Stats and set bonuses apply exactly once and are removed exactly once.
- [ ] Native Strength, Agility, Intelligence, damage, and armor show equipment increases in green and decreases in red without converting those changes into permanent/base values.
- [ ] Level gains, tomes, scripted permanent rewards, morphs, and respecs modify only the base layer; equipment remains an independently removable bonus layer.
- [ ] Repeated equip/unequip, item mutation, set activation, death/revive, and load cycles produce no base-stat drift or `+-value` character-sheet text.
- [ ] Native-equipped item abilities and PotS aggregate bonus carriers never double-apply the same stat.
- [ ] Two-handed/offhand and dual-wield restrictions remain correct.
- [ ] Quest items, profession ingredients, shops, loot, death loss, revival restoration, and cleanup see the correct storage categories.
- [ ] Directly used consumables support all target modes and share cooldowns correctly.
- [ ] Native and PotS UI stay synchronized after every operation.

### Multiplayer and local presentation

- [ ] Equip, unequip, item use, random selection, fog, camera, and UI tests run with at least two players.
- [ ] Local camera/input/HUD calls do not create synchronized state divergence.
- [ ] Selected heroes may occupy different zones without applying another player's fog or camera state.

### Performance and visual modes

- [ ] Compare long-session FPS and memory before/after doodad, minimap, SD-compatible lighting, and post-processing changes.
- [ ] Verify the supported SD/Classic presentation at low and high graphics settings.
- [ ] Verify all new SD-compatible model, texture, sound, and light assets resolve without editor-log warnings.

## Completion criteria

This plan is complete when each adopted workstream has documented runtime semantics, full-map harness and normal full-map compile/runtime results, multiplayer validation where relevant, an explicit rollback route, updated developer documentation, and a current-date changelog entry. Features that fail parity or safety testing should remain documented prototypes rather than production dependencies.
