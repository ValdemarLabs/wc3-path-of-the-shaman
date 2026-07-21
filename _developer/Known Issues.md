# WC3 - Path of the Shaman
## KNOWN ISSUES
*Last updated: 2026-07-22*

> ### Known issues usage notes
> Pull current confirmed issues from `_Changelogs/PotS Changelog.md` and keep this file as the working summary.
> Strike through issues only when the changelog has a concrete later fix or replacement, and add a short comment explaining why it is considered fixed or superseded.

## Current Open Issues

### Build, Import, and Validation
- Full in-map JassHelper / Warcraft III compile validation is still missing across several recent JASS passes because the repo snapshot does not expose a combined `war3map.j` or normal map build entry point.
- The newest libraries and UI systems still need normal map-build import/order validation, especially:
  - `Abilities/AbilitiesPlayer.j`
  - `Abilities/Abilities.j`
  - `Abilities/Talents.j`
  - `UI/AbilitiesUI.j`
  - `UI/TalentsUI.j`
  - `Events/Events.j`
  - voiceline speaker libraries required by `qAradion.j`, `AI.j`, `AI_Voicelines.j`, and `AI_CompanionReplies.j`
- The bundled `pjass` only validates plain JASS and is not a useful validator for standalone vJASS libraries by itself.

### Abilities, Talents, and Leveling
- The new ability/talent libraries still need in-game validation with the actual trainer units (`o625`, `o626`, `o627`, `o628`), Nazgrek, Zul'kis, and the current object-data rawcodes.
- Old GUI player ability add/level/reset triggers should be disabled after the JASS learner is imported, otherwise ability learning/reset behavior can double-run or conflict.
- The old GUI triggers under `Leveling/_oldGUI` must be disabled after the new AP/rested/base-camp/camp-fire libraries are imported, otherwise AP/rested/base-camp/camp-fire behavior can double-run or conflict.
- Talent helper APIs exist, but individual ability scripts still need to be wired to the relevant talent effect helpers before every talent has visible gameplay impact.
- Talent save/load persistence is not implemented yet; current talent ranks live only in runtime JASS state.
- `TalentsUI` tooltip placement and dependency link textures need in-game visual validation on the Warcraft III frame layer.
- The tent death animation still uses a configurable first-pass death-animation unit rawcode and should be verified in-game against the intended tent death visuals.
- Tent Sleep and the delayed dismantle-item fallback still need in-game validation with both legacy GUI handlers enabled and disabled.

### Events and Trigger Routing
- The 22.7.2026 event refactor is high risk. Any system that relied on direct trigger registration order, disabled trigger state, or event response timing should be retested in-game.
- GUI `Floating Texts Spell Event` must be manually registered once through `Events_RegisterPlayerUnitTrigger`; leaving the old per-unit add-event behavior enabled can keep recreating the original event-bloat risk.
- Remaining direct event registrations still exist in separate quest/gather/UI/imported/old systems. They were not all migrated in the 22.7.2026 pass.

### AI, Professions, Gathering, and Crafting
- The AI library stack still needs in-map runtime validation for random spawning, multiple same-profile AI instances, companion invite/kick/mode barks, Warlock imp ownership/behavior for both unit types, Shaman totem ownership/MUI behavior, Valeria/qAradion control handoff, companion reinvite/order repair, and old GUI trigger retirement.
- AI shop buy/sell initiation and the `/debug aibuy`, `/debug aisell`, and `/debug aishop` commands still need in-map validation with real registered shop units and full/empty AI inventories.
- Direct AI-created camp fires still need in-game validation for `/debug aicamp`, Warmth/rested registration, light cleanup, and normal autonomous night-camp timing.
- Low-skill/wrong-profession AI gather-node blocking still needs in-game retesting around Tin Vein and gather-item nodes, especially with companion/player-issued target orders.
- AI profession harvesting and social movement still need validation around inventory-full behavior, skinning node coverage, mining orders against all vein owner types, and interactions with companion orders or quest-controlled AI.
- Blacksmithing Copper Bar material costs are first-pass design values because the old workbook / GUI draft lists the Copper Chain outputs but not final material requirements.
- Leatherworking Reinforced Leather recipes currently match the old Tannery GUI trigger and therefore have no material requirements yet.
- The Alchemy workbook still contains material-less or unresolved rows such as Purified Water, Vampiric Potion, Elixir of Might, Elixir of Shadows, and the non-Nazgrek flask ideas. Those recipes are intentionally not registered until live item rawcodes and material requirements are confirmed.
- Fel Iron Vein exists in the current gather-node exports, but `Fel Iron Ore` and `Fel Iron Bar` item rawcodes are not present in the visible item/WTS exports yet, so Fel Iron smelting is still pending item data.

