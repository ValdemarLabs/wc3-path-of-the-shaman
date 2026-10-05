# WC3 Rebirth DE Conversion

## Purpose and current status

This project ports WC3 Rebirth to Warcraft III Definitive Edition (DE) without disabling DE renderer features such as the newer shadow system. Rebirth remains the visual foundation of Path of the Shaman, while the compatibility work adapts its legacy assets and data paths to Warcraft III 3.0.0.24268.

> **Work-in-progress status:** The DE conversion and its installation architecture are under active development. The generated packages are suitable for controlled testing, but the final installer-managed distribution, runtime validation, and conversion of PotS-imported SD models are not complete.

The project currently produces two copy-ready runtime trees:

```text
_WC3Rebirth\Assets\PotS_DE\WC3Rebirth_DE\       Baseline package with SD-origin models
_WC3Rebirth\Assets\PotS_DE\WC3Rebirth_DE_Full\  Combined package with converted HD/DE models
```

Use `WC3Rebirth_DE_Full` when testing or installing WC3 Rebirth DE with the converted models. Copy the **contents** of that directory into Warcraft III's `_retail_` directory; do not copy `WC3Rebirth_DE_Full` itself as an extra nested folder.

`WC3Rebirth_DE` remains the self-contained baseline and the read-only input to the model conversion. `WC3Rebirth_DE_Full` applies `WC3Rebirth_DEModels` over that baseline so all 1,521 MDX collisions resolve to the converted version and all generated TIF material resources are included. Neither package requires a separate Rebirth installation first.

Current generated baseline package:

| Property | Result |
|---|---:|
| Package files | 5,719 |
| Package size | 4,825,839,069 bytes |
| MDX models | 1,521 |
| Target Warcraft build | 3.0.0.24268 |
| Root layout | Direct `_retail_` loose-file paths |

Current generated full package:

| Property | Result |
|---|---:|
| Runtime files | 16,677 |
| Package size | 10,725,509,519 bytes |
| Converted MDX models | 1,521 |
| Generated TIF resources | 10,958 |
| MDX version | 1000 |
| Root layout | Direct `_retail_` loose-file paths |

All package-layer, critical-table, MDX-header, layout, and SHA-256 manifest checks pass. Runtime testing has confirmed that Rebirth units load in DE, Ashenvale Grass and Lumpy Grass use the intended Rebirth art, cliffs use the correct tileset art without the camera-angle white-face defect, and Sunken Ruins Sand blends without the earlier repeated seams. The subsequent 296-file ground-material neutralization passes static validation but still needs a World Editor retest across representative tilesets. Six diffuse-atlas remaps for Dalaran Ruins Black Marble, Dungeon Square Tiles, Sunken Ruins Rough Dirt, and Cityscape White Marble, Brick Tiles, and Round Tiles also pass static validation and need the same runtime retest.

The manual copy workflow below remains the development and validation path. The intended player-facing release flow is an installer that owns and manages WC3 Rebirth DE and external PotS assets as separately maintainable components.

## Clean installation

1. Use Warcraft III 3.0.0.24268. A newer build requires re-extracting Blizzard references and regenerating the package.
2. Enable Warcraft III `Allow Local Files`.
3. Close World Editor and Warcraft III completely.
4. Back up the existing `_retail_` directory's loose mod files.
5. For the cleanest validation, use a fresh Warcraft III installation. If SD Rebirth is already installed, move or remove only known Rebirth-owned loose files before installing the full package. Do **not** delete the entire `_retail_` directory: it also contains Warcraft executables, game data, and potentially unrelated mods. Copying the full package will replace all 1,521 known Rebirth model paths, but it cannot remove unknown stale files from an older or modified installation.
6. Copy everything inside:

   ```text
   H:\Pelit\PotS_JASS\_WC3Rebirth\Assets\PotS_DE\WC3Rebirth_DE_Full
   ```

   into:

   ```text
   C:\Program Files (x86)\Warcraft III\_retail_
   ```

7. Allow replacement of existing files.
8. Restart World Editor and select Definitive Edition graphics.

