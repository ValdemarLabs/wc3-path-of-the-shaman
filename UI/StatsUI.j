library StatsUI initializer AutoInit requires Table, MasterUI
/**
    StatsUI
    
    Author: [Valdemar]
    Version: 1.0

    Description: Shows the current party and companion stats with a quick list and a detailed view.

    Credits: Tasyen (TasQuestBox as inspiration)

**/

globals
    private constant real SUI_REFRESH_INTERVAL = 1.00
    private constant integer SUI_MAX_ROWS = 8
    private constant integer SUI_VISIBLE_ROWS = 6

    private boolean SUI_Initialized = false
    private boolean SUI_IsVisible = false
    private boolean SUI_SyncingListScroll = false
    private integer SUI_SelectedRow = 0

    private framehandle SUI_Parent = null
    private framehandle SUI_Title = null
    private framehandle SUI_LeftPane = null
    private framehandle SUI_RightPane = null
    private framehandle SUI_CloseButton = null
    private framehandle SUI_ReturnButton = null
    private framehandle SUI_ListScroll = null
    private framehandle SUI_DetailIcon = null
    private framehandle SUI_DetailTitle = null
    private framehandle SUI_DetailValue = null
    private framehandle SUI_DetailDescription = null

    private framehandle array SUI_RowButton
    private framehandle array SUI_RowIcon
    private framehandle array SUI_RowText
    private framehandle array SUI_RowLevel
    private framehandle array SUI_RowHighlight
    private unit array SUI_RowUnit
    private integer array SUI_RowKind
    private integer array SUI_ListScrollValue

    private Table SUI_ButtonRow = 0

    private trigger SUI_CloseTrigger = null
    private trigger SUI_ReturnTrigger = null
    private trigger SUI_RowTrigger = null
    private trigger SUI_ListScrollTrigger = null
    private trigger SUI_ClearFocusTrigger = null
    private trigger SUI_WheelTrigger = null
    private timer SUI_RefreshTimer = null

    private string SUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private string SUI_RowHighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
    private string SUI_DefaultUnitIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    private integer SUI_KIND_HERO = 1
    private integer SUI_KIND_PET = 2
    private integer SUI_KIND_COMPANION = 3
endglobals

private function SUI_GetDisplayName takes unit u returns string
    if u == null or GetHandleId(u) == 0 then
        return "Unavailable"
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHeroProperName(u)
    endif
    return GetUnitName(u)
endfunction

private function SUI_GetKindLabel takes integer kind returns string
    if kind == SUI_KIND_HERO then
        return "|cffffcc00Player|r"
    elseif kind == SUI_KIND_PET then
        return "|cff9fd3ffPet|r"
    endif
    return "|cffffffccCompanion|r"
endfunction

private function SUI_GetUnitIconPath takes unit u returns string
    local string iconPath

    if u == null or GetHandleId(u) == 0 then
        return SUI_DefaultUnitIcon
    endif

    set iconPath = BlzGetAbilityIcon(GetUnitTypeId(u))
    if iconPath == null or iconPath == "" then
        return SUI_DefaultUnitIcon
    endif
    return iconPath
endfunction

private function SUI_GetHealthColor takes integer percent returns string
    if percent >= 75 then
        return "|cff00ff00"
    elseif percent >= 50 then
        return "|cffffff00"
    elseif percent >= 25 then
        return "|cffff8a0e"
    endif
    return "|cffff0000"
endfunction

private function SUI_GetHealthPercent takes unit u returns integer
    local real maxLife
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    set maxLife = GetUnitState(u, UNIT_STATE_MAX_LIFE)
    if maxLife <= 0.0 then
        return 0
    endif
    return R2I((GetUnitState(u, UNIT_STATE_LIFE) / maxLife) * 100.0)
endfunction

private function SUI_GetManaPercent takes unit u returns integer
    local real maxMana
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    set maxMana = GetUnitState(u, UNIT_STATE_MAX_MANA)
    if maxMana <= 0.0 then
        return 0
    endif
    return R2I((GetUnitState(u, UNIT_STATE_MANA) / maxMana) * 100.0)
endfunction

private function SUI_GetStatusText takes unit u returns string
    local integer hp
    local integer mp

    if u == null or GetHandleId(u) == 0 then
        return "|cff7f7f7fUnavailable|r"
    endif
    if GetWidgetLife(u) <= 0.405 then
        return "|cffff0000Dead|r"
    endif

    set hp = SUI_GetHealthPercent(u)
    set mp = SUI_GetManaPercent(u)
    return SUI_GetHealthColor(hp) + I2S(hp) + "|r / |cff7ebff1" + I2S(mp) + "|r"
