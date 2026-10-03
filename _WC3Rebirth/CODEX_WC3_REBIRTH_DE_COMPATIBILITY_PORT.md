# Codex Task: Port Warcraft III Rebirth for Warcraft III Definitive Edition (DE)

## Objective

Make the **entire Warcraft III Rebirth mod** compatible with the current Warcraft III **Definitive Edition (DE)** graphics mode while preserving the visual identity and content of Rebirth as closely as possible.

Codex has access to:

- the installed Warcraft III game files;
- the existing Warcraft III Rebirth files;
- the Path of the Shaman (PotS) development environment/repository;
- tools/scripts available in the local development environment.

The final result must allow **Path of the Shaman + Rebirth** to run in **Definitive Edition mode** with Rebirth visuals replacing the corresponding Blizzard DE visuals wherever Rebirth provides an override.

This is primarily a **compatibility-port and asset-mapping task**, not a redesign of Rebirth.

---

# Primary goals

1. Make Rebirth assets load correctly in Warcraft III DE mode.
2. Preserve the original Rebirth appearance wherever technically possible.
3. Preserve PotS compatibility.
4. Preserve current Warcraft III DE renderer features where they do not conflict with Rebirth.
5. Avoid replacing modern Warcraft III data tables wholesale with obsolete Rebirth tables.
6. Create the compatibility changes as a **separate overlay/patch**, rather than destructively modifying the original Rebirth distribution.
7. Produce tooling and documentation so that the DE compatibility layer can be regenerated when Warcraft III is updated.

---

# Important external reference

A previous community-made Rebirth compatibility pack exists:

- **My edits for Warcraft III Rebirth (including Mountain King fix) for Reforged**
- https://www.moddb.com/addons/my-edits-for-warcraft-iii-rebirth-including-mountain-king-fix-for-reforged

This package was made for Reforged HD rather than the newer Definitive Edition, but it is useful reference material.

According to its author:

- most Rebirth models already worked when used with the newer renderer;
- some models required scale corrections;
- some units became too large or too small;
- the Blood Elf Spell Thief required resizing;
- the Mountain King had a texture/hero-glow issue;
- some Blood Elf hero team-color behavior was corrected.

The downloadable package is named:

`units.zip`

Known metadata from ModDB:

- size: approximately 215.77 MB;
- MD5: `b0b7dfeb179244302421c08c1646bc40`.

If this package is already available locally, inspect it and compare it against both:

1. the original Rebirth files;
2. the current Warcraft III DE asset/data structure.

Do **not** assume that this Reforged compatibility pack is automatically correct for DE.

If the package is not available locally, do not block the work. Continue using the installed Rebirth and Warcraft III files and leave a documented integration point for later comparison.

---

# Non-goals

Do not:

- redesign Rebirth;
- replace Rebirth models with unrelated DE/Reforged models;
- change PotS gameplay;
- change PotS object data unless a compatibility issue specifically requires it;
- modify unrelated JASS/Lua/gameplay systems;
- permanently alter the user's original Rebirth installation;
- blindly copy old SLK/TXT data over current Warcraft III data;
- remove working Rebirth assets merely because a DE version exists;
- convert every asset pre-emptively if the original works correctly in DE.

---

# Required project structure

Create a separate compatibility workspace.

Recommended structure:

```text
Rebirth_DE_Compat/
├── README.md
├── docs/
│   ├── COMPATIBILITY_MATRIX.md
│   ├── ASSET_MAPPING.md
│   ├── DATA_MERGE_NOTES.md
│   ├── TEST_RESULTS.md
│   └── KNOWN_ISSUES.md
├── source/
│   ├── rebirth/
│   ├── wc3_de/
│   └── community_reference/
├── overlay/
│   ├── Units/
│   ├── Buildings/
│   ├── Doodads/
│   ├── TerrainArt/
│   ├── ReplaceableTextures/
│   ├── Textures/
│   ├── UI/
│   └── ...
├── generated/
├── scripts/
└── reports/
```

The exact directory layout may be adjusted to match the current PotS installer architecture, but maintain the conceptual separation between:

- original Rebirth;
- Warcraft III DE reference data;
- community reference fixes;
- generated DE compatibility overlay.

---

# Safety and modification rules

## Rule 1 — Never work destructively against the game install