Copying this package over an existing installation overwrites every path owned by the package, including the corrected DE terrain and data files. It cannot remove unrelated loose files from other mods that are not part of WC3 Rebirth. A fresh or deliberately cleaned test installation is therefore the only way to prove that no unrelated leftovers affect the result.

The obsolete `_retail_\_DE.w3mod` test folder is not used. Warcraft ignores that loose disk folder for this purpose. It may be removed only if it was created solely by an earlier PotS_DE test and contains no unrelated files.

## Package composition

The package builder applies three layers in this exact order:

| Order | Layer | Source files selected | Purpose |
|---:|---|---:|---|
| 1 | Rebirth 9th Release runtime | 5,112 | Original models, textures, terrain sources, and legacy runtime data |
| 2 | `FixesLast2023` runtime | 8 | Final original-Rebirth corrections |
| 3 | PotS DE compatibility overlay | 1,924 | DE path conversions, neutral terrain materials, current data tables, model fixes, and selected community Reforged edits |

The DE overlay overwrites 1,325 paths from earlier layers. The final package has 5,719 unique files rather than the sum of all three input counts.

`WC3Rebirth_DE_Full` adds the converted-model tree as a fourth runtime layer. It replaces exactly 1,521 baseline MDX files and adds 10,958 TIF material resources. Conversion reports are excluded, producing 16,677 unique runtime files.

The original extracted 9th Release has 5,141 files. The clean package excludes 29 non-runtime files, including MPQ metadata, nested RAR archives, PSD working files, terrain-source PNGs, desktop INIs, and MDL source files. Runtime `MDX`, `BLP`, `TGA`, `DDS`, and `SLK` assets remain. DE overlay audio files are retained as well.

## Changes compared with original WC3 Rebirth

### Installation and asset resolution

Original Rebirth was made for the legacy/SD asset namespace. Its loose BLP/TGA terrain paths and old tables are not sufficient in DE mode because DE resolves many visible assets through explicit diffuse, normal, and ORM material paths.

The DE conversion:

- installs assets at resolved root loose-file paths such as `Units`, `Doodads`, `TerrainArt`, and `ReplaceableTextures`;
- does not use a loose `_DE.w3mod` directory;
- packages every original runtime dependency instead of requiring an existing Rebirth installation;
- applies DE-specific replacements after the original files so the corrected versions always win path collisions;
- generates a complete SHA-256 manifest outside the install folder.

### Terrain textures

The conversion generates 181 DE terrain diffuse files:

- 148 Rebirth ground and blight textures;
- 32 Rebirth cliff diffuse textures;
- one PotS-specific fully transparent Lordaeron Winter Rough Dirt texture.

The converter now:

- matches DE dimensions, DXT compression, mip counts, flags, and container metadata;
- completes every compressed mip payload, avoiding purple missing-texture output;
- for the known alpha-sensitive atlases, matches each classic transition cell to the closest native DE alpha-mask cell, including rotation/reflection, then composites hidden legacy RGB over an opaque source tile before DE alpha is applied; this prevents green matte exposure, directional smear fields, and misaligned Cityscape border joints;
- preserves Rebirth color aspect and tiles legacy 2:1 atlases instead of stretching them into square targets;
- copies DE transition-alpha blocks for DXT5 terrain while retaining Rebirth color;
- rebuilds DXT1 color blocks through a valid DXT5 intermediate because BLP Laboratory's direct 24-bit DXT1 route corrupted cliff colors;
- explicitly selects the release `Ashen_Grass.tga`, `Ashen_GrassLumpy.tga`, `Ruins_Sand.tga`, and `Ruins_DirtRough.tga` files where same-stem BLP siblings contain different art, incorrect atlas layouts, or insufficient alpha information for safe atlas remapping.

Sunken Ruins Sand is an important special source-selection case. Its BLP sibling is 512×512, but the intended release TGA is 1024×512. Converting the square BLP produced repeated internal seams even when its alpha was changed. The working DE texture uses the 2:1 TGA, tiles it vertically into the 1024×1024 DE target, and retains the native DE transition mask.

