# GUI triggers and `udg_*` variable audit

Audit date: 12 August 2026

## Purpose

This document tracks how current PotS JASS code depends on World Editor GUI globals and which legacy GUI triggers or Variable Editor variables may be removable.

The classifications are source-level findings, not permission to delete objects from the live map without validation. The repository does not contain the current map's complete trigger enable/import state or its complete Variable Editor declaration list. A candidate is only actually removable after all of the following are true:

1. The replacement library is imported into the map in the required order.
2. The old trigger is disabled and the affected behavior passes runtime testing.
3. A full-map JassHelper compile succeeds after deletion.
4. "Find all references" in World Editor finds no remaining GUI, custom-script, or initialization use.
5. Deleting a trigger does not remove a custom-text library or a required `gg_trg_*` declaration.

Removing a GUI trigger does not imply that its `udg_*` variables, `gg_rct_*` rects, `gg_unit_*` placed units, or `gg_snd_*` sounds are removable.

## Audit scope and totals

The active-code scan excludes old GUI exports, backups, drafts, tests, debugging copies, generated database exports, Blizzard sources, and folders marked unused. Comments are excluded from symbol counts.

| Scope | Files using GUI globals | `udg_*` references | Unique `udg_*` | `gg_*` references | Unique `gg_*` |
|---|---:|---:|---:|---:|---:|
| PotS-owned active code | 157 | 2,465 | 292 | 1,510 | 877 |
| Active code including imported libraries | 167 | 3,391 | 519 | 3,298 | 2,568 |
| Converted or legacy-compatible libraries | 71 | 847 | 119 | Not separately counted | Not separately counted |

Of the 71 converted or compatibility-oriented libraries, 38 contain no executable `udg_*` reference and 33 still use at least one. The largest compatibility users are `Companions/Companions.j`, `Companions/Pet.j`, `Death/Revival.j`, and `QuestsAndDialogs/QuestGivers/qOutcastJinzun.j`.

The most-used PotS-owned GUI globals are:

| Variable | Executable references |
|---|---:|
| `udg_Nazgrek` | 248 |
| `udg_PatrolSystem_Point` | 217 |
| `udg_Zulkis` | 209 |
| `udg_PatrolSystem_Wait` | 202 |
| `udg_AbilityPreloader` | 141 |
| `udg_Companion_Group` | 70 |
| `udg_TamedUnits` | 57 |
| `udg_TamedUnit` | 37 |
| `udg_InCinematic` | 28 |

## GUI trigger removal classifications

### High-confidence removal candidates

These groups have explicit replacement instructions and no known direct `gg_trg_*` dependency, subject to the validation checklist above.

- `Abilities/_OldGUI_triggers/Ability Init Setup/Init Abilities`
- `Abilities/_OldGUI_triggers/General/Shield Block/*`
- `Abilities/_OldGUI_triggers/Player Ability System/Elemental/*`
- `Abilities/_OldGUI_triggers/Player Ability System/Enhancement/*`
- `Abilities/_OldGUI_triggers/Player Ability System/Restoration/*`
- `Abilities/_OldGUI_triggers/Player Ability System/Totemic/*`
- `Abilities/_OldGUI_triggers/SHAMAN ABILITIES/*`
- `Death/_OldGui/HeroDeathResurrect/*`
- `Death/_OldGui/ReviveSystemPlayer/*`; retain the compatibility variables used by `Death.j` and `Revival.j`.
- `Leveling/_oldGUI/Experience Rested/*`
- `Leveling/_oldGUI/Leveling System/Rested Experience`
- `Leveling/_oldGUI/Leveling System/Hero Levels Up`
- `Leveling/_oldGUI/Base Camp/*`
- `Leveling/_oldGUI/Camp Fire/*`
- `Leveling/_oldGUI/Base Camp/AbilityPoints/Reset Abilities`
- `World/_oldGUI/Dragons/*`, after `DragonBehavior.j` and `EmberpeakDragons.j` are imported and tested.
- `Events/_OldGUI/Init 07 Unit Event Enters`; its export explicitly identifies `Events/Events.j` as the only central dispatcher.
- Migrated Creep Respawn GUI triggers after `CreepRespawn.j` and `CreepUnitAssignment.j` are active.
- `Companions/_OldGUI_Triggers/Companions/*`, excluding documentation.
- `Companions/_OldGUI_Triggers/Pet/*`, except the direct dependencies in the do-not-remove section.
- `QuestsAndDialogs/OLDGUI/Kribugs/*`
- `QuestsAndDialogs/OLDGUI/Valeria quests/*`
- `QuestsAndDialogs/OLDGUI/ChieftainThork/*`
- Converted `QuestsAndDialogs/OLDGUI/OutcastJinzun/*` triggers, except the remaining Crypt-side Resurgence completion caller.

