//===========================================================================
// QuestIconSystem v1.0
// Author: GPT + User collaboration
// Description:
//   Displays WoW-style quest icons above quest givers based on quest state/type.
//===========================================================================

//===========================================================================
// ICON EFFECT PATHS
//===========================================================================
globals
    string QIS_EFFECT_AVAILABLE = "Abilities\Spells\Other\TalkToMe\TalkToMe.mdl"
    string QIS_EFFECT_DAILY     = "Abilities\Spells\Items\ResourceItems\ResourceEffectTarget.mdl"
    string QIS_EFFECT_COMPLETE  = "Abilities\Spells\Human\Resurrect\ResurrectTarget.mdl"
    string QIS_EFFECT_PROGRESS  = "Abilities\Spells\NightElf\TrueshotAura\TrueshotAura.mdl"
    string QIS_EFFECT_UNAVAILABLE = "Abilities\Spells\Undead\FreezingBreath\FreezingBreathTargetArt.mdl"
endglobals

//===========================================================================
// GLOBALS
//===========================================================================
globals
    hashtable QIS_Hash = InitHashtable()
    constant integer QIS_KEY_EFFECT = StringHash("effect")
endglobals

//===========================================================================
// FUNCTION: QuestIcon_Remove(unit u)
// Description: Removes the current icon effect from the unit
//===========================================================================
function QuestIcon_Remove takes unit u returns nothing
    local integer hid = GetHandleId(u)
    local effect fx = LoadEffectHandle(QIS_Hash, hid, QIS_KEY_EFFECT)
    if fx != null then
        call DestroyEffect(fx)
        call RemoveSavedHandle(QIS_Hash, hid, QIS_KEY_EFFECT)
    endif
endfunction

//===========================================================================
// FUNCTION: QuestIcon_Add(unit u, string effectPath)
//===========================================================================
function QuestIcon_Add takes unit u, string effectPath returns nothing
    local integer hid = GetHandleId(u)
    call QuestIcon_Remove(u)
    local effect fx = AddSpecialEffectTarget(effectPath, u, "overhead")
    call SaveEffectHandle(QIS_Hash, hid, QIS_KEY_EFFECT, fx)
endfunction

//===========================================================================
// FUNCTION: QuestIcon_RefreshIcon(unit u)
// Description: Determines the correct icon to show based on quests tied to this unit
//===========================================================================
function QuestIcon_RefreshIcon takes unit u returns nothing
    local integer i = 0
    local integer qid
    local string qtype
    local integer qstate
    local integer bestPriority = 0
    local string bestEffect = ""
    local integer hid = GetHandleId(u)

    loop
        set qid = LoadInteger(QIS_Hash, hid, i)
        exitwhen qid == 0

        set qtype = LoadStr(udg_QuestData, qid, StringHash("Type"))
        set qstate = LoadInteger(udg_QuestData, qid, StringHash("State"))

        if qstate == 4 and bestPriority < 4 then
            set bestPriority = 4
            set bestEffect = QIS_EFFECT_COMPLETE
        elseif qstate == 2 and bestPriority < 3 then
            if qtype == "Daily" then
                set bestPriority = 3
                set bestEffect = QIS_EFFECT_DAILY
            else
                set bestPriority = 3
                set bestEffect = QIS_EFFECT_AVAILABLE
            endif
        elseif qstate == 3 and bestPriority < 2 then
            set bestPriority = 2
            set bestEffect = QIS_EFFECT_PROGRESS
        elseif qstate == 1 and bestPriority < 1 then
            set bestPriority = 1
            set bestEffect = QIS_EFFECT_UNAVAILABLE
        endif

        set i = i + 1
    endloop

    if bestPriority > 0 then
        call QuestIcon_Add(u, bestEffect)
    else
        call QuestIcon_Remove(u)
    endif
endfunction

//===========================================================================
// FUNCTION: QuestIcon_RegisterQuest(unit u, integer questID)
// Description: Registers a quest to a unit (quest giver)
//===========================================================================
function QuestIcon_RegisterQuest takes unit u, integer questID returns nothing
    local integer hid = GetHandleId(u)
    local integer i = 0
    loop
        exitwhen LoadInteger(QIS_Hash, hid, i) == 0
        set i = i + 1
    endloop
    call SaveInteger(QIS_Hash, hid, i, questID)
endfunction

//===========================================================================
// FUNCTION: SetQuestStateAndRefreshIcon
// Description: GUI-callable function to update a quest state and refresh the icon
//===========================================================================
function SetQuestStateAndRefreshIcon takes unit u, integer questID, string questType, integer questState returns nothing
    call SaveStr(udg_QuestData, questID, StringHash("Type"), questType)
    call SaveInteger(udg_QuestData, questID, StringHash("State"), questState)
    call QuestIcon_RefreshIcon(u)
endfunction

//===========================================================================
// GUI CUSTOM SCRIPT USAGE
//===========================================================================
// 1. Register a quest to a unit:
//    Custom script: call QuestIcon_RegisterQuest(udg_QuestTempUnit, udg_QuestID_Temp)
//
// 2. Update quest type/state and refresh icon:
//    Custom script: call SetQuestStateAndRefreshIcon(udg_QuestTempUnit, udg_QuestID_Temp, "Daily", 2)
//    Quest States:
//      1 = Unavailable (gray !)
//      2 = Available (yellow ! or blue ! for daily)
//      3 = In Progress (gray ?)
//      4 = Complete (yellow ?)
