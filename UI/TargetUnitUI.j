/**
    TargetUnitUI

    Author: Valdemar
    Version: 1.2.0

    Description:
    Compact upper-left target and threat frame for active boss encounters,
    selected ordinary enemies, and optional player-party combat discovery. It
    includes local display settings plus minimize and close controls. Rank one
    is always the current aggro holder.

    Credits:
    - Blizzard Entertainment, native frame API
    - StatsLiteUI, header controls and configuration-pane pattern

    How to install:
    Import after Table, ThreatSystem, Boss, Events, and Companions. No FDF or
    TOC import is required. Active bosses registered through Boss are found
    automatically. Selection and deselection use the shared Events dispatcher.

    API:
    - call TargetUnitUI_ShowForUnit(whichUnit) // Shows only active threat
    - call TargetUnitUI_ShowAutomatic()        // Return to automatic display
    - call TargetUnitUI_ShowConfig()
    - call TargetUnitUI_Hide()
    - call TargetUnitUI_Minimize()
    - call TargetUnitUI_Maximize()
    - set minimized = TargetUnitUI_IsMinimized()
    - set whichUnit = TargetUnitUI_GetDisplayedUnit()

**/
library TargetUnitUI initializer Init requires Table, ThreatSystem, Boss, Events, Companions

globals
    // Fullscreen-relative upper-left layout. The left offset clears hero icons.
    private constant real TUI_SCREEN_HEIGHT = 0.600
    private constant real TUI_SCREEN_CENTER_X = 0.400
    private constant real TUI_PANEL_LEFT_OFFSET = 0.052
    private constant real TUI_PANEL_TOP_OFFSET = -0.045
    private constant real TUI_PANEL_WIDTH = 0.275
    private constant real TUI_PANEL_HEIGHT = 0.128
    private constant real TUI_PANEL_CONFIG_HEIGHT = 0.132
    private constant real TUI_PANEL_MINIMIZED_HEIGHT = 0.034
    private constant real TUI_BAR_WIDTH = 0.245
    private constant real TUI_BAR_HEIGHT = 0.009
    private constant real TUI_UPDATE_INTERVAL = 0.25

    private constant integer TUI_ACTION_MINIMIZE = 1
    private constant integer TUI_ACTION_CONFIG = 2
    private constant integer TUI_ACTION_CLOSE = 3
    private constant integer TUI_ACTION_ALWAYS_SHOW = 10
    private constant integer TUI_ACTION_AUTO_HIDE = 11
    private constant integer TUI_ACTION_PLAYER_COMBAT = 12
    private constant integer TUI_ACTION_PARTY_COMBAT = 13
    private constant integer TUI_ACTION_SHOW_MANA = 14
    private constant integer TUI_ACTION_AGGRO_TEXT = 15

    private constant string TUI_EMPTY_BAR_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private constant string TUI_HEALTH_TEXTURE = "ReplaceableTextures\\TeamColor\\TeamColor06.blp"
    private constant string TUI_MANA_TEXTURE = "ReplaceableTextures\\TeamColor\\TeamColor09.blp"
    private constant string TUI_CONFIG_ICON_PATH = "ReplaceableTextures\\CommandButtons\\BTNengineering.blp"

    private framehandle TUI_ScreenParent = null
    private framehandle TUI_ScreenAnchor = null
    private framehandle TUI_Parent = null
    private framehandle TUI_Backdrop = null
    private framehandle TUI_Title = null
    private framehandle TUI_MinimizeButton = null
    private framehandle TUI_ConfigButton = null
    private framehandle TUI_ConfigIcon = null
    private framehandle TUI_CloseButton = null
    private framehandle TUI_ContentPane = null
    private framehandle TUI_HealthBack = null
    private framehandle TUI_HealthFill = null
    private framehandle TUI_HealthText = null
    private framehandle TUI_ManaBack = null
    private framehandle TUI_ManaFill = null
    private framehandle TUI_ManaText = null
    private framehandle TUI_CurrentTargetText = null
    private framehandle TUI_ThreatHeader = null
    private framehandle array TUI_ThreatRow
    private framehandle TUI_ConfigPane = null
    private framehandle TUI_ConfigTitle = null
    private framehandle array TUI_ConfigToggleButton

    private Table TUI_ButtonAction = 0
    private trigger TUI_ButtonTrigger = null
    private trigger TUI_ClearFocusTrigger = null
    private timer TUI_UpdateTimer = null

    private unit TUI_SelectedUnit = null
    private unit TUI_PinnedUnit = null
    private unit TUI_DisplayedUnit = null
    private unit TUI_SuppressedUnit = null
    private unit TUI_AutoBoss = null
    private integer TUI_AutoBossId = 0
    private boolean TUI_Visible = false
    private boolean TUI_Closed = false
    private boolean TUI_Minimized = false
    private boolean TUI_ConfigVisible = false

    // Per-client display defaults. Always-show and auto-hide are exclusive.
    private boolean TUI_AlwaysShow = false
    private boolean TUI_AutoHide = true
    private boolean TUI_OpenPlayerCombat = true
    private boolean TUI_OpenPartyCombat = true
    private boolean TUI_ShowMana = true
