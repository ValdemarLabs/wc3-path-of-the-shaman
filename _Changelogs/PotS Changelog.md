# WC3 - Path of the Shaman
## CHANGELOG

> Changelog template / usage notes
>
> Use ###`Player-Facing Updates` for clear gameplay changes, player experience changes, UI changes players directly notice, balance/content changes, or anything that directly affects normal play.
>
> Use ###`Technical Updates` for map-development work such as JASS libraries, trigger refactors, performance/stability work, frame/UI implementation details, data structure changes, and other general mapping-related technical work.
>
> Use ###`Tool Updates` for `WC3ItemManager`, PotS SQL Server related work, and other similar internal development tools. These are usually not player-facing by themselves, even if they may later affect gameplay data.
>
> Use ###`Imports` for imported models, textures, icons, sounds, effects, and other asset backlog notes, including credits and intended/future usage checks.
>
> Use ###`Known Issues` for current confirmed problems, validation gaps, or incomplete/problematic behavior that still needs checking.
>
> Use ###`Actions Remaining` for follow-up work, cleanup, validation, polish, or tasks intentionally left for later.

## [30.8.2026]

### Player-Facing Updates

- Restored the one-time Orc Grunt conversations at the western Horde scout base and southern mountain camp; the mountain exchange unlocks after Protect the Outpost as before.
- Added the Elemental Master's ordered Summon Elemental covenant quests: Air, Earth, Fire, and Water. Any Elemental Master can begin a rank, but its essence must be returned to that same trainer; Stormcaller remains required, and rank 5 Greater Elementals remain the final AP upgrade.
- Configured Elemental Essences as WC3 Manager unit-specific drops from their matching Air, Earth, Fire, and Water elementals, with guaranteed drops reserved for the listed powerful sources.
- Added Erduk's one-time Heads of the Murlocs quest for Nazgrek, tracking and consuming 40 Murloc Heads before rewarding experience, gold, and Horde reputation.
- Updated Protect the Outpost's first grunt warning, added a four-second pause before the overwhelmed response, and shifted the remaining dialogue and camera timing with it.
- Protect the Outpost now periodically sends idle gnolls and gnolls lingering in their spawn regions toward the Horde mountain outpost.
- Shadowclaw now joins the Protect the Outpost completion scene beside Nazgrek and remains there when Nazgrek gameplay resumes after Zul'kis's prologue.
- Fixed new Hint notifications obscuring and repeatedly dimming the Game button; it now keeps its normal button frame and briefly displays `Game!` in the same style as QuestUI's `Quests!` update indicator.
- Corrected Zul'kis's opening camera direction and timing: the river cinematic now snaps from camera 2 toward camera 1, cuts after five seconds from camera 5 toward camera 6, and the shore dialogue snaps from camera 3 toward camera 4 over 20 seconds.
- Zul'kis's narrator introduction now begins with the river cinematic instead of waiting for the shore conversation.
- Chieftain Thork now shows the objective question mark while Zul'kis is assigned to meet him.
- Fixed the death-camera motion remaining active after Zul'kis is revived.
- After the wounded witch doctor's death, a four-grunt orc patrol now crosses the broken landing, speaks briefly with Zul'kis in the continuing cinematic, and joins him as temporary companions for Rescue the Brother.
- Added a companion-support hint explaining patrol modes and group orders, and recommending that Zul'kis remain behind the grunts to heal and support them.
- Fixed Graknar's bag-trade dialogue becoming stuck without choices in fullscreen cinematic mode when leaving through Farewell, including after returning from trade; Kribugs now uses the same corrected custom-vendor exit.

### Technical Updates

- Added `World/AmbientEvents/AmbientEvents.j` with reusable one-shot region-entry and ambient unit-type transmission helpers, and added `World/AmbientEvents/HordeUnitsRandomChat.j` to convert the three legacy Horde chat triggers with `Voicelines/Voicelines_OrcGrunt.j` keys and text; updated `QuestsAndDialogs/QuestGivers/Orcs/qRagno.j` and `_developer/Design Plans/Story and Quest Design.md` with the Protect the Outpost unlock contract.
- Added `QuestsAndDialogs/QuestGivers/Shaman/qElementalMaster.j` with per-trainer quest identity, ordered rank conditions, shared item tracking, class metadata, and quest-granted Summon Elemental ranks; updated `Abilities/AbilitiesPlayer.j`, `Abilities/Abilities.j`, `Abilities/AbilityPoints.j`, and `Abilities/AbilityTrainerDialogs.j` with rank-aware quest locks, exact quest-rank grants, reset preservation for earned quest ranks, and trainer-dialog refresh support.
- Added `WC3_Database/WC3ItemManager/elemental_essence_drops_20260830.sql` with the configured essence source units and chances; corrected the manager's `specific_drop_only` handling and label so Specific Drops Only items stay out of generic pools while enabled unit-specific drops still export.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the implemented elemental covenant order, trainer binding, rawcodes, specialization dependency, and rank-5 boundary.
- Added `QuestsAndDialogs/QuestGivers/Orcs/qErduk.j` to convert Erduk's legacy GUI dialogue and quest to the shared quest, item-tracking, objective-reveal, dialogue, camera, and respawn systems; updated `CreepRespawn/CreepUnitAssignment.j`, its test-map respawn dispatcher, and `_developer/Design Plans/Story and Quest Design.md` with Erduk's respawn hook and confirmed Ghostwalk Ridge placement outside Ironspine Post.
- Updated `QuestsAndDialogs/QuestGivers/Orcs/qRagno.j` with synchronized intro-delay timing, periodic gnoll attack-order recovery, and completion-position preservation for active Shadowclaw, and updated `Voicelines/Voicelines_OrcGrunt.j` with the corrected attack warning.
- Updated `UI/MasterUI.j` to remove the invalid full-texture Game alert and alpha pulse, reusing QuestUI's timed replacement-button label pattern instead.
- Updated `QuestsAndDialogs/QuestGivers/Player/qZulkis.j` with GUI-equivalent zero-second camera setup application, the intended six-camera arrival flow, opening narration timing, and Thork objective-target registration.
- Updated `Death/Revival.j` to stop the active camera motion and restore the revived hero as CameraControl's target before releasing the death camera.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the corrected Zul'kis arrival-camera and narration sequence.
- Updated `QuestsAndDialogs/QuestGivers/Player/qZulkis.j` with the chance patrol arrival, uninterrupted dialogue extension, four temporary grunt companions, and end-of-prologue cleanup that also releases retained fallen-companion state.
- Updated `UI/HintsUI.j` with dedicated guidance for controlling and supporting Zul'kis's temporary orc patrol.
- Updated `Voicelines/Voicelines_Zulkis.j` and `Voicelines/Voicelines_OrcGrunt.j` with the broken-landing patrol exchange.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the temporary patrol's story timing, companion behavior, hint, and cleanup contract.
- Updated `QuestsAndDialogs/QuestGivers/Orcs/qGraknar.j` and `QuestsAndDialogs/QuestGivers/Goblins/qKribugs.j` to restore gameplay immediately on vendor farewell and play the farewell as a non-blocking field line, matching normal vendors; updated `QuestsAndDialogs/DialogInteraction.j` so configured dialog exit transitions also explicitly show and unpause the restored hero.

### Imports

- Generated FishAudio review MP3s for `Zulkis_0009` and `OrcGrunt_0167`–`0168`; the files remain under `tools/temp/fishaudio-review` pending listening and promotion to the master audio folder.

### Actions Remaining

- Import `World/AmbientEvents/AmbientEvents.j` before `World/AmbientEvents/HordeUnitsRandomChat.j`, import the Horde chat library before `qRagno.j`, disable the three legacy Horde Units Random Chat GUI triggers, then compile and runtime-test both one-shot regions and the delayed mountain follow-up.
- Disable the four old Quest Elemental GUI trigger groups, import `qElementalMaster`, export the refreshed generic and unit-specific loot definitions from WC3 Manager, then compile and runtime-test every trainer start/turn-in pairing, inventory consumption, Stormcaller gating, ranks 1–4, the rank-5 AP upgrade, configured essence chances, and save/load behavior. Add the Colossus Earth Essence drop after its final rawcode replaces `XXXX`.
- Disable Erduk's old GUI trigger group, then compile and runtime-test the `gg_rct_LakeAmbient042` reveal, 40-head tracking across both inventories, turn-in consumption, rewards, camera restoration, and respawned selection hooks in Ghostwalk Ridge `19` outside Ironspine Post `1901`.
- Compile and runtime-test Protect the Outpost's delayed intro, both wave spawn exits, ESC timing, completion staging, and Shadowclaw's post-Zul'kis return position.
- Compile the full map with World Editor/JassHelper and runtime-test the zero-second camera snaps, both river pans, the shore pan, Thork's temporary question mark, and Zul'kis's death-camera release after revival.
- Review and import the new `Zulkis_0009` and `OrcGrunt_0167`–`0168` audio, then runtime-test patrol entry timing, companion orders, combat deaths, ESC skipping, the tactical hint queue, and complete patrol removal after Rescue the Brother.
- Runtime-test Graknar and Kribugs by leaving directly through Farewell and by opening trade, returning to their choices, and then leaving through Farewell; confirm fullscreen mode, camera, selection, and hero control all restore.

## [29.8.2026]

### Player-Facing Updates

- Zul'kis now revives at Graveyard02 during his separate prologue gameplay; finishing the prologue restores the player's previously selected graveyard. Nazgrek and Shadowclaw remain hidden and isolated until that gameplay section ends.
- Added Zul'kis's starter loadout: Shadowcaster's Scepter, eight modest Darkspear travel pieces, two Mana Potions, one Healing Potion, and Purified Water. Most of the new common equipment is flavor-only, with only small Intelligence, Mana, and Spell Power bonuses across the set.
- Corrected Hint alerts so new hints flash around the complete Game button edge and the unread marker is centered at the Hints icon's size.
- Fixed Ragno's follow-up quests remaining unavailable when delayed quest initialization missed the player's entry into the Protect the Outpost regions.
- Fixed pressing ESC during Ragno's dialogue entry transition leaving the interaction without dialogue or choices.
- Restored the missing grunt attack warning in the Protect the Outpost intro before the outnumbered response.
- Protect the Outpost now restores the player's tracked gameplay camera unit after the intro finishes or is skipped.
- Fixed Zul'kis's river and landing cameras inheriting the current gameplay view: the gameplay camera controller is suspended, cameras 1 and 3 apply instantly, and only the intended camera 1-to-2 and camera 3-to-4 movements pan.
- Darkspear bodies at the broken landing now remain as fleshy corpses throughout Zul'kis's prologue and begin decaying normally after it ends; the wounded witch doctor now dies as the same unit, stops bleeding, and is not replaced or restaged afterward.
- The DEquipment Inspect button now stays hidden during fullscreen cinematics.
- Chieftain Thork's Zul'kis meeting now consumes the selection event so his generic Nazgrek greeting cannot overlap the prologue dialogue.
- Zul'karak now describes his captors as forest trolls questioning what he witnessed at the shore, without naming Bramblehide or claiming to know who carried out the false-flag attack.
- Added two minimal narrator lines before Zul'kis and Zul'karak speak, establishing the Darkspear arrival along Havenwoods' eastern river after answering Thork's call to aid the orcish clan, and identifying the brothers without additional exposition.
- Fixed placed Traveler's Journals failing to provide a replacement item or offer a reliable way to bind a new home.
- Selecting a placed Traveler's Journal now opens the Journal dashboard in a distinct binding mode, with context-sensitive Take Journal, Set Home, and Cancel actions.

### Technical Updates

- Updated `QuestsAndDialogs/QuestGivers/Player/qZulkis.j` to snapshot `udg_GraveyardSelect`, override it with Graveyard02 ID `2` for the complete Zul'kis gameplay section, and restore the saved value at prologue completion; verified its existing Nazgrek and Shadowclaw state snapshots already hide and isolate both characters for the same interval.
- Updated `Preload/Start.j` with reusable per-hero starter-item helpers and an idempotent Zul'kis loadout API, and updated `QuestsAndDialogs/QuestGivers/Player/qZulkis.j` to grant the loadout after his inventory and equipment systems initialize.
- Updated `Voicelines/Voicelines_OrcGrunt.j` with normal grunt, Protect the Outpost, Call of the Horde, Ragno-specific, Mountain Defense, and Rescue the Grunts sections; moved active Ragno, Granis, and Krezgrel quest text/key pairs into the shared library and documented the remaining legacy GUI grunt lines there.
- Updated `UI/MasterUI.j` with a race-matched, full-button highlight texture for Game hint notifications and an explicitly sized and offset Hints icon sprite.
- Updated `QuestsAndDialogs/QuestGivers/Orcs/qRagno.j` with occupied-region recovery, legacy intro dialogue, explicit CameraControl suspension/restoration, the standard shared dialogue ESC path, and pending-dialog cleanup when the encounter interrupts an interaction.
- Updated `QuestsAndDialogs/DialogInteraction.j` with complete configured-transition abort cleanup for cinematic triggers, fullscreen UI, game buttons, and player control.
- Updated `QuestsAndDialogs/QuestGivers/Player/qZulkis.j` with explicit CameraControl suspension/resume, instant camera setup application before both intended pans, legacy GUI-equivalent permanent corpse staging, and same-unit witch-doctor death handling.
- Updated `Voicelines/Voicelines_Narrator.j` and `QuestsAndDialogs/QuestGivers/Player/qZulkis.j` with registered narrator audio keys and two speakerless opening lines before the shore conversation.
- Updated `Voicelines/FishAudioVoiceIds.md` with Thork, Zul'karak's shared TrollMale1 reference, Narrator, and confirmation that Zul'kis story dialogue uses the ZulkisGeneric profile.
- Added `Voicelines/FishAudioNarratorTts.csv` with narrator-only delivery cues and short pauses that remain separate from in-game dialogue text.
- Updated `QuestsAndDialogs/QuestGivers/Orcs/qChieftainThork.j` to consume the prologue selection before generic selection handlers run, and updated `Voicelines/Voicelines_Zulkarak.j` with captivity dialogue that preserves Zul'karak's uncertainty.
- Updated `UI/MasterUI.j` and `DestroyerInventoryAndEquipmentSystem/PoTs/DEquipment.j` with cinematic inspect-button suppression and restoration.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the corrected Zul'kis camera and corpse lifecycle plus the resolved premise that Thork paid forest trolls to leave no Darkspear survivors and frame humans for the attack.
- Updated `PlayerHome/PlayerHome.j`, `UI/PlayerHomeUI.j`, and `UI/HintsUI.j` with direct world-Journal binding mode, current-home replacement Journals, delayed initial delivery, DInventory fallback when vanilla inventory is full, and matching recovery guidance.

### Tool Updates

- Added `WC3_Database/WC3ItemManager/zulkis_starter_gear_20260829.sql` and applied it to WC3 Manager, creating eight common starter-equipment records, their three low-power stat assignments, and correcting Shadowcaster's Scepter to the Stave class for DEquipment export.
- Updated `WC3_Database/WC3ItemManager/` with guarded round-trip editing for synchronized qXXX sources: only uniquely mapped literals are editable, custom/shared/computed fields remain gray with source-only guidance, every write requires a patch preview and three-way field conflict check, and confirmed patches are backed up, structurally validated, atomically written, and synchronized.
- Added explicit WC3 Manager-owned quest-region support for safely inserting standard external quests without replacing hand-authored library code, plus a read-only source-edit audit command covering all synchronized quest records.

### Imports

- Generated 15 FishAudio review MP3s for the Zul'kis prologue: `Zulkarak_0001`–`0004`, `Narrator_0006`–`0007`, `Thork_0013`–`0014`, `Zulkis_0005`–`0008`, and witch-doctor testimony `GenericTroll_0001`–`0003`.
- Regenerated `Narrator_0006`–`0007` as brief introductions centered on the Darkspear answering Thork's call for aid and Zul'karak being Zul'kis's elder brother.
- Regenerated `Narrator_0006`–`0007` with calm measured-narration cues and short pauses around the character and location beats.

### Actions Remaining

- Runtime-test Zul'kis dying during each playable prologue phase, confirm revival at Graveyard02, and confirm the prior graveyard selection plus Nazgrek and Shadowclaw visibility/state are restored only after Rescue the Brother completes.
- Export/import Zul'kis's new `j4c3`-`j4d0` item objects and current DEquipment definitions from WC3 Manager, then compile and runtime-test the one-time prologue loadout, two-handed scepter equip, native consumable counts, and ESC/retry paths.
- Review and promote/import the 15 generated Zul'kis-prologue MP3s, then runtime-test narrator pacing across the camera-2-to-1 and camera-5-to-6 river shots, the wounded witch doctor's interrupted final line, and all speaker transitions.

## [28.8.2026]

### Player-Facing Updates

- Added Quinx's level-5 `Shredder Fuel` side quest. After receiving Goblin Rocket Fuel, Quinx periodically harvests nearby trees and pauses between work cycles.
- Specialized goblin explosives and reagent merchants now stock Goblin Rocket Fuel `j4c2` for 150 gold, with four canisters available and one replenished every five minutes.
- Updated the approved Nazgrek, Zul'kis, Engineer, Paladin, Shaman, Rogue, Warrior, and Aveline puke-reaction dialogue while retaining every reaction marked `No` and all pass-out lines.
- Companion puke reactions now wait until shortly after the visible puke begins instead of playing as soon as the puking ability is applied.
- Human patrol activity now varies between one and two simultaneous groups. Each group remains assigned either to the Sereneglade–Twilight Grove route or entirely within Havenwoods instead of crossing all three zones.
- Player-hero pass-outs now begin fading before fullscreen mode changes, and waking with a hangover revives the other player hero and all companions while interrupting active boss and arena encounters.

### Technical Updates

- Added `QuestsAndDialogs/QuestGivers/Goblins/qQuinx.j` with delayed `udg_Quinx` registration, Goblin Rocket Fuel `j4c2` tracking and consumption, dialogue, availability/respawn hooks, and a post-completion harvesting loop; updated `Vendors/VendorCatalogs.j` with the fuel stock.
- Refactored `World/HumanPatrols.j` to maintain independent indexed movement, camp, leader, tent, death, and respawn state for up to two route-bound patrols while preserving the original singular compatibility API.
- Updated `Professions/Drunk.j` with hangover wake recovery and encounter interruption, and updated `DungeonsAndBosses/Boss.j` with a shared active-boss reset API.

### Tool Updates

- Updated `WC3_Database/WC3ItemManager/` as the user-facing WC3 Manager and added the database-backed Quest Designer for quest-giver/quest CRUD, giver/receiver/prerequisite relationships, objectives, rewards, dialog/event sequences, source-reconciled voicelines, World Editor dependencies, and an in-game journal-style preview.
- Added `WC3_Database/migrations/007_create_quest_designer.sql`, `run_all_quest_migrations.sql`, and `docs/QUEST_DESIGNER.md` with normalized quest authoring data, relationship views, validation boundaries, and the managed/hybrid/external source-ownership contract.
- Added change-aware validated qXXX scaffold exports with per-giver SHA-256 fingerprints, JSON snapshots, validation reports, World Editor manifests, cross-giver bindings, required-reputation support, and explicit safeguards for behavior that remains hand-owned.
- Added `WC3_Database/WC3ItemManager/Importers/QuestSourceSynchronizer.cs` and `WC3_Database/migrations/008_add_quest_source_sync.sql` so WC3 Manager can non-destructively synchronize active `QuestGivers` and `GenericQuests` JASS into read-only external previews, including standard quests, vendor fetch/kill/supply quests, turn-in/prerequisite links, qXXX library relationships, and separate source fingerprints.
- Updated `WC3_Database/WC3ItemManager/QuestDesignerForm.cs` with a repository-style `QuestGivers`/`GenericQuests` navigation hierarchy, preserved source folders, collapsed quest branches, and a separate database-authored section.
- Updated `WC3_Database/WC3ItemManager/QuestDesignerForm.cs` and `Models/QuestDesignerModels.cs` with a friendlier searchable workspace, categorized editor fields, folder overview cards, clearer ownership badges, and prominent read-only safeguards for synchronized JASS libraries.

### Imports

- Generated all 13 approved replacement puke-reaction MP3 files under `tools/temp/fishaudio-review/` for review before master-audio promotion and map import, and moved 32 older review MP3s into `tools/temp/fishaudio-review/older-review-files/` so the active review folders contain only the approved batch.

### Actions Remaining

- Import `qQuinx`, confirm `udg_Quinx` points to a placed harvest-capable shredder, verify Quinx's final rawcode/zone and nearby harvestable trees, then compile and runtime-test `j4c2` quest turn-in plus repeated work/pause cycles.
- Exercise giver/quest/relationship/sequence CRUD and change-aware exports, then compile a managed and hybrid generated qXXX library in a focused JassHelper test map and the full map.

- Review `Nazgrek_DrunkPuke1`–`2`, `Zulkis_DrunkPuke1`–`2`, `HeroEngineer_DrunkPuke1`–`2`, `HeroPaladin_DrunkPuke1`–`2`, `HeroShaman_DrunkPuke1`, `HeroRogue_DrunkPuke2`, `HeroWarrior_DrunkPuke2`, and `Aveline_DrunkPuke1`–`2`, then replace/import their stale master audio files.

- Runtime-test both one-patrol route variants and the two-patrol configuration, including independent formation movement/camps, Havenwoods-only destination selection, Sereneglade–Twilight alternation, shared Captain Maelhood uniqueness, creep-respawn exclusion, and indexed quest hooks.
- Compile `Professions/Drunk.j` with its new Death/Boss dependencies and runtime-test player-hero pass-outs during ordinary combat, active boss fights, and arena sessions; verify gradual fade timing, party revival, encounter cleanup, and multiplayer-local camera/UI behavior.

## [27.8.2026]

### Tool Updates

- Updated `WC3_Database/WC3ItemManager/ItemEditForm.cs` and `BatchItemEditDialog.cs` with editable Perishable (`iper`) support, charged/actively-used defaults, and consumable generation that produces inventory items removed when their charges reach zero.

### Player-Facing Updates

- Fixed direct Sirensong-Ashfang wyvern flights so they follow the configured flight-point chain through Horde Scout Base instead of flying straight to the destination.
- Added a recurring Mok'natha battlefield where small orc and ogre forces attack along varied lanes around the crater field.
- Added a recurring human patrol that begins after one minute, travels in coordinated formation among Twilight Grove, Sereneglade, and Havenwoods, makes and removes camps, and may include Captain Maelhood scouting around the camp.
- Fixed unread Hint effects so the Game-button flash fills the complete button, replays for every new hint, and the persistent Hints marker matches the full-button Quest update effect.
- Delayed `Protect the Outpost` discovery until five seconds after the gnoll-attack intro cinematic, approximately 15 seconds after the encounter begins.
- Added Nazgrek's self-discovered prologue opening: Wolf Hunt I kills six wolves, collects six Wolf Skin, and then leads directly into the recovered Nazgrek's Flask ingredient quest.
- Nazgrek's Flask now uses its exact legacy materials, reveals the missing Empty Flask objective after the recovered delay, and can be crafted from Alchemy 0 so the level-1 story does not require profession grinding.
- Added Zul'kis's parallel prologue with the Darkspear river landing, first meeting with Chieftain Thork, destroyed shore, wounded troll's interrupted warning, and Rescue the Brother in Bramblehide Village.
- Smoothed the Protect the Outpost-to-Zul'kis handoff with a black-screen camera transition, made ESC skip the moving-ship segment, and removed the repeated fade cycle during ship arrival.
- Nazgrek and Zul'kis no longer display quest-giver punctuation for their self-driven hero quests.
- Hero quest markers now default off for Nazgrek and Zul'kis, while unit-specific quests such as Call of the Horde hide their giver, receiver, and objective markers whenever their required hero is neither owned nor an active companion.
- During Zul'kis's separate gameplay, Nazgrek is hidden, invulnerable, paused, and neutral-passive, while Shadowclaw is removed from pet/companion gameplay and restored with Nazgrek afterward; the destroyed Darkspear landing is staged immediately after Thork's order, with the wounded witch doctor lying down and periodically bleeding from the chest.
- Ragno now receives five seconds to walk into his Protect the Outpost conversation position before the cinematic applies its final placement correction.
- Ragno's Gnoll Headcount, Lumberjack Duties, Kobold Thieves, and Satyr Negotiations quests now unlock after Protect the Outpost instead of being treated as unrelated starting quests.
- Nazgrek is now reliably stopped and cinematic-positioned in front of Chieftain Thork before their Call of the Horde meeting, even when the World Editor cinematic trigger skips its normal unit-mover branch.
- Quest-giver dialogue now keeps the fullscreen interface active while returning user control for dialogue choices, and reliably restores the normal interface after farewells such as Thork's and Ragno's.
- Nazgrek's Wolf Hunt I now waits for the intro cinematic's completion hook instead of appearing while the cinematic is still playing.
- Added Bramblehide Village as a Bloodtusk forest-troll subzone of Havenwoods.
- Velyssara's charm now gives Nazgrek the `S01P` dummy aura while Chains of Seduction binds him, then removes it when her tasks are completed or the charm is dispelled.

### Technical Updates

- Updated `Travel/TravelWyvern.j` and `Travel/TravelSystem.j` with stitched long-distance wyvern routes, expanded route waypoint capacity, and recovery when Warcraft drops an active flight movement order.
- Added `World/MoknathaBattle.j` with randomized two-sided respawns, cinematic-aware periodic cycles, persistent crater ubersplats, legacy group compatibility, and public quest/event control hooks.
- Added `World/HumanPatrols.j` with configurable delayed startup, recurring travel/camp/respawn phases, coordinated group movement, normal-creep-respawn exclusion, single optional leader spawning, leader scouting, legacy group compatibility, and public quest-state hooks.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the ambient-system ledger, Mok'natha regional support, and a proposed five-step Chieftain Thork patrol/garrison chain that treats the later human attacks as retaliation rather than folding the garrison into the Dark Horde.
- Updated `UI/MasterUI.j` with parent-sized Game-button alert framing, explicit flash-animation resets, and Quest-style full-button Hints alert framing, and updated `QuestsAndDialogs/QuestGivers/qRagno.j` plus `_developer/Design Plans/Story and Quest Design.md` with post-cinematic Protect the Outpost acceptance and wave progression.
- Added `QuestsAndDialogs/QuestGivers/qNazgrek.j` with public intro/start, recovery, progress-refresh, and completion-state hooks; combined wolf-kill tracking; live DInventory/vanilla-inventory progress; automatic Wolf Hunt I completion; and acquisition-based flask completion.
- Updated `QuestsAndDialogs/QuestGivers/qVelyssara.j` to own Nazgrek's temporary charm aura across quest acceptance, normal completion, and external dispels such as Jin'Zun's cure.
- Updated `Professions/ProfessionsAlchemy.j` to make the existing reusable Nazgrek's Flask `I61L` recipe available at Alchemy 0 while retaining all six recovered material requirements.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the implemented Wolf Hunt I/flask flow, planned Wolf Mother and Shamanic Cowl conclusions, compact parallel Zul'kis intro, Thork false-flag premise, Rescue the Brother convergence, and Zul'karak's later quest-giver/recruit contract.
- Recovered the legacy `Dead Darkspear Trolls` shore layout for the Zul'kis plan: five headhunters and one witch doctor use `gg_rct_CorpseTroll01` through `gg_rct_CorpseTroll06`, with living versions shown during the landing. The headhunters become permanent corpses when Zul'kis returns; the wounded witch doctor at 03 gives the interrupted testimony before becoming the final corpse. Recorded `gg_rct_ZulkisStart` and the already preplaced Zul'karak `n65F`, referenced by `udg_Zulkarak`, as confirmed World Editor staging.
- Added `QuestsAndDialogs/QuestGivers/qZulkis.j` with the four-camera arrival, temporary `'odes'` ship removal at `gg_rct_ZulkisShipWP2`, living-to-corpse shore staging, Thork objective, Bramblehide rescue, stable completion queries, and Zul'kis/Nazgrek control handoffs.
- Added `Voicelines/Voicelines_Zulkarak.j` and `Voicelines/Voicelines_GenericTroll.j`, and extended `Voicelines_Zulkis.j` plus `Voicelines_Thork.j` with the prologue dialogue and prepared sound keys.
- Updated `Zones/ZonesCore.j` with Bramblehide Village `701`, a level 1–5 Bloodtusk Tribe subzone of Havenwoods using `gg_rct_BramblehideVillage`.
- Updated `QuestsAndDialogs/QuestGivers/qRagno.j` to start `qZulkis` from the Protect the Outpost completion fade and updated `qChieftainThork.j` to redirect the prologue meeting and gate Call of the Horde completion/companion enablement behind Rescue the Brother.
- Updated `QuestsAndDialogs/QuestMaster.j` with reversible per-unit quest-marker suppression, used by `qNazgrek.j` and `qZulkis.j`; hardened `qZulkis.j` cinematic skipping so skipped staging still reaches its final world state.
- Updated `QuestsAndDialogs/QuestMaster.j` and `QuestGiver.j` with reusable unit-specific quest availability/marker settings, then applied them to the Nazgrek, Zul'kis, and Call of the Horde prologue quests.
- Updated `Companions/Pet.j` with reversible Shadowclaw story-isolation hooks so Zul'kis-only gameplay cannot show or command Nazgrek's pet, including when the prologue begins before delayed pet initialization.
- Updated `QuestsAndDialogs/QuestMaster.j` to transfer completed-quest prerequisite giver references when a quest giver such as Ragno is replaced after death.
- Updated `QuestsAndDialogs/DialogInteraction.j` so configured quest-giver entry transitions guarantee the selected hero reaches the configured cinematic point while the screen is black.
- Updated `QuestsAndDialogs/DialogInteraction.j` to own fullscreen-interface entry, interactive dialogue, and exit cleanup independently of qXXX quest-giver libraries and the World Editor cinematic triggers.
- Updated `QuestsAndDialogs/QuestGivers/Player/qNazgrek.j` to preserve start requests made before delayed QuestData initialization while leaving cinematic timing to its explicit intro-finish hook.

### Actions Remaining

- Compile the updated travel libraries with JassHelper and runtime-test Sirensong-Horde Scout Base, Horde Scout Base-Ashfang, and direct Sirensong-Ashfang wyvern flights in both directions against `gg_rct_FPRoute001` through `028`.
- Import `MoknathaBattle.j`, keep `gg_rct_MoknathaBattleRegion01` through `05` plus `gg_rct_MoknathaCrater01` through `07`, disable both legacy Moknatha GUI triggers, compile the full map, and runtime-test ownership, lane pathing, respawn timing, cinematic suppression, and crater rendering.
- Import `HumanPatrols.j` after `CreepRespawn`, keep `gg_rct_PatrolSpawnPoint`, the three zone rects, and the legacy `PatrolGroup1`/tent variables, disable all four legacy Human Patrol GUI triggers, compile the full map, and runtime-test coordinated formation movement, route pathing, creep-respawn exclusion, campsite placement, tent deaths, unique leader chance/scouting, complete patrol death, and automatic patrol-owned respawn. The proposed Thork quest chain still needs its QuestData, item/drop, capture, garrison, barrel, fire, reinforcement, and counterattack implementation.
- Runtime-test the Game/Hints alert sprite bounds and Protect the Outpost discovery timing after both normal completion and Escape-skipping of the gnoll-attack cinematic.
- Import `qNazgrek.j` after its listed dependencies; add `call qNazgrek_StartIntroQuestChain()` to Nazgrek's intro cinematic shared normal/ESC completion path; disable the legacy Nazgrek's Flask GUI folder; compile the full map; and runtime-test post-cinematic Wolf Hunt I discovery, wolf kills, all ingredient counts, the 175-second Empty Flask reminder, Alchemy 0 crafting, and completion while using DInventory and vanilla inventory. Confirm whether `Spawn Plants Intro` still supplies extra prologue herbs and stop/remove that spawner after `qNazgrek_IsFlaskCompleted()`.
- Create or confirm a unique Wolf Mother Head/Pelt and Shamanic Cowl, verify early sources for two Light Leather `I6A6` and one Thread `I66L`, register the planned trophy + six Wolf Skin + leather/thread recipe, decide the flask's Wolf Mother encounter effect, and verify Wolf Den `12111` plus Wolf Mother `n648` before implementing Wolf Hunt II–III.
- Import `VoicelinesZulkarak`, `VoicelinesGenericTroll`, and `qZulkis` after their listed dependencies; disable the legacy `Dead Darkspear Trolls` 5-second GUI event; compile the full map; and runtime-test ship movement/removal, all four cameras, Thork-time corpse/captive staging, the witch doctor's death pose and chest blood effect, Thork selection, Bramblehide entry, Zul'karak rescue, hero ownership/inventory state, hero-marker suppression, Nazgrek and Shadowclaw isolation/restoration, and Call of the Horde convergence. Add audio files for the prepared Zul'kis, Thork, Zul'karak, and Generic Troll keys when recordings are available.
- Design and implement Zul'karak's post-rescue Horde-base quest set before enabling recruitment, then add the planned simple berserker AI and timed dismissal return to `gg_rct_ZulkarakHordeHome`.

## [26.8.2026]

### Player-Facing Updates

- Added the voiced five-part Boom Brothers and Atex Blix story chain, from recovering unstable explosives through Mad Blix's takeover, the Boom Mine dungeon conclusion, and its Crown of Kings +5 reward.
- Snikka Sparkdust in Sirensong now keeps up to two costly Barrel of Explosives in stock, with a long replenishment time, as an alternative route for Explosive Crisis.
- Updated Hints with a short publication delay, a spaced notification queue, heading-only chat messages, and persistent unread effects on the Game and Hints buttons.
- Added contextual hints for hero revival and graveyards, Traveler's Journals, quests, free return flights, ability and talent points, specializations, Spirit Shards, companions, pet fatigue, reputation, and Boom Brothers Mine explosives.
- Added Gar as a quest/event-spawned Deadwoods boss with a slow six-point patrol and a faster-attacking frenzy below half health.
- Added the Traveler's Journal home system and dashboard: bind a shared home at world Journals, inspect each hero's Journal and cooldown state, ping home, and channel a nearby-party return from either hero.
- Moved the legacy cheat/debug command reference into the Commands screen and replaced the old Cheats menu entry with Traveler's Journal.

### Technical Updates

- Added `QuestsAndDialogs/QuestGivers/qBoomBrothers.j` and `QuestsAndDialogs/QuestGivers/qAtexBlix.j` by converting the recovered five-quest GUI chain to the current quest, dialogue, inventory, escort, dungeon, and boss APIs.
- Updated `DungeonsAndBosses/Dungeons/Boom Brothers Mine/BossMadBlix.j`, `CreepRespawn/CreepUnitAssignment.j`, `Vendors/VendorCatalogs.j`, and `Vendors/VendorFactions/VendorGoblins.j` with Mad Blix quest completion, quest-giver respawn restoration, and Snikka Sparkdust's capped explosives stock.
- Updated `_developer/Design Plans/Story and Quest Design.md` and `QuestsAndDialogs/QuestGivers/Vendors/README.md` with the implemented Boom Mine chain, exact objective data, dependency contracts, vendor fallback, and remaining physical access/ore decision.
- Updated `UI/HintsUI.j` and `UI/MasterUI.j` with queued publication state, duplicate suppression, unread tracking, compact notifications, and reusable alert sprites.
- Updated `Death/Revival.j`, `PlayerHome/PlayerHome.j`, `Abilities/AbilityPoints.j`, `Abilities/Talents.j`, `Abilities/AbilityTrainerDialogs.j`, `Death/Death.j`, `Companions/Companions.j`, `Companions/Pet.j`, `Reputation/Reputation.j`, `QuestsAndDialogs/QuestMaster.j`, `Travel/TravelWyvern.j`, and `DungeonsAndBosses/Dungeons/Boom Brothers Mine/DungeonBoomBrothersMine.j` with event-driven hint publishers.
- Removed the old `Hero Death and Resurrect` GUI trigger folder.
- Removed the old `Revive System Player` GUI trigger folder.
- Added `DungeonsAndBosses/OpenWorld/Gar/BossGar.j` with the `BossGar_Spawn()` hook, `udg_BossGar` assignment, event-owned respawning, patrol/reset handling, and two-phase boss registration.
- Updated `_developer/Design Plans/Story and Quest Design.md` with Gar's implemented spawn rect, patrol, phase scope, and remaining quest/outcome decisions.
- Added `PlayerHome/PlayerHome.j` with registered home destinations, shared binding, per-hero cooldowns, one guarded return channel, nearby-party snapshots, pathing-aware placement, state restoration, and zone refresh handling.
- Added `UI/PlayerHomeUI.j` and updated `UI/MasterUI.j`, `UI/AbilitiesUI.j`, and `UI/TalentsUI.j` with live Journal controls and centralized panel cleanup.
- Updated `UI/CommandsUI.j` with the complete legacy cheat reference, removed `UI/CheatsUI.j`, and refreshed `_Credits/PotS Credits.md` for the replacement libraries.

### Actions Remaining

- Import `qBoomBrothers.j` and `qAtexBlix.j` after their listed dependencies, disable both legacy GUI folders, verify all placed globals and Boom Brothers rects in World Editor, then compile and runtime-test barrel detonation, Snikka stock/restock, log inspection, dust turn-in, escort/betrayal staging, turret ownership, Mad Blix death readiness, final turn-in, and both quest-giver respawn hooks.
- Decide whether Boom Mine entry should consume `qBoomBrothers_IsMineAccessGranted()` and implement the promised renewable ore benefit without creating an economy exploit.
- Compile the full map with JassHelper and runtime-test queued hint timing, duplicate suppression, unread clearing, alert sprite placement, and simultaneous level-up/quest/reputation notifications.
- Import `BossGar.j` after Boss and PatrolSystem, create/verify `gg_rct_GarWP01` through `gg_rct_GarWP06` and `udg_BossGar` in World Editor, keep Gar unplaced, then call `BossGar_Spawn()` from the owning quest/event and runtime-test patrol, reset, frenzy, death, and explicit re-spawn.
- Import `PlayerHome.j` and `PlayerHomeUI.j` in dependency order, remove `CheatsUI.j` from the map import list, disable the legacy Player Home GUI triggers, and remove the old Traveler's Journal optional quest creation from Game Guide.
- In World Editor, verify `gg_rct_PlayerHome1`, `gg_rct_PlayerHome2`, both placed `n65G` Journals, rawcodes `I6CL` and `A6DU`, and the Journal item's reusable/non-consumable behavior; then compile and runtime-test binding, interruption, personal cooldowns, inventory staging, party exclusions, state restoration, zone refresh, and all Journal UI navigation paths.

## [25.8.2026]

### Player-Facing Updates

- Added Velyssara's `Chains of Seduction` story quest in Sereneglade: submit to four escalating tasks or seek Jin'Zun's dispel and turn on her.
- Charmed Nazgrek is now bound to Sereneglade until the spell is broken or Velyssara's tasks are completed; escape attempts immediately return him to his last safe position in the zone.
- Added destination zone icons to the travel window, with subzones inheriting their parent zone icon when they do not define one.
- Added Graknar's `Mistaken Kin` level-2 quest: find his lost Kodo, draw nearby hostile creatures into the recovery, escort the Kodo home, and retry if it is slain.
- Replaced Graknar's legacy 30-second trade window with his existing persistent bag shop in the same quest dialog.
- Added Grum Bloodfang's voiced `Whelps of Destruction`, `Dragon Egg Hunt`, `Drake Hunt`, and `The Desolator` story chain in Emberpeak Highlands, including the recovered periodic Scorching Drake attack on his camp.
- Added Grim's voiced `Big Bear Tooth` daily quest in Thornwoods, with shared item tracking and turn-in support for tooth `I6AB`.
- Fixed converted Granis, Garthork, and Krezgrel conversations so completing or skipping their greeting with Escape reveals the available dialog choices.
- Restored Garthork's first meeting with Nazgrek before he introduces `The Magical Eye` quest.
- Added Kaelthir's `Kaelthir's Struggle` and `Kaelthir's Hunger` story quests, including the mercy, mana-wraith, and failed Aradion cure outcomes.
- Fixed Prince Zaekolaerr's first greeting, Escape handling, negotiation menus, missing Nazgrek replies, sound playback, and cinematic placement at `gg_rct_SatyrPrinceRect`.
- Updated the Satyr Negotiations arena choice so it directs the player to satyr arena master `n62V` and only becomes ready to report after a successful Coliseum of Ages challenge.

### Technical Updates

- Added `QuestsAndDialogs/QuestGivers/qVelyssara.j` by converting the recovered Velyssara/Succubus GUI dialogue, task events, follow behavior, combat reactions, reward, charm state, and public confinement/escape/dispel hooks to the current master APIs.
- Updated `QuestsAndDialogs/QuestGivers/qOutcastJinzun.j` to dispel Chains of Seduction through `qVelyssara` instead of calling the legacy GUI trigger, and updated `CreepRespawn/CreepUnitAssignment.j` to restore Velyssara's quest-giver hooks after respawn.
- Updated `_developer/Design Plans/Story and Quest Design.md` with Velyssara's canonical name, implemented quest flow, Sereneglade confinement contract, reward, and remaining allegiance/fate decision.
- Updated `Travel/TravelUI.j` and `Zones/ZonesCore.j` with discovered-route icon frames and reusable parent-zone icon fallback resolution.
- Added `QuestsAndDialogs/QuestGivers/qGraknar.j` by converting the recovered Graknar GUI quest, dialogue flow, Kodo proximity tracking, FollowSystem escort, failure/retry handling, and VendorBags/ShopUI handoff to the current master APIs.
- Updated `CreepRespawn/CreepUnitAssignment.j` to restore Graknar's quest, custom dialog, and vendor hooks after respawn and removed its obsolete direct dependency on the legacy Mistaken Kin quest handle.
- Updated `_developer/Design Plans/Story and Quest Design.md` with Graknar's recovered quest ownership and the requirement that canonical Graknar alone retain unit rawcode `o61S`.
- Updated `QuestsAndDialogs/QuestGivers/Vendors/README.md` with the named-bag-vendor rawcode and catalog rules for Graknar and future bag sellers.
- Added `QuestsAndDialogs/QuestGivers/qGrumBloodfang.j` by converting the recovered Grum GUI quest, dialogue, combined drake-kill tracking, item turn-ins, item rewards, and camp-attack event to the current quest/dialog APIs.
- Updated `CreepRespawn/CreepUnitAssignment.j` to restore Grum's selection and quest-giver hooks after respawn, and updated `_developer/Design Plans/Story and Quest Design.md` with the recovered chain's exact levels, items, Emberpeak zone, implementation status, and remaining egg/Mordrax decisions.
- Added `QuestsAndDialogs/QuestGivers/qGrim.j` by converting the recovered Grim GUI quest and dialogue to QuestGiver, QuestMaster, DialogInteraction, DialogSystem, and item-tracking APIs.
- Updated `CreepRespawn/CreepUnitAssignment.j` to restore Grim's quest-giver registration and selection hooks after respawn, and updated `_developer/Design Plans/Story and Quest Design.md` with Grim's recovered quest ownership and implementation status.
- Updated `Preload/Preloader.j` with a pre-preload choice between the normal sound/music preload and a fast developer-check path that keeps ability preloading but skips the audio preload stages, including their saved-game reload pass.
- Updated `QuestsAndDialogs/DialogInteraction.j` to leave fullscreen cinematic mode before displaying a native dialog after a greeting sequence.
- Updated `QuestsAndDialogs/QuestGivers/qGranis.j`, `QuestsAndDialogs/QuestGivers/qGarthork.j`, and `QuestsAndDialogs/QuestGivers/qKrezgrel.j` to use the shared first-greeting completion path and preserve their dedicated introductions.
- Added `QuestsAndDialogs/QuestGivers/qKaelthir.j` by converting the recovered legacy GUI quests and dialogue to QuestGiver, QuestMaster, DialogInteraction, DialogSystem, item tracking, and escort APIs.
- Updated `_developer/Design Plans/Story and Quest Design.md` with Kaelthir's canonical rawcode, Vanguard Vale quest ownership, Act IV placement, and durable Hunger outcome contract.
- Updated `QuestsAndDialogs/QuestGivers/qZaekolaerr.j` and `QuestsAndDialogs/QuestGivers/qRagno.j` from the recovered PrinceZaekolaerr GUI triggers with one-shot negotiation outcome routing and deferred arena completion.
- Updated `Arena/Arena.j` with reusable arena-end callbacks so quest systems can react to successful or failed sessions without replacing mode callbacks.
- Updated `Voicelines/Voicelines_Satyr.j` and `Voicelines/Voicelines_Demoness.j` to register their owned sound keys with ExSound.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the implemented Satyr Negotiations arena gate and remaining branch gaps.

### Actions Remaining

- Import `qVelyssara.j`, disable the legacy Velyssara/Succubus and Jin'Zun Chains of Seduction GUI branches, and runtime-test acceptance, all four tasks, Jin'Zun dispel, both completion routes, escape teleportation, combat barks/blink, reward delivery, and respawn hooks.
- In World Editor, rename remaining player-facing `Succubus` or `Velaria` references for unit `n636` to Velyssara while retaining those names only as legacy search terms.
- Import `qGraknar.j`, disable the legacy Graknar GUI trigger group, and runtime-test quest acceptance, Kodo discovery, hostile aggro, following, return, death/retry, turn-in, bag trading, trade return, and respawned-Graknar hooks.
- In World Editor, keep only the canonical Graknar on rawcode `o61S`, create distinct rawcodes and identities for the other placed bag merchants, remove the old placed Kodo near Graknar, and verify the intended Graknar, `KodoSpawn`, and `KodoEnd` placement and zone.
- Import `qGrumBloodfang.j`, disable the legacy Grum GUI quest/dialog/drake-attack trigger groups, and runtime-test all four accept/turn-in paths, combined drake kills, item rewards, Escape handling, respawn hooks, both raid rects, and Mordrax's current scale drop.
- Import `qGrim.j`, disable the legacy Grim GUI trigger group, and runtime-test first/repeat greetings, acceptance, tooth pickup readiness, turn-in from either hero inventory, daily reset, and respawned-Grim interaction hooks.
- Compile the full map with JassHelper and runtime-test both preload choices, including loading a saved game created after each choice.
- Runtime-test natural completion and Escape skipping for the first and repeat interactions with Granis, Garthork, and Krezgrel.
- Import `qKaelthir.j`, disable the legacy Kaelthir GUI trigger group, and runtime-test Struggle item removal plus all three Hunger outcomes, including the escort to `gg_rct_AradionPlace`.
- Import the updated Zaekolaerr and arena libraries, disable the legacy PrinceZaekolaerr GUI trigger group to prevent overlapping dialogs, then runtime-test first/repeat greetings, Escape at every sequence/menu, all three negotiation choices, satyr arena failure/retry/success, sounds, camera restoration, and the `gg_rct_SatyrPrinceRect` placement.

## [24.8.2026]

### Player-Facing Updates

- Added Granis's `Punish` quest against Rol'jin and the separate nine-wave `Mountain Defense` follow-up at Ragno's outpost, including defender survival conditions, helper-item drops, failure cleanup, and retries.
- Added Garthork's `The Magical Eye` story quest against Mur'gal, including the Eye of Mur'gal turn-in and Adept Shaman Claws reward.
- Added Krezgrel's `Murloc Fins` and `Rescue The Grunts` daily quests; eight randomized water-rescue targets can yield either a rescued survivor or a drowned grunt.

### Technical Updates

- Added `UnitSystems/UnitWaves.j` as a reusable staged attack-wave event library with configurable delays, spawn rects or points, attack targets, order refreshes, completion polling, callbacks, cancellation, and reset cleanup.
- Added `QuestsAndDialogs/QuestGivers/qGranis.j`, `QuestsAndDialogs/QuestGivers/qGarthork.j`, and `QuestsAndDialogs/QuestGivers/qKrezgrel.j` by converting the recovered legacy GUI quest and dialogue exports to QuestGiver, QuestMaster, DialogInteraction, and DialogSystem APIs.
- Updated `QuestsAndDialogs/QuestGivers/qChieftainThork.j` so `Duty For The Horde` tracks Granis's `Punish` and Garthork's `The Magical Eye` as separate proof requirements with explicit completion reports and QuestData recovery.
- Clarified `QuestsAndDialogs/QuestGivers/qGranis.j` and the story ledger that Granis owns and rewards `Mountain Defense`, while Ragno is its field commander, encounter anchor, required survivor, and principal battlefield speaker.
- Updated `_developer/Design Plans/Story and Quest Design.md` with the implemented quest identities, Thornwoods zone ownership, the resolved second-outpost-defense decision, Krezgrel's recovered role, and the Reforged-safe rescue proxy/effect approach.

### Actions Remaining

- After importing the replacement libraries, disable the legacy Granis, Garthork, and Krezgrel GUI trigger groups in World Editor to prevent duplicate quest/dialogue execution.
- In World Editor, remove the eight placed upside-down grunt units; retain `gg_rct_UpsideGrunt01` through `gg_rct_UpsideGrunt08` and `gg_rct_UpsideGruntRemoval` for `qKrezgrel.j`.
- Compile the affected test map and full map with JassHelper, then runtime-test all quest accept/decline/turn-in paths, Mountain Defense success and both failure cases, daily reset behavior, rescue target selection, and the negative-pitch grunt effects in Reforged.

### Imports

- Generated ten normal-speed FishAudio review candidates for `Zulkis_DrunkPassOut3` and promoted the selected `v05` take to the official voice folder.

## [23.8.2026]

### Player-Facing Updates

- Split each custom quest-journal entry into Details, Description, Objectives, and Rewards tabs; item rewards now display their Object Editor icon and extended tooltip.
- Added live question-mark markers to current talk-objective targets, including `A Night To Remember` witnesses, supply handoffs, apology targets, and forgiveness returns.
- Alcohol now absorbs one Drunk point at a time before natural decay begins, while repeatable puke and pass-out checks rise steeply at high intoxication instead of occurring only when a drink is consumed.
- Puking now lasts three seconds: the unit first staggers toward a random point 250 range away, then uses a spell animation while a scaled chimera acid missile travels from head height to the ground; its hit and armor penalties remain for the configured 10 seconds afterward.
- Player pass-outs now hide MasterUI and the replacement quest-log button, restore them after the wake camera finishes, and display wake-up dialogue after the fullscreen cinematic UI has been removed.
- Player pass-outs now hold the black screen for five seconds, begin their sleeping camera at a closer distance, and let one or two nearby companions or the other player hero react before the hungover hero wakes.
- Nazgrek and Zul'kis now each choose from four urgent reactions when the other player hero passes out; these remain separate from the passed-out hero's Hangover wake-up lines.
- Nazgrek's fourth Zul'kis pass-out reaction now asks how many drinks he has had.
- After a player pass-out relocation, the other player hero, the full active companion party, and the active pet now appear nearby and move toward the sleeping hero during the fade-in cinematic.
- Travel ships, wyverns, and zeppelins now update zone music, ambience, fog, lighting, effects, and callbacks as their carrier crosses into a new zone.
- Configured Sirensong-Scout Base and Scout Base-Ashfang Outpost wyvern routes now validate their full scenic waypoint sequence instead of silently falling back to direct travel.

### Technical Updates

- Updated `UI/QuestUI.j`, `QuestsAndDialogs/QuestMaster.j`, `QuestsAndDialogs/QuestGiver.j`, `QuestsAndDialogs/QuestsVendor.j`, and `QuestsAndDialogs/QuestGivers/qANightToRemember.j` with tabbed quest details, item-reward presentation, and centralized objective-target marker registration and cleanup.
- Updated `Professions/Drunk.j`, `SoundAndMusic/ExSound.j`, and `Voicelines/Voicelines_Drunk.j` with MUI alcohol absorption, recurring exponential mishap rolls, a timed puke projectile, custom-UI pass-out lifecycle handling, first-play external audio startup before duration probing, robust vendor voice-profile lookup, and explicit missing-profile diagnostics.
- Updated `Professions/Drunk.j`, `Voicelines/Voicelines_Drunk.j`, and `tools/generate-drunk-voicelines.ps1` with a closer three-stage wake camera, a configurable five-second black hold, randomized one-or-two-speaker pass-out reactions, and personality-specific voiced reactions for AI companions.
- Updated `Voicelines/Voicelines_Drunk.j` and `tools/generate-drunk-voicelines.ps1` with four-line Nazgrek and Zul'kis pass-out reaction pools.
- Updated `Professions/Drunk.j` with pathing-aware party placement, inward cinematic movement, duplicate filtering, and restoration of prior companion suspension state after the Hangover transition.
- Updated `Travel/TravelSystem.j`, `Travel/TravelWyvern.j`, `Zones/ZoneEvent.j`, and `Travel/README.md` with carrier-position zone tracking, movement-safe player-hero zone entry forwarding, stop-ID-based waypoint assignment, and checked route construction.
- Updated `_developer/Design Plans/Story and Quest Design.md` after reviewing the legacy `_developer/_Other/WC3 Pots notes.odt` and `_developer/_Other/WC3 Pots notes other.odt`, recovering detailed prologue, Shadowclaw/fel-orc, outpost, Deadwoods, ship, Zul'karak, and Crypt concepts while separating them from current canon and implementation.
- Reconciled the old notes with current `Zones/ZonesCore.j`, Nazgrek's existing Flask item `I61L`, Zul'karak unit `n65F`, Gar unit `n60Z` in Deadwoods, the current Crypt boss roster, Ghostwalk Ridge, Elarindor's Vanguard Vale, and the confirmed mapping of the old ruined “Vanguard” city/docks to Dawnhold `20`.
- Recorded that `Travel/TravelShipA.j` already serves Sirensong, Dawnhold, and Stormhaven, so the legacy Fix the Ship quest must improve or add a service instead of duplicating the existing travel unlock.

### Tool Updates

- Added configurable FishAudio prosody speed to `tools/voicelines.ps1` and `tools/generate-drunk-voicelines.ps1` for lines that need a quicker or slower delivery.

### Imports

- Generated and imported 14 FishAudio pass-out reactions for Engineer, Paladin, Restoration Shaman, Rogue, Warlock, Warrior, and Aveline into their official voice folders.
- Generated and imported four additional FishAudio pass-out reactions for Nazgrek and Zul'kis into their official voice folders.
- Re-generated `Zulkis_DrunkPassOut3`, `Zulkis_DrunkPassOut4`, and the revised `Nazgrek_DrunkPassOut4` FishAudio recordings.
- Re-generated `Zulkis_DrunkPassOut3` again at the normal `1.0x` FishAudio prosody speed after rejecting the accelerated take.

### Actions Remaining

- In World Editor, identify the exact Dawnhold city/dock quest rects and triggers plus the northern Orc outpost, legacy Ghostridge village within Ghostwalk Ridge, Gar encounter mechanics, Nazgrek's Flask prologue, Zul'karak recruitment, and Crypt rooms before implementing those legacy concepts.

## [22.8.2026]

### Player-Facing Updates

- Fixed Outcast Jin'Zun randomly walking away during dialogue.
- Updated all 40 cooking foods and 15 drinks with explicit Well Fed or Well Hydrated durations, balanced alcoholic drinks around repeated consumption, and removed their shared item cooldown restriction.
- Wyvern flights between Sirensong, Horde Scout Base, and Ashfang Outpost now follow the first configured scenic waypoint routes in both directions.

### Technical Updates

- Updated `Zones/ZonesCore.j`, `Debug/DebugObjectRegistry.j`, and `_developer/Design Plans/Story and Quest Design.md` with Velyssara's canonical name, existing `n636` identity, legacy-name lookup rule, unresolved story decisions, and the remaining manual World Editor rename.
- Restored `_MISC/war3map.wts` to its point-in-time Velaria export after removing the attempted generated-file rename.
- Updated `AGENTS.md`, `codex-skills/jassmaster/SKILL.md`, and `codex-skills/create-qxxx-from-gui/SKILL.md` to treat `_MISC/war3map.wts` as read-only and leave all map-specific World Editor edits to the map author.
- Added `_developer/Design Plans/Story and Quest Design.md` as the master implementation ledger and forward plan for current quests, recovered Articy/GUI story material, zone-linked generic quests, dungeon packages, story branches, and cross-library event contracts.
- Updated `AGENTS.md`, `codex-skills/jassmaster/SKILL.md`, and `codex-skills/create-qxxx-from-gui/SKILL.md` so future quest and story work consults and maintains the master design plan.
- Updated `QuestsAndDialogs/QuestGivers/qOutcastJinzun.j` to lock Jin'Zun's movement for the full dialogue and restore his prior movement speed afterward.
- Updated `Professions/ProfessionsCooking.j` so registered alcoholic descriptions remain limited to the 10-minute Well Hydrated effect while runtime effect-text APIs append the configured 6-30 Drunk value automatically.
- Updated `Travel/TravelWyvern.j` and `Travel/README.md` with reusable `FPRoute001`-`FPRoute028` rect waypoints while retaining each route's existing start and final destination drop point.
- Updated `QuestsAndDialogs/QuestGivers/qRagno.j` to block Ragno interactions throughout Protect the Outpost, cancel pending dialog entry when the encounter starts, and prevent its cinematics from replacing a greeting before the quest choices appear.
- Updated `UI/MasterUI.j` and `UI/ShopUI.j` so a newly starting cinematic silently closes an active shop session without playing trade outcomes, returning to the vendor dialog, or restoring gameplay over the incoming cinematic.
- Added `_developer/Test Plans/Recent Changes Test Plan 2026-08-22.md` with prioritized, fillable compile, gameplay, UI, multiplayer, performance, and tooling checks for the major changes made from 14-21 August 2026.

### Tool Updates

- Updated `WC3_Database/WC3ItemManager/ItemEditForm.cs` with editable `icid` Cooldown Group and `iicd` Ignore Cooldown fields; selecting a Base Item ID updates only the cooldown group.
- Updated `WC3_Database/WC3ItemManager/MainForm.cs`, `WC3_Database/WC3ItemManager/ProfessionItemStatsSeeder.cs`, and `WC3_Database/WC3ItemManager/WC3ItemManager.csproj` so profession stat seeding is an explicit one-time development action that never overwrites existing database values during normal use.
- Added and applied `WC3_Database/database/update_cooking_consumables_20260822.sql` to update all cooking consumable texts, per-item ability descriptions, Drunk stats, `Alxk` cooldown groups, and Ignore Cooldown values.

## [21.8.2026]

### Player-Facing Updates

- Added a persistent 0–100 Drunk stat for alcoholic cooking drinks, party-only intoxication threshold notices, slow natural sobering, a head-attached corrosive puke stream, and a staged fullscreen pass-out camera approach with sleep invulnerability.
- Added zone and subzone hints to `A Night To Remember` witness and apology objectives, and voiced randomized Nazgrek/Zul'kis questions at the start of Last Night conversations.
- Fixed travel skip/drop-out prompts so their choices remain clickable and cancelling them with ESC preserves player-controlled camera rotation and angle.
- Reorganized custom quest-journal details into consistent Quest Details, Description, Objectives, and Rewards sections, with clearer quest-giver/turn-in contacts and explicit empty objective or reward states.
- Replaced the native Quests button with a custom quest journal using the established `TasQuestBox` presentation, improved `ShopUI`-style controls, live objective/status details, Normal/Daily/Repeatable type filters, and Story/Dungeon/Class/Profession content-category filters.
- Expanded `A Night To Remember` so one or two of its three random witnesses can be active AI company heroes, with stored witness references remaining usable after a companion leaves the party.
- Added randomized make-amends stages to one or two witness requirements, including small kill, supply replacement, and apology errands followed by a return for forgiveness.
- Expanded every LastNight witness to five personal recollections involving the speaker's reputation, property, rescue efforts, stolen goods, or a final absurd incident. Nazgrek and Zul'kis now answer each recollection with a matching voiced response.
- Reworked the repeated Stormhaven adventures across Twilight Grove, Ashfang Falls, Bonecrush Stronghold, Havenwoods, Riverbane, the Maw of Cinders, Morgrim's Claim, the Ruins of Zul'Garok, Serpentshore, Redwind Pass, Ironspine Post, and the Circle of Blood. Paladin and Aveline retain distinct Stormhaven incidents.

### Technical Updates

- Updated `Professions/Drunk.j`, `Professions/ProfessionsCooking.j`, `DestroyerInventoryAndEquipmentSystem/PoTs/DEquipment.j`, `WC3_Database/WC3ItemManager/ProfessionItemStatsSeeder.cs`, `WC3_Database/WC3ItemManager/ItemEditForm.cs`, and `Debug/DebugCommands.j` to use `udg_Stats_Drunk[]`, expose the Drunk dummy display stat, and add `/debug drunk` for the selected unit.
- Updated `Zones/ZonesCore.j`, `QuestsAndDialogs/QuestGivers/qANightToRemember.j`, `Voicelines/Voicelines_Drunk.j`, and `tools/generate-drunk-voicelines.ps1` for localized quest directions and voiced Last Night questions.
- Updated `Travel/TravelSystem.j` and `Travel/TravelUI.j` to restore native user control after travel ESC handling and release hidden prompt-button focus.
- Fixed the confirmed map-wide unit movement freeze by updating `Vendors/VendorFloatingText.j` to use the centralized `Events.j` unit-enter dispatcher instead of registering another playable-map region event.
- Updated `UI/QuestUI.j` to render reward data directly from `QuestMaster` flags for experience, gold, arena marks, faction reputation, and item rewards, and normalized the item-reward line formatting in `QuestsAndDialogs/QuestMaster.j`.
- Added `UI/QuestUI.j` as a direct `QuestMaster` consumer and updated `UI/MasterUI.j` so the replacement quest button, centralized panel hiding, ESC handling, and cinematic visibility work with the existing UI lifecycle.
- Updated `QuestsAndDialogs/QuestMaster.j`, `QuestsAndDialogs/QuestGiver.j`, and `QuestsAndDialogs/QuestsGeneric.j` with all-quest enumeration, shared display-data notifications, native-independent objective flags, category support, capacity guards, and custom quest-button notifications. Existing native quest handles remain as a hidden compatibility mirror for legacy JASS and GUI quest paths.
- Updated `QuestsAndDialogs/QuestGivers/qANightToRemember.j` with persistent AI witnesses, staged task requirements, party kill credit, dynamic vendor buttons, and self-completion after all forgiveness requirements finish.
- Added consumable pre-selection handlers to `QuestsAndDialogs/DialogInteraction.j` so quest-specific AI witness conversations can take priority over a named hero's ordinary selection dialog.
- Expanded `Voicelines/Voicelines_Drunk.j`, `tools/voicelines.ps1`, `tools/generate-drunk-voicelines.ps1`, vendor documentation, and Object Editor setup notes for AI witness dialogue and seven-line vendor Hangover pools.
- Updated `QuestsAndDialogs/QuestGivers/qANightToRemember.j` to carry the selected story category into the hungover hero's reply and complete the other-player-hero requirement only after the paired dialogue finishes.
- Added exact-key filtering to `tools/generate-drunk-voicelines.ps1` so corrected dialogue can be regenerated without rebuilding the entire review set.
- Added Aveline's Fish Audio voice ID `829032b867d447ebbabc6c30ebba911c` and retained the integer `D_PUKE_HIT_PENALTY` required by the integer `udg_Stats_Hit` scale.

### Critical Development Note

> **CRITICAL:** Do not add separate `unit enters playable map area`, `TriggerRegisterEnterRectSimple(..., bj_mapInitialPlayableArea)`, or equivalent world-region events. Additional map-wide enter registrations can cause units across the map to stop moving. All new shared unit-enter consumers must register through `Events_RegisterUnitEnter` or `Events_RegisterUnitEnterTrigger` in `Events/Events.j`. Audit and centralize an existing direct registration before introducing any new map-wide unit-enter behavior.

### Imports

- Generated and imported 4 Last Night question MP3s for Nazgrek and Zul'kis into the official voice folders.
- Generated and imported 174 Drunk/Hangover MP3s for Nazgrek, Zul'kis, Engineer, Paladin, Restoration Shaman, Rogue, Warlock, Warrior, Aveline, and eleven reusable Horde vendor profiles.
- Regenerated and imported the 15 LastNight recordings revised with zone-specific adventures without replacing unaffected audio.

### Actions Remaining

- Import and order `UI/QuestUI.j` after `QuestMaster`, `MasterUI`, `Interface`, and `Table`, then run a full JassHelper map compile and in-game test of category filtering, live objective refreshes, daily reset, quest-button flashing, cinematic hiding, and the retained legacy GUI/native compatibility paths.
- Move any remaining optional native quest-log entries used only as game-guide information into a dedicated `MasterUI` information panel when their GUI trigger definitions are available.
- Run a full JassHelper map compile and in-game test of matched recollection replies, AI witness persistence, all three task types, and vendor dialogue interruption paths.

## [20.8.2026]

### Player-Facing Updates

- Expanded `Professions/Drunk.j` with escalating puke and exponential pass-out chances, temporary hit/armor penalties, sleep effects, randomized witness reactions, player-hero fade/relocation wakeups, five-minute Hangovers, and configurable wake locations.
- Added the repeatable, self-completing quest `A Night To Remember`, which asks the hungover hero to question the other owned player hero and three random Orc, Tauren, or Troll vendors about the previous night.
- Converted the Satyr rare-goods, reagent, enchanting, and potion vendors to Velyssra the Covetous, Malthera Duskmoss, Ithryssa Runehorn, and Selyth Venomcup, with a mean and cunning female Satyr voice profile shared by their vendor and quest dialogue.
- Nazgrek and Zul'kis now each have four personality-specific randomized replies for generic quest acceptance, kill completion, talk completion, fetch completion, progress, supply handoffs, and quest purchases.
- Generic vendor and quest voices now use clearly reusable `GenericRaceGenderN` profile names instead of vendor-oriented or ambiguous speaker names.

### Technical Updates

- Added `QuestsAndDialogs/QuestGivers/qANightToRemember.j`, `Voicelines/Voicelines_Drunk.j`, `Professions/DrunkObjectEditorSetup.md`, and the Troll witness libraries `qZanjinGemeye.j` and `qRokjinHexsmoke.j`.
- Updated `Vendors/VendorDialogs.j` and 13 existing Horde vendor qXXX libraries with contextual last-night dialogue and a 15-vendor witness registry.
- Updated `tools/voicelines.ps1`, added `tools/generate-drunk-voicelines.ps1`, and updated `Voicelines/FishAudioVoiceIds.md` plus the vendor quest README for the new hero, AI companion, and reusable Horde vendor voice pools.
- Added and registered `GenericSatyrFemale1` across `Voicelines/Voicelines_VendorLines.j`, `Voicelines_Quests.j`, Satyr vendor bindings, and the four matched vendor-quest definitions.
- Moved Nazgrek and Zul'kis generic quest text, keys, sound registration, and reply-variant registration into `Voicelines/Voicelines_Nazgrek.j` and `Voicelines_Zulkis.j`.
- Updated `QuestsAndDialogs/QuestsGeneric.j` and `QuestsVendor.j` to select matching randomized hero text and audio by interaction type.
- Renamed reusable profile constants, sound keys, registered paths, vendor bindings, quest bindings, documentation, and generator filters to the `Generic*` convention.
- Updated `tools/voicelines.ps1` to regenerate official keys with `-Force`, read speaker-owned hero text constants, and prefer specific nested sound folders during generation.
- Updated `tools/voicelines.ps1` to scan directly registered personality voice lines, including the custom female Satyr profile.

### Imports

- Generated, validated, and imported all 118 registered `GenericSatyrFemale1` MP3s: 15 personality lines, 76 catalog-role lines, and 27 reusable Satyr quest lines.
- Imported the 175 previously validated Elarindor and Goblin review files into their renamed official generic folders.
- Generated and imported 3,468 previously missing generic-profile MP3s.
- Regenerated and replaced 38 existing Nazgrek and Zul'kis generic MP3s whose reply categories changed, and added 18 new replies, producing 28 active generic replies per hero.
- Renamed the active reusable sound folders and MP3 keys to `Generic*`; all 6,225 selected registered keys are present in the official tree.

### Actions Remaining

- Replace the placeholder `ADRK`, `APUK`, and `AHNG` rawcodes with the three configured Object Editor aura/buff abilities, register the final preplaced pass-out rects, and configure death/decay fallbacks for models without sleep animations.
- Generate and review the staged Drunk/Hangover MP3 set after Fish Audio tool usage becomes available; Aveline also needs a Fish Audio reference ID.
- Decide whether to delete the 14 legacy `Vendor*` and `VendorQuest*` folders. Their 2,544 MP3s are hash-identical to mapped files in the reusable profiles and no active JASS registration uses the legacy paths.
- Run a full JassHelper map compile and in-game vendor/quest dialogue test.

## [18.8.2026]

### Player-Facing Updates

- Generic Human, Orc, Troll, Goblin, Tauren, Satyr, Morgrim dwarf, Elarindor, and Bonecrusher voices now support multiple reusable FishAudio profiles instead of treating every member of a race and gender as one speaker.
- Vendors now distribute regional and role-appropriate voice profiles across their roster, and quest-giving vendors retain the same voice while trading and giving quests.
- Nazgrek and Zul'kis now have twelve additional reusable generic quest replies each.

### Technical Updates

- Updated `Vendors/VendorLines.j` with per-unit and per-unit-type voice bindings independent of regional dialogue profiles.
- Updated `Voicelines/Voicelines_VendorLines.j`, `Voicelines_Quests.j`, vendor faction libraries, and vendor quest libraries to use reusable numbered voice prefixes and a shared `1001+` generic-quest range.
- Updated `tools/voicelines.ps1` to discover reusable numbered profiles, shared vendor/quest sequences, and multiple speaker filters in one generation run.
- Updated `Voicelines/FishAudioVoiceIds.md` and the vendor-quest README with reference IDs, regional/role usage, folders, and normalized duplicate profile labels.

### Imports

- Re-keyed 2,558 existing approved vendor and quest MP3s into reusable profile folders without replacing their source recordings.
- Added 24 new reusable Nazgrek and Zul'kis generic quest-reply MP3s.

- New models (from WoW vanilla):
  - Goblins:
    - Alchemist Pestlezugg.mdx
    - Arena Promoter.mdx
    - Auctioneer Kresky.mdx
    - Baron Revilgaz.mdx
    - Crank Fizzlebub.mdx
    - Fin Fizracket.mdx
    - Frezza.mdx
    - Grimestack.mdx
     -Grizzlowe.mdx
    - Jazzrik.mdx
    - Narkk.mdx
  - Humans:
    - HumanFemaleFarmer.mdx
    - HumanFemalePeasant.mdx
    - HumanMaleBlacksmith.mdx
  - Ogres:
    - Ogre.mdx
    - OgreMage.mdx
    - OgreWarlord.mdx
  - Zeppelin:
    - transport_zeppelin.mdx
    - zepanimation.mdx
## [16.8.2026]

### Player-Facing Updates

- Crafting cameras now remain locked to the active crafting unit during normal and repeated query crafting.
- Ship-travel cameras now target above the vehicle origin, keeping the deck centered instead of framing the hull and waterline.
- Nazgrek and Zul'kis ship proxies now use standing character effects with separately tuned neutral-ship and orc-frigate deck positions.
- Human, goblin, Bonecrusher ogre, Elarindor, and Tauren vendor quests now play their generated race and gender voice files for introductions, completions, and daily follow-up dialogue.
- Nazgrek and Zul'kis now use their own voiced replies when accepting, progressing, completing, collecting, or purchasing for vendor quests.

### Technical Updates

- Extended `Camera/FixedCameraLock.j` with a backward-compatible configurable target-height offset and updated `Travel/TravelSystem.j` to use a 300-unit offset for ships only.
- Updated `Travel/TravelSystem.j`, `TravelShipA.j`, and `TravelShipB.j` with centrally registered passenger effects, reusable local-X/local-Y deck slots, per-ship deck configuration, model preloading, and explicit stand animation playback.
- Updated `Camera/DialogCamera.j` to use the persistent fixed-camera lock for focused cameras and release it before restoring normal camera control.
- Updated `EnvironmentSystems/FrostbiteSystem.j` to scan only the two relevant player owners and reuse its unit filter instead of enumerating the entire map every second.
- Updated `QuestsAndDialogs/QuestMaster.j` to preserve unchanged minimap icons and distribute periodic quest-giver availability checks across smaller timer batches, preventing five-second refresh spikes.
- Updated `Vendors/VendorFloatingText.j` to replace its recurring full-map vendor scan with startup discovery and event-driven registration for newly entering units.
- Updated `Voicelines/Voicelines_Quests.j`, `QuestsAndDialogs/QuestsGeneric.j`, `QuestsVendor.j`, and `DialogInteraction.j` with selectable-hero quest voice routing and separate male/female Elarindor vendor-quest families.
- Updated the Elarindor vendor quest libraries and `QuestsAndDialogs/QuestGivers/Vendors/README.md` with gender-specific sound prefixes and folder mappings.
- Added `Voicelines/FishAudioVoiceIds.md` as the non-secret reference-ID map for current vendor, vendor-quest, Nazgrek, and Zul'kis FishAudio voices.
- Updated `Voicelines/Voicelines_Quests.j`, the vendor-quest README, and the FishAudio ID map so Nazgrek and Zul'kis vendor-quest replies use their character-specific generic sound folders.

### Tool Updates

- Updated `tools/voicelines.ps1` to discover computed `VendorQuestXXXX_0000` definitions, daily variants, hero replies, sequence ranges, and expected folders directly from `Voicelines_Quests.j`.

### Imports

- Added 175 generated vendor-quest MP3s across human, goblin, Bonecrusher ogre, Elarindor male, Elarindor female, Tauren, Nazgrek, and Zul'kis voice folders.

### Actions Remaining

- Generate the 43 Orc and 27 satyr vendor-quest files after suitable FishAudio voice references are available.

## [15.8.2026]

### Player-Facing Updates

- Fixed Aveline's retained Fake Death pose so her custom model plays its full death animation before the corpse is frozen.
- Gnoll Hideout now allows camera rotation with a limited 270-295-degree angle range.
- Travel-point discovery now reads "New travel point" in white while keeping the discovered destination name green.
- Fullscreen crafting and travel cameras now keep arrow-key control available; travel ESC and intermediate-stop choices stay in fullscreen and use a dedicated TravelUI prompt.
- Wyvern and AI flight arrivals now finish reliably after landing instead of remaining stuck when Warcraft does not update the carrier's reported fly height.
- Goblin vendors in Riverbane, Stormhaven, Sirensong, travelling routes, and the arena now have distinct voiced trade dialogue profiles ready for their shared goblin voice set.
- Fiery Mountain, forest, and Sirensong orc vendors, satyr merchants, Bonecrusher ogres, Graknar's bag shop, and the regional human/orc blacksmiths now have voiced transaction profiles ready for their matching voice sets.
- Vendor greetings, shop-open lines, catalog chatter, transaction responses, and farewells now use each vendor's bound race and gender voice, including Tauren bartenders and Elarindor quartermasters.
- Missing external vendor sounds now keep dialogue timing intact by estimating duration from the displayed text and reporting the missing ExSound key.
- Restyled the crafting panel to match ShopUI, with a darker inset backdrop, clearer text hierarchy, larger recipe rows and icons, a framed profession line, and cleaner detail and action-button spacing.
- Kribugs' dialogue now distinguishes the goblin Kribugs from his ogre carrier Mogsnort even though they share one composite unit, with situational Mogsnort interjections and the original ogre grunts, growls, hunger complaint, and fart laugh.
- Kribugs' normal shop now has a clear Back control, reliably returns to his dialogue choices, and uses unique trade chatter and transaction reactions with occasional Mogsnort interruptions.
- Expanded wyvern travel to Verdant Plains, Ashfang Outpost, and Sirensong, with all six flight points requiring player discovery and Verdant Plains also supporting a quest/event unlock.
- Added gradual takeoff and landing height transitions for wyvern and bat travel, plus physical zeppelin travel for AI heroes that treats every flight point as discovered.
- Added the scheduled neutral Ship A route between Sirensong, Dawnhold, and Stormhaven, including Dawnhold drop-out prompts and direction-aware destination choices.
- Travel-point discovery now uses the region-title presentation, a green destination name, and the zone-discovery sound.
- Enabled Mok'natha, Frontbase, and Ironspine as Ship B boarding points and added configured Nazgrek and Zul'kis deck models for ship journeys.

### Technical Updates

- Updated `AI/Specific/AI_Aveline.j` with the custom model's two-second death-time field used by retained Fake Death animation freezing.
- Updated `UI/CameraControl.j` and `UI/FullscreenUI.j` with the adjustable Gnoll Hideout preset, centralized interactive-camera user control, and delayed ESC fullscreen restoration.
- Updated `Travel/TravelSystem.j`, `TravelUI.j`, `TravelWyvern.j`, and `TravelAI.j` with fullscreen frame prompts, reusable registered waypoints, bounded player/AI flight descent completion, and active travel camera control.
- Updated `Travel/README.md` with fullscreen prompt, interactive camera, shared waypoint, and arrival fallback behavior.
- Updated `Voicelines/Voicelines_VendorLines.j`, `Vendors/VendorFactions/VendorGoblins.j`, `Vendors/VendorCatalogs.j`, and `tools/voicelines.ps1` with named goblin profile constants, 75 numbered `VendorGoblinMale` sound keys, constant-based unit and zone bindings, and scanner support for computed vendor sequences.
- Updated `Voicelines/Voicelines_VendorLines.j` and the orc, satyr, Bonecrusher ogre, blacksmith, bag, and general-goods vendor libraries with 135 additional voiced lines, shared profile constants, contiguous ExSound sequences, and constant-based bindings.
- Updated `SoundAndMusic/ExSound.j`, `Vendors/VendorLines.j`, `Vendors/VendorDialogs.j`, and `Voicelines/Voicelines_VendorLines.j` with restored missing-sound warnings, text-duration fallback, catalog sound-key resolution, and explicit race/gender catalog registrations.
- Updated `UI/CraftingUI.j` with the ShopUI panel proportions, seven-row recipe list, detail-info backdrop, and pane-local crafting controls.
- Updated `Voicelines/Voicelines_Kribugs.j` and `QuestsAndDialogs/QuestGivers/qKribugs.j` with separate `Mogsnort_XXXX` voicelines, labeled legacy ogre Sound Editor cues, registered speaker folders, and shared-unit cinematic speaker routing.
- Updated `QuestsAndDialogs/QuestMaster.j` so unchanged quest-giver marker models persist instead of being destroyed and recreated during periodic availability refreshes.
- Updated `UI/ShopUI.j`, `QuestsAndDialogs/QuestGivers/qKribugs.j`, and `Voicelines/Voicelines_Kribugs.j` with per-vendor return handlers, clearer shop navigation, and Kribugs-owned vendor lines.
- Updated `Vendors/VendorLines.j` with optional per-line speaker overrides so composite vendors can randomly alternate speakers without changing ordinary vendor profiles.
- Updated `Travel/TravelSystem.j`, `TravelWyvern.j`, `TravelAI.j`, `TravelShipA.j`, and `TravelShipB.j` with the six wind-rider masters, six shipmasters, flight-height transitions, AI zeppelin carriers, direction-aware scheduled routes, and complete local PatrolSystem paths.
- Updated `Travel/TravelAI.j` and `PatrolFollowSystems/PatrolSystem.j` to pause idle travel updates, throttle AI approach scans, and avoid repeatedly rebuilding active patrol paths.
- Updated `Travel/README.md` with the active master mapping, Ship A waypoint loop, default fares, quest discovery API, passenger models, and AI discovery policy.

### Tool Updates

- Updated `tools/voicelines.ps1` with exact-key filtering for selective FishAudio regeneration without replacing an entire speaker family.
- Updated `tools/voicelines.ps1` to discover race/gender catalog combinations and generate their computed numbered FishAudio keys into the correct review folders.

### Imports

- Added 2,113 generated vendor catalog MP3s across the human male, human female, Tauren male, Morgrim dwarf male, Elarindor male, Elarindor female, goblin male, and Bonecrusher ogre male voice folders.

- Imported 270 generated vendor MP3 files for the human male, human female, Tauren male, Morgrim Dwarf male, Elarindor male, Elarindor female, Goblin male, and Bonecrusher Ogre male ExSound sequences.

### Actions Remaining

- Generate the Orc, Troll, and Satyr vendor sequences after suitable FishAudio voice references are available.

### Known Issues

- The new Ship A rect globals and full travel changes still require World Editor/JassHelper compilation and in-map route, deck-offset, camera, discovery, and multiplayer validation.

## [14.8.2026]

### Player-Facing Updates

- Updated `QuestsAndDialogs/QuestGivers/qOutcastJinzun.j` so Jin'Zun's quests have no hidden hero-level requirement; their displayed levels remain recommendations and the quest chain still follows its prerequisite order.
- Added configurable wyvern, zeppelin, neutral-ship, and orcish-ship travel with a ShopUI-styled destination/passenger panel, fullscreen vehicle camera, paid ESC skipping, ship stop drop-out prompts, party fare accounting, and physical AI wyvern journeys.
- Wyvern and zeppelin routes now require both endpoint travel masters to be discovered before use; ship routes can remain available without endpoint discovery.
- Travel now fades before changing units or camera mode, uses a closer adjustable vehicle camera, shows working ESC confirmation dialogs, and keeps the MasterUI Game button hidden when configured.
- Added Sirensong as a discoverable wyvern station through `WindRiderMaster[6]`, with directed connections to all three legacy Horde stations.
- Vendors now refuse conversations while either participant is in combat, and vendor dialogue, trade UI, camera transitions, and active voicelines end immediately when the hero or vendor attacks, is attacked, dies, or enters combat.

### Technical Updates

- Added `Travel/TravelSystem.j`, `TravelUI.j`, and method sublibraries for per-route discovery policy, directed fares, waypoint paths, scheduled vehicles, passenger effects, legacy Horde wyvern stations, and the existing Ship B patrol.
- Updated `AI/AI.j` with a travel-provider bridge and external approach/travel lifecycle used by `Travel/TravelAI.j`, retaining abstract random travel as the fallback.
- Updated `PatrolFollowSystems/PatrolSystem.j` with a backward-compatible direct-coordinate patrol API that does not require temporary locations or GUI waypoint arrays.
- Updated `Travel/TravelShipB.j`, the Mordrax, Morthun, and Mountain Giant boss libraries, and `QuestsAndDialogs/QuestGivers/qValeria.j` to own and start their patrol routes locally through the direct-coordinate API.
- Updated `Travel/TravelSystem.j` with the authoritative World Editor shared-unit mapping for wyvern, zeppelin, ship-master, vehicle, hero, and pet globals, including active versus reserved bindings.
- Updated `Travel/TravelSystem.j`, `TravelWyvern.j`, and `TravelShipB.j` so only the master travel library accesses World Editor `udg_*` bindings; method libraries now use semantic getters and named master-index constants.
- Updated `Travel/TravelZeppelin.j` to bind the Sereneglade and Sirensong flightmasters, endpoint regions, and their Zeppelin A/B outbound vehicles automatically through `TravelSystem`.
- Updated `Travel/TravelSystem.j`, `UI/CameraControl.j`, and `UI/MasterUI.j` with fade-staged travel presentation, a 750-distance/80-FOV adjustable camera preset, configurable Game-button hiding, visible native travel prompts, Player(5) invulnerable flight vehicles, shared-master-safe selection handling, and overhead green marks for all configured GUI travel masters.
- Updated `UI/CameraControl.j`, `Travel/TravelUI.j`, and `UI/CraftingUI.j` so suspended travel cameras start their interactive keyboard state correctly, while travel and crafting buttons release frame keyboard focus and the crafting panel restores normal camera mode.
- Updated `QuestsAndDialogs/DialogInteraction.j` and `DialogSystem.j` with a reusable, default-on combat-sensitive interaction guard, optional per-call opt-out, cancellable transitions, and immediate sequence, field-line, transmission, and ExSound cleanup.
- Updated `Vendors/VendorDialogs.j`, `UI/ShopUI.j`, and Kribugs' custom qXXX dialogue to transfer the guarded vendor/hero context between dialogue and trade UI instead of maintaining separate partial attack listeners.

### Actions Remaining

- Import the travel libraries after their dependencies, disable the replaced legacy travel dialogs and detached patrol initialization triggers, and run focused plus full-map JassHelper and multiplayer tests, including Ship A deck-offset tuning.
- Full-map test vendor entry, greeting, quest dialogue, ShopUI, and Kribugs' custom trade/deal UI while either participant attacks, is attacked, dies, or enters combat; also verify an explicit `endOnCombat = false` test interaction remains open.

## [13.8.2026]

### Player-Facing Updates

- Increased grouped dungeon boss and creep respawns from five minutes to thirty minutes; independently selected random-respawn creeps retain their shorter individual timers.

### Technical Updates

- Updated `DungeonsAndBosses/Boss.j` to call open-world and dungeon fight boundaries combat areas, avoiding confusion with the separate `Arena/` game-mode system; `Boss_SetArena` remains as a compatibility alias.
- Updated `DungeonsAndBosses/Dungeon.j` and dungeon registrations with the thirty-minute grouped timer plus force-respawn APIs covering dead bosses, grouped creeps, and random-respawn creeps.
- Updated `Debug/DebugCommands.j` with `/debug creeprespawn dungeon respawn` for all registered dungeons and an optional zone-id suffix for one dungeon.

## [12.8.2026]

### Player-Facing Updates

- Updated `Professions/Professions.j` and `UI/CameraControl.j` so crafting cameras accept arrow-key angle and rotation changes while remaining locked to the active crafting unit.
- Fixed `UI/GambleUI.j` so Previous and close reliably return to Kribugs' dialog, insufficient-gold and inventory errors remain visible inside the panel, and the Special Deal uses a clearer ShopUI-inspired offer layout.
- Fixed Ragno's level-one Neutral-Horde quest availability and Protect the Outpost completion staging so Ragno walks into a close conversation position and cinematic units only move while the screen is fully faded out.

### Technical Updates

- Updated `QuestsAndDialogs/DialogSystem.j` with reusable fade-out, black-screen action, and fade-in sequence transitions, `QuestsAndDialogs/QuestMaster.j` with batched quest-giver icon refreshes, and `QuestsAndDialogs/QuestGivers/qRagno.j` with the standardized fade-safe choreography and explicit Neutral Horde requirements.
- Added `_developer/gui-variables.md` with a source-level inventory of current `udg_*` and `gg_*` usage, classified legacy GUI trigger removal candidates, and categorized Variable Editor cleanup candidates.
- Updated `Zones/ZonesCore.j` with `ZoneData.addDungeonEnterRegion` and `addDungeonExitRegion`; Gnoll Hideout, Crypt, and Boom Mine now keep portal source, destination, and facing metadata in ZonesCore while ZoneEvent executes the transitions.
- Added `World/Dragons/DragonBehavior.j` for shared red/scorching dragon melee animations, opportunistic Breath of Fire and Flame Strike casts, and ambient dragon sounds.
- Added `World/Dragons/EmberpeakDragons.j` for Emberpeak center/highlands wandering and occasional random-unit Flame Strikes.
- Added `World/Dragons/DragonfirePeaksDragons.j` as the separate owner of preplaced or generated Dragonfire Peaks wanderers and their occasional random-unit Flame Strikes.
- Updated `DungeonsAndBosses/OpenWorld/Colossus/EmberpeakDragonfire.j` and `BossColossus.j` so the encounter-specific dragons and targeting modes remain separate from both ambient zone systems.
- Updated `UI/CameraControl.j` and `DungeonsAndBosses/Dungeons/Gnoll Hideout/DungeonGnollHideout.j` with a unique Gnoll Hideout camera preset and zone activation.
- Added `DungeonsAndBosses/Dungeons/Gnoll Hideout/BossImpaler.j`, `BossFeldok.j`, and `BossAbomination.j`, moving all Gnoll Hideout boss state, phases, abilities, descriptions, summons, cleanup, and dungeon registration out of `DungeonGnollHideout.j`.
- Added `DungeonsAndBosses/Dungeons/Boom Brothers Mine/BossMadBlix.j`, moving Mad Blix's recoverable encounter behavior and dungeon registration out of `DungeonBoomBrothersMine.j`.
- Updated the Gnoll Hideout and Boom Brothers Mine dungeon libraries to contain only dungeon-wide configuration and events, with their ordinary-creep scans delayed until the separate boss libraries have registered.

### Actions Remaining

- Run an in-map JassHelper compile and validate Ragno's level-one quest buttons, stable overhead marker, and both Protect the Outpost fade-safe CinematicMover transitions.
- Import `World/Dragons/DragonBehavior.j`, `EmberpeakDragons.j`, and `DragonfirePeaksDragons.j`; disable the converted Dragons GUI triggers and runtime-test both zones' wandering/casting plus every Colossus dragonfire mode.
- Import each new dungeon `BossXXX.j` after its owning dungeon library, then run the affected-map and full-map JassHelper compiles and runtime-test boss registration before ordinary-creep registration.

## [11.8.2026]

### Player-Facing Updates

- Dungeon bosses and their full-respawn creep packs now return together after thirty minutes, while a configured 35% share of ordinary dungeon creeps can repopulate independently after 120-320 seconds; bosses are never part of that random pool.
- Revived AI heroes now follow their focused player hero back toward the active dungeon entrance. Changing focus restores normal companion behavior immediately, and an AI hero still outside after 120 seconds teleports to the dungeon's configured inside point with teleport effects.
- Gnoll Hideout, Crypt, and Boom Mine entrances and exits now use registered ZoneEvent transitions, moving the entering hero, controlled companions, and tamed units without their disabled GUI portal triggers.
- Restored the recoverable dungeon mechanics for Impaler, Deathlord Fel'Dok, Abomination, the Crypt spike trap, Boom Brothers Mine, and Mad Blix, plus the recoverable open-world mechanics for Chimairo, Colossus, Mordrax, Rol'jin, Sargoth, Scorchion, and the Void Entity.
- Restored Boom Mine barrel countdown text, the Colossus dragonfire reversal and healing-golem cycle, Scorchion's worshipper engagement and fire-orb warnings, Mordrax's loot and combat lines, Rol'jin's movement taunts, and the Void Entity's reveal, dialogue, scripted defeat, and quest requirement completion.
- Converted Outcast Jin'Zun's legacy quest chain, optional quests, roaming dialogue, Healing Ward placement, tree restoration, and succubus dispel interaction to the current quest and dialogue systems.
- Jin'Zun's quests no longer grant Horde reputation. After Sargoth he equips his fishing pole; after Unknown Entity he loses it, discovers `Da Fishing Pole Missing`, relocates to his lake spot, and resumes fishing animation when the pole is returned.
- The Unknown Entity lake investigation, meat lure, tentacle ambushes, boss reveal, combat start, slime drop, and death cleanup now run without the legacy GUI triggers.
- Prince Zaekolaerr can now be questioned about Jin'Zun's missing fishing pole while the retrieval quest is active.
- Converted Kribugs' six legacy quests, ogre fullness cycle, patrol interaction, unique dialogue, and merchant access to the current quest and vendor systems.
- Kribugs' ordinary Trade stock is now his own fixed selection of adventuring supplies. His 1000-gold Special Deal opens a separate mystery-item gamble, grants a weighted random reward, and no longer reuses stale ShopUI vendor state or leaves player control disabled.
- Added 21 planned dialogue vendors: ten bartenders, four jewelcrafters, two Orc spirit speakers, two Orc fel-curio dealers, one Troll voodoo merchant, one Human arcanist, and one Elarindor magister.
- Bartenders primarily sell common drinks with light food stock; jewelcrafters sell rings, necklaces, and trinkets; each mystical specialist carries themed crystals, essences, charms, or relics.
- Horde Troll merchants now use Horde reputation and their own male merchant dialogue profile.
- Autonomous AI heroes now shop across nearby Vendor-system merchants, favoring faction-compatible, reachable, useful, and situationally relevant catalogs without requiring manual shop bindings.
- AI purchasing now follows a conservative price tier based on Player(0)'s highest hero level, buys at most one item per trip, waits four to eight minutes between successful shopping trips, and keeps at most two copies of a consumable type.
- Fixed Ragno's starting quest availability, Protect the Outpost wave and cinematic choreography, grunt speakers, Gnoll Head drops, and Lumberjack Duties acceptance and harvesting flow.

### Technical Updates

- Updated `DungeonsAndBosses/Boss.j` with encounter descriptions, dungeon ownership, durable boss replacement and respawn, respawn callbacks, name-based setup discovery, and strict defeated-unit respawn validation.
- Added `DungeonsAndBosses/Dungeon.j` with explicit ZonesCore/ZoneEvent dungeon registration, simultaneous full-pack respawns, independent random-creep respawns, boss exclusion, and synchronized revived-AI entrance routing with a 120-second teleport fallback.
- Added `DungeonsAndBosses/Dungeons/DungeonZones.j` for Wyrmhold Sanctum, Firelands, and Dreadforge routing/containment configuration.
- Added `DungeonsAndBosses/Dungeons/Gnoll Hideout/DungeonGnollHideout.j`, `DungeonsAndBosses/Dungeons/Crypt/DungeonCrypt.j`, and `DungeonsAndBosses/Dungeons/Boom Brothers Mine/DungeonBoomBrothersMine.j` as JASS replacements for the recoverable dungeon boss, trap, wave, and explosive-rock GUI behavior.
- Added encounter libraries for Chimairo, Colossus, Jinvorrak, Mal'kiri, Mordrax, Morthun, Mountain Giant, Rol'jin, Sargoth, Scorchion, Void Entity, and Vorkatha under `DungeonsAndBosses/OpenWorld/`; source-empty encounters remain catalogued without invented mechanics.
- Updated `Companions/Companions.j` with focused-leader queries, suspension state, and immediate leader-change callbacks used by dungeon revival routing.
- Updated `Zones/ZoneEvent.j` with synchronized per-hero zone queries and leave-state cleanup for dungeon routing.
- Updated `Zones/ZoneEvent.j` with reusable entrance/exit transition and presentation handling; ZonesCore owns portal rects/facings, dungeon libraries own presentation choices, and ZoneEvent owns movement and zone state.
- Added `DungeonsAndBosses/OpenWorld/Colossus/EmberpeakDragonfire.j`, `DungeonsAndBosses/OpenWorld/Mordrax/BossMordraxDialogue.j`, and `DungeonsAndBosses/OpenWorld/Void Entity/BossVoidEntityDialogue.j` to replace the remaining disabled dragonfire and voice GUI triggers.
- Updated `Companions/Companions.j` with an external-order override used by dungeon revival routing without changing player suspension state.
- Updated `CreepRespawn/CreepUnitAssignment.j` to stop executing the disabled Mordrax, Morthun, and Mountain Giant patrol triggers; their encounter libraries now own patrol setup.
- Updated `CreepRespawn/CreepRespawn.j` so encounter-owned units can be durably excluded before its deferred preplaced-unit scan, preventing duplicate boss or dungeon-creep respawns.
- Added `DungeonsAndBosses/Unknown Entity/BossUnknownEntity.j` to implement the complete imported Unknown Entity encounter on `Boss.j`, with quest callback registration instead of GUI trigger calls.
- Added `QuestsAndDialogs/QuestGivers/qOutcastJinzun.j` from the legacy `QuestsAndDialogs/OLDGUI/OutcastJinzun` triggers, including quest prerequisites and rewards, item tracking, direct `BossUnknownEntity` integration, the remaining crypt hook, patrol and fishing-spot control, quest-item recovery, neutral-faction rewards, and respawn refresh support.
- Updated `QuestsAndDialogs/QuestGivers/qZaekolaerr.j` with the active fishing-pole quest inquiry and availability marker integration.
- Updated `CreepRespawn/CreepUnitAssignment.j` and its test-map variant to restore Jin'Zun through `qOutcastJinzun` instead of restarting the legacy GUI patrol trigger.
- Added `QuestsAndDialogs/QuestGivers/qKribugs.j` from the legacy `QuestsAndDialogs/OLDGUI/Kribugs` triggers, including quest prerequisites, item and kill tracking, repeatable meat/cure flow, dialogue voicelines, patrol control, and respawn hooks.
- Updated `Vendors/VendorDialogs.j` with custom-dialog vendor registration so bespoke quest givers can retain ShopUI, catalog, trade outcome, and return-flow integration without opening the generic vendor dialog in parallel.
- Added `UI/GambleUI.j` as an isolated weighted mystery-item purchase panel with inventory-capacity checks, gold validation, reward reveal, and purchase/return callbacks.
- Updated `QuestsAndDialogs/QuestGivers/qKribugs.j` so normal Trade uses a unique fixed vendor catalog while Special Deal follows the legacy 1000-gold gamble draft and its paid voicelines.
- Updated `QuestsAndDialogs/QuestGivers/qRagno.j` with Horde-enemy starting access, a Protect the Outpost prerequisite for Call of the Horde, rect-selected surviving grunts, CinematicMover staging, threshold-based gnoll waves, base-gnoll loot registration, and delayed FollowSystem-safe peon harvesting.
- Updated `CreepRespawn/CreepUnitAssignment.j` to restore `qKribugs` vendor, quest-dialog, and patrol hooks after respawn instead of executing the converted GUI patrol trigger.
- Updated `Vendors/VendorCatalogs.j` and `Vendors/VendorLines.j` with seven new catalogs, 21 canonical unit names, initial stock, and specialist type labels.
- Updated the Orc, Tauren, Human, Goblin, Bonecrusher Ogre, Elarindor, and Morgrim Dwarf faction libraries with the new unit bindings.
- Added `Vendors/VendorFactions/VendorTrolls.j` and required it from `Vendors/VendorDialogs.j`.
- Updated `Voicelines/Voicelines_VendorLines.j` with centralized bartender, jewelcrafter, shamanic, fel, voodoo, arcanist, magister, and Horde Troll dialogue; reserved `VendorTrollMale_0001-0015` in ExSound.
- Removed legacy Marketplace, Goblin Merchant, Voodoo Lounge, Armorsmith, Weaponsmith, and Tome Merchant buildings from current vendor defaults and AI shop bindings while leaving their Object Editor definitions untouched.
- Updated `Vendors/Help/VendorsHelper.md` and `Vendors/Help/infoVendors.md` with the Object Editor roster, genders, zones, import order, and legacy-building exclusion list.
- Updated `AI/AI.j` with dynamic nearby vendor discovery, weighted catalog selection, allowed-zone checks, faction-link and Neutral-reputation gating, and low-health/low-mana shopping priorities.
- Updated `Vendors/Shop.j` with reusable AI vendor-utility evaluation and a Player(0)-hero-level price ceiling shared by discovery and final purchasing.

### Actions Remaining

- Import the new Boss, Dungeon, dungeon-zone, dungeon encounter, open-world encounter, dragonfire, and dialogue sublibraries in dependency order, then compile the affected test map and full map with JassHelper. The matching legacy GUI triggers are now disabled; `Init Boss Units` remains enabled for preplaced-unit setup.
- Multiplayer runtime-test simultaneous/random dungeon respawns, Crypt and Boom Mine events, focus switching, graveyards at different distances, portal pathing, physical dungeon entry, and the 120-second teleport fallback in all six configured dungeon zones.
- Runtime-test every migrated boss reset, phase, summoned-unit cleanup, scripted defeat, patrol, dialogue, quest callback, and respawn path. Mal'kiri and Vorkatha remain catalog encounters because no non-empty source mechanics exist to reconstruct.
- Full-map compile and multiplayer runtime-test Ragno's starting availability, daily reset, outpost wave threshold, cinematic movement and speakers, Gnoll Head drops, and lumber-peon harvesting.
- Import `QuestsAndDialogs/QuestGivers/qOutcastJinzun.j` after `BossUnknownEntity` and before `qZaekolaerr.j`; disable the converted OutcastJinzun and Unknown Entity GUI trigger groups, connect the remaining Crypt encounter hook, then compile and runtime-test the full quest chain, lake encounter, Jin'Zun's fishing-spot pathing, and both player interaction paths.
- Create the 21 documented unit types in Object Editor using the assigned rawcodes, names, suffixes, and genders, then place and runtime-test representative vendors from every new catalog.
- Import recordings for `VendorTrollMale_0001-0015`; text-duration fallback remains active until those files exist.
- Full-map test autonomous Horde, Riverbane, Goblin, and Elarindor heroes near friendly, neutral, hostile, inaccessible, empty-stock, and high-price vendors.

## [10.8.2026]

### Player-Facing Updates

- Companion Attack commands now use the Aggressive mode voice lines, while Move commands use the Normal mode voice lines.
- Forest Trolls now grant Horde reputation using their actual Thornwoods unit types, and killing the Riverbane Bandit Lord now grants Riverbane reputation.
- AI heroes, including Aveline, now use selectable retained Fake Death bodies and return normally when their automatic revival completes.
- Nazgrek's starting Healing Salve and Spring Water now begin in his standard six-slot inventory instead of DInventory.
- Vendor cameras now remain near an 850-range view and drift slowly between low-height, obstacle-checked compositions instead of snapping through distant or excessively elevated shots.
- Closing Trade UI now plays the correct bought, sold, bought-and-sold, or no-transaction response and returns to the vendor's dialogue choices; choosing Exit restores gameplay before the farewell line.
- Morgrim Clan vendors now respond using their current `h00T` through `h010` Object Editor rawcodes.
- Selecting a vendor below its faction reputation requirement now reports that faction immediately instead of entering a conversation that cannot trade.
- Quest dialogue buttons now use shared state markers, and incomplete generic quests draw from objective-specific kill, fetch, talk, and purchase responses.
- All Morgrim Clan Dwarf vendors now use male names and the dedicated male Dwarf merchant voice profile.
- Vendor dialogue and Trade UI cameras now remain locked to the active vendor until the interaction fully exits.
- Vendor quest availability now updates independently of vendor selection using the higher Player(0)-owned Nazgrek or Zulkis level and the giver faction's Neutral reputation requirement.
- Quest giver overhead markers now remain stable when an availability check leaves every quest in the same state.

### Technical Updates

- Updated `Companions/Companions.j` with separate Move and Attack voice-line mappings, currently backed by the Normal and Aggressive mode line sets so dedicated command recordings can replace them later.
- Updated `Reputation/Reputation.j`
  - Replaced the mistakenly registered Furbolg rawcodes with all six standard Forest Troll rawcodes used in Thornwoods.
  - Added the missing Bandit Lord rawcode to the hidden Bandit reputation source.
- Updated `AI/AI.j` and `Death/Death.j`
  - Enabled Fake Death by default for every AI hero profile while preserving the existing per-profile override.
  - Added an automatic AI revival callback that releases retained Death-system state, clearing corpse invulnerability, pause, pathing, and fallen-state tracking.
- Updated `Preload/Start.j` to exclude Nazgrek's newly created starter consumables from DInventory pickup storage while placing them in his standard inventory.
- Updated `Camera/DialogCamera.j`, `Vendors/VendorDialogs.j`, and `UI/ShopUI.j`
  - Slowed preset transitions to 4.5 seconds, expanded shot intervals to 16-26 seconds, constrained the built-in dialogue presets to 820-900 distance with moderated Z offsets, and extended path checks to blocking structures.
  - Added a ShopUI return callback that preserves the active camera and cinematic interaction while returning from trade to vendor choices.
  - Moved final vendor farewell playback outside cinematic mode.
  - Locked the native camera target to the active dialogue unit and restored the tracked hero target during the smooth camera reset.
- Updated `Vendors/VendorCatalogs.j` and `Vendors/VendorFactions/VendorDwarves.j` to replace obsolete `n05C`-`n05J` bindings with the documented Morgrim `h00T`-`h010` unit types.
- Updated `Vendors/VendorCatalogs.j`, `Vendors/VendorFactions/VendorDwarves.j`, and `Voicelines/Voicelines_VendorLines.j` to rename the three female-named Dwarves and replace the neutral Morgrim voice key with male-only `VendorDwarfMorgrimMale_0001-0015` registration.
- Updated `QuestsAndDialogs/DialogSystem.j`, `QuestsAndDialogs/QuestMaster.j`, `QuestsAndDialogs/QuestsGeneric.j`, `Reputation/Reputation.j`, and `Voicelines/Voicelines_Quests.j`
  - Centralized `[!]`, `[?]`, and in-progress quest-button formatting for vendor and authored quest givers.
  - Added immediate availability and overhead-marker refreshes for hero-level and reputation changes while retaining the periodic custom-condition fallback.
  - Added twelve reusable incomplete-objective lines and reserved `QuestGeneric_0001-0012` ExSound keys.
- Updated `QuestsAndDialogs/QuestMaster.j`, `QuestsAndDialogs/QuestsGeneric.j`, `QuestsAndDialogs/QuestsVendor.j`, and `Vendors/VendorDialogs.j`
  - Restricted vendor quest level checks to Player(0)-owned Nazgrek and Zulkis and selected the higher eligible hero level.
  - Applied each giver's registered faction as a Neutral-standing availability requirement when no quest-specific faction override exists.
  - Added an independent delayed vendor quest-giver scan and kept selection as an idempotent fallback rather than the quest creation event.
- Updated `QuestsAndDialogs/QuestMaster.j` to rebuild a giver's overhead quest marker only when `QuestData.setState` detects an actual state transition.
- Updated `Vendors/Help/infoVendors.md` and `Vendors/Help/VendorsHelper.md` with the Trade UI return lifecycle, quest refresh behavior, generic quest voice range, and current Morgrim rawcode contract.

### Actions Remaining

- Compile the full map and runtime-test Horde reputation from each Thornwoods Forest Troll type and Riverbane reputation from Bandits and the Bandit Lord.
- Compile the full map and runtime-test Aveline and representative autonomous and companion AI heroes through lethal damage, corpse selection, Spirit Shard revival, and automatic timer revival.
- Compile the full map and confirm Nazgrek starts with Healing Salve and Spring Water in his standard inventory while his starter equipment remains equipped.
- Compile the full map and test vendor camera movement, Trade UI return/outcome dialogue, Morgrim selection, reputation gating, and quest-marker refreshes after level and reputation changes.
- Import recordings for `QuestGeneric_0001-0012`; text-duration fallback remains active until those files exist.

## [9.8.2026]

### Player-Facing Updates

- Killing Murlocs and Forest Trolls now grants Horde reputation, Bandits grant Riverbane reputation, mana aberrations grant Elarindor reputation, and Player(4) Fel Orc kills share the existing Fel Orc reputation behavior.
- The Path of the Shaman logo now remains behind game mode and difficulty selection and disappears only when the selected run starts.
- Nazgrek's complete starter equipment, including Ancestral Charm in a trinket slot, now equips without overflowing the starting bag.
- Restored The True Horde's dedicated Reputation UI description while retaining the separate Morgrim Clan Dwarf faction.
- Vendor selection now uses a global catalog-aware selection listener, so every registered vendor family can open dialogue even when its unit missed the initial world scan.
- Vendor dialogue and active trade now rotate through five cinematic camera compositions, selecting alternate angles when destructibles obstruct the requested view.
- Companion Move and Attack commands now remain in control after reaching their destination and bypass normal companion and AI behaviors until another companion mode or command replaces them; Hold Position units continue to ignore both commands.
- Profession failure barks now require actual companion-group membership and proximity to a player hero; autonomous AI chatter uses a reduced 2000 range.
- Under-skilled AI gatherers now remember rejected nodes and move away instead of repeatedly trying to harvest them; autonomous wandering uses Move rather than Attack-Move so hostile resource nodes are not acquired incidentally.
- Aveline now uses the retained Fake Death flow while preserving her AI revive timer.
- Hired non-hero companions now remain as revivable Fake Death units for 60 seconds, appear dead in Stats UI, and receive a real death with normal cleanup and decay if no Spirit Shard revives them.
- Spirit Shards can now revive fatigued pets as well as other fallen party units, restoring the selected unit to exactly 50% health and 50% mana.
- Game mode and difficulty selection now render in front of the retained Path of the Shaman logo.
- Pressing ESC now closes the active MasterUI panel through a shared handler.

### Technical Updates

- Added hidden, unit-type-backed Murloc, Bandit, Forest Troll, and Mana Aberration reputation sources; they remain available to the Reputation UI by changing their faction visibility setting.
- Changed starter gear setup to equip each item immediately instead of staging all 13 equipment pieces in the 12-slot starting bag.
- Kept the completed preload image active through game mode selection and raised the selection panel above the retained logo frame.
- Made every vendor-family library an explicit VendorDialogs dependency and added visible setup feedback when a canonically named vendor lacks its catalog binding.
- Added reusable dialogue-camera presets, custom preset registration, randomized camera cycling, smooth shot changes, and multi-angle destructible path checks.
- Persisted manual companion-command state across completed Warcraft orders and blocked idle wandering, AI actions, follower corrections, and mode-driven orders while that state is active.
- Added profile-selectable AI Fake Death handling so Aveline can use retained death without regressing normal engine death for other AI heroes.
- Extended FallenHeroState and Spirit Shard targeting to hired non-hero companions, with timed conversion from retained Fake Death to permanent engine death.
- Integrated fatigued pets into Spirit Shard targeting and AI revival searches, canceling their pending automatic recovery and applying the requested health and mana percentages consistently to every revived unit.
- Updated `UI/ImagesUI.j` and `UI/GameMode.j` with a dedicated preload overlay layer that keeps selection controls above the logo image.
- Updated `UI/MasterUI.j` with a centralized Player 0 ESC trigger that closes MasterUI and every panel in its existing shared hide list.
- Updated `CreepRespawn/CreepRespawn.j`
  - Require an immutable saved spawn record before a unit can schedule a respawn; deaths of unregistered units no longer create records from their death positions.
  - Preserve original unit type, owner, position, and facing across every respawn generation.
  - Clear dead-unit spawn records after copying them to timer data, preventing recycled handle IDs from transferring records to unrelated units.
  - Exclude the six BloodSplat unit types, actual summoned instances, and generic timed-life units from respawn tracking.
  - Keep saved owners independent from later ownership changes, including Player(10) Dark Green units.
  - Restrict debug death messages to units that actually have a valid tracked spawn record.
  - Keep CreepRespawn debug mode local instead of enabling global UnitDeathEvent dispatch messages for every map death.

### Tool Updates

- Updated the DEquipment exporter to convert every ItemManager whole-percent value used by Warcraft fractional ability fields, including exactly 1%, and added the missing `Thorns %` mapping. Trinket classes continue to export both slot 17 and slot 18; a new corrected 9.8.2026 definition file was generated without modifying earlier exports.
- Restored WC3ItemManager's stable flow-based Icon Selector loading model and removed the shared native image list that caused slow reopenings and intermittent Windows-handle failures. Thumbnail and icon-file caches now persist for the active session, loading is cancellable and batched, and remembered folders, folder-scoped search, category filtering, and configurable icon paths remain available.
- Updated `WC3_Database/WC3ItemManager/IconSelectorDialog.cs` and `WC3_Database/WC3ItemManager/IconPathConfig.cs` to remember the Icon Selector window size, maximized state, and folder-grid splitter position. Large folders now open with an initial icon page and load the remaining unbounded results incrementally while scrolling.

### Actions Remaining

- Compile the full map and runtime-test representative Murloc, Bandit, Forest Troll, mana aberration, and Player(4) Fel Orc kills, including linked gains and hidden Reputation UI filtering.
- Compile and runtime-test Riverbane, Horde, and the remaining vendor-family selections, including missing-hero feedback, reputation-gated Trade, quest buttons, direct ShopUI entry, camera cycling, and obstructed market stalls.
- Compile and runtime-test point- and unit-target Move and Attack commands in every companion mode, including Hold Position exclusion.
- Runtime-test autonomous profession failure near hostile unit nodes, companion-only failure barks, 2000-range autonomous chatter, and Aveline's Fake Death revival cycle.
- Runtime-test hired non-hero Fake Death status in both Stats interfaces, Spirit Shard revival before expiry, and permanent death/decay after 60 seconds.
- Runtime-test manual and AI Spirit Shard revival of a fatigued pet, including exact 50% health/mana restoration and cancellation of the normal pet recovery timer.
- Compile the full map and runtime-test preplaced Player(10), Player(12), and Neutral Hostile respawns, including repeated generations and original position/facing preservation.

## [8.8.2026]

### Technical Updates

- Updated `Reputation/Reputation.j`
  - Restore `True Horde` faction (by mistake this was removed) and this time for player(13) - need to check that player(13) is not used for any "dummy"/"cinematic" actions
  - adjusted REP_KILL_DELTA values from -50 to -10

## [7.8.2026]

### Technical Updates

Issue with CreepRespawn not respawing creeps anymore for some reason:
- Updated `CreepRespawn/CreepRespawn.j` and `Events/UnitDeathEvent.j`
  - Keeps Bribe Table v6; native hashtables are NOT used for CreepRespawn storage.
  - Moves the primary Table.create() lifecycle into CreepRespawnTableState.onInit,
    matching the working struct-initializer pattern used by Reputation.j.
  - CreepRespawn's library Init no longer calls Table.create() or EnsureState().
  - Registers UnitDeathEvent/Events callbacks before any deferred runtime state work.
  - Adds tableInitStage diagnostics so a silent Table initialization interruption can
    be localized (20=rhash create, 30=respawnData, 40=ignoredUnits, 50=summonedUnits,
    100=all Table state ready).
  - Retries incomplete Table initialization once at game-time 0 in InitActions.
  - Runtime callbacks validate Table state before accessing it.
  - Keeps actual summoned-instance tracking instead of UNIT_TYPE_SUMMONED filtering.
  - Keeps direct callback dispatch; no TriggerRegisterVariableEvent is used for code
    subscribers.
  - Code callbacks are TriggerExecute'd directly.
  - RegisterTrigger callers retain condition evaluation before TriggerExecute.
  - Nested death context remains save/restored.
  1. Preserved Bribe Table v6. No native hashtable replacement.
  2. Removed runtime EXCLUDED_UNIT_TYPES array initialization from the Table initializer path.
  3. Replaced the fixed 7-entry exclusion array with equivalent direct unit-type comparisons in IsExcludedUnitType().
  4. CreepRespawnTableState.onInit now mirrors Reputation.j: it does only Table.create() calls and readiness bookkeeping.
  5. Table stage markers now directly identify Table allocation:
    20/21 = rhash before/after Table.create()
    30/31 = respawnData before/after Table.create()
    40/41 = ignoredUnits before/after Table.create()
    50/51 = summonedUnits before/after Table.create()
    100   = all Table state ready
  6. Added a separate game-time-0 repair function that creates only missing Tables; it never manually calls the struct onInit and does not overwrite successfully-created Table instances.
  7. UnitDeathEvent direct callback dispatch remains unchanged from the previous fixed version (no TriggerRegisterVariableEvent for code subscribers).

- Expected next test:
  - InitActions should report Table stage=100.
  - A unit death should show UnitDeathEvent dispatch followed by CreepRespawn OnUnitDeath ENTER and normal respawn scheduling.
  - If initialization still fails, the new stage value now points at a specific Table.create() call.


## [6.8.2026]

### Player-Facing Updates

- Continued attacks or kills against a temporarily hostile reputation faction now restart its hostility timer, preventing the faction from becoming peaceful while combat is still ongoing.
- Cooking recipes now display the crafted item's Object Editor icon consistently with the other professions.
- Opening any crafting station now closes the crafter owner's inventory and equipment panels.
- Raised the crafting camera and restored arrow-key pitch and rotation control while a player craft is in progress.
- Removed the duplicate crafting-start announcement; the crafted-item completion message remains.
- Vendor conversations and quests can now open regardless of faction standing; attempting to enter Trade still rejects insufficient reputation with an on-screen warning.
- Randomized-goods catalogs now retain their inventory between trade sessions and reroll on a configurable internal timer, initially set to fifteen minutes.
- Added eight Morgrim Clan Dwarf vendors covering blacksmithing, weapons, armor, mining supplies, and trade goods.
- Added four Horde Tauren vendors and daily kill or gathering quests for Boran Flintmane, Tawa Deepvein, Koro Windpack, and Nara Stormhoof.
- Added companion Move (`A0F6`) and Attack (`A0F7`) commands for unit or point targets; companions in Hold Position ignore both commands.
- Corrected AI hero revival, including Spirit Shards stored in DInventory, and made AI heroes use better stored equipment without downgrading their current slot.
- AI heroes can move stored potions, food, drinks, and other active-use consumables into their normal inventory when they need to use them.
- Player death item loss now follows difficulty: Story drops nothing, Normal drops equipped gear, and Hard drops equipped gear plus carried inventory items.
- Spirit Healers now use the preplaced graveyard units and open the shared fullscreen dialogue flow when restoring lost items.

### Technical Updates

- Temporal hostility refreshes its existing per-faction timer while preserving the original restoration state, without allocating duplicate timers or hostility records.
- Added player-specific inventory/equipment closing and an interactive suspended-camera mode used by profession crafting cinematics.
- Bound Orc, Satyr, Human, Goblin, Bonecrusher, Elarindor, Tauren, and Dwarf vendor rawcodes directly to their intended reputation factions instead of relying only on Object Editor ownership.
- Added Morgrim Clan as the separate `Player(7)` Dwarf reputation faction and retained The True Horde as its own faction.
- Added a reusable Blacksmith catalog, Morgrim Dwarf trade voice profile, Tauren quest dialogue pool, and ExSound ranges for both cultures.
- Updated the vendor roster with the intended regional distribution for Orc, Satyr, Human, Goblin, Bonecrusher, Tauren, and Dwarf vendors.
- Preserved AI companion revive-timer remaining time, including the unusual dead-without-an-active-timer state, across temporary cinematic revival.
- Added DInventory helpers for staging revive and consumable items, swapping a full-bag equipment upgrade, and dropping equipped or stored items without leaving stale equipment stats.
- Restored native AI hero death before retention so autonomous `ReviveHero` completion releases `Death` and `FallenHeroState` consistently.
- Kept difficulty-based death item loss while removing the `Difficulty -> Revival` library dependency that formed a JassHelper requirements cycle.
- Decoupled CinematicMover from AI through registered revive-state callbacks, removing the `AI -> Professions -> CinematicMover -> AI` requirements cycle.

- debug commands for reputation testing purposes (increase rep level so can eg test vendors):
/debug setfactionrep horde
/debug setfactionrep elarindor
/debug setfactionrep riverbane
/debug setfactionrep morgrim
/debug setfactionrep bonecrusher
/debug setfactionrep undead
/debug setfactionrep goblins
/debug setfactionrep satyr
/debug setfactionrep stormhaven
/debug setfactionrep gnolls

 - Add more starting items to Nazgrek and make him equip them

### Actions Remaining

- Create or update Object Editor vendor unit types `o01B-o01E` and `n05C-n05J` to match `VendorsHelper.md`, including Morgrim ownership on `Player(7)` where appropriate.
- Import recordings for `VendorDwarfMorgrimMale_0001-0015` and `VendorQuestTauren_0001-0014`; text-duration fallback remains active until those files exist.
- Compile the affected libraries in the full map and runtime-test hostile-reputation dialogue, trade rejection, timed randomized stock, daily reset, and the new vendor quests.
- Compile and runtime-test companion point/unit commands, AI death and Spirit Shard revival, full-bag equipment upgrades, cinematic timer restoration, difficulty item loss, and every preplaced graveyard healer dialogue.

## [5.8.2026]

### Player-Facing Updates

- Reworked delayed respawning for configured creep factions and respawn-managed NPCs to remove the remaining centralized-event and timer-dispatch failure points.

### Technical Updates

- Updated `Events/UnitDeathEvent.j`
  - Replaced manual `TriggerEvaluate`/`TriggerExecute` subscriber calls with separate Warcraft variable-event triggers while preserving cached dying and killing units, including nested and synthetic death dispatch.

- Updated `CreepRespawn/CreepRespawn.j`
  - Removed TimerUtils from respawn scheduling and keyed payloads directly to native respawn timers.
  - Corrected typed real-value cleanup for saved positions and respawn payloads.
  - Retained centralized `Events.j` unit-enter tracking, with death-position fallback when a unit was not previously tracked.
  - Added `CreepRespawn_SetDebugEnabled` for in-map tracing without editing the library constant.

### Known Issues

- The centralized death fan-out and full 120-320 second creep respawn cycle still require in-map runtime validation.

## [3.8.2026]

### Player-Facing Updates

- **Critical hero-death compatibility update:** Fallen player, AI, companion, and other hero bodies now remain technically alive at one life so Warcraft III cannot force the hero-dissipation animation. Updated party frames, cameras, AI, quests, professions, inventory, minimap, and nearby-world systems nevertheless treat these retained bodies as dead.
- Selecting a vendor now immediately explains insufficient faction reputation, while valid vendors no longer fail silently because of stale NPC casting or combat flags. Other blocked selection states also report their reason.
- Centered pooled vendor-type floating labels over their units instead of anchoring each label's left edge to the unit origin.
- Generic vendor commissions are now presented as Daily quests, Repeatable quests, or Quests instead of the misleading Vendor quest category.
- Added ten one-time vendor quests for Kargun Ashblade, Rukgar Longroad, Vaelith the Covetous, Garrick Holt, Silas Reed, Rixit Roadcoin, Nackle Quickdeal, Mugrok Ironclub, Aerendir Sunblade, and Maerith Silvercrest.
- All fifteen normal vendor quests now include an additional voiced giver line after acceptance and completion. Daily quests add one randomized objective- and culture-specific follow-up after the hero accepts.

### Technical Updates

- **Critical system contract:** Added `FallenHeroState_IsAlive`, `FallenHeroState_IsDead`, and `FallenHeroState_IsFallen` as the authoritative hero life-state checks. Because a retained corpse has approximately one life and is not natively dead, direct checks using `UnitAlive`, `IsUnitAliveBJ`, `UNIT_TYPE_DEAD`, or life greater than zero can return the wrong result. Migrated the identified active JASS consumers to the shared predicates. Revivable party heroes remain privately separated from one-minute unmanaged hero corpses in `Death.j`.
- Added `QuestsGeneric.j`, a Shop-independent template and dialogue layer for reusable kill, fetch, and talk quests, including faction rewards, daily variants, authored extensions, and interrupt-safe state commits.
- Replaced `VendorQuests.j` with the focused `QuestsVendor.j` adapter, retaining cross-vendor handoffs, purchase objectives, stock detection, lost-item replacement, and continuation into ShopUI.
- Consolidated shared quest dialogue and ExSound registration in `Voicelines_Quests.j`, migrated every vendor quest giver to the new API, and documented the revised import order and quest classifications.

### Tool Updates

- `WC3ItemManager`
  Reused loaded icon-selector thumbnails across dialog openings during the active application session and added an enabled-by-default Remember folder option that restores the previously browsed icon source and folder.
  Preserved the item grid's selected items and scroll position by item ID when database data is refreshed, while add/edit operations now retain the active filters and sorting.
  Normalized all 40 Food tooltips to show their configured Well Fed stat effects, normalized all 15 Drink tooltips to the shared beverage-consumption style, restored Bear Fat Biscuit's missing effect text, and assigned themed custom food and drink icons through an explicit one-time migration.

### Known Issues

- Legacy GUI triggers remain a high-risk compatibility area. The map contains thousands of triggers, and any trigger that determines hero death through normal Warcraft III alive/dead conditions, current life, or `UNIT_TYPE_DEAD` may incorrectly treat a retained corpse as alive. These failures can be intermittent and difficult to trace because the hero visually appears dead while the engine still considers the unit alive.
- Newly imported or re-enabled GUI/JASS systems must use `FallenHeroState_IsAlive`, `FallenHeroState_IsDead`, or `FallenHeroState_IsFallen` whenever their logic can receive a player, AI, companion, or other hero-type unit.

### Actions Remaining

- Continue auditing legacy GUI triggers and converted custom-script conditions for native hero alive/dead checks, prioritizing resurrection, camera, quest, cinematic, companion, AI, inventory, and periodic unit-group logic.
- Import recordings for the newly reserved vendor-quest ranges: Orc through `0043`, Satyr through `0027`, Human through `0037`, Goblin through `0035`, Bonecrusher through `0025`, and Elarindor through `0025`. Missing recordings continue to use text-duration fallback.

## [2.8.2026]

### Player-Facing Updates

- Lethal hero damage now leaves a visible frozen body without entering Warcraft III's dissipate state. Player, companion, and AI heroes remain available for revival, while other hero bodies are removed after one minute.
- Cooked food and beverages now use the shared Eat/Drink item ability, allowing their charge to be consumed while Cooking applies the correct Well Fed or Well Hydrated effect through JASS.
- Custom shop entries now use each item's WC3 Stock Maximum and Stock Replenish Interval by default, restoring one item per interval until the entry reaches maximum stock. Explicit `Shop_SetStockSupply` configuration still overrides the item defaults.
- Fixed vendor floating text exhausting Warcraft III's shared text-tag capacity, restoring reliable totem labels, dropped-item names, casting text, and damage numbers while retaining camera-visible vendor-type labels.
- Reputation faction entries now display a live standing badge over their faction emblem, using distinct Enemy through Exalted textures and a Hostile badge during temporary aggression.
- Added support for eight named Elarindor vendors covering weapons, armor, shields, enchanting supplies, reagents, potions, expedition supplies, and faction-quartermaster goods.
- Elarindor merchants now have faction-specific trade chatter and purchase, sale, exchange, and no-transaction responses with separate male and female voice sets.
- Aerendir Sunblade, Elowen Starweaver, Vaeriel Dawnflask, and Maerith Silvercrest now offer daily Elarindor quests with gold and faction-reputation rewards.
- Vendor quests now use cinematic NPC-and-hero dialogue sequences for acceptance, progress checks, and completion, committing quest events when the sequence finishes.
- Added support for six Horde Tauren vendors covering weapons, armor, shields, provisions, beast supplies, and quartermaster goods.
- Added female Human variants for all 24 Riverbane, Stormhaven, neutral, and travelling Human vendor roles.
- Every merchant voice profile and vendor role now has at least three randomized active-trade lines and three responses for each purchase, sale, mixed-trade, and no-transaction exit outcome.
- Cross-vendor supply quests now require an explicit quest dialogue choice at the target merchant instead of advancing when the merchant is merely selected. Some commissions continue directly into trade and require buying and returning the requested stock item.

### Technical Updates

- Split fallen-hero state tracking into the low-level `FallenHeroState` library, removing the `CameraControl -> Death` requirement cycle while retaining fake-corpse camera filtering.
- Documented the intended placement zone for every vendor in `VendorsHelper.md`, retaining explicit multi-zone and unspecified entries where no single location is defined.
- Updated `Death/Death.j`, `Events/UnitDeathEvent.j`, `AI/AI.j`, `Death/Revival.j`, `UI/CameraControl.j`, and `Arena/Arena.j` with one-life fake hero death, synthetic centralized death dispatch, fake-body revival support, fallen-aware camera/arena targeting, and 60-second cleanup for unmanaged heroes.
- Removed the redundant raw-meat and spring-water abilities from all 55 cooked outputs. Food/drink stats and recipe aura abilities remain owned exclusively by `ProfessionsCooking.j`.
- Updated `Shop.j` to read item object fields `isto` and `istr` while registering stock, and changed replenishment from full-stack-at-empty behavior to WC3-style incremental replenishment whenever current stock is below maximum.
- Reworked `VendorFloatingText.j` from one permanent text tag per discovered vendor to a bounded pool of eight reusable labels assigned to the nearest camera-visible vendors. Off-screen, hidden, dead, fogged, and cinematic vendors no longer reserve individual text tags.
- Published the seven reputation-tier texture constants and added `Reputation.getStatusIcon`, then connected `ReputationUI` row/detail badges to the shared tier mapping.
- Added `Vendors/VendorFactions/VendorElarindor.j` with catalog and voice-profile assignments for rawcodes `h00L`, `h00N` through `h00S`, and `n00M`.
- Registered all eight canonical Elarindor vendor names in `VendorCatalogs.j`, documented them in `VendorsHelper.md`, and reserved twelve external `ExSound` keys under `VendorElarindorMale` and `VendorElarindorFemale` voice folders.
- Added four Elarindor `qVendorName.j` libraries, eight `VendorQuestElarindor` voice keys, and configurable vendor-quest faction reputation rewards.
- Added interrupt-safe pending accept/complete events to `VendorQuests.j`; `VendorDialogs.j` now owns sequence completion and `DialogSystem.j` exposes non-completing sequence cancellation.
- Added `Vendors/VendorFactions/VendorTauren.j` for rawcodes `o015` through `o01A` and expanded `VendorHumans.j` with 24 female variants on `n04O` through `n05B`.
- Added gender metadata to the full vendor helper roster and reserved 18 male Human, 18 female Human, and 6 male Tauren merchant voice keys.
- Centralized all merchant and generic vendor-quest dialogue text, profile constants, ExSound keys, sequence ranges, and sound folders under `Voicelines_VendorLines.j` and `Voicelines_VendorQuests.j`.
- Aligned Female Human, Elarindor, and Horde Tauren catalog bindings, canonical names, and Elarindor quest targets with the final Object Editor rawcodes documented in `VendorsHelper.md`.
- Expanded centralized merchant line pools and ExSound ranges to 45 lines per Human gender/region set and 15 lines per Tauren or Elarindor gender set, while retaining vendor-role-specific dialogue fallbacks.
- Reworked `VendorQuests.j` target-vendor actions into interrupt-safe dialog handoffs or catalog purchases; `VendorDialogs.j` can now continue a purchase objective directly into the shop after its dialogue sequence.

### Tool Updates

- `WC3ItemManager`
  Updated the one-time Cooking seed data and live database so all cooked consumables export only `A0F5`, with inherited base abilities disabled and consistent manual-ability metadata. The historical seeder is excluded from the application build so normal ItemManager use cannot rerun it; the auditable SQL migration remains available for database setup.
  Exposed the existing `stock_max` and `stock_replenish` database fields as Stock Maximum and Stock Replenish Interval in the Add/Edit Item Basic Info tab. Increased the initial editor window size within the current screen's working area so all Basic Info fields are visible without manual resizing on sufficiently large displays.
  Added Food and Drink item classes with distinct tooltip colors, made them selectable in the consumable editor, and changed the main class filter to load every class from the database.

### Actions Remaining

- Rebase Object Editor abilities `A60V` (Raw Meat) and `A61F` (Spring Water) onto a Berserk-style no-target ability so their separate raw-consumable behavior can cast at full hit points or mana.
- Create or assign the eight matching Object Editor unit types and import recordings for the thirty reserved Elarindor vendor voice keys.
- Create or assign the six Horde Tauren and 24 female Human Object Editor unit types; ensure Tauren vendors are owned by Horde `Player(5)`.
- Import recordings for the eight Elarindor quest, 90 Human merchant, 30 Elarindor merchant, and 15 Tauren merchant voice keys; text-duration fallback remains active until then.

## [1.8.2026]

### Player-Facing Updates

- DInventory now has fixed sequential bag tiers from the 12-slot Starting Bag through the 80-slot Bottomless Bag, shows used/total bag space, and sizes partial pages to their occupied rows.
- Shops now show the selected hero's used/total bag space, set purchases to the advertised total capacity, and require Small, Medium, Large, Traveler's, Explorer's, Adventurer's, and Bottomless upgrades in order.
- Opening the Master UI now closes DInventory and DEquipment, and the unit Inspect/Close button has been moved upward to avoid the game UI intercepting clicks.
- Shop vendors now require Neutral reputation with their faction by default, while individual goods can require higher standings and remain hidden until unlocked.
- Limited vendor stock now shows its remaining supply, turns grey when sold out, and can replenish after a vendor-defined delay.
- Item charges are now shown on merchant, buyback, DInventory/DEquipment, and vanilla inventory item icons, and buyback items preserve their sold charge count.
- Shop inventory source labels now use `Inventory` and `Quick inventory` instead of `DInv` and `Bag`.
- Shop resource text now displays the `Gold` label in yellow and `Arena Marks` in red, with both resource values in white.
- Vendor cinematic transmissions now identify the unit by name or hero proper name followed by its vendor type, such as `Graknar (Bags)`.
- Vendors now speak randomized trade chatter every 60-120 seconds by default and react when a trade closes after purchases, sales, both, or no transaction.
- Blacksmith, general-goods, and bag merchants now have larger role-specific line pools, with reusable human, orc, satyr, Bonecrusher ogre, and regional goblin voice profiles available for future vendors.
- Added 26 ready-to-use merchant catalogs covering weapons, armor, shields, arena rewards, travelling trade, profession supplies, quartermasters, rare goods, provisions, potions, reagents, and other specialized stock.
- Travelling and specialty merchants can now change their stock and dialogue according to their current zone, while curiosity merchants reroll randomized goods whenever a new trade begins.
- Ninety-three new Orc, Satyr, Human, Goblin, and Bonecrusher Ogre vendor unit types now have assigned merchant roles and combine their racial or regional personality with role-specific trade dialogue.
- Vendors now display their merchant type as gold floating text while inside the local player's current camera view, with all active labels hidden during cinematics.
- Forty Orc, Satyr, Human, Goblin, and Bonecrusher vendor NPC types now offer generic kill, gathering, and cross-vendor supply quests alongside trading; thirty-five of these quests can be completed again after each new dawn.
- Camp fires now last five minutes instead of one minute.
- Crafting recipe details now include the crafted item's extended tooltip below the recipe description.
- Shields now grant their matching 50%, 75%, or 100% Shield Block ability while equipped and remove that equipment-granted ability when unequipped.
- The Inventory Inspect/Close button has been moved slightly farther upward.
- Well Fed and Well Hydrated recipe abilities no longer occupy visible unit command-card slots while their status buffs are active.
- Drunken vision now follows the active Nazgrek/Zulkis camera target instead of being removed when another unit is merely selected.
- Higher drunkenness now produces stronger irregular camera sway and increasingly frequent mishaps, including sudden stops, facing changes, and accidental casts from learned Shaman abilities.
- Cooking navigation now stays on the selected tier, Food/Beverages group, and recipe screen without reopening an earlier selection layer when a recipe is clicked.
- Opening a different profession workstation now clears the previous profession's selected recipe, preventing Alchemy or other recipe details from carrying into Cooking.
- Cooking category and recipe buttons no longer repeatedly rescan the full profession registry during every frame refresh, reducing the navigation lag spikes.
- Dead campfires and other destroyed profession stations can no longer start or complete crafting.
- All active pets now become fatigued and revive after lethal damage instead of ordinary tamed beasts dying permanently.
- Fallen player, companion, and AI heroes now remain at their death location without decaying or dissipating, and a Spirit Shard's three-second Revive cast can restore the nearest allied fallen hero within 250 range.
- Nazgrek and Zulkis now revive at the selected graveyard after 30 seconds, where a temporary Spirit Healer or Spirit Walker can recover items left at their death site.
- A fallen active player hero now receives the rotating death camera until revival; switching the camera to the other living player hero ends the death view immediately.
- Kicked pets now return to Shadowclaw's home and can be invited back later, automatically replacing the current pet. The roster holds two ordinary tamed pets in addition to Shadowclaw.
- Taming a third ordinary pet now opens a choice dialog that dismisses one of the two older pets while keeping the newly tamed pet active; dismissed pets leave their carried items at home.

### Technical Updates

- Updated `Leveling/Experience.j`
  - Removed obsolete synchronization with the deleted GUI `XP_ExpMultiplier` variable; XP multipliers continue to use the library's hashtable-backed API directly.

- Updated `DestroyerInventoryAndEquipmentSystem`, `Vendors/Shop.j`, `UI/ShopUI.j`, and `UI/MasterUI.j`
  - Decoupled the 12-slot starting capacity from the 24-slot page layout, added fixed per-inventory bag-tier storage, maximum-capacity clamping, capacity counters, partial-page sizing, combined inventory/equipment closing, and safer Inspect button placement.
  - Reworked bag vendor stock to target permanent total capacities and reject skipped, duplicate, or downgrade purchases before charging gold.
  - Completed the required PotS library header sections for the touched legacy inventory and MasterUI libraries.

- Updated `Vendors/Shop.j`
  - Added vendor-level and stock-entry reputation thresholds based on the vendor unit's registered faction.
  - Added synchronized unlimited/limited supply configuration and full-stock replenishment timers that begin when an entry sells out.
  - Added stock, inventory, and persistent buyback charge queries; purchases now preserve configured or sold charges.
  - AI purchases now obey vendor reputation, item reputation, and shared stock availability.

- Updated `UI/ShopUI.j`
  - Added charge overlays, grey sold-out icons, stock counts, sold-out action disabling, and visible-session refreshes for replenished stock.

- Updated vendor templates and dialogue
  - Added vendor-type labels for General Goods, Blacksmith, and Bags vendors.
  - Added Friendly/Covenant reputation stock and finite replenishing stock examples to the Blacksmith template.
  - Added a separate trade-line picker so registered vendor lines retain their lookup name while transmissions use the unit's proper display name and vendor type.
  - Added profile-based chatter and transaction-result categories, unit/unit-type voice-profile binding, per-vendor chatter enable and interval configuration, and standardized labels for weapon, armor, shield, arena, travelling, profession-supply, quartermaster, and randomized-goods vendors.
  - Added session purchase/sale counters and limited outcome lines to normal trade closure so interrupted trades do not play misleading commerce responses.
  - Added role-specific greeting, chatter, purchase, sale, exchange, and no-transaction lines for 26 vendor catalogs, plus public unit and unit-type registration helpers.

- Added `Vendors/VendorCatalogs.j` and updated `Vendors/Shop.j` and `Vendors/VendorLines.j`
  - Added zone-restricted stock with optional child-zone inheritance and zone-selected voice profiles based on vendor coordinates from `ZonesCore`.
  - Added configurable random-stock pools that reroll when trade opens, and supplied rotating equipment, consumable, and material examples.
  - Auto-bound explicit weaponsmith, armorsmith, arena master, shopkeeper, barkeeper, tome merchant, and beastmaster types, and assigned four existing generic vendor placeholders starter shield, fishing, alchemy, and mining roles in one configurable section.
  - Added canonical runtime names for all 93 vendor rawcodes and applied them to placed vendors automatically, removing the need to duplicate the roster in Object Editor names.

- Added racial vendor assignment libraries
  - Added `VendorOrcs.j`, `VendorSatyrs.j`, `VendorHumans.j`, `VendorGoblins.j`, and `VendorBonecrusherOgres.j` with explicit catalog and voice-profile assignments for all 93 newly created vendor rawcodes.
  - Vendor dialogue now mixes role lines with bound racial, regional, or zone profiles instead of allowing one profile layer to suppress the others.

- Added `Vendors/VendorFloatingText.j`
  - Added camera-local vendor-type labels using the Totems floating-text visibility pattern, including fog and cinematic checks, moving-vendor position updates, delayed discovery, and runtime vendor support.

- Added `Vendors/VendorQuests.j` and forty `qVendorName.j` quest-content libraries
  - Added contextual vendor quest buttons without replacing the vendor selection handler, including 22 gathering quests, 11 kill quests, and 7 cross-vendor supply pickups.
  - Added shared Orc, Satyr, Human, Goblin, and Bonecrusher vendor-quest voice-key families and registered all 80 planned lines through `ExSound`.
  - Added dawn resets for completed `daily` quests through `udg_DNE_DayNightEvent`, including quest-log cleanup and objective-progress resets for existing and new daily quests.
  - Renamed every vendor quest file and library identifier to the canonical `VendorCatalogs` NPC name and documented all 40 quest-enabled vendors in `VendorsHelper.md`.

- Updated `UI/CraftingUI.j` and `Leveling/CampFire.j`
  - Added output item extended tooltips to every profession's shared recipe details and increased constructed camp-fire/light timed life to five minutes.

- Updated `DestroyerInventoryAndEquipmentSystem` equipment generation
  - Shield Block is emitted from the database's Shield class instead of inferred from the shared OffHand slot, keeping off-hand weapons unaffected and reusing DEquipment's safe ability-level ownership tracking.
  - Common through Rare shields receive the 50% ability, Epic shields receive 75%, and Legendary shields receive 100%; manual definitions can select a tier explicitly.

- Added `Abilities/General/AbilityShieldBlock.j`
  - Converted the imported GUI Shield Block effect, five-second timed removal, and finish animation to a multi-instance JASS library for all three ability variants.

- Updated `Professions/ProfessionsCooking.j`
  - Recipe aura abilities are hidden immediately after being added to a unit, while expiration, replacement, and death cleanup continue to remove them normally.

- Updated `Professions/Drunk.j`
  - Replaced selection-owned drunk view state with polling of `CameraControl`'s active target.
  - Added synchronized level-scaled mishap scheduling and a restricted learned-ability miscast pool that excludes profession and UI Channel abilities.
  - Added deterministic irregular sway noise without consuming synchronized random values from local camera-only branches.

- Updated `UI/CraftingUI.j`
  - Replaced inferred category state with explicit root, subcategory, and recipe view modes.
  - Added a per-player navigation cache rebuilt only when the workstation or category path changes.
  - Reset selected recipe, query, and reopen state when opening a workstation, and reduced duplicate recipe readiness checks per row.

- Updated `Professions/Professions.j`
  - Workstation range/start/preparation/completion checks now require the station unit to be alive.

- Updated `Companions/Pet.j` and `Companions/Companions.j`
  - Added the retained pet roster, shared home-return behavior with per-pet fallback timers, automatic active-pet replacement, and over-limit dismissal dialog.
  - Applied fatigue and revival protection to every active pet and routed pet-owned Invite casts away from the generic companion invite handler.

- Added `Death/Death.j` and `Death/Revival.j`, and updated `AI/AI.j`
  - Added retained hero corpses, Revive item range/cast handling, and corpse-scoped AI reviver searches that only run while a managed hero is fallen.
  - Limited automatic item revival to companion-controlled AI helping the player party and AI heroes helping members of their current AI party.
  - Added atomic external AI revival so item casts cancel the original AI revive timer and restore AI state without a second delayed revival.
  - Replaced the player graveyard GUI flow while preserving the Nazgrek/Zulkis timers, death flags, graveyard selection, Spirit Healer group, and item-recovery globals used by existing systems.
  - Added configurable temporary `u605` Spirit Healers and `u607` Spirit Walkers, with Spirit Walkers used by default at the two totem graveyards.
  - Recreated the legacy Death Camera on retained hero corpses and integrated it with CameraControl target switching and revival cleanup.
  - Preserved the GUI `rect` handle type of the legacy Nazgrek and Zulkis death-area variables for item recovery compatibility.

- Updated `Events/UnitDeathEvent.j` and centralized death subscribers
  - Isolated every registered death callback behind its own trigger so a failing or operation-heavy subscriber cannot prevent later systems such as creep respawning from running.
  - Cached the dying and killing units during dispatch, added accessor APIs, and migrated active death handlers to use the preserved event context, including nested death handling.
  - Confirmed that the migrated `Events.j` unit-enter dispatcher registers CreepRespawn, UnitStats, Rage, and Energy handlers that replaced the old playable-map GUI trigger.

- Updated `qRagno.j`
  - Edited voicelines slightly and created new voice files

- Updated `ExSound.j`
  - Allow register for more orc grunt voice files

- Slight terraining of `Thornwoods` and `Sereneglade`

### Tool Updates

- Updated `WC3_Database/WC3ItemManager`
  - Replaced the Icon Selector's control-per-icon and paginated result grid with a lightweight ListView so all matching textures remain browsable without exhausting Windows handles.
  - Fixed the LargeIcon viewport lookup that caused an unhandled `Cannot get the top item in LargeIcon` exception immediately after opening Browse Icons, and guarded deferred thumbnail loading from closing the application on future loader errors.
  - Added a 300 ms search debounce and scoped search to the selected folder tree. The new `All configured icons` root can search both Blizzard and custom icons when a global search is needed.
  - Load only visible icon thumbnails while browsing and retain up to 5000 compact thumbnails in memory, avoiding full-folder texture decoding on every search or folder visit.
  - Added virtual Abilities, Items, Units, Buildings, UI, Effects, and Other filters without changing the source texture folders.
  - Cached the global icon index so reopening the selector avoids repeated filesystem scanning, reduced initial indexing to one recursive directory pass per configured source, and now build the folder tree directly from that index instead of scanning the folders again.
  - Prevent unit-level dropdown initialization from overwriting the saved WC3 Level while opening an item. WC3 Levels changed through single-item or batch editing now remain visible when the item is reopened.
  - Updated the DEquipment CLI exporter to assign 50%, 75%, or 100% Shield Block to current and future Shield-class items according to rarity.

### Known Issues

- Cooking food and drink still use the heal/mana-based `A60V` and `A61F` object abilities. Their required Berserk-based no-target ability rebase must be made in the map's `war3map.w3a`, which is not present in this repository, before they can self-cast at full health or mana.

## [31.7.2026]

### Technical Updates

- Updated `UI/IconQuery.j`
  - Change quest icons to show on map always by default. This can be changed to other mode like "query" by the Player.

### Tool Updates

- Updated `WC3_Database/WC3ItemManager`
  - [MainForm.cs] and [ItemEditForm.cs]: removed automatic CookingItemsSeeder.Ensure(...) calls. The app no longer seeds/manipulates cooking item rows on startup or item edit form init.
  - [CookingItemsSeeder.cs]: if manually called later, it no longer overwrites existing item rows.
  - [ItemEditForm.cs]: MISC/Miscellaneous items no longer get forced into rarity item-level ranges.
  - [IconSelectorDialog.cs]: added folder file-list caching, raised memory image cache to 6000 icons, and load images as cloned bitmaps so revisiting large folders should be much faster.
  - [LootTableAutoFillDialog.cs] and [LootTierRepository.cs]: loot auto-fill and tier item counts now use COALESCE(item_level_unclassified, item_level), matching the generic loot exporter.
- Stormlink Girdle:
    - Live DB row for `j1c1` has max_charges=0, max_stack=0, no stock values, item_level=460, item_level_unclassified=15.
    - So (1) is not coming from the current ItemManager row.
    - In WC3 object data, (1) is usually item charges from iuse. The exporter maps max_charges -> iuse, and current data should export iuse=0. If the map still shows (1), it is likely stale object data in the map or another export/import path.
- Loot Level:
    - WC3 Level / Stack exports to WC3 object ilev and drives equipment slot ranges.
    - `Note`: Loot Level is separate drop-tier level. It is used by generic loot export and now also by loot auto-fill/count UI. It does not change the item’s equipment slot or WC3 object item level.

## [30.7.2026]

### Player-Facing Updates

- Shop category buttons now use smaller shared label text so longer categories such as `Consumables` and `Food and Drink` fit without resizing the buttons.
- Added Graknar as a bag-space merchant selling direct DInventory upgrades for +6, +12, and +20 slots, starting at 1000 gold for the +6 upgrade.
- AI heroes now start with a limited 16-slot DInventory allowance and cannot buy bag-space upgrades from vendors.
- Crafting UI recipe lists now use more of the available panel height, so Cooking tier recipe lists fit without unnecessary extra pages.
- Cooking tier subcategories now move directly from `Food` or `Beverages` into the actual recipe list instead of showing a duplicate-looking Food/Beverages category screen.
- Added the first arena system pass.
  - Arena masters can now open an arena dialog with Waves, Team Deathmatch, Capture the Flag, and Duel entries.
  - Waves mode supports Easy, Medium, and Hard difficulties, delayed wave starts, inter-wave recovery, final-wave boss spawns, random health/mana powerups, and Arena Mark rewards.
  - Team Deathmatch starts immediately against a generated opposing team and rewards Arena Marks on victory.
  - Capture the Flag and Duel are registered but currently fail cleanly with setup messages until their dedicated AI/opponent-selection passes are implemented.

### Technical Updates

- Updated `UI/CraftingUI.j`
  - Increased the shared crafting recipe list from `8` to `12` visible rows and changed list navigation to page-aligned starts instead of overlapping one-row-shifted pages.
  - Added explicit recipe-path state for category/subcategory selection, so choosing a subcategory cannot keep the UI in subcategory mode.
  - Added valid Food/Beverage category icons, widened long path/detail text frames, tightened row text/icon spacing for the denser list, and clear hidden row text to avoid stale duplicate-looking entries.

- Updated `UI/ShopUI.j`
  - Category buttons now render their label through a disabled child text frame using one shared scale value for every category.

- Updated `Shop.j`
  - Added non-item stock service support for direct DInventory bag-slot purchases through `Shop_AddBagSlotService`.
  - Bag services apply `DInvAddSlotsForHeroVendor` directly and only charge gold after the slot expansion succeeds.
  - Bag services are restricted to user-owned buyers, keeping AI shop buying item-only.

- Added `Vendors/VendorBags.j`
  - Registered Graknar (`o61S`) as the first bag vendor, with synchronized slot-based pricing rounded to 500 gold steps.
  - Bag-space stock is player-only and no longer participates in AI shop buying weights or AI shop-route binding.

- Updated `AI/AI.j`
  - Registered computer-owned AI heroes normalize to a 16-slot DInventory allowance during AI setup without using vendor purchases.

- Updated `DestroyerInventoryAndEquipmentSystem/PoTs/SharedDInvLib.j`
  - Vendor bag expansion helpers now reject computer-owned units, preventing AI from buying extra bag space through ShopUI or legacy vendor calls.

- Updated `SoundAndMusic/ExSound.j`
  - Kept Sound Editor paths in the editor lookup only, so normal `ExSound_Play` dialog keys keep their external `Pots\\Sound\\Voicelines\\...` paths after `ExSoundEditorSounds` initializes.
  - Restored external-folder playback resolution for registered voice labels such as `Nazgrek_0001`, `Nazgrek_0057`, and `OrcGrunt_0017`.
  - Corrected `OrcGrunt_####` and `OrcPeon_####` external folder registration to use `Orc Grunt` and `Orc Peon`, matching the speaker-owned voiceline folder constants.
  - Normal ExSound key registration now clears/blocks generated Sound Editor associations for the same key, so voicelines never route through removed `gg_snd_*` imports.

- Updated `QuestsAndDialogs/QuestGivers/qRagno.j`
  - Renamed Ragno's Thork handoff quest title from `Giving the Letter` to `Call of the Horde`.
  - `Protect the Outpost` completion now prepares a hidden replacement Ragno if he died during the gnoll fight, rebinds quest-giver state to him, and reveals him after the completion cinematic fade-in before the letter dialogue starts.

- Updated `QuestsAndDialogs/QuestGivers/qChieftainThork.j`
  - Updated Thork's handoff completion to use the `Call of the Horde` title.
  - Moved the final `Zulkis_0003` / Nazgrek exchange out of Thork's completion cinematic: the quest now completes first, then a 3-second reserved delay plays the companion exchange.

- Updated `QuestsAndDialogs/DialogSystem.j` and `QuestsAndDialogs/DialogInteraction.j`
  - Added a shared dialog interaction reservation gate so scripted dialogue delays can temporarily block questgiver/vendor/trainer selection without editing each individual dialog library.

- Added `Arena/Arena.j`
  - Added the shared arena session core, arena/mode/difficulty ids, arena rect lookup APIs, participant tracking, arena-owned unit tracking, mode callback registration, Arena Mark rewards, and delayed cleanup back to the starting arena master.
  - Arena sessions suspend selected player hero XP, clear rested XP bonus state for participating player heroes, and restore the prior hero XP suspension state when the arena ends.
  - Arena-spawned units are routed through the centralized unit death event, excluded from normal item loot, removed on cleanup, and exposed to mode libraries through public query helpers.

- Added `Arena/ArenaModeWaves.j`
  - Implemented the initial Waves mode with 60-second first-wave and next-wave delays, themed creep-family wave composition, final-wave boss additions, periodic arena-unit attack orders, powerup spawning, wave rewards, completion rewards, and wave-clear participant recovery.

- Added `Arena/ArenaModeTeamDeathmatch.j`
  - Implemented the initial Team Deathmatch mode with immediate opponent-team generation, arena-unit AI orders, participant-scaling team size, master/faction-aware opponent families, and victory when all arena-owned enemies are defeated.

- Added `Arena/ArenaModeCTF.j` and `Arena/ArenaModeDuel.j`
  - Registered Capture the Flag and Duel mode ids so the arena master dialog/API can expose them, while keeping them blocked with explicit setup messages until their larger behavior systems are built.

- Added `Arena/ArenaModes.j`
  - Added selectable arena master registration for Horde (`N60L`), Satyr (`n62V`), Bonecrusher (`O61A`), and a Riverbane placeholder rawcode.
  - Added the arena master mode dialog and a lightweight party-selection step for selected hero, both heroes, selected hero party, or full party.
  - Bound Horde/Bonecrusher starts to Circle of Blood or Coliseum of Ages according to mode/difficulty, with Satyr/Riverbane using Coliseum of Ages.

- Updated `ItemLootSystems/ItemLootSystem.j`
  - Added per-unit loot exclusion registration so temporary arena-spawned units can suppress normal loot drops without globally excluding their shared unit rawcodes.

### Known Issues

- ExSound path resolution and the Protect the Outpost dead-Ragno completion flow still need in-map runtime validation.
- The new arena libraries still need full in-map/JassHelper validation after import order is finalized, especially arena rect globals, arena master registration, mode callback ordering, rawcode spawns, and the new per-unit loot exclusion API.
- Non-hero companion and pet revive/recreate handling is not complete for arena wave-clear recovery because `Companions`/`Pet` do not currently expose a safe public arena revive API.


## [29.7.2026]

### Player-Facing Updates

- Added the first PotS merchant shop system draft.
  - Vendors can now expose shop stock through a dedicated shop panel.
  - The shop panel has a shared `Merchant` / `You` mode button for switching between vendor goods and the player's sellable items.
  - The `You` view combines DInventory, DEquipment, and vanilla inventory items into one list.
  - Equipped DEquipment items are shown with an `Equipt` label and are blocked from normal selling until unequipped.
  - Merchant stock can now be filtered through category buttons such as `Shields`, with `All` as the default category.
  - Sold items now appear under each vendor's capped `Recent` category so players can buy back mistakes across later visits until the item is bought back or older entries are evicted.
  - Vendor trade entry now uses the same fullscreen fade/camera presentation as ability trainers and exits if the buyer or vendor is attacked, dies, or the shop UI is closed.
  - Shop item selection now uses a normal menu-click sound, while successful buying and selling use distinct gold sounds.
  - The shop panel now shows the player's current `Gold` and `Arena Marks` beneath the transaction message.
  - Quest/campaign items are now marked as unsellable in the shop and cannot be sold from DInventory, vanilla inventory, or AI sell paths.
  - Added starter General Goods and Blacksmith vendor templates with conservative early-game stock.

### Technical Updates

- Added `Shop.j` and `ShopUI.j`
  - `Shop.j` owns vendor registration, unit-type/unit lookup, stock entries, buy/sell transactions, sell values, item delivery into DInventory with vanilla inventory fallback, and a cached combined inventory view for UI rendering.
  - Added shop category query helpers, filtered stock lookups, and a persistent per-vendor buyback cache capped at 64 recent entries per vendor.
  - Renamed the buyback category display from `Recently Sold` to `Recent`.
  - `ShopUI.j` follows the existing PotS frame UI pattern with a left item list, right detail pane, item icons/tooltips, local-player frame updates, scroll handling, buy/sell action button, and transaction status text.
  - Added cached ShopUI resource text frames for current player gold and `PLAYER_STATE_RESOURCE_LUMBER` displayed as `Arena Marks`.
  - `ShopUI.j` now owns the active trade-session lifecycle, session buyback purchases, merchant category buttons, ESC close handling, and attack/death interruption cleanup.
  - Added `Interface_EVENT_SHOP_BUY` and `Interface_EVENT_SHOP_SELL` so shop transaction sounds can be configured separately from generic confirm/cancel UI feedback.
  - Credited Elprede's Hive Workshop `RpgMerchantShop` as shop-system inspiration while keeping the PotS implementation separate and integrated with local inventory/dialog systems.

- Added `Vendors/`
  - Added `VendorLines.j` for merchant display-name lookup and generic greet/trade/farewell line registration.
  - Added `VendorDialogs.j` for selectable merchant NPC dialogue using the existing `DialogInteraction` / `DialogSystem` flow.
  - Updated `VendorDialogs.j` to use ability-trainer-style dialog fade/camera/fullscreen setup and to close the dialog camera if the selected vendor or viewing hero is attacked or dies before the shop UI opens.
  - Added `GeneralGoodsVendor.j` and `BlacksmithVendor.j` as simple sublibrary templates for future shop vendors, including unit-type binding helpers and optional AI profile binding helpers.

- Updated `AI/AI.j`
  - Added optional `Shop` integration so AI shop buy/sell states use `Shop_AIBuySimple` and `Shop_AISellSimple` when the selected shop unit is a registered PotS vendor.
  - Kept legacy AI shop behavior as the fallback for non-PotS shop targets.
  - AI shop purchases use bounded item weights and price caps so AI can cheat simple shopping decisions without jumping to overly strong items.

- Updated `DestroyerInventoryAndEquipmentSystem/PoTs/DConfigurationArea.j` and `DestroyerInventoryAndEquipmentSystem/PoTs/SharedDInvLib.j`
  - Tightened DInventory stackability so `DInventoryIsItemStackable(...)` now treats WC3 item level `1-49` as the stack-cap range and treats level `0` and `50+` as non-stackable, regardless of Object Editor item category.
  - Updated the DInventory stacking configuration comments to document that WC3 item level, not item class/type, owns the stackability rule.

- Updated `UI/CraftingUI.j`
  - Crafting UI selected-recipe details now keep the same transparent right-pane layout used by Mining and Blacksmithing while still raising recipe row/detail text frame levels so recipe description, skill/time, and materials render consistently.

- Updated `Professions/ProfessionsCooking.j`
  - Simplified Cooking recipe browsing so each skill tier now contains only `Food` and `Beverages` subcategories instead of separate meat, seafood, stew, and oddity branches.
  - Replaced invalid generic Cooking drink/stew/fish recipe icon paths with stable command button icons to avoid green missing-texture squares in the crafting list and recipe detail pane.
  - Made Cooking's consumable buff split explicit: each unit can have one active food buff and one active drink buff, and applying a new consumable only removes/replaces the existing same-type stats and aura ability.
  - Added food-only, drink-only, and generic Cooking consumable lookup helpers for aura abilities and effect text.
  - Clarified that not every drink buff is intoxicating: non-alcohol drinks such as Honeyed Milk, Salted Makrura Broth, Sagefish Tonic, and Lobster Bisque Cup now keep their drink buff stats/aura without adding drunkenness.
  - Wired all 55 Cooking consumables to their recipe-specific `S000`-series Object Editor aura ability rawcodes, keeping per-unit buff text/icons stable while Cooking still enforces one active food buff and one active drink buff.
  - Documented that Warcraft runtime tooltip setters are object-code global, so collapsing Cooking to one shared food aura and one shared drink aura would not provide correct per-unit text when different units have different active food or drink effects.

- Updated `Debug/DebugObjectRegistry.j`
  - Added debug lookup entries for newer DEquipment-exported item rawcodes, including Fishing materials, creature drops, seeded profession gear, Cooking cooked foods/beverages, and new cooking materials.
  - Added or refreshed debug lookup entries for the Cooking food/drink buff aura ability rawcodes used by the one-food-buff and one-drink-buff consumable system.

- Updated `QuestsAndDialogs/QuestGivers/qRagno.j`
  - Restored the event-driven `Protect the Outpost` intro from the old `RagnoIntroRegion01` through `RagnoIntroRegion04` rects as a hidden Ragno quest that starts gnoll waves and self-completes into `Giving the Letter` when the spawned gnolls are dead.
  - Restored more of `Lumberjack Duties`: the helper peon now belongs to Player 2 Blue, scans nearby `LTlt` Pine Trees and custom `B61E` lumber trees, issues harvest orders, creates/removes the old lumber blocker/return helper objects, and uses the migrated Orc Peon voice barks for intro, chopping, and random chatter.
  - Added optional Zaekolaerr availability refresh calls so accepting, readying, or completing `Satyr Negotiations` updates the external satyr quest marker when `qZaekolaerr.j` is imported.
  - Removed qRagno's extra Nazgrek first-greet line so Ragno's first dialog no longer plays two player greeting lines.
  - Reworked Ragno's greeting to use only qRagno's custom Ragno lines instead of the generic hero-greet helper.
  - Moved the Lumberjack peon's accept-intro barks into the accept sequence so the cinematic does not exit before the peon finishes talking.
  - Tightened `Protect the Outpost` quest-log text so it does not mention Ragno before the player has met him.
  - Added short intro and post-fight Protect Outpost cinematics using the old GUI camera/unit globals, with the post-fight flow now completing `Protect the Outpost`, delaying, playing the Ragno/Nazgrek letter scene, delaying again, then accepting `Giving the Letter`.
  - Changed `Giving the Letter` to a single-objective delivery quest with no registered item-gather requirement; the Blood Signed Summon Letter is still given when the quest is accepted.
  - Enabled XP/reputation reward text for Ragno's quest descriptions, with minimal early-chain rewards for `Protect the Outpost` and `Giving the Letter`.

- Updated `QuestsAndDialogs/QuestMaster.j`
  - Cross-NPC turn-ins now remove the giver-side marker when the quest is ready and show the turn-in question mark only on the receiver; completed quests are removed from giver icon tables.

- Updated `QuestsAndDialogs/QuestGivers/qChieftainThork.j`
  - Adjusted `Giving the Letter` completion for the single-objective delivery shape: Thork still checks/removes the Blood Signed Summon Letter manually, then marks the one delivery objective complete.

- Updated `SoundAndMusic/ExSound.j`
  - Sound Editor registration now exposes generated handle/path lookup for label playback while normal registered dialog keys keep their external voiceline paths.
  - This fixes converted dialog lines such as `OrcGrunt_0085`, `OrcGrunt_0088`, `OrcGrunt_0089`, `OrcGrunt_0090`, and `OrcGrunt_0094` being registered but resolving to the wrong playback path.

- Added `QuestsAndDialogs/QuestGivers/qZaekolaerr.j`
  - Added Prince Zaekolaerr as the selectable satyr endpoint for Ragno's `Satyr Negotiations` quest.
  - Zaekolaerr now uses the `Satyr_####` voiceline constants, plays first-meet/greet/farewell lines through `DialogSystem`, exposes the three negotiation branch choices, updates Ragno's quest objective, and supports ESC closing through `DialogSystem_SetEscapeAction`.
  - Added a dummy ready-turn-in style quest marker on Zaekolaerr while `Satyr Negotiations` is active and waiting for the satyr conversation.
  - Split Zaekolaerr back into the old GUI two-dialog flow: first greet/farewell dialog, a `Satyr Negotiations (Continue Quest)` intro sequence, then a second dialog with arena/taunt/alliance choices.
  - Shows the second negotiation dialog directly after the intro sequence so it does not inject another generic greet line or reopen the first dialog state.

- Updated `CreepRespawn/CreepUnitAssignment.j`
  - Prince Zaekolaerr respawns now run quest-giver restoration and refresh the new `qZaekolaerr` dialog/icon hook after `udg_Zaekolaerr` is reassigned.

### Tool Updates

- Updated `WC3_Database/WC3ItemManager`
  - Corrected the documented item-level data model: any item class/type can be stackable when its WC3 item level is `1-49`, with that value acting as the stack cap; WC3 item level `0` and `50+` are intended non-stackable, and equipment continues to use higher WC3 item-level values.
  - Added clearer `Ignore Loot Tables` wording for the existing per-item loot exclusion flag, exposed it in the item list and batch editor, and kept it mapped to `specific_drop_only` so existing data remains compatible.
  - Generated loot export now skips `specific_drop_only` items in generic item pools, named destructible loot tables, unit-specific drops, and destructible-specific drops; loot-table autofill also skips those items so crafter gear and other manually controlled items are not pulled into loot accidentally.
  - Updated Cooking item seeding to use non-missing food, fish, stew, and beverage icon paths that match the simplified Cooking crafting UI recipe icons.

### Known Issues

- The new shop libraries still need full in-map/JassHelper validation after import order is finalized, especially the frame panel, vendor selection scan, DInventory/DEquipment sale paths, and AI shop behavior against real registered shop units.
- `qRagno.j` now references additional Outpost old-GUI globals such as `gg_rct_RagnoIntroRegion01` through `gg_rct_RagnoIntroRegion04`, the gnoll attack/spawn rects, `gg_cam_ProtectOutpost01` / `02` / `03` / `Skipped` / `Skipped02`, `gg_unit_ogru_1209`, `gg_unit_ogru_1210`, `gg_unit_ogru_1633`, and `gg_unit_orai_1221`; confirm these globals and the new quest-giver import order in the next full in-map JassHelper compile.
- `qZaekolaerr.j` still needs full in-map JassHelper compile/runtime validation with `VoicelinesSatyr`, `VoicelinesDemoness`, `DialogSystem`, and `qRagno` imported before it, plus confirmation of the old Zaekolaerr camera globals.
- The ExSound Sound Editor path override needs runtime validation with `SoundAndMusic/ExSoundEditorSounds.j` imported after `SoundAndMusic/ExSound.j`.
- `Satyr_0028` exists as a voiceline constant but was not present in the checked-in Sound Editor registry; Zaekolaerr's runtime dialog avoids that line until the import/path is verified.


## [28.7.2026]

### Technical Updates

- Updated `CastingBar/CastingBarSystem.j`
  - Reworked spell event handling so normal cast-time abilities start their casting bar from `EVENT_PLAYER_UNIT_SPELL_CAST` / `EVENT_PLAYER_UNIT_SPELL_CHANNEL` instead of waiting for the later channel path, fixing cases where a 5s cast could only flash briefly.
  - Split casting state into explicit pre-cast, pending channel, and confirmed channel phases.
  - Channel/follow-through bars now start from `EVENT_PLAYER_UNIT_SPELL_EFFECT` only after a short current-order confirmation, so ordinary buff/debuff duration fields are not automatically mistaken for true channeled casts.
  - Channel timing now prefers `ABILITY_RLF_FOLLOW_THROUGH_TIME` and falls back to hero/normal duration for abilities such as Life Drain.
  - Cleaned up all per-unit casting tables on interruption, endcast, completion, death, or invalid-unit cleanup to avoid stale handle-id state.
  - Added the standard PotS library header and clarified install/API notes.

- Updated `Professions/Professions.j`
  - Profession crafting now updates the temporary `A6DY` Craft fake-cast ability's `acas` casting time to match the selected recipe's actual craft duration before issuing the self-cast order.
  - This keeps the Warcraft ability cast phase and casting bar aligned with variable recipe craft times instead of always using the old fixed 5 second object-data value.
  - Raised the internal maximum registered profession recipe count from `256` to `512` so the expanded Cooking recipe table has room without crowding other profession libraries.

- Updated `Professions/ProfessionsCooking.j`
  - Replaced the placeholder Cooking hook with a full campfire recipe set for the existing Cooking skill `1-100` scale.
  - Registered `55` Camp Fire recipes across Apprentice, Journeyman, Expert, and Artisan tiers, including meat dishes, seafood, stews, beverages, and odd high-skill recipes.
  - Cooking recipes still require proximity to the Camp Fire unit `n61C`; library comments now note that future fire-source units should be added as additional station registrations.
  - Added Cooking-owned timed food and beverage stat effects instead of relying on Object Editor aura abilities for the first implementation.
  - Food and beverage buffs are separate timed slots: a new food replaces the old food buff, a new beverage replaces the old beverage stat buff, and both remove their stat deltas when they expire or the unit dies.
  - Added runtime stat support for Strength, Agility, Intelligence, max hit points, max mana, hit point regeneration, mana regeneration, damage, armor, movement speed, sight range, Crit, Dodge, Block, Hit, flat Spell Power, and percent Spell Power.
  - `udg_Stats_Crit`, `udg_Stats_Dodge`, `udg_Stats_Block`, `udg_Stats_Hit`, `udg_Stats_SpellPowerFlat`, and `udg_Stats_SpellPowerPct` are updated directly for timed Cooking effects.
  - Added a delayed reapply path after hero item drops so `UnitStats_RecalculateHero(...)` item-stat clears do not permanently wipe active Cooking timed stats.
  - Added a `PC_RegisterAuraRawcodes` section where each recipe can define one Object Editor aura rawcode; Cooking now adds/removes mapped aura abilities together with the timed stat effect and clears them through `UnitDeathEvent`.

- Added `Professions/Drunk.j`
  - Added a helper library for beverage drunkenness.
  - `Drunk_Add(...)` stacks a unit's drunk level, attaches a Drunken Haze target visual, expires through `TimerUtils`, and clears visual/player state when the drunk timer ends.
  - Player drunk fade and camera sway are local to the player currently selecting an owned drunk unit.
  - Switching selection away from a drunk unit, such as from drunk Nazgrek to non-drunk Zul'kis, clears the local drunk filter and camera roll until a drunk owned unit is selected again.
  - Camera sway uses `CAMERA_FIELD_ROLL` instead of rotation to avoid the known camera-rotation crash path.

- Updated `GatherSystems/GatherNodeSkills.j`
  - Kept the shared profession skill cap at `100`; Cooking recipe requirements now fit the existing 1-100 profession progression.

- Updated `CreepRespawn/CreepRespawn.j`
  - Added defensive state initialization so respawn tables, ignored-unit tracking, the exclusion list, and the bootstrap group exist before `Events_RegisterUnitEnter` or `UnitDeathEvent_Register` callbacks can touch them.
  - Replaced the delayed startup trigger and hard-coded timer event-id check with a one-shot `TimerUtils` timer that saves initial creep positions once.
  - Kept CreepRespawn on the centralized `Events.j` unit-enter dispatcher and `UnitDeathEvent.j` death dispatcher; both APIs preserve native event responses for direct code callbacks.
  - Added Player 23 / Emerald to the initial respawn-position enumeration, matching the existing Emerald-to-Neutral-Passive respawn-owner mapping.
  - Added a saved-position existence check and death-time fallback save so valid creeps that missed startup or enter tracking still respawn from their current death position instead of failing with blank respawn data.

- Added `QuestsAndDialogs/QuestItemSpawner.j`
  - Added a reusable quest/event helper for temporary item sets that can spawn items at registered rects, points, or locations.
  - Spawning chooses a random configured spawn point per item and respects each spawner's configured maximum active item count before creating more items.
  - Added tracked cleanup helpers for despawning all spawned items, despawning random tracked items, and rotating random items by despawning and respawning replacements.

- Updated `QuestsAndDialogs/QuestGivers/qValeria.j`
  - Aligned `Token of Love` and `Lost Supplies` quest metadata formatting with the current `qAradion.j` quest-log style, using the shared `Quest giver:` and `Recommended level:` text layout.
  - Fixed `Token of Love` item creation so `Heart of the Ocean` is created at `gg_rct_ItemTokenLove` instead of at the interacting hero / Nazgrek position.
  - Moved Valeria's temporary quest item spawning to `QuestItemSpawner`.
  - `Lost Supplies` now creates `ITEM_SUPPLIES` through a max-8 spawner using `gg_rct_ItemSupplies01` through `gg_rct_ItemSupplies07`.
  - Added Valeria-owned availability gates so `Token of Love` waits for `Ranger Missing` completion and `Lost Supplies` waits for `Token of Love` completion, even when game-mode quest prerequisite checks are disabled.
  - Hid the `Lost Supplies` accept/complete dialog buttons until `Token of Love` has actually been completed.
  - Restored player-control locking on Valeria's farewell button by starting a dialog sequence before playing the farewell lines.

- Added `QuestsAndDialogs/QuestGivers/qRagno.j` and `QuestsAndDialogs/QuestGivers/qChieftainThork.j`
  - Converted Ragno's old GUI quest giver flow to the shared `QuestGiver`, `QuestMaster`, `DialogInteraction`, and `DialogSystem` stack.
  - Added Ragno's repeatable `Gnoll Headcount`, `Lumberjack Duties`, and `Kobold Thieves` quests with item turn-ins, lumber peon support, Kobold leader kill tracking, and random Kobold stash drops.
  - Added `Satyr Negotiations` with public update/ready/complete hooks for the external satyr branch.
  - Added Ragno-owned `Giving the Letter` as the renamed Thork handoff quest, with Chieftain Thork as the quest receiver so the ready turn-in marker appears on Thork.
  - Added Chieftain Thork dialog completion for `Giving the Letter`, including Blood Signed Summon Letter removal, Zul'kis rescue/ownership setup, DInventory/DEquipment initialization, starter item grants, and `Duty For The Horde` unlock helpers.
  - Normalized new Thork dialog text to `Chieftain Thork` / `Thork` instead of the old title naming.

- Updated `CreepRespawn/CreepUnitAssignment.j`
  - Ragno and Chieftain Thork respawns now run quest-giver restoration and refresh the new `qRagno` / `qChieftainThork` dialog hooks after unit references are transferred.

- Updated `Companions/Companions.j` and `AI/AI.j`
  - Companion order and idle timers now pause while a dialog sequence, visible dialog, field-line queue, cinematic, or companion dialog is active.
  - Companion-controlled AI profile thinking now uses the same dialog-blocking guard instead of only checking `udg_InCinematic`, preventing companions from issuing movement, pickup, gather, or AI orders during normal dialog windows.

- Updated `AI/AI.j`
  - AI gather-node selection now uses effective profession skill when checking whether a hero can gather from a node.
  - AI heroes now permanently ignore a specific gather node while their profile lacks the required profession or effective skill, preventing repeated gather attempts against nodes they cannot use.
  - Ignored gather nodes become valid again automatically if the AI later gains the required profession and reaches the node's required skill level.

- Updated `Professions/Professions.j`, `Professions/ProfessionsBlacksmithing.j`, and `UI/CraftingUI.j`
  - Profession recipe icons now fall back to the output item's object-data icon when a recipe does not define an explicit icon, so crafting buttons can show the actual item being created.
  - Added required-tool support to profession recipes and applied it to blacksmithing recipes with `Blacksmith's Hammer` rawcode `I700`.
  - Crafting UI now shows missing required tools in recipe rows and recipe details.
  - Added a `Query` craft button that keeps crafting the selected recipe until the required tool or materials are no longer available, then reopens the same crafting view.
  - Query crafting now continues repeated crafts inside the same active crafting camera/fade sequence instead of flashing back to the normal view between each item.
  - Pressing ESC now stops an active crafting query, and starting a query displays a reminder that ESC cancels it.

- Updated `Companions/Companions.j`
  - Companion command abilities that target the ground now also include temporary controlled companions in `ControlledDisplayGroup`, so summoned/temporary companions follow group command mode and focus orders without needing to be manually selected.

- Updated `Abilities/Shaman/ShamanSummonElemental.j`
  - Added simple periodic spell-use AI for Shaman summoned elementals.
  - Elementals now look for nearby hostile ground targets and cast their own abilities when ready, while respecting passive mode, cinematics, current casting state, cooldowns, and mana.
  - Air elementals can use Lightning Shield, Chain Lightning, and Purge; Water elementals can use Crushing Wave and Frost Nova; Fire elementals can use Flame Strike and Firebolt; Earth elementals can use Taunt, Thunder Clap, and Hurl Boulder.
  - Rank 5 Summon Elemental now creates Greater elementals by prefixing the summoned unit name with `Greater ` and applying stronger summoner Intelligence scaling to elemental life and damage.
  - Greater Fire and Water Elementals gain `+25%` Spell Power and `+10%` Crit; Greater Earth Elementals gain `+25%` Block and `+10%` Hit; Greater Air Elementals gain `+20%` Dodge, `+10%` Crit, and `+15%` Spell Power.
  - Rank 5 Summon Elemental now refreshes the four elemental summon channel ability titles to `Summon Air Elemental - Level 2`, `Summon Water Elemental - Level 2`, `Summon Fire Elemental - Level 2`, and `Summon Earth Elemental - Level 2`.
  - `Abilities/Shaman/ShamanFeralSpirits.j` was intentionally left without spell AI because Feral Spirit summons currently do not have their own abilities.

- Updated Shaman and profession sound playback helpers
  - `SoundAndMusic/ExSound.j` now owns shared 2D/3D sound playback for reusable `sound` handles, Sound Editor labels, generated `gg_snd_*` label strings, and explicit import paths.
  - Added central `ExSound_PlayHandle*`, `ExSound_PlayLabel*`, `ExSound_PlayPath*`, `ExSound_PlayLabelOrPath*`, and handle-label-path helper APIs for normal, point, and unit playback.
  - Label playback accepts both Sound Editor labels such as `"Smelting"` and generated-name strings such as `"gg_snd_Smelting"` by stripping the `gg_snd_` prefix before `CreateSoundFromLabel(...)`.
  - Added `ExSound_RegisterEditorSound(...)`, `ExSound_RegisterEditorSoundEx(...)`, `ExSound_GetEditorSound(...)`, `ExSound_GetEditorSoundPath(...)`, and `ExSound_ClearEditorSound(...)` so string-based Sound Editor labels can resolve to reusable handles and exported filepaths.
  - Added generated `SoundAndMusic/ExSoundEditorSounds.j` and `SoundAndMusic/SoundEditorSounds.json` from `temp/war3map.w3s`, registering each `gg_snd_*` Sound Editor entry once with its actual filepath.
  - Label/path 3D playback now uses min distance `600.00` and distance cutoff `1500.00` by default; registered voiceline keys keep legacy non-spatial playback for imported-audio compatibility.
  - Reusable `gg_snd_*` handles are stopped/restarted but not destroyed; registered editor handles are marked so loop cleanup does not kill them, and `KillSoundWhenDone(...)` is only used for fresh transient handles created by label/path playback.
  - Spatial Sound Editor label playback now creates fresh 3D handles from registered filepaths so simultaneous casts do not interrupt a shared `gg_snd_*` handle.
  - `Abilities/Shaman/ShamanCommon.j` now delegates its sound wrappers to `ExSound` instead of owning duplicated deferred-start, create, attach, and cleanup logic.
  - `Abilities/Shaman/ShamanCommon.j` now initializes the generated Sound Editor registry and uses label-only calls for Stormstrike, Whirlwind, Lightning Strike, Ghost Wolf morph/return, and Ghost Wolf Bite.
  - `UI/Interface.j` now initializes the generated Sound Editor registry, resolves profession filepath defaults from it, and prefers label-created fresh 3D sounds before shared handles for unit-attached profession, mining-hit, and herb-pick playback.
  - Removed the `GetSoundDuration(professionSound) > 0` gate from profession-created sounds so valid newly created Sound Editor/import sounds are not discarded before playback.
  - Mining hit and herb-pick world event sounds now prefer generated Sound Editor labels at the relevant unit location, with configured `gg_snd_*` handles kept as fallback.
  - `Professions/Professions.j` now prefers configured profession labels for craft start/loop/finish sounds and only falls back to handles/paths when label playback is unavailable.
  - Profession craft sounds now attach to the workstation when a station unit is available, matching the old GUI playback shape for Cauldron, Forge, Anvil, and Tannery sounds.
  - `Professions/Professions.j` and `Professions/ProfessionsFishing.j` now pass the shared `1500.00` cutoff used by `ExSound` 3D playback.
  - `Abilities/Abilities.j` and `Abilities/Talents.j` now route local-player feedback sound playback through `ExSound_PlayHandleForPlayer(...)`.
  - This keeps registered external voiceline playback unchanged while making generated Sound Editor labels the reliable first path for profession, gather, and converted shaman SFX.

- Updated Fishing profession sounds
  - Registered `Tradeskill_FishingStart` and `Tradeskill_FishingEnd` in `SoundAndMusic/ExSoundEditorSounds.j` / `SoundAndMusic/SoundEditorSounds.json` for `war3mapImported\\FX_Fishing_Cast_02.mp3` and `war3mapImported\\FishingBobber_ver2_1.mp3`.
  - `UI/Interface.j` now maps `Profession_Fishing_Start` to `gg_snd_Tradeskill_FishingStart`, `Profession_Fishing_End` to `gg_snd_Tradeskill_FishingEnd`, and new `Profession_Fishing_Fail` to the existing `gg_snd_Tradeskill_Fishing`.
  - `Professions/ProfessionsFishing.j` now plays the cast sound when fishing starts, plays the bite/end sound once when the bite window opens or when a valid reel happens first, and plays the fail sound when the fish gets away or no reward is caught.
  - Fish-got-away failures now suppress the generic UI error sound so the dedicated fishing fail sound owns that feedback.

- Updated `Debug/DebugCommands.j`
  - Added `/debug fishpool spawn` for fishing testing.
  - The command syncs the player's camera target, finds the current `ZonesCore` zone at that point, selects a random enabled GatherNodeUnits definition registered as a Fishing fish-pool node, and attempts to spawn it through `GNU_ForceSpawn(...)`.
  - Added aliases `/debug fish pool spawn` and `/debug fishing pool spawn`.
  - Debug feedback now reports successful fish-pool spawns with the selected definition name/rawcode and zone, or reports failure when no fish-pool definitions are registered, no zone is found, or the selected point fails water/terrain restrictions.

- Updated Fishing line and fish-pool placement support
  - `Professions/ProfessionsFishing.j` now defaults fishing-line fallback offsets to `0.00` so the line start is no longer pushed away from the configured `"hand,right"` attachment marker.
  - Enabled the fishing-line custom color by default and lowered the lightning alpha to make the `LEAS` fishing line appear slightly thinner/fainter with the imported lariat texture.
  - `GatherSystems/GatherNodeUnits.j` now accepts water-like terrain for fish pools instead of requiring unwalkable water, allowing fish pools to spawn in shallow walkable water.
  - `Zones/ZonesCore.j` now supports per-zone FishRects through `z.addFishRect(...)` and `ZonesCore_AddFishRect(...)`.
  - Random fish-pool spawning now prefers registered FishRects for the zone before falling back to the normal zone spawn rect, and FishRects override the fish-pool terrain restriction for manually approved water areas.

- Updated gather-node profession skill and SteamBreath handling
  - `GatherSystems/GatherNodeSkills.j` now keeps `TradeSkillLevelUpEffectModelPath` effects alive briefly through `SpeciFX_DestroyTimed(...)` instead of creating and destroying the attached effect on the same tick.
  - `GatherSystems/GatherNodeUnits.j` now strips any existing SteamBreath effect from unit gather nodes when they are registered or spawned.
  - `EnvironmentSystems/SteamBreath.j` now excludes active `GatherNodes` unit nodes from SteamBreath target enumeration, preventing fish pools and other gather-node units from receiving head-attached breath effects.

- Updated `Companions/Pet.j` and `UI/StatsUI.j`
  - Added `Pet_CanRename(...)` and `Pet_ShowRenamePrompt(...)` so UI code can reuse the existing pet rename rules instead of duplicating rename logic.
  - StatsUI now replaces the right-side `Professions` button with a `Rename` button when the selected stats target is an eligible pet.
  - Shadowclaw and already-renamed pets do not show the Rename button; clicking Rename hides StatsUI and prompts the existing `/pet rename <name>` chat command flow.

- Updated `DestroyerInventoryAndEquipmentSystem/PoTs/DConfigurationArea.j` and `DestroyerInventoryAndEquipmentSystem/PoTs/SharedDInvLib.j`
  - DEquipment/DInventory equipment tooltips now default to the vanilla-style authored item text: item name, custom gold row, and the Object Editor extended tooltip.
  - Disabled generated equipment tooltip detail blocks by default because ItemManager-authored item descriptions already contain slot, rarity, stat, and ability text.
  - Hardened custom tooltip generation so the internal granted-ability text fragment starts empty while the debug-only granted ability name listing remains disabled.
  - This prevents stale DEquipment definitions that still grant dummy/stat abilities from leaking lines such as `Item Attack Bonus 1`, `Item Damage Bonus 1`, or `Skin 1` into custom item tooltip frames once the updated library is imported.
  - Confirmed the current generated DEquipment export keeps Skinning Knife damage as a DEquipment `Damage` stat and only grants the real Skin ability `A0F3`; older generated exports that still grant `A07N`/`AIat` should not be used for the active map import.

- Critical update to AI hero inventory/equipment support
  - `AI/AI.j` now initializes DInventory and DEquipment for registered AI heroes on creation/registration.
  - AI consumable logic can now stage needed healing or mana consumables from DInventory into the vanilla inventory, stash unneeded vanilla items back into DInventory when space is needed, and then use the best available consumable based on current life/mana need.
  - `DestroyerInventoryAndEquipmentSystem/PoTs/DInventory.j` and `DestroyerInventoryAndEquipmentSystem/PoTs/DEquipment.j` now allow computer-player heroes to own DInventory/DEquipment data while keeping frame UI creation user-only.
  - Added inspect-mode open helpers for DInventory and DEquipment plus a new `Inspect` / `Close` button above the vanilla inventory.
  - The inspect button appears when selecting another player's initialized unit that has DInventory and/or DEquipment, opens that unit's custom inventory/equipment UI, and hides again after deselecting if inspect mode was not opened.
  - The normal inventory ability remains self-only because it is a self-targeted ability.
  - Added a DInventory `Give` button for transferring the selected DInventory item to the currently selected target unit, using target DInventory first and target vanilla inventory only when the target has no DInventory.
  - The DInventory `Give` button now refreshes when the target selection changes and is positioned below the DInventory slots so it appears reliably after selecting both an item and a target unit.
  - DInventory give transfer now reports `Target unit doesn't have inventory.` or `Target unit inventory is full.` when the selected target cannot receive the item.
  - Inspect mode is read-only for inventory/equipment slot clicks while still allowing UI viewing and DInventory paging.
  - The Inspect/Close button now resolves the selected inspect target again on click, preventing stale selection cache cases where the button only worked after switching selection away and back.
  - Vanilla inventory handling now rejects DEquipment items, keeping equippable gear in DInventory or DEquipment slots while still allowing consumables, materials, and miscellaneous non-equipment items in vanilla inventory.
  - Invalid vanilla-equipment moves and failed DEquipment equip checks now use the Nazgrek/Zulkis `ExSound` item-error voicelines when applicable.
  - Fixed a DEquipment initialization edge case where enabling equipment after creating DInventory could keep using a stale `eqid = 0`.
  - AI heroes now periodically evaluate DEquipment items stored in their DInventory and equip a higher-level valid item into a matching slot when possible.

### Tool Updates

- Updated `WC3_Database/WC3ItemManager`
  - Fixed the Edit Item form so opening an existing item no longer rewrites its stored WC3 item level during form load.
  - This fixes cases such as `Copper Ore`, where the item list correctly showed WC3 item level / stack cap `20`, but opening Edit Item could snap the field to an equipment-range value such as `700` before the item's final class/rarity state was fully loaded.
  - Renamed the raw item-level UI to `WC3 Level / Stack Cap` in the item editor and batch editor to make its current runtime meaning explicit.
  - Added and exposed `Loot Level` / `item_level_unclassified` beside the raw WC3 item level in the editor, item list, and column configuration.
  - Background: `DestroyerInventoryAndEquipmentSystem` still reads Warcraft III's object-editor item level through `GetItemLevel(...)` when deciding stack capacity. Because Warcraft III item charges are the visible count used by DInventory stacks, PotS has historically repurposed WC3 item level as the maximum stack/charge cap for stackable non-equipment instead of treating it as item power.
  - `item_level_unclassified` remains the separate loot/drop tier field for items whose raw WC3 item level is being used for stack behavior.
  - Populated the PotS ItemManager database with 64 additional item records: 32 junk/misc/food/material creature-drop items and 32 Cloth, Leather, Mail, and Plate armor pieces.
  - Added stat rows and matching WC3 ability-code grants for the new armor pieces, following the existing Copper Chain armor pattern while using `item_level_unclassified` as the drop-tier level.
  - Added rare armor descriptions/flavor text to selected higher-rarity pieces while keeping common/simple items concise.
  - Added the new items and existing OldGUI loot items into relevant generic and category loot tables, including dragon, undead, humanoid, and boss-oriented pools.
  - Added explicit `unit_specific_drops` for OldGUI-style creature categories and fitting imported units: wolves, bears, stags, boars, snakes, frogs, crawlers, murlocs, makrura, lizards, dragons/whelps, gnolls, and undead.
  - Added boss-oriented drops for old boss-trigger units such as Deathlord Fel'Dok, Margul, Mur'gal, Unknown Entity, Velaria, Colossus, Gollum, Sargoth, Mordrax, and Rol'jin, and marked those units for boss/both loot behavior where applicable.
  - Verified the inserted loot data has no duplicate unit/item or loot-table/item mappings.
  - Added `CookingItemsSeeder.cs` for deterministic startup seeding of Cooking item data.
  - The seeder upserts `65` Cooking-related items: `55` cooked food/beverage outputs and `10` new cooking materials such as Coarse Flour, Honey, Peppercorn, Baker's Yeast, Bitter Hops, Cactus Pulp, Sour Berries, Glowcap, Icecap Shavings, and Empty Bottle.
  - Cooking-seeded cooked food and beverage loot/tier levels now use the corrected 1-100 Cooking scale in `item_level_unclassified`, while raw WC3 item level stays reserved for stack-cap behavior.
  - Wired the Cooking item seeder into `MainForm` and `ItemEditForm` connection startup beside the existing profession stat seeder.
  - Cooking-seeded consumables use generic item abilities to trigger item-use events while `ProfessionsCooking.j` owns the actual timed stat and drunk effects.

### Known Issues

- `qValeria.j` now references `gg_rct_ItemTokenLove` and `gg_rct_ItemSupplies01` through `gg_rct_ItemSupplies07`; confirm these rects exist in the main map globals during the next in-map compile.
- `qRagno.j` now references Ragno/Kobold/Lumber old-GUI rect globals such as `gg_rct_KoboldsChest01` through `gg_rct_KoboldsChest08`, `gg_rct_LumberPeonSpawn`, and `gg_rct_LumberPeonMove`; confirm these rects and the new quest-giver import order in the next full in-map JassHelper compile.
- The Shaman/profession/ExSound changes passed targeted static checks and `git diff --check`, but still need full in-map JassHelper compile and runtime audio validation with `SoundAndMusic/ExSoundEditorSounds.j` included after `SoundAndMusic/ExSound.j`.
- The gather-node skill effect, SteamBreath exclusion, and StatsUI pet rename changes passed `git diff --check`, but still need full in-map JassHelper compile and runtime validation because this checkout does not expose a combined `war3map.j` build entry point.
- The expanded Cooking and new Drunk libraries passed focused rawcode/effect cross-checks, `git diff --check`, and `WC3ItemManager` build validation, but still need a full in-map JassHelper compile with `Professions/Drunk.j` imported before `Professions/ProfessionsCooking.j`.
- Drunk fade uses the cinematic filter layer, so it may visually compete with other cinematic-filter systems such as wounded screen feedback until runtime priority/ownership is tested.

### Actions Remaining

- Re-test `CastingBar/CastingBarSystem.j` in-game with normal cast-time spells and channel/follow-through spells, especially Firebolt-style casts, Rain of Fire, Blizzard, Life Drain, and Channel-based custom abilities.
- Re-test Valeria's `Token of Love` and `Lost Supplies` chain in-game: quest-log text, item spawn at `ItemTokenLove`, `ITEM_SUPPLIES` spawning across `ItemSupplies01` through `ItemSupplies07`, sequential availability, item turn-in cleanup, and farewell control lock.
- Re-test Ragno and Chieftain Thork in-game: repeatable quest reset, Kobold chest drops, Lumberjack peon survival/failure, `Giving the Letter` turn-in marker on Thork, Zul'kis unlock, and Ragno/Thork respawn hook refresh.
- Re-test Aradion/Valeria/Nazgrek dialog scenes with companions present to confirm companion movement stays paused during dialog and resumes correctly afterward.
- Import `Professions/Drunk.j` into the actual map build order before `Professions/ProfessionsCooking.j`.
- Re-export or run `WC3ItemManager` against the PotS database so the new Cooking materials, cooked foods, and beverages are present in the generated item object data.
- Runtime-test Cooking at a Camp Fire: material consumption, skill gating through `1-100`, repeated query crafting, crafted item creation, item-use event firing, food replacement, beverage replacement, expiration/death stat and aura removal, and drunk selection switching between Nazgrek/Zul'kis.


## [26.7.2026]

### Technical Updates

- Updated `UI/FullscreenUI.j`
  - Fullscreen enable and disable now also disable fog of war and black mask through `FogEnable(false)` and `FogMaskEnable(false)`.
  - Kept repeated fullscreen enable/disable calls enforcing the visibility state even when the fullscreen UI was already in the requested state.

- Updated cinematic fullscreen callers
  - Replaced direct `CinematicModeBJ(...)` usage with `FullscreenUI_SetEnabled(...)` in dialog interaction transition fallback paths, profession crafting cinematics, and trailer cinematic playback.
  - Dialog transition paths that already run the shared `Cinematic ON` / `Cinematic OFF` triggers now skip extra fullscreen calls because those triggers own fullscreen enable/disable.
  - Updated profession cinematic audio comments to refer to fullscreen craft sequences instead of the old cinematic mode behavior.

- Added `QuestsAndDialogs/DialogInteraction.j`
  - Split generic selectable-NPC dialog mechanics out of `QuestGiver.j` into a reusable interaction layer.
  - Centralized selectable NPC registration, selection handlers, hero/range/cooldown gating, selection failure reasons, greet playback wrappers, dialog reopen timers, and configured dialog camera entry/exit transitions.
  - Preserved immediate player-control locking during dialog fades without using `CinematicModeBJ` or hiding cinematic panels.
  - Uses `FullscreenUI_SetEnabled(...)` only for dialog paths that do not already run the shared `Cinematic ON` / `Cinematic OFF` GUI triggers.

- Updated `QuestsAndDialogs/QuestGiver.j`
  - Reduced `QuestGiver` back toward quest ownership: quest registration, quest state, requirements, rewards, quest buttons, companion quest helpers, and quest availability.
  - Replaced the old embedded selection/greet/dialog-camera implementation with compatibility wrappers that delegate to `DialogInteraction`.
  - Kept `QuestGiver_Register(...)` registering both quest availability through `QuestMaster` and dialog interaction through `DialogInteraction`, so older quest givers remain compatible.

- Updated `Abilities/AbilityTrainerDialogs.j`
  - Ability trainer dialogs now depend on `DialogInteraction` and no longer require `QuestGiver`.
  - Trainer selection, selection gates, trainer camera transition configuration, greet playback, cooldowns, and dialog sequence control now call the shared `DialogInteraction_*` API directly.
  - Keeps ability trainers as non-quest dialog NPCs while still allowing quest libraries to add trainer quest buttons separately.

- Updated `QuestsAndDialogs/QuestGivers/qAradion.j`
  - Migrated generic dialog interaction calls from `QuestGiver_*` to `DialogInteraction_*`.
  - Kept actual quest work on `QuestGiver_*`, including quest creation, requirements, accept/complete buttons, companion quest helpers, and availability refresh.
  - This makes qAradion follow the new modular split while preserving the quest behavior surface.

- Updated `QuestsAndDialogs/QuestGivers/tools/qxxx-generator.html`
  - Generated quest-giver libraries now require `DialogInteraction` for selection/camera/greet/farewell dialog mechanics.
  - Generated templates still use `QuestGiver` for quest data, quest state, quest rewards, quest buttons, and quest registration.

- Added `Debug/DebugObjectRegistry.j`
  - Generated item, unit, and ability lookup tables from the latest checked-in Path of the Shaman object exports.
  - Registered 946 item names, 468 unit names, and 1137 ability names/aliases for debug-command lookup.
  - Added public lookup helpers for resolving rawcodes by exact/partial display name and for listing matching lookup results.

- Added `Debug/DebugCommands.j`
  - Added centralized `/debug` chat command handling for map testing and future cheat-command support.
  - Added `/debug item create '<rawcode-or-name>'` to create any item by rawcode or lookup name.
  - Item creation gives the item to the player's selected unit when available, or creates it at the player's current camera target when no unit is selected.
  - Added `/debug item lookup '<rawcode-or-name>'` to fetch item rawcodes by name or inspect a known rawcode.
  - Added `/debug unit create '<rawcode-or-name>'` to spawn any unit at the player's current camera target.
  - Added `/debug unit lookup '<rawcode-or-name>'` to fetch unit rawcodes by name or inspect a known rawcode.
  - Added `/debug ability give '<rawcode-or-name>'` and `/debug ability add '<rawcode-or-name>'` to give abilities to the player's selected unit.
  - Added `/debug ability lookup '<rawcode-or-name>'` to fetch ability rawcodes by name or inspect a known rawcode.
  - Tracks selected units per player and syncs local camera target positions through `BlzSendSyncData` before running camera-based create commands.
  - Uses `Ascii` rawcode conversion so rawcode text and four-character string input work consistently with the imported map libraries.

- Updated `Abilities/Shaman/ShamanLightningShield.j`
  - Lightning Shield now tracks the actual object-editor buff after a short post-cast grace window.
  - If the Lightning Shield buff is dispelled or otherwise removed, the custom periodic damage instance and persistent shield visual are cleaned up immediately.
  - Natural duration expiry now also removes the Lightning Shield buff if it is still present.
  - Recasting still replaces the previous tracked instance without stripping the newly applied buff.
  - Verified that normal Ancestral Ward and Water Shield casts already use the shared `ShamanBoneArmor.j` buff-required cleanup path; Totemic Resurgence bonus Ancestral Ward remains buff-independent by design.

- Updated `Professions/ProfessionsFishing.j`
  - Fishing now creates a lightning-based fishing line when the cast begins, starting from a hidden marker attached to the fisher's configured `"hand,right"` attachment point and ending at a randomized bobber point near the selected fish pool.
  - Added configurable `ProfessionsFishing_FishingLineLightningType`, `ProfessionsFishing_FishingLineUseCustomColor`, and `ProfessionsFishing_LineHandAttachmentPoint`, defaulting to `LEAS`, disabled custom tinting, and `"hand,right"`.
  - Added configurable fishing-line fallback offsets `ProfessionsFishing_LineHandForwardOffset`, `ProfessionsFishing_LineHandRightOffset`, `ProfessionsFishing_LineHandHeight`, and `ProfessionsFishing_LineHandZOffset`; lowered the default fallback height from overhead-level `105.00` to `70.00`.
  - Changed the fishing line to use raw `LEAS` by default for compatibility with a `ReplaceableTextures\Weather\lariatCaught.blp` Aerial Shackles texture replacement, with fallback right-hand offset handling if the hidden marker reports the unit origin or map-center null coordinates instead of a hand position.
  - Added short endpoint/bobber wobble pulses on cast start, reel, bait use, cancellation, completion, interruption, and fish escape.
  - Added configurable `ProfessionsFishing_BobberModelPath` for the fishing bobber model.
  - Fishing bobbers now use configurable special-effect animation type/subanimation IDs for the intended `Cinematic Custom0 1` creation/end animation and `Stand 1` fishing animation.
  - Bobber cleanup now delays `DestroyEffect` briefly after the ending animation is triggered so the ending animation has time to show before the model's death/removal behavior runs.
  - Increased fishing pool interaction distance to 750 and moved the cast approach point farther from the pool so fishers do not stand almost on top of the node before casting.

- Updated `ItemLootSystems/ItemLootSystem.j` and `GatherSystems/GatherNodeUnits.j`
  - Gather-node unit rawcodes registered through `GNU_RegisterDefinition(...)` are now excluded from normal ItemLoot unit death drops.
  - This prevents fish pools, ore veins, and other unit-based gather nodes from rolling generic or specific ItemLoot tables when their rewards are already handled through GatherNodeUnits harvest rewards.

- Updated `GatherSystems/GatherNodeSkills.j`
  - Profession skill point gains now play a one-shot special effect on the unit when the stored profession skill value actually increases.
  - Added configurable `GatherNodeSkills_TradeSkillLevelUpEffectModelPath`, defaulting to `spells_tradeskilllevelup.mdx`.
  - The effect is shared by crafting, gathering, fishing, and skinning paths that award profession skill through `GNS_AwardGatherSkillForNode(...)`.

### Imports

-Imported following models from WoW (credits Blizzard Entertainment):
- Fishing profession related:
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_01.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_02.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_03.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_blue.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_eelsyellow.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_elementalfire.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_elementalwater.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_green.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_lava.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_red.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_fishschool_shipwreck.mdx
  - world_goober_g_fishingbobber.mdx
- Fishing line texture replacement:
  - `ReplaceableTextures\Weather\lariatCaught.blp` replaces the Aerial Shackles lightning texture used by `LEAS` so the fishing line renders as a thin line instead of the vanilla shackles/chain look.
- Profession skill levelup:
  - spells_tradeskilllevelup.mdx
- Alchemy profession related but more likely to be just aesthetics in various environments:
  - world_expansion01_doodads_generic_arakkoa_tradeskill_ak_alchemyset01.mdx (could fit The Crypt dungeon)
  - world_skillactivated_tradeskillenablers_tradeskill_alchemycauldron_blue.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_alchemycauldron_green.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_alchemycauldron_purple.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_alchemycauldron_red.mdx
  - world_skillactivated_tradeskillenablers_tradeskill_alchemycauldron_white.mdx

### Tool Updates

- Added `WC3_Database/SQL/seed_fishing_items_and_rewards.sql`
  - Seeded 78 fishing reward items into the PotS ItemManager database, using fish, trophy fish, fishing junk, elemental reagent, fel-tainted, lava, pearl, and shipwreck loot naming patterns.
  - Added 27 active self-use fish consumables using the Healing Salve-style health regeneration ability, with perishable charged stacks up to 10.
  - Added 10 non-stackable MainHand trophy/junk weapon catches with intentionally poor attack bonuses for funny fishing rewards.
  - Added 41 special fish-pool reward items for elemental fire/water pools, fel pools, lava pools, eel schools, and shipwreck pools.
  - Added gather-node unit definitions for fish pool rawcodes `'n02N'`, `'n02O'`, `'n02P'`, `'n02Q'`, `'n02R'`, `'n02S'`, `'n02T'`, `'n02U'`, `'n02V'`, `'n02W'`, and `'n02X'`.
  - Added 143 explicit fish-pool zone assignments filtered by pool tier, zone level range, and zone theme, replacing the old catch-all fish-pool placement.
  - Rebuilt fish-pool gather rewards into 1171 bounded drop rows, with zone-specific rewards capped per pool/zone/group so the exported JASS stays below `GNU_MAX_DROPS`.
  - Elemental Fire Pool rewards now focus on fire reagents, Fel Pool rewards on fel/shadow materials, Lava Pools on fiery catches, and Ship Wreck rewards on treasure with fish only as occasional secondary loot.
  - Marked the fish-pool unit types as `loot_mode='none'` with `0/0` ItemLoot drop counts so their rewards are owned by GatherNodeUnits.
  - Used existing ItemManager icon paths for fish, crab, gem, spell, chest, reagent, and weapon-style icons instead of adding new imported assets.

- Updated `WC3_Database/WC3ItemManager` gather-node unit reward support
  - Added `zone_id` and `zone_name` support to `gather_unit_node_drops` so ItemManager can store zone-specific unit-node reward rows.
  - Added zone display to the unit-node drop grid and preserved zone metadata when editing existing drop rows.
  - Updated `GatherNodeExporter` so zone-specific unit-node drops export as `GNU_RegisterZoneDrop(...)`, while generic fallback rows still export as `GNU_RegisterDrop(...)`.

### Known Issues

- The new debug command libraries passed local JassHelper script-only validation, but still need in-map validation with the active imported object data and multiplayer sync context.
- The new `DialogInteraction.j` split passed targeted static checks for stale `QuestGiver_*` generic dialog calls and panel-hide usage, but still needs a full in-map JassHelper compile and runtime test with ability trainers and qAradion.
- The seeded fishing item and fish-pool database rows passed local PostgreSQL verification, but the map still needs fresh ItemManager item object export/import and Gather Nodes JASS export/import before the new fish pools and rewards can be validated in-game.
- The fishing line/bobber visuals and gather-node ItemLoot exclusion passed `git diff --check`, but still need full map compile and in-game validation with the active bobber model import path.
- The profession skill-up effect passed `git diff --check`, but still needs full map compile and in-game validation with `spells_tradeskilllevelup.mdx` imported at the configured path.


## [25.7.2026]

### Player-Facing Updates

- Shaman abilities now use hero attributes more meaningfully:
  - Enhancement melee-focused abilities lean more on Strength and Agility.
  - Elemental and Restoration caster abilities lean more on Intelligence.
  - Frost Shock, Nature Shock, Lightning Strike, and Lightning Shield now gain Intelligence-based damage scaling.
  - Stormstrike, Whirlwind, Ghost Wolf Bite, Primal Force, Feral Spirits, and Bloodlust now include Strength/Agility or hybrid attribute scaling where appropriate.

- Summon Elemental and Feral Spirits summons now behave more like temporary controlled companions:
  - Summoned elementals and spirit wolves are included in the companion follow/idle update flow.
  - They appear in StatsLiteUI and StatsUI as tracked companion-style rows.
  - They still do not consume normal companion party slots.

- Ability trainer dialog camera timing now waits for the configured QuestGiver fade transition path instead of snapping immediately when the trainer is selected.

- Ability trainer interactions now provide voiced/text trainer feedback when:
  - The player successfully learns an ability.
  - The player resets abilities, specialization, or talents.
  - The player cannot learn or reset because of missing points, missing requirements, or invalid state.

- Added specialization requirements for higher shaman progression abilities:
  - Summon Elemental requires Stormcaller.
  - Ghost Wolf / Spirit Wolf requires Earthwarden and still keeps its initial Spirit Wolf quest-training lock.
  - Reincarnation requires Spiritmender.
  - Totem Master requires Totemist.

- Ghost Wolf now keeps Nazgrek/Zul'kis focused companions and pets following the active wolf form, then retargets them back to the normal hero form when shifting out.

- Ancestral Ward now uses the old Bone Armor-style orbiting segment visual setup more closely:
  - Restored three orbiting Faerie Dragon missile segments around the shielded unit.
  - Restored positioned hit flare behavior for absorbed damage.
  - Added safer target fallback for direct casts.

- Added the first Fishing profession gameplay flow:
  - Fish pools can be selected and fished by a tracked hero carrying a registered fishing pole.
  - Fish pools can spawn in non-walkable shallow or deep water.
  - All configured fishing poles can qualify for fishing, with stronger poles contributing their Fishing item-stat bonus.
  - Fishing now uses a compact WoW-style FishingUI cast bar with a random bite window and Reel button.
  - FishingUI was moved higher on screen so it no longer covers the bottom unit portrait/command UI.
  - FishingUI status text now sits under the fishing bar instead of overlapping the action buttons.
  - Missing the reel window fails the attempt with "Fish went away".
  - Moving too far away from the fish pool now interrupts fishing.
  - FishingUI bait selection now uses the strongest usable bait found in vanilla inventory or DInventory.
  - Baits with Fishing skill requirements cannot be applied until the fisher meets the requirement.
  - Fishing skill, fishing pole bonuses, and temporary bait bonuses can affect success against the selected pool's required fishing level.

- Added the first Skinning profession gameplay flow:
  - The Skinning Knife's Skin ability can now skin nearby dead beast corpses while the corpse still exists.
  - Skinning requires a Skinning Knife in normal inventory, DInventory, or equipped in DEquipment main hand.
  - Skinning takes 1.5 seconds and is interrupted by new orders, attacks, death, moving away, losing the knife, or corpse invalidation.
  - Successful skinning marks the corpse as skinned until respawn and creates the configured skin item at the corpse location.

- ItemManager-authored equipment should now equip in the configured DEquipment slots more reliably:
  - `Stave` items are treated as two-handed main-hand weapons.
  - Trinkets now have two visible DEquipment slots.
  - Rawcode casing mismatches such as Skinning Knife `'i66m'` / `'I66M'` are handled in the current DEquipment export.
  - DEquipment no longer double-applies ItemManager stat bonuses by also granting generated or legacy WC3 stat abilities.
  - DEquipment and DInventory custom tooltips no longer show internal stat/dummy ability object names above the normal item tooltip text.

- ItemManager-authored profession skill stats now contribute to the matching profession values shown and checked in-game.

### Technical Updates

- Added `UI/FullscreenUI.j`
  - Created simple library to modify the UI to true fullscreen mode when called.

- Added `Preload/Start.j`
  - Converted the old `Game Start` GUI trigger into a simple JASS startup library called by `Preloader.j` after preload completes.
  - Split player startup into clear phases for initial game state/zone disabling, delayed Nazgrek creation and starter setup, then intro cinematic/world-system initialization.
  - Recreated Nazgrek's starting inventory, equipment setup, starter abilities, starter items, Player 1 gold, weather start, terrain-damage initialization, and bridge ignored-unit registration in JASS.

- Updated `Preload/Preloader.j`
  - Uses now the newly created FullscreenUI to hide UI elements during preload.
  - Increased preload title display duration and phase pauses to 5 seconds so startup and phase screens remain readable instead of flashing past.
  - Moved post-preload player startup ownership away from the old `gg_trg_Game_Start` GUI trigger and into the JASS startup flow.
  - Kept the final preload completion image phase but hides the "Preload Successful" title text before the Game Mode UI opens.
  - Starts `ExMusic` track 35 during the final preload completion image phase.

- Added `UI/GameMode.j`
  - Added a pre-start Game Mode UI that appears after preload and before `Start_Start()`.
  - Added Story, Free Roam, and Developer mode configuration flags for story flow, intro cinematic usage, quest requirements, ability requirements, AP costs, quest reveal style, and starting gold bonus.
  - Shows Difficulty selection after game mode selection and applies it through `Difficulty_SetDifficulty()` before starting the player setup flow.
  - Re-enables player control while the mode/difficulty selection UI is open, then locks control again when `Start_Start()` begins.
  - Developer mode can be hidden for release builds with `GM_SHOW_DEVELOPER_MODE`.

- Updated `Preload/Preloader.j` and `Preload/Start.j`
  - `Preloader.j` now shows `GameMode_Show()` after preload instead of calling `Start_Start()` directly.
  - `Start.j` now exposes `Start_SetRunIntroCinematic()` and `Start_SetStartingGoldBonus()` so selected game mode settings can affect startup without making `Start.j` depend on `GameMode.j`.

- Updated `Abilities/Abilities.j` and `QuestsAndDialogs/QuestMaster.j`
  - Added optional `GameMode` hooks so Developer mode can bypass ability prerequisites, ability quest locks, AP costs, and quest availability requirements.
  - Free Roam mode can bypass configured story-style quest gates while keeping level and reputation requirements enabled by configuration.

- Updated `Events/UnitDeathEvent.j`
  - Registered death callbacks directly on the central death trigger so `GetDyingUnit()` and `GetKillingUnit()` remain valid for systems such as `TerrainDamage`, `CreepRespawn`, AI revive handling, companion death handling, item drops, and reputation.
  - Added lazy central-trigger creation so older libraries that call `UnitDeathEvent_Register` without an explicit `requires UnitDeathEvent` dependency still register safely.

- Updated `UI/StatsLiteUI.j`
  - Matched the dead-state display check to `StatsUI` by using the unit's current widget life instead of the UnitIndexer alive flag, preventing revived heroes from staying shown as dead when the handle is still valid.

- Updated `Abilities/Shaman/ShamanGhostWolf.j`
  - Added optional `TerrainDamage` handoff during Ghost Wolf morph/return so terrain damage tracks the active wolf form instead of the hidden original hero.
  - Added optional `Companions` handoff during Ghost Wolf morph/return so focused companions, tamed pets, and controlled-display summons retarget to the currently active hero form.

- Updated `QuestsAndDialogs/DialogSystem.j`
  - Added reusable trainer result-line pools for learn success, reset success, and unable/failure responses.
  - Changed registered dialog line selection to keep per-list pick state and avoid immediate repeats, preventing trainer greet/learn/reset/unable lines from feeling stuck on the first option while cinematic mode has Warcraft's random seed fixed.

- Updated `Abilities/AbilityTrainerLines.j`
  - Added per-trainer result lines for Totemic, Restoration, Elemental, and Enhancement trainers.
  - Added helper playback APIs for learned, reset, and unable trainer feedback.

- Updated `UI/AbilitiesUI.j`
  - Plays trainer feedback lines from AbilityUI learn/reset actions based on the backend success/failure result.

- Updated `Abilities/AbilitiesPlayer.j`
  - Added ability prerequisite rawcodes for Ghost Wolf / Spirit Wolf, Reincarnation, and Totem Master.

- Updated `EnvironmentSystems/TerrainDamage.j`
  - Refreshes configured unit/group sources during the periodic scan so terrain damage still tracks Nazgrek, Zul'kis, pets, and companion groups if preload/game-start ordering makes the original delayed initialization run before those globals are ready.
  - Removes hidden Ghost Wolf original heroes from the manual terrain-damage group while keeping the active hero/wolf globals tracked.

- Updated `Abilities/Shaman/ShamanCommon.j`
  - Added hybrid stat amount helpers so abilities can combine two hero attributes with `AbilitiesPlayerInit.j` base values and talent-aware damage/healing modifiers.

- Updated shaman ability runtime libraries under `Abilities/Shaman/`
  - Added Intelligence scaling to Frost Shock, Nature Shock, Lightning Strike, and Lightning Shield.
  - Added Strength/Agility hybrid scaling to Stormstrike, Whirlwind, Ghost Wolf Bite, and Primal Force.
  - Added Agility-scaled crit bonus support to Bloodlust.
  - Added Intelligence inheritance for Summon Elemental health/damage.
  - Added Strength/Agility inheritance for Feral Spirits health/damage.

- Updated `Companions/Companions.j`
  - Added a controlled-display unit list for temporary controlled summons.
  - Included controlled-display units in order, idle, halt/resume, hostility-source, class/type/faction, and ability-info handling.
  - Kept controlled-display units separate from `udg_CompanionUnit[]` so temporary summons do not change the normal companion party size.

- Updated companion command voicelines
  - Added dedicated Nazgrek/Zulkis companion command lines for invite, kick, drop items, Passive, Normal, Aggressive, and Hold Position commands using `Nazgrek_CompanionXXX` / `Zulkis_CompanionXXX` sound keys.
  - Companion commands now queue the owned Nazgrek/Zulkis command line before the selected AI companion replies; all-companion mode commands still pick one random eligible AI companion responder.
  - If both Nazgrek and Zulkis are player-owned, the command speaker is selected randomly; if only one is owned, that hero is used.
  - Added companion-command line registration/picking support to `DialogSystem.j`, registered the new player lines in `DialogSystemPlayer.j`, registered the new ExSound sequences, and adjusted AI command bark queuing so replies wait behind the commander line.

- Updated `UI/StatsLiteUI.j` and `UI/StatsUI.j`
  - Added controlled-display summon rows after normal companion rows.
  - Stats panels can now show Summon Elemental and Feral Spirits units without treating them as normal companion party members.

- Updated `Abilities/Shaman/ShamanBoneArmor.j` and `Abilities/Shaman/ShamanAncestralWard.j`
  - Rebuilt Ancestral Ward visuals around the old BAmr three-segment orbit setup.
  - Added shield buff grace timing so the absorb state is not removed before Warcraft attaches the object buff.
  - Added self-target fallback for Ancestral Ward when the cast event has no explicit target unit.

- Updated `Abilities/AbilityTrainerDialogs.j`
  - Trainer selection now passes `ATD_USE_DIALOG_CAMERA` into the configured QuestGiver dialog-entry transition instead of starting the camera immediately before the fade path finishes.
  - Removed `FixedCameraLock` usage from ability trainer dialogs so the trainer camera follows the same normal `DialogCamera` handling style as `qAradion` and no longer applies an extra z-offset correction after the transition.

- Updated `Cinematic ON` and `Cinematic OFF` GUI triggers:
  - testing using the fullscreen mode from `FullscreenUI.j` with call FullscreenUI_SetEnabled(boolean)
  - Disabled the following functions as they could interfere with FullScreenUI:
    - Cinematic - Turn on letterbox mode (hide interface) for (All players): fade out over 2.00 seconds
    - Cinematic - Turn off letterbox mode (show interface) for (All players): fade in over 2.00 seconds

- Updated `DialogSystemPlayer.j`
  - Updated Nazgrek lines and added soundkeys, Zulkis lines and soundkeys remains in wip state to be worked on later.

- Updated `SoundAndMusic/ExSound.j`
  - Registered ability trainer voice sequences for Elemental, Enhancement, Restoration, and Totemic trainers.
  - Added grouped registrations for newly keyed Nazgrek player dialog lines used by `DialogSystemPlayer.j`, including trainer greeting/farewell, info, trade, exit, follow, stop, decline, and accept lines.
  - Added a compatibility registration for the current `Nazgrek_Accep4` dialog key so it resolves to the intended `Nazgrek_Accept4.mp3` asset.
  - Kept Zulkis trainer/info-style player lines as text-only for now because those lines currently use empty sound keys.

- Updated `Professions/ProfessionsFishing.j`
  - Implemented the first Fishing profession minigame around selectable fish pool unit nodes.
  - Registered Jin'Zun's Fishing Pole `'I6CJ'`, Basic Fishing Pole `'I6CQ'`, Strong Fishing Pole `'I6CR'`, Big Iron Fishing Pole `'I6CS'`, and ProMaster Fishing Pole 2000 `'I6CT'`.
  - Registered the first fish pool unit rawcode `'n02N'` as the default fish pool gather node.
  - Added bait registration and bait consumption hooks for temporary fishing skill bonuses and per-bait Fishing requirements.
  - Registered Shiny Bauble `'I6CM'`, Nightcrawlers `'I6CN'`, Bright Baubles `'I6CO'`, and Aquadynamic Fish `'I6CP'` as fishing bait items.
  - Auto-equips the best available DInventory fishing pole when it improves the fisher's pole bonus.
  - Selects the strongest usable bait from vanilla inventory or DInventory and reports the lowest unmet Fishing requirement when only locked bait is available.
  - Repositioned the FishingUI action buttons into a cleaner vertical stack beside the cast bar.
  - Moved FishingUI status text below the cast bar so it does not sit under the Cancel button.
  - Added a loose post-cast pool range check so walking away cancels fishing without interrupting normal animation jitter.
  - Stops fishing when the unit is attacked, the pool becomes invalid, the unit moves out of range, the reel window is missed, or the player cancels.

- Updated `Professions/ProfessionsSkinning.j`
  - Replaced the Skinning stub with the active Skin ability runtime.
  - Added a table-backed skinnable corpse registry with `ProfessionsSkinning_RegisterSkinningUnit` for future unit-type additions.
  - Added default mappings for boars, bears, frogs, turtles, wolves, and thunder lizards/salamanders to their skin item drops.
  - Supports Skinning Knife rawcodes `'I66M'` and `'i66m'` for inventory, DInventory, and DEquipment main-hand checks.
  - Integrated successful skinning with `GatherNodeSkills` skill gain and `UnitDeathEvent` state reset.
  - Uses Boar Skin rawcode `'I61C'`, matching the item export data where `'I61B'` is Bear Skin.

- Updated `GatherSystems/GatherNodes.j`
  - Added reusable water-depth and water-type helpers using the invisible platform probe.
  - Added non-walkable water predicates for gather nodes that must spawn in shallow or deep water.

- Updated `GatherSystems/GatherNodeUnits.j`
  - Added fish-pool category handling so unit node category `9` spawns only in non-walkable shallow or deep water.
  - Added zone-aware unit-node drops through `GNU_RegisterZoneDrop`, with exact zone, parent zone, then generic drop fallback.
  - Added public unit-node query helpers for definition id, category id, and stored zone id.
  - Added `GNU_RegisterExistingUnitNode` and `GNU_RollGatherUnitRewards` support for preplaced or UI-driven unit-node harvesting.

- Updated `Zones/ZonesCore.j`
  - Added numeric `levelMin` and `levelMax` fields to `ZoneData`.
  - Converted configured zone quest level strings to derive from `setLevelRange`.
  - Added effective zone-level helpers for systems such as fishing rewards.
  - Added point-to-zone lookup so preplaced fish pools can register with their actual zone.

- Updated `Professions/Professions.j`
  - Exposed `Professions_ConsumeItem` so profession extension UIs such as Fishing can consume bait items from vanilla inventory or DInventory.
  - Added profession item-bonus and effective-skill wrappers for ItemManager/DEquipment-authored profession stats.
  - Profession crafting requirements and recipe availability summaries now use effective skill instead of base-only learned skill.

- Updated `GatherSystems/GatherNodeSkills.j`
  - Added effective profession skill calculation that combines base learned skill with DEquipment profession attributes.
  - Gather node requirements and the `/skills` readout now account for profession item bonuses without changing base skill gain.

- Updated `UI/ProfessionsUI.j`
  - Profession rows and detail panels now display effective profession skill values, including item bonuses.
  - Clamps only the progress bar fill to 100 while preserving over-cap effective values in the text label.

- Updated `DestroyerInventoryAndEquipmentSystem/PoTs/DEquipment.j` and `DestroyerInventoryAndEquipmentSystem/PoTs/SharedDInvLib.j`
  - Enabled symmetrical `Trinket1` / `Trinket2` slots using DEquipment slot IDs `17` and `18`.
  - Lowered the main-hand/off-hand row and equipment backdrop to make room for the new trinket row.
  - Increased the per-player equipment-frame stride so enabling slots `17` and `18` does not collide with the next player's frame indexes.
  - Made slot-name lookup case-insensitive enough for definitions such as `Mainhand` / `MainHand`, and made generic `Ring` / `Trinket` definitions expand to both corresponding slots.
  - Renamed DEquipment stat ID `19` from `Cleave Damage` to `Cleave Area`, matching the runtime code that already changes cleave area.
  - Registered DEquipment profession stat names for Mining, Herbalism, Skinning, Fishing, Alchemy, Blacksmithing, Leatherworking, Enchanting, and Cooking.
  - Hid the generated granted-ability-name block in DEquipment/DInventory tooltips by default so internal bonus abilities such as item attack/damage bonuses do not leak into custom tooltip frames.

- Updated `DestroyerInventoryAndEquipmentSystem/PoTs/DEquipmentDefinitionHELP.j`
  - Documented the new `Trinket1` and `Trinket2` slots.

### Tool Updates

- Updated `WC3_Database/export_dequipment_cli.py`
  - Fixed DEquipment slot export for classes such as `Main Hand Weapon`; the exporter no longer matches the `HAND` substring before weapon hand checks.
  - DEquipment export now considers explicit `items.equipment_slot` and `item_classes.slot_type` metadata instead of relying only on class-name text guessing.
  - Verified that Skinning Knife `'i66m'` exports as `MainHand` instead of `Gloves`.
  - Preserves rawcode case instead of forcing lowercase, and emits aliases from `WC3_Database/config/item_table_mapping.json` so generated DEquipment definitions can cover both imported uppercase rawcodes and lowercase database codes.
  - Exports `Ring` items to slots `8` and `9`, `Trinket` items to slots `17` and `18`, and `Stave` items to slot `19` with the two-handed flag.
  - Normalizes current ItemManager stat names to registered DEquipment stat names such as `Hitpoints`, `Hitpoint regeneration`, `Mana regeneration`, `MoveSPD Pct`, `Spell Damage Taken Pct`, and `Cleave Area`.
  - Exports profession item stats to the matching DEquipment stat names.
  - Converts whole-percent ItemManager values to DEquipment fractional values for stats whose Warcraft ability fields expect fractions, such as attack speed, lifesteal, armor percent, movement speed percent, and damage-taken percent.
  - Filters generated ItemManager stat abilities and legacy imported stat abilities out of DEquipment ability grants when the item already exports DEquipment stats, while preserving real item-use abilities such as Skin.

- Updated `WC3_Database/WC3ItemManager/ItemEditForm.cs`
  - Treats legacy imported stat abilities as stat-generated abilities when loading an item with regenerated stats, preventing old codes such as `AIat` from being saved back as manual abilities beside the new generated stat ability.

- Updated `WC3_Database/core/wc3_w3t_exporter.py`
  - Removes legacy imported stat ability codes from vanilla item ability export when ItemManager-generated stat abilities are already present, preventing rows such as Skinning Knife from exporting both `A07N` and `AIat`.

- Updated `WC3_Database/WC3ItemManager` database bootstrap paths
  - Ensures `Stave` is seeded as `TWOHAND_STAFF` and `Trinket` is seeded as `TRINKET` for older or freshly initialized ItemManager databases.
  - Seeds ItemManager stat definitions for Healing Power and all profession skill stats through Cooking.

- Added `WC3_Database/database/add_profession_stats_39_48.sql`
  - Provides a non-destructive migration for Healing Power and profession stat definitions.

- Updated `WC3_Database/core/wc3_deq_exporter.py`
  - Aligned the older level-range DEquipment exporter path with the current two ring slots and two trinket slots.

- Updated `WC3_Export/DEquipmentItemDefinitions/DEquipmentItemDefinitions_20260725-1730.j`
  - Patched the current generated DEquipment definitions so `Stave`, `Ring`, and `Trinket` items have the corrected slot definitions immediately.
  - Added uppercase rawcode aliases for Skinning Knife `'I66M'` and Copper Chain Boots `'I68M'`, matching other profession, AI, and loot-system references.
  - Replaced invalid exported stat labels such as `Health`, `HPS`, `Mana Regen Per Sec`, `Lifesteal`, `Movement Speed %`, and damage-taken names with DEquipment-registered stat names.
  - Removed generated/legacy stat ability grants from rawcodes that already have DEquipment stat definitions; Skinning Knife keeps the real Skin ability `A0F3` but no longer grants extra damage abilities.

### Known Issues

- Full in-map JassHelper / Warcraft III compile validation was not completed in this repo snapshot because no combined `war3map.j` or normal map build entry point is exposed.
- The converted `Preload/Start.j` and new `UI/GameMode.j` player startup flow still needs in-map validation with the active generated globals for `IntroV2Nazgrek01`, `Intro Cinematic Orc Q`, frame UI interaction, and selected mode/difficulty handoff.
- The updated shaman scaling, Ancestral Ward orbiting effects, trainer camera timing, Ghost Wolf companion retargeting, trainer feedback lines/randomized registered-line picker, ability prerequisites, trainer/player ExSound registrations, and temporary summon Stats UI rows still need in-game validation with the active object data/import set.
- The new FishingUI minigame, fish-pool water placement, preplaced fish-pool zone detection, and zone-aware fish rewards still need in-game validation with the active map object data.
- The new Skinning flow and default beast rawcode list still need in-game validation with the active object data; Vizier Skin has no confirmed unit rawcode registered yet.
- The corrected DEquipment trinket row, slot-name fallback behavior, and regenerated ItemManager equipment definitions still need in-map validation with the active object data/import set.

## [23.7.2026]

### Player-Facing Updates

- Ability point and talent point gains now show immediate player feedback when points are earned.
- TalentUI now swaps the talent-tree pane background texture per selected shaman tree: Elemental, Enhancement, Restoration, and Totemic.
- Converted the non-totem player shaman ability runtime from old GUI triggers into JASS libraries for Elemental, Enhancement, and Restoration abilities.
- Summon Elemental and Feral Spirits now register their summons as controlled companions, so they can follow/defend the player without consuming normal companion party slots.
- Ghost Wolf now has a JASS-backed morph/unmorph flow that preserves hero state, inventory ownership, XP, learned ability ranks, life/mana, and item pickup handoff.
- Ancestral Ward and Water Shield now use a shared absorb-shield backend. Water Shield restores mana from absorbed shield damage.

### Technical Updates

- Updated `Events.j`
  - Added centralized helper registrations:Events_RegisterSpellEffect
    - Events_RegisterSpellChannel
    - Events_RegisterSpellFinish
    - Events_RegisterSpellEndcast
    - Events_RegisterUnitSummon
    - Events_RegisterUnitPickupItem
    - Events_RegisterUnitDropItem
    - Events_RegisterUnitAttacked
    - Events_RegisterHeroLevel
  - Added cached Events_Get* accessors for trigger-dispatched callbacks: spell ability/target, summoning/summoned unit, manipulating unit, manipulated item.
  - Preserved the important rule: direct code callbacks still run on the central trigger and should use normal natives like GetTriggerUnit() / GetSpellAbilityId().

- Added `Abilities/AbilitiesPlayerInit.j`
  - New JASS library that stores player shaman ability base values from the old `Init Abilities` trigger in Bribe's Table v6 instead of `udg_Ability_*` globals.
  - Added query helpers for raw base values, unit-rank base values, talent-aware damage values, and talent-aware healing values.
  - Damage and healing value helpers run through `Talents_ApplyDamageBonus` / `Talents_ApplyHealBonus` when `Talents.j` is present, so converted cast scripts can combine old base tuning with talent modifiers at cast time.
  - Added base values for Frost Shock, Nature Shock, Lightning Shield, Primal Force, Water Shield, and Ancestral Ward for the new runtime libraries.
  - Corrects the obvious old Fire Shock AoE rank-index export typo by storing the intended ranks 3-5 values.

- Updated `Abilities/Shaman/*.j` and `Totems.j`:
  - Replaced all generic Events_RegisterPlayerUnitEvent(..., EVENT_...) calls with the new event-specific helpers.
  - Confirmed there are no direct TriggerRegisterPlayerUnitEvent calls and no remaining generic Events_RegisterPlayerUnitEvent calls inside Abilities/Shaman.

- Added `Abilities/Shaman/ShamanCommon.j`
  - Shared player shaman rawcodes, caster-stat scaling helpers, dummy cast helpers, hero-state transfer helpers, companion registration helpers, and talent-aware cooldown reduction helpers.

- Added Elemental shaman runtime libraries under `Abilities/Shaman/`
  - `ShamanLightningBolt.j`, `ShamanChainLightning.j`, `ShamanFireShock.j`, `ShamanFrostShock.j`, `ShamanNatureShock.j`, `ShamanLightningStrike.j`, `ShamanLightningShield.j`, and `ShamanSummonElemental.j`.
  - Converted old GUI damage setup, dummy casting, AoE damage, shock effects, Lightning Shield periodic damage, and Summon Elemental channel/summon behavior into JASS.
  - Converted damage calculations now combine `AbilitiesPlayerInit.j` base values, hero Int scaling, and `Talents.j` damage modifiers at cast time.
  - Summon Elemental now registers air, water, fire, and earth elementals as player-controlled companions in defend mode without limiting the normal companion party.

- Added Enhancement shaman runtime libraries under `Abilities/Shaman/`
  - `ShamanStormstrike.j`, `ShamanWhirlwind.j`, `ShamanWindShear.j`, `ShamanPrimalForce.j`, `ShamanBloodlust.j`, `ShamanFeralSpirits.j`, `ShamanGhostWolf.j`, `ShamanHex.j`, `ShamanVoodooCurse.j`, and `ShamanVoodooSpirits.j`.
  - Converted old GUI direct damage, dummy burst casts, totem interaction hooks, silence/stop control, Bloodlust group casting, rank-based crit bonus cleanup, and Feral Spirits summon behavior into JASS.
  - Feral Spirits now registers wolves as controlled companions and applies the Feral Bond special talent to wolf health and damage.
  - Ghost Wolf was rebuilt carefully around the old hidden-original/active-wolf model so Nazgrek and Zul'kis keep inventory, XP, hero stats, learned ranks, and item pickup behavior when shifting.
  - Hex now preserves the old target restrictions for bosses and high-level targets without carrying over GUI debug spam.

- Added Restoration shaman runtime libraries under `Abilities/Shaman/`
  - `ShamanTotemicResurgence.j`, `ShamanBoneArmor.j`, `ShamanAncestralWard.j`, `ShamanWaterShield.j`, `ShamanHealingWave.j`, `ShamanChainHeal.j`, `ShamanHealingRain.j`, `ShamanRejuvenation.j`, `ShamanSpiritualHealing.j`, `ShamanSpiritLink.j`, and `ShamanReincarnation.j`.
  - `ShamanBoneArmor.j` provides the shared BAmr-style absorb shield core used by Ancestral Ward and Water Shield.
  - Ancestral Ward and Water Shield now use base values from `AbilitiesPlayerInit.j`, Int scaling, healing talent modifiers, and 90 second shield durations.
  - Water Shield returns mana based on shield damage absorbed.
  - Healing Wave, Chain Heal, Healing Rain, and Rejuvenation now apply base values, Int scaling, healing talents, and Totemic Resurgence where appropriate.
  - Spiritual Healing now has a JASS hook for delayed mana refunds based on caster Int and spell mana cost.

- Updated `Abilities/Abilities.j`
  - Added `AbilitiesPlayerInit` as an explicit dependency so player shaman ability base values are initialized with the JASS ability system.

- Updated `Leveling/AbilityPoints.j`
  - Added positive-gain feedback for manual AP grants and hero level-up AP awards.

- Updated `Abilities/Talents.j`
  - Added a public talent tree registration API for tree dimensions and talent definitions.
  - Moved default Elemental, Enhancement, Restoration, and Totemic talent definitions out of the runtime talent state library.
  - Added positive-gain feedback for talent level syncs, level-up awards, and bonus talent point grants.

- Added `Abilities/TalentsElemental.j`, `Abilities/TalentsEnhancement.j`, `Abilities/TalentsRestoration.j`, and `Abilities/TalentsTotemic.j`
  - Each shaman tree now owns its talent definitions in a separate library for easier tree tuning and expansion.

- Updated `UI/TalentsUI.j`
  - Added per-tree background texture selection for the TalentUI tree pane.

- Updated `Professions.j`
  - Crafting now cancels when the crafting unit is attacked:
    - Registers EVENT_PLAYER_UNIT_ATTACKED during Professions_Init.
    - Checks whether the attacked unit has an active profession job.
    - Calls the existing cancel path so the craft fails, loop sound/fake cast/animations/reservations/cinematic state are cleaned up.
    - Player-owned interrupted crafting shows Crafting interrupted.
    - If the station feedback had already started, it is reset; alchemy also removes the cauldron light ability and cancels pending delayed alchemy animation stages.
- Updated `CampFire.j` and `BaseCamp.j`
  - BaseCamp now shows the normal is now Rested message when a Tent rest renews an already Rested hero. CampFire behavior remains non-renewing; it still filters out already Rested heroes before applying resting progress, documented that in the library header.

- `Preload/Preloader.j`
  - Creates a temporary hidden AbilityLoader unit from rawcode `h60N` for ability preloading and removes it immediately after use.

### Known Issues

- Full in-map JassHelper compile and runtime validation are still required before retiring the old Elemental, Enhancement, and Restoration shaman GUI runtime triggers.
- Old `Init Abilities` and old GUI ability learning triggers should only be disabled after confirming no remaining non-converted systems still depend on them.

### Actions Remaining

- Import/include the new `Abilities/Shaman/Shaman*.j` libraries in the active map build order and run a full JassHelper compile.
- After successful compile and gameplay testing, disable the old runtime GUI trigger folders under `SHAMAN ABILITIES/Elemental abilities`, `SHAMAN ABILITIES/Enhancement abilities`, and `SHAMAN ABILITIES/Restoration abilities`.

## [22.7.2026]

### Player-Facing Updates

- Added a startup preload presentation before the intro/game-start flow:
  - Player control is disabled while the preload sequence runs.
  - Preload now enters a UI-hidden state, displays 16:9 frame UI images over a full-screen backing frame, and shows two-line colored RegionTitles-style phase text for ability, sound, music, and completion stages.
  - The intro/game start trigger is executed only after the preload sequence completes.
  - Loading a saved game reruns sound/music preload without restarting the game-start flow.

- Added a new player shaman ability learning flow for Nazgrek and Zul'kis:
  - Enhancement, Elemental, Restoration, and Totemic trainers now start a short cinematic greeting dialog instead of opening the learning UI immediately on selection.
  - Trainer dialogs have basic `Learn` and `Farewell` buttons; `Learn` opens the focused ability training UI and `Farewell` exits the dialog flow.
  - Each trainer type now has its own generic personality lines:
    - Totemic / Totem Master: calm tauren spiritwalker, astral and totem-focused.
    - Restoration Master: troll witchdoctor healer voice.
    - Elemental Master: storm, fire, frost, and elemental shaman voice.
    - Enhancement Master: combat-shaman weapon/spirit voice.
  - Learning is now driven by the new `AbilityPoints.j` ability-point state instead of the old GUI `AbilityPoints` integers.
  - Successful ability learning plays `gg_snd_NewAbility`.
  - Failed learning attempts, such as missing AP or requirements, play `gg_snd_Error`.
  - Learned abilities are made permanent in the same style as the old GUI learning triggers.
  - Ghost Wolf / Spirit Wolf is now marked as quest-trained for the initial rank, so trainers cannot teach rank 1 directly.

- Added the new shaman talent tree UI:
  - `AbilitiesLiteUI` now exposes a Talents entry for player shaman heroes.
  - Elemental, Enhancement, Restoration, and Totemic talents are available as separate tree tabs.
  - Talent buttons show ranks, locked overlays, selected highlights, hover tooltips, and dependency links between prerequisite talents.
  - Talent details now show preview rank text, missing requirement text, tree points, available points, and pending point status.
  - Players can add pending ranks, remove pending ranks, confirm pending talents, and cancel pending changes from `TalentsUI`.
  - Talent effects only apply after Confirm; ability scripts still read confirmed talent ranks.
  - Talent points are primarily earned from hero level-ups, matching ability points: 1 talent point per qualifying player hero level starting at level 2.
  - Talent tree buttons now use a denser WoW-style icon layout with compact `0/5` style rank numbers and stable hover tooltips.
  - Talent allocation can be done from the talent tree anywhere; talent reset is trainer-only through `AbilitiesUI`.

- Refined profession crafting sound playback:
  - Player-started cinematic crafting now creates fresh non-3D profession sounds from configured file paths so playback is not locked to Sound Editor 3D settings.
  - AI crafting and any non-cinematic craft actions continue to use 3D sound playback on the workstation unit.
  - Crafting cinematics now hide the MasterUI `Game` button until the craft cinematic ends.
  - Forge smelting now uses the `Smelting` craft sound label instead of mining-hit labels; mining ore harvesting and herb picking sounds were left unchanged.

- Stats UI now shows `Rested` for the selected unit when the centralized Experience system reports that the unit is rested.
- Rested status is now lost when the rested unit dies.
- Tent Sleep can now be used by already Rested Nazgrek/Zul'kis heroes; completing the tent rest renews the Rested state instead of blocking the sleep.

### Technical Updates

- Added `UI/ImagesUI.j`
  - New lightweight 16:9 image frame helper for preload and similar scripted presentation flows.
  - Provides public APIs for showing, updating, and hiding the preload image surface.
  - Keeps image paths caller-controlled so imported preload BLPs can be swapped without changing the UI helper.
  - Uses a full-screen backing frame while preserving the image surface at `0.800 x 0.450`.
  - Preloads texture paths before frame texture swaps to make staged preload image changes more reliable.

- Added `Preload/Preloader.j`
  - New timer-driven startup preload runner that replaces the old GUI wait chain.
  - Runs at elapsed game time `0.00`, hides the normal game UI, updates preload UI/status text through `RegionTitles`, and preloads abilities, sounds, and music in staged steps.
  - Enters the UI-hidden state with `ShowInterface(false, 0.00)` followed by `BlzHideCinematicPanels(true)`.
  - Restores the UI in reverse order with `BlzHideCinematicPanels(false)` followed by `ShowInterface(true, 0.00)`.
  - Splits each preload phase into a visible UI/title tick and a later preload-work tick so image changes can render before synchronous preload work begins.
  - Calls `ExSound_PreloadAll()`, `ExMusic_PreloadAll()`, and `Preload_Abilities(...)`.
  - Executes `gg_trg_Game_Start` and initializes `StatsLiteUI` after preload completion.
  - Added a saved-game load path using `EVENT_GAME_LOADED` that preloads sound/music again but does not execute `gg_trg_Game_Start`.

- Updated `Texts/RegionTitlesLight.j`
  - Raised region-title frame levels so preload phase text renders above the full-screen preload image.
  - Added a preload-specific two-row title API with smaller `Preloading...` text above a larger colored phase title.

- Updated `UI/MasterUI.j`
  - The `Game` button is now hidden by default and still appears normally when `MasterUI_ShowGameButton()` is called.

- Updated `Preload/PreloadAbilities.j`
  - Wrapped the existing rawcode preload function in a `PreloadAbilities` library so other libraries can declare a proper dependency.
  - Made the function's `unit u` parameter populate `udg_AbilityPreloader` before the existing ability-add list runs.
  - Documented that the startup preloader now creates the temporary `h60N` loader unit itself instead of relying on a placed World Editor unit.
  - Consolidated the duplicate ability preloader into this single `Preload/PreloadAbilities.j` file and removed the stale `InitRelated/PreloadAbilities.j` copy.
  - Preserved the missing Craft (Fake Cast) preload rawcode `A6DY` while consolidating.

- Updated `UI/StatsUI.j`
  - Added `Experience` as an explicit dependency.
  - Added a detail-header `Rested` text indicator that reads `Experience_IsRested(unit)` and clears when the selected unit changes, dies, loses Rested, or the panel is hidden.

- Updated `Leveling/Experience.j`
  - Renamed the misleading Rested rawcode constant from `BUFF_RESTED` to `RESTED_ABILITY_ID`.
  - Added comments clarifying that Rested uses hidden aura ability rawcode `S000` through `UnitAddAbility` / `UnitRemoveAbility`, not a buff rawcode.
  - Rested death cleanup now clears the dying unit's hidden Rested ability, expiry timer, and multiplier state before cinematic XP guards can skip XP processing.

- Updated `Leveling/BaseCamp.j`
  - Removed the Rested-state gate from Tent Sleep hero registration.
  - Added BaseCamp-local elapsed tracking so already Rested heroes can complete the normal 8-second tent rest and renew Rested through `Experience_GrantRested`.
  - Non-rested Tent Sleep still uses the shared `Experience_AddRestingProgress` path.

- Added `Abilities/AbilitiesPlayer.j`
  - New player shaman ability registry for JASS learning and UI display.
  - Stores ability tree, kind, learn/raw ability ids, permanent ability ids, AP cost, max level, and optional requirements.
  - Added per-entry initial quest-lock metadata for abilities that must be awarded by quests before normal trainer rank-ups.
  - Marked Ghost Wolf / Spirit Wolf as requiring Spirit Wolf quest training for rank 1.
  - Centralizes player shaman ability definitions for Elemental, Enhancement, Restoration, and Totemic trees.
  - Provides trainer-unit tree lookup for:
    - Enhancement Master (`o628`)
    - Elemental Master (`o627`)
    - Restoration Master (`o626`)
    - Totem Master (`o625`)
  - Reuses object-data tooltip/icon data where possible and supports authored fallback text.

- Added `Abilities/Abilities.j`
  - New JASS backend for ability learning, specialization reset, ability reset, and talent reset delegation.
  - Uses `AbilityPoints.j` for all AP checks/spending instead of the old GUI ability-point globals.
  - Preserves the old GUI learning behavior of adding the permanent learned ability and hiding it when needed.
  - Added public learn/reset APIs for use by trainer UI and future scripted reward/learning hooks.
  - Added quest reward grant APIs:
    - `Abilities_GrantQuestEntry`
    - `Abilities_GrantQuestAbility`
  - Trainer learning now reports quest-locked initial ranks with a dedicated `RESULT_QUEST_LOCKED` result.
  - Delegates talent reset to `Talents_ResetHeroTalents` when the optional `Talents` library exists.

- Added `Abilities/AbilityTrainerLines.j`
  - Registers stable trainer display names and generic greet/farewell lines for Totem, Restoration, Elemental, and Enhancement Masters.

- Added `Abilities/AbilityTrainerDialogs.j`
  - New QuestGiver-backed dialog/cinematic layer for all shaman trainer unit-types.
  - Scans placed trainer units on map init and registers trainers created later through `Events_RegisterUnitEnter` when `Events.j` is available.
  - Uses `QuestGiver_RegisterSelectionHandler` and configured dialog entry/camera handling, matching the existing qAradion-style cinematic flow.
  - Builds `Learn` / `Farewell` trainer dialogs and opens `AbilitiesUI_ShowForTrainer` only from the `Learn` button.
  - Added a dialog-builder hook so future trainer quest libraries can add quest buttons to the same trainer dialog.
  - Follow-up fix: trainer dialog camera settings now match the profession crafting camera profile.
  - Follow-up fix: trainer selection now skips the old broad `gg_trg_Cinematic_ON` movement trigger and explicitly restores/selects the hero on dialog end, preventing the player unit from remaining hidden after the trainer flow.
  - Follow-up fix: trainer cameras now compute rotation from the active player hero's side of the trainer instead of using one static offset.
  - Follow-up fix: trainer dialog camera is fixed while `AbilitiesUI` is open, preventing camera movement while keeping frame buttons usable.
  - Follow-up fix: trainer selection now applies the configured dialog camera immediately and disables the delayed QuestGiver camera application for that entry transition.

- Added `UI/AbilitiesUI.j`
  - New trainer-facing ability learning UI based on the `AbilitiesLiteUI` frame style.
  - Shows only the ability tree that matches the trainer unit being talked to.
  - Displays ability name, icon, current level, cost, requirement state, and detailed text.
  - Includes controls for learning abilities, resetting abilities, resetting specialization, and resetting talents.
  - Hides other major custom UI panels when opened and integrates with `MasterUI` / `AbilitiesLiteUI` panel behavior.
  - Trainer selection is no longer handled directly here; `AbilityTrainerDialogs` owns selection and opens this frame from the dialog `Learn` button.
  - Follow-up fix: closing or returning from a trainer-opened `AbilitiesUI` now reopens the trainer dialog selection with cinematic mode still active.

- Added `Abilities/Talents.j`
  - New shaman talent backend for Nazgrek and Zul'kis.
  - Stores Elemental, Enhancement, Restoration, and Totemic talent definitions separately from Warcraft ability rawcodes.
  - Added confirmed-rank, pending-rank, and preview-rank handling.
  - Added pending allocation APIs:
    - `Talents_Allocate`
    - `Talents_Deallocate`
    - `Talents_ConfirmPending`
    - `Talents_CancelPending`
  - Kept `Talents_GetTalentRank` confirmed-only so ability scripts never read unconfirmed UI preview ranks.
  - Added preview APIs for UI point totals, tree-spent totals, rank text, info text, and body text.
  - Added requirement/failure text APIs so UI and click feedback use the same backend requirement messages.
  - Added a stored level-earned talent point pool, level-up awarding, and `Talents_SyncLevelPoints` for load/import catch-up.
  - Expanded each backend talent tree viewport from 5 columns by 6 rows to 6 columns by 8 rows for larger future trees.
  - Talent level-up awarding uses `Events.j` when available, falls back to its own player hero level trigger otherwise, and respects `AbilityPoints_IsHeroLevelUpEnabled` when `AbilityPoints.j` is imported.
  - Follow-up fix: level-up talent awards now read `GetLevelingUnit()` directly and award from hero level 2 onward, so talent points increase with the same level-up rhythm as ability points.
  - Added reusable effect helper APIs for ability scripts:
    - `Talents_GetDamageBonusPercent`
    - `Talents_ApplyDamageBonus`
    - `Talents_GetHealBonusPercent`
    - `Talents_ApplyHealBonus`
    - `Talents_GetCooldownBonusPercent`
    - `Talents_HasTalentById`
  - Talent reset now clears both confirmed and pending talent ranks.

- Added `UI/TalentsUI.j`
  - New custom frame talent tree UI for player shaman heroes.
  - Inspired by The_Spellweaver's STK talent tree ideas, but implemented directly in the lighter PotS globals-based UI style instead of importing the full external framework.
  - Adds four tree tabs, a fixed grid, rank labels, locked overlays, selection highlight, detail pane, Add Rank, Remove, Confirm, Cancel, Return, and Close controls.
  - Adds STK-style hover tooltip panels.
  - Adds STK-style dependency link frames between prerequisite talents with active/inactive textures.
  - Uses preview ranks and preview point totals while pending changes exist.
  - Confirms pending ranks through `Talents_ConfirmPending`, which then plays `gg_snd_NewAbility`.
  - Replaced native `BlzFrameSetTooltip` ownership with disabled manual tooltip frames to avoid hover flicker.
  - Replaced the filled active-button talent highlight with a selected-talent autocast sprite highlight based on the `StatsLiteUI` sprite pattern.
  - Expanded the talent grid capacity to 6 columns by 8 rows and matched the backend tree dimensions.
  - Raised tooltip frame levels above talent icons and wrapped detail requirement text so descriptions stay inside the talent panel.
  - Follow-up fix: unavailable talent icons now use a darkened icon tint instead of an opaque black overlay, keeping the artwork visible while still reading as locked.
  - Follow-up fix: unavailable talent icons now add a controlled low-alpha black overlay above the icon but below rank text, making locked talents read as unavailable without becoming solid black.

- Updated `UI/AbilitiesLiteUI.j`
  - Added a Talents button for player shaman heroes.
  - Opens `TalentsUI_ShowForUnit` for Nazgrek/Zul'kis when the optional `TalentsUI` library exists.

- Updated `QuestsAndDialogs/DialogSystem.j` and `DialogSystemPlayer.j`
  - Added trainer-specific hero greet/farewell line pools for Nazgrek and Zul'kis.
  - Added `DialogSystem_PickGreetTrainerLine`, `DialogSystem_PickFarewellTrainerLine`, `DialogSystem_RegisterGreetTrainerLine`, and `DialogSystem_RegisterFarewellTrainerLine`.
  - Initialized the existing info-line table during DialogSystem init so registered info lines are stored consistently.

- Updated `UI/MasterUI.j` and related panel hiding behavior:
  - Added `TalentsUI_Hide` calls so the talent panel closes consistently when other major UI panels open.

- Added `Events/Events.j`
  - New centralized non-death event dispatcher for common map-wide unit events.
  - Registers each supported player-unit event once for player slots `0..27`, then dispatches callbacks to registered systems.
  - Added APIs for code callbacks and trigger callbacks:
    - `Events_RegisterUnitEnter`
    - `Events_RegisterUnitEnterTrigger`
    - `Events_RegisterPlayerUnitEvent`
    - `Events_RegisterPlayerUnitTrigger`
  - Added current-event helper APIs:
    - `Events_GetTriggerUnit`
    - `Events_GetCurrentEventId`
    - `Events_GetCurrentPlayerUnitEvent`
  - Explicitly rejects `EVENT_PLAYER_UNIT_DEATH`; death remains handled by `_CoreSystems/UnitDeathEvent.j`.
  - Trigger callbacks now respect disabled triggers and run conditions before actions, matching normal trigger callback behavior more closely.
  - Follow-up fix: `Events_RegisterUnitEnter` and `Events_RegisterPlayerUnitEvent` now attach code callbacks directly to the central event trigger instead of executing them through secondary triggers, so normal event responses such as `GetTriggerUnit()`, `GetSpellAbilityId()`, and `GetManipulatedItem()` remain valid.

- Replaced the old centralized GUI map-enter pattern:
  - `Events/_OldGUI/Init 07 Unit Event Enters` is now documented as migrated/deprecated.
  - The old per-unit `Floating Texts Spell Event` add-event pattern should not be replaced with `Events_RegisterPlayerUnitTrigger` if the GUI trigger depends on native event responses. Convert it to a JASS code callback with `Events_RegisterPlayerUnitEvent`, or keep one direct all-player spell-effect registration until it is converted.
  - `CreepRespawn`, `UnitStats`, `ResourceRage`, and `ResourceEnergy` now register their unit-enter handling through `Events.j`.

- Migrated many active systems away from standalone all-player event registrations:
  - `AI/AI.j`
  - `Abilities/Shaman/Totems.j`
  - `CastingBar/CastingBarSystem.j`
  - `Companions/Companions.j`
  - `Companions/Pet.j`
  - `CreepRespawn/CreepRespawn.j`
  - `ItemLootSystems/ItemLootSystem.j`
  - `ItemSystems/ItemCleanup.j`
  - `ItemSystems/ItemUnstack.j`
  - `Leveling/BaseCamp.j`
  - `Leveling/CampFire.j`
  - `Leveling/Experience.j`
  - `PatrolFollowSystems/PatrolSystem.j`
  - `Reputation/Reputation.j`
  - `Resources/ResourceEnergy.j`
  - `Resources/ResourceRage.j`
  - `Stealth/Stealth.j`
  - `UnitSystems/UnitStats.j`

- Migrated additional direct death listeners to `UnitDeathEvent_Register` instead of local `EVENT_PLAYER_UNIT_DEATH` registrations:
  - `Abilities/Shaman/Totems.j`
  - `Companions/Pet.j`
  - `Leveling/BaseCamp.j`
  - `Leveling/CampFire.j`

- Split handlers that previously depended on `GetTriggerEventId()` before moving them to `Events.j`:
  - `AI/AI.j` now has separate item pickup/drop callbacks.
  - `Leveling/Experience.j` now has separate bonus-item pickup/drop callbacks.

- Converted migrated condition-trigger callbacks back to direct code callbacks after the event-response issue was found:
  - `Stealth/Stealth.j`
  - `ItemSystems/ItemCleanup.j`
  - `ItemSystems/ItemUnstack.j`
  - `Abilities/Talents.j`

- Updated profession crafting sound routing:
  - `UI/Interface.j` now exposes configurable `Interface_Profession_*Path` globals and fresh path-created profession playback helpers for normal or 3D playback.
  - `Professions/Professions.j` now restores muted volume groups for player craft cinematics, tries configured file paths before `gg_snd_*` handles for player-cinematic craft sounds, and keeps workstation-attached 3D playback for AI or non-cinematic craft jobs.
  - `Professions/Professions.j` now optionally calls `MasterUI_HideGameButton` / `MasterUI_ShowGameButton` around player craft cinematics.
  - `Professions/ProfessionsMining.j` now registers `Smelting` as the Forge start/loop/end sound label.

### Known Issues

- Full in-map JassHelper / Warcraft III compile validation was not completed for the abilities/talents work because no local `jasshelper`, `pjass`, or `wurst` command is available in this shell and the repo snapshot still does not expose a normal combined map build entry point.
- The new ability/talent libraries still need in-game validation with the actual trainer units (`o625`, `o626`, `o627`, `o628`), Nazgrek, Zul'kis, and the current object-data rawcodes.
- The new trainer dialog/cinematic handoff still needs in-game validation for selection gating, greeting sequences, `Learn` handoff, `Farewell` exit transition, and trainer quest-button builder hooks.
- Ghost Wolf / Spirit Wolf quest-lock behavior still needs a real quest-chain reward script that calls `Abilities_GrantQuestAbility` for the initial rank.
- Old GUI player ability add/level triggers should be disabled after the JASS learner is imported, otherwise ability learning/reset behavior can double-run or conflict.
- Talent helper APIs are present, but individual ability scripts still need to be wired to the relevant talent effect helpers before every talent has visible gameplay impact.
- Talent save/load persistence is not implemented yet; current talent ranks live in runtime JASS state.
- `TalentsUI` tooltip placement and dependency link textures need in-game visual validation on the Warcraft III frame layer.
- This is a high-risk structural event refactor. Any system that relied on direct trigger registration order, disabled trigger state, or event response timing should be retested in-game.
- Full map compile validation was not completed because the repo snapshot still does not expose a combined `war3map.j` or normal map build entry point. `git diff --check` passed for the edited files.
- GUI `Floating Texts Spell Event` must not keep the old per-unit add-event behavior. Convert it to a JASS code callback registered through `Events_RegisterPlayerUnitEvent`, or keep one direct all-player spell-effect event on the GUI trigger until it is converted.
- Remaining direct event registrations still exist in separate quest/gather/UI/imported/old systems. They were not all migrated in this pass to avoid changing unrelated behavior without focused testing.
- Rested UI display and death-removal behavior still need in-game validation with the actual `S000` object-data aura setup.

### Actions Remaining

- Import/include the new ability/talent libraries in the active map build order:
  - `Abilities/AbilitiesPlayer.j`
  - `Abilities/Abilities.j`
  - `Abilities/AbilityTrainerLines.j`
  - `Abilities/AbilityTrainerDialogs.j`
  - `Abilities/Talents.j`
  - `UI/AbilitiesUI.j`
  - `UI/TalentsUI.j`
- Confirm the old GUI player ability add/level/reset triggers are disabled after the JASS replacements are active.
- In-game test each trainer dialog opening the correct tree through `Learn`:
  - `o628` Enhancement
  - `o627` Elemental
  - `o626` Restoration
  - `o625` Totemic
- Add the Spirit Wolf quest/quest-chain reward and call `Abilities_GrantQuestAbility(hero, 'A68Y')` when the initial rank should be awarded.
- In-game test AP spending, missing-AP errors, requirement errors, permanent learned abilities, ability reset, specialization reset, talent reset, pending talent allocation, Confirm, Cancel, Remove, and hover tooltip/link visuals.
- Wire live ability scripts to the relevant `Talents.j` effect helpers where the talents should modify damage, healing, cooldowns, mana, or special behavior.
- Add talent save/load serialization after the current PotS save/load direction is confirmed.
- Import/include `Events/Events.j` before every library that now requires `Events`.
- In World Editor, remove/disable the old `Init 07 Unit Event Enters` GUI trigger after confirming all listed unit-enter callbacks are handled by `Events.j`.
- Add the one-time map-init registration for `gg_trg_Floating_Texts_Spell_Event` if that GUI trigger is still used.
- Stress-test 10-60 minute sessions with heavy ability casting, unit spawning, item pickup/drop/use, AI orders, totems, pets, patrols, camp fires, tents, and reputation hostility.
- Watch especially for missing event callbacks, duplicate callbacks, floating text not firing, rested/base-camp/camp-fire behavior regressions, and death cleanup regressions.

## [21.7.2026]

### Player-Facing Updates
- Profession crafting sounds should now be audible again:
  - Player-started crafting uses normal sound playback.
  - AI-started crafting uses 3D sounds on the crafting station unit.
- AI profession crafting is less likely to be interrupted by normal AI side behavior while walking to the workstation; combat can still interrupt AI-started crafting.
- Picking herbalism item nodes now plays `Tradeskill_HerbPick` as a 3D sound on the picking unit.

### Technical Updates
- `StatsLiteUI.j`
  - Dead detection now also respects udg_IsUnitAlive[unitId] and UNIT_TYPE_DEAD, not just widget life.
  - Revive remaining seconds are centralized through SLUI_GetReviveRemainingSeconds, including Zul'kis’ udg_ReviveTimerZulkis.
  - Row cache now tracks revive countdown changes, so Dead (Xs) refreshes while the timer ticks.

- `UI/Interface.j`
  - Added `EVENT_TRADESKILL_HERB_PICK` and `Interface_NotifyHerbPickOnUnit`.
  - Profession and gather feedback sounds no longer force the old feedback sound channel before playback, avoiding muted/quiet playback under cinematic volume handling.

- `GatherSystems/GatherNodeItems.j`
  - Added explicit `Interface` dependency and herbalism-success pickup sound playback.

- `Professions/Professions.j`
  - AI profession jobs now prefer label-created 3D station sounds before falling back to shared sound handles, while player jobs keep direct playback.
  - AI station travel timeout increased from 8 seconds to 60 seconds.
  - AI craft preparation now reissues the station move if another order interrupts the walk.
  - Added `Professions_IsUnitAiCrafting` and `Professions_CancelUnitCraft` for AI reservation handling.

- `AI/AI.j`
  - Reserved profession jobs now hold normal AI side actions until the craft starts/finishes.
  - AI-started crafting is cancelled and backed off when nearby combat appears, so combat behavior can take over cleanly.

- `Preload/PreloadAbilities.j`
  - Consolidated the duplicate ability preloader into the `Preload` folder and removed the stale `InitRelated/PreloadAbilities.j` copy.
  - Kept the missing Craft (Fake Cast) preload rawcode `A6DY` while consolidating.


## [20.7.2026]

### Player-Facing Updates

- Camp fires now grant rested XP progress to nearby heroes based on the registered camp-fire radius, even if the Warmth aura buff/status is not visible on the hero.
- Rested now uses the hidden `S000` ability instead of Acid Bomb, so it no longer creates 0-damage combat events.
- Tent time skipping and rested progress now start from the tent's Sleep ability (`A0F2`) instead of starting automatically when a hero is loaded.
- Tent Sleep now requires Nazgrek or Zul'kis to be inside the tent before it does anything, and the other player-owned hero is paused/hidden during the sleep if they are outside the tent.
- Dismantling a tent now returns only one Tent item when the JASS BaseCamp system runs alongside a still-enabled legacy GUI dismantle handler.

### Technical Updates

- `Leveling/AbilityPoints.j`
  - Added the new centralized AbilityPoints library for Nazgrek and Zul'kis.
  - Ability points are now tracked through the JASS API instead of the legacy GUI globals:
    - `AbilityPoints_Get`
    - `AbilityPoints_Set`
    - `AbilityPoints_Add`
    - `AbilityPoints_Reduce`
    - `AbilityPoints_Spend`
  - Moved the old "Hero Levels Up" behavior into JASS for player hero AP gain, level-up text, HP/mana refill, and companion group-size synchronization.
  - Added a temporary enable/disable API for the JASS "Hero Levels Up" handling:
    - `AbilityPoints_SetHeroLevelUpEnabled`
    - `AbilityPoints_DisableHeroLevelUp`
    - `AbilityPoints_EnableHeroLevelUp`
    - `AbilityPoints_IsHeroLevelUpEnabled`
  - Added Reset Abilities item handling for `I6A1`, replacing the hero, preserving inventory/equipment through the DInventory/DItemTransfer hooks when available, and resetting AP to hero level + 3.
  - Added Player 1 debug chat command `/debug ap add`, which adds 1 AP to both Nazgrek and Zul'kis through the new AbilityPoints state.
  - Updated `StatsUI.j` to read AP through `AbilityPoints_Get` instead of `udg_AbilityPointsNazgrek` / `udg_AbilityPointsZulkis`.

- `Leveling/Experience.j`
  - Added the new centralized Experience library for rested XP, bonus XP, and XP multiplier application.
  - Rested state is now backed by the hidden Rested ability rawcode `S000` instead of the old Acid Bomb buff.
  - Added MUI resting-progress tracking so camp fires and tents can grant rested progress without singleton GUI timers.
  - Rested no longer uses `A6AI` / Acid Bomb, avoiding 0-damage periodic Acid Bomb events and AI combat-state side effects.
  - Rested duration is now tracked in JASS; the system hides `S000` from the unit command UI, removes it when its timer expires, and exposes `Experience_ClearRested`, `Experience_GetRestedRemaining`, and `Experience_GrantRestedTimed`.
  - Bonus XP now adds the extra hero XP without vanilla eye candy and displays its own offset `+X Bonus XP` texttag so it does not overlap the normal Warcraft XP popup.
  - Added bonus XP multiplier APIs:
    - `Experience_GetBonusMultiplier`
    - `Experience_GetTotalMultiplier`
    - `Experience_SetBonusMultiplier`
    - `Experience_AddBonusMultiplier`
    - `Experience_RegisterBonusItem`
    - `Experience_ApplyMultiplier`
  - Added hero XP delta handling through `UnitDeathEvent`, replacing the old GUI rested/bonus XP death trigger pattern for Nazgrek and Zul'kis.
  - Added a first-pass registered bonus XP item hook for the Crown of Kings rawcode (`ckng`) as a configurable item-multiplier example.

- `Leveling/BaseCamp.j`
  - Added the new BaseCamp library for tent/base-camp behavior.
  - Added MUI tent tracking, one-tent-per-player checks, Sleep-started loaded-hero resting, time-of-day fast-forward while resting, tent dismantle handling, and tent death cleanup.
  - Tent resting now delegates rested progress and buff application to `Experience.j`.
  - Tent loading now only registers the tent/passenger state; Sleep (`A0F2`) starts the actual rest records.
  - Sleep rejects empty tents, starts records for loaded Nazgrek/Zul'kis, hides and pauses any other tracked player hero outside the tent, and restores their previous pause/visibility state when sleep ends or the tent is removed.
  - Tent Dismantle (`A02X`) now queues delayed carried-item creation and checks for an existing nearby Tent item first, preventing duplicate items when legacy GUI dismantle still creates one.
  - One-tent-limit hints use `HintsUI` when available and fall back to player text otherwise.

- `Leveling/CampFire.j`
  - Reworked CampFire into a proper JASS library instead of the old singleton timer/index implementation.
  - Camp fires now register on construction, receive Warmth/Warmth HP/Warmth Mana abilities, get timed life, create their light helper, and clean up nearby light helpers on death.
  - Camp-fire registration now applies Warmth abilities, timed life, and the light helper from the shared `CampFire_Register` / `AddCampfire` path, so old GUI calls and AI-created camp fires receive the same 60 second lifetime setup.
  - Nearby alive heroes inside registered camp-fire radius now gain rested progress through `Experience_AddRestingProgress`; rested progress no longer depends on the Warmth buff being visible.
  - Camp fire/tent build channeling is blocked while the builder is in combat, using `HintsUI` when available.
  - Kept legacy wrappers `AddCampfire`, `RemoveCampfire`, and `InitCampFireBuffSystem` for compatibility with older calls.

- `Preload/PreloadAbilities.j`
  - Added preloading for Sleep (`A0F2`), Build Camp Fire (`A61P`), Rested (`S000`), and Warmth abilities (`S600`, `A02W`, `A02Y`) alongside tent build/dismantle abilities.

- `UnitSystems/UnitExperience3.j`
  - Added optional `Experience` support so registered custom unit XP can apply the centralized XP multiplier through `Experience_ApplyMultiplier`.

- `Professions.j`
  - Changed crafting camera parameters
  - Also changed rotation so the camera is placed from the crafter’s side of the workstation after the cinematic mover has snapped the unit near the station, instead of using a fixed station-facing offset.

- `AI.j`
  - Added autonomous shop-state initiation for idle/wandering autonomous AI:
    - full inventory now tries to start shop sell
    - empty inventory can randomly start shop buy
    - shop checks run on a per-instance cooldown so AI units do not all start shopping at once
  - Added AI shop debug chat commands:
    - `/debug aibuy` or `aibuy` to force eligible AI units into buy state
    - `/debug aisell` or `aisell` to force eligible AI units into sell state
    - `/debug aishop` or `aishop` to force inventory-based buy/sell selection
  - Added public debug APIs:
    - `AI_DebugForceShopBuy()`
    - `AI_DebugForceShopSell()`
    - `AI_DebugForceShopByInventory()`
  - Tightened shop sell fallback so profiles with configured shops no longer sell/drop at the current position just because no live shop target was selected.

### Known Issues

- Full in-map JassHelper / Warcraft III compile validation was not completed in this pass because the repo snapshot does not expose a combined `war3map.j` or normal map build entry point.
- The old GUI triggers under `Leveling/_oldGUI` must be disabled after these libraries are imported, otherwise AP/rested/base-camp/camp-fire behavior can double-run or conflict.
- The tent death animation still uses a configurable first-pass death-animation unit rawcode and should be verified in-game against the intended tent death visuals.
- Tent Sleep and the delayed dismantle-item fallback still need in-game validation with both legacy GUI handlers enabled and disabled.
- AI shop buy/sell initiation and the `/debug aibuy`, `/debug aisell`, and `/debug aishop` commands still need in-map validation with real registered shop units and full/empty AI inventories.

### Actions Remaining

- Import/include `Leveling/AbilityPoints.j`, `Leveling/Experience.j`, `Leveling/BaseCamp.j`, and the updated `Leveling/CampFire.j` in the active map build order.
- In-game test normal hero leveling, Reset Abilities (`I6A1`), camp fire rested progress, Sleep-started tent resting/time skip, single-item tent dismantle, tent death cleanup, and bonus XP item pickup/drop.
- Test Sleep (`A0F2`) with Nazgrek only, Zul'kis only, both heroes inside, and no hero inside to confirm outside-hero hide/restore and no-op behavior.
- Debug-testing reminder: use `/debug ap add` to verify both Nazgrek and Zul'kis gain AP and that the AP UI/legacy globals update correctly.
- Test `AbilityPoints_DisableHeroLevelUp()` and `AbilityPoints_EnableHeroLevelUp()` around scripted level changes to confirm temporary level-up suppression works as intended.

## [19.7.2026]

### Player-Facing Updates

- Profession workstations can now open a custom frame crafting panel instead of relying on unit spellbook command cards.
  - Alchemy opens from nearby Cauldron units (`n61D`).
  - Blacksmithing opens from Anvil units (`n62R`).
  - Mining smelting opens from Forge units (`n62S`).
  - Leatherworking opens from Tannery units (`n625`).
  - Cooking workstation hooks are registered for Camp Fire (`n61C`) so recipes can be added later.
- The new crafting panel lists workstation recipes, required skill, material readiness, crafting time, and current availability state.
- Starting a player craft now reserves the workstation, enters cinematic mode, uses a 0.5 second fade-out/fade-in reposition to place only the nearest tracked hero close to the workstation, starts the craft only after the setup sequence completes, and reopens the related CraftingUI after completion.
- AI units with matching profession profiles can now occasionally use nearby profession stations as cheat-crafting jobs, with per-profession toggles for whether AI ignores recipe materials.
- AI night camping now creates a finished camp fire directly on nearby walkable terrain instead of relying on a temporary Camp Fire item-use order, so eligible AI units can actually start camp when night camping is forced or rolled.
- AI gather-node orders are now blocked before movement or attack starts when the AI lacks the profile profession, current skill, required tool, or inventory room for that node, preventing repeated low-skill attempts such as Paladin attacking Tin Veins.
- Profession crafting start/loop/finish sounds now use direct playback for player crafts and 3D workstation playback for AI station crafts, including Tannery, Forge smelting, Anvil, and Cauldron flows.
- Mining gather ore-node hits now play the imported MiningHit sound handles as 3D feedback at the mined node when struck with a Mining Pick.
- Profession station sound handles are now centralized in `UI/Interface.j` as `Interface_Profession_*_Start`, `Interface_Profession_*_Loop`, and `Interface_Profession_*_End` globals.
- Crafting camera settings now use a closer `qAradion`-style DialogCamera setup with full farZ, and the camera switch happens during the black fade after CinematicMover places/faces the crafter.
- Crafting work animations are refreshed during the craft and reset to Stand when the craft ends or is cancelled.
- Crafted output now tries to enter DInventory first, then vanilla inventory, before falling back to a ground drop at the workstation.
- Alchemy cauldrons now get the passive Light Effect ability (`A6DJ`) during crafting, keep the light/Stand phase for 60 seconds after crafting, play Death for 120 seconds, and then switch to Decay.
- Alchemy recipes are now grouped in the custom CraftingUI by the workbook categories:
  - Basic Alchemy: Spring Water, Crystal Water, Healing Salve, Greater Healing Salve, Minor Replenishment Potion, Replenishment Potion, and Greater Replenishment Potion.
  - Basic Potions: Minor Healing Potion, Healing Potion, Greater Healing Potion, Major Healing Potion, Minor Mana Potion, Mana Potion, Greater Mana Potion, Major Mana Potion, Restoration Potion, and Greater Restoration Potion.
  - Utility Potions: Potion of Invisibility, Potion of Speed, Potion of Lesser Invulnerability, Potion of Divinity, and Anti-Magic Potion.
  - Flasks: Nazgrek's Flask.
- Blacksmithing now has first-pass Copper Chain armor recipes from the old workbook / GUI draft, using Copper Bars as material costs and the Apprentice Blacksmithing -> Copper Armor category path.
- Leatherworking now has first-pass Reinforced Leather recipes from the old Tannery GUI draft under the Apprentice Leatherworking -> Reinforced Leather category path:
  - Reinforced Leather Belt
  - Reinforced Leather Boots
  - Reinforced Leather Chestpiece
  - Reinforced Leather Gloves
  - Reinforced Leather Helmet
  - Reinforced Leather Shoulderpads
- Mining now supports basic smelting recipes:
  - Copper, Tin, Silver, Iron, Gold, Mithril, Arcanite, and Thorium Ore into their Bar versions.
  - Bronze Bar from Copper Bar + Tin Bar.
  - Steel Bar from Iron Bar + Coal.

### Technical Updates

- `Professions/Professions.j`
  - Added the central profession crafting registry and executor.
  - Added APIs for workstation registration, recipe registration, material registration, recipe lookup, station lookup, crafting start checks, material counting, and profession summary text.
  - Added recipe category and subcategory metadata APIs so profession sublibraries can expose workstation recipe paths such as Alchemy category lists or later Blacksmithing tier -> group lists.
  - Crafting jobs now reserve crafter and station immediately, run player or AI preparation first, consume materials only when the actual craft begins, create the output item on completion, prefer inventory delivery, and award profession skill through `GatherNodeSkills`.
  - Material checks support the custom DInv inventory helpers when `SharedDInvLib` is present, with vanilla inventory fallback.
  - Crafted item creation uses `ItemHook_CreateItem` when `ItemHook` is present, with normal `CreateItem` fallback.
  - Added workstation busy/crafter busy guards so the same station or crafter cannot run overlapping jobs.
  - Added profession sound label and sound-handle support, now preferring `Interface_Profession_*` sound handles and routing player crafts through direct playback while AI crafts attach 3D playback to the station.
  - Added timed-craft cinematic handling using `DialogCamera`, `CinematicMover`, quick black fades, and cinematic mode depth tracking; the DialogCamera now starts after fade-out and mover placement.
  - Added a per-job work-animation loop timer so crafter/station work animations keep playing during timed crafts and are cleaned up on finish/cancel.
  - Added profession-configured crafter animation strings, unit-type-specific crafter animation overrides, per-profession AI cheat-crafting toggles, and AI craft recipe lookup helpers.
  - Added `A6DY` Craft (Fake Cast) handling: the ability is added to the crafter, self-cast with the Inner Fire order, and removed when the craft ends or is cancelled.
  - Added Alchemy cauldron feedback using the existing `A6DJ` Light Effect ability, station animation changes, and delayed decay animation.
  - Alchemy cauldron delayed timers are generation-guarded so starting a new craft prevents older light-removal or decay timers from affecting the active cauldron.
  - Added short globals-section comments for registry state, recipe data, material data, active jobs, sound labels, and lookup tables.

- `Professions/Professions*.j`
  - Moved per-profession Start / Loop / Finish sound labels into configurable globals constants.
  - Registered Interface-owned profession sound handles for Alchemy, Blacksmithing, Leatherworking, and Mining where existing sound variables are available.
  - Registered per-profession AI cheat-crafting toggles and crafter animation defaults.
  - Added short globals-section comments for runtime guards, workstation raw codes, sound label config, recipe raw codes, and icon paths.
  - WIP profession modules use empty sound label constants until their actual sound assets and crafting flows are defined.

- `Professions/ProfessionsAlchemy.j`
  - Registered the Cauldron workstation and Alchemy start/loop/finish sound labels:
    - `CauldronSound`
    - `CauldronSound`
    - `Tradeskill_AlchemyEnd`
  - Expanded Alchemy from the first-pass six recipes into the concrete `ALCHEMY` / `alchemy_help` workbook recipe set.
  - Corrected the workbook material requirements for Crystal Water, Healing Salve, Greater Healing Salve, and Minor Healing Potion.
  - Assigned every registered Alchemy recipe to Basic Alchemy, Basic Potions, Utility Potions, or Flasks.
  - Left later placeholder or material-less potion/flask ideas unregistered until their item rawcodes and material requirements are intentionally defined.

- `Professions/ProfessionsBlacksmithing.j`
  - Registered the Anvil workstation and first-pass Copper Chain armor recipes.
  - Assigned Copper Chain recipes to the Apprentice Blacksmithing -> Copper Armor category path.
  - Preserved the old GUI crafting time pattern of 5 seconds.
  - Added first-pass Copper Bar costs so the recipes are usable through the new material system instead of free spellbook casts.

- `Professions/ProfessionsMining.j`
  - Registered the Forge workstation for smelting only.
  - Added Ore -> Bar recipes without changing the existing gather-node Mining systems.
  - Added Arcanite Ore -> Arcanite Bar smelting from the exported item rawcodes.
  - Added confirmed Bronze Bar and Steel Bar alloy smelts from the current item rawcodes.

- `Professions/ProfessionsLeatherworking.j`
  - Registered the Tannery workstation and first-pass Reinforced Leather recipes from the old GUI trigger.
  - Assigned Reinforced Leather recipes to the Apprentice Leatherworking -> Reinforced Leather category path.
  - Preserved the old GUI crafting time pattern of 5 seconds.
  - Registered the old Tannery sound label for start/loop/finish playback.
  - Material requirements are intentionally still empty because the old GUI trigger did not define material checks.

- `Professions/ProfessionsCooking.j`, `Professions/ProfessionsSkinning.j`, `Professions/ProfessionsEnchanting.j`, and `Professions/ProfessionsFishing.j`
  - Added profession sublibrary placeholders / workstation hooks where the profession start event is already known.
  - These files are intentionally light until each profession's actual crafting rules are defined.

- `UI/CraftingUI.j`
  - Added the shared custom-frame crafting UI.
  - The UI opens from workstation selection, pulls recipe data through `Professions.j`, and uses the nearest tracked hero to the station as the active crafter.
  - Added category/subcategory browsing using the shared recipe metadata, with category state preserved when the panel reopens after a craft.
  - Added recipe rows, selected recipe detail view, material readiness display, Prev/Next paging, Craft, Return, and Close controls.
  - Crafting success hides the panel during the cinematic craft, refreshes `ProfessionsUI` summary data, and reopens the station panel when the job finishes.
  - Moved the Craft button slightly upward in the panel layout.

- `Cinematic/CinematicMove.j`
  - Added single-unit cinematic move/return helpers so profession crafting can use CinematicMover without moving companions, pets, or other tracked units.
  - Added an explicit point-targeted single-unit move helper for workstation close-up crafting sequences.

- `AI/AI.j` and selected `AI/Classes/AI_*.j`
  - Extended AI profession IDs to match `GatherNodeSkills` through Cooking.
  - AI side profession work can now find nearby reserved-free profession stations and start a random eligible recipe through `Professions_StartRecipeForAi`.
  - Added Blacksmithing to Engineer/Warrior profiles, Alchemy to Restoshaman, and Leatherworking to Rogue.
  - Added `/debug aicraft` / `aicraft` to force eligible active AI units to start a nearby station craft, randomizing among the professions available to each unit.
  - Night camp placement now requires `CampFire` and creates/registers the finished `n61C` camp-fire unit directly, adding Warmth abilities (`S600`, `A02W`, `A02Y`), `n619` light, timed life, `AddCampfire`, and cleanup instead of using `I611` through `UnitUseItemPoint`.
  - AI profession refresh now only registers matching profession-profile units with `GatherNodeSkills`; it no longer derives or raises profession skill from hero/unit level.
  - Added an AI target-order guard for active gather items and gather units so invalid profile, skill, tool, or inventory requirements stop the order and apply profession backoff before the unit reaches or attacks the node.

- `UI/Interface.j`
  - Mining hit and profession feedback sounds now prefer imported `gg_snd_*` handles over `CreateSoundFromLabel` fallback paths.
  - Added a direct profession sound playback helper for player crafting and kept station-attached 3D playback for AI/station feedback.
  - Added central feedback sound channel/volume configuration for mining and profession sounds.

- `Preload/PreloadAbilities.j`
  - Added `A6DY` to ability preloading for the shared Craft (Fake Cast) behavior.

- `UI/ProfessionsUI.j`
  - Now requires `Professions`.
  - Profession detail text now appends crafting summary data from `Professions_GetProfessionSummary`.
  - Detail body cache invalidation now includes the `Professions` recipe revision.
  - `ProfessionsUI` still reads profession crafting data only through the central `Professions.j` API, not direct `ProfessionsXXX.j` sublibrary calls.

- `UI/MasterUI.j`
  - `MUI_HideAllPanels` now also hides `CraftingUI`.

### Known Issues

- Full in-map JassHelper / Warcraft III compile validation was not completed in this pass because the repo snapshot does not expose a combined `war3map.j` or normal map build entry point.
- The bundled `pjass` only validates plain JASS and is not a useful validator for these vJASS libraries by themselves.
- Blacksmithing Copper Bar material costs are first-pass design values because the old workbook / GUI draft lists the Copper Chain outputs but not final material requirements.
- Leatherworking Reinforced Leather recipes currently match the old Tannery GUI trigger and therefore have no material requirements yet.
- The Alchemy workbook still contains material-less or unresolved rows such as Purified Water, Vampiric Potion, Elixir of Might, Elixir of Shadows, and the non-Nazgrek flask ideas. Those recipes are intentionally not registered until their live item rawcodes and material requirements are confirmed.
- Fel Iron Vein exists in the current gather-node exports, but `Fel Iron Ore` and `Fel Iron Bar` item rawcodes are not present in the visible item/WTS exports yet, so Fel Iron smelting is still pending item data.
- Direct AI-created camp fires still need in-game validation for `/debug aicamp`, Warmth/rested registration, light cleanup, and normal autonomous night-camp timing.
- Low-skill/wrong-profession AI gather-node blocking still needs in-game retesting around Tin Vein and gather-item nodes, especially with companion/player-issued target orders.

### Actions Remaining

- Import/include the new `UI/CraftingUI.j` and `Professions/Professions*.j` files in the actual map build order.
- Run the full map compile after the new libraries are added to the active import/build pipeline.
- In-game test workstation selection, range checks, material consumption, crafting completion, skill gain, and Alchemy cauldron light/sound/animation timing.
- Re-test `/debug aicamp` at night and normal AI night-camp rolls across common terrain.
- Re-test Paladin and other low-skill/wrong-profession AI near Tin Vein and gather-item nodes to confirm blocked orders no longer short-loop.
- Define final material requirements and skill thresholds for the remaining Alchemy, Blacksmithing, Leatherworking, Cooking, Enchanting, Fishing, and Skinning crafting flows.

## [18.7.2026]

### Technical Updates

- `Voicelines/Voicelines.j`
  - Added the new base voiceline helper library.
  - `Voicelines.j` now requires `ExSound` and exposes the shared game path root:
    - `VOICELINES_GAME_ROOT = "Pots\\Sound\\Voicelines\\"`
  - Added helper APIs for speaker libraries and future consumers:
    - `Voicelines_RegisterKey`
    - `Voicelines_RegisterKeyInSubfolder`
    - `Voicelines_RegisterPaddedSequence`
    - `Voicelines_RegisterUnpaddedSequence`
  - The base library intentionally does not require every speaker library. Speaker and consumer libraries require only the voiceline libraries they actually use.
  - This keeps import dependencies simpler and avoids making one huge master library responsible for every possible speaker.

- `Voicelines/Voicelines_*.j`
  - Created/expanded speaker-owned JASS voiceline constant libraries as the runtime source of truth for voiceline keys and text.
  - Each speaker file owns its own `VL_<SPEAKER>_*_KEY` and `VL_<SPEAKER>_*_TEXT` constants.
  - Added folder constants such as `VL_ARADION_FOLDER`, `VL_VALERIA_FOLDER`, and similar speaker-specific folder mappings so tooling and runtime code can keep disk/game folder names explicit.
  - Existing active Aradion, Valeria, and Nazgrek dialog constants were preserved and expanded with missing legacy Excel draft/reference rows.
  - Aradion and Valeria AI profile bark ranges are now also represented in their speaker libraries:
    - `Aradion_0181` through `Aradion_0312`
    - `Valeria_0181` through `Valeria_0312`
  - New or expanded speaker libraries now include:
    - `Voicelines_Aradion.j`
    - `Voicelines_AtexBlix.j`
    - `Voicelines_Aveline.j`
    - `Voicelines_BoomBrothers.j`
    - `Voicelines_CompanionReplies.j`
    - `Voicelines_DarkShaman.j`
    - `Voicelines_Demoness.j`
    - `Voicelines_Engineer.j`
    - `Voicelines_Garthork.j`
    - `Voicelines_Granis.j`
    - `Voicelines_GrumBloodfang.j`
    - `Voicelines_GrumBloodfangOld.j`
    - `Voicelines_HumanFemale1.j`
    - `Voicelines_Jinzun.j`
    - `Voicelines_Kaelthir.j`
    - `Voicelines_Krezgrel.j`
    - `Voicelines_Kribugs.j`
    - `Voicelines_Mordrax.j`
    - `Voicelines_Narrator.j`
    - `Voicelines_Nazgrek.j`
    - `Voicelines_OrcGrunt.j`
    - `Voicelines_OrcPeon.j`
    - `Voicelines_OrcQGiver.j`
    - `Voicelines_Paladin.j`
    - `Voicelines_RestoShaman.j`
    - `Voicelines_Rogue.j`
    - `Voicelines_Satyr.j`
    - `Voicelines_Serenthia.j`
    - `Voicelines_Shipmaster.j`
    - `Voicelines_Thork.j`
    - `Voicelines_UndeadWarlock.j`
    - `Voicelines_Valeria.j`
    - `Voicelines_VoidEntity.j`
    - `Voicelines_Warlock.j`
    - `Voicelines_Warrior.j`
    - `Voicelines_Zulkis.j`
  - `HeroReplyLines` is intentionally not a standalone speaker library. Reply text is split by responder libraries and shared companion reply glue, because the runtime speaker is the responder, not the primary line starter.
  - `GrumBloodfangOld` exists as a constants-only placeholder library because there is an external master audio folder for the old files, but no matching Excel draft text was mapped to it yet.
  - `Kribugs` was added as a draft JASS speaker library from Excel even though no current external master audio folder exists for it. It is now visible to scan/generation as missing audio.
  - Existing active speaker libraries with initializers still register only the active keys they already used. Newly imported draft/reference constants are mostly constants-only until runtime consumers intentionally wire them in.

- AI voiceline migration
  - Moved AI class bark, companion chat, companion reply, and Aveline-specific voiceline text out of active AI behavior files and into `Voicelines_*.j` helper libraries.
  - Updated active AI files to require the voiceline libraries they use instead of carrying raw key/text literals:
    - `AI/AI.j`
    - `AI/AI_CompanionReplies.j`
    - `AI/AI_Voicelines.j`
    - `AI/Classes/AI_Engineer.j`
    - `AI/Classes/AI_Paladin.j`
    - `AI/Classes/AI_Restoshaman.j`
    - `AI/Classes/AI_Rogue.j`
    - `AI/Classes/AI_Warlock.j`
    - `AI/Classes/AI_Warrior.j`
    - `AI/Specific/AI_Aradion.j`
    - `AI/Specific/AI_Aveline.j`
    - `AI/Specific/AI_Valeria.j`
  - AI behavior logic remains in the existing AI files. Only text/key ownership moved into the voiceline libraries.
  - `AI_Aradion.j` and `AI_Valeria.j` now require their speaker libraries and register profile barks through `VL_ARADION_*` and `VL_VALERIA_*` constants instead of duplicated raw strings.
  - `AI/AI_Voicelines.j` now requires the relevant speaker voiceline libraries for the active bark/chat pools.
  - `AI/AI.j` now requires the voiceline libraries needed by special AI dialogue checks that previously used raw string constants.
  - `Voicelines_CompanionReplies.j` now owns shared primary-key, responder-name, prefix, and fallback constants used by `AI_CompanionReplies.j`.
  - `Voicelines_UndeadWarlock.j` owns the Undead Warlock responder reply constants that target the `HeroReplyLines\HeroWarlockReplyLines` audio folder.

- `QuestsAndDialogs/QuestGivers/qAradion.j`
  - Replaced duplicated raw Aradion, Valeria, and Nazgrek voiceline key/text literals with constants from:
    - `VoicelinesAradion`
    - `VoicelinesValeria`
    - `VoicelinesNazgrek`
  - `qAradion` now requires only the speaker voiceline libraries it uses.
  - This reduces the chance of typo drift between quest dialogue text, generated audio filenames, and ExSound playback keys.
  - This is a high-risk change for the Aradion quest chain because it touches dialogue sequence text/key references without changing the quest logic itself. All Aradion dialog paths must be retested in-game.

- `SoundAndMusic/ExSound.j`
  - Added duplicate-safe registration behavior so registering the same sound key more than once no longer duplicates preload keys.
  - Added folder-based registration helpers used by the new voiceline base library and scanner:
    - `ExSound_RegisterKeyInFolder`
    - `ExSound_RegisterUnpaddedSequence`
  - Added explicit registrations for Undead Warlock reply-line keys that live under `Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\`.
  - Existing sound playback APIs remain unchanged.

- `Voicelines/VoicelinesInfo.md`
  - Filled out the voiceline workflow documentation.
  - Documented that JASS `Voicelines_*.j` libraries are the runtime source of truth.
  - Documented that `Voicelines/_oldExcel/VoicelinesMaster.xlsx` is legacy draft/reference data only.
  - Documented that repo-side `Voicelines/<SpeakerFolder>/` directories are reference-only and must not be treated as scanner input, generation output, or canonical audio storage.
  - Documented the external master audio root:
    - `H:\Pelit\WC3_PotS_Files\001 OFFICIAL FILES\Pots\Sound\Voicelines`
  - Documented that FishAudio generation must write only into:
    - `tools/temp/fishaudio-review`
  - Documented scanner, import, and generation commands.
  - Documented the split between real `excel_only` draft text and blank Excel filename placeholders.

### Tool Updates

- `tools/voicelines.ps1`
  - Added the main voiceline scan/generation tool.
  - Defaults:
    - `-MasterRoot "H:\Pelit\WC3_PotS_Files\001 OFFICIAL FILES\Pots\Sound\Voicelines"`
    - `-TempRoot "tools/temp/fishaudio-review"`
    - `-ExcelPath "Voicelines/_oldExcel/VoicelinesMaster.xlsx"`
    - `-Manifest "tools/temp/voicelines/voicelines-scan.csv"`
  - `-Mode Scan` compares:
    - JASS voiceline constants/registrations
    - Excel draft/reference rows
    - external master audio files
    - temp FishAudio review files
  - The scan report is disposable generated output under ignored `tools/temp/`. It is not source of truth and should not be manually edited.
  - Scan report flags now include:
    - `present_in_master`
    - `pending_review`
    - `missing_audio`
    - `excel_only`
    - `excel_only_blank_text`
    - `jass_only`
    - `duplicate_key`
    - `duplicate_text_variants`
    - `orphan_audio`
    - `folder_mismatch`
  - `excel_only` now means an Excel row with real draft text that has no matching JASS constant.
  - `excel_only_blank_text` means an old workbook filename placeholder with no text.
  - Added explicit folder/prefix handling for cases where disk folders and JASS keys differ:
    - `Aradion` -> `AradionFarseer`
    - `Boomers` -> `BoomBrothers`
    - `HeroShaman` -> `HeroRestoshaman`
    - `HeroUndeadWarlock` -> `HeroWarlock`
    - `OrcGrunt` -> `Orc Grunt`
    - `OrcPeon` -> `Orc Peon`
    - `Peon_####` Excel drafts -> `OrcPeon_####`
    - `XXX_####` -> `OrcQGiver`
  - Added special folder inference for AI hero chat/reply lines:
    - primary AI chat folders such as `HeroWarrior\ChatLines`
    - reply folders such as `HeroReplyLines\HeroWarlockReplyLines`
  - `-Mode Generate` sends only missing JASS-backed lines to FishAudio.
  - FishAudio output always goes to `tools/temp/fishaudio-review/<SpeakerFolder>/<FileName>.mp3`.
  - The tool intentionally does not copy files into the external master folder. Review/listening and master copying remain manual.
  - Generation skips rows already present in the external master folder.
  - Generation skips pending review files unless `-Force` is used.
  - Generation skips rows with duplicate text variants until the text ambiguity is resolved.
  - Optimized scan construction by indexing JASS and Excel rows by key before building the final report. Scan time dropped from roughly two minutes to roughly five seconds on the current dataset.

- `tools/voicelines-import-excel.ps1`
  - Added a repeatable importer for migrating remaining text-backed workbook draft rows into JASS constants.
  - Dry run reports how many rows would be imported, skipped because they already exist in JASS, skipped because they have no text, or skipped because no speaker mapping exists.
  - `-Apply` creates missing speaker libraries and appends only missing Excel-backed rows to existing speaker libraries.
  - Existing JASS constants are preserved and never overwritten by older Excel text.
  - Old Excel `Peon_####` names are canonicalized to `OrcPeon_####` because the master audio files already use `OrcPeon_####`.
  - Original Excel filenames are kept in generated comments when canonicalized, so the old workbook can still be traced.
  - Imported rows are grouped with compact comments containing workbook sheet, quest, event, done, and comment metadata where available.
  - After applying the import, a dry run reports:
    - `imported_rows: 0`
    - `skipped_existing_jass: 1007`
    - `skipped_no_text: 1313`
    - `skipped_no_speaker_mapping: 0`
  - This confirms every mapped Excel row with real draft text is now represented in JASS.

### Imports

- External master voice audio handling
  - The authoritative generated-audio scan root is now the external master folder:
    - `H:\Pelit\WC3_PotS_Files\001 OFFICIAL FILES\Pots\Sound\Voicelines`
  - Current scan sees `2605` `.mp3`/`.wav` files in the external master root.
  - The scanner currently reports:
    - `total_rows: 3729`
    - `present_in_master: 2181`
    - `pending_review: 0`
    - `missing_audio: 283`
    - `excel_only: 0`
    - `excel_only_blank_text: 1271`
    - `jass_only: 1368`
    - `duplicate_text_variants: 14`
    - `orphan_audio: 120`
    - `folder_mismatch: 455`
  - Repo-side `Voicelines/<SpeakerFolder>/` directories are kept only as reference folders. They are not used as canonical generated-audio folders and are not generation output targets.

### Known Issues

- This is a large voiceline source-of-truth migration and can break runtime behavior if the new libraries are not imported in the right order or if any consumer is missing a required speaker library.
- A full JassHelper/WC3 compile was not completed during this changelog update. All changed JASS import dependencies must be validated in the normal map build workflow.
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

### Actions Remaining

- Run the full WC3/JassHelper compile/import workflow with all new `Voicelines_*.j` libraries included.
- Confirm the import order:
  - `ExSound.j`
  - `Voicelines.j`
  - required `Voicelines_*.j` speaker libraries
  - consumers such as `qAradion.j`, `AI.j`, `AI_Voicelines.j`, and `AI_CompanionReplies.j`
- Run:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines.ps1 -Mode Scan`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines.ps1 -Mode Generate -DryRun -MaxCount 3`
- Resolve duplicate text variants before real FishAudio generation, especially missing `Thork_0012`.
- When FishAudio credentials are available, generate only a very small batch first:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/voicelines.ps1 -Mode Generate -MaxCount 1`
- Confirm generated files appear only under `tools/temp/fishaudio-review`.
- Listen/check review files manually before copying accepted audio into the external master folder.
- Retest qAradion in-game and verify no raw migrated text/key literal was accidentally left behind in active Aradion dialog paths.
- Retest AI bark playback for Warrior, Rogue, Warlock, Undead Warlock, Restoshaman, Paladin, Engineer, Aveline, Aradion, and Valeria.

## [16.7.2026]

### Technical Updates

- `QuestGiver.j`
  - Added reusable unique quest-item cleanup that removes matching item rawcodes from loose map items, unit inventories, and DInventory slots before granting a replacement quest item.
  - DInventory cleanup now deletes the matching DInventory slot, removes the hidden item handle, and refreshes the owning player's DInventory frames.

- `qAradion.j`
  - Tel'anor Rod accept/recovery now uses the QuestGiver unique quest-item grant helper.
  - Fading Sparks completion now removes all Tel'anor Rod copies globally instead of only checking the player hero.

- `StatsLiteUI.j`
  - Mode text anchor now uses that constant instead of the hard-coded 0.004
    - SLUI_ROW_MODE_OFFSET_X = 0.008 (value increased)
  - Now remembers whether the monitor was visible before a cinematic/dialogue UI hide and restores it afterward without playing UI sounds.
  - Restores the config view after cinematic/dialogue if that was the active StatsLite view before hiding.
  - increased only the name-display settings:
    - SLUI_ROW_NAME_WIDTH from 0.120 to 0.145
    - name trim caps from 30/28 to 40
    - extra-long name scale from 0.40 to 0.34

- `MasterUI.j`
  - MasterUI_ShowGameButton() now asks StatsLiteUI to restore its pre-cinematic state, keeping the hide/restore flow centralized around MasterUI.

- `AI.j`
  - Night camping now uses closer random camp-fire placement around the AI unit and retries more placement points before giving up.
  - Added `AI_DebugForceNightCamp()` plus chat commands for forcing eligible AI units to camp at night:
    - `/debug aicamp`
    - `aicamp`
  - AI shop state now keeps an optional shop-unit handle, so invoked sell behavior can move to a selected shop and target the shop unit when dropping/selling an item.
  - Added `AI_AddProfileShopUnitType(profileId, unitTypeId)` so profiles can register shop locations from preplaced shop unit types instead of relying on unstable generated unit globals.
  - Existing AI debug commands to remember:
    - `/debug ai`
    - `/debug aidebug`
    - `/debug aispawn`
    - `aispawn`

- `AI_LegacyLocations.j`
  - Horde/neutral/Riverbane AI profile shop bindings now scan shop unit types (`nmrk`, `o609`, `o62J`, `o61U`) instead of using `udg_Shop[]` or disabled `gg_unit_*` shop globals.

### Tool Updates

- `Installer`
  - Expanded the `Path of the Shaman` Inno Setup installer to package the map zip, required `Pots` local files, and Warcraft III Rebirth mod archives from ignored `Installer/payload` folders.
  - Added manifest-driven installed/to-install version display per installer section, supporting clearer install, update, and repair decisions for map, local files, and Rebirth mod payloads.
  - Corrected Rebirth mod unpacking so only the required inner archive contents are copied into `Warcraft III\_retail_`, without keeping the wrapper folders from `9thRelease.rar` or `FixesLast2023.rar`.
  - Added installer wizard branding support with PotS logo assets, a non-stretched final ready/finished image, and progress-page image rotation from `Installer/assets/install-random`.

### Known Issues

- AI buy/sell states still only run when `AI_BeginBuy` or `AI_BeginSell` is called. The autonomous inventory-full/empty decision that starts those states still needs to be added or wired back in.
- Full in-map/JassHelper validation is still required for the new AI camp-fire placement, forced camp debug command, unit-type shop scan, and shop-targeted sell behavior.

## [15.7.2026] 

### Technical Updates

- `StatsLiteUI.j`
  - The mode text now uses textGap + stateOffset + 0.004, moving it right from the previous - 0.004 position. That is an 0.008 rightward correction from the screenshot state, aimed at visually aligning it under the status text.
  - Increased allowed displayed name length for normal rows and companion rows.
  - Adjusted long-name scaling so names like Companion Aradin the Farseer can fit without changing HP/resource bar settings.

- `ReputationUI.j`
  - Now formats faction status through a wrapper, appending Aggressive during temporary hostility, e.g. Neutral (Aggressive).

- `Interface.j`
  - Now plays mining hit sounds as fresh 3D sound instances attached to the node unit, with cutoff/distance set to 1000.00. `GatherNodeUnits.j` already passes the node via Interface_NotifyMiningHitOnUnit(node), so no change was needed there.

- `MasterUI.j`
  - MasterUI_HideGameButton() now closes the MasterUI-routed panels via the existing MUI_HideAllPanels() path, hides the MasterUI panel itself, and also calls StatsLiteUI_HideForCinematic() so the monitor is covered without changing callers like QuestGiver.

- `qAradion.j`
  - Strengthened `qAradion_TestSpawnManaRifts()` so it now prints slot begin/end markers for ManaRift1/2/3, reports when `CreateUnit` returns non-null, and delays runtime cleanup until after all rift slots and proximity registrations are processed.
  - Fixed the Aradion `Info` dialog path so ending or ESC-skipping the info sequence no longer calls cinematic OFF before returning to dialog choices.
  - Added Rifts delayed-discovery diagnostics for companion setup, including state-skip reasons and whether Valeria/Aradion are controlled after setup.
  - Added a proximity registration count warning if fewer than all three Mana Rift units are registered for ritual range detection.

## [14.7.2026] Part II
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

### Technical Updates

- `qAradion.j`
  - Removed Player(0) ownership checks from qAradion's player-hero resolver. Nazgrek/Zulkis being temporarily owned by the cinematic player during `Cinematic ON` no longer makes qAradion lose the active hero for Tel'anor Rod grants, Rifts companion setup, or dialog fallback resolution.
  - Kept hero ownership restoration out of qAradion. Ownership restore remains handled by the existing GUI `Cinematic OFF` trigger, preserving the intended cinematic trigger order.
  - Added a temporary Elarindor hostility gate to Aradion selection so Aradion dialog cannot be opened while the player is temporarily hostile with Elarindor.
  - Hardened `Rifts of Corruption` accept setup: field companions now sync unit refs before resolving the leader, and Valeria is unpaused / made vulnerable before being placed behind the hero and ordered toward her Rifts intro position.
  - Simplified Mana Rift creation so slots 1, 2, and 3 all use the same direct `CreateUnit` path from their own `gg_rct_ManaRift1/2/3` rect centers. qAradion stores each created unit in `RiftsUnits[]`, owns them by Neutral Passive, and discards them from CreepRespawn.
  - Made initial Mana Rift setup non-destructive: `CreateInitialRiftUnits` no longer removes existing stored rift units before ensuring the three slots exist.
  - Refactored dialog selection, greeting, info-sequence reopen, transition startup, and quest setup calls to use shared `QuestGiver` APIs instead of local qAradion boilerplate.
  - Rifts intro Valeria movement now uses a configured range around Aradion instead of `gg_rct_ValeriaNewPos`; if Valeria is already near Aradion she is only ordered to move to her relative spot instead of being repositioned.
  - Rifts delayed-discovery handling now starts the Rifts field phase: it resets/re-registers all three Mana Rift slots, adds Aradion and Valeria to the companion group, enables Rifts failure triggers, and starts the Rifts field monitor only when QuestMaster fires the delayed quest-discovered event.
  - Rifts failure reset no longer recreates Mana Rifts immediately; retrying/discovering `Rifts of Corruption` now recreates/registers the rifts from the delayed discovery event.
  - Rechecked qAradion as the qXXX foundation and removed remaining local wrappers around shared dialog-sequence and quest-event boilerplate where QuestGiver now provides the reusable API.
  - Added `qAradion_TestSpawnManaRifts()` as a direct Mana Rift spawn diagnostic. It checks slots 1-3, reports each rect center / existing handle / CreateUnit result, stores successful Neutral Passive rifts into `RiftsUnits[]`, discards them from CreepRespawn, and refreshes the proximity trigger.
    - Type in chat: `/debug manarift` to debug

- `QuestGiver.j`
  - Replaced the dialog hero validity helper's Player(0)-ownership requirement with a live-unit check. `GetAvailableHero`, `GetAllowedHero`, and `ResolveDialogHero` now treat known Nazgrek/Zulkis unit refs as valid even while cinematic ownership is temporarily changed.
  - Confirmed quest-item grant logic itself already uses the generic `UnitAddItem` path and does not require a DInventory-specific grant. The Tel'anor Rod failure was caused by hero resolution returning null before the grant call.
  - Added reusable quest-giver session helpers for selection gating with optional casting/combat checks, per-giver/default dialog transition config, greet/info sequence scaffolding, delayed dialog reopen, and quest metadata/reward/prerequisite setup wrappers.
  - Fixed `OnGreetSequenceEnd` compiler errors by restoring the missing pending `npc`/`dialog`/`player` locals and nulling those handle locals after the pending dialog is shown.
  - Added shared helpers for matching the current quest event by quest name/giver and for starting the default configured dialog-exit transition without repeating fade/camera/cinematic constants in qXXX libraries.
  - Fixed cinematic greet-to-dialog handoff so `OnGreetSequenceEnd` / `OnFirstGreetSequenceEnd` no longer call cinematic OFF immediately before showing the dialog window. Cinematic shutdown is left to the dialog-exit transition, and first-greet completion now clears its pending sequence handle like normal greet completion.

- `DialogSystem.j`
  - Changed sequence finish cleanup so active sequence state is cleared before running the finish callback, preventing follow-up dialog/exit logic from seeing the completed sequence as still active.

- `qxxx-generator.html`
  - Updated generated qXXX scaffolds to use the new `QuestGiver` selection gate, configured transition starter, info-sequence reopen flow, and quest creation/reward wrappers.
  - Updated generated qXXX scaffolds to use the configured dialog-exit wrapper, register a delayed quest-discovered callback stub, and use `QuestGiver_IsEventQuestByNameAndGiver` for post-discovery quest matching.

- `QuestMaster.j`
  - Updated generic highest-hero-level availability checks to include `udg_Nazgrek` and `udg_Zulkis` directly after the Player(0) group scan, so quest availability level gates do not silently fail while cinematic ownership is temporarily changed.
  - Added a delayed quest-discovered event hook that fires after the delayed discovery message/icons update, allowing quest giver libraries to start post-discovery behavior at the actual displayed discovery time.

- `Companions.j`
  - Focus Nazgrek/Zulkis now matches the mode ability behavior:
    - Unit-targeted Focus affects only that companion/pet.
    - Ground-cast Focus applies to all valid companions and tamed units.

- `Interface.j`
  - now plays Interface_SelectTarget only when Player(0) selects a unit not owned by Player(0).
  - EVENT_UNIT_SELECT no longer points at gg_snd_Interface_SelectTarget.
  - EVENT_CANCEL now uses gg_snd_Interface_MenuClose.
  - Added Interface events for quest activate/complete/log close/write, loot coin, and hard warning.

- `AbilitiesLiteUI.j`, ``AchievementsUI.j`, `CameraUI.j`, `CheatsUI.j`, `CommandsUI.j`, `HintsUI.j`, `MasterUI.j`, `ProfessionsUI.j`, `ReputationUI.j`, `SecretsUI.j`, `SettingsUI.j`, `StatsLiteUI.j`, and `StatsUI.j` and `TasQuestBoxLight_PotS.j`
  - Wired active UIs directly to Interface.j

- `SettingsUI.j`
  - Displays UI Sounds: On/Off
    - Toggles Interface_SetSoundsEnabled(not Interface_AreSoundsEnabled())
    - Uses the existing master sound gate in Interface.j, so all sounds routed through Interface stop playing when disabled
  - Removed the standalone AI Units text frame.
  - Changed the slider label from AI cap to AI Units Cap, including the refreshed value text: AI Units Cap: 4.

- `TasQuestBoxLight_PotS.j` (`ZonesUI`)
  - Adjusted to behave as ZonesUI.
  - It now uses:
    - Interface_NotifyUIOpened()
    - Interface_NotifyUIClosed()
  - and no longer uses:
    - Interface_NotifyQuestActivated()
    - Interface_NotifyQuestLogClosed()

- `StormhavenCity.j`
  - Stormhaven citizen turnover now uses SHC_TURNOVER_PLAYER_GUARD_RANGE = 1250.00.
  - Removed random-looking spell, attack, stand ready, and holdposition ambient choices.
  - Street/social callbacks now use purposeful movement or plain standing.
  - Market callbacks use stand work for adults and plain stand for children.
  - Moved market/social chat chances into globals.
  - Added StormhavenCity_DebugForceChat() for testing citizen chat at 100% chance.
  - Best chat test path now: bind/call StormhavenCity_DebugForceChat() from a temporary test trigger or debug command while near citizens. It skips routine timing/random chance, but still uses the real chat rules: player nearby, valid Stormhaven citizen, nearby partner within SHC_CHAT_PARTNER_RANGE, and no active chat lock.
  - debug: in chat "/debug StormhavenCity" to testing citizen chat at 100% chance.

- `AIRoutines.j`
  - Added AIRoutines_SetManagedUnitGroupRemovalPlayerGuardRange(spawnGroupId, range).
  - Managed turnover removal now checks for a nearby Player(0) unit before removing a leaving unit.
  - If a player unit is nearby, removal is deferred and retried later instead of making the citizen vanish.

## [14.7.2026] Part I
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

### Technical Updates

- `Interface.j`
  - First version created
  - Interface_SetEventSound, Interface_ClearEventSound
  - Interface_PlayEventSound, Interface_PlayEventSoundForPlayer
  - clear notify helpers like Interface_NotifyUIOpened, Interface_NotifyUIClosed, Interface_NotifyMapOpened, Interface_NotifyMapClosed
  - event constants for unit select, UI open/close, map open/close, menu/button/tab/confirm/cancel/error
  - null placeholder bindings for future gg_snd_Interface_* sounds
  - automatic unit-selection event registration, currently silent until EVENT_UNIT_SELECT gets a sound
  - Added dialog-button sound events, eg:
    - Interface_EVENT_DIALOG_BUTTON_NORMAL
    - Interface_EVENT_DIALOG_BUTTON_TRADE
    - Interface_EVENT_DIALOG_BUTTON_CLOSE
  - Added notify helpers, eg:
    - Interface_NotifyDialogButtonClicked
    - Interface_NotifyDialogTradeButtonClicked
    - Interface_NotifyDialogCloseButtonClicked
  - now owns the minimap sound mapping:
    - Interface_EVENT_MAP_OPEN -> gg_snd_Interface_TurnPage
    - Interface_EVENT_MAP_CLOSE -> gg_snd_Interface_MinimapClose
    - new Interface_EVENT_MAP_MODE -> gg_snd_Interface_MenuClick2
    - new helper: Interface_NotifyMapModeChanged()
  - now maps the WE sounds variables for Interface events

- `DialogSystem.j`
  - Wired DialogSystem.j to requires Interface and added per-button interface sound classification:
  - default DialogSystem_AddButton -> normal dialog click
  - AddButtonTrade -> trade sound
  - AddFarewellButton, AddButtonPrevious, AddButtonDecline, AddButtonExit -> close sound
  - click playback is centralized in DialogSystem_OnClicked

- `MasterUI.j`
  - Updated MasterUI to requires Interface and notify the new library when the Game menu opens/closes and when a menu panel is opened.

- `DynamicMinimap_lastWorking.j`
  - now requires Interface, removed its local MINIMAP_OPEN/CLOSE/MODE sound globals, and calls:
    - InInterface_NotifyMapOpened() when enlarged
    - InInterface_NotifyMapClosed() when restored
    - InInterface_NotifyMapModeChanged() when toggling full/chunked map mode
  - Note about this library: Tens of issues in Valdemar MS-ToDO app to be taken care of (like minimap drift / camerabounds issues etc.). Also need to clean/reorganize `DynamicMinimap` -folder at some point.

- `GatherNodeUnits.j`
  - Mining is wired to:
    - Interface_EVENT_TRADESKILL_MINING_HIT_A through E
    - Interface_NotifyMiningHitOnUnit(unit)
  - GatherNodedUnits calls it for valid mining-profession unit nodes before the gather success roll. The sound is attached to the mined unit with AttachSoundToUnit, so nearby players can hear it spatially.

- `DInventory.j`
  - now requires Interface and calls those inventory sounds on real open/close, with visibility checks to avoid spam.

- `Terraining`
  - Lots of terraining has been done over the past several days. The changes are minor, but important (e.g., Lots of pathing blocker placements). Most notable zones terraining:
    - Vanguard Vale
    - Havenwoods
    - Thornwoods
    - Redwind Pass

## [13.7.2026] Part II
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

### Technical Updates

- `AI.j`
  - Generalized the companion pickup helper and now also runs it for autonomous AI.
  - _ChatWarrior target checks now distinguish Horde Warrior from Aveline, with only neutral Warrior-targeted lines allowed for Aveline.
  - Targeted companion mode commands now queue the bark from the affected unit only. Multi-target/no-target mode commands still randomize through the existing queued candidate behavior.
  - companion-controlled Aveline now clears a stale udg_UnitIsCasting[CV] lock only if she is Aveline, has no real order or only stop, is not moving, and stays that way past the existing stuck timeout. Then it refreshes her companion orders.

- `AI_Aveline.j`
  - Removed Aveline reply registrations for Tauren-only Warrior target lines.

- `StatsLiteUI.j`
  - Nudged alert sprite compensation slightly farther down-left:
    - SLUI_RowAlertOffsetX = -0.006
    - SLUI_RowAlertOffsetY = -0.006
  - Added companion mode text for companion rows:
    - Passive
    - Normal
    - Aggressive
    - Hold Position
  - Added config toggle:
    - Mode: On/Off
  - Mode text is shown only for SLUI_KIND_COMPANION rows and defaults to enabled.
  - Pet rows now use the same companion-control mode text path as companion rows, gated by Companions_IsControlled(u). 
  - The mode text anchor was also moved to the same X alignment as the status text, so Normal/Passive/etc. lines up directly under Ready/Moving.
  - Adjust party unit name allowed text length; full Companion label, slightly wider name frame, and label-aware scaling/trimming so it does not overlap the unchanged bar column.

- `qAradion.j`
  - Aradion quest/dialog registration now completes before rift spawning.
  - Mana Rift creation now runs in its own delayed timer pass via InitRiftsDelayed.
  - Rift proximity registration runs after that delayed creation pass.
  - qAradion no longer has its own Tel’anor CreateItem, ground fallback, inventory scan, or recovery-button condition logic.
  - The existing one-rawcode QuestGiver_AddQuestItemRecoveryButton still works and delegates to the new fallback-aware API.
  - Tel’anor Rod hero resolution now uses GetPlayerQuestHero, which syncs unit refs and falls back through cached hero, Nazgrek, udg_Nazgrek, then udg_Zulkis. Accept/recovery also preserves SelectedHero before the dialog callback runs.
  - Rifts companions now join even if accepting the quest outside a field zone. The old StartFieldCompanions zone gate was blocking this.
  - Simplified ManaRift units creation

- `StormhavenCity.j`
  - Moved the StreetAction chat chance into globals as SHC_STREET_CHAT_CHANCE and raised it from 12 to 18 to match the market chance. StreetAction now calls TryStartChat(whichUnit, SHC_STREET_CHAT_CHANCE).
  - Increase the citizen unit amount
  - Fix unit-type 'N65R' to lowercase 'n65R'
  - Temporary player chat range increase for debug purposes (from 500 to 3000)

- `QuestGiver.j`
  - now has reusable quest-item helpers:
    - HasHeroItemEither
    - RemoveHeroItemsEither
    - CreateQuestItem
    - GiveQuestItemToHero
    - AddQuestItemRecoveryButtonEither

## [13.7.2026] Part I
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

### Technical Updates

- `AI.j`
  - now blocks all AI barks while a cinematic, dialog sequence, visible dialog menu, or queued field line is active.

- `DialogSystem.j`
  - now exposes active field-line queue state and visible dialog-menu state.

- `qAradion.j`
  - now defers the Ranger Missing Valeria random barks and retries after 5s if dialog/field dialogue is active.

- `Installer`
  - Started creating `Path of the Shaman` installer setup to make it more easier to manage all the local files and mods required by the map.

### Known Issues
- Aradion `qAradion.j` dialogs and quest now don't work. The library itself seem to break silently.

#### Debug notes
- use command `/debug setfactionrep riverbane` to set Riverbane rep
- use command `/debug setfactionrep horde` to set Horde rep

## [12.7.2026] Part III
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

### Technical Updates

- `StatsLiteUI.j`
  - Changed sprite compensation from upper-right to down-left. Size and scale stayed unchanged.

- `StatsUI.j`
  - The Party: X / Y label is now moved inward and slightly lower under Monitor. The Abilities and Professions buttons are now side by side below the selected unit icon, with Abilities on the left and Professions on the right, matching the second screenshot direction.

- `AI_Aradion.j` and `AI_Valeria.j`
  - adjusted bark reputation ranges so behavior stays the same after the constants became tier-start values.

- `Reputation.j`
  - Reputation_REP_NEUTRAL is now the start of Neutral (0), not the upper edge of Neutral. A rep value like 2000 now satisfies Neutral requirements, including the companion gate that already uses Reputation_REP_NEUTRAL.
  - added Reputation_IsFactionTemporarilyHostile.
  - Added Stormhaven faction, Player(8) mapping, hostile Player(0) starting rep, kill rep handling, and icon

- `ReputationUI.j`
  - added an Info row with tier thresholds, and each faction detail now shows the consequence of the current status.
  - Added Stormhaven UI description

- `AI.j`
  - Aveline now uses graveyard id 5 only when she is not companion-controlled. If she is a companion, she still uses udg_GraveyardSelect when available; other non-companion AI still keeps the random 1..9 graveyard fallback.
  - Camp fire AI now stops first, retries nearby random placement points, and removes the temporary camp item on failure instead of dropping it.
  - Generic companion pickup now ignores gather-node items, so profession nodes only go through profession logic.
  - Low-skill profession attempts now immediately stop, clear tracked tools, reset wander to idle, and back off instead of short-loop retrying.

- `AI_LegacyLocations.j`
  - AI_Warlock_UndeadProfileId now gets the same Horde spawn, retreat, and shop bindings as AI_Warlock_ProfileId, so undead warlock random spawning should use the Horde spawn rect list instead of falling back to random playable-map coordinates.

- `AIRoutines.j`
  - Random managed groups now spawn from weighted unit-type pools. Turnover lets a managed unit walk toward an exit rect, get removed after a delay, then respawn later from the same random pool, so villages/cities can naturally swap citizen types over time.
  - Fixed AIRoutines turnover cleanup so “leaving” units keep their turnover state until actual unregister/removal

- `StormhavenCity.j`
  - Creates 30 Player(8) Stormhaven citizens across street, market, and social city routines, with weighted random unit types and periodic turnover/replacement.
  - Random two-villager overhead chats during street/market/social routine callbacks.
  - Player proximity gate: chat only starts when a visible Player(0) unit is within 500 range.
  - Global chat lock so conversations do not overlap.
  - 90 paired lines split by speaker/listener class: male, female, child.
  - Unit-type chat classes through AddCitizenTypeEx, so future villagers can be added with the right line category.
  - Note: these chats use TexTags to display the chats. `ExSound.j` is not utilized and thus there are no audio files for the chat voicelines at the moment.

- `qAradion.j`
  - Mana Rift not killed issue: The Mana Rift issue was not that the unit variable was lost. RiftsCurrentRift and RiftsUnits[] existed, but the finish path also used a redundant PlacedManaRifts[] copy seeded from placed unit globals. I removed that extra array entirely. Rift lookup and completion now use RiftsUnits[] plus RiftsCurrentRift, and closing calls KillUnit then RemoveUnit through CloseManaRiftUnit. Completion also now refuses to run unless a ritual is actually active.
  - Other fixes:
    - Valeria now starts offset and moves to her Rifts intro position instead of teleporting directly.
    - Rifts ritual start is blocked when Elarindor rep is hostile, and active rituals fail if it turns hostile mid-ritual.
    - Rifts now treats temporary Elarindor hostility as hostile.
    - detects stale Aradion/Valeria companion control if the generic companion system removed them.
    - fails/stops Rifts instead of letting timers/orders continue with stale companion state.
    - Ranger Missing had faction = "Elarindor", and QuestMaster treats any quest faction as a reputation requirement. Since requiredReputation defaults to 0, the quest silently required neutral Elarindor rep before it could become QUEST_STATE_AVAILABLE. Changed "call q.setRequiredReputation(Reputation_REP_ENEMY)" so it still rewards Elarindor reputation, but negative Elarindor rep no longer hides the start button after Aradion’s intro.
    - Valeria now randomly plays Valeria_0021 / Valeria_0022 at her unit while Ranger Missing escort is active and she is in qAradion’s companion state.
    - Removed the direct DInvUnitAddItem path for Tel’anor Rod.
    - Rod grant now does the normal flow only: CreateItem(I013) -> UnitAddItem(hero, rod).
    - If UnitAddItem returns false, it forces the same rod visible at the hero position and adds floating item text, plus a debug message.
    - Rifts acceptance now recreates Valeria if missing/dead, places her behind the hero, and orders her to move to a side position next to Aradion.
    - Mana Rifts are now created by qAradion during InitDelayed at gg_rct_ManaRift1/2/3, stored in RiftsUnits[], owned by Neutral Passive, and explicitly discarded from CreepRespawn.

  - `Companions controller unit` abilities
    - Passive Mode, Normal Mode, Aggressive Mode, Hold Position can now be targeted on single unit or on point (ground)
       - Cast on single target unit the command only affects that unit
       - Cast on point affect the whole companion party

- `ZonesCore.j`
  - Added parentzone for Horde Scout Base (id 8810)
  - Updated Zone 13 faction text to Stormhaven

- `HordeMainBasePeons.j`
  - Draft AI Routines for Horde Main base peons

- `Companions.j`
   - Mode abilities now:
     - Unit-target cast: applies only to that targeted companion/tamed unit.
     - Point/no-unit cast: applies to the full controlled companion group.

- `CreepRespawn.j`
   - Added CreepRespawn_DiscardUnit so quest-managed units can be excluded from saved positions and respawn scheduling.


## [12.7.2026] Part II

### Technical Updates
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

- `StatsUI.j`
  - Professions is stacked above Abilities, and both buttons use the same 0.030 height as Return for matching button text sizing. I also moved the stats summary block down to avoid overlap.

- `StatsLiteUI.j`
  - The sprite (Alert LowHP / Far) now uses offset values in its center anchor. If it is still slightly off in-game, these four globals are the intended tuning points. A fully reliable alternative would be replacing the sprite model with a frame/backdrop border, because backdrops center predictably while sprite models depend on the model’s internal origin.

- `Companions.j` and `StatsUI.j` and `StatsLiteUI.j`
  - Improved the companion party text in Companions.j, StatsUI.j, and StatsLiteUI.j. The ? info now uses \n instead of visible |n markers and reads as clearer companion party size information.

- `ProfessionsUI.j`
  - Mining details now show a Can mine now: list built from enabled GNU_* unit-node definitions and the current viewing unit’s Mining skill. I also added the viewer handle to the detail-body cache so opening Professions UI for a different active unit forces the mining list/body text to refresh.

- `Companions.j`
  - Normal-mode companions now break out of stale post-combat attack orders and smart-follow the leader once they drift 350+ range and the leader is not in combat.

- `AI.j`
  - Existing/preplaced O009 Avelines are now scanned and registered during AI_Aveline init before random spawn can create another.
  - Newly indexed default-profile units now try AI_RegisterUnitByType, so direct-created O009 Avelines are caught too.
  - If Aveline’s unique id AVLN is already active, later duplicates are removed instead of staying as level 1 no-AI units.

- `AI_Aveline.j`
  - That line is a starter RegisterChat, not a reply.
  - The bug was that _ChatUndeadWarlock was not recognized by the target filter, so it was treated like a general line. It now requires a nearby allied Undead Warlock 
>### Issue reference: 
>Aveline say the line "undead or not, you still choose where your shadowfalls." isnt that the reply line to some other AI unit speaking towards undead warlock and after that Aveline should say it? Aveline said this without anyone targeting undead warlock bark and without undead warlock being in companions party or even close.

### Known Issues
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.
- `[12.7.2026] Part I` seems to have introduced some accumilating lag (stuck-loop / periodic timers etc.), to be checked whether this is fixed with the latest updates or do we need to go deeper investigating.

## [12.7.2026] Part I

### Technical Updates

- `Reputation.j`
  - Added Reputation_ClearFactionTemporalHostility.

- `qAradion.j`
  - Clears Elarindor temporal hostility when Valeria is added for Ranger Missing escort.
  - Aradion/Valeria now play the nearby survivor death reaction even when not in the companion group.
  
- `Companions.j`
  - Attacking or killing a reputation faction unit now drops matching faction companions from the party, with a randomized kicked/farewell bark speaker.

- `StatsUI.j`
  - Added a Professions button beside Abilities, wired to the currently selected StatsUI unit.

- `ProfessionsUI.j`
  - Added ProfessionsUI_ShowForUnit(unit) and return-to-StatsUI behavior.

- `AI.j`
  - Fixed companion chatter gating and reply selection.
  - Also fixed the Aveline/remote warlock issue more broadly: target-class chat lines like ChatWarlock are only eligible when that class is actually nearby, and replies must come from a companion within 900 range of the speaker.

- `GatherNodeSkills.j`
  - AI profession skill-up messages now only announce for Nazgrek/Zulkis or units in udg_Companion_Group.

## [11.7.2026] Part II
#### Note: Because of the vast updates and to make it more simpler to update the changelog, the updates have only been written under `### Technical Updates` for now.

### Technical Updates

- `QuestGiver.j` and `DialogSystem.j`
  - Added shared recovery-button support:
    - DialogSystem_AddButtonQuestItemRecovery
    - QuestGiver_IsQuestActiveByNameAndGiver
    - QuestGiver_AddQuestItemRecoveryButton

- `qAradion.j`
  - changed Tel’anor Rod to use the lowercase rawcode 'i013' to match the item definition export, and I now preserve the accepting hero through the dialog callback before granting the rod.
  - Aradion now uses that helper shared item recovery-button support. The “Get new Tel'anor Rod” button appears only while Fading Sparks is discovered, not completed/failed, and the party does not currently have the rod. Clicking it plays a short Aradion line and grants a new rod to the resolved hero.


- `AI.j` and `Companions.j`
  - added a quest-NPC level bypass for Aradion/Valeria. It only applies during the same active quest windows already used for their quest invite/reputation bypass, so normal companions still keep the higher-level block.
  - AI companions now late-register on death if they somehow missed AI registration, so StatsUI/StatsLiteUI can show the AI revive timer without legacy timer globals.
  - Current companion hire reputation requirement is now Neutral for faction units.
  - Companion random movement is throttled: 3-7s normally, 5-15s when the focused hero is idle.
  - Idle/moving barks no longer require another nearby companion.
  - Mode-change barks now pick a random eligible AI companion speaker instead of sticking to the command target/first companion.
  - Attack/cast bark spam reduced: lower trigger chance and longer cooldowns.
  - Removed the now-dead nearby-companion chat helper.

  - Temporary AI mining picks now track the active ore-vein unit.
  - The pick is kept while that ore unit still exists as a live gather node, then cleanup starts after the vein is gone.
  - AI units now stop immediately if they attack a gather unit without the required profile profession/skill or without a mining pick.
  - Aveline is no longer removed from the companion list on death, matching Valeria/Aradion behavior. This keeps her row in StatsUI/StatsLiteUI so the existing AI_GetReviveTimer display can show her revive countdown.

- `AI.j` and `AI_Aveline.j`
  - Aveline now keeps the Warrior mining profession so AI.j will assign her rough mining skill from level. With her fixed level 10, that gives mining skill 50, so she can mine nodes up to requirement 50 and should skip higher nodes like Thorium.
  - if some non-profession order path still makes her attack an ineligible ore node, she stops and gets a profession backoff instead of immediately retrying in a loop.


- `StatsLiteUI.j`
  - Increased monitor row text sizes:
    - name 0.56
    - class / level / state 0.50
    - HP/Mana bar labels 0.50
  - Shifted row text slightly right and moved the state column farther right to match the reference spacing better.
  - Centered the alert sprite on the unit icon using a centered frame point and explicit size.
  - Low HP icon alert now flashes on/off with the refresh pulse instead of staying continuously visible.
  - Far-away alert remains continuously visible.
  - Low Power was renamed to Low Mana.
  - Low Mana alert now only applies when the unit resource mode is normal mana. Rage/Energy units are ignored.

  - Low HP alert now uses a 1.50s cycle: 1.00s visible, 0.50s hidden.
  - Monitor refresh cadence changed from 0.35s to 0.25s so the pulse timing lands cleanly.
  - Alert sprite was reduced and offset left/down over the icon:size 0.022
    - scale 0.56
    - center offset -0.004, -0.001

- `ZoneEvent.j` and `AIRoutines.j` and `MountainPeons.j`
  - AIRoutines.j now requires ZoneEvent, subscribes to player hero zone enter/leave events, and only runs zone-bound NPCs while at least one player hero is in that zone.
  - Added zone APIs: RegisterUnitInZone, RegisterUnitsInRectInZone, RegisterUnitTypeInRectInZone, CreateManagedUnitGroupInZone, SetZoneActive, IsZoneActive.
  - The AIRoutines periodic timer now starts only when at least one routine unit is active and pauses when none are active.
  - ZoneEvent.j now exposes lightweight enter/leave listener hooks with ZoneEvent_EventZoneId and ZoneEvent_EventUnit.
  - MountainPeons.j now orders peons to harvest a real nearby destructible within 1024 range using IssueTargetOrder(peon, "harvest", pickedDestructible).
  - Mountain peons are registered through AIRoutines_CreateManagedUnitGroupInZone(..., 3). If that camp belongs to a different ZonesCore zone, change MP_ROUTINE_ZONE_ID.

- `Cinematic ON trigger`
  - added calls to DInv and DEqui to close up inventory and equipment frames when cinematic starts (with call CloseDInventory(0) and call CloseDEqUI(0) functions)


## [11.7.2026]

### Technical Updates
- `AI_Valeria.j` and `AI_Aradion.j`
  - Edited and added more voicelines
  - Reputation-specific bark types: greet, farewell, passive, normal, aggressive, hold, kicked, idle, moving
    - Each of those has 3 lines per status: Neutral-or-worse, Friendly, Covenant, Exalted
    - Common all-status barks: drop_items, item_given, attacking, casting, killing, companion_dies

- `ExSound.j`
  - Extended both Valeria and Aradion ExSound_RegisterSequence ranges from 300 to 312.

- `AI.j`
  - Added explicit AI profile faction metadata in AI.j: AI_SetProfileFaction, AI_GetProfileFaction, and AI_GetFactionInfoText.
  - Invited unregistered companions now register through AI_RegisterUnitByType on invite, which should fix Warrior/Aveline timers in both UIs:

- AI `\Classes` and AI `\Specific`
  - Registered factions on Warrior, Rogue, Restoshaman, Warlock, Engineer, Paladin, Aveline, Aradion, and Valeria profiles.

- `AI_LegacyLocations.j`
  - Aveline now uses only gg_rct_RiverbaneHeroSpawn1

- `Reputation.j`
  - Added reputation unit-type faction registration, so faction lookup is not derived from profile name or current owner.

- `StatsUI.j`
  - StatsUI now shows dead revive countdowns via Nazgrek/Zulkis/Pet timers or AI_GetReviveTimer, with cache invalidation so the seconds update

- `StatsLiteUI.j`
  - Row text is now anchored from the unit icon’s right edge, so name/class/level/state use fixed columns instead of drifting over the icon.
  - Companion label in the compact monitor is shortened from Companion to Comp to leave more name space.
  - Alerts now use a visible autocast sprite border on the unit icon.
  - Low HP alert pulses red and also pulses the HP bar background.
  - Far-away alert stays continuously yellow on the icon.
  - Low resource alert pulses blue and also pulses the resource bar background.
  - Low Res was renamed to Low Power.

- `Companions.j`
  - Add FactionName fetch

## [10.7.2026]

### Technical Updates

- `StatsUI.j`
  - added the same AI class resource registry pattern as StatsLiteUI, so Warrior shows Rage and Rogue shows Energy in the detail resource label and regen stat labels. 
  - added valid-unit checks and selection clearing so StatsUI stops reading stale/removed unit handles during refreshes, which should address the random crash when the open panel races a Nazgrek/unit change.
  - now hides mana from the row status text and detail summary for no-mana units.
StatsUI 
  - also skips detailed stat rows for Mana, Mana Regen, and Mana %/Sec when the unit has no resource pool.

- `StatsLiteUI.j`
Lots of troubleshooting and trying to adjust the UI. So, therefore quite many changelog notes...
  - fixed the same fallback rawcode typo from 0631/0629 to O631/O629.
  - Reworked monitor anchoring with a fullscreen relative frame under ConsoleUIBackdrop, using BlzGetLocalClientWidth/Height, so it can sit at the real right edge instead of the 4:3 edge.
  - Monitor height now shrinks/grows based on tracked unit count.
  - Fixed row layout: wider name area, shortened long names, compact Lvl X, aligned level/class/status text, and added class display.
  - Added config toggle for Class.
  - Cleaned config layout with smaller buttons and no overlap with the Monitor button.
  - Changed default resource label from MP to Mana.
  - Improved alerts: row-wide colored flash, resource alert now works at 0%, and blinking uses a refresh tick instead of timer elapsed.
  - Changed rogue Energy text from black to yellow so it stays visible on dark/empty bars.
  - Energy text now works like this:
    - Energy > 50%: black text, because the center of the bar should still be yellow.
    - Energy <= 50%: yellow text, because the center is likely on the dark/empty part of the bar.
  - Low HP alert now matches the red HP threshold:
  - HP bar turns red at <= 25%.
  - Low HP alert also starts at <= 25%.
  - It goes away once HP is above 25%.

  - Text alignment is now column-based:
    - Icon column fixed.
    - Name starts from one fixed text column.
    - Class starts from the same text column.
    - Level starts from the same text column.
    - State uses one fixed status column on every row.
  - also increased row height so those three text lines are not crammed together.
  - Previous fullscreen anchor could plausibly block mouse input even when the monitor panel was hidden. It was a full-screen FRAME and the monitor was parented under it. Changed it so the fullscreen anchor is disabled, hidden, and no longer the parent of the actual monitor panel. It is now only used as an invisible positioning reference.

  - Widened the monitor panel and row width.
  - Moved the text block much farther right from the icon.
  - Kept name, class, and level on the same fixed left column.
  - Kept state on one fixed column beside class.
  - Moved HP/Mana bars farther right.
  - Re-applied text frame points after scale so scaling cannot pull the text back over the icon.

  - Row icons reduced to 0.020 x 0.020, about half the previous size.
  - Row height reduced from 0.040 to 0.026.
  - Panel max height reduced so full party does not grow oversized.
  - Name, class, level all start from the same fixed column to the right of the icon.
  - State has its own fixed column beside class.
  - Text scale reduced and vertical alignment changed to TEXT_JUSTIFY_TOP.
  - HP/Mana bars reduced and moved into the compact row layout.

 - Row text is now anchored from the unit icon’s right edge, so name/class/level/state use fixed columns instead of drifting over the icon.
 - Companion label in the compact monitor is shortened from Companion to Comp to leave more name space.
 - Alerts now use a visible autocast sprite border on the unit icon.
 - Low HP alert pulses red and also pulses the HP bar background.
 - Far-away alert stays continuously yellow on the icon.
 - Low resource alert pulses blue and also pulses the resource bar background.
 - Low Res was renamed to Low Power.
   - Low Res meant “low resource”: mana/rage/energy below 20%. It is now labeled Low Power so it is less cryptic.

  - StatsLiteUI now hides the mana/resource bar entirely when UNIT_STATE_MAX_MANA <= 0.

- `AI_Warrior` and `AI_Rogue`
  - register their resource mode with StatsUI.

- `AI_Warlock.j`
  - removed the redundant AI_WARLOCK_UNIT_HORDE = 'H60X'. More importantly, AI_Warlock.j now adds AI_Warlock_UndeadProfileId to the random spawn pool, so undead warlock 'O61K' can actually spawn.

- `AI_Aveline.j`
  - Aveline now opts into level 10, XP locked until invite, first random spawn, cap 1, expanded barks, chat lines, and companion replies.
  - Add more chat lines, Aveline can now reply to every existing AI hero starter line from `AI_Voicelines.j`

- `AI_LegacyLocations.j`
  - Aveline’s initial autonomous zone restriction is bound to Sereneglade and Riverbane rects from `ZonesCore.j`.

- `AI_Valeria.j` and `AI_Aradion.j`
  - RegisterChat + RegisterBarks, keys Valeria_0201 through Valeria_0225 and keys Aradion_0201 through Aradion_0225
  - Valeria now has Elarindor-tiered lines, hostile/wary at neutral-or-worse and warmer up to Exalted.
  - Aradion uses the same reputation tiers, but stays more friendly/cautious even at neutral.

`AI.j`
  - now defaults active random AI cap to 4, clamps cap APIs to max 32, and forces excess non-companion random AI into TRAVEL when the active cap is lowered.
  - added profile support for fixed hero level, XP lock until first invite, first random spawn priority, and initial allowed-zone rectangles.
  - now lets random-managed AI heroes form private AI parties using internal tables, with followers assisting/following the AI leader and no new udg_ party group.
  - Companion command handling now removes invited AI from private AI parties and resets stale companion AI state on invite/kick/mode changes.

  - Mode command barks are now batched and choose one random valid companion, instead of the first processed companion always consuming the global bark cooldown.
  - Companion-controlled units now have lightweight party chatter, so idle/moving bark lines can trigger existing companion reply lines.
  - During udg_InCinematic, companion AI side-actions are suppressed and companions are parked once: no pickup/profession/social/stuck refresh/order refresh/ability think loop.
  - Added AI_RemoveProfileProfession, and Aveline now opts out of inherited warrior mining.
  - Hardened temporary profession tool creation: if the AI-created tool is not actually retained by the unit, it is removed immediately and treated as unavailable.

  - added reusable AI_RegisterBarkLineForReputation(...) while keeping old AI_RegisterBarkLine(...) working.
  - bark selection now filters by faction reputation before randomly picking a line.

`Companions.j`
  - added Aveline’s short info/background line to the companion information output.
  - invite level floor logic: candidate level must be at least the max of Nazgrek/Zulkis
  - Invite now allows companion levels <= highest player hero level and rejects only higher levels.

`SettingsUI.j`
  - now has an AI cap slider plus the requested lag/order/input-lag warning.

- `AIRoutines.j`
  - Flexible routine families with ordered steps: wait, work/animation, point orders, rect orders, unit/destructable target orders, immediate orders, sleep, and custom callbacks.
  - Easy assignment by single unit, all units in a rect, unit type in a rect, or all current/future units of a unit type.
  - Sleep handling with rawcode A0F1: routine-sleeping units are paused, get the sleep ability, and wake/unpause when attacked.
  - Built-in helper factories for blacksmith work and peon lumber-to-sleep routines.
  - Optional AI.j profile registration via AIRoutines_SetRoutineAIRegistration, defaulted off to avoid unwanted AI.j revive behavior on ambient NPCs.
  - A commented Guide section with patterns for village walkers, fishers, guard patrols, day workers/sleepers, shopkeepers, quest NPC callbacks, prop interactions, and other RPG ambient routines.
  - Readability helpers:AIRoutines_AddWanderStep
  - AIRoutines_AddStandStep
  - AIRoutines_AddEffectWorkStep
  - Generic factory helpers:
    - AIRoutines_CreateVillageWanderRoutine
    - AIRoutines_CreateFishingRoutine
  - API docs now include AIRoutines_RegisterUnitTypeInRect.

    example usage:
    set r = AIRoutines_CreateBlacksmithRoutine("Town Blacksmiths", gg_rct_BlacksmithWork)
    call AIRoutines_RegisterUnitsInRect(gg_rct_BlacksmithNPCs, r)

  - AIRoutines can create units itself from a spawn rect.
  - Created units are registered to the routine automatically.
  - On death, AIRoutines unregisters the dead unit and respawns a replacement after respawnDelay.
  - facing < 0.00 means random facing.
  - Managed groups can switch routine, which MountainPeons uses for day/night.

  - now resolves "harvest" rect steps by picking a live destructable inside the rect and issuing IssueTargetOrder(..., "harvest", targetDest). It only falls back to point-order if no destructable is found.
  - Sleep now:
    - stores whether the unit already had 'Asla'
    - adds 'Asla' when routine sleep begins
    - plays "sleep" animation and pauses the unit
    - removes 'Asla' on wake only if AIRoutines added it
    - There are no UnitAddSleep, UnitCanSleep, UnitAddSleepPerm, or UnitCanSleepPerm calls left in

- `MountainPeons.j`
  - Defines library MountainPeons initializer Init requires AIRoutines.
  - Picks managed peons from gg_rct_MountainPeons.
  - Day routine: harvests lumber from gg_rct_MountainPeons, wanders/idles around gg_rct_HordeMountainCamp, and runs random camp actions.
  - Night routine: moves peons to gg_rct_HordeMountainCamp and uses AIRoutines_AddSleepStep.
  - Switches on dawn/dusk using GAME_STATE_TIME_OF_DAY, with a 15s sync timer as backup.
  - Exposes MountainPeons_Refresh() to add current units from the pickup rect and reapply day/night mode.
  - every registration path goes through AddPeon, which rejects anything where GetUnitTypeId(whichUnit) != MP_PEON_UNIT_TYPE_ID.
  - That applies to:
    - initial units inside gg_rct_MountainPeons
    - recreated peons found by the 15s sync scan
    - units entering gg_rct_MountainPeons
    - manual MountainPeons_RegisterPeon(whichUnit) calls
  - the library no longer picks placed peons. It now creates MP_PEON_COUNT = 5 'opeo' units at gg_rct_MountainPeons, owned by PLAYER_NEUTRAL_PASSIVE, and respawns them after 60.00 seconds.
  - now creates peons for Player(1) instead of neutral passive.

- `ExSound.j`
  - Registered:
    - All current Aveline_* bark/chat keys under Pots\\Sound\\Voicelines\\Aveline\\
    - All Aveline companion reply keys under Pots\\Sound\\Voicelines\\Aveline\\ChatOther\\

- `StormV2.j`
  - Replaced KillUnit(.Unit) with RemoveUnit(.Unit) so the dummy is removed immediately instead of dying/decaying.
  - Added SetUnitPathing(.Unit, false) right after dummy creation.
  - Added Locust via UnitAddAbility(.Unit, 'Aloc') so other systems treat it as a dummy/non-interactive unit.

- `Aveline voicelines`
  - Created most Aveline audio files manually with FishAudio and the rest with FishAudio API and python script. Note these could have issues or something that requires editing voiceline text itself or/and the audio file, but this is not huge priority.


## [9.7.2026]

### Technical Updates
- `StatsLiteUI.j`
  - Updated StatsLiteUI panel styling to combine the native Warcraft III border frame with a separate translucent grey inner backdrop.
  - Raised StatsLiteUI content frame levels so title, buttons, rows, config controls, row icons, alert frames, and bar layers render cleanly above the transparent background layer.
  - Kept the monitor right-anchored and hidden until explicitly shown through the StatsLiteUI API.
  - Restored compact row spacing so the panel can fit the full party monitor set more reliably.
  - Reworked row layout so icon, unit kind/name, level, status, HP bar, and resource bar use fixed aligned columns with reduced overlap risk.
  - Moved `Level X` under the unit name and aligned status on the same compact subline.
  - Resized and inset the configuration icon button so it visually matches the other header buttons.
  - Reworked HP/resource bars away from the old black `blank-background.blp` rendering issue.
  - Updated HP bars to use green by default.
  - Added configurable HP percentage coloring:
    - `HP Color: Off` keeps HP bars always green.
    - `HP Color: On` changes HP bars by percentage: green above 50%, yellow from 26–50%, and red from 0–25%.
  - Updated resource bar labels and colors:
    - default mana classes show `MP` with a light-blue bar;
    - Warrior/rage classes show `Rage` with a red bar;
    - Rogue/energy classes show `Energy` with a yellow bar and black label text for readability.
  - Refactored resource-bar class detection to use the current `AI.j` class registry instead of legacy `udg_NPC_Horde_AI_xxx` unit globals.
  - Added resource display registration APIs for AI classes:
    - `StatsLiteUI_RegisterManaResourceClass(classId)`
    - `StatsLiteUI_RegisterRageResourceClass(classId)`
    - `StatsLiteUI_RegisterEnergyResourceClass(classId)`
  - Removed legacy class-specific companion revive timer references from StatsLiteUI; only current player/pet revive timers remain directly handled.
  - Added configurable row alerts for low HP, low resource, and far-away party members.
  - Added flashing row alert frames around party member icons, with alert priority ordered as low/dead HP, low resource, then far-away companion state.
  - Added config toggles for `Low HP`, `Low MP`, `Far`, and `HP Color`.
  - Utilize `AI.j` API for AI companion revive timer

- `AI_Warrior.j`
  - Registered the Warrior AI class with StatsLiteUI as a rage-style resource class so Warrior resource bars display red in the party monitor.
  - Added `StatsLiteUI` as a dependency for the Warrior AI class registration integration.

- `AI_Rogue.j`
  - Registered the Rogue AI class with StatsLiteUI as an energy-style resource class so Rogue resource bars display yellow in the party monitor.
  - Added `StatsLiteUI` as a dependency for the Rogue AI class registration integration.

- `AI.j`
  - Expose API for AI revive status and revive timer.

## [8.7.2026]

### Player-Facing Updates
- `AI` and `Companions`
  Improved AI logic e.g., item pickup
- `StatsUI` / `StatsLiteUI`
  StatsUI and StatsLiteUI now show companion party status as current/max companions, with an info button explaining the level ranges used for the companion cap.
  StatsLiteUI now behaves more like an upper-right party monitor: transparent background, improved icon/name spacing, engineering-icon configuration button, and state-preserving maximize/minimize behavior when opening StatsUI and returning.
  StatsUI now shows unit faction, always-visible ability points, and XP as current/required for pets, companions, and heroes.
- `Companions`
  Companion-controlled AI units with matching profession profiles can try nearby mining veins or herb nodes when they are not in combat, Passive mode, or Hold Position mode.

### Technical Updates
- `AI.j`
  No-mana profiles now reject/drop mana-only items instead of trying to use them.
  Companion AI can delayed-pick nearby items, giving the player time first.
  Autonomous AI can randomly use a Camp Fire at night and camp for a while.
  Companion-controlled AI now reuses the existing profession scanner for nearby gather nodes, while bypassing the autonomous idle-roll so close valid nodes can be acted on when companion mode allows it.
  Throttled companion pickup/profession side scans with a shared per-tick budget, smaller pickup radius, and longer pickup retry delay to reduce FPS impact around nearby items.
  Added companion stale-order recovery to reduce Warrior/Engineer/etc. “stuck after combat/item” cases.
- `AI_Warrior.j`
  Warrior profiles, including Aveline, no longer do low-health companion retreat.
  Warrior ability templates now register with AbilitiesLiteUI, including the shared helper used by Aveline.
- `AI_Rogue.j`
  Rogue is now marked no-mana-restoration.
  Rogue ability templates now register with AbilitiesLiteUI from the Rogue sublibrary.
- `AI_Paladin.j`
  Paladin no longer does low-health companion retreat.
  Paladin ability templates now register with AbilitiesLiteUI from the Paladin sublibrary.
- `AI_Shaman.j`
  Companion Shaman now prioritizes healing and avoids support totems unless allies are pressured.
  Restoshaman ability templates now register with AbilitiesLiteUI from the Restoshaman sublibrary.
- `AI_Aveline.j`
  Aveline explicitly registers with ResourceRage.
  Aveline now registers her Riverbane Warrior unit type with the shared Warrior AbilitiesLiteUI templates.
- `AI_Warlock.j`
  Orc and Undead Warlock ability templates now register with AbilitiesLiteUI from the Warlock sublibrary.
- `AI_Engineer.j`
  Engineer and Shredder-form ability templates now register with AbilitiesLiteUI from the Engineer sublibrary.
- `AI_Companions.j`
  Added public mode/order refresh APIs for AI integration.
- `Companions.j`
  Added companion limit/status APIs for StatsUI and StatsLiteUI, including level-based companion cap info and public faction text lookup.
- `StatsUI.j`
  Removed the old Lite Config button and replaced it with a left-pane Monitor button that opens StatsLiteUI.
  Added a StatsLiteUI return path so opening StatsUI from StatsLiteUI returns to the previous StatsLiteUI minimized/maximized state.
  Added cached required-XP helpers for StatsUI XP display. Hero XP requirements use the `NeedHeroXPFormulaA=1`, `NeedHeroXPFormulaB=150`, `NeedHeroXPFormulaC=0` recurrence and must stay synchronized with Game Constants if those values change.
- `StatsLiteUI.j`
  Added cinematic hide/show-last-state APIs for GUI Cinematic ON/OFF trigger use.
  Moved the party monitor to the upper-right multiboard-style screen area, made the main monitor background transparent, replaced the `Cfg` text button with the engineering icon, and added companion cap info access.
  Changed the row container to a non-rendering frame and shifted the monitor closer to the right screen edge to remove the green backdrop panel.
  Removed initializer autoInit from library header and now to be initialized externally with call `StatsLiteUI_Init()` and to show it use first time use `call StatsLiteUI_Show()`
  Updated StatsLiteUI initialization and frame layout so the monitor remains hidden after external init and only appears when explicitly shown through the API.
  Adjusted the main panel to use an invisible right-anchored parent frame with child backdrop/content layering to reduce preload flicker and improve UI stacking.
  Note: Later clean comments like `CHANGE` in the library!
- `qAradion.j`
  Fading Sparks now removes existing TelAnor Rods from player units/heroes and gives a fresh rod to a player-owned hero.

- GUI Triggers `Cinematic ON` and `Cinematic OFF`
  added call hide/show `StatsLiteUI` in Cinematic ON and Cinematic OFF triggers
- GUI Trigger `Preload`
  Added call `StatsLiteUI_Init()` but not show the frame at this point
- GUI Trigger `Intro Orc Cleanup`
  Added call `StatsLiteUI_Show()`

- `StatsDummy` and `RepDummy` hero-type units
  Removed these units on the map and from these from triggers `Init 01a Units`, `DummyUnitFollow`
  Note 1: that there may be several places where these units are referred (eg., mostly as unit != StatsDummy). Should affect gameplay, but for future references.
  Note 2: `CompDummy` left as its still in use as `Companions controller `

- Removed old GUI triggers to clean map triggers
- These are replaced by `ResourceEnergy.j` and `ResourceRage.j` libraries:
  Folder `RAGE ENERGY System OLD`
  `RageEnergy Limit Mana Max From Items`
  `RageEnergy Limit Mana Regen From Items`
  `RageEnergy Remove Aura`
  `RageEnergy Energy Add`
  `RageEnergy Energy Tick`
  `RageEnergy Rage Init`
  `RageEnergy Rage Generation`
  `HeroWarrior Rage Decay`

- These are replaced by `Totems.j` library
  Folder `TOTEMIC abilities OLD`
  `Totem Setup`
  `Totem Dies`
  `Fire Totem AutoCast Fire Shield`
  `Wind Totem AutoCast Cyclone`
  `Wind Totem Greater AutoCast Lightning`
  `Cleansing Totem Level 1`
  `Cleansing Totem Level 2`
  `Windfury Totem Aura`
  `Windfury Totem Aura Effect`
  `Windfury Totem Greater Aura wip`
  `Totem Master Return Mana`
  `Skyfury Aura Setup`
  `Skyfury Aura Add Source`
  `Skyfury Aura Loop`
  `Skyfury Aura DeIndex`
  `Earth Totem`
  `Fire Totem`
  `Water Totem`
  `Wind Totem`
  `Stoneskin Totem`
  `Earthbind Totem`
  `Windfury Totem`
  `Cleansing Totem`
  `Skyfury Totem`

- These are replaced by `AI.j` library and `AI_xxx` sublibraries
  Only shown removed trigger folders because too many GUI triggers to list here. These can be found in project AI folder under `_OldGUI_triggers`
  Folder `AI COMMON`
  Folder `AI HORDE HEROES`
  Folder `AI RIVERBANE HEROES`
  Folder `AI NEUTRAL HEROES`

- These are replaced by `Pet.j` and `Companions.j` libraries
  Folder `Tame System OLD`
  Note: `Variables` folder moved to upper portion where Pet.j and Companions.j are

  `debug Tame Beast cleartamed`
  `Tamed Unit Heal Event and items`
  `Tame Beast I Start`
  `Tame Beast ExtraDmg`
  `Tame Beast I Start Copy`
  `Tame Beast I Timer`
  `Tame Beast I Stop`
  `Tame Beast I Finish`
  `Tame Beast Rename`
  `Tame Beast PreventTameDmg`
  `Tamed Unit Dies Permanent`
  `Tamed Unit Dies`
  `Tamed Unit Revival`
  `Tame Beast I Finish 2`
  `Tame Beast II`
  `Tame Beast III`

- These are replaced by `AI.j`
  Folder `Hired Units OLD`
  `Hired Units Init Shops`

### Known Issues
- Full in-map/JassHelper validation is still required for the updated StatsUI/StatsLiteUI frame layout, cached hero XP requirement display, companion profession gathering behavior, and AbilitiesLiteUI registrations for AI class unit types.

### Actions Remaining
- Still more folders and old GUI triggers to be removed, but its important to check whether global variables defined there are in use by the new JASS library. Removing the global variables can break the library and would need modification/fix updates.

## [7.7.2026]

### Player-Facing Updates
- `StatsLiteUI`
  Added a compact frame-based party monitor for player heroes, the active pet, and current companions, with maximize/minimize controls, HP/mana bars, level/status display toggles, and a quick button into the full StatsUI.
  Companion, pet, and tamed-unit status monitoring now uses the new StatsUI/StatsLiteUI frame path instead of relying on the old GUI multiboard update triggers.
- `AI professions`
  AI heroes with profession behavior should no longer get stuck repeatedly trying to mine or gather nodes they cannot actually use because of missing tools, blocked inventory space, insufficient skill, or rejected gather orders.
  Profession failure chatter is now limited to companion-controlled AI units that are close enough to player-owned Nazgrek or Zulkis, preventing distant autonomous AI units from commenting on failed mining/gather attempts.

### Technical Updates
- `StatsLiteUI.j` / `StatsUI.j`
  Added `StatsLiteUI.j` as the frame replacement path for the old GUI multiboard monitor, consuming the existing hero, pet, companion, revive timer, and status globals while leaving full attributes in `StatsUI.j`.
  Added a `Lite Config` button in `StatsUI.j` that opens the StatsLite display configuration section for choosing shown categories and status fields.
  Fixed the `StatsLiteUI.j` header-button compile issue by avoiding a local variable named `button`, which conflicts with the JASS `button` type.
- `QuestGiver.j` / `Pet.j` / `UnitExperience3.j`
  Removed active calls to the old GUI multiboard hooks for companion add/remove, tamed pet add/remove, and tamed level updates. These systems now continue updating the shared companion, pet, tamed-unit, XP, and revive globals that `StatsUI.j` and `StatsLiteUI.j` read directly.
- `Companions/companions-to-do.md`
  Updated the companion migration notes to mark the old multiboard hooks as no longer called by active JASS and to document that the old `UI/MultiboardGUI` map triggers can be disabled once `StatsLiteUI.j` is imported and active.
- `AI.j`
  Added per-instance profession failure tracking and a temporary profession backoff after repeated failed gather attempts, so impossible mining/gather tasks yield back to normal AI behavior instead of monopolizing the idle/wander task loop.
  Hardened profession order startup by rechecking profile profession access, gather skill requirement, free inventory/tool space, temporary tool creation, and accepted order state before treating a gather action as active.
  Added inventory/tool-space gating to ore-unit selection so AI units do not choose mining nodes when they cannot hold or create the required Mining Pick.
  Improved AI debug output to include the unit proper name or unit name plus registered AI class for state changes, registration, random spawn/travel, active-cap hide/show, debug icons, profession actions, social movement, stale-order recovery, and hired-unit initialization.
- `AI_Paladin.j` / `AI_Aveline.j`
  Confirmed Aveline already inherits Warrior profession setup through `AIWarrior_ConfigureProfile`, while Paladin remains a non-mining profile unless explicitly configured later.
- `ResourceRage.j`
  Previously every item pickup, item drop, item use, and spell cast creates a new timer. Usually fine. But if an AI loop or item logic causes repeated item/spell events, this can create a large timer burst. Update to prevents 50 refresh timers for the same unit during one event burst.
  If UnregisterRageUnit(whichUnit) ever returns false, then index is not incremented and RageUnitCount is not reduced. That would create an infinite loop inside RageDecayTick.
  Normally this should not happen, because any unit inside RageUnits[index] should also have a valid RageUnitSlot. But if the table state ever becomes inconsistent, this becomes a hard freeze candidate. Updated to preserve the intended behavior but ensures the loop always progresses.
  Added `AI_Aveline` unit-type `O009` register.
- `ResourceEnergy.j`
  Note: Similar issue as in `ResourceRage` may be within `ResourceEnergy` system. To be checked and possibly updated later. 
- `ExSound.j` 
  Fix incorrect file path for `AI_Restoshaman` (HeroRestoshaman) voicelines

### Known Issues
- Full in-map/JassHelper validation is still required for the 7.7.2026 AI profession safeguards, especially Paladin near ore veins, Aveline/Warrior Mining Pick creation and cleanup, inventory-full behavior, and under-skilled gather-node backoff.
- Full in-map validation is still required after importing `StatsLiteUI.j`, especially frame visibility/config behavior, pet/companion revive status text, and confirming the old `UI/MultiboardGUI` triggers stay disabled without breaking companion or pet monitoring.

## [6.7.2026]

### Player-Facing Updates
- `AI heroes`
  AI heroes with assigned professions can now autonomously harvest nearby gather nodes while idle or wandering, including ore veins, herbalism item nodes, and skinning item nodes when their profile supports the matching profession.
  Autonomous AI heroes can now occasionally move near a friendly AI unit or nearby friendly non-hero NPC and face them briefly, adding a lightweight social ambient behavior without using companion chatter spam.
  Random AI hero population now keeps at least four active random heroes when possible, allows more active random AI heroes at the same time, and keeps a larger hard cap before random spawning stops.
  Added Aveline as a unique Riverbane Warrior AI hero using unit type `'O009'`, with random spawning/travel support and a one-active-unit cap separate from Horde Warrior instances.
  AI ambient/social chatter is now only audible when a player-owned Nazgrek or Zulkis is nearby, preventing player-controlled swaps or temporarily non-player-owned heroes from incorrectly enabling AI chatter.
  Rogue AI now uses its stealth-style Surprise Attack behavior less aggressively during combat.
- `Companions / quest companions`
  Pets and companions no longer silently switch to the other hero when their focused Nazgrek/Zulkis leader dies; they stop until their intended focused leader is valid again.
  Horde-faction AI companions can now be invited at Friendly reputation, while Valeria and Aradion are blocked from normal companion invitation outside their active quest windows.
- `Ranger Missing`
  Kicking Valeria from companions during Ranger Missing now returns the quest objective back to finding her in the field zones.
- `Quests`
  Quest update messages now appear after a short 5-second delay instead of immediately interrupting the moment a requirement is completed.

### Technical Updates
- `AI.j`
  Added AI profession constants, `AI_AddProfileProfession`, `AI_GetProfessionSkill`, per-profile profession flags, per-instance profession/social cooldowns, and profession skill initialization based on unit or hero level.
  Integrated AI profession behavior with `GatherNodes`, `GatherNodeSkills`, `GatherNodeItems`, and `GatherNodeUnits`, including node skill checks, randomized scan timing, temporary Mining Pick/Skinning Knife item handling, and cleanup on death, travel, unregister, and tool expiry.
  Added a new autonomous social state that selects nearby friendly registered AI units or friendly non-hero NPCs, moves to a randomized nearby point, faces both units toward each other, can request a gated idle bark when the player is close enough, and yields to companion control, combat, low-health retreat, boss evasion, and travel.
  Raised default random AI population limits to a 24-unit hard cap, 8 active-visible cap, and 4 active-visible minimum, with a new `AI_SetRandomSpawnActiveMin` API.
  Added unit-type default profile registration, `AI_RegisterUnitByType`, profile register callbacks, and profile random unique ids so shop-sold/hired AI units and unique random profiles can initialize without map-enter hooks.
  Added AI debug minimap icons through `IconQuery` while AI debug mode is enabled, plus extra debug messages for registration, state changes, random spawns, active-cap hide/show, travel start/return, social behavior, and profession harvesting.
  Tightened bark audibility to require nearby player-owned Nazgrek or Zulkis and shortened temporary profession-tool retention after gather orders so Mining Picks/Skinning Knives are cleaned up shortly after use.
- `AI_Warrior.j`
  Exposed shared Warrior profile setup through `AIWarrior_ConfigureProfile`, allowing new Warrior-profile units to reuse the same Warrior ability pool, starting abilities, profession setup, shop items, and combat think callback.
- `AI_Rogue.j`
  Reduced Surprise Attack / stealth action frequency in the Rogue combat decision chain.
- `AI_Aveline.j`
  Added the new `AIAveline` library for the unique Riverbane Warrior Aveline, including profile/unit-type caps of 1, unique id lookup, `udg_Aveline` mapping, Riverbane ownership, random-spawn participation, and Aveline-specific bark keys.
- `AI_LegacyLocations.j`
  Bound Aveline to the Riverbane AI spawn, retreat, and shop location set.
- `Companions.j`
  Preserved focused-leader identity for companions and pets so a dead Nazgrek/Zulkis focus does not automatically fall back to the other hero.
  Changed Horde companion reputation gating to Friendly-or-better and limited Valeria/Aradion invite bypasses to their active Ranger Missing / Rifts of Corruption quest windows.
  Added Aveline as a named Riverbane Warrior companion type for invite metadata, return ownership, minimap/icon handling, class/type/faction text, and ability information.
- `QuestGiver.j`
  Dialog hero resolution now ignores Nazgrek/Zulkis unless the hero is currently player-owned, preventing cinematic/dialog movement from selecting a hero temporarily controlled by another owner.
- `QuestMaster.j`
  Quest update messages now use the queued update path with a 5-second initial delay, including direct `QuestMaster_ShowUpdateMessage` calls.
- `qAradion.j`
  Added a Valeria kick handler for Ranger Missing that resets the quest back to the field-zone find objective and refreshes the quest log/update message.
- `GatherNodeSkills.j`
  Added a generic tracked-gatherer registry so non-player AI units can use the same profession skill gating and skill gain path as Nazgrek/Zulkis, with unregister cleanup for tracked flags, throttles, and stored profession skills.
- `AI_*` sublibraries
  Assigned initial AI profile professions: Warrior and Engineer/Shredder use Mining, Rogue uses Skinning, and Restoshaman uses Herbalism.
- `AI_MasterPlan.md`
  Documented Aveline, random unique profile ids, unit-type default profile registration, and the safe `EVENT_PLAYER_UNIT_SELL` hired-unit initialization path.
- `ResourceRage.j` and `ResourceEnergy.j`
  Key points:
  MUI tracking via per-unit arrays/tables, no singleton NPC_Horde_AI_* state.
  Default auto-registration for AI_Rogue ('O631') and AI_Warrior ('O629').
  Public RegisterUnitType / Register APIs for normal NPC units.
  Mana bar is capped at 100 and treated as the visible resource.
  External mana gains are discarded by stored resource state; real mana spends are accepted.
  Mana potion/replenishment item abilities are blocked.
  Rage uses DamageEngine, per-unit decay timing, Bloodrage support, and fixes the old defense-gain/Bloodrage-target issues.

  Note: These libraries use centralized GUI trigger "Init 07 Unit Event Enters" to get new unit spawning to map.

### Known Issues
- CRITICAL: Do not add new standalone `Unit - A unit enters (Playable map area)` / `TriggerRegisterEnterRectSimple(GetWorldBounds())` / playable-map enter hooks in individual systems. Route all unit-enter initialization through the existing GUI trigger `Init 07 Unit Event Enters`, which currently dispatches `CreepRespawn_OnUnitEnter(GetTriggerUnit())`, adds the unit-specific Floating Texts spell event, and calls `UnitStats_ProcessUnit(GetTriggerUnit())`. Duplicated map-wide enter hooks are a known cause of severe map stalls/hangups where units stop responding to player/controller movement.
- Full in-map validation is still required for AI profession harvesting and social movement, especially inventory-full behavior, skinning node coverage, mining orders against all vein owner types, and interactions with companion orders or quest-controlled AI.

## [5.7.2026]

### Player-Facing Updates
- `AI companions`
  AI companion invite/reinvite handling now immediately refreshes follow orders, companion minimap icon setup, and stale idle state so newly invited AI companions do not remain standing still.
  AI barks now respect player distance, cinematic/dialogue state, companion-only contexts, and anti-overlap cooldowns so AI heroes should no longer spam or talk over each other.
  Orc and Undead Warlock AI profiles now keep separate bark/chat pools so different race variants can use different voicelines.
- `Ranger Missing`
  Re-inviting Valeria now explicitly completes the "Find Valeria in Vanguard Vale, Verdant Plains, or Redwind Pass" objective in the quest log/update message and restores the "Escort Valeria to Aradion" objective.
- `Rifts of Corruption`
  Valeria and Aradion companion setup now repairs ownership and creep-guard state before adding them to the companion system, preventing quest companions from remaining Neutral Passive during field phases.
  Re-inviting Valeria or Aradion during active Aradion quest phases now refreshes the matching quest objectives and companion state.
  Rifts waves now repeatedly retarget toward Aradion during the ritual, completed rituals kill the active mana-rift handles more reliably, and returning home updates the objective to speak with Aradion.

### Technical Updates
- `AI.j`
  Added runtime AI debug toggles through `/debug ai` and `/debug aidebug`, plus public debug mode API helpers for future AI sublibraries.
  Added shared bark range checks, cinematic/dialogue suppression, companion-only bark gating, per-instance/per-bark cooldowns, and a short global bark gap to replace the old spam-prone GUI chat timing pattern.
  Added AI cast-order guards using `udg_UnitIsCasting`, plus small randomized ability and consumable timing jitter so AI instances do not all issue periodic orders on the same exact tick.
  Fixed a JASS declaration-order issue in `PlayBarkReply` by using the internal instance table instead of calling the generated `AI_GetInstance` wrapper before it is declared.
- `AI_Warlock.j`
  Split Warlock registration so Orc Warlock `'H60X'` remains the voiced `HeroWarlock_*` profile while Undead Warlock `'O61K'` uses its own profile and race-specific bark/chat data.
  Shared Warlock combat, shop setup, and imp ownership logic between both profiles without sharing their voiceline pools.
- `AI_Voicelines.j`
  Added separate `HeroUndeadWarlock_*` bark, long-chat, and reply text keys for Undead Warlock so matching ExSound assets can be imported later without reworking the AI profile.
- `Companions.j`
  Repaired AI companion add flow by clearing stale idle/order state, issuing an immediate follow/defend order toward the focused leader, refreshing Always-mode companion icons, and returning Orc Warlocks to the AI Horde owner on kick.
- `qAradion.j`
  Added a companion-command bridge for Valeria/Aradion reinvite repairs, switched Ranger Missing Valeria control to follower behavior, repaired the Ranger Missing reinvite requirement/log update path, fixed Rifts intro Valeria placement, and tightened Rifts return-home objective handling.
- `AI_MasterPlan.md`
  Documented the no-underscore vJASS library naming rule, generated public API prefix expectations, and the newer AI chatter gating/cooldown rules.

### Known Issues
- Full in-map compile and runtime validation are still required for the AI follow-up changes, especially AI bark timing, Warlock imp behavior for both unit types, Shaman totem MUI behavior, companion reinvite/order repair, and the Rifts handoff fixes.
- Undead Warlock voiceline text keys are implemented, but the matching sound files still need to be created/imported before the profile has full audio coverage.

## [4.7.2026]

### Player-Facing Updates
- `AI heroes`
  Began the large AI hero migration from old GUI trigger trees into JASS libraries. AI heroes can now be managed as independent instances instead of being limited to one singleton Warrior, Rogue, Warlock, Shaman, Paladin, or Engineer global.
  Added random AI hero spawning through the new AI registry, including the debug chat command `/debug aispawn`.
  Added random AI travel support where AI heroes can temporarily leave the map by being hidden/paused and later return without losing their registered unit handle or AI state.
  Added hard random-spawn and active-visible caps so random AI heroes stop spawning when the population cap is full, and returning/revived random AI heroes stay hidden if the active cap has no open slot.
  Valeria can now use the `AI_Valeria` combat profile while still allowing patrol and quest scripts such as `qAradion` to own scripted movement.
- `Companions / pets`
  Shadowclaw is now treated as a normal Wolf in pet metadata instead of being described as a Spirit Wolf.
  Pet ability inspection from StatsUI now opens the normal Abilities UI instead of printing the old text-only ability summary to the game message area.
  Shadowclaw and pets tamed with Tame Beast III now keep their companion/follower minimap icon while fatigued or fake-dead, while lower-rank tames still die permanently and clean up their pet state.
  Companion command abilities now replay the old GUI feedback sounds for invite, hired-unit add, focus, mode changes, information, and kick flows.
- `Quest companions`
  Aradion and Valeria can now be re-invited through quest-related companion paths without being blocked by the normal Elarindor Covenant reputation requirement.

### Technical Updates
- `AI.j`
  Created the master JASS AI registry/state engine for class/profile/unit-type/unique identity, per-instance Table state, caps, spawning, random spawning, travel, revive/death handling, companion-aware behavior gates, consumables, shared ability helpers, boss-cast evade hooks, and ExSound/DialogSystem chatter dispatch.
  Replaced old singleton-driven AI assumptions such as `udg_NPC_Horde_AI_Warrior` with registry lookups, profile/class/unit-type caps, and optional unique ids for named special units.
  Added a random-managed population layer separate from normal quest/cinematic AI registrations, so random AI caps do not hide or block manually registered unique AI units.
- `AI_*` sublibraries
  Created the first-wave AI class/profile libraries for Warrior, Rogue, Warlock, Restoshaman, Paladin, Engineer, and Valeria.
  Moved class-specific combat decisions, ability pools, starting abilities, bark registrations, Warlock imp ownership, Shaman totem ownership, Engineer/Shredder behavior, and Valeria retreat-like combat behavior out of GUI patterns and into profile sublibraries.
  Added reusable generic AI profile factories for generic, aggressive, passive, civilian, guard, scripted, vendor, caster, healer, and boss NPC behavior so future units can register into the AI system without copying a full hero-class sublibrary.
  Added `AI_Aradion` as a non-autonomous quest-character AI profile similar to `AI_Valeria`, with defensive retreat behavior and opt-in combat orders so quest scripts can keep ownership of scripted movement.
  Added `AI_LegacyLocations.j` for old GUI spawn, retreat, and shop location bindings, keeping map-specific generated rect/unit globals out of the class logic.
  Added `AI_CompanionReplies.j`, `AI_Voicelines.j`, and the ODS-backed voiceline import data for AI barks, long idle/moving chats, companion replies, and ExSound/DialogSystem migration.
- `Companions.j`
  Added a companion command-event bridge so AI libraries can react to invite, kick, mode changes, and drop-items commands with profile bark logic instead of relying on old GUI chat triggers.
  Added a command sound replay helper so repeated companion command sounds restart reliably, and restored old rescue/upkeep/good-job feedback sounds on the matching JASS command paths.
  Added an Aradion/Valeria quest-companion reputation bypass for reinvite checks while leaving the normal faction requirement intact for regular companion hiring.
- `PetDefinitions.j`
  Added a shared pet definition library for pet and tameable unit rawcodes, raw meat item checks, pet class/role/ability text, stat-profile families, and pet Abilities UI definition keys.
  Moved Shadowclaw, wolf, bear, feline, turtle, stag, boar, and moth metadata out of duplicated `Pet.j` / `UnitExperience3.j` helper logic so the pet systems read one shared definition source.
- `Pet.j`
  Pet registration now records whether a pet is persistent. Shadowclaw and Tame Beast III pets use fatigue/revive behavior, while Tame Beast I/II pets are allowed to die permanently and then clean up companion control, XP, damage hooks, multiboard state, and active pet globals.
  Pet metadata helpers now delegate to `PetDefinitions.j`, including tameable checks, raw meat checks, class text, role text, and ability summary text.
- `UnitExperience3.j`
  Pet stat-profile classification now delegates to `PetDefinitions.j`, removing duplicated pet unit-type tables from the XP/stat system.
- `StatsUI.j` / `AbilitiesLiteUI.j`
  StatsUI now routes selected pet ability inspection directly into `AbilitiesLiteUI_ShowForUnit`.
  AbilitiesLiteUI now registers pet-family ability templates for training, inventory, fatigue, revive, and raw-meat recovery details when a pet unit is selected.
- `IconQuery.j`
  Companion/follower icon validation is now category-aware, allowing registered companion/pet unit entries to stay visible while fake-dead without making normal icon categories show dead units.
- `World Editor trigger cleanup`
  Disabled the old AI GUI triggers in the `AI Wandering` folder now that the JASS AI libraries own the replacement behavior path.
  Deleted the obsolete `CAMERA SYSTEMS OLD` folder and its old trigger set.
  Removed old camera command trigger usage for `trailer1`, `trailer1snow`, and `trailer2`.
- `AI_MasterPlan.md`
  Updated the AI migration plan to document the implemented random spawn manager, active/hard random caps, random travel return behavior, Valeria non-autonomous profile mode, and current AI test expectations.

### Known Issues
- Full in-map JASS compile and runtime validation are still required for the new AI library stack, especially random spawning, multiple same-profile AI instances, companion invite/kick/mode barks, Warlock imp ownership, Shaman totem ownership, Valeria/qAradion control handoff, and old GUI trigger retirement.
- Full in-map validation is also still required for the new pet definition split, pet Abilities UI templates, Tame Beast I/II permanent death cleanup, Tame Beast III fake-death icon persistence, and Aradion/Valeria reputation-bypass reinvite path.
- `TravelShipB Moknatha Enter` may still reference old camera behavior. It should stop using deleted old camera triggers and route ship-enter camera behavior through `CameraControl`.

### Actions Remaining
- Re-test `/debug aispawn`, timed random AI spawning, active/hard caps, cap-hidden returns, travel returns, death/revival, companion commands, ExSound bark playback, and multi-instance Warrior/Rogue/Warlock/Shaman/Paladin/Engineer behavior in-game.
- Re-test StatsUI pet Abilities button behavior, AbilitiesLiteUI pet entries, Shadowclaw metadata text, companion command sounds, Shadowclaw/Tame Beast III fatigue icons, Tame Beast I/II permanent death cleanup, and Aradion/Valeria reinvite after kick.
- Update `TravelShipB Moknatha Enter` so the camera can target the travel ship when appropriate, but still switch back to Zulkis or Nazgrek when they are not considered inside the ship.
- Confirm no old `AI Wandering` GUI trigger path remains enabled after the new JASS AI libraries are imported and wired into the map build.

## [3.7.2026]

### Player-Facing Updates
- `Companions / pets`
  Companion command-card abilities now resolve correctly after invite/reinvite, including Passive/Normal/Aggressive/Hold modes, Kick Companion, Focus Nazgrek/Zulkis, Information, and Drop Items from companion-owned command cards.
  Shadowclaw now keeps Nazgrek as the initial pet focus, walks back to `NazgrekIntroPoint` when kicked, and only teleports home after 120 seconds if stuck or still away from home.
  Shadowclaw now registers as a Nazgrek-focused pet during startup but can stay halted during the intro cinematic until the companion system is resumed.
  Pets now use the fatigue/fake-death flow on fatal damage instead of dying normally, and active pets are included with companions when dungeon or zone movement relocates the hero.
  Aradion and Valeria now return to Elarindor ownership and can be invited back after being kicked from the companion group.
  Companion/follower map icons now support an `Always` setting that is the default for companions and pets, keeping their icons visible without extra pings unless they are actually too far from the focused hero.
  Far-away companion and pet map icons now continue to work while Hold Position mode is active.
- `StatsUI`
  Kicking Shadowclaw or another pet now clears the active pet display instead of showing Shadowclaw through the old fallback when `udg_TamedUnit` is empty.
  Companion and pet icons in StatsUI now prefer the real unit object icon before falling back to companion metadata icons.
  Companion and pet Class, Type, and Abilities details now come from `Companions.j` / `Pet.j` unit metadata, and fake-dead pets are shown through the pet library status instead of misleading current HP.
- `Ranger Missing`
  Valeria now starts her home patrol again after the reunion completion flow recreates her at Aradion's home position, restoring the old GUI behavior where she waits at Aradion before continuing her route.
  The quest now fails if Valeria is lost while the quest is in progress or ready to turn in, including during the successful negotiation transition.
- `Rifts of Corruption`
  Accepting the quest no longer teleports Valeria away for the intro staging when she is already near Aradion; she is instead ordered to move normally toward her home/start position.
  Aradion and Valeria now remain companion-mode quest units during the field phase, but use follower-style visuals and stop behavior when they are too far away.
  Leaving Vanguard Vale, Verdant Plains, or Redwind Pass now pauses Aradion/Valeria companion/follower orders, updates the quest log, and shows a quest update message; returning to a valid field zone shows a rejoined update and resumes their companion/follower behavior.
  Aradion and Valeria now show left-behind map icons and pings when they are outside valid field zones and far from the focused hero.
- `Item floating text`
  Items dropped by units and destructibles now use the shared item-name floating text presentation, matching DInv-origin item drops.
- `Weather`
  Wind weather is now shorter and much less frequent, especially in zones where wind was previously the only available dry-weather result.

### Technical Updates
- `Companions.j`
  Added defensive GUI-state repair so missing companion/focus groups are created and `udg_CompanionUnit[]` entries are re-added to `udg_Companion_Group` before command/order enumeration, keeping `CinematicMover`, StatsUI, and old GUI consumers in sync.
  Added `Companions_Halt`, `Companions_HaltAll`, and `Companions_ResumeAll` for cinematic-safe companion/pet order suspension on top of the existing per-unit resume path.
  Companion-owned command-card casts now map back to the real control player for selected-unit lookup and can fall back to the casting companion/pet itself.
  Companion focus commands now play the old GUI `GoodJob` sound, and empty companion icon paths now fall back through the existing `BlzGetAbilityIcon(unitTypeId)` lookup when possible.
  Added Aradion and Valeria named-companion metadata, icons, Elarindor faction text, info text, and Elarindor return-owner handling so the generic invite flow can restore them after a kick.
  Added companion class/type/ability metadata APIs for StatsUI and companion information output, plus a follower-behavior profile for quest companions that should stay in companion mode while still using follower-style effects and leash-stop behavior.
  Companion far-icon registration now separates icon visibility from pinging so the `Always` setting can keep icons visible while pings still only fire when the unit is outside the configured follow distance.
- `Pet.j`
  Ensures `udg_TamedUnits` exists before pet registration, forces Shadowclaw registration toward Nazgrek, and clears `udg_TamedUnit` before old multiboard pet-removal hooks run.
  Added delayed Shadowclaw init retry, intro-aware pet suspension, explicit Shadowclaw leader assignment, and DamageEngine lethal-damage clamping for pet fatigue.
  Moved pet Class, Type, and Abilities text into pet-library helper functions, including separate class helpers for wolves, bears, felines, turtles, stags, boars, moths, and Shadowclaw.
- `ZoneEvent.j`
  Centralized controlled-unit collection for zone transitions so `udg_Companion_Group`, `udg_TamedUnits`, and the explicit active `udg_TamedUnit` are all moved with the entering hero.
- `StatsUI.j`
  Replaced the hardcoded Shadowclaw icon fallback with the same object-icon-first lookup used by the abilities UI, retaining quest companion icons as fallback metadata.
  StatsUI now reads companion/pet Class, Type, and Abilities through `Companions.j` / `Pet.j` instead of keeping those definitions local, and treats pet fake-death status as Dead through `Pet.j`.
- `IconQuery.j` / `SettingsUI.j`
  Added the per-category `Always` mode, exposed it through the existing Settings category button cycle, and made companions/followers default to `Always`.
- `qAradion.j`
  Added a near-Aradion guard to the Rifts intro preparation path, restarted Valeria's home patrol after the Ranger Missing fade-black home recreation callback, and cleaned up the completion timer local.
  Added Ranger Missing Valeria death protection through a fatal-damage clamp plus a global death fallback, with duplicate failure protection during quest reset.
  Rifts field companions now use companion follower behavior instead of escort-mode follow logic, Redwind Pass is accepted as a field zone, and invalid-zone ticks strip Aradion/Valeria from companion/follower control until the player returns to a valid zone.
  Added leave/rejoin quest update messages and quest-log objective refreshes for the Rifts field zone gate, including correct requirement handling during both the rift-search phase and the escort-home phase.
  Added temporary left-behind IconQuery markers and minimap pings for Aradion/Valeria while they are outside valid field zones and far from the focused hero.
- `ItemLootSystem.j` / `ItemLootDestructibles.j`
  Unit and destructible item drops now call the shared item floating-text helpers so dropped loot consistently displays item-name floating text.
- `WeatherSystemV4.j` / `ZonesCore.j`
  Reduced wind durations and wind weather weights, and added an extra wind start gate so wind-only weather pools no longer keep wind active too often.

### Tool Updates
- `WC3ItemManager`
  Fixed destructible loot-table export selection so destructibles with a selected named loot table now emit `RegisterDestructibleTable` and `RegisterDestructibleDropEx` even when their loot mode is `Generic`; `Generic` with no named table still falls back to level/tier registration, while `Both` remains additive and `None` stays disabled.
  Rebuilt the `bin/Debug/net8.0-windows` debug executable after the exporter fix, so launching `WC3ItemManager.exe` now uses the corrected destructible loot-table export logic.

### Actions Remaining
- Re-test invited companions with `CinematicMover`, selected-unit mode casts, companion self command-card casts, Kick Companion on non-pet companions, Shadowclaw kick/reinvite, and StatsUI pet rows in-game.
- Re-test Ranger Missing completion to confirm Valeria waits at Aradion before patrolling, and accept Rifts of Corruption while Valeria is already near Aradion to confirm she is not teleported away.
- Re-test Shadowclaw intro halt/resume, initial Nazgrek focus without casting Focus Nazgrek, pet fatigue/revive, pet dungeon transfers, Aradion/Valeria reinvite after kick, Ranger Missing Valeria death during negotiation, wind pacing in affected zones, and in-map destructible drops from the newly exported named loot tables.
- Re-test the companion/follower IconQuery `Always` setting, far-away icons while Hold Position is active, StatsUI companion/pet Class/Type/Abilities, Rifts leave/rejoin zone updates, Rifts left-behind icons/pings, and floating text from unit/destructible loot drops.

## [2.7.2026]

### Player-Facing Updates
- `Vanguard Vale`
  Continued terrain work in Vanguard Vale, including additional pathing blockers and general terrain/pathing polish.
- `Void Entity`
  Added the WIP `Void Entity` boss as a hidden initial map presence for future quest-related use, possibly tied to Aradion's questline.
  The boss can currently be revealed for testing with the debug command `/debug VoidEntity`.
- `Ranger Missing`
  Valeria now hard-resets to her home spot after the reunion completion instead of immediately resuming her home patrol.
- `Rifts of Corruption`
  Mana-rift ritual starts are more reliable across all three rifts, with the player hero and Aradion both required near the rift area.
  Rift waves now arrive more often, stop spawning near the final ritual countdown, and Valeria's "They are too many!" line is reserved for sustained or overlapping waves instead of normal wave spawns.
  Completed rituals now kill the current indexed mana-rift unit directly, and Aradion/Valeria followers stay active in Vanguard Vale, Verdant Plains, and their child zones.
- `Item floating text`
  Items transferred from DInv into vanilla inventory now show their item-name floating text again when later dropped from the vanilla inventory.
- `Steam Breath`
  Steam breath effects are now removed from units when they die, so dead units no longer keep the breath visual attached.
- `Companions / pets`
  Companion and pet control modes now keep normal companions following the focused hero without the escort-style leash stop, while Hold Position still keeps them stationary.
  Kick Companion can now resolve a selected companion or pet when the control ability has no explicit target unit.

### Technical Updates
- `QuestGiver.j`
  Added shared quest-giver helpers for recurring qXXX boilerplate: dialog hero resolution, hero line insertion, dialog-sequence start handling, quest accept/fail/complete button wiring, quest metadata application, preferred unit lookup inside a rect, reusable quest-unit recreate/reposition handling, and field-unit reset-to-position cleanup.
  These helpers let quest giver sublibraries keep more of their custom content local while moving repeatable setup, lookup, and lifecycle behavior into the upper quest-giver system.
- `DialogSystem.j`
  Added shared field-line queue helpers for estimating field-line duration, clearing queued field lines, and queueing delayed field barks from quest runtime systems.
- `qAradion.j`
  Refactored Aradion's quest-giver library onto the new shared `QuestGiver` and `DialogSystem` helper APIs, removing local copies of common dialog, button, metadata, field-line, unit-lookup, unit-recreate, and unit-reset patterns.
  The file was reduced from over 4000 lines to roughly 3700 lines while keeping Aradion/Valeria-specific encounter, rift, Fading Sparks, and dialogue behavior inside `qAradion`.
  Converted the external progression helpers to proper public library APIs, so the exposed names are `qAradion_SetBackstorySeen` and `qAradion_SetRangerMissingReq1Complete`.
- `UnitSpawn.j`
  Fixed `Wave.getRemainingCount()` so checking live wave counts no longer empties the tracked wave group.
- `FollowSystem.j`
  Re-enabled the `TargetPreSelected.mdl` following ring as a persistent effect that hides/shows via alpha and scale instead of being destroyed during normal follow-state transitions, avoiding residual visuals from the model's missing death animation.
- `Companions.j` / `Pet.j`
  Merged the old GUI companion and pet control flow into JASS libraries. `Companions.j` now owns companion invite/kick, hired-unit add/reject, focus target selection, information/drop-items commands, non-hero companion death cleanup, idle/wander state maintenance, and Passive/Normal/Aggressive/Hold control modes.
  Normal companions and pets now use a dedicated companion-order controller instead of `FollowSystem.j`, so Passive/Normal/Aggressive modes no longer stop issuing follow orders when the focused hero is outside the escort max range.
  Added explicit escort behavior opt-in through `Companions_SetEscortBehavior`, allowing quest-specific followers such as Ranger Missing Valeria to keep using `FollowSystem.j` while normal companions, hired units, invited units, and pets stay on companion orders.
  Companion control modes now apply to selected companion/pet units when one is selected, and fall back to the full companion/pet group when no controlled unit is selected.
  Far-away normal companions and pets now register through the companion/follower `IconQuery` category and ping their location while outside the companion follow distance, matching the existing follower visibility workflow without giving normal companions an escort leash.
  Kick Companion now supports selected-unit fallback for both companion and pet paths, fixing casts where `GetSpellTargetUnit()` was empty.
  Rebuilt the old `Companion Information` behavior with name, unit type, attack type, faction, shared stat, ability, current mode, focus, life, mana, damage, and armor output.
  Rebuilt the old `Companion Idle or Move` core behavior in JASS: companions and pets now gain/remove `Wander (Neutral)` during idle checks and update `udg_CompanionUnitIdle[]`, while Hold/Suspended units stay stationary. The old GUI branch that cleared `CompanionUnitIdle[0]` was corrected to use the picked unit custom value.
  `Pet.j` now owns Shadowclaw initialization/reinvite, Tame Beast I/II/III, pet registration, pet kick, fatigue/revival, raw-meat healing, pet rename, and the tame-channeling damage multiplier while using the companion control layer for follow behavior.
  Cleaned up JASS compile-order/tooling issues by moving the pet damage-trigger refresh below `OnPetDamaged` and replacing `bj_lastCreatedTrigger` use in `Companions.j` with explicit spell/sell trigger handles.
  Kept compatibility with the current GUI globals and old multiboard hooks, including `udg_Companion_Group`, `udg_CompanionUnit[]`, `udg_CompanionCount`, `udg_TamedUnits`, `udg_TamedUnit`, `udg_TM_*`, and the multiboard add/remove triggers.
  Added `Companions/companions-to-do.md` to track remaining legacy GUI variable usage, disable-now GUI triggers, and follow-up work for chat barks, AI migration, and the later `StatsBoardUI.j` replacement.
- `QuestGiver.j`
  Mirrored companion icon/index/reference writes into `udg_CompanionIcon[]`, `udg_CompanionIndex[]`, and `udg_UnitHider_ReferenceUnits[]` so current GUI multiboard code can keep reading the legacy arrays until the later `StatsBoardUI.j` rewrite.
- `SteamBreath.j`
  Registered `SteamBreathSystem` through a library initializer so its centralized `UnitDeathEvent` callback actually runs, switched the death cleanup to `GetDyingUnit()`, and made single-unit cleanup destroy all tracked steam effects for the dying unit.
- `ItemLootSystem.j` / `SharedDInvLib.j`
  Added a per-item custom drop-text marker for DInv-origin items moved into vanilla inventory, so `EVENT_PLAYER_UNIT_DROP_ITEM` can recreate item-name floating text instead of treating unregistered item types as Common rarity with disabled text.

### Tool Updates
- `qxxx-generator.html`
  Updated the qXXX generator to emit scaffolds that use the newer shared quest-giver helpers for metadata, hero resolution, quest buttons, and dialog flow.
  Replaced stale `TODO OLDGUI PARITY` wording with `TODO QUEST-SPECIFIC` so new quest-giver templates reflect the current JASS quest system instead of the removed GUI-trigger workflow.
  Added the standard PotS library header, safer generated function ordering, public hook signatures, handle-local cleanup, leaner core `requires`, and per-quest recommended-level metadata.
  Updated generated dialog selection to use `QuestGiver_StartDialogEntryTransition` / `QuestGiver_StartDialogExitTransition` with generated camera and cinematic constants, set dialog context before raw dialog display, and fixed real-number formatting for dialog range/cooldown values.

### Actions Remaining
- Decide how the hidden `Void Entity` boss should be connected to quest progression, including whether it belongs in Aradion's questline.
- Re-test `qAradion` in-game after the helper extractions, especially Valeria recreation at home/ambush, Ranger Missing completion, Rifts of Corruption rift binding/retry/return-home behavior, field-line barks, and the public progression hooks.
- Disable the old GUI companion/pet triggers listed in `Companions/companions-to-do.md`, then test companion invite/kick, hired units, focus swaps, selected-unit mode changes, Companion Information, Companion Idle or Move, Shadowclaw, Tame Beast ranks, pet fatigue/revive, pet rename, and old multiboard rows in-game.
- Move companion/pet bark triggers into the later AI library update and replace the current GUI multiboard hooks with the planned `StatsBoardUI.j` work.
- Re-test DInv-to-vanilla item transfers by moving a named item into vanilla inventory and dropping it from there, confirming the floating text appears and cleans up normally on pickup/use.
- Continue the next modularization pass only after the practical helper extraction is verified; the remaining larger candidate is a reusable `DialogSystem` choice/response dialog scaffold for Valeria-style persuasion prompts.

## [1.7.2026]

### Player-Facing Updates
- `Ranger Missing`
  Valeria's failed negotiation choices can now be reopened with `ESC` after the current hero/Valeria lines finish, failed quests no longer respawn Valeria until the player re-accepts the quest, and the successful negotiation branch now removes the old Valeria before adding the companion version.
  The Aradion return step now accepts Valeria within a wider 500 range, and Valeria no longer leashes back toward her original spot when the reunion completion scene starts.
  Completing the reunion now forces Valeria out of companion/follow state so leftover follower indicators do not remain on her.
- `Rifts of Corruption`
  Void units now telegraph their arrival with delayed `vortex1.mdx` portal effects, including portal birth and death sounds at the spawn point.
  Rift rituals can now start at any unclosed mana rift in any order, and completing a ritual now removes the placed mana rift unit from its active slot.
- `Quest item tracking`
  Item collection quests now refresh against items already carried by the hero, and DInv-managed items are no longer double-counted when mirrored through vanilla inventory slots.
- `Map icons / Settings`
  Icon query/rest timing changes now apply immediately from Settings instead of waiting for the previous timer phase to expire.
  Companion/follower icons now honor the Settings toggle, icon visibility/rest ranges were expanded, and quest givers plus companions/followers are prioritized ahead of secondary icon categories.
  Flight master and ship master travel icons can now be shown together during the travel icon query pass.
  Map icon pings can now be disabled while keeping icon reveals, and icons can now be switched from query mode to all-icons timed or all-icons always-visible display modes.
  Each icon category now supports `Query`, `On`, and `Off` states in Settings; companion/follower icons default to `On`, while other categories default to `Query`.
- `Difficulty`
  Added active `Story`, `Normal`, and `Hard` difficulty profiles wired into Settings, with configurable native difficulty, health/damage, gold, XP, and revive pacing hooks.

### Technical Updates
- `qAradion.j`
  Reworked Valeria retry, recreation, ownership, stale companion cleanup, negotiation prompt rearming, completion range, and quest-fail reset behavior for `Ranger Missing`.
  Routed `Rifts of Corruption` void waves through delayed portal spawning with vortex create/destroy sounds and sticky attack-move orders toward Aradion.
  Hardened `Rifts of Corruption` cleanup by removing Valeria and Aradion from companion/follow state on fail/finish paths, selecting the nearest valid unclosed rift for ritual starts, and clearing killed `PlacedManaRifts` handles after ritual completion.
- `UnitSpawn.j`
  Added delayed wave spawn APIs that support pre-spawn special-effect birth and timed-destroy sounds while preserving the existing delayed spawn calls.
- `QuestGiver.j` / `SharedDInvLib.j`
  Added item-requirement refresh APIs and a lightweight periodic requirement scan, then made DInv charge counting skip vanilla-slot handles that are still owned by DInv.
- `QuestMaster.j`
  Quest-giver overhead effects now refresh immediately when a quest is accepted, so an accepted/on-going quest with no newly available quests switches to the question mark state.
- `IconQuery.j` / `SettingsUI.j`
  Added immediate timer restarts, per-category query durations, configurable category query frequencies, wider query/rest clamps, and Settings UI controls for secondary icon pacing.
  Added a configurable `IconQuery` travel-master grouping option, enabled by default, so flight master and ship master markers reveal as one grouped query step.
  Added `IconQuery` ping enablement and display-mode APIs, plus Settings UI buttons for ping toggling and cycling query/all-timed/all-always icon display.
  Replaced category on/off toggles with per-category mode cycling and renamed the secondary icon pacing control to clarify that it affects travel, boss, and place query categories.
- `FollowSystem.j`
  Follower minimap indicators now register through `IconQuery`, allowing companion/follower icon visibility to be controlled centrally.
  Re-applying follow state now clears the previous follow entry first, and the risky `TargetPreSelected.mdl` following ring is disabled by default to avoid residual companion visuals after removal.
- `Difficulty.j`
  Added a central difficulty library with apply/read APIs and configurable player/hostile handicap multipliers for future gameplay systems.

### Actions Remaining
- Re-test the full `Ranger Missing` fail/re-accept/negotiate/turn-in path, Rifts portal wave telegraphs/sounds, any-order rift ritual starts, mana rift removal after ritual completion, carried-item quest progress, DInv/vanilla item count parity, IconQuery category pacing, companion/follower icon toggles, and the new difficulty profiles in-game.

## [30.6.2026]

### Player-Facing Updates
- `Chimairo`
  Added a test ability, `Poison Nova`, based on Flame Strike and using the newly imported `Poison Nova` model.

### Technical Updates
- `GatherNodeDefinitions`
  Tested startup-freeze isolation by disabling `GNU_SpawnInitialAll()` inside `DelayedSpawn` in the gather-node definitions export sublibrary; this had no effect on the freeze.
  Also tested disabling the `DelayedSpawn` call from `DelayedInit`; this also had no effect on the freeze.
- `SettingsUI.j`
  Confirmed the post-loadscreen game-start freeze was fixed by hardening the Settings UI slider refresh path. The likely risky path was slider value synchronization firing `FRAMEEVENT_SLIDER_VALUE_CHANGED`, re-entering `SETUI_SliderAction`, and calling `SETUI_Refresh` again.
  Hardened the settings slider synchronization with cached slider values, a slider-action re-entry guard, null-safe sync helper, and initial slider value setup before slider frame-event registration.
- `IconQuery.j`
  Kept `IconQuery` active after the Settings UI fix; no obvious unbounded JASS loop was found in code review. Its loops are bounded by registered icon count or category count, and its query timer restarts at configured delays.
  Remaining work is to tune the IconQuery parameters and pacing now that the startup freeze is no longer blocking in-game testing.

### Known Issues
- `IconQuery tuning`
  Startup freeze is fixed in the latest in-game test after the `SettingsUI.j` slider re-entry hardening, but IconQuery timing/category parameters still need adjustment and validation.

### Actions Remaining
- Adjust `IconQuery` query/rest timing and category parameters, then validate in-game pacing with quest-giver minimap icons enabled.
- Continue watching startup stability while testing IconQuery changes, since the earlier freeze was tied to UI/event refresh behavior at game start.

## [29.6.2026]

### Technical Updates
- `SettingsUI.j`
  Delayed Settings UI TOC loading and frame creation to a `0.20` timer callback, matching the safer `CameraUI.j` / `MasterUI.j` startup pattern instead of creating the slider-backed settings frames immediately during library initialization.

### Actions Remaining
- Re-test map startup in-game to confirm whether the post-loadscreen freeze still happens after the `SettingsUI.j` delayed-initialization fix.

## [28.6.2026]

### Player-Facing Updates
- `Map icons / Settings`
  Added a Settings panel to the in-game `Game` menu with controls for quest/travel/boss/place/companion icon query categories, query timing, rest timing, and a map difficulty placeholder.

### Technical Updates
- `IconQuery.j` / `QuestMaster.j`
  Added a centralized minimap icon and ping query scheduler that keeps registered icons hidden and reveals one icon at a time by category, with a configurable rest delay after each full pass. Quest giver minimap icons now register through `IconQuery` instead of being shown immediately.
- `MasterUI.j` / `SettingsUI.j`
  Added a `Settings` menu button and a standalone settings UI for icon query toggles, timing clamps, map difficulty state, and future settings placeholders.

### Imports
- `Imported asset backlog`
  Added a list of imported models/effects to check for future usage, with possible placement/ability ideas tracked in MS ToDo.
- `Gnome Tinker - Gunstriders` (by Villagerino):
  `AutomatedMechanostriderv`, `GnomeTinkerGrenade.mdx`, `GnomeTinkerGunstriderHero.mdx`, `GnomeTinkerGunstriderUnit.mdx`, `GnomeTinkerTracerAmmo.mdx`, `GunstriderGunImpact.mdx`
- `Firenova.mdx` (by Sarsaparilla, Blizzard Entertainment)
- `vortex` (by GAQ):
  `vortex1.mdx`, `vortex2.mdx`, `vortex3.mdx`, `vortex4.mdx`, `vortex5.mdx`, `vortex6.mdx`, `vortex7.mdx`, `vortex8.mdx`
- `Poison Nova` (by Sarsaparilla)
- `Ring` (by Sarsaparilla, Blizzard Entertainment):
  `Ring.mdx`, `Ring_small.mdx`
- `Skill Indicator` (by BaiyuGalan):
  `Skill_Indicator_Circle`, `Skill_Indicator_Haymaker`, `Skill_Indicator_Move`, `Skill_Indicator_Ring`, `Skill_Indicator_Sector`, `Skill_Indicator_Square`, `Skill_Indicator_Straight`, `Skill_Indicator_Straight2`
- `Thunder Nova.mdx` (by Sarsaparilla, Blizzard Entertainment)
- `ZooCage.mdx` (by purparisien)

### Actions Remaining
- Replace the old World Editor travel minimap toggle trigger with `IconQuery` registration calls for flight masters, ship masters, and route points, then validate the query pacing in-game.

## [26.6.2026]

### Player-Facing Updates
- `Ranger Missing`
  Hardened Valeria persuasion so the `ESC` choice prompt cannot reopen while Nazgrek/Valeria voice lines or transition beats are still running.
- `Fading Sparks`
  Tel'anor Rod extraction now accepts additional configured wraith unit-type placeholders and shows floating text for the created `Wraith Essence`.
- `Rifts of Corruption`
  Valeria now stages much farther behind the player before moving into Aradion's intro scene, public/region-started rift rituals can resolve the correct rift in any order, and respawned Aradion/Valeria handles now rebind quest hooks.
- `Item floating text`
  DInv ground drops and quest-created drops now create item-name floating text, while item floating text is hidden unless the player hero is within 1000 range.
- `Camera / Zone transitions`
  Fast camera pans now rebind the active camera mode after snapping to the target, middle mouse button presses reset stored camera state, Boom Mine camera angle is locked top-down, and Shadowmaw Cave exits defer Sirensong parent-zone activation so the parent zone can enter normally.
- `Quest rewards`
  Quest XP, gold, arena, reputation, and item rewards now pay from the 5-second delayed quest-completion callback instead of immediately when the dialog/cinematic completion function runs.

### Technical Updates
- `qAradion.j`
  Added an explicit Valeria negotiation speech-busy guard, failed-log-preserving Ranger Missing retry reset, configurable Fading Sparks wraith-type checks, Rifts intro staging from the interacting hero, safer any-order ritual fallback, and a respawn hook refresh API for Aradion/Valeria.
- `QuestMaster.j`
  Moved `awardRewards()` into `ShowDelayedQuestCompleted`, so all quest reward side effects occur together after `QUEST_COMPLETED_DELAY`; reputation reward calls still bypass the reputation system cinematic guard only inside that delayed payout.
- `CreepRespawn.j` / `CreepUnitAssignment.j`
  Fixed native respawn assignment by updating `bj_lastCreatedUnit` before `CreepUnitAssignment`, then added Aradion/Valeria quest-hook refresh after their respawn assignments.
- `ItemLootSystem.j` / `SharedDInvLib.j`
  Added 1000-range item floating-text visibility gating and wired DInv ground placement into the item floating-text API.
- `CameraControl.j`
  Reapplies the current camera mode after public target pans, handles middle mouse button camera-state reset events, and makes Boom Mine's special camera non-adjustable at its configured top-down angle.
- `ZoneEvent.j`
  Changed parent-zone handoff after interior exits to reset child-zone state before teleporting out and force-enter the parent only if the normal parent enter trigger does not run.
- `GatherNodeItems.j` / `GatherNodeUnits.j`
  Fixed initial gather-node lifetime despawn tracking by switching the lifetime tables to the correct `.real` accessors for `has` / `remove`, so untouched spawned nodes can expire and schedule fresh spawn attempts again.

### Tool Updates
- `WC3ItemManager`
  Gather-node export now uses the spawn-group zone id for grouped unit spawn points and logs a warning when a spawn point row carries a mismatched zone id, preventing stale point-level zone data from exporting the wrong `ZonesCore` zone.

### Known Issues
- `CameraControl.j`
  Boom Mine camera is now angle-locked, but the requested centered camera offset still needs a targeted AdvancedCamera/proxy-unit implementation and in-map tuning.
- `Quest rewards`
  XP and reputation rewards still need direct in-map confirmation after quest completion, including the cinematic turn-in path patched today.

### Actions Remaining
- Re-test Ranger Missing persuasion timing, Fading Sparks extraction against all configured wraith types, Rifts any-order starts/fail flow, DInv/drop floating text distance visibility, quest XP/reputation rewards, Boom Mine camera behavior, and Shadowmaw-to-Sirensong zone activation.
- `WC3ItemManager`
  Fix remaining item stackability data issues, including cases like `Mana Crystals` and `Wraith Essence` that still stack only to `1` when they should allow larger stacks.

## [14.6.2026]

### Player-Facing Updates
- `Ranger Missing` / `qAradion.j`
  Valeria's escort step now transitions into `Speak with Aradion The Farseer`, and selecting Aradion at that point starts the reunion completion directly instead of relying on a separate completion dialog button.
  The Valeria persuasion `ESC` prompt is now delayed until the intro combat beat has finished, and the standoff keeps the hero and Valeria facing each other more consistently while persuasion is available.
  The correct persuasion answer now runs through its own fade-backed reunion beat before Valeria's follow-up lines, instead of snapping straight through the success state, and Valeria's home-return recreation is timed to the fade-black phase of the reunion completion exit.
  Tightened the Valeria intro and reunion presentation again: Nazgrek now stops/faces Valeria immediately when the encounter opens, `ESC` persuasion choices are cleared as soon as a response is selected so they cannot reopen during the hero line, and the Aradion reunion turn-in now pushes stronger hero-to-speaker facing through the exchange.
- `Rifts of Corruption`
  Aradion and Valeria now return through a proper quest-owned companion runtime instead of the older direct follow-only path, helping both companions behave more like real party companions during escort/combat phases.
  Rift rituals no longer snap both units into teleported ritual offsets at start; Aradion now enters a dedicated ritual state while Valeria stays under companion control.
  Closed rifts are now removed immediately on success, the all-closed bark order is closer to the old GUI sequence, and ritual failure no longer snaps both units home instantly before the surviving companion reacts.
  Tightened more of the old-GUI ritual presentation and fail flow: Valeria now stages farther away before moving into the Aradion start scene, ritual/field lines are queued one by one instead of overlapping, fail text now splits correctly between `X has died.` and `X fell during the ritual.`, and the survivor reaction / delayed retry reset now plays out before both companions are restored home.
- `Fading Sparks`
  Successful Tel'anor Rod extraction now kills the Mana Wraith at the same time the `Wraith Essence` drop is created.
- `Camera / Zone transitions`
  Mouse-wheel camera reset now snaps back into the active camera mode again, and teleport-style subzone entries refresh the tracked camera target before the fast pan is applied.
- `StatsUI.j`
  Shadowclaw now stays visible as a named/iconed pet entry even when the generic `udg_TamedUnit` tracking path is missing.
- `ItemLootSystem.j`
  Dropped powerup hover text now also self-cleans when the item vanishes before the normal pickup/use handlers remove its floating text.

### Tool Updates
- `WC3ItemManager`
  Item ability tooltip headings and per-ability labels now use the defined `Ability` item-class color instead of the old hardcoded tooltip colors.
- `WC3ItemManager`
  Added batch edit support for multi-selected items directly from the main item list. The new batch editor only applies fields explicitly changed/checked by the user, so shared updates such as `base_id`, rarity, class, type, `wc3_classification`, costs, levels, tooltip text, asset paths, and main WC3 item flags can now be pushed safely across selected items without overwriting untouched fields.
- `WC3ItemManager`
  Cleaned up the current build setup for the active desktop toolchain by excluding generated `obj` / `bin` / temp build folders from compile input, then restored a clean normal `bin/Debug/net8.0-windows` debug build after recovering from the blocked output/intermediate folder state encountered during today's ItemManager session.
- `WC3ItemManager`
  Fixed destructible loot-table export parity so assigned destructible loot tables now generate their table-level drop chance, drop-count range, and per-item quantity/chance/weight data into the `ItemLootDefinitionsDestructible` output instead of only exporting generic destructible levels or older direct specific-drop rows.

### Technical Updates
- `Companions.j`
  Added a new quest-friendly companion wrapper over `QuestGiver` and `FollowSystem`, with defend/passive/hold modes plus suspend/resume handling for scripted companion control.
- `QuestMaster.j`
  Aligned quest reward awarding closer to the old GUI reward flow: XP now also reaches hero companions in `Companion_Group`, and faction reputation reward calls now always route through `AddReputation` / `AddReputationLinked` when a faction is set.
  Failed quests now mark properly as failed in the Warcraft III quest log and clear that failed flag again on accept, complete, abandon, and reset paths.
  XP reward delivery now also falls back explicitly to `udg_Nazgrek` / `udg_Zulkis` when they are valid hero units but were missed by the current Player 1 hero enumeration path.
- `qAradion.j`
  Moved more of Aradion/Valeria field control onto the new companion runtime, added direct-select Ranger Missing completion handling, reworked the Valeria success branch into a lead-in line plus timed cinematic transition, and reworked the Rift fail/reset state around delayed retry cleanup instead of immediate home reset.
- `Reputation.j` / `ReputationUI.j`
  Added an event-driven `ReputationUI` refresh hook so faction reputation changes now refresh the currently open UI immediately, while reopening the panel also forces a fresh rebuild instead of trusting the previous cached row state.
- `ZoneEvent.j`
  Updated teleport-style fast-pan handling so `ZoneEvent` refreshes `CameraControl` target cache immediately after move-start teleports before applying the fast pan.
  Interior exits now only honor the currently active child zone on shared exit rects, and they hand zone state back to the parent zone on exit so Shadowmaw-style cave re-entry does not stay blocked by stale `currentZone` state.
- `ItemLootDestructibles.j` / `ItemLootSystem`
  Extended the newer destructible loot runtime so destructible loot tables can now roll a table-level chance first, apply guaranteed table items, perform weighted extra rolls using the configured drop-count range, and honor per-entry quantity ranges. This fixes the newer ItemManager destructible-table path that previously ignored named-table semantics and behaved closer to legacy per-entry direct rolls or generic-tier fallback.

### Known Issues
- `qAradion.j` / `Rifts of Corruption`
  Today's non-teleport ritual start, companion-combat behavior, third-rift escort-home state, sequential bark ordering, death-text split, closed-rift cleanup, and delayed fail-reset flow still need direct in-map verification across all three rifts.
- `QuestMaster.j` / quest rewards
  The updated reward parity path still needs live confirmation for XP on hero companions, XP fallback on Nazgrek/Zulkis, failed-quest log state, and reputation reward delivery on actual quest completion.
- `qAradion.j` / `Rifts of Corruption`
  The current JASS-side channel-animation fix removes the forced stuck spell pose, but the portal-closing ability itself may still need object-editor validation if it continues to override Aradion's looping channel animation in Warcraft III.
- `ZoneEvent.j` / `Shadowmaw Cave`
  The stale interior-zone state path and shared-exit-rect overlap have now been patched, but Shadowmaw Cave still needs direct gameplay validation to confirm the enter-rect issue is fully gone in-map.
- `Item loot systems`
  The older `ItemDropSystem` / `ItemDropDestructible` path still exists in the repo as a legacy/manual loot system and is not driven by `WC3ItemManager` exports. Maps still importing that older runtime instead of `ItemLootSystem` + `ItemLootDestructibles` will not use the newer destructible loot-table data until their imports are aligned.

### Actions Remaining
- `qAradion.j` / `Ranger Missing`
  Re-test the full Valeria encounter and reunion flow: intro timing, `ESC` persuasion timing, facing lock, correct-answer fade beat, escort completion, black-phase home return, and direct-select turn-in on `Speak with Aradion The Farseer`.
- `qAradion.j` / `Rifts of Corruption`
  Re-test all three rifts as the first target, repeated proximity while a ritual is active, Valeria intro staging, closed-rift retry prevention, bark ordering, death-text split, third-rift escort-home transition, and the delayed death/fail reset flow.
- `QuestMaster.j` / quest rewards
  Re-test XP, gold, and reputation rewards on real quest completions, including hero companions inside `Companion_Group`, Nazgrek/Zulkis fallback XP, and failed-quest quest-log state.
- `ReputationUI.j`
  Re-test that opening `ReputationUI` always refreshes the visible list and that live faction reputation changes refresh the open UI immediately without needing a manual close/reopen.
- `CameraControl.j` / `ZoneEvent.j`
  Re-test mouse-wheel reset and fast-pan behavior on the intended interior/subzone teleports, including Shadowmaw Cave re-entry after exiting through the shared cave-out rect.
- `Destructible loot`
  Re-export the loot JASS from `WC3ItemManager`, then verify in-map that destructibles assigned named loot tables now follow the configured table chance/count behavior and that the active map import path is the newer `ItemLootSystem` / `ItemLootDestructibles` runtime instead of the old `ItemDropSystem`.

## [13.6.2026]

### Player-Facing Updates
- `ItemLootSystem.j`
  Fixed dropped-item floating text cleanup for powerups so their hover text is now removed when the powerup is consumed on pickup instead of lingering after use.
- `StatsUI.j`
  Restored the pet presentation fallback in `StatsUI` so Shadowclaw no longer degrades into a generic `Pet` entry without a proper name/icon.
  Companion rows now also prefer quest-registered companion icon paths instead of relying only on the weaker generic unit icon lookup fallback.
- `Camera / Zone transitions`
  Camera reset inputs now snap the view back into the currently active camera mode immediately, so mouse-wheel and `PageUp` / `PageDown` usage no longer leave the player outside the intended live camera state.
  Teleport-style entries into selected caves, interiors, and dungeon subzones now fast-pan the camera directly to the tracked hero unit instead of letting the view linger at the old location after a far transition.
- `qAradion.j`
  Reworked more of the `Ranger Missing` Valeria encounter toward the old GUI behavior: the intro now uses stronger old-style facing/camera timing, persuasion response choices spoken through `ESC` now play during normal gameplay instead of entering a mini-cinematic, and the correct persuasion answer now lets the hero finish speaking before Valeria stops attacking and transitions into the friendly success path.
  Improved `Ranger Missing` reunion flow so the completion exchange uses more explicit old-GUI-style facing beats, and Valeria's return-home recreation is now deferred into the fade-black window instead of snapping too early while still visible.
- `Rifts of Corruption`
  Stabilized the mana-rift start path so `qAradion` now binds the three real placed main-map Mana Rift objects directly as its canonical rift slots before any fallback recreation logic, bringing the quest closer to the old GUI `QuestRifts[1..3]` behavior.
  Continued the runtime restoration pass: Rift completion now tracks closed portals properly, the objective text now splits out `Rifts closed X / 3`, the escort-home phase now uses `Escort Aradion and Valeria to Aradion's place`, and Aradion should only become turn-in ready after both companions have actually been escorted back home.
  Improved the post-ritual companion flow so Aradion and Valeria return with defend-style follow/combat behavior instead of passive movement-only follow, and the escort-home phase no longer teleports Valeria away immediately after the last portal closes.
  Restored more old-GUI-style ritual behavior: Aradion now re-applies his portal-closing channel if interrupted, the start/combat/finish lines are routed through proper unit transmissions, and the return-home phase now uses generic return lines instead of still reusing portal-combat warnings.
- `Fading Sparks`
  Restored the missing Tel'anor Rod extraction runtime in `qAradion`: using `A04W` on a sufficiently weakened Mana Wraith now follows the old GUI-style 2-second extraction flow and creates `Wraith Essence` on success.

### Tool Updates
- `WC3ItemManager`
  Generated fresh ItemManager debug logs and new `ItemData_20260613_*.w3t` exports during today's database/tooling session.
- `WC3ItemManager`
  Continued the current `ItemManager` development pass around WC3 item-data parity, manual-ability handling, tooltip generation, icon-path normalization, powerup auto-use integrity, and item-class presentation.
  Added support paths for richer WC3 ability lookup/import usage in the toolchain, including ability tooltip-related schema updates and related importer/exporter compatibility work needed by the active item-database workflow.
  Improved ItemManager handling for item classes and class-driven presentation so newer slot/class entries such as `Ability` and `Skill` can be seeded into the database and used more consistently by the tool.
  Added and aligned item-class color handling work for ItemManager so class headers/tooltips can use intended colors instead of falling back toward generic gray/default presentation.
  Fixed WC3 tooltip color output for class/rarity headers so ItemManager now writes valid opaque WC3 color codes for saved item text instead of older legacy variants that could still appear gray in-game even when the tool preview showed the intended class color.
  Added export-side normalization in the `.w3t` pipeline so older saved tooltip strings using legacy `|c00RRGGBB` formatting are rewritten into valid `|cFFRRGGBB` color codes during item export, helping class headers such as `Ability` keep their intended color in Warcraft itself.
  `ItemManager_debug` is the current latest version and shall be used for managing the PotS database at this time.
  The `Release` ItemManager build is not yet the current authoritative version and will be updated later after the ongoing debug-side development pass is stabilized.

### Technical Updates
- `ItemLootSystem.j`
  Extended item-loot hover-text cleanup to listen to both pickup and item-use events, covering immediate powerup consumption paths that were not fully handled by the pickup-only trigger.
- `TasQuestBoxLight_PotS.j`
  Locked the legacy standalone `Zones` open button behind library-level visibility handling so it no longer reappears through older `Unhide` / `SetButtonVisible` paths.
  `Zones` access is now kept routed through `MasterUI` instead of exposing the old direct button again.
- `QuestGiver.j`
  Added a small public companion-icon accessor so shared UI code can read the currently registered icon for companion rows directly from the quest companion registry instead of duplicating lookup state.
- `StatsUI.j`
  Added explicit Shadowclaw fallback handling for display name/icon resolution and switched companion icon resolution to use the `QuestGiver` companion registry before falling back to generic runtime lookups.
- `DialogSystem.j`
  Hardened the shared `ESC` action path so a questgiver can safely clear or replace its own registered escape callback while that callback is executing, preventing self-destroy / stale-trigger issues during non-sequence dialog flows.
- `CameraControl.j`
  Removed the old normal-mode safe / no-clipping correction path from active runtime use, added a safer special-camera preset configuration structure for future internal rect-driven camera modes, fixed the stuck-rotation case when chat is opened during arrow-key camera turning, and cleaned up special-camera helper ordering so the library follows plain JASS call-order rules.
  Added a reusable fast target-pan helper, and changed mouse-wheel / `PageUp` / `PageDown` reset handling so it immediately reapplies the player's currently active camera mode instead of only restoring the older normal-mode path.
- `CameraUI.j`
  Removed the obsolete `Safe Camera` / no-clip toggle button and related readout so the camera panel now matches the current `CameraControl` runtime instead of exposing the retired legacy option.
- `qAradion.j`
  Added more quest-owned Valeria encounter helpers for hero-camera swap timing, standoff movement, standoff facing, and delayed success-state application so the persuasion runtime matches the old GUI pacing more closely without pushing every branch through cinematic-mode handling.
  Split Valeria persuasion into two clearer runtime paths: wrong answers now use live gameplay dialog only, while the correct answer applies the hostile-stop / ownership-reset transition only after the hero line has played.
  Added a `PlacedManaRifts[1..3]` binding block in `InitDelayed` and updated rift-slot resolution so the three exact WE Mana Rift globals are the first source of truth inside `qAradion`, with rect-based lookup retained only as fallback for recreated rifts after failure/reset.
  Kept the additional rect/range fallback guards around rift start detection so main-map ritual start is more resilient if a placed rift is replaced later during quest fail/retry handling.
  Added a larger Rift-state cleanup pass: closed-rift tracking now prevents completed portals from being recreated/restarted, ritual follow-up objectives now stay `IN_PROGRESS` until the escort-home step is actually completed, and the field monitor now waits for the hero, Aradion, and Valeria all to reach `AradionPlace` before flipping the quest to turn-in ready.
  Reworked field-dialog handling for the Rift runtime so speaker lines use `DialogSystem_PlayLine` transmissions with a small local queue instead of stacking bare timed text, reducing overlap between Aradion/Valeria and bringing ritual dialog flow closer to the old triggers.
  Switched the Aradion/Valeria escort runtime from passive follow toward defend-style follow and removed the unnecessary Valeria ghost re-apply on ambush reset, reducing several newer-runtime behavior mismatches from the old quest chain.
  Added the missing `Fading Sparks` spell-event runtime for `A04W`, including effect / finish / endcast handling, target validation against Mana Wraiths, extraction timing, and quest-owned item creation on successful completion.
  Cleaned up several newer local-handle leak candidates in the Valeria encounter / Rift event code and fixed more struct/handle cleanup mismatches discovered during the leak pass.
- `QuestGiver.j`
  Added unregister/removal paths for `FindNPC`, `GoToPlace`, and `Reputation` requirement polling so those timers can shut down cleanly once their tracked requirements are completed instead of accumulating permanent background checks over the whole session.
  Fixed `GetReputationLevel` so the local `Faction` value is treated as the integer-backed struct id it actually is, avoiding the invalid `set f = null` cleanup path.
- `QuestMaster.j`
  Corrected the reputation reward calculation path so quest reputation rewards are computed from quest level plus adjustment instead of using the broken truncated multiplier-only formula.
- `ZoneEvent.j`
  Added a narrow fast-pan-on-enter path for teleport-style cave / interior transitions and selected dungeon entries so zone-owned camera effects can immediately recenter the view on the tracked hero after long-distance subzone jumps without affecting normal border crossings.

#### Lag and possible leak investigation
From the 8-13 June 2026 changelog entries, the strongest suspects are not the new DialogSystem ESC hook, but the newer camera and quest-runtime polling.

High: [UI/CameraControl.j (line 876)](/h:/Pelit/PotS_JASS/UI/CameraControl.j:876) is the clearest FPS risk. CC_DriftTimer runs every 0.03 seconds, and for each normal-mode player it can call [CC_UpdateNormalEffectiveDistance (line 510)](/h:/Pelit/PotS_JASS/UI/CameraControl.j:510), which ray-traces the camera path in 50-unit steps and, on blocked samples, falls back to [EnumItemsInRect path checks (line 205)](/h:/Pelit/PotS_JASS/UI/CameraControl.j:205). With the default 1650 distance, that is roughly 30+ samples per recompute. This matches the changelog suspicion almost exactly: heavy periodic work, no leak required, just raw CPU.

High: [QuestsAndDialogs/QuestGiver.j (line 1898)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGiver.j:1898), [QuestsAndDialogs/QuestGiver.j (line 1986)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGiver.j:1986), and [QuestsAndDialogs/QuestGiver.j (line 2085)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGiver.j:2085) start permanent polling timers for FindNPC, GoToPlace, and Reputation. I found no matching unregister/destroy path for those timers anywhere in the file, while their counts only ever increase at [1881 (line 1881)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGiver.j:1881), [1971 (line 1971)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGiver.j:1971), and [2070 (line 2070)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGiver.j:2070). That means every such requirement ever registered leaves background polling behind for the rest of the session. This is a good explanation for “lag gets worse nowadays”.

Medium-high: qAradion now uses both trigger-based rift detection and a separate 0.50 second field monitor. The trigger path is registered in [RegisterRiftUnits (line 1695)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:1695) and [RegisterRiftsProximityTrigger (line 1825)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:1825), while the poll loop is started at [OnAcceptQuest4End (line 2696)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:2696) and runs in [OnRiftsFieldTick (line 2195)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:2195). That poll loop repeatedly scans all rifts and calls [GetAllowedRiftHeroForIndex (line 1953)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:1953), even though the in-range trigger already exists. It is not the worst offender, but it is new, always-on during the quest, and redundant.

Medium: qAradion has classic JASS handle-leak candidates in the newer timer/event code. Examples: [OnValeriaEncounterRandomTick (line 760)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:760) creates a timer and never nulls local t; [OnValeriaEncounterRangeTick (line 780)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:780), [OnRiftsProximity (line 1798)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:1798), [OnRiftsFieldTick (line 2195)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:2195), [GetAllowedRiftHeroInRange (line 1932)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:1932), and [GetAllowedRiftHeroForIndex (line 1953)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:1953) all use local unit handles without nulling them before exit. If your build path still behaves like classic JASS, these are real long-session leak candidates.

Medium-low: [QuestsAndDialogs/QuestMaster.j (line 2749)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestMaster.j:2749) refreshes availability for every quest giver every 5.00 seconds from [Init (line 2756)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestMaster.j:2756). This is not a leak, but it is global background work that scales with content.

Low: qAradion also creates a texttag every second during each rift ritual at [OnRiftsCountdownTick (line 2081)](/h:/Pelit/PotS_JASS/QuestsAndDialogs/QuestGivers/qAradion.j:2081). Those tags do expire, so this is churn rather than a leak, but a full 3 x 120s run still creates a lot of short-lived UI handles.

### Known Issues
- `ItemLootSystem.j`
  Today's powerup floating-text cleanup fix was not yet verified live in Warcraft III. The immediate check still needed is that dropped powerup text disappears correctly when the item is auto-consumed on pickup.
- `CameraControl.j` / `ZoneEvent.j`
  Today's immediate camera-reset and fast zone-pan changes were not yet verified live in the main map. The affected paths still need gameplay confirmation in normal, advanced, and special camera modes, plus a quick pass through the intended teleport-style cave/interior/dungeon entries.
- `WC3ItemManager`
  The current authoritative build is the debug build, not the release build. Until the release package is refreshed, any newer ItemManager fixes should be verified against `ItemManager_debug`.
- `qAradion.j` / `QuestSystems`
  Today's Valeria encounter and mana-rift binding changes were not yet verified end-to-end on the live main map after the code pass. The latest behavior still needs direct gameplay confirmation, especially around `ESC` persuasion flow, post-success hostile stop timing, and ritual start from each real Mana Rift.
- `qAradion.j` / `Rifts of Corruption`
  The ritual-start path is now bound to the placed Mana Rift units, but the Aradion portal-closing cast / custom ability ownership path still needs in-map validation against the current runtime.
  The newer escort-home completion path still needs direct gameplay verification after today's state-flow fixes: confirm no early question mark appears on Aradion, no premature Valeria teleport occurs after the last portal, and the quest only becomes turn-in ready once both companions actually reach Aradion's place.
- `QuestSystems` / `qAradion.j`
  The current QuestSystems and Aradion-related quest fixes still need a focused end-to-end test pass before `qAradion` is restructured into a more modular questgiver/template-friendly layout for reuse by other libraries.

### Actions Remaining
- `ItemLootSystem.j`
  Re-test dropped powerups on the main map and confirm their floating text is removed both on normal pickup and on immediate auto-use consumption.
- `CameraControl.j` / `ZoneEvent.j`
  Re-test camera reset inputs with mouse wheel and `PageUp` / `PageDown`, then verify the fast-pan behavior on the intended far-transition subzones such as cave/interior teleports, Boom Mine, Gnoll Hideout, The Crypt, and Firelands.
- `WC3ItemManager`
  Update the release ItemManager package later so it matches the current debug build once the ongoing item/database tool changes are considered stable enough to freeze into release.
- `qAradion.j` / `QuestSystems`
  Re-test the full Valeria encounter on the main map: intro facing/camera, `ESC` prompt, wrong-answer live gameplay responses, correct-answer stop timing after the hero line, and the follow-up escort progression.
- `qAradion.j` / `Rifts of Corruption`
  Re-test all three real Mana Rift starts on the main map and confirm that placed-rift binding, ritual start, Aradion cast behavior, and fail/retry rift recreation all still resolve back into the correct local `qAradion` rift slots.
  Re-test the full last-rift-to-home flow: objective swap to `Escort Aradion and Valeria to Aradion's place`, no early complete-quest question mark on Aradion, no immediate home teleport after the last closure, and turn-in unlock only after the escort-home step is actually done.
- `QuestSystems` / `qAradion.j`
  Finish the current quest-runtime validation pass before advancing to the next planned refactor, then structurize `qAradion` into a more modular and template-friendly questgiver library only after the present Aradion/QuestSystems fixes are confirmed stable in gameplay.

## [11.6.2026]

### Player-Facing Updates
- `qAradion.j`
  Reworked the `Ranger Missing` Valeria encounter closer to the old GUI flow: the intro now uses the old-style close camera values again, persuasion is opened with `ESC`, and the actual persuasion response / success exchange no longer runs as a full cinematic-mode sequence.
  Improved Valeria negotiation behavior so choosing the correct persuasion line now stops her attack immediately instead of letting the hostile combat state linger awkwardly into the success path.
  Fixed `Ranger Missing` progression so Valeria's ghost/invisibility state is removed when the quest advances and the escort step now appears immediately as `Escort Valeria to Aradion` instead of only surfacing too late in the chain.
  Improved `Rifts of Corruption` setup so Valeria is pulled near Aradion for the quest-start exchange and her patrol is stopped before the field follow/escort phase begins.

### Technical Updates
- `DialogSystem.j`
  Added a small reusable `ESC` action hook for non-sequence dialog flows: `DialogSystem` can now execute a registered escape callback when no dialog sequence is currently active, instead of hard-wiring every `ESC`-driven side flow inside each questgiver library.
  Kept the existing sequence-skip behavior intact, so `ESC` still skips active sequences first and only falls back to the custom escape action when no sequence is playing.
- `qAradion.j`
  Replaced the old local Valeria-specific `ESC` trigger with the new shared `DialogSystem` escape-action path so future `qXXX` libraries can reuse the same pattern for similar non-cinematic interaction prompts.
  Restored Valeria encounter camera values toward the old GUI setup and split the negotiation runtime into a lighter non-cinematic branch that hides dialog/UI correctly without forcing full cinematic mode.
  Added stronger quest-owned handling for Valeria ghost state, escort objective text, retry reset state, and ambush reset so the `Ranger Missing` chain no longer depends on leftover GUI assumptions for those pieces.
  Added a local mana-rift proximity trigger path inside `qAradion` so `Rifts of Corruption` can begin ritual logic from quest-owned JASS event handling instead of relying only on the timer-polled field check.
  Restored an Aradion ritual-start cast order at the rift-start point and hid the obsolete `TasQuestBox` / `Zones` UI during quest-dialog sequences to reduce old cinematic/UI bleed-through.

### Known Issues
- `qAradion.j` / `Rifts of Corruption`
  The restored ritual-start cast path still needs in-map verification. Aradion is now ordered to cast at ritual start again, but the custom portal-closing ability ownership/rawcode path has not yet been fully revalidated against the current map runtime.
- `QuestSystems` / `qAradion`
  Today's Valeria encounter and rift-start fixes were not yet verified live on the main map after the code pass, so camera feel, UI hiding, escort progression, and the new rift proximity trigger still need gameplay confirmation.

### Actions Remaining
- `qAradion.j` / `QuestSystems`
  Test the full `Ranger Missing` chain again on the main map: intro camera, `ESC` persuasion prompt, hostile stop on correct answer, ghost removal, escort objective creation, escort completion, and turn-in flow.
- `qAradion.j` / `Rifts of Corruption`
  Re-test quest accept, Valeria patrol shutdown, Valeria placement near Aradion, mana-rift ritual start, and Aradion portal-closing cast on the main map.
- `QuestSystems`
  If today's `ESC` prompt pattern proves stable, reuse the new shared `DialogSystem` escape-action helper for later `qXXX` libraries instead of rebuilding separate ad hoc `ESC` triggers per questgiver.

## [10.6.2026]

### Player-Facing Updates
- `qAradion.j`
  Reworked the Valeria encounter so it behaves closer to the old GUI version: after the opening exchange, the player is prompted to press `ESC` to open the persuasion choices instead of being forced through chained negotiation options automatically.
  Softened the Valeria encounter close-up camera so it no longer uses the earlier aggressive low-angle setup that could clip under the terrain during the encounter.
  Improved the `Ranger Missing` quest chain so escort completion now cleanly transitions into the return-to-Aradion phase instead of leaving the quest in a broken mixed state with missing follow-up objective handling.
  Failed `Ranger Missing` runs are now reset toward a retryable offer path rather than leaving the quest in an unusable failed state that still showed stale dialog branches.

### Technical Updates
- `QuestGiver.j`
  Synced JASS companion add/remove handling with the shared GUI companion arrays and counters so quest-added companions such as Valeria are visible to systems that rely on `udg_CompanionUnit[]`, including companion-facing UI like `StatsUI`.
  Fixed escort requirement progression so escort objectives no longer write `(Complete)` into the requirement text before the quest log also marks them complete, which was causing duplicate `(Complete) (Complete)` output.
  Added the shared return-to-questgiver requirement automatically for escort objectives when the escort actually reaches the destination, bringing escort handling in line with the other tracked requirement types.
  Updated shared dialog transition helpers so cinematic-style quest entry and exit can consistently hide and restore the `MasterUI` `Game` button.
- `QuestMaster.j`
  Hardened quest state transitions so completing a quest now clears stale failed state and completed quests can no longer be failed again afterward by late event callbacks.
  Kept required-level evaluation aligned with the allowed-heroes rule: when both `Nazgrek` and `Zulkis` are allowed, the highest valid hero level is used, and when only one hero is allowed, only that hero's level is used for availability checks.
- `qAradion.j`
  Continued moving Aradion / Valeria quest-owned event behavior into the `qAradion` sublibrary so the new JASS quest path owns more of the `Ranger Missing` runtime directly instead of depending on scattered old GUI trigger behavior.
  Standardized the `Ranger Missing` retry/reset path around local JASS helpers so escort failure, Valeria-loss handling, turn-in safety, and reset-to-ambush behavior all follow the same library-owned flow.
  Added extra guards around Aradion dialog rebuilds, ready-turn-in handling, and retry offers so the main-map availability flow has fewer chances to fall into the earlier yellow-to-red quest-marker regression path.
  On the "`qXXX` libraries are getting large" point: they are larger mainly because quest-owned event logic is intentionally being kept local to the owning sublibrary for now.
  No further extraction should be forced before main-map verification; the next safe shared candidates, if this passes testing, are silent objective-reset helpers and generic field-ritual runtime helpers only if the second quest giver repeats the same pattern.

### Known Issues
- `QuestSystems` / `qAradion`
  The newest Aradion fixes still need full main-map verification, especially the availability-marker behavior after the `Info` branch, Valeria negotiation flow, and the complete `Ranger Missing` escort-to-turn-in chain.

### Actions Remaining
- `Bridges`
  Add invisible platforms to `Bridge009`.
- `Bridges`
  Adjust pathing-blocker rects at `Bridge009`.
- `QuestSystems` / `qAradion`
  Re-test the newest Aradion changes on the main map before treating the current JASS quest-giver pattern as frozen for generator-driven `qXXX` production.

## [9.6.2026]

### Technical Updates
- `TerrainDamage.j`
  Completed a direct lag-isolation test with TerrainDamage disabled and confirmed that turning the system off did not reduce the periodic lag spikes in any significant way.
  This makes TerrainDamage much less likely to be the main source of the recurring `20-40` FPS drops, such as falling from roughly `90` FPS to `60`.
- `CameraControl.j`
  Continued troubleshooting the remaining periodic performance drops and current testing suggests that normal camera mode's automatic safe / no-clipping adjustment path is a more likely source of the troublesome lag than TerrainDamage.
  The next direction is to think more aggressively about running normal mode without constant safe-camera correction and relying more on internally activated special camera modes in specific zones / rects where custom camera behavior is actually needed.
  This also points toward expanding `CameraControl` so special camera modes can be handled more easily both internally and externally beyond the current Boom Mine-specific path.

### Known Issues
- `CameraControl.j` / normal camera mode
  Normal mode camera adjustment currently looks like the more problematic performance path. The automatic no-clipping / safe-camera correction still needs more profiling and likely a design simplification pass if it is causing the recurring drops.
- `QuestSystems` / `qAradion`
  During testing, entering dialog with Aradion can incorrectly turn his quest exclamation mark from yellow to red even when a quest should still be available.
  While the marker is red, the interaction appears to get stuck at the `Info` section and does not continue into the expected quest-accept flow. After exiting dialog, the marker turns yellow again.

### Actions Remaining
- `TerrainDamage.j`
  Re-enable TerrainDamage after the latest isolation test, because disabling it did not meaningfully improve the lag spikes and it should no longer stay bypassed on the assumption that it is the main culprit.
- `CameraControl.j`
  Explore a lighter normal-camera design that avoids always-on safe / no-clipping adjustment where possible, and rely more on deliberate special-camera-mode activation in selected zones or rect-driven situations.
  If zone- or rect-specific manual camera behavior is still needed outside Boom Mine, add an easier internal and external special-camera handling path in `CameraControl.j` for more than one special camera profile.
- `QuestSystems` / `qAradion`
  Investigate why Aradion's quest marker flips from available-yellow to unavailable-red on dialog entry, and why that state change blocks access beyond the `Info` branch until the dialog is closed again.

## [8.6.2026]

### Technical Updates
- `CameraControl.j`, `ZoneEvent.j`
  Added an internal special-camera-mode path so zones can temporarily override the player's active camera behavior without overwriting the stored base camera mode or its saved parameters.
  Added `CAMERA_SPECIAL_MODE_BOOMMINE` and wired `Zone104 Boom Mine` through `ZoneEvent` special-effects handling so entering the zone applies the Boom Mine camera and leaving it restores the player's stored camera mode and values.
  Reworked the Boom Mine special camera so it now supports the same keyboard angle / rotation controls as normal mode, but keeps that adjustment in special-mode-local state instead of polluting the player's stored normal camera settings.
  Limited Boom Mine camera angle-of-attack adjustment to a maximum of `295` while keeping its own internal distance, far z, angle, rotation, and field-of-view values separate from the normal camera profile.
  Further softened normal-mode blocker tracing so safe-camera correction does not react as heavily to pathing found too far toward the intended camera endpoint, reducing restless bounce during gameplay.
- `WE Mainmap` - `Cinematic ON`, `Cinematic OFF`, `Intro Cinematic`
  Verified that intro-style cinematics now return through the shared camera flow correctly after the earlier `Cinematic ON/OFF` suspend / resume trigger fixes, instead of fighting the stored player camera state during cinematic shutdown.
- `QuestGiver.j`, `qAradion.j`, `QuestsAndDialogs/QuestGivers/tools/qxxx-generator.html`
  Continued the `qAradion` parity-and-modularity pass so the current JASS quest giver behaves more like the old GUI version while also becoming the reusable template for future `qXXX` quest-giver sublibraries.
  Added shared `QuestGiver` sequence scaffolding such as `CreateBaseSequence(...)`, kept the more generic accept / farewell helpers for cases where shared banter fits, and moved `qAradion` quest accept / complete flow onto the new lower-level reusable base path so unique questgiver dialog can stay custom without rewriting sequence setup every time.
  Added a small local browser generator that emits `q<Name>.j` questgiver templates with quest blocks, dialog-button wiring, handler stubs, public hook placeholders, and explicit `TODO OLDGUI PARITY` markers instead of generating only an empty shell.
  Reworked `qAradion` Ranger Missing, item-turn-in, and Rifts flow further toward JASS-owned quest logic, including escort/fail trigger setup, companion handling, ready-turn-in gating, and more stable dialog hero / cinematic return handling.
  Fixed a strict compile-order problem in `qAradion` by moving `OnRangerMissingValeriaDamaged` before the trigger registration that binds it.
- `PatrolFollowSystems/Patrols/Valeria_Movement_Start.j`, `qAradion.j`
  Updated `ValeriaMovementStart` to use a local unit variable instead of `udg_TempUnit`, which is the safer direction for the other patrol-start functions that still depend on the shared temp-unit pattern.
  Updated `qAradion` to call `ExecuteFunc("ValeriaMovementStart")` when restarting Valeria's patrol because this patrol-start entry point is still a plain function and not a JASS library API.
- `QuestsAndDialogs/Plans/_otherPlansAndHelpers`
  Reorganized several older quest/dialog reference markdown files into the shared helper/plans folder so the historical crash notes, requirements notes, and refactoring references are grouped in one place instead of being scattered across the top-level `QuestsAndDialogs` folders.

### Player-Facing Updates
- `Camera / Zones`
  Entering Boom Mine now switches to a dedicated zone camera profile, and leaving it returns cleanly to the player's previous stored camera mode and settings.
  Boom Mine camera can now be adjusted with the same keyboard rotation / angle controls as normal mode, but with a tighter maximum downward angle suited for that area.
- `Camera / Cinematics`
  Intro cinematic and similar shared cinematic trigger flows now appear to hand camera ownership back normally after the earlier `Cinematic ON/OFF` trigger fix.

### Known Issues
- `TerrainDamage.j`
  The terrain-damage lag investigation is still unresolved. Even though the system currently has a hard internal bypass switch, the intended isolation test still needs to be repeated cleanly so the session can confirm whether the slight lag spikes are really tied to TerrainDamage's periodic timer activity or to some other always-running system.
- `AbilitiesLiteUI.j`
  The gray overlay on unlearned abilities did not seem to work as intended in testing and still needs another in-game verification / fix pass.
- `PatrolFollowSystems`
  `ValeriaMovementStart` no longer depends on `udg_TempUnit`, but similar patrol-start functions such as `Mordrax` and other older patrol helpers still need the same cleanup pass.

### Actions Remaining
- `CameraControl.j`
  Continue smoothing normal-mode safe-camera correction so blocker / terrain adjustment feels closer to advanced camera quality without adding gameplay-disrupting bounce or extra lag in blocker-dense areas.
- `TerrainDamage.j`
  Re-run the lag isolation test with TerrainDamage fully bypassed / disabled for the session and confirm whether the slight lag spikes and unresolved FPS drop are tied to TerrainDamage's periodic timers or to another always-running system.
- `AbilitiesLiteUI.j`
  Re-check why the unlearned-ability gray overlay did not appear correctly in-game and fix the icon-overlay path if the current unavailable-state art is still not being shown.
- `PatrolFollowSystems`
  Apply the same `udg_TempUnit` removal pattern from `ValeriaMovementStart` to other older patrol-entry functions that still rely on shared temp globals.
- `qAradion.j` / questgiver workflow
  Re-test `qAradion` on-map after the latest parity pass, keep closing the remaining old-GUI parity gaps, and use the stabilized helper boundary plus generator output as the starting point for the next questgiver NPC instead of duplicating the old boilerplate by hand.

## [7.6.2026]

### Technical Updates
- `CameraControl.j`
  Reworked normal camera mode to use the same blocker and terrain-height adjustment approach as `AdvancedCameraSystem`, while still preserving the stored `CameraControl` rotation instead of rotating with unit facing.
  Added per-player caching and lighter refresh paths around normal-mode blocker tracing so repeated pathing-blocker camera adjustment does not recalculate as aggressively as before.
  Added a normal-mode correction smoothing pass so blocker / terrain adjustments apply over time instead of snapping too hard when stairs, invisible platforms, or blocker-heavy height transitions would otherwise make the camera bounce.
  Added a per-player normal-mode `Safe Camera` toggle so blocker / terrain no-clip prevention can be turned off completely without affecting advanced or developer camera modes.
  Added a wounded-state camera overlay tied to the currently viewed camera unit, including a sustained red cinematic filter, pulsing transparency beats, and heartbeat sound playback while the viewed unit is below `25%` life.
  Made `CameraControl` suspend / resume calls idempotent so duplicate dialog and cinematic trigger calls no longer keep restarting or overriding the current suspended / resume-pending camera state.
- `CameraUI.j`
  Added `Safe Camera` status text and toggle controls for the normal-mode blocker / terrain camera protection.
  Simplified the camera panel actions by removing the duplicate left-side `Defaults` action, renaming the lower reset button to `Defaults`, and placing the `Safe Camera` toggle under it with matching button width.
- `AbilitiesLiteUI.j`
  Added collapsible `Player Shaman` specialization tree headers so `Elemental`, `Enhancement`, `Restoration`, and `Totemic` sections can now be opened and closed directly from the abilities list.
  Reworked the visible-row lookup path to use a cached visible-definition list keyed to the active unit and current tree state, removing repeated full definition scans during slider movement.
  Added tree-state-aware selection and scroll clamping so collapsing a specialization no longer leaves hidden child abilities selected or produces mismatched slider ranges.
  Added clearer gray unavailable overlays for unlearned ability icons in both the left list and the right-side detail icon.
  Set the default open state so all specialization trees start collapsed when the abilities panel is opened fresh or the view resets.
- `TerrainDamage.j`
  Added a hard internal `DEBUG_BYPASS_SYSTEM` switch that short-circuits `InitDelayed`, so the terrain-damage system can be disabled completely for FPS-isolation testing without removing the library from the map.
- `WE Mainmap` - `Game Start`, `Cinematic ON`, `Cinematic OFF`
  Disabled the hardcoded `Player 1 (Red)` startup camera pan to `Nazgrek Start Point` because it no longer had a clear ownership reason and could override the intended camera flow at map start.
  Added `call CameraControl_Suspend(Player(0))` in `Cinematic ON` and `call CameraControl_Resume(Player(0))` in `Cinematic OFF` so these GUI cinematic triggers now hand camera ownership through the shared `CameraControl` flow.

### Player-Facing Updates
- `Camera / UI`
  Normal camera mode now handles blocker-heavy corridors, tunnels, and terrain-height differences much closer to advanced camera behavior while still respecting the stored normal camera rotation.
  The camera panel now lets players toggle `Safe Camera` on or off directly, and the wounded low-health camera effect now stays visibly active with slower heartbeat-style pulsing instead of brief flickering flashes.
  Duplicate dialog or cinematic camera suspend / resume calls should now be much less likely to restart camera return timing or fight over the current camera state.
- `AbilitiesLiteUI`
  Player shaman ability trees can now be expanded or collapsed by clicking the specialization rows, and the panel currently starts with all trees closed by default.
  Unlearned abilities are now easier to read at a glance because their icons use a clearer gray unavailable overlay in both the list and detail view.
  Scrolling the abilities list should now be noticeably smoother after the visible-row refresh path was cached.
- `Camera / Cinematics`
  Main-map startup and GUI cinematic camera flow should now be less likely to force an unexplained snap toward `Nazgrek`, and the `Cinematic ON/OFF` triggers now suspend and resume through `CameraControl` instead of bypassing it.

### Actions Remaining
- `CameraControl.j`
  Re-test normal mode in blocker-dense tunnels, narrow pathing corridors, and elevation-heavy areas, and profile whether the latest trace caching is enough to remove the remaining FPS drop around blocker-based adjustment.
  Continue tuning the normal-mode minimum trace distance, cache thresholds, and correction smoothing if corridor zoom still feels too strong or blocker reaction still costs too much.
- `CameraControl.j` / `CameraUI.j`
  Validate the new `Safe Camera` toggle across normal, advanced, and developer modes and confirm the wounded-state cinematic filter / heartbeat effect does not conflict with other cinematic filter usage elsewhere in the map.
  Audit intro / main-map cinematic trigger usage so only the intended master flow owns `CameraControl_Suspend` / `Resume`, even though duplicate calls are now guarded.
- `AbilitiesLiteUI.j`
  Re-test the new shaman tree collapse flow in-game with both `Nazgrek` and `Zul'kis`, including repeated slider dragging, mouse-wheel scrolling, and tree toggling while different rows are selected.
  Confirm the new cached visible-definition path fully removes the earlier scrollbar hitching and does not introduce stale selection, stale row text, or hidden-row edge cases after rapid open/close interaction.
- `TerrainDamage.j`
  Use the new `DEBUG_BYPASS_SYSTEM` path to confirm whether disabling terrain damage removes the periodic FPS sink, then either clear the system or continue profiling the remaining always-on timers.
- `WE Mainmap` / `CameraControl`
  Re-test `Game Start` and the shared `Cinematic ON/OFF` flow on the main map and confirm no other GUI camera actions still override the intended `CameraControl` suspend / resume ownership.

## [6.6.2026]

### Technical Updates
- `ProfessionsUI.j`
  Investigated the slowly worsening UI-side FPS drop path against the earlier scrollbar and refresh hardening already applied in `AbilitiesLiteUI.j` and `ReputationUI.j`.
  Reworked the professions refresh path so periodic updates stop blindly reapplying unchanged row text, row icons, row highlight state, detail icon/title, progress-bar values, and detail-body text every refresh tick.
  Added cached list-scroll and detail-scroll synchronization, guarded slider callback state, and clamped wheel movement so programmatic frame refreshes no longer churn extra slider updates while the panel is open.
  Added detail-body cache invalidation tied to selected profession, current skill, and milestone rebuild state so the right-side unlock text only rebuilds when the actual profession data changed.
  Synced the open-button toggle path with the visibility-based refresh timer so the professions panel resumes refreshing when opened and reliably pauses again when closed through the same button.
- `CameraControl.j`, `DialogCamera.j`, `QuestGiver.j`, `qAradion.j`
  Reworked the dialog-camera handoff so `DialogCamera` now suspends and resumes through `CameraControl` instead of restoring its own saved camera setup, which preserves the smooth return to the stored player camera mode and values.
  Added a duration-aware `CameraControl` resume path, explicit tracked-target caching, and native-camera reset protection for normal mode so Warcraft III page up/down or mouse-wheel camera drift gets snapped back to the stored camera state without interfering with advanced or developer camera modes.
  Updated quest-giver hero resolution and the `qAradion` dialog entry flow so the interacting hero is cached before dialog camera takes over, preventing dialog restore from incorrectly falling back to `Nazgrek` when `Zulkis` was the active hero.
  Traced the remaining wrong-hero / snap-back behavior through the quest giver cleanup chain into the shared `Cinematic OFF` trigger, and confirmed a hardcoded pan-to-`Nazgrek` there was still overriding the intended camera return path after dialog.
- `Cinematic OFF`
  Removed the hardcoded post-dialog camera snap toward `Nazgrek` so `CameraControl` can own the final return to the interacting hero instead of being visually overridden by the cinematic shutdown trigger.
- `Terrain`
  Continued terraining work in Dragonfire Peaks, Havenwoods, Orc base in Havenwoods/Thornwoods crossover (to be named more properly)

### Player-Facing Updates
- `ProfessionsUI`
  Leaving the professions panel open, switching tracked gatherers, and scrolling both panes should now produce much less long-session UI-side FPS decay than before.
- `Camera / Dialog`
  Dialog and quest camera transitions should now return smoothly to the correct stored player camera and interacting hero, and normal-mode native camera drift from page up/down or mouse wheel should immediately reset back to the intended view.

### Actions Remaining
- `ProfessionsUI.j`
  Re-test the panel in-game under longer open-idle, repeated list/detail scrolling, and tracked-gatherer switching so the slow FPS-drop path can be confirmed gone after the latest cache/sync cleanup.
- `CameraControl.j`, `DialogCamera.j`, `QuestGiver.j`, `qAradion.j`
  Re-test dialog entry and exit with both `Nazgrek` and `Zulkis`, and confirm normal, advanced, and developer camera modes each keep the intended ownership and restore behavior after quest-dialog cinematics now that the `Cinematic OFF` trigger no longer hardcodes a camera snap to `Nazgrek`.
- `qAradion.j` / related quest systems
  `qAradion.j` is still not on the main map, so review the current `MS Todo` items around `qAradion` and the shared quest/dialog systems, and keep the modular JASS structure organized enough that new quest givers and old GUI-era quest lines can be rebuilt quickly in the same style.
- `Cinematic ON/OFF` / quest-dialog flow
  Check whether `Cinematic ON/OFF` and the quest/dialog system still duplicate any `CinematicMover` calls during entry and exit, and remove overlap if both paths are moving the same units.

## [5.6.2026]

### Technical Updates
- `ReputationUI.j`, `ProfessionsUI.j`
  Continued rebuilding the right-side detail presentation after the earlier hidden `TasQuestBox` reuse kept leaking imported frame ornament art into the panel and produced black-backdrop spill outside the intended area.
  Removed the hidden `TasQuestBox` text-area host approach from both UIs and replaced it with native right-pane detail backdrops, native body backdrops, and native text-frame content areas.
  Kept the standalone list scrollbars for the left-side lists while restructuring the right-side detail stack closer to the safer native-frame pattern already used by `AbilitiesLiteUI` and `StatsUI`.

### Player-Facing Updates
- `Sirensong`
  Continued terraining work in the `Sirensong` zone, focused mostly on the river route and the troll-side areas.

### Actions Remaining
- `ReputationUI.j`, `ProfessionsUI.j`
  Re-test the rebuilt native right-side detail panes in-game and confirm the earlier lower-center ornament leak and black-background overflow are actually gone.
  Continue polishing the right-side description-card presentation until it fully matches the intended final look.

## [4.6.2026]

### Technical Updates
- `ReputationUI.j`, `ProfessionsUI.j`
  Reworked the right-side description panel approach again after the stretched tooltip-texture backdrop experiment produced broken vertical gold-strip artifacts instead of the intended `TasQuestBox` panel look.
  Embedded a hidden helper `TasQuestBox` instance inside each custom right pane and started reusing the imported `TasQuestBoxTextArea1` child for the description area so these panels can move closer to the same framed detail presentation used by `HintsUI` and the other `TasQuestBox`-based UIs.
  Added separate frame contexts and local imported-frame lookups so the custom profession / reputation panels can reuse the shared imported text-area frame without colliding with the existing `TasQuestBox` users elsewhere in the map.

### Actions Remaining
- `ReputationUI.j`, `ProfessionsUI.j`
  The right-side description area and its surrounding outer frame/panel layout still need more adjustment work before the final look fully matches the intended `TasQuestBox` presentation.
  Validate the imported text-area alignment, sizing, spacing, and any remaining overlap / anchoring issues in-game, then finish polishing the outside frame treatment around the reused description panel.

## [3.6.2026]

### Technical Updates
- `AbilitiesLiteUI.j`, `ReputationUI.j`
  Finished fixing the custom left-list scrollbar system so the slider track uses explicit sizing instead of stretched bottom anchoring.
  Corrected the slider value mapping so opening the list at the top also places the thumb at the top of the visible rail.
  Stabilized the click / drag / wheel path and initial hide-state so the thumb stays inside the intended scrollbar frame and only appears when scrolling is actually needed.
- `ProfessionsUI.j`
  Updated both the left profession list and the right detail-text scrollbar to use the same corrected top-resting slider mapping.
  Replaced the old stretched left-list scrollbar setup with explicit sizing based on the visible-row region, matching the working list-scroll system used in the repaired UIs.
  Added the same initial hide-state behavior used by the repaired list UIs so stale slider thumbs do not appear before refresh.
- `HintsUI.j`, `CommandsUI.j`, `AchievementsUI.j`, `SecretsUI.j`, `CheatsUI.j`, `TasQuestBoxLight_PotS.j`
  Standardized the page-slider logic so these `TasQuestBox`-style UIs now use the same top-resting scrollbar behavior as the fixed abilities / reputation lists.
  Added cached slider sync, integer step sizing, clamped wheel movement, conditional slider visibility, and guarded slider callback handling so programmatic refreshes no longer feed back into slider events or cause the earlier slider-related crashes.
- `MasterUI.j`
  Added configurable per-button icon constants for the `Game` menu so each submenu entry can be given its own small left-side icon or left text-only by setting the path to `""`.
  Rebuilt the menu buttons as composite button/icon/text frames and widened the panel/button layout slightly so the grouped menu can fit icons without crowding the labels.
- `TerrainDamage.j`
  Adjusted `LAVA_EFFECT_SCALE_START`, `LAVA_EFFECT_SCALE_END`, `FEL_EFFECT_SCALE_START`, and `FEL_EFFECT_SCALE_END` closer to `1.00`.
  This tones down the ramped terrain-damage special-effect growth so the end-state visuals no longer become too large.

### Player-Facing Updates
- `AbilitiesLiteUI`, `ReputationUI`, `ProfessionsUI`, `Hints`, `Commands`, `Achievements`, `Secrets`, `Cheats`, `Zones`
  The affected scrollbars now start visually from the top when the list itself is at the top, move in the expected direction, and hide themselves when no scrolling is needed.
  The latest slider pass also resolved the known slider drag / click instability, and no slider crashes are currently known after these fixes.
- `Game` menu
  The `Game` menu buttons can now show matching submenu icons while keeping the existing grouped multi-column layout.
  The menu frame and button widths were adjusted slightly so the new icons fit cleanly beside the labels.
- `Terrain damage visuals`
  Lava / fel damage effects now stay closer to normal unit scale during the ramp instead of growing overly large near the end.

## [2.6.2026]

### Technical Updates
- `AbilitiesLiteUI.j`, `ReputationUI.j`
  Continued fixing the left-side list sliders after drag/click problems and incorrect thumb placement.
  Re-anchored the slider track to the visible row area instead of letting the thumb drift outside the intended frame region.
  Corrected the vertical slider value mapping so the list starts at the top while the thumb also begins at the top of the visible gold track.
  Added stricter wheel/drag clamping so slider movement stays within the intended min/max range of the drawn scrollbar.
  Despite these changes, the latest slider iteration did not actually improve the broken behavior yet and still needs more work.

### Player-Facing Updates
- `Terraining`
  Continued terraining work in the `Sirensong` area, focused mostly on the `Panthera` miniboss entrance area.
- `AbilitiesLiteUI`, `ReputationUI`
  The left-side scrollbars were adjusted so their thumb position should now better match the visible scrollbar art and start from the top instead of the bottom.
  In practice, this slider pass did not yet produce a real improvement and the UI scrollbars still behave incorrectly.

## [1.6.2026]

### Technical Updates
- `AbilitiesLiteUI.j`
  Continued rebuilding the abilities browser around real player-shaman ability data instead of placeholder sample entries.
  Added the larger rawcode-backed `Player Shaman` ability pool for `Elemental`, `Enhancement`, `Restoration`, and `Totemic` abilities so names, icons, and tooltip text can come from Warcraft object data.
  Refined ability presentation so the visible classification line uses shared style such as `Shaman - Elemental` instead of separate `Player Shaman` / `NPC Shaman` display text.
  Changed visible ability-title lookup to prefer the normal tooltip text and strip trailing level-style suffixes such as ` - [Level X]` before display.
  Continued iterating on left-side slider/list behavior, wheel handling, and row-click interaction after repeated crash and drag issues.
  Refined the ability list/detail presentation so single-rank abilities no longer show unnecessary level text.
  Added mana-cost display to rawcode-driven ability details.
  Repositioned and enlarged the detail-text area to better fit the intended right-side description region.
  Reduced the `Not learned` row-text scale slightly and added a subtle dark overlay on unlearned ability icons so unavailable abilities read more clearly.
- `ReputationUI.j`
  Continued reworking the left-side faction-list slider and click/scroll behavior to move it closer to the proven `TasQuestBoxLight_PotS` pattern.
  Adjusted row visibility handling, slider interaction, and left-list click behavior after drag/click regressions during the reputation-panel refactor.
- `MasterUI.j`, `AbilitiesLiteUI.j`
  Added the `Abilities` entry into the `Game` menu layout and updated the open flow so `MasterUI` uses the same `ExecuteFunc(...)` pattern as the other sub-UIs.
  Moved the selected-hero resolution into `AbilitiesLiteUI`, where the panel now determines whether to open for `Nazgrek` or `Zul'kis`, defaulting to `Nazgrek` when neither is selected.
- `MasterUI.j`
  Added public `ShowGameButton` / `HideGameButton` API support for the `Game` menu button itself.
  Wired cinematic trigger usage so `Cinematic ON` / `Cinematic OFF` can now hide/show the `Game` button cleanly through the new API.
- `CameraControl.j`
  Fixed advanced camera mode so switching into `Advanced` now also binds arrow-key movement through `SetMovementUnit(...)`.
  This makes the advanced movement helper apply consistently on mode switch, target refresh/reselection, and resume because those already flow through the shared advanced bind path.
- `CameraUI.j`
  Reworked camera UI initialization so TOC loading and frame creation happen through a delayed init instead of immediate `AutoInit`.
  This was done because the missing-slider issue appears to be tied to custom slider-template frame creation happening too early in the main map, not to `Nazgrek` / `Zul'kis` initialization timing.
  Added slider-value resync on `Show()` so the visible controls refresh to current camera values when the panel is opened.
- `Camera` / cinematic cleanup
  `Intro Orc Cleanup` still contained obsolete GUI-side camera-control calls that were interfering with the newer JASS camera-control flow in the main map.
  Those old GUI camera-control function calls were disabled for now and should later be removed entirely as obsolete.
  This also highlighted that other older triggers may still be calling first-person / GUI camera controls unnecessarily and need further cleanup.

### Player-Facing Updates
- `AbilitiesLiteUI`
  Player shamans now expose a broader real ability list with names/icons/tooltips pulled from actual object data instead of only a few placeholder definitions.
  Ability names and specialization labels are being presented in a cleaner format that better matches the intended class/spec display.
  Ability details now show mana cost where available, use a better-sized description area, and make unlearned abilities easier to distinguish visually.
- `Game` menu
  The `Game` menu now includes direct access to `Abilities`, with the panel opening for the currently selected main shaman hero when possible.
  The `Game` button can now be hidden during cinematics and restored afterward through the newer cinematic trigger flow.
- `Camera`
  Advanced camera mode now restores working arrow-key movement instead of only changing the camera view.
- Sirensong small terraining
- Dragonpeak Mountain high mountain terraining

### Known Issues
- `AbilitiesLiteUI`
  The left-side abilities list still has unresolved slider/drag stability problems and has remained one of the main crash-prone UI areas during this session.
  Row selection and scroll behavior still need in-map validation after the latest slider parenting and click-interaction changes.
- `ReputationUI`
  The left-side faction list still needs more validation; drag/click/scroll behavior has been unstable while trying to match the quest-box pattern.
- `Camera`
  There may still be other old GUI-trigger paths that call outdated first-person / camera GUI functions and can conflict with the newer camera-control system.
  `CameraUI` slider controls are not appearing correctly in the main map even though they work in the test map.
  Current suspicion is that custom slider-template frames from `templates.toc` are being created too early in the main map load flow rather than the issue being caused by `Nazgrek` / `Zul'kis` variable initialization.

### Actions Remaining
- `AbilitiesLiteUI`
  Finish stabilizing the left-side ability-list slider and drag behavior until it safely matches `TasQuestBoxLight_PotS`.
  Continue filling and validating class ability definitions, especially for NPC-only classes that still only have template sections.
- `ReputationUI`
  Finish stabilizing the left-side faction list slider and drag behavior and continue aligning it with the quest-box style interaction model.
- `Camera` cleanup
  Continue searching for other old GUI-trigger references to first-person / GUI camera controls and remove or disable them so only the newer JASS camera-control flow remains active.
  Re-test whether delayed `CameraUI` frame creation resolves the main-map-only slider issue; if not, inspect the built-map slider template import state rather than unit-variable timing.
- `MasterUI` / cinematics
  Re-test the new `Game` button hide/show flow during `Cinematic ON` / `Cinematic OFF` and any other trigger paths that should suppress menu access temporarily.

## [31.5.2026]

### Technical Updates
- `MasterUI.j`, `AbilitiesLiteUI.j`
  Added an `Abilities` button to the `Game` menu and updated the grouped menu layout/order to fit the new entry.
  Switched the menu-side open flow back to the same `ExecuteFunc(...)` style used by the other sub-UIs.
  Moved hero resolution into `AbilitiesLiteUI`, so opening the abilities panel now checks the current selected hero between `Zul'kis` and `Nazgrek`, with `Nazgrek` as the default fallback when neither is selected.
- `AbilitiesLiteUI.j`
  Reworked the class-pool configuration so only `Player Shaman` exists as a player pool, while the other class sections remain NPC-only templates for future filling.
  Added clearer `// ====== CONFIGURE` guidance and class-template notes for future ability authoring.
  Replaced the earlier 4-entry placeholder player-shaman setup with a much larger real rawcode-backed player-shaman registration list covering `Elemental`, `Enhancement`, `Restoration`, and `Totemic` abilities.
  Added duplicate-safe auto-registration helpers so reopening the panel does not keep stacking ability definitions.
  Continued reducing the earlier heavy/detail-refresh approach and adjusted the left-side scroll handling to move closer to the `TasQuestBox` slider style.
- `ReputationUI.j`
  Continued iterating on the left-side factions list and slider behavior so the panel can move away from the earlier unstable scroll handling.
  Refined row visibility/highlight handling and continued trying to align the list/slider interaction more closely with `TasQuestBoxLight_PotS`.

### Player-Facing Updates
- `Game` menu
  The main `Game` menu now includes `Abilities` as a direct submenu entry.
- `AbilitiesLiteUI`
  Player shamans now expose a much larger real ability list based on actual ability rawcodes instead of only a few placeholder sample abilities.
  Opening the panel from the main menu now targets the currently selected main hero, or defaults to `Nazgrek` if neither player hero is selected.

### Known Issues
- `AbilitiesLiteUI`
  The left-side ability list scroll/slider path is still unstable and has been causing lag or crashes during drag/scroll interaction.
  Left-side row interaction and scroll behavior still need full validation after the latest slider changes.
- `ReputationUI`
  The left-side faction slider/list interaction is still not fully stable and needs more work to properly match the intended `TasQuestBox`-style behavior.
  Layout/interaction validation is still needed for the left-side list after the latest scroll fixes.

### Actions Remaining
- `AbilitiesLiteUI`
  Continue correcting the left-side slider/list interaction until it behaves safely and consistently like `TasQuestBoxLight_PotS`.
  Finish authoring/validating the player-shaman rawcode list and continue filling NPC class ability definitions.
- `ReputationUI`
  Finish stabilizing the left-side faction scrolling and dragging behavior and fully mirror the proven `TasQuestBox` left-list interaction pattern.

## [30.5.2026]

### Technical Updates
- `CameraControl.j`, `CameraUI.j`, `MasterUI.j`, `ProfessionsUI.j`, `ReputationUI.j`, `StatsUI.j`
  Added short purpose-focused header descriptions to the newer JASS UI libraries so their main intent is easier to identify at a glance.
- `Reputation.j`, `ReputationUI.j`
  Retired the old reputation multiboard from active use while keeping the code in place as legacy fallback.
  `ReputationUI` no longer commands the old multiboard, and `ReputationBoard` init/show flow was disabled so the frame UI is the active visual path.
- `StatsUI.j`
  Reworked the stats panel around UI-side unit selection instead of Warcraft's current map selection.
  Added broader stat coverage based on `DEqStatNames`, split the view into summary stats plus a denser lower-right stat grid, and removed the old detail scrollbar path.
  Added class/type placeholders and later hardcoded fallback metadata for player-shaman examples such as Nazgrek.
  Added a black detail backdrop for clearer reading and wired an `Abilities` button into the unit detail view.
  Removed direct multiboard hiding from `StatsUI` to avoid conflicts with external multiboard triggers.
- `AbilitiesLiteUI.j`
  Added a new lightweight ability browser opened from `StatsUI`, with separate player-shaman vs companion-shaman definition routing so their ability pools do not mix.
  Added hardcoded starter shaman templates for `Lightning Bolt`, `Stormstrike`, `Healing Wave`, and `Stoneskin Totem`.
  Added support for player-hero learn-state display so unlearned Nazgrek / Zulkis abilities can show greyed `Not learned` state based on real ability level checks.
  Simplified the detail panel away from the earlier heavy scroll/body-refresh path, restored lightweight body wrapping, and began adding full black backdrop treatment similar to `StatsUI`.
- `ReputationUI.j`
  Kept live timed refresh, but narrowed it to cached visible-row/detail updates instead of full panel rewrites each refresh tick.
  Added more caching around row visibility, row status text, slider sync, and detail text updates to reduce repeated frame churn while the panel is open.
- `CheatsUI.j`
  Replaced placeholder cheat examples with the real current cheat list and removed redundant category text duplication by making the UI render the category once from stored data.
  Continued hardening scroll/slider behavior after crash investigation by removing brittle event coupling and reducing unsafe slider-sync paths.

### Player-Facing Updates
- `StatsUI`
  The stats panel now shows fuller unit information through the new frame layout, including expanded summary fields and broader derived stats.
  Unit details are now meant to follow the row selected inside the stats UI itself rather than depending on the current world selection.
- `AbilitiesLiteUI`
  Units opened through `StatsUI` now have a separate ability list and description view, with player shamans showing richer specialization-style text.
- `Reputations`
  Reputation display is now intended to use the frame UI instead of the old multiboard presentation.

### Tool Updates
- `WC3_Database/WC3ItemManager`
  Modernized `WC3ItemManager` from the old `.NET 5` setup to a supported desktop stack using `.NET 10 SDK` with the app targeting `net8.0-windows`.
  Updated package/runtime configuration for the newer build chain and verified successful Debug build plus self-contained Release publish.
  Replaced the brittle old WinForms/WPF assembly-reference setup with explicit desktop project configuration.
- `WC3_Database/WC3ItemManager/Assets`
  Moved the integral icon texture libraries out of the old `bin\Debug\net5.0-windows` output tree into a proper source location under `Assets\blizzard` and `Assets\custom`.
  Updated the project so both Debug and published outputs now copy the full icon libraries from `Assets` automatically.
- `WC3_Database/WC3ItemManager/IconPathConfig.cs`
  Changed default icon lookup paths to prefer app-local `blizzard` and `custom` folders so the newer build outputs remain self-contained even without a hand-written config file.

### Known Issues
- `AbilitiesLiteUI`
  Ability definitions are still only partially populated, and the frame still needs more visual tuning around layout, text balance, and overall readability.
- `ReputationUI`
  The factions list is still not fully aligned inside the main frame and needs more follow-up layout work.
- `StatsUI`, `AbilitiesLiteUI`, `ReputationUI`
  These newer frame UIs have had several performance/stability corrections, but they still need full in-map validation after the latest refresh/scroll/backdrop changes.

### Actions Remaining
- `AbilitiesLiteUI`
  Add many more manually configured ability rawcodes for player and companion unit types, plus the needed configuration/text authoring work for each ability definition.
  Continue visual adjusting so the panel layout, text blocks, icon presentation, and detail area feel finalized.
- `Companions` / `Tamed`
  Create a proper `Companions.j` JASS library and merge logic from the current GUI versions.
  This is a heavy change because many systems still depend on the GUI companion / tamed trigger flow and shared `udg_` globals.
- `ReputationUI`
  Continue fixing the left-side faction list layout so entries stay fully inside the main reputations frame.
- UI backdrop idea
  Consider using the same style of black backdrop frame more broadly across newer UIs, as it makes text much easier to read during gameplay.
- `WC3ItemManager`
  Re-test normal item editing, icon browsing, imports, and exports in the upgraded app during regular use to confirm there are no behavior regressions beyond successful build/startup verification.


## [26.5.2026]

### Technical Updates
- `MasterUI.j`
  Refined the central `Game` menu toward a cleaner grouped multi-column layout.
  Continued tuning frame width/height, button width, spacing, and title presentation.
  Added and refined the `Path of the Shaman` heading styling in the main menu frame.
- `HintsUI.j`
  Simplified hints to one shared text body used by both popup/chat output and the hints panel.
  Repeated `SetHintText(...)` calls now append paragraphs automatically, so multi-paragraph hints are easier to author and edit.
  Removed the remaining one-off hardcoded hint formatting path so hint display stays data-driven.
  Popup hint formatting was aligned to `Hint - <title>` followed by the hint text on the next line.
  Added conversion from frame-style `|n` paragraph breaks to real chat newlines for popup display.
  Added hint popup sound support using `Sound\\Interface\\Hint.wav`.
- `SecretsUI.j`, `AchievementsUI.j`, `ReputationUI.j`
  `SecretsUI.j` now hides the icon and real title for unfound secrets, showing greyed-out `Undiscovered` entries instead.
  `SecretsUI.j` now displays `Secrets - Undiscovered` for locked entries in the detail view.
  Removed `Owner player` text from `ReputationUI.j` so the reputation detail pane stays focused on faction-facing information only.
  Added unlock sound support to `AchievementsUI.j` using `Sound\\Inferface\\AchievementEarned.wav`.
  Added unlock sound support to `SecretsUI.j` using `Sound\\Interface\\SecretFound.wav`.

### Player-Facing Updates
- `Game` menu
  The `Game` menu continues to become a cleaner hub for newer systems.
  Menu presentation is now tighter and more readable as the grouped multi-column layout is refined.
  The main menu title and button presentation are being tuned toward a more polished in-game menu feel.
- Discovery / collection feedback
  Hints now pop with a matching hint sound and cleaner popup formatting.
  Unfound secrets no longer spoil their title or icon in the secrets list.
  Achievements and secrets now give their own unlock sounds when earned/found.

### Known Issues
- `MasterUI.j`
  The grouped `Game` menu still needs visual tuning; frame width, heading scale, and button spacing are not finalized yet.
- `HintsUI.j`, `AchievementsUI.j`, `SecretsUI.j`
  The new popup/unlock sound paths still need full in-map validation to confirm they resolve correctly in the target build.

### Actions Remaining
- `MasterUI.j`
  Continue refining sizing, spacing, and title presentation until the grouped menu feels finalized.
  Re-test the grouped `Game` menu against all currently wired sub-UIs after more layout changes.
- UI feedback / audio
  Re-check hint popup line breaks and sound playback in normal gameplay flow.
  Re-check achievement and secret unlock sounds to make sure the chosen paths are valid in the target map build.
  Continue refining hidden/locked presentation for collection-style UIs where needed.



============================================================================
25.5.2026 - List of Actions:

======================== Technical Updates: 

UI / Camera / Master Menu
- Continued the new frame-based UI migration with more systems moved under the `Game` menu flow
>> Added and iterated on `CameraUI.j` and `CameraControl.j` as the new JASS-side camera split for camera controls and camera settings
>> Imported `templates.toc` from `PotS_JASS\\_tocs` for `CameraUI` so the newer slider templates can be used by the camera frame UI
>> Continued refining `MasterUI.j` button grouping, order, spacing, return flow, and visual styling while keeping the old systems in place underneath
>> Reworked `MasterUI` toward a multi-column `Game` menu layout instead of a single long vertical list
>> Added a centered `Path of the Shaman` heading to the `Game` menu and continued tuning frame width / height and button sizing to better fit the grouped menu layout
>> Added newer collection / utility frame UIs such as `HintsUI`, `AchievementsUI`, `SecretsUI`, `CommandsUI`, and `CheatsUI` as part of the broader `Game` menu expansion

UI / Camera / Legacy Trigger Retirement
- Began properly retiring the older GUI-driven camera control layer
>> Disabled the old camera-control triggers in the folders `Camera commands testing`, `Camera Keyboard Actions`, `Camera Settings`, and `Camera Commands`
>> These older GUI trigger folders are intended to be removed later entirely once the new JASS-side camera flow is fully validated
>> Moved `FixedCameraLock` and `AdvancedCameraSystem` into the upper-level `Camera` folder structure for cleaner organization around the newer camera libraries

Camera / Controls / Cinematics
- Updated cinematic camera transition handling to use the new camera-control API instead of the older mixed GUI/JASS references
>> `Cinematic ON` now calls `CameraControl_Suspend(Player(0))`
>> Removed the old camera GUI / JASS references from `Cinematic ON`
>> `Cinematic OFF` now calls `CameraControl_Resume(Player(0))`
>> Removed the old camera GUI / JASS references from `Cinematic OFF`
>> Added a `ResumeQuick` variant so the camera library now supports both instant and smooth resume behavior when restoring a suspended camera mode

UI / Stability / Performance
- Continued correcting the newer frame UIs now that the main catastrophic startup FPS issue had already been isolated
>> Follow-up testing continued to confirm that the severe startup FPS drop / fast crash was caused by `ProfessionsUI.j`, not by the gather-node runtime itself
>> Continued hardening scroll handling, refresh timing, and open/close behavior across the newer frame UIs
>> `ProfessionsUI`, `ReputationUI`, and `StatsUI` were refined further so they only refresh while actually open, with additional guarding against update/scroll recursion

UI / Hints
- Simplified `HintsUI.j` so hint authoring and display are more data-driven and easier to maintain
>> Removed the older split between separate primary / secondary popup messages and moved hints to one shared text body per hint
>> Simplified hint definitions so multi-paragraph hints can now be built with repeated `SetHintText(...)` calls instead of embedding all formatting into one long registration line
>> Removed the hardcoded special-case formatting path for individual hints so the popup/panel flow is now driven by hint data rather than one-off logic
>> Aligned the popup text format with the hint panel format as `Hint - <title>` followed by the hint text on the next line
>> Added conversion so frame-style `|n` paragraph breaks still display correctly when the same hint text is shown through chat-style popup output

======================== Player-Facing Updates:

Game UI / Navigation
- The in-game `Game` menu is expanding toward being the central access point for newer systems
>> Camera, Hints, Achievements, Secrets, Commands, and Cheats are now part of the broader frame-UI migration path
>> More of the old top-bar / GUI-trigger based access points are being retired in favor of the new centralized menu flow
>> The `Game` menu itself is being reshaped toward a more compact grouped multi-column layout instead of a single tall stack of buttons

Camera / Cinematics
- Camera handling is moving toward one cleaner JASS-side control model
>> Cinematics can now suspend and resume the currently used camera mode through `CameraControl`
>> This reduces reliance on the older mixed GUI/JASS camera setup and prepares the map for later cleanup of redundant camera triggers

======================== Actions Remaining:

UI / Camera
- The new camera UI and camera-control split still need more in-map validation before the older systems can be removed
>> Continue validating `CameraUI` frame stability, slider placement, and open/close behavior
>> Re-check that smooth `CameraControl_Resume` behavior feels distinct from `ResumeQuick`
>> Continue testing arrow-key behavior so only `Normal` mode uses keyboard rotation controls
>> Remove the older disabled GUI camera trigger folders entirely later once the new system is confirmed stable

UI / General
- The newer frame-UI layer remains WIP and still needs more polish
>> Continue refining `MasterUI` layout and submenu presentation
>> Continue polishing the new `Game` menu width, heading scale, and grouped button spacing now that the layout has shifted to multiple columns
>> Continue stress-testing `ProfessionsUI` rapid switching / scrolling to confirm the remaining crash paths are gone
>> Continue validating `HintsUI` popup formatting and panel text presentation now that hints use one shared text body for both outputs
>> Keep older redundant systems (such as multiboards and older trigger-based flows) in place only until the new replacements are proven stable

============================================================================

============================================================================
24.5.2026 - List of Actions:

======================== Technical Updates: 

UI / Master Menu / Frame UIs
- Began a broader UI consolidation pass under a new master menu flow
>> Added a new `MasterUI.j` library that places a `Game` button in the old top-bar `Zones` slot
>> `Game` now opens a central master menu with entries such as `Zones`, `Professions`, `Reputations`, `Stats`, `Camera`, and `Hints`
>> Added close handling and sub-UI return flow so child frame UIs can return back to the master menu
>> Broke a compile-order / requirement-cycle issue by letting sub-UIs require `MasterUI` while `MasterUI` avoids direct compile-time dependency on them

UI / Zones / Professions / Reputations / Stats
- Continued moving UI access into frame-based menus, though the whole pass is still very much work-in-progress
>> `TasQuestBoxLight_PotS.j` (`Zones`) no longer needs its own permanent top-bar open button when used through `MasterUI`
>> `ProfessionsUI.j` no longer needs its own permanent top-bar open button when used through `MasterUI`
>> Added `Return` buttons in the newer frame UIs so they can return to `MasterUI`
>> Reputations and Stats received new frame-based UI work using the same broad visual language as `ProfessionsUI`
>> Continued refining positions, panel layout, row highlight sprite style, and detail-pane behavior across the newer UIs

UI / Professions / Performance
- Corrected the root cause of the severe startup FPS drop / rapid crash investigated during this session
>> The major FPS collapse after game start was caused by `ProfessionsUI.j`, not by `GatherNodes` runtime changes
>> The professions UI refresh / update behavior was reworked to reduce unnecessary continuous UI churn
>> Follow-up profiling/validation is still needed while the professions panel is open, but the main startup regression was traced away from gather-node spawning logic

UI / Legacy Systems
- Kept older systems in place as redundant backends while newer frame UIs are being layered on top
>> Old multiboard-based systems such as Reputations and Stats still remain in the map for now
>> The new frame UIs are currently additive / replacement-facing, but not yet the only remaining implementations

Zones / Events
- Updated `ZoneEvent.j`
>> Added the needed library requirement to `TasQuestBox`

World / Time / Test Map Sync
- Updated `DNC.j`
>> Brought it up to date where the test map had been behind the latest script state

======================== Player-Facing Updates:

Game UI / Navigation
- The UI is moving toward one central in-game menu instead of many separate top-bar entry buttons
>> `Game` now acts as the main access point for newer frame-based interfaces
>> Zones, Professions, Reputations, and Stats are being reorganized around this master-menu flow

Stability / Performance
- The earlier fast FPS collapse after game start was not caused by gather-node spawning itself
>> Current investigation indicates the main offender was `ProfessionsUI`
>> This means gather-node runtime work should be re-validated separately from the UI performance regression

======================== Actions Remaining:

UI / Validation
- The new UI layer is still in active WIP state and needs more in-map verification
>> Continue testing `MasterUI` open/close/return flow across all sub-UIs
>> Continue aligning `ReputationUI` and `StatsUI` detail views and data presentation
>> Re-check `ProfessionsUI` while the panel stays open to ensure the main lag path is fully resolved
>> Decide later when the old redundant multiboard-based UIs can actually be retired instead of just hidden / left in place

Gather Nodes / Separation of Concerns
- Now that the worst startup FPS issue was traced to `ProfessionsUI`, gather-node runtime stability should be validated again on its own merits
>> Re-test natural despawn / respawn timing, glow cleanup, and harvest flow without conflating them with UI-side performance issues

============================================================================
23.5.2026 - List of Actions:

======================== Technical Updates: 

Gather Nodes / Skills / ItemManager
- Continued refinement of gather-skill gating, harvest rewards, and ItemManager clarity
>> `/skills` now shows only the currently selected tracked gatherer (Nazgrek or Zulkis), and falls back to Nazgrek if no tracked unit is selected
>> `/skills` now prints the hero proper name instead of the raw unit type name
>> Successful gathering now displays a blue skill-up message showing the unit name, profession, and new skill value
>> Skill-up text was cleaned so the new value no longer prints with quotation marks
>> Gather failure bark / text now uses a longer timeout between repeated messages to reduce spam
>> Gather failure handling was improved so missing node names now fall back safely instead of showing blank text
>> Blocked low-skill item pickup was tightened so gather items should no longer remain stored in PoTs DInventory when the gatherer lacks the required skill
>> Low-skill gather attempts now abort more aggressively so units stop instead of continuing to move toward item nodes or attack unit nodes
>> Skill gain from lower-tier nodes now tapers off and can eventually stop once the gatherer's profession skill significantly exceeds the node's required skill

Gather Nodes / Unit Harvest Rewards
- Corrected and clarified the unit-node reward model to better match the old GUI mining ideology
>> Clarified the difference between the node's main reward pool and per-hit reward quantities
>> Main / Secondary groups continue to pick one weighted reward from their own group when the group roll succeeds
>> Secondary rewards still roll only after a successful main reward
>> Hardened group reward selection so `Main` / `Secondary` use an explicit candidate list and weighted pick per group
>> Fixed JASS issues found during cleanup, including source-order problems in `GatherNodeSkills`, uninitialized locals in unit reward rolling, and later-declared respawn calls in timed-despawn handlers

ItemManager / Harvest Reward UI
- Improved unit-node harvest editor wording so reward behavior is easier to understand
>> Renamed labels such as `Harvest Yield` to `Main Reward Pool`, and clarified that reward rows define per-hit quantities
>> Added inline help text to explain successful-hit chance, main / secondary group chance, and the difference between pool size and reward amount
>> Updated reward-grid and reward-dialog labels to clearer terms like `Drop Group`, `Pick Weight`, `Reward %`, and `Per-Hit Qty`

Gather Nodes / Lifecycle / Cleanup
- Aligned node cleanup, glow tracking, and respawn timing more consistently
>> Timed despawn now follows the same lifecycle model as gather / kill: remove node, wait its respawn delay, then roll a fresh spawn attempt
>> Added watchdog cleanup for item nodes so if an external system removes a tracked gather item, the gather system unregisters it and schedules the next spawn attempt correctly
>> Added watchdog cleanup for unit nodes so externally removed gather units also clear glow/tracking and re-enter the respawn cycle correctly
>> Simplified unit-node glow tracking so unit glow is now managed only by the shared gather master system instead of dual local/shared tables
>> This was aimed at fixing cases where old vein glow remained in place or appeared to belong to the wrong newly spawned node
>> Reworked timed-despawn dispatchers in both item and unit systems to use trigger actions / `TriggerExecute` instead of condition-style evaluation, to make lifetime expiry handling more reliable
>> Follow-up source-order cleanup was also done so the newer item/unit gather helpers no longer depend on later-declared functions in the library file

UI / Professions
- Added the first dedicated professions UI runtime under `UI/Professions`
>> Added a new standalone `ProfessionsUI` library with a `Professions` open button near the upper-left quest/zones button area
>> The panel uses a two-column list/detail layout: all 9 professions on the left, selected profession details on the right
>> Each profession row now shows its icon, name, and current skill as `x/100`
>> The detail pane now shows profession icon, colored title, current skill, progress bar, short description, and next milestone / unlock text
>> The UI follows the currently tracked gatherer selection and falls back safely to Nazgrek or Zulkis if no tracked gatherer is selected
>> Added lightweight profession presentation metadata such as icon, accent color, and description text inside the UI library
>> Added milestone scanning so the UI can derive `Next unlock` hints from exported gather item/unit definition skill requirements
>> Added a public `GNS_GetUITargetUnit()` helper and gather-definition query helpers so the professions UI can read current tracked hero skill data cleanly
>> Follow-up UI pass moved the `Professions` open button to the left side of the vanilla `Quests` button instead of below the upper-left stack
>> Reworked the detail pane to use a proper scrollable text body so longer descriptions and milestone text stay inside the panel border
>> Removed redundant `x/100` text from the detail pane so the progress presentation is less noisy while keeping profession row values visible in the left list
>> Promoted key UI strings and textures such as button text, close text, fallback icon, panel texture, progress bar texture, and profession icon/description/accent data into configurable globals instead of burying them in frame creation logic

Gather Nodes / Glow Tracking
- Fixed a tracking bug found through `/gathernodes glowtest` and `/gathernodes glowclear`
>> Shared gather glow effects were being created into the typed `effect` child table but checked/removed through the parent glow table, which made debug glow logs report `tracked=false` even while the effect still existed visually
>> Corrected glow tracking/removal to use the same typed glow-effect table consistently, so new debug test glows and gather-node point glows can now be found and destroyed correctly

Item Systems / Cleanup
- Added a new `ItemCleanup.j` library in `ItemSystems`
>> Combines the old GUI map-clutter cleanup and dead-item/tome cleanup into one JASS runtime library
>> Protects gather node items, campaign / quest items, DInventory-managed items, and manually protected item instances / item types
>> Supports two intended cleanup purposes: long-lived ground clutter cleanup and used-tome / zero-life leftover cleanup
>> Added source credits in the library header for Bribe, Tirlititi, and Vexorian

Item Systems / Legacy GUI Cleanup
- Disabled the old GUI cleanup triggers now replaced by `ItemCleanup.j`
>> `Item Remove`
>> `Item Picked`
>> `Item Cleanup`

======================== Player-Facing Updates:

Gathering / Feedback
- Gather-node profession feedback should now read more clearly in-game
>> Skill increases now announce visibly when a successful gather improves Mining / Herbalism / other professions
>> Skill checks now identify the required node more clearly when a gather attempt fails
>> Profession progression from low-tier nodes should now slow down naturally as the character outlevels that node's required skill

ItemManager / Reward Authoring
- Harvest reward setup for unit nodes is now easier to read
>> The editor now makes it clearer that the node defines the total main reward pool, while each reward row defines what one successful harvest can actually give

======================== Actions Remaining:

Gather Nodes / Validation
- More in-map verification is still needed around the newest gather gating and reward changes
>> Confirm that low-skill gatherers cannot continue into pickup / attack / harvest through edge cases
>> Confirm that DInventory never retains a blocked gather item
>> Re-verify unit-node reward behavior against the intended old GUI-style pool logic, especially weighted selection inside `Main` / `Secondary`
>> Re-test node lifetime despawn timing to confirm nodes now wait through respawn delay before the next spawn roll
>> Re-test external item cleanup interaction so removed gather items properly re-enter the spawn cycle
>> Re-test unit and item glow cleanup on kill, gather, timed despawn, and refresh

UI / Professions
- The new professions UI still needs live in-map validation
>> Confirm the `Professions` button appears consistently both with and without the zones `MapInfoButton` active
>> Verify the panel updates correctly when switching between Nazgrek and Zulkis
>> Re-check that milestone text matches current gather-node definition data after fresh exports/imports
>> Verify the new left-of-`Quests` button anchor does not overlap any other custom top-bar button in the current UI stack
>> Verify scrollbar behavior and long-text wrapping in the detail pane with both short and long profession descriptions
>> Continue compile-order cleanup if any remaining gather helper source-order problems are reported by the map compiler

Combat / Daze
- Testing note: `Daze NonMount` is now being exercised again even though daze had previously only been used for mounts, which have been inactive for a long time
>> For a proper long-term implementation, this should become a shared JASS `Daze` library that can handle both mounts and normal units cleanly

============================================================================
22.5.2026 - List of Actions:

======================== Technical Updates: 

Gather Nodes / Skills / Harvest Rewards
- Added a new `GatherNodeSkills` sublibrary for gather profession tracking and enforcement
>> Tracks profession skill values per unit handle instead of assuming `Player(0)`, fixing the earlier behavior where only player 1 skill logic worked reliably
>> Added profession support for gather nodes through ItemManager, exporter, and runtime so both item nodes and unit nodes now author an explicit profession type
>> Added `/skills` chat output for player 1 to print current tracked gather skill values
>> Added gather failure gating and feedback for Nazgrek / Zulkis, including the requested general-error ExSounds and the displayed requirement text for nodes that need higher skill

Gather Nodes / Unit Harvesting
- Reworked unit-node harvesting toward a generic ItemManager-driven reward system
>> Added node-level harvest settings for unit nodes in ItemManager, including yield range, gather success chance, and special behavior support
>> Added ItemManager-authored reward rows for unit nodes and exported them into the gather runtime
>> Added generic runtime reward rolling for ore veins / crystals / similar unit gather nodes while keeping Mana Crystal special behavior handled separately
>> Simplified grouped harvest rewards to two fixed lanes only: `Main` and `Secondary`
>> Unit nodes now define `Main Group %` and `Secondary %`, while each reward row only chooses whether it belongs to `Main` or `Secondary`
>> On each successful gather hit, the system rolls the node's group chances, then picks weighted reward rows inside each passed group

ItemManager / Gather Node Management
- Expanded and cleaned the Gather Node Management tooling for the new harvest flow
>> Added `Profession` authoring for item nodes and unit nodes
>> Added harvest reward editing for unit nodes
>> Adjusted the harvest reward grid/dialog so the grouped reward fields are visible and no longer rely on per-row group-chance input
>> Added `Main Group %` and `Secondary %` fields to unit nodes so the fixed two-group reward model is controlled at the node level

======================== Player-Facing Updates:

Gathering / Professions
- Gather professions are now being prepared as a real per-character progression system
>> Nazgrek and Zulkis can now have separate gather skill values instead of sharing player-based logic
>> Gather nodes can now require a specific profession and skill threshold before they can be harvested correctly

Mining / Reward Behavior
- Unit-based gather nodes now support more structured reward behavior
>> Mining hits can now roll a primary reward lane and an optional secondary bonus lane instead of relying on one flat reward pool
>> This makes ore / crystal node rewards easier to tune in ItemManager while keeping special Mana Crystal behavior separate

======================== Actions Remaining:

Gather Nodes / Validation
- Live Warcraft/JASS validation is still needed for the newest gather-skill and harvest-reward changes
>> Export a fresh `GatherNodeDefinitions` after the latest ItemManager changes
>> Re-import the updated gather JASS files and verify:
>>> item-node skill gating
>>> unit-node mining skill gating
>>> `/skills` output
>>> `Main / Secondary` harvest reward behavior in-map

============================================================================
21.5.2026 - List of Actions:

======================== Technical Updates: 

ItemManager / Spawn Points
- Improved Spawn Points UI support for zone-less setup
>> Added `Any / Not configured` to the Add/Edit Spawn Point dialog zone dropdown, so spawn points can now be created without attaching them to a real zone
>> Added the same `Any / Not configured` option to the Spawn Point Autofill dialog zone dropdown for consistent bulk-creation behavior
>> This aligns spawn point editing with the earlier spawn-group support for unconfigured / global zone usage

======================== Player-Facing Updates:

Spawn Points / Workflow
- Spawn point authoring is now more flexible
>> You can create individual spawn points or autofilled spawn-point batches without forcing them into a specific zone first
>> This makes it easier to prepare global / shared spawn groups and finish zone setup later if needed

======================== Actions Remaining:

ItemManager / Spawn Points
- Continue checking for any other spawn-point related dialogs or filters that should also expose `Any / Not configured` for consistency

============================================================================
20.5.2026 - List of Actions:

======================== Technical Updates: 

Gather Nodes / Glow / Spawn Filters
- Continued gather-node runtime fixes and tooling
>> Reworked gather unit-node glow to use a point-based effect instead of attaching the imported glow effect directly to the unit
>> Added safer glow cleanup handling and debug glow test commands for player 1: `/gathernodes glowtest` and `/gathernodes glowclear`
>> Finished runtime glow support for item nodes as well, so ItemManager item glow settings now actually create and remove glow effects in-game
>> Fixed missing item pickup trigger wiring, so gathered item nodes now properly run cleanup logic instead of leaving stale glow/effects behind
>> Fixed gather-node glow cleanup so both item nodes and unit nodes now remove their point-glow effect correctly on gather, death, timed despawn, and debug refresh
>> Added `ZonesCore` support for gather-node random-spawn restriction rects for both item nodes and unit nodes
>> Added a new node-level spawn filter in ItemManager for both item and unit nodes: prevent spawning in water / amphibious terrain
>> Refined the runtime water filter so it uses floatability only, instead of the earlier broader amphibious-pathing check
>> Added `ZonesCore` support for `addNodeWaterIgnoreRect(...)` so selected shallow-water areas can still allow random node spawning
>> Changed fixed unit spawn points so they ignore only the water check, while still respecting the rest of spawn validation
>> Wired the new water-terrain setting through ItemManager database, export, and gather runtime checks
>> Tightened unit fixed spawn-point selection so nearby living units also block node spawning at that spawn point
>> Tightened random point-in-zone spacing heavily so item and unit nodes no longer spawn too close together

Gather Nodes / Stability
- Resolved two important runtime regressions found during today's testing
>> Fixed shared-pool spawn loops so failed spawn attempts no longer risk looping forever during initial spawn or debug refresh
>> Corrected the earlier terrain-filter regression that could block normal land spawns too aggressively
>> Reworked node lifecycle timing so `respawn min/max` now acts as node lifetime before timed despawn, after which the system immediately rolls a fresh spawn using normal weights / limits / random point logic
>> Gathered or killed nodes now also schedule a fresh delayed spawn event instead of recreating the same node at the same location
>> Cleaned up new gather lifetime / fresh-spawn helper ordering so the JASS runtime no longer depends on lower-declared functions in the latest item/unit node changes
>> Current result: gather nodes are spawning again and the previous gather glow crash path is now working with the new point-based implementation

Bridges / BridgeSystem
- Added a new bridge variant for simple top-lane-only crossing behavior
>> Added `HBridge004.j` for bridges that only need `C/D` movement handling
>> This variant does not use bridge activation/deactivation switching, `A/B` underlane handling, entry blocker points, or under-approach setup
>> Added a persistent-open top-lane option in `BridgeSystem` so selected bridges can keep the bridge top active at all times while still forcing `C/D` units cleanly across

======================== Player-Facing Updates:

Gather Nodes / Stability
- Gather nodes should behave more reliably again after the latest runtime fixes
>> Nodes should no longer fail because of the earlier overly aggressive land/water filtering regression
>> Item and unit node spawning should also avoid some earlier bad spawn clustering, so spawns should look more natural and less stacked together
>> Gather nodes should now cycle more naturally over time, because nodes can despawn after their configured lifetime and the next spawn is rolled fresh instead of simply returning to the same spot

Bridges / Top-Lane-Only Crossing
- Added support for bridges that are always open on top and only use `C/D` crossing flow
>> On these bridges, units approaching from the top-lane bridge sides should now cross directly without the bridge visually toggling open/closed
>> There is no `A/B` under-bridge traffic handoff on this bridge type, so the bridge behaves more like a dedicated always-active top crossing

======================== Actions Remaining:

Gather Nodes / Validation
- Live Warcraft/JASS testing is still needed after the latest runtime changes
>> Re-export and re-import fresh `GatherNodeDefinitions` so the new node-definition signature and water-spawn flag are in sync with runtime
>> Continue content-side `ZonesCore` authoring for any zone-specific node restriction rects and shallow-water water-ignore rects that are still needed

============================================================================
19.5.2026 - List of Actions:

======================== Technical Updates: 

GatherNodes / GatherNodeDefinitions / GatherNodeDebug
- Continued investigation and isolation work for the current post-loadscreen gather-node crash
>> Confirmed an important isolation result: when `GatherNodeDefinitions` is disabled, the game no longer crashes after the loadscreen
>> This means the active crash investigation is currently focused on the exported `GatherNodeDefinitions` library and its delayed initialization / initial spawn flow
>> Split `GatherNodeDebug` out of `GatherNodes.j` into its own file so the master gather library no longer contains two libraries in one script file during crash investigation
>> Reworked `GatherNodeDefinitions` delayed init to use the same trigger-based style as older known-working systems such as `DEquipmentItemDefinitions.j`
>> Removed timer-destruction style from current Gather Node Definitions generation during delayed init cleanup
>> Cleaned Gather Node Definitions generation so duplicate later `globals ... endglobals` blocks are no longer emitted just for delayed-init trigger variables
>> Separated Gather Node Definitions initialization into two stages:
>>> first delayed stage registers all node definitions and spawn-group data
>>> second delayed stage performs the actual initial node spawning later
>> This was done because the strongest suspect inside `GatherNodeDefinitions` was no longer plain registration, but the immediate initial spawn calls:
>>> `GNI_SpawnInitialAll()`
>>> `GNU_SpawnInitialAll()`
>> Further in-map isolation later confirmed:
>>> disabling only `DelayedSpawn` prevents the crash
>>> item-only refresh and item-only initial spawning do not crash
>>> unit refresh (`/gathernodes refresh units`) does crash
>> This narrows the live crash scope away from item nodes and onto the unit-node initial spawn / refresh path

GatherNodeUnits / Glow Effect Crash Isolation
- Narrowed the unit-node crash cause much further during live testing
>> Temporarily disabling both unit-side glow application and per-unit death-event registration made `/gathernodes refresh units` work
>> Further testing then confirmed that commenting out `ApplyGlowEffect(u, defId)` alone is enough to stop the unit refresh crash
>> At this point the strongest confirmed crash path is:
>>> `GNU_SpawnUnitAt(...)`
>>> `ApplyGlowEffect(u, defId)`
>>> `GN_ApplyGlowEffect(...)`
>>> `AddSpecialEffectTarget("war3campImported\\Glow.mdl", u, "origin")`
>>> followed by `BlzSetSpecialEffect*` setup such as scale/color/alpha/height
>> Ongoing next-step isolation is now focused on determining whether the problem is:
>>> the imported `Glow.mdl` effect itself
>>> `BlzSetSpecialEffectHeight(...)`
>>> or heavy glow-effect manipulation during mass unit spawn

GatherNodes / ZonesCore Spawn Rect Usage
- Adjusted random zone spawn rect preference again during investigation
>> Direct `ZoneData` usage was confirmed to be valid by comparing against systems such as `WeatherSystemV4` and `ZoneEvent`
>> However, using the first zone enter rect as the default gather spawn area was found to be risky because some zones use smaller entry rects instead of full-zone coverage
>> Gather random spawning was therefore moved back to prefer the zone's main weather/full rect first, with enter-rect fallback only if needed

GatherNodes / Debug Spawn Visibility
- Improved debug spawn visibility during heavy spawn bursts
>> Item and unit spawn pings were found to be unreliable to observe when many nodes spawned in the same tick
>> Reworked debug minimap spawn pings into a staggered queue so each successful spawn gets a visible ping instead of multiple pings being visually swallowed at once
>> This helps verify real spawning in zones such as Twilight Grove and Sereneglade without confusing lack of visible ping for lack of actual spawn

GatherNodeItems / ZonesCore Validation
- Investigated confusing herb/item random-zone spawn behavior
>> Current exported herb assignments were verified to exist for Twilight Grove and Sereneglade in the latest `GatherNodeDefinitions`
>> Current `ZonesCore` data was also verified to provide valid main weather/full rects for those zones
>> This means the earlier apparent missing spawns in those zones were not explained by missing zone rect data
>> Current understanding is that item spawning itself does work there, and the bigger confusion during testing came from debug visibility / timing rather than the `ZonesCore` zone-rect source

ItemManager / Gather Node Export
- Continued Gather Node export cleanup while isolating the crash source
>> Exported Gather Node Definitions now more closely match the intended delayed-init pattern and current runtime ownership of random zone spawning
>> Current generated files in `GatherSystems/ItemManagerExports` were also patched in-repo so testing can use cleaner exported definitions immediately

======================== Player-Facing Updates:

Gather Nodes / Stability Investigation
- Loadscreen crash investigation is still ongoing
>> The gather system is narrowed down much better than before, but the exact root cause is still not fully proven down to one exact native call
>> Current strongest confirmed scope is no longer general `GatherNodeDefinitions` registration, but the unit-node spawn glow path reached through initial spawn / debug refresh
>> Item-node spawning is currently much less suspicious than unit-node spawning

======================== Actions Remaining:

Gather Nodes / Loadscreen Crash Investigation
- In-map testing is still required to finish proving the exact unit glow crash cause and final safe fix
>> Current most likely remaining causes:
>>> `war3campImported\\Glow.mdl` itself is unsafe in this gather-unit spawn context
>>> `BlzSetSpecialEffectHeight(...)` is unsafe on this attached glow effect during mass node spawn
>>> another `BlzSetSpecialEffect*` manipulation on the created glow effect is the actual bad call
>> Recommended next isolation steps:
>>> keep `ApplyGlowEffect(...)` enabled but temporarily disable `BlzSetSpecialEffectHeight(...)`
>>> if crash still happens, temporarily replace `Glow.mdl` with a safe Blizzard stock effect
>>> if needed, test scale/color/alpha setup individually to isolate the exact bad effect manipulation
>>> once proven, re-enable only the safe subset of glow visuals for gather unit nodes

============================================================================
18.5.2026 - List of Actions:

======================== Technical Updates: 

GatherNodes / GatherNodeItems / GatherNodeUnits
- Refined gather-node debug tooling and spawn visibility
>> Removed the earlier gather-node refresh chat-command queue / timer workaround from the master library path
>> Removed the `ExecuteFunc`-based sublibrary refresh calls from `GatherNodes` debug handling
>> Split gather-node debug chat handling into a dedicated `GatherNodeDebug` library that explicitly requires `GatherNodes`, `GatherNodeItems`, and `GatherNodeUnits`
>> Gather-node refresh chat handling now uses the same broad-chat-listener pattern as other debug systems such as `WeatherSystemV4`, with message filtering inside the handler instead of duplicate exact-match chat registrations
>> Gather-node debug chat registration is now limited to `Player(0)` only
>> Gather-node debug chat features now initialize and run only when gather-node debug mode is enabled
>> Added debug-only minimap spawn pings for gather nodes so real herb/item and vein/unit spawns are easier to verify during tests
>>> herb/item node spawns now ping the minimap in green for 5 seconds
>>> vein/unit node spawns now ping the minimap in orange for 5 seconds
>> Reworked random zone spawning to use `ZonesCore` zone data directly instead of exported gather-zone spawn-region registrations
>> Added `GN_GetZoneSpawnRect(zoneId)` as the shared gather helper for zone-random spawning across both item and unit node subsystems
>> IMPORTANT: random zone spawning now prefers the zone's first enter rect as the spawn area
>>>> Sometimes for some zones this rect can be small opening etc. so when configuring zone enter rects, keep in mind
>>>> IDEA: could make separate node spawn rect that covers always the whole zone!
>> If a zone has no enter rect configured, gather random spawning falls back to that zone's main weather rect from `ZonesCore`

ItemManager / Gather Node Export
- Aligned Gather Node Management export and UI with the final `ZonesCore`-driven random-zone spawning model
>> `GatherNodeExporter` no longer treats random zone spawning as a separate gather-zone rect export concern
>> Exported `RegisterSpawnRegions()` is now intentionally empty because random zone placements use `ZonesCore` rects at runtime
>> Export now only emits explicit spawn-group registrations and spawn points for placement modes that actually need them
>> Removed the earlier temporary herb/item spawn-region fallback behavior from the exporter after the runtime was updated to use `ZonesCore`
>> Hardened gather-node export spawn-mode normalization so old and new placement labels still map correctly to runtime spawn modes
>> Updated Gather Node Management placement labels and help text so `Random In Zone` clearly means `ZonesCore` zone-rect spawning
>> `Spawn Group + Random` is now presented more clearly as `Spawn Group + Zone Random Fallback`

======================== Player-Facing Updates:

Gather Nodes / Debug & Testing
- Gather-node debug visibility is improved during in-map testing
>> When gather debug mode is enabled, node spawns are now easier to notice because new gather nodes ping the minimap on spawn
>> The gather refresh debug command is now restricted to player 1 chat instead of being registered for all player slots

Gather Nodes / Spawn Reliability
- Random zone spawning now follows the central zone setup from `ZonesCore`
>> Zone assignments using `Random In Zone` no longer require separate gather-zone rect setup in exported gather definitions
>> Random herb/item and vein/unit spawns now use the zone rect from `ZonesCore`, with the first enter rect preferred as the actual spawn area
>> This removes duplicate zone-rect authoring for gather random spawns and makes zone placement behavior match the project's main zone data source

======================== Actions Remaining:

Gather Nodes / Debug Refresh Validation
- In-map validation is still needed for the gather-node refresh command path
>> The chat-command plumbing was simplified and moved out of the master library, but refresh behavior still needs live verification in Warcraft after the latest refactor

Gather Nodes / Content Validation
- Gather random spawning still needs another in-map validation pass after the `ZonesCore` integration
>> Verify that zones now spawn gather nodes inside the intended first enter rect coverage and only fall back to weather rects when necessary
>> Review current `ZonesCore` enter-rect setup for any zones where the preferred random spawn area should be broader or narrower than the current first enter rect

============================================================================
17.5.2026 - List of Actions:

======================== Technical Updates: 

GatherNodes / GatherNodeItems / GatherNodeUnits
- Continued Gather Node runtime integration and spawn-control fixes
>> Added shared category-cap support across placements so nodes in the same category can now share one active max in the same zone or spawn group
>> Added type-specific random-spawn occupancy checks so herb/item nodes avoid overlapping other active herb/item nodes and vein/unit nodes avoid overlapping other active vein/unit nodes
>> Item and unit random-spawn occupancy checks do not block each other across types, so herbs do not block veins and veins do not block herbs
>> Fixed JASS function declaration order issues in `GatherNodes.j`, `GatherNodeItems.j`, and `GatherNodeUnits.j` so the updated gather-node scripts compile with the project's declaration-order limitations
>> Added gather-node debug refresh support through chat command `/gathernodes refresh`, which now clears active gather nodes and respawns them from current assignments
>> Added refresh-generation safety for gather-node respawn timers so old timers do not recreate duplicate nodes after a manual refresh
>> Mitigated a post-load gather-node crash risk by moving the new `/gathernodes refresh` chat-trigger registration out of earliest library init and into delayed init after game load
>> Hardened gather-node glow-effect application so glow setup now skips height / color / scale native calls when effect creation fails instead of assuming a valid effect handle exists

ItemManager / Gather Node Management
- Continued Gather Node Management UI and data-model work
>> Added readable spawn-group display names in spawn-point / placement selectors instead of raw class-name object text
>> Improved Add/Edit Zone Assignment dialog layout and help text for shared category max usage
>> Added clearer shared-pool chance visibility in Gather Management so zone/group placement rows now show effective weight and relative chance within the shared pool instead of only raw override values
>> Added persistent item-node and unit-node display ordering plus `Move Up` / `Move Down` controls in Gather Management for easier authoring / export control
>> Gather-node export ordering now follows the managed node order more closely instead of relying only on alphabetical output inside categories
>> Added unit-node glow height authoring and export support so vein glow visuals can be offset vertically per node
>> Added `Any / Not configured` zone support in spawn-group and zone-assignment editing for manual authoring cases where a concrete zone should not be required yet
>> Reworked unit-node owner-player editing to use Warcraft slot-style owner labels instead of raw JASS index guessing, so `Player 24` now maps correctly to `Player(23)` while neutral owners remain explicit options

Gather Node Authoring / Export / Imported Runtime
- Imported new working versions of:
>> `GatherNodes.j`
>> `GatherNodeItems.j`
>> `GatherNodeUnits.j`
>> Also continued configuration work in ItemManager Gather Node Management and exported a newer `GatherNodeDefinitions` version for current testing
>> Tightened unit spawn-point export for mixed spawn groups so ore-family nodes and crystal-family nodes no longer share the same unrestricted spawn-point pool when the exported group data contains both families
>> This was added after content testing exposed a case where `Gold Vein` could use a spawn rect from the wrong mixed unit spawn group content set

======================== Player-Facing Updates:

Gather Nodes / Authoring Progress
- Gather node setup is now in a better work-in-progress state for real map-side iteration
>> Shared caps, spawn-group targeting, occupancy control, placement editing, and clearer chance visibility are now in place for further balancing and content setup
>> Manual gather-node refresh is now available in-map through `/gathernodes refresh`, making it easier to re-test imported gather-node data and placement changes without relying only on natural despawn/respawn flow
>> Current gather-node data and placement setup still needs more work, especially herb definitions / herb spawn rect coverage and general placement polish

======================== Actions Remaining:

Gather Nodes / Content Pass
- Herb nodes and their spawn-rect setup still need more authoring and testing work
>> Current state is usable as a stronger WIP baseline, but herb placements in particular still need more configuration / cleanup in ItemManager and in-map verification
- Further balancing is still needed for shared spawn pools
>> Recommended next pass:
>>> review per-zone / per-group shared category max values
>>> review spawn-weight splits such as copper / tin / silver distribution in each pool
>>> verify exported `GatherNodeDefinitions` against current imported `GatherNodes` runtime files in the map

============================================================================
16.5.2026 - List of Actions:

======================== Technical Updates: 

BridgesAndGates / BridgeSystem
- Added optional top-lane entry-centering for `BridgeSystem.j` `C/D` crossings
>> Added per-bridge boolean config/API:
>>> `BridgeSystem_SetTopLaneEntryCentering`
>> Default behavior is now `true`
>> When enabled, a unit entering from `C` or `D` first moves to that side's activation rect center before the normal forced move continues toward the opposite `C/D` exit
>> This was added to keep top-lane bridge crossings visually centered instead of starting the forced bridge move from an off-center edge approach

Zones / ZonesCore
- Refactored parent-zone relationships into explicit `ZonesCore` data
>> `ZoneData` now stores an explicit `parentZoneId` instead of relying on other systems to infer parent/child links from numeric zone ID patterns
>> Added reusable parent-zone helpers/API in `ZonesCore.j`:
>>> `setParentZone`
>>> `getParentZoneId`
>>> `hasParentZone`
>>> `GetParentZoneId`
>>> `GetParentZoneData`
>>> `HasParentZone`
>>> `IsChildZoneOf`
>> Wired explicit parent links into current known child zones / interiors so the relationship can now be reused by systems beyond weather

EnvironmentSystems / WeatherSystemV4
- Refactored `WeatherSystemV4.j` to use explicit parent-zone links from `ZonesCore`
>> Removed the old weather-side parent-zone inference based on numeric zone ID formatting
>> Weather inheritance / propagation now reads the parent zone relationship directly from `ZonesCore`
>> This makes weather inheritance data-driven and keeps zone hierarchy ownership centralized in `ZonesCore`

CreepRespawn
- Refactored `CreepRespawn.j` respawn scheduling to remove `TriggerSleepAction` from the death-event flow
>> Replaced the old wait-based respawn path with `TimerUtils` timer scheduling, so each death now creates an isolated respawn timer instead of sleeping inside trigger execution
>> Stored respawn payload data per scheduled timer and moved actual unit recreation into a timer-expire callback, which is a safer library pattern for JASS/vJASS systems
>> Fixed respawn delay behavior so the 80-240 second delay is now rolled per death instead of being randomized once at map init and then reused for the whole game

======================== Player-Facing Updates:

Bridges / Top-Lane Crossing
- `C/D` bridge crossings should now stay more centered when entering the bridge
>> Units coming from the top-lane bridge sides now first align to the bridge entry center before crossing to the opposite side
>> This should reduce sideways-looking entry movement and make bridge traversal look cleaner on bridges using the standard `C/D` top lane setup

Zones / System Foundations
- Parent-child zone relationships are now defined explicitly in the zone system
>> This does not mainly change immediate gameplay on its own, but it gives better control for future zone-specific behavior, inheritance, and linked system logic

CreepRespawn
- Creeps now use proper delayed respawn scheduling internally
>> Respawn timing remains in the same 80-240 second range, but the delay now varies correctly per individual death instead of all affected units sharing the same rolled value for the full session

ItemManager / Gather Node Management
- Refactored Gather Node authoring toward main-table-backed nodes and explicit spawn placement targeting
>> Item gather nodes now validate against the main `items` table before save instead of relying on `gather_herb_definitions` as the source of truth
>> Unit gather nodes now validate against the main `unit_types` table before save instead of relying on `gather_vein_definitions` as the source of truth
>> `gather_herb_definitions` and `gather_vein_definitions` remain available as preset metadata pickers, but they no longer bypass the main database tables for authoritative codes
>> Added spawn-point groups to the Gather Node database / UI / export path so nodes can now target selected spawn-point groups instead of only broad zone-level region lists
>> Zone placement authoring now uses the clearer model:
>>> `Random In Zone`
>>> `Spawn Group`
>> Gather-node export/runtime was updated so group-targeted placement data is exported and used by both `GatherNodeItems.j` and `GatherNodeUnits.j`
>> Item and unit spawn placement support now shares the same conceptual targeting flow instead of items remaining random-only
- Added practical multi-edit for Gather Node management
>> Added bulk category assignment for selected item nodes
>> Added bulk category assignment for selected unit nodes
>> Added multi-select placement management for node zone placements
>>> Selected placements can now be removed together
>>> Selected placements can now be enabled / disabled together
- Improved spawn-point authoring workflow
>> Added spawn-point group management in the Spawn Points tab
>> Added spawn-point autofill by numeric pattern so batches such as `RegionXXX0001` to `RegionXXX0010` can be created while retaining the selected zone / node type / optional spawn group context
>> This gives a cheaper authoring path for large rect sets without requiring Excel-style drag fill yet

ItemManager / Items / Drop Sources
- Fixed the unsaved-item foreign-key failure in Drop Sources
>> `Add Drop Source` is now disabled until the item exists in the main `items` table
>> Drop-source actions now hard-check that the item was saved first, preventing the `23503` / `fk_usd_item` crash path from trying to insert orphan `unit_specific_drops` rows

======================== Actions Remaining:

ItemManager / Gather Nodes
- In-game verification is still needed for the new gather-node spawn-group export/runtime path in the actual map
>> Recommended checks:
>>> one herb using `Random In Zone`
>>> one herb using `Spawn Group`
>>> one vein using `Spawn Group`
>>> mixed-zone setups where one zone uses group targeting and another uses random placement
- Extra bulk-edit tools can still be expanded later if needed
>> likely next useful additions would be batch placement-mode updates and batch spawn-group reassignment for selected placement rows
- Excel-style drag fill for spawn-point rows is still not implemented
>> pattern autofill was added first because it solves the higher-value authoring case with much less UI complexity

============================================================================
15.5.2026 - List of Actions:

======================== Technical Updates: 

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` patrol and timeout fallback fixes
>> Bridge-triggered patrol handling now uses a relocation-safe patrol pause path instead of issuing `stop` / `holdposition` before the bridge snap
>> Top-lane timeout fallback was adjusted to be less aggressive
>>> `BRIDGE_TOP_LANE_FORCE_EXIT_TIMEOUT` increased from `6.0` to `10.0`
>> Stuck `C/D` timeout recovery now snaps units to the saved forced overshoot destination past the far exit, instead of the opposite exit entry center
>> This should reduce false timeout recoveries and prevent timeout teleports from immediately re-triggering `BridgeSystem_AddActivateRect` top-lane activation
>> Under-lane `A/B` bridge relocation now tells bridge-paused patrol units to skip the stale currently awaited waypoint after the bridge move

PatrolFollowSystems / PatrolSystem
- Refined bridge relocation patrol resume behavior again
>> Added `PatrolSystem_PauseForRelocation(unit)` so systems like `BridgeSystem` can pause patrol state/timers without forcing a visible stop first
>> `PatrolSystem_ResumeFromCurrentPosition(unit)` now keeps advancing patrol index when a relocated unit is clearly closer to later waypoint legs than the stale stored target
>> This should prevent patrol units from pausing briefly after a bridge move and then trying to walk backward toward the pre-bridge waypoint
>> Added `PatrolSystem_ResumeFromCurrentPositionEx(unit, skipCurrentWaypoint)` for systems that need explicit post-relocation waypoint skipping
>> `BridgeSystem` now uses that path for under-lane `A/B` patrol relocations so patrol units continue to the next waypoint instead of trying to finish the pre-bridge one

Zones / ZonesCore
- Added new `Dragonfire Peaks` subzones to `ZonesCore.j`
>> `0401` `Ashfang Outpost`
>> `0402` `Skaldrath "Wyrmfall"`
>> `0403` `Morgrim's Claim`
>> `0404` `Maw of Cinders`
>> `0405` `Ashfang Falls`
- Updated volcanic-zone weather setup in `ZonesCore.j`
>> `Emberpeak Highlands` and `Dragonfire Peaks` now use a dry weather profile without rain or storm rolls
>> The outdoor `Dragonfire Peaks` subzones now use the same dry profile
>> Added per-zone toggle `weatherInheritFromParent` (default `true`) so subzones can either inherit their parent zone weather or roll their own seasonal weather
>> Current use case: `04xx` outdoor `Dragonfire Peaks` subzones inherit the parent zone weather by default unless explicitly overridden

EnvironmentSystems / WeatherSystemV4
- Expanded subzone weather inheritance handling in `WeatherSystemV4.j`
>> Added parent-zone lookup for subzones based on the current zone ID layout
>> Parent-zone weather start / stop now propagates to inheriting subzones instead of treating them as completely separate outdoor weather islands
>> Seasonal weather checks now scan the wider zone ID range and skip only subzones that inherit from a parent
>> Subzones with `weatherInheritFromParent = false` can now keep their own seasonal weather behavior while inheriting subzones follow the parent zone state

EnvironmentSystems / TerrainDamage
- Expanded `IgnoreTerrainDamage` ability coverage
>> Added `IgnoreTerrainDamage` to many units that needed it, especially dummy units and other units that should never be affected by terrain hazards
>> This should reduce incorrect lava / hazard damage on helper units and special-purpose noncombat units
- Added terrain effect scale ramp-up visuals
>> Lava / fel terrain special effects can now scale up gradually during the existing terrain damage ramp
>> Added configurable start / end effect scale constants per terrain type
>> Effect scale growth now includes random upward-trending variation during the ramp instead of a perfectly constant increase

======================== Player-Facing Updates:

Bridges / Patrol Movement
- Patrol units moved by bridge logic should now continue more smoothly after the transfer
>> Reduced the visible pause caused by bridge patrol handoff
>> Reduced cases where a patrol unit tries to return backward toward the old side because its previous waypoint was still being waited on
>> Under-lane `A/B` patrol units moved by the bridge should now continue to their next patrol waypoint instead of trying to complete the stale pre-bridge waypoint

Bridges / Timeout Recovery
- Top-lane bridge stuck recovery was made safer
>> `C/D` timeout fallback should now trigger less prematurely
>> When recovery does happen, the forced exit snap should land beyond the far exit instead of directly on the opposite bridge entry, reducing accidental re-activation loops

Dragonfire Peaks
- Added more subzone groundwork in `Dragonfire Peaks`
>> `Ashfang Outpost`
>> `Skaldrath "Wyrmfall"`
>> `Morgrim's Claim`
>> `Maw of Cinders`
>> `Ashfang Falls`

Dragonfire Peaks / Emberpeak Highlands
- Removed rainy weather from the volcanic mountain zones
>> `Dragonfire Peaks`, its outdoor subzones, and `Emberpeak Highlands` no longer roll rain-based weather
>> These areas now follow a drier weather pattern, favoring wind and limited snow instead

Hazards / Unit Immunities
- More units now correctly ignore terrain hazard damage
>> Especially dummy / helper units should no longer take incorrect lava or similar terrain damage

Hazards / Terrain Visuals
- Damaging terrain effects now intensify visually over time
>> Lava / fel effect scale ramps up gradually while a unit remains on the damaging terrain, with some variation instead of a perfectly even increase

============================================================================
14.5.2026 - List of Actions:

======================== Technical Updates: 

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` fixes and bridge compatibility updates
>> Added destructable type `OTis` to the default controlled bridge platform types
>>> `OTis` // invisible platform (small)
>> This ensures bridges using the smaller invisible platform type are now included in bridge init / open / close platform handling just like `OTip` bridges
>> Follow-up fix: companion/stat/reputation-related units should no longer become incorrectly exposed to death because of mismatched bridge platform state or bridge-managed vulnerability/state cleanup edge cases
>> Top-lane shadow hiding now swaps the unit shadow image to `NONE` and restores the original shadow image afterward, instead of only changing shadow size/offset fields
>> Added bridge-managed unit death cleanup so a `C/D` unit dying on the bridge is removed from active bridge handling immediately
>> Added a top-lane timeout fallback so stuck `C/D` units are forced to the opposite exit entry and released instead of leaving the bridge permanently active

BridgesAndGates / Bridges
- Added new bridge sublibrary: `HBridge003`

Terrain / Pathing
- Adjusted pathing blockers in many cliff areas
>> Continued cleanup of terrain movement edges and pathing flow around cliffside sections

Terrain / Subzones / Zone Drafting
- Created new draft subzone rects for `04DragonfirePeaks`
>> `04AshfangOutpost` - orcish outpost
>> `04Skaldrath` (`Wyrmfall`) - ancient dragon graveyard
>> `04MorgrimsClaim` - dwarven mine claim

EnvironmentSystems / TerrainDamage
- Expanded terrain-damage immunity coverage
>> Added `IgnoreTerrainDamage` to more units, especially lava / fire-themed units that should naturally ignore those hazards

======================== Player-Facing Updates:

Bridges / Companion Safety
- Bridge behavior was corrected on another bridge variant using smaller invisible bridge platforms
>> This should make bridge state changes more reliable and should also prevent cases where companion/stat/reputation-related units could die incorrectly near bridge logic
>> Bridge crossings should now also recover more safely if a unit dies mid-crossing or gets stuck before reaching the far side

Bridges
- Added a new bridge: `HBridge003`

World / Traversal
- Improved movement around many cliff areas by adjusting pathing blockers

Dragonfire Peaks
- Added groundwork for new subzones in `Dragonfire Peaks`
>> `Ashfang Outpost` - an orcish outpost area
>> `Skaldrath` / `Wyrmfall` - an ancient dragon graveyard area
>> `04MorgrimsClaim`  - dwarven mine claim

Hazards / Creature Logic
- More lava / fire-like units now ignore terrain damage where it makes sense

Attributes & Stats:
- Attack Speed Bonus per Agility Point reduced from 0.020 to 0.010
- Defense bonus per Agility Point reduced from 0.100 to 0.050


============================================================================
13.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` fixes and API improvements
>> Top-lane shadow hiding was strengthened by also zeroing shadow width / height while a `C/D` unit is bridge-managed, then restoring the original values on cleanup
>> Added new ignore API for bridge handling:
>>> `BridgeSystem_AddIgnoredUnit`
>>> `BridgeSystem_RemoveIgnoredUnit`
>>> `BridgeSystem_AddIgnoredGroup`
>>> `BridgeSystem_RemoveIgnoredGroup`
>> Added delayed bridge config hooks similar to TerrainDamage:
>>> `BridgeSystem_InitIgnoredUnits`
>>> `BridgeSystem_InitIgnoredGroups`
>> Ignored units / groups are now skipped by bridge activation, approach redirect, bridge adoption, and cleanup validation

BridgesAndGates / HBridge008
- Corrected bridge-specific assumptions
>> Removed an incorrect temporary ship-only top-lane activate filter after verifying `HBridge008` currently follows the same `A/B` and `C/D` rect logic as `HBridge001`

BridgesAndGates / HBridge002
- Created HBridge002

PatrolFollowSystems / PatrolSystem
- Refined bridge patrol resume behavior
>> `PatrolSystem_Pause` now stores the patrol state that was active before the bridge pause
>> `PatrolSystem_ResumeFromCurrentPosition` now resumes toward the correct current patrol leg using the stored patrol direction / state instead of choosing a nearest waypoint that could make the unit continue backwards

EnvironmentSystems / TerrainDamage
- Continued `TerrainDamage.j` optimization and behavior changes
>> Added optional rect-local player tracking for registered players so terrain tracking can be limited to configured `gg_rct_...` hazard areas instead of always maintaining the whole player-owned unit set
>> Added new API / config hook:
>>> `TerrainDamage_RegisterPlayerTrackRect`
>>> `TerrainDamage_InitPlayerTrackRects`
>> Player tracking bootstrap and periodic resync now use those configured rects when present, which should reduce expensive whole-player scan overhead
>> Terrain damage on dead units was changed so dead corpses no longer take actual damage, but terrain effects still play while the corpse remains on the damaging terrain
>> Corpse terrain sounds now play at reduced `50%` volume instead of full volume
>> Object Editor follow-up: added `IgnoreTerrainDamage` ability to many fire / similar appropriate units so they are ignored by terrain damage without needing extra script-side exclusions

EnvironmentSystems / FogSystem / WeatherSystem / ZoneEvent
- Reduced repeated fog application spam
>> `FogSystem.j` now ignores exact repeated fog requests for the same player instead of logging / reapplying them again
>> Fixed `FogSystem` init so it no longer repeatedly applies startup fog to `Player(0)` inside the user-player loop
>> `FogSystem` now still applies valid fog distance-only changes even when fog color stays the same
>> Important branch correction: `WeatherSystemV4.j` is now the current master WeatherSystem script in use
>> The earlier note that referenced `WeatherSystemv3.j` for these latest fog/weather stop-start fixes was wrong; the relevant logic must live in `WeatherSystemV4.j` instead
>> `WeatherSystemV4.j` stop/start flow was cleaned up to avoid some redundant `ZoneEvent_ApplyCurrentZoneEffects()` calls and region-stop / zone-stop reapply duplication that could contribute to repeated fog reapplication
>> `WeatherSystemv3_maybeWorkingVersion.j` was renamed to `WeatherSystemV4.j` to make the active master branch clearer

=================================================================================================================================================
12.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` bridge fixes / behavior safeguards
>> Bridge-managed patrol units now resume patrol from their current position by selecting the nearest saved patrol waypoint instead of returning toward their old patrol-side location
>> Added shared lane-trigger guard logic so a unit already managed on one bridge lane cannot be immediately picked up by the opposite lane trigger on the same bridge
>> This was aimed especially at `HBridge008`, where overlapping / sensitive rect behavior could cause weird state flips such as bridge mode changing unexpectedly and top-lane shadow / bridge-state behavior not staying consistent

PatrolFollowSystems / PatrolSystem
- Added patrol resume helper for bridge integration
>> New helper: `PatrolSystem_ResumeFromCurrentPosition(unit)`
>> When used by `BridgeSystem`, patrol now continues from the nearest waypoint based on the unit's current location instead of forcing a return toward the previous patrol target

EnvironmentSystems / TerrainDamage
- Fixed dead-unit terrain timer cleanup more aggressively
>> `TerrainDamage.j` now requires `UnitDeathEvent` and clears armed terrain damage timers immediately when a tracked unit dies
>> Added extra dead-unit bailout in the per-unit terrain timer callback so stale terrain timers do not continue damaging corpses while waiting for periodic rescan cleanup

CreepRespawn / Neutral Passive hostile-temporary flow
- Continued Neutral Passive respawn fixes for units temporarily turned hostile
>> `CreepRespawn.j` now stores the intended respawn owner together with saved respawn position/facing data, using saved owner state instead of only the unit's current owner at death time
>> Fixed respawnable-owner checks so units temporarily changed from Neutral Passive to Player 23 are still accepted by respawn logic and recreated as their original saved owner
>> Also corrected saved respawn data layout so owner storage no longer overlaps another saved unit's position/facing slots
>> GUI integration note: added `call CreepRespawn_OnUnitEnter(udg_DamageEventTarget)` before the GUI ownership swap in the `Neutral Creature Attacked` trigger, so temporary-hostile critters save their original Neutral Passive respawn owner before being changed to Player 23

=================================================================================================================================================
11.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` bridge fixes / cleanup
>> Top-lane `C/D` units now hide their shadow while crossing and restore the original shadow values after leaving bridge control
>> Added patrol-aware under-lane `A/B` handling so bridge teleports pause / resume `PatrolSystem` when needed instead of letting patrol orders snap units back toward old locations
>> Added extra forced-state cleanup safety so stuck `C/D` units are freed more reliably if bridge state becomes stale
>> Fixed a regression where `C/D` units could lose invulnerability too early while crossing because top-lane safety release was firing outside the main bridge rect gap

EnvironmentSystems / TerrainDamage
- Optimized `TerrainDamage.j` periodic scanning
>> Removed the expensive every-`0.40` full-player fallback scan from the hot loop; registered player units are now mainly processed through the maintained tracked group
>> Added a slower periodic player resync safety pass instead of rescanning all registered players every terrain tick
>> Added per-pass duplicate-scan suppression so the same unit is not reprocessed multiple times in one terrain scan cycle when present in overlapping sources
>> Dead units are now filtered out before terrain damage ticks are applied
>> Added easier ignore configuration helpers for unit-types / players, useful for cases like ore veins without adding ignore ability manually to every unit

CreepRespawn / UnitDeathEvent
- Fixed Neutral Passive respawn support
>> Found that `_CoreSystems/UnitDeathEvent.j` used Blizzard `TriggerRegisterAnyUnitEventBJ`, which does not cover extended neutral player slots needed by this map setup
>> Replaced the centralized death registration with explicit `Player(0)` to `Player(27)` registration so Neutral Passive / other extended-slot deaths reach respawn callbacks reliably
>> Fixed `CreepRespawn.j` so units temporarily moved to Player 23 (Emerald) now actually respawn back as Neutral Passive instead of only changing a local owner variable during death checks

=================================================================================================================================================
10.5.2026 - List of Actions:

UnitEvent
- added: constant integer `UNIT_EVENT_MAX_PLAYER_INDEX = 27`
- replaced old reliance on Blizzard `bj_MAX_PLAYER_SLOTS`, which only covers 16 players in older WC3 format
- fixed preplaced unit bootstrap enumeration to use an explicit reusable group instead of fragile `bj_lastCreatedGroup` usage
- result: neutral passive / neutral aggressive preplaced units now index correctly for systems depending on `GetUnitUserData`
- likely root cause note: the earlier incorrect `UNIT_EVENT_MAX_PLAYER_INDEX` value was very likely also behind issues where Neutral Passive units turned hostile and Neutral Passive units did not respawn correctly
- follow-up check recommended: audit other existing systems for hardcoded max-player values such as `26` or use of Blizzard max-player slot natives/constants, and replace with `27` or another verified higher value where required by the map setup

BridgesAndGates / BridgeSystem
- Continued `BridgeSystem.j` bridge traffic fixes / refinements
>> Added configurable per-bridge approach redirect helpers for entry pathing:
>>> `BridgeSystem_SetTopApproach`
>>> `BridgeSystem_SetUnderApproach`
>> `C/D` approach redirect now re-orders units to the entry rect when movement is issued through the bridge area before invisible platforms are active
>> `A/B` under-lane bridge control is now only active while top-lane `C/D` traffic is active
>> Default idle state now leaves `A/B` fully normal / free when bridge traffic is cleared
>> Under-lane bridge pass handling was adjusted so `A/B` special movement can start while top-lane movement is active instead of being left stuck in queue flow
>> Refactored managed-state cleanup helper ordering to avoid function declaration-order issues in JASS
>> Current status: `BridgeSystem` now seems to work pretty well overall after the latest top / under-lane fixes

- Remaining notes
>> There may still be edge cases that require more in-game testing
>> Each bridge still needs careful editor setup for rect placement, pathing blockers, and invisible platforms

EnvironmentSystems / TerrainDamage
- Refactored `TerrainDamage.j` terrain tick handling
>> Reworked the system so the global timer is now only a terrain scanner and units on damaging terrain own their own local damage timers
>> Terrain damage ticks are no longer fully synchronized for all units standing on the same terrain at the same time
>> Added per-unit timer state / revalidation so each unit timer checks that the unit is still alive, still tracked by the terrain system, not protected by bridge state, and still standing on the same terrain type before applying damage
>> Registered-player tracking was refactored toward UnitIndexer / `UnitEvent`-driven maintenance, while keeping a direct player rescan fallback for stability / resync
>> Added deterministic first-tick phase offset so units entering lava / fel do not feel as lockstep as before
>> Added per-terrain interval ramp configuration:
>>> `*_INTERVAL_START`
>>> `*_INTERVAL_END`
>>> `*_RAMP_DURATION`
>> Interval ramp currently affects tick frequency only; damage amount still uses the configured terrain damage percent
>> Added per-terrain sound pitch variation configuration:
>>> `*_SOUND_VARIATION`
>>> `*_SOUND_PITCH_MIN`
>>> `*_SOUND_PITCH_MAX`
>> Terrain damage sounds can now optionally randomize pitch slightly on each playback to add variation
>> Sound pitch is explicitly reset to `1.00` when variation is disabled so recycled SoundTools handles do not keep an old altered pitch
>> Added configurable ignore-marker ability:
>>> `TERRAIN_DAMAGE_IGNORE_ABILITY`
>> Units with the configured ignore ability are skipped by terrain qualification checks
>> Added extra safety guard at actual damage application so ignored units do not take terrain damage even from an already armed stale timer
>> Changed terrain damage application to non-attack `UnitDamageTarget(..., false, false, ...)` behavior so units without a normal attack setup can still be damaged correctly
>> Flat interval behavior remains the default when start / end interval are equal or ramp duration is `0.00`
>> Existing group / unit / player registration API was kept intact
>> Fel terrain effect cleanup still uses `SpeciFX_DestroyTimed(...)` instead of immediate destroy

=================================================================================================================================================
2.5.2026 - List of Actions:

BridgesAndGates / BridgeSystem
- Reworked bridge traffic handling into lane-based movement control
>> `C/D` now act as the top-of-bridge lane and `A/B` as the under-bridge lane
>> Units entering either lane are force-moved toward the opposite rect of that same lane
>> Added lane priority / queue handling so only one bridge lane is active at a time per bridge
>> Added periodic bridge evaluation to keep active lane units moving out of the bridge area and to recover from paused deadlock states
>> Added forced-order interception so bridge-managed units keep their system-issued crossing movement instead of getting stuck on conflicting orders
>> Top-lane units now gain `Ghost (visible)` during forced crossing to disable collision and have it removed on cleanup
>> Completion / cleanup logic now also resolves based on actual destination reach / proximity, not only trigger rect transitions

- Updated bridge-specific sublibraries:
>> `HBridge001.j`
>>> Removed old Player 1 / owner restrictions so bridge behavior applies to any unit
>> `HBridge008.j`
>>> Removed old ship-name-based restriction so bridge behavior applies to any unit

- Updated bridge template:
>> `HBridgeTemplate.j`
>>> Documented slot-order contract and lane-based top / under bridge movement behavior

=================================================================================================================================================
1.5.2026 - List of Actions:

SpeciFX
- Added timed special effect destroy support
>> New API: `SpeciFX_Duration(real duration)` to destroy the latest created SpeciFX/GUI effect after the given duration
>> Added `SpeciFX_DestroyTimed(effect whichEffect, real duration)` for explicit timed cleanup of native JASS-created effect handles
>> Timed destroy now reuses SpeciFX tracking/cleanup so delayed-destroyed effects are also unregistered correctly

Models
- Imported Sindu elf - recolored version (credits Missing Shadowsong (sponsor), Commedia, Xiaoyuezhen, Blizzard Entertainment)
>> to be decided whether to actually use the model and what permissions (e.g., the skin recolor)

BridgesAndGates / BridgeSystem
- Added new JASS-based bridge core library: `BridgesAndGates/Bridges/BridgeSystem.j`
>> Replaces old GUI-style bridge handling with reusable bridge registration API
>> Handles bridge init state, bridge pathing/platform destructibles, entry blockers, activate/deactivate trigger flow, and unit invulnerability toggling while crossing
>> Automatically updates GUI boolean array state with `udg_IsUnitOnBridge[GetUnitUserData(unit)] = true/false`
>> Added public helper API for manual control and queries:
>>> `BridgeSystem_SetUnitOnBridge`
>>> `BridgeSystem_SetUnitOnBridgeByCustomValue`
>>> `BridgeSystem_IsUnitOnBridge`
>>> `BridgeSystem_Activate`
>>> `BridgeSystem_Deactivate`

- Added bridge-specific sublibraries:
>> `Bridge_HBridge001.j`
>>> Mirrors old GUI logic for HBridge001
>>> Uses Player 1 (Red) owner checks for activate/deactivate
>> `Bridge_HBridge008.j`
>>> Mirrors old GUI logic for HBridge008
>>> Uses ship-only deactivate filter based on current bridge notes / unit names

- Added bridge template sublibrary:
>> `BridgesAndGates/Bridges/Bridge_HBridgeTemplate.j`
>>> Copyable template for creating new bridge sublibraries faster
>>> Includes placeholders for bridge rects, blocker point rects, optional conditions, and optional custom activate/deactivate callbacks

- Documentation / comments
>> Added usage comments and API examples directly into `BridgeSystem.j`
>> Documented relevant sections so future bridge additions are easier to maintain

- Follow-up bridge fixes / behavior corrections
>> Corrected bridge rect semantics in sublibraries and template:
>>> Upper bridge-entry rects now activate bridge-top state / invulnerability
>>> Underneath rects now deactivate bridge-top state
>> Updated `HBridge001.j`, `HBridge008.j`, `HBridgeTemplate.j`, and `BridgeSystem.j` comments/examples to match the corrected bridge logic
>> Added bridge-state cleanup safety handling in `BridgeSystem.j`
>>> Units now have `udg_IsUnitOnBridge[...]` reset to false if they leave the bridge area without hitting the normal deactivate rects
>>> Covers unexpected exits such as teleporting out of the bridge area or leaving via upper-side routes
>>> Also clears the temporary invulnerability state during this cleanup
>> Updated `TerrainDamage.j`
>>> Terrain damage no longer affects units while `udg_IsUnitOnBridge[GetUnitUserData(unit)]` is true

=================================================================================================================================================
26.4.2026 - List of Actions:

TerrainDamage
- In main map - need to consider to re-add Nazgrek/Zulkis if the variable is re-assigned...
- Now runs necessary init functions again in "Game Start" -trigger

Wyrmhold Sanctum
- terrained lava doodads around Dragon Mother boss area
>>> more pathing blockers + invisible platforms
>>> rocks

=================================================================================================================================================
25.4.2026 - List of Actions:

Imported "new" DNC to test with different fixed ambient intensity value
- test with 0.01 ambient intensity (command dnc lordfixed); Result: only map center area is affected and borders of the map are without any DNC (similar result as in previous DNC tests...)

Wyrmhold Sanctum
- terrained lava doodads around Dragon Mother boss area
>>> lava
>>> more pathing blockers + invisible platforms

TerrainDamage -library
- created
- damages units added to the system depending if they are on the defined terrain type, e.g., Lava Cracks
- pretty caveman library but should do its job

SoundTools (Credits Magtheridon96)
- imported to map
- was necessary to utilize more advanced sound functionalities and my custom ExSound does provide functionality to have multisounds for internal WC3 sounds 



=================================================================================================================================================
20.4.2026 - List of Actions:

GatherNodes.j
- GN_RANDOM_SPAWN_ATTEMPTS - Changed from private constant to constant in GatherNodes.j:46-47 so GatherNodeItems.j and GatherNodeUnits.j can access it

ItemManager / UI:
- GatherNodeDefinitions - C# Export Fixes:
>> Decimal separator bug - Added CultureInfo.InvariantCulture for all real number formatting in GatherNodeExporter.cs. Real values like 5.0 were exported as 5,0 causing JASS parse errors
- UI Additions:
>> Enable/Disable buttons added to all three tabs:
>>>> Item Nodes: Enable/Disable buttons for selected items
>>>> Unit Nodes: Enable/Disable buttons for selected units
>>>> Spawn Points: Enable/Disable buttons for selected spawn points




=================================================================================================================================================
15.4.2026 - List of Actions:
==== Item Manager and SQL Database

Pre-defined Loot Tables Feature
- Database
>> Added loot_tables and loot_table_items tables
>>Added loot_table_id column to unit_types and destructible_types
>> Created 24 pre-defined loot tables for all level ranges (1-5 through 31+)

- Models
>> Added LootTable and LootTableItem model classes

- Repositories
>> Added LootTableRepository and LootTableItemRepository
>> Updated UnitTypeRepository and DestructibleTypeRepository to support loot_table_id
- UI

>> Added new Loot Table Management form (LootTableForm) with:
>>>> Table list with category filtering
>>>> Add/Edit/Delete/Duplicate tables
>>>> Item management within tables
>> Added "Loot Table" dropdown to Unit Type form
>> Added "Loot Table" dropdown to Destructible Type form
>> Added "Manage Loot Tables..." menu item to main menu

- Updated User Guide / FAQ

- GatherNodes System (big update)
>> Random spawning across zone area
>> Fixed spawn points (like your existing OreRegions[] system)
>> Per-zone spawn mode: random, fixed, or both
>> Integration with Zones.j for zone tracking
>> Respawn timers per node
>> Max nodes per zone limits
>> Use either Units or Items as "Nodes"

JASS Library additions;
- GatherNodes.j - Master library with:
>>> System enable/disable
>> Zone tracking
>> Glow effect system
>> Debug commands
- GatherNodeItems.j - Herb/item spawning:
>> Random zone spawning
>> Pickup detection & respawn
>> Skill requirements
- GatherNodeUnits.j - Vein/unit spawning:
>> Fixed spawn points support
>> Death event handling
>> Vein glow effects



=================================================================================================================================================
14.4.2026 - List of Actions:


==== Item Manager and SQL Database
- Added support for destructible loot management
- Feature to export ItemLootDestructibles.j

ItemLootSystem
- added sublibrary support for ItemLootDestructibles

=================================================================================================================================================
13.4.2026 - List of Actions:

==== Item Manager and SQL Database
- Slight improves to overall GUI experience, QoL updates

ItemLootSystem + sublibraries _Generic and _Specific
- TESTING; started testing these systems in ZoneTests -map
>> with imported W3T Item Data
>> with imported ItemLootSystem JASS sublibraries
- fixed issues with incorrect use of Briebe's table
- fixed issues with integer-to-Boolean and boolean-to-integer usage
- fixed some other minor issues with the system preventing compiling in WE
>> Initial results: works, but some bugs, item creation related wc3 engine timing related?
- Floating text hovering above item when dropped by either ItemDropSystem or unit dropping from inventory
>> API to external systems how to use:
// When your system creates an item:
local item newItem = CreateItem('I000', x, y)
call ItemLoot_CreateFloatingText(newItem, ITEM_RARITY_RARE)

// Or with custom name/color:
call ItemLoot_CreateFloatingTextCustom(newItem, "Special Reward", 255, 215, 0)


=================================================================================================================================================
11.4.2026 - List of Actions:

==== Item Manager and SQL Database
1. W3U Parser & Import
- Fixed binary parser to correctly handle version 3 format
- Correct field order: SetCount → Level → FieldCount → [FieldId → Type → Value → EndMarker]*
- Successfully parses 653 units (122 modified + 531 custom)
- mport dialog with Expected vs Parsed verification
2. ItemSelectorDialog
- Created new Dialogs/ItemSelectorDialog.cs
- Searchable item grid with rarity-colored rows
- Drop configuration: Chance, Guaranteed, Min/Max Qty, Weight, Notes
3. UnitTypeForm Improvements
- Added specific drops grid with Code, Name, Rarity (colored), Chance, Qty columns
- Integrated ItemSelectorDialog for "Add Drop" functionality
- Fixed SQL joins (r.rarity_id → r.id)
4. ItemEditForm Drop Sources
- Added "Drop Sources" tab showing which units drop the item
- Displays: Unit Code, Unit Name, Drop Chance, Guaranteed, Quantity, Notes
5. Database/SQL
- All 6 loot migrations confirmed working
- 7 tiers seeded with rarity weights
6. Logs Tab - Added to MainForm
- Created LogsViewerForm.cs with live updates, color-coded entries, file selection
- Added "Logs" menu with "📋 View Logs..." and "Open Logs Folder"
7. Unit Icons - Added to UnitTypeForm
- Icon column in unit list grid (32x28 thumbnails)
- Selected unit icon display (64x64)
8. TooltipPhrases.json - Expanded to v2.0
- All 38+ stat codes mapped in statCodeMapping
- New itemSuffixes section (14 animal, 12 archetype, 10 elemental - WoW-inspired)
- 24 phrases per rarity (6 rarities) and class (7 classes)
- 20+ phrases for 24 stat categories in byDominantStat
- New sections: closingLines, classSpecificClosing, loreHints, prefixes
9. Bug Fix - UnitTypeForm boss message


=================================================================================================================================================
23.3.2026 - List of Actions:

ItemManager / SQL Database
- modified wc3_base_items table to contain same items as Wc3 has (with Casc viewer from SLK file)
>>> Wc3_base_items -table: we could take advantage of this fully blizzard/WE like table structure if NEEDED

Terraining
- Wyrmhold Sanctum

=================================================================================================================================================
21.3.2026 - List of Actions:

Import more icons from WoW (classic and more recent):
Armor - Necklace
Armor - Rings
Armor - Shields
Armor - Shirts
Armor - Shoulders
Characters and Creatures
Miscellaneous
Trade
Weapons - ShortBlade
Weapons - Staff
Weapons - Wands

Exported into path:
ReplaceableTextures\

Updated also to ItemManager (as PNG format)

ItemManager
- wc3_w3t_exporter.py
>>> The exporter now supports a per-item toggle (copy_base_abilities) to always copy abilities (iabi) from the base item.
>>> If a custom item does not have a cooldown group (icid), it will inherit it from the base item if available.
- NOT implemented; Update Item Add/Edit UI to add the toggle button and bind it to "copy_base_abilities" column !
- bug found: base item IDs are not all correct - e.g., "sor6" reads as its "Scroll of Mana" but in reality sor6 is "Shadow Orb +6 - this will fuck up item creation


=================================================================================================================================================
19.3.2026 - List of Actions:

ItemManager
- fixed DEquipment export
>>> Init was not done correctly like in the original DEquipmentItemDefinitions.j file (delayed Init)
- Dodge stat was named Evasion
>>> Fixed

New Units (Mining)
- Truesilver Vein (lower level places special)
- Fel Iron Vein (Fel orc places)
- Gem Vein (caves etc)
- Incendicite Vein (fiery places)
>>> need to create logic for spawning these and also the item versions of: XXX Ore and XXX Bar
Vein models for reference:
world_skillactivated_tradeskillnodes_ancientgem_miningnode_01
world_skillactivated_tradeskillnodes_incendicite_miningnode_01
world_skillactivated_tradeskillnodes_mithril_miningnode_01
world_skillactivated_tradeskillnodes_tin_miningnode_01
world_skillactivated_tradeskillnodes_truesilver_miningnode_01
world_skillactivated_tradeskillnodes_feliron_miningnode_01

======= Abilities (model attachments) for items created:
item_objectcomponents_weapon_misc_1h_bone_a_01
item_objectcomponents_weapon_misc_1h_book_a_01
item_objectcomponents_weapon_misc_1h_book_b_01
item_objectcomponents_weapon_misc_1h_book_b_02
item_objectcomponents_weapon_misc_1h_book_c_01
item_objectcomponents_weapon_misc_1h_book_c_02
item_objectcomponents_weapon_misc_1h_bottle_a_01
item_objectcomponents_weapon_misc_1h_bottle_a_02
item_objectcomponents_weapon_misc_1h_bread_a_01
item_objectcomponents_weapon_misc_1h_bread_a_02
item_objectcomponents_weapon_misc_1h_bucket_a_01
item_objectcomponents_weapon_misc_1h_fish_a_01
item_objectcomponents_weapon_misc_1h_flower_a_01
item_objectcomponents_weapon_misc_1h_flower_a_02
item_objectcomponents_weapon_misc_1h_flower_a_03
item_objectcomponents_weapon_misc_1h_flower_a_04
item_objectcomponents_weapon_misc_1h_flower_b_01
item_objectcomponents_weapon_misc_1h_flower_b_02
item_objectcomponents_weapon_misc_1h_gizmo_a_01
item_objectcomponents_weapon_misc_1h_glass_a_01
item_objectcomponents_weapon_misc_1h_glass_a_02
item_objectcomponents_weapon_misc_1h_holysymbol_a_01
item_objectcomponents_weapon_misc_1h_lantern_a_01
item_objectcomponents_weapon_misc_1h_lantern_b_01
item_objectcomponents_weapon_misc_1h_mutton_a_01
item_objectcomponents_weapon_misc_1h_mutton_a_02
item_objectcomponents_weapon_misc_1h_mutton_b_01
item_objectcomponents_weapon_misc_1h_mutton_b_02
item_objectcomponents_weapon_misc_1h_orb_a_01
item_objectcomponents_weapon_misc_1h_orb_a_02
item_objectcomponents_weapon_misc_1h_orb_c_01
item_objectcomponents_weapon_misc_1h_potion_a_01
item_objectcomponents_weapon_misc_1h_potion_b_01
item_objectcomponents_weapon_misc_1h_random
item_objectcomponents_weapon_misc_1h_rollingpin_a_01
item_objectcomponents_weapon_misc_1h_seal_a_01
item_objectcomponents_weapon_misc_1h_seal_b_01
item_objectcomponents_weapon_misc_1h_seal_c_01
item_objectcomponents_weapon_misc_1h_skull_b_01
item_objectcomponents_weapon_misc_1h_sparkler_a_01blue
item_objectcomponents_weapon_misc_1h_sparkler_a_01red
item_objectcomponents_weapon_misc_1h_sparkler_a_01white
item_objectcomponents_weapon_misc_1h_tankard_a_01
item_objectcomponents_weapon_misc_1h_waterwand_a_01
item_objectcomponents_weapon_misc_1h_wrench_a_01

item_objectcomponents_weapon_misc_2h_broom_a_01
item_objectcomponents_weapon_misc_2h_fishingpole_a_01
item_objectcomponents_weapon_misc_2h_harpoon_b_01
item_objectcomponents_weapon_misc_2h_pitchfork_a_01
item_objectcomponents_weapon_misc_2h_shovel_a_01

item_objectcomponents_weapon_stave_2h_ahnqiraj_d_01
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_02
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_03
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_04
item_objectcomponents_weapon_stave_2h_blackwing_a_01
item_objectcomponents_weapon_stave_2h_blackwing_a_02
item_objectcomponents_weapon_stave_2h_epic_a_01
item_objectcomponents_weapon_stave_2h_flaming_d_01
item_objectcomponents_weapon_stave_2h_jeweled_a_01
item_objectcomponents_weapon_stave_2h_jeweled_a_02
item_objectcomponents_weapon_stave_2h_jeweled_a_03
item_objectcomponents_weapon_stave_2h_jeweled_b_01
item_objectcomponents_weapon_stave_2h_jeweled_b_02
item_objectcomponents_weapon_stave_2h_jeweled_c_01
item_objectcomponents_weapon_stave_2h_jeweled_d_01
item_objectcomponents_weapon_stave_2h_long_a_01
item_objectcomponents_weapon_stave_2h_long_a_02
item_objectcomponents_weapon_stave_2h_long_a_03
item_objectcomponents_weapon_stave_2h_long_a_04
item_objectcomponents_weapon_stave_2h_long_b_01
item_objectcomponents_weapon_stave_2h_long_b_02holy
item_objectcomponents_weapon_stave_2h_long_b_03
item_objectcomponents_weapon_stave_2h_long_b_04
item_objectcomponents_weapon_stave_2h_long_c_01
item_objectcomponents_weapon_stave_2h_long_c_02
item_objectcomponents_weapon_stave_2h_long_d_01
item_objectcomponents_weapon_stave_2h_long_d_05
item_objectcomponents_weapon_stave_2h_long_epicpriest01
item_objectcomponents_weapon_stave_2h_long_epicpriest02
item_objectcomponents_weapon_stave_2h_medivh_d_01
item_objectcomponents_weapon_stave_2h_other_a_01
item_objectcomponents_weapon_stave_2h_other_b_01
item_objectcomponents_weapon_stave_2h_other_c_01
item_objectcomponents_weapon_stave_2h_other_c_02
item_objectcomponents_weapon_stave_2h_other_d_01
item_objectcomponents_weapon_stave_2h_pvpalliance_a_01
item_objectcomponents_weapon_stave_2h_pvphorde_a_01
item_objectcomponents_weapon_stave_2h_scythe_c_03
item_objectcomponents_weapon_stave_2h_stratholme_d_01
item_objectcomponents_weapon_stave_2h_stratholme_d_02
item_objectcomponents_weapon_stave_2h_stratholme_d_03
item_objectcomponents_weapon_stave_2h_zulgurub_d_01
item_objectcomponents_weapon_stave_2h_zulgurub_d_02
item_objectcomponents_weapon_stave_2h_zulgurub_d_03

===== Herbs added into database as items:
>>> some added into testing area in main map
world_skillactivated_tradeskillnodes_bush_ancientlichen
world_skillactivated_tradeskillnodes_bush_arthastears
world_skillactivated_tradeskillnodes_bush_azsharasveil
world_skillactivated_tradeskillnodes_bush_blacklotus
world_skillactivated_tradeskillnodes_bush_blindweed
world_skillactivated_tradeskillnodes_bush_bloodthistle
world_skillactivated_tradeskillnodes_bush_bruiseweed01
world_skillactivated_tradeskillnodes_bush_chameleonlotus
world_skillactivated_tradeskillnodes_bush_cinderbloom
world_skillactivated_tradeskillnodes_bush_constrictorgrass
world_skillactivated_tradeskillnodes_bush_crownroyal01
world_skillactivated_tradeskillnodes_bush_dragonsteeth
world_skillactivated_tradeskillnodes_bush_dreamfoil
world_skillactivated_tradeskillnodes_bush_dreamingglory
world_skillactivated_tradeskillnodes_bush_evergreenmoss
world_skillactivated_tradeskillnodes_bush_fadeleaf01
world_skillactivated_tradeskillnodes_bush_felweed
world_skillactivated_tradeskillnodes_bush_firebloom
world_skillactivated_tradeskillnodes_bush_fireweed
world_skillactivated_tradeskillnodes_bush_flamecap
world_skillactivated_tradeskillnodes_bush_foolscap
world_skillactivated_tradeskillnodes_bush_frostlotus
world_skillactivated_tradeskillnodes_bush_frostweed
world_skillactivated_tradeskillnodes_bush_frozenherb
world_skillactivated_tradeskillnodes_bush_goldclover
world_skillactivated_tradeskillnodes_bush_goldenlotus
world_skillactivated_tradeskillnodes_bush_gravemoss01
world_skillactivated_tradeskillnodes_bush_gromsblood
world_skillactivated_tradeskillnodes_bush_heartblossom
world_skillactivated_tradeskillnodes_bush_icecap
world_skillactivated_tradeskillnodes_bush_jadetealeaf
world_skillactivated_tradeskillnodes_bush_khadgarswhisker01
world_skillactivated_tradeskillnodes_bush_magebloom01
world_skillactivated_tradeskillnodes_bush_manathistle
world_skillactivated_tradeskillnodes_bush_mountainsilversage
world_skillactivated_tradeskillnodes_bush_mushroom03
world_skillactivated_tradeskillnodes_bush_mushroom02
world_skillactivated_tradeskillnodes_bush_mushroom01
world_skillactivated_tradeskillnodes_bush_netherbloom
world_skillactivated_tradeskillnodes_bush_nightmarevine
world_skillactivated_tradeskillnodes_bush_peacebloom01
world_skillactivated_tradeskillnodes_bush_plaguebloom
world_skillactivated_tradeskillnodes_bush_purplelotus
world_skillactivated_tradeskillnodes_bush_ragveil
world_skillactivated_tradeskillnodes_bush_rainpoppy
world_skillactivated_tradeskillnodes_bush_sansam
world_skillactivated_tradeskillnodes_bush_shaherb
world_skillactivated_tradeskillnodes_bush_silkweed
world_skillactivated_tradeskillnodes_bush_silverleaf01
world_skillactivated_tradeskillnodes_bush_snowlily
world_skillactivated_tradeskillnodes_bush_spineleaf
world_skillactivated_tradeskillnodes_bush_stardust
world_skillactivated_tradeskillnodes_bush_starflower
world_skillactivated_tradeskillnodes_bush_steelbloom01
world_skillactivated_tradeskillnodes_bush_stormvine
world_skillactivated_tradeskillnodes_bush_stormvinebubbles
world_skillactivated_tradeskillnodes_bush_stranglekelp01
world_skillactivated_tradeskillnodes_bush_sungrass
world_skillactivated_tradeskillnodes_bush_swiftthistle01
world_skillactivated_tradeskillnodes_bush_taladororchid
world_skillactivated_tradeskillnodes_bush_talandrasrose
world_skillactivated_tradeskillnodes_bush_goldthorn01
world_skillactivated_tradeskillnodes_bush_icethorn
world_skillactivated_tradeskillnodes_bush_terrocone
world_skillactivated_tradeskillnodes_bush_tigerlily
world_skillactivated_tradeskillnodes_bush_twilightjasmine
world_skillactivated_tradeskillnodes_bush_whiptail01
world_skillactivated_tradeskillnodes_bush_whispervine
world_skillactivated_tradeskillnodes_bush_wintersbite01
world_skillactivated_tradeskillnodes_stranglekelp_01
world_skillactivated_tradeskillnodes_bush_liferoot01
world_skillactivated_tradeskillnodes_bush_snakeroot
world_skillactivated_tradeskillnodes_bush_thornroot01



=================================================================================================================================================
18.3.2026 - List of Actions:

ItemManager GUI / SQL Database
- Problem: Items couldn't be equipped in DEquipment slots
  Fix: DEquipment Export fixed slot definitions

- Cleave Stat Text - FIXED

- Probem: Healing potions couldn't be right-clicked to use
  Root Causes:
    actively_used = FALSE (WC3 requires TRUE for usable items)
    is_perishable = FALSE and max_charges = NULL (needed for consumables)

  Fixes Applied:

    Set actively_used = TRUE for all potions (7 items updated)
    Set is_perishable = TRUE (item disappears when charges used)
    Set max_charges = 1 for single-use consumables

UnitStats.j
- API for DInventory "UnitStats_RecalculateHero(u)"
- UnitStats clears all tracking and recalculates from hero's remaining abilities

DInventory.j
- Added optional UnitStats to library requirements (won't fail if UnitStats not present)
- Added call to UnitStats_RecalculateHero(u) in ItemPickedUpActions() function
- Triggers after StoreItemForPIDBID() completes (item stored in DInventory)
- Only calls for hero units to avoid unnecessary processing

DEquipment Export from ItemManager:
- DEquipmentItemDefinitions_20260318-1814

Re-imported W3T export from ItemManager
- ItemData_20260318_181431.w3t

Terranining
- Sirensong

Debug Spellpower Flat
- chat command "spelldmg" / "debugstats"

QuestGiver.j
- debug set to FALSE


=================================================================================================================================================
17.3.2026 - List of Actions:

Note Merge Items:
- Last version before merge items from ItemManager/PotS SQL Database: Epic Quests-2026-03-18-0203.zip
- Merged Item Data from ItemManager (Epic Quests-2026-03-18-0218-ItemsMerged.zip)

Trailer2 added
- fast trailer to showcase some latest areas
- use chat command " trailer2 " to play it


ItemManager GUI / SQL Database
- w3t importer works more better
- w3t exporter works more better
- many other minor improvements to e.g., default item model path / cooldown group / wc3 classification by default
- drop-down-menu to select model attachment ability for the item
- StatsMapper updated to work with with more wider stats abilities range

UnitStats
- updated to include SpellPowerFlat

New stats abilities created + export W3A file "POTS_AbilitySettings-2026-03-17-2331.w3a"

HP REGEN % (hp_regen_pct) - Health % regeneration per second:
A09Q +10.0 HP%/sec
A09R +5.0 HP%/sec
A09S +2.5 HP%/sec
A09T +1.0 HP%/sec
A09U +0.5 HP%/sec
A09V +0.1 HP%/sec

MANA REGEN % (mp_regen) - Mana % regeneration per second:
A09W +10.0 MP%/sec
A09X +5.0 MP%/sec
A09Y +2.5 MP%/sec
A09Z +1.0 MP%/sec
A0A0 +0.5 MP%/sec
A0A1 +0.1 MP%/sec

MELEE DAMAGE (melee_dmg) - Flat melee damage bonus:
A0AO +100 melee_dmg
A0AP +50 melee_dmg
A0AQ +25 melee_dmg
A0AR +10 melee_dmg
A0AS +5 melee_dmg
A0AT +1 melee_dmg

MELEE DAMAGE % (melee_dmg_pct) - Percentage melee damage:
A0AU +50% melee_dmg_pct
A0AV +25% melee_dmg_pct
A0AW +10% melee_dmg_pct
A0AX +5% melee_dmg_pct
A0AY +2% melee_dmg_pct
A0AZ +1% melee_dmg_pct


RANGED DAMAGE (ranged_dmg) - Flat ranged damage bonus:
A0A2 +100 ranged_dmg
A0A3 +50 ranged_dmg
A0A4 +25 ranged_dmg
A0A5 +10 ranged_dmg
A0A6 +5 ranged_dmg
A0A7 +1 ranged_dmg

RANGED DAMAGE % (ranged_dmg_pct) - Percentage ranged damage:
A0A8 +50% ranged_dmg_pct
A0A9 +25% ranged_dmg_pct
A0AA +10% ranged_dmg_pct
A0AB +5% ranged_dmg_pct
A0AC +2% ranged_dmg_pct
A0AD +1% ranged_dmg_pct

CLEAVE % (cleave_pct) - Cleave damage percentage:
A0AE +50% cleave_pct
A0AF +25% cleave_pct
A0AG +10% cleave_pct
A0AH +5% cleave_pct
A0AI +2% cleave_pct
A0AJ +1% cleave_pct

CLEAVE AREA (cleave_area) - Cleave attack radius:
A0AK +300 cleave_area
A0AL +200 cleave_area
A0AM +100 cleave_area
A0AN +50 cleave_area

LIFESTEAL (lifesteal) - Lifesteal percentage:
A0B0 +50% lifesteal
A0B1 +25% lifesteal
A0B2 +10% lifesteal
A0B3 +5% lifesteal
A0B4 +2% lifesteal
A0B5 +1% lifesteal

THORNS (thorns_flat) - Return damage on hit (flat):
A0B6 +100 thorns_flat
A0B7 +50 thorns_flat
A0B8 +25 thorns_flat
A0B9 +10 thorns_flat
A0BA +5 thorns_flat

THORNS % (thorns_pct) - Return damage percentage:
A0BZ +50% thorns_pct
A0C0 +25% thorns_pct
A0C1 +10% thorns_pct
A0C2 +5% thorns_pct
A0C3 +2% thorns_pct
A0C4 +1% thorns_pct

ARMOR % (armor_pct) - Armor percentage bonus:
A0BH +50% armor_pct
A0BI +25% armor_pct
A0BJ +10% armor_pct
A0BK +5% armor_pct
A0BL +2% armor_pct
A0BM +1% armor_pct

MAGIC DAMAGE TAKEN (magic_dmg_taken) - Magic damage reduction:
A0BN -50% magic_dmg_taken
A0BO -25% magic_dmg_taken
A0BP -10% magic_dmg_taken
A0BQ -5% magic_dmg_taken
A0BR -2% magic_dmg_taken
A0BS -1% magic_dmg_taken
A0BT +50% magic_dmg_taken
A0BU +25% magic_dmg_taken
A0BV +10% magic_dmg_taken
A0BW +5% magic_dmg_taken
A0BX +2% magic_dmg_taken
A0BY +1% magic_dmg_taken

MELEE DAMAGE TAKEN (melee_dmg_taken) - Melee damage reduction:
A0BB -50% melee_dmg_taken
A0BC -25% melee_dmg_taken
A0BD -10% melee_dmg_taken
A0BE -5% melee_dmg_taken
A0BF -2% melee_dmg_taken
A0BG -1% melee_dmg_taken
A0C5 +50% melee_dmg_taken
A0C6 +25% melee_dmg_taken
A0C7 +10% melee_dmg_taken
A0C8 +5% melee_dmg_taken
A0C9 +2% melee_dmg_taken
A0CA +1% melee_dmg_taken

PIERCE DAMAGE TAKEN (pierce_dmg_taken)) - Melee damage reduction:
A09E -50% pierce_dmg_taken
A09F -25% pierce_dmg_taken
A09G -10% pierce_dmg_taken
A09H -5% pierce_dmg_taken
A09I -2% pierce_dmg_taken
A09J -1% pierce_dmg_taken
A09K +50% pierce_dmg_taken
A09L +25% pierce_dmg_taken
A09M +10% pierce_dmg_taken
A09N +5% pierce_dmg_taken
A09O +2% pierce_dmg_taken
A09P +1% pierce_dmg_taken

MOVEMENT SPEED BONUS (ms_bonus) - Movement speed bonus (already created - just slight naming fixes):
A08B +1 ms_bonus
A08C +2 ms_bonus
A08D +3 ms_bonus
A08E +4 ms_bonus
A08F +5 ms_bonus
A08G +10 ms_bonus
A08H +20 ms_bonus
A08I +30 ms_bonus
A08J +40 ms_bonus
A08K +50 ms_bonus

MOVEMENT SPEED % (ms_pct) - Movement speed percentage:
A092 +50% ms_pct
A093 +25% ms_pct
A094 +10% ms_pct
A095 +5% ms_pct
A096 +2% ms_pct
A097 +1% ms_pct
A098 -50% ms_pct
A099 -25% ms_pct
A09A -10% ms_pct
A09B -5% ms_pct
A09C -2% ms_pct
A09D -1% ms_pct

SPELL POWER % (spell_power_pct) - Spell power percentage (check that StatsMapper correctly maps to percentage bonus):
A01E +100% spell_power_pct
A01D +90% spell_power_pct
A01C +75% spell_power_pct
A01B +60% spell_power_pct
A01A +50% spell_power_pct
A019 +40% spell_power_pct
A018 +35% spell_power_pct
A6F6 +30% spell_power_pct
A6F5 +25% spell_power_pct
A6F4 +20% spell_power_pct
A6F3 +15% spell_power_pct
A6F2 +10% spell_power_pct
A6F1 +5% spell_power_pct
A06P +4% spell_power_pct
A06O +3% spell_power_pct
A06N +2% spell_power_pct
A06M +1% spell_power_pct

SPELL POWER FLAT BONUS (spell_power_flat_bonus) - Spell power flat bonus (chech that StatsMapper correctly maps flat bonus):
A091 +300 spell_power_flat_bonus
A08V +100 spell_power_flat_bonus
A08W +50 spell_power_flat_bonus
A08X +25 spell_power_flat_bonus
A08Y +10 spell_power_flat_bonus
A08Z +5 spell_power_flat_bonus
A090 +1 spell_power_flat_bonus


=================================================================================================================================================
16.3.2026 - List of Actions:

Note Merge Items:
- Last version before merge items from ItemManager/PotS SQL Database: Epic Quests-2026-03-16-2308

ItemManager GUI / SQL Database
- continue improving
- bug fixes
- Greatest challenge remains;
>> More stats abilities and system to handle giving relevant stats to unit based on what stats abilities he has
>> Note that some stats abilities increment/decrement e.g., Stat_Crit[custom value of unit]
>> And some stat abilities add ability to unit and change its value
>> See SharedDInvLibrary how it handles this in DEquipment system (separate system handling DInventory and DEquipment item stats)

UnitStats
- added new stats abilities
- added to handle vanilla inventory custom stats abilities for heroes picking/dropping items
- Now should co-exist as parallel system with DEquipment & DInventory system

New stats abilities created;
A06M (1% Spell)
A06N (2% Spell)
A06O (3% Spell)
A06P (4% Spell)

A06X (Strength bonus 1)
A06Y (Strength bonus 3)
A06Z (Strength bonus 4)
A070 (Strength bonus 5)
A071 (Strength bonus 6)
A072 (Strength bonus 7)
A073 (Strength bonus 9)

A06Q (Agility bonus 1)
A06R (Agility bonus 3)
A06S (Agility bonus 4)
A06T (Agility bonus 5)
A06U (Agility bonus 6)
A06V (Agility bonus 7)
A06W (Agility bonus 9)

A074 (Intelligence bonus 1)
A075 (Intelligence bonus 3)
A076 (Intelligence bonus 4)
A077 (Intelligence bonus 5)
A078 (Intelligence bonus 6)
A079 (Intelligence bonus 7)
A07A (Intelligence bonus 9)

A07K (Life bonus 1)
A07J (Life bonus 5)
A07I (Life bonus 10)
A66A (Life bonus 25)
A643 (Life bonus 50)
A63E (Life bonus 100)
A63Y (Life bonus 150)
A63Z (Life bonus 200)
A6D8 (Life bonus 250)
A641 (Life bonus 500)
A642 (Life bonus 1000)


A07B (Mana bonus 1)
A07C (Mana bonus 5)
A07D (Mana bonus 10)
A07E (Mana bonus 25)
A644 (Mana bonus 50)
A07F (Mana bonus 100)
A64U (Mana bonus 150)
A07G (Mana bonus 200)
A645 (Mana bonus 250)
A646 (Mana bonus 500)
A07H (Mana bonus 1000)

A07L (Damage bonus 1)
A07M (Damage bonus 2)
A07N (Damage bonus 3)
A07O (Damage bonus 4)
A07P (Damage bonus 5)
A07Q (Damage bonus 10)
A07R (Damage bonus 15)
A07S (Damage bonus 20)
A07T (Damage bonus 30)
A07U (Damage bonus 40)
A07V (Damage bonus 50)
A07W (Damage bonus 100)
A07X (Damage bonus 200)
A07Y (Damage bonus 500)

A07Z (armor bonus 1)
A080 (armor bonus 2)
A081 (armor bonus 3)
A082 (armor bonus 4)
A083 (armor bonus 5)
A084 (armor bonus 10)
A085 (armor bonus 15)
A086 (armor bonus 20)
A087 (armor bonus 30)
A088 (armor bonus 40)
A089 (armor bonus 50)
A08A (armor bonus 100)

A08L (attack speed bonus 0.01)
A08M (attack speed bonus 0.02)
A08N (attack speed bonus 0.03)
A08O (attack speed bonus 0.04)
A08P (attack speed bonus 0.05)
A08Q (attack speed bonus 0.1)
A08R (attack speed bonus 0.2)
A08S (attack speed bonus 0.3)
A08T (attack speed bonus 0.4)
A08U (attack speed bonus 0.5)

A08B (movement speed bonus 0.01)
A08C (movement speed bonus 0.02)
A08D (movement speed bonus 0.03)
A08E (movement speed bonus 0.04)
A08F (movement speed bonus 0.05)
A08G (movement speed bonus 0.1)
A08H (movement speed bonus 0.2)
A08I (movement speed bonus 0.3)
A08J (movement speed bonus 0.4)
A08K (movement speed bonus 0.5)


A64J (1% block chance)
A64T (100% block chance)
A64K (2% block chance)
A64L (3% block chance)
A64M (4% block chance)
A64N (5% block chance)

A64E (1% crit chance)
A64F (2% crit chance)
A64G (3% crit chance)
A64H (4% crit chance)
A64I (5% crit chance)

A64O (1% dodge chance)
A64P (2% dodge chance)
A64Q (3% dodge chance)
A64R (4% dodge chance)
A64S (5% dodge chance)

A649 (1% hit chance)
A64A (2% hit chance)
A64C (3% hit chance)
A64D (4% hit chance)
A64B (5% hit chance)

Old stats abilities linked to database/UnitStats;
=================================================================================================================================================
15.3.2026 - List of Actions:

ItemManager GUI / SQL Database
- many improvements (huge list so i dont list them here)


=================================================================================================================================================
12.3.2026 - List of Actions:

Imported models from UTM 4.0:
BlueLight
bush2
Cloudx-blend
Glow
TerrainGlow
TerrainGlow2
Ufergras

Imported models from Hive:
IcyMist2
CloudOfFog
>>> implement to object editor

Testing moving clouds for later clouds system modification:
debug cloudunit
>>> idea test good and should be implemented as special effect

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ItemManager GUI:

Implemented Features (shit ton):

1. DataGrid Enhancements:
✓ Column sorting (click headers)
✓ Column resizing with persistence (MainFormSettings.ini)
✓ Right-click context menu (Edit, Duplicate, Delete, Copy Code, Batch Delete)
✓ Double-click to edit (already existed)
✓ Multi-select enabled (Ctrl+Click, Shift+Click)

2. Advanced Filters:
✓ Multi-field search (Name, Code, Description, Abilities)
✓ Collapsible advanced panel ("▼ Advanced" button)
✓ Cost range filters (min/max)
✓ "Has Abilities" checkbox
✓ "Has Stats" checkbox
✓ "✖ Clear All" button

3. Item Preview Panel:
✓ Split-view layout (resizable)
✓ WC3-style tooltip rendering with rarity colors
✓ Icon preview placeholder with rarity-colored border
✓ Updates on selection change

4. Copy/Duplicate:
✓ Duplicate item functionality with auto-code generation
✓ Copy item code to clipboard

5. Smart Assistance:
✓ Duplicate name detection
✓ Missing data alerts (icon, model, tooltip)
✓ Balance suggestions (price vs level)
✓ Code format validation
✓ Basic spell checking

6. Visual Enhancements:
✓ Rarity-colored borders and text
✓ Styled DataGrid (blue headers, alternating rows)
✓ Color-coded buttons
✓ Modern flat design

Button Added: Export DEquipment (appears when connected)

Orange button on main toolbar
Exports to: .j JASS library format
Auto-generates: Equipment slots, stats, gold costs, abilities
Smart detection: Recognizes slots from item class (Head Armor → "Head" slot)
Full integration: Created Python exporter script (export_dequipment_cli.py)

Checkbox Added: Show WC3 Colors

Currently triggers data refresh
Preview panel (right side) already shows WC3 colors with rarity-based formatting

Automatic Rarity Color Codes for Item Names:

In the Database: Item names are now stored WITH WC3 hex color codes (e.g., |c00FF8000Legendary Sword|r)

In the GUI: Names are displayed WITHOUT color codes for easy editing and viewing

Color Codes by Rarity:

Common: |c00FFFFFF (White)
Uncommon: |c001EFF00 (Green)
Rare: |c000070DD (Blue)
Epic: |c00A335EE (Purple)
Legendary: |c00FF8000 (Orange)
How It Works:

When Loading Items: Color codes are automatically stripped from item_name using regex, so the edit fields show clean text
When Saving Items: The clean name is automatically wrapped with the appropriate color code based on the selected rarity
MainForm DataGrid: Also strips color codes for clean display in the item list
Tooltips & Previews: Continue to render the colors properly using the existing WC3 color rendering system
The system is fully automatic - users just type the item name normally, select a rarity, and the color codes are added behind the scenes when saving to the database!


Icon Selector Implementation
New Files Created:

IconPathConfig.cs - Configuration manager for icon paths

Stores paths for Blizzard WC3 icons and custom icons
Saves/loads from IconPathConfig.ini
Resolves icon paths automatically
Scans directories for BLP, TGA, PNG, JPG files
IconSelectorDialog.cs - Grid view icon selector dialog

Search and filter by name/source (Blizzard/Custom)
Grid layout showing up to 500 icons
Click to select, double-click to confirm
Configuration button to set icon paths
Supports PNG/JPG preview (BLP/TGA show placeholders)
Updated Features:

ItemEditForm:

Added "🔍 Browse Icons" button next to Icon Path field
Opens icon selector dialog when clicked
Selected icon path is populated into the text field
MainForm:

Updated SQL query to include icon_path column
Preview panel now loads and displays item icons
Supports PNG/JPG formats (BLP/TGA show colored placeholders)
Icons scale to fit 64x64 preview area
Rarity-colored borders when icon is missing
Configuration:

Default Blizzard path: C:\Program Files (x86)\Warcraft III\UI\
Default Custom path: .\CustomIcons\
Users can configure paths via "⚙ Configure Paths" button in icon selector
Settings persisted in IconPathConfig.ini
Usage:

Open item editor or create new item
Click "Browse Icons" button in WC3 Properties tab
Search/filter icons from configured directories
Click icon to select, double-click or press Select button
Icon path is saved relative to configured directories
Icons display in preview panel (larger) when item is selected in main grid

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

=================================================================================================================================================
11.3.2026 - List of Actions:

Terraining;
- Vanguard Vale
- Havenwoods
- Stormhaven surroundings
- Deadwoods

Imported more models (Credits Talavaj)
HFMBush_CoveA
HFMBush_CoveADEAD
HFMBush_ValeA
HFMBush_ValeADEAD
HFMC0Tree_Autumnal
HFMC0Tree_Lush
HFMC0Tree_Vermilion
HFMCBush_Autumnal
HFMCBush_Umbra
HFMCBush_Vermilion
HFMCGrass_Vermilion
HFMCTree_Autumnal
HFMCTree_Lush
HFMCTree_Vermilion
HFMFlowers_CoveA
HFMFlowers_ValeA
HFMLog_Fallen
HFMLog_Stump
HFMShrub_ValeA
HFMShrub_ValeB
HFMShrub_ValeC
HFMTree_CoveA
HFMTree_CoveADEAD
HFMTree_CoveB
HFMTree_CoveBDEAD
HFMTree_CoveC
HFMTree_CoveCDEAD
HFMTree_ValeA
HFMTree_ValeADEAD
HFMTree_ValeC
HFMTree_ValeCDEAD

SQL database
- continued work
- now seems to work pretty well
- import/export scripts seem to work

GUI application for item management;
- created application for more convenient item creation/modification/view, ....
- idea is to use this as master to create/generate items

=================================================================================================================================================
10.3.2026 - List of Actions:

SQL database
- started creating database mainly to create/import/export/manage POTS items
- created using POSTGRESQL
- can import .w3t file and migrate/update to SQL database
- export function to WC3 WE not tested
- issues... as always - could work...
- tables need editing
>>> not all item_types defined / incorrect
>>> item_classes seem to be define the "chest", "head" etc. armor types

=================================================================================================================================================
1.3.2026 - List of Actions:

ZonesCore
- z.Data; added rect definitions: startRegion, moveRegion, exitRegion

ZoneEvent
- Added MoveIn (used by HandleZoneLeave)
- Added MoveOut (used by HandleZoneEnter)
- Added RegisterZoneExitRegions (used to register exit region triggers per zone)
- updated HandleZoneEnter to handle moving the units if that is defined by the zone (ZonesCore zone definitions)
- updated HandleZoneLeave to handle moving the units if that is defined by the zone (ZonesCore zone definitions)

Terraining
- caves
- setting up regions (enter/exit/move,...)

Shield attachment testin
- added more shields to testing area to analyze Nazgrek shield attachment problem



=================================================================================================================================================
28.2.2026 - List of Actions:

Nazgrek model notes:
- previously some time ago fixed model of Nazgrek is in wrong path (war3mapImported/)
>>> remove it from there, only one "nazgrek.mdx" file be in map
- fixed cape texture issues - was using twosided option in material
- cape style "blend" or "transparent" should be checked -> now selection circle is shown through it and maybe other stuff...
>>> Filter mode set to "none"
- testing editing Nazgrek Hand Right/Left Ref attachement points
>>> RESULT: now 1H/2H weapons are off and also the edit went somehow wrongly to shields (Retera studio attachement point dont match - maybe the follow some bone logic etc...)
>>> Testing addind custom "Shield" attachment point to Nazgrek
>>>>> Result: didn't work???

Terraining;
- Wyrmhold Sanctum
- Mini dungeons / caves

ZonesCore
- set z.weatherAllowed = false -> For all dungeons
- edited fog settings for most dungeons
- edited Wyrmhold Sanctum (zone icon, texts)
- Emberpeak Highlands DNC to "Outdoors Mountains"
- More dungeons to be added to ZonesCore (Some are meant to be multipurposed)

>>> cave04
>>>>>>> use case 1: Cinderfall (Emberpeak Highlands)

>>> Cave06
>>>>>>> use case 1: Wolf Den (Sereneglade)
>>>>>>> use case 2: Shadowmaw Cave (Sirensong,Mal'kiri panther)

>>> Dragoncave01
>>>>>>> use case 1: Kobold Mine (Sereneglade

>>> boreanmagnataurmicro
>>>>>>> use case 1: Blazehollow (in Dragonfire Peaks)

>>> hellfirecave (not placed on maps properly)
>>>>>>> use case: Dustfire Cave (Emberpeak Highlands)

>>> ragefire_micro
>>>>>>> use case: Dreadforge

>>> Cellar
>>>>>>> use case 1: Riverbane Inn Cellar
>>>>>>> use case 2: Havenwoods Inn
>>>>>>> use case 3: Stormhaven Inn

>>> Inn / Tavern
>>>>>>> use case 1: Riverbane Inn
>>>>>>> use case 2: Havenwoods Inn
>>>>>>> use case 3: Stormhaven Inn

Inn - RiverbaneInn
Inn - HavenwoodsInn
Inn - StormhavenInn
Cave - Cinderfall
Cave - Wolf Den
Cave - Shadowmaw Cave
Cave - Kobold Mine
Cave - Blazehollow
Cave - Dustfire Cave


DNC
- updated DNC_Firelands to change DNC model
- added DNC_OutdoorsMountains (to be used by Emperpeak Highlands)

ZoneEvent
- Added API call to DNC_OutdoorsMountains





=================================================================================================================================================
27.2.2026 - List of Actions:

- shield test item created (right corner of map)
>>> if ok --> need to do same bone node position edit
>>> note shield attachement was not with the shield models but with nazgrek.mdx model itself (WowConverter issue setting up correct attachement point)

- terraining; cavemicro / drafting for Fel orc / Demon lair boss



=================================================================================================================================================
26.2.2026 - List of Actions:

WeatherSystemv3_maybeWorkingVersion (dont ask...)
- private boolean FPS_CloudsDisabled          => set to true  // Disable clouds for FPS
- private boolean FPS_RipplesDisabled         => set to true  // Disable ripples for FPS
>>> These are temporarily disabled, we need to implement them properly / different way (at least clouds, rippes itself doesn't even seem finished)

DNC
- added DNC_Death1

ZonesCore
- Deadwoods to use DNC_Deat1

ZoneEvent
- updated RunDNC to include DNC_Death1

Note about libraries;
- As some time has passed between development of these libraries (some issues/bugs when last visiting them), 
- it is not clear whether the MAIN map has the latest libraries using same as in TEST map


Skybox testing vol66.6
Via testing with debug commands:
- debug skybox death1 -> to test skybox when all hero players are dead
>>> very good, use for Deadwoods, and when all hero players are dead
- debug skybox death2 -> to test skybox when all hero players are dead
>>> looks good, use e.g., for Emberpeak Highlands
- debug skybox sethral -> random skybox test
>>> looks ok, for dungeon usage - although definitely needs good FOG setting
- debug skybox strat -> random skybox test
>>> Looks ok for fiery place, but has problem with scale maybe... COMPARE to Lordaeron SkyRed
- debug skybox voidsky01 -> random skybox test, maybe for Void related quests
>>>
- debug skybox darkportal -> random skybox test
>>> looks good, suitable for Felfire Bastion area
- debug skybox volcanos -> random skybox test
>>> TO BE REMOVED - does not work good as it is
- debug skybox ruby -> random skybox test
>>> Not remove, very suitable for Vanguard Vale
- debug skybox cavemicro -> random skybox test, for dungeons?
>>> not so good, could be removed?

Other Skybox:
>>> Firelands used skybox looks bad
>>> battleskyboxdirty looks bad

Skyboxes that look promising (even with compressed quality):
- sethral => For Gnoll hideout
- cavemicro => For cave dungeons
- ruby => for Elarindor
- death1 => for when all player heros dead
- ... there were maybe others but texture compression affected the "review"


Added test items for Shields (to see if conversion from WoW worked);
item_objectcomponents_shield_buckler_damaged_a_01
item_objectcomponents_shield_buckler_damaged_a_02
item_objectcomponents_shield_buckler_oval_a_01
item_objectcomponents_shield_buckler_round_a_01
item_objectcomponents_shield_shield_ahnqiraj_d_01

Terraining;
- Havenwoods (dwarven area - modified from murloc area)
- Firelands; red visual blockers and fire testing, very draft still and needs in-game checks
- Sirensong; very small terraining
- Stormhaven; testing adding wall related entrance to the city (staircase, might need less pitch....)

Re-import textures for following skyboxes:1) Make list of all skyboxes (before Folder26 texture update)
1) Make list of all skyboxes (before Folder26 texture update)
war3campImported\\SummerSphereCT2.mdx
	Environment\Sky\LordaeronSummerSky\LordaeronSummerSky.blp (INGAME TEXTURE)
	Textures\cloudstile1.blp
	Textures\cloudstile2.blp
	UI\Glues\SinglePlayer\Orc_Exp\Stars3.blp
	UI\Glues\SinglePlayer\Orc_Exp\moon.blp
	Textures\Flare.blp
	Textures\sun.blp
	Textures\star4.blp
	Textures\Star8.blp
	Textures\Star7b.blp

environments_stars_skywallskybox.mdx
	wow/environments/stars/skwall_skybox_topsky.blp
	wow/environments/stars/skwall_skybox_mist.blp
	wow/environments/stars/skwall_skybox_frontbottom.blp
	wow/environments/stars/skwall_skybox_front.blp
	wow/environments/stars/skwall_skybox_backsky.blp
	wow/environments/stars/skwall_skybox_bottom.blp
	wow/environments/stars/skwall_skybox_back.blp

environments_stars_battlefield_dirty_skybox.mdx
	wow/environments/stars/battlefield_edgesky01.blp
	wow/environments/stars/battlefieldcloudsorange2.blp
	wow/environments/stars/battlefield_dirty_edgeclouds02.blp

war3mapImported\\LordaeronWinterSkyRedCustom.mdx
	Environment\Sky\LordaeronWinterSkyRed\Custom\LordaeronWinterSkyRed.blp

environments_stars_firelandssky01.mdx
	wow/environments/stars/firelandssky_foglayer.blp
	wow/environments/stars/firelandsskyclouds02.blp
	wow/environments/stars/firelandsskyhotspot01.blp
	wow/environments/stars/firelandsskyclouds01.blp
	wow/environments/stars/firelandsskyhorizon01.blp

2) Made list of all new skyboxes
- only handful re-imported
- 95% of them are 3-20mb files
3) Re-imported original textures of these skyboxes



>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Created and imported "visual blockers":
visual\VisualBlocker_black.mdx
visual\VisualBlocker_blue.mdx
visual\VisualBlocker_darkgrey.mdx
visual\VisualBlocker_grey.mdx
visual\VisualBlocker_lightblack.mdx
visual\VisualBlocker_lightwhite.mdx
visual\VisualBlocker_red.mdx

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ITEM Models (Vanilla classic) imported from WoW:
- Shields
- Staves
- Misc_1h
- Misc_2h

item_objectcomponents_shield_buckler_damaged_a_01
item_objectcomponents_shield_buckler_damaged_a_02
item_objectcomponents_shield_buckler_oval_a_01
item_objectcomponents_shield_buckler_round_a_01
item_objectcomponents_shield_shield_ahnqiraj_d_01
>>>> Up-to-this point created test items 

item_objectcomponents_shield_shield_ahnqiraj_d_02
item_objectcomponents_shield_shield_ahnqiraj_d_03
item_objectcomponents_shield_shield_blackwing_drakeadon
item_objectcomponents_shield_shield_blackwing_reddragon
item_objectcomponents_shield_shield_crest_a_01
item_objectcomponents_shield_shield_crest_a_02
item_objectcomponents_shield_shield_crest_b_01
item_objectcomponents_shield_shield_crest_b_02
item_objectcomponents_shield_shield_crest_b_03
item_objectcomponents_shield_shield_engineer_a_01
item_objectcomponents_shield_shield_engineer_b_01
item_objectcomponents_shield_shield_engineer_c_01
item_objectcomponents_shield_shield_epic_a_01
item_objectcomponents_shield_shield_epic_b_01
item_objectcomponents_shield_shield_horde_a_01
item_objectcomponents_shield_shield_horde_a_02
item_objectcomponents_shield_shield_horde_a_03
item_objectcomponents_shield_shield_horde_a_04
item_objectcomponents_shield_shield_horde_b_01
item_objectcomponents_shield_shield_horde_b_02
item_objectcomponents_shield_shield_horde_b_03
item_objectcomponents_shield_shield_horde_b_04
item_objectcomponents_shield_shield_horde_c_02
item_objectcomponents_shield_shield_horde_c_03
item_objectcomponents_shield_shield_lion_a_01
item_objectcomponents_shield_shield_militia_a_01
item_objectcomponents_shield_shield_naxxramas_d_01
item_objectcomponents_shield_shield_naxxramas_d_02
item_objectcomponents_shield_shield_naxxramas_d_03
item_objectcomponents_shield_shield_oval_a_01
item_objectcomponents_shield_shield_pvpalliance_a_01
item_objectcomponents_shield_shield_pvphorde_a_01
item_objectcomponents_shield_shield_rectangle_a_01
item_objectcomponents_shield_shield_rectangle_b_01
item_objectcomponents_shield_shield_round_a_01
item_objectcomponents_shield_shield_round_b_01
item_objectcomponents_shield_shield_stratholme_d_01
item_objectcomponents_shield_shield_stratholme_d_02
item_objectcomponents_shield_shield_wheel_b_01
item_objectcomponents_shield_shield_zulgurub_d_01
item_objectcomponents_shield_shield_zulgurub_d_02

item_objectcomponents_weapon_misc_1h_bone_a_01
item_objectcomponents_weapon_misc_1h_book_a_01
item_objectcomponents_weapon_misc_1h_book_b_01
item_objectcomponents_weapon_misc_1h_book_b_02
item_objectcomponents_weapon_misc_1h_book_c_01
item_objectcomponents_weapon_misc_1h_book_c_02
item_objectcomponents_weapon_misc_1h_bottle_a_01
item_objectcomponents_weapon_misc_1h_bottle_a_02
item_objectcomponents_weapon_misc_1h_bread_a_01
item_objectcomponents_weapon_misc_1h_bread_a_02
item_objectcomponents_weapon_misc_1h_bucket_a_01
item_objectcomponents_weapon_misc_1h_fish_a_01
item_objectcomponents_weapon_misc_1h_flower_a_01
item_objectcomponents_weapon_misc_1h_flower_a_02
item_objectcomponents_weapon_misc_1h_flower_a_03
item_objectcomponents_weapon_misc_1h_flower_a_04
item_objectcomponents_weapon_misc_1h_flower_b_01
item_objectcomponents_weapon_misc_1h_flower_b_02
item_objectcomponents_weapon_misc_1h_gizmo_a_01
item_objectcomponents_weapon_misc_1h_glass_a_01
item_objectcomponents_weapon_misc_1h_glass_a_02
item_objectcomponents_weapon_misc_1h_holysymbol_a_01
item_objectcomponents_weapon_misc_1h_lantern_a_01
item_objectcomponents_weapon_misc_1h_lantern_b_01
item_objectcomponents_weapon_misc_1h_mutton_a_01
item_objectcomponents_weapon_misc_1h_mutton_a_02
item_objectcomponents_weapon_misc_1h_mutton_b_01
item_objectcomponents_weapon_misc_1h_mutton_b_02
item_objectcomponents_weapon_misc_1h_orb_a_01
item_objectcomponents_weapon_misc_1h_orb_a_02
item_objectcomponents_weapon_misc_1h_orb_c_01
item_objectcomponents_weapon_misc_1h_potion_a_01
item_objectcomponents_weapon_misc_1h_potion_b_01
item_objectcomponents_weapon_misc_1h_random
item_objectcomponents_weapon_misc_1h_rollingpin_a_01
item_objectcomponents_weapon_misc_1h_seal_a_01
item_objectcomponents_weapon_misc_1h_seal_b_01
item_objectcomponents_weapon_misc_1h_seal_c_01
item_objectcomponents_weapon_misc_1h_skull_b_01
item_objectcomponents_weapon_misc_1h_sparkler_a_01blue
item_objectcomponents_weapon_misc_1h_sparkler_a_01red
item_objectcomponents_weapon_misc_1h_sparkler_a_01white
item_objectcomponents_weapon_misc_1h_tankard_a_01
item_objectcomponents_weapon_misc_1h_waterwand_a_01
item_objectcomponents_weapon_misc_1h_wrench_a_01

item_objectcomponents_weapon_misc_2h_broom_a_01
item_objectcomponents_weapon_misc_2h_fishingpole_a_01
item_objectcomponents_weapon_misc_2h_harpoon_b_01
item_objectcomponents_weapon_misc_2h_pitchfork_a_01
item_objectcomponents_weapon_misc_2h_shovel_a_01

item_objectcomponents_weapon_stave_2h_ahnqiraj_d_01
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_02
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_03
item_objectcomponents_weapon_stave_2h_ahnqiraj_d_04
item_objectcomponents_weapon_stave_2h_blackwing_a_01
item_objectcomponents_weapon_stave_2h_blackwing_a_02
item_objectcomponents_weapon_stave_2h_epic_a_01
item_objectcomponents_weapon_stave_2h_flaming_d_01
item_objectcomponents_weapon_stave_2h_jeweled_a_01
item_objectcomponents_weapon_stave_2h_jeweled_a_02
item_objectcomponents_weapon_stave_2h_jeweled_a_03
item_objectcomponents_weapon_stave_2h_jeweled_b_01
item_objectcomponents_weapon_stave_2h_jeweled_b_02
item_objectcomponents_weapon_stave_2h_jeweled_c_01
item_objectcomponents_weapon_stave_2h_jeweled_d_01
item_objectcomponents_weapon_stave_2h_long_a_01
item_objectcomponents_weapon_stave_2h_long_a_02
item_objectcomponents_weapon_stave_2h_long_a_03
item_objectcomponents_weapon_stave_2h_long_a_04
item_objectcomponents_weapon_stave_2h_long_b_01
item_objectcomponents_weapon_stave_2h_long_b_02holy
item_objectcomponents_weapon_stave_2h_long_b_03
item_objectcomponents_weapon_stave_2h_long_b_04
item_objectcomponents_weapon_stave_2h_long_c_01
item_objectcomponents_weapon_stave_2h_long_c_02
item_objectcomponents_weapon_stave_2h_long_d_01
item_objectcomponents_weapon_stave_2h_long_d_05
item_objectcomponents_weapon_stave_2h_long_epicpriest01
item_objectcomponents_weapon_stave_2h_long_epicpriest02
item_objectcomponents_weapon_stave_2h_medivh_d_01
item_objectcomponents_weapon_stave_2h_other_a_01
item_objectcomponents_weapon_stave_2h_other_b_01
item_objectcomponents_weapon_stave_2h_other_c_01
item_objectcomponents_weapon_stave_2h_other_c_02
item_objectcomponents_weapon_stave_2h_other_d_01
item_objectcomponents_weapon_stave_2h_pvpalliance_a_01
item_objectcomponents_weapon_stave_2h_pvphorde_a_01
item_objectcomponents_weapon_stave_2h_scythe_c_03
item_objectcomponents_weapon_stave_2h_stratholme_d_01
item_objectcomponents_weapon_stave_2h_stratholme_d_02
item_objectcomponents_weapon_stave_2h_stratholme_d_03
item_objectcomponents_weapon_stave_2h_zulgurub_d_01
item_objectcomponents_weapon_stave_2h_zulgurub_d_02
item_objectcomponents_weapon_stave_2h_zulgurub_d_03

=================================================================================================================================================
25.2.2026 - List of Actions:

Crit note:
- skybox texture quality got really horrible after compression with BLP Lab!
- this may effect already previously imported models!
- may need re-import skybox textures!
- Check older versions from EpicQuestsFolder28 or 27 etc. maybe 26? older can do as well...


Added debug commands:
- debug blackmask1 -> to test whether we could use black mask to hide unwanted visibility of areas
>>> Didnt do shit
- debug skybox death1 -> to test skybox when all hero players are dead
- debug skybox death2 -> to test skybox when all hero players are dead
- debug skybox sethral -> random skybox test
- debug skybox strat -> random skybox test
- debug skybox voidsky01 -> random skybox test, maybe for Void related quests
- debug skybox darkportal -> random skybox test
- debug skybox volcanos -> random skybox test
- debug skybox ruby -> random skybox test
- debug skybox cavemicro -> random skybox test, for dungeons?

Skyboxes that look promising (even with compressed quality):
- sethral => For Gnoll hideout
- cavemicro => For cave dungeons
- ruby => for Elarindor
- death1 => for when all player heros dead
- ... there were maybe others but texture compression affected the "review"





Re-edited (maybe this time?) models causing lag in-game and in WE (at least for AMD GPU/CPU randomly):
md_cryptsimpleent2.mdx

>>> Will many re-checks (different PC shutdown / WC3 / WE starts) to evaluate is the lag gone, because sometimes before there was no lag, and other WE map loading there was lag


Check for crypt models:
world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo 
>>> not used (older model?)

world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e2.wmo
>>> OK no lag
world_wmo_dungeon_md_crypt_md_cryptsimpleent_md_cryptsimpleent_md.wmo
>>> OK no lag
world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo
>>> causes lag
md_cryptsimpleent2
>>> causes lag


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ENVIRONMENTAL / PROPS Models imported from WoW:
environments_stars_8des_sethralisssky04
environments_stars_deathclouds
environments_stars_deathskybox__e38898f61f50c7ebf4f12515f3390ceb
environments_stars_lostislevocanoskybox
environments_stars_rubysanctumsky
environments_stars_shadowmoonburialgrounds_voidsky01
environments_stars_stratholmeskybox
environments_stars_tanaan_darkportal_front_sky01
environments_stars_tanaan_patch_infernalball_01
world_azeroth_karazahn_activedoodads_karazahn_chessroomdoors
world_azeroth_karazahn_activedoodads_karazahn_secretroomdoor
world_expansion02_doodads_scholazar_waterfalls_sholazarsouthoceanwaterfall-06
world_expansion03_doodads_firelands_ragnaros_firewall_ragnaros_firewall
world_expansion03_doodads_grimbatolraid_grimbatolraid_fire_wall_01
world_expansion03_doodads_grimbatolraid_grimbatolraid_fire_wall_02
world_expansion05_doodads_fx_6fx_firewall_door
world_expansion05_doodads_fx_6fx_firewall_door_sm
world_expansion05_doodads_fx_6fx_firewall_doorfel
world_expansion05_doodads_fx_6fx_firewall_doorsmfel
world_expansion05_doodads_nagrand_doodads_6ng_burningblade_micro_lavafall01
world_expansion07_doodads_fx_8fx_firewall_door
world_expansion07_doodads_fx_8fx_firewall_door_small
world_kalimdor_hyjal_passivedoodads_fire_hyjal_red_wall_fire_01
world_wmo_brokenisles_7xp_karazhanroom01
world_wmo_dungeon_hellfire_hellfire_wall01.wmo__57d3e71d89d4fa666f61b1738d82091f
world_wmo_dungeon_hellfire_hellfire_wall02.wmo__28a564e9bc7e0d778a9c8386f1c56422
world_wmo_dungeon_hellfire_hellfire_wall03.wmo__584af82697e25625678c8f680bbfe170
world_wmo_dungeon_hellfire_hellfire_wall04.wmo__c84087523ed30450ba8d3a4bdd5b6940
environments_stars_8des_cavemicrosky01

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BUILDING / INTERIOR Models imported from WoW:
world_expansion01_doodads_pvp_activedoodads_doors_pvp_ogre_door_interior
world_expansion01_doodads_pvp_activedoodads_doors_pvp_orc_door_interior
world_wmo_brokenisles_vrykul_7vr_vrykul_dwellingmedium01_interior
world_wmo_dungeon_boreanmagnataurmicro_boreanmagnataurmicro_1room
world_wmo_kalimdor_buildings_orctower_abandonedorctower
world_wmo_kalimdor_buildings_orctower_abandonedorctower_alt
world_wmo_khazmodan_buildings_dwarven_tavern_wetlands_tavern_wet_tavern
world_wmo_northrend_buildings_human_nd_human_inn_nd_human_inn
world_wmo_pandaria_jadeforest_orcrefuge_orcrefugetent


Terraining;
- Minizones (minimap rooms) added, located near Firelands
- Firelands zone desperately needs visual barricades to block view outside Firelands and especially seeing these minizone rooms/caves, whatever



=================================================================================================================================================
24.2.2026 - List of Actions:


Todo;
- Check minizones / subzones draft locations in-game (Firelands refactored area)
- Crypt are lag caused by "crypt" models;
>>> Extends and whatever most likely broken as Crypt related doodads could be accidently clicked far away from the model (collision boxes reaching far)
>>> Need to make necessary fixes in Retera Studio (or are there already fixed models because something was done before in Retera related to extends / geosets, etc.)

Zone ideas:
- murloc are near orcs to be smaller and add goblin area there (draft building remarking the spot)

Terraining:
- Dragonpeak Mountains / Wyrmhold Sanctum layout drafting
- Thornwoods; Check what thorns / roots work best for Thornwoods "look"

>>>>>> Many exported models made into doodads;

world_kalimdor_mulgore_passivedoodads_thorns_mullgorethornspike
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn07
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn06
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn05
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn04
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn03
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn02
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn01
world_outland_passivedoodads_thorns_outlandthorn07
world_outland_passivedoodads_thorns_outlandthorn06
world_outland_passivedoodads_thorns_outlandthorn05
world_outland_passivedoodads_thorns_outlandthorn04
world_outland_passivedoodads_thorns_outlandthorn03
world_outland_passivedoodads_thorns_outlandthorn02
world_outland_passivedoodads_thorns_outlandthorn01__61d808f48932cb35e09b4aa787da4c40
world_outland_passivedoodads_roots_outlandroot03
world_outland_passivedoodads_roots_outlandroot02
world_outland_passivedoodads_roots_outlandroot01

Added many models into doodad objects (from latest exports)
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash01
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash02
world_expansion02_doodads_generic_scourge_icecrown_stairs01
world_expansion02_doodads_generic_scourge_sc_stairs2
world_expansion03_doodads_firelands_towerflame_firelands_towerflame01

world_wmo_brokenisles_araknashal_7an_dragoncave01
world_wmo_brokenisles_araknashal_7an_dragoncave02
world_wmo_brokenisles_araknashal_7an_dragoncave03
world_wmo_brokenisles_azsuna_7az_sinkhole_cave01
world_wmo_brokenisles_legion_7lg_legion_cave01
world_wmo_brokenisles_legion_7lg_legion_cave02
world_wmo_brokenisles_legion_7lg_legion_cave03
world_wmo_brokenisles_legion_7lg_legion_cave04
world_wmo_brokenisles_legion_7lg_legion_cave05
world_wmo_brokenisles_legion_7lg_legion_cave06
world_wmo_scenario_ragefire_ragefire_micro

>>>> Maybe modify into smaller models?
world_wmo_brokenisles_legion_7lg_legion_cave01
world_wmo_brokenisles_legion_7lg_legion_cave05 ???? not working?


=================================================================================================================================================
23.2.2026 - List of Actions:

Fixed following models:
world_wmo_dungeon_kl_orgrimmarlavadungeon_lavadungeon
world_wmo_scenario_ragefire_ragefire_micro

Some terraining
- e.g., Dragon boss area drafting


=================================================================================================================================================
22.2.2026 - List of Actions:

Requirements_DialogSystemPlan
- added ESC key function (configurability)
- dialog outcomes / flows / paths

Other:
- Testing compressing textures which hugely reduces the overall map size

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Models imported from WoW:
world_wmo_brokenisles_valsharah_7vs_gilneas_building01
world_wmo_brokenisles_valsharah_7vs_gilneas_building02
world_wmo_brokenisles_valsharah_7vs_gilneas_building03
world_wmo_brokenisles_valsharah_7vs_gilneas_building04
world_wmo_brokenisles_valsharah_7vs_gilneas_building05
world_wmo_brokenisles_valsharah_7vs_gilneas_building06
world_wmo_brokenisles_valsharah_7vs_gilneas_building07
world_wmo_brokenisles_valsharah_7vs_gilneas_building08
world_wmo_brokenisles_valsharah_7vs_gilneas_building09
world_wmo_brokenisles_valsharah_7vs_gilneas_building10
world_expansion07_doodads_barbarianzone_8dru_fallingleaves_b01
world_expansion05_doodads_nagrand_doodads_6ng_fallingleaves_arid01
world_expansion03_doodads_gilneas_trees_fallingoakleaves01
world_expansion03_doodads_gilneas_trees_fallingoakleaves02
world_expansion03_doodads_gilneas_detaildoodads_gnleaves01
world_expansion03_doodads_gilneas_detaildoodads_gnleaves02
world_expansion03_doodads_gilneas_detaildoodads_gnleaves03
world_expansion03_doodads_gilneas_trees_oaktree01
world_expansion03_doodads_gilneas_trees_oaktree02
world_expansion03_doodads_gilneas_trees_oaktree03
world_expansion03_doodads_gilneas_trees_oaktree04
world_expansion03_doodads_gilneas_trees_oaktree05
world_expansion03_doodads_gilneas_trees_oaktreeroot01
world_expansion03_doodads_gilneas_trees_oaktreeroot02
world_expansion03_doodads_gilneas_trees_oaktreeroot03
world_expansion03_doodads_gilneas_trees_oaktreeroot04

creature_worgen_worgen

>>> The following are to be used for Alchemy / Herbalism / Mining
world_skillactivated_tradeskillnodes_ancientgem_miningnode_01
world_skillactivated_tradeskillnodes_incendicite_miningnode_01
world_skillactivated_tradeskillnodes_mithril_miningnode_01
world_skillactivated_tradeskillnodes_tin_miningnode_01
world_skillactivated_tradeskillnodes_truesilver_miningnode_01
world_skillactivated_tradeskillnodes_feliron_miningnode_01
world_skillactivated_tradeskillnodes_bush_ancientlichen
world_skillactivated_tradeskillnodes_bush_arthastears
world_skillactivated_tradeskillnodes_bush_azsharasveil
world_skillactivated_tradeskillnodes_bush_blacklotus
world_skillactivated_tradeskillnodes_bush_blindweed
world_skillactivated_tradeskillnodes_bush_bloodthistle
world_skillactivated_tradeskillnodes_bush_bruiseweed01
world_skillactivated_tradeskillnodes_bush_chameleonlotus
world_skillactivated_tradeskillnodes_bush_cinderbloom
world_skillactivated_tradeskillnodes_bush_constrictorgrass
world_skillactivated_tradeskillnodes_bush_crownroyal01
world_skillactivated_tradeskillnodes_bush_dragonsteeth
world_skillactivated_tradeskillnodes_bush_dreamfoil
world_skillactivated_tradeskillnodes_bush_dreamingglory
world_skillactivated_tradeskillnodes_bush_evergreenmoss
world_skillactivated_tradeskillnodes_bush_fadeleaf01
world_skillactivated_tradeskillnodes_bush_felweed
world_skillactivated_tradeskillnodes_bush_firebloom
world_skillactivated_tradeskillnodes_bush_fireweed
world_skillactivated_tradeskillnodes_bush_flamecap
world_skillactivated_tradeskillnodes_bush_foolscap
world_skillactivated_tradeskillnodes_bush_frostlotus
world_skillactivated_tradeskillnodes_bush_frostweed
world_skillactivated_tradeskillnodes_bush_frozenherb
world_skillactivated_tradeskillnodes_bush_goldclover
world_skillactivated_tradeskillnodes_bush_goldenlotus
world_skillactivated_tradeskillnodes_bush_gravemoss01
world_skillactivated_tradeskillnodes_bush_gromsblood
world_skillactivated_tradeskillnodes_bush_heartblossom
world_skillactivated_tradeskillnodes_bush_icecap
world_skillactivated_tradeskillnodes_bush_jadetealeaf
world_skillactivated_tradeskillnodes_bush_khadgarswhisker01
world_skillactivated_tradeskillnodes_bush_magebloom01
world_skillactivated_tradeskillnodes_bush_manathistle
world_skillactivated_tradeskillnodes_bush_mountainsilversage
world_skillactivated_tradeskillnodes_bush_mushroom03
world_skillactivated_tradeskillnodes_bush_mushroom02
world_skillactivated_tradeskillnodes_bush_mushroom01
world_skillactivated_tradeskillnodes_bush_netherbloom
world_skillactivated_tradeskillnodes_bush_nightmarevine
world_skillactivated_tradeskillnodes_bush_peacebloom01
world_skillactivated_tradeskillnodes_bush_plaguebloom
world_skillactivated_tradeskillnodes_bush_purplelotus
world_skillactivated_tradeskillnodes_bush_ragveil
world_skillactivated_tradeskillnodes_bush_rainpoppy
world_skillactivated_tradeskillnodes_bush_sansam
world_skillactivated_tradeskillnodes_bush_shaherb
world_skillactivated_tradeskillnodes_bush_silkweed
world_skillactivated_tradeskillnodes_bush_silverleaf01
world_skillactivated_tradeskillnodes_bush_snowlily
world_skillactivated_tradeskillnodes_bush_spineleaf
world_skillactivated_tradeskillnodes_bush_stardust
world_skillactivated_tradeskillnodes_bush_starflower
world_skillactivated_tradeskillnodes_bush_steelbloom01
world_skillactivated_tradeskillnodes_bush_stormvine
world_skillactivated_tradeskillnodes_bush_stormvinebubbles
world_skillactivated_tradeskillnodes_bush_stranglekelp01
world_skillactivated_tradeskillnodes_bush_sungrass
world_skillactivated_tradeskillnodes_bush_swiftthistle01
world_skillactivated_tradeskillnodes_bush_taladororchid
world_skillactivated_tradeskillnodes_bush_talandrasrose
world_skillactivated_tradeskillnodes_bush_goldthorn01
world_skillactivated_tradeskillnodes_bush_icethorn
world_skillactivated_tradeskillnodes_bush_terrocone
world_skillactivated_tradeskillnodes_bush_tigerlily
world_skillactivated_tradeskillnodes_bush_twilightjasmine
world_skillactivated_tradeskillnodes_bush_whiptail01
world_skillactivated_tradeskillnodes_bush_whispervine
world_skillactivated_tradeskillnodes_bush_wintersbite01
world_skillactivated_tradeskillnodes_stranglekelp_01
world_skillactivated_tradeskillnodes_bush_liferoot01
world_skillactivated_tradeskillnodes_bush_snakeroot
world_skillactivated_tradeskillnodes_bush_thornroot01

>>> Many of these intended for Thornwoods
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethornspike
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn07
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn06
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn05
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn04
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn03
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn02
world_kalimdor_mulgore_passivedoodads_thorns_mullgorethorn01
world_outland_passivedoodads_thorns_outlandthorn07
world_outland_passivedoodads_thorns_outlandthorn06
world_outland_passivedoodads_thorns_outlandthorn05
world_outland_passivedoodads_thorns_outlandthorn04
world_outland_passivedoodads_thorns_outlandthorn03
world_outland_passivedoodads_thorns_outlandthorn02
world_outland_passivedoodads_thorns_outlandthorn01__61d808f48932cb35e09b4aa787da4c40
world_wmo_azeroth_buildings_stranglethorn_bootybay_bootybay_railing
world_wmo_azeroth_buildings_stranglethorn_bootybay_bootybay_house2
world_wmo_azeroth_buildings_stranglethorn_bootybay_bootybay_house1
world_kalimdor_kalidar_passivedoodads_kalidarroots_kalidarroots03
world_kalimdor_kalidar_passivedoodads_kalidarroots_kalidarroots02
world_kalimdor_kalidar_passivedoodads_kalidarroots_kalidarroots01
world_outland_passivedoodads_roots_outlandroot03
world_outland_passivedoodads_roots_outlandroot02
world_outland_passivedoodads_roots_outlandroot01
world_generic_quilboar_passive doodads_thorncanopies_thorncanopy_03
world_generic_quilboar_passive doodads_thorncanopies_thorncanopy_02
world_generic_quilboar_passive doodads_thorncanopies_thorncanopy_01

creature_northrendworgen_northrendworgen

world_wmo_azeroth_buildings_gilneas_gilneas_marketquarter
world_wmo_brokenisles_valsharah_7vs_gilneas_town01

>>> Many of these are as inspiration for Firelands / Dragon Den dungeon:
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash01
world_expansion01_doodads_shadowmoon_guyser_shadowmoon_lavasplash02
world_expansion02_doodads_generic_scourge_icecrown_stairs01
world_expansion02_doodads_generic_scourge_sc_stairs2
world_expansion03_doodads_firelands_towerflame_firelands_towerflame01
world_expansion03_doodads_grimbatol_lava_grimbatol_cave_lavafalls_01
world_expansion03_doodads_grimbatol_lava_grimbatol_cave_lavafalls_02
world_generic_human_passive doodads_woodenstairs_woodenstairs01
world_generic_human_passive doodads_woodenstairs_woodenstairs02
world_wmo_azeroth_buildings_gilneas_gilneas_cellar_1
world_wmo_azeroth_buildings_gilneas_gilneas_manor
world_wmo_azeroth_buildings_stormwind_sw_staircase
world_wmo_brokenisles_araknashal_7an_dragoncave01
world_wmo_brokenisles_araknashal_7an_dragoncave02
world_wmo_brokenisles_araknashal_7an_dragoncave03
world_wmo_brokenisles_azsuna_7az_sinkhole_cave01
world_wmo_brokenisles_legion_7lg_legion_cave01
world_wmo_brokenisles_legion_7lg_legion_cave02
world_wmo_brokenisles_legion_7lg_legion_cave03
world_wmo_brokenisles_legion_7lg_legion_cave04
world_wmo_brokenisles_legion_7lg_legion_cave05
world_wmo_brokenisles_legion_7lg_legion_cave06
world_wmo_brokenisles_valsharah_7vs_cavemicro01
world_wmo_dungeon_kl_orgrimmarlavadungeon_lavadungeon
world_wmo_hozu_huts_hz_mountaincaveclosed2.wmo__8dde19c967e0ce85e82c43c76d0dc9b4
world_wmo_scenario_ragefire_ragefire_micro

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

>>> Terraining Havenwoods / Stormhaven outside area
>>> Terraining Emberpeark Highlands

=================================================================================================================================================
19.2.2026 - List of Actions:

Created requirements files to update DialogSystem, QuestGiver, QuestMaster;
- Requirements_DialogSystem.md
- Requirements_DialogSystemPlan.md
- Requirements.Quests.md

No changes yet to the systems themselves.


=================================================================================================================================================
15.2.2026 - List of Actions - CRASH debug log:
2/15 22:29:29.364  Opening map - C:/Users/Valtteri/Documents/Warcraft III/Maps/EpicQuests/Epic Quests.w3x
2/15 22:29:40.258  model creation failed - war3mapImported\Build.mdx
2/15 22:29:40.258  model creation failed - war3mapImported\DecayMesh.mdx
2/15 22:29:51.310  model creation failed - 
2/15 22:29:51.551  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.551  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.566  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.566  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.632  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:51.633  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.131  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestRight.mdl
2/15 22:29:52.174  model creation failed - Abilities\Spells\Other\SpikedShell\SpikedShellTargetChestLeft.mdl
2/15 22:29:52.448  model creation failed - 
2/15 22:29:52.448  model creation failed - 
2/15 22:29:53.040  model creation failed - 
2/15 22:29:55.280  model creation failed - https://www.hiveworkshop.com/members/sarsaparilla.295950/
2/15 22:29:55.280  model creation failed - https://www.patreon.com/user?u=52986355
2/15 22:29:55.449  model creation failed - https://www.hiveworkshop.com/members/sarsaparilla.295950/
2/15 22:29:55.449  model creation failed - https://www.patreon.com/user?u=52986355
2/15 22:29:56.495  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 22:29:56.495  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//5) Error, string /SimpleInfoPanelTitleTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//11) Error, string /SimpleInfoPanelTitleTextDisabledTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//15) Error, string /SimpleInfoPanelDescriptionTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//21) Error, string /SimpleInfoPanelDescriptionHighlightTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//24) Error, string /SimpleInfoPanelDescriptionDisabledTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//28) Error, string /SimpleInfoPanelLabelTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//36) Error, string /SimpleInfoPanelLabelHighlightTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//39) Error, string /SimpleInfoPanelLabelDisabledTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//43) Error, string /SimpleInfoPanelValueTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//47) Error, string /SimpleInfoPanelObserverValueTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//56) Error, string /SimpleInfoPanelAttributeTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//62) Error, string /SimpleInfoPanelAttributeDisabledTextTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//66) Error, string /InfoPanelIconTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//72) Error, string /ResourceIconTemplate already exists!
2/15 22:32:38.931  (war3mapImported\ShowUnitLevel.fdf//77) Error, string /ResourceTextTemplate already exists!
2/15 22:40:30.014  model creation failed - 
2/15 22:41:20.749  model creation failed - 
2/15 22:41:26.785  model creation failed - 
2/15 22:41:32.808  model creation failed - 
2/15 22:42:16.784  model creation failed - 
2/15 22:42:34.872  model creation failed - 
2/15 22:42:46.923  model creation failed - 
2/15 22:44:10.165  model creation failed - 
2/15 22:45:04.344  model creation failed - 
2/15 22:46:58.625  model creation failed - 
2/15 22:47:12.396  model creation failed - 
2/15 22:47:16.925  model creation failed - 
2/15 22:47:25.549  model creation failed - 
2/15 22:47:30.871  model creation failed - 
2/15 22:47:49.387  model creation failed - 
2/15 22:47:51.257  model creation failed - 
2/15 22:48:01.450  model creation failed - 
2/15 22:48:03.384  model creation failed - 
2/15 22:48:18.864  model creation failed - 
2/15 22:48:23.055  model creation failed - 
2/15 22:48:27.659  model creation failed - 
2/15 22:48:33.735  model creation failed - 
2/15 22:48:35.253  model creation failed - 
2/15 22:48:51.943  model creation failed - 
2/15 22:49:19.927  model creation failed - 
2/15 22:49:38.220  model creation failed - 
2/15 22:50:08.617  prism: Error Invalid (0x80070057): pm_dx11::Device::CreateBuffer: CreateBuffer Failed
2/15 22:50:42.670  model creation failed - 
2/15 22:51:12.729  model creation failed - 
2/15 22:51:24.947  model creation failed - 
2/15 22:51:46.694  model creation failed - 


=================================================================================================================================================
15.2.2026 - List of Actions:

Terraining
- Vanguard Vale
- Verdant Plains
- Havenwoods / Stormhaven

Continued coding libraries for following:
- QuestMaster
- QuestGiver
- qAradion

Changes to above;
- Support messages for Return to questGiver / questReceiver
- Quest map icon / effect on questgiver/receiver unit is updated delayed same as with the quest messages for more synchronized visuality
- When creating quests in qSublibrary; If the quest giver and quest receiver are the same unit (like Aradion), you only need to call setReceiverDisplayName(giverName).

------------------------------------------------------------------ Main map todos;
Note: if any updates later in test map, copy updated scripts to main map!

- Create Folder Quests (-----> DONE)
- Create Folder QuestGivers (-----> DONE)
These from top onwards order;
- Create script QuestMaster and copy from VS Code  (-----> DONE)
- Create script DialogSystem and copy from VS Code  (-----> DONE)
- Create script QuestGiver and copy from VS Code   (-----> DONE)
- Create script qAradion and copy from VS Code (-----> DONE)

Old systems:
- Disable Triggers in Quest Handling System
>>> Rename the folder Quest Handling System OLD
- Disable script QuestIconSystem (-----> DONE)
- Disable script QuestEvaluationSystem (-----> DONE)
>>> Rename folder "Quest Icon System OLD" (-----> DONE)
>>> Rename folder "Quest Evaluation System OLD" (-----> DONE)
>>> disable "Call QuestEvaluateSystemInit()" in trigger Orc Cleanup (-----> DONE)

=========================
CRITICAL NOTE: if disabling old quest system related scripts and triggers, all other quest giver related triggers will fail to compile because they are heavily utilizing them!
=========================
CRITICAL NOTE2: The following quests / associated triggers are disabled/broken and yet to utilize new QuestSystems 

Whelps of Destruction
Dragon Egg Hunt
Desolator

Mistaken Kin

Token Love
Lost Supplies

Kaelthir Struggle
Kaelthir Hunger

Ogre Lost His Sandwitch
Kribugs Lost His Satchel
Ogre Is Very Thirsty
Meat For The Ogre
Angry Customers

Explosive Crisis
Boomsite Compliance
More Hazard Mitigation
Mandatory Training
Boom Will Be Back

Other:
BOSS Mad Blix dies - had call to QuestIcon system

=========================
CRITICAL NOTE 3: All other quest givers except Aradion and older (ancient) quest style npcs ARE NOW DISABLED
- meaning no dialogue/dialog/quests for these
- these are to be refactored into qQuestGiverName libraries!
=========================

Folder "Aradion the Farseer"
- set all triggers disabled - do not remove yet (-----> DONE)
- there are still some triggers we need to check like in the "Events" -folder

Later todos:
- No need for following variables (handled by DialogSystem)
>>> All variables in "DIALOGS" -folder
- All quest folders to be scrapped, but one by one - because we need to convert them to qSublibrary scripts

Update Following:
- SharedDInvLib (-----> DONE)
- HeroItemCheck (-----> DONE)
- Reputation (-----> DONE)
- CreepUnitAssignment (-----> DONE)

------------------------------------------------------------------


=================================================================================================================================================
14.2.2026 - List of Actions:

Reputation
- Changed the reputation tier constants from private to public so they can be accessed from other libraries
- Now accessible as Reputation_REP_ENEMY, Reputation_REP_HOSTILE, Reputation_REP_UNFRIENDLY, Reputation_REP_NEUTRAL, Reputation_REP_FRIENDLY, Reputation_REP_COVENANT, Reputation_REP_EXALTED

SharedDInvLib.j
- Updated function "GetDInvItemChargesByType" to also check vanilla inventory
- Critical for QuestGiver.j item gather progress function checks

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- QuestGiver
- QuestMaster
- qAradion

Updates to Quest Systems in short: 
- Support for separate QuestGiver and QuestReceiver NPCs
- added new quest types: TalkTo, FindNPC, GoToPlace, GetRep,Investigate
- The previously mentioned systems are becoming closer and closer to ready systems
- Escort quest type possibility added utilizing FollowSystem.j
- qAradion / qSublibrary should be more easier to copy-paste for other quest givers, there is still quite many manual work involved...
>>> Though it might not be wise to make qSubLibrary as generic as possible because we want to have control per qGiver
>>> Still need to check most generic uses and could those be implemented as functions inside QuestGiver or DialogSystem and in qSublibrary only minimial effort required, like change unit / durations, texts, etc.

Critical error;
- Game crashes randomly, the issue trying to get fixed by having safety checks on Quests Systems related libraries for edge-cases,
- but it is starting to look that the crash causer might be related to other systems than Quests system related
- Could be WeatherSystem or Zones related crash, but this is not known
- the crash/critical error is totally random

Some info from crash.txt / Error log: 2026-02-15 00.15.38 fa6fb12c
<Exception.Summary:>
ACCESS_VIOLATION (Failed to write address 0x0000000000000000 at instruction 0x00007FF6F7F67732) DBG-OPTIONS<FunctionsOnly SingleLine> DBG-ADDR<00007FF6F7F67732>("Warcraft III.exe") <- DBG-ADDR<0000029CEF6F9850>("") <- DBG-ADDR<0000029CEEBF7650>("")  DBG-OPTIONS<>
<:Exception.Summary>

Also these errors in War3Log.txt:
2/15 00:08:10.797  Opening map - C:/Users/Valtteri/AppData/Local/Temp/WorldEditTestMap.w3x
2/15 00:08:12.123  model creation failed - war3campImported\SummerSphereCT2.mdx
2/15 00:08:12.123  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:08:12.123  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:08:12.158  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 00:08:12.158  (war3mapImported\TasQuestBox.fdf//437) Error, string /ReplayPanelStringTemplate already exists!
2/15 00:08:20.672  model creation failed - environments_stars_battlefield_dirty_skybox.mdx
2/15 00:08:20.672  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:08:20.672  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:45.973  model creation failed - war3campImported\SummerSphereCT2.mdx
2/15 00:13:45.973  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:45.973  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:56.652  model creation failed - environments_stars_battlefield_dirty_skybox.mdx
2/15 00:13:56.652  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:13:56.652  model creation failed - Environment\DNC\DNCAnimated2\DNCAnimated2_Darker.mdl
2/15 00:15:38.714  Played C:/Users/Valtteri/AppData/Local/Temp/WorldEditTestMap.w3x

>>> Fixed these errors for the testing map by importing them (they were missing...)
>>> Could most likely just been the causes of the random crashes



=================================================================================================================================================
13.2.2026 - List of Actions:

Imported following models from WoW:
world_expansion02_doodads_zuldrak_waterfalls_zuldrak_waterfalls_set1_high_ripples.mdx
world_expansion05_doodads_ashran_6as_a_graveyard_set_1.mdx
world_expansion06_doodads_suramar_7sr_dungeonwaterfall02.mdx
world_expansion07_doodads_dungeon_doodads_8du_cityofgoldwaterfall_01.mdx
world_expansion07_doodads_dungeon_doodads_8du_cityofgoldwaterfall_02.mdx
world_expansion07_doodads_zuldazarzone_8zul_cityofgoldwaterfall_b17.mdx

world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_01.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_02.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_03.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_04.mdx
world_azeroth_stranglethorn_passivedoodads_seaweed_bootybay_seaweed_05.mdx
world_expansion01_doodads_bladesedge_bush_bladesedgebush01.mdx
world_expansion01_doodads_bladesedge_bush_bladesedgebush02.mdx
world_expansion03_doodads_worgen_walls_worgen_citywall_01_broken.mdx
world_expansion06_doodads_7xp_fel_largerock_c01.mdx
world_expansion06_doodads_7xp_fel_largerock_c02.mdx
world_expansion06_doodads_7xp_fel_largerock_c03.mdx
world_expansion06_doodads_suramar_7sr_citygroundbush_a01.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter02.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter03.mdx
world_generic_human_passive doodads_planterboxes_stormwindplanter04.mdx
world_generic_human_passive doodads_stormwind_stormwindfountain_03.mdx
world_generic_human_passive doodads_stormwind_waterfalls_stormwind_waterfall_03.mdx
world_generic_human_passive doodads_vendorawnings_stormwindvendorawning01.mdx
world_wmo_brokenisles_fel_7xp_fel_largerock_c03.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b01.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b02.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b03.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b04.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b05.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b06.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b07.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b08.mdx
world_wmo_brokenisles_fel_7xp_fel_wmorock_b09_bone.mdx
world_wmo_lorderon_undercity_8xp_lordaeronboulderwmo.mdx

==> And some already placed on the map

Terraining
- Stormhaven / Havenwoods

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- DiagloSystemPlayer
- QuestGiver
- QuestMaster
- qAradion

==> Most notable updates/implementations regarding above; 
>>> Cinematic mode, mover, unit facing, head facing, quest messages correctly

=================================================================================================================================================
12.2.2026 - List of Actions:

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- DiagloSystemPlayer
- QuestGiver
- qAradion


=================================================================================================================================================
11.2.2026 - List of Actions:

Continued coding libraries for following (many changes/additions - but not too important at this stage to write here....;
- DialogSystem
- DiagloSystemPlayer
- QuestGiver
- qAradion

List of todo / suggestion to qSublibrary (Aradion) to move generic functions elsewhere:
>>> GPT 5.2 Codex:
Here is a focused review of the generic-looking logic in qAradion that should move into a shared library (QuestGiver or DialogSystem) so qAradion only supplies content, flags, and minimal custom gating.

Generic helpers that can be centralized
Debug/logger wrapper and quest lookup are generic and not content-specific; GetQuest is unused. Consider moving to QuestGiver or removing. qAradion.j:62-74
Camera preset wrappers are generic and currently unused; either move to DialogSystem or remove. qAradion.j:85-92

Generic “sequence end” handlers
These all do the same sequence-close pattern (close dialog, cooldown, stop camera). That should be a reusable QuestGiver helper:
Info end/start flow. qAradion.j:95-107
Accept/fail/complete end handlers for quests 1–4. qAradion.j:200-420
Farewell end handler. qAradion.j:434-438

Generic accept/complete/farewell sequence scaffolding
Each accept sequence repeats: create sequence → set default speaker → set callbacks → add hero accept line → add NPC accept line → custom lines → play. This should be a QuestGiver helper that takes custom lines as input. qAradion.j:207-355 and qAradion.j:386-413
Farewell sequence is also boilerplate aside from the NPC text pool. qAradion.j:440-456

Generic dialog-building rules
BuildDialog is mostly state-driven button logic (accept/complete/fail). This is prime for a data-driven builder in QuestGiver, with qAradion only supplying per-quest button rules and a few custom conditions (e.g., RangerMissingReq1Complete, Valeria proximity). qAradion.j:466-540

Generic dialog show + selection gating
ShowDialog and OnSelected are standard flow control (selection gate, first greet, then normal greet, camera start). These should be in QuestGiver as a default selection handler with callbacks for greet sequences and dialog build. qAradion.j:542-587

Generic quest creation boilerplate
CreateQuests is almost entirely data setup; better as a QuestGiver “create from defs” helper (list of quest defs with id/title/icon/desc/reqs/etc). qAradion.j:590-643
Generic init/wait-for-udg flow

InitDelayed + Init are likely identical across quest givers; move to QuestGiver with a registration function that takes unit refs and a config struct. qAradion.j:645-669

What qAradion should keep (content/inputs only)
Quest definitions (ids, titles, icons, descriptions, requirements).
Text lines and sound ids for greet/backstory/accept/complete.
Custom gating flags like AradionBackstorySeen, RangerMissingReq1Complete, Valeria in range.
A small number of callbacks that supply “custom lines” into generic sequence builders.

Suggested QuestGiver abstractions
QuestGiver_HandleSequenceEnd(giver, cooldownTimer, cooldownSeconds, stopCamera, reopenDialog)
QuestGiver_PlayAcceptSequence(giver, heroOptions, onEnd, customLinesFn)
QuestGiver_PlayFarewellSequence(giver, heroOptions, onEnd)
QuestGiver_BuildDialogFromRules(giver, dialog, rules[])
QuestGiver_ShowDialog(giver, dialog, cameraConfig, greetFn)
QuestGiver_OnSelectedDefault(config) (handles selection gate, first greet, normal greet)
QuestGiver_CreateQuestsFromDefs(giver, defs[])
If you want, I can start by extracting the generic helpers into QuestGiver and refactor qAradion to only pass in definitions and custom lines.
>>>


=================================================================================================================================================
10.2.2026 - List of Actions:

DialogSystem
- Added full dialogue creation with sequence order etc. stuff - huge update
- added generic Greet, Farewell, Exit, Follow, Stop, etc. lines usage

DialogSystemNazgrek
- defined generic Nazgrek lines

QuestMaster
- some updates

QuestGiver
- some update

qAradion (sublibrary)
- editing to get the sublibrary as easy as possible to re-use for other qGivers

TODO

- Nazgrek (or Zulkis) play relevant generic lines to be added function calls to relevant places
- in cinematic,
- .... and more

(DONE - to be checked)
- DialogSystem
>>> - also play their action lines (like DialogSystem\_PlayAccept) for other buttons, Trade line are played when button "Trade" is pressed, Exit line is played when "Exit" button is played, Follow line are played when "Follow button is pressed, Stop line is played when "Stop" button is pressed, Decline is played when "Decline" button is pressed, Accept is played when quest accept button is pressed (e.g. Ranger Missing (Accept)), quest accept button always follows then qGiver built sequence for that quest accept 


=================================================================================================================================================
9.2.2026 - List of Actions:

QuestMaster
 - Added core quest-giver registry + availability evaluation to QuestMaster so all logic stays centralized, and exposed public APIs QuestGiver can call. Main changes are in QuestMaster.j (giver list storage, evaluation timer, requirement checks, event flags, and public register/query helpers).
- NOTE: Rewards missing
- NOTE 2: Icon not present

DialogSystem
- First version;
- lightweight dialog creation + button routing for quest givers.

QuestGiver
- Note: Dialogs not done / sublibrary

HeroItemCheck.j (DInv related helper functions)
- Wrapped in library

qAradion
- created first questGiver sublibrary
>>> need to analyze how well this sublibrary style can be "copy-pasted" for other questGivers - it looks very manual >>> re-occurring things should be easy to use or perhaps set in QuestGivers.j

======= key notes for qAradion.j
 	Built the qAradion quest giver library with quest creation, dialog gating, and button actions that mirror the OLDGUI logic, using QuestMaster/QuestGiver/DialogSystem and a selection 	trigger with cooldown. All logic lives in qAradion.j.

 	Key notes:

 	Item IDs are placeholders (ITEM_MANA_CRYSTAL, ITEM_WRAITH_ESSENCE, ITEM_TELANOR_ROD are set to 'I000').
 	Dialog/cinematic narrative lines from OLDGUI are not ported yet; only the structural flow and quest actions are in place.
 	Two public helpers exist for external progression signals: qAradion_SetBackstorySeen and qAradion_SetRangerMissingReq1Complete.
 	If you want me to continue, I can:
=================================

Note about Weather, ZonesCore, ZoneEvent;
- WeatherSystemv3_maybeWorkingVersion - is the current version (older version that worked, lol... some breaking stuff in new under "construction"

=================================================================================================================================================
7.2.2026 - List of Actions:
Terraining
- Stormhaven;
>>> Continue area construction
>>> Need some stairs to the walls...
- Havenwoods;
>>> Small terraining; e.g., destroyed human barracks near the human camp - this can be used either/and/or to quests helping humans discover who destroyed their barracks or as background that orcs OR ogres destroyed the barracks, ....

Quest Systems; QuestMaster.j
- Some development steps forwards slowly
- Here is some what has been done this day;
Added quest fields (requirements, faction/rep, failure text, reward item), reward text building, reward payout, and message helpers.
Added QuestMaster-owned icon logic (overhead effects + minimap pings) modeled after QuestIconSystem.
Added API functions for discover/fail/turn-in, requirement management, update/fail messages, templates, and TableV6-based save/load stubs.

Potential follow-ups:
>>> AddReputation and AddReputationLinked to be optional, add guards or hooks?
>>> different reward distribution targets (companions/group)?
>>> wire icon priority to per-giver lists and tighten quest log formatting (including requirement headings) to mirror OLDGUI output more closely?




=================================================================================================================================================
7.2.2026 - List of Actions:

Terraining
- Stormhaven;
>>> made the area large by removing waterside section
>>> could also remove the pathway from Redwind Pass to make the city or atleast the village area "larger"

Breaking changes incoming; Quests Systems huge overhaul
- Started creating new quest systems purely JASS based instead of current GUI triggers / JASS combinations
- This will reduce the amount of triggers by huge amount
- More detailed stuff is written to Requirements.md in Visual Code project folder




=================================================================================================================================================
4.2.2026 - List of Actions:

WeatherSystem
- refactored Stop weather related functions (confusing redundant functions)
>>> The stop logic has been refactored: StopRegionWeatherInternal now only stops weather for a single region, with all zone-wide stopping handled by StopZoneWeatherInternal. This prevents recursive start/stop conflicts and clarifies the API. Now can safely call StopZoneWeatherInternal(zoneIndex) to stop all weather in a zone, and StopRegionWeatherInternal(regionIndex) for single regions (if needed).
- root cause of multiple issues; RegisterAllZoneRects
>>> WeatherSystem expects to operate on its own RegionRect array, but the authoritative source of rects is ZonesCore.
>> If ZonesCore and WeatherSystem create rects separately, their handles will not match, causing failures in FindRegionIndex and incomplete weather stopping.
- Note: still issues with system and there are multiple coding practice failures / copy-paste from older systems / globals define twice etc
- Note 2!: revert to WeatherSystemv3_mayWorkingVersion.j




=================================================================================================================================================
1.2.2026 - List of Actions:

WeatherSystem
- index/registering debugging
- Now correctly sets the weather of zone to "none" when weather stops for that zone


ZonesCore
- Added API method to get list of registered weather and snow rects

Stormhaven terraining started
- issues; area too small



=================================================================================================================================================
24.1.2026 - List of Actions:

WeatherSystem
- Updated Storm/Thunder logic that was not sending random integer Variant properly
- added 50 % chance per timer interval to cause storm effect (might have to lower the chance)
- thunder/storm timer call back every 10s
- Snow should now spawn gradually in waves (waves and the amount spawned per waves defined in the constants further modified by the size of snowRects)

Storm
- back to using the original library with some modifications
- the other modified library was shittified
- trying get dynamic fog internal Storm functionality working but problem was that it alters the current weather fog and cant somehow restore it back to normal

FogSystem
- updated timer variable name...

ZonesCore
- added set method: SetWeatherState
- added get method: GetWeatherState
>>> Used to set weather state for checking the current weather by other systems

ZoneEvent
- modified ApplyFog (to use getWeatherState)
- modified ApplyCurrentZoneEffects

SnowSystem
- multiple changes / fixes to gradual destroy of snow
- now instead of destroying snow from last index to first, the snow is destroyed randomly and random amount of units depending on snow_light / snow_medium / snow_heavy

Testing related:
- import ubersplats file ZonesTest map OK
- import snow unit to ZonesTest map OK
- Import Ubersplat triggers OK
- Import frostbite (optionally)

TEMP: List of libraries to be updated to main map
subject to re-update!
- Storm 	OK
- FogSystem 	OK
- WeatherSystem OK
- zonesCore 	OK
- ZoneEvent  OK
- Snow	OK

============= ISSUES
ApplyCurrentZoneEffects / ApplyFog
- does not change the fog...
- ApplyCurrentZoneEffects return weather Heavy - while the weather should be already none
-something wrong getting the ZoneData / or retrieving the zone weatherState?
WeatherSystem: incorrectly sets the weatherState or something because it gets stuck in this mode / OR ApplyFog in ZoneEvent has some faulty logic
- incorrect indexing / ID wrong usage?
>>>>>> MOST CRITICAL ISSUE THAT MOST LIKELY BUGS OTHER ZONES AS WELL!

WeatherSystem
- despite StopZoneWeatherInternal
call z.SetWeatherState(WEATHER_NONE)
- it doesn't set the weather to "none" and ApplyFog applies the previously set WeatherState (heavy fog) after Storm


=================================================================================================================================================
23.1.2026 - List of Actions:

Terraining
- Verdant Plains
- Thornwoods
- Emberpeak Highlands

Imported new models (credits Lord of Souls)
Ashland Plants\imp\AshGrass.mdx
Ashland Plants\imp\AshGrass1.mdx
Ashland Plants\imp\AshYam.mdx
Ashland Plants\imp\FireFern1.mdx
Ashland Plants\imp\FireFern2.mdx
Ashland Plants\imp\Trama_Tree2.mdx
Ashland Plants\imp\Trama_Tree3.mdx
Ashland Plants\imp\Trama_Tree4.mdx
Ashland Plants\imp\TramaRoot1.mdx
Ashland Plants\imp\TramaRoot2.mdx
Ashland Plants\imp\TramaShrub.mdx
Ashland Plants\imp\TramaTree1.mdx



=================================================================================================================================================
22.1.2026 - List of Actions:

Working with these:
- ZonesCore
>>> Weather: Define weather/snow regions and chances under construction, ready zones:
>>>>> Twilight Grove
>>>>> Sereneglade
>>> Fog: adjust by testing good fog values for each zone (fogDay, fogNight, weather fogs; fogLight, fogMedium, fogHeavy)
- ZoneEvent (renamed from Zonesv2)
- WeatherSystemv3
- Storm (Storm still has issue - cant figure out how to restore from "black fog" DNC taken over)
>>> tried to add calls to  "call ZoneEvent\_ApplyCurrentZoneEffects()" and use DNC\_Storm - no results
- DNC


=================================================================================================================================================
20.1.2026 - List of Actions:

Breaking changes in short;
- ZonesCore (master library containg all zone data) - maybe rename to Zones
- Zonesv2 - handles now zone events but not configuration for zones - Maybe rename to ZoneEvent
- WeatherSystemv2 - refactored to use ZonesCore
==> All data is fetched from ZonesCore!

=================================================================================================================================================
19.1.2026 - List of Actions:

Zones
- DayNighEvent runs "Zones_ApplyCurrentZoneEffects" -function after 1s timer (vs. 0.5s) DNE_IsDaytime Boolean didn't update correctly with faster timer
>>> Note that the underlying issue is with DNE DayNightEvent events not always firing Day or Night especially when using cheat code to toggle DayNightEvent
>>> Now zone correctly applies night related settings (fogNight) when DayNightEvent occurs

DayNightEvent
- added timer to evaluate DNE_IsDaytime Boolean (if skips etc. occur) triggered by DayNightEvent

WeatherSystem
- now calls "Zones_ApplyCurrentZoneEffects()" from Zones library mainly to change the Fog effect to match with the weather
- Note: WeatherSystem cant call it "undeclared function" even though Zones library is above WeatherSystem and Zones requires WeatherSystem

WeatherShared -library created but unused
- WeatherSystem.j (to be set to require it)
- Zones.j (to be set to require it)
- Storm.j (to be set to require it)


=================================================================================================================================================
18.1.2026 - List of Actions:


FCL / FixedCameraLock
- function FCL_Lock: changed Y value of SetCameraTargetController from "200" back to "200"

FogSystem
- Refactored new library "FogSystem" from The_Flood (Flood @ hiveworkshop) system

Zones
- Added Debug message to display the fog values of the entered zone
>>> To be used to debug application of fog / FogSystem
- DNE_DayNightEvent's global variable udg_DNE_Daytime used to track whether it is day or night (previously was not correctly checked)
- Now should correctly work to apply different effects whether day or night


=================================================================================================================================================
17.1.2026 - List of Actions:

Zones
- Added icon paths in library to various zones

Imports
- various zone icons with path "zones\zone_xxx.blp"
- "Fish" by MiniMage (Fesh_Final.mdx)
- Sonya by Razorclaw_X / Blizzard Entertainment (Sonya.mdx)
- Gnoll Camp Doodads pack (or part of them) by RatzRatzzz:
10gl_gnoll_bag01.mdx
10gl_gnoll_bag02.mdx
10gl_gnoll_banner01.mdx
10gl_gnoll_barrel_large01.mdx
10gl_gnoll_barrel_large01_open01.mdx
10gl_gnoll_barrel01.mdx
10gl_gnoll_bed01.mdx
10gl_gnoll_bench01.mdx
10gl_gnoll_cage01.mdx
10gl_gnoll_cage02.mdx
10gl_gnoll_cage03.mdx
10gl_gnoll_cage04.mdx
10gl_gnoll_campfire02_off.mdx
10gl_gnoll_chair01.mdx
10gl_gnoll_crate02.mdx
10gl_gnoll_hangingtrinket02.mdx
10gl_gnoll_hangingtrinket03.mdx
10gl_gnoll_rope03.mdx
10gl_gnoll_ropecoil01.mdx
10gl_gnoll_ropecoil02.mdx
10gl_gnoll_spikes01.mdx
10gl_gnoll_spit01_boarroast01.mdx
10gl_gnoll_table01.mdx
10gl_gnoll_tent01.mdx
DoodadWeaponRackGnoll.mdx

Terraining;
- Havenwoods; Slight terraining at old forest troll area
- Thornwoods / Sereneglade gnoll camps terraining

Fixed model(s):
world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo (caused lag - huge box / extends)


=================================================================================================================================================
15.1.2026 - List of Actions:

UnitExperience
- Show pet lvl up using RegionTitlesLight (function ShowSingleLineText)

Hero Dies (Nazgrek or Zulkis)
- Show message using RegionTitlesLight (function ShowSingleLineText)

Engineer Dies
- As test; Show message using RegionTitlesLight (function ShowSingleLineText)

Storm (drafting)
- To checks whats the player's current zone - if the zone doesn't match - then Storm effect are not applied - NOT WORKING CHECK
- Note: Need to think careful what system handles what - i.e., does Storm give information of storm ended in zone and then the other system handles applying normal zone settings

SpeciFX library
- Added two functions to make easier to create special effect on location (if called e.g., from GUI trigger) vs. strict point X and Y values
>>> SpeciFX\_AddToLocation
>>> SpeciFX\_AddToLocationEx

CastingBarSystem
- Tried to resolve issues with some abilities not working correctly (channel vs cast ability?)
>>> Created into new file "CastingBarSystem\_testing2025-01-15.j" if to be used
>>> Note: didn't work properly for normal abilities like "Firebolt" but channeled abilities worked (maybe just not calling Bar text creation function etc.?

Havenwoods
- Slight terraining at old forest troll area


=================================================================================================================================================
13.1.2026 - List of Actions:

DynamicMinimap
- Working on the library to fix XY drift; Results: Several version test - always something is out-of-place non-working
- Best to use DynamicMinimap_LastWorking.j at this point / as starting point to fix the system
>>> DynamicMinimap\_LatestBuggy.j have some good better globals usage etc. but its buggy - the unit jumps between the chunks (like in previous older versions)
>>>>> It can update the camera bounds but not the minimap chunk etc. buggyness

DynamicMinimap_lastWorking
- Added sounds for minimap enlarge (minimap open) and minimap normal (minimap close)
- Note: when working with other version of DynamicMinimap - remember to transfer these related changes to the library

RegionTitlesLight
- Now has two text frames; one to be used mainly for Zone "Entered" or "Discovered" message and the other text frame for the zone name
- Note: This system current implementation is mainly for Zones.j, but it should maybe be more modular and usable for other text displaying
- Added function; ShowSingleLineText takes string text, real fadeIn, real duration, real fadeOut, real scale

Zones
- Updated RegionTitles usage for enter/discover zone/dungeon
- Added sounds for zone/dungeon enter/discover
- DayNight_UpdateZone; now uses "Zones_ApplyCurrentZoneEffects() instead of HandleZoneEnter
- updated Zone texts
- added new field for common entities, notable characters, environment type
- added "z.isDungeon" Boolean - used basically for different sounds enter/discover - more use cases could be

TasQuestBox_PotS
- change color of button
- "Zones" button as variable
- added functions to hide/unhide with;
call TasQuestBox_Hide()
call TasQuestBox_Unhide()

ON Cinematic -trigger
- added call to hide TasQuestBox
OFF Cinematic -trigger
- added call to unhide TasQuestBox

FCL / FixedCameraLock
- function FCL_Lock: changed Y value of SetCameraTargetController from "0" to "200"

Clouds
- GetLocZ disabled
- use fixed Z 2200.0 (previously 200.0 which meant the clouds clipping through various stuff like terrain)

Hero Levelup trigger
- Uses now RegionTitlesLight's ShowSingleLineText function to display Hero levelup with frame text native

=================================================================================================================================================
12.1.2026 - List of Actions:

Zones
- Issue with the system not working upon unit entering zone region but working manually was found at ExMusic using Wait 2s
- Updated dayNightEvent functions to not use Waits

ExMusic
- Previously used wait in fuction PlayTrack when changing the track, this causes unpredictable issues when using Events etc.
- The wait function replaced with timers
- Purpose was to reduce when music track changes - so the old track has time to die before new is played
- Update:
>>> Fade-completion handler added
>>> Refactored ExMusic\_PlayTrack
>>> Instant cut option
>>> Some description updates etc.
- Updated to main map

DynamicMinimap
- added these in globals;
local real MAP_WIDTH  = MAP_WORLD_MAX_X - MAP_WORLD_MIN_X
local real MAP_HEIGHT = MAP_WORLD_MAX_Y - MAP_WORLD_MIN_Y

In UpdateMinimapAndBounds;
- replaced this...;
set centerX = MAP_WORLD_MIN_X + (I2R(chunkCoordX) * scaleFactor * 128.0) + (actualChunkSizeInMapTiles * 128.0 / 2.0)
set centerY = MAP_WORLD_MIN_Y + (I2R(chunkCoordY) * scaleFactor * 128.0) + (actualChunkSizeInMapTiles * 128.0 / 2.0)
... with;
// Normalize chunk position (0..1)
local real nx = I2R(chunkCoordX) / I2R(CHUNK_COORDINATE_SYSTEM)
local real ny = I2R(chunkCoordY) / I2R(CHUNK_COORDINATE_SYSTEM)

// Chunk size in world units
local real chunkWorldSize = actualChunkSizeInMapTiles * 128.0

// World-space center
set centerX = MAP_WORLD_MIN_X + nx * MAP_WIDTH  + chunkWorldSize * 0.5
set centerY = MAP_WORLD_MIN_Y + ny * MAP_HEIGHT + chunkWorldSize * 0.5

In PeriodicUpdate;
- added;
// Clamp to valid range in map tile coordinates to prevent edge drift when camera is nudged against bounds.
    if unitTileY < 0 then
        set unitTileY = 0
    elseif unitTileY > MAP_SIZE_TILES - 1 then
        set unitTileY = MAP_SIZE_TILES - 1
    endif
 

=================================================================================================================================================
11.1.2026 - List of Actions:

Zones -library
- Some modifications, e.g., to use DNC library
- texts modified

DNC -library
- created
- some triggers to use call DNC_XXX instead of old triggers that were used

RegionTitles
- some modifications, NOTE: cant get custom TOC to work properly....

Notes on this day:
- Zones, Weather, Storm all have many things that need to worked on...
Known issues:
- Storm: Storm not properly working for: Checking current zone + Re-applying current zone DNC after the STORM
- Storm: Storm system used old udg_ZoneCurrent stuff that needs heavy modification for Zone system
- WeatherSystem not fully tested; Ambient sounds may not work as intended
- Zones; Ambient sounds may not work as intended
- Zones; missing enter/discover sounds
- Zones; missing zone specific enter/discover sounds
- Zones; some old GUI variables weirdly transformed over to system by AI (some may not be fully used or used wrongly)
- Zones/Weather System; Linking: weather.j to use region/other data straight from Zones.j to limit multiple config areas (e.g. regions of the zones)
- TasQuestBox needs to be hidden when InCinematic / CInematic ON and re-enabled when over
- Zones; Icons for TasQuestBox to be added per zone -> All zones have similar texture and dungeons own / unique or ALL zones have unique texture paths?
- RegionTitles; FDF and TOC files not imported to main map! Note: also they didn't seem to modify text at all from native blizzard text???

- All new systems updated to main map (with notes / known issues in mind...)


=================================================================================================================================================
10.1.2026 - List of Actions:

Zones -library (testing version)
- Zones_EnterZone will now also enable the zone by calling "Zones_EnableZone", because otherwise the zone handle will not work
- Zones_EnterDungeon will now also enable the zone by calling "Zones_EnableDungeon", because otherwise the zone handle will not work
- Added Table utilization for zone ID - simple integer array would also do the trick
- dungeon IDs changed to unique (were previously using already used ids)
- Note: many stupid coding practices leftover from AI... - could be simplified...
- Started utilizing Tasyen TasQuestBox for Zones descriptions
- Started utilizing RegionTitles by Antares for Zones titles




=================================================================================================================================================
8.1.2026 - List of Actions:

- Issue: camerabounds / units positioning on map is not almost exact vs. how they are positioned in the real word - see older "known" working system have different ways to handle? - each time chunk minimap is updated - units go slightly wrong position relativily
>>> Fix: Hardcoded symmetric bounds (leftover from testing) changed to use GetRectMinX / Y (bj\_mapInitialPlayableArea)'
- Issue: Minimap toggle M (enlarge / normal) sometimes only the background frame is visible but minimap is invisible - togglin on/off/on might bring the minimap visible
>>> Fix: Always set minimap visibility explicitly during toggle, Re-assert frame levels after toggling
- added ESC key detection to reset chatWindowOpen state
- Remove GetLocalPlayer() check for border operations (unnecessary)

Zones -library
- Transform the current GUI triggers into more flexible JASS library
- Note: not all zones in GUI triggers where finished - these were not copied
- Not yet implemented into main map - as there are some unfinished things in the library
->>> many Todos - see MS To-do list
- Fog Intensity by Weather Type; ApplyWeatherFog() function to adjust fog based on weather intensity:
>>> Heavy fog: rain\_heavy, snow\_heavy, storm (uses full fog settings)
>>> Medium fog: rain\_medium, snow\_medium (fog pushed 30-50% further back)
>>> Light fog: rain\_light, snow\_light, wind, other types (fog pushed 60-100% further back)


WeatherSystem
- Storm Zone-Specific Triggering; Storm effects (lightning/thunder) now only trigger visually and audibly for players whose selected unit is in the storm's zone
- Storm DNC Trigger Timing; The zone's DNC trigger (udg_ZoneTrigger[udg_ZoneCurrent]) is now called AFTER storm effects fully complete, not during
- Storm Always Has Rain; Storm weather now ALWAYS includes rain companion weather:
>>> 70% chance: rain\_heavy with storm
>>> 30% chance: rain\_medium with storm
- Increased Snow in Specified Zones; Updated snow chances and enabled snow spawning in these zones:
>>> TwilightGrove (Zone 1): Added snow (55% chance), enabled spawning
>>> Serenaglade (Zone 2): Increased from 75% to 85%, enabled spawning in main region
>>> Thornwoods (Zone 6): Added snow (45% chance), enabled spawning
>>> Havenwoods (Zone 7): Added snow (60% chance), enabled spawning
---- All zones also have steam breath effects enabled for cold weather atmosphere.

=================================================================================================================================================
7.1.2026 - List of Actions:

DynamicMinimap
- Adjusted after intensive testing (crash causer troubleshooting) version

DynamicMinimapTesting
- Made simplified testing library to see if crashes still occur without frame natives (BlzChangeMinimapTerrainTex kinda is still though)
- only functions; chunked view, full view - no enlarge function for map
- Temporarily changed DynamicMinimap and related calls (in Cinematic ON and Cinematic OFF) in main map to refer to DynamicMinimapTesting library
- RESULT: Still crash - verify that indeed testing version was used
>>> This should help troubleshooting
- The main suspects:
>>> originalCameraBounds might be invalid - GetEntireMapRect() might not be safe
>>> Calling SetCameraBoundsToRect during/after cinematic - Camera state might be locked or in transition
>>> No validation before SetCameraBoundsToRect - Should check if rect is valid
Key changes made to fix the crash:
1. Using bj_mapInitialPlayableArea directly instead of GetEntireMapRect() - this is more reliable
2. Added rect validation - Checks that the rect is non-null and not degenerate before calling SetCameraBoundsToRect
3. Changed order of operations - Applies texture BEFORE changing camera bounds to avoid conflicts
4. Added safety checks - Validates rect dimensions (maxX > minX, maxY > minY)
5. PeriodicUpdate calling:
>>> Only the timer calls PeriodicUpdate()
>>> No race conditions between manual and timer-based calls
>>> No rapid successive BlzChangeMinimapTerrainTex() or SetCameraBoundsToRect() calls
>>> At most 0.1 second delay before chunk updates, which is imperceptible

=========> Results after all these changes:
- No crash at least immediately after intro cinematic over
- for some reason camera is not tracked to Nazgrek / Nazgrek not selected?
- then when minimap (chunked version) updates to new chunks (couple of updates) -> units disappear from map => Meaning camerabounds are getting messed up -> Crash (out of bounds?)
- intensive use of "get bj_mapInitialPlayableArea" leading crash causer (does not show stress in testing map because not full of stuff)
- issue found:
>>> Using SetCameraField(CAMERA\_FIELD\_ROTATION) with some values and together calling SetCameraBounds will crash the game
>>> source: https://www.hiveworkshop.com/threads/setcamerabounds-camera-rotation-bug.319374/
>>> Now with Camera rotation safe checks DynamicMinimapTesting.j does not cause crash to map
>>> Have to adjust the full version

WeatherSystem
- Clouds now use GetLocationZ() to spawn at terrain height + 200 offset, so they appear higher on mountains and lower in valleys
- larger regions automatically get more clouds (up to 20 per region).
- Clouds now only spawn for: rain_medium, rain_heavy, snow_medium, snow_heavy
- No clouds for: rain_light, snow_light, storm, or wind
- Added 3 new functions:
>>> IsWeatherActive(pattern) - Check if weather exists anywhere (supports "rain\_any", "snow", zone names like "Sirensong")
>>> GetWeatherInZone(zoneName, pattern) - Get specific zone's weather with pattern matching
>>> CountZonesWithWeather(pattern) - Count zones with matching weather
- Snow Duration Varies by Intensity
>>> snow\_light: 30-120 seconds (much shorter)
>>> snow\_medium: 90-240 seconds
>>> snow\_heavy: 120-300 seconds (longest)
- Snow Waves/Units Vary by Intensity
>>> snow\_light: 3 waves, 30 units/wave (~90 total)
>>> snow\_medium: 6 waves, 60 units/wave (~360 total)
>>> snow\_heavy: 8 waves, 90 units/wave (~720 total)

- Added MasterZoneID[] array to track zone IDs
- Updated ZoneThunderCallback() to use zone-specific storm calls
- Added WeatherSystem_SetZoneID() function
- Configured all 28 zones with their udg_ZoneCurrent values (1, 2, 3, 4, 6, 601, 602, 7-20, 1401-1404, 1701-1704, 1901)

Storm
- Zone-Based Effect Visibility
Storm effects (lightning, thunder, fog) now only visible to players whose selected unit is in the storm's zone
Uses udg_ZoneCurrent to check player's current zone
Zone ID 0 = global (backward compatible)
- DNC Restoration
Stores fog settings before storm starts
After last storm ends, restores fog and executes udg_ZoneTrigger[udg_ZoneCurrent] to restore zone-specific day/night cycle

Terraning
- Deadwoods
- Verdant Plains

Zones:
- added call check to WeatherSystem_GetZoneWeather("ZoneName") to change the fog if any weather is active for that zone
- Note 1: mentioned call is added only to majority of zone triggers but not all - also could be implemented better...
- Note 2: maybe could also use ZoneTrigger[ZoneCurrent] run from WeatherSystem?

=================================================================================================================================================
6.1.2026 - List of Actions:

DynamicMinimap
- Trying to solve crashing issues appearing only in the main PotS map that do not occur in the light-weight testing map...
- added border frame to minimap
>>> Note: Because minimap is part of GameUI - we cant (or I cant) set the border to be between gameUI frames and minimap frames - various tests and always resulting minimap being under the minimapborder frame
>>> Temporarily checking with custom background / positioning / etc. that is more than just border and more background-like
- TestingMap: no crashes
- MainMap: random crash after intro cinematic and starting moving (no using of enlarge map/full map
>>> Could be multiple causes; here some listed:
>>>>> GetRectMinX(bj\_mapInitialPlayableArea) could cause crash in main map
>>>>> ChatBox checking
>>>>> PeriodicUpdate interval too high 0.1s? > Result: even faster crash when using higher value 1.0s
>>>>> Incorrect use of frame natives
>>>>> Null pointer etc.
>>>>> Here could be found some help: https://www.hiveworkshop.com/pastebin/e23909d8468ff4942ccea268fbbcafd1.20598
>>> Temporarily disabled DynamicMinimap and related calls (in Cinematic ON and Cinematic OFF) from main map
>>> The reason for crashing needs to be solved

Temporarily disabled all WeatherSystem related (to check whether Game crash is because of this or DynamicMap)

Terraining
- Deadwoods
- Vanguard Vale / Elf Remnants small village / etc.
- Verdant Plains


=================================================================================================================================================
5.1.2026 - List of Actions:

DynamicMinimap
- Trying solve camera bounds / unit position on real map grid vs. position on minimap, ....
- added chat commands to change modes/help/info etc.
- show commands with " -minimap help "
- Camera bounds / minimap misalignment was caused by BOUNDS_PADDING_MULTIPLIER = set to 2.0
>>> This makes the camera bounds twice the size of the minimap chunk, which breaks the alignment between what the player sees and what's on the minimap.
>>> changed BOUNDS\_PADDING\_MULTIPLIER = 1.0
>>> Stable working version: Jan 6, 2026 at 2:08 AM
- Note in the map enabling/disabling etc. different calls might need to be checked within triggers especially Cinematic ON and Cinematic OFF

Models imported (credits ScorpioT1000 XGM Guru)
D_L_BurningBoards.MDX
D_L_Campfire.MDX
D_L_AshenLamp1.MDX
D_L_DarnassusStreetLamp01.mdx
D_L_DarnassusWreckedStreetLamp02.mdx
D_L_DifficultTorch.mdx
D_L_DifficultTorchHanded.mdx
>> Replace vanilla torch with these torch models!
(old versio as item ability: war3campImported\TinyTorch1.mdx)

Models imported (credits XXX
Night Elf FencesWalls
- 8ne_pvp_warsongbg_nightelfwall01.mdx
- 8ne_pvp_warsongbg_nightelfwall02.mdx
- 8ne_pvp_warsongbg_nightelfwall03.mdx
>>> Vanguard Vale?
Vampire Stone Fences
- 9vm_vampire_rural_fence01_destroyed01.mdx
- 9vm_vampire_rural_fence02.mdx
- 9vm_vampire_rural_fence02_destroyed01.mdx
- 9vm_vampire_rural_fencepole01.mdx
>>> Crypt / Dawnhold?

=================================================================================================================================================
4.1.2026 - List of Actions:

SpeciFX
- Added Terrain Alignment API (by Antares) + GetLocZ function usage
- Added global variable udg_SpeciFXEffect (for temp usage)

WeatherSystem
- Added debug messages / mode
- Water Ripples spawning on rain
- Water Ripples should only be spawned on water
- The amount of Water Ripples depends on rain_light, rain_medium, rain_heavy

CloudsSystem
- Adjusted to only spawn on set region
- Adjusted the amount of clouds to be spawned - dynamically calculates the number of clouds based on region size (min 1 cloud per region, max 20 clouds)

CreepRespawn
- Again checking this: - Player 23 (Emerald) units will be changed to Neutral Passive at death event by this system

Minimap - named as " DynamicMinimap "
- New idea figured out - needs intensive testing / modification to maybe to minimap chunk .blp files etc.
- also the camera bounds thing might need adjusting etc.
- Implemented into main map
- Functions:
>>> HQ map in minimap adjusted to small camera bound section that updates when based on camera location
>>> Enlarge / Normalize map function - The map is brought to center of screen enlarged for better view


=================================================================================================================================================
3.1.2026 - List of Actions:

Minimap
- custom minimap development under construction (issues trying to scale / re-scale back to vanilla minimap...)
- Note: not implemented into main map! Only in test map

Neutral Mobs
- Added game debug message for when Neutral unit (turnt hostile) dies to check whether it changed to neutral passive

Lumberjack Duties
- Fixed bugs with FollowSystem related incorrect unit assignment

CreepRespawn library
- Added DEBUG_MODE constant (set to true) that controls all debug messages
- Fixed the exclusion list bug - All 7 unit types were using index [0], so only the last one was actually excluded. Now each uses indices 0-6, and EXCLUDED_COUNT is properly set to 7.
- Added debug messages showing:
>>> Unit ownership at death - Shows Player ID and HandleID
>>> Whether saved position data exists for the unit
>>> Why units are skipped (summoned, wrong owner, excluded type)
>>> When units will respawn and confirmation when they spawn
>>> Initialization details and respawn timer value
- Player 23 (Emerald) units will be changed to Neutral Passive at death event by this system

WeatherSystem
- First draft of the massive immersive weather system (combined logic for controlling the weather with seasonal etc. settings)
- This system also affected / needed refactoring of following systems:
>>> SteamBreath
>>> SnowSystem
>>> CloudsSystem
- Listed libraries were previously just functions called from GUI triggers
- NOTE: This system will require intensive testing and also creation of subregions for each zones, also checking what weather settings for each zones, subzones, etc.

FrostbiteSystem
- Removed player 2 from affected units

=================================================================================================================================================
1.1.2026 - List of Actions:

SpeciFX
- New library for creation of special effects (handling inside library)
- Configurable effects, easily managed and destroyed
- Utilizes tag system to separate effects per unit or globally

FollowSystem
- All 5 effect creation points now call SpeciFX_MarkAsExcluded()

QuestIconSystem
- Quest icon effects now marked as excluded (SpeciFX)

Intro Cinematic
- Trying to fix why orc patrol does not move by unpausing them Intro Orc Setup -trigger
- Trying to fix Shadowclaw unmovement by unpausing it in Intro Orc Setup -trigger

Kodo quest (Mistaken Kin)
- Updated triggers to make Kodo as Horde (Player 6) owned when following to get neutral hostile attack it

CreepUnitAssignment
- Added Graknar, KodoGrak
- KodoGrak will have FollowSystem assigned if quest Mistaken Kin is active but not completed

Valeria
- fix respawn issue by changing ownership of Valeria back to Neutral Passive (if killed upon Ranger Missing Valeria Encounter situation)

ItemDropSystem with sub-libraries created (based of current GUI triggered version)
- First versions are strictly old version based JASS versions
- Trying to draft versions utilizing Briebe's TableV6
- NOTE! Not utilized in the map currently - the system has to be designed/planned well ahead before usage

Quest Lumberjack Duties
- Now uses the new FollowSystem for udg_LumberPeon


=================================================================================================================================================
Epic Quests 31.12.2025 - List of Actions:

Imports:
- LootEFFECT.mdx (by Geries from WoW)
>>> For Item drops?
>>> Added as ability (effect) for dropped items (IDEA, not implemented)
>>> Remove loot effect ability when picked up (IDEA, not implemented)
- QuestMarking.mdx (by stan0033)
>>> Used at least by Followystem NPCs

ItemHook (not transferred into map yet, just VS code level stuff)
- https://www.hiveworkshop.com/threads/itemhook-create-remove.318849/ - Based of this LUA version, JASS library was created
- see widgets etc that could be utilized for Item events; https://www.hiveworkshop.com/threads/event-item-dies-is-it-possible.294411/

Aradion - Ranger Missing
- Fixed: After ranger missing dialog Failed button pressed - it should not be able to pressed again

Quest Mistaken Kin
- Adjusted Kodo follow range
- Salamanders will now attack the player when reaching Kodo
- Adjusted texts
- Adjuste Kodo end positioning triggers

Chimairo
- Trying fixing Corrosive Venom ability dummy casting
- try "debug chimairo2" to get TesterGuy unit


=================================================================================================================================================
Epic Quests 30.12.2025 - List of Actions:

CinematicMover
- trying fixing: moving revived unit to off-map before killing - does not work?
- trying fixing: unit is not re-killed after cinematic is over (when was dead before cinematicmover) - but revive timer seemed to continue (not visible in multiboard, because alive by CInematicMover system)

FollowSystem
- created first version
- makes units follow target units with (annoying :D) RPG style
- see jass library for documentation / how to use
- make escort related quests utilize the FollowSystem

Valeria
- Ranger Missing quest failed additions

DInv - DItemTransfer
- DItemTransfer addon created to transfer items and equipment between units
- main reason: Resetting abilities aka replacing old unit with new unit, Ghost wolf ability usage, special cases,...

=================================================================================================================================================
Epic Quests 29.12.2025 - List of Actions:

CastingBarSystem
- Reworked the system / made some fixes and adjustments
- Additional configuration options made
- dynamic visibility check and owner tracking

CinematicMover
- Clean death animation: Revived units are now moved to off-map corner coordinates (-15000, -15000) before being killed, so the death animation won't be visible to players. Added a 0.05s delay to ensure position update completes.
- Revive timer preservation: The system already had StoreAndPauseReviveTimer() and ResumeReviveTimer() functions. I ensured they're called correctly:
>>> When reviving during cinematic: Stores remaining timer value and pauses it
>>> When returning to dead state: Resumes timer with the stored remaining time (continues from where it left off, doesn't restart)

CreepUnitAssignment / QuestEvaluationSystem / QuestIconSystem
- Trying to make quest repop again when unit respawns...

HealEngine
- added FIRE_REGEN_EVENT constant set to false which prevents regeneration from triggering the AfterHealEvent. Self-regeneration will no longer fire the event that displays floating heal text

Chimairo
- Corrosive Venom damage engine related triggering work (needs testing)

=================================================================================================================================================
Epic Quests 28.12.2025 - List of Actions:

Lag Resolve (maybe?):
- causer: world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo --> When deleted - lag is gone
- testing to set shadows for all the related crypt wmo doodads to "false"
- Note: in-game check >>> Still lag!!!

UnitExperience
- debug messages now only shown if private debugmode enabled

CreepUnitAssignment / QuestEvaluationSystem / QuestIconSystem
- When a quest giver unit respawns, this system automatically triggers quest re-evaluation, QuestEvaluationSystem will restore any pre-configured quests (states 1 & 2)
>>> QuestEvaluationSystem: Added QuestEval\_ForceUpdateForNPC(unit npc) and QuestIcon\_RestoreQuestData(u) - Forces immediate quest evaluation for a specific NPC
>>> CreepUnitAssignment: Added TriggerQuestEvaluation(unit u) helper function with small delay
>>> QuestIconSystem: BACKUP QUEST DATA (for respawn) - Stores active quest data by unit-type ID so it can be restored on respawn
- Active quests (states 3 & 5) must be managed by quest triggers separately

Terraining
- Crypt (e.g., pathing blockers)

Batrider (Zul'kis)
- model changed -> not looking that great, but utilized

Vanguard Vale
- Sky changed to DNC Outdoor version that most other zones use

Valeria
- Added Rapid Fire ability (berserk based)
- Added Fan of Knives ability
- Added Aimed Shot ability
- When as "companion" - will not be removed from companion group upon death and will use Player's selected Graveyard

Hero / Companion revival
- Added ping map for companion heroes when revived to indicate their revival location
- fixed leak in player hero ping map upon revival

Chimairo
- Venomous Breath; updated missiles and their speed
- Trigger updated: Init Boss Units
- Created boss related triggers (Draft)
- Note: Need to update CreepUnitAssignment for BossChimairo -unit
- Added dummy Corrosive Venom unit / related trigger (Note: currently maybe works for all harmful abilities cast by Chimairo on DamageEventTarget - needs to be somehow checked what the ability was (i.e., Venomous Breath hitting unit)

Multiboard - Companions / Stats
- Fixed issue of not correctly updating all companion rows

Aradion / Valeria / Ranger Missing quest
- Valeris initially invisible (ghost ability)
- Valeria is made visibile when Ranger missing quest is accepted
- Valeria can only be encounted when Ranger Missing quest is discovered
- Quest Failed activity added
- When talking to Aradion after failing quest, Elarindor will turn temporarily hostile to player
- Ranger Missing quest may be started again after Elarindor is atleast unfriendly / not temporarily hostile

CastingBarSystem
- New JASS system to replace old CastingBar
- This new system works for all abilities without manually needed to put ability codes etc. work
- has exclusion list which can be utilized for abilites not desired to show casting bar

Revive system
- added informational text about companion dying / revived

Companions - Hired units
- Fixed issue with trigger removing incorrectly previous multiboard row stored in the variable as the sold unit was never added to multiboard when group size is full

=================================================================================================================================================
Epic Quests 27.12.2025 - List of Actions:

Models (from WoW)
- unshaded models modified into shaded models:
>>> dark-ranger
>>> duskwither-apperentice
>>> nazgrek
>>> elf-sorcerer

Imported models:
- Chimera.mdx     (CREDITS: ZugothNDeadly)
- BatRider.mdx   (CREDITS: Zenonoth)
- Portals:      (CREDITS: Izhael_DC)
>>> Portal\_ArcaneBlue\_I.mdx
>>> Portal\_ArcaneBlue\_II.mdx
>>> Portal\_Bloody\_I.mdx
>>> Portal\_Bloody\_II.mdx
>>> Portal\_Divine\_I.mdx
>>> Portal\_Divine\_II.mdx
>>> Portal\_Fel\_I.mdx
>>> Portal\_Fel\_II.mdx

DNC:
- DNC DarkerPlace trigger now uses the later tested "dnc darkplace3c" as the DNC model
- No need to adjust other triggers etc.

QuestEvaluateSystem / QuestIconSystem
- QuestIconSystem Icon logic: // Unavailable (gray exclamation) - show overhead icon but NO minimap marker
- debug messages now only shown if private debugmode enabled

Item mysterious vanishing from DInv:
- Added condition "Made invisible - IsItemVisible() == FALSE" to check if picked item is hidden into triggers "Item Remove" and "Item Cleanup" in Item Systems Folder / Item Removing After Time / Item Cleamup
>>> UNADDED: Additional check could be used to check if the item is located in bottom-left corner of map:
>>> stored at (MapMinX, MapMinY) which is typically (0, 0) or negative coordinates


Boss Chimairo (Verdant Plaints)
- Model changed (CREDITS: ZugothNDeadly)
- Abilities and fight drafted;
>>> Ability 1: Caustic Fang - Draft
>>> Ability 2: Venomous Breath (Frontal AoE Cone) - Draft
>>> Ability 3: Acidic Rupture (Venom Spread / Anti-Clump) - Not started
>>> Ability 4: Sky Rend Charge (Fly-Charge) - Not started 
>>> Ability 5: Rending Talons (Cleave Strike) - Draft
>>> Ability 6: Predator’s Frenzy (Enrage / Phase Ability) - Not started

New dungeon portals:
- added ghost (visible) abilities
- removed some old portal doodads

UnitsStats
- debug messages now only shown if Boolean debugEnabled true

Lag Resolve (maybe?):
- Fog FX doodad at Crypt (old entrance) had "Shadows = Enabled" - this probably caused heavy GPU work
- In WE resolved, but in-game crypt old entrace area causes heavy GPU utilization and lag

Terraining:
- The Crypt
- Vanguard Vale / Verdant Plains human lumber mill area

=================================================================================================================================================
Epic Quests 24.12.2025 - List of Actions:

QuestEvaluateSystem
- Added API functions to get evaluate in GUI trigger the quest giver NPC quest state(s)
- Red Quest Exclamation mark should now be displayed on the unit if quest is not available (unavailable state)

DNC
- Added default dark DNC test with " dnc darkplacedef "
>>> Works only on small part of the map

- Added few more custom DNC tests;
dnc darkplace3e (Ambient 0.02)
>>> Works only on small part of the map

dnc darkplace3f (Directional 0.02)
>>> Works only on small part of the map

Terraining
- Sirensong

Crypt
- Entrance (Original) location has lag, its not all around - some model causing it?


=================================================================================================================================================
Epic Quests 12.12.2025 - List of Actions:

DNC testing by chaning ambient light node settings
- test with:
 dnc darkplace3b
 dnc darkplace3c
 dnc darkplace3d
RESULTS: No difference in models
IDEA: what about setting ambient light node 0.0?


Terraining
- Verdant Plains lite terraining > testing new doodads

=================================================================================================================================================
Epic Quests 7.12.2025 - List of Actions:

QuestEvaluateSystem
- Init run after intro cinematic (trigger "Intro Cinematic Cleanup"

Fixing ceiling/walls of the models from previous edit:
world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a2.wmo.mdx (1st part)
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4f.wmo.mdx (2nd part)
>>> for some reason bth model causes heavy lag of PC / map in WE
>>> Is this model related issue or PC CPU / RAM related (changes in RAM done lately)
>>> Also... northrend4a.wmo didn't have any ceiling so there never was wall/ceilings that are now missing, either removed earlier or intended

Other:
- onyxia lair as dragon dungeon (to be edited into parts)
DUNGEON: world_wmo_dungeon_kl_onyxiaslair_kl_onyxiaslair_a1.wmo.mdx
- textures missing (why)
DUNGEON: world_wmo_dungeon_kl_onyxiaslair_kl_onyxiaslair_b1.wmo.mdx
- textures missing (why)
SIGN: world_dungeon_goldmine_passivedoodads_caveminekobolds_cavekobolddangersign_red_01.mdx
TREE: world_expansion04_doodads_valleyoffourwinds_willowtree_vfw_riverwillow02.mdx

DNC, testing "" style with
call SetDayNightModels("","")

- use command " dnc darkstock " to test
- notice that call has "","". While you have used only "" within the call, DNC Model + unit need to be both?
Example: call SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl" , "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")

=================================================================================================================================================
Epic Quests 3.12.2025 - List of Actions:

world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx
- edited (missing texture / bad)
- saved and imported as world_wmo_dungeon_md_crypt_md_crypt_f_northrend2b.wmo.mdx
- re-placed the model at Crypt entrance location

world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo.mdx (1st part)
- saved as and imported world_wmo_dungeon_md_crypt_md_crypt_f_northrend4e.wmo.mdx (2nd part)
>>> might still need to change the XY position, because too far in XY grid? test
>>> still does disappearing with separated models, might because of some model settings e.g., related ceiling or the grid position
>>> cause found: extends had to be re-calculated + grid position of the model to 0,0
>>> re-placed models at crypt
NOTE: ...e2 and 4d models missing some parts (ceiling + some walls), that maybe got deleted when separating the models....

DNC testing
- added debug commands to test DNCs
>>> dnc darkerplace (what crypt uses currently)
- seems to work across the map more widely when used 2nd time - Colossal Arena not covered - but this happened at some gameplay only... ==> game engine related bug
>>> dnc darkplace
- brighter than "darkerplace", but works across the whole map
>>> dnc underground (same as dnc darkplace but with sky set to none)
>>> dnc7
- good, not broken, bright
>>> dnc9
- good, not broken, but not that dark

>>> dnc darkerplaceoffset
- very weird, unshaded units, and the placement seems to be more at EAST

Testing new DNC with offset model position:
X: 5000
Y: -29000
- model name: DNCAnimated2_Darker5_offset.mdx

=================================================================================================================================================
Epic Quests 30.11.2025 - List of Actions:

QuestEvaluationSystem:
1. Only show AVAILABLE quests (state 2)
Unavailable quests (requirements not met) are now removed completely - no red exclamation marks shown
Only when requirements ARE met does the quest icon appear (yellow/blue !)

2. State change tracking
Added SlotLastState array to remember what state each slot is in
Only calls QuestIcon_RegisterQuest or QuestIcon_RemoveQuest when state actually changes
Prevents unnecessary re-registration of the same quest state

3. Dynamic updates
When hero reaches level 10 and has neutral Horde rep, Grum's quest will automatically appear
When requirements stop being met, the quest icon is removed
System efficiently only updates when changes occur

How it works now:
Requirements NOT met → No quest icon (removed if it was showing)
Requirements met → Yellow/blue ! appears (only registered once until state changes)
Active quest exists → Dummy icon removed (real quest takes over)
Quest completes → Dummy icon reappears if requirements still met

Terraining:
- Sirensong; testing new rocks
- Serenaglade; testing new rocks
- Crypt; testing new wmo


Imported following models:

Crypt related (credits Blizzard):
Darkshire Entrace texture edit to not contain "darkshire
md_cryptsimpleent1.mdx
md_cryptsimpleent2.mdx
md_cryptsimpleent3.mdx
world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx
world_wmo_dungeon_md_crypt_md_crypt_f_northrend3.wmo.mdx
world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx

Rocks (Credits Blizzard submitted by Renn01):
Elsecaro_Large_Rock_04.mdx
Elsecaro_Large_Rock_05.mdx
Elsecaro_Large_Rock_06.mdx
Elsecaro_Large_Rock_07.mdx
Elsecaro_Medium_Rock_00.mdx
Elsecaro_Medium_Rock_01.mdx
Elsecaro_Medium_Rock_02.mdx
Elsecaro_Medium_Rock_03.mdx
Elsecaro_Medium_Rock_04.mdx
Elsecaro_Medium_Rock_05.mdx
Elsecaro_Medium_Rock_06.mdx
Elsecaro_Medium_Rock_07.mdx
Elsecaro_Medium_Rock_08.mdx
Elsecaro_Medium_Rock_09.mdx
Elsecaro_Medium_Rock_Group_00.mdx
Elsecaro_Medium_Rock_Group_01.mdx
Elsecaro_Medium_Rock_Group_02.mdx
Elsecaro_Medium_Rock_Group_03.mdx
Elsecaro_Medium_Rock_Group_04.mdx
Elsecaro_Medium_Rock_Group_05.mdx
Elsecaro_Medium_Rock_Group_06.mdx
Elsecaro_Medium_Rock_Group_07.mdx
Elsecaro_Rock_Ramp_00.mdx
Elsecaro_Rock_Ramp_01.mdx
Elsecaro_Small_Rock_00.mdx
Elsecaro_Small_Rock_01.mdx
Elsecaro_Small_Rock_02.mdx
Elsecaro_Small_Rock_03.mdx
Elsecaro_Small_Rock_04.mdx
Elsecaro_Small_Rock_05.mdx
Elsecaro_Small_Rock_Group_00.mdx
Elsecaro_Small_Rock_Group_01.mdx
Elsecaro_Small_Rock_Group_02.mdx
Elsecaro_Small_Rock_Group_03.mdx
Elsecaro_Large_Rock_00.mdx
Elsecaro_Large_Rock_01.mdx
Elsecaro_Large_Rock_02.mdx
Elsecaro_Large_Rock_03.mdx


=================================================================================================================================================
Epic Quests 16.11.2025 - List of Actions:

Imported many models from WoW (mainly Crypt-dungeon targeted, but other misc models as well:
CRYPT / UNDEAD
 	md_cryptsimpleent_part1.mdx
 	md_cryptsimpleent_part2.mdx
 	md_cryptsimpleent1.mdx
 	world_wmo_dungeon_md_cryptsimpleent_md_cryptsimpleent.wmo.mdx
 	world_azeroth_karazahn_activedoodads_karazahn_gatedoors.mdx
 	world_azeroth_karazahn_passivedoodads_rubble_karazahnrockrubble01.mdx
 	world_azeroth_karazahn_passivedoodads_rubble_karazahnrockrubble02.mdx
 	world_expansion02_doodads_generic_scourge_sc_platform2.mdx
 	world_expansion02_doodads_generic_scourge_sc_spirits_02.mdx
 	world_expansion02_doodads_generic_scourge_sc_spirits_03.mdx
 	world_expansion02_doodads_generic_scourge_sc_stairs2.mdx
 	world_generic_human_passive doodads_fire_undeadcampfire.mdx
 	world_generic_passivedoodads_deathskeletons_scourgefemaledeathskeleton.mdx
 	world_generic_passivedoodads_deathskeletons_scourgemaledeathskeleton.mdx
 	world_generic_undead_passive doodads_undeadalchemytable_undead_alchemy_table.mdx
 	world_generic_undead_passive doodads_undercityslimefalls_undercityslimefalls01.mdx
 	world_lordaeron_arathi_passivedoodads_impalingstonecorpses_impalingstone_corpse_01.mdx
 	world_lordaeron_arathi_passivedoodads_impalingstonecorpses_impalingstone_corpse_02.mdx
 	world_lordaeron_plagueland_passivedoodads_hangingscourge_scourgebodyhangingfemale01.mdx
 	world_lordaeron_plagueland_passivedoodads_hangingscourge_scourgebodyhangingfemale02.mdx
 	world_lordaeron_scholomance_passivedoodads_bookshelves_scholme_bookshelf.mdx
 	world_lordaeron_scholomance_passivedoodads_bookshelves_scholme_bookshelflarge.mdx
 	world_lordaeron_scholomance_passivedoodads_bookshelves_scholme_bookshelfsmall.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlescorner01.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlescorner01green.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight02.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight02green.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight04.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_floorcandlesstraight04green.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_scholme_greenrug.mdx
 	world_lordaeron_scholomance_passivedoodads_candles_scholme_purplerug.mdx
 	world_lordaeron_scholomance_passivedoodads_cauldrons_greenbubblingcauldron.mdx
 	world_lordaeron_scholomance_passivedoodads_operationtables_creepyoperationtable01.mdx
 	world_lordaeron_stratholme_activedoodads_doors_largeportcullis.mdx
 	world_lordaeron_stratholme_activedoodads_doors_smallportcullis.mdx
 	world_lordaeron_stratholme_passivedoodads_anvil_nox_anvil.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_bodies_massgrave.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_bodies_scourgebodyhanging01.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_bodies_scourgebodyhanging03.mdx
 	world_lordaeron_tirisfalglade_passivedoodads_graves_brillgraves01.mdx
 	world_wmo_azeroth_buildings_chapel_duskwoodchapel.wmo.mdx
 	world_azeroth_duskwood_passivedoodads_darkshireentrance_darkshireentrance01.mdx

BANNERS
 	world_expansion02_doodads_generic_highelf_he_banner_03.mdx
 	world_expansion02_doodads_generic_scourge_sc_banner_03.mdx
 	world_expansion02_doodads_generic_scourge_sc_banner_04.mdx
 	world_expansion02_doodads_generic_scourge_sc_banner_06.mdx

COFFINS
 	world_expansion01_doodads_auchindoun_passivedoodads_coffin_ancient_d_coffin.mdx
 	world_azeroth_duskwood_passivedoodads_coffin_coffin.mdx
 	world_azeroth_duskwood_passivedoodads_coffinlid_coffinlid.mdx
 
OTHER	world_critter_fireflies_fireflies01.mdx
 	world_azeroth_burningsteppes_passivedoodads_warlockshrine_warlockshrine.mdx
 	world_azeroth_duskwood_passivedoodads_duskwoodscarecrow_duskscarecrow.mdx
 
FIRE
 	creature_8fx_generic_fire_basic_bonfirehuge_smoke_8fx_generic_fire_basic_bonfirehuge_smoke.mdx
 	spells_stratholmefloatingembers_centered.mdx
 	world_generic_pvp_fires_lowpolyfire.mdx
 
SKYBOX
 	environments_stars_deathknightfireskybox.mdx
 	environments_stars_firelandssky01.mdx
 	environments_stars_orgrimmarraid_firesky01.mdx
 	environments_stars_skywallskybox.mdx
 	environments_stars_battlefield_dirty_skybox.mdx
 
WAGONS
 	world_generic_human_passive doodads_gypsywagons_stormwindgypsywagon01.mdx
 	world_kalimdor_mulgore_passivedoodads_burnedwagons_burnedgypsywagon01.mdx
 	world_kalimdor_mulgore_passivedoodads_burnedwagons_burnedgypsywagon02.mdx


Skybox
- Testing DNC Outdoors Cloudy for Vanguard Vale
- Testing DNC Firelands for Firelands
- Testing DNC Outdoors Dirty for Emberpeark Highlands
>>> Results: these skyboxe are too lowpoly vs. DNC Outdoor/DNC Hellish
>>> Option: Upscale textures to 512x512

QuestEvaluateSystem
- Fixing issues not working for pre-configured units


=================================================================================================================================================
Epic Quests 14.11.2025 - List of Actions:

QuestEvaluateSystem
- made the system more "automatic";
- usage example:
// In ConfigureQuestRequirements():
call AddQuest(1, udg_Thrall, 5, Faction.getFaction("Horde"), 3000, "normal")

QuestIconSystem
- hashtable made public so QuestEvaluatinSystem can access it

Quest System Quest Givers -trigger
-previously used to set initial quest icons (dummy)

=================================================================================================================================================
Epic Quests 13.11.2025 - List of Actions:

QuestEvaluateSystem -created
- QuestEvaluationSystem.j - The main system library
- Evaluates quest availability every 5 seconds
- Checks level, reputation, events, and custom conditions
- Integrates with QuestIconSystem and Reputation library
- Key Features:
>>> Automatic evaluation every 5 seconds
>>> Level requirements - Hero level checking
>>> Reputation requirements - Uses your Reputation system API
>>> Event-based quests - Support for boolean flag requirements
>>> Custom conditions - Advanced requirement functions
>>> Quest types - Normal, daily, repeatable, dungeon
>>> Dynamic icons - Automatically shows gray ! (unavailable) or yellow/blue ! (available)
>>> No duplicates - Prevents duplicate icons when quest becomes active
>>> Easy configuration - All setup in two functions
- How to use:
1. Configure quest givers in ConfigureQuestGivers():
call QuestEval_RegisterGiver(udg_YourNPC)
2. Configure quest requirements in ConfigureQuestRequirements():
call AddQuestRequirement(questID, npc, minLevel, faction, minRep, "normal")
3. In your quest triggers, when player accepts quest:
call QuestEval_MarkQuestActive(questID)
4. When quest is turned in:
call QuestEval_MarkQuestInactive(questID)

=================================================================================================================================================
Epic Quests 1.11.2025 - List of Actions:

Reputation
- debug messages hidden/shown with DEBUG variable (=set to FALSE to hide)
- mapped players to faction all should follow the primary faction player alliance state
- added debug calls for GUI debug commands:
>>> call SetFactionReputation(Player(0), "Horde", 5000)
>>> call TriggerFactionTemporalHostility("Horde")
>>> call SetReputationMultiplier(true)  // Enable 10x
>>> call SetReputationMultiplier(false) // Disable

Patrol System
- debug messages hidden/shown with DEBUG variable (=set to FALSE to hide)

Patrol Group System
- debug messages hidden/shown with DEBUG variable (=set to FALSE to hide)

Neutral Creeps
- lightning lizard
- removed all unit-type checks from "Neutral Unit Dies", not needed

Companions
- When kicked will change the AI heroes ownership to original player (hardcoded...)
- using udg_NPC_AI_XXX == no unit -> to check it the AI hero of is already created...
>>> This logic in spawnging AI heroes could be more dynamic/versatile...

=================================================================================================================================================
Epic Quests 31.10.2025 - List of Actions:

Reputation
- when temporal hostility for faction is active - show icon "Hostile" then revert to what ever icon status of that faction is
- show temporal hostility time left

Companion abilities
- should now work on Neutral units

Patrol System
- The units should now properly engage in combat when attacked without constantly being stopped




=================================================================================================================================================
Epic Quests 30.10.2025 - List of Actions:

Reputation
- faction temporarily hostility when attacked/unit killed by player0
>>> When Player(0) attacks/kills a non-hostile faction unit → faction becomes temporarily hostile
>>> After configured duration → faction returns to original status (based on reputation)
>>> Already hostile/enemy factions are not affected (they're already hostile
- Note: Alliances set in Init triggers for Player needs to be re-adjusted, because Reputation system is now the master (for Player 1)
- companion player (player(18)) alliance to follow player0's status with each faction (configurable by false/true boolean)

CreepRespawn
- Added way to configure unit-types that will not be respawned

AI Heroes
- Horde heroes changed to Player6 (HORDE)
- Note: may be breaking change and some things may not be correct as of this change!
- When invited to Companion Group, are now changed to Player 19
- When kicked, then changed back to their original player ownerships (WIP)

Import:
- Imported faction icons
- Imported faction status icons

Vanguard Vale
- some terraining


=================================================================================================================================================
Epic Quests 29.10.2025 - List of Actions:

PatrolSystem & PatrolGroupSystem
- Now should work
- unified PatrolSystem4.j under work and buggy (not used in map currently)
- added functionalities to have patrol group waypoint be random at set region OR manually set waypoints from regions

Reputation
- added faction status icons
- added faction icons
- all factions now use same status icons
- Reputation system is now the master system determine alliances for Player0, every computer unit alliances towards each other could also determined with this system with configurable boolean to utilize it or not
- added function to not show faction related rep increase/decrease messages and be visible in multiboard


=================================================================================================================================================
Epic Quests 27.10.2025 - List of Actions:

Reputation
- Fixes long-lasting issues with the library (failing silently)
- Now unit death event works because the library is completely initialized properly

CreepRespawn
- fixed wrong players in the configuration

PatrolGroupSystem
- still trying to get patrol group units moving - maybe try in test map...


=================================================================================================================================================
Epic Quests 26.10.2025 - List of Actions:

Reputation system
- small bug fixes
- use " debug alliancestatus " to check if the selected unit's player is enemy with player1
- Added Player-to-Faction Mapping System
>>> Configured Player 2 and Player 6 as Horde
- To add more players to certain faction (EXAMPLE):
>>> call Faction.mapPlayerToFaction(Player(1), horde)  // Player 2
>>> call Faction.mapPlayerToFaction(Player(9), horde)  // Player 10 is also Horde
>>> call Faction.mapPlayerToFaction(Player(4), alliance)  // Player 5 is Alliance
- Big issue: UNIT DEATH EVENT NOT WORKING

Ghost Wolf
- Items picked in Ghost Wolf shall now be transferred to invisible (real) morphed unit

Creep Unit Assignment
- Updated; added BossMountainGiant
- Elarindor player units should now respawn

Rifts Corrution
- Testing different channel based abiity for Aradion ritual spell
>>> test with: " debug aradion "
>>> stop test with: " ddebug aradion stop "
- should now display quest as Failed when Aradion or Valeria dies
- Valeria/Aradion should now return to their place when quest is failed
- all Ritual related timer/trigger should now be disabled when quest is failed

CinematicMover
- added new move mode: 9 = No Return (move all units but don't return them)
>>> Useful for cinematics / quests where you dont want to return any unit back

DInventory system
- Bug: DInventory - Stacking bug - After picking full stack of items of Item-type XXX, then next item of that item-type are inserted into DInventory as individual 1x charges and not adding the stacks (e.g., 6x -> 1x -> 1x -> 1x, etc.)
- Root Cause: The FirstStackableItemSlotOfBID function in SharedDInvLib.j was finding and returning any existing stack of the same item type, without checking if that stack was already full.
- Modified the FirstStackableItemSlotOfBID function to check if a stack has available capacity before returning it
- File Modified: SharedDInvLib.j / Function: FirstStackableItemSlotOfBID (lines 675-710)

Patrol System

Patrol Group System
- Death Check Filter Issue (PatrolGroupSystem.j)
>>> Added IsUnitInGroup() verification to ensure only deaths of actual patrol group members trigger the respawn check.
- The delayed patrol start timer was only paused, not destroyed, causing potential memory leaks.
>>> Changed PauseTimer() to DestroyTimer() and set to null.
- Critical Bug in PatrolSystem.j - Wrong Data Stored
>>> Added new hashtable key 11 to store unit count
>>> Updated PatrolSystem\_GroupStart to save waypointCount in key 6 and unitCount in key 11
>>> Updated all 9 functions that read unit count to use key 11 instead of key 6

UnitDeathEvent (new system)
- this is to centralize generic UnitDeathEvent

Creep Respawn
- new jass library CreepRespawn created to replace old GUI format
- utilizes UnitDeathEvent

Companions
- The logic of checking if the target unit IS an enemy backwards; this should fix inviting new companion units from AI heroes


=================================================================================================================================================
Epic Quests 25.10.2025 - List of Actions:

Heal Engine - Spell Power Percentual and Flat bonus
- modified logic for both Percentual and Flat spell power bonus for healing

DInventory system (bag slots)
- 12 slots initially
- Changes Made:
>>> DConfigurationArea.j - Initial Inventory Size
>>>>> Changed initial inventory from 25 slots (5×5) to 12 slots (3×4)
>>>>> Added comprehensive documentation header explaining how to use the bag expansion system
>>>>> Configuration:
integer InventoryColumns = 4
integer InventoryRows = 3
integer InventoryCapacityBase = 12

>>> SharedDInvLib.j - Added Vendor Functions
>>>>> Added two new convenience wrapper functions specifically for vendors:

DInvAddSlotsForPlayerVendor(playerId, numberOfSlots)
- For "1PerPlayer" paradigm
- Adds slots and shows confirmation message

DInvAddSlotsForHeroVendor(heroUnit, numberOfSlots)
- For "1PerHero" paradigm (current setting)
- Auto-detects paradigm and calls appropriate function
- Adds slots and shows confirmation message

>>> New Files Created
>>>>> EXAMPLE\_BagVendor.j - Complete working example with:
>>>>>>>>>> Item usage triggers (consumable bags)
>>>>>>>>>> Vendor purchase functions
>>>>>>>>>> Shop dialog system
>>>>>>>>>> Chat command testing (-bag 1, -bag 2, etc.)
>>>>> BAG\_EXPANSION\_GUIDE.md - Comprehensive documentation covering:
>>>>>>>>>> How the system works
>>>>>>>>>> All available functions
>>>>>>>>>> Suggested bag tiers and pricing
>>>>>>>>>> Multiple implementation methods
>>>>>>>>>> Testing instructions
>>>>> BAG\_QUICK\_REFERENCE.j - Copy-paste ready code snippets for:
>>>>>>>>>> Vendor functions
>>>>>>>>>> Consumable bag items
>>>>>>>>>> Dialog shop menus
>>>>>>>>>> Testing commands
>>>>>>>>>> Region-based vendor interactions
>>>>>>>>>> Existing Functions (Already in the System)

// Examples and testing6
// In your shop/vendor trigger:
call DInvAddSlotsForHeroVendor(buyerHero, 12)  // Adds 12 slots
Use the chat command system from EXAMPLE_BagVendor.j:

- Bag Vendor
>>> Now sells bag items (powerups) to be used to increase bag slots for the unit 
>>> Small, Medium, Large Bags powerup items created
>>> uses call DInvAddSlotsForHeroVendor(unit, integer)

Vanguard Vale
- Added Mountain Giant to wander at Redwind Pass

Reputation
- Fixed Linked Faction Reputation Bug
- Added Reputation Change Messages with Blue Text and Quick Fade
- Fixed Missing Faction Status Change Messages

Krolm (outcast ogre)
- added to Thornwoods
- chat/quest WIP

Patrol System
- Fixed Patrol Speed Not Reverting When Paused/Stopped
- Added Complete Group Patrol Functionality, with functions:
>>> PatrolSystem\_GroupStart(group, waypointCount, resetTime, pathStyle, autoResume, moveOrder, patrolSpeed) → returns groupId
>>> PatrolSystem\_GroupPause(groupId)
>>> PatrolSystem\_GroupResume(groupId)
>>> PatrolSystem\_GroupStop(groupId)
>>> PatrolSystem\_GroupContinue(groupId)

Patrol Group System (helper library)
- created

ThornwoodsHordePatrol (subfunction using Patrol Group System)
-created

Rifts of Corruption
- Accept quest; Valeria teleported outside camera at start and shall move near Aradion.
>>> Would need another trigger to wait for Valeria enter the spot and then issue face towards player / angle 192.0
- Added debug " debug Aradion " to test Channel spell on Nazgrek's position


=================================================================================================================================================
Epic Quests 24.10.2025 - List of Actions:

WaveSpawner (UnitSpawner)
- renamed to UnitSpawner
- refactor to be library using Briebe's table v6
- each spawned unit "wave" can be removed individually

Floating Text Spell
- Disabled "Floating Texts Config"
- Disabled "Flaoting Texts SPell Event"
>>> To test if these are the causes of random lag spikes
>>> If they are;
>>>>> then FloatingTextTag jass system / usage must be checked
>>>>> the triggers and function/condition usage withing the triggers themselves

HealEngine
- Fixed Critical CheckLoop Bug (Lines 173-241)
>>> Separated loop counter i from unitIndex to prevent infinite loops/skipped units
>>> This was the primary cause of unpredictable lag spikes
- Removed BJ Function Overhead
>>> Replaced RMaxBJ(0.00, regen\[unitIndex]) with inline comparison
>>> Replaced StartTimerBJ() with native TimerStart()
- Reduced Timer Frequency
>>> Changed HEAL\_CHECK\_INTERVAL from 0.05 to 0.10 seconds
>>> Cuts CheckLoop executions from 20/sec to 10/sec = 50% reduction
- Added Per-Frame Heal Limiter
>>> New constant: MAX\_HEALS\_PER\_FRAME = 25
>>> Prevents processing 100+ heals in one frame
>>> Excess heals automatically deferred to next frame
- Improved Loop Reset
>>> Added i = 1.00 reset between heals to prevent PreHealEvent counter issues

Heal Engine - Spell Power Percentual bonus
- modified, test if it works for native heals now when unit has Stat Spell power %

HeroItemCheck.j
- There were random issues with items disappearing from Inventory when calling these functions; main culprit seems to have been using wait(s)
- It has to be ensured that the system still works after the modifications and especially not using wait anymore, as there was reason for the wait to work for Quest Update triggers
>>> Race Condition: HeroItemCheck had a TriggerSleepAction(0.05) that created a 50ms window where game state could change between checks
>>> Global Variable Pollution: HeroItemCheckBoth used udg\_DInvUnit as a side effect, causing items to be removed from the wrong hero when multiple checks happened rapidly
>>> Non-Atomic Operations: Time gap between checking and removing allowed items to disappear or be consumed
- Fixes applied:
>>> Removed TriggerSleepAction from HeroItemCheck - now instant, no delays
>>> Made HeroItemCheckBothAndRemove atomic - check and remove happen together using local variables

Reputation system
- modified reputation states; enemy, hostile, unfriendly, neutral, friendly, covenant, exalted
>>> Enemy: some factions will hunt you
>>> Hostile = You will always be attacked on sight 
>>> Unfriendly = cannot buy items or companions, cant talk if quest givers / etc talk
>>> Neutral = can buy basic items, can talk
>>> Friendly = can buy more items, can talk
>>> Covenant = can buy more items, can hire companion units, can talk
>>> Exalted = can buy more items, can hire companion units, can talk, special item reward is given and title?

Aradion
- Rifts of Corruption:
>>> will not say unfinished lines when quest is failed
>>> the quest can be started again if its failed

=================================================================================================================================================
Epic Quests 23.10.2025 - List of Actions:

DInv & DEquipment system(s):
Updated the RemoveDInvItemChargesByType function in SharedDInvLib.j with:
- Comprehensive debug logging that tracks every step of the removal process
- Separated null and type checks for clearer logic flow
- Added a critical safety check that re-verifies the item type immediately before deletion to prevent any wrong items from being deleted
- Better error reporting that will show exactly which items are being processed and why

Updated HeroItemCheck.j & GetDInvItemChargesByTypeThreshold + RemoveDInvItemChargesByType in (in SharedDInvLib.j)
- Now operates in two phases:
>>> Phase 1: Removes items from DInventory (as before)
>>>Phase 2: If still need to remove more items, removes from vanilla inventory
- Uses the same logic for both:
>>> Handles 0-charge items (treats as 1 item)
>>> Handles partial removal (when an item has more charges than needed)
>>> Handles complete removal (when an item has equal or fewer charges)
>>> Enhanced debug messages show which phase is executing and from which inventory items are being removed

How It Works:
- When you call HeroItemCheckAndRemove(hero, 'I000', 10):
>>> First checks if the hero has 10+ items of type 'I000' in DInventory + vanilla inventory combined
>>> If yes, removes 10 items, prioritizing DInventory first, then vanilla inventory
>>> Returns true if successful, false if not enough items

ItemSearch.j
- Added requires SharedDInvLib to access DInventory functions and data structures
- Updated Documentation
- Added note that it now searches BOTH inventories
- Clarified that DInventory is searched first, then vanilla inventory
- Two-Phase Search Logic
>> Phase 1: Search DInventory
>>> Checks if unit has a DInventory (bid != -1)
>>> Searches all slots in DInventory
>>> Returns immediately if match is found
>> Phase 2: Search Vanilla Inventory
>>> Only executes if no match found in DInventory
>>> Searches all 6 vanilla inventory slots
>>> Returns if match is found
- Enhanced Debug Messages
>>> Shows which phase is executing
>>> Labels slots as "DInv Slot" or "Vanilla Slot" for clarity
>>> Shows which inventory the match was found in

How It Works:
When you call ItemSearch_FindItemByKeyword(udg_hero, "meat"):

- First searches the hero's DInventory for any item with "meat" in its name
- If found, sets udg_QuestItemTemp to that item's type ID and returns
- If not found, continues to search the vanilla inventory
- If found there, sets udg_QuestItemTemp to that item's type ID
- If no match in either inventory, sets udg_QuestItemTemp = 0
This ensures that quest items or special items can be found regardless of which inventory they're in!

Blood Splats Ground
- added condition to not trigger if the unit-type is "Totem"

Rifts of Corruption
- Ritual Prepare:
>>> Aradion is now moved near RiftCurrent Unit
>>> Aradion should now move to position of 500 away from from RiftCurrent unit from the direction of where Aradion is (=to not make him move to opposite side of Rift / walk pass the riftCurrent unit)
>>> Adjusted DialogCamera; double the distance and different angle
>>> Removed Wander ability from Aradion at start of trigger
- Fixed incorrect voicefiles for quest unfinished talk with Aradion
- Quest Req2 should now be also completed when all rifts closed

UnitStats
- The Problem:
>>> Scanned entire map every 3 seconds using GetWorldBounds()
>>> Processed hundreds of units repeatedly with 65+ ability checks each
>>> Caused severe lag spikes: 100 fps → 2 fps
- Fixes:
>>> 1. Event-Driven System (NO MORE PERIODIC SCANNING!)
>>>>> Units are processed only once when they spawn via trigger "Init 07 Unit Event Enters" and with function "call UnitStats\_ProcessUnit(GetTriggerUnit())"
>>>>> Uses triggers to detect unit creation automatically
>>>>> No more expensive map-wide scans
>>> 2. Smart Caching
>>>>> Tracks which units have been processed in a processedUnits table
>>>>> Never processes the same unit twice (unless you explicitly refresh)
>>>>> Instant checks, no redundant work
>>> 3. One-Time Initial Scan
>>>>> Runs once at map start (2 seconds delay)
>>>>> After that, only new units trigger processing
>>>>> No periodic lag after initialization

Kaelthir
- added item check and remove for quest Kaelthir Struggle
- voiceline (Kaelthir_0003) was missing from greet - edited to not include it

WavesSpawner.j
- Created
- To be utilized as waves of units easy spawning around point
- Current form should be separated, and create lite scripts that utilize this WaveSpawner to not fill it with quest/event specific scripts...

Multiboard Remove Companion
- For the Remove Companion trigger added clearing of texts of each column/row

Multiboard Add Companion
- changed "For each (Integer Multiboard_Int2) from 1 to 9, do (Actions)" to:
>>> "For each (Integer Multiboard\_Int2) from 1 to Multiboard\_RowVar, do (Actions)"
>>> This ensures that all rows (including newly added companion rows) get their widths set correctly.

Vanguard Vale
- Some terraining

=================================================================================================================================================
Epic Quests 22.10.2025 - List of Actions:

DInv & DEquipment system(s):
- Bug 1: Issue with using HeroItemCheck and GetDInvItemChargesByTypeThreshold(whichHero, itemId, requiredAmount) in SharedDInvLib will seems to randomly remove charges from items where it should not removed them
- Bug 2: Campaign items (and other item types) were showing charge numbers even when they shouldn't
- Bug 3: HeroItemCheck for 0-Charge Items / single items didn't work


BUG 1 FIX: RemoveDInvItemChargesByType
When using HeroItemCheck or any function that removes items from DInventory, there was a critical loop bug causing random items to disappear.

The Bug:
In RemoveDInvItemChargesByType (SharedDInvLib.j), when deleting items:

Item deleted from slot 3 → all items shift down (slot 4→3, 5→4, etc.)
Loop counter ALWAYS incremented → next check at slot 4
Result: Item that shifted from slot 4 to slot 3 was SKIPPED! ❌
Example:
Inventory: Gold(0), Water(1), Potion(2), Water(3), Mana(4)

Command: Remove 6 Water charges

BUG 2 FIX:
Campaign item with Level = 0 (not stackable) was showing "0" or "1"
Should only show charges if the item can actually stack (Level > 0)
The Fix: Updated DInventoryIsItemStackable to check Item Level

BUG 3 FIX:
- Now treat 0-charge items as 1 item when checking for item
- Treat 0-charge items as 1 item when removing item


Aradion
- edited Fading Sparks voicelines slightly
- All Aradion quest descriptions missed \n\n - fixed
- Fading Sparks quest title was incorrectly Crystal of Hope - fixed
- Rifts quest should now have Aradion properly added to multiboard when starting

Rifts Corruption
- wrong create trigger was used, fixed and it should now work
- Cinematic will start when preparing for RIFT closing
- Valeria + Player and companions are move near Aradion when preparing for RIFT closing
- Aradion should cast life drain based channel spell on DummyTargetUnit
- Added enabling fail conditions (Valeria or Aradion) dies to triggers upon quest start
- Added disabling fail conditions (Valeria or Aradion) dies to triggers upon quest complete

Fading Sparks
- changed Rod to cause attack type Spells and damage type Normal when using of Mana Wraith

CinematicMover
- Added distance check in MoveCompanionCallback
- Added distance check in MoveTamedCallback
Added new constant:
>>> MAX\_MOVE\_RANGE = 1200.0 - Controls when to skip moving companions/pets during cinematic start
- Kept existing constant:
>>> MAX\_RETURN\_RANGE = 1200.0 - Controls when to skip returning units after cinematic ends
- Updated functions:
>>> MoveCompanionCallback - Now uses MAX\_MOVE\_RANGE for distance check
>>- MoveTamedCallback - Now uses MAX\_MOVE\_RANGE for distance check



---



=================================================================================================================================================
Epic Quests 19.10.2025 - List of Actions:

DInv & DEquipment system(s): Serious BUG - Some item may (Spring Water 3rd slot in this case) lose charges / get disappeared - Is it because of some function?
- Bugs found:
>>> 1. CRITICAL BUG in Item Swapping (DInventory.j, lines 857-865)
>>> 2. CRITICAL BUG in Equipment Transfer (SharedDInvLib.j, line 4829)
>>> 3. Item Stacking Issues (SharedDInvLib.j, lines 3615-3670)
>>> 4. 4. Missing Handle DB Updates in Unequip (SharedDInvLib.j, line 4683)
- Bugs Fixed:
>>> Item Swap Bug (DInventory.j)
Problem: When swapping items, the system never updated the slot tracking database
Result: Items appeared to move but system thought they were in old slots → deleted wrong items
Fixed: Now updates DInvItemHandleDB[].integer[2] for both items after every swap

>>>Equipment Transfer Bug (SharedDInvLib.j)

Problem: Code accessed item data AFTER removing it from inventory
Result: Corrupted references, unpredictable item loss
Fixed: Now stores item handle ID before deletion
>>> Missing Slot ID Storage (SharedDInvLib.j, 2 locations)

Problem: When storing items, the slot ID field was never set
Result: System couldn't reliably locate items for later operations
>>>Fixed: Now properly stores slot ID in integer\[2] field

Vanguard Vale / Elarindor story acts
- more lines for Rifts of Corruption quest
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Valeria Dies
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Aradion Dies
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Prepare
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual Combat
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual CombatIncoming
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual FinishOne
- Completed (almost, chat related parts mostly) trigger: Quest Rifts Corruption Ritual FinishAll

Vanguard Vale
- terraining

Mana Crystals
- Created "Mana Crystal" unit
- Logic for spawning mana crystals
- Logic for mining mana crystals (including random explode chance)
- adjusted scale and height of vein glow for mana crystals
- debug spawn: manacrystalstest

Aradion
- Adjusted quests for new Reputation system, DInv item check & remove functions
- Created Fading Sparks quest and related events (Rod that is used to harvest the essences and its associated triggers)
- Created Rifts of Corruption quest and related events

Valeria
- Adjusted quests for new Reputation system, DInv item check & remove functions

Note on abilities:
- Item abilities need to be temporalily made non-item ability to change the Description tooltip that will be shown in-game!

Reputations system
- Disabled debug messages

UnitExperience system
- Disabled most debug messages

RangeCheck
- BossMordax and BossVoidEntity; fixed wrong player (Player1) instead to be Player0

SharedDInvLib
- modified GetDInvItemChargesByTypeThreshold because it only worked for more than 1 charges item-type check
- Campaign classified items should now stack

Crypt
- Attemp to fix crash at Crypt Trap1

=================================================================================================================================================
Epic Quests 18.10.2025 - List of Actions:

Redone storyline / voicelines for Vanguard Vale / Elarindor story acts
- still needs heavy editing before advancing to creating the voice files / quests
- Now should be able to edit/make voicelines/quests/events until the quest "The Witch's Smile"
- WIP: Continue from Aradion / Valeria quests

Crypt Trap
- edited trap trigger



=================================================================================================================================================
Epic Quests 15.10.2025 - List of Actions:


DummyUnits
- set Art - Backswing = 0.00.
- set Cast Point = 0.00
- set Speed Base 0
- set Movement Type = None

UnitExperience
- added function ForceLevelUp
- added debug to levelup pet with " debug pet levelup "
- added debug to retrieve pet xp to level with " debug pet status "

Terraining
- Crypt; walling / trap testing
- Elarindor (walls)

RangeCheck
- new library that provides functions to check the range from a unit or point to the closest unit owned by a specified player.




=================================================================================================================================================
Epic Quests 14.10.2025 - List of Actions:

Reminder: RUN " debug aidisablemainstates " to disable Ai

BoomBrothers
- added safety instructions item to "Mandatory Training"
- BoomBrothers EDIT / SOUNDS/CAMERAS/CINEMATIC SETTINGS/QUEST CREATION - continued working on THIS > Mostly done
>>> Need to edit still: Cameras, cinematic settings, quest creations, DInv \& DEquip related item removal from inventory and checking

Dragonpeaks
- Testing adjusting fog

HealEngine
- Disabled trigger "Heal Adjust On Damage"
- Disabled trigger "Heal Adjust After Damage"
>>> These one caused atleast Nazgrek have "Healed XXX" texts...
- set in library: "IS_NATIVE_REGEN_SELF"   = true

UnitExperience
- Will only remove units that are: Have a valid Custom Value (id > 0), AND Are actually registered in the XP system (registered.boolean[id])
- Changed the registration logic to initialize the unit with 0 XP at their current level, rather than calculating cumulative XP. This way:
>>> E.g., Unit registers at level 6 with 0 XP
>>> They start fresh and need to gain XP to progress to level 7
>>> No immediate level-ups upon registration

Imported:
- Unit models
>>> Skeleton
>>> SkeletonNaked
>>>>> These should replace regular skeleton units
>>> Dwarf Prospector Gehn.mdx


- Axes;
>>> Axe\_1H\_Flint\_A\_01
>>> Axe\_1H\_Hatchet\_A\_01
>>> Axe\_1H\_Hatchet\_A\_02
>>> Axe\_1H\_Hatchet\_A\_03

- Fires
>>> LargeBuildingFire0, 2, 2
>>> SmallBuildingFire0, 1, 2

-Staves
>>> Stave1, 2, 3, 4, 5, 6, 7, 8, 9

- Tools
>>> itemWeaponAxe1.mdx"
>>> itemWeaponBroom.mdx"
>>> itemWeaponHammer.mdx"
>>> itemWeaponPick1.mdx"
>>> itemWeaponPitchfork.mdx"
>>> itemWeaponRake.mdx"
>>> itemWeaponShovel.mdx"
>>> itemWeaponWrench.mdx"
>>> WeaponAxe1.mdx"
>>> WeaponBroom.mdx"
>>> WeaponHammer.mdx"
>>> WeaponPick1.mdx"
>>> WeaponPitchfork.mdx"
>>> WeaponRake.mdx"
>>> WeaponShovel.mdx"
>>> WeaponSickle1.mdx"
>>> WeaponWrench.mdx"
>>> ... And also suitable Icons for these models

- Swords
>>> Sword\_Bronze
>>> Sword\_Ebonite
>>> Sword\_Iron
>>> Sword\_Steel
>>> Almalexia\_Scimitar
>>> Bipolar\_Blade
>>> Chrisamer
>>> IceMonarch
>>> Umbra
>>> Sword of Death

Shields
>>> Buckler\_Damaged\_A\_01.m2"
>>> Buckler\_Damaged\_A\_02.m2"
>>> Buckler\_Oval\_A\_01.m2"
>>> Buckler\_Round\_A\_01.m2"
>>> Shield\_Crest\_A\_01.m2"
>>> Shield\_Crest\_A\_02.m2"
>>> Shield\_Crest\_B\_01.m2"
>>> Shield\_Crest\_B\_02.m2"
>>> Shield\_Crest\_B\_03.m2"
>>> Shield\_Engineer\_A\_01.m2"
>>> Shield\_Horde\_B\_04.mdx"
>>> Shield\_Horde\_B\_03.mdx"
>>> Shield\_Horde\_B\_02.mdx"
>>> Shield\_Horde\_B\_01.mdx"
>>> Shield\_Horde\_A\_04.mdx"
>>> Shield\_Horde\_A\_03.mdx"
>>> Shield\_Horde\_A\_02.mdx"
>>> Shield\_Horde\_A\_01.mdx"
>>> Shield\_Engineer\_C\_01.mdx"
>>> Shield\_Engineer\_B\_01.mdx"

Multicategory weapons
>>> Adamantium\_Claymore.mdx"
>>> Adamantium\_Mace.mdx"
>>> Adamantium\_Shortsword.mdx"
>>> Adamantium\_Spear.mdx"
>>> Adamantium\_WarAxe.mdx"

Maces
>>> Mace\_2H\_Spiked\_A\_02\\Mace\_2H\_Spiked\_A\_02.mdx"
>>> Mace\_2H\_Spiked\_A\_03.mdx"
>>> Mace\_2H\_Spiked\_B\_02.mdx"
>>> Mace\_2H\_ZulGurub\_D\_01.mdx"
>>> Mace\_2H\_Stratholme\_D\_02.mdx"
>>> Mace\_2H\_Spiked\_B\_01.mdx"
>>> Mace\_2H\_Standard\_A\_02.mdx"
>>> Mace\_2H\_Standard\_A\_03.mdx"
>>> Mace\_2H\_Standard\_A\_01.mdx"
>>> Mace\_1H\_Blood\_A\_01.mdx"
>>> Mace\_1H\_AhnQiraj\_D\_03.mdx"
>>> Mace\_1H\_AhnQiraj\_D\_02.mdx"
>>> MaceNaxxramas01.mdx"
>>> MaceBlackWing01.mdx"
>>> MaceBlacksmithing03.mdx"
>>> MaceBlackWing02.mdx"
>>> MaceCoilfang01.mdx"
>>> MaceAhnQiraj01.mdx"
>>> MaceHellfire.mdx"
>>> MaceBlood02.mdx"

=================================================================================================================================================
Epic Quests 13.10.2025 - List of Actions:


UnitExperience -v3
- Updating

Tamed Unit Dies
- Changed pause to be after animation to try to solve why Stand animation gets stuck for tamed unit

Imported:
- HarvestMana model
- Mythic Storms models
- Overhead Buff Pack models

Taming
- should now take 75 % more dmg during taming
- new tame issue not registering should be fixed now

VeinGlow
- should now be correctly positioned in Z height

UnitHider V3 worked, but disabled for now,...

Dead Woods
- terraining (draft)


=================================================================================================================================================
Epic Quests 12.10.2025 - List of Actions:

Major updates:

UnitExperience -v3
- Now using custom value of unit vs. previously unit handle
- massively updated the system, to also include unit-type predefined stats, e.g., turtle having more HP / block per level vs. tiger etc.

UnitHider v2
- revamped the whole system to use Table by Briebe and TimerUtils (unsure about this)
- needs to be tested is it now useable all the time
- Disabled for now as there are issues with:
>>> UnitHider: not working correctly - it hides most, it seems to hide units very slowly
>>> UnitHider: severe lag introduced when now in use

Tamed Unit - multiboard
- Stats will now be added initially when pet is added to multiboard

UnitStats v1
- jass library version created and old GUI version disabled for now
- also added HIT stats, although for unit may not be used...

Old bags systems related
- Disabled trigger "Bag Follow"
- Disabled trigger "Bag Add"
- Preplace bag unit deleted
- Disabled bag related variable setting in Initialization and Init 01a Units triggers
>>> To be replaced with new logic that will expand DInv slots
>>> Also DInv initial slots should be like 6 or 12 slots

EDIT / SOUNDS/CAMERAS/CINEMATIC SETTINGS/QUEST CREATION
- Intro Cinematic -> Done
- BoomBrothers -> started


=================================================================================================================================================
Epic Quests 11.10.2025 - List of Actions:

Pet related
- Shadowclaw will now be vulnerable when invited back into the group (as TamedUnit)
- Pet crit, block, dodge, hit, spell power are now shown in multiboard
- Pet values are correctly cleaned after pet removed from multiboard
- Pet death counter functionality added

UnitExperience
- Testing with different methods why only the 1st unit register works
- Testing filter methods to reduce lag for XP gaining when unit dies near
- The library left in error state - needs fixing

Dark Shamans (Boss Scorchion)
- Removed IsUnitAlive(CV) check from Reset trigger - needs testing that the Reset trigger works correctly


=================================================================================================================================================
Epic Quests 10.10.2025 - List of Actions:

Reputation System
- updated library; multiboard silently failing

Shadowclaw Stats trigger disabled as now using generic UnitExperiece stats increase logic

BossScorchion
- Dark Shamans should not correctly stay in combat and not reset in the middle of combat (wrong logic in the loop)

Vanguard Vale
- terraining
- created B yellow version of Bush
- added brambles04 and bushes around the Vanguard Vale trees

Tame Beast Start
- added more units that can be tamed (unfinished)

Tamed Units animation
- tried to fix stuck animation after death (test)

Tamed Units level up
- added triggr MultiboarUpdateLevelTamed to be used by UnitExperience system when unit levels up

UnitExperience
- added ScaleUnitStats function that will increase the following stats of the pet;
>>> armor
>>> hp
>>> hp regen
>>> min dmg
>>> max dmg
>>> secondary stats; block, crit, hit, dodge 
- Still to be decided whether this is good way to increase stats, also is there possibility of very overpowered pets at high levels?

CinematicTrailer1
- testing FoV 120


NOTE: CRASH UPON SAVE!!!!
- all these editions below not saved!
- causer: UnitExperience system! Some incorrect function usage perhaps
- Redone the edits...

=================================================================================================================================================
Epic Quests 9.10.2025 - List of Actions:

Quest Hashtable System
- Added reward Reputation with Faction to the system
>>> Note: needs to be implemented to already created ones!

Reputation and Stats -dummy units
- created
- setting variables at Init 01a Units
- testing to use these to Open either multiboard Reputations or Stats
- NOTE: Has to be taken into account possibly in many triggers...

Pets
- Tamed pet should now be added to focus unit group Nazgrek or Zulkis depending who was the "tamer"
- Pet name should now update after renaming pet
- pet level should be erased from multiboard when kicked out
- pet level should now update correctly to multiboard
- if the pet was previously registered to UnitExperience system, XP is just enabled again, not registered again

UnitExperience
- pet level will be taken into account upon registering to the system

Invite / Kick Companion
- Shadowclaw should now be able to be invited to group
- Shadowclaw XP is just enabled again, not registered again
- kicking TamedUnit will disable it's XP gain in UnitExperience system

Reputation system
- fixed incorrect index using in loops from "0" to "1"

Imported WoW models wit fixes to "head" attachement point
- nazgrek
- elf-sorcerer (Evil witch elf illusion)
- magister-duskwither (Aradion)
- dark-ranger (Valeria)

Imported (finally) big amount of Icons for items to be used
- axes
- bags
- belts
- boots
- boxes and barrels
- bracers
- chests
- cloaks
- cloth and leather
- food
- gloves
- hammers
- heads
- helmets
- herbs
- keys
- maces
- mail
- necklaces
- other
- pelts
- potions and bottles
- rings
- shields
- staves
- swords

Imported following item weapon models and set as ability attachement items for future item creations:
itemweapons\Ashkandi, Greatsword of the Brotherhood.mdx
itemweapons\axe_1h_pvehorde_d_01_Green.mdx
itemweapons\axe_1h_pvehorde_d_01_red.mdx
itemweapons\Betrayer of Humanity.mdx
itemweapons\Blade of the Warlord - D3.mdx
itemweapons\Bloodmaw Magus-Blade.mdx
itemweapons\bloodrazor.mdx
itemweapons\Bonereaver's Edge.mdx
itemweapons\Crux of the Apocalypse.mdx
itemweapons\Deadly Strike of the Hydra.mdx
itemweapons\Iridal, the Earth's Master.mdx
itemweapons\jelly-sword.mdx
itemweapons\Kalimdor's Revenge.mdx
itemweapons\Kang the Decapitator.mdx
itemweapons\MaldraxxusLordAxe.mdx
itemweapons\Seraph's Strike.mdx
itemweapons\Shin'ka, Execution of Dominion.mdx
itemweapons\Starshatter.mdx
itemweapons\Stave_2H_Jeweled_D_01.mdx
itemweapons\sword_1h_long_d_03.mdx
itemweapons\Syphon of the Nathrezim.mdx
itemweapons\Teebu's Blazing Longsword.mdx
itemweapons\The Gidbinn.mdx
itemweapons\The Turning Tide.mdx
itemweapons\The Widow's Embrace.mdx
itemweapons\Tomb Reaver .mdx
itemweapons\Verigan'sFist.mdx
itemweapons\Whirlwind Axe.mdx


=================================================================================================================================================
Epic Quests 8.10.2025 - List of Actions:

Reputation system
- continued creating the jass library and now compiled without errors
- will need proper testing; debugging
- show multiboard: debug repmb show
- hide multiboard: debug repmb hide
- multiple edits
- added possibility for unit type factions - e.g., neutral hostile gnolls as faction etc.

Patrol System
- V2 using Table and TimerUtils is under draft

debug changeowner -command added
- changes the selecte unit(s) to player 1 ownership

UnitExperience V2
- fixed not giving any XP - missing initializer Init at the library header...

Multiboard (stats)
- reverted: - MultiboardCreate on map init vs. previously after 1s game time

Companion Invite
- added inviting Shadowclaw possible if player doesn't have any tamed unit

FloatingTextTagSimple
- added boolean to control if we want the text to drift upwards or not
- added boolean to control if we want the text to follow the unit

Tamed Unit Dies
- floating text tag should now remain still with new modifications to FloatingTextTag.create function

Mordrax
- added "death flight" when Mordrax has been defeated


=================================================================================================================================================
Epic Quests 7.10.2025 - List of Actions:

Reputation system
- Started drafting reputation library in vjass that will replace the current draft reputation system
- Note: May require intensive testing and good API for quests to add rep properly
- Idea is for the GUI triggering to only call ADD or REMOVE REP in quests or events, death events will be handled by the system internally
- ADDING or REMOVING REP by quest should not be linked to other functions? only killing?
- Continue editing the LIBRARY

Tamed Units
- fixed wrong UnitExperience register unit when Finishing tame beast
- when kicking Tamed unit, it's XP will be disabled but it can be continued as long as that unit stays alive
- fixed some multiboard tamed unit related bugs

UnitExperience
- added function UnitExperience_DisableXP
- V2 that should be more lag-free and perform better utilizing Table under testing

Tame Beast -abilities
- changed Hit points drained to 0; note that it can affect the unit not attacking the taming unit

Mordrax
- created voicelines for combat and register to ExSound
- triggered voicelines to Boss Mordrax

Models uploaded/updated
- old Nazgrek model replaced
- new elf model: elventowersilithus01.mdx
- Faerie Dragon ghost form: FaerieDragon_Ghost.mdx
- elf sorcerer model added (witch illusion): elf-sorcerer.mdx
- elf statue: StatueofAzshara1.mdx

Sound files (NOTE: IMPORTANT) <<<<<<<<<<<<<<<<<<<<<<<<
- removed all imported voicefiles except AIHero lines for now
- remove reason: now using external sound files that are called by ExSound system
- note: that most sounds/cinematics wont work, because need to use ExSound!
- copy style for older cinematics/dialogues from Grum/Aradion for example, check the camera / DInv stuff as well.

CinematicMover
- edited Shadowclaw out, and use only TamedUnit / RevivalTimerPet
- pets dont really die, so we have to use "fake" triggers
- using trigger Tamed Unit Dies (to "kill" pet) and triger Tamed Unit Revival to "revive" pet

Multiboard (Stats)
- MultiboardCreate on map init vs. previously after 1s game time
>>> Reason: Reputation system uses/calls udg\_Multiboard (stats)

Vein Glow
- now using position of vein unit instead of attachement point, as there were not attachement point for OreVeins or Crystals

=================================================================================================================================================
Epic Quests 6.10.2025 - List of Actions:

CinematicMover
- added debug commands;
>>> debug cinematicmove
>>> debug cinematicmove withpoints (target of current camera view)
>>> debug cinematicreturn
- fixed not moving companions/tamed units in "CinematicMove
- fixed moved CinematicTriggerUnit also returning to init location
>>> Note: It maybe sometimes wanted to move the unit to return location?

Tamed Units (pets)
- Tamed units now won't completely die when killed, instead they are kind of freezed for RevivalTimerPet and after that they are back to normal
- Before this only Shadowclaw was revived, but now all pets share same logic, otherwise leveling pet wouldn't make sense in case they die and progress is lost
>>> Note: Pet Death Animation and animation when Revived needs to be sorted out - How do we play Death animation for the pet and how do we keep the pet staying in paused death animation?
>>> Note: may have to adjust FloatingTextSimple, we want the new floating text to act similarly as the old one; floating slowly above the dead pet

Multiboard
- Added pet level (when new pet is added and update multiboard
- Changed ReviveTimerShadowclaw to ReviveTimerPet

Pets (Tamed Units)
- Added Pet Rename function; player can change the pets name by typing: /pet rename <name>


=================================================================================================================================================
Epic Quests 5.10.2025 - List of Actions:

DestructibleDeathEngine
- created simple destructible death event that utilizes DestructibleRevival system for getting the dying destructible
DestructibleRevival
- added hook after "set argDest = GetTriggerDestructable() -- call FireDestructibleDeathEvent(argDest)

Destructible Item Spawn
- created first trigger to try spawn items from dying destructibles - note how to get level area of destructible?
- createde various range of Crates and use Editor suffix (Level 1-5) etc.
- Note: do for barrels etc.
- Note: Fill the map with zone / specific destructibles
- Note: Drop rate could be lower? / less crap?

CinematicMover
- once again fixing companions and tamed units not storing...

Floating Spell Event Text
- Once again trying to use Arcing TT Linear function (will see if this one still lags)

FloatingTextTag
- created similar style library for simple text tags

Vanguard Vale
- terraining

Sirensong
- terraining

Morthun
- Added patrol slow speed and when engaged normal speed triggers
- adjusted animation walk and run speeds

Mordrax
- removed movement speeds settings as PatrolSystem now handles it on its own

Valeria
. added ValeriaEncounterReset Boolean to prevent random movement triggering from periodic timer

Cloned more voices for future quest givers and bosses etc.

Boom Brothers
- Added CinematicMove related positioning - to test how companion units are moved (if at all)

=================================================================================================================================================
Epic Quests 4.10.2025 - List of Actions:

UnitExperience
- fixing issues with lag / wrong xp gain

CinematicMove -library
- editing the library

Morthun
- Mini boss added to Verdant Plains wandering around the area

Vanguard Vale
- terraining

Vein Glow
- Fixed special effect not showing
- Note: there mighty be issues with Crystal and Ore vein spawn triggers as they use utilize same locations when spawning at once, therefore possibility of point being null and the ore spawning at the center of the map

Arcing TT
- again, some fixing (try)

DestructibleRevival
- added DESTRUCTABLE DEATH CALLBACKS / hook to when destructible dies
- to be used in trigger(s) to spawn items from crates, barrels, etc.


=================================================================================================================================================
Epic Quests 3.10.2025 - List of Actions:

UnitExperience
- some fixes
- debug messages to help checking the system

Arcing TT
- changed camera distance to 2500 from 1200

CinematicMove -library
- to make simple cinematic storing / restoring of units for and after cinematic
- CinematicTriggerUnit = Nazgrek (Quests of Grum trigger)
--- this basically handles around what unit things will be moved
- unfinished yet and definitely needs some testing etc. setting up


=================================================================================================================================================
Epic Quests 2.10.2025 - List of Actions:

Floating Spell Event Text
- made some modifications fix lag caused by heavy stringHash color conversion before creating Arcing text

Arcing TT
- some fixes

=================================================================================================================================================
Epic Quests 1.10.2025 - List of Actions:

DInv & DEquip system
- HeroItemCheck and HeroItemCheckBoth (Nazgrek and Zulkis) added as "addon"
>>> These help fastly check whether either hero has item of type and with amount for quests/dialogs etc.
- Note on getting item of type from hero Inventory:
>>> In SharedDInvLib.j there are also: DInvUnitHasItemType and DInvUnitGetItemSlotOfFirstItemByItemType original functions
>>> We currently utilize our own GetDInvItemChargesByTypeThreshold
- Added "RemoveDInvItemChargesByType" function
>>> This is to be used together with HeroItemCheckBoth or HeroItemCheck

Arcing TT
- added createLinear method for simple floating texts
- changed this: "set .t = duration" >>> "set .t = TIME_LIFE" like originally is to try fix texts disappearing

Grum Bloodfang
- added proper item checks for Whelps of Destruction, Dragon Eggs and GrumDialog completion checks

Quest Icon System V1.0 -> V1.1
- fixed not properly saved and handled minimap ping icons

DInv and DEquip initialized for Zulkis in triggers (unfinished / need remake) Giving The Letter Q / Giving The Letter Q debug (command "debug givezulkis")

ExMusic
- wait before starting new track increased from 1.00s to 2.00s to reduce lag caused by music, might not help at all

Zones
- Added ZoneDayNightEvent Boolean to prevent "Entered Zone XXX" appearing during DayNightEvent

=================================================================================================================================================
Epic Quests 30.9.2025 - List of Actions:

GetItemCost -added
- use GetItemTypeIdGoldCost to get item cost (gold)
- use GetItemTypeIdWoodCost to get item cost (lumber)
>> Note: still cant use them as DInv system says undeclared function - something needs setting up even though setting GetItemCost as "requires"

DInv & DEquip system
- Stacking now works without player needing to press "Infite Stacking"
- SharedDInvLib.j
 	>>> Changed the texts and the order of texts in function UpdateDEqCSheet
 	>>> Added colors to the stat texts
 	>>> Note: the coloring / stat names have to match also on the item itself vs. DEqCSheet
 	>>> GenerateDEqTooltip function:
 		>>> Modified texts + some modifications to showing the numbers
 		>>> If item contains ability with string containing "EQUIP" it wont be displayed

- DInventory.j
 	>>> function InitializeDInventoryForUnit
 		>>> added: set PlayerStackingMode[pid] = 2
 		>>> this should allow stacking of charges.

- Spell damage changed to Spell Power (now there can be "+ XX % Spell Power" (perc amount) and "+ XX Spell Power (flat amount)"

- Spell power flat amount increase needs to be created as system;
 	Stat_SpellPowerPerc[ ] 	- Original variable
 	Stat_SpellPowerFlat[ ]	- New variable

- trigger "Stat Spell Power Damage" -added flat spell damage increase
- trigger "Stat Spell Power Healing" -added flat spell healing increase

Block Chance
- fixed incorrect damage amount block; previously blocked only 25 % when it should be other way around and block 75 %
- TBD: Block reflection damage of DMG event amount x 0.25 that is caused by block to the DMG event source

UnitExperience
- created to system for unit experience (tamed pets in mind)
- first iteration only considers increasing Shadowclaw's stats when it levels up - other pets should also level up, but stat increase are not implemented

Ore Veins and Crystals
- Added glow effect to some veins, upon death the effect is removed


=================================================================================================================================================
Epic Quests 29.9.2025 - List of Actions:

Item Unstack system
- Added debug messages
- Fixed item disappearing when splitting charge
- Note: split charge item will go from vanilla inventory to the new Custom inventory
- Note 2: should the unstack/split function be inside the new custom inventory?

Heal Engine
- DRAFT (WIP): Stat Healing bonus -trigger: If unit has Spell bonus, it should now adjust healing received

DInv & DEquip system
- modified stat names in DEquipment.j
- modified item slot names in DEquipment.j
- Note: Modify what the stats do in "SharedDInvLib.j"
>>> added definitions to add Crit, Dodge, Block, Hit, Spell Power
- DInventory.j
 	>>> change PlayerStackingMode[24] to PlayerStackingMode[1]
 	>>> Maybe need to test whether it must be 1 or 2?
- SharedDInvLib.j
 	>>> Added max charge functionality by using Item levels as charge
- SharedDInvLib.j
 	>>> Modified function UpdateDEqCSheet for correct percentage Crit, Dodge, Hit, Block, Spell Power, ...
- SharedDInvLib.j
 	>>> Added function to easily returns the number of charges of a given item-type carried by a unit.
 	Usage:
 	DInvUnit = unit
 	DInvItemType = item to be searched
 	DInvItemAmount = how many items
 	set udg_DInvItemCarrierHasItems = GetDInvItemChargesByTypeThreshold(udg_DInvUnit, udg_DInvItemType, udg_DInvItemAmount)

ExMusic
- Added stop with fade with wait + then stop music immediately to PlayMusic function to prevent lag spike occurring

Following doodads has been imported:
Aiur_Plantlife_00
Aiur_Plantlife_01
Aiur_Plantlife_02
Aiur_Plantlife_03
Aiur_Plantlife_16

Elsecaro_Curtain1x1_00
Elsecaro_Curtain1x1_01
Elsecaro_Curtain1x1_02
Elsecaro_Curtain1x1_03
Elsecaro_Curtain1x1_04
Elsecaro_Curtain2x2_00
Elsecaro_Curtain2x2_01
Elsecaro_Curtain2x2_02
Elsecaro_Curtain2x2_03
Elsecaro_Curtain2x2_04
Elsecaro_Curtain4x2_00
Elsecaro_Curtain4x2_01
Elsecaro_Curtain4x2_02
Elsecaro_Curtain4x2_03
Elsecaro_Curtain4x2_04

credits Renn01

These are mainly to be used in Sirensong zone and subzones


=================================================================================================================================================
Epic Quests 28.9.2025 - List of Actions:

HealEngine
- IS_NATIVE_REGEN_SELF set to false
- HealingDisplay; added condition HealSource Equal to No unit
- RegenerationDisplay; added condition; (HealTarget has buff Warmth ) Equal to False
>>> This maybe redundant with IS\_NATIVE\_REGEN\_SELF

Blood Splats
- added condition to return (skip creating blood splat) if the dying unit has "Locust" (Aloc) ability

Item Drop System
- added condition to return (not spawn any item) if the dying unit has "Locust" (Aloc) ability

DInv
- added wait 0.05s to GetDInvItemChargesByTypeThreshold to help system see proper charges when unit acquires item
- The wait worked, but is it good practice - no, but can be thinked later maybe...
>>> Note: waits should not be used here, maybe use timer and refresh?

Item Unstack system created and added

=================================================================================================================================================
Epic Quests 27.9.2025 - List of Actions:

Unit Within Range 1.5 (by Tasyen - New System added)
- all current range check (that most currently leak position) should be replaced with this?
- remember need to register unit again if the unit dies and respawns

Void Entity
- fixed voicelines triggers spamming

Boss Scorchion
- Fixed following issue: After engage reset - Scorchion is not set vulnerable again
- Fixed following issue: Darkshamans during engage voicelines?
- NOTE: To be fixed: When engage reset is triggered, dark shaman voiceline should only be played if player unit is near
- NOTE: To be fixed: last dark shaman will stay for voiceline and then die before Scorchion boss fight starts
- Added: Extra high HP regen to Scorchion before Boss Fight and set HP regen to normal when the fight starts and set to High again when combat resets

Destroyer Inventory - Charges
- Testing how to retrieve charges of item type from the custom inventory with added API function "GetUnitItemChargesByType" to SharerdDInvLib
- Test on trigger Quest Whelps of Destruction Update - the quest should now update when player picks the 10th item


Imported doodads specifically for Vanguard Vale zone in mind

Debug
- added debug that will see what dying dummy unit is
>>> Solve what unit is causing these blood splats spawning everywhere

=================================================================================================================================================
Epic Quests 26.9.2025 - List of Actions:

Dark Shamans (by BossScorchious)
- Added voicelines Engage, Start, Reset, Distant (filmed from far away)
--- NOTE: need to trigger last shaman dying and stopping animation for the line and then "finish" him off before Scorchion starts fully

AI Heroes
- Closest unit functions (Rogue, Warrior, Paladin, Engineer (shredder form); Leak inside "Pick every unit in Closest_Group" removed (cascading point leaks)
- dsiabled debug messages from AI actions

AI Heroe - New vJass system on develop
- Aim is to be more event-driven logic, and easy to maintain
- basic actions should be functions that can be easily bug fixed etc.
- Must be lag free vs. current Logic tree style made in GUI triggers is heavy process on map

Disabled most found debug messages from Abilities

BossScorchion
- disabled debug messages (dark shamans Engage Reset)
- disabled debug messages (Fire Orbs Start Q, Loop, End)
- disabled debug messages (Temporal Instability)
- disabled debug messages (Fire Ward)

Cinematic ON
- enabling / disabling Isometric Camera disabled with bool "AlwaysFALSE" - this interfered with old cinematic dialogues

Void Entity
- Added chat related triggers

Note on Lag previously known to be caused by AI Heroes logic
- Now no lag spikes - issue was "closest unit function point leaks"

=================================================================================================================================================
Epic Quests 25.9.2025 - List of Actions:

Inventory systems
- EasyItemStacking system disabled - it interfered with DestroyerInventory system
>>> Note: may need to enable stacking from gameplay constants

Void Entity
- started adding some triggers

=================================================================================================================================================
Epic Quests 23.9.2025 - List of Actions:

Cinematic Trailer
- created script for creating cinematic teaser trailers
- played with command: " trailer1 "
- with snow: " trailer1snow "
- Using command:
--- disables/releases Isometric camera lock
--- disables AI heroes
--- Runs Cinematic ON trigger
RUN debug aidisablemainstates to disable Ai

AI Heroes lag NOTE
- Note: when multiple AI heroes spawned, fps dropped to 2 fps.
- There is definitely somethings very wrong there...

PDMS Periodic Damage added
- not configured yet / nothing using it atm

NOTE new lag:
- some system is causing periodic lag - PDMS?

A-B cam pan did not work

AI Heroes
- Will now start spawning only after Intro Cinematic

Imported Entropius model by Sarsaparilla
- to be used as Void Entity boss at Vanguard Vale

Started testing DestroyerEquipment custom definitions
- with Colossus loot

Arcing TT by Maker
- Modified to prevent seeing far away occurring floating texts
- added RGB
- DamageEngine, HealEngine, FloatingSpellEventText now use the modified ArcingText

=================================================================================================================================================
Epic Quests 22.9.2025 - List of Actions:

Destroyer Inventory & Equipment System
- testing again
- apparently previous lag / unit pathing errors were caused by some getWorldBounds / PlayableMapArea related functions?
- Works after these modifications DConfigurationArea:
--- boolean AutomaticallyAddHeroesToTheDEqSystem = FALSE (default TRUE)
--- boolean AutomaticallyAddHeroesToTheSystem = FALSE (default TRUE)

TasQuestBox
- Added
- Initial idea to use for quests, but probably too much rework to current Quest system?
- To be used for Zone descriptions etc.? / Info?
>>> If used for info/general/etc. then normal quest dialog could be changed to have Normal quests and daily quests separated?

Valeria
- Token of Love triggers fixing
- Lost Supplies triggers fixing
- Added patrol after Ranger Missing is completed
--- NOTE: Neutral passive cant Patrol because it will always return to its initial location - Either way need to utilize some PlayerX for the Valeria, so that she attacks hostile units...

ExMusic
- Preload function changed to similar as in ExSound (all music files preloaded and played as "sounds"
--- NOTE: Umm... now music files dont work at all - reverted to old style which still doesn't completely preload music files

ShowUnitLevel by Tasyen
- Added

Other minor fixes / terraning Vanguard Vale

=================================================================================================================================================
Epic Quests 21.9.2025 - List of Actions:

Valeria & Aradion & Nazgrek
- Created more voicelines
- Created 3 quests and related voicelines and dialogues for Aradion (wip)

TasInventoryEx
- Added "call TasInventoryEx_ReAddInventories(unit)" to CinematicOFF and Game Start triggers
--- This function needs to be called: after revive/reinc, unpause, channel ability with "disable other abilities", doom ability debuff, Probably for all skills/situations that silence inventories. Right after you unpause the unit tell the system to readd the inventories and items. Otherwise the unit can only fill the main inventory with items (no more additional inventories). - Tasyen

Stealth
- trying to fix spin attack animation (stuck animation when casting stealth when unit not moving)

=================================================================================================================================================
Epic Quests 20.9.2025 - List of Actions:

Valeria & Aradion related
- fixed some issues related to cameras, movements, etc.
- Added Token of Love, Lost Supplies quests to Valeria, some work still need to be done

Cinematic Store/Move units function
- Added pets (TamedUnits unitgroup)

TasInventoryEx
- under testing, issued found with items not being inserted into custom inventory, ...

Stealth
- Now should not break when directly behind the enemy even if close to enemy

Tiles
- Added some new tiles to create variation to zones

=================================================================================================================================================
Epic Quests 19.9.2025 - List of Actions:

Grum Bloodfang
- Fixed some quests related issues
- Drake attack can now occur in the middle of dialogue, and when occurs will interrupt it.

Cinematics
- Added triggers to store and restore player units locations and pet/companion locations
- If CinematicRestoreNazgrek = true -> moves Nazgrek to stored location after cinematic
- If CinematicRestoreZulkis = true -> moves Zulkis to stored location after cinematic
- Currently pet and companions will always be restored to their stored location before the cinematic

Valeria fight / negotiate dialog triggering
- continued editing
- Added more cinematic/dialogue movements/events

Ranger Missing
- added quest related triggers and dialogues

Creep Respawn system
- Added some fix to Creep Respawn trigger to respawn specific Player 19 units

Vanguard Vale
- some lite terraining to sketch the zone

Nazgrek
- Unit model updated once again; could use some torn / fur-like cloak to make it complete?

=================================================================================================================================================
Epic Quests 18.9.2025 - List of Actions:

Inventory system under testing: https://www.hiveworkshop.com/threads/a-modern-inventory-and-equipment-system-prototype.351433/
- Result: game break (maybe related to unit enters playable map area ? - search if there is such function inside jass scripts)
>>> Removed for now....

Updated Valeria, Aradion, Nazgrek dialogues

Mana Wraiths
- Fixed DamageEngine issue with all units being immune to physical dmg

Nazgrek
- Created more greet / farewell lines

Valeria fight / negotiate dialog triggering started (WIP)

=================================================================================================================================================
Epic Quests 17.9.2025 - List of Actions:

Lirael -> Valeria (new name)

Updated Valeria, Aradion, Nazgrek related dialogues

Updated (under testing) Easy Item Stack n Split v3

Mana Wraiths
- Now immune to physical dmg by using DamageEngine

=================================================================================================================================================
Epic Quests 16.9.2025 - List of Actions:

Vanguard Vale elves Storyline
- Drafted storyline, npcs, quests, locations for elf questlne

Imported new models:
- model for Wretched elf
- model for Aradion the Farseer
- model for Lirael Dawnwhisper

Draft for Quests/dialogs/... for:
- Aradion the Farseer
- Lirael Dawnwhisper
- Kaelthir

Added Wretched units

Aradion
- continued dialogs/first quest (WIP)

Mana wraiths
- Made attackable with spells and magic only by discarding "Ethereal" ability and instead use Hardened Skin and Elune's Grace

Kaelthir
- added dialogue and first quest (WIP)

Grum Bloodfang
- fixed issue with voicelines triggerent without player presence in the zone / near

=================================================================================================================================================
Epic Quests 15.9.2025 - List of Actions:

Mana Wraiths
- Added abilities Arcane Bolt, Shadowstep, Siphon Life and Mana

Intro Cinematic
- Switched "Intro Setup" trigger to be after "CINEMATIC ON" Trigger

Grum Bloodfang
- Created voicelines for Nazgrek
- Created more voicelines to Drake attack event

=================================================================================================================================================
Epic Quests 12.9.2025 - List of Actions:

Zones
- Changed Blizzard music functions to call ExMusic system external music files

HeroDeath Animation (WIP)
- Added to try remove hero dissipation animation

ExMusic
- added function to get current track name / index
- added in-game function to display current track name with command " /music current "
- added in-game function to play random music with command " /music random "

Intro Cinematic
- Trying to solve issues with grunts not moving

Mana Wraiths
- added "Ethereal" ability to make them only attackable with spells and magic and also to prevent Blood Splat visual effects for these

=================================================================================================================================================
Epic Quests 10.9.2025 - List of Actions:

Triggers
- Reorganized Utility & core, and main map system triggers to upper part of triggers (after Global variables and Init)
>>> Some systems might still be across the trigger folders, but main systems are now in upper part.


Kodo Beast Drums
- Imported empty KodoDrum1.wav and KodoDrum2.wav to bypass drum sounds (that could be heard with Salamanders....)

DestructibleRevival system
- Added to map with necessary Util systems
>>> Note: Need to configure

=================================================================================================================================================
Epic Quests 9.9.2025 - List of Actions:

Grum Bloodfang
- All voicelines now modified for ExSound -system

ExSound system
- Added all <CURRENT> voicelines to register paths
- removed automatic preload within the code itself, instead map will call preload function manually
- commented out (=disabled) fallback to constant duration if no sound and text is not provided, because sound and/or dialogtext should always be provided

ExMusic system
- removed automatic preload within the code itself, instead map will call preload function manually

PatrolSystem
- removed all debug calls
- Added option to choose what movestyle (order issue) patrol unit has; "move", "attack", "patrol", ...
- Updated all PatrolSystem related calls in WE side to take into account the new movestyle

TravelShip
- Enabled again

Quest updates twice when picking up all required items
- this might be because of EasyItemSystem
--- to prevent this - need to add EasyItem_SystemActive == false in conditions >> TEST

Mordrax
- fixed Reset trigger issue not working
- adjusted attacking flying height

=================================================================================================================================================
Epic Quests 8.9.2025 - List of Actions:

ExSound system
- Added fallback value to ExSoundDuration that will be based on the length of the ExSoundString (if provided), if ExSoundString == null, then use constant value fallback_duration (5s)
- added preload function
- added "takes string dialogtext" to play/playUnit/playPoint functions

Grum Bloodfang
- started doing ExSound -modification - WIP on "Quests of Grum"
- fixed some errors related to quest creation (used TriggerExecute instead of correct ConditionalTriggerExecute)
- Drake attack interval increased
- typo fixed in Whelps of Destruction
- Some other minor fixes to quests triggers

TravelShip
- Temporary disabled UnitAttach to travel ship and using Hide unit instead

Map Init
- Added Preload trigger on map start
- Game start and init related triggers need to be re-organized, its a slightly messy

=================================================================================================================================================
Epic Quests 7.9.2025 - List of Actions:

BOSS Mordrax
- Created WayPoints
- Added PatrolSystem triggers
- Added attacked/attacking start and reset related triggers

Creep Unit Assignment
- Added Mordrax to list
- Added PatrolSystem start trigger calls to relevant unit
>>> Note: one should also call QuestIcon systems for relevant units!

Whelps
- Edited item drop loot tables
- Added dragon related misc items

ExSound -system
- Created first version
- Added testing trigger "exsound test1" that can be triggered with command " exsound test1 " & " exsound test2 " - it should Play Nazgrek_0001 sound
- API:
    call ExSound_Register(key, path)
    call ExSound_RegisterSequence("Nazgrek_", 1, 50, "Pots\\Sound\\Dialogs\\")
    call ExSound_Play("Nazgrek_0001")
    call ExSound_PlayAtUnit("Nazgrek_0002", udg_Hero)
    call ExSound_PlayAtPoint("Nazgrek_0003", x, y)

    call ExSound_Stop()
    call ExSound_PlayAmbience(udg_ExSoundRegion, "ForestAmbience")
    call ExSound_StopAmbience(udg_ExSoundRegionn)

    duration of played sound can be get from variable: udg_ExSoundDuration

Unit Sounds Attacked/Attacking
- Salamander added

=================================================================================================================================================
Epic Quests 6.9.2025 - List of Actions:

Grum Bloodfang
- Drake attack trigger edited
- Updated quest related update quest triggers

ExMusic (external music system)
- Created and under testing

Item Drops
- Whelp Scales drop added
- Scale of Mordrax drop added
- temp Dragon egg drop added

Thornwoods / Emberpeak Highlands
- Slight terraining

Orc Spearthrower
- Added level 12 variant and changed these to Grum location to match zone level units

=================================================================================================================================================
Epic Quests 5.9.2025 - List of Actions:

Grum Bloodfang
- Created voicelines and audio files
- Note: Need to create small lines for Nazgrek
- Created dialog/quest related triggers

Travel system
- Added Cinematic mode for travel (test)
- Note: camera should be freely rotated during the travel
- Note: it should be possible to skip the travel by using ESC key?
>>>> This can be hard to implement, as we would need a way for the PatrolSystem unit to skip it's waypoint
>>>> Maybe can implement function into PatrolSystem with function like PatrolSystem\_SkipToWP takes integer index, etc....


=================================================================================================================================================
Epic Quests 4.9.2025 - List of Actions:

Travel system
- Edited TravelShipB Patrol waypoints / wait times / using PathStyle 0
- Created simple TravelShipB_MovementStart jass script (because of way too many regions, that are more easier to set in JASS vs. GUI...)
- Transport ship speed and turn rate reduced

- Added shipmaster[1] (MOKNATHA) - travel related triggers
- Added logic for when ship arrives at each dock
- Shipmaster (goblin) lines created and imported

Items
- Shovel fixed missing item attachment ability
- Note: looks like shit when attached to unit hand!

Boom Brothers Mine
- Fixed wrong point at AoE barrels of explosives damage at rocks1 & rocks2
- Goblins should return to their init location / area after they are turned back to Neutral Passive

Grum Bloodfang
- Started doing dialogs and quests
- Note: Unfinished Button Pressed in...
- Note: Unfinished DialogOver
- Note: Unfinished Quests

UnitAttch jass script added
- Utilized in TravelShip visualization of Hero being onboard the ship

=================================================================================================================================================
Epic Quests 3.9.2025 - List of Actions:

Imported:
- Potions - various shapes and colors by stan0033
- Shovel model Narberal Gamm (XGM Guru)
- Webbed victim by Zenonoth

ItemDropLocationUnits
- added trigger to drop any not Campaign class item immediately, Campaign class item will also be dropped from the unit after 5s wait (to prevent player misplacing items into ItemDropLocation unit's inventory)

Kribugs
- Added more debug commands to test special effect overhead on Kribugs

Zones
- Zone "entered" text was not shown for Twilight Grove and Serenaglade, because they had old LocalPlayer handle usage, but this was not anymore used thus no message was displayed

FindItemByKeyword
- Fixed wrong string parsing in the function
- Now works with any keyword e.g., "meat", "gnollhead"
- Unsure if this works when keywords is two words; e.g., "Angry Chicken"
- Renamed to "ItemSearch"
- Made as library with private functions and private global variables
- Function now to use: call ItemSearch_FindItemByKeyword(unit, string)

Travel system
- Started drafting this old system...
- Travel Ship Moknatha patrol system utilized to create movement between travel locations
- Added Shipmasters (goblins) on the map
- Added Flight point icons on map for current flight masters (Control Point Ally)

=================================================================================================================================================
Epic Quests 2.9.2025 - List of Actions:

Kribugs
- Added quests
- Made DialogButtons (global) as normal variables to be used
- IMPORTANT NOTE!: Utilize the same logic to other NPCS! - REMOVE THE UNNECESSARY UNIC SPECIFIC DIALOG BUTTON VARIABLES - THIS NEEDS SOME TIME EDITING...
- Added dialogs
- Added function inside Complete Quest 4 to loop-check hero's inventory and first item with the word "meat" will be set as QuestItemTemp item-type
--- Note: this would be better if this was a JASS Script and we pass string e.g., "meat" and the jass function will return back with Item-type
- Fixed wrong quest Discovered/create triggers
- Fixed wrong conditions for "Meat For the Ogre" quest completion dialog button visibility

- added debug command: " debug kribugs questmark " to test create normal quest exclamation mark
- added debug command: " debug change kribugs " to change the kribugs unit

- Test quest Meat For The Ogre - can it be re-done and re-completed?

FindItemByKeyword -JASS function created
- This can be utilized to check if UNIT has item in inventory with specific keyword like "meat"

DialogCamera
- Added IsCameraBlocked function (when destructibles in the way of camera)

ItemDropLocation
- Added debug functions to test how to drop items to its inventory
- Added Init 04b Players - 1s gametime set Player 1 friendly with spells with Player 17

Indicators
- Imported https://www.hiveworkshop.com/threads/target-and-circle-indicator-tc-vfx.349193/
- Imported https://www.hiveworkshop.com/threads/skill-indicator.357350/
- These can be used to indicate:
--- AoE / incoming damage
--- Objective location
--- Item drop location
--- Secret location
--- Quest / event location point of interest
--- etc.

Quest Icon system
- Edited Dummy Icon/marker function

Boom Brothers Mine
- removed range for leave region triggers (for now)
- Added Shredder units
--- Note: Edit the abilities to be unique to Shredder vs. now using Mad Blix abilities

Interface Dialog Sounds
- Added 0.1s wait before playing InterfaceSound

=================================================================================================================================================
Epic Quests 1.9.2025 - List of Actions:

DeatCamera
- Angle adjustd
- Rotating camera 30s --> change to 45s

Neutral Player (Player 17)
- Adjusted Player 1 to have friendly with spells towards Player 17
- This should have effect to be able to place items inside that player units inventory

Player Bounties
- Added player bounties for other players in addition of neutral hostile

ItemDropLocation -unit
- Adjusted model again

Moknatha Battle
- Fixed and edited ogre and orc attack waves triggers
- added craters with Ubersplats

Boom Brothers Mine
- Edited BoomMine AttackWave R7 trigger to have range check before turning the hostile goblins to Neutral Passive

DialogButtons (global)
- Testing using global DialogButton_XXX variables instead of unit specific dialog button variables for KRIBUGS

Moknatha Craters
- Added
- Note: not working / visible

Moknatha Catapults
- make attack speed very slow
- make damage very high - almost instant death if hit?

Zones:
- Note: Serenaglade entered text not working
- Note: Twilight Gtove entered text not working
- Note: see other zones e.g., Riverbane, Sirensong that work

=================================================================================================================================================
Epic Quests 31.8.2025 - List of Actions:

Dialog Camera
- Added NearZ
- Added default cam time, and set to 0 instead of 0.5

Boom Brothers Mine
- more terraining

See more notes at To-Do app....


=================================================================================================================================================
Epic Quests 29.8.2025 - List of Actions:

Sounds
- Imported many Ambient, Interface related sounds
--- To be used for many events player does (like selecting unit) and also ambient sounds for dungeons, lakes, etc.

Dialogamera
- Modified
- Testing with Kribugs
- OutcastJinzun settings may be now wrong...

Boom Brothers Mine
- more terraining
- triggering events

Ambient sounds
- Testing ambient sounds for Zones
--- Note: Need a way to remove the ambient sound from zone that the Player no longer is in / switched to other zone

Interface sounds
- Started creating interface sounds, e.g., levelup, dialog button pressing

NOTE: Test checking how to use local audio files for WE / WC3!

=================================================================================================================================================
Epic Quests 27.8.2025 - List of Actions:

OutcastJinzun
- Camera distance and angle modified
>>> Result: BAD
>>> Camera position seems like its off many units, why?
>>> What would be best all-time use generic camera parameters for dialog NPCs? Note that the location may sometimes be more smaller and could have doodads etc blocking the view

Kribugs
- Deleted IsUnitMoving condition from "Quests of Kribugs" initial check

DeathCamera
- Modified angle/distance etc.

Boom Brothers Mine
- Added draft events for:
--- exploding rocks
--- attacking units (note: Event triggers many times - it should have timer e.g. 360s etc. - also the spawned units should be removed or something and/or not to spawn more units if they are still alive?

=================================================================================================================================================
Epic Quests 26.8.2025 -2 - List of Actions:

PatrolSystem
- Fixed patrol unit not stopping when damaged or attacked or paused

DialogCamera (NEW)
- Added function to use generic DialogCamera that should make dialog cinematic cameras more easy
- NOTE: DialogCamera didn't work - Reason: no camera settings was applied >> DialogNPC was = No unit

Kribugs
- Movement speed increased from 50 to 140
- Added 3 quests
- Added dialog system
- A way to "trade"

Note:
- Something might have gone wrong with BoomBrother triggers - because falsely editing them instead of Kribugs triggers

Outcast Jinzun
- Sounds when issued order "move" added additional conditions to consider only orders o Outcast Jinzun

Raining
- Added FX_Ripples -doodads that can be used with Play Animation Stand - 100 and Death
- These can be preplaced or placed via Special Effect (TBD)

Warlock Blood Pact
- Heal Engine text reads funnily when unit gets Blood Pact aura
---- Is there way to prevent text for this?

Curse of Agony / garrote / and other similar abilities based of "Parasite" will not work when the unit is close to death
- Add triggered damage to kill the unit with DamageEngine? Maybe not...
---- Stacking type of the ability to: "Kill Unit" - TEST

NOTES===
- Camera for Jinzun too close, maybe set distance to 1000?
- Now Jinzun seems to stay and not wander during PatrolSystem_Pause
- Selecting Kribugs did not start anything
- DeathCamera to be more further distance (maybe 1400) + angle can be more +30? Maybe 315?

=================================================================================================================================================
Epic Quests 26.8.2025 - List of Actions:

Outcast Jinzun
- Added PatrolSystem call
- Removed old movement trigger
- NOTE: Sounds triggers does work poorly
-----> Need to add condition "issued order is move" to the sound trigger
- NOTE: Was not properly paused when starting to talk to Jinzun

Kribugs
- Added as Quest Neutral folder
- Added PatrolSystem call
- Removed old movement trigger

### Notes on Patrol System:
- Tested with multiple units, seems to work fine
- unit is not stopped when it is attacked or damaged!


Death Camera
- Works poorly, should disable player control (see in Cinematics - disable control for Player)
- Camera is off compared to that it should be hovering near the dead player unit

=================================================================================================================================================
Epic Quests 25.8.2025 - List of Actions:

Patrol System
- Modified the script
--- NOTE 1: Now it works like it should; the unit can be paused, and will continue where it was going
>>> To be teste with multiple settings and multiple units


=================================================================================================================================================
Epic Quests 23.8.2025 - List of Actions:

Patrol System
- Modified the script
--- NOTE 1: Pause didnt work + no debug msg
--- NOTE 2: Stop didnt work - debug msg came
--- NOTE 3: unit is still going to some nonsense location
--- NOTE 4: Saved WP that is debug messaged from system itself matches with the waypoint location debug msg in GUI trigger

=================================================================================================================================================
Epic Quests 22.8.2025 - List of Actions:

Patrol System
- Added patrol / waypoint system that can be used to set NPC to walk certain path with settings like; how long the NPC waits at each waypoint etc.
--- NOTE: Need to test the system with multiple Patrol NPCs and different settings!
--- NOTE 2: there was issue with WayPoints! (not set correctly?)
--- NOTE 3: debugging the waypoints; waypoints are set correctly, however something wrong with the JASS system itself, as it seems that the NPC is walking towards map center 0.0, 0.0
--- NOTE 4: New version in VSCode to be transferred to World Editor and to be tested....

Boom Brothers Mine
- Continued terrain
- Added Pathing Blockers (Both air & ground)
- Note: next time; lower the torch "lights"

=================================================================================================================================================
Epic Quests 15.8.2025 - List of Actions:

Creep Respawn System - Creep Unit Assignment
- Added JASS script that will be called from Creep Respawn -trigger. This script will assign global unit variable to the last created unit if unit-type matches.
--- The JASS script will be faster to update vs. using the huge and in the end messy custom script wall of text within the respawn trigger itself.

SteamBreath
- Added functions to remove the steam breath effect from dying unit using;
--- function SteamBreath_Death
--- function RemoveSteamEffectUnit
--- function HasSteamEffect

Spirit Shards
- Modified "Revive" ability item ability to false and changed tooltip text to "Revive"
- Changed "Deceased" unit back to Hover
- Changed height from 100 to 75
- Changed scale to 1.5 from 1.2

Revival
- Changed AI hero revival time from 20s to 60s
- Changed player Hero revival time from 20s to 30s
- Added circling camera to pan slowly around the died player hero if:
--- Both Nazgrek and Zulkis are dead
--- Nazgrek dies and Zulkis is not yet playable
- Note: The camera settings need to go back to the normal used by the player when reviving
- Note: The camera should be locked and player should not be able to move the camera during the Death Camera time

Zone Entering
- Changed location of Turn off this trigger, might not affect the trigger firing 2nd time for other unit - needs thinking

Quest Icon System
- modified Boomsite Compliance Ready trigger - see if yellow question mark now for BoomBrothers
- Added dummy quest icon creation / removal to differ from the real quest icon register system:
--- call CreateDummyQuestIcon(someUnit, "normal", 2)
--- call RemoveDummyQuestIcon(someUnit)

Quest Mandatory Training
- Goblin Miners and BoomBrothers follow logic improved; Miners should only follow BoomBrothers without any distance check and BoomBrothers should only follow Nazgrek is the distance is less than 1000, forcing player to "escort" the BoomBrothers
- Mad Blix temp unit spawn location changed closer to entrance (fitting / collision reasons)
- Removed generic timer and replaced with Enters Region to remove BossMadBlixTemp unit

Quest Boom Will Be Back
- EDITED: Cameras dont pan to right location (at least in Quests of Boom Brothers, individual event after pressing Dialog button might need adjustment OR/AND move the Boom Brothers to correct location after turrets are destroyed,...
- NOTE: BoomBrothers should move to BoomBrotherWP0XXX and have new dummy quest available after the turrets / enemies are dead
- EDITED: Quest mark should be yellow question (ready to turn in / quest state 5) when Mad Blix is defeated
- EDITED: After completing the quest - dialog button Boom Will Be Back (completion) is created, when it should not be visible anymore

Boom Brothers Mine Cam
- Camera should change for the first entering OR leaving PLAYER 1 unit
--- Player 2 (AI Heroes) cant make this occur
--- THINK: what about if the other PLAYER 1 hero is outside the dungeon and we click/ change to him? The Camera should change back to normal and when we change to the unit that is inside the dungeon the Camera should change to Dungeon Camera
>>>> This kind of action should also make RUN DNC OUTDOORS / INDOORS AND FOGS etc. depending on where the outside HERO is and where inside dungeon HERO is
>>>>>>>>

=================================================================================================================================================
Epic Quests 14.8.2025 - List of Actions:

Item abilities:
- If the ability is set to "Item ability" true; then its tooltips will be hidden
>>> Item ability must be set to false to modify the tooltip that will be shown when ability is cast

Spirit Shards
- Modified "Revive" ability item ability to false and changed tooltip text to "Revive"
- Changed "Deceased" unit from Hover unit to Flying unit
- Changed height from 50 to 100
>>> Note: this looked worse than original Hover + 50 Height setting and clickability did not improve!

Note on graveyard revive:
- Should the time for revival be something like 60s? or be 30s but have option to "release" the corpse
>>> This would add time to decide whether to use Spirit shard or if AI Hero is close and can resurrect
>>> AI heroes to have longer respawn, e.g., 60-120s time

Quest Icon troubleshooting
- There was unnecessary / improper use of functions like RemoveQuest / UpdateNPC in wrong places;
- Quest Icon Refresh had RemoveQuest, which does delete the quest with ID XXX, so if we want to update quest's status to 5 etc. we cant remove the quest
>>> Use: call QuestIcon\_RegisterQuest -function with same questID to refresh the quest's state.

Creep Unit Assignments -trigger created
- Started mapping units to proper unit variables when they are respawned (e.g., Quest givers, important npcs which Unit variable must be set)
>>> Note: Made first trigger but realized that the Creep Respawn trigger uses local variables that are important to respawn / variable re-assignment and so thus transferred unit assignments into "Creep Respawn" trigger

Debug DayNight
- using "debug daynight" command: it returns FALSE (NIGHT) when it is DAY (6:45) and it should be TRUE
>>> THIS CAN AFFECT CAMPING FOR AI HEROES ETC MANY OTHER TRIGGERS which use Boolean DNE\_IsDay

Zone DayNight
- event seems to work now and will change fog to night setting or day setting when night or day event is fired

Zone Entering texts
- NOTE: Discovered zone + followed by Entered zone when coming with Zulkis after Nazgrek, then it wont refire again
>>> Edit: this only seemed to occur atleast for Riverbane, but e.g. Siresong worked properly

Quest Explosive Crisis
- NOTE: Quest Update Ready to turn in only triggered when Nazgrek had more than 6 Barrels in inventory,
- it did not set the Question mark to yellow (State 5)
- it also trigger 2 times
- Quest Requirement was not completed - but is this wanted (if the player is attacked and thus barrels might be removed, the quest requirement should be set back to discovered)

Quest Boomsite Compliance
- NOTE: Quest mark for Boom Brothers did not change to yellow question mark (QuestState 5)
- NOTE: Quest mark of AtexBlix was not removed
>>> Something probably not correct in QuestIcon System jass

Quest More Hazard Mitigation
- NOTE:Quest is updated twice when Quest item is acquired, is still related to Item Stack system?

Quest Mandatory Training
- NOTE: Goblin miners are not following BoomBrothers / tried to follow but stopped???
>>> They followed BoomBRothers when they were close to BoomBrothers - some InRange typish check logic is now wrong and needs modification
- Note: Mad Blix Temp cant get through the mine to the entrance, too big collision - Ghost visible did not seem to work - change spawn location more closer to entrance
- Note: has to remove the Mad Blix after some time / entering region, because now using generic timer for unit - causes him to die in tunnel which looks poor

Quest Boom Will Be Back
- NOTE: Cameras dont pan to right location
- NOTE: BoomBrothers should move to BoomBrotherWP0XXX and have new dummy quest available after the turrets / enemies are dead
- NOTE: Quest mark should be yellow question (ready to turn in / quest state 5) when Mad Blix is defeated
- NOTE: After completing the quest - dialog button Boom Will Be Back (completion) is created, when it should not be visible anymore

SteamBreath
- NOTE: SteamBreath stuck on even when its not raining!
- NOTE: SteamBreath remains on unit that is dead, it should be removed when the unit dies!

Zone/Dungeon - Boom Mine
- NOTE: No trigger to trigger Sirensong Zone after leaving the Mine! Stuck on Boom Mine fog / etc setting
- NOTE: Add pan camera function

=== LAG PREVENTION NOTE:
use command "debug aidisablemainstates" to prevent AI Hero system causing lag
>>> Testing for longer time the map without AI - theres no lag / spikes - so look for AI system to remove Leaks / etc.

=================================================================================================================================================
Epic Quests 13.8.2025 - List of Actions:

Modular Quests:
- Empty space \n\n added to proper space in Quest Discovered trigger
- Added "- " to all Quest Requirements

Quest Icon system / Quests
- After completing "Explosive Crisis":
--> Quest Grey mark was removed - OK
--> No new "dummy" quest icon marks for Atex Blix and Boom Brothers were created!
--> After getting Boom Compliance quest (CREATE) - both Atex Blix and Boom Brothers have Grey Quest mark (normal quest) - is it wanted?
- Also new quest markers for these quest should be updated when QUEST 1Q1C etc is run at the end (after all the chat)
>>> EDIT: Reason was; using QuestState that was set to 4 (for previous quest), dummy quest icon needs QuestState = 2 - corrected and also placed "New Quest" to place after dialogs (vs. not immediately after completing the quest)

Quest Explosive Crisis
- Added turn on Quest Update and turn off Quest Update calls
>>> This Quest Ready to turn in did not seem to work...

Boomsite Compliance
- Remove quest mark from Atex Blix when all wood collected
>>> EDITED and added Quest Ready trigger that will be run during AtexBlix dialog if all 10 woods are accepted
- Change BoomBrothers quest icon "Ready to turn in" when all wood collected
>>> EDITED and added Quest Ready trigger that will be run during AtexBlix dialog if all 10 woods are accepted
>>> When Quest Update ready to turn in, BoomBrothers dont have any Yellow question mark! 
>>>>>> Reason: Call QuestIcon\_RemoveQuest(unit u, integer questID) was called, this will delete the Quest from NPC, which should not be used but only when completing the quest!

Abilities:
- NOTE: Texts for many abilities wrong e.g., Healing Wave does not match what it heals (base heal amount)

NIGH / DAY + Zones:
- When NighEvent or DayEVent triggers - Run some zone trigger that will check what zone player is in - then run that zones Zone specific trigger
---> might need some array system to run the proper zone! + store where player currently is!
>>> EDITED: added DayNightEvent to run Zone trigger based on what the current Zone/Dungeon the player is in
>>>>> Does not 1st time work, 2nd time works, 3rd time Zone is stuck in NightTime fog setting

Zones:
- Added zoneCurrent and ZoneLast functionalities; Zone trigger must trigger only once, but work other time when coming from other zone
>>> Logic:
>>>>>> First hero to enter a specific zone triggers it.
>>>>>>Any other hero entering that same zone right after won’t trigger it again.
>>>>>>If you move to another zone, that zone’s trigger still works normally.
- Needs to be tested, maybe the setup now is too complicated vs. what the function needed is....

> ZoneCurrent/ZoneLast logic did not work, other unit entering the region also triggered the trigger
>>> EDITED; Streamlined and made the logic much more simpler....

Spirit Shards
- Wrong tooltip / shows Storm Bolt (Level 1) when it should show "Revive Hero" / "Spirit Shard" / "Resurrect"
- Maybe should resurrect the fallen Hero at the location of the resurrecting hero
- Hard to click the "!" unit - maybe make it hover / fly +200 etc. and test if its easier to click?

=================================================================================================================================================
Epic Quests 11.8.2025 - List of Actions:

Boom Brothers
- EDITED: prevent "normal talk" when Quest Boom Will Be Back is discovered
- EDITED: did not stop following after completing quest Mandatory Training
- EDITED: Boom Will Be Back could not be completed after Defeating Mad Blix -> no dialog button to complete

AtexBlix
- EDITED: did not fit through mine pathing blockers to come at the entrance - need to at abilty Ghost (visible) to him

Modular quests:
- EDITED: Note that there should be empty space with "|n|n" after Quest Discovered + Quest TItle + (here) + Quest Requirement + n....
- Note: QuestGiverUnit should be stored per QuestID related to the quest to QuestData hashtable
--- This is stored into questData already, but not utilized properly, >> now should be used
- EDITED: Modified quest create / quest complete triggers; set quest that is being completed QuestState to 4 (complete) - then create new dummy quest with id 9990 to create visual effect of new Quest available (yellow exclamation mark)
- EDITED: Save hashtable trigger - separated from Quest Create triggers
- EDITED: QuestGiverUnit[QuestID / QuestID_Temp] created + now using QuestGiverUnitTemp to initially set the Quest Giver unit that will be stored into QuestGiverUnit[QuestID]

Quest Explosive Crisis
- Added Quest Update trigger to update "Ready to turn in" state for Boom Brothers - needs testing that all relevant Call QuestIcon_xxx are used
>>> TEST RESULT: OK

Terrain:
- Minor continue of Boom Brother mine (almost ready Major terrain parts)

=================================================================================================================================================
Epic Quests 10.8.2025 - List of Actions:

QUEST ICON SYSTEM
- reworked the system
- related quest system triggers call scripts updated to match the updated quest icon system function calls
- Testing;
>> Red (Grey) Exclamation mark on BoomBrothers Init Icon
>>>>> Also this mark came when Quest was COMPLETED!
>>>>>> EDITED - should be now fixed - State was set to 1 (unavailable) instead of 2 (available)
>> Grey question mark when quest is accepted (CREATED) >> OK
>> Note: Set quest requirement complete when you have requirement complete and then set the QuestIcon to Yellow Question mark (Ready to turn in)
>> Note: Should the MapIcon be Question mark when quest is "in Progress?"

>> Note: after edits, now yellow exclamation mark when it should be Grey Question mark when Quest is CREATED! - Previosly it worked, it seems that priority system is taking affect???
>> note: "Debug quest reward item" -message was shown when quest is CREATED! >> REMOVED TEXT

Modular quests:
- Note that there should be empty space with "|n|n" after Quest Discovered + Quest TItle + (here) + Quest Requirement + n....

AtexBlix
- did not fit through mine pathing blockers to come at the entrance - need to at abilty Ghost (visible) to him

Boom Brothers
- prevent "normal talk" when Quest Boom Will Be Back is discovered
- did not stop following after completing quest Mandatory Training
- Boom Will Be Back could not be completed after Defeating Mad Blix -> no dialog button to complete

Bridges:
- Added bridge008 activate/deactivate triggers in Sirensong
- Switched entering regions Event logic, should be now correct? >>> Yes.
- Note# Need to add check target of issue of the unit to move the units correctly near the bridge (especially when the pathing blockers on bridge entering sides are active)
- Make the related triggers (e.g. creating side pathing blockers) more easy using "For Each Loops"

Terrain:
- Minor continue of Boom Brother mine

Lag note:
- Without disabling ai with "debug aidisablemainstates" - things get pretty stuttering and laggy at some point
- However, when disabling ai with above command, things settle and fps kind of stabilizes, there are some spikes still

=================================================================================================================================================
Epic Quests 9.8.2025 - List of Actions:

QUEST ICON SYSTEM
- working on making the system working and without compiler errors
- Testing results:
--- Init trigger - quest icon/marker on map works
--- On Quest Discover - quest icon/marker correctly changed - except - on map the icon is yellow Turn In question mark (is it wanted or more preferable to have no icon on map when quest is in-progress?
--- After completing the quest;
>>>>> Quest Turnin map icon was not removed
>>>>> Quest Exclamination mark was not created on the BoomBrothers or on the map
>>>>>>>>>> Probably trigger related stuff..
>>>>> But then when getting NEW quest - correctly made Question mark on the Unit/map

>>> EDITED by setting QuestState to 2 after quest completion and when no quests anymore to 4, now test!

MODULAR QUESTS
- Quest System Complete Rewards added - all rewards related are now also generic, which is run from the unique Quest XXX Completed trigger

=================================================================================================================================================
Epic Quests 8.8.2025 - List of Actions:

MODULAR QUESTS
- added QuestType and QuestState and QuestGiverUnit
- Load Hashtable, Complete, Discover related Generic functions made into separate triggers, which are called by the unique Quest XXX Discover/Quest XXX Completed triggers
>>> things that don't change quest by quest, this way easier to manage if changes to design of the Hashtables / etc. error finding.

QUEST ICON SYSTEM added
- modular quests will have calls to this system
- multiple Quest Icon MAP related errors; can not be used with Hashtables?
- see if the code can be adjusted, notice that the latest script is not in the map!

=================================================================================================================================================
Epic Quests 6.8.2025 - List of Actions:

MODULAR QUESTS
- Modified strings for linebreaks "\n"
- Added generic kill and gather arrays + texts if using those (Boolean Active = TRUE)

XP:
- Modified Cinematic OFF trigger to prevent enabling XP gain for other units than Nazgrek and Zulkis (e.g., bag, companiondummy unit, etc.)

=================================================================================================================================================
Epic Quests 5.8.2025 - List of Actions:

MODULAR QUEST REWARDS:
- Quest reward item name get function created
- Finalized rewards texts
- added Quest Icon Path array string
- Now should be fully usable for new (+ re-edit older quests) quests, there is still some manual work, but now should be less work involved...

- Issues found so far:
--- Quest discovered Text reads QUEST|n|n|n|n
>>> Edited; Should now work, as reading from hashtable was set too early before creating the quest, meaning nothing was really stored inside the quest

--- Quest requirement text does not need additional "-" sign, Quest log will add it automatically, however Quest Display text wont have it..., so ...
>> Edited

--- Quest Completed text reads: Rewards|nXP: 500|nGold: 500 - however in Message log it looks properly
>> EDITED - TEST!

--- QUEST COMPLETED|nBoomsite Compliance (in message log it reads correctly...)
>> EDITED - TEST!

- Notes:
--- After Boomsite Compliance - set Boom Brothers to go "inside" the mine and then return (set collision to 0 / add ghost visible ability and then remove it
--- After Dust Migation - set AtexBlix to go "inside" the mine and then return (set collision to 0 / add ghost visible ability and then remove it
>> EDITED and added

- Boom Brothers if killed, should then respawn and continue following Player
- Goblin miners if killed, should then respawn at Boom Brothers and continue following player (stop respawn/follow) and remove units when quest completed
----- NOT ADDED LOGIC YET!

- If Nazgrek is further than 1000-2000 yards, stop follow for goblin miners and Boom Brothers
>> EDITED - TEST!

- Add Grenade ability to Boom Brothers and other gadgets, but not normal attack
- will assist player if player units are attacked (= make them as companions player units, but not add into companion group)
>> EDITED - TEST!

- maybe goblin miners should follow Boom Brothers instead of player
>> EDITED - TEST!

- when player selects Boom Brothers;
--- camera must pan to BOom Brothers
--- dialog button to command Hold position
--- dialog button to follow
------ ADDED: logic created inside "Button Pressed..." - TEST

- When AT KOBOLD MINE; Camera looks weird, because panned to Boom Brothers but angle/etc. camera settings make camera go underground
>> EDITED - TEST!

- Returning back to Boom Brother mine did not trigger
--- Issue with CV not set to BoomBrothers -unit -- probably
>> EDITED - TEST!

=================================================================================================================================================
Epic Quests 2.8.2025 - List of Actions:

MODULAR QUEST REWARDS:
- Started using strings also during QUEST ID creation -
---> Make changes to Boom Brother quests so that they follow the template (there will be some work.....)
- Rewards:
--- Added Arena Marks as option for reward
--- Added Item-type as option for reward
------ Note: Need a way to get a name of Item-Type, so less manual work. ELSE NEED TO WRITE DOWN THE NAME OF THE ITEM (but it could be useful)
--- Rewards Texts still under work in Quest System Create and all the QUEST TEMPLATES
--- Note#: RewardsText may look funny now if there are no e.g., Gold reward with those "| " lines
--- Note#: RewardsText to be separate for QUEST DISCOVERED and for inside the QUEST DESCRIPTION!
--- NOTE#:  local item i = CreateItem(udg_QuestRewardItem[QuestID],0,0) does not work as locals are only supported at the top of the function!

=================================================================================================================================================
Epic Quests 1.8.2025 - List of Actions:

Lag testing
--- LAG severly got less bad when disabling AI using "debug aidisablemainstates"
------ Still some lag spikes after this, probably Steam Breath affects
------ Try adding debug disable SteamBreath / Thunderstorm

MODULAR QUEST REWARDS:
--> RESULT: Seems to work fine other than text rows needs some editing.
- EXTRA TESTS: Try discovering QUESTS in random order then complete them in random order --> Verify that Player is receiving correct REWARDS related to the quest - to see that QUEST ID / HASHtable is working

---> See if you could get less re-writing of STRINGS, by possible storing string values into QuestID and retrieve them through Hashtable!

=================================================================================================================================================
Epic Quests 31.7.2025 - List of Actions:

Lag checking:
- When checking memory used by Warcraft III.exe, it keeps incrementing where rabidly, over 4- up to 5GB RAM

- To be tested:
---- Disable UnitHider again
---- Disable New added Heal Engine - this could be source of new lag - despite the effort cleaning older triggers from memory leaks...
---- SteamBreath / Rain / Thunderstorm causing laggyness?

AI
--- Added command "debug aidisablemainstates" - that will disable AI mainstates AND prevent new AI Hero Spawn

Without AI and UnitHider systems, there seems to be lingering lag spikes;
--- Try disable Heal Engine and see how it works then

BUT RESULT: >>>>>> NO LAG
--- LAG Causer either: AI system related triggers or AND UnitHider system
---

#Note regarding LAG:
--- Memory keeps increasing steadily, but FPS remains OK (this might still be ok, as map has lots of things going on the background (item spawns, etc.)

Quest System
--- Modification to make modular quest rewards / texts system
--- Problems with Hashtable / arrays to fetch proper QuestIDs - WIP!
--- There needs to be way to check not to run QUEST ID etc related generation when QUEST DISCOVERED / QUEST COMPLETED ARE RUN
--- Quest description text didnt work as planned: description of the text was old and Rewads only text without gold /XP ----> Reason: Create trigger has old stuff, latest ones are inthe Quest System trigger
--- Now done for quests QuestExplosiveCrisis & BoomsiteCompliance
------> To be tested

-Continued Boom Brother Mine terraining


Quest Mandatory Training
- Wrong quest More Hazard Trainign was discovered!
- Goblins dont follow Nazgrek
->> Should be NOW fixed.

=================================================================================================================================================
Epic Quests 30.7.2025 - List of Actions:

AI triggers added/modified:
- New "Horde NPC Inventory State XXX"
--- will trigger when AI hero loses/acquires/uses item and then logic is made whether to go buy new item(s) or go sell item(s)
--- Logic transferred from MAIN STATE trigger
- New "Horde NPC Buy Items Q XXX"
--- Logic transferred from MAIN STATE -trigger "ITEMS BOUGHT"
- New "Horde NPC Sell Items Q XXX" trigger
--- Logic transferred from MAIN STATE -trigger "ITEMS SOLD"
- New "Horde NPC Camp Night Time XXX" -trigger - where actually start AI camping when night starts (vs. not check periodically is it night)
--- previous camp trigger name changed to "Horde NPC Camp Night Time Q XXX"
- These changes made to Rogue, Warlock, Warrior

- Started thinking and drafting "Quest Rewards" template that is to be used in every quest related XP / Gold / other rewards

=================================================================================================================================================
Epic Quests 29.7.2025 - List of Actions:

- Heal Engine 1.0.4 by Marchombre
--- System added to the map

- NPC AI Heroes:
--- CampFire position memory leaks fixed
--- Shop BUY - multiple position memory leaks fixed - Note: Can there be conflict using same NPC_VarPointX for each AI Hero MAIN STATE triggers?
--- Note: AI logic system can be the cause of lags / memory leaks staggering up

- Experience / Rested experience
--- Disabled: Experience Rested Unit Dies
--- Disabled: Experience Rested System Init
--- Cause: XP floating text comes 2 times or more
--- Created Experience Rested Unit Dies Test for testing XP floating text

=================================================================================================================================================
Epic Quests 28.7.2025 - List of Actions:

- Trying to fix leaks:
--- SteamBreath edited -> Script combined into one single script instead of "create" & "destroy"
--- FrostbiteSystem edited
--- Item Remove trigger edited
--- Destroy Crystals Limit trigger edited
--- Destroy Ore Limits trigger edited
--- Bag Follow trigger edited
--- HeroDeathRessurect AI Hero Reviver + Loop triggers disabled as they could be worked more + they are not working currently + possible causers of lag
--- Notes: Gar & Gor movement triggers are shit, poor / no conditions
--- Notes: AI hero states can cause lag, especially if they get stuck repeat on some actions like warrior's buy
--- Notes: RAGE ENERGY SYSTEM could cause lags - especially if the unit tries to keep using item, but its denied
--- Fog Fade system (The_Flood's Fog System) - could it cause lag?
--- Disabled Wandering Hostile NPCs triggers - these should be checked/re-edited to be more fine adjusted + check no leaks
--- ... lots of more triggers to check....

=================================================================================================================================================
Epic Quests 27.7.2025 - List of Actions:

- Cinematic Player (Player 22 Snow) now treated as ally by all players (previously was neutral and was attacked during a cinematic cutscene)
--- Problem with this version is; Player 22 or vise versa could go assist others which can break the immersion

- AtexBlix and BoomBrothers quest / dungeon continue

=================================================================================================================================================
Epic Quests 26.7.2025 - List of Actions:

- AtexBlix
--- Fixing dialog

- Boom Brothers Mine
--- Terraining / doodads

- UnitHider; now re-enabled - cause of lag must be found from other periodic triggers/newer JASS scripts (like Frostbite system / etc.)

=================================================================================================================================================
Epic Quests 25.7.2025 - List of Actions:

Create neutral sea life creatues (crab, turtle, ...) with proper levels
--- Created 10, 12, 14 level Spider Crabs
--- Created 10, 15, 14 level Sea Turtles + 16 level Azuron - sea turtle miniboss
--- Spider Crab Shorecrawler, Sea Turtle (lvl 10) + Giant Sea Turtle (lvl 15) added Neutral unit trigger

- AtexBlix
--- Clicking Blix before his quests will result in just Blix turning to Nazgrek, and no dialog / etc.
--- need to add normal greets/ etc?, or just can be talked when: 1st quest complete, 2nd quest discovered

- Sounds
--- Finalized adding seaturtle, Firefly (Moth), crab sound files (attacked/attacking / death)

- Sky
--- SkyHellish + SkyDungeon removed (related triggers + model files)

DNC
- added String-type condition check to not run the trigger, if its setting is already run before
- added DNC_OutdoorsRed

Zones:
--- Combined Discovered and normal Zone triggers into one for more clearer structure/readability + less same kind of triggers...
--- Added some new zones to Sirensong, Verdant Plains

Boom Brothers / Atex Blix:
- Continued with more quests / voicelines
- Created Boom Brothers Mine -dungeon - not finished yet

=================================================================================================================================================
Epic Quests 22.7.2025 - List of Actions:

- Fixed issues related to AtexBlix / BoomBrothers quests/events - not finished yet...
--- Note 6 fixed
--- Note 2, 3, 6 could be fixed now - cause was DialogSkipped was set to TRUE, causing the triggers not to continue... Now each DialogOver trigger contains DialogSkipped = False at the end
--- Note 4; created Atex wood inspection, could be improved though
----- Need to remove completion at Boom Brothers for these quests (Note 5 related)
--- More Hazard Mitigation quest created; could need some more work with lines, etc. way of handling the quest

=================================================================================================================================================
Epic Quests 21.7.2025 - List of Actions:

- Boom Brothers / "AtexBlix" quests continued working
--- Note #1: All quests available at dialog - should be 1 at a time, check conditions in trigger "Create BoomBrotherDialog01"
--- Note #2: Completing Explosive Crisis results in new camera angle, but nothing happens after that and stuck in cinematic mode, it could however be skipped and then Explosive Crisis will be completed
--- Note #3: Nothing happens when clicking Boomsite Compliance, but using ESC key to skip, then the quest is discovered
--- Note #4: add return / click trigger to AtexBlix after quest is discovered
--- Note #5: quest will be completed at AtexBlix, not BoomBrothers
--- Note #6: same thing when completing BoomSite compliance, skipping works, but no dialogue before that
--- Note #7: Whoa whoa whoa -line only should have one "whoah" for AtexBlix
- Added triggers for attacked/attacking sounds for Tigers, panthers, lynx, stags/deers
- Skybox testing;
--- SkyDungeon edited now as static
--- SkyHellish red and animated
--- Notes: Sky sphre looks shit, and also sometimes looks black???/
--- SkyDungeon sky crashed game, could be just Blizzard bug, but also could be model issus / corrupt of deleting Global Sequence / animation...

=================================================================================================================================================
Epic Quests 20.7.2025 - List of Actions:

- Fixed Boom Brothers moving / couldn't talk to him bug
- Added "Explosive Risk Assessor Blix" with quest follow ups for Boom Brothers
--- Voicelines + voice files
--- Triggers; Buttons pressed / dialogues / quest creation
- Note 1#: Cannot complete quest with 6 barrels in inventory, just says the lines when not all items in inventory
- Note 2#: if not taken any quests, there are no "NORMAL GREET" -lines - should there be?

- Skybox testing:
--- Sky is animated; remove animation for SkyDungeon
--- Sky (RED) can be animated, but requires testing

- Sirensong; continued terraining

- NPCs;
--- Tigers with proper levels
--- Panthers with proper levels
--- Raptors with proper levels

- Sounds
--- Added raptor, tiger, seaturtle, nagaFemale, deer/elk, Firefly, crab sound files (attacked/attacking / death)
--- abilities; could create new variations to Dash/Shred/RIP etc.

- TO BE Removed 2nd player / GetLocalPlayer features --> 2-player playable map feature discarded as too much work would be involved - Zul'kis will remain as 2nd playable hero for Player 1
-- TO BE Edited following associated triggers/functions/configurations:
--- XXX

=================================================================================================================================================
Epic Quests 19.7.2025 - List of Actions:
- Testing skyboxes (see previous notes)
--- Note: Added skyboxes dont stretch, and are displayed like normal models, it can be seen around the camera, --> not looking great!
--- Modified to Zones / DNCs / Entering/leaving Gnoll Hideout
- Fixed Boomer Brothers dialog if/elses + now correct quest should be discovered
- Added random movement to Boom Brothers;
--- Bug on; wait for issue order stop is not working, the Boomer is stuck on "Moving"
--- See if it could be simplified more + usable for other NPCs in the map
--- Safety-mechanism should be added in case the NPC gets stuck for any reason (other unit blocking, etc.) --> If not using "current order not equal smart / or move...", maybe it will work
- Add "Unstable explosives" buff to unit carrying 1 or more "Barrel of Explosives" -> When carrying Barrel of Explosives, there is 25 % chance for them to explode, greatly damaging the carrier!
- Camera lock bugged after new patch 2.03! --> Lock to unit does not work
- Discovery? AI heroes, especially different periodically run triggers causes lag spikes

=================================================================================================================================================
Epic Quests 18.7.2025 - List of Actions:

- Creep Respawn System / Creep Respawn -trigger
--- Modified to set Unit variable e.g., Ragno if the respawning unit-type is Ragno etc.
--- Test now with Ragno 1) kill Ragno 2) wait for respawn 3) try to click him to get dialogue / quest(s), if it works, the system works and you should add all important units like quest givers to the Creep Respawn -trigger if they are not invulnerable and can be killed.
- Imported dungeon like skybox shibi.mdx and hellish/fiery skybox xingkong3.mdx
--- Use shibi.mdx for dungeons like: Gnoll Hideout, The Crypt
--- Use xingkong3.mdx for: The Firelands, Dragon Lair
- Sirensong;
--- goblins "Boom Brothers" created; fixed / edited dialogue triggers (bug on Farewell, etc.)
--- Some lite terraining

=================================================================================================================================================
Epic Quests 10.7.2025 - List of Actions
- Sirensong;
--- Added draft idea for goblin sappers at the entrance of old mine who will need the Hero to search for Explosive barrels, barrels are highly unstable
--- Created base for quest dialogs

=================================================================================================================================================
Epic Quests 6.7.2025-2 - List of actions:
- Blood/bleed effects:
--- Fixed Point for the generic blood splat unit
--- Added SFX for the Blood Effect
- Units:
--- Added Panther boss and renamed Devilsaur as boss
- Terrain:
--- Continued Sirensong

=================================================================================================================================================
Epic Quests 5.7.2025 - List of actions:
- Blood/bleed effects:
--- Added Blood Splats and modified Bleed triggers, there is a chance to spawn blood effects on ground when attacked and under 25% hp or when the unit dies

=================================================================================================================================================
Epic Quests 4.7.2025 - List of actions:
- Sirensong:
-- Continued terraining southern end of the map, ogre / mine entrance areas
- Added models:
-- zombie, ghoul, moth, potions (potions models not used by any item, but imported)
-- Withering Presence (based on immolation)
-- Endemic Field (added as ability (test) for Soul Devourer Undead boss
- Blood/bleed effects added when unit is 25% low and taking damage and chance to spawn blood effect on the unit
-- Chance to occur maybe too low? + maybe start bleeding when below 25 %? or that kind of thing only for Heroes?

==================================================================================================================================================
Epic Quests 1.7.2025 - List of actions:
- Sirensong:
-- Continued terraining southern end of the map, sea shore area
-- Bridge lifted near naga area
- DestructibleHider >> enabled
- Floating Text Spell:
--- Modified floating text: "level of ability being cast -1
--- Note: "tooltip missing" e.g., when using item (e.g., Spring Water)
--- coloring now just uses the fixed coloring that is set in the tooltip text itself, its ok.
- Camera:
--- Interesting view by using: FoV 50-60, Dist 2200
--- Rotate left & right should be inversed?
--- BUG cinematics: if using arrow keys to rotate while transiting to Cinematic, camera will bug out in the cinematic but it will also remain bugged and stuck moving after the cinematic, can only be reset via /camera normal /cameral default etc. trying to use arrow keys....
- Note on Riverbane bridge: need to lower bridge end/start Invisible platforms
- Note on lag:
--- It is possible that Frostbite system or other newest system cause lag by utilizing periodic timers...

==================================================================================================================================================
Epic Quests 30.6.2025 - List of actions:

- Floating texts:
-- Added "Floating Spell Name" + Floating Spell Configuration triggers to have floating texts for spells;
--- This will need some conditions for blocking dummy units, and some wc3 internal spells e.g., critical strike, etc.
--- Critical note: Can't use "unit enters playable map area" as event, because of the huge number of pre-placed units OR/AND many unit enters region events
--- NEW: Init 07 on SETUP for "unit enters playable map area" events --> only use this trigger to run other triggers that need this event (SINGLE place for the generic event)
--- Note: need to add "level of ability being cast + 1", now its level 1 for e.g., level 2 ability
--- Note: coloring of ability does not work, it only works for some abilities tooltips as they already might have HEX coloring in them, so results is not clear always, best would be to have the ability text without coloring and then only the level is in different color
- Sirensong:

==================================================================================================================================================
Epic Quests 27.6.2025 - List of actions:

- Sirensong:
-- Continued terraining southern end of the map, sea shore area

==================================================================================================================================================
Epic Quests 25.6.2025 - List of actions:

- Note on textures: lots of imported duplicate textures with path war3mapImported / war3campImported .blp files that should be removed
- Note on re-imported textures:
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_floor_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_floor_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_floor_03.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_trim_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_trim_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_wall_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_int_wall_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_roof_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_roof_03.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_trim_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_trim_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_wall_01.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_wall_02.blp"
"C:\Users\Valtteri\Desktop\WowExport\Model and texture fixes 2025-06\orczeppelinhouse_durotar01\Texture re import\mm_ogrmr_window_01.blp"
---> Now black / glitching occurs also on orc hut!!!!!! Previous textures worked better!
- Sirensong:
-- Continued terraining southern end of the map, sea shore area

- Note on lag issues:
-- Previously disabled Stats check 2 -trigger was not the (main) cause of lag, still getting laggier after some time
-- Also; when units shown? or area near at water elemental boss caused fps to drop to 2 fps, could also be because of overlapping of Unit hider on AI / other units??
-- Now testing:
----- disabled UnitHider + related triggers and functions in CinematicON, CinematicOFF, Intro Cinematic Cleanup
----- disabled DestructibleHider

==================================================================================================================================================
Epic Quests 24.6.2025 - List of actions:

- Crash after doing countless regions for zones + some STV/jungle like doodad search, nothing fully inserted
-- Crash caused by STV_root01, could be others that may cause similar crash, or its related to the weirdly huge sizes, but most likely texture issue.
- modify Valkier to be "on foot" instead of on air, still need to fix her stand animation OR remove
- Stats check 2 -trigger disabled temporally
-- To check if this is causing lag / memory leak
--- seemed to be better, but needs more testing, still some minor peaks not that bad?

==================================================================================================================================================
Epic Quests 21.6.2025 - List of actions:

- Testing UnitHider1.1
-- whether it even works AND if memory leaks are reduced
-- Results: it does not work AND it lags even more!
-- Reverting to UnitHider1.0

Added units in WE:
- Core Hound
- NorthrendskeletonmaleBosses (Skullreaver)
- Valkier (Seralyth)

Terrain / doodads
- Added altar of storms to Dragonfire Peaks
- Added fel orcs at the altar of storms, some quest related to multiple Altar of Storms located in multiple locations in the map
- Sirensong terraining forward slightly
-- Sirensong Orc base edited forward
-- Sirensong orc base doodads some may require some editing (black textures when viewed from afar

Issues after testing:
- Valkier model bad; in air + changing stand animation to flying

Orc doodads (zeppelin):
- Tried to use UV remapping on black/glitchy orc zeppelin -> did not work
- Tried to use wrap width & wrap height on orc zeppelin and re-import the model (without re-importing textures) -> did not work, maybe need to re-import textures or related to Material filter modes

- Progressive lag / memory leak; gets bad quite quickly;
-- To test in next revision:
--- Disable UnitHider
--- Disable DestructibleHider
--- Disable AI hero spawning >> a)
--- Disable AI hero spawning, but leave UnitHider enabled >> b)

==================================================================================================================================================
