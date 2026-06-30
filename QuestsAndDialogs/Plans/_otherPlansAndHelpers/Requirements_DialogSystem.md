=====================================================================================================
# DialogSystem Requirements

Last updated: 2026-02-19
=====================================================================================================

## Dialogue construction - generic dialog flow
- DialogSystem should have basic dialogue construction function - e.g., in OLDGui trigger "Button Pressed in AradionDialog01.md" there is a lot of dialogue - we should be able to create easily the dialogue flow in qAradion / questGiver sublibrary
- We should build simple dialog flow into the system - i.e. dialog paths and end result - most will practically have at max 2 outcomes but usually only 1 despite multiple paths that give feel of in-control for the player

## Dialog sequences
- besides AddLines, Delays, facings, we should have also action to move to point or play animation configurable with delay or no delay

## Modularity
- More modularity (especially in regards to qAradion / qSublibrary)
- Not really sure whats the best way to approach to make the systems modular - and especially make it easy for each qGiver (sublibrary) make easy to re-use for other quest givers and also easy for me refactor old gui triggers into the new JASS sublibraryfor

## Other notes
- see qAradion.j (single quest giver sublibrary), how to make repeating/re-occurring dialogsystem related functions be more developed inside DialogSystem rather than "hardcoding" to each questgiver sublibrary (like qAradion)