endglobals

private function TUI_IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
endfunction

private function TUI_GetDisplayName takes unit whichUnit returns string
    if whichUnit == null then
        return "-"
    endif
    if IsUnitType(whichUnit, UNIT_TYPE_HERO) then
        return GetHeroProperName(whichUnit)
    endif
    return GetUnitName(whichUnit)
endfunction

private function TUI_OnOff takes boolean flag returns string
    if flag then
        return "|cff80ff80On|r"
    endif
    return "|cffff8080Off|r"
endfunction

private function TUI_ClampPercent takes real currentValue, real maximumValue returns integer
    local integer percent

    if maximumValue <= 0.00 then
        return 0
    endif
    set percent = R2I(currentValue * 100.00 / maximumValue + 0.50)
    if percent < 0 then
        return 0
    elseif percent > 100 then
        return 100
    endif
    return percent
endfunction

private function TUI_SetBar takes framehandle fillFrame, framehandle textFrame, integer percent, string label, integer currentValue, integer maximumValue returns nothing
    local real width = TUI_BAR_WIDTH * I2R(percent) * 0.01

    if percent <= 0 then
        call BlzFrameSetVisible(fillFrame, false)
        set width = 0.001
    else
        call BlzFrameSetVisible(fillFrame, true)
        if width < 0.001 then
            set width = 0.001
        elseif width > TUI_BAR_WIDTH then
            set width = TUI_BAR_WIDTH
        endif
    endif

    call BlzFrameSetSize(fillFrame, width, TUI_BAR_HEIGHT)
    call BlzFrameSetText(textFrame, label + " " + I2S(currentValue) + " / " + I2S(maximumValue) + "  (" + I2S(percent) + "%)")
endfunction

private function TUI_ConsiderBoss takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    local integer bossId = Boss_GetId(whichUnit)

    if Boss_IsActive(bossId) and (TUI_AutoBossId == 0 or bossId < TUI_AutoBossId) then
        set TUI_AutoBoss = whichUnit
        set TUI_AutoBossId = bossId
    endif

    set whichUnit = null
endfunction

private function TUI_GetAutomaticBoss takes nothing returns unit
    set TUI_AutoBoss = null
    set TUI_AutoBossId = 0
    if Boss_GetActiveCount() > 0 and udg_BOSS != null then
        call ForGroup(udg_BOSS, function TUI_ConsiderBoss)
    endif
    return TUI_AutoBoss
endfunction

private function TUI_GetSourceCombatTarget takes unit source returns unit
    if TUI_IsAlive(source) then
        return ThreatSystem_GetCombatTarget(source)
    endif
    return null
endfunction

private function TUI_GetAutomaticCombatTarget takes nothing returns unit
    local integer index = 1
    local unit source = null
    local unit target = null

    if TUI_OpenPlayerCombat then
        set target = TUI_GetSourceCombatTarget(udg_Nazgrek)
        if target == null then
            set target = TUI_GetSourceCombatTarget(udg_Zulkis)
        endif
    endif

    if target == null and TUI_OpenPartyCombat then
        set target = TUI_GetSourceCombatTarget(udg_TamedUnit)
        loop
            exitwhen target != null or index > udg_CompanionCount
            set source = udg_CompanionUnit[index]
            set target = TUI_GetSourceCombatTarget(source)
            set index = index + 1
        endloop
        set index = 1
        loop
            exitwhen target != null or index > Companions_GetControlledDisplayCount()
            set source = Companions_GetControlledDisplayUnit(index)
            set target = TUI_GetSourceCombatTarget(source)
            set index = index + 1
        endloop
    endif

    set source = null
    return target
endfunction

private function TUI_ResolveDisplayUnit takes nothing returns unit
    local unit automaticUnit = null

    if TUI_IsAlive(TUI_PinnedUnit) and (ThreatSystem_HasThreat(TUI_PinnedUnit) or TUI_AlwaysShow or not TUI_AutoHide) then
        return TUI_PinnedUnit
    endif
    set TUI_PinnedUnit = null

    if (TUI_AlwaysShow or not TUI_AutoHide) and TUI_IsAlive(TUI_SelectedUnit) then
        return TUI_SelectedUnit
    endif

    set automaticUnit = TUI_GetAutomaticCombatTarget()
    if TUI_IsAlive(automaticUnit) then
        return automaticUnit
    endif

    set automaticUnit = TUI_GetAutomaticBoss()
    if TUI_IsAlive(automaticUnit) then
        return automaticUnit
    endif

    if not TUI_AutoHide and TUI_IsAlive(TUI_DisplayedUnit) then
        return TUI_DisplayedUnit
    endif

    set automaticUnit = null
    return null
