library QuestIconSystem
//===========================================================================
/*
    QuestIconSystem 1.1

    Author: [Valdemar]

    Description:
    This system handles the visual display of overhead quest icons on quest giver units, such as question marks and exclamation points.
    Icons update dynamically based on quest availability, progress, and completion, including daily quests.

    Supported Icons:
    - Yellow Exclamation (!)  → New quest available (Normal/Dungeon)
    - Blue Exclamation (!)    → New quest available (Daily/Repeatable)
    - Yellow Question (?)     → Ready to turn in (Normal/Dungeon)
    - Blue Question (?)       → Ready to turn in (Daily/Repeatable)
    - Gray Question (?)       → Completed but not turned in (state 3)
    - Gray Exclamation (!)    → Unavailable quests (state 1)

    Quest States 1-5:
    1 = unavailable
    2 = available
    3 = in Progress
    4 = complete (No quests)
    5 = ready to turn in

    Quest Types:
    "normal", "daily", "repeatable", "dungeon"

    API:
    - call QuestIcon_RegisterQuest(unit u, integer questID, string questType, integer questState)
    - call QuestIcon_RemoveQuest(unit u, integer questID)
    - call QuestIcon_UpdateForNPC(unit u)
    - call QuestIcon_RefreshIcon(unit u, integer questID, string questType, integer questState) 
    - call QuestIcon_UpdateForNPC(u)   

    Dummy Quest Icons:
    - call CreateDummyQuestIcon(unit u, string questType, integer questState)
    - call RemoveDummyQuestIcon(unit u)

    E.g, to register dummy "normal" quest:
    call CreateDummyQuestIcon(udg_unitXXX, "normal", 2)
*/ 
//===========================================================================
globals
    private hashtable QUEST_ICON_TABLE = InitHashtable()

    // Model paths
    private constant string QUEST_ICON_MODEL_YELLOW_EXCLAMATION = "war3campImported\\ExcMark_Gold_NonrepeatableQuest.mdl"
    private constant string QUEST_ICON_MODEL_BLUE_EXCLAMATION   = "war3campImported\\ExcMark_Blue_RepetableQuest.mdl"
    private constant string QUEST_ICON_MODEL_YELLOW_QUESTION    = "war3campImported\\Completed_Quest.mdl"
    private constant string QUEST_ICON_MODEL_BLUE_QUESTION      = "war3campImported\\Completed_Quest_Daily.mdl" 
    private constant string QUEST_ICON_MODEL_GRAY_QUESTION      = "war3campImported\\Completed_Quest_NOT.mdl"
    private constant string QUEST_ICON_MODEL_GRAY_EXCLAMATION   = "war3campImported\\ExcMark_Grey_UnavailableQuest.mdl"

    private integer QUEST_ICON_EFFECT_ID = StringHash("effect")
    private integer QUEST_ICON_MINIMAP_ID = StringHash("minimaps")
    private integer QUEST_ICON_QUESTS_ID = StringHash("quests")

    private minimapicon array QuestIconMapPing // indexed by unit handle ID or other way
    private integer MinimapIconIndex = 0

    // ---- per-unit quest list key offsets ----
    // Each unit stores an indexed list of quests. For index i:
    // childKey = i*100 + QUEST_ID_KEY  -> saved questID (integer)
    // childKey = i*100 + QUEST_TYPE_KEY -> saved questType (string)
    // childKey = i*100 + QUEST_STATE_KEY-> saved questState (integer)
    private integer QUEST_ID_KEY = 1
    private integer QUEST_TYPE_KEY = 2
    private integer QUEST_STATE_KEY = 3
    private integer NPC_QUEST_COUNT_KEY = 4

    constant integer QUEST_PRIORITY_STATE_5 = 5 // Ready to turn in
    constant integer QUEST_PRIORITY_STATE_2 = 4 // Available
    constant integer QUEST_PRIORITY_STATE_3 = 3 // Completed (gray ?)
    constant integer QUEST_PRIORITY_STATE_1 = 2 // Unavailable
    constant integer QUEST_PRIORITY_STATE_4 = 1 // Complete (no quests)

    constant integer DUMMY_OFFSET = 1000 // Offset for dummy quest IDs to avoid conflicts with real quests

