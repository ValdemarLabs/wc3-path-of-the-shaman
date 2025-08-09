CHANGELOG
==================================================================================================================================================
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
Epic Quests 22.7.2025 - List of Actions:

- Fixed issues related to AtexBlix / BoomBrothers quests/events - not finished yet...
--- Note 6 fixed
--- Note 2, 3, 6 could be fixed now - cause was DialogSkipped was set to TRUE, causing the triggers not to continue... Now each DialogOver trigger contains DialogSkipped = False at the end
--- Note 4; created Atex wood inspection, could be improved though
----- Need to remove completion at Boom Brothers for these quests (Note 5 related)
--- More Hazard Mitigation quest created; could need some more work with lines, etc. way of handling the quest

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
Epic Quests 26.7.2025 - List of Actions:

- AtexBlix
--- Fixing dialog

- Boom Brothers Mine
--- Terraining / doodads

- UnitHider; now re-enabled - cause of lag must be found from other periodic triggers/newer JASS scripts (like Frostbite system / etc.)

=================================================================================================================================================
Epic Quests 27.7.2025 - List of Actions:

- Cinematic Player (Player 22 Snow) now treated as ally by all players (previously was neutral and was attacked during a cinematic cutscene)
--- Problem with this version is; Player 22 or vise versa could go assist others which can break the immersion

- AtexBlix and BoomBrothers quest / dungeon continue

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
Epic Quests 6.8.2025 - List of Actions:

MODULAR QUESTS
- Modified strings for linebreaks "\n"
- Added generic kill and gather arrays + texts if using those (Boolean Active = TRUE)

XP:
- Modified Cinematic OFF trigger to prevent enabling XP gain for other units than Nazgrek and Zulkis (e.g., bag, companiondummy unit, etc.)

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
Epic Quests 10.8.2025 - List of Actions:

QUEST ICON SYSTEM
- reworked the system
- related quest system triggers call scripts updated to match the updated quest icon system function calls