endfunction

private function SUI_GetLevelText takes unit u returns string
    if u == null or GetHandleId(u) == 0 then
        return "-"
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return I2S(GetHeroLevel(u))
    endif
    return I2S(GetUnitLevel(u))
endfunction

private function SUI_GetUnitPoints takes unit u returns integer
    if u == udg_Nazgrek then
        return udg_AbilityPointsNazgrek
    elseif u == udg_Zulkis then
        return udg_AbilityPointsZulkis
    endif
    return 0
endfunction

private function SUI_GetUnitKills takes unit u returns integer
    local integer id
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    if u == udg_Nazgrek then
        return udg_NazgrekKillCount
    elseif u == udg_Zulkis then
        return udg_ZulkisKillCount
    elseif u == udg_TamedUnit then
        return udg_TamedUnitKillCount
    endif
    set id = GetUnitUserData(u)
    return udg_CompanionUnitKillCount[id]
endfunction

private function SUI_GetUnitDeaths takes unit u returns integer
    local integer id
    if u == null or GetHandleId(u) == 0 then
        return 0
    endif
    if u == udg_Nazgrek then
        return udg_NazgrekDeathCount
    elseif u == udg_Zulkis then
        return udg_ZulkisDeathCount
    endif
    set id = GetUnitUserData(u)
    return udg_CompanionUnitDeathCount[id]
endfunction

private function SUI_GetDetailedStatsText takes unit u returns string
    local integer id
    local integer points
    local real maxLife
    local real maxMana
    local string text

    if u == null or GetHandleId(u) == 0 then
        return "No stats available."
    endif

    set id = GetUnitUserData(u)
    set points = SUI_GetUnitPoints(u)
    set maxLife = GetUnitState(u, UNIT_STATE_MAX_LIFE)
    set maxMana = GetUnitState(u, UNIT_STATE_MAX_MANA)

    set text = "Status: " + SUI_GetStatusText(u) + "|nLevel: |cffffffff" + SUI_GetLevelText(u) + "|r"
    if points > 0 then
        set text = text + "   Points: |cffffffff" + I2S(points) + "|r"
    endif
    set text = text + "|nLife: |cffffffff" + I2S(R2I(GetUnitState(u, UNIT_STATE_LIFE))) + " / " + I2S(R2I(maxLife)) + "|r"
    set text = text + "|nMana: |cffffffff" + I2S(R2I(GetUnitState(u, UNIT_STATE_MANA))) + " / " + I2S(R2I(maxMana)) + "|r"
    set text = text + "|n|nHit: |cffffffff" + I2S(udg_Stats_Hit[id]) + "%|r   Crit: |cffffffff" + I2S(udg_Stats_Crit[id]) + "%|r"
    set text = text + "|nDodge: |cffffffff" + I2S(udg_Stats_Dodge[id]) + "%|r   Block: |cffffffff" + I2S(udg_Stats_Block[id]) + "%|r"
    set text = text + "|nSpell: |cffffffff" + I2S(udg_Stats_SpellPowerPct[id]) + "%|r"
    set text = text + "|n|nKills: |cffffffff" + I2S(SUI_GetUnitKills(u)) + "|r   Deaths: |cffffffff" + I2S(SUI_GetUnitDeaths(u)) + "|r"
    return text
endfunction

private function SUI_GetRowCount takes nothing returns integer
    local integer count = 0
    local integer i = 1

    if udg_Nazgrek != null and GetHandleId(udg_Nazgrek) != 0 then
        set count = count + 1
    endif
    if udg_Zulkis != null and GetHandleId(udg_Zulkis) != 0 then
        set count = count + 1
    endif
    if udg_TamedUnit != null and GetHandleId(udg_TamedUnit) != 0 then
        set count = count + 1
    endif

    loop
        exitwhen i > udg_CompanionCount
        if udg_CompanionUnit[i] != null and GetHandleId(udg_CompanionUnit[i]) != 0 then
            set count = count + 1
        endif
        set i = i + 1
    endloop

    return count
endfunction

private function SUI_GetSelectedUnit takes player whichPlayer returns unit
    local integer rowIndex = SUI_SelectedRow

    if rowIndex >= 1 and rowIndex <= SUI_MAX_ROWS and SUI_RowUnit[rowIndex] != null then
        return SUI_RowUnit[rowIndex]
    endif

    set SUI_SelectedRow = 1
    return SUI_RowUnit[1]