Treat the Warcraft III installation and original Rebirth files as **read-only reference sources**.

Create backups before any temporary test installation.

All permanent changes belong in the compatibility workspace/overlay.

## Rule 2 — Prefer minimal overrides

If an existing Rebirth asset works correctly in DE:

**do not modify it.**

Only add a compatibility override where DE actually requires one.

## Rule 3 — Do not replace modern tables with old tables

Never simply copy an old Rebirth version of files such as:

```text
CliffTypes.slk
Terrain.slk
DestructableData.slk
UnitData.slk
UnitUI.slk
Doodads.slk
UnitSkins.txt
```

over the current Warcraft III equivalents.

Instead:

```text
current WC3 DE table
        +
required Rebirth modifications
        =
DE-compatible merged table
```

Preserve all current Blizzard rows/columns/fields unless there is a documented reason to modify them.

## Rule 4 — Every generated change must be reproducible

Where practical, implement modifications through scripts rather than one-off manual edits.

Examples:

- SLK merge script;
- TXT merge script;
- asset inventory script;
- MDX path scanner;
- model scale comparison report;
- missing texture report;
- duplicate-path report.

---

# Phase 1 — Discover the actual installations

Do not assume paths.

Locate:

1. Warcraft III installation root;
2. Rebirth installation/content root;
3. PotS repository;
4. any existing PotS installer asset staging folders;
5. any downloaded Rebirth DE/Reforged compatibility reference packages.

Document all discovered roots in:

`reports/environment.md`

Do not commit machine-specific absolute paths into reusable scripts.

Use configuration or relative paths instead.

---

# Phase 2 — Inventory Rebirth

Generate a complete Rebirth inventory.

For every file record at least:

- relative path;
- filename;
- extension;
- size;
- hash;
- asset category.

Recommended categories:

```text
MDX / MDL models
BLP textures
DDS textures
TGA textures
SLK data
TXT data
UI
terrain
cliffs
doodads
destructibles
units
heroes
buildings
missiles
effects
portraits
icons
sounds
other
```

Produce:

`reports/rebirth_inventory.csv`

and a summarized Markdown report:

`docs/COMPATIBILITY_MATRIX.md`

Also identify all Rebirth files that replace a path that exists in the current Warcraft III installation.

---

# Phase 3 — Inventory Warcraft III DE

Inspect the current installed Warcraft III data.

Use the installation itself as the source of truth.

Determine the current DE asset/data organization, especially for:

```text
Units
Buildings
Doodads
Destructables
TerrainArt
ReplaceableTextures
Textures
UI
Abilities
Effects
Environment
Water
Cliffs
```

Locate and inspect current equivalents of at least:

```text
UnitSkins.txt
UnitData.slk
UnitUI.slk
DestructableData.slk
Doodads.slk
Terrain.slk
CliffTypes.slk
```

Search for any newer DE-specific files that now control:

- graphics-mode model selection;
- texture selection;
- variations;
- skins;
- model scale;
- destructible variants;
- doodad variants;
- terrain variants;
- cliff variants;
- portraits.

Do not assume the old Reforged `file:sd` / `file:hd` behavior is still the complete mechanism.

Document the actual DE mechanism found in the installed version.

---

# Phase 4 — Compare the community Reforged compatibility pack

If `units.zip` or its extracted contents are available, compare it against original Rebirth.

Generate a diff report showing:

- added files;
- removed files;
- binary differences;
- MDX files changed;
- texture files changed;
- path changes;
- size changes;
- likely model scaling changes.

For every modified model, attempt to determine why it differs.

Pay special attention to:

- Mountain King;
- Blood Elf Spell Thief;
- Blood Elf heroes;
- hero glow/team-color materials;
- models whose scale differs between renderers.

Store this report as:

`reports/community_rebirth_reforged_diff.md`

Treat useful fixes as candidates for the DE compatibility layer.

Do not automatically use the entire archive.

---

# Phase 5 — Establish compatibility tests

Before bulk conversion, create representative tests.

Test at minimum:

## Units

- normal ground unit;
- hero;
- large unit;
- small unit;
- flying unit;
- summoned unit.

## Buildings

- normal building;
- large building;
- animated building.

## Doodads

- tree;
- rock;
- environmental doodad;
- animated doodad;
- large doodad.

