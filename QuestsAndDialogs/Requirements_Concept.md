=====================================================================================================
# Quest System Requirements

Last updated: 2026-02-07
=====================================================================================================

## Purpose
Define the requirements for a full quest system with a core library and related sublibraries. This document is the baseline for implementing the new Quest system in the Quests folder.

## Scope
- Provide a unified quest framework that covers quest availability, progress tracking, completion, and visual feedback.
- Consolidate or replace behavior from the existing QuestIconSystem and QuestEvaluationSystem.
- Support configuration-driven quests with level, reputation, and custom conditions.

## Non-Goals (for now)
- Full GUI editor or in-game quest journal UI.
- Networked synchronization beyond the standard Warcraft III multiplayer model.
- Automated content generation for quest text or dialog.

## Dependencies
- Reputation system (factions and reputation values).
- SpeciFX or equivalent effect handling for overhead icons.
- Standard Warcraft III JASS/vJASS runtime.
- Bribe's Table v6 (TableV6) for persistent quest data storage (replace raw hashtables).

## Terminology
- Quest State:
  - 1 = Unavailable
  - 2 = Available
  - 3 = In Progress
  - 4 = Complete (no icon)
  - 5 = Ready to Turn In
- Quest Type:
  - "normal", "daily", "repeatable", "dungeon"
- Dummy quest: internal quest entry used for availability display before player acceptance.

## Architecture Overview
The system is composed of a core library and sublibraries. Evaluation and icon handling are implemented inside QuestMaster by default, with optional thin sublibraries if we decide to split later.

- QuestMaster (core)
  - Owns shared data structures and global configuration.
  - Provides a stable public API for quest registration and lifecycle events.
  - Implements availability evaluation and icon handling internally.
  - Consolidates any duplicated logic from legacy systems (state priority, quest lists, active checks).
  - Provides quest templates and creation helpers (kill, fetch, kill+fetch).
  - Use ZonesCore.j as coding guidance for library/data structure patterns.
  - Centralize functionality currently split across QuestIconSystem and QuestEvaluationSystem (to be audited).

- QuestGiver (sublibrary)
  - Handles registration/unregistration of quest giver NPCs.
  - Maintains per-NPC quest lists and metadata.
  - Use ZonesCore.j as coding guidance for library/data structure patterns.
  - Provides base creation APIs for quest giver NPCs.
  - Must be used by per-giver sublibraries located in the QuestGivers folder.

- QuestEvaluationv2 (optional sublibrary)
  - Thin wrapper that calls QuestMaster evaluation hooks.
  - Use only if we want replaceable evaluation logic later.

- QuestIconsv2 (optional sublibrary)
  - Thin wrapper that calls QuestMaster icon hooks.
  - Use only if we want replaceable icon logic later.

## Functional Requirements

### Core Quest Lifecycle
- Must support quest registration with unique quest IDs and a quest type.
- Quest IDs must be auto-incremented at creation (no manual ID assignment).
- Must allow quest acceptance, progress updates, completion, and turn-in.
- Must allow quests to be set active/inactive, impacting availability display.
- Must support daily and repeatable quests (re-availability after reset).
- Must provide a manual override API to force a refresh of quest availability.
- Must expose `QuestAccept`, `QuestComplete`, `QuestUpdate` style APIs (exact names TBD).
- Must support quest discovery and quest completed messaging with quest log flash.
- Must support quest failure states and explicit reset flows (fail -> reset -> rediscover).
- Must support quest update messages with dynamic requirement text updates.
- Must support storing quest level and quest giver level for reward calculations.
 - The old GUI triggers under OLDGUI/ (especially Quest System Create Template) are authoritative reference patterns for new data structures and creation flows.

### Quest Availability Evaluation
- Must support these requirement checks:
  - Minimum hero level (use the highest level among configured heroes).
  - Faction reputation threshold.
  - Custom boolean condition triggers.
  - Optional event flags (boolean array).