### Likely removable, but validate first

These groups have current JASS counterparts, but the changelog still records import or runtime validation work, or the replacement header does not explicitly authorize removal.

- `DungeonsAndBosses/_oldGUI/Init Boss Units`, after every boss-specific initializer is imported.
- `DungeonsAndBosses/Dungeons/Boom Brothers Mine/_oldGUI/*`
- `DungeonsAndBosses/Dungeons/Gnoll Hideout/_oldGUI/*`
- Open-world boss groups under `Chimairo`, `Colossus`, `Jinvorrak`, `Mordrax`, `Morthun`, `MountainGiant`, `Roljin`, `Sargoth`, `Scorchion`, `Unknown Entity`, and `Void Entity`.
- The four empty Vorkatha GUI exports. `BossVorkatha.j` catalogs the source-empty encounter without inventing mechanics.
- `QuestsAndDialogs/OLDGUI/Ragno/*`
- `QuestsAndDialogs/OLDGUI/Example_qAradion/*`
- `ItemLootSystems/_OldGUI/*`, after comparing the active generated specific-drop definitions with every old special-drop trigger.
- `Inventory/_oldGui/ItemTypeChecks/*`, after confirming every consumer uses the current item classification or database API.
- Old preload triggers and the old `Game Start` elapsed-time/startup event after `Preloader.j` and `Start.j` are connected. This does not include the intro cinematic trigger.

### Do not remove yet

These triggers have a concrete active source dependency or an incomplete replacement.

- `Tamed Unit Revival`, `Tamed Unit Dies`, and `Shadowclaw Revival`; `Cinematic/CinematicMove.j` executes them directly.
- `Intro Cinematic Orc Q`; `Preload/Start.j` conditionally executes `gg_trg_Intro_Cinematic_Orc_Q`.
- `Cinematic_ON` and `Cinematic_OFF`; `QuestsAndDialogs/DialogInteraction.j` executes them.
- `Fog_Fade_System`; `EnvironmentSystems/AddFogForPlayer.j` enables it.
- Codex GUI triggers: `Codex_UI_Entry_One_Button_Clicked` through `Codex_UI_Entry_Six_Button_Clicked`, `Codex_UI_Done_Button_Clicked`, `Codex_UI_Reload`, `Codex_UI_Pause`, `Codex_UI_Maintenance_Menu`, and `Codex_UI_Unpause`.
- GUI configuration/container triggers: `Is_Unit_Moving_Config`, `WithinRange`, `GTS_Main`, `GCSM_Main`, `Mordrax_Movement_Start`, `Morthun_Movement_Start`, `MountainGiant_Movement_Start`, and `TravelShipB_Movement_Start`.
- `AI/_OldGUI_triggers/*`. Several current AI class headers state that detailed rotations still need to be layered into the new profiles.
- `Professions/_oldGUI_unfinished/*`; these are unfinished or sole implementations rather than proven replacements.
- Any remaining GUI variable-event listener using `UnitDeathEvent_Event`. `Events/UnitDeathEvent.j` deliberately retains its compatibility pulse for those listeners.

### Uncertain/manual inspection required

- `Arena/_OldGuiTriggers/Arena Building Barricade`
- Root `QuestsAndDialogs/OLDGUI/Quest System *` triggers
- The Crypt-side completion caller for Outcast Jin'Zun's `Resurgence of Dead Part 2`
- Miscellaneous old GUI item-cleanup triggers not named in `ItemSystems/ItemCleanup.j`
- Any trigger stored as converted custom text in World Editor. Deleting the trigger can delete the library itself even when its event list is empty.

