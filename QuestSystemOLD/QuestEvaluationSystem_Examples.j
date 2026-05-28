//===========================================================================
// QuestEvaluationSystem - Example Implementation
//===========================================================================
// This file demonstrates how to configure and use the QuestEvaluationSystem
// Copy these examples into your QuestEvaluationSystem.j configuration functions
//===========================================================================

//===========================================================================
// EXAMPLE 1: Basic Quest Giver Setup
//===========================================================================
/*
private function ConfigureQuestGivers takes nothing returns nothing
    // Register all NPCs that will give quests
    call QuestEval_RegisterGiver(udg_Thrall)
    call QuestEval_RegisterGiver(udg_Jaina)
    call QuestEval_RegisterGiver(udg_Cairne)
    call QuestEval_RegisterGiver(udg_Rexxar)
    call QuestEval_RegisterGiver(udg_VendorOrc)
    call QuestEval_RegisterGiver(udg_InnKeeper)
endfunction
*/

//===========================================================================
// EXAMPLE 2: Quest Requirements Setup
//===========================================================================
/*
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    local Faction alliance = Faction.getFaction("Alliance")
    local Faction satyr = Faction.getFaction("Satyr")
    local Faction centaur = Faction.getFaction("Centaur")
    
    //-----------------------------------------------------------------------
    // THRALL'S QUESTS - Horde Starting Area
    //-----------------------------------------------------------------------
    
    // Quest 1: "Call of the Shaman" - First quest, no requirements
    call AddQuestRequirement(1, udg_Thrall, 1, null, 0, "normal")
    
    // Quest 2: "Proving Your Worth" - Requires level 3
    call AddQuestRequirement(2, udg_Thrall, 3, null, 0, "normal")
    
    // Quest 3: "Earning Trust" - Requires level 5 and Horde Neutral
    call AddQuestRequirement(3, udg_Thrall, 5, horde, 0, "normal")
    
    // Quest 4: "Honored Warrior" - Requires level 8 and Horde Friendly
    call AddQuestRequirement(4, udg_Thrall, 8, horde, 3000, "normal")
    
    // Quest 50: "Daily: Horde Supplies" - Daily quest, level 5+
    call AddQuestRequirement(50, udg_Thrall, 5, horde, 0, "daily")
    
    //-----------------------------------------------------------------------
    // JAINA'S QUESTS - Alliance Area
    //-----------------------------------------------------------------------
    
    // Quest 10: "Alliance Welcome" - First Alliance quest
    call AddQuestRequirement(10, udg_Jaina, 1, null, 0, "normal")
    
    // Quest 11: "Defend Theramore" - Level 5, Alliance Neutral
    call AddQuestRequirement(11, udg_Jaina, 5, alliance, 0, "normal")
    
    // Quest 12: "Arcane Studies" - Level 10, Alliance Friendly
    call AddQuestRequirement(12, udg_Jaina, 10, alliance, 3000, "normal")
    
    // Quest 51: "Daily: Theramore Patrol" - Daily quest
    call AddQuestRequirement(51, udg_Jaina, 7, alliance, 0, "daily")
    
    //-----------------------------------------------------------------------
    // CAIRNE'S QUESTS - Advanced Horde Quests
    //-----------------------------------------------------------------------
    
    // Quest 20: "Test of Strength" - Level 10, Horde Friendly
    call AddQuestRequirement(20, udg_Cairne, 10, horde, 3000, "normal")
    
    // Quest 21: "Tauren Traditions" - Level 12, Horde Covenant
    call AddQuestRequirement(21, udg_Cairne, 12, horde, 6000, "normal")
    
    // Quest 100: "Dungeon: Mulgore Depths" - Dungeon quest
    call AddQuestRequirement(100, udg_Cairne, 15, horde, 6000, "dungeon")
    
    //-----------------------------------------------------------------------
    // REXXAR'S QUESTS - Neutral/Beast Master Quests
    //-----------------------------------------------------------------------
    
    // Quest 30: "Beast Master's Trial" - Level 7, no faction requirement
    call AddQuestRequirement(30, udg_Rexxar, 7, null, 0, "normal")
    
    // Quest 31: "Taming the Wild" - Level 10
    call AddQuestRequirement(31, udg_Rexxar, 10, null, 0, "normal")
    
    //-----------------------------------------------------------------------
    // VENDOR QUESTS - Repeatable and Commerce
    //-----------------------------------------------------------------------
    
    // Quest 40: "Gathering Supplies" - Repeatable, level 3
    call AddQuestRequirement(40, udg_VendorOrc, 3, null, 0, "repeatable")
    
    // Quest 41: "Trade Routes" - Repeatable, level 5, Horde Neutral
    call AddQuestRequirement(41, udg_VendorOrc, 5, horde, 0, "repeatable")
    
    //-----------------------------------------------------------------------
    // INN KEEPER QUESTS - Daily Quests Hub
    //-----------------------------------------------------------------------
    
    // Quest 60: "Daily: Deliver Meals" - Daily quest
    call AddQuestRequirement(60, udg_InnKeeper, 3, null, 0, "daily")
    
    // Quest 61: "Daily: Collect Ingredients" - Daily quest
    call AddQuestRequirement(61, udg_InnKeeper, 5, null, 0, "daily")
    
endfunction
*/

