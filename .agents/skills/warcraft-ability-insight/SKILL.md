---
name: warcraft-ability-insight
description: Research, design, implement, or review PotS Warcraft III abilities using the repository's converted Ability Insight reference. Use when choosing or repurposing a base ability, interpreting Object Editor fields, investigating rawcodes, AI casting, buff stacking, targeting, damage/healing behavior, morphs, or engine quirks. Do not use for unrelated JASS work that does not depend on ability behavior.
---

# Warcraft Ability Insight

Use the repository's searchable [Warcraft 3 WE Ability Insight](<../../../_developer/Abilities/Warcraft 3 WE Ability Insight.md>) as a research input for custom ability decisions. It contains stock ability observations, rawcodes, behavioral tags, field tests, patch notes, inline comment links, and an appendix preserving every exported comment. Credit for the original document belongs to HiveWorkshop user **ScrewTheTrees**; retain the link to [The Warcraft 3 Ability Insight Document](https://www.hiveworkshop.com/threads/the-warcraft-3-ability-insight-document.294584/) when redistributing or deriving documentation from it.

## Workflow

1. Define the required gameplay behavior and its constraints: active/passive/autocast, target types, stacking, dispel/steal behavior, damage or healing semantics, AI use, and multiplayer sensitivity.
2. Search the Markdown by base-ability name, four-character rawcode, and relevant tag or field term. Use the generated table of contents for neighboring alternatives.
3. Read the entire matching ability section, not only the matching line. Follow every inline comment link and check `Latest tested version`, `TODO`, `Unused`, `Dummy Ability`, and `Depreciated` labels.
4. Compare the findings with the closest PotS ability implementation and current Object Editor data. Check `_Blizzard/common.j` and `_Blizzard/Blizzard.j` before assuming a native or helper is unavailable.
5. Choose a stock base ability only when its documented hardcoded behavior fits the use case. Prefer explicit JASS control when an Object Editor field is documented as ignored, refresh-dependent, unsafe, or patch-sensitive.
6. Keep JASS changes in the repository and report rawcode creation, field configuration, buff creation, icons, orders, and other Object Editor work as manual World Editor follow-up.
7. Validate compile order and cleanup in JassHelper, then test the affected ability in a focused map and the full map. Test multiplayer when orders, local UI, synchronization, ownership, morphing, or documented desync risks are involved.

## Evidence rules

- Treat the reference as a versioned collection of observations, not a guarantee for the current Warcraft III patch.
- Keep the documented rawcode casing when searching, while checking suspicious `I`/`l` and upper/lower-case variants against actual Object Editor data.
- Distinguish negative damage from healing and negative healing; armor, resistance, attribution, and kill credit can differ.
- Do not rely on a shared buff ID or a changed buff ID to stack unless the selected base ability's section supports it in the relevant patch.
- Treat crash, permanent visual leak, unremovable state, and desync notes as design blockers until current-version testing disproves them.
- The DOCX export has no modern resolved-thread metadata. The Markdown labels resolution and reopen events only where those events survived as comment text; do not infer missing thread relationships.

## Maintaining the reference

The Markdown is generated content. When `_developer/Abilities/Warcraft 3 WE Ability Insight.docx` changes, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\_developer\Abilities\Convert-AbilityInsightDocx.ps1
```

Confirm that the reported heading count, comment count, and contextual comment-reference count are nonzero and that all exported comments have both an inline link and an appendix entry.