endglobals

//===========================================================================
// STORE QUEST MINIMAP ICON
// Store minimap/world-map quest ping for a unit
function StoreQuestMinimapIcon takes unit u, minimapicon mi returns nothing
    //set QuestIconMapPing[GetHandleId(u)] = mi - OLD WAY
    //call SaveHandle(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_MINIMAP_ID, mi)

    if mi != null then
        set QuestIconMapPing[MinimapIconIndex] = mi
        call SaveInteger(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_MINIMAP_ID, MinimapIconIndex)
        set MinimapIconIndex = MinimapIconIndex + 1
    endif

endfunction
//===========================================================================
// GET QUEST MINIMAP ICON
// Get minimap/world-map quest ping for a unit
// This function retrieves the minimap icon associated with a unit.
private function GetQuestMinimapIcon takes unit u returns minimapicon
    local integer index = LoadInteger(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_MINIMAP_ID)

    //return QuestIconMapPing[GetHandleId(u)] - OLD WAY
    //return LoadHandle(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_MINIMAP_ID)

    if index >= 0 and index < MinimapIconIndex then
        return QuestIconMapPing[index]
    endif
    return null

endfunction
//===========================================================================
// REMOVE OLD MINIMAP ICON
// Remove old minimap/world-map quest ping
// This function removes the minimap icon associated with a unit, if it exists.
// It checks if the icon exists, destroys it, and sets the reference to null.
private function RemoveOldMapPing takes unit u returns nothing
    //local minimapicon mi = GetQuestMinimapIcon(u)
    local integer index = LoadInteger(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_MINIMAP_ID)

    /* OLD WAY
    if mi != null then
        call DestroyMinimapIcon(mi)
        // set QuestIconMapPing[GetHandleId(u)] = null - OLD WAY
        // remove saved handle so future lookups return null
        call RemoveSavedHandle(QUEST_ICON_TABLE, GetHandleId(u), QUEST_MINIMAPICON_ID)
    endif
    */

    if index >= 0 and index < MinimapIconIndex then
        call DestroyMinimapIcon(QuestIconMapPing[index])
        set QuestIconMapPing[index] = null
        call RemoveSavedInteger(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_MINIMAP_ID)
    endif

endfunction
//===========================================================================
// CREATE MAP PING FOR UNIT
// This function creates a minimap icon for a unit based on the specified style.
// It first removes any existing icon, then creates a new one using the CampaignMinimapIconUnitBJ function.
// The created icon is then stored in the hashtable for later retrieval.
private function CreateMapPingForUnit takes unit u, integer style returns nothing
    local minimapicon qi

    // always remove previous map icon
    call RemoveOldMapPing(u)

    // create new minimap icon
    call CampaignMinimapIconUnitBJ(u, style)
    set qi = GetLastCreatedMinimapIcon()
    if qi != null then
        call StoreQuestMinimapIcon(u, qi)
    else
        // optional debug message if the creation failed
        //call BJDebugMsg("CreateMapPingForUnit: GetLastCreatedMinimapIcon returned null for unit " + I2S(GetHandleId(u)))
    endif 
endfunction
//===========================================================================
// REMOVE QUEST MARKER EFFECT
// Store overhead quest icon effect for a unit
private function RemoveOldEffect takes unit u returns nothing
    local integer id = GetHandleId(u)
    local effect old = LoadEffectHandle(QUEST_ICON_TABLE, id, QUEST_ICON_EFFECT_ID)
    if old != null then
        call DestroyEffect(old)
        call RemoveSavedHandle(QUEST_ICON_TABLE, id, QUEST_ICON_EFFECT_ID)
    endif