endfunction

private function TUI_SetVisible takes boolean visible returns nothing
    if TUI_Parent != null and TUI_Visible != visible then
        set TUI_Visible = visible
        call BlzFrameSetVisible(TUI_Parent, visible)
    endif
endfunction

private function TUI_UpdateScreenAnchor takes nothing returns nothing
    local integer clientWidth
    local integer clientHeight
    local real screenWidth = 0.800

    if TUI_ScreenAnchor == null then
        return
    endif

    set clientWidth = BlzGetLocalClientWidth()
    set clientHeight = BlzGetLocalClientHeight()
    if clientHeight > 0 then
        set screenWidth = I2R(clientWidth) / I2R(clientHeight) * TUI_SCREEN_HEIGHT
    endif
    if screenWidth < 0.800 then
        set screenWidth = 0.800
    endif

    call BlzFrameClearAllPoints(TUI_ScreenAnchor)
    call BlzFrameSetSize(TUI_ScreenAnchor, screenWidth, TUI_SCREEN_HEIGHT)
    call BlzFrameSetAbsPoint(TUI_ScreenAnchor, FRAMEPOINT_BOTTOM, TUI_SCREEN_CENTER_X, 0.0)
endfunction

private function TUI_GetPanelHeight takes nothing returns real
    if TUI_Minimized then
        return TUI_PANEL_MINIMIZED_HEIGHT
    elseif TUI_ConfigVisible then
        return TUI_PANEL_CONFIG_HEIGHT
    endif
    return TUI_PANEL_HEIGHT
endfunction

private function TUI_ApplyLayout takes nothing returns nothing
    if TUI_Parent == null then
        return
    endif

    call TUI_UpdateScreenAnchor()
    call BlzFrameClearAllPoints(TUI_Parent)
    call BlzFrameSetSize(TUI_Parent, TUI_PANEL_WIDTH, TUI_GetPanelHeight())
    call BlzFrameSetPoint(TUI_Parent, FRAMEPOINT_TOPLEFT, TUI_ScreenAnchor, FRAMEPOINT_TOPLEFT, TUI_PANEL_LEFT_OFFSET, TUI_PANEL_TOP_OFFSET)

    if TUI_MinimizeButton != null then
        if TUI_Minimized then
            call BlzFrameSetText(TUI_MinimizeButton, "+")
        else
            call BlzFrameSetText(TUI_MinimizeButton, "-")
        endif
    endif
    if TUI_ContentPane != null then
        call BlzFrameSetVisible(TUI_ContentPane, not TUI_Minimized and not TUI_ConfigVisible)
    endif
    if TUI_ConfigPane != null then
        call BlzFrameSetVisible(TUI_ConfigPane, not TUI_Minimized and TUI_ConfigVisible)
    endif
    if TUI_ManaBack != null then
        call BlzFrameSetVisible(TUI_ManaBack, TUI_ShowMana)
    endif
endfunction

private function TUI_UpdateConfig takes nothing returns nothing
    call BlzFrameSetText(TUI_ConfigToggleButton[1], "Always: " + TUI_OnOff(TUI_AlwaysShow))
    call BlzFrameSetText(TUI_ConfigToggleButton[2], "Auto-hide: " + TUI_OnOff(TUI_AutoHide))
    call BlzFrameSetText(TUI_ConfigToggleButton[3], "Player combat: " + TUI_OnOff(TUI_OpenPlayerCombat))
    call BlzFrameSetText(TUI_ConfigToggleButton[4], "Comp/Pet: " + TUI_OnOff(TUI_OpenPartyCombat))
    call BlzFrameSetText(TUI_ConfigToggleButton[5], "Mana: " + TUI_OnOff(TUI_ShowMana))
    call BlzFrameSetText(TUI_ConfigToggleButton[6], "Aggro text: " + TUI_OnOff(ThreatSystem_IsAggroTextVisible()))
endfunction

