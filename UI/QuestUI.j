/**
    QuestUI

    Author: Valdemar
    Version: 1.1.1

    Description:
    Replaces the native Quests button with a TasQuestBox-styled quest journal
    backed directly by QuestMaster data and state events.

    Credits:
    Tasyen (TasQuestBox frame templates and list interaction pattern)

    How to install:
    Import after QuestMaster, MasterUI, Interface, and Table. Import the
    existing TasQuestBox.toc and TasQuestBox.fdf assets with their current
    war3mapImported paths.

    API:
    - QuestUI_Show() and QuestUI_Hide() control the journal.
    - QuestUI_ShowButton() and QuestUI_HideButton() control top-bar access.
    - QuestUI_Refresh() redraws visible quest data.
    - QuestUI_FlashButton() marks new quest activity on the replacement button.

**/
library QuestUI initializer AutoInit requires QuestMaster, MasterUI, Interface, Table

globals
    // Imported TasQuestBox frame configuration
    private constant string QUI_TOC_PATH = "war3mapImported/TasQuestBox.toc"
    private constant integer QUI_FRAME_CONTEXT = 6
    private constant integer QUI_ROW_CONTEXT_BASE = 600

    // List and category layout
    private constant integer QUI_VISIBLE_ROWS = 7
    private constant integer QUI_QUEST_KEY_STRIDE = 512
    private constant integer QUI_CATEGORY_COUNT = 8
    private constant real QUI_CATEGORY_BUTTON_WIDTH = 0.057
    private constant real QUI_CATEGORY_BUTTON_HEIGHT = 0.024
    private constant integer QUI_SECTION_COUNT = 4
    private constant real QUI_SECTION_BUTTON_WIDTH = 0.070
    private constant real QUI_SECTION_BUTTON_HEIGHT = 0.022

    private constant integer QUI_CATEGORY_ALL = 0
    private constant integer QUI_CATEGORY_NORMAL = 1
    private constant integer QUI_CATEGORY_DAILY = 2
    private constant integer QUI_CATEGORY_REPEATABLE = 3
    private constant integer QUI_CATEGORY_STORY = 4
    private constant integer QUI_CATEGORY_DUNGEON = 5
    private constant integer QUI_CATEGORY_CLASS = 6
    private constant integer QUI_CATEGORY_PROFESSION = 7

    private constant integer QUI_SECTION_DETAILS = 0
    private constant integer QUI_SECTION_DESCRIPTION = 1
    private constant integer QUI_SECTION_OBJECTIVES = 2
    private constant integer QUI_SECTION_REWARDS = 3

    private boolean QUI_Initialized = false
    private boolean QUI_FramesCreated = false
    private boolean QUI_OpenButtonVisible = false
    private boolean QUI_SyncingSlider = false

    // Player-local presentation state. These values never affect quest gameplay.
    private integer array QUI_Category
    private integer array QUI_ViewOffset
    private integer array QUI_SelectedQuestId
    private integer array QUI_DetailSection
    private integer array QUI_FilteredCount
    private integer array QUI_SliderMaxCache
    private integer array QUI_SliderValueCache

    private framehandle QUI_Parent = null
    private framehandle QUI_OpenButton = null
    private framehandle QUI_NativeQuestButton = null
    private framehandle QUI_CloseButton = null
    private framehandle QUI_TitleFrame = null
    private framehandle QUI_TextArea = null
    private framehandle QUI_Slider = null
    private framehandle QUI_WheelArea = null
    private framehandle QUI_RewardItemIcon = null
    private framehandle QUI_RewardItemName = null
    private framehandle array QUI_RowButton
    private framehandle array QUI_RowIcon
    private framehandle array QUI_RowText
    private framehandle array QUI_CategoryButton
    private framehandle array QUI_CategoryText
    private framehandle array QUI_SectionButton
    private framehandle array QUI_SectionText

    private Table QUI_RowByButton = 0
    private Table QUI_CategoryByButton = 0
    private Table QUI_SectionByButton = 0
    private Table QUI_FilteredQuest = 0

    private trigger QUI_OpenTrigger = null
    private trigger QUI_CloseTrigger = null
    private trigger QUI_RowTrigger = null
    private trigger QUI_CategoryTrigger = null
    private trigger QUI_SectionTrigger = null
    private trigger QUI_SliderTrigger = null
    private trigger QUI_WheelTrigger = null
    private trigger QUI_ClearFocusTrigger = null
    private trigger QUI_EscapeTrigger = null
    private trigger QUI_InitTrigger = null
    private timer QUI_FlashTimer = null
endglobals

private function QUI_GetStorageKey takes integer pid, integer listIndex returns integer
    return pid*QUI_QUEST_KEY_STRIDE + listIndex
endfunction

private function QUI_GetCategoryLabel takes integer category returns string
    if category == QUI_CATEGORY_NORMAL then
        return "Normal"
    elseif category == QUI_CATEGORY_DAILY then
        return "Daily"
    elseif category == QUI_CATEGORY_REPEATABLE then
        return "Repeatable"
    elseif category == QUI_CATEGORY_STORY then
        return "Story"
    elseif category == QUI_CATEGORY_DUNGEON then
        return "Dungeon"
    elseif category == QUI_CATEGORY_CLASS then
        return "Class"
    elseif category == QUI_CATEGORY_PROFESSION then
        return "Profession"
    endif
    return "All"
