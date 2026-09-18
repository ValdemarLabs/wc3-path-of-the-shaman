/**
    TargetUnitUI

    Author: Valdemar
    Version: 1.0.0

    Description:
    Compact top-center target frame for active boss encounters. It shows the
    boss name, health, mana, current aggro target, and the top three threat
    units. Rank one is always the unit that currently has aggro.

    Credits:
    - Blizzard Entertainment, native frame API

    How to install:
    Import after ThreatSystem and Boss. No FDF or TOC import is required.
    Active bosses registered through Boss are discovered automatically.

    API:
    - call TargetUnitUI_ShowForUnit(whichUnit) // Pin a non-boss or boss target
    - call TargetUnitUI_ShowAutomatic()        // Return to active-boss display
    - set whichUnit = TargetUnitUI_GetDisplayedUnit()

**/
library TargetUnitUI initializer Init requires ThreatSystem, Boss

globals
    // Top-center layout, below the native upper game UI border.
    private constant real TUI_PANEL_CENTER_X = 0.400
    private constant real TUI_PANEL_TOP = 0.570
    private constant real TUI_PANEL_WIDTH = 0.340
    private constant real TUI_PANEL_HEIGHT = 0.145
    private constant real TUI_BAR_WIDTH = 0.310
    private constant real TUI_BAR_HEIGHT = 0.011
    private constant real TUI_UPDATE_INTERVAL = 0.10

    private constant string TUI_EMPTY_BAR_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private constant string TUI_HEALTH_TEXTURE = "ReplaceableTextures\\TeamColor\\TeamColor06.blp"
    private constant string TUI_MANA_TEXTURE = "ReplaceableTextures\\TeamColor\\TeamColor09.blp"

    private framehandle TUI_Parent = null
    private framehandle TUI_Title = null
    private framehandle TUI_HealthBack = null
    private framehandle TUI_HealthFill = null
    private framehandle TUI_HealthText = null
    private framehandle TUI_ManaBack = null
    private framehandle TUI_ManaFill = null
    private framehandle TUI_ManaText = null
    private framehandle TUI_CurrentTargetText = null
    private framehandle TUI_ThreatHeader = null
    private framehandle array TUI_ThreatRow

    private unit TUI_PinnedUnit = null
    private unit TUI_DisplayedUnit = null
    private unit TUI_AutoBoss = null
    private integer TUI_AutoBossId = 0
    private timer TUI_UpdateTimer = null
    private boolean TUI_Visible = false
endglobals

private function TUI_IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
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
    if udg_BOSS != null then
        call ForGroup(udg_BOSS, function TUI_ConsiderBoss)
    endif
    return TUI_AutoBoss
endfunction

private function TUI_ResolveDisplayUnit takes nothing returns unit
    if TUI_IsAlive(TUI_PinnedUnit) then
        return TUI_PinnedUnit
    endif
    set TUI_PinnedUnit = null
    return TUI_GetAutomaticBoss()
endfunction

private function TUI_SetVisible takes boolean visible returns nothing
    if TUI_Parent != null and TUI_Visible != visible then
        set TUI_Visible = visible
        call BlzFrameSetVisible(TUI_Parent, visible)
    endif
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
    return prefix + I2S(rank) + ". " + GetUnitName(source) + "  " + I2S(R2I(threat + 0.50)) + "  (" + I2S(percent) + "%)" + suffix
endfunction

private function TUI_Update takes nothing returns nothing
    local unit threatUnit = TUI_ResolveDisplayUnit()
    local unit aggroTarget = null
    local unit rankedUnit = null
    local real currentLife
    local real maximumLife
    local real currentMana
    local real maximumMana
    local real topThreat
    local integer row = 1

    if not TUI_IsAlive(threatUnit) then
        set TUI_DisplayedUnit = null
        call TUI_SetVisible(false)
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

    call BlzFrameSetText(TUI_Title, "|cffffcc00" + GetUnitName(threatUnit) + "|r")
    call TUI_SetBar(TUI_HealthFill, TUI_HealthText, TUI_ClampPercent(currentLife, maximumLife), "HP", R2I(currentLife + 0.50), R2I(maximumLife + 0.50))
    call TUI_SetBar(TUI_ManaFill, TUI_ManaText, TUI_ClampPercent(currentMana, maximumMana), "Mana", R2I(currentMana + 0.50), R2I(maximumMana + 0.50))
    if aggroTarget == null then
        call BlzFrameSetText(TUI_CurrentTargetText, "Target: |cffbfbfbfNone|r")
    else
        call BlzFrameSetText(TUI_CurrentTargetText, "Target: |cffff8040" + GetUnitName(aggroTarget) + "|r")
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

public function ShowForUnit takes unit whichUnit returns nothing
    set TUI_PinnedUnit = whichUnit
    call TUI_Update()
endfunction

public function ShowAutomatic takes nothing returns nothing
    set TUI_PinnedUnit = null
    call TUI_Update()
endfunction

public function GetDisplayedUnit takes nothing returns unit
    return TUI_DisplayedUnit
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
    call BlzFrameSetScale(textFrame, 0.64)
    call BlzFrameSetEnable(textFrame, false)
    call BlzFrameSetLevel(textFrame, 7)
