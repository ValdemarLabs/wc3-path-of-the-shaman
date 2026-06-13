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
5. Use parser-aware tooling guidance from [references/jass-tree-sitter-rust.md](references/jass-tree-sitter-rust.md) when structural analysis, cross-file symbol resolution, import handling, or leak diagnostics matter.
6. Add or fix comments only where they improve maintainability.
7. Ensure every standalone library has the required top header block. Use `Valdemar` as the default author unless the user provides another name.

## Core JASS Principles

- Declare user-defined functions before their first direct use whenever possible.
- Treat forward references as disallowed in normal JASS structure. Reorder helpers instead of relying on later declarations.
- Use `ExecuteFunc("FunctionName")` only as a last resort when direct reordering is impractical.
- Only use `ExecuteFunc` for no-argument functions. Do not try to use it for parameter passing.
- Prefer clear call graphs, explicit initialization order, and small helper functions over clever indirection.
- Prefer parser-confirmed symbol and call relationships over guesswork when the toolchain exposes them.
- Preserve compatibility with basic JASS language rules before adding Reforged-specific API usage.

## Tooling Rules

- Treat `WarRaft/JASS-Tree-sitter-Rust` as the preferred structural reference when the user is working in that VS Code toolchain or when its parser/LSP output is available.
- Use it to confirm cross-file definitions, reference chains, call graphs, unused functions, and import relationships rather than inferring them from partial file reads.
- Respect its JASS build requirement that callees appear before callers. If needed, reorder helpers instead of masking ordering problems.
- Read [references/jass-tree-sitter-rust.md](references/jass-tree-sitter-rust.md) when the task involves imports, entry files, diagnostics, leak fixes, or build ordering.

## Handle Leaks

- Assume local handle variables leak unless they are released or explicitly nullified before every exit path.
- Null local handle-type variables with `set variable = null` before `return` and before the implicit `endfunction` exit when they still hold references.
- Check common handle categories carefully: `unit`, `group`, `force`, `timer`, `trigger`, `location`, `rect`, `boolexpr`, `effect`, `lightning`, `quest`, `dialog`, `multiboard`, `leaderboard`, and similar handle-backed locals.
- Destroy or remove the underlying object where required before nulling the variable. Nulling alone does not replace `DestroyGroup`, `DestroyTimer`, `RemoveLocation`, `DestroyTrigger`, and similar cleanup calls.
- Treat leak suppression directives as exceptions for known-safe cases, not as the default fix.

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
- For parser-backed JASS analysis and editor workflows, use `https://github.com/WarRaft/JASS-Tree-sitter-Rust` as the reference for supported diagnostics, imports, call graph behavior, topological build ordering, and handle leak checks.
- Inspect local [_Blizzard/common.j](h:/Pelit/PotS_JASS/_Blizzard/common.j) for native types, constants, and native declarations before assuming a function does not exist.
- Inspect local [_Blizzard/Blizzard.j](h:/Pelit/PotS_JASS/_Blizzard/Blizzard.j) for Blizzard helper wrappers and shared constants before writing duplicate wrapper code.
- Prefer `common.j` natives for low-level capability checks. Use `Blizzard.j` helpers when PotS already relies on them or when the wrapper materially improves clarity.

## Common Requests

- "Create a new PotS JASS library for X."
- "Refactor this JASS library to match PotS style."
- "Add proper comments and the required header to this library."
- "Review this JASS code for PotS convention issues."