endfunction

private function QUI_GetTypeLabel takes string questType returns string
    if questType == "daily" then
        return "Daily"
    elseif questType == "repeatable" then
        return "Repeatable"
    elseif questType == "story" then
        return "Story"
    elseif questType == "dungeon" then
        return "Dungeon"
    elseif questType == "class" then
        return "Class"
    elseif questType == "profession" then
        return "Profession"
    endif
    return "Normal"
endfunction

private function QUI_GetSectionLabel takes integer section returns string
    if section == QUI_SECTION_DETAILS then
        return "Details"
    elseif section == QUI_SECTION_OBJECTIVES then
        return "Objectives"
    elseif section == QUI_SECTION_REWARDS then
        return "Rewards"
    endif
    return "Description"
endfunction

private function QUI_GetQuestCategoryLabel takes string category returns string
    if category == "story" then
        return "Story"
    elseif category == "dungeon" then
        return "Dungeon"
    elseif category == "class" then
        return "Class"
    elseif category == "profession" then
        return "Profession"
    endif
    return "General"
endfunction

private function QUI_MatchesCategory takes QuestData q, integer category returns boolean
    if category == QUI_CATEGORY_ALL then
        return true
    elseif category == QUI_CATEGORY_DAILY then
        return q.questCategory == "general" and q.questType == "daily"
    elseif category == QUI_CATEGORY_REPEATABLE then
        return q.questCategory == "general" and q.questType == "repeatable"
    elseif category == QUI_CATEGORY_STORY then
        return q.questCategory == "story" or q.questType == "story"
    elseif category == QUI_CATEGORY_DUNGEON then
        return q.questCategory == "dungeon" or q.questType == "dungeon"
    elseif category == QUI_CATEGORY_CLASS then
        return q.questCategory == "class" or q.questType == "class"
    elseif category == QUI_CATEGORY_PROFESSION then
        return q.questCategory == "profession" or q.questType == "profession"
    endif
    return q.questCategory == "general" and q.questType != "daily" and q.questType != "repeatable" and q.questType != "story" and q.questType != "dungeon" and q.questType != "class" and q.questType != "profession"
endfunction

private function QUI_ShouldList takes QuestData q returns boolean
    return q != 0 and q.title != "" and not q.discoveryPending and (q.discovered or q.active or q.completed or q.failed)
endfunction

private function QUI_GetStatusLabel takes QuestData q returns string
    if q.failed then
        return "|cffff6060Failed|r"
    elseif q.completed or q.state == QUEST_STATE_COMPLETE then
        return "|cff80ff80Completed|r"
    elseif q.state == QUEST_STATE_READY_TURNIN then
        return "|cffffff00Ready to turn in|r"
    elseif q.active or q.state == QUEST_STATE_IN_PROGRESS then
        return "|cffffffffIn progress|r"
    elseif q.state == QUEST_STATE_AVAILABLE then
        return "|cffc0c0c0Available|r"
    endif
    return "|cff808080Unavailable|r"
endfunction

private function QUI_GetGiverName takes QuestData q returns string
    if q.giverDisplayName != "" then
        return q.giverDisplayName
    elseif q.giver != null then
        return GetUnitName(q.giver)
    endif
    return ""
endfunction

private function QUI_GetReceiverName takes QuestData q returns string
    if q.receiverDisplayName != "" then
        return q.receiverDisplayName
    elseif q.receiver != null then
        return GetUnitName(q.receiver)
    endif
    return ""
endfunction

private function QUI_TrimLineBreaks takes string text returns string
    local integer length = StringLength(text)

    loop
        exitwhen length <= 0 or SubString(text, 0, 1) != "\n"
        set text = SubString(text, 1, length)
        set length = length - 1
    endloop
    loop
        exitwhen length <= 0 or SubString(text, length - 1, length) != "\n"
        set text = SubString(text, 0, length - 1)
        set length = length - 1
    endloop
    return text
endfunction

private function QUI_AppendParagraph takes string text, string paragraph returns string
    set paragraph = QUI_TrimLineBreaks(paragraph)
    if paragraph == "" then
        return text
    elseif text == "" then
        return paragraph
    endif
    return text + "\n\n" + paragraph
endfunction

private function QUI_StartsWith takes string text, string prefix returns boolean
    local integer prefixLength = StringLength(prefix)

    return prefixLength > 0 and StringLength(text) >= prefixLength and SubString(text, 0, prefixLength) == prefix
endfunction

private function QUI_IsRecommendedLevelText takes string text returns boolean
    return QUI_StartsWith(QUI_TrimLineBreaks(text), "|cffffcc00Recommended level:|r")
endfunction

private function QUI_IsLegacyMetadataText takes string text returns boolean
    set text = QUI_TrimLineBreaks(text)
    return QUI_StartsWith(text, "|cffffcc00Quest giver:|r") or QUI_StartsWith(text, "|cffffcc00Quest receiver:|r") or QUI_StartsWith(text, "|cffffcc00Recommended level:|r") or QUI_StartsWith(text, "|cff80a0ffDaily quest|r") or QUI_StartsWith(text, "|cff80a0ffRepeatable quest|r") or text == "|cffffcc00Quest|r"