endfunction
//===========================================================================
// REFRESH ICON FUNCTION
// This function refreshes the overhead icon for a unit based on its quest state and type.
// It first removes any existing icon and minimap ping, then determines the correct icon model and ping style based on the quest state and type.
// It then attaches the new icon effect to the unit and creates a minimap/world map ping if needed.
// The function handles different quest states (available, in progress, ready to turn in) and types (normal, daily, repeatable, dungeon).
// It uses predefined model paths for the icons and applies the appropriate minimap ping style. 
function QuestIcon_RefreshIcon takes unit u, integer questID, string questType, integer questState returns nothing
    local string model = ""
    local effect e
    local integer pingStyle = -1 // -1 → no minimap ping

    // Clean previous icons
    call RemoveOldEffect(u)
    call RemoveOldMapPing(u)

    //  Icon logic
    // Unavailable (gray exclamation)
    if questState == 1 then
        set model = QUEST_ICON_MODEL_GRAY_EXCLAMATION
        set pingStyle = bj_CAMPPINGSTYLE_BONUS

    // Available (exclamation)
    elseif questState == 2 then                         
        if questType == "daily" or questType == "repeatable" then
            set model = QUEST_ICON_MODEL_BLUE_EXCLAMATION
        elseif questType == "normal" or questType == "dungeon" then
            set model = QUEST_ICON_MODEL_YELLOW_EXCLAMATION
        else
            set model = QUEST_ICON_MODEL_GRAY_EXCLAMATION
        endif
        set pingStyle = bj_CAMPPINGSTYLE_BONUS

    // In progress but not ready to turn in
    elseif questState == 3 then               
        set model = QUEST_ICON_MODEL_GRAY_QUESTION
        // gray question ping (note there are no grey question pings, so we just use regular bonus ping)
        set pingStyle = bj_CAMPPINGSTYLE_BONUS       

    // Ready to turn in
    elseif questState == 5 then                         
        if questType == "daily" or questType == "repeatable" then
            set model = QUEST_ICON_MODEL_BLUE_QUESTION
        elseif questType == "normal" or questType == "dungeon" then
            set model = QUEST_ICON_MODEL_YELLOW_QUESTION
        else
            set model = QUEST_ICON_MODEL_GRAY_QUESTION
        endif
        set pingStyle = bj_CAMPPINGSTYLE_TURNIN

    endif

    // Attach overhead icon if needed
    if model != "" then
        set e = AddSpecialEffectTarget(model, u, "overhead")
        call SaveEffectHandle(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_EFFECT_ID, e)
    endif

    // Create minimap/world map ping if needed
    if pingStyle != -1 then
        call CreateMapPingForUnit(u, pingStyle)
    endif
endfunction
//===========================================================================
// QUEST ICON STATE PRIORITY FUNCTION
// Map state to priority score (so we can compare easily)
private function QuestIcon_StatePriority takes integer state returns integer
    if state == 5 then
        return QUEST_PRIORITY_STATE_5
    elseif state == 2 then
        return QUEST_PRIORITY_STATE_2
    elseif state == 3 then
        return QUEST_PRIORITY_STATE_3
    elseif state == 1 then
        return QUEST_PRIORITY_STATE_1
    endif
    return QUEST_PRIORITY_STATE_4 // state == 4
endfunction
//===========================================================================
// QUEST TYPE PRIORITY FUNCTION
// Quest type priority: higher = more important
private function QuestIcon_TypePriority takes string questType returns integer
    if questType == "normal" or questType == "dungeon" then
        return 3
    elseif questType == "daily" or questType == "repeatable" then
        return 2
    endif
    return 1 // others