## Destructibles

- tree/destructible;
- gate;
- bridge or equivalent complex destructible.

## Terrain

- standard ground tile;
- blended tile;
- cliff;
- cliff transition;
- shoreline.

## Effects

- missile;
- spell effect;
- attachment effect;
- hero glow;
- blood/death effect.

For each representative test record:

```text
Loads?
Correct geometry?
Correct scale?
Correct textures?
Correct team color?
Correct animations?
Correct portrait?
Correct attachment points?
Correct shadow?
Correct selection circle?
Correct death animation?
Correct sound references?
Correct transparency/blending?
Correct lighting/material response?
Visual regressions?
Crash?
```

---

# Phase 6 — Models

## Default approach

Try existing Rebirth models first.

If the model renders correctly in DE, use it unchanged.

Only modify models when one of the following is observed:

- wrong scale;
- missing texture;
- incorrect material;
- incorrect alpha/blending;
- hero glow corruption;
- attachment corruption;
- portrait issue;
- animation issue;
- DE crash;
- renderer-specific artifact.

## Scale

Do not apply one global scale multiplier.

Determine whether the problem belongs to:

- model geometry;
- object-data scale;
- model metadata;
- DE renderer interpretation.

Prefer the least invasive correction.

If the community Reforged compatibility model already contains a verified scale correction, use it as evidence and compare against actual DE rendering.

Document every changed model and its reason.

---

# Phase 7 — Textures and materials

For every model with missing or incorrect textures:

1. enumerate referenced texture paths;
2. compare those paths against Rebirth;
3. compare them against WC3 DE;
4. determine whether DE path resolution changed;
5. repair paths only where required.

Avoid duplicating textures unnecessarily.

Check:

- team color;
- team glow;
- alpha channels;
- replaceable textures;
- emissive-looking effects;
- transparency modes;
- portrait textures.

Do not visually redesign textures merely to make them look more "DE".

The target is Rebirth's existing style.

---

# Phase 8 — Unit/object graphics mapping

Determine how DE chooses graphics for a Warcraft III object.

Inspect current data rather than relying on historical assumptions.

Particularly analyze:

`UnitSkins.txt`

and related current DE graphics-selection files.

Determine whether DE uses:

```text
classic
sd
hd
reforged
definitive
skin-specific
variation-specific
```

references or another selection mechanism.

Create a mapping such as:

```text
Object ID
Original Classic model
Original Rebirth model
Current DE model
Current Reforged model
Desired DE-Rebirth model
Required mapping change
```

Store in:

`docs/ASSET_MAPPING.md`

Automate generation where practical.

---

# Phase 9 — Doodads and destructibles

Rebirth visual identity depends strongly on environment assets.

Perform the same mapping process for:

- doodads;
- destructibles;
- environmental props;
- trees;
- rocks;
- gates;
- bridges;
- ruins;
- decorative objects.

Be particularly careful with DE variation systems.

If DE introduces new variation entries absent from Rebirth, preserve those entries and map only the appropriate visual fields.

Do not replace entire modern data tables with Rebirth-era tables.

---

# Phase 10 — Terrain and cliffs

Terrain is high priority for PotS.

Compare Rebirth and current Warcraft III versions of:

```text
Terrain.slk
CliffTypes.slk
```

Determine exactly which cells/records Rebirth changed.

Then apply those modifications to the **current DE versions**.

Preserve all modern fields and rows that Rebirth does not intentionally alter.

Also inspect:

- terrain textures;
- cliff textures;
- cliff meshes if applicable;
- tile normals/material data if DE uses them;
- shoreline interaction;
- water-edge behavior.

Create deterministic merge tooling.

Recommended outputs:

```text
scripts/merge_terrain_data.*
generated/Terrain.slk
generated/CliffTypes.slk
```

The script should fail loudly if the Blizzard source schema changes unexpectedly.

Do not silently generate potentially corrupt tables.

---

# Phase 11 — Water, lighting, shadows and renderer features

Do not disable DE rendering features merely to make Rebirth resemble Classic.

Prefer:

```text
Rebirth visual assets
+
DE renderer
+
DE shadows
+
DE water
+
DE lighting
```

unless a specific feature visibly breaks Rebirth.

If an incompatibility exists, isolate and document it.