private function TUI_FormatThreatRow takes unit threatUnit, unit source, integer rank, real topThreat returns string
    local real threat = ThreatSystem_GetThreat(threatUnit, source)
    local integer percent = 0
    local string prefix = "|cffffffff"
    local string suffix = "|r"

    if source == null then
        return prefix + I2S(rank) + ". -" + suffix
    endif
    if topThreat > 0.00 then
        set percent = R2I(threat * 100.00 / topThreat + 0.50)
    endif
    if rank == 1 then
        set prefix = "|cffff8040"
        set suffix = "  AGGRO|r"
    elseif rank == 2 then
        set prefix = "|cffffcc00"
    endif
    return prefix + I2S(rank) + ". " + TUI_GetDisplayName(source) + "  " + I2S(R2I(threat + 0.50)) + "  (" + I2S(percent) + "%)" + suffix
endfunction

private function TUI_ShowEmptyContent takes nothing returns nothing
    local integer row = 1

    call BlzFrameSetText(TUI_Title, "|cffffcc00Target / Threat|r")
    call TUI_SetBar(TUI_HealthFill, TUI_HealthText, 0, "HP", 0, 0)
    call TUI_SetBar(TUI_ManaFill, TUI_ManaText, 0, "Mana", 0, 0)
    call BlzFrameSetText(TUI_CurrentTargetText, "Aggro: |cffbfbfbfNone|r")
    loop
        exitwhen row > 3
        call BlzFrameSetText(TUI_ThreatRow[row], "|cffffffff" + I2S(row) + ". -|r")
        set row = row + 1
    endloop
endfunction

private function TUI_Update takes nothing returns nothing
    local unit threatUnit = null
    local unit aggroTarget = null
    local unit rankedUnit = null
    local real currentLife
    local real maximumLife
    local real currentMana
    local real maximumMana
    local real topThreat
    local integer row = 1

    call TUI_ApplyLayout()
    if TUI_ConfigVisible then
        call BlzFrameSetText(TUI_Title, "|cffffcc00Threat Settings|r")
        call TUI_UpdateConfig()
        call TUI_SetVisible(true)
        return
    endif

    set threatUnit = TUI_ResolveDisplayUnit()
    if TUI_Closed then
        if threatUnit == null then
            set TUI_SuppressedUnit = null
        elseif threatUnit != TUI_SuppressedUnit then
            set TUI_Closed = false
        endif
        if TUI_Closed then
            set TUI_DisplayedUnit = null
            call TUI_SetVisible(false)
            set threatUnit = null
            return
        endif
    endif

    if not TUI_IsAlive(threatUnit) then
        set TUI_DisplayedUnit = null
        if TUI_AlwaysShow then
            call TUI_ShowEmptyContent()
            call TUI_SetVisible(true)
        else
            call TUI_SetVisible(false)
        endif
        set threatUnit = null
        return
    endif

    set TUI_DisplayedUnit = threatUnit
    set currentLife = GetWidgetLife(threatUnit)
    set maximumLife = GetUnitState(threatUnit, UNIT_STATE_MAX_LIFE)
    set currentMana = GetUnitState(threatUnit, UNIT_STATE_MANA)
    set maximumMana = GetUnitState(threatUnit, UNIT_STATE_MAX_MANA)
    set aggroTarget = ThreatSystem_GetAggroTarget(threatUnit)
    set topThreat = ThreatSystem_GetRankedThreat(threatUnit, 1)

    call BlzFrameSetText(TUI_Title, "|cffffcc00" + TUI_GetDisplayName(threatUnit) + "|r")
    call TUI_SetBar(TUI_HealthFill, TUI_HealthText, TUI_ClampPercent(currentLife, maximumLife), "HP", R2I(currentLife + 0.50), R2I(maximumLife + 0.50))
    call TUI_SetBar(TUI_ManaFill, TUI_ManaText, TUI_ClampPercent(currentMana, maximumMana), "Mana", R2I(currentMana + 0.50), R2I(maximumMana + 0.50))
    if aggroTarget == null then
        call BlzFrameSetText(TUI_CurrentTargetText, "Aggro: |cffbfbfbfNone|r")
    else
        call BlzFrameSetText(TUI_CurrentTargetText, "Aggro: |cffff8040" + TUI_GetDisplayName(aggroTarget) + "|r")
    endif

    loop
        exitwhen row > 3
        set rankedUnit = ThreatSystem_GetRankedUnit(threatUnit, row)
        call BlzFrameSetText(TUI_ThreatRow[row], TUI_FormatThreatRow(threatUnit, rankedUnit, row, topThreat))
        set row = row + 1
    endloop

    call TUI_SetVisible(true)
    set threatUnit = null
    set aggroTarget = null
    set rankedUnit = null
endfunction

public function Hide takes nothing returns nothing
    set TUI_Closed = true
    set TUI_ConfigVisible = false
    set TUI_SuppressedUnit = TUI_DisplayedUnit
    call TUI_SetVisible(false)
endfunction

