library QuestEvaluationSystem requires QuestIconSystem, Reputation
//===========================================================================
/*
    QuestEvaluationSystem 2.0 - Fully Automatic (Dummy Quest System)

    Author: [Valdemar]

    Description:
    This system AUTOMATICALLY shows quest availability icons for all configured NPCs.
    NO quest IDs needed! Uses dummy quests that show availability status.
    
    Simply configure which NPCs should show quests based on requirements:
    - Hero level (udg_Nazgrek and udg_Zulkis)
    - Reputation with factions
    - Custom conditions (events, flags, etc.)
    
    The system creates "dummy" quests that automatically show:
    - State 1: Gray/Red ! when requirements NOT met (unavailable)
    - State 2: Yellow/Blue ! when requirements ARE met (available)
    
    When player accepts a real quest, your quest triggers use QuestIconSystem
    to create actual quest with ID and manage states 3 (in progress), 5 (turn in).
    
    Configuration (ONE TIME SETUP):
    call AddQuestAvailability(npcUnit, minLevel, faction, minRep, "questType")
    
    Example:
    call AddQuestAvailability(udg_Thrall, 5, Faction.getFaction("Horde"), 3000, "normal")
    
    System shows availability icons automatically.
    Your quest triggers handle the actual quests separately (QuestIconSystem).
*/
//===========================================================================
globals
    private constant boolean DEBUG_MODE = false // Set to true to enable debug messages
    private constant real EVALUATION_INTERVAL = 5.0 // Check every 5 seconds
    private constant integer MAX_QUEST_SLOTS = 500
    private constant integer DUMMY_QUEST_OFFSET = 900000 // Large offset for dummy quest IDs
    
    // Reputation level constants (matching Reputation library)
    private constant integer REP_ENEMY = -20000
    private constant integer REP_HOSTILE = -12000
    private constant integer REP_UNFRIENDLY = -3000
    private constant integer REP_NEUTRAL = 0
    private constant integer REP_FRIENDLY = 3000
    private constant integer REP_COVENANT = 6000
    private constant integer REP_EXALTED = 12000
    
    // Quest availability data structures (indexed by slot)
    private unit array SlotNPC // Which NPC this slot is for
    private integer array SlotMinLevel // Minimum hero level required (0 = no requirement)
    private Faction array SlotRequiredFaction // Faction requirement (null = none)
    private integer array SlotMinReputation // Minimum reputation required
    private string array SlotQuestType // "normal", "daily", "repeatable", "dungeon"
    private trigger array SlotCustomCondition // Custom condition trigger (null = none)
    private integer array SlotLastState // Track last state to avoid unnecessary updates
    
    private integer SlotCount = 0
    
    // Player hero references
    private unit PlayerHero = null
    private unit PlayerHero2 = null
    
    private timer EvaluationTimer = CreateTimer()
    
    // Track unique NPCs for efficient evaluation
    private unit array UniqueNPCs
    private integer UniqueNPCCount = 0
endglobals

//===========================================================================
// HELPER: Check if NPC has any active quests (states 3 or 5) from QuestIconSystem
// Returns true if NPC has active quests managed by quest triggers
//===========================================================================
private function NPCHasActiveQuests takes unit npc returns boolean
    local integer npcId = GetHandleId(npc)
    local integer count = LoadInteger(QUEST_ICON_TABLE, npcId, NPC_QUEST_COUNT_KEY)
    local integer i = 0
    local integer existingState
    
    loop
        exitwhen i >= count
        set existingState = LoadInteger(QUEST_ICON_TABLE, npcId, i*100 + QUEST_STATE_KEY)
        
        if existingState == 3 or existingState == 5 then
            return true // NPC has active quest (in progress or ready to turn in)
        endif
        set i = i + 1
    endloop
    
    return false
endfunction

//===========================================================================
// HELPER: Get player reputation with faction
//===========================================================================
private function GetPlayerReputation takes player p, Faction f returns integer
    if f != 0 then
        return Reputation.getRep(p, f)
    endif
    return 0
endfunction

