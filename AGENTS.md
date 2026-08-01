# Repository Guidelines

## Project Structure & Module Organization

Path of the Shaman is primarily vJASS/JassHelper code grouped by gameplay feature. Add source to the existing domain folder, such as `Abilities/`, `Arena/`, `QuestsAndDialogs/`, `UI/`, or `UnitSystems/`. Shared and imported dependencies live in `_CoreSystems/`; use `_Blizzard/common.j` and `_Blizzard/Blizzard.j` as native and helper references. Frame definitions and load lists are under `_fdf/` and `_tocs/`. Database-generated JASS is written to `WC3_Export/`, while the Windows item tool lives in `WC3_Database/WC3ItemManager/`. Tests are generally focused `.j` harnesses beside their systems. Treat `backups/`, `_Old*`, `bin/`, and `obj/` as historical or generated unless explicitly targeted.

## Build, Test, and Development Commands

There is no single repository-wide build command. Useful local checks are:

```powershell
rg --files -g "*.j"                                      # inventory JASS sources
dotnet build .\WC3_Database\WC3ItemManager\WC3ItemManager.csproj
dotnet run --project .\WC3_Database\WC3ItemManager\WC3ItemManager.csproj
powershell -ExecutionPolicy Bypass -File .\Installer\build-installer.ps1
```

The installer command requires prepared `Installer/payload/` content and Inno Setup. Validate gameplay code by importing it through the normal Warcraft III/JassHelper workflow, compiling an affected test map, then compiling the full map. Standalone `pjass` is insufficient for these vJASS libraries.

## Coding Style & Naming Conventions

Use four-space indentation and follow the closest comparable library. Keep callees before callers, initialization order explicit, and public/private APIs clearly separated. Prefix globals and internal helpers with the owning system (`Arena_Active`, `MUI_CreateFrames`); use descriptive PascalCase library and file names. Standalone libraries require the standard header sections: `Description`, `Credits`, `How to install`, and `API`. Destroy owned handles when required, then null local handle variables on every exit path. Keep comments short and reserve them for configuration or non-obvious flow.

## Testing Guidelines

No automated test framework or coverage threshold is configured. Name focused harnesses consistently with existing files, for example `*_TestMap.j`, `*_testing.j`, or `*_testFunctions.j`. Verify compile success, initialization, cleanup, and affected runtime behavior. Multiplayer-sensitive UI, frame events, and synchronized state require multiplayer testing. For item-manager changes, run `dotnet build` and exercise the affected workflow against a non-production database.

## Commit & Pull Request Guidelines

Recent history uses short, direct, sentence-case summaries without Conventional Commit prefixes, such as `Add Circle of Blood arena zone`. Keep each commit cohesive and describe the observable result. Pull requests should list affected systems, dependencies or import-order changes, test-map/full-map results, and known validation gaps. Include screenshots for UI/frame changes and identify regenerated exports separately from hand-edited source.

## Changelog and commit messages

Always update `Pots Changelog.md` on the current date.
Write short commit messages in chat per changed files or sometimes for many files if the commit is clearly for many files.

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