public function Maximize takes nothing returns nothing
    set TUI_Minimized = false
    call TUI_Update()
endfunction

public function Minimize takes nothing returns nothing
    set TUI_Minimized = true
    call TUI_Update()
endfunction

public function IsMinimized takes nothing returns boolean
    return TUI_Minimized
endfunction

public function ShowConfig takes nothing returns nothing
    set TUI_Closed = false
    set TUI_Minimized = false
    set TUI_ConfigVisible = true
    call TUI_Update()
endfunction

public function ShowForUnit takes unit whichUnit returns nothing
    set TUI_ConfigVisible = false
    if ThreatSystem_HasThreat(whichUnit) then
        set TUI_PinnedUnit = whichUnit
        set TUI_Closed = false
    else
        set TUI_PinnedUnit = null
    endif
    call TUI_Update()
endfunction

public function ShowAutomatic takes nothing returns nothing
    set TUI_PinnedUnit = null
    set TUI_ConfigVisible = false
    set TUI_Closed = false
    call TUI_Update()
endfunction

public function GetDisplayedUnit takes nothing returns unit
    return TUI_DisplayedUnit
endfunction

private function TUI_ToggleMinimized takes nothing returns nothing
    if TUI_Minimized then
        call Maximize()
    else
        call Minimize()
    endif
endfunction

private function TUI_ToggleConfig takes nothing returns nothing
    if TUI_ConfigVisible then
        set TUI_ConfigVisible = false
        call TUI_Update()
    else
        call ShowConfig()
    endif
endfunction

private function TUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function TUI_ButtonClickAction takes nothing returns nothing
    local integer handleId = GetHandleId(BlzGetTriggerFrame())
    local integer actionId = 0
    local player triggerPlayer = GetTriggerPlayer()

    if triggerPlayer == GetLocalPlayer() and TUI_ButtonAction.has(handleId) then
        set actionId = TUI_ButtonAction.integer[handleId]
        if actionId == TUI_ACTION_MINIMIZE then
            call TUI_ToggleMinimized()
        elseif actionId == TUI_ACTION_CONFIG then
            call TUI_ToggleConfig()
        elseif actionId == TUI_ACTION_CLOSE then
            call Hide()
        elseif actionId == TUI_ACTION_ALWAYS_SHOW then
            set TUI_AlwaysShow = not TUI_AlwaysShow
            if TUI_AlwaysShow then
                set TUI_AutoHide = false
            endif
            call TUI_Update()
        elseif actionId == TUI_ACTION_AUTO_HIDE then
            set TUI_AutoHide = not TUI_AutoHide
            if TUI_AutoHide then
                set TUI_AlwaysShow = false
            endif
            call TUI_Update()
        elseif actionId == TUI_ACTION_PLAYER_COMBAT then
            set TUI_OpenPlayerCombat = not TUI_OpenPlayerCombat
            call TUI_Update()
        elseif actionId == TUI_ACTION_PARTY_COMBAT then
            set TUI_OpenPartyCombat = not TUI_OpenPartyCombat
            call TUI_Update()
        elseif actionId == TUI_ACTION_SHOW_MANA then
            set TUI_ShowMana = not TUI_ShowMana
            call TUI_Update()
        elseif actionId == TUI_ACTION_AGGRO_TEXT then
            call ThreatSystem_SetAggroTextVisible(not ThreatSystem_IsAggroTextVisible())
            call TUI_Update()
        endif
    endif

    set triggerPlayer = null
endfunction

private function TUI_RegisterButton takes framehandle whichFrame, integer actionId returns nothing
    call BlzTriggerRegisterFrameEvent(TUI_ButtonTrigger, whichFrame, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(TUI_ClearFocusTrigger, whichFrame, FRAMEEVENT_CONTROL_CLICK)
    set TUI_ButtonAction.integer[GetHandleId(whichFrame)] = actionId
    set whichFrame = null
endfunction

private function TUI_CreateHeaderButton takes string name, string label, framehandle anchor returns framehandle
    local framehandle buttonFrame = BlzCreateFrameByType("GLUETEXTBUTTON", name, TUI_Parent, "ScriptDialogButton", 0)

    call BlzFrameSetSize(buttonFrame, 0.020, 0.020)
    call BlzFrameSetText(buttonFrame, label)
    call BlzFrameSetPoint(buttonFrame, FRAMEPOINT_TOPRIGHT, anchor, FRAMEPOINT_TOPLEFT, -0.003, 0.0)
    call BlzFrameSetLevel(buttonFrame, 8)
    set anchor = null
    return buttonFrame
endfunction

private function TUI_CreateConfigButton takes integer index, string label, integer actionId, real x, real y returns nothing
    set TUI_ConfigToggleButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "TargetUnitUIConfigToggle" + I2S(index), TUI_ConfigPane, "ScriptDialogButton", 0)
    call BlzFrameSetSize(TUI_ConfigToggleButton[index], 0.112, 0.020)
    call BlzFrameSetPoint(TUI_ConfigToggleButton[index], FRAMEPOINT_TOPLEFT, TUI_ConfigPane, FRAMEPOINT_TOPLEFT, x, y)
    call BlzFrameSetText(TUI_ConfigToggleButton[index], label)
    call BlzFrameSetLevel(TUI_ConfigToggleButton[index], 9)
    call TUI_RegisterButton(TUI_ConfigToggleButton[index], actionId)