endfunction

private function TUI_CreateFrames takes nothing returns nothing
    local integer row = 1
    local real y

    set TUI_Parent = BlzCreateFrameByType("BACKDROP", "TargetUnitUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
    call BlzFrameSetSize(TUI_Parent, TUI_PANEL_WIDTH, TUI_PANEL_HEIGHT)
    call BlzFrameSetAbsPoint(TUI_Parent, FRAMEPOINT_TOP, TUI_PANEL_CENTER_X, TUI_PANEL_TOP)
    call BlzFrameSetLevel(TUI_Parent, 4)

    set TUI_Title = BlzCreateFrameByType("TEXT", "TargetUnitUITitle", TUI_Parent, "", 0)
    call BlzFrameSetPoint(TUI_Title, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, -0.012)
    call BlzFrameSetSize(TUI_Title, TUI_BAR_WIDTH, 0.016)
    call BlzFrameSetTextAlignment(TUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(TUI_Title, 0.90)
    call BlzFrameSetEnable(TUI_Title, false)
    call BlzFrameSetLevel(TUI_Title, 7)

    set TUI_HealthBack = BlzCreateFrameByType("BACKDROP", "TargetUnitUIHealthBack", TUI_Parent, "", 0)
    set TUI_HealthFill = BlzCreateFrameByType("BACKDROP", "TargetUnitUIHealthFill", TUI_HealthBack, "", 0)
    set TUI_HealthText = BlzCreateFrameByType("TEXT", "TargetUnitUIHealthText", TUI_HealthBack, "", 0)
    call TUI_CreateBar(TUI_HealthBack, TUI_HealthFill, TUI_HealthText, -0.032, TUI_HEALTH_TEXTURE)

    set TUI_ManaBack = BlzCreateFrameByType("BACKDROP", "TargetUnitUIManaBack", TUI_Parent, "", 0)
    set TUI_ManaFill = BlzCreateFrameByType("BACKDROP", "TargetUnitUIManaFill", TUI_ManaBack, "", 0)
    set TUI_ManaText = BlzCreateFrameByType("TEXT", "TargetUnitUIManaText", TUI_ManaBack, "", 0)
    call TUI_CreateBar(TUI_ManaBack, TUI_ManaFill, TUI_ManaText, -0.046, TUI_MANA_TEXTURE)

    set TUI_CurrentTargetText = BlzCreateFrameByType("TEXT", "TargetUnitUICurrentTarget", TUI_Parent, "", 0)
    call BlzFrameSetPoint(TUI_CurrentTargetText, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, -0.063)
    call BlzFrameSetSize(TUI_CurrentTargetText, TUI_BAR_WIDTH, 0.013)
    call BlzFrameSetTextAlignment(TUI_CurrentTargetText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(TUI_CurrentTargetText, 0.68)
    call BlzFrameSetEnable(TUI_CurrentTargetText, false)
    call BlzFrameSetLevel(TUI_CurrentTargetText, 7)

    set TUI_ThreatHeader = BlzCreateFrameByType("TEXT", "TargetUnitUIThreatHeader", TUI_Parent, "", 0)
    call BlzFrameSetPoint(TUI_ThreatHeader, FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, -0.080)
    call BlzFrameSetSize(TUI_ThreatHeader, TUI_BAR_WIDTH, 0.012)
    call BlzFrameSetText(TUI_ThreatHeader, "|cffbfbfbfThreat|r")
    call BlzFrameSetTextAlignment(TUI_ThreatHeader, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    call BlzFrameSetScale(TUI_ThreatHeader, 0.64)
    call BlzFrameSetEnable(TUI_ThreatHeader, false)
    call BlzFrameSetLevel(TUI_ThreatHeader, 7)

    loop
        exitwhen row > 3
        set y = -0.094 - I2R(row - 1) * 0.014
        set TUI_ThreatRow[row] = BlzCreateFrameByType("TEXT", "TargetUnitUIThreatRow" + I2S(row), TUI_Parent, "", 0)
        call BlzFrameSetPoint(TUI_ThreatRow[row], FRAMEPOINT_TOPLEFT, TUI_Parent, FRAMEPOINT_TOPLEFT, 0.015, y)
        call BlzFrameSetSize(TUI_ThreatRow[row], TUI_BAR_WIDTH, 0.012)
        call BlzFrameSetTextAlignment(TUI_ThreatRow[row], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(TUI_ThreatRow[row], 0.62)
        call BlzFrameSetEnable(TUI_ThreatRow[row], false)
        call BlzFrameSetLevel(TUI_ThreatRow[row], 7)
        set row = row + 1
    endloop

    call BlzFrameSetVisible(TUI_Parent, false)
endfunction

private function Init takes nothing returns nothing
    call TUI_CreateFrames()
    set TUI_UpdateTimer = CreateTimer()
    call TimerStart(TUI_UpdateTimer, TUI_UPDATE_INTERVAL, true, function TUI_Update)
endfunction

endlibrary
