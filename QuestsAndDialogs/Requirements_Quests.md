=====================================================================================================
# Quest systems related requirements
- QuestMaster.j
- QuestGiver.j
- qAradion.j, and other similar quest giver sublibraries that will be created later on

Last updated: 2026-02-19
=====================================================================================================

## Common (to be decided which system handles QuestGiver or QuestMaster or both)
- Quest: sometimes we may want to quest to get completed without returning/dialogue with questgiver - e.g GoToPlace/GoToZone quest 
- GoToPlace quest should require to to go to certain rect (udg_rct_xxx)
- We should have also GoToZone quest template - it will utilize ZonesCore / ZoneEvent libraries


## Bugs/issues (some might be already implemented / working)
- QUEST_TEST_KILL / Kill quest dont have quest requirement shown in quest log - maybe for other new templates as well similarly missing?
- QUEST_TEST_KILL: We didnt update quest status X/X killed units message / quest log / requirement text
- QUEST_TESTS: we didnt start exit fade out properly / camera didnt reset - after one exitfadeout -> maybe something preventing it? THIS IS FOR EVERY EXIT quest giver things (e.g., Accept Ranger quest too)
- QUEST_GoTO: Didnt autocomplete quest when zone VErdant plains was entered
- TemplateGotoZone requires setting Zone id - we should only need to set the zone name
- QUEST_TEST_KILL: Kill quest should have similarly like gather quest - e.g., Kill 0 <unit-type> / X 
>>> this might be done


## QuestMaster (some might be already implemented / working)
- QuestMaster: we are calling "sub" library QuestGiver functions QuestGiver_RegisterUnitKillRequirement and QuestGiver_RegisterItemRequirement - which is not allowed - QuestMaster is the master system and does not call QuestGiver!
- Also, it should be better practice to create quest using QuestGiver_CreateQuest and then apply template to it, instead of using QuestMaster TemplateKill
- QuestMaster: Item harvest quest requirements we should be able to configre the text "gather" to something else e.g., "Find" / "Retrieve", if it is only 1 item then there is no X/X item - eg., "Gather/find/retrieve/collect <Item-type name>"
- Questgiver map icon / effect: dont reapply effects if the questqiver unit already has that effect - this is done with some Refresh function - needs check before applying effects
- New quest style: Follow <questgiver / Follow unit x
- New quest style: Protect unit x / together with requirement "<unit x> must not die


## QuestGiver
- QuestGivers: QuestHelpers - we should have functions for all QuestStyles and their events - especially ones that are most generic - only track for quests that are active
- QuestHelpers: with these helper functions either in QuestGiver and/or QuestMaster and/or DialogSystem - we should be able easily built quests with just necessary input info for quest givers without the need of handcrafting each qSublibrary


## qAradion
- qAradion: analyze library - what functions are generic and suspect to be used for other questgiver? These should be transferred to QuestGivers / DialogSystem and use simple calls from qSublibrary


## Other notes
- 