### Grass and foliage

Ashenvale Grass and Lumpy Grass needed more than a diffuse replacement because DE adds separate foliage and material detail.

The conversion therefore includes:

- the exact Rebirth release TGAs for both grass tiles;
- two transparent DE foliage diffuses so native DE grass geometry does not obscure the Rebirth art;
- two flat ATI2 normal maps;
- two neutral DXT5 ORM maps.

This removes DE-specific flowers, stones, tufts, rings, and embossed surface detail while preserving DE lighting and shadows.

The same material policy now applies to all 148 converted Rebirth ground/blight textures: 148 native-profile flat ATI2 normal maps plus 148 neutral opaque DXT5 ORM maps. The neutral ORM values are unoccluded, maximally rough, and non-metallic, eliminating the native DE angle-dependent shine while diffuse alpha continues to control terrain transitions. This new all-terrain material pass requires World Editor confirmation.

### Cliffs

The original Rebirth `CliffTypes.slk` has 12 columns and 36 keyed rows. Warcraft III 3.0.0.24268 has 13 columns and 45 keyed rows, including `overrideTexture`. Installing the old table would remove modern rows and schema content.

The merged table:

- retains every current DE row and column;
- maps all 36 shared `overrideTexture` fields to each row's current DE material base;
- places converted Rebirth color art at the corresponding DE diffuse path;
- supplies flat ATI2 normals and neutral opaque DXT5 ORM maps for all 32 cliffs for which Rebirth supplies art;
- leaves four unsupplied legacy cliff images on their current DE diffuse assets.

Using direct legacy cliff BLPs restored some color but bypassed the DE material triplets, producing side faces that became bright or white depending on camera angle. Loading the converted Rebirth diffuse, flat normal, and neutral ORM together through the current DE material base fixed that behavior.

### Data tables

`TerrainArt\CliffTypes.slk` is a deterministic current-schema merge rather than the original legacy file.

`Units\DestructableData.slk` is the unmodified current build-24268 table. Original Rebirth contains only 247 keyed rows and 57 legacy columns, while the current table has 344 keyed rows and 41 current columns. Rebirth has no proven model-path customization in that table that justifies losing the current content.

The merge scripts check the Blizzard source hashes and stop if the target build changes unexpectedly.

### Models, textures, and sounds

The copy-ready package retains the complete original Rebirth runtime model/texture set and the eight `FixesLast2023` files. The DE overlay adds the selected changed and additional files from the verified community Reforged edit pack, rather than installing that archive blindly.

The model work completed in this round includes:

- DE/HD collision selection so Rebirth models outrank native DE/HD models at the resolved paths;
- 14 targeted MDX texture-path repairs;
- static resolution of all 5,704 texture references scanned for the selected overlay models;
- valid `MDLX` headers for all 1,521 MDX files in the final package;
- community fixes such as the Reforged Mountain King-related edits where the verified community files differ from the base release.

The models inside this baseline package are still primarily Rebirth's SD-origin models. A separate material-conversion batch has now produced an HD/DE staging tree, but that tree has not yet replaced the baseline models in the copy-ready package and still requires broad in-game validation.

## Separate SD-to-HD/DE model staging