### Voicelines and Audio
- The 18.7.2026 voiceline source-of-truth migration can break runtime behavior if the new libraries are not imported in the right order or if any consumer is missing a required speaker library.
- `qAradion.j` must be retested carefully because many dialogue text/key literals were replaced by external constants:
  - first greet
  - normal greet/farewell
  - Valeria encounter and negotiation
  - Ranger Missing paths
  - crystal shard dialogue
  - Fading Sparks dialogue
  - Rifts of Corruption intro, ritual barks, failure, and completion paths
- AI bark/chat/reply playback must be retested because text/key ownership moved out of AI behavior files:
  - standard bark categories
  - companion chat starters
  - companion replies
  - Aveline reply handling
  - Aradion and Valeria reputation-gated AI profile barks
  - Undead Warlock reply folder mapping
  - AI bark suppression during cinematics/dialogues
- The scan currently reports `14` duplicate text-variant keys. Most are already present in the master folder, but `Thork_0012` is missing audio and has two text variants. It must be manually resolved before FishAudio generation can safely generate that line.
- The scanner reports `455` folder mismatches and `120` orphan audio rows. These are report-only and were not auto-renamed or auto-moved. They need manual review before changing any master audio folder/file names.
- `Kribugs` exists in JASS from Excel draft text but does not currently have a matching external master audio folder. Generation will treat those lines as missing until a master/review folder decision is made.
- Some Excel workbook rows are still represented as `excel_only_blank_text`; these are old filename placeholders without draft text and are intentionally not migrated into JASS constants.
- Undead Warlock voiceline text keys are implemented, but the matching sound files still need to be created/imported before the profile has full audio coverage.

### Quests, Dialogues, Camera, and Zones
- `qAradion.j` / `Rifts of Corruption` still needs focused in-map verification for the non-teleport ritual start, companion-combat behavior, third-rift escort-home state, sequential bark ordering, death-text split, closed-rift cleanup, delayed fail-reset flow, and the portal-closing ability ownership/rawcode path.
- `qAradion.j` / Valeria encounter and Mana Rift binding still need end-to-end main-map validation, especially around `ESC` persuasion flow, post-success hostile stop timing, and ritual start from each real Mana Rift.
- `QuestMaster.j` / quest rewards still need live confirmation for XP on hero companions, XP fallback on Nazgrek/Zul'kis, failed-quest log state, and reputation reward delivery on actual quest completion.
- The current QuestSystems and Aradion-related quest fixes still need a focused end-to-end test pass before `qAradion` is restructured into a more modular questgiver/template-friendly layout for reuse by other libraries.
- `qAradion.j` is still noted as not being on the main map; review current MS Todo items around `qAradion` and shared quest/dialog systems before treating the modular JASS pattern as production-ready.
- `TravelShipB Moknatha Enter` may still reference old camera behavior. It should stop using deleted old camera triggers and route ship-enter camera behavior through `CameraControl`.
- Boom Mine camera is now angle-locked, but the requested centered camera offset still needs a targeted AdvancedCamera/proxy-unit implementation and in-map tuning.
- `CameraControl.j` / `ZoneEvent.j` immediate camera-reset and fast zone-pan changes still need gameplay confirmation in normal, advanced, and special camera modes, plus intended teleport-style cave/interior/dungeon entries.
- `CameraControl.j` normal camera mode remains a likely performance-risk path for recurring FPS drops because the automatic no-clipping / safe-camera correction does heavy periodic camera-path sampling.
- `CameraUI` slider controls were reported as not appearing correctly in the main map even though they work in the test map. The current suspicion was early custom slider-template frame creation from `templates.toc`; no later concrete closure was found.
- `ZoneEvent.j` / Shadowmaw Cave still needs direct gameplay validation to confirm the stale interior-zone state path and shared-exit-rect overlap are fully gone in-map.

