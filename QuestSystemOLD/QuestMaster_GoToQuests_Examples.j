//===========================================================================
// QuestMaster GoToPlace/GoToZone Implementation Example
//===========================================================================
// This file shows complete working examples of how to use the new
// GoToPlace (with rect) and GoToZone quest templates with autocomplete.
//
// Copy and adapt these examples for your own quests!
//===========================================================================

//===========================================================================
// Example 1: GoToPlace Quest with Rect and Periodic Check
//===========================================================================

globals
    // Store quest ID for checking
    private integer QUEST_DISCOVER_GROVE = 0
endglobals

function CreateDiscoverGroveQuest takes nothing returns nothing
    local QuestData q
    local string giverName = "Aradion the Farseer"
    
    // Create quest using enhanced template with rect and autocomplete
    set q = QuestMaster_TemplateGoToPlaceRect(
        "Discover Twilight Grove",      // Quest name
        udg_Aradion,                     // Quest giver
        "normal",                        // Quest type
        8,                               // Quest level
        "the Twilight Grove",            // Place name (shown in objective)
        gg_rct_TwilightGrove,           // Target rect (player must enter this)
        true                             // Auto-complete (no need to return)
    )
    
    // Store quest ID for later checks
    set QUEST_DISCOVER_GROVE = q.id
    
    // Set quest details
    set q.title = "Discover the Twilight Grove"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
    set q.description = "Explore the mysterious Twilight Grove located north of Elarindor.\n\n"
    set q.infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
    set q.info2Text = "|cffffcc00Recommended level:|r 8\n\n"
    set q.requiredLevel = 5
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 150, false, 0, true, 300, false)
    call q.setReceiverDisplayName(giverName)
endfunction

function CheckDiscoverGroveQuest takes nothing returns nothing
    local group g = GetUnitsOfPlayerAll(Player(0))
    local unit u
    local QuestData q
    
    // Get quest data
    set q = QuestMaster_GetById(QUEST_DISCOVER_GROVE)
    
    // Only check if quest is active and not yet completed
    if q != 0 and q.active and not q.completed then
        loop
            set u = FirstOfGroup(g)
            exitwhen u == null
            call GroupRemoveUnit(g, u)
            
            if IsUnitType(u, UNIT_TYPE_HERO) then
                // Check if hero is in target rect
                if QuestMaster_CheckHeroInTargetRect(QUEST_DISCOVER_GROVE, u) then
                    // Mark objective complete
                    call QuestMaster_SetRequirementCompleted(QUEST_DISCOVER_GROVE, 1, true)
                    // Quest will auto-complete since autocomplete is enabled!
                    exitwhen true  // Stop checking once found
                endif
            endif
        endloop
    endif
    
    call DestroyGroup(g)
endfunction

function InitDiscoverGroveQuest takes nothing returns nothing
    local trigger t = CreateTrigger()
    
    // Create the quest
    call CreateDiscoverGroveQuest()
    
    // Set up periodic check (every 2 seconds)
    call TriggerRegisterTimerEvent(t, 2.0, true)
    call TriggerAddAction(t, function CheckDiscoverGroveQuest)
endfunction

//===========================================================================
// Example 2: GoToPlace Quest with Region Enter Event
//===========================================================================

globals
    private integer QUEST_FIND_RUINS = 0
endglobals

function OnEnterAncientRuins takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local QuestData q
    
    // Only process player heroes
    if not IsUnitType(u, UNIT_TYPE_HERO) or GetOwningPlayer(u) != Player(0) then
        return
    endif
    
    // Get quest data
    set q = QuestMaster_GetById(QUEST_FIND_RUINS)
    
    // Check if quest is active
    if q != 0 and q.active and not q.completed then
        // Verify hero is in the target rect (redundant here but good practice)
        if QuestMaster_CheckHeroInTargetRect(QUEST_FIND_RUINS, u) then
            call QuestMaster_SetRequirementCompleted(QUEST_FIND_RUINS, 1, true)
            // Quest auto-completes!
        endif
    endif
endfunction

