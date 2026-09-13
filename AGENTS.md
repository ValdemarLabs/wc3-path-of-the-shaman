# Repository Guidelines

## Project Structure & Module Organization

Path of the Shaman is primarily vJASS/JassHelper code grouped by gameplay feature. Add source to the existing domain folder, such as `Abilities/`, `Arena/`, `QuestsAndDialogs/`, `UI/`, or `UnitSystems/`. Shared and imported dependencies live in `_CoreSystems/`; use `_Blizzard/common.j` and `_Blizzard/blizzard.j` as native and helper references. Frame definitions and load lists are under `_fdf/` and `_tocs/`. Database-generated JASS is written to `WC3_Export/`, while the Windows item tool lives in `WC3_Database/WC3ItemManager/`. Tests are generally focused `.j` harnesses beside their systems. Treat `backups/`, `_Old*`, `bin/`, and `obj/` as historical or generated unless explicitly targeted.

## Build, Test, and Development Commands

There is no single repository-wide build command. Useful local checks are:

```powershell
rg --files -g "*.j"                                      # inventory JASS sources
dotnet build .\WC3_Database\WC3ItemManager\WC3ItemManager.csproj
dotnet run --project .\WC3_Database\WC3ItemManager\WC3ItemManager.csproj
powershell -ExecutionPolicy Bypass -File .\Installer\build-installer.ps1
```

The installer command requires prepared `Installer/payload/` content and Inno Setup. Validate gameplay code by importing it through the normal Warcraft III/JassHelper workflow, compiling an affected test map, then compiling the full map. Standalone `pjass` is insufficient for these vJASS libraries.

## World Editor export boundaries

Treat `_MISC/war3map.wts` as a read-only, point-in-time export from the Warcraft III World Editor. It may be inspected as supporting evidence but must never be edited. The user performs map-specific Object Editor, GUI trigger, placed-unit, region, and string changes in World Editor; report those changes as manual WE follow-up instead of modifying exported map data.

## Blizzard API baseline

Treat `_Blizzard/common.j` and `_Blizzard/blizzard.j` as the active Warcraft III 3.0.0, build 24268 API snapshot. Files under `_Blizzard/Archive/` are historical comparison material, not the availability baseline. Before implementing a native-dependent feature, search the active files for the exact declaration, parameter order, return type, related constants, and handle inheritance; patch-note summaries and older online JASS references are not sufficient for signature checks. Prefer a `common.j` native over a duplicate custom wrapper, and inspect `blizzard.j` before adding a BJ-style helper. New 3.0 APIs include ability cooldown control, aura toggling, attack reset, equipment/loadout, fog and HD-water controls, input/camera queries, and doodad/destructable transforms and colors. When using a 3.0-only API, identify the minimum game version in the handoff and validate it in the current World Editor/JassHelper and game client, including multiplayer testing for local input, camera, frame, or synchronization-sensitive behavior.

## Coding Style & Naming Conventions

Use four-space indentation and follow the closest comparable library. Keep callees before callers, initialization order explicit, and public/private APIs clearly separated. Prefix globals and internal helpers with the owning system (`Arena_Active`, `MUI_CreateFrames`); use descriptive PascalCase library and file names. Standalone libraries require the standard header sections: `Description`, `Credits`, `How to install`, and `API`. Destroy owned handles when required, then null local handle variables on every exit path. Keep comments short and reserve them for configuration or non-obvious flow.

## Testing Guidelines

No automated test framework or coverage threshold is configured. Name focused harnesses consistently with existing files, for example `*_TestMap.j`, `*_testing.j`, or `*_testFunctions.j`. Verify compile success, initialization, cleanup, and affected runtime behavior. Multiplayer-sensitive UI, frame events, and synchronized state require multiplayer testing. For item-manager changes, run `dotnet build` and exercise the affected workflow against a non-production database.

## Commit & Pull Request Guidelines

Recent history uses short, direct, sentence-case summaries without Conventional Commit prefixes, such as `Add Circle of Blood arena zone`. Keep each commit cohesive and describe the observable result. Pull requests should list affected systems, dependencies or import-order changes, test-map/full-map results, and known validation gaps. Include screenshots for UI/frame changes and identify regenerated exports separately from hand-edited source.

## Changelog and commit messages

Always update `Pots Changelog.md` on the current date. Use for example "Added/updated `Arena/ArenaModes.j`" this styling when updating library.
Write short commit messages in chat per changed files or sometimes for many files if the commit is clearly for many files.

## Story and quest design source of truth

Before creating or materially updating a quest, quest giver, story dialogue, dungeon quest, or story-driven world event, read `_developer/Design Plans/Story and Quest Design.md`. Reconcile the proposed change with its implementation ledger, story dependencies, canonical names, zone ID, and open decisions. Current JASS, current World Editor data, and `Zones/ZonesCore.j` take priority over outdated Articy material; inspect unexported GUI triggers before claiming or replacing their behavior. When implementation changes a quest's status, dependencies, location, identity, or story outcome, update the design plan and the current-date changelog in the same change.

## Ability design reference

Before creating or materially changing a custom ability, selecting or repurposing a Warcraft III base ability, or diagnosing Object Editor ability behavior, search `_developer/Abilities/Warcraft 3 WE Ability Insight.md`. Read the relevant ability section, its latest-tested-version note, tags, field behavior, AI behavior, and linked comments, including exported resolution/reopen markers. Treat the document as a versioned research reference rather than authority over current game behavior: reconcile it with current PotS JASS and Object Editor data and validate risky, patch-sensitive, multiplayer, crash, or desync claims in the current Warcraft III build. Use `.agents/skills/warcraft-ability-insight/SKILL.md` for the detailed workflow. Regenerate the Markdown with `_developer/Abilities/Convert-AbilityInsightDocx.ps1` when its source DOCX changes; do not hand-edit generated source content.

## Subagent policy

Use subagents only for independent, bounded work.

Good subagent tasks:
- read-only codebase exploration
- call-site and dependency inventories
- test execution and failure classification
- SQL reference searches
- mechanical changes in non-overlapping files
- independent code review

The primary agent must retain responsibility for:
- task decomposition
- cross-library reasoning
- architecture decisions
- edits affecting shared interfaces
- resolving conflicting findings
- integration
- compilation and testing
- final diff review

Prefer Terra Medium for repository investigation.
Prefer Luna Medium for clear, repetitive work.
For everyday usage prefer Sol Medium parent + Terra Medium subagents, with Luna Medium explicitly requested for mechanical tasks.
Use Sol Low + Luna Medium when you already understand the architecture and can state the subagent assignments precisely. Do not make it the universal default merely because the repository is large. Repository size increases the value of parallel searching, but dependency complexity increases the reasoning required from the orchestrator.

Do not allow parallel agents to modify overlapping files.
