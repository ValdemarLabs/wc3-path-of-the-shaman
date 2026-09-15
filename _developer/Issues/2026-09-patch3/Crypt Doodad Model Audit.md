# Crypt Doodad Model Audit

## Table of contents

- [Purpose and status](#purpose-and-status)
- [Crash evidence](#crash-evidence)
- [Audit scope and method](#audit-scope-and-method)
- [Primary Crypt-shell doodads placed in the zone](#primary-crypt-shell-doodads-placed-in-the-zone)
- [Findings shared by the Crypt model family](#findings-shared-by-the-crypt-model-family)
  - [Oversized and copied collision boxes](#oversized-and-copied-collision-boxes)
  - [Zero-face geosets](#zero-face-geosets)
  - [Community corroboration](#community-corroboration)
  - [Extents and rendering workload](#extents-and-rendering-workload)
  - [Textures, sequences, cameras, and attachment points](#textures-sequences-cameras-and-attachment-points)
- [Complete Crypt-named doodad and model list](#complete-crypt-named-doodad-and-model-list)
- [Other placed doodads in the Crypt rectangle](#other-placed-doodads-in-the-crypt-rectangle)
- [Risk ranking and isolation order](#risk-ranking-and-isolation-order)
- [Repair procedure](#repair-procedure)
- [Validation matrix](#validation-matrix)
- [Conclusions and limits](#conclusions-and-limits)

## Purpose and status

This document tracks the second World Editor 3.0.0.24268 problem found after the initial `AltarOfStorms.mdx` loading crash was isolated. The map now reaches the editable view when that model is absent, but moving the viewport into the large Crypt dungeon scenery can still crash World Editor.

On 15 September 2026, scrolling through other inspected areas did not reproduce the crash. Viewing the Crypt area containing the large Crypt-related doodads did. The same area could lag unpredictably in World Editor 2.x, sometimes apparently varying with Warcraft III's CPU-core scheduling. That older lag is important historical evidence: the Crypt assets had an existing culling, selection, collision, geometry, or rendering cost before 3.0, while 3.0 appears less tolerant of it.

**Current status:** the area is reproducible enough to prioritize its assets, but no single Crypt model has yet been proven by removal/reintroduction to cause the viewport crash. The findings below identify two models with a community-corroborated Warcraft III 3.0 crash defect and one additional severe collision-envelope candidate for controlled isolation.

## Crash evidence

The latest evidence bundle is [`2026-09-15 19.05.49 2b228384`](<2026-09-15 19.05.49 2b228384/>).

| Property | Result |
| --- | --- |
| Warcraft III / World Editor | 3.0.0.24268 |
| Process | `_retail_\x86_64\World Editor.exe` |
| Failure | Null-address read `ACCESS_VIOLATION` |
| Fault instruction | `0x00007FF7F12D240B` |
| First call-chain entries | `F12D240B <- F12191C4 <- F12149F4` |
| Map opened in log | `EpicQuestsFolder40_test1\Epic Quests.w3x` |
| Reported editor action | Viewport movement into the Crypt scenery |

After subtracting the relocated World Editor module base, the faulting function offsets and first call-chain offsets are `0x55240B <- 0x4991C4 <- 0x4949F4`, matching all four earlier load-stage crash reports exactly. This strongly indicates the same internal World Editor code-path family, plausibly model creation or editor rendering, was reached during a different stage. Symbols are unavailable, so the function's exact responsibility remains unknown.

`War3EditorLog.txt` records the map opening at 17:51 and again at 17:56. It contains the already known missing-model messages, including the deliberately absent `war3campImported\AltarOfStorms.mdl`, but it records no Crypt model name immediately before the 19:05 crash. The log therefore does not identify the viewport offender.

The fact that `AltarOfStorms.mdx` was absent while this crash occurred establishes that this is a second trigger or a broader model-path defect, not merely another observation of the original file being loaded.

## Audit scope and method

The static inventory was read from the folder map:

`C:\Users\Valtteri\Documents\Warcraft III\Maps\EpicQuestsFolder40\Epic Quests.w3x`

The viewport crash was recorded against the `_test1` copy. The audit assumes its `war3map.doo`, `war3map.w3d`, and Crypt imports still match the source folder map. Regenerate this inventory if placements or Object Editor data are changed.

The Crypt dungeon rectangle is `gg_rct_DungeonCrypt`:

| Bound | Coordinate |
| --- | ---: |
| Minimum X | -3840 |
| Maximum X | 13056 |
| Minimum Y | -32256 |
| Maximum Y | -24032 |

The version-8 `war3map.doo` contains 486 doodad/destructable placements inside those bounds. Object definitions were resolved through `war3map.w3d` and `war3map.wts`. Imported MDX files were checked locally for:

- valid `MDLX` magic and top-level chunk boundaries;
- MDX version, file size, sequences, texture records, and dependencies;
- model extents and bounding radius;
- geoset vertex/index counts, including zero-face geosets;
- generated cameras and collision-shape chunks;
- collision-box coordinates compared with each model's own visual extents.

This is a structural audit, not a replacement for Hive Model Checker, Retera Model Studio inspection, or a controlled World Editor removal test.

## Primary Crypt-shell doodads placed in the zone

Only five Crypt-named custom doodad types are placed inside `gg_rct_DungeonCrypt`. Together they account for 12 large shell placements.

| Priority | Rawcode | Crypt placements | Placed scale | Model | Primary findings |
| --- | --- | ---: | ---: | --- | --- |
| **P0** | `D05P` | 3 | 2.91 | `md_cryptsimpleent2.mdx` | Geoset 9 has 12 vertices and zero face indices; copied three-box collision envelope is larger and offset from this split mesh; no `Origin` node. |
| **P0** | `D06W` | 1 | 2.00 | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo.mdx` | Geoset 14 has two vertices and zero face indices; 11,648-unit visual span but inherited 21,700-unit collision span; scaled collision span is about 43,400 world units. |
| **P0** | `D06Y` | 1 | 2.00 | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e2.wmo.mdx` | No zero-face geoset, but only a 5,281-unit visual span with the same inherited 21,700-unit collision span; scaled collision span is about 43,400 world units. |
| **P1** | `D043` | 2 | 1.75 | `world_wmo_dungeon_md_cryptsimpleent_md_cryptsimpleent.wmo.mdx` | Large 38-geoset/192.2 KiB shell; three collision boxes; no zero-face geoset found. One additional copy exists elsewhere in the map. |
| **P1** | `D040` | 5 | 1.84-2.21 | `md_cryptsimpleent_part1.mdx` | Six-geoset shell; three collision boxes; no zero-face geoset found. |

The `D06W` and `D06Y` collision envelope is wider than the entire 16,896-unit Crypt rectangle before placement scaling. At scale 2.00 it spans roughly 43,400 units, which is large enough to affect selection, hit testing, visibility/culling, and editor work far from the visible mesh. This matches the old observation that Crypt assets could be clickable or cause lag far away from their apparent geometry.

## Findings shared by the Crypt model family

### Oversized and copied collision boxes

All 18 unique Crypt-named MDX files contain:

- a 120-byte generated camera named `Portrait_Camera_generated`;
- a 372-byte `CLID` chunk;
- three boxes named `Collision Box01`, `Collision Box02`, and `Collision Box03`.

The simple-entrance family shares the same three-box envelope:

`(-1216, -1930, -1164) .. (1065, 464, 232)`

The Northrend/WMO family shares this much larger envelope:

`(-15830, -15873, -2645) .. (5870, 516, 905)`

The repeated coordinates show that split/subset models retained collision geometry from a larger source model instead of receiving collision fitted to each exported piece. The most extreme placed mismatch is `D06Y`: its collision span is about 4.1 times its visual-model span before the Object Editor placement scale is applied.

This is a strong explanation for the historical far-away selection/collision and lag. It is also a plausible contributor to the 3.0 viewport crash, but it is not yet proven as the null-read cause.

### Zero-face geosets

The local scan found zero-face geosets in 11 of the 18 unique Crypt-named files:

| Model | Zero-based zero-face geosets | Placed in Crypt |
| --- | --- | --- |
| `md_cryptsimpleent1.mdx` | 9 | No |
| `md_cryptsimpleent2.mdx` | 9 | **Yes: `D05P`, three copies** |
| `md_cryptsimpleent3.mdx` | 9 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx` | 18, 19 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend3.wmo.mdx` | 24, 25, 26 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx` | 27, 28, 40 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a1.wmo.mdx` | 27, 28, 40 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a2.wmo.mdx` | 0, 1, 2, 3, 4, 5, 15, 16, 28 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4b.wmo.mdx` | 27, 28, 40 | No |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo.mdx` | 14 | **Yes: `D06W`, one copy** |
| `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4f.wmo.mdx` | 18, 19, 21, 22 | No |

A subsequent full-map scan covered all 479 v1000 and both v1100 MDX imports. It found 31 vertices-without-faces geosets in 11 files, and every result is one of the Crypt models in this table. There are no unrelated v1000/v1100 matches elsewhere in the map. Together with the single affected v800 file, `AltarOfStorms.mdx`, the complete PotS total is 12 affected MDX files and 32 affected geosets out of 2,431 MDX imports.

These Crypt files are MDX v1000 and do not contain a `GEOA` chunk, so the empty geosets are not referenced by geoset-animation records in the same way as the confirmed `AltarOfStorms.mdx` defect. Even so, a declared geoset with vertices or other mesh records but zero face indices is now a community-reproduced Warcraft III 3.0 crash condition. `D05P` and `D06W` should be treated as the first two geometry-isolation candidates because they are the affected members actually placed in the crashing Crypt rectangle.

### Community corroboration

Hive Workshop user Achille reports that maps from multiple creators began crashing World Editor after Warcraft III 3.0 when models contained geosets with vertices but no faces/triangles. Deleting the matching geosets allowed the same models to render and stopped the startup crashes. See [Achille's report](https://www.hiveworkshop.com/threads/warcraft-iii-3-0-bugs-issues.374131/#post-3738985).

This independently validates the zero-face structure as a post-3.0 crash trigger class. The full-map scan further shows that every remaining PotS example beyond `AltarOfStorms.mdx` belongs to this Crypt model family. It substantially raises the priority of placed `D05P` and `D06W`, but does not by itself prove which one controls the Crypt viewport crash. It also does not validate the separate collision-box hypothesis for `D06Y`.

### Extents and rendering workload

The most concerning model-level extents are:

| Model family/member | Bounding radius | Largest axis span | Assessment |
| --- | ---: | ---: | --- |
| `northrend2`, `northrend3`, `northrend4a`, `northrend4b`, `northrend4c`, `northrend4e` | 19,555 | 21,710 | Full-parent WMO extents; extremely large. |
| `northrend4a1`, `northrend4a2`, `northrend4d` | 7,777 | 11,648 | Large subset extents; collision remains 21,700. |
| `northrend2b` | 4,990 | 8,720 | Subset extent; collision remains 21,700. |
| `northrend4e2`, `northrend4f` | about 3,420 | 5,281 | Small subsets with the full 21,700 collision envelope. |
| Simple-entrance family | 1,885-2,261 | 2,009-2,394 | Moderate alone, but several copies are scaled to 1.75-2.91. |

Some members are not currently placed, so large extents alone cannot explain this specific viewport crash. The placed `D06W` and `D06Y` members remain high risk because their Object Editor scale doubles already excessive collision dimensions.

### Textures, sequences, cameras, and attachment points

- All 18 models have valid top-level chunk boundaries and are not simply truncated files.
- All are MDX version 1000 and declare `Stand 1` and `Death 1` sequences.
- Every texture referenced by the five placed Crypt-shell models exists in the folder map.
- The unplaced `northrend2` model references one texture absent from the folder map: `wow\dungeons\textures\decoration\mm_wroughtiron_01.blp`. It may resolve from game data, but should be imported or corrected before using that model.
- No member contains an `Origin`-named node. This is normally a warning/cleanup item for static scenery, not proof of a crash.
- Every member contains the same generated portrait camera and one of two repeated three-box collision templates. These are characteristic converter/export residue and should be reviewed rather than assumed intentional.

## Complete Crypt-named doodad and model list

This list covers every custom doodad definition whose `dfil` model path contains `crypt`. The table distinguishes definitions from actual placements.

| Rawcode | Model | Map placements | In Crypt rect | Zero-face geosets | Radius / max span | Collision span | Notes |
| --- | --- | ---: | ---: | --- | --- | ---: | --- |
| `D040` | `md_cryptsimpleent_part1.mdx` | 5 | 5 | None | 2,261 / 2,394 | 2,394 | Placed P1. |
| `D041` | `md_cryptsimpleent_part2.mdx` | 1 | 0 | None | 2,261 / 2,394 | 2,394 | Defined and used outside Crypt. |
| `D042` | `md_cryptsimpleent1.mdx` | 0 | 0 | 9 | 2,261 / 2,394 | 2,394 | Unplaced; structurally suspect. |
| `D043` | `world_wmo_dungeon_md_cryptsimpleent_md_cryptsimpleent.wmo.mdx` | 3 | 2 | None | 2,261 / 2,394 | 2,394 | Placed P1; 38 geosets. |
| `D05L` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx` | 0 | 0 | 18, 19 | 19,555 / 21,710 | 21,700 | Missing one map texture; unplaced. |
| `D05M` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend3.wmo.mdx` | 0 | 0 | 24, 25, 26 | 19,555 / 21,710 | 21,700 | 875.9 KiB; unplaced. |
| `D05N` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx` | 0 | 0 | 27, 28, 40 | 19,555 / 21,710 | 21,700 | Unplaced. |
| `D05O` | `md_cryptsimpleent1.mdx` | 0 | 0 | 9 | 2,261 / 2,394 | 2,394 | Second definition for same suspect file. |
| `D05P` | `md_cryptsimpleent2.mdx` | 3 | 3 | 9 | 1,885 / 2,009 | 2,394 | **Placed P0; scale 2.91.** |
| `D05Q` | `md_cryptsimpleent3.mdx` | 0 | 0 | 9 | 2,261 / 2,394 | 2,394 | Unplaced. |
| `D06P` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo.mdx` | 2 | 0 | None | 4,990 / 8,720 | 21,700 | Used elsewhere; large collision mismatch. |
| `D06U` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4b.wmo.mdx` | 0 | 0 | 27, 28, 40 | 19,555 / 21,710 | 21,700 | Unplaced. |
| `D06V` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4c.wmo.mdx` | 0 | 0 | None | 19,555 / 21,710 | 21,700 | Unplaced. |
| `D06W` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo.mdx` | 1 | 1 | 14 | 7,777 / 11,648 | 21,700 | **Placed P0; scale 2.00.** |
| `D06X` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e.wmo.mdx` | 0 | 0 | None | 19,555 / 21,710 | 21,700 | Unplaced. |
| `D06Y` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e2.wmo.mdx` | 1 | 1 | None | 3,418 / 5,281 | 21,700 | **Placed P0; scale 2.00; worst placed collision mismatch.** |
| `D06Z` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a1.wmo.mdx` | 0 | 0 | 27, 28, 40 | 7,777 / 11,648 | 21,700 | Unplaced. |
| `D070` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a2.wmo.mdx` | 0 | 0 | 0-5, 15, 16, 28 | 7,777 / 11,648 | 21,700 | Nine empty geosets; unplaced. |
| `D071` | `world_wmo_dungeon_md_crypt_md_crypt_f_northrend4f.wmo.mdx` | 0 | 0 | 18, 19, 21, 22 | 3,427 / 5,281 | 21,700 | Unplaced. |

## Other placed doodads in the Crypt rectangle

The remaining area inventory should be retained for the second isolation pass. Counts below are within `gg_rct_DungeonCrypt`.

| Category | Rawcode and count | Model/path note |
| --- | --- | --- |
| Pathing/blockers | `B00I` x174, `YTpb` x147 | `B00I` is custom `Pathing Blocker (Ground) 2x8`; `YTpb` is the standard ground pathing blocker. They dominate placement count but are not the visible large Crypt shells. |
| Visual block walls/fog | `D678` x37, `D63A` x18, `D03X` x1, `D0CE` x1, `D637` x1 | `BlockWall01.mdx` reaches scale 10; `EerieFog.mdx` reaches scale 4.65; also `Cloud-blend.mdx`, `Visual\VisualBlocker_black3.mdx`, and `Glow.mdx`. Test after the shell P0 group. |
| Green magma effects | `D01N` x15, `D01L` x11 | `Magma River Green.mdx` at scale 2.70 and `Magma Fall Green.mdx` at scale 1.80-3.00. These can impose transparent/animated rendering cost. |
| Webs | `D01A` x2, `D01B` x2, `D01C` x3, `D01D` x1, `D01E` x1 | `war3mapImported\od_web5X.mdx` through `od_web1.mdx`; large scales around 2.30-4.77. |
| Crypt props | `D059` x4, `D05A` x1, `D04K` x1, `D04Q` x1, `D04S` x1, `D04T` x2, `D04W` x1, `D044` x1, `D045` x2, `D046` x1, `D048` x1, `D0BU` x3 | Coffins, bookshelf, candles/rugs, gates, rubble, spirits, and stairs. Individually lower priority, but they use converted WoW models and textures. |
| Undead/Nerubian props | `D6A2` x3, `D6AB` x1, `D6B9` x2, `D6BA` x4, `D6BB` x2, `D6BC` x2, `D6BE` x1 | Nerubian tower, torch, floor spikes, bone piles, and ziggurat altar. `D6A2` has a 3,803-unit radius and 6,452-unit vertical span; check it if shell isolation fails. |
| Other structures/effects | `D08W` x1, `D076` x1, `D62D` x1, `D62E` x1 | Broken Worgen wall, arcane portal, and two boulders. |
| Stock/inherited doodads | `YOgr` x4, `NOok` x4, `GSp9` x2, `GSp0` x2, `LOgr` x2, `AObr` x1; custom `D03V` x1 and `D03W` x1 inherit `GSp0` | Lower priority unless the crash remains after all imported shell/effect models are replaced. |

This table deliberately keeps malformed/tolerated imports separate from proven crash causes. None of these secondary models has yet controlled the crash outcome.

## Risk ranking and isolation order

Use safe placeholder substitution in Object Editor so placed transforms and rawcodes remain intact.

1. Replace `D05P`, `D06W`, and `D06Y` together with one known-safe low-poly model. These cover both placed zero-face meshes and the two 43,400-unit scaled collision envelopes.
2. If the area becomes stable, restore one rawcode at a time in this order: `D06Y`, `D06W`, `D05P`. Test multiple clean editor restarts per model.
3. If the crash remains, also replace `D040` and `D043` to remove the entire Crypt-named shell family from the viewport.
4. Next replace `D6A2`, then the transparency/effect group `D678`, `D63A`, `D03X`, `D01N`, and `D01L`.
5. Then test the remaining WoW-prop group and the Undead/Nerubian prop group in halves.
6. Test `B00I` and `YTpb` only after visible models are cleared; their high instance count can affect editor responsiveness even though they are not the prominent scenery.
7. Repeat the controlling test in SD and HD, with shadows, fog, and lighting preview independently disabled/enabled.

Do not delete the import files during this viewport isolation. Removing a file changes loader behavior globally and can hide which placed rawcode is responsible. Placeholder substitution gives a cleaner area-level test.

## Repair procedure

For each model that controls the crash or remains structurally suspect:

1. Preserve the original file and import path in a backup.
2. Open a copy in Retera Model Studio and export an MDL text copy for review.
3. For `D05P`, remove zero-based geoset 9. For `D06W`, remove zero-based geoset 14. Confirm the target has zero triangle/face indices before deletion.
4. For other files, remove only the zero-face geosets listed in the complete table. These models have no `GEOA` chunk, but still check for any material, bone, or other references before saving.
5. Inspect `Collision Box01` through `Collision Box03`. Delete the inherited source-WMO boxes and create collision fitted to the actual exported piece, or omit collision shapes if the doodad's Object Editor pathing and editor selection remain acceptable without them.
6. Recalculate model extents and both `Stand 1` and `Death 1` sequence extents from the surviving geometry. Do not retain the parent WMO's bounds on a split model.
7. Remove `Portrait_Camera_generated` if the scenery model is never used for portraits or previews that require it.
8. Add an `Origin` attachment only if downstream attachments or tooling need it; it is not the first crash repair target.
9. Keep MDX v1000 for the first normalized test. A v800 conversion should be a separate A/B test because changing both structure and format at once obscures the cause.
10. Save under a temporary import name, point only one duplicated test doodad type to it, and run the validation matrix before replacing the canonical file.

For `northrend2`, also import or correct `wow\dungeons\textures\decoration\mm_wroughtiron_01.blp` before placing the model.

## Validation matrix

For every isolated or repaired candidate, record:

| Test | Required result |
| --- | --- |
| Hive Model Checker | No zero-face geosets or severe warnings. Record ordinary warnings rather than silently ignoring them. |
| Retera Model Studio | Model opens, each animation can be selected, and no orphaned geoset/material/bone references remain. |
| Clean World Editor start | Test map loads with `AltarOfStorms.mdx` still absent. |
| Controlled camera approach | Enter the Crypt view from the same direction at least five times without a crash. |
| Selection/hit testing | Doodad can be selected only near its visible mesh; no far-away invisible selection volume remains. |
| Editor responsiveness | Pan, rotate, zoom, and select around the Crypt without the previous large hitch. |
| SD and HD | Repeat in both modes. |
| Lighting variants | Repeat with shadows, fog, and lighting preview toggled independently. |
| Save/reopen | Save the disposable test map, close the editor, reopen, and revisit the area. |
| Game client | Load and traverse the dungeon; verify walls, ceilings, pathing, occlusion, and death/stand animation behavior. |

## Conclusions and limits

The current strongest candidates are not merely “large custom imports.” Two placed models contain the now independently corroborated post-3.0 crash defect of vertices without faces, and two placed WMO subsets carry a 21,700-unit collision envelope that becomes about 43,400 units after their scale-2 placements. Those are concrete structural defects consistent with the Crypt's old lag, far-away collision/selection reports, and its new 3.0 viewport instability.

The evidence does **not** yet establish which single model causes the crash. The decisive next result must be a controlled Object Editor placeholder test where removing one rawcode/model family from the rendered area changes the outcome. Until that test is complete, the zero-face meshes, inherited collision boxes, large extents, transparent effects, and World Editor 3.0 renderer regression remain interacting candidates rather than a proven singleton cause.
