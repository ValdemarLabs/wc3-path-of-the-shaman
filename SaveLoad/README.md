# PotS Maxou NSL SaveLoad 2.1.0

This directory contains the PotS-owned automatic character-state layer described by `PotS_MaxouNSL_AutoSaveLoad_Codex.json`. It uses the existing Maxou New Save Load (NSL) codec and FileIO stack as an immutable backend. No file under `_CoreSystems/MaxouNSL/` is modified or copied.

The implementation is single-player only. Local file reads are deliberately separated in `PotSMaxouNSLAdapter`; all game-state scanning and mutation lives in the other PotS libraries. Multiplayer synchronization is not implemented or claimed.

## Architecture and import order

Import the scripts in this dependency order:

1. `PotSSaveConfig.j`
2. Immutable vendor core:
   - `_CoreSystems/MaxouNSL/Core by Trigger Happy vJASS/FileIO.j`
   - `_CoreSystems/MaxouNSL/Core by Trigger Happy vJASS/SaveFile.j`
   - `_CoreSystems/MaxouNSL/Save Load System vJASS/NSL Size Enum.j`
   - `_CoreSystems/MaxouNSL/Save Load System vJASS/NSL Helper.j`
   - `_CoreSystems/MaxouNSL/Save Load System vJASS/NSL Save Load.j`
3. `PotSStateData.j`
4. `PotSStateTracker.j`
5. `PotSWorldProgression.j`
6. `PotSStateScanner.j`
7. `PotSStateSerializer.j`
8. `PotSStateMigration.j`
9. `PotSMaxouNSLAdapter.j`
10. `PotSSaveLoad.j`
11. `PotSSaveCommands.j`
12. `PotSSaveUI.j`, after `GameMode`, `ImagesUI`, `Interface`, and `MasterUI`; then `Preloader.j`

`PotSSaveLoadTests.j` is test-map-only and has no initializer.

Do not import the vendor example/user-integration scripts (`NSL Implementation.j`, `NSL Utils.j`, `NSL SaveLoadExecutor.j`, `NSL CodeHelper.j`, `NSL CodexStore.j`, `NSL NumberUtils.j`, or the multiple-code example) as part of this PotS workflow. They remain byte-identical in the repository. The examples own their own state and `-save`/`-load` workflow; selecting only the reusable NSL core avoids duplicate commands and duplicate vendor configuration. `NSL NumberUtils.j` is empty in the inspected package, while the example helper references number utilities, so the example stack is not a safe dependency for this adapter.

The PotS ability, quest, and item integrations are optional vJASS dependencies. For full PotS behavior, import the existing `AbilitiesPlayer`, `Abilities`, `AbilityPoints`, `QuestMaster`, `DInventory`, and `DEquipment` libraries before the relevant SaveLoad modules. `Start`, `GameMode`, `Preloader`, and `MasterUI` contain only the narrow startup/menu wiring for this feature.

### World Editor requirement

FileIO still requires the package's `Z000` buffer ability configured with 50 levels exactly as documented by Maxou NSL/FileIO. This is an Object Editor step and must be done in World Editor; exported map data is not edited by this implementation.

## Verified backend surface

The adapter uses only these source-verified public APIs:

- `NSL_Code.create_save(playerId, callback)`, `SV(value, bitCount)`, and `Generate()`
- `NSL_Code.create_load(playerId, code, callback)`, `RV(bitCount)`, `code_version`, and `destroy()`
- `SaveFile.create(player, title, characterId, data)`, `exists(characterId)`, and `getData(characterId)`
- `NSL_SIZE_BOOLEAN`

NSL remains responsible for its player-name binding, integrity check, NSL code version, integer encoding, and FileIO transport. PotS adds an application-schema header inside the NSL integer payload. The inspected package matches the published Maxou NSL resource updated 13 November 2025.

`PotSSaveConfig.j` supplies the three globals required by the reusable vendor core without editing vendor files: `NSL_CodeVersion = 1`, `NSL_Key = 19`, and `NSL_FolderName = "Pots"`.

## Player workflow

- After preload, the first gameplay panel offers `New Game` and `Load Saved`. New Game opens the existing mode/difficulty flow; Load Saved lists six local slots.
- `MasterUI` exposes the same six-slot Save / Load panel during play.
- `-pots-save <slot>` and `-pots-load <slot>` remain available for 1-30-character ASCII slot names made of letters, digits, underscores, or hyphens.
- A party slot writes authenticated `pots_<slot>_n` and, when owned, `pots_<slot>_z` character files. A small `pots_meta_<slot>` manifest publishes the title, hero count, game mode, and difficulty only after every required character file succeeds.
- The startup panel restores the saved mode/difficulty before `Start` creates Nazgrek, then loads Nazgrek followed by Zul'kis when the manifest contains both heroes.
- The startup slot choice explicitly reopens and owns the safe-load window, so waiting on the title panel does not invalidate a selected save.

