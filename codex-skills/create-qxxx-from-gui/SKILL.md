---
name: create-qxxx-from-gui
description: Convert old Warcraft III World Editor GUI quest giver trigger exports into PotS qXXX JASS sublibraries. Use when Codex needs to create, refactor, or review a quest-giver-specific qXXX.j library from old GUI triggers, especially Valeria, BoomBrothers, or similar NPC quest givers, while reusing QuestGiver, QuestMaster, DialogInteraction, DialogSystem, DialogCamera, and related PotS master libraries instead of mechanically porting GUI trigger internals.
---

# Create qXXX From GUI

## Overview

Convert old GUI quest giver triggers into PotS `qXXX.j` sublibraries that match the current `qAradion.j` style and master-library architecture.

The goal is gameplay-equivalent conversion, not a line-by-line GUI rewrite. Prefer established master APIs for quest state, dialog, camera, rewards, requirements, icons, companions, and common tracking. Keep genuinely questgiver-specific sequences, event hooks, spawns, patrols, and failure cleanup inside the qXXX sublibrary.

## Required Workflow

1. Read `_developer/Design Plans/Story and Quest Design.md` and locate the giver, quest status, canonical names, zone IDs, dependencies, legacy conflicts, and intended story connections.
2. Read the old GUI trigger export or user-provided trigger text. If the user's map contains unexported GUI triggers, inspect or request those triggers before claiming full parity; Articy and voice lines alone are design evidence.
3. Read the relevant structure in `QuestsAndDialogs/QuestGivers/qAradion.j`; use `rg` for sections such as `CreateQuests`, `BuildDialog`, `OnSelected`, `StartExitFadeOut`, and `InitDelayed`.
4. Read the master APIs needed for the conversion, starting with `QuestGiver.j`, `QuestMaster.j`, `DialogInteraction.j`, `DialogSystem.j`, and `Camera/DialogCamera.j`.
5. Read [references/qxxx-conversion.md](references/qxxx-conversion.md) before creating or materially changing a qXXX library.
6. If a scaffold is useful, inspect `QuestsAndDialogs/QuestGivers/tools/qxxx-generator.html`, but treat its output as a draft that still needs manual prerequisites, requirement tracking, and quest-specific behavior.
7. Also follow PotS JASS style rules from `jassmaster` when that skill is available.
8. After implementation, update the master plan's implementation ledger, dependencies, and open decisions when they changed, and add the current-date changelog entry.

## Conversion Rules

- Preserve the old questgiver's visible behavior: offered quests, dialog outcomes, rewards, objective progress, failure/retry behavior, companions, and triggered world events.
- Treat `_MISC/war3map.wts` as a read-only snapshot exported from World Editor. Use it only as supporting evidence; never edit it. The user owns map-specific World Editor changes, so list required Object Editor, GUI trigger, placed-unit, region, or string changes as manual WE follow-up.
- Do not preserve obsolete GUI implementation details when a master library already provides the same result.
- Use `QuestGiver_` wrappers over direct `QuestMaster_` calls in qXXX libraries unless the local pattern needs a `QuestData` method.
- Keep qXXX globals focused on configuration, unit references, quest-specific state, triggers, timers, dialogs, and public hooks called by map events.
- Prefer delayed initialization that waits for required `udg_` unit variables before registration and quest creation.
- Keep custom code local only when it is actually quest-specific.
- Preserve the current quest metadata model: use `normal`, `daily`, or `repeatable` for type and set `story`, `dungeon`, `class`, or `profession` separately as category where applicable.

## Deliverables

For a new questgiver, produce one `QuestsAndDialogs/QuestGivers/qXXX.j` library with:

- PotS library header and `library qXXX initializer Init requires ...`.
- Config constants and unit/dialog/state globals.
- `SyncUnitReferences`, dialog entry/exit helpers, quest accept/complete/fail handlers, `BuildDialog`, `CreateQuests`, delayed init, and public hooks needed by old GUI events.
- Calls to master APIs for shared behavior and short comments only where the conversion is not obvious.

## Validation

Before finishing a conversion, check:

- The qXXX library declares functions before direct use or uses `ExecuteFunc` only for no-argument delayed callbacks.
- Every old GUI trigger outcome has an equivalent qXXX path or an explicit note explaining why it is obsolete.
- No generated `QUEST-SPECIFIC` scaffold markers remain unless the user explicitly asked for a scaffold.
- Item, kill, escort, talk, find, go-to, reputation, and investigate objectives use the existing `QuestGiver` trackers where applicable.
- Dialog buttons use `QuestGiver_AddAvailableQuestAcceptButton`, `QuestGiver_AddReadyQuestCompleteButton`, `QuestGiver_AddFailedQuestButton`, or an established `DialogSystem` button only when a wrapper does not fit.