endfunction

private function TUI_OnUnitSelected takes nothing returns nothing
    local unit selectedUnit = GetTriggerUnit()
    local player selectingPlayer = GetTriggerPlayer()

    if selectingPlayer == GetLocalPlayer() then
        set TUI_SelectedUnit = selectedUnit
        if ThreatSystem_HasThreat(selectedUnit) or TUI_AlwaysShow or not TUI_AutoHide then
            set TUI_PinnedUnit = selectedUnit
            set TUI_ConfigVisible = false
            set TUI_Closed = false
        else
            set TUI_PinnedUnit = null
        endif
        call TUI_Update()
    endif

    set selectedUnit = null
    set selectingPlayer = null
endfunction

private function TUI_OnUnitDeselected takes nothing returns nothing
    local unit deselectedUnit = GetTriggerUnit()
    local player deselectingPlayer = GetTriggerPlayer()

    if deselectingPlayer == GetLocalPlayer() then
        if TUI_SelectedUnit == deselectedUnit then
            set TUI_SelectedUnit = null
        endif
        if TUI_PinnedUnit == deselectedUnit and TUI_AutoHide and not TUI_AlwaysShow then
            set TUI_PinnedUnit = null
        endif
        call TUI_Update()
    endif

    set deselectedUnit = null
    set deselectingPlayer = null
endfunction

