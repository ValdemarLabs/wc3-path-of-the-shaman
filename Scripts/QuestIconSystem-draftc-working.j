library QuestIconSystem
//===========================================================================
/*
    QuestIconSystem 1.0

    Author: [Your Name]

    Description:
    This system handles the visual display of overhead quest icons on quest giver units, such as question marks and exclamation points.
    Icons update dynamically based on quest availability, progress, and completion, including daily quests.

    Supported Icons:
    - Yellow Exclamation (!)  → New quest available (Normal/Repeatable/Dungeon)
    - Blue Exclamation (!)    → New daily quest available
    - Yellow Question (?)     → Normal quest ready to turn in
    - Blue Question (?)       → Daily quest ready to turn in
    - Gray Question (?)       → Quest completed but already turned in (for non-repeatables)
    - Gray Exclamation (!)    → Quest(s) unavailable yet

    Quest States:
    1 = Available
    2 = In Progress
    3 = Completed (Ready to turn in)
    4 = Turned In

    Quest Types:
    "Normal", "Daily", "Repeatable", "Dungeon"

    API:
    - call QuestIcon_RegisterQuest(unit u, integer questID)
    - call QuestIcon_RemoveQuest(unit u, integer questID)
    - call QuestIcon_RefreshIcon(unit u, integer questID, string questType, integer questState)
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

    private group QUEST_ICON_TEMP_GROUP = CreateGroup()
    private integer QUEST_ICON_EFFECT_ID = StringHash("effect")
    private integer QUEST_ICON_QUESTS_ID = StringHash("quests")

    private minimapicon array QuestIconMapPing // indexed by unit handle ID or other way

endglobals

//===========================================================================
function QuestIcon_RegisterQuest takes unit u, integer questID returns nothing
    call SaveInteger(QUEST_ICON_TABLE, GetHandleId(u), questID, 1)
endfunction
//===========================================================================
function QuestIcon_RemoveQuest takes unit u, integer questID returns nothing
    call RemoveSavedInteger(QUEST_ICON_TABLE, GetHandleId(u), questID)
endfunction
//===========================================================================
private function RemoveOldEffect takes unit u returns nothing
    local integer id = GetHandleId(u)
    local effect old = LoadEffectHandle(QUEST_ICON_TABLE, id, QUEST_ICON_EFFECT_ID)
    if old != null then
        call DestroyEffect(old)
        call RemoveSavedHandle(QUEST_ICON_TABLE, id, QUEST_ICON_EFFECT_ID)
    endif
endfunction
//===========================================================================
function StoreQuestMinimapIcon takes unit u, minimapicon mi returns nothing
    set QuestIconMapPing[GetHandleId(u)] = mi
endfunction
//===========================================================================
private function GetQuestMinimapIcon takes unit u returns minimapicon
    return QuestIconMapPing[GetHandleId(u)]
endfunction
//===========================================================================
// Remove old minimap/world-map quest ping
private function RemoveOldMapPing takes unit u returns nothing
    local minimapicon mi = GetQuestMinimapIcon(u)
    if mi != null then
        call DestroyMinimapIcon(mi)
        set QuestIconMapPing[GetHandleId(u)] = null
    endif
endfunction
//===========================================================================
// Create a minimap/world-map quest ping on the unit
private function CreateMapPingForUnit takes unit u, integer style returns nothing
    local minimapicon qi

    call RemoveOldMapPing(u)
    call CampaignMinimapIconUnitBJ(u, style)
    set qi = GetLastCreatedMinimapIcon()
    call StoreQuestMinimapIcon(u, qi)
endfunction
//===========================================================================
// Refresh both overhead and minimap quest icons based on state/type
function QuestIcon_RefreshIcon takes unit u, integer questID, string questType, integer questState returns nothing
    local string model = ""
    local effect e
    local integer pingStyle = -1 // -1 → no minimap ping

    // Clean previous icons
    call RemoveOldEffect(u)
    call RemoveOldMapPing(u)

    // Choose appropriate overhead icon and ping style
    if questState == 1 then
        if questType == "daily" then
            set model = QUEST_ICON_MODEL_BLUE_EXCLAMATION
        elseif questType == "normal" or questType == "repeatable" or questType == "dungeon" then
            set model = QUEST_ICON_MODEL_YELLOW_EXCLAMATION
        else
            set model = QUEST_ICON_MODEL_GRAY_EXCLAMATION
        endif
        set pingStyle = bj_CAMPPINGSTYLE_BONUS

    elseif questState == 2 then
        return

    elseif questState == 3 then
        if questType == "daily" then
            set model = QUEST_ICON_MODEL_BLUE_QUESTION
        elseif questType == "normal" or questType == "repeatable" or questType == "dungeon" then
            set model = QUEST_ICON_MODEL_YELLOW_QUESTION
        else
            set model = QUEST_ICON_MODEL_GRAY_QUESTION
        endif
        set pingStyle = bj_CAMPPINGSTYLE_TURNIN

    elseif questState == 4 then
        if questType == "normal" then
            set model = QUEST_ICON_MODEL_GRAY_QUESTION
            set pingStyle = bj_CAMPPINGSTYLE_TURNIN
        else
            return
        endif

    else
        set model = QUEST_ICON_MODEL_GRAY_EXCLAMATION
        set pingStyle = bj_CAMPPINGSTYLE_BONUS
    endif

    // Attach overhead model icon
    set e = AddSpecialEffectTarget(model, u, "overhead")
    call SaveEffectHandle(QUEST_ICON_TABLE, GetHandleId(u), QUEST_ICON_EFFECT_ID, e)

    // Minimap ping
    // Create minimap/world-map icon if needed
    if pingStyle != -1 then
        call CreateMapPingForUnit(u, pingStyle)
    endif
endfunction
//===========================================================================
endlibrary
//===========================================================================