//===========================================================================
// EXAMPLE 3: Quest Acceptance Trigger
//===========================================================================
/*
function Trig_Quest_001_Accept_Actions takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    
    // Mark quest as active in the evaluation system
    // This prevents the availability icon from showing
    call QuestEval_MarkQuestActive(questID)
    
    // Register quest as "in progress" in QuestIconSystem
    call QuestIcon_RegisterQuest(npc, questID, "normal", 3)
    call QuestIcon_UpdateForNPC(npc)
    
    // Display quest accepted message
    call DisplayTimedTextToPlayer(Player(0), 0, 0, 10.0, "|cffffcc00Quest Accepted:|r Call of the Shaman")
    
    // Create quest objectives, start tracking, etc.
    // Your quest setup code here...
    
endfunction
*/

//===========================================================================
// EXAMPLE 4: Quest Progress Update
//===========================================================================
/*
function Trig_Quest_001_Update_Actions takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    local integer currentProgress = 0
    local integer requiredProgress = 10
    
    // Update progress counter
    set udg_Quest001_Progress = udg_Quest001_Progress + 1
    set currentProgress = udg_Quest001_Progress
    
    // Check if quest objectives are complete
    if currentProgress >= requiredProgress then
        // Quest ready to turn in
        call QuestIcon_RegisterQuest(npc, questID, "normal", 5)
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 8.0, "|cff00ff00Quest Complete:|r Return to Thrall")
    else
        // Still in progress
        call QuestIcon_RegisterQuest(npc, questID, "normal", 3)
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 5.0, "Progress: " + I2S(currentProgress) + "/" + I2S(requiredProgress))
    endif
    
    call QuestIcon_UpdateForNPC(npc)
endfunction
*/

//===========================================================================
// EXAMPLE 5: Quest Turn In / Completion
//===========================================================================
/*
function Trig_Quest_001_TurnIn_Actions takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    local unit hero = udg_Nazgrek
    
    // Check if quest is ready to turn in
    if udg_Quest001_Progress >= 10 then
        
        // Give rewards
        call AddHeroXP(hero, 100, true)
        call SetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) + 50)
        
        // Add reputation
        call Reputation.addRaw(Player(0), Faction.getFaction("Horde"), 250)
        
        // Display completion message
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 10.0, "|cff00ff00Quest Completed:|r Call of the Shaman")
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 8.0, "|cffffcc00Rewards:|r 100 XP, 50 Gold, +250 Horde Reputation")
        
        // Mark quest as inactive in evaluation system
        // This allows next quest to appear (if configured)
        call QuestEval_MarkQuestInactive(questID)
        
        // Remove quest icon
        call QuestIcon_RemoveQuest(npc, questID)
        call QuestIcon_UpdateForNPC(npc)
        
        // Clean up quest data
        set udg_Quest001_Active = false
        set udg_Quest001_Progress = 0
        
    else
        // Not ready to turn in
        call DisplayTimedTextToPlayer(Player(0), 0, 0, 5.0, "|cffff0000Quest not complete yet!|r")
    endif
    
endfunction
*/

//===========================================================================
// EXAMPLE 6: Quest Abandonment
//===========================================================================
/*
function Trig_Quest_001_Abandon_Actions takes nothing returns nothing
    local integer questID = 1
    local unit npc = udg_Thrall
    
    // Mark quest as inactive (makes it available again if requirements still met)
    call QuestEval_MarkQuestInactive(questID)
    
    // Clean up quest data
    set udg_Quest001_Active = false
    set udg_Quest001_Progress = 0
    
    // Force immediate evaluation to restore availability icon
    call QuestEval_ForceUpdate()
    
    call DisplayTimedTextToPlayer(Player(0), 0, 0, 5.0, "|cffff8040Quest Abandoned:|r Call of the Shaman")
    
endfunction
*/