Do not globally disable a rendering feature before establishing that a targeted fix is impossible.

---

# Phase 12 — UI

Inventory Rebirth UI modifications separately.

Determine whether each UI asset:

- works unchanged;
- is ignored in DE;
- conflicts with DE UI;
- is incompatible with current aspect-ratio handling;
- depends on obsolete frame paths.

Do not force old UI files into DE if they break current gameplay screens.

Where Rebirth has no intentional UI replacement, leave DE UI untouched.

---

# Phase 13 — Path of the Shaman compatibility

After the generic Rebirth DE layer works, test PotS.

The compatibility layer must not modify PotS gameplay or object data unless necessary.

Test at minimum:

- map startup;
- hero loading;
- terrain;
- major PotS areas;
- custom units;
- custom doodads;
- custom destructibles;
- cinematics;
- attachments;
- inventory/item models;
- spells/effects;
- day/night;
- fog;
- water;
- shadows;
- save/load if applicable.

Check both visually and for runtime errors/crashes.

Because PotS heavily relies on Rebirth's visual environment, prioritize terrain, doodads, destructibles and unit visuals.

---

# Phase 14 — Automated diagnostics

Create scripts for the following where feasible.

## Missing texture scanner

Parse model texture references and report missing files.

Output:

`reports/missing_textures.csv`

## Duplicate override scanner

Identify multiple local files targeting the same logical Warcraft III path.

Output:

`reports/duplicate_overrides.csv`

## Stale data schema checker

Compare old Rebirth SLK/TXT schemas against current Blizzard schemas.

Output:

`reports/data_schema_diff.md`

## Asset path comparer

Compare:

```text
Rebirth path
WC3 current path
DE graphics mapping
compatibility overlay path
```

Output:

`reports/asset_paths.csv`

## Hash manifest

Create hashes of all compatibility-layer files.

Output:

`generated/manifest.sha256`

---

# Phase 15 — Compatibility matrix

Maintain a living matrix.

Example:

| Area | Rebirth original | Works in DE | Fix needed | Fix completed | Notes |
|---|---|---:|---:|---:|---|
| Human units | yes | partial | yes | | |
| Orc units | yes | | | | |
| Undead units | yes | | | | |
| Night Elf units | yes | | | | |
| Neutral units | yes | | | | |
| Heroes | yes | | | | |
| Buildings | yes | | | | |
| Doodads | yes | | | | |
| Destructibles | yes | | | | |
| Terrain | yes | | | | |
| Cliffs | yes | | | | |
| UI | yes | | | | |
| Effects | yes | | | | |
| Portraits | yes | | | | |

Do not declare the port complete merely because common melee units work.

The target is the **whole Rebirth mod**.

---

# Phase 16 — Regression testing

Once fixes are applied, test:

1. DE + Rebirth compatibility overlay;
2. DE + Rebirth compatibility overlay + PotS;
3. Classic/SD behavior if the same installation is expected to support it.

The DE compatibility patch must not accidentally overwrite files required for Classic Rebirth unless that behavior is explicitly intended.

Prefer mode-specific or installer-selected overlays where required.

---

# Phase 17 — Installer integration

Do not integrate into the main PotS installer until the overlay is independently verified.

After verification, prepare the compatibility layer so the installer can support something conceptually like:

```text
Graphics setup

[ ] Classic / Rebirth
[X] Definitive Edition / Rebirth
```

The installer should know which compatibility overlay to deploy.

Do not duplicate hundreds of MB of unchanged files if the same base Rebirth asset can serve both modes.

Use delta-style installation wherever possible.

---

# Phase 18 — Deliverables

The task is not complete until the following exist.

## Required

### 1. DE compatibility overlay

A clean overlay containing only required changes.

### 2. README

Explain:

- what the compatibility layer does;
- supported WC3 version;
- required Rebirth version;
- installation order;
- uninstall/rollback;
- known limitations.

### 3. Compatibility matrix

`docs/COMPATIBILITY_MATRIX.md`

### 4. Asset mapping

`docs/ASSET_MAPPING.md`

### 5. Data merge notes

`docs/DATA_MERGE_NOTES.md`

### 6. Test results

`docs/TEST_RESULTS.md`

### 7. Known issues

`docs/KNOWN_ISSUES.md`

### 8. Reproducible scripts