//===========================================================================
// HELPER: Check if quest requirements are met for a slot
//===========================================================================
private function CheckSlotRequirements takes integer slotIndex returns boolean
    local unit hero1 = PlayerHero
    local unit hero2 = PlayerHero2
    local integer heroLevel1 = 0
    local integer heroLevel2 = 0
    local integer heroLevel = 0
    local integer playerRep = 0
    local boolean customMet = true
    
    if slotIndex < 0 or slotIndex >= SlotCount then
        if DEBUG_MODE then
            call BJDebugMsg("    CheckReq: Invalid slot index " + I2S(slotIndex))
        endif
        return false
    endif
    
    // Check hero level requirement - use HIGHEST level between both heroes
    if hero1 != null then
        set heroLevel1 = GetHeroLevel(hero1)
    endif
    if hero2 != null then
        set heroLevel2 = GetHeroLevel(hero2)
    endif
    
    // Use the higher level
    if heroLevel1 > heroLevel2 then
        set heroLevel = heroLevel1
    else
        set heroLevel = heroLevel2
    endif
    
    if heroLevel > 0 then
        if DEBUG_MODE then
            call BJDebugMsg("    CheckReq: Hero level=" + I2S(heroLevel) + " (Nazgrek=" + I2S(heroLevel1) + ", Zulkis=" + I2S(heroLevel2) + "), required=" + I2S(SlotMinLevel[slotIndex]))
        endif
        if heroLevel < SlotMinLevel[slotIndex] then
            if DEBUG_MODE then
                call BJDebugMsg("    CheckReq: FAILED - level too low")
            endif
            return false
        endif
    else
        if DEBUG_MODE then
            call BJDebugMsg("    CheckReq: No heroes found!")
        endif
        // No heroes = can't meet level requirement
        if SlotMinLevel[slotIndex] > 0 then
            return false
        endif
    endif
    
    // Check reputation requirement
    if SlotRequiredFaction[slotIndex] != 0 then
        set playerRep = Reputation.getRep(Player(0), SlotRequiredFaction[slotIndex])
        if DEBUG_MODE then
            call BJDebugMsg("    CheckReq: Reputation=" + I2S(playerRep) + ", required=" + I2S(SlotMinReputation[slotIndex]))
        endif
        if playerRep < SlotMinReputation[slotIndex] then
            if DEBUG_MODE then
                call BJDebugMsg("    CheckReq: FAILED - reputation too low")
            endif
            return false
        endif
    else
        if DEBUG_MODE then
            call BJDebugMsg("    CheckReq: No faction requirement")
        endif
    endif
    
    // Check custom condition
    if SlotCustomCondition[slotIndex] != null then
        set customMet = TriggerEvaluate(SlotCustomCondition[slotIndex])
        if not customMet then
            if DEBUG_MODE then
                call BJDebugMsg("    CheckReq: FAILED - custom condition not met")
            endif
            return false
        endif
    endif
    
    if DEBUG_MODE then
        call BJDebugMsg("    CheckReq: PASSED - all requirements met!")
    endif
    return true
endfunction

