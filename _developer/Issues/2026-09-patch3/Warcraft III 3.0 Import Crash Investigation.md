# Warcraft III 3.0 World Editor Import Crash Investigation

## Table of contents

- [Executive summary](#executive-summary)
- [Scope and identifiers](#scope-and-identifiers)
- [Observed failure](#observed-failure)
- [Crash-report evidence](#crash-report-evidence)
- [Investigation method](#investigation-method)
- [Isolation results](#isolation-results)
- [Confirmed offender: AltarOfStorms.mdx](#confirmed-offender-altarofstormsmdx)
  - [Map references and placed instances](#map-references-and-placed-instances)
  - [File identity and container structure](#file-identity-and-container-structure)
  - [Model resources](#model-resources)
  - [Defective geoset](#defective-geoset)
  - [Hive Model Checker result](#hive-model-checker-result)
  - [Causal assessment](#causal-assessment)
- [Repairing or replacing AltarOfStorms.mdx](#repairing-or-replacing-altarofstormsmdx)
  - [Immediate containment](#immediate-containment)
  - [Preferred Retera Model Studio repair](#preferred-retera-model-studio-repair)
  - [Alternative geometry reconstruction](#alternative-geometry-reconstruction)
  - [Reimport and Object Editor follow-up](#reimport-and-object-editor-follow-up)
  - [Repair validation checklist](#repair-validation-checklist)
- [Other malformed or suspicious imports that did not crash map loading](#other-malformed-or-suspicious-imports-that-did-not-crash-map-loading)
  - [Malformed DNC light chunks](#malformed-dnc-light-chunks)
  - [BLP mipmap tables extending past end of file](#blp-mipmap-tables-extending-past-end-of-file)
  - [Zero-byte assets](#zero-byte-assets)
  - [Multi-dot names and extension parsing](#multi-dot-names-and-extension-parsing)
  - [Missing-model and doubled-extension warnings](#missing-model-and-doubled-extension-warnings)
  - [Unknown 3.0 data fields and custom SLKs](#unknown-30-data-fields-and-custom-slks)
  - [Unusual compact and ABANDON-family models](#unusual-compact-and-abandon-family-models)
- [Final known-good test state](#final-known-good-test-state)
- [Open follow-up: unexpected viewport inspection crash](#open-follow-up-unexpected-viewport-inspection-crash)
  - [Crypt doodad audit findings](#crypt-doodad-audit-findings)
- [Recommendations](#recommendations)
- [Future import-crash triage procedure](#future-import-crash-triage-procedure)
- [Evidence and related reports](#evidence-and-related-reports)

## Executive summary

Warcraft III World Editor 3.0.0.24268 consistently crashed while opening the PotS folder map `Epic Quests-2026-09-13-0239`. Windows also displayed an `Unsupported 16-bit Application` dialog, but Blizzard's crash reports identify the actual editor failure as a 64-bit `World Editor.exe` null-address read access violation.

The investigation isolated the loading crash to one imported model:

`war3campImported\AltarOfStorms.mdx`

The complete map import set loads when this one file is absent. Reintroducing the file causes the crash. All other import folders and files load together, including several assets with independently detectable format defects.

This is a load-stage result, not a declaration that the map is fully stable in World Editor 3.0. A later controlled viewing pass remained stable while scrolling elsewhere, then crashed when the viewport reached the large Crypt dungeon doodads. World Editor 3.0 also feels substantially heavier and laggier than the previous 2.x editor during ordinary map viewing. The Crypt had already produced intermittent lag and far-away collision/selection behavior under 2.x, so its imported WMO scenery is now the primary area-specific suspect rather than the previously broader Crypt/Firelands lead.

The strongest structural defect inside `AltarOfStorms.mdx` is its tenth geoset (zero-based index 9). It declares 13 vertices and 13 normals but no face indices and no triangles. A geoset animation still references this empty mesh. Across all 1,950 MDX version 800 models in the map, this is the only geoset found with nonzero vertices and zero faces.

The exact un-symbolized World Editor code path is not available, so the engine-level mechanism remains an inference. The working conclusion is that World Editor 3.0's model-loading or editor-rendering path does not safely handle this internally inconsistent geoset and dereferences a null mesh-related value.

The immediate workaround is to keep the model absent or use a safe placeholder. The preferred permanent fix is to remove the empty geoset and its associated geoset animation in a structure-aware model editor, save a normalized MDX v800 copy, and validate it under a new import name before replacing the production import.

## Scope and identifiers

| Item | Value |
| --- | --- |
| Warcraft III / World Editor version | 3.0.0.24268 |
| Patch name | Forsaken Kingdom / Warcraft III 3.0.0 |
| PotS map version | `Epic Quests-2026-09-13-0239` |
| Original folder map | `C:\Users\Valtteri\Documents\Warcraft III\Maps\EpicQuestsFolder40\Epic Quests.w3x` |
| Isolation test map | `C:\Users\Valtteri\Documents\Warcraft III\Maps\EpicQuestsFolder40_test1\Epic Quests.w3x` |
| Investigation dates | 13-15 September 2026 |
| Confirmed crashing import | `war3campImported\AltarOfStorms.mdx` |
| Affected custom doodad | `D6NJ` (`altar _of_storms`) |

The map is saved as an unpacked folder map. This allowed imported payload files to be removed and restored independently while leaving map metadata and the import manifest available for controlled tests.

The import inventory is unusually large:

- `war3map.imp` contains 12,683 records and 12,682 unique normalized paths.
- The physical import payload is approximately 526.6 MiB.
- The map contains 2,431 MDX files: 1,950 v800, 479 v1000, and 2 v1100.
- The map also contains 16 text-format MDL files and 8,231 BLP files.

## Observed failure

Opening the full PotS map after updating to Warcraft III 3.0.0.24268 produced two visible symptoms:

1. World Editor crashed during map loading.
2. Windows displayed an `Unsupported 16-bit Application` dialog referring to a Warcraft III executable.

The dialog was misleading as a root-cause indicator:

- The crash report names `_retail_\x86_64\World Editor.exe` as the failing process.
- Each report records an access violation caused by reading address `0x0000000000000000`.
- Other maps without PotS's imports loaded successfully.
- Scan and Repair did not change the result.
- Replacing suspected old game-data files did not change the result.
- The complete PotS map loads under the same installation when only `AltarOfStorms.mdx` is absent.

This does not explain why Windows presented the 16-bit dialog after the editor failure. It establishes that the dialog was a secondary symptom and not proof that the map contained or launched 16-bit code.

A similar dialog had appeared during a different PotS incident in summer 2025, when `DestructibleHider` caused a crash during map saving. That historical incident demonstrates that the dialog is not specific to one failure mode. It should not be used by itself to identify the crashing subsystem.

## Crash-report evidence

Five captured reports identify the same build and the same failure class:

| Report | Build | Failure |
| --- | --- | --- |
| [`2026-09-13 12.50.37 e5c597cc`](<2026-09-13 12.50.37 e5c597cc/Crash.txt>) | 24268 | Null-address read `ACCESS_VIOLATION`; instruction ends in `3B240B` |
| [`2026-09-13 13.24.40 a5aec748`](<2026-09-13 13.24.40 a5aec748/Crash.txt>) | 24268 | Same null-address read signature |
| [`2026-09-13 14.49.49 40679a7c`](<2026-09-13 14.49.49 40679a7c/Crash.txt>) | 24268 | Same null-address read signature |
| [`2026-09-14 01.42.46 4b9a5dd4`](<2026-09-14 01.42.46 4b9a5dd4/Crash.txt>) | 24268 | Same null-address read signature after address relocation |
| [`2026-09-15 19.05.49 2b228384`](<2026-09-15 19.05.49 2b228384/Crash.txt>) | 24268 | Same relocated instruction and call-chain offsets during the Crypt viewport crash |

The absolute instruction addresses differ when the executable is loaded at a different virtual address. After subtracting the World Editor module base, all five reports have the same faulting and first call-chain offsets: `0x55240B <- 0x4991C4 <- 0x4949F4`. This strongly supports the same internal editor code path being reached during both initial model loading and later Crypt viewport rendering, but the reports do not contain symbols that name that function.

The accompanying editor logs contain numerous asset and data-field warnings. Those warnings were useful leads, but the final successful full-import test proves that most were non-fatal to map loading. The latest [`War3EditorLog.txt`](<2026-09-15 19.05.49 2b228384/War3EditorLog.txt>) records the `_test1` map opening twice and the deliberately absent `AltarOfStorms.mdl`, but it does not name a Crypt model immediately before the later crash.

## Investigation method

The tests used elimination and progressive restoration on a disposable folder-map copy:

1. Preserve `war3map.imp` and the core map files.
2. Remove imported payloads from the test copy.
3. Confirm that the stripped map loads.
4. Restore broad asset classes and directories.
5. When a restored group crashes, split it by type or alphabetic range.
6. Repeat until a singleton file remains.
7. Restore every other import simultaneously to exclude a group interaction.
8. Inspect the singleton model's binary structure and map references.

The procedure distinguished three different categories:

- **Confirmed loading crash cause:** removal and reintroduction changes the outcome reproducibly.
- **Malformed but tolerated import:** static format checks find a defect, but the complete map still loads with the file present.
- **Warning or compatibility concern:** logs or Warcraft III 3.0 reports identify a risk, but the tested condition does not control this crash.

## Isolation results

| Test | Result | Interpretation |
| --- | --- | --- |
| Map with `war3map.imp` but without importer payload files | Loaded | Import manifest alone was not the cause. |
| Remove only custom `.slk` files | Crashed | Custom SLKs were not sufficient to explain the crash. |
| Scan and Repair Warcraft III files | Crashed | Installation repair did not resolve the map-specific failure. |
| Remove `*.wmo.mdx`, `*.wmo__*.mdx`, `*.blp.blp`, `*.alpha.blp`, and `war3mapImported\ocean_h.*.BLP` | Crashed | The obvious multi-dot candidates were not the loading-crash cause. |
| Restore all root-level imported assets | Loaded | Root imports were safe in this test. |
| Restore complete `war3campImported` | Crashed | The offender was in this directory. |
| Restore selected water MDX files | Loaded | The tested water models were safe. |
| Restore `hellfire_wall01.mdl` through `trollshoppingmall01.mdl` | Loaded | These text MDL models were safe. |
| Restore BLP, MP3, TGA, PNG, JPG, WAI, and AI files from `war3campImported` | Loaded | The crash followed an MDX payload rather than these asset classes. |
| Alphabetic group B, `ITEMBrillianceStaff.mdx` through `ZulGurubTree05.mdx` | Loaded | Group B was cleared. |
| Alphabetic group A, `[btw]_waterF.mdx` through `Farmer3.mdx` | Crashed | The offender remained in group A. |
| `Farmer4.mdx` through `ITEMBox.mdx` | Loaded | This range was cleared. |
| `[btw]_waterF.mdx` through `Book4.mdx` | Crashed | The suspect range was reduced again. |
| `BootsOfSpeed.mdx` through `crystalsongaspenbush02.mdx` | Loaded | This range was cleared. |
| `[btw]_waterF.mdx` through `8swa_watergrass_b03.mdx` | Loaded | This range was cleared. |
| `8wi_witch_cauldron01.mdx` plus three `9mw_...` models | Loaded | These four models were cleared. |
| `AltarOfStorms.mdx`, `arathifarmhouse01.mdx`, and `arathifarmhouse02.mdx` | Crashed | Three-file suspect group. |
| `AltarOfStorms.mdx` isolated | Crashed | Singleton offender reproduced the failure. |
| Complete `war3campImported` except `AltarOfStorms.mdx` | Loaded | All other assets in that directory were cleared together. |
| Complete `Environment` directory | Loaded | DNC defects documented below are tolerated during loading. |
| Complete `war3mapImported` directory | Loaded | All 1,405 files, including 278 MDX models, were cleared together. |
| Complete `ReplaceableTextures` directory | Loaded | All icon files, including malformed mip tables, were tolerated during loading. |
| Every remaining import directory together | Loaded | The full import set works when only `AltarOfStorms.mdx` is absent. |

The final all-assets test is important: it rules out the possibility that a second missing directory was merely hiding another immediate load crash.

It does not rule out assets that fail only when instantiated, streamed, selected, animated, or rendered in a particular area. The later reproducible Crypt viewing crash is evidence that at least one additional editor-stability problem remains.

## Confirmed offender: AltarOfStorms.mdx

### Map references and placed instances

The import and Object Editor data use different extensions:

| Location | Value |
| --- | --- |
| Physical import and `war3map.imp` | `war3campImported\AltarOfStorms.mdx` |
| Custom doodad `dfil` field in `war3map.w3d` | `war3campImported\AltarOfStorms.mdl` |

Warcraft III historically resolves an Object Editor `.mdl` reference to an imported `.mdx`. That convention is not the primary cause here: the missing model reference allows the editor to load, while supplying this particular MDX makes it crash.

The associated Object Editor record is:

| Property | Value |
| --- | --- |
| Object type | Custom doodad |
| Rawcode | `D6NJ` |
| Base doodad | `LZth` |
| Display name | `altar _of_storms` (`TRIGSTR_5920`) |
| Model field | `dfil` |
| Model path | `war3campImported\AltarOfStorms.mdl` |

The byte sequence `D6NJ` occurs eight times in `war3map.doo`, consistent with eight placed instances. No `AltarOfStorms` path was found in `war3map.j`, `war3map.wtg`, or `war3map.wct`. A match in `war3mapSkin.w3t` refers only to `btnaltarofstorms.blp`, not to the crashing model.

### File identity and container structure

| Property | Value |
| --- | --- |
| Relative path | `war3campImported\AltarOfStorms.mdx` |
| File size | 268,732 bytes |
| SHA-256 | `C06BA8EA01DACD7651986B3C7AB779BE16A5390F71D6AFDA0C3768ED8D820B6B` |
| MDX magic | `MDLX` |
| MDX version | 800 |
| Internal model name | `AltarOfStorms_wmo` |

The top-level container is complete and ends exactly at the file boundary:

| Chunk | Payload bytes | Meaning |
| --- | ---: | --- |
| `VERS` | 4 | MDX version |
| `MODL` | 372 | Model header and extents |
| `SEQS` | 132 | One animation sequence record |
| `MTLS` | 432 | Nine materials |
| `TEXS` | 2,412 | Nine texture records |
| `GEOS` | 264,880 | Ten geosets |
| `GEOA` | 308 | Eleven geoset animations |
| `BONE` | 104 | Bone data |
| `PIVT` | 12 | One pivot point |

This is not a simple truncated file or a corrupt top-level chunk table. The defect is inside a structurally reachable geoset.

### Model resources

The model references nine clean, single-extension texture names:

- `MM_AOS_BASE_02.blp`
- `MM_AOS_PILLAR_01.blp`
- `MM_AOS_TRIM_01.blp`
- `DARKPORTAL_STAUE_01.BLP`
- `DARKPORTAL_STAUE_02.BLP`
- `MM_AOS_SKULL_01.blp`
- `MM_AOS_BASE_01.blp`
- `MM_AOS_RUBBLE_01.blp`
- `MM_AOS_BONES_01.blp`

All nine files exist at the map root. Missing textures and multi-dot texture names therefore do not explain this model's load crash.

### Defective geoset

The ten geosets have the following geometry counts:

| Zero-based geoset | Vertices | Face indices | Status |
| ---: | ---: | ---: | --- |
| 0 | 98 | 261 | Populated |
| 1 | 96 | 426 | Populated |
| 2 | 118 | 246 | Populated |
| 3 | 18 | 36 | Populated |
| 4 | 1,041 | 3,708 | Populated |
| 5 | 1,708 | 5,343 | Populated |
| 6 | 2,960 | 11,682 | Populated |
| 7 | 129 | 366 | Populated |
| 8 | 355 | 1,668 | Populated |
| **9** | **13** | **0** | **Defective/suspicious empty mesh** |

Detailed fields for geoset 9:

| Field | Value |
| --- | ---: |
| Geoset byte offset | 267,683 |
| Inclusive geoset size | 601 bytes |
| Vertices (`VRTX`) | 13 |
| Normals (`NRMS`) | 13 |
| Primitive-type entries (`PTYP`) | 1 |
| Primitive type | 4 (triangles) |
| Primitive-count entries (`PCNT`) | 1 |
| Primitive count value | 0 |
| Face indices (`PVTX`) | 0 |
| Vertex groups (`GNDX`) | 13 |
| Matrix groups (`MTGC`) | 1 |
| Matrix indices (`MATS`) | 1 |
| Material ID | 8 |
| Selection group | 0 |
| Selection flags | 0 |

The final geoset-animation record, zero-based `GEOA` index 10, references geoset ID 9. The bad geoset is therefore not merely unreachable trailing bytes; it participates in the model's declared structure.

A complete scan of the map's 1,950 MDX v800 models found exactly one geoset with vertices but no face indices: this one.

### Hive Model Checker result

The model was independently checked with the [Hive Workshop Model Checker](https://viewer.hiveworkshop.com/check/). It reported one severe warning and three ordinary warnings:

| Severity | Checker result | Local interpretation |
| --- | --- | --- |
| Severe warning | `Geoset 9: Zero faces` | Independently confirms the exact empty geoset found by the binary scan. This remains the primary repair target and likely 3.0 crash trigger. |
| Warning | `Missing "Death" sequence` | A static doodad can intentionally omit a death animation. This may affect removal/death presentation but is not established as a loading-crash cause. |
| Warning | `Geoset 6: Referenced by 2 geoset animations: 0, 7` | Confirms that geoset 6 has two animation controllers. Inspect whether they intentionally combine different alpha/color states before merging or deleting either record. |
| Warning | `Missing the Origin attachment point` | May limit attachment-based effects or tooling expectations. It is recommended cleanup, but an Origin attachment is not required to explain the zero-face crash. |

The checker result materially strengthens the structural diagnosis because it reaches the same geoset-9 conclusion independently. It does not prove that the three ordinary warnings contribute to the World Editor crash. For clean causal validation, repair the severe zero-face geoset first and test that change before making optional animation or attachment cleanup.

### Causal assessment

The evidence for `AltarOfStorms.mdx` as the crash trigger is conclusive at the file level:

- The map crashes with the file present.
- The map loads with the file absent.
- The file crashes when isolated from its neighboring alphabetic group.
- All other imports load together without it.
- Its dependencies exist and use uncomplicated paths.
- It contains a unique empty-but-allocated geoset anomaly.
- The crash report is a null read, compatible with an unchecked empty mesh, index-buffer, or editor-selection structure.

The last point is an inference. Without Blizzard symbols or a fixed build comparison, it is not possible to prove which internal pointer is null. The repair should target the unique geoset anomaly first and then be validated empirically.

## Repairing or replacing AltarOfStorms.mdx

### Immediate containment

Until a repaired file passes validation:

1. Keep `war3campImported\AltarOfStorms.mdx` out of the working map.
2. Open the map while the model is absent; the missing asset is non-fatal.
3. Do not delete doodad type `D6NJ` or its eight placements merely to make the editor load.
4. If the area must be edited immediately, assign `D6NJ` a known-safe placeholder model in Object Editor.
5. Work from a fresh backup of the production map rather than promoting the isolation folder directly.

### Preferred Retera Model Studio repair

Retera Model Studio UI labels differ between releases, but the required structure edits are the same:

1. Copy `AltarOfStorms.mdx` outside the production map and preserve the original unchanged.
2. Open the copy in Retera Model Studio.
3. Save or export an MDL text copy for inspection as well as retaining an MDX working copy.
4. Open the model structure/geoset manager and count geosets from the top.
5. Select the **tenth geoset** in a one-based UI, which is zero-based geoset index 9.
6. Confirm that it has 13 vertices but no triangles/faces. In an MDL export, its Faces/Triangles section should contain no triangle indices.
7. Delete this empty geoset. Do not create arbitrary triangles merely to satisfy the format; the original topology is unknown.
8. Find and delete the geoset animation that targets this geoset. In the original file it is zero-based `GEOA` record 10 targeting `GeosetId 9`.
9. Check whether material 8 and its layer/texture are still used by another geoset. Remove them only if the editor proves they are orphaned; do not assume material and texture indices can be deleted safely.
10. Let the model editor reindex geoset-animation references after deletion, then verify that every remaining `GeosetId` is within the new geoset count.
11. Recalculate model and geoset extents if Retera exposes that operation.
12. Save as MDX version 800 under a new test filename such as `AltarOfStorms_fixed.mdx`.
13. Close and reopen the saved file in Retera Model Studio. This catches serialization failures before World Editor is involved.
14. Run the Hive Model Checker again and confirm that `Geoset 9: Zero faces` is gone.
15. Test this minimal repair in World Editor before addressing the three ordinary checker warnings. This preserves evidence that removing the empty geoset fixes the crash.
16. After the crash fix is confirmed, inspect geoset 6's duplicate geoset animations 0 and 7. Keep both if their color/alpha behavior is intentional; otherwise merge or remove the redundant record.
17. Add an Origin attachment point only if PotS effects or the desired model standard require one.
18. Add a Death sequence only if the doodad needs an animated death/removal state; do not fabricate one solely to silence the checker.

Using a new filename for the first test avoids confusing an editor or game asset cache with the old bytes.

### Alternative geometry reconstruction

Deleting the empty geoset is appropriate when it is an abandoned or unused mesh fragment. If visual comparison against the source model shows that geometry is actually missing, reconstruct it instead:

1. Obtain the original source model or an earlier working export.
2. Rebuild the intended triangles in a Warcraft-compatible model editor or Blender workflow.
3. Use only vertex indices `0-12` for this geoset and ensure the face-index count is a multiple of three.
4. Preserve matching normals, UV coordinates, vertex groups, matrix groups, material assignment, and extents.
5. Keep the geoset animation only if it still targets the reconstructed geoset correctly.
6. Export as MDX v800 and perform the same validation sequence as the deletion repair.

Do not hex-edit the face count alone. A proper removal changes nested `GEOS` sizes and requires deletion or reassignment of the related `GEOA` record. A partial binary edit can make the model more dangerous while appearing superficially valid.

If the source geometry cannot be recovered, replacing the visual model with a known-good equivalent is safer than inventing topology.

### Reimport and Object Editor follow-up

Test the repair without disturbing the existing object graph:

1. Import `AltarOfStorms_fixed.mdx` into a copy of the known-good test map.
2. Set custom doodad `D6NJ` to the exact temporary path `war3campImported\AltarOfStorms_fixed.mdx`.
3. Prefer an explicit `.mdx` Object Editor path during 3.0 testing instead of relying on `.mdl` to `.mdx` substitution.
4. Restart World Editor before the first load to avoid a cached copy of the crashing asset.
5. If the new file works, either:
   - replace the original import bytes while retaining `war3campImported\AltarOfStorms.mdx`, or
   - keep the new path and update the one `D6NJ` Object Editor reference.
6. Remove the obsolete import-manifest entry after deciding which path is canonical.

No JASS, GUI-trigger, or custom-text reference to the model path was found. The known functional dependency is the `D6NJ` doodad definition and its placed instances, so changing that one Object Editor path is considerably lower risk than a broad import-path rewrite.

### Repair validation checklist

- [ ] Retera Model Studio opens the repaired model.
- [ ] Retera Model Studio can save and reopen the repaired model.
- [ ] A structure scan reports no nonempty-vertex/zero-face geoset.
- [ ] Hive Model Checker no longer reports the severe `Geoset 9: Zero faces` result.
- [ ] The duplicate geoset-6 animation warning has been reviewed and documented as intentional or corrected.
- [ ] The missing Death sequence and Origin attachment warnings have been accepted for this static doodad or corrected deliberately.
- [ ] World Editor 3.0.0.24268 opens the full map with the repaired model present.
- [ ] World Editor can display and select all eight `D6NJ` placements.
- [ ] The model renders correctly in SD/Classic and the PotS target HD mode.
- [ ] Materials, alpha, shadows, team color, and selection behavior are visually correct.
- [ ] World Editor can save the map and reopen the saved result.
- [ ] The game client can load the map and enter the affected area.
- [ ] Multiplayer-sensitive full-map testing still passes.
- [ ] The final import table contains one canonical Altar model path and no temporary duplicate.

## Other malformed or suspicious imports that did not crash map loading

These findings should remain in the maintenance backlog. They are not cleared as healthy merely because World Editor tolerated them during this test.

### Malformed DNC light chunks

A strict top-level MDX scan found five malformed files, all under `Environment\DNC`:

| Model | File bytes | `LITE` offset | Declared `LITE` payload | `KLAC` offset | `PIVT` offset | Implied `LITE` payload |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `DNC\DNCAnimated2\DNCAnimated2_Darker2.mdx` | 900 | 548 | 180 | 736 | 880 | 324 |
| `DNC\DNCAnimated2\DNCAnimated2_Darker4.mdx` | 900 | 548 | 180 | 736 | 880 | 324 |
| `DNC\DNCAnimated2\DNCAnimated2_Darker5.mdx` | 900 | 548 | 180 | 736 | 880 | 324 |
| `DNC\DNCTests\DNCDarkNightsLordaeronTerrainFixed.mdx` | 1,556 | 548 | 180 | 736 | 1,536 | 980 |
| `DNC\DNCTests\DNCDarkNightsLordaeronUnitFixed.mdx` | 1,556 | 548 | 180 | 736 | 1,536 | 980 |

The `LITE` chunk declares only 180 bytes, causing its animated color track (`KLAC`) and subsequent data to be interpreted as top-level chunks by a strict parser. For the three 900-byte files, the declared size is short by 144 bytes. For the two 1,556-byte files, it is short by 800 bytes.

The complete `Environment` directory loaded successfully, so none of these files caused the investigated loading crash. They can still cause underlying lighting problems:

- animated light color or intensity tracks may be ignored or misread;
- HD and SD lighting may diverge;
- the new 3.0 Lighting Editor may normalize, reject, or alter the malformed records;
- later patches may enforce stricter parsing.

Repair these separately by opening and re-saving them through a structure-aware model editor, checking each light and its animation tracks, then testing the full day/night cycle in both editor and game. Preserve the originals because normalization may visibly change the intended custom DNC look.

### BLP mipmap tables extending past end of file

A BLP header scan found 236 BLP1 icons whose mip level 7 entry begins at the end of the file while declaring additional data beyond EOF:

- 118 files under `ReplaceableTextures\CommandButtons`.
- 118 matching files under `ReplaceableTextures\CommandButtonsDisabled`.

For example, `BTNAbility_Parry.blp` is 6,162 bytes but declares mip level 7 at offset 6,162 with another 325 bytes of data.

The complete `ReplaceableTextures` directory loaded successfully, so these malformed final-mip entries did not cause the World Editor load crash. Possible remaining effects include low-resolution icon corruption, bad sampling at small UI scales, warnings in stricter tools, or future parser incompatibility.

The correct repair is to re-encode the source images as valid BLP files with a complete mip chain, keeping enabled and disabled button pairs synchronized.

### Zero-byte assets

Six imported files are empty:

- `stormwind_safetybox.blp`
- `stranglebrownvine01_128.blp`
- `stranglevineset01.blp`
- `war3campImported\strangletree02_leaves.blp`
- `units\orc\KotoBeast\KodoDrum1.wav`
- `units\orc\KotoBeast\KodoDrum2.wav`

The full map loads with these files present. They remain invalid payloads and may cause missing textures, silent sounds, or tool warnings at runtime. Replace them with valid assets or remove both the files and all references after confirming they are unused.

### Multi-dot names and extension parsing

Warcraft III 3.0 community reports identified changed parsing for filenames containing a dot before the final extension. PotS contains relevant patterns, including `.wmo.mdx`, `.blp.blp`, `.alpha.blp`, `ocean_h.*.BLP`, and embedded multi-dot texture references in MDX files.

Removing the clearest physical multi-dot candidates did not change the crash. Later, the complete import set loaded with those files restored and only `AltarOfStorms.mdx` absent. Therefore:

- multi-dot parsing is a real 3.0 compatibility concern;
- it was not the cause of this World Editor loading crash;
- affected assets still require in-game visual validation because the reported failure can be silent or game-only.

Do not run a bulk renamer on the production map without a backup and a complete reference rewrite. Paths can exist in object data, skin data, imported models, FDF/TOC files, and JASS strings.

### Missing-model and doubled-extension warnings

`War3EditorLog.txt` lists many `Could not load file` messages, including `.mdl.mdl`, extensionless or `.mdl` model paths, and deliberately invisible placeholder models.

These messages were initially plausible leads. The final full-import test shows that they are not sufficient to cause the investigated crash. They should be audited by gameplay importance:

- intentional invisible models may remain as documented placeholders;
- accidental `.mdl.mdl` or missing-extension values should be corrected in Object Editor;
- paths that work in World Editor must also be tested in the game client under 3.0;
- changing a shared path requires checking units, doodads, items, destructibles, skins, and scripted effect creation.

### Unknown 3.0 data fields and custom SLKs

The editor log reports unknown database fields including:

- `occlusion` and `showAirToGround` in `Units/UnitUI.slk`;
- `equipment`, `tag`, `teamColor`, and `customTeamColor` in `Units/ItemData.slk`;
- `netsafe` in `UI/SkinMetaData.slk`.

Old 2018 SLK files and a suspicious root executable were backed up/renamed, followed by Battle.net Scan and Repair. The crash remained. Removing only custom SLKs from the test map also did not resolve it. The map now loads with its full asset set minus `AltarOfStorms.mdx` despite these warnings.

The warnings therefore belong to the separate 3.0 data migration investigation. They may affect visibility of new Object Editor fields or how old custom data overlays the 3.0 schema, but they were not the loading-crash trigger.

### Unusual compact and ABANDON-family models

Several `ABANDON`-related models and other unusually small MDX payloads use unconventional authoring techniques with much of the visual detail stored in large external textures. They appeared suspicious during the alphabetic bisection because groups containing them crashed.

Their smaller subgroups and eventually the complete `war3campImported` directory loaded when `AltarOfStorms.mdx` was absent. They are not confirmed crashers. They should still be checked for missing geometry, texture-path breakage, and HD/SD rendering differences rather than judged only by file size.

## Final known-good test state

The existing isolation map is:

`C:\Users\Valtteri\Documents\Warcraft III\Maps\EpicQuestsFolder40_test1\Epic Quests.w3x`

Its confirmed loading state is:

- all original import directories restored;
- all `war3campImported` files restored except `AltarOfStorms.mdx`;
- complete `Environment`, `war3mapImported`, and `ReplaceableTextures` directories present;
- all remaining directories restored together;
- World Editor 3.0.0.24268 loads the map.

Loading is the confirmed improvement and the boundary of this result. In the 15 September pass, scrolling through other inspected parts of the map did not crash the editor, but viewing the Crypt area containing the large imported dungeon doodads did. The editor is also noticeably heavier and less responsive than World Editor 2.x, although no controlled performance measurements have been taken. These remaining symptoms could come from the structurally suspect Crypt imports, from the 3.0 renderer/editor itself, or from an interaction between them.

The test copy also contains 87 extra root-level BLP files that are byte-identical duplicates of files under `war3campImported`. These were introduced during isolation and are tolerated, but they change import-path state. Do not use this test folder as the production repair without removing the duplicates or starting from a clean map backup.

## Open follow-up: unexpected viewport inspection crash

**Status:** Open; narrowed to the Crypt area and prioritized models, but not yet isolated to one rawcode.

After the initial map-loading blocker is removed, World Editor can still crash unexpectedly while inspecting or moving around the loaded map. The 15 September recheck scrolled through other areas without a crash and then reproduced the failure when the viewport reached the large Crypt-related doodads. This makes the Crypt a strong area-level correlation, although the trigger has not been reproduced down to one object.

A plausible working hypothesis is that World Editor 3.0 initially accepts the import table and map data, then fails later when a particular placed asset must be decoded, instantiated, rendered, animated, selected, or included in editor lighting. This would explain why the complete import set can pass map loading while viewport movement still exposes another problem. It remains only a hypothesis until a specific asset or editor operation controls the result.

Possible trigger classes include:

- another malformed MDX/MDL structure that the initial loader tolerates;
- invalid or unusual geoset, material, texture, particle, ribbon, attachment, light, or animation data;
- an extreme or invalid model extent that affects culling or selection;
- a missing or malformed texture loaded only when its model becomes visible;
- a placed doodad/destructible using a path that resolves differently under 3.0;
- a custom DNC/light model interacting with the new 3.0 lighting pipeline;
- editor memory, rendering, or performance regression independent of the map assets;
- an interaction between a tolerated asset defect and the new editor renderer.

The existing malformed DNC models, BLP mip tables, zero-byte assets, and Model Checker warnings are leads, not confirmed causes of this second crash.

### Crypt doodad audit findings

The separate [`Crypt Doodad Model Audit.md`](<Crypt Doodad Model Audit.md>) resolves the Crypt rectangle's 486 placed doodads/destructables, all 19 Crypt-named Object Editor definitions, and the 18 unique Crypt MDX files. Its most important findings are:

- five Crypt-shell rawcodes place 12 large imported models inside `gg_rct_DungeonCrypt`;
- `D05P` (`md_cryptsimpleent2.mdx`) has zero-face geoset 9 and is placed three times at scale 2.91;
- `D06W` (`...northrend4d.wmo.mdx`) has zero-face geoset 14 and is placed once at scale 2.00;
- `D06Y` (`...northrend4e2.wmo.mdx`) has only a 5,281-unit visual span but inherits a 21,700-unit three-box collision envelope and is placed at scale 2.00;
- both `D06W` and `D06Y` therefore expose a collision span of roughly 43,400 world units after placement scaling;
- 11 of the 18 unique Crypt-named models contain at least one zero-face geoset;
- every Crypt-named model carries a generated portrait camera and one of two repeated three-box collision templates, consistent with unspecialized converter output;
- the five placed Crypt-shell models have all referenced textures present, so missing texture payloads are not the leading explanation for this area crash.

These are concrete model defects and strong isolation candidates. They are not yet a causal singleton result: the next decisive test is to replace `D05P`, `D06W`, and `D06Y` with a safe placeholder, then restore them one at a time.

For every new occurrence, capture the following before changing imports:

1. New Blizzard crash-report directory, including `Crash.txt`, `War3.dmp`, and `War3EditorLog.txt`.
2. Approximate camera location, named area, and viewing direction.
3. Whether the camera moved, zoomed, rotated, selected an object, changed tileset/light settings, or merely remained idle.
4. Active graphics mode and editor options, especially HD/SD mode, shadows, fog, water, lighting preview, and draw distance.
5. The last visible or selected doodad, destructible, unit, effect, or terrain feature.
6. Whether the same camera approach reproduces the crash after restarting World Editor.

Suggested isolation procedure:

1. Start from the full known-good loading state with `AltarOfStorms.mdx` absent.
2. Save a camera near—but not looking directly into—the suspected area.
3. Approach the area repeatedly from controlled directions with identical editor graphics settings.
4. Determine whether the crash depends on entering visibility range, selecting something, enabling lighting/shadows, or elapsed editor time.
5. Inventory placed object rawcodes within the suspect camera bounds and resolve each rawcode to its model and texture paths.
6. Replace suspect area models with a known-safe placeholder in groups, preserving placed objects and transforms.
7. Bisect only the group whose replacement prevents the crash.
8. Reintroduce the final suspect model alone and inspect it with Hive Model Checker and a binary structure scan.
9. Repeat in SD and HD to separate general model parsing from renderer-specific behavior.
10. Compare each new crash signature with the five existing null-read reports. A different instruction stack should be tracked as a separate defect even if Windows displays the same 16-bit dialog.

Until this work is complete, “map loads” should be understood to mean that World Editor reaches the editable map view. It does not yet mean that all areas can be viewed or edited reliably.

## Recommendations

1. Keep `AltarOfStorms.mdx` quarantined until a repaired or replacement model passes the checklist.
2. Repair the empty geoset first; it is the unique structural anomaly most strongly correlated with the crash.
3. Test the repair under a new filename, then restore the canonical path only after a clean editor restart and save/reopen cycle.
4. Verify all eight `D6NJ` doodad placements visually.
5. Do not bulk-rename imports solely to solve this incident; multi-dot paths are a separate compatibility project.
6. Audit and normalize the five malformed DNC light models before relying heavily on the 3.0 Lighting Editor.
7. Re-encode the 236 malformed BLP icon pairs as a lower-priority asset-health task.
8. Replace or remove the six zero-byte assets after resolving their references.
9. Follow the Crypt audit's placeholder order: test `D05P`, `D06W`, and `D06Y` first, then `D040` and `D043`, before expanding to transparent effects and other converted props.
10. Compare World Editor 3.0 and 2.x responsiveness using the same map, camera location, graphics mode, draw distance, and visible-object set before attributing all lag to the map imports.
11. Recheck the map after Blizzard hotfixes because stricter or corrected asset parsing may change which tolerated defects become visible.
12. Retain this report, the Crypt doodad audit, and all five crash bundles with the map version so later failures can be compared by build, stage, and singleton-file reproduction.

## Future import-crash triage procedure

For a future World Editor crash during folder-map loading:

1. Duplicate the map folder; never destructively test the only copy.
2. Record Warcraft build, map version, exact failure stage, and crash bundle.
3. Verify a small/no-import map under the same editor installation.
4. Retain `war3map.imp` and remove payload files first. This separates manifest parsing from asset parsing.
5. Restore root imports, then top-level directories.
6. Split a crashing directory by file type, prioritizing MDX/MDL, BLP/DDS/TGA, FDF/TOC, sound, and SLK.
7. Bisect a crashing type group alphabetically until one file remains.
8. Reintroduce that file alone to reproduce the crash.
9. Restore every other import simultaneously while keeping only the singleton absent.
10. Compare the singleton against all same-version assets for unique structural traits.
11. Search object data and scripts for every reference before renaming or replacing it.
12. Validate editor load, save/reopen, game load, rendering modes, and multiplayer-sensitive behavior independently.

The critical discipline is to keep “malformed” separate from “caused this crash.” Warcraft III has historically tolerated many imperfect assets, and a patch can change which defect becomes fatal.

## Evidence and related reports

Local evidence:

- [`2026-09-13 12.50.37 e5c597cc`](<2026-09-13 12.50.37 e5c597cc/>)
- [`2026-09-13 13.24.40 a5aec748`](<2026-09-13 13.24.40 a5aec748/>)
- [`2026-09-13 14.49.49 40679a7c`](<2026-09-13 14.49.49 40679a7c/>)
- [`2026-09-14 01.42.46 4b9a5dd4`](<2026-09-14 01.42.46 4b9a5dd4/>)
- [`2026-09-15 19.05.49 2b228384`](<2026-09-15 19.05.49 2b228384/>)
- [`Crypt Doodad Model Audit.md`](<Crypt Doodad Model Audit.md>)

External context:

- [Official Warcraft III: Reforged Forsaken Kingdom patch notes](https://us.forums.blizzard.com/en/warcraft3/t/warcraft-iii-reforged-forsaken-kingdom-patch-notes/38400)
- [Hive: Warcraft III 3.0 bugs and issues](https://www.hiveworkshop.com/threads/warcraft-iii-3-0-bugs-issues.374131/)
- [Hive: custom models visible in editor but not in game after 3.0](https://www.hiveworkshop.com/threads/custom-models-show-up-in-editor-but-not-in-game-after-updating-to-3-0.374120/#post-3737812)
- [Hive: file-extension parsing logic changed in 3.0](https://www.hiveworkshop.com/threads/file-extension-parsing-logic-changed-in-version-3-0-%E2%80%94-causing-model-texture-recognition-errors.374128/)
- [Hive: Import Fixer for Reforged 3.00's Multi-Dot Bug](https://www.hiveworkshop.com/threads/import-fixer-for-reforged-3-00s-multi-dot-bug.374159/)
- [Hive: older Unsupported 16-bit Application report](https://www.hiveworkshop.com/threads/wc3-map-editor-unsupported-16-bit-application.353700/)

The Hive links are community reports and tools, not authoritative proof of the PotS crash mechanism. The PotS conclusion comes from the local controlled isolation tests and binary inspection described above.
