CHANGELOG
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

Epic Quests 24.6.2025 - List of actions:

- Crash after doing countless regions for zones + some STV/jungle like doodad search, nothing fully inserted
-- Crash caused by STV_root01, could be others that may cause similar crash, or its related to the weirdly huge sizes, but most likely texture issue.
- modify Valkier to be "on foot" instead of on air, still need to fix her stand animation OR remove
- Stats check 2 -trigger disabled temporally
-- To check if this is causing lag / memory leak
--- seemed to be better, but needs more testing, still some minor peaks not that bad?

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

Epic Quests 27.6.2025 - List of actions:

- Sirensong:
-- Continued terraining southern end of the map, sea shore area

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
-- Continued terraining southern end of the map, sea shore area

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

=================================================================================================================================================

Epic Quests 5.7.2025 - List of actions:
- Blood/bleed effects:
--- Added Blood Splats and modified Bleed triggers, there is a chance to spawn blood effects on ground when attacked and under 25% hp or when the unit dies

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

Epic Quests 10.7.2025 - List of Actions
- Sirensong;
--- Added draft idea for goblin sappers at the entrance of old mine who will need the Hero to search for Explosive barrels, barrels are highly unstable
--- Created base for quest dialogs

=================================================================================================================================================
Epic Quests 11.7.2025 - List of Actions
- Sirensong;
--- goblins "Boom Brothers" created; sounds for dialogues, created quest related triggers


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