All scripts required to regenerate merged tables or compatibility assets.

### 9. Manifest

Hash manifest of the generated compatibility package.

---

# Acceptance criteria

The port may be considered ready when:

- PotS loads and runs in Definitive Edition mode;
- Rebirth models appear instead of unintended Blizzard DE replacements;
- Rebirth terrain appearance is preserved;
- Rebirth cliffs work correctly;
- Rebirth doodads and destructibles work correctly;
- unit and hero models use correct scale;
- portraits function;
- team color works;
- textures load;
- animations work;
- attachments work;
- major effects work;
- no systematic missing-texture errors remain;
- no known compatibility-layer crash remains;
- merged SLK/TXT files retain current WC3 schema/content outside intentional Rebirth changes;
- all modifications are documented;
- all generated data modifications are reproducible;
- rollback is possible without reinstalling Warcraft III.

---

# Investigation principles

When there is uncertainty, inspect the installed game files and test.

Use this priority:

```text
Actual current Warcraft III installation
    >
observed runtime behavior
    >
current PotS/Rebirth files
    >
community compatibility patches
    >
old tutorials/documentation
```

The installed game's current data is the source of truth for DE.

---

# Do not guess asset mappings

If a Rebirth path no longer overrides the expected DE asset:

1. identify the Warcraft III object ID;
2. trace the object's current graphical definition;
3. find the DE-specific reference;
4. determine the actual override path or data field;
5. make the smallest required compatibility change;
6. test;
7. document it.

Do not solve unknown mappings by copying large folders into guessed locations.

---

# Working style

Work iteratively.

For each subsystem:

```text
inspect
→ diff
→ form hypothesis
→ implement smallest fix
→ test
→ document
→ continue
```

Do not perform a large uncontrolled conversion before representative tests demonstrate the correct mechanism.

Commit or checkpoint changes in logical batches such as:

```text
DE compatibility: unit model mapping
DE compatibility: unit scale corrections
DE compatibility: destructible mappings
DE compatibility: terrain SLK merge
DE compatibility: cliff mappings
DE compatibility: texture path fixes
DE compatibility: PotS integration fixes
```

---

# First actions

Begin with these actions in this order:

1. Locate the Warcraft III, Rebirth and PotS roots.
2. Create the compatibility workspace.
3. Inventory Rebirth.
4. Inventory current Warcraft III DE graphics/data files.
5. Locate the current graphics-mode selection mechanism.
6. Inspect `UnitSkins.txt` and related DE data.
7. Compare current `Terrain.slk`, `CliffTypes.slk`, `DestructableData.slk`, `Doodads.slk`, `UnitData.slk` and `UnitUI.slk` against Rebirth.
8. If available, inspect the ModDB `units.zip` reference pack.
9. Test one Rebirth unit, hero, doodad, destructible, terrain tile and cliff in DE.
10. Write an initial compatibility report before bulk modification.
11. Implement the compatibility layer subsystem by subsystem.
12. Validate the completed layer with PotS.

---

# Initial report required before bulk edits

Before performing widespread modifications, create:

`reports/INITIAL_DE_COMPATIBILITY_ANALYSIS.md`

It must state:

- installed Warcraft III version/build;
- Rebirth version/build/fix pack found;
- relevant file roots;
- how DE selects unit/building/doodad graphics;
- whether existing Rebirth MDX files load directly;
- whether model scale differs;
- whether Rebirth texture paths resolve;
- how terrain selection works;
- how cliff selection works;
- which old Rebirth data files cannot safely replace modern files;
- value of the ModDB Reforged compatibility pack;
- proposed architecture for the final overlay;
- highest-risk compatibility areas;
- recommended next implementation step.

After this report, proceed with implementation unless a truly blocking ambiguity remains.

---

# References

- Warcraft III Rebirth:
  https://www.moddb.com/mods/warcraft-iii-rebirth

- Rebirth models edited for Reforged:
  https://www.moddb.com/addons/my-edits-for-warcraft-iii-rebirth-including-mountain-king-fix-for-reforged

- Path of the Shaman repository:
  https://github.com/ValdemarLabs/wc3-path-of-the-shaman/tree/dev

- Blizzard Warcraft III forums / current patch information:
  https://us.forums.blizzard.com/en/warcraft3/