## `udg_*` Variable Editor classifications

In the lists below, `prefix_*` means every Variable Editor variable beginning with that exact prefix. It does not include similarly named variables without the underscore; for example, `udg_Ability_*` does not include `udg_AbilityPreloader`.

### High-confidence removal candidates

These variables are written by GUI groups with explicit JASS replacements and have no executable reference in the active JASS scope. They are still candidates until the World Editor reference search and full-map compile pass.

Ability and spell-conversion families:

- `udg_Ability_*`
- `udg_BAmr_*`, `udg_BAmr2_*`
- `udg_BL_*`, `udg_FR_*`, `udg_FS_*`, `udg_NS_*`, `udg_PF_*`
- `udg_KB_*`, `udg_KBA_*`, `udg_LS0_*`, `udg_LS1_*`, `udg_SF_*`
- `udg_Shieldblock_*`, `udg_FeralSpirits_*`, `udg_SummonElemental_*`
- `udg_WindShear_*`, `udg_Whirlwind_*`, `udg_chainheal_*`
- `udg_AbilityPointsNazgrek`, `udg_AbilityPointsZulkis`
- `udg_ancestralward_temp`, `udg_BiteCaster`, `udg_BiteDummy`, `udg_BitePoints`
- `udg_CleansingGroup`, `udg_DummyTotemPoint`, `udg_HealManaCost`
- `udg_StormstrikeCaster`, `udg_StormstrikeDummy`, `udg_StormstrikePoints`
- `udg_TargetHextUnit`, `udg_TotemGenericTimer`, `udg_TotemManaCost`
- `udg_TotemText`, `udg_TotemTextFontSize`, `udg_TotemTextOffsetZ`, `udg_TotemVarPoint`
- `udg_Windfury_Duration`, `udg_WindfuryDummy`, `udg_WindfuryPoint`

Leveling, camp, death, and dragon temporary families:

- `udg_BaseCamp_*`, `udg_BaseCampGrp_Int`
- `udg_XP_*`
- `udg_CampFirePoint`, `udg_RestedDummy`, `udg_RestedPoint`, `udg_RestedTarget`
- `udg_HeroDeathResurrect_*`
- `udg_NPC_DeathPoint`, `udg_NPC_Deceased`, `udg_NPC_DeceasedHero`, `udg_NPC_DeceasedTarget`
- `udg_DeathCameraPoint`, `udg_NazgrekCurPos`, `udg_NazgrekDeathPoint`, `udg_ZulkisCurPos`, `udg_ZulkisDeathPoint`
- `udg_SpiritHealerDialogCancel`, `udg_SpiritHealerDialogRestoN`, `udg_SpiritHealerDialogRestoZ`
- `udg_DragonSoundUnit`, `udg_TempPointDragonWander`

Generic names such as `udg_CV`, `udg_Temp_Integer`, and `udg_VarPoint` are intentionally not high-confidence candidates even though this scan found no active JASS reference; their names are too generic to exclude use by unexported live GUI triggers.

### Likely removable, but validate first

These old encounter or quest temporaries have no executable reference in the active JASS scope, but their replacement libraries still require import/runtime validation or their data parity is not fully proven.

Boss and dungeon temporaries:

- `udg_BoomMinePoint`, `udg_BOSS_RT`, `udg_BossChimairo_Point`
- `udg_BossColossus_BouldersPoint`, `udg_BossColossus_GolemPoint`, `udg_BossColossusBoulders`, `udg_BossColossusFacingAngle`, `udg_BossColossusGolems`, `udg_BossColossusSlam`, `udg_BossColossusSlamInt`, `udg_BossColossusSP`, `udg_BossColossusSplitBoulderLoc`, `udg_BossColossusTempPoint`
- `udg_BossFeldok_ChanceInteger`, `udg_BossImpalerEffect`
- `udg_BossMordrax_Angle`, `udg_BossMordrax_LinesInt`, `udg_BossMordrax_Point`, `udg_BossMordrax_Target`, `udg_BossMordrax_TargetGroup`, `udg_BossMordrax_TargetPoint`, `udg_BossMordrax_VoicelineActive`
- `udg_BossSargothReset`
- `udg_BossScorchionAngle`, `udg_BossScorchionDarkShaman`, `udg_BossScorchionDarkShamansLine`, `udg_BossScorchionDarkShamansR_ON`, `udg_BossScorchionEngageAngle`, `udg_BossScorchionOrbEffect`, `udg_BossScorchionOrbInt`, `udg_BossScorchionOrbPoint`, `udg_BossScorchionPoint`, `udg_BossScorchionStartFx`, `udg_BossScorchionTarget`, `udg_BossScorchionTargetGroup`, `udg_BossScorchionTargetPoint`
- `udg_BossUnknownEntity`, `udg_BossVoidEntity_LinesInt`, `udg_BossVoidEntity_VoicelineActive`
- `udg_RoljinMoveInt`, `udg_RoljinSupportInt1`, `udg_RoljinSupportInt2`
- `udg_SargothLair`, `udg_SargothSpiderAttackPoint`, `udg_SargothSpiderSpawnPoint1`, `udg_SargothSpiderSpawnPoint2`, `udg_SargothSpiderSpawnPoint3`
- `udg_TentacleSpawn`, `udg_VarTentacle`

Converted quest-giver and dialogue state:

- `udg_JinzunDialog01Decline`, `udg_JinzunDialog01Farewell`, `udg_JinzunDialog01Plague`, `udg_JinzunDialog01Wards`
- `udg_JinzunDialog02Decline`, `udg_JinzunDialog02Farewell`, `udg_JinzunDialog02Sargoth`
- `udg_JinzunDialog03Decline`, `udg_JinzunDialog03Farewell`, `udg_JinzunDialog03Seeds`, `udg_JinzunDialog03Unknown`
- `udg_JinzunDialog04Farewell`, `udg_JinzunDialog04FishingPole`, `udg_JinzunDialog04Resurgence`
- `udg_JinzunDialog05Accept`, `udg_JinzunDialog05Decline`, `udg_JinzunDialog05Farewell`
- `udg_JinzunDialog06Accept`, `udg_JinzunDialog06Decline`, `udg_JinzunDialog06Farewell`
- `udg_JinzunInteger2`, `udg_JinzunTalking`
- `udg_KribugsOgreFull`, `udg_KribugsOgreFullCount`, `udg_KribugsRandomGreet`, `udg_KribugsSatchel`
- `udg_RagnoDialog01Farewell`, `udg_RagnoDialog01FarewellBoolean`, and every `udg_RagnoDialog01*` quest-button variable
- `udg_ThorkDialog01Farewell`, `udg_ThorkDialog01Letter`
- `udg_ValeriaFarewellBoolean`, `udg_ValeriaRandomGreet`
- `udg_QuestAngryCustomers*`, `udg_QuestCallOfTheHorde*`, `udg_QuestFirstQuests*`
- `udg_QuestFishingPole*`, `udg_QuestGnollHeadcount*`, `udg_QuestKobolds*`
- `udg_QuestKribugsSatchel*`, `udg_QuestLostSupplies*`, `udg_QuestLumberjack*`
- `udg_QuestMeatForOgre*`, `udg_QuestOgreAteMuch*`, `udg_QuestOgreSandwich*`, `udg_QuestOgreThirsty*`
- `udg_QuestPlagueUponTree*`, `udg_QuestResurgenceDead*`, `udg_QuestSargoth*`
- `udg_QuestSatyrNegotiations*`, `udg_QuestSeedsOfLife*`, `udg_QuestTokenLove*`, `udg_QuestUnknownEntity*`

Loot candidates requiring generated-data comparison:

- `udg_ItemLootTable`, `udg_TempGroupDrop`

### Do not remove yet

Every variable below has at least one executable reference in active PotS-owned JASS. Prefix entries cover all variables with that exact prefix.

Core heroes, NPCs, bosses, and map references:

- `udg_Nazgrek`, `udg_Zulkis`, `udg_Aradion`, `udg_AtexBlix`, `udg_Aveline`, `udg_BoomBrothers`, `udg_Drekthor`, `udg_Erduk`, `udg_Garthork`, `udg_Graknar`, `udg_Granis`, `udg_Grim`, `udg_Grum`, `udg_KodoGrak`, `udg_Krezgrel`, `udg_Kribugs`, `udg_MightyTree`, `udg_MysterWizard`, `udg_Ogmar`, `udg_OutcastJinzun`, `udg_Ragno`, `udg_Roljin`, `udg_SatyrQueen`, `udg_Shadowclaw`, `udg_Succubus`, `udg_Thork`, `udg_Valeria`, `udg_Zaekolaerr`
- `udg_BOSS`, `udg_BossAbomination`, `udg_BossChimairo`, `udg_BossColossus`, `udg_BossColossus_Golems`, `udg_BossFeldok`, `udg_BossImpaler`, `udg_BossMadBlix`, `udg_BossMalkiri`, `udg_BossMordrax`, `udg_BossMorthun`, `udg_BossMountainGiant`, `udg_BossSargoth`, `udg_BossScorchion`, `udg_BossVoidEntity`, `udg_BossVorkatha`
- `udg_NPC_Horde_AI_Rogue`, `udg_NPC_Horde_AI_Shaman`, `udg_NPC_Horde_AI_Warlock`, `udg_NPC_Horde_AI_Warrior`, `udg_NPC_Neutral_Engineer`, `udg_NPC_Riverbane_Paladin`

System/API families:

- `udg_AbilityPreloader`
- every `udg_CCSS_*` camera variable
- every `udg_Codex_*` variable
- every `udg_Companion*` variable and `udg_CompDummy`
- `udg_DamageEvent`, `udg_DamageEventAmount`, `udg_DamageEventSource`, `udg_DamageEventTarget`, `udg_DamageEventType`, `udg_DamageModifierEvent`, `udg_DamageTypeHeal`, `udg_IsDamageAttack`, `udg_IsDamageMelee`, `udg_IsDamageSpell`, `udg_LethalDamageHP`
- `udg_DestructibleDeathEvent`, `udg_DestructibleDeathTarget`
- `udg_DInv_SourceUnit`, `udg_DInv_TargetUnit`, `udg_DInvUnit`
- `udg_DNE_DayNightEvent`, `udg_DNE_IsDaytime`, `udg_DaysPassed`
- every `udg_Fog_Player_*` variable
- every `udg_Frostbite_*` variable
- `udg_FollowSystem_Source`, `udg_FollowSystem_Target`
- `udg_GCSM_UnitInCombat`, `udg_IsUnitAlive`, `udg_IsUnitOnBridge`
- `udg_ItemHook_CreateEvent`, `udg_ItemHook_DestroyEvent`
- every `udg_PatrolSystem_*` variable
- every `udg_Stats_*` variable currently referenced: `Block`, `Crit`, `Dodge`, `Hit`, `SpellPowerFlat`, and `SpellPowerPct`
- `udg_UDex`, `udg_UDexUnits`, `udg_UnitIndexEvent`, `udg_UnitTypeEvent`, `udg_UnitIsCasting`, `udg_UnitMoving`
- every `udg_UnitHider_*` variable

Companion, pet, death, and revival compatibility:

- `udg_TamedUnit`, `udg_TamedUnits`, `udg_TamedUnitDeathCount`, `udg_TamedUnitKillCount`
- `udg_Pet`, `udg_Pet_Dead`, `udg_Pet_DeathPoint`, `udg_Pet_Renamed`, `udg_Pet_Tamer`, `udg_Pet_TamerChanneling`
- `udg_Shadowclaw_armor`, `udg_Shadowclaw_armor_base`, `udg_Shadowclaw_dmg`, `udg_Shadowclaw_dmg_base`, `udg_Shadowclaw_hp`, `udg_Shadowclaw_hp_base`
- `udg_NazgrekDead`, `udg_NazgrekDeathCount`, `udg_NazgrekDeathRegion`, `udg_NazgrekKillCount`, `udg_NazgrekMorph`, `udg_NazgrekMorphing`
- `udg_ZulkisDead`, `udg_ZulkisDeathCount`, `udg_ZulkisDeathRegion`, `udg_ZulkisKillCount`, `udg_ZulkisMorph`, `udg_ZulkisMorphing`
- every `udg_ReviveTimer*` variable
- `udg_GraveyardPoint`, `udg_GraveyardSelect`, `udg_GraveyardSpecialEffect`, `udg_RestoreItemsPossibleN`, `udg_RestoreItemsPossibleZ`, `udg_SpiritHealer`, `udg_SpiritHealers`

