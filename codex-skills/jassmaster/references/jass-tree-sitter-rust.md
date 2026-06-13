# JASS Tree-sitter Rust Notes

Use this reference when a JASS task benefits from parser-backed structure rather than plain-text inspection.

Source repo:

- `https://github.com/WarRaft/JASS-Tree-sitter-Rust`

## What it is

- A Rust-based Tree-sitter grammar and VS Code tooling stack for Warcraft III formats, with JASS as the primary scripting language target.
- A standalone LSP server provides JASS diagnostics, definition/reference navigation, rename, hover, completion, formatting, document symbols, and related editor features.

## JASS features to rely on

- Cross-file symbol resolution across linked files.
- Call graph construction and unused-function detection.
- Topological function ordering for builds so callees are emitted before callers.
- Handle leak diagnostics for local handle variables not nullified before every function exit.
- Import directives that connect files into a shared scope.

## Import and build directives

Use these only when the project or file already follows this tooling model, or when the user explicitly wants it.

- `//import path/to/file.j`
- `//import! path/to/file.j`
- `//import-ujapi! ujapi/file.j`
- `//entry`
- `//set build-jass <path>`
- `//ignore ...`
- `//@ignore ...`

## Leak workflow

- Prefer fixing the leak instead of suppressing the diagnostic.
- Make sure cleanup happens on every return path, not only the happy path.
- Destroy/remove the underlying object first when required by the handle type, then null the local variable.
- Use suppression comments only for deliberate and understood exceptions.

## Practical use in PotS work

- Use parser-backed symbol lookup before manually tracing large UI or system libraries.
- Use call graph awareness when reorganizing helpers to satisfy JASS ordering rules.
- Use leak diagnostics as a review pass after refactors that add locals, early returns, or new cleanup paths.