- Must run evaluation on a configurable timer (default 5 seconds), implemented in QuestMaster.
- Must avoid showing availability icons when an NPC has active quests in progress or ready to turn in.
- Must avoid redundant updates if state has not changed since last evaluation.

### Quest Giver Management
- Must allow registering and unregistering NPCs as quest givers.
- Must support multiple quests per NPC.
- Must maintain a unique NPC list for efficient evaluation.
- Must allow quest giver scripts to create dialog flows that gate options by quest state.
- Must support hundreds of quest givers with consistent, lightweight setup.
- QuestGivers library must expose a flexible base pattern that supports per-giver customization while keeping sublibrary creation minimal.

### QuestGivers Responsibilities Split
- **QuestGivers Base:** Provide registration, shared data helpers, dialog/button gating utilities, item-check helpers, and standardized hooks for quest accept/update/complete/fail.
- **Per-Giver Sublibrary (qX):** Define NPC-specific dialog flow, cinematic sequences, custom conditions, quest creation calls, and any bespoke event wiring.

### Visual Icon Behavior
- Must display overhead quest icons and minimap pings based on state and type.
- Must use distinct models for:
  - Available: yellow exclamation (normal, dungeon), blue exclamation (daily, repeatable).
  - In progress: gray question.
  - Ready to turn in: yellow question (normal, dungeon), blue question (daily, repeatable).
  - Unavailable: gray exclamation.
- Must respect icon priority when multiple quests exist for one NPC.
- Must update minimap ping style based on availability or turn-in states.
- Must remove icons when state is complete or when no quests remain.

### API and Compatibility
- Must expose a stable API for:
  - Register/unregister quest givers.
  - Add quest requirements.
  - Mark quest active/inactive.
  - Update quest state and refresh icons.
  - Add custom condition triggers.
  - Display quest discovered and completed messages (with requirement/reward text support).
  - Display quest update and failed messages.
- Should provide compatibility wrappers for existing QuestIconSystem and QuestEvaluationSystem calls (TBD). If optional sublibraries exist, they should be wrappers around QuestMaster.
- Should provide compatibility for legacy dummy quest usage (ID 9999) and refresh patterns.
 - Quest System Create/Discover/Complete/Save/Load GUI triggers should be fully reflected in the new core APIs and data structures.

### Limits and Defaults
- Must support at least 500 quests and 100 quest givers (configurable limits).
- Must define a dummy quest ID offset to avoid collisions with real IDs.
- Must provide a debug mode toggle for tracing state evaluation.

## Data Model Requirements
- Per quest:
  - Quest ID (integer, unique).
  - Quest type (string enum).
  - Quest level and quest giver level (for rewards and UI).
  - Required level (integer, 0 for none).
  - Required faction and reputation (or none).
  - Custom condition trigger (optional).
  - Last known evaluation state.
  - Active flag (tracked by QuestMaster).
  - Quest rewards data (XP, gold, items, reputation, custom callbacks).
  - Reward calculation parameters (base multiplier + adjustment for XP, gold, arena marks, reputation).
  - Reward calculation must clamp negative results to 0.
  - Reputation reward must support linked vs direct modes.
  - Reward text fragments and heading (for quest completed messages).
  - Requirement text lines (up to 8 entries) used in quest discovered messages.
  - Quest failure state and failure reason text.
  - Quest objective text entries that can be updated in place.
  - Quest icon path, title, description, and info text (quest giver + recommended level).
- Per NPC:
  - Quest list (ordered).
  - Active quest count and state summary for icon priority.

### QuestMaster Structures
- Must define a `QuestData` structure with:
  - Static `create` factory method for new quests.
  - Fields for name, description, type, giver, requirements, rewards, and objectives.
  - Methods for state transitions (accept, update, complete, abandon).
  - Methods to format quest requirement text and reward summaries.
  - Methods to format quest update and failed messages.
  - Methods to update quest requirement descriptions in-place.

