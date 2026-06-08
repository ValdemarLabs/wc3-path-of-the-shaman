# qAradion Readiness and qXXX Generator Plan

## Summary
- Current situation:
  - The roadmap workbook is strategic and lagging behind code reality. It still shows the alpha quest-pipeline objectives as effectively not started, even though `QuestMaster`, `QuestGiver`, `DialogSystem`, and `qAradion` already exist.
  - For the roadmap, this work is on the immediate critical path for `Foundation locked` on August 23, 2026 and `Systems stable for alpha buildout` on October 2, 2026.
  - The latest TODO export is the real granular source of truth here: `QuestGivers library` has 128 unchecked checklist items, `questGiver_qAradion` has 20 unchecked items, and the June 6, 2026 follow-up task still says `qAradion` is not on the main map and modularity must be improved.
  - `qAradion.j` is functional as a prototype, but it is not yet template-quality: it still contains production gaps, debug/test quest content, old-GUI parity gaps, manual cinematic flow, and map-specific glue.
- Priority decision:
  - Use a parity-first implementation wave.
  - Finish `qAradion` enough that it becomes the canonical production example, then build the helper app on top of that stabilized pattern.
- Helper-app decision:
  - Build a tiny browser-based generator.
  - v1 should generate a content template, not just an empty skeleton.

## Implementation Changes
1. Finish `qAradion` as the canonical production sublibrary.
- Remove or gate the six test quests behind a clear debug-only switch so production dialog only exposes real Aradion quests.
- Port the missing old-GUI quest-side effects into JASS for the four shipped Aradion quests:
  - Quest 1: Valeria discovery/escort completion flow, Ghost/Wander handling, companion add/remove, movement back to Aradion, correct requirement text `Escort Valeria to Aradion`, correct completion-state changes, patrol/resume behavior after reunion.
  - Quest 3: grant Tel'anor Rod on accept, remove it on completion, keep item-removal and quest completion in sync.
  - Quest 4: accept/start actions, fail-trigger enable/disable, rift-start and rift-complete side effects, Valeria/Aradion post-quest recovery flow.
- Replace the remaining required `OLDGUI/Example_qAradion/RangerMissingEvents/*` behavior with JASS-owned logic or thin JASS-called bridge hooks; do not leave quest-critical behavior trapped in old GUI triggers.
- Fix the known dialog-flow issues in the live file:
  - wrong hero / wrong speaker during first greet and info
  - Info-end dialog rebuild timing
  - Ranger Missing not appearing immediately after backstory
  - selection/cooldown/cinematic return regressions
  - completion-button availability checks for item and escort conditions

2. Harden shared systems only where they directly unblock Aradion parity.
- Keep changes additive; do not do a framework-first rewrite.
- Reuse the existing shared helpers already present in `QuestGiver` where safe, and refactor `qAradion` back toward those helpers for accept/complete/farewell flows after parity fixes are in.
- Add only the missing shared primitives required by old-GUI parity:
  - `DialogSystem` support for move-to-point and play-animation sequence actions if Aradion parity needs them.
  - shared wrappers for common companion/escort side effects only if the same logic would otherwise be copied again in the next quest giver.
- Investigate and remove duplicate cinematic ownership between `qAradion` and `Cinematic ON/OFF`, especially duplicate mover/camera control.
- Keep the current auto-increment quest-ID model for this wave; do not introduce manual quest IDs yet.

3. Reintegrate `qAradion` into the main map as the first real production user.
- Wire the current JASS version onto the main map after the parity pass, not before.
- Standardize the external/public hook boundary so map systems call JASS intentionally instead of relying on scattered old GUI behavior.
- Keep `qAradion` as the only supported production quest-giver path until its regressions are closed.

4. Build the tiny browser helper app after `qAradion` is stable enough to template.
- Build a static local HTML/JS tool with no backend.
- Inputs:
  - NPC/library/file name
  - allowed heroes and cinematic/camera flags
  - quest list with quest type, title, icon, receiver mode, requirements, rewards, and whether accept/complete/fail handlers are needed
  - optional public hook stubs for external progression events
- Output:
  - one generated `q<Name>.j` file using the stabilized `qAradion` structure
  - filled `CreateQuests()` content blocks
  - dialog button wiring
  - empty or partially scaffolded accept/complete/fail sequence functions
  - explicit `TODO OLDGUI PARITY` markers for event-specific custom logic
- v1 should not attempt automatic old-GUI trigger conversion, workbook editing, or map-trigger generation.

5. Reconcile planning artifacts after the code pass is verified.
- Once `qAradion` is on the main map and the parity pass is tested, refresh the roadmap workbook/objective statuses so the quest-pipeline tracker reflects reality.
- Do not update roadmap status optimistically before main-map verification.

## API / Interface Changes
- Shared library changes must be additive only.
- Stabilize the sublibrary contract that the generator will target:
  - config/constants block
  - `CreateQuests()`
  - `BuildDialog()`
  - `OnSelected()`
  - per-quest `OnAccept*`, `OnComplete*`, optional `OnFail*`
  - public external update hooks
- Generator public interface:
  - browser form inputs -> generated `q<Name>.j` content template
  - import/export of a tiny JSON spec is allowed, but optional for v1

## Test Plan
- Dialog entry with both `Nazgrek` and `Zulkis`: correct speaker, correct interacting hero, correct camera restore.
- Backstory flow: Info plays, ESC behavior is correct, dialog rebuilds immediately, Ranger Missing appears without needing to leave and reselect.
- Ranger Missing chain: Valeria first encounter, negotiation success path, companion join, escort to Aradion, reunion completion, failure branch, death handling.
- Crystals of Hope and Fading Sparks: item-progress updates, completion button only when items are actually carried, correct quest-log text, Tel'anor Rod grant/remove.
- Rifts of Corruption: start actions, per-rift counter update, ready-turn-in gating at 3/3, fail conditions for Aradion/Valeria death, complete cleanup.
- Exit flow: no black screen, no stuck control loss, no duplicate cinematic movement, cooldown respected.
- Main-map regression: `qAradion` works there, not just in isolation.
- Generator smoke test: create one sample `qXXX` file and verify it compiles against the current shared APIs.

## Assumptions
- `qAradion` remains the canonical template for future quest givers.
- Manual quest IDs are deferred; current automatic IDs stay in place.
- Old GUI files remain reference material only; quest-critical behavior must end up owned by JASS.
- The first helper app is intentionally small and local, optimized for speed of use rather than full automation.