endfunction

private function QUI_FormatObjective takes string objectiveText, boolean completed returns string
    if objectiveText == "" then
        return ""
    elseif completed then
        return "|cff80ff80[Complete]|r " + objectiveText + "\n"
    endif
    return "|cffffffff[ ]|r " + objectiveText + "\n"
endfunction

private function QUI_BuildObjectives takes QuestData q returns string
    local string text = ""

    set text = text + QUI_FormatObjective(q.requirement1, q.req1Completed)
    set text = text + QUI_FormatObjective(q.requirement2, q.req2Completed)
    set text = text + QUI_FormatObjective(q.requirement3, q.req3Completed)
    set text = text + QUI_FormatObjective(q.requirement4, q.req4Completed)
    set text = text + QUI_FormatObjective(q.requirement5, q.req5Completed)
    set text = text + QUI_FormatObjective(q.requirement6, q.req6Completed)
    set text = text + QUI_FormatObjective(q.requirement7, q.req7Completed)
    set text = text + QUI_FormatObjective(q.requirement8, q.req8Completed)
    if text == "" then
        return "|cff808080No objectives listed.|r"
    endif
    return QUI_TrimLineBreaks(text)
endfunction

private function QUI_BuildDetails takes QuestData q returns string
    local string text
    local string giverName = QUI_GetGiverName(q)
    local string receiverName = QUI_GetReceiverName(q)
    local boolean sameContact = giverName != "" and receiverName != "" and giverName == receiverName

    if q.giver != null and q.receiver != null then
        set sameContact = q.giver == q.receiver
    endif

    set text = "|cffffcc00Type:|r " + QUI_GetTypeLabel(q.questType) + "    |cffffcc00Level:|r " + I2S(q.questLevel) + "\n"
    if q.questCategory != "" and q.questCategory != "general" then
        set text = text + "|cffffcc00Category:|r " + QUI_GetQuestCategoryLabel(q.questCategory) + "\n"
    endif
    set text = text + "|cffffcc00Status:|r " + QUI_GetStatusLabel(q) + "\n"
    if QUI_IsRecommendedLevelText(q.infoText) then
        set text = text + QUI_TrimLineBreaks(q.infoText) + "\n"
    endif
    if QUI_IsRecommendedLevelText(q.info2Text) then
        set text = text + QUI_TrimLineBreaks(q.info2Text) + "\n"
    endif
    if giverName != "" and q.autoCompletes then
        set text = text + "|cffffcc00Quest giver:|r " + giverName + "\n"
        set text = text + "|cffffcc00Completion:|r Automatic\n"
    elseif giverName != "" and sameContact then
        set text = text + "|cffffcc00Quest giver / turn-in:|r " + giverName + "\n"
    elseif giverName != "" then
        set text = text + "|cffffcc00Quest giver:|r " + giverName + "\n"
        if receiverName != "" then
            set text = text + "|cffffcc00Turn in to:|r " + receiverName + "\n"
        endif
    elseif receiverName != "" then
        set text = text + "|cffffcc00Turn in to:|r " + receiverName + "\n"
    elseif q.autoCompletes then
        set text = text + "|cffffcc00Completion:|r Automatic\n"
    endif
    if q.failed and q.failReasonText != "" then
        set text = text + "|cffff6060Failure:|r " + q.failReasonText + "\n"
    endif
    return QUI_TrimLineBreaks(text)
endfunction

private function QUI_BuildDescription takes QuestData q returns string
    local string text = ""

    set text = QUI_AppendParagraph(text, q.description)
    if not QUI_IsLegacyMetadataText(q.infoText) then
        set text = QUI_AppendParagraph(text, q.infoText)
    endif
    if not QUI_IsLegacyMetadataText(q.info2Text) then
        set text = QUI_AppendParagraph(text, q.info2Text)
    endif
    if text == "" then
        return "|cff808080No description provided.|r"
    endif
    return text
endfunction

private function QUI_BuildRewards takes QuestData q returns string
    local string text = ""
    local string itemTooltip = ""

    if q.rewardXPActive then
        set text = text + "|cff8080ffExperience:|r " + I2S(q.rewardXP) + "\n"
    endif
    if q.rewardGoldActive then
        set text = text + "|cffffff00Gold:|r " + I2S(q.rewardGold) + "\n"
    endif
    if q.rewardArenaActive then
        set text = text + "|cffff8080Arena Marks:|r " + I2S(q.rewardArena) + "\n"
    endif
    if q.rewardRepActive then
        set text = text + "|cff8080ffReputation:|r " + I2S(q.rewardRep)
        if q.faction != "" then
            set text = text + " with " + q.faction
        endif
        set text = text + "\n"
    endif
    if q.rewardItemActive and q.rewardItemType != 0 then
        set itemTooltip = BlzGetAbilityExtendedTooltip(q.rewardItemType, 0)
        if itemTooltip != null and itemTooltip != "" then
            set text = text + "\n|cffffcc00Item details|r\n" + itemTooltip + "\n"
        endif
    endif
    if text == "" then
        set text = QUI_TrimLineBreaks(q.rewardsText)
    endif
    if text == "" then
        return "|cff808080No rewards listed.|r"
    endif
    return QUI_TrimLineBreaks(text)