private function TUI_CreateBar takes framehandle backFrame, framehandle fillFrame, framehandle textFrame, real y, string fillTexture returns nothing
    call BlzFrameSetTexture(backFrame, TUI_EMPTY_BAR_TEXTURE, 0, false)
    call BlzFrameSetPoint(backFrame, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, y)
    call BlzFrameSetSize(backFrame, TUI_BAR_WIDTH, TUI_BAR_HEIGHT)
    call BlzFrameSetVertexColor(backFrame, BlzConvertColor(190, 40, 40, 40))
    call BlzFrameSetEnable(backFrame, false)
    call BlzFrameSetLevel(backFrame, 5)

    call BlzFrameSetTexture(fillFrame, fillTexture, 0, false)
    call BlzFrameSetPoint(fillFrame, FRAMEPOINT_LEFT, backFrame, FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(fillFrame, 0.001, TUI_BAR_HEIGHT)
    call BlzFrameSetEnable(fillFrame, false)
    call BlzFrameSetLevel(fillFrame, 6)

    call BlzFrameSetAllPoints(textFrame, backFrame)
    call BlzFrameSetTextAlignment(textFrame, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(textFrame, 0.54)
    call BlzFrameSetEnable(textFrame, false)
    call BlzFrameSetLevel(textFrame, 7)
endfunction

private function TUI_CreateFrames takes nothing returns nothing
    local integer row = 1
    local real y

    set TUI_ScreenParent = BlzGetFrameByName("ConsoleUIBackdrop", 0)
    if TUI_ScreenParent == null then
        set TUI_ScreenParent = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    endif
    set TUI_ScreenAnchor = BlzCreateFrameByType("FRAME", "TargetUnitUIScreenAnchor", TUI_ScreenParent, "", 0)
    call TUI_UpdateScreenAnchor()
    call BlzFrameSetEnable(TUI_ScreenAnchor, false)
    call BlzFrameSetVisible(TUI_ScreenAnchor, false)

    set TUI_Parent = BlzCreateFrameByType("FRAME", "TargetUnitUIPanel", TUI_ScreenParent, "", 0)
    call BlzFrameSetLevel(TUI_Parent, 4)
    call TUI_ApplyLayout()

    set TUI_Backdrop = BlzCreateFrameByType("BACKDROP", "TargetUnitUIBackdrop", TUI_Parent, "", 0)
    call BlzFrameSetTexture(TUI_Backdrop, TUI_EMPTY_BAR_TEXTURE, 0, false)
    call BlzFrameSetAllPoints(TUI_Backdrop, TUI_Parent)
    call BlzFrameSetVertexColor(TUI_Backdrop, BlzConvertColor(210, 25, 25, 25))
    call BlzFrameSetEnable(TUI_Backdrop, false)
    call BlzFrameSetLevel(TUI_Backdrop, 4)

    set TUI_Title = BlzCreateFrameByType("TEXT", "TargetUnitUITitle", TUI_Parent, "", 0)
    call BlzFrameSetPoint(TUI_Title, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.012, -0.009)
    call BlzFrameSetSize(TUI_Title, 0.175, 0.014)
    call BlzFrameSetTextAlignment(TUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(TUI_Title, 0.72)
    call BlzFrameSetEnable(TUI_Title, false)
    call BlzFrameSetLevel(TUI_Title, 8)

    set TUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "TargetUnitUIClose", TUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(TUI_CloseButton, 0.020, 0.020)
    call BlzFrameSetText(TUI_CloseButton, "X")
    call BlzFrameSetPoint(TUI_CloseButton, FRAMEPOINT_TOPRIGHT, TUI_Parent, FRAMEPOINT_TOPRIGHT, -0.006, -0.006)
    call BlzFrameSetLevel(TUI_CloseButton, 8)
    call TUI_RegisterButton(TUI_CloseButton, TUI_ACTION_CLOSE)

    set TUI_MinimizeButton = TUI_CreateHeaderButton("TargetUnitUIMinimize", "-", TUI_CloseButton)
    call TUI_RegisterButton(TUI_MinimizeButton, TUI_ACTION_MINIMIZE)

    set TUI_ConfigButton = TUI_CreateHeaderButton("TargetUnitUIConfig", "", TUI_MinimizeButton)
    set TUI_ConfigIcon = BlzCreateFrameByType("BACKDROP", "TargetUnitUIConfigIcon", TUI_ConfigButton, "", 0)
    call BlzFrameSetTexture(TUI_ConfigIcon, TUI_CONFIG_ICON_PATH, 0, true)
    call BlzFrameSetPoint(TUI_ConfigIcon, FRAMEPOINT_CENTER, TUI_ConfigButton, FRAMEPOINT_CENTER, 0.0, 0.0)
    call BlzFrameSetSize(TUI_ConfigIcon, 0.013, 0.013)
    call BlzFrameSetEnable(TUI_ConfigIcon, false)
    call BlzFrameSetLevel(TUI_ConfigIcon, 9)
    call TUI_RegisterButton(TUI_ConfigButton, TUI_ACTION_CONFIG)

    set TUI_ContentPane = BlzCreateFrameByType("FRAME", "TargetUnitUIContent", TUI_Parent, "", 0)
    call BlzFrameSetAllPoints(TUI_ContentPane, TUI_Parent)
    call BlzFrameSetEnable(TUI_ContentPane, false)
    call BlzFrameSetLevel(TUI_ContentPane, 5)

    set TUI_HealthBack = BlzCreateFrameByType("BACKDROP", "TargetUnitUIHealthBack", TUI_ContentPane, "", 0)
    set TUI_HealthFill = BlzCreateFrameByType("BACKDROP", "TargetUnitUIHealthFill", TUI_HealthBack, "", 0)
    set TUI_HealthText = BlzCreateFrameByType("TEXT", "TargetUnitUIHealthText", TUI_HealthBack, "", 0)
    call TUI_CreateBar(TUI_HealthBack, TUI_HealthFill, TUI_HealthText, -0.035, TUI_HEALTH_TEXTURE)

    set TUI_ManaBack = BlzCreateFrameByType("BACKDROP", "TargetUnitUIManaBack", TUI_ContentPane, "", 0)
    set TUI_ManaFill = BlzCreateFrameByType("BACKDROP", "TargetUnitUIManaFill", TUI_ManaBack, "", 0)
    set TUI_ManaText = BlzCreateFrameByType("TEXT", "TargetUnitUIManaText", TUI_ManaBack, "", 0)
    call TUI_CreateBar(TUI_ManaBack, TUI_ManaFill, TUI_ManaText, -0.046, TUI_MANA_TEXTURE)

    set TUI_CurrentTargetText = BlzCreateFrameByType("TEXT", "TargetUnitUICurrentTarget", TUI_ContentPane, "", 0)
    call BlzFrameSetPoint(TUI_CurrentTargetText, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, -0.059)
    call BlzFrameSetSize(TUI_CurrentTargetText, TUI_BAR_WIDTH, 0.011)
    call BlzFrameSetTextAlignment(TUI_CurrentTargetText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(TUI_CurrentTargetText, 0.58)
    call BlzFrameSetEnable(TUI_CurrentTargetText, false)
    call BlzFrameSetLevel(TUI_CurrentTargetText, 7)

    set TUI_ThreatHeader = BlzCreateFrameByType("TEXT", "TargetUnitUIThreatHeader", TUI_ContentPane, "", 0)
    call BlzFrameSetPoint(TUI_ThreatHeader, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, -0.072)
    call BlzFrameSetSize(TUI_ThreatHeader, TUI_BAR_WIDTH, 0.010)
    call BlzFrameSetText(TUI_ThreatHeader, "|cffbfbfbfThreat|r")
    call BlzFrameSetTextAlignment(TUI_ThreatHeader, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(TUI_ThreatHeader, 0.56)
    call BlzFrameSetEnable(TUI_ThreatHeader, false)
    call BlzFrameSetLevel(TUI_ThreatHeader, 7)

    loop
        exitwhen row > 3
        set y = -0.083 - I2R(row - 1) * 0.011
        set TUI_ThreatRow[row] = BlzCreateFrameByType("TEXT", "TargetUnitUIThreatRow" + I2S(row), TUI_ContentPane, "", 0)
        call BlzFrameSetPoint(TUI_ThreatRow[row], FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, y)
        call BlzFrameSetSize(TUI_ThreatRow[row], TUI_BAR_WIDTH, 0.010)
        call BlzFrameSetTextAlignment(TUI_ThreatRow[row], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_ThreatRow[row], 0.55)
        call BlzFrameSetEnable(TUI_ThreatRow[row], false)
        call BlzFrameSetLevel(TUI_ThreatRow[row], 7)
        set row = row + 1
    endloop

    set TUI_ConfigPane = BlzCreateFrameByType("BACKDROP", "TargetUnitUIConfigPane", TUI_Parent, "", 0)
    call BlzFrameSetTexture(TUI_ConfigPane, TUI_EMPTY_BAR_TEXTURE, 0, false)
    call BlzFrameSetPoint(TUI_ConfigPane, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.010, -0.032)
    call BlzFrameSetPoint(TUI_ConfigPane, FRAMEPOINT_BOTTOMRIGHT, TUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.008)
    call BlzFrameSetVertexColor(TUI_ConfigPane, BlzConvertColor(220, 6, 6, 6))
    call BlzFrameSetLevel(TUI_ConfigPane, 6)

    set TUI_ConfigTitle = BlzCreateFrameByType("TEXT", "TargetUnitUIConfigTitle", TUI_ConfigPane, "", 0)
    call BlzFrameSetPoint(TUI_ConfigTitle, FRAMEPOINT_TOPLEFT, TUI_ConfigPane, FRAMEPOINT_TOPLEFT, 0.010, -0.006)
    call BlzFrameSetSize(TUI_ConfigTitle, 0.220, 0.012)
    call BlzFrameSetText(TUI_ConfigTitle, "|cffbfbfbfDisplay and threat alerts|r")
    call BlzFrameSetTextAlignment(TUI_ConfigTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(TUI_ConfigTitle, 0.58)
    call BlzFrameSetEnable(TUI_ConfigTitle, false)
    call BlzFrameSetLevel(TUI_ConfigTitle, 8)

    call TUI_CreateConfigButton(1, "Always", TUI_ACTION_ALWAYS_SHOW, 0.010, -0.022)
    call TUI_CreateConfigButton(2, "Auto-hide", TUI_ACTION_AUTO_HIDE, 0.130, -0.022)
    call TUI_CreateConfigButton(3, "Player combat", TUI_ACTION_PLAYER_COMBAT, 0.010, -0.047)
    call TUI_CreateConfigButton(4, "Comp/Pet", TUI_ACTION_PARTY_COMBAT, 0.130, -0.047)
    call TUI_CreateConfigButton(5, "Mana", TUI_ACTION_SHOW_MANA, 0.010, -0.072)
    call TUI_CreateConfigButton(6, "Aggro text", TUI_ACTION_AGGRO_TEXT, 0.130, -0.072)

    call BlzFrameSetVisible(TUI_ConfigPane, false)
    call BlzFrameSetVisible(TUI_Parent, false)
endfunction

private function Init takes nothing returns nothing
    set TUI_ButtonAction = Table.create()
    set TUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(TUI_ButtonTrigger, function TUI_ButtonClickAction)
    set TUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(TUI_ClearFocusTrigger, function TUI_ClearFocusAction)

    call TUI_CreateFrames()
    set TUI_UpdateTimer = CreateTimer()
    call TimerStart(TUI_UpdateTimer, TUI_UPDATE_INTERVAL, true, function TUI_Update)
    call Events_RegisterPlayerUnitEvent(function TUI_OnUnitSelected, EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function TUI_OnUnitDeselected, EVENT_PLAYER_UNIT_DESELECTED)
endfunction

endlibrary
