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
>>>>>> Reason: Call QuestIcon_RemoveQuest(unit u, integer questID) was called, this will delete the Quest from NPC, which should not be used but only when completing the quest!

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
>>> Use: call QuestIcon_RegisterQuest -function with same questID to refresh the quest's state.

Creep Unit Assignments -trigger created
- Started mapping units to proper unit variables when they are respawned (e.g., Quest givers, important npcs which Unit variable must be set)
>>> Note: Made first trigger but realized that the Creep Respawn trigger uses local variables that are important to respawn / variable re-assignment and so thus transferred unit assignments into "Creep Respawn" trigger

Debug DayNight
- using "debug daynight" command: it returns FALSE (NIGHT) when it is DAY (6:45) and it should be TRUE
>>> THIS CAN AFFECT CAMPING FOR AI HEROES ETC MANY OTHER TRIGGERS which use Boolean DNE_IsDay

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
Epic Quests 23.8.2025 - List of Actions:

Patrol System
- Modified the script
--- NOTE 1: Pause didnt work + no debug msg
--- NOTE 2: Stop didnt work - debug msg came
--- NOTE 3: unit is still going to some nonsense location
--- NOTE 4: Saved WP that is debug messaged from system itself matches with the waypoint location debug msg in GUI trigger

=================================================================================================================================================
Epic Quests 25.8.2025 - List of Actions:

Patrol System
- Modified the script
--- NOTE 1: Now it works like it should; the unit can be paused, and will continue where it was going
>>> To be teste with multiple settings and multiple units

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
Epic Quests 31.8.2025 - List of Actions:

Dialog Camera
- Added NearZ
- Added default cam time, and set to 0 instead of 0.5

Boom Brothers Mine
- more terraining

See more notes at To-Do app....


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