endfunction

private function QUI_BuildSectionText takes QuestData q, integer section returns string
    if section == QUI_SECTION_DETAILS then
        return QUI_BuildDetails(q)
    elseif section == QUI_SECTION_OBJECTIVES then
        return QUI_BuildObjectives(q)
    elseif section == QUI_SECTION_REWARDS then
        return QUI_BuildRewards(q)
    endif
    return QUI_BuildDescription(q)
endfunction

private function QUI_RebuildFilter takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer category = QUI_Category[pid]
    local integer questIndex = 1
    local integer questCount = QuestMaster_GetQuestCount()
    local integer questId
    local integer filteredCount = 0
    local boolean selectedFound = false
    local QuestData q

    loop
        exitwhen questIndex > questCount
        set questId = QuestMaster_GetQuestIdByIndex(questIndex)
        set q = QuestMaster_GetById(questId)
        if QUI_ShouldList(q) and QUI_MatchesCategory(q, category) then
            set filteredCount = filteredCount + 1
            set QUI_FilteredQuest.integer[QUI_GetStorageKey(pid, filteredCount)] = questId
            if QUI_SelectedQuestId[pid] == questId then
                set selectedFound = true
            endif
        endif
        set questIndex = questIndex + 1
    endloop

    set QUI_FilteredCount[pid] = filteredCount
    if not selectedFound then
        if filteredCount > 0 then
            set QUI_SelectedQuestId[pid] = QUI_FilteredQuest.integer[QUI_GetStorageKey(pid, 1)]
        else
            set QUI_SelectedQuestId[pid] = 0
        endif
    endif
endfunction

private function QUI_GetQuestIdAt takes integer pid, integer listIndex returns integer
    if listIndex <= 0 or listIndex > QUI_FilteredCount[pid] then
        return 0
    endif
    return QUI_FilteredQuest.integer[QUI_GetStorageKey(pid, listIndex)]
endfunction

private function QUI_GetMaxStart takes integer pid returns integer
    if QUI_FilteredCount[pid] > QUI_VISIBLE_ROWS then
        return QUI_FilteredCount[pid] - QUI_VISIBLE_ROWS
    endif
    return 0
endfunction

private function QUI_SyncSliderVisual takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer maxStart = QUI_GetMaxStart(pid)
    local integer frameValue

    if QUI_Slider == null then
        return
    endif
    if QUI_ViewOffset[pid] < 0 then
        set QUI_ViewOffset[pid] = 0
    elseif QUI_ViewOffset[pid] > maxStart then
        set QUI_ViewOffset[pid] = maxStart
    endif
    set frameValue = maxStart - QUI_ViewOffset[pid]

    set QUI_SyncingSlider = true
    if QUI_SliderMaxCache[pid] != maxStart then
        set QUI_SliderMaxCache[pid] = maxStart
        call BlzFrameSetMinMaxValue(QUI_Slider, 0.0, I2R(maxStart))
    endif
    if QUI_SliderValueCache[pid] != frameValue then
        set QUI_SliderValueCache[pid] = frameValue
        call BlzFrameSetValue(QUI_Slider, I2R(frameValue))
    endif
    set QUI_SyncingSlider = false
    call BlzFrameSetVisible(QUI_Slider, maxStart > 0)
endfunction

private function QUI_UpdateCategoryButtons takes integer pid returns nothing
    local integer categoryIndex = 0
    local string label

    loop
        exitwhen categoryIndex >= QUI_CATEGORY_COUNT
        set label = QUI_GetCategoryLabel(categoryIndex)
        if QUI_Category[pid] == categoryIndex then
            call BlzFrameSetText(QUI_CategoryText[categoryIndex], "|cffffffff" + label + "|r")
        else
            call BlzFrameSetText(QUI_CategoryText[categoryIndex], "|cffffcc00" + label + "|r")
        endif
        set categoryIndex = categoryIndex + 1
    endloop
endfunction

private function QUI_UpdateSectionButtons takes integer pid returns nothing
    local integer section = 0
    local string label

    loop
        exitwhen section >= QUI_SECTION_COUNT
        set label = QUI_GetSectionLabel(section)
        if QUI_DetailSection[pid] == section then
            call BlzFrameSetText(QUI_SectionText[section], "|cffffffff" + label + "|r")
        else
            call BlzFrameSetText(QUI_SectionText[section], "|cffffcc00" + label + "|r")
        endif
        set section = section + 1
    endloop
endfunction