### UI and Player-Facing Systems
- The pet definition split and pet-facing UI/templates still need full in-map validation, especially pet Abilities UI entries, Tame Beast I/II permanent death cleanup, Tame Beast III fake-death icon persistence, Shadowclaw metadata/fatigue icons, and Aradion/Valeria reputation-bypass reinvite paths.
- Full in-map validation is still required after importing `StatsLiteUI.j`, especially frame visibility/config behavior, pet/companion revive status text, and confirming the old `UI/MultiboardGUI` triggers stay disabled without breaking companion or pet monitoring.
- Full in-map/JassHelper validation is still required for the updated StatsUI/StatsLiteUI frame layout, cached hero XP requirement display, companion profession gathering behavior, and AbilitiesLiteUI registrations for AI class unit types.
- `AbilitiesLiteUI.j` unlearned-ability gray overlay did not appear correctly in testing and still needs another in-game verification/fix pass.
- `ReputationUI.j` should be retested to confirm opening the UI always refreshes the visible list and live faction reputation changes refresh the open UI immediately without needing a manual close/reopen.
- `MasterUI.j` grouped `Game` menu still needs visual tuning; frame width, heading scale, and button spacing are not finalized yet.
- `HintsUI.j`, `AchievementsUI.j`, and `SecretsUI.j` popup/unlock sound paths still need full in-map validation to confirm they resolve correctly in the target build.
- `StatsUI`, `AbilitiesLiteUI`, and `ReputationUI` have had several performance/stability corrections, but they still need full in-map validation after refresh/scroll/backdrop changes.

### Items, Loot, and Tools
- `ItemLootSystem.j` powerup floating-text cleanup was not yet verified live in Warcraft III. Confirm dropped powerup text disappears correctly when the item is auto-consumed on pickup.
- The older `ItemDropSystem` / `ItemDropDestructible` path still exists as a legacy/manual loot system and is not driven by `WC3ItemManager` exports. Maps still importing that older runtime instead of `ItemLootSystem` + `ItemLootDestructibles` will not use the newer destructible loot-table data until imports are aligned.
- The current authoritative `WC3ItemManager` build is the debug build, not the release build. Until the release package is refreshed, newer ItemManager fixes should be verified against `ItemManager_debug`.

### Performance and Legacy Follow-Up
- `[12.7.2026] Part I` seems to have introduced some accumulating lag or stuck-loop/periodic-timer behavior. No explicit full closure was found; keep watching long-session performance while testing newer AI, camera, UI, and profession changes.
- `IconQuery` startup freeze is fixed, but IconQuery timing/category parameters still need adjustment and in-game validation with quest-giver minimap icons enabled.
- `PatrolFollowSystems`: `ValeriaMovementStart` no longer depends on `udg_TempUnit`, but similar patrol-start functions such as `Mordrax` and other older patrol helpers still need the same cleanup pass.

## Resolved or Superseded Issues

- ~~AI buy/sell states still only run when `AI_BeginBuy` or `AI_BeginSell` is called; the autonomous inventory-full/empty decision still needs to be added or wired back in.~~ Comment: Fixed/narrowed by the 20.7.2026 `AI.j` update that added autonomous shop-state initiation for idle/wandering AI. Current remaining issue is in-map validation with real shops and full/empty inventories.
- ~~CRITICAL: Do not add new standalone playable-map unit-enter hooks; route all unit-enter initialization through GUI `Init 07 Unit Event Enters`.~~ Comment: Superseded by the 22.7.2026 `Events/Events.j` centralized event dispatcher and migration away from the old GUI map-enter pattern. Current remaining issues are the high-risk event-refactor retest, one-time `Floating Texts Spell Event` registration, and unmigrated direct registrations.
- ~~Aradion `qAradion.j` dialogs and quest now do not work; the library seems to break silently.~~ Comment: Later 14.7.2026 entries fixed/narrowed the known breakage with `qAradion.j`, `QuestGiver.j`, and `DialogSystem.j` changes, including the `Info` dialog path and `OnGreetSequenceEnd` compiler errors. Current remaining qAradion work is focused retesting and migration validation.
- ~~Settings UI / post-loadscreen startup freeze.~~ Comment: Fixed in the 30.6.2026 in-game test after `SettingsUI.j` slider re-entry hardening. `IconQuery` tuning remains open separately.
- ~~AbilitiesLiteUI / ReputationUI left-list slider drag/click instability and known slider crashes.~~ Comment: Fixed by the 3.6.2026 custom scrollbar pass; the changelog says no slider crashes are currently known after those fixes. Current remaining UI items are validation and specific follow-up such as the AbilitiesLiteUI gray overlay.
- ~~TerrainDamage was suspected as the main source of recurring periodic FPS drops.~~ Comment: Closed as main suspect by the 9.6.2026 isolation test; disabling TerrainDamage did not meaningfully improve the lag spikes. Current performance suspicion shifted to `CameraControl.j` normal-mode safe/no-clipping correction.