function CreateFindRuinsQuest takes nothing returns nothing
    local QuestData q
    local trigger t
    local string giverName = "Elder Valeros"
    
    // Create quest
    set q = QuestMaster_TemplateGoToPlaceRect(
        "Find Ancient Ruins",
        udg_ElderValeros,
        "normal",
        12,
        "the Ancient Ruins",
        gg_rct_AncientRuins,
        true  // Auto-complete
    )
    
    set QUEST_FIND_RUINS = q.id
    
    set q.title = "Find the Ancient Ruins"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNAncientRelic.blp"
    set q.description = "Discover the ancient ruins hidden in the eastern mountains.\n\n"
    set q.infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
    set q.info2Text = "|cffffcc00Recommended level:|r 12\n\n"
    set q.requiredLevel = 10
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 200, false, 0, true, 400, false)
    call q.setReceiverDisplayName(giverName)
    
    // Register region enter event for instant response
    set t = CreateTrigger()
    call TriggerRegisterEnterRectSimple(t, gg_rct_AncientRuins)
    call TriggerAddAction(t, function OnEnterAncientRuins)
endfunction

//===========================================================================
// Example 3: GoToZone Quest
//===========================================================================

globals
    private integer QUEST_ENTER_DEADWOODS = 0
endglobals

function CheckEnterDeadwoodsQuest takes nothing returns nothing
    local QuestData q = QuestMaster_GetById(QUEST_ENTER_DEADWOODS)
    local integer currentZone
    
    // Check if quest is active
    if q != 0 and q.active and not q.completed then
        // Get current zone from ZoneEvent system
        set currentZone = ZoneEvent_GetCurrentZone()
        
        // Check if player is in target zone
        if QuestMaster_CheckHeroInTargetZone(QUEST_ENTER_DEADWOODS, currentZone) then
            call QuestMaster_SetRequirementCompleted(QUEST_ENTER_DEADWOODS, 1, true)
            // Quest auto-completes!
        endif
    endif
endfunction

function CreateEnterDeadwoodsQuest takes nothing returns nothing
    local QuestData q
    local trigger t
    local string giverName = "Ranger Valeria"
    
    // Create zone-based quest
    // Zone ID 11 = Deadwoods (check your ZonesCore.j for zone IDs)
    set q = QuestMaster_TemplateGoToZone(
        "Enter the Deadwoods",
        udg_RangerValeria,
        "normal",
        15,
        "Deadwoods",  // Zone name for objective text
        11,           // Zone ID from ZonesCore
        true          // Auto-complete
    )
    
    set QUEST_ENTER_DEADWOODS = q.id
    
    set q.title = "Journey to the Deadwoods"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHaunt.blp"
    set q.description = "Travel to the dark and haunted Deadwoods forest.\n\n"
    set q.infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
    set q.info2Text = "|cffffcc00Recommended level:|r 15\n\n"
    set q.requiredLevel = 13
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 250, false, 0, true, 500, false)
    call q.setReceiverDisplayName(giverName)
    
    // Set up periodic check
    set t = CreateTrigger()
    call TriggerRegisterTimerEvent(t, 2.0, true)
    call TriggerAddAction(t, function CheckEnterDeadwoodsQuest)
endfunction

//===========================================================================
// Example 4: Multiple GoToPlace Quests (Quest Chain)
//===========================================================================

globals
    private integer QUEST_TOUR_1 = 0  // Visit Grove
    private integer QUEST_TOUR_2 = 0  // Visit Vale
    private integer QUEST_TOUR_3 = 0  // Visit Plains
endglobals

function CheckTourQuests takes nothing returns nothing
    local group g = GetUnitsOfPlayerAll(Player(0))
    local unit u
    local QuestData q1 = QuestMaster_GetById(QUEST_TOUR_1)
    local QuestData q2 = QuestMaster_GetById(QUEST_TOUR_2)
    local QuestData q3 = QuestMaster_GetById(QUEST_TOUR_3)
    
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        
        if IsUnitType(u, UNIT_TYPE_HERO) then
            // Check Quest 1: Visit Grove
            if q1 != 0 and q1.active and not q1.completed then
                if QuestMaster_CheckHeroInTargetRect(QUEST_TOUR_1, u) then
                    call QuestMaster_SetRequirementCompleted(QUEST_TOUR_1, 1, true)
                endif
            endif
            
            // Check Quest 2: Visit Vale (unlocked after Quest 1)
            if q2 != 0 and q2.active and not q2.completed then
                if QuestMaster_CheckHeroInTargetRect(QUEST_TOUR_2, u) then
                    call QuestMaster_SetRequirementCompleted(QUEST_TOUR_2, 1, true)
                endif
            endif
            
            // Check Quest 3: Visit Plains (unlocked after Quest 2)
            if q3 != 0 and q3.active and not q3.completed then
                if QuestMaster_CheckHeroInTargetRect(QUEST_TOUR_3, u) then
                    call QuestMaster_SetRequirementCompleted(QUEST_TOUR_3, 1, true)
                endif
            endif
        endif
    endloop
    
    call DestroyGroup(g)