//===========================================================================
// EXAMPLE 7: Custom Condition Quest
//===========================================================================
/*
// Define custom condition
function Quest_Special_Condition takes nothing returns boolean
    // Example: Player must have defeated a boss AND collected an item
    return udg_BossKarthokDefeated == true and udg_HasAncientRelic == true
endfunction

// In ConfigureQuestRequirements:
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    local trigger customTrigger = CreateTrigger()
    
    // Setup custom condition trigger
    call TriggerAddCondition(customTrigger, Condition(function Quest_Special_Condition))
    
    // Quest 200: Special quest with custom requirements
    call AddQuestRequirement(200, udg_SpecialNPC, 15, horde, 6000, "normal")
    
    // Add custom condition trigger
    call QuestEval_AddCustomCondition(200, customTrigger)
endfunction
*/

//===========================================================================
// EXAMPLE 8: Dynamic Quest Giver Registration
//===========================================================================
/*
function Trig_SpawnQuestGiver_Actions takes nothing returns nothing
    local unit newNPC
    local real x = GetRectCenterX(gg_rct_SpawnRegion)
    local real y = GetRectCenterY(gg_rct_SpawnRegion)
    
    // Create NPC
    set newNPC = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h000', x, y, 270.0)
    set udg_DynamicQuestGiver = newNPC
    
    // Register as quest giver
    call QuestEval_RegisterGiver(newNPC)
    
    // Force update to show icons immediately
    call QuestEval_ForceUpdate()
    
    set newNPC = null
endfunction

function Trig_RemoveQuestGiver_Actions takes nothing returns nothing
    // Unregister quest giver
    call QuestEval_UnregisterGiver(udg_DynamicQuestGiver)
    
    // Remove unit
    call RemoveUnit(udg_DynamicQuestGiver)
    set udg_DynamicQuestGiver = null
endfunction
*/

//===========================================================================
// EXAMPLE 9: Level-Up Integration
//===========================================================================
/*
function Trig_HeroLevelUp_Actions takes nothing returns nothing
    local unit hero = GetTriggerUnit()
    local integer newLevel = GetHeroLevel(hero)
    
    // Display level up message
    call DisplayTimedTextToPlayer(Player(0), 0, 0, 5.0, "|cffffcc00Level Up!|r You are now level " + I2S(newLevel))
    
    // Force quest evaluation update
    // New quests may become available based on level
    call QuestEval_ForceUpdate()
    
    set hero = null
endfunction
*/

//===========================================================================
// EXAMPLE 10: Reputation Change Integration
//===========================================================================
/*
// Hook into reputation changes to update quest availability
// This can be added to the Reputation system's addRaw function,
// or called manually after reputation changes

function OnReputationChanged takes nothing returns nothing
    // Force quest evaluation when reputation changes
    // New quests may become available based on new reputation tier
    call QuestEval_ForceUpdate()
endfunction
*/

//===========================================================================
// EXAMPLE 11: Quest Chain Setup
//===========================================================================
/*
// Quest Chain: "Rise of the Champion"
// Quest 301 → 302 → 303 → 304 (Each quest unlocks the next)

private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    
    // Quest 301: "The First Step" - Starting quest
    call AddQuestRequirement(301, udg_QuestChainNPC, 5, null, 0, "normal")
    
    // Quest 302: "Proving Worth" - Requires level 7 (player should be this level after 301)
    call AddQuestRequirement(302, udg_QuestChainNPC, 7, horde, 0, "normal")
    
    // Quest 303: "Earning Recognition" - Requires level 9, Horde Friendly
    call AddQuestRequirement(303, udg_QuestChainNPC, 9, horde, 3000, "normal")
    
    // Quest 304: "Champion's Trial" - Requires level 12, Horde Covenant
    call AddQuestRequirement(304, udg_QuestChainNPC, 12, horde, 6000, "normal")
endfunction

// When completing quest 301, mark it inactive so 302 can appear:
function Quest301_Complete takes nothing returns nothing
    call QuestEval_MarkQuestInactive(301)
    // Quest 302 will automatically appear if requirements are met
    call QuestEval_ForceUpdate()
endfunction
*/

//===========================================================================
// EXAMPLE 12: Multiple Quest Givers with Shared Requirements
//===========================================================================
/*
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde = Faction.getFaction("Horde")
    
    // Same quest from multiple NPCs (player can choose who to get it from)
    // Quest 400: "Daily: Resource Gathering"
    call AddQuestRequirement(400, udg_ThrallQuestGiver, 5, horde, 0, "daily")
    call AddQuestRequirement(401, udg_CairneQuestGiver, 5, horde, 0, "daily") // Different ID, same quest type
    call AddQuestRequirement(402, udg_RexxarQuestGiver, 5, horde, 0, "daily")
    
    // All three NPCs will show the daily quest icon when available
endfunction
*/

//===========================================================================