//===========================================================================
// HELPER: Evaluate quest availability for a specific NPC
// Shows dummy quest icon: state 1 (unavailable) or state 2 (available)
//===========================================================================
private function EvaluateQuestsForNPC takes unit npc returns nothing
    local integer i = 0
    local integer dummyID = 0
    local boolean requirementsMet = false
    local integer newState = 0 // 0 = no quest configured, 1 = unavailable, 2 = available
    local string bestType = ""
    local boolean hasActiveQuests = false
    local string npcName = GetUnitName(npc)
    local boolean stateChanged = false
    local boolean foundQuest = false
    
    // Debug: Check if NPC is valid
    if npc == null then
        if DEBUG_MODE then
            call BJDebugMsg("QuestEval ERROR: NPC is null!")
        endif
        return
    endif
    
    // Check if NPC has any active quests from QuestIconSystem
    set hasActiveQuests = NPCHasActiveQuests(npc)
    
    if DEBUG_MODE then
        if hasActiveQuests then
            call BJDebugMsg("QuestEval: Checking " + npcName + " (hasActive=1)")
        else
            call BJDebugMsg("QuestEval: Checking " + npcName + " (hasActive=0)")
        endif
    endif
    
    if hasActiveQuests then
        // NPC has active quests - remove all dummy quest icons
        loop
            exitwhen i >= SlotCount
            if SlotNPC[i] == npc then
                set dummyID = DUMMY_QUEST_OFFSET + i
                if SlotLastState[i] != 0 then
                    call QuestIcon_RemoveQuest(npc, dummyID)
                    set SlotLastState[i] = 0
                    if DEBUG_MODE then
                        call BJDebugMsg("  Removed dummy quest (active quest exists)")
                    endif
                endif
            endif
            set i = i + 1
        endloop
    else
        // No active quests - check quest availability and show appropriate icon
        set i = 0
        loop
            exitwhen i >= SlotCount
            
            if SlotNPC[i] == npc then
                set foundQuest = true
                set requirementsMet = CheckSlotRequirements(i)
                
                if DEBUG_MODE then
                    if requirementsMet then
                        call BJDebugMsg("  Slot " + I2S(i) + ": reqMet=1, level=" + I2S(SlotMinLevel[i]))
                    else
                        call BJDebugMsg("  Slot " + I2S(i) + ": reqMet=0, level=" + I2S(SlotMinLevel[i]))
                    endif
                endif
                
                // Show state 2 (available) or state 1 (unavailable)
                if requirementsMet then
                    set newState = 2 // Available
                    set bestType = SlotQuestType[i]
                    set dummyID = DUMMY_QUEST_OFFSET + i
                    
                    // Only register if state changed
                    if SlotLastState[i] != 2 then
                        if DEBUG_MODE then
                            call BJDebugMsg("  -> Registering AVAILABLE quest: ID=" + I2S(dummyID) + ", type=" + bestType)
                        endif
                        call QuestIcon_RegisterQuest(npc, dummyID, bestType, 2)
                        set SlotLastState[i] = 2
                        set stateChanged = true
                    else
                        if DEBUG_MODE then
                            call BJDebugMsg("  -> Quest already available (no change)")
                        endif
                    endif
                    exitwhen true // Found an available quest, stop looking
                else
                    // Requirements not met - show state 1 (unavailable/gray exclamation)
                    set newState = 1 // Unavailable
                    set bestType = SlotQuestType[i]
                    set dummyID = DUMMY_QUEST_OFFSET + i
                    
                    // Only register if state changed
                    if SlotLastState[i] != 1 then
                        if DEBUG_MODE then
                            call BJDebugMsg("  -> Registering UNAVAILABLE quest: ID=" + I2S(dummyID) + ", type=" + bestType)
                        endif
                        call QuestIcon_RegisterQuest(npc, dummyID, bestType, 1)
                        set SlotLastState[i] = 1
                        set stateChanged = true
                    else
                        if DEBUG_MODE then
                            call BJDebugMsg("  -> Quest already unavailable (no change)")
                        endif
                    endif
                    exitwhen true // Found an unavailable quest, stop looking
                endif
            endif
            
            set i = i + 1
        endloop
        
        if not foundQuest then
            if DEBUG_MODE then
                call BJDebugMsg("  No quest configured for this NPC")
            endif
        endif
    endif
    
    // Only update icon display if state changed
    if stateChanged or hasActiveQuests then
        call QuestIcon_UpdateForNPC(npc)
    endif
endfunction

//===========================================================================
// PERIODIC EVALUATION
//===========================================================================
private function PeriodicEvaluation takes nothing returns nothing
    local integer i = 0
    
    loop
        exitwhen i >= UniqueNPCCount
        if UniqueNPCs[i] != null then
            call EvaluateQuestsForNPC(UniqueNPCs[i])
        endif
        set i = i + 1
    endloop
endfunction

//===========================================================================
// HELPER: Register NPC if not already registered
//===========================================================================
private function RegisterNPC takes unit npc returns nothing
    local integer i = 0
    local boolean found = false
    
    // Check if already registered
    loop
        exitwhen i >= UniqueNPCCount
        if UniqueNPCs[i] == npc then
            set found = true
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    // Add if not found
    if not found then
        set UniqueNPCs[UniqueNPCCount] = npc
        set UniqueNPCCount = UniqueNPCCount + 1
    endif
endfunction

//===========================================================================
// HELPER: Convert reputation level string to numeric value
//===========================================================================
private function GetReputationValue takes string repLevel returns integer
    if repLevel == "ENEMY" then
        return REP_ENEMY
    elseif repLevel == "HOSTILE" then
        return REP_HOSTILE
    elseif repLevel == "UNFRIENDLY" then
        return REP_UNFRIENDLY
    elseif repLevel == "NEUTRAL" then
        return REP_NEUTRAL
    elseif repLevel == "FRIENDLY" then
        return REP_FRIENDLY
    elseif repLevel == "COVENANT" then
        return REP_COVENANT
    elseif repLevel == "EXALTED" then
        return REP_EXALTED
    endif
    return REP_NEUTRAL // Default to neutral if unrecognized
endfunction

//===========================================================================
// HELPER: Add quest availability slot (simplified configuration)
//===========================================================================
private function AddQuestAvailability takes unit npc, integer minLevel, string factionName, string repLevel, string questType returns nothing
    if SlotCount >= MAX_QUEST_SLOTS then
        if DEBUG_MODE then
            call BJDebugMsg("QuestEvaluationSystem: MAX_QUEST_SLOTS limit reached!")
        endif
        return
    endif
    
    if npc == null then
        if DEBUG_MODE then
            call BJDebugMsg("QuestEval ERROR: Trying to add null NPC at slot " + I2S(SlotCount))
        endif
        return
    endif
    
    set SlotNPC[SlotCount] = npc
    set SlotMinLevel[SlotCount] = minLevel
    
    // Get faction object if faction name provided
    if factionName != "" then
        set SlotRequiredFaction[SlotCount] = Faction.getFaction(factionName)
    else
        set SlotRequiredFaction[SlotCount] = 0
    endif
    
    set SlotMinReputation[SlotCount] = GetReputationValue(repLevel)
    set SlotQuestType[SlotCount] = questType
    set SlotCustomCondition[SlotCount] = null
    set SlotLastState[SlotCount] = 0 // Initialize last state
    
    if DEBUG_MODE then
        call BJDebugMsg("QuestEval: Added slot " + I2S(SlotCount) + " for " + GetUnitName(npc) + " (level " + I2S(minLevel) + ", type=" + questType + ")")
    endif
    
    // Register this NPC for evaluation
    call RegisterNPC(npc)
    
    set SlotCount = SlotCount + 1
endfunction

//===========================================================================
// HELPER: Add custom condition to last added slot
//===========================================================================
private function AddAvailabilityCondition takes trigger conditionTrigger returns nothing
    if SlotCount > 0 then
        set SlotCustomCondition[SlotCount - 1] = conditionTrigger
    endif
endfunction

//===========================================================================
// ╔═══════════════════════════════════════════════════════════════════════╗
// ║                   CONFIGURATION SECTION                               ║
// ║                   CONFIGURE QUEST AVAILABILITY HERE                   ║
// ╚═══════════════════════════════════════════════════════════════════════╝
//===========================================================================
private function ConfigureQuestRequirements takes nothing returns nothing
    local Faction horde
    local Faction alliance
    local trigger customCondition
    
    // Get faction references (adjust to your faction names)
    set horde = Faction.getFaction("Horde")
    set alliance = Faction.getFaction("Alliance")
    
    //=======================================================================
    // ADD QUEST AVAILABILITY SLOTS BELOW - System handles everything!
    //=======================================================================
    
    // Format: call AddQuestAvailability(npcUnit, minLevel, "factionName", "repLevel", "questType")
    //
    // NOTE: This system uses DUMMY QUESTS for showing availability only.
    // Your actual quest triggers will create real quest IDs when needed.
    //
    // Parameters:
    //   npcUnit: The NPC unit variable (e.g., udg_Thrall, gg_unit_h000_0001)
    //   minLevel: Minimum hero level (0 = no requirement)
    //   factionName: Faction name string (e.g., "Horde", "Alliance") or "" for no faction
    //   repLevel: Reputation level string (see below)
    //   questType: "normal" or "daily" or "repeatable" or "dungeon"
    //
    // Reputation levels:
    //   "ENEMY" | "HOSTILE" | "UNFRIENDLY" | "NEUTRAL"
    //   "FRIENDLY" | "COVENANT" | "EXALTED"
    //
    // How it works:
    //   - If NPC has NO active quests: Shows availability icon (! or ?)
    //   - If NPC has active quests: Removes dummy icon automatically
    //   - When quest completes: Dummy icon reappears if requirements met

    //-----------------------------------------------------------------------
    // EXAMPLE QUEST AVAILABILITY SLOTS (uncomment and modify):
    //-----------------------------------------------------------------------
    
    // Slot 1: First quest available from level 1
    // call AddQuestAvailability(udg_Thrall, 1, "", "NEUTRAL", "normal")
    
    // Slot 2: Quest available from level 5 with Horde Friendly
    // call AddQuestAvailability(udg_Thrall, 5, "Horde", "FRIENDLY", "normal")
    
    // Slot 3: Daily quest, level 10
    // call AddQuestAvailability(udg_Jaina, 10, "", "NEUTRAL", "daily")
    
    // Slot 4: High level quest with Alliance Covenant requirement
    // call AddQuestAvailability(udg_Jaina, 15, "Alliance", "COVENANT", "dungeon")
    
    // Slot 5: Low level repeatable quest
    // call AddQuestAvailability(udg_Vendor, 3, "", "NEUTRAL", "repeatable")
    
    //-----------------------------------------------------------------------
    // EXAMPLE: Quest availability with custom condition
    //-----------------------------------------------------------------------
    
    // Define condition function first (outside this function, above)
    // function SlotCustom_Condition takes nothing returns boolean
    //     return udg_BossDefeated == true and udg_HasSpecialItem == true
    // endfunction
    
    // Then in this function:
    // set customCondition = CreateTrigger()
    // call TriggerAddCondition(customCondition, Condition(function SlotCustom_Condition))
    // call AddQuestAvailability(udg_SpecialNPC, 10, "Horde", "FRIENDLY", "normal")
    // call AddAvailabilityCondition(customCondition)
    
    //=======================================================================
    // ADD YOUR QUEST AVAILABILITY SLOTS HERE:
    //=======================================================================
    
    // call AddQuestAvailability(npcUnit, minLevel, "factionName", "repLevel", "normal")ABLE")
    
    call AddQuestAvailability(udg_BoomBrothers, 10, "", "NEUTRAL", "normal")
    call AddQuestAvailability(udg_Kribugs, 1, "", "NEUTRAL", "normal")
    call AddQuestAvailability(udg_Krezgrel, 1, "", "NEUTRAL", "normal")
    call AddQuestAvailability(udg_OutcastJinzun, 1, "", "NEUTRAL", "normal")
    call AddQuestAvailability(udg_Grum, 10, "Horde", "NEUTRAL", "normal")
    
endfunction