The unchanged FileIO backend accepts only a relative folder. With `NSL_FolderName = "Pots"`, its generated paths are `Pots\SaveChar_<characterId>.pld` inside Warcraft III's permitted custom-map/FileIO storage. JASS cannot force these files into the literal installation directory `C:\Program Files (x86)\Warcraft III\_retail_\Pots`; the client chooses the physical sandbox location.

Party saves prefer `udg_Nazgrek` and include `udg_Zulkis` when Zul'kis is a valid player-owned hero. The registered/selected-hero resolver remains as a safe fallback when Nazgrek is unavailable.

Only one operation per player can run at once. A second load is rejected. An unexpected apply-stage failure locks further loading for that session and tells the player to reload the map, because Warcraft III does not provide a transactional rollback for arbitrary unit mutations.

Checkpoints may explicitly reopen or close loading with `PotSSaveLoad_SetLoadAllowed`. The default implementation does not relocate a hero to a checkpoint because no stable authoritative checkpoint API was found.

## Persisted state

| Category | Coverage | Source and behavior |
| --- | --- | --- |
| Hero identity | Automatic | Unit type rawcode; load requires the current resolved hero to have the same type unless an explicit rawcode migration is registered. |
| Hero progression | Automatic | Total XP, level, native skill points, and optional custom `AbilityPoints`. |
| Permanent base stats | Automatic | Base strength, agility, and intelligence. |
| Learned abilities | Automatic for `AbilitiesPlayer`; event-assisted otherwise | Catalog entries are queried through existing APIs. Native hero-learn events and `PotSStateTracker_TrackPermanentAbility` provide provenance for conventional or exceptional permanent skills. |
| Temporary/item abilities | Intentionally excluded | An ability not in `AbilitiesPlayer` and not tracked as permanent is not serialized, so item or temporary buffs are not revived permanently. |
| Normal inventory | Automatic | Every normal engine inventory slot, item rawcode, and charge count; no per-item SaveLoad registry. |
| Custom inventory | Automatic with `DInventory` | Exact bag tier, additional capacity, occupied slot, item rawcode, and charges. Items are restored to the same custom slots. |
| Equipment | Automatic with `DEquipment` | Exact equipment slot, item rawcode, and charges. Existing equipment bonuses/set counters are removed before the saved equipment is rebuilt and its stats reapplied. |
| Stash/bank and item affixes | Not saved | No enabled stash or named/enchantment item module was found in the active configuration; unsupported metadata is not approximated. |
| Player resources | Automatic | Gold and lumber. |
| Vitals | Automatic optional values | Life and mana are stored as clamped ratios and applied last. |
| Quest/world progression | Bounded adapter | Completed `QuestMaster` entries only, identified by quest-name hash plus giver unit type. Current-map definitions remain authoritative; completion is overlaid without replaying rewards. Missing or ambiguous old entries are skipped with a warning. |
| Whole world, loose items, arbitrary globals, buffs, timers | Not saved | The current map initializes normally; no old map clone or handle/order identity is restored. Private story-phase globals outside `QuestMaster` (for example an in-progress Zul'kis prologue scene) remain map-specific follow-up work. |

Script-granted abilities that should survive must call `PotSStateTracker_TrackPermanentAbility(hero, rawcode, level)` when granted. No hook is needed for normal `AbilitiesPlayer` catalog skills or native hero-learn events.

## Application schema

Current schema is `2.1`; schema `1.x` and `2.0` remain readable and are migrated/defaulted in memory.

The integer stream begins with magic, schema major, schema minor, and record count. Every record is `[tag, payload length, payload...]`. Required tags are hero identity, hero progression, attributes, abilities, inventory, and resources. Optional tags cover custom inventory, equipment, vitals, ability provenance, and completed quests. Unknown tags are skipped by their declared length. Duplicate tags, malformed lengths, missing required records, future schema versions, duplicate slots/abilities, and out-of-range values are rejected before gameplay mutation.

Schema 1 stored the core fields but no explicit provenance record and allowed a three-integer hero-progress record. Migration defaults custom ability points and vitals to `-1`, derives catalog membership from the current `AbilitiesPlayer`, and conservatively treats remaining saved abilities as tracked permanent abilities. Schema 2.0 adds tracked-ability provenance; 2.1 adds optional custom-inventory and equipment records, so older saves default those categories to untouched/unavailable.

Rawcode renames are explicit and bounded:

- `PotSStateMigration_RegisterHeroRawcode(oldId, newId)`
- `PotSStateMigration_RegisterAbilityRawcode(oldId, newId)`
- `PotSStateMigration_RegisterItemRawcode(oldId, newId)`
- `PotSStateMigration_RegisterQuestIdentity(oldNameHash, oldGiverType, newNameHash, newGiverType)`

Existing rawcodes should remain stable whenever possible.

## Load stages and safety

1. Read and authenticate the local NSL code.
2. Decode the complete bounded integer stream.
3. Validate and migrate without touching gameplay state.
4. Preflight hero identity, catalog levels, normal/custom inventory and equipment item creation, and quest mapping.
5. Enable the restore guard and suppress tracker events.
6. Apply XP/level/base stats/points, then abilities, normal inventory, custom inventory/equipment, player resources, vitals, and quest completion metadata.
7. When Zul'kis is present, authenticate/decode/migrate/preflight and cache that snapshot before applying Nazgrek, then apply the cached Zul'kis state. Restore tracker provenance, disable the guard, and permanently reject a second load.

`PotSSaveLoad_IsRestoring()` lets future PotS-owned adapters avoid reward or progression side effects. Decode, schema, integrity, and preflight failures do not mutate the hero. Quest completion is set directly and refreshes existing quest UI/icons; it does not call completion/reward actions.

## Capacity

The adapter stores each signed PotS integer as one sign bit plus a 31-bit magnitude. The one unrepresentable JASS value (`-2147483648`) is rejected before save. The stream count uses 10 bits and PotS additionally caps each character snapshot at 1,000 integers.

The inspected NSL codec uses 6-bit characters plus a seven-character integrity suffix. Its FileIO buffer is 50 levels times 200 characters (10,000 characters). The source-derived estimator is:

`ceil((10 NSL-version bits + 10 count bits + 32 * values) / 6) + 7`

| Snapshot | Integer values | Estimated NSL characters |
| --- | ---: | ---: |
| Smallest valid schema-2.1 snapshot | 48 | 267 |
| Large representative: 40 tracked skills, 6 items, 100 quest flags | 486 | 2,603 |
| Configured hard stream maximum | 1,000 | 5,344 |

These counts are asserted by `PotSSaveLoadTests`. The maximum remains below the 10,000-character FileIO ceiling. The independent per-category maxima deliberately exceed the combined stream budget; if a snapshot combines too many abilities and world flags, serialization fails before NSL generation or file overwrite instead of omitting data.

## Tests

Import `PotSSaveLoadTests.j` into a test map and call `PotSSaveLoadTests_Run()`. It covers deterministic ordering, signed integer/rawcode serialization, custom inventory/equipment roundtrips and invalid slots, schema-2.1 roundtrip, schema-1 fixture migration, unknown optional tags, missing defaults, malformed/truncated records, future schema rejection, representative sizes, and hard-cap rejection.

`tests/PotSSaveLoadCompile.j` is compile-only and must not be imported into a production map. It imports the immutable reusable NSL core, actual `AbilitiesPlayer`/`AbilityPoints`, and narrow contracts for `Abilities`, `QuestMaster`, `DInventory`, `DEquipment`, `Start`, and `GameMode`, so every optional branch is preprocessed outside the full map. `tests/PotSSaveUICompile.j` independently compiles the changed startup, GameMode, Preloader, MasterUI, and Save UI path. Compile either with `jasshelper --scriptonly <common.j> <blizzard.j> <harness.j> <output.j>`, then pass the generated output to pJass with the same active API files. These focused compiles supplement rather than replace a current World Editor full-map compile.

Required engine tests that cannot be run from the source repository alone:

1. Compile the affected test map and then the full map with the current World Editor/JassHelper.
2. Save/load Nazgrek alone and Nazgrek plus Zul'kis; verify both heroes' level, abilities, normal inventory, exact custom inventory slots, exact equipment slots, charges, and equipment-derived stats.
3. Learn a catalog skill normally, add a temporary/item ability, and opt in one scripted permanent ability; only the two persistent abilities should return.
4. Save in map version A; load unchanged in version B after adding unrelated terrain, an item, an ability, and a quest. New world content must remain.
5. Load the schema-1 fixture through schema 2, then save again.
6. Try nonexistent, wrong-profile, truncated, tampered, oversize, repeated, and rapid save/load requests.
7. Exercise abilities, items, `StunGuard`, `DiminishingReturns`, quest UI, custom inventory/equipment, and the startup New Game / Load Saved navigation after load.
8. Measure actual generated code length/time for the representative-large state in game.
9. Recompute `NSL_SHA256.txt` and verify every vendor hash is unchanged.

No atomic save replacement, backup rotation, absolute directory choice, multiplayer synchronization, or profile-independent code transfer is claimed. The facade prevalidates every included party hero before writing the first character file and publishes the manifest last, but the immutable backend does not expose a transactional multi-file replace.
