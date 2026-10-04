# WC3 Rebirth DE Conversion

## Purpose and current status

This project ports WC3 Rebirth to Warcraft III Definitive Edition (DE) without disabling DE renderer features such as the newer shadow system. Rebirth remains the visual foundation of Path of the Shaman, while the compatibility work adapts its legacy assets and data paths to Warcraft III 3.0.0.24268.

The main copy-ready package is:

```text
_WC3Rebirth\Assets\PotS_DE\WC3Rebirth_DE\
```

Copy the **contents** of `WC3Rebirth_DE` into Warcraft III's `_retail_` directory. Do not copy the `WC3Rebirth_DE` directory itself as an extra nested folder.

Unlike the development `overlay` folder, `WC3Rebirth_DE` is self-contained with respect to Rebirth. It already combines the original 9th Release runtime files, `FixesLast2023`, the selected community Reforged fixes, and the DE compatibility layer. It does not require a separate Rebirth installation first.

Current generated package:

| Property | Result |
|---|---:|
| Package files | 5,719 |
| Package size | 4,825,839,069 bytes |
| MDX models | 1,521 |
| Target Warcraft build | 3.0.0.24268 |
| Root layout | Direct `_retail_` loose-file paths |

All package-layer, critical-table, MDX-header, layout, and SHA-256 manifest checks pass. Runtime testing has confirmed that Rebirth units load in DE, Ashenvale Grass and Lumpy Grass use the intended Rebirth art, cliffs use the correct tileset art without the camera-angle white-face defect, and Sunken Ruins Sand blends without the earlier repeated seams. The subsequent 296-file ground-material neutralization passes static validation but still needs a World Editor retest across representative tilesets. Six diffuse-atlas remaps for Dalaran Ruins Black Marble, Dungeon Square Tiles, Sunken Ruins Rough Dirt, and Cityscape White Marble, Brick Tiles, and Round Tiles also pass static validation and need the same runtime retest.

## Clean installation

1. Use Warcraft III 3.0.0.24268. A newer build requires re-extracting Blizzard references and regenerating the package.
2. Enable Warcraft III `Allow Local Files`.
3. Close World Editor and Warcraft III completely.
4. Back up the existing `_retail_` directory's loose mod files.
5. For the cleanest validation, use a fresh Warcraft III installation or remove/move the previous Rebirth and other loose mod assets before installing this package. Do **not** delete the entire `_retail_` directory: it also contains Warcraft executables and game data.
6. Copy everything inside:

   ```text
   H:\Pelit\PotS_JASS\_WC3Rebirth\Assets\PotS_DE\WC3Rebirth_DE
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

These models are still primarily Rebirth's SD-origin models. They work in DE mode, but this terrain/data compatibility round does not convert the entire unit library to DE's HD material pipeline.

## Separate unit-model SD-to-HD conversion round

Rebirth unit models still need a separate planned conversion round using [Zorrot's War3 Retro HD Converter](https://github.com/UIZorrot/war3-retro-hd-converter/).

The converter changes SD MDX models to version 1000 HD-material models, builds `Shader_HD_DefaultUnit` materials, and generates diffuse, alpha, team-color, normal, ORM, and team-ORM resources while preserving the original geometry, UVs, animations, and Warcraft-managed replaceable resources. It is a material converter, not a remesher or texture upscaler: it does not add polygons or increase the original diffuse resolution.

That distinction matters for Rebirth. The planned model round should improve compatibility with DE lighting and material behavior, but it will not automatically create higher-detail geometry or artwork.

Recommended conversion plan:

1. Freeze this validated `WC3Rebirth_DE` package as the baseline.
2. Inventory unit and hero MDX files separately from buildings, doodads, missiles, effects, portraits, and attachment models.
3. Start with a representative test group: one normal unit per race, heroes, team-color-heavy models, mounted units, morphs, summoned units, and models with portraits or external submodels.
4. Add the clean package as the converter's source/resource root so duplicate texture basenames retain their logical directory structure.
5. Run the converter's texture check before conversion and treat missing or ambiguous matches as blocking failures.
6. Write conversion output to a separate staging directory, never directly over `WC3Rebirth_DE`.
7. Reapply and compare the selected community Reforged fixes and the existing 14 MDX path repairs where necessary.
8. Validate animations, portraits, attachments, team color/glow, alpha, death/dissipate, sounds, model scale, selection circles, shadows, and multiplayer behavior in the current game client.
9. Add only validated converted packages as a new deterministic layer in the package builder.

The converter currently does not automatically collect external submodels, sounds, or FaceFX assets, so the Rebirth dependency/package audit remains necessary after conversion. Generated automatic normal and ORM maps are compatibility-oriented and should be replaced with authored maps where physically accurate materials are important.

## Development folders

```text
Assets\PotS_DE\overlay\
```

Development delta. It contains only selected collisions and generated DE compatibility files. It still depends on original Rebirth for unique non-colliding assets and is not the preferred end-user install folder.

```text
Assets\PotS_DE\WC3Rebirth_DE\
```

Generated self-contained runtime package. This is the folder whose **contents** are copied into `_retail_`.

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
```

The manifest is intentionally outside `WC3Rebirth_DE`, so copying the package contents installs only Warcraft runtime files.

## Rollback and cleanup

The package manifest lists every installed package path. Removing those paths does not restore files that were overwritten during installation. For a reliable rollback, restore the backed-up loose files or repair/reinstall Warcraft III and then reinstall only the desired mods.

Do not perform broad deletion against `_retail_`. It contains the game client and data in addition to loose mod assets.

## Remaining validation

Terrain, grass, cliffs, and Sunken Ruins Sand have received focused World Editor runtime testing. The following still require broader validation before main-installer integration:

- representative units, heroes, buildings, doodads, destructibles, missiles, effects, portraits, and attachments;
- animations, model scale, selection circles, team color, hero glow, alpha, sounds, and death/dissipate behavior;
- water edges, fog, day/night lighting, cinematics, and terrain combinations not yet exercised;
- PotS startup, loading, major zones, spells, inventories, save/load, and multiplayer-sensitive behavior;
- the future Zorrot SD-to-HD unit-model conversion layer.