endfunction

private function SUI_UpdateRows takes player whichPlayer returns nothing
    local integer rowIndex = 1
    local integer i = 1
    local integer listStart = SUI_ListScrollValue[GetPlayerId(whichPlayer)]
    local integer skipped = 0
    local integer maxStart = SUI_GetRowCount() - SUI_VISIBLE_ROWS
    local unit u

    if maxStart < 0 then
        set maxStart = 0
    endif
    if listStart < 0 then
        set listStart = 0
        set SUI_ListScrollValue[GetPlayerId(whichPlayer)] = 0
    elseif listStart > maxStart then
        set listStart = maxStart
        set SUI_ListScrollValue[GetPlayerId(whichPlayer)] = maxStart
    endif

    if udg_Nazgrek != null and GetHandleId(udg_Nazgrek) != 0 then
        if skipped < listStart then
            set skipped = skipped + 1
        elseif rowIndex <= SUI_VISIBLE_ROWS then
            set SUI_RowUnit[rowIndex] = udg_Nazgrek
            set SUI_RowKind[rowIndex] = SUI_KIND_HERO
            if GetLocalPlayer() == whichPlayer then
                call BlzFrameSetTexture(SUI_RowIcon[rowIndex], SUI_GetUnitIconPath(udg_Nazgrek), 0, true)
                call BlzFrameSetText(SUI_RowText[rowIndex], SUI_GetKindLabel(SUI_KIND_HERO) + " " + SUI_GetDisplayName(udg_Nazgrek))
                call BlzFrameSetText(SUI_RowLevel[rowIndex], SUI_GetStatusText(udg_Nazgrek))
                call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], rowIndex == SUI_SelectedRow)
                call BlzFrameSetVisible(SUI_RowButton[rowIndex], true)
            endif
            set rowIndex = rowIndex + 1
        endif
    endif

    if udg_Zulkis != null and GetHandleId(udg_Zulkis) != 0 then
        if skipped < listStart then
            set skipped = skipped + 1
        elseif rowIndex <= SUI_VISIBLE_ROWS then
            set SUI_RowUnit[rowIndex] = udg_Zulkis
            set SUI_RowKind[rowIndex] = SUI_KIND_HERO
            if GetLocalPlayer() == whichPlayer then
                call BlzFrameSetTexture(SUI_RowIcon[rowIndex], SUI_GetUnitIconPath(udg_Zulkis), 0, true)
                call BlzFrameSetText(SUI_RowText[rowIndex], SUI_GetKindLabel(SUI_KIND_HERO) + " " + SUI_GetDisplayName(udg_Zulkis))
                call BlzFrameSetText(SUI_RowLevel[rowIndex], SUI_GetStatusText(udg_Zulkis))
                call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], rowIndex == SUI_SelectedRow)
                call BlzFrameSetVisible(SUI_RowButton[rowIndex], true)
            endif
            set rowIndex = rowIndex + 1
        endif
    endif

    if udg_TamedUnit != null and GetHandleId(udg_TamedUnit) != 0 then
        if skipped < listStart then
            set skipped = skipped + 1
        elseif rowIndex <= SUI_VISIBLE_ROWS then
            set SUI_RowUnit[rowIndex] = udg_TamedUnit
            set SUI_RowKind[rowIndex] = SUI_KIND_PET
            if GetLocalPlayer() == whichPlayer then
                call BlzFrameSetTexture(SUI_RowIcon[rowIndex], SUI_GetUnitIconPath(udg_TamedUnit), 0, true)
                call BlzFrameSetText(SUI_RowText[rowIndex], SUI_GetKindLabel(SUI_KIND_PET) + " " + SUI_GetDisplayName(udg_TamedUnit))
                call BlzFrameSetText(SUI_RowLevel[rowIndex], SUI_GetStatusText(udg_TamedUnit))
                call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], rowIndex == SUI_SelectedRow)
                call BlzFrameSetVisible(SUI_RowButton[rowIndex], true)
            endif
            set rowIndex = rowIndex + 1
        endif
    endif

    loop
        exitwhen i > udg_CompanionCount
        set u = udg_CompanionUnit[i]
        if u != null and GetHandleId(u) != 0 then
            if skipped < listStart then
                set skipped = skipped + 1
            elseif rowIndex <= SUI_VISIBLE_ROWS then
                set SUI_RowUnit[rowIndex] = u
                set SUI_RowKind[rowIndex] = SUI_KIND_COMPANION
                if GetLocalPlayer() == whichPlayer then
                    call BlzFrameSetTexture(SUI_RowIcon[rowIndex], SUI_GetUnitIconPath(u), 0, true)
                    call BlzFrameSetText(SUI_RowText[rowIndex], SUI_GetKindLabel(SUI_KIND_COMPANION) + " " + SUI_GetDisplayName(u))
                    call BlzFrameSetText(SUI_RowLevel[rowIndex], SUI_GetStatusText(u))
                    call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], rowIndex == SUI_SelectedRow)
                    call BlzFrameSetVisible(SUI_RowButton[rowIndex], true)
                endif
                set rowIndex = rowIndex + 1
            endif
        endif
        set i = i + 1
    endloop

    loop
        exitwhen rowIndex > SUI_MAX_ROWS
        set SUI_RowUnit[rowIndex] = null
        set SUI_RowKind[rowIndex] = 0
        if GetLocalPlayer() == whichPlayer then
            call BlzFrameSetVisible(SUI_RowButton[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    if GetLocalPlayer() == whichPlayer then
        set SUI_SyncingListScroll = true
        call BlzFrameSetMinMaxValue(SUI_ListScroll, 0.0, I2R(maxStart))
        call BlzFrameSetValue(SUI_ListScroll, I2R(SUI_ListScrollValue[GetPlayerId(whichPlayer)]))
        set SUI_SyncingListScroll = false
        call BlzFrameSetVisible(SUI_ListScroll, maxStart > 0)
    endif

    set u = null
endfunction

private function SUI_UpdateDetail takes player whichPlayer returns nothing
    local unit u = SUI_GetSelectedUnit(whichPlayer)
    local integer kind
    local string headerText

    if u == null then
        if GetLocalPlayer() == whichPlayer then
            call BlzFrameSetTexture(SUI_DetailIcon, SUI_DefaultUnitIcon, 0, true)
            call BlzFrameSetText(SUI_DetailTitle, "No unit")
            call BlzFrameSetText(SUI_DetailValue, "")
            call BlzFrameSetText(SUI_DetailDescription, "No tracked units are currently available.")
        endif
        return
    endif

    set kind = SUI_RowKind[SUI_SelectedRow]
    set headerText = SUI_GetKindLabel(kind) + " " + SUI_GetDisplayName(u)

    if GetLocalPlayer() == whichPlayer then
        call BlzFrameSetTexture(SUI_DetailIcon, SUI_GetUnitIconPath(u), 0, true)
        call BlzFrameSetText(SUI_DetailTitle, headerText)
        call BlzFrameSetText(SUI_DetailValue, "Level " + SUI_GetLevelText(u))
        call BlzFrameSetText(SUI_DetailDescription, SUI_GetDetailedStatsText(u))
    endif

    set u = null
endfunction

private function SUI_Update takes player whichPlayer returns nothing
    if SUI_Parent == null then
        return
    endif

    if SUI_SelectedRow <= 0 and SUI_GetRowCount() > 0 then
        set SUI_SelectedRow = 1
    endif

    call SUI_UpdateRows(whichPlayer)
    call SUI_UpdateDetail(whichPlayer)
endfunction

private function SUI_PeriodicRefresh takes nothing returns nothing
    if SUI_Parent != null and BlzFrameIsVisible(SUI_Parent) then
        call SUI_Update(GetLocalPlayer())
    endif
endfunction

private function SUI_SetRefreshActive takes boolean active returns nothing
    if SUI_RefreshTimer == null then
        return
    endif
    if active then
        call TimerStart(SUI_RefreshTimer, SUI_REFRESH_INTERVAL, true, function SUI_PeriodicRefresh)
    else
        call PauseTimer(SUI_RefreshTimer)
    endif
endfunction

private function SUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

public function Hide takes nothing returns nothing
    call SUI_SetRefreshActive(false)
    if SUI_Parent != null then
        call BlzFrameSetVisible(SUI_Parent, false)
    endif
endfunction

private function SUI_CloseAction takes nothing returns nothing
    call Hide()
endfunction

private function SUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function SUI_RowAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer handleId = GetHandleId(BlzGetTriggerFrame())

    if SUI_ButtonRow.has(handleId) then
        set SUI_SelectedRow = SUI_ButtonRow.integer[handleId]
        call SUI_Update(p)
    endif

    set p = null
endfunction

private function SUI_ListScrollAction takes nothing returns nothing
    local player p = GetTriggerPlayer()
    if SUI_SyncingListScroll then
        set p = null
        return
    endif
    set SUI_ListScrollValue[GetPlayerId(p)] = R2I(BlzGetTriggerFrameValue())
    call SUI_Update(p)
    set p = null
endfunction

private function SUI_WheelAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() and SUI_ListScroll != null and BlzFrameIsVisible(SUI_ListScroll) then
        if BlzGetTriggerFrameValue() > 0 then
            call BlzFrameSetValue(SUI_ListScroll, BlzFrameGetValue(SUI_ListScroll) + 1.0)
        else
            call BlzFrameSetValue(SUI_ListScroll, BlzFrameGetValue(SUI_ListScroll) - 1.0)
        endif
    endif
endfunction

private function SUI_CreateFrames takes nothing returns nothing
    local integer rowIndex = 1
    local real rowTopOffset = -0.012
    local real rowHeight = 0.033
    local real rowGap = 0.003

    set SUI_Parent = BlzCreateFrameByType("BACKDROP", "StatsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetAbsPoint(SUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
    call BlzFrameSetAbsPoint(SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

    set SUI_Title = BlzCreateFrameByType("TEXT", "StatsUITitle", SUI_Parent, "", 0)
    call BlzFrameSetPoint(SUI_Title, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(SUI_Title, 0.30, 0.018)
    call BlzFrameSetTextAlignment(SUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_Title, 1.10)
    call BlzFrameSetEnable(SUI_Title, false)
    call BlzFrameSetText(SUI_Title, "|cffffe4a3Stats|r")

    set SUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsUIClose", SUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(SUI_CloseButton, 0.03, 0.03)
    call BlzFrameSetText(SUI_CloseButton, "X")
    call BlzFrameSetPoint(SUI_CloseButton, FRAMEPOINT_TOPRIGHT, SUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
    call BlzTriggerRegisterFrameEvent(SUI_CloseTrigger, SUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

    set SUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsUIReturn", SUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(SUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(SUI_ReturnButton, "Return")
    call BlzFrameSetPoint(SUI_ReturnButton, FRAMEPOINT_TOPRIGHT, SUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(SUI_ReturnTrigger, SUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    set SUI_LeftPane = BlzCreateFrameByType("BACKDROP", "StatsUILeftPane", SUI_Parent, "", 0)
    call BlzFrameSetTexture(SUI_LeftPane, SUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(SUI_LeftPane, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.058)
    call BlzFrameSetPoint(SUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

    set SUI_ListScroll = BlzCreateFrameByType("SLIDER", "StatsUIListScroll", SUI_LeftPane, "QuestMainListScrollBar", 0)
    call BlzFrameSetPoint(SUI_ListScroll, FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
    call BlzFrameSetPoint(SUI_ListScroll, FRAMEPOINT_BOTTOMLEFT, SUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, 0.004, 0.002)
    call BlzFrameSetMinMaxValue(SUI_ListScroll, 0.0, 0.0)
    call BlzFrameSetStepSize(SUI_ListScroll, 1.0)
    call BlzFrameSetValue(SUI_ListScroll, 0.0)
    call BlzTriggerRegisterFrameEvent(SUI_ListScrollTrigger, SUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
    call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

    set SUI_RightPane = BlzCreateFrameByType("BACKDROP", "StatsUIRightPane", SUI_Parent, "", 0)
    call BlzFrameSetTexture(SUI_RightPane, SUI_PanelTexture, 0, true)
    call BlzFrameSetPoint(SUI_RightPane, FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
    call BlzFrameSetPoint(SUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

    set SUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "StatsUIDetailIcon", SUI_RightPane, "IconButtonTemplate", 0)
    call BlzFrameSetPoint(SUI_DetailIcon, FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
    call BlzFrameSetSize(SUI_DetailIcon, 0.042, 0.042)

    set SUI_DetailTitle = BlzCreateFrameByType("TEXT", "StatsUIDetailTitle", SUI_RightPane, "", 0)
    call BlzFrameSetPoint(SUI_DetailTitle, FRAMEPOINT_TOPLEFT, SUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
    call BlzFrameSetSize(SUI_DetailTitle, 0.26, 0.018)
    call BlzFrameSetTextAlignment(SUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_DetailTitle, 1.05)
    call BlzFrameSetEnable(SUI_DetailTitle, false)

    set SUI_DetailValue = BlzCreateFrameByType("TEXT", "StatsUIDetailValue", SUI_RightPane, "", 0)
    call BlzFrameSetPoint(SUI_DetailValue, FRAMEPOINT_TOPLEFT, SUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.004)
    call BlzFrameSetSize(SUI_DetailValue, 0.26, 0.018)
    call BlzFrameSetTextAlignment(SUI_DetailValue, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_DetailValue, 0.98)
    call BlzFrameSetEnable(SUI_DetailValue, false)

    set SUI_DetailDescription = BlzCreateFrameByType("TEXT", "StatsUIDetailDescription", SUI_RightPane, "", 0)
    call BlzFrameSetPoint(SUI_DetailDescription, FRAMEPOINT_TOPLEFT, SUI_DetailIcon, FRAMEPOINT_BOTTOMLEFT, 0.0, -0.020)
    call BlzFrameSetPoint(SUI_DetailDescription, FRAMEPOINT_BOTTOMRIGHT, SUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.012, 0.018)
    call BlzFrameSetTextAlignment(SUI_DetailDescription, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(SUI_DetailDescription, 0.95)
    call BlzFrameSetEnable(SUI_DetailDescription, false)

    loop
        exitwhen rowIndex > SUI_MAX_ROWS
        set SUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "StatsUIRowButton" + I2S(rowIndex), SUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetPoint(SUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
        call BlzFrameSetSize(SUI_RowButton[rowIndex], 0.156, rowHeight)
        call BlzTriggerRegisterFrameEvent(SUI_RowTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        set SUI_ButtonRow.integer[GetHandleId(SUI_RowButton[rowIndex])] = rowIndex

        set SUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsUIRowIcon" + I2S(rowIndex), SUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(SUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, SUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
        call BlzFrameSetSize(SUI_RowIcon[rowIndex], 0.02, 0.02)

        set SUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "StatsUIRowText" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, SUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
        call BlzFrameSetPoint(SUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.05, 0.004)
        call BlzFrameSetTextAlignment(SUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(SUI_RowText[rowIndex], false)

        set SUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "StatsUIRowLevel" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SUI_RowLevel[rowIndex], FRAMEPOINT_TOPRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.006, -0.004)
        call BlzFrameSetPoint(SUI_RowLevel[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.004)
        call BlzFrameSetTextAlignment(SUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetEnable(SUI_RowLevel[rowIndex], false)

        set SUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "StatsUIRowHighlight" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetAllPoints(SUI_RowHighlight[rowIndex], SUI_RowButton[rowIndex])
        call BlzFrameSetModel(SUI_RowHighlight[rowIndex], SUI_RowHighlightModel, 0)
        call BlzFrameSetScale(SUI_RowHighlight[rowIndex], 0.76)
        call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], false)
        call BlzFrameSetEnable(SUI_RowHighlight[rowIndex], false)

        set rowTopOffset = rowTopOffset - rowHeight - rowGap
        set rowIndex = rowIndex + 1
    endloop

    call BlzFrameSetVisible(SUI_Parent, false)
endfunction

public function Show takes nothing returns nothing
    local player p = GetLocalPlayer()
    if udg_Multiboard != null then
        call MultiboardDisplay(udg_Multiboard, false)
    endif
    call SUI_Update(p)
    call SUI_SetRefreshActive(true)
    call BlzFrameSetVisible(SUI_Parent, true)
    set p = null
endfunction

public function Toggle takes nothing returns nothing
    if SUI_Parent != null and BlzFrameIsVisible(SUI_Parent) then
        call Hide()
    else
        call Show()
    endif
endfunction

public function IsVisible takes nothing returns boolean
    return SUI_Parent != null and BlzFrameIsVisible(SUI_Parent)
endfunction

public function Init takes nothing returns nothing
    if SUI_Initialized then
        return
    endif
    set SUI_Initialized = true

    set SUI_ButtonRow = Table.create()

    set SUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(SUI_CloseTrigger, function SUI_CloseAction)

    set SUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ReturnTrigger, function SUI_ReturnAction)

    set SUI_RowTrigger = CreateTrigger()
    call TriggerAddAction(SUI_RowTrigger, function SUI_RowAction)

    set SUI_ListScrollTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ListScrollTrigger, function SUI_ListScrollAction)

    set SUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(SUI_ClearFocusTrigger, function SUI_ClearFocusAction)

    set SUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(SUI_WheelTrigger, function SUI_WheelAction)

    call SUI_CreateFrames()

    set SUI_RefreshTimer = CreateTimer()
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