endfunction
//===========================================================================
// QUEST ICON UPDATE FOR NPC
// Scans all quests for this NPC and picks the best one for display
function QuestIcon_UpdateForNPC takes unit u returns nothing
    local integer questID
    local integer questCount
    local integer i = 0
    local integer bestState = 4 // default to "complete" (no icon)
    local string bestType = ""
    local integer statePriority
    local integer typePriority
    local integer bestStatePriority = 0
    local integer bestTypePriority = 0
    local integer id = GetHandleId(u)
    local integer curState = 4
    local string curType = ""

    // Get number of quests for this NPC (per-unit stored count)
    set questCount = LoadInteger(QUEST_ICON_TABLE, id, NPC_QUEST_COUNT_KEY)

    loop
        exitwhen i >= questCount

        // Get questID for index (stored per-unit)
        set questID = LoadInteger(QUEST_ICON_TABLE, id, i*100 + QUEST_ID_KEY)

        // Get quest state & type from the same per-unit list
        set curState = LoadInteger(QUEST_ICON_TABLE, id, i*100 + QUEST_STATE_KEY)
        set curType = LoadStr(QUEST_ICON_TABLE, id, i*100 + QUEST_TYPE_KEY)

        // Convert to priorities for comparison
        set statePriority = QuestIcon_StatePriority(curState)
        set typePriority = QuestIcon_TypePriority(curType)

        // Compare to current best
        if statePriority > bestStatePriority or (statePriority == bestStatePriority and typePriority > bestTypePriority) then
            set bestStatePriority = statePriority
            set bestTypePriority = typePriority
            set bestState = curState
            set bestType = curType
        endif

        set i = i + 1
    endloop

    // Now draw icon if not "complete" (state == 4)
    if bestState != 4 then
        call QuestIcon_RefreshIcon(u, -1, bestType, bestState)
    else
        call RemoveOldEffect(u)
        call RemoveOldMapPing(u)
    endif
endfunction
//===========================================================================
// QUEST ICON REGISTER QUEST
// Public API
// This function registers a quest with a unit, allowing the system to track the quest's type and state.
// It saves the quest type and state in a hashtable under two nearby keys (questID*10 + offset).
// The first key stores the quest type as a string, and the second key stores the quest state as an integer.
// This allows the system to easily retrieve and update quest information for the unit.
function QuestIcon_RegisterQuest takes unit u, integer questID, string questType, integer questState returns nothing
    local integer id = GetHandleId(u)
    local integer count = LoadInteger(QUEST_ICON_TABLE, id, NPC_QUEST_COUNT_KEY)
    local integer i = 0
    local integer existingQuestID = 0
    local boolean updated = false

    // Search for existing quest entry — update if found
    loop
        exitwhen i >= count
        set existingQuestID = LoadInteger(QUEST_ICON_TABLE, id, i*100 + QUEST_ID_KEY)
        if existingQuestID == questID then
            // update type & state
            call SaveStr(QUEST_ICON_TABLE, id, i*100 + QUEST_TYPE_KEY, questType)
            call SaveInteger(QUEST_ICON_TABLE, id, i*100 + QUEST_STATE_KEY, questState)
            set updated = true
            exitwhen true
        endif
        set i = i + 1
    endloop

    // If not found, append at the end
    if not updated then
        call SaveInteger(QUEST_ICON_TABLE, id, count*100 + QUEST_ID_KEY, questID)
        call SaveStr(QUEST_ICON_TABLE, id, count*100 + QUEST_TYPE_KEY, questType)
        call SaveInteger(QUEST_ICON_TABLE, id, count*100 + QUEST_STATE_KEY, questState)
        call SaveInteger(QUEST_ICON_TABLE, id, NPC_QUEST_COUNT_KEY, count + 1)
    endif

    // Refresh icons for this NPC
    call QuestIcon_UpdateForNPC(u)
endfunction
//===========================================================================
// REMOVE QUEST FROM UNIT
// This function removes a quest from a unit by deleting the saved type and state.
// It uses the same keys as QuestIcon_RegisterQuest to remove the quest type and state. 
function QuestIcon_RemoveQuest takes unit u, integer questID returns nothing
    local integer id = GetHandleId(u)
    local integer count = LoadInteger(QUEST_ICON_TABLE, id, NPC_QUEST_COUNT_KEY)
    local integer i = 0
    local integer j = 0
    local integer foundIndex = -1
    local integer curID = 0

    // Find quest index
    loop
        exitwhen i >= count
        set curID = LoadInteger(QUEST_ICON_TABLE, id, i*100 + QUEST_ID_KEY)
        if curID == questID then
            set foundIndex = i
            exitwhen true
        endif
        set i = i + 1
    endloop

    if foundIndex == -1 then
        // not found, nothing to do
        return
    endif

    // Shift subsequent entries down to fill the hole
    set j = foundIndex
    loop
        exitwhen j >= count - 1
        // copy j+1 -> j
        call SaveInteger(QUEST_ICON_TABLE, id, j*100 + QUEST_ID_KEY, LoadInteger(QUEST_ICON_TABLE, id, (j+1)*100 + QUEST_ID_KEY))
        call SaveStr(QUEST_ICON_TABLE, id, j*100 + QUEST_TYPE_KEY, LoadStr(QUEST_ICON_TABLE, id, (j+1)*100 + QUEST_TYPE_KEY))
        call SaveInteger(QUEST_ICON_TABLE, id, j*100 + QUEST_STATE_KEY, LoadInteger(QUEST_ICON_TABLE, id, (j+1)*100 + QUEST_STATE_KEY))
        set j = j + 1
    endloop

    // Remove last now-duplicated slot
    call RemoveSavedInteger(QUEST_ICON_TABLE, id, (count-1)*100 + QUEST_ID_KEY)
    call RemoveSavedString(QUEST_ICON_TABLE, id, (count-1)*100 + QUEST_TYPE_KEY)
    call RemoveSavedInteger(QUEST_ICON_TABLE, id, (count-1)*100 + QUEST_STATE_KEY)

    // Decrement count
    call SaveInteger(QUEST_ICON_TABLE, id, NPC_QUEST_COUNT_KEY, count - 1)

    // Refresh icons for this NPC
    call QuestIcon_UpdateForNPC(u)
endfunction
//===========================================================================
// Dummy Quest Icon Function
// Creates a dummy quest icon for a unit with type and state
function CreateDummyQuestIcon takes unit u, string questType, integer questState returns nothing
    local integer dummyID = R2I(GetUnitUserData(u)) + DUMMY_OFFSET
    // Register dummy quest so the system has something to show
    call QuestIcon_RegisterQuest(u, dummyID, questType, questState)
endfunction

//===========================================================================
// REMOVE DUMMY QUEST ICON
// Removes any dummy quest icon attached to the unit
function RemoveDummyQuestIcon takes unit u returns nothing
    local integer dummyQuestID = DUMMY_OFFSET + R2I(GetUnitUserData(u))
    call QuestIcon_RemoveQuest(u, dummyQuestID)
endfunction
//===========================================================================
// PRIORITY COMPARISON FUNCTION
// This function compares two quest states and types to determine which one has a higher priority.
// Using the corrected states (1=unavailable,2=available,3=in progress,4=complete)
// Priority (state): 2 (available) > 4 (complete/turned-in/finished) > 1 (unavailable/gray) > 3 (in progress)
// This function checks if quest A has a higher priority than quest B based on their states and types.
private function QuestPriority takes string questType, integer questState returns integer
    local integer priority = 0
    // State priority order: 5 > 2 > 3 > 1 > 4 (4 = no icon)
    if questState == 5 then
        set priority = 500
    elseif questState == 2 then
        set priority = 400
    elseif questState == 3 then
        set priority = 300
    elseif questState == 1 then
        set priority = 200
    elseif questState == 4 then
        set priority = 100
    endif

    // Add quest type weight within same state:
    // Normal/Dungeon highest, then Daily/Repeatable, then others
    if questType == "normal" or questType == "dungeon" then
        set priority = priority + 30
    elseif questType == "daily" or questType == "repeatable" then
        set priority = priority + 20
    else
        set priority = priority + 10
    endif

    return priority
endfunction
//===========================================================================
endlibrary
//===========================================================================