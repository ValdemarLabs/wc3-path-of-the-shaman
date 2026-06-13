---
name: jassmaster
description: PotS JASS coding expert for writing, refactoring, reviewing, and documenting JASS/JassHelper code that must follow existing PotS custom library styling and conventions. Use when Codex needs to produce or modify PotS JASS libraries, add or clean up comments, enforce the required library header block, or align implementation details with nearby project patterns instead of generic JASS style.
---

# JASS Master

## Overview

Write PotS JASS in the local project style first and generic JASS style second. Inspect nearby libraries before changing structure, naming, spacing, initializer patterns, or helper usage.

## Workflow

1. Read the target file and at least one nearby PotS library with similar purpose before editing.
2. Preserve established naming, layout, and library organization unless the user asks for a larger cleanup.
3. Prefer PotS-local helpers and patterns over introducing fresh abstractions.
4. Check core language rules and available natives against the relevant reference sources before inventing workarounds.
5. Add or fix comments only where they improve maintainability.
6. Ensure every standalone library has the required top header block. Use `Valdemar` as the default author unless the user provides another name.

## Core JASS Principles

- Declare user-defined functions before their first direct use whenever possible.
- Treat forward references as disallowed in normal JASS structure. Reorder helpers instead of relying on later declarations.
- Use `ExecuteFunc("FunctionName")` only as a last resort when direct reordering is impractical.
- Only use `ExecuteFunc` for no-argument functions. Do not try to use it for parameter passing.
- Prefer clear call graphs, explicit initialization order, and small helper functions over clever indirection.
- Preserve compatibility with basic JASS language rules before adding Reforged-specific API usage.

## Comment Rules

- Add a short library-start comment block that explains purpose, install expectations, and public API.
- Add basic comments on `globals` content, configuration settings, and usage-sensitive constants.
- Add short comments before advanced sections only: non-obvious state flow, complex UI positioning, synchronization, tricky math, data transforms, or unusual control flow.
- Do not comment trivial assignments, obvious loops, or native calls whose purpose is already clear from names.
- Keep comments compact and factual.

## Library Requirements

- Include the required header format shown in [references/library-template.md](references/library-template.md).
- Keep the `Description`, `Credits`, `How to install`, and `API` sections present even if some entries are brief placeholders during scaffolding.
- Prefer meaningful API notes over long prose.
- If a file is not a full library yet, add the header when creating or promoting it into one.

## PotS Style Guardrails

- Follow the surrounding file's indentation and section ordering.
- Keep public and private separation clear through naming and placement.
- Avoid introducing verbose framework-style comments or documentation blocks inside routine code.
- Reuse existing helper libraries and local patterns when they already solve the problem.
- When style is ambiguous, choose the pattern used by the closest comparable PotS file.

## Reference Sources

- Use the JASS manual at `https://jass.sourceforge.net/doc/` as a baseline reference for core language behavior and older standard API details.
- Treat that manual as incomplete for modern Warcraft III work because its changelog shows its last update was on November 19, 2011.
- For Reforged-era UI frame work, use `https://www.hiveworkshop.com/threads/the-big-ui-frame-tutorial.335296/` as a practical reference for frame types, positioning, parenting, events, TOC/FDF usage, and multiplayer considerations.
- Inspect local [_Blizzard/common.j](h:/Pelit/PotS_JASS/_Blizzard/common.j) for native types, constants, and native declarations before assuming a function does not exist.
- Inspect local [_Blizzard/Blizzard.j](h:/Pelit/PotS_JASS/_Blizzard/Blizzard.j) for Blizzard helper wrappers and shared constants before writing duplicate wrapper code.
- Prefer `common.j` natives for low-level capability checks. Use `Blizzard.j` helpers when PotS already relies on them or when the wrapper materially improves clarity.

## Common Requests

- "Create a new PotS JASS library for X."
- "Refactor this JASS library to match PotS style."
- "Add proper comments and the required header to this library."
- "Review this JASS code for PotS convention issues."