private function QUI_UpdateRewardItem takes QuestData q, integer section returns nothing
    local boolean showItem = q != 0 and section == QUI_SECTION_REWARDS and q.rewardItemActive and q.rewardItemType != 0

    call BlzFrameClearAllPoints(QUI_TextArea)
    if showItem then
        call BlzFrameSetSize(QUI_TextArea, 0.300, 0.135)
        call BlzFrameSetTexture(QUI_RewardItemIcon, BlzGetAbilityIcon(q.rewardItemType), 0, true)
        call BlzFrameSetText(QUI_RewardItemName, "|cff00ffffItem:|r " + GetObjectName(q.rewardItemType))
    else
        call BlzFrameSetSize(QUI_TextArea, 0.300, 0.178)
        call BlzFrameSetText(QUI_RewardItemName, "")
    endif
    call BlzFrameSetPoint(QUI_TextArea, FRAMEPOINT_BOTTOMRIGHT, QUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
    call BlzFrameSetVisible(QUI_RewardItemIcon, showItem)
    call BlzFrameSetVisible(QUI_RewardItemName, showItem)
endfunction

private function QUI_UpdateRows takes integer pid returns nothing
    local integer rowIndex = 1
    local integer questId
    local string rowText
    local QuestData q

    loop
        exitwhen rowIndex > QUI_VISIBLE_ROWS
        set questId = QUI_GetQuestIdAt(pid, QUI_ViewOffset[pid] + rowIndex)
        set q = QuestMaster_GetById(questId)
        if q != 0 then
            set rowText = q.title
            if q.failed then
                set rowText = "|cffff6060" + rowText + "|r"
            elseif q.completed or q.state == QUEST_STATE_COMPLETE then
                set rowText = "|cff80ff80" + rowText + "|r"
            elseif q.state == QUEST_STATE_READY_TURNIN then
                set rowText = "|cffffff00" + rowText + "|r"
            elseif questId == QUI_SelectedQuestId[pid] then
                set rowText = "|cffffffff> " + rowText + "|r"
            else
                set rowText = "|cffffcc00" + rowText + "|r"
            endif
            if q.iconPath != "" then
                call BlzFrameSetTexture(QUI_RowIcon[rowIndex], q.iconPath, 0, true)
                call BlzFrameSetVisible(QUI_RowIcon[rowIndex], true)
            else
                call BlzFrameSetVisible(QUI_RowIcon[rowIndex], false)
            endif
            call BlzFrameSetText(QUI_RowText[rowIndex], rowText)
            call BlzFrameSetVisible(QUI_RowButton[rowIndex], true)
        else
            call BlzFrameSetVisible(QUI_RowButton[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop
endfunction

private function QUI_UpdateDetail takes integer pid returns nothing
    local QuestData q = QuestMaster_GetById(QUI_SelectedQuestId[pid])

    call QUI_UpdateSectionButtons(pid)
    if q == 0 then
        call BlzFrameSetText(QUI_TitleFrame, "Quest Log - " + QUI_GetCategoryLabel(QUI_Category[pid]))
        call BlzFrameSetText(QUI_TextArea, "No discovered quests in this category.")
        call QUI_UpdateRewardItem(q, QUI_DetailSection[pid])
        return
    endif
    call BlzFrameSetText(QUI_TitleFrame, "Quest Log - " + q.title)
    call BlzFrameSetText(QUI_TextArea, QUI_BuildSectionText(q, QUI_DetailSection[pid]))
    call QUI_UpdateRewardItem(q, QUI_DetailSection[pid])
endfunction

private function QUI_UpdateForPlayer takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)

    if QUI_Parent == null or GetLocalPlayer() != whichPlayer then
        return
    endif
    call QUI_RebuildFilter(whichPlayer)
    call QUI_SyncSliderVisual(whichPlayer)
    call QUI_UpdateCategoryButtons(pid)
    call QUI_UpdateRows(pid)
    call QUI_UpdateDetail(pid)
endfunction

private function QUI_ApplyOpenButtonVisibility takes nothing returns nothing
    if QUI_NativeQuestButton != null then
        call BlzFrameSetVisible(QUI_NativeQuestButton, false)
    endif
    if QUI_OpenButton != null then
        call BlzFrameSetVisible(QUI_OpenButton, QUI_OpenButtonVisible)
    endif
endfunction

private function QUI_ResetFlash takes nothing returns nothing
    if QUI_OpenButton != null then
        call BlzFrameSetText(QUI_OpenButton, "|cffffffffQuests|r")
    endif
endfunction

public function Refresh takes nothing returns nothing
    if QUI_Parent != null and BlzFrameIsVisible(QUI_Parent) then
        call QUI_UpdateForPlayer(GetLocalPlayer())
    endif
endfunction

public function Hide takes nothing returns nothing
    if QUI_Parent != null and BlzFrameIsVisible(QUI_Parent) then
        call Interface_NotifyQuestLogClosed()
        call BlzFrameSetVisible(QUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    if not QUI_Initialized then
        return
    endif
    call MasterUI_ClosePanels()
    if QUI_Parent != null then
        call Interface_NotifyUIOpened()
        call BlzFrameSetVisible(QUI_Parent, true)
        call QUI_UpdateForPlayer(GetLocalPlayer())
    endif
endfunction

public function ShowButton takes nothing returns nothing
    set QUI_OpenButtonVisible = true
    call QUI_ApplyOpenButtonVisibility()
endfunction

public function HideButton takes nothing returns nothing
    call Hide()
    set QUI_OpenButtonVisible = false
    call QUI_ApplyOpenButtonVisibility()
endfunction

public function FlashButton takes nothing returns nothing
    if QUI_OpenButton != null then
        call BlzFrameSetText(QUI_OpenButton, "|cffffcc00Quests!|r")
        call TimerStart(QUI_FlashTimer, 2.00, false, function QUI_ResetFlash)
    endif
endfunction

private function QUI_OnQuestDataChanged takes nothing returns nothing
    call Refresh()
endfunction

private function QUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function QUI_OpenAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local boolean showPanel

    if GetLocalPlayer() == p then
        set showPanel = QUI_Parent != null and not BlzFrameIsVisible(QUI_Parent)
        if showPanel then
            call Show()
        else
            call Hide()
        endif
    endif
    set p = null
endfunction

private function QUI_CloseAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call Hide()
    endif
endfunction

private function QUI_EscapeAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call Hide()
    endif
endfunction

private function QUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer rowIndex = QUI_RowByButton.integer[GetHandleId(BlzGetTriggerFrame())]
    local integer questId = QUI_GetQuestIdAt(pid, QUI_ViewOffset[pid] + rowIndex)

    if questId > 0 then
        set QUI_SelectedQuestId[pid] = questId
        set QUI_DetailSection[pid] = QUI_SECTION_DESCRIPTION
        if GetLocalPlayer() == p then
            call QUI_UpdateForPlayer(p)
        endif
    endif
    set p = null
endfunction

private function QUI_CategoryAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer category = QUI_CategoryByButton.integer[GetHandleId(BlzGetTriggerFrame())]

    set QUI_Category[pid] = category
    set QUI_ViewOffset[pid] = 0
    set QUI_SelectedQuestId[pid] = 0
    set QUI_DetailSection[pid] = QUI_SECTION_DESCRIPTION
    set QUI_SliderMaxCache[pid] = -1
    set QUI_SliderValueCache[pid] = -1
    if GetLocalPlayer() == p then
        call Interface_NotifyTabChanged()
        call QUI_UpdateForPlayer(p)
    endif
    set p = null
endfunction

private function QUI_SectionAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer section = QUI_SectionByButton.integer[GetHandleId(BlzGetTriggerFrame())]

    set QUI_DetailSection[pid] = section
    if GetLocalPlayer() == p then
        call Interface_NotifyTabChanged()
        call QUI_UpdateDetail(pid)
    endif
    set p = null
endfunction

private function QUI_SliderAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer maxStart = QUI_GetMaxStart(pid)

    if not QUI_SyncingSlider then
        set QUI_SliderValueCache[pid] = R2I(BlzGetTriggerFrameValue() + 0.5)
        set QUI_ViewOffset[pid] = maxStart - QUI_SliderValueCache[pid]
        if QUI_ViewOffset[pid] < 0 then
            set QUI_ViewOffset[pid] = 0
        elseif QUI_ViewOffset[pid] > maxStart then
            set QUI_ViewOffset[pid] = maxStart
        endif
        if GetLocalPlayer() == p then
            call QUI_UpdateForPlayer(p)
        endif
    endif
    set p = null
endfunction

private function QUI_WheelAction takes nothing returns nothing
    local real nextValue
    local real maxValue

    if GetLocalPlayer() == GetTriggerPlayer() and QUI_Slider != null and BlzFrameIsVisible(QUI_Slider) then
        set maxValue = I2R(QUI_GetMaxStart(GetPlayerId(GetTriggerPlayer())))
        set nextValue = BlzFrameGetValue(QUI_Slider)
        if BlzGetTriggerFrameValue() > 0.0 then
            set nextValue = nextValue + 1.0
        else
            set nextValue = nextValue - 1.0
        endif
        if nextValue < 0.0 then
            set nextValue = 0.0
        elseif nextValue > maxValue then
            set nextValue = maxValue
        endif
        call BlzFrameSetValue(QUI_Slider, nextValue)
    endif
endfunction

private function QUI_CreateCategoryButton takes integer category returns nothing
    local real x = 0.012 + I2R(category)*(QUI_CATEGORY_BUTTON_WIDTH + 0.002)

    set QUI_CategoryButton[category] = BlzCreateFrameByType("GLUETEXTBUTTON", "QuestUICategoryButton" + I2S(category), QUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(QUI_CategoryButton[category], QUI_CATEGORY_BUTTON_WIDTH, QUI_CATEGORY_BUTTON_HEIGHT)
    call BlzFrameSetPoint(QUI_CategoryButton[category], FRAMEPOINT_TOPLEFT, QUI_Parent, FRAMEPOINT_TOPLEFT, x, -0.045)
    call BlzFrameSetText(QUI_CategoryButton[category], "")

    set QUI_CategoryText[category] = BlzCreateFrameByType("TEXT", "QuestUICategoryText" + I2S(category), QUI_CategoryButton[category], "", 0)
    call BlzFrameSetAllPoints(QUI_CategoryText[category], QUI_CategoryButton[category])
    call BlzFrameSetTextAlignment(QUI_CategoryText[category], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(QUI_CategoryText[category], 0.72)
    call BlzFrameSetEnable(QUI_CategoryText[category], false)

    set QUI_CategoryByButton.integer[GetHandleId(QUI_CategoryButton[category])] = category
    call BlzTriggerRegisterFrameEvent(QUI_CategoryTrigger, QUI_CategoryButton[category], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(QUI_ClearFocusTrigger, QUI_CategoryButton[category], FRAMEEVENT_CONTROL_CLICK)
endfunction

private function QUI_CreateSectionButton takes integer section returns nothing
    local real x = 0.193 + I2R(section)*(QUI_SECTION_BUTTON_WIDTH + 0.003)

    set QUI_SectionButton[section] = BlzCreateFrameByType("GLUETEXTBUTTON", "QuestUISectionButton" + I2S(section), QUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(QUI_SectionButton[section], QUI_SECTION_BUTTON_WIDTH, QUI_SECTION_BUTTON_HEIGHT)
    call BlzFrameSetPoint(QUI_SectionButton[section], FRAMEPOINT_TOPLEFT, QUI_Parent, FRAMEPOINT_TOPLEFT, x, -0.085)
    call BlzFrameSetText(QUI_SectionButton[section], "")

    set QUI_SectionText[section] = BlzCreateFrameByType("TEXT", "QuestUISectionText" + I2S(section), QUI_SectionButton[section], "", 0)
    call BlzFrameSetAllPoints(QUI_SectionText[section], QUI_SectionButton[section])
    call BlzFrameSetTextAlignment(QUI_SectionText[section], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(QUI_SectionText[section], 0.72)
    call BlzFrameSetEnable(QUI_SectionText[section], false)

    set QUI_SectionByButton.integer[GetHandleId(QUI_SectionButton[section])] = section
    call BlzTriggerRegisterFrameEvent(QUI_SectionTrigger, QUI_SectionButton[section], FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(QUI_ClearFocusTrigger, QUI_SectionButton[section], FRAMEEVENT_CONTROL_CLICK)
endfunction

private function QUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local integer category = 0
    local integer section = 0

    if QUI_FramesCreated then
        return
    endif
    set QUI_FramesCreated = true

    call BlzLoadTOCFile(QUI_TOC_PATH)
    set QUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, QUI_FRAME_CONTEXT)
    call BlzFrameSetAbsPoint(QUI_Parent, FRAMEPOINT_TOPLEFT, 0.100, 0.550)

    set QUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", QUI_FRAME_CONTEXT)
    set QUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", QUI_FRAME_CONTEXT)
    set QUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", QUI_FRAME_CONTEXT)
    set QUI_CloseButton = BlzGetFrameByName("TasQuestBoxCloseButton1", QUI_FRAME_CONTEXT)

    call BlzFrameClearAllPoints(QUI_TextArea)
    call BlzFrameSetSize(QUI_TextArea, 0.300, 0.178)
    call BlzFrameSetPoint(QUI_TextArea, FRAMEPOINT_BOTTOMRIGHT, QUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
    call BlzFrameClearAllPoints(QUI_Slider)
    call BlzFrameSetSize(QUI_Slider, 0.012, 0.205)
    call BlzFrameSetPoint(QUI_Slider, FRAMEPOINT_TOPRIGHT, QUI_Parent, FRAMEPOINT_TOPLEFT, 0.190, -0.085)
    call BlzFrameSetMinMaxValue(QUI_Slider, 0.0, 0.0)
    call BlzFrameSetStepSize(QUI_Slider, 1.0)
    call BlzTriggerRegisterFrameEvent(QUI_SliderTrigger, QUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(QUI_WheelTrigger, QUI_Slider, FRAMEEVENT_MOUSE_WHEEL)

    set QUI_WheelArea = BlzCreateFrameByType("SLIDER", "QuestUIWheelArea", QUI_Parent, "", 0)
    call BlzFrameSetPoint(QUI_WheelArea, FRAMEPOINT_TOPRIGHT, QUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(QUI_WheelArea, FRAMEPOINT_BOTTOMLEFT, QUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.010)
    call BlzTriggerRegisterFrameEvent(QUI_WheelTrigger, QUI_WheelArea, FRAMEEVENT_MOUSE_WHEEL)

    call BlzFrameSetText(QUI_TitleFrame, "Quest Log")
    call BlzTriggerRegisterFrameEvent(QUI_CloseTrigger, QUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(QUI_ClearFocusTrigger, QUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen category >= QUI_CATEGORY_COUNT
        call QUI_CreateCategoryButton(category)
        set category = category + 1
    endloop

    loop
        exitwhen section >= QUI_SECTION_COUNT
        call QUI_CreateSectionButton(section)
        set section = section + 1
    endloop

    set QUI_RewardItemIcon = BlzCreateFrameByType("BACKDROP", "QuestUIRewardItemIcon", QUI_Parent, "IconButtonTemplate", 0)
    call BlzFrameSetSize(QUI_RewardItemIcon, 0.034, 0.034)
    call BlzFrameSetPoint(QUI_RewardItemIcon, FRAMEPOINT_TOPLEFT, QUI_Parent, FRAMEPOINT_TOPLEFT, 0.205, -0.115)
    set QUI_RewardItemName = BlzCreateFrameByType("TEXT", "QuestUIRewardItemName", QUI_Parent, "", 0)
    call BlzFrameSetPoint(QUI_RewardItemName, FRAMEPOINT_TOPLEFT, QUI_RewardItemIcon, FRAMEPOINT_TOPRIGHT, 0.008, 0.0)
    call BlzFrameSetPoint(QUI_RewardItemName, FRAMEPOINT_BOTTOMRIGHT, QUI_Parent, FRAMEPOINT_TOPRIGHT, -0.020, -0.149)
    call BlzFrameSetTextAlignment(QUI_RewardItemName, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(QUI_RewardItemName, 0.90)
    call BlzFrameSetEnable(QUI_RewardItemName, false)
    call BlzFrameSetVisible(QUI_RewardItemIcon, false)
    call BlzFrameSetVisible(QUI_RewardItemName, false)

    loop
        exitwhen rowIndex > QUI_VISIBLE_ROWS
        set QUI_RowButton[rowIndex] = BlzCreateFrame("TasQuestBoxButton", QUI_Parent, 0, QUI_ROW_CONTEXT_BASE + rowIndex)
        set QUI_RowIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", QUI_ROW_CONTEXT_BASE + rowIndex)
        set QUI_RowText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", QUI_ROW_CONTEXT_BASE + rowIndex)
        set QUI_RowByButton.integer[GetHandleId(QUI_RowButton[rowIndex])] = rowIndex
        if rowIndex > 1 then
            call BlzFrameSetPoint(QUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, QUI_RowButton[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        call BlzTriggerRegisterFrameEvent(QUI_RowTrigger, QUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(QUI_ClearFocusTrigger, QUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(QUI_WheelTrigger, QUI_RowButton[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(QUI_RowButton[1], FRAMEPOINT_TOPRIGHT, QUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)

    set QUI_NativeQuestButton = BlzGetFrameByName("UpperButtonBarQuestsButton", 0)
    set QUI_OpenButton = BlzCreateFrameByType("GLUETEXTBUTTON", "QuestUIOpenButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "ScriptDialogButton", 0)
    call BlzFrameClearAllPoints(QUI_OpenButton)
    if QUI_NativeQuestButton != null and GetHandleId(QUI_NativeQuestButton) != 0 then
        call BlzFrameSetAllPoints(QUI_OpenButton, QUI_NativeQuestButton)
    else
        call BlzFrameSetAbsPoint(QUI_OpenButton, FRAMEPOINT_TOPLEFT, 0.574, 0.600)
        call BlzFrameSetAbsPoint(QUI_OpenButton, FRAMEPOINT_BOTTOMRIGHT, 0.694, 0.565)
    endif
    call BlzFrameSetLevel(QUI_OpenButton, 3)
    call BlzFrameSetText(QUI_OpenButton, "|cffffffffQuests|r")
    call BlzTriggerRegisterFrameEvent(QUI_OpenTrigger, QUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(QUI_ClearFocusTrigger, QUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(QUI_Parent, false)
    call QUI_ApplyOpenButtonVisibility()
endfunction

private function QUI_DelayedInit takes nothing returns nothing
    call QUI_CreateFrames()
endfunction

public function Init takes nothing returns nothing
    local integer pid = 0

    if QUI_Initialized then
        return
    endif
    set QUI_Initialized = true
    set QUI_RowByButton = Table.create()
    set QUI_CategoryByButton = Table.create()
    set QUI_SectionByButton = Table.create()
    set QUI_FilteredQuest = Table.create()
    set QUI_FlashTimer = CreateTimer()

    loop
        exitwhen pid >= bj_MAX_PLAYERS
        set QUI_Category[pid] = QUI_CATEGORY_ALL
        set QUI_DetailSection[pid] = QUI_SECTION_DESCRIPTION
        set QUI_SliderMaxCache[pid] = -1
        set QUI_SliderValueCache[pid] = -1
        set pid = pid + 1
    endloop

    set QUI_OpenTrigger = CreateTrigger()
    call TriggerAddAction(QUI_OpenTrigger, function QUI_OpenAction)
    set QUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(QUI_CloseTrigger, function QUI_CloseAction)
    set QUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(QUI_RowTrigger, function QUI_RowAction)
    set QUI_CategoryTrigger = CreateTrigger()
    call TriggerAddAction(QUI_CategoryTrigger, function QUI_CategoryAction)
    set QUI_SectionTrigger = CreateTrigger()
    call TriggerAddAction(QUI_SectionTrigger, function QUI_SectionAction)
    set QUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(QUI_SliderTrigger, function QUI_SliderAction)
    set QUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(QUI_WheelTrigger, function QUI_WheelAction)
    set QUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(QUI_ClearFocusTrigger, function QUI_ClearFocusAction)
    set QUI_EscapeTrigger = CreateTrigger()
    set pid = 0
    loop
        exitwhen pid >= bj_MAX_PLAYERS
        call BlzTriggerRegisterPlayerKeyEvent(QUI_EscapeTrigger, Player(pid), OSKEY_ESCAPE, 0, true)
        set pid = pid + 1
    endloop
    call TriggerAddAction(QUI_EscapeTrigger, function QUI_EscapeAction)

    call QuestMaster_AddDataChangedAction(function QUI_OnQuestDataChanged)

    set QUI_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(QUI_InitTrigger, 0.20, false)
    call TriggerAddAction(QUI_InitTrigger, function QUI_DelayedInit)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