//===========================================================================
// PUBLIC API FOR GUI TRIGGERS - Dialog Condition Checks
//===========================================================================
/*
GUI USAGE EXAMPLES: 
Dialog - Show dialog button "Do you have quests?"
Conditions:
    (QuestEval_NPCHasAvailableQuest(udg_DialogNPC) Equal to TRUE)

Dialog - Show "Available Quest" button
Conditions:
    (QuestEval_GetNPCQuestState(udg_Thrall) Equal to 2)
    
Dialog - Show "Requirements not met" button  
Conditions:
    (QuestEval_GetNPCQuestState(udg_Thrall) Equal to 1)
    
====== Most Common: Dialog Button Condition
    Custom script:   if QuestEval_NPCHasAvailableQuest(udg_DialogNPC) then

====== Full GUI Example:
Dialog NPC Interaction
    Events
        Unit - A unit comes within 200.00 of udg_Thrall
    Conditions
    Actions
        Dialog - Clear MyDialog
        Dialog - Change the title of MyDialog to "Thrall"
        
        -------- Show quest button only if available --------
        Custom script:   if QuestEval_NPCHasAvailableQuest(udg_Thrall) then
            Dialog - Create a dialog button for MyDialog labelled "I'm looking for adventure."
            Set udg_QuestButton = (Last created dialog Button)
        Custom script:   endif
        
        Dialog - Create a dialog button for MyDialog labelled "Farewell"
        Dialog - Show MyDialog for Player 1 (Red)  
    
====== Checking Quest State (Advanced)
    Custom script:   if QuestEval_GetNPCQuestState(udg_Thrall) == 2 then
        Dialog - Create button "Accept Quest"
    Custom script:   elseif QuestEval_GetNPCQuestState(udg_Thrall) == 1 then
        Dialog - Create button "Requirements not met..."
    Custom script:   endif

====== Variable-Based Check (Easier for Multiple Uses)
    Actions:
        Custom script:   set udg_TempBoolean = QuestEval_NPCHasAvailableQuest(udg_Thrall)
        
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                udg_TempBoolean Equal to True
            Then - Actions
                Dialog - Create button "I have a quest for you!"
            Else - Actions
                -------- No quest available --------

    Custom script:   set udg_QuestState = QuestEval_GetNPCQuestState(udg_DialogNPC)

====== Storing State in Variable
    If (udg_QuestState Equal to 2) then
        -------- Has available quest --------
        Dialog - Create button...
    Else if (udg_QuestState Equal to 1) then  
        -------- Has quests but requirements not met --------
        Dialog - Create button "Come back when you're stronger..."
    Else
        -------- No quests configured --------

======  Inline One-Liners (No Variables Needed)
    -------- Simple yes/no check --------
    Custom script:   if QuestEval_NPCHasAvailableQuest(gg_unit_H001_0023) then
    Custom script:       call DialogAddButtonBJ(udg_MyDialog, "Quest Available!")
    Custom script:   endif

====== Complete working example 
    NPC Dialog - Thrall
        Events
            Unit - A unit Starts the effect of an ability
        Conditions
            (Ability being cast) Equal to Talk to NPC
            (Target unit of ability being cast) Equal to udg_Thrall
        Actions
            -------- Store the NPC unit --------
            Set udg_DialogNPC = (Target unit of ability being cast)
            
            -------- Check quest availability --------
            Custom script:   set udg_TempBoolean = QuestEval_NPCHasAvailableQuest(udg_DialogNPC)
            
            -------- Create Dialog --------
            Dialog - Clear udg_NPCDialog
            Dialog - Change the title of udg_NPCDialog to "Thrall"
            
            -------- Conditionally show quest button --------
            If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                If - Conditions
                    udg_TempBoolean Equal to True
                Then - Actions
                    Dialog - Create a dialog button for udg_NPCDialog labelled "Do you have any quests?"
                    Set udg_QuestDialogButton = (Last created dialog Button)
                Else - Actions
                    -------- No available quests, don't show button --------
            
            Dialog - Create a dialog button for udg_NPCDialog labelled "Goodbye"
            Dialog - Show udg_NPCDialog for (Owner of (Triggering unit))

Required Variables (example)
    Create these in Variable Editor if you use the examples above:

    udg_DialogNPC - Unit variable (the NPC being talked to)
    udg_TempBoolean - Boolean variable
    udg_QuestState - Integer variable
    udg_QuestButton - Dialog Button variable
*/

// Check if NPC has any available quests (most common use case)
function QuestEval_NPCHasAvailableQuest takes unit npc returns boolean
    local integer i = 0
    local boolean hasActiveQuests = NPCHasActiveQuests(npc)
    
    if hasActiveQuests then
        return false  // Has active quests, no availability icon showing
    endif
    
    // Check if any slot for this NPC has requirements met
    loop
        exitwhen i >= SlotCount
        if SlotNPC[i] == npc then
            if CheckSlotRequirements(i) then
                return true  // Found an available quest
            endif
        endif
        set i = i + 1
    endloop
    
    return false  // No available quests
endfunction

// Check specific quest slot availability
function QuestEval_IsSlotAvailable takes integer slotIndex returns boolean
    if slotIndex < 0 or slotIndex >= SlotCount then
        return false
    endif
    return CheckSlotRequirements(slotIndex)
endfunction

// Get NPC's quest state for dialog choices
// Returns: 0 = no quests configured, 1 = has unavailable quests, 2 = has available quests
function QuestEval_GetNPCQuestState takes unit npc returns integer
    local integer i = 0
    local boolean hasSlots = false
    local boolean hasActiveQuests = NPCHasActiveQuests(npc)
    
    if hasActiveQuests then
        return 0  // Active quests trump availability
    endif
    
    loop
        exitwhen i >= SlotCount
        if SlotNPC[i] == npc then
            set hasSlots = true
            if CheckSlotRequirements(i) then
                return 2  // Has available quest
            endif
        endif
        set i = i + 1
    endloop
    
    if hasSlots then
        return 1  // Has quest slots but not available
    endif
    
    return 0  // No quests configured
endfunction

// Force immediate update for a specific NPC (useful for respawns)
// Resets state tracking to force icon recreation
function QuestEval_ForceUpdateForNPC takes unit npc returns nothing
    local integer i = 0
    
    if npc == null then
        return
    endif
    
    // Reset state tracking for this NPC's slots to force icon recreation
    loop
        exitwhen i >= SlotCount
        if SlotNPC[i] == npc then
            set SlotLastState[i] = 0 // Reset to force re-registration
        endif
        set i = i + 1
    endloop
    
    // Now evaluate and create the icons
    call EvaluateQuestsForNPC(npc)
endfunction

// Update unit reference for respawned NPCs
// When a quest giver dies and respawns, update all slots to point to new unit instance
function QuestEval_UpdateUnitReference takes integer unitTypeId, unit newUnit returns nothing
    local integer i = 0
    local unit oldUnit
    
    if newUnit == null then
        return
    endif
    
    // Find all slots for this unit type and update them to the new unit instance
    loop
        exitwhen i >= SlotCount
        set oldUnit = SlotNPC[i]
        
        if oldUnit != null and GetUnitTypeId(oldUnit) == unitTypeId then
            // Update slot to point to new unit instance
            set SlotNPC[i] = newUnit
            set SlotLastState[i] = 0 // Reset state to force icon recreation
            
            if DEBUG_MODE then
                call BJDebugMsg("QuestEval: Updated slot " + I2S(i) + " to new unit instance (type: " + I2S(unitTypeId) + ")")
            endif
        endif
        
        set i = i + 1
    endloop
    
    set oldUnit = null
endfunction

//===========================================================================
// INITIALIZATION - Runs automatically when map loads
//===========================================================================
private function InitDelayed takes nothing returns nothing
    // Set player hero references
    set PlayerHero = udg_Nazgrek
    set PlayerHero2 = udg_Zulkis

    // Configure all quest availability slots (delayed to allow unit variables to initialize)
    call ConfigureQuestRequirements()
    
    // Start automatic periodic evaluation (every 5 seconds)
    call TimerStart(EvaluationTimer, EVALUATION_INTERVAL, true, function PeriodicEvaluation)
    
    // Do initial evaluation immediately after configuration
    call PeriodicEvaluation()
    
    // Display initialization message
    if DEBUG_MODE then
        call BJDebugMsg("|cff00ff00QuestEvaluationSystem initialized|r - " + I2S(SlotCount) + " availability slots configured for " + I2S(UniqueNPCCount) + " NPCs")
    endif
endfunction

function QuestEvaluateSystemInit takes nothing returns nothing
    // Delay configuration by 1 second to allow unit variables to initialize
    call TimerStart(CreateTimer(), 1.0, false, function InitDelayed)
endfunction

//===========================================================================
endlibrary
//===========================================================================