endfunction

function CreateTourQuests takes nothing returns nothing
    local QuestData q
    local trigger t
    local string giverName = "Guide Elara"
    
    // Quest 1: Visit Twilight Grove
    set q = QuestMaster_TemplateGoToPlaceRect(
        "Tour: Twilight Grove",
        udg_GuideElara,
        "normal",
        5,
        "the Twilight Grove",
        gg_rct_TwilightGrove,
        true
    )
    set QUEST_TOUR_1 = q.id
    set q.title = "Guided Tour: Twilight Grove"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
    set q.description = "Visit the Twilight Grove as part of your introduction to the region.\n\n"
    set q.requiredLevel = 1
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
    call q.setReceiverDisplayName(giverName)
    
    // Quest 2: Visit Vanguard Vale (requires Quest 1 complete)
    set q = QuestMaster_TemplateGoToPlaceRect(
        "Tour: Vanguard Vale",
        udg_GuideElara,
        "normal",
        5,
        "Vanguard Vale",
        gg_rct_VanguardVale,
        true
    )
    set QUEST_TOUR_2 = q.id
    set q.title = "Guided Tour: Vanguard Vale"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
    set q.description = "Visit Vanguard Vale to continue your tour.\n\n"
    set q.requiredLevel = 1
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
    call q.setReceiverDisplayName(giverName)
    // Add requirement: Must complete Quest 1 first
    call QuestMaster_SetEventFlag(100, false)  // Use event flag as gate
    
    // Quest 3: Visit Verdant Plains (requires Quest 2 complete)
    set q = QuestMaster_TemplateGoToPlaceRect(
        "Tour: Verdant Plains",
        udg_GuideElara,
        "normal",
        5,
        "the Verdant Plains",
        gg_rct_VerdantPlains,
        true
    )
    set QUEST_TOUR_3 = q.id
    set q.title = "Guided Tour: Verdant Plains"
    set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
    set q.description = "Complete your tour by visiting the Verdant Plains.\n\n"
    set q.requiredLevel = 1
    call q.setFaction("Elarindor")
    call q.setRewardParams(true, 0, true, 100, false, 0, true, 200, false)
    call q.setReceiverDisplayName(giverName)
    
    // Set up periodic check for all tour quests
    set t = CreateTrigger()
    call TriggerRegisterTimerEvent(t, 2.0, true)
    call TriggerAddAction(t, function CheckTourQuests)
endfunction

//===========================================================================
// Example 5: Converting Existing GoToPlace Quest to Use Rect
//===========================================================================

function UpgradeExistingQuestToUseRect takes nothing returns nothing
    local QuestData q
    
    // Get existing quest by name and giver
    set q = QuestMaster_GetByNameAndGiver("Quest Name", udg_QuestGiver)
    
    if q != 0 then
        // Enable autocomplete
        call QuestMaster_SetAutoCompleteByNameAndGiver("Quest Name", udg_QuestGiver, true)
        
        // Set target rect
        call QuestMaster_SetTargetRectByNameAndGiver("Quest Name", udg_QuestGiver, gg_rct_TargetLocation)
        
        // Now you can check if hero is in rect
        // (Add periodic check or region enter trigger)
    endif
endfunction

//===========================================================================
// Initialization
//===========================================================================

function InitGoToQuestExamples takes nothing returns nothing
    // Initialize all example quests
    // Uncomment the ones you want to use:
    
    // call InitDiscoverGroveQuest()
    // call CreateFindRuinsQuest()
    // call CreateEnterDeadwoodsQuest()
    // call CreateTourQuests()
endfunction
