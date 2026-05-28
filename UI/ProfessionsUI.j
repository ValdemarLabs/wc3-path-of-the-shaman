library ProfessionsUI initializer AutoInit requires GatherNodeSkills, GatherNodeItems, GatherNodeUnits, Table, MasterUI
/**
    ProfessionUI
    
    Author: [Valdemar]
    Version: 1.0

    Description: Shows the selected hero's profession progress, current levels, and upcoming unlocks in one place.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    // ======== CONFIG
    private constant integer PUI_SKILL_MAX = 100
    private constant integer PUI_FIRST_PROFESSION = GNS_PROF_MINING
    private constant integer PUI_LAST_PROFESSION = GNS_PROF_COOKING
    private constant integer PUI_MAX_MILESTONES = 128
    // Refresh only while the panel is visible. Keep this modest to avoid UI-side FPS churn.
    private constant real PUI_REFRESH_INTERVAL = 0.75
    private constant real PUI_DETAIL_VIEWPORT_HEIGHT = 0.102
    private constant real PUI_DETAIL_BODY_WIDTH = 0.258
    private constant integer PUI_BODY_WRAP_CHARS = 38
    private constant integer PUI_VISIBLE_BODY_LINES = 8
    private constant integer PUI_VISIBLE_LIST_ROWS = 6

    private boolean PUI_Initialized = false
    private boolean PUI_SyncingDetailScroll = false
    private boolean PUI_SyncingListScroll = false
    private boolean array PUI_Updating
    private boolean array PUI_PendingUpdate
    private boolean array PUI_UpdateQueued
    private boolean PUI_DeferredUpdateRunning = false

    public string TitleText = "|cffffe4a3Professions|r"
    public string ButtonTitleText = "|cffffffffProfessions|r"
    public string CloseButtonText = "X"
    public string ViewingPrefixText = "Viewing: "
    public string NoTrackedHeroText = "No tracked hero"
    public string NoUnlockDataText = "No unlock data available yet"
    public string MaxedText = "Maxed"
    public string AllKnownUnlocksText = "All known unlocks learned"
    public string NextUnlockPrefixText = "Next unlock: "
    public string NextUnlockAtText = " at "
    public string FallbackNodeSuffixText = " node"
    public string DefaultProfessionIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    public string PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    public string ProgressBarTexture = "UI\\Widgets\\Console\\Human\\human-tooltip-background.blp"
    public real OpenButtonTopLeftX = 0.086
    public real OpenButtonTopLeftY = 0.592
    public real OpenButtonBottomRightX = 0.205
    public real OpenButtonBottomRightY = 0.557
    public string array ProfessionIcon
    public string array ProfessionDescription 
    public string array ProfessionAccent

    // ================================

    private framehandle PUI_Parent = null
    private framehandle PUI_OpenButton = null
    private framehandle PUI_Title = null
    private framehandle PUI_ViewingText = null
    private framehandle PUI_LeftPane = null
    private framehandle PUI_RightPane = null
    private framehandle PUI_CloseButton = null
    private framehandle PUI_ReturnButton = null
    private framehandle PUI_DetailIcon = null
    private framehandle PUI_DetailTitle = null
    private framehandle PUI_DetailViewport = null
    private framehandle PUI_DetailBodyText = null
    private framehandle PUI_DetailScroll = null
    private framehandle PUI_ListScroll = null
    private framehandle PUI_DetailBarBackdrop = null
    private framehandle PUI_DetailBar = null
    private framehandle PUI_DetailBarLabel = null

    private framehandle array PUI_RowButton
    private framehandle array PUI_RowIcon
    private framehandle array PUI_RowText
    private framehandle array PUI_RowLevel
    private framehandle array PUI_RowHighlight

    private integer array PUI_SelectedProfession
    private integer array PUI_ListScrollValue
    private integer array PUI_DetailScrollValue
    private integer array PUI_DetailBodySourceHash
    private integer array PUI_DetailBodyHash
    private integer array PUI_DetailBodyLineCount
    private string array PUI_DetailBodyCache

    private integer array PUI_MilestoneCount
    private integer array PUI_MilestoneSkill
    private string array PUI_MilestoneNode
    private integer PUI_LastItemDefinitionCount = -1
    private integer PUI_LastUnitDefinitionCount = -1

    private Table PUI_ButtonProfession = 0

    private trigger PUI_OpenTrigger = null
    private trigger PUI_CloseTrigger = null
    private trigger PUI_ReturnTrigger = null
    private trigger PUI_RowTrigger = null
    private trigger PUI_ClearFocusTrigger = null
    private trigger PUI_SelectTrigger = null
    private trigger PUI_ScrollTrigger = null
    private trigger PUI_ListScrollTrigger = null
    private trigger PUI_WheelTrigger = null
    private timer PUI_RefreshTimer = null
    private timer PUI_DeferredUpdateTimer = null
endglobals

private function PUI_ProfessionCount takes nothing returns integer
    return PUI_LAST_PROFESSION - PUI_FIRST_PROFESSION + 1
endfunction

private function PUI_IsProfessionValid takes integer professionId returns boolean
    return professionId >= PUI_FIRST_PROFESSION and professionId <= PUI_LAST_PROFESSION
endfunction

private function PUI_GetMilestoneKey takes integer professionId, integer index returns integer
    return professionId * PUI_MAX_MILESTONES + index
endfunction

private function PUI_GetViewerUnit takes nothing returns unit
    return GNS_GetUITargetUnit()
endfunction

private function PUI_GetViewerName takes unit u returns string
    if u == null then
        return NoTrackedHeroText
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHeroProperName(u)
    endif
    return GetUnitName(u)
endfunction

private function PUI_SetProfessionMeta takes integer professionId, string iconPath, string accentColor, string description returns nothing
    if ProfessionIcon[professionId] == null or ProfessionIcon[professionId] == "" then
        set ProfessionIcon[professionId] = iconPath
    endif
    if ProfessionAccent[professionId] == null or ProfessionAccent[professionId] == "" then
        set ProfessionAccent[professionId] = accentColor
    endif
    if ProfessionDescription[professionId] == null or ProfessionDescription[professionId] == "" then
        set ProfessionDescription[professionId] = description
    endif
endfunction

private function PUI_InitProfessionMeta takes nothing returns nothing
    call PUI_SetProfessionMeta(GNS_PROF_MINING, "ReplaceableTextures\\CommandButtons\\BTNmining.blp", "|cffd6b46a", "Extract ore and mineral veins to build metal-based progression.")
    call PUI_SetProfessionMeta(GNS_PROF_HERBALISM, "ReplaceableTextures\\CommandButtons\\BTNherbalism.blp", "|cff7fd36b", "Harvest herbs, flowers, and other plant reagents from the wild.")
    call PUI_SetProfessionMeta(GNS_PROF_SKINNING, "ReplaceableTextures\\CommandButtons\\BTNINV_Weapon_ShortBlade_01.blp", "|cffc98f62", "Recover hides and useful materials from slain beasts and carcasses.")
    call PUI_SetProfessionMeta(GNS_PROF_FISHING, "ReplaceableTextures\\CommandButtons\\BTNfishing.blp", "|cff67b9ff", "Pull resources from pools and waters that other professions cannot reach.")
    call PUI_SetProfessionMeta(GNS_PROF_ALCHEMY, "ReplaceableTextures\\CommandButtons\\BTNalchemy.blp", "|cff8ee38e", "Transform gathered reagents into restorative and experimental concoctions.")
    call PUI_SetProfessionMeta(GNS_PROF_BLACKSMITHING, "ReplaceableTextures\\CommandButtons\\BTNTrade_BlackSmithing.blp", "|cffd49758", "Forge metal into practical arms, armor, and field-ready equipment.")
    call PUI_SetProfessionMeta(GNS_PROF_LEATHERWORKING, "ReplaceableTextures\\callCommandButtons\\BTNTrade_LeatherWorking.blp", "|cffb88352", "Shape leather and bone into flexible gear, fittings, and travel tools.")
    call PUI_SetProfessionMeta(GNS_PROF_ENCHANTING, "ReplaceableTextures\\CommandButtons\\BTNDisenchant.blp", "|cff8fb6ff", "Bind arcane power into equipment, components, and magical enhancements.")
    call PUI_SetProfessionMeta(GNS_PROF_COOKING, "ReplaceableTextures\\CommandButtons\\arrayBTNFood_15.blp", "|cffffc96b", "Turn gathered foodstuffs into buffs, provisions, and camp-ready meals.")
endfunction

private function PUI_GetProfessionIcon takes integer professionId returns string
    if ProfessionIcon[professionId] == null or ProfessionIcon[professionId] == "" then
        return DefaultProfessionIcon
    endif
    return ProfessionIcon[professionId]
endfunction

private function PUI_GetProfessionColoredName takes integer professionId returns string
    return ProfessionAccent[professionId] + GNS_GetProfessionName(professionId) + "|r"
endfunction

private function PUI_GetProfessionDescriptionText takes integer professionId returns string
    return ProfessionDescription[professionId]
endfunction

private function PUI_AddMilestone takes integer professionId, integer requiredSkill, string nodeName returns nothing
    local integer i = 0
    local integer count
    local integer key

    if not PUI_IsProfessionValid(professionId) then
        return
    endif

    set count = PUI_MilestoneCount[professionId]
    loop
        exitwhen i >= count
        set key = PUI_GetMilestoneKey(professionId, i)
        if PUI_MilestoneSkill[key] == requiredSkill then
            if (PUI_MilestoneNode[key] == null or PUI_MilestoneNode[key] == "") and nodeName != null and nodeName != "" then
                set PUI_MilestoneNode[key] = nodeName
            endif
            return
        endif
        set i = i + 1
    endloop

    if count >= PUI_MAX_MILESTONES then
        return
    endif

    set key = PUI_GetMilestoneKey(professionId, count)
    set PUI_MilestoneSkill[key] = requiredSkill
    set PUI_MilestoneNode[key] = nodeName
    set PUI_MilestoneCount[professionId] = count + 1
endfunction

private function PUI_RebuildMilestones takes nothing returns nothing
    local integer professionId = PUI_FIRST_PROFESSION
    local integer i = 0
    local integer itemCount = GNI_GetDefinitionCount()
    local integer unitCount = GNU_GetDefinitionCount()

    loop
        exitwhen professionId > PUI_LAST_PROFESSION
        set PUI_MilestoneCount[professionId] = 0
        set professionId = professionId + 1
    endloop

    loop
        exitwhen i >= itemCount
        call PUI_AddMilestone(GNI_GetDefinitionProfessionId(i), GNI_GetDefinitionSkillRequired(i), GNI_GetDefinitionName(i))
        set i = i + 1
    endloop

    set i = 0
    loop
        exitwhen i >= unitCount
        call PUI_AddMilestone(GNU_GetDefinitionProfessionId(i), GNU_GetDefinitionSkillRequired(i), GNU_GetDefinitionName(i))
        set i = i + 1
    endloop

    set PUI_LastItemDefinitionCount = itemCount
    set PUI_LastUnitDefinitionCount = unitCount
endfunction

private function PUI_EnsureMilestones takes nothing returns nothing
    if PUI_LastItemDefinitionCount != GNI_GetDefinitionCount() or PUI_LastUnitDefinitionCount != GNU_GetDefinitionCount() then
        call PUI_RebuildMilestones()
    endif
endfunction

private function PUI_GetNextMilestoneText takes integer professionId, integer currentSkill returns string
    local integer i = 0
    local integer count = PUI_MilestoneCount[professionId]
    local integer bestSkill = -1
    local string bestNode = ""
    local integer key
    local integer skill

    if count <= 0 then
        return NoUnlockDataText
    endif

    loop
        exitwhen i >= count
        set key = PUI_GetMilestoneKey(professionId, i)
        set skill = PUI_MilestoneSkill[key]
        if skill > currentSkill and (bestSkill < 0 or skill < bestSkill) then
            set bestSkill = skill
            set bestNode = PUI_MilestoneNode[key]
        endif
        set i = i + 1
    endloop

    if bestSkill >= 0 then
        if bestNode == null or bestNode == "" then
            set bestNode = GNS_GetProfessionName(professionId) + FallbackNodeSuffixText
        endif
        return NextUnlockPrefixText + bestNode + NextUnlockAtText + I2S(bestSkill)
    endif

    if currentSkill >= PUI_SKILL_MAX then
        return MaxedText
    endif

    return AllKnownUnlocksText
endfunction

private function PUI_WrapBodyText takes string text returns string
    local integer i = 0
    local integer length = StringLength(text)
    local integer lineChars = 0
    local string result = ""
    local string token
    local string activeColor = ""
    local string word = ""
    local integer wordChars = 0
    local boolean pendingSpace = false

    loop
        exitwhen i >= length
        if i + 1 < length and SubString(text, i, i + 2) == "|n" then
            if wordChars > 0 then
                if lineChars > 0 and lineChars + wordChars + 1 > PUI_BODY_WRAP_CHARS and pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                    set pendingSpace = false
                elseif lineChars > 0 and lineChars + wordChars > PUI_BODY_WRAP_CHARS and not pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                endif
                if pendingSpace and lineChars > 0 then
                    set result = result + " "
                    set lineChars = lineChars + 1
                endif
                set result = result + word
                set lineChars = lineChars + wordChars
                set word = ""
                set wordChars = 0
                set pendingSpace = false
            endif
            set result = result + "|n"
            set lineChars = 0
            set i = i + 2
            if activeColor != "" then
                set result = result + activeColor
            endif
        elseif i + 1 < length and SubString(text, i, i + 2) == "|r" then
            if wordChars > 0 then
                if lineChars > 0 and lineChars + wordChars + 1 > PUI_BODY_WRAP_CHARS and pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                    set pendingSpace = false
                elseif lineChars > 0 and lineChars + wordChars > PUI_BODY_WRAP_CHARS and not pendingSpace then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                endif
                if pendingSpace and lineChars > 0 then
                    set result = result + " "
                    set lineChars = lineChars + 1
                endif
                set result = result + word
                set lineChars = lineChars + wordChars
                set word = ""
                set wordChars = 0
                set pendingSpace = false
            endif
            set result = result + "|r"
            set activeColor = ""
            set i = i + 2
        elseif i + 9 < length and SubString(text, i, i + 2) == "|c" then
            set token = SubString(text, i, i + 10)
            set activeColor = token
            set result = result + token
            set i = i + 10
        else
            set token = SubString(text, i, i + 1)
            if token == " " then
                if wordChars > 0 then
                    if lineChars > 0 and lineChars + wordChars + 1 > PUI_BODY_WRAP_CHARS and pendingSpace then
                        set result = result + "|n"
                        set lineChars = 0
                        if activeColor != "" then
                            set result = result + activeColor
                        endif
                        set pendingSpace = false
                    elseif lineChars > 0 and lineChars + wordChars > PUI_BODY_WRAP_CHARS and not pendingSpace then
                        set result = result + "|n"
                        set lineChars = 0
                        if activeColor != "" then
                            set result = result + activeColor
                        endif
                    endif
                    if pendingSpace and lineChars > 0 then
                        set result = result + " "
                        set lineChars = lineChars + 1
                    endif
                    set result = result + word
                    set lineChars = lineChars + wordChars
                    set word = ""
                    set wordChars = 0
                endif
                set pendingSpace = lineChars > 0
            else
                if wordChars == 0 and pendingSpace and lineChars >= PUI_BODY_WRAP_CHARS then
                    set result = result + "|n"
                    set lineChars = 0
                    if activeColor != "" then
                        set result = result + activeColor
                    endif
                    set pendingSpace = false
                endif
                if wordChars > 0 and lineChars == 0 and wordChars >= PUI_BODY_WRAP_CHARS then
                    set result = result + word + token
                    set lineChars = wordChars + 1
                    set word = ""
                    set wordChars = 0
                else
                    set word = word + token
                    set wordChars = wordChars + 1
                endif
            endif
            set i = i + 1
        endif
    endloop

    if wordChars > 0 then
        if lineChars > 0 and lineChars + wordChars + 1 > PUI_BODY_WRAP_CHARS and pendingSpace then
            set result = result + "|n"
            set lineChars = 0
            if activeColor != "" then
                set result = result + activeColor
            endif
            set pendingSpace = false
        elseif lineChars > 0 and lineChars + wordChars > PUI_BODY_WRAP_CHARS and not pendingSpace then
            set result = result + "|n"
            set lineChars = 0
            if activeColor != "" then
                set result = result + activeColor
            endif
        endif
        if pendingSpace and lineChars > 0 then
            set result = result + " "
        endif
        set result = result + word
    endif

    if activeColor != "" and StringLength(result) >= 2 and SubString(result, StringLength(result) - 2, StringLength(result)) != "|r" then
        set result = result + "|r"
    endif

    return result
endfunction

private function PUI_GetBodyLineCount takes string text returns integer
    local integer i = 0
    local integer length = StringLength(text)
    local integer lineCount = 1

    loop
        exitwhen i >= length
        if i + 1 < length and SubString(text, i, i + 2) == "|n" then
            set lineCount = lineCount + 1
            set i = i + 2
        elseif i + 1 < length and SubString(text, i, i + 2) == "|r" then
            set i = i + 2
        elseif i + 9 < length and SubString(text, i, i + 2) == "|c" then
            set i = i + 10
        else
            set i = i + 1
        endif
    endloop

    return lineCount
endfunction

private function PUI_GetBodyVisibleText takes string text, integer startLine, integer maxLines returns string
    local integer i = 0
    local integer length = StringLength(text)
    local integer currentLine = 0
    local integer endLine = startLine + maxLines
    local string result = ""
    local string token
    local string activeColor = ""

    loop
        exitwhen i >= length or currentLine >= endLine
        if i + 1 < length and SubString(text, i, i + 2) == "|n" then
            if currentLine >= startLine and currentLine + 1 < endLine then
                set result = result + "|n"
            endif
            set currentLine = currentLine + 1
            set i = i + 2
            if currentLine >= startLine and currentLine < endLine and activeColor != "" then
                set result = result + activeColor
            endif
        elseif i + 1 < length and SubString(text, i, i + 2) == "|r" then
            if currentLine >= startLine and currentLine < endLine then
                set result = result + "|r"
            endif
            set activeColor = ""
            set i = i + 2
        elseif i + 9 < length and SubString(text, i, i + 2) == "|c" then
            set token = SubString(text, i, i + 10)
            set activeColor = token
            if currentLine >= startLine and currentLine < endLine then
                set result = result + token
            endif
            set i = i + 10
        else
            if currentLine >= startLine and currentLine < endLine then
                set result = result + SubString(text, i, i + 1)
            endif
            set i = i + 1
        endif
    endloop

    if activeColor != "" and StringLength(result) >= 2 and SubString(result, StringLength(result) - 2, StringLength(result)) != "|r" then
        set result = result + "|r"
    endif
    return result
endfunction

private function PUI_GetBodyText takes integer professionId, integer currentSkill returns string
    return PUI_GetProfessionDescriptionText(professionId) + "|n|n" + PUI_GetNextMilestoneText(professionId, currentSkill)
endfunction

private function PUI_RefreshDetailBodyFromCache takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local integer maxStartLine = PUI_DetailBodyLineCount[pid] - PUI_VISIBLE_BODY_LINES
    local string visibleText

    if maxStartLine < 0 then
        set maxStartLine = 0
    endif
    if PUI_DetailScrollValue[pid] < 0 then
        set PUI_DetailScrollValue[pid] = 0
    elseif PUI_DetailScrollValue[pid] > maxStartLine then
        set PUI_DetailScrollValue[pid] = maxStartLine
    endif

    set visibleText = PUI_GetBodyVisibleText(PUI_DetailBodyCache[pid], PUI_DetailScrollValue[pid], PUI_VISIBLE_BODY_LINES)

    if GetLocalPlayer() == whichPlayer then
        call BlzFrameSetText(PUI_DetailBodyText, visibleText)
        set PUI_SyncingDetailScroll = true
        call BlzFrameSetMinMaxValue(PUI_DetailScroll, 0.0, I2R(maxStartLine))
        call BlzFrameSetValue(PUI_DetailScroll, I2R(PUI_DetailScrollValue[pid]))
        set PUI_SyncingDetailScroll = false
        call BlzFrameSetVisible(PUI_DetailScroll, maxStartLine > 0)
    endif
endfunction

private function PUI_SetDetailBody takes player whichPlayer, string bodyText returns nothing
    local integer pid = GetPlayerId(whichPlayer)
    local string wrappedText = PUI_WrapBodyText(bodyText)
    local integer sourceHash = StringHash(bodyText)
    local integer newHash = StringHash(wrappedText)

    if PUI_DetailBodyHash[pid] != newHash or PUI_DetailBodyCache[pid] != wrappedText then
        set PUI_DetailBodySourceHash[pid] = sourceHash
        set PUI_DetailBodyHash[pid] = newHash
        set PUI_DetailBodyCache[pid] = wrappedText
        set PUI_DetailBodyLineCount[pid] = PUI_GetBodyLineCount(wrappedText)
        set PUI_DetailScrollValue[pid] = 0
    endif

    call PUI_RefreshDetailBodyFromCache(whichPlayer)
endfunction

private function PUI_UpdateForPlayer takes player whichPlayer returns nothing
    local integer pid
    local integer professionId
    local integer rowIndex
    local integer currentSkill
    local unit viewer
    local string bodyText
    local integer bodyHash
    local integer visibleProfessionId
    local integer maxListStart

    if PUI_Parent == null then
        return
    endif

    set pid = GetPlayerId(whichPlayer)
    if PUI_Updating[pid] then
        set PUI_PendingUpdate[pid] = true
        return
    endif
    set PUI_Updating[pid] = true

    if not PUI_IsProfessionValid(PUI_SelectedProfession[pid]) then
        set PUI_SelectedProfession[pid] = GNS_PROF_MINING
    endif
    set maxListStart = PUI_ProfessionCount() - PUI_VISIBLE_LIST_ROWS
    if maxListStart < 0 then
        set maxListStart = 0
    endif
    if PUI_ListScrollValue[pid] < 0 then
        set PUI_ListScrollValue[pid] = 0
    elseif PUI_ListScrollValue[pid] > maxListStart then
        set PUI_ListScrollValue[pid] = maxListStart
    endif

    call PUI_EnsureMilestones()
    set viewer = PUI_GetViewerUnit()

    if GetLocalPlayer() == whichPlayer then
        call BlzFrameSetText(PUI_ViewingText, ViewingPrefixText + PUI_GetViewerName(viewer))

        set rowIndex = 0
        set professionId = PUI_FIRST_PROFESSION + PUI_ListScrollValue[pid]
        loop
            exitwhen rowIndex >= PUI_VISIBLE_LIST_ROWS or professionId > PUI_LAST_PROFESSION
            set rowIndex = rowIndex + 1
            set currentSkill = GNS_GetSkill(viewer, professionId)

            call BlzFrameSetTexture(PUI_RowIcon[rowIndex], PUI_GetProfessionIcon(professionId), 0, true)
            call BlzFrameSetText(PUI_RowText[rowIndex], PUI_GetProfessionColoredName(professionId))
            call BlzFrameSetText(PUI_RowLevel[rowIndex], I2S(currentSkill) + "/" + I2S(PUI_SKILL_MAX))
            call BlzFrameSetVisible(PUI_RowHighlight[rowIndex], professionId == PUI_SelectedProfession[pid])
            call BlzFrameSetVisible(PUI_RowButton[rowIndex], true)
            set PUI_ButtonProfession.integer[GetHandleId(PUI_RowButton[rowIndex])] = professionId

            set professionId = professionId + 1
        endloop
        loop
            exitwhen rowIndex >= PUI_ProfessionCount()
            set rowIndex = rowIndex + 1
            call BlzFrameSetVisible(PUI_RowButton[rowIndex], false)
        endloop
        set PUI_SyncingListScroll = true
        call BlzFrameSetMinMaxValue(PUI_ListScroll, 0.0, I2R(maxListStart))
        call BlzFrameSetValue(PUI_ListScroll, I2R(PUI_ListScrollValue[pid]))
        set PUI_SyncingListScroll = false
        call BlzFrameSetVisible(PUI_ListScroll, maxListStart > 0)

        set professionId = PUI_SelectedProfession[pid]
        set currentSkill = GNS_GetSkill(viewer, professionId)

        call BlzFrameSetTexture(PUI_DetailIcon, PUI_GetProfessionIcon(professionId), 0, true)
        call BlzFrameSetText(PUI_DetailTitle, PUI_GetProfessionColoredName(professionId))
        call BlzFrameSetValue(PUI_DetailBar, I2R(currentSkill))
        call BlzFrameSetText(PUI_DetailBarLabel, I2S(currentSkill) + " / " + I2S(PUI_SKILL_MAX))
    endif

    set bodyText = PUI_GetBodyText(professionId, currentSkill)
    set bodyHash = StringHash(bodyText)
    if PUI_DetailBodySourceHash[pid] != bodyHash then
        call PUI_SetDetailBody(whichPlayer, bodyText)
    endif

    set PUI_Updating[pid] = false
    if PUI_PendingUpdate[pid] then
        set PUI_PendingUpdate[pid] = false
        call PUI_UpdateForPlayer(whichPlayer)
    endif

    set viewer = null
endfunction

private function PUI_RunDeferredUpdates takes nothing returns nothing
    local integer i = 0

    set PUI_DeferredUpdateRunning = false
    loop
        exitwhen i >= bj_MAX_PLAYERS
        if PUI_UpdateQueued[i] then
            set PUI_UpdateQueued[i] = false
            call PUI_UpdateForPlayer(Player(i))
        endif
        set i = i + 1
    endloop
endfunction

private function PUI_RequestUpdate takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)

    set PUI_UpdateQueued[pid] = true
    if not PUI_DeferredUpdateRunning then
        set PUI_DeferredUpdateRunning = true
        call TimerStart(PUI_DeferredUpdateTimer, 0.00, false, function PUI_RunDeferredUpdates)
    endif
endfunction

private function PUI_PosOpenButton takes framehandle frame returns nothing
    local framehandle questButton = BlzGetFrameByName("UpperButtonBarQuestsButton", 0)
    local real fallbackWidth = OpenButtonBottomRightX - OpenButtonTopLeftX
    local real fallbackHeight = OpenButtonTopLeftY - OpenButtonBottomRightY

    call BlzFrameClearAllPoints(frame)
    if GetHandleId(questButton) != 0 then
        if fallbackWidth <= 0.0 then
            set fallbackWidth = BlzFrameGetWidth(questButton)
        endif
        if fallbackHeight <= 0.0 then
            set fallbackHeight = BlzFrameGetHeight(questButton)
        endif
        call BlzFrameSetSize(frame, fallbackWidth, fallbackHeight)
        call BlzFrameSetPoint(frame, FRAMEPOINT_TOPRIGHT, questButton, FRAMEPOINT_TOPLEFT, 0.0, 0.0)
    else
        call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, OpenButtonTopLeftX, OpenButtonTopLeftY)
        call BlzFrameSetAbsPoint(frame, FRAMEPOINT_BOTTOMRIGHT, OpenButtonBottomRightX, OpenButtonBottomRightY)
    endif
    call BlzFrameSetLevel(frame, 3)

    set questButton = null
endfunction

private function PUI_RefreshOpenButtonPosition takes nothing returns nothing
    if PUI_OpenButton != null then
        call BlzFrameClearAllPoints(PUI_OpenButton)
        call PUI_PosOpenButton(PUI_OpenButton)
    endif
endfunction

private function PUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local integer professionId = PUI_FIRST_PROFESSION
    local real rowTopOffset = -0.012
    local real rowHeight = 0.033
    local real rowGap = 0.003

    set PUI_Parent = BlzCreateFrameByType("BACKDROP", "ProfessionsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(PUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(PUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

    set PUI_Title = BlzCreateFrameByType("TEXT", "ProfessionsUITitle", PUI_Parent, "", 0)
    call BlzFrameSetPoint(PUI_Title, FRAMEPOINT_TOPLEFT, PUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(PUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(PUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(PUI_Title, 1.10)
    call BlzFrameSetEnable(PUI_Title, false)
    call BlzFrameSetText(PUI_Title, TitleText)

    set PUI_ViewingText = BlzCreateFrameByType("TEXT", "ProfessionsUIViewing", PUI_Parent, "", 0)
    call BlzFrameSetPoint(PUI_ViewingText, FRAMEPOINT_TOPLEFT, PUI_Title, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.006)
    call BlzFrameSetSize(PUI_ViewingText, 0.40, 0.014)
    call BlzFrameSetTextAlignment(PUI_ViewingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetEnable(PUI_ViewingText, false)

    set PUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ProfessionsUIClose", PUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(PUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(PUI_CloseButton, CloseButtonText)
    call BlzFrameSetPoint(PUI_CloseButton, FRAMEPOINT_TOPRIGHT, PUI_Parent, FRAMEPOINT_TOPRIGHT, -0.01, -0.01)

    set PUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ProfessionsUIReturn", PUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(PUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(PUI_ReturnButton, "Return")
    call BlzFrameSetPoint(PUI_ReturnButton, FRAMEPOINT_TOPRIGHT, PUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)

    set PUI_LeftPane = BlzCreateFrameByType("BACKDROP", "ProfessionsUILeftPane", PUI_Parent, "", 0)
    call BlzFrameSetTexture(PUI_LeftPane, PanelTexture, 0, true)
    call BlzFrameSetPoint(PUI_LeftPane, FRAMEPOINT_TOPLEFT, PUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.078)
    call BlzFrameSetPoint(PUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, PUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

    set PUI_RightPane = BlzCreateFrameByType("BACKDROP", "ProfessionsUIRightPane", PUI_Parent, "", 0)
    call BlzFrameSetTexture(PUI_RightPane, PanelTexture, 0, true)
    call BlzFrameSetPoint(PUI_RightPane, FRAMEPOINT_TOPLEFT, PUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(PUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, PUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

    set PUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "ProfessionsUIDetailIcon", PUI_RightPane, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(PUI_DetailIcon, FRAMEPOINT_TOPLEFT, PUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(PUI_DetailIcon, 0.042, 0.042)

    set PUI_DetailTitle = BlzCreateFrameByType("TEXT", "ProfessionsUIDetailTitle", PUI_RightPane, "", 0)
    call BlzFrameSetPoint(PUI_DetailTitle, FRAMEPOINT_TOPLEFT, PUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(PUI_DetailTitle, 0.232, 0.018)
    call BlzFrameSetTextAlignment(PUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(PUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(PUI_DetailTitle, false)

    set PUI_DetailBarBackdrop = BlzCreateFrameByType("BACKDROP", "ProfessionsUIBarBackdrop", PUI_RightPane, "", 0)
    call BlzFrameSetTexture(PUI_DetailBarBackdrop, PanelTexture, 0, true)
    call BlzFrameSetPoint(PUI_DetailBarBackdrop, FRAMEPOINT_TOPLEFT, PUI_DetailIcon, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.016)
    call BlzFrameSetSize(PUI_DetailBarBackdrop, 0.270, 0.02)

    set PUI_DetailBar = BlzCreateSimpleFrame("SimpleStatusBarTemplate", PUI_DetailBarBackdrop, 0)
    call BlzFrameSetAllPoints(PUI_DetailBar, PUI_DetailBarBackdrop)
    call BlzFrameSetTexture(PUI_DetailBar, ProgressBarTexture, 0, true)
    call BlzFrameSetMinMaxValue(PUI_DetailBar, 0.00, I2R(PUI_SKILL_MAX))
    call BlzFrameSetValue(PUI_DetailBar, 0)

    set PUI_DetailBarLabel = BlzCreateFrameByType("TEXT", "ProfessionsUIBarLabel", PUI_DetailBarBackdrop, "", 0)
    call BlzFrameSetAllPoints(PUI_DetailBarLabel, PUI_DetailBarBackdrop)
    call BlzFrameSetTextAlignment(PUI_DetailBarLabel, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetEnable(PUI_DetailBarLabel, false)

    set PUI_DetailViewport = BlzCreateFrameByType("FRAME", "ProfessionsUIDetailViewport", PUI_RightPane, "", 0)
    call BlzFrameSetPoint(PUI_DetailViewport, FRAMEPOINT_TOPLEFT, PUI_DetailBarBackdrop, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.016)
    call BlzFrameSetSize(PUI_DetailViewport, PUI_DETAIL_BODY_WIDTH, PUI_DETAIL_VIEWPORT_HEIGHT)

    set PUI_DetailBodyText = BlzCreateFrameByType("TEXT", "ProfessionsUIDetailBody", PUI_DetailViewport, "", 0)
    call BlzFrameSetPoint(PUI_DetailBodyText, FRAMEPOINT_TOPLEFT, PUI_DetailViewport, FRAMEPOINT_TOPLEFT, 0.0, 0.0)
    call BlzFrameSetSize(PUI_DetailBodyText, PUI_DETAIL_BODY_WIDTH, PUI_DETAIL_VIEWPORT_HEIGHT)
    call BlzFrameSetTextAlignment(PUI_DetailBodyText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(PUI_DetailBodyText, 0.95)
    call BlzFrameSetEnable(PUI_DetailBodyText, false)

    set PUI_DetailScroll = BlzCreateFrameByType("SLIDER", "ProfessionsUIDetailScroll", PUI_RightPane, "QuestMainListScrollBar", 0)
    call BlzFrameSetPoint(PUI_DetailScroll, FRAMEPOINT_TOPLEFT, PUI_DetailViewport, FRAMEPOINT_TOPRIGHT, 0.004, 0.0)
    call BlzFrameSetSize(PUI_DetailScroll, BlzFrameGetWidth(PUI_DetailScroll), PUI_DETAIL_VIEWPORT_HEIGHT)
    call BlzFrameSetMinMaxValue(PUI_DetailScroll, 0.0, 0.0)
    call BlzFrameSetStepSize(PUI_DetailScroll, 1.0)
    call BlzFrameSetValue(PUI_DetailScroll, 0.0)
    call BlzTriggerRegisterFrameEvent(PUI_ScrollTrigger, PUI_DetailScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(PUI_WheelTrigger, PUI_DetailScroll, FRAMEEVENT_MOUSE_WHEEL)
    call BlzTriggerRegisterFrameEvent(PUI_WheelTrigger, PUI_DetailViewport, FRAMEEVENT_MOUSE_WHEEL)

    set PUI_ListScroll = BlzCreateFrameByType("SLIDER", "ProfessionsUIListScroll", PUI_LeftPane, "QuestMainListScrollBar", 0)
    call BlzFrameSetPoint(PUI_ListScroll, FRAMEPOINT_TOPLEFT, PUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
    call BlzFrameSetPoint(PUI_ListScroll, FRAMEPOINT_BOTTOMLEFT, PUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, 0.004, 0.002)
    call BlzFrameSetMinMaxValue(PUI_ListScroll, 0.0, 0.0)
    call BlzFrameSetStepSize(PUI_ListScroll, 1.0)
    call BlzFrameSetValue(PUI_ListScroll, 0.0)
    call BlzTriggerRegisterFrameEvent(PUI_ListScrollTrigger, PUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(PUI_WheelTrigger, PUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
    call BlzTriggerRegisterFrameEvent(PUI_WheelTrigger, PUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

    loop
        exitwhen professionId > PUI_LAST_PROFESSION

        set PUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "ProfessionsUIRowButton" + I2S(rowIndex), PUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(PUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, PUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(PUI_RowButton[rowIndex], 0.156, rowHeight)
        call BlzTriggerRegisterFrameEvent(PUI_RowTrigger, PUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PUI_ClearFocusTrigger, PUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        set PUI_ButtonProfession.integer[GetHandleId(PUI_RowButton[rowIndex])] = professionId

        set PUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "ProfessionsUIRowIcon" + I2S(rowIndex), PUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(PUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, PUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(PUI_RowIcon[rowIndex], 0.02, 0.02)

        set PUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "ProfessionsUIRowText" + I2S(rowIndex), PUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(PUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, PUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
        call BlzFrameSetPoint(PUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, PUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.05, 0.004)
        call BlzFrameSetTextAlignment(PUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(PUI_RowText[rowIndex], false)

        set PUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "ProfessionsUIRowLevel" + I2S(rowIndex), PUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(PUI_RowLevel[rowIndex], FRAMEPOINT_TOPRIGHT, PUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
        call BlzFrameSetPoint(PUI_RowLevel[rowIndex], FRAMEPOINT_BOTTOMRIGHT, PUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
        call BlzFrameSetTextAlignment(PUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetEnable(PUI_RowLevel[rowIndex], false)

        set PUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "ProfessionsUIRowHighlight" + I2S(rowIndex), PUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(PUI_RowHighlight[rowIndex], PUI_RowButton[rowIndex])
        call BlzFrameSetModel(PUI_RowHighlight[rowIndex], "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx", 0)
        call BlzFrameSetScale(PUI_RowHighlight[rowIndex], 0.76)
        call BlzFrameSetVisible(PUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(PUI_RowHighlight[rowIndex], false)

        set rowTopOffset = rowTopOffset - rowHeight - rowGap
        set rowIndex = rowIndex + 1
        set professionId = professionId + 1
    endloop

    set PUI_OpenButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ProfessionsUIOpenButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "ScriptDialogButton", 0)
    call PUI_PosOpenButton(PUI_OpenButton)
    call BlzFrameSetText(PUI_OpenButton, ButtonTitleText)
    call BlzTriggerRegisterFrameEvent(PUI_OpenTrigger, PUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PUI_ClearFocusTrigger, PUI_OpenButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PUI_CloseTrigger, PUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PUI_ClearFocusTrigger, PUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PUI_ReturnTrigger, PUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(PUI_ClearFocusTrigger, PUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    call BlzFrameSetVisible(PUI_Parent, false)
endfunction

private function PUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function PUI_OpenAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)

    if not PUI_IsProfessionValid(PUI_SelectedProfession[pid]) then
        set PUI_SelectedProfession[pid] = GNS_PROF_MINING
    endif

    call PUI_RefreshOpenButtonPosition()
    if GetLocalPlayer() == p then
        call BlzFrameSetVisible(PUI_Parent, not BlzFrameIsVisible(PUI_Parent))
    endif
    if PUI_Parent != null and BlzFrameIsVisible(PUI_Parent) then
        call PUI_RequestUpdate(p)
    endif

    set p = null
endfunction

private function PUI_PeriodicRefresh takes nothing returns nothing
    if PUI_Parent != null and BlzFrameIsVisible(PUI_Parent) then
        call PUI_RequestUpdate(GetLocalPlayer())
    endif
endfunction

private function PUI_SetRefreshActive takes boolean active returns nothing
    if PUI_RefreshTimer == null then
        return
    endif
    if active then
        call TimerStart(PUI_RefreshTimer, PUI_REFRESH_INTERVAL, true, function PUI_PeriodicRefresh)
    else
        call PauseTimer(PUI_RefreshTimer)
    endif
endfunction

public function Hide takes nothing returns nothing
    call PUI_SetRefreshActive(false)
    if PUI_Parent != null then
        call BlzFrameSetVisible(PUI_Parent, false)
    endif
endfunction

private function PUI_CloseAction takes nothing returns nothing
    call Hide()
endfunction

private function PUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function PUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p)
    local integer handleId = GetHandleId(BlzGetTriggerFrame())

    if PUI_ButtonProfession.has(handleId) then
        set PUI_SelectedProfession[pid] = PUI_ButtonProfession.integer[handleId]
        call PUI_RequestUpdate(p)
    endif

    set p = null
endfunction

private function PUI_SelectAction takes nothing returns nothing
    if PUI_Parent != null and BlzFrameIsVisible(PUI_Parent) and GNS_IsTrackedGatherer(GetTriggerUnit()) then
        call PUI_RequestUpdate(GetTriggerPlayer())
    endif
endfunction

private function PUI_ScrollAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    if PUI_SyncingDetailScroll then
        set p = null
        return
    endif
    set PUI_DetailScrollValue[GetPlayerId(p)] = R2I(BlzGetTriggerFrameValue())
    call PUI_RefreshDetailBodyFromCache(p)
    set p = null
endfunction

private function PUI_ListScrollAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    if PUI_SyncingListScroll then
        set p = null
        return
    endif
    set PUI_ListScrollValue[GetPlayerId(p)] = R2I(BlzGetTriggerFrameValue())
    call PUI_RequestUpdate(p)
    set p = null
endfunction

private function PUI_WheelAction takes nothing returns nothing
    local framehandle triggerFrame = BlzGetTriggerFrame()

    if GetLocalPlayer() == GetTriggerPlayer() then
        if (triggerFrame == PUI_ListScroll or triggerFrame == PUI_LeftPane) and PUI_ListScroll != null and BlzFrameIsVisible(PUI_ListScroll) then
            if BlzGetTriggerFrameValue() > 0 then
                call BlzFrameSetValue(PUI_ListScroll, BlzFrameGetValue(PUI_ListScroll) + 1.0)
            else
                call BlzFrameSetValue(PUI_ListScroll, BlzFrameGetValue(PUI_ListScroll) - 1.0)
            endif
        elseif PUI_DetailScroll != null and BlzFrameIsVisible(PUI_DetailScroll) then
            if BlzGetTriggerFrameValue() > 0 then
                call BlzFrameSetValue(PUI_DetailScroll, BlzFrameGetValue(PUI_DetailScroll) + 1.0)
            else
                call BlzFrameSetValue(PUI_DetailScroll, BlzFrameGetValue(PUI_DetailScroll) - 1.0)
            endif
        endif
    endif
    set triggerFrame = null
endfunction

public function Refresh takes nothing returns nothing
    call PUI_RequestUpdate(GetLocalPlayer())
endfunction

public function Show takes nothing returns nothing
    call PUI_RefreshOpenButtonPosition()
    call PUI_SetRefreshActive(true)
    call BlzFrameSetVisible(PUI_Parent, true)
    call PUI_RequestUpdate(GetLocalPlayer())
endfunction

public function Toggle takes nothing returns nothing
    call PUI_RefreshOpenButtonPosition()
    if PUI_Parent != null and BlzFrameIsVisible(PUI_Parent) then
        call Hide()
    else
        call Show()
    endif
endfunction

public function SetButtonVisible takes boolean flag returns nothing
    if PUI_OpenButton != null then
        call BlzFrameSetVisible(PUI_OpenButton, flag)
    endif
endfunction

public function GetOpenButton takes nothing returns framehandle
    return PUI_OpenButton
endfunction

public function Init takes nothing returns nothing
    local integer i = 0

    if PUI_Initialized then
        return
    endif
    set PUI_Initialized = true

    set PUI_ButtonProfession = Table.create()
    call PUI_InitProfessionMeta()

    set PUI_OpenTrigger = CreateTrigger()
    call TriggerAddAction(PUI_OpenTrigger, function PUI_OpenAction)

    set PUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(PUI_CloseTrigger, function PUI_CloseAction)

    set PUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(PUI_ReturnTrigger, function PUI_ReturnAction)

    set PUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(PUI_RowTrigger, function PUI_RowAction)

    set PUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(PUI_ClearFocusTrigger, function PUI_ClearFocusAction)

    set PUI_SelectTrigger = CreateTrigger()
    loop
        exitwhen i >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(PUI_SelectTrigger, Player(i), EVENT_PLAYER_UNIT_SELECTED, null)
        set PUI_SelectedProfession[i] = GNS_PROF_MINING
        set i = i + 1
    endloop
    call TriggerAddAction(PUI_SelectTrigger, function PUI_SelectAction)

    set PUI_ScrollTrigger = CreateTrigger()
    call TriggerAddAction(PUI_ScrollTrigger, function PUI_ScrollAction)

    set PUI_ListScrollTrigger = CreateTrigger()
    call TriggerAddAction(PUI_ListScrollTrigger, function PUI_ListScrollAction)

    set PUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(PUI_WheelTrigger, function PUI_WheelAction)

    call PUI_CreateFrames()
    call SetButtonVisible(false)
    call PUI_RebuildMilestones()

    set PUI_RefreshTimer = CreateTimer()
    set PUI_DeferredUpdateTimer = CreateTimer()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