### Quest Log / UI Integration
- Must support creating Warcraft III quest log entries with title, description, icon, and requirements.
- Must support adding additional quest requirements during progress updates.
- Must allow marking specific quest requirements complete or incomplete.
- Must allow changing quest requirement descriptions during progression.
- Must support flashing the quest dialog button on updates/discover/complete/fail.

### Persistence and Lookup
- Must support mapping between quest objects and quest IDs (bidirectional).
- Must allow saving and loading quest state using TableV6 (quest ID, type, giver, state, and any required metadata).

### Quest Templates
- Must provide reusable templates for common quest types:
  - Kill quest (target unit types + required count).
  - Fetch quest (item types + required count).
  - Combined kill+fetch quest.
- Templates should be usable by sublibraries with minimal boilerplate.

### Scripted Quest Flows (from GUI patterns)
- Must allow quest giver sublibraries to orchestrate dialog and cinematic flows tied to quests.
- Must allow gating dialog buttons based on quest states and additional conditions (distance, alive checks, combat flags).
- Must support item check helpers for dialog gating and completion (e.g., `HeroItemCheckBoth`, `HeroItemCheckBothAndRemove`).
- Must support time-based objectives and countdown timers with UI feedback (floating text or messages).
- Must support event-driven objectives: unit enters region, item acquired, ability start/finish, and custom events.
- Must support companion/escort logic hooks (add/remove companions, follow, escort completion).
- Must support failure triggers tied to NPC death or other events, and cleanup routines (disable waves, reset rifts, restore NPCs).
- Must support wave-based combat events with reusable wave helpers.
- Must allow dialog cooldown or re-entry gating timers after conversations/cinematics.

## Non-Functional Requirements
- Performance: evaluation must not cause noticeable spikes with 500 quests.
- Maintainability: keep the API small and documented; avoid duplicate state logic.
- Extensibility: allow adding new requirement checks without breaking APIs.
- Determinism: state transitions should be consistent across evaluations.

## Integration Points
- Hero level-up should trigger immediate availability refresh.
- Reputation changes should trigger immediate availability refresh.
- Quest acceptance/turn-in triggers must call the core API.
- Daily quest resets should hook into the existing day/night system:
  - Event: "Game - DNE_DayNightEvent becomes Equal to 1.00"
  - Data: udg_DaysPassed increment, udg_DayPassed boolean true for one second
  - The quest system should consume this event to reset daily quests.
- Quest giver sublibraries must be able to call into other game systems used by legacy GUI (dialog camera, cinematic control, ExSound, WithinRange, companion systems).
- Item/inventory helpers from other systems must be callable for quest gating and completion.

## Query and Lookup Requirements
- Must allow lookup by quest name, quest giver name, and quest giver unit.
- Must allow querying quest status by quest name and quest giver unit:
  - States include not discovered, available, active, ready to turn in, complete.
- Must provide get/set APIs for quest status for a given quest giver unit.

## Open Questions
- Persistence: should quest states be saved/loaded across sessions?
- Compatibility layer: which legacy calls must remain intact?
- Repeatable cooldown rules beyond daily resets.
- Do we need optional wrapper sublibraries (QuestEvaluationv2/QuestIconsv2), or keep everything in QuestMaster permanently?

## Player Model
- Single-player only, evaluation and state are for Player(0).

## File Layout
- Quests/QuestMaster.j
- Quests/QuestGiver.j
- Quests/Requirements.md
- Quests/QuestGivers/ (one sublibrary per quest giver)
  - Each sublibrary must create quests using QuestMaster and QuestGiver APIs.
  - File naming should be NPC-based and concise, e.g., qAradion.j, qValeria.j.
- Optional (only if we split later):
  - Quests/QuestEvaluationv2.j
  - Quests/QuestIconsv2.j