A full staging conversion has been completed using [Zorrot's War3 Retro HD Converter](https://github.com/UIZorrot/war3-retro-hd-converter/). The source package was treated as read-only and the converted results were written to a separate directory:

```text
Source: Assets\PotS_DE\WC3Rebirth_DE\
Output: Assets\PotS_DE\WC3Rebirth_DEModels\
```

The converter changes SD MDX models to version 1000 HD-material models, builds `Shader_HD_DefaultUnit` materials, and generates diffuse, alpha, team-color, normal, ORM, and team-ORM resources while preserving the original geometry, UVs, animations, and Warcraft-managed replaceable resources. It is a material converter, not a remesher or texture upscaler: it does not add polygons or increase the original diffuse resolution.

That distinction matters for Rebirth. The converted models should improve compatibility with DE lighting and material behavior, but they do not automatically gain higher-detail geometry or artwork.

Current staging result:

| Property | Result |
|---|---:|
| Source MDX models | 1,521 |
| Converted successfully | 1,521 |
| Failed | 0 |
| Output MDX version | 1000 |
| Generated TIF resources | 10,958 |
| Total output files | 12,482 |
| Total output size | 6,352,506,241 bytes |
| MDX load failures | 0 |
| MDX chunk-framing failures | 0 |
| Pivot mismatches | 0 |

The batch reports are stored under `Assets\PotS_DE\WC3Rebirth_DEModels\_reports\` as `conversion_report.json`, `source_texture_audit.json`, and `strict_validation.json`.

The local conversion toolchain is kept under `tools\war3-retro-hd-converter\`, `tools\PyMdlxConverter\`, and `tools\War3RetroHD-v0.1.0\`.

The local PyMdlxConverter checkout currently contains four required parser/serializer corrections for integer animation values, light type serialization, unknown-chunk version handling, and event-track byte lengths. These changes must be retained, upstreamed, or captured as a reproducible patch before rebuilding the model layer on another machine.

This is a structurally validated staging result, not yet the installer-ready model layer. It still needs representative in-game testing for units, heroes, buildings, portraits, attachments, morphs, team color and glow, alpha blending, death/dissipate animations, sounds, scale, selection circles, and shadows. Only validated converted models should be promoted into the final package.

PotS-specific imported models are a separate body of work. Many of those imports are still SD-origin assets and must later receive the same SD-to-HD/DE conversion, dependency audit, staging, and in-game validation before they can be externalized safely.

Promotion and validation plan:

1. Freeze this validated `WC3Rebirth_DE` package as the baseline.
2. Inventory the converted units and heroes separately from buildings, doodads, missiles, effects, portraits, and attachment models.
3. Test a representative group first: one normal unit per race, heroes, team-color-heavy models, mounted units, morphs, summoned units, and models with portraits or external submodels.
4. Review the texture audit and resolve ambiguous texture basenames before promoting affected models.
5. Reapply and compare the selected community Reforged fixes and the existing 14 MDX path repairs where necessary.
6. Validate animations, portraits, attachments, team color/glow, alpha, death/dissipate, sounds, model scale, selection circles, shadows, and multiplayer behavior in the current game client.
7. Convert and validate the separate PotS imported-model set using the same staged process.
8. Add only validated converted packages as new deterministic layers in the package builder and installer payload.

The converter currently does not automatically collect external submodels, sounds, or FaceFX assets, so the Rebirth dependency/package audit remains necessary after conversion. Generated automatic normal and ORM maps are compatibility-oriented and should be replaced with authored maps where physically accurate materials are important.

## Installer-managed DE architecture (work in progress)

The intended release architecture makes the PotS installer responsible for two distinct external asset components in addition to the map:

1. **WC3 Rebirth DE**: the validated Rebirth terrain, data, models, textures, and supporting files required by PotS in DE mode.
2. **PotS external assets**: selected assets currently embedded in the map import table that will later be installed as loose files under Warcraft III's `_retail_` directory.

External PotS assets must preserve their exact map-import-relative paths beneath `_retail_`. For example:

```text
Map import path:
war3mapImported\Units\Nazgrek.mdx

External installation path:
Warcraft III\_retail_\war3mapImported\Units\Nazgrek.mdx
```

The map reference does not change when the asset moves outside the map. The installer payload and installed loose-file path must therefore match the original import path exactly, including its directories and filename. Many PotS imports are expected to move to `_retail_` this way after their dependencies, DE conversion requirements, and runtime behavior have been validated.

The installer must maintain explicit ownership and version information for each component and each installed file. Its maintenance UI must provide clear player-facing actions to:

- install, update, or repair the complete supported setup;
- add or remove WC3 Rebirth DE independently;
- add or remove PotS external assets independently;
- remove the map while retaining selected external components, or remove the complete PotS installation;
- show what will be installed or removed before applying the operation.

Removal must target only manifest-owned files and may prune only directories left empty by that removal. It must never broadly delete Warcraft III's `_retail_` directory or unrelated loose mods. If installation overwrites a pre-existing loose file that is not already owned by the same PotS component, the installer must back it up and restore it during removal, or stop and ask the user how to resolve the collision.

This installer architecture is not implemented yet. Until manifest-based install and removal are available and validated, the manual copy and backup instructions remain the supported development workflow.

## Development folders

```text
Assets\PotS_DE\overlay\
```

Development delta. It contains only selected collisions and generated DE compatibility files. It still depends on original Rebirth for unique non-colliding assets and is not the preferred end-user install folder.

```text
Assets\PotS_DE\WC3Rebirth_DE\
```

Generated self-contained baseline runtime package with the SD-origin Rebirth models. It is retained as the reproducible input to model conversion and as a diagnostic fallback.

```text
Assets\PotS_DE\WC3Rebirth_DEModels\
```

Structurally validated HD/DE model and generated material staging tree. Its `_reports` child is development evidence and is not runtime content.

```text
Assets\PotS_DE\WC3Rebirth_DE_Full\
```

Combined installable runtime tree. It consists of the baseline package followed by the converted-model overlay, excluding `_reports`. Copy this folder's **contents** into `_retail_` when testing the converted models.

```text
Assets\PotS_DE\source\
Assets\PotS_DE\reports\
Assets\PotS_DE\generated\
Assets\PotS_DE\scripts\
```

Build references, evidence, manifests, and tooling. Do not copy these directories into Warcraft III.

## Rebuilding and validation

Build the DE overlay first using the documented PotS_DE workflow. Then compose the clean package from the repository root:

```powershell
& .\_WC3Rebirth\Assets\PotS_DE\scripts\Build-WC3RebirthDePackage.ps1 -Clean
```

The builder removes only the exact generated `WC3Rebirth_DE` child directory after validating its resolved path. It then applies the three source layers and writes:

```text
Assets\PotS_DE\reports\WC3Rebirth_DE_package_layers.csv
Assets\PotS_DE\reports\WC3Rebirth_DE_package_validation.csv
Assets\PotS_DE\generated\WC3Rebirth_DE_manifest.sha256
Assets\PotS_DE\generated\WC3Rebirth_DE_build_summary.json
Assets\PotS_DE\generated\WC3Rebirth_DE_Full_manifest.sha256
Assets\PotS_DE\generated\WC3Rebirth_DE_Full_build_summary.json
```

The manifests are intentionally outside the runtime package directories, so copying package contents installs only Warcraft runtime files.

After the baseline and converted-model staging trees have been validated, compose `WC3Rebirth_DE_Full` by copying the baseline first and then overlaying all runtime files from `WC3Rebirth_DEModels` while excluding its `_reports` directory. The model overlay must win all MDX collisions.

## Rollback and cleanup

The package manifest lists every installed package path. Removing those paths does not restore files that were overwritten during installation. For a reliable rollback, restore the backed-up loose files or repair/reinstall Warcraft III and then reinstall only the desired mods.

Do not perform broad deletion against `_retail_`. It contains the game client and data in addition to loose mod assets.

## Remaining validation

Terrain, grass, cliffs, and Sunken Ruins Sand have received focused World Editor runtime testing. The following still require broader validation before main-installer integration:

- representative units, heroes, buildings, doodads, destructibles, missiles, effects, portraits, and attachments;
- animations, model scale, selection circles, team color, hero glow, alpha, sounds, and death/dissipate behavior;
- water edges, fog, day/night lighting, cinematics, and terrain combinations not yet exercised;
- PotS startup, loading, major zones, spells, inventories, save/load, and multiplayer-sensitive behavior;
- representative runtime testing and promotion of the staged Zorrot SD-to-HD/DE model layer;
- conversion and validation of PotS-specific imported SD models;
- installer-managed installation, update, repair, complete removal, and per-component removal for WC3 Rebirth DE and PotS external assets.
