# Rebirth Asset Complexity Plan

## Metadata

- **Candidate ID:** PERF-007
- **Priority:** P2 research
- **Status:** planned; object-to-model mapping and runtime impact `NOT_MEASURED`
- **Bundle ID:** ASSET-01
- **Prerequisite:** read-only current-map extraction and working MDX parser
- **Hard dependencies:** current World Editor object/import data and installed Rebirth overrides
- **Behavioral dependencies:** DoodadManager/Render, destructables, weather, SpeciFX and any system using an affected model
- **Shared files:** no JASS source by default; World Editor changes are manual
- **Can ship independently:** yes, one asset experiment at a time

## Evidence

The audited retail installation contains approximately:

- 1,521 MDX files, about 462 MB;
- 2,723 BLP files, about 917 MB;
- 555 DDS files, about 1.16 GB;
- 915 TGA files, about 2.30 GB;
- total loose override footprint about 4.50 GiB.

Some individual models are several megabytes and multiple textures are about 16.8 MB. These sizes identify investigation targets only; disk size is not evidence of GPU cost.

The available DoodadManager reference covers about 24.65% of recorded doodad placements. The current map archive and Object Editor mappings are required to resolve every rawcode to its actual SD/DE/Rebirth model.

## Read-only analysis pipeline

1. Copy/extract the current W3X to a temporary read-only workspace using an approved MPQ tool; never edit `_MISC/war3map.wts` or repository exports.
2. Export rawcode-to-model and placed-instance counts for units, doodads and destructables.
3. Resolve imported and loose-override paths with case/path normalization.
4. Prepare the existing MDX parser dependencies without modifying the source corpus.
5. Parse vertices, faces, geosets, material layers, transparent/additive layers, particles, ribbons, lights, bones and referenced textures.
6. Read texture dimensions/formats and flag very large transparent assets.
7. Rank candidates using placement count multiplied by a disclosed per-instance complexity score. Keep each raw component visible rather than relying only on the composite score.
8. Cross-reference DoodadRender/DestructableHider coverage and effect attachment so the test reflects actual simultaneous instances.

## Experiment design

For each of the highest-ranked assets:

1. Make one reversible replacement/simplification in a World Editor test copy.
2. Keep placements, camera, lighting, shadows, animation and all scripts unchanged.
3. Capture SD and DE, Rebirth enabled and disabled where possible.
4. Compare dense static view, camera traversal and any relevant animation/effect scene.
5. Record visual differences with screenshots and frame-time captures.

Potential changes include lower particle counts, fewer transparent layers, optimized geometry, smaller textures or a lighter replacement model. Do not merge clusters or alter pathing/selection footprints without a separate gameplay design.

## Acceptance criteria

- Asset identity and credits are known; replacement rights are valid.
- At least 5% GPU frame-time or 1%-low improvement in the affected dense scene.
- No unacceptable SD/DE appearance, portrait, attachment, team-color, animation, shadow, selection or pathing regression.
- The same rawcode/model mapping is revalidated in the current map build.
- The user performs and verifies all Object Editor/import changes manually.

## Rollback

Restore the original import/object-model assignment in World Editor, rebuild the map and verify the original checksum/path. Remove temporary extracted data rather than committing it.

Suggested commit for an accepted asset change: `Optimize <asset name> rendering cost`.

