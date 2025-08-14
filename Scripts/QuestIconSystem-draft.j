
globals
    unit array QuestGiver_Unit
    integer array QuestGiver_QuestStatus // index = 100 * questGiverId + questIndex
    effect array QuestGiver_IconSFX
    integer MAX_QUESTS_PER_GIVER = 3
endglobals

// Quest status constants
constant integer QUEST_UNAVAILABLE = 1
constant integer QUEST_AVAILABLE   = 2
constant integer QUEST_INPROGRESS  = 3
constant integer QUEST_COMPLETE    = 4

// Path to SFX models
constant string ICON_GREY_EXCLAM   = "Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl"
constant string ICON_YELLOW_EXCLAM = "Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl"
constant string ICON_GREY_QUESTION = "Abilities\\Spells\\Other\\Question\\Question.mdl"
constant string ICON_YELLOW_QUESTION = "Abilities\\Spells\\Other\\Question\\Question.mdl"
constant string ICON_BLUE_EXCLAM   = "Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl" // Placeholder

function GetQuestStatus takes integer giverIndex returns integer
    local integer i = 0
    local integer base = giverIndex * 100
    local boolean hasComplete = false
    local boolean hasAvailable = false
    local boolean hasInProgress = false
    local boolean hasUnavailable = false
    loop
        exitwhen i >= MAX_QUESTS_PER_GIVER
        if QuestGiver_QuestStatus[base + i] == QUEST_COMPLETE then
            set hasComplete = true
        elseif QuestGiver_QuestStatus[base + i] == QUEST_AVAILABLE then
            set hasAvailable = true
        elseif QuestGiver_QuestStatus[base + i] == QUEST_INPROGRESS then
            set hasInProgress = true
        elseif QuestGiver_QuestStatus[base + i] == QUEST_UNAVAILABLE then
            set hasUnavailable = true
        endif
        set i = i + 1
    endloop

    if hasComplete then
        return QUEST_COMPLETE
    elseif hasAvailable then
        return QUEST_AVAILABLE
    elseif hasInProgress then
        return QUEST_INPROGRESS
    elseif hasUnavailable then
        return QUEST_UNAVAILABLE
    endif
    return 0 // No active quests
endfunction

function RefreshQuestIcon takes integer giverIndex returns nothing
    local unit u = QuestGiver_Unit[giverIndex]
    local integer status = GetQuestStatus(giverIndex)
    local string path = ""
    if QuestGiver_IconSFX[giverIndex] != null then
        call DestroyEffect(QuestGiver_IconSFX[giverIndex])
    endif

    if status == QUEST_COMPLETE then
        set path = ICON_YELLOW_QUESTION
    elseif status == QUEST_AVAILABLE then
        set path = ICON_YELLOW_EXCLAM
    elseif status == QUEST_INPROGRESS then
        set path = ICON_GREY_QUESTION
    elseif status == QUEST_UNAVAILABLE then
        set path = ICON_GREY_EXCLAM
    endif

    if path != "" then
        set QuestGiver_IconSFX[giverIndex] = AddSpecialEffectTarget(path, u, "overhead")
    endif
endfunction

function RefreshAllQuestIcons takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i > 10 // Assume 10 quest givers max
        if QuestGiver_Unit[i] != null then
            call RefreshQuestIcon(i)
        endif
        set i = i + 1
    endloop
endfunction
