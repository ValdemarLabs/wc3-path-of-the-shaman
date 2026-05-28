# DialogSystem Refactor Plan

_Last updated: 2026-02-19_

## Overview
This plan outlines improvements for `DialogSystem.j` based on the requirements in `Requirements_DialogSystem.md` and analysis of the current implementation. The goal is to make dialog creation easier, more modular, and reusable for all quest givers.

## 1. Easier Dialogue Flow Construction
- **Goal:** Allow simple, declarative creation of dialog flows for quest givers.
- **Actions:**
  - Add helper functions or a builder pattern to define dialog trees and outcomes.
  - Enable easy specification of dialog paths, choices, and end results.
  - Provide clear API for registering dialog flows in sublibraries (e.g., qAradion).

## 2. Expanded Dialog Actions
- **Goal:** Support more in-dialog actions beyond lines, delays, and facings.
- **Actions:**
  - Add built-in support for unit movement ("move to point") and playing animations as dialog actions or any actions
  - add built-in support to easily create special effects in dialog sequence (use SpeciFX.j for special effects)
  - Allow configuration of delays for these actions.
  - Ensure these actions can be chained or combined with existing dialog steps.

## 3. Improved Modularity
- **Goal:** Make dialog logic reusable and easy to extend for different quest givers.
- **Actions:**
  - Refactor common dialog patterns (greetings, farewells, trade, etc.) into reusable templates or functions.
  - Allow quest givers to register their unique lines and behaviors via a clean API.
  - Minimize code duplication in sublibraries by centralizing logic in DialogSystem.

## 4. Reduce Hardcoding in Quest Givers
- **Goal:** Move repeated dialog logic out of individual quest giver files.
- **Actions:**
  - Centralize dialog sequence templates and common actions in DialogSystem.
  - Provide mechanisms for quest givers to supply only their unique content and custom logic.
  - Document best practices for integrating quest givers with the new system.

## 5. Documentation & Migration
- **Goal:** Ensure smooth adoption and clear usage for future dialog content.
- **Actions:**
  - Update documentation with examples for the new API and patterns.
  - Provide migration guidelines for refactoring old GUI triggers and sublibraries to use the improved DialogSystem.

---

_This plan will guide the next steps in refactoring and extending DialogSystem.j to meet project needs._

## 6. Backward Compatibility & Additive Approach
- **Goal:** Ensure existing systems and dialog usage are not broken by refactoring.
- **Actions:**
  - Avoid breaking changes to current DialogSystem API and usage patterns.
  - Prefer adding new functions and helpers, rather than changing or removing existing ones.
  - When making generic functions, base them on how dialogs and dialog events are currently used and desired in files like qAradion.j.
  - Generic functions/templates should support:
    - Random or conditional dialog blocks (e.g., pick a line from a set, or branch based on quest state).
    - Quest-state-driven dialog construction, allowing for dynamic and context-sensitive dialog flows.
    - Custom logic/callbacks where needed, so advanced or unique dialog flows can still be implemented cleanly.
    - Both simple and advanced dialog flows, so helpers are useful for all quest givers.
    - We should build simple dialog flow into the system - i.e. dialog paths and end result - most will practically have at max 2 outcomes but usually only 1 despite multiple paths that give feel of in-control for the player
  - Consider adding planning for reusable dialog templates (e.g., greet, info, quest in progress) that can be parameterized and extended.
  - Allow gradual migration and adoption of new features without disrupting current quest givers or dialog flows.

  ## 7. ESC key function (Skipping cinematic)
 - we should be able config whether skip is allowed, by default it is - but sometimes for some cutscenes/dialogues we may not want skip to be allowed