Other active state:

- `udg_BoomMineBarrel`, `udg_BoomMineCountdown`, `udg_Cauldrons`
- `udg_CinematicMoveMode`, `udg_CinematicMovePoint`, `udg_CinematicTrailer`, `udg_CinematicTriggerUnit`, `udg_InCinematic`
- `udg_EmberpeakDragonCasting`, `udg_EmberpeakDragonsCenter`
- `udg_ExMusicInteger`, `udg_ExMusicString`, `udg_ExSoundDuration`
- `udg_hashtable`, `udg_LastDroppedItem`, `udg_PlayerGroup`, `udg_QuestItemTemp`, `udg_TempUnit`
- `udg_PlagueTree1Ritual`, `udg_PlagueTree2Ritual`, `udg_PlagueTree3Ritual`, `udg_PlagueTreeNecros`
- `udg_QuestBoomWillBeBackReq1`, `udg_QuestChainsOfSeduction`, `udg_QuestChainsOfSeductionDispelld`, `udg_QuestChainsOfSeductionReq2`, `udg_QuestMistakenKin`
- `udg_RoljinGroup`, `udg_SuccubusSeduced`
- `udg_SnowAmount`, `udg_SnowAmounts`, `udg_SnowDestructionZone`, `udg_SnowIndex`, `udg_SnowRegion`, `udg_SnowRegions`
- `udg_START`, `udg_TM_Timer`, `udg_TM_TimerFinished`, `udg_TM_Value`, `udg_Totem`
- `udg_TrapDoodad`, `udg_TrapRegion_01`, `udg_TravelShipB`, `udg_TreeRune`

### Uncertain/manual inspection required

Do not delete these solely because active JASS does not reference them:

- Variables used by `AI/_OldGUI_triggers/*`; the new AI profiles do not yet claim complete behavioral parity.
- Variables used by `Professions/_oldGUI_unfinished/*`.
- Variables used by `Inventory/_oldGui/ItemTypeChecks/*` until every live inventory consumer is checked.
- Generic shared names such as `udg_CV`, `udg_GroupVar`, `udg_Random`, `udg_PingPoint`, `udg_tmp_point`, `udg_Temp_Integer`, `udg_VarPoint`, `udg_VarPoint2`, `udg_BossVarPoint`, `udg_CompVarPoint`, and `udg_CompVarPoint2`.
- Old generic quest-engine temporaries such as `udg_QuestID`, `udg_QuestTemp`, `udg_QuestStateTemp`, `udg_QuestTitleTemp`, `udg_QuestDescriptionTemp`, `udg_QuestRequirement*Temp`, and `udg_QuestReward*Temp`. These need a search across all live GUI quest triggers before removal.
- Pet/companion temporary variables such as `udg_Pet_Index`, `udg_Pet_Name`, `udg_CompVarAngle`, `udg_CompVarDistance`, `udg_CompVarTarget`, and `udg_PartyKickVoice` until the remaining directly executed pet triggers are refactored.
- Any variable absent from this document. Absence means the variable was not discovered by the repository scan, not that it is unused in the map.

## Recommended cleanup order

1. Import and runtime-test the replacement libraries already listed in the changelog's actions remaining.
2. Disable high-confidence GUI trigger candidates without deleting their variables.
3. Run affected-map and full-map JassHelper compiles and multiplayer-sensitive tests.
4. Refactor the remaining direct `gg_trg_*` calls to library APIs or private JASS triggers.
5. Delete proven obsolete trigger objects.
6. Search and delete obsolete `udg_*` variables in small subsystem batches, compiling after each batch.
7. Re-run this inventory after every conversion wave.
