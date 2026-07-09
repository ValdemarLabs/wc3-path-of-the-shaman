/**
    StatsLiteUI

    Author: Valdemar
    Version:

    Description:
    Lightweight party monitor for player heroes, the active pet, and current
    companions. It replaces the old multiboard monitor surface with a compact
    frame UI focused on status, life, mana, level, and simple combat state.

    Credits:
    Old MultiboardGUI triggers as data/layout reference.
    Tasyen (TasQuestBox as frame UI inspiration)

    How to install:
    Import after MasterUI, QuestGiver, Companions, and Pet. StatsUI can require
    this library for the party monitor handoff and return flow.

    API:
    call StatsLiteUI_Show()
    call StatsLiteUI_ShowConfig()
    call StatsLiteUI_Hide()
    call StatsLiteUI_HideForCinematic()
    call StatsLiteUI_ShowAfterCinematic()
    call StatsLiteUI_ShowLastState()
    call StatsLiteUI_Toggle()
    call StatsLiteUI_Minimize()
    call StatsLiteUI_Maximize()
    call StatsLiteUI_IsMinimized() returns boolean
    call StatsLiteUI_Refresh()

**/
library StatsLiteUI requires Table, MasterUI, QuestGiver, Companions, Pet
    globals
        // Monitor sizing and refresh cadence.
        private constant real SLUI_REFRESH_INTERVAL = 0.35
        private constant integer SLUI_MAX_ROWS = 10

        // CHANGE: The monitor is now anchored from the right edge and sized by width.
        // This keeps the panel fixed to the right side even when minimized/maximized,
        // instead of depending on separate left/right absolute coordinates.
        private constant real SLUI_PANEL_RIGHT = 0.800 // CHANGE: pushed to the UI right edge
        private constant real SLUI_PANEL_WIDTH = 0.243
        private constant real SLUI_PANEL_TOP = 0.565
        private constant real SLUI_PANEL_BOTTOM = 0.325
        private constant real SLUI_MIN_RIGHT = 0.800 // CHANGE: pushed minimized state to the UI right edge
        private constant real SLUI_MIN_WIDTH = 0.243
        private constant real SLUI_MIN_BOTTOM = 0.522
        private constant real SLUI_BAR_WIDTH = 0.080 // CHANGE: slightly shorter bars leave cleaner padding inside the row

        private constant integer SLUI_ACTION_MINIMIZE = 1
        private constant integer SLUI_ACTION_STATS = 2
        private constant integer SLUI_ACTION_CONFIG = 3
        private constant integer SLUI_ACTION_CLOSE = 4
        private constant integer SLUI_ACTION_MONITOR = 5
        private constant integer SLUI_ACTION_INFO = 6
        private constant integer SLUI_ACTION_SHOW_HEROES = 10
        private constant integer SLUI_ACTION_SHOW_PET = 11
        private constant integer SLUI_ACTION_SHOW_COMPANIONS = 12
        private constant integer SLUI_ACTION_SHOW_MANA = 13
        private constant integer SLUI_ACTION_SHOW_LEVEL = 14
        private constant integer SLUI_ACTION_SHOW_STATE = 15

        private constant integer SLUI_KIND_HERO = 1
        private constant integer SLUI_KIND_PET = 2
        private constant integer SLUI_KIND_COMPANION = 3
        private constant integer SLUI_UNIT_SHADOWCLAW = 'n655'

        private boolean SLUI_Initialized = false
        // CHANGE: Keep default false. Init creates the hidden frame tree only;
        // visibility is controlled by explicit API calls such as StatsLiteUI_Show().
        private boolean SLUI_DefaultVisible = false
        private boolean SLUI_Minimized = false
        private boolean SLUI_ConfigVisible = false
        private boolean SLUI_ShowHeroes = true
        private boolean SLUI_ShowPet = true
        private boolean SLUI_ShowCompanions = true
        private boolean SLUI_ShowMana = true
        private boolean SLUI_ShowLevel = true
        private boolean SLUI_ShowState = true

        private framehandle SLUI_Parent = null
        private framehandle SLUI_Backdrop = null
        private framehandle SLUI_BackdropTint = null // CHANGE: inner translucent grey surface, separate from native border
        private framehandle SLUI_Title = null
        private framehandle SLUI_MinimizeButton = null
        private framehandle SLUI_StatsButton = null
        private framehandle SLUI_ConfigButton = null
        private framehandle SLUI_ConfigIcon = null
        private framehandle SLUI_InfoButton = null
        private framehandle SLUI_CloseButton = null
        private framehandle SLUI_RowPane = null
        private framehandle SLUI_ConfigPane = null
        private framehandle SLUI_ConfigTitle = null
        private framehandle SLUI_ConfigMonitorButton = null
        private framehandle SLUI_FooterText = null

        private framehandle array SLUI_RowButton
        private framehandle array SLUI_RowIcon
        private framehandle array SLUI_RowName
        private framehandle array SLUI_RowLevel
        private framehandle array SLUI_RowState
        private framehandle array SLUI_RowHPBack
        private framehandle array SLUI_RowHPFill
        private framehandle array SLUI_RowHPText
        private framehandle array SLUI_RowMPBack
        private framehandle array SLUI_RowMPFill
        private framehandle array SLUI_RowMPText
        private framehandle array SLUI_ConfigToggleButton

        private integer array SLUI_RowDisplayHandle
        private integer array SLUI_RowVisibleState
        private integer array SLUI_RowHPValue
        private integer array SLUI_RowMPValue
        private integer array SLUI_RowDeadState
        private string array SLUI_RowStateCache

        private Table SLUI_ButtonAction = 0

        private trigger SLUI_ButtonTrigger = null
        private trigger SLUI_ClearFocusTrigger = null
        // CHANGE: Kept for compatibility/readability, but Init no longer schedules
        // a delayed default show trigger. This prevents preload/init-time display.
        private trigger SLUI_InitTrigger = null
        private timer SLUI_RefreshTimer = null

        private string SLUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        private string SLUI_DefaultUnitIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
        private string SLUI_DefaultPetIcon = "ReplaceableTextures\\CommandButtons\\BTNAnimalWarTraining.blp"
        private string SLUI_ConfigIconPath = "ReplaceableTextures\\CommandButtons\\BTNengineering.blp"
    endglobals

    private function SLUI_OnOff takes boolean flag returns string
        if flag then
            return "|cff80ff80On|r"
        endif
        return "|cffff8080Off|r"
    endfunction

    private function SLUI_IsValidUnit takes unit u returns boolean
        return u != null and GetHandleId(u) != 0 and GetUnitTypeId(u) != 0
    endfunction

    private function SLUI_IsPlayerOwnedMainHero takes unit u returns boolean
        return SLUI_IsValidUnit(u) and GetOwningPlayer(u) == Player(0)
    endfunction

    private function SLUI_GetDisplayName takes unit u returns string
        local string displayName
        local integer unitTypeId

        if not SLUI_IsValidUnit(u) then
            return "Unavailable"
        endif
        if IsUnitType(u, UNIT_TYPE_HERO) then
            return GetHeroProperName(u)
        endif

        set unitTypeId = GetUnitTypeId(u)
        set displayName = GetUnitName(u)
        if displayName != null and displayName != "" then
            return displayName
        endif

        set displayName = GetObjectName(unitTypeId)
        if displayName != null and displayName != "" then
            return displayName
        endif

        if u == udg_Shadowclaw or unitTypeId == SLUI_UNIT_SHADOWCLAW then
            return "Shadowclaw"
        endif

        return "Unknown"
    endfunction

    private function SLUI_GetKindLabel takes integer kind returns string
        if kind == SLUI_KIND_HERO then
            return "|cffffcc00Hero|r"
        elseif kind == SLUI_KIND_PET then
            return "|cff9fd3ffPet|r"
        endif
        return "|cffffffccCompanion|r"
    endfunction

    private function SLUI_GetUnitIconPath takes unit u, integer kind returns string
        local string iconPath

        if not SLUI_IsValidUnit(u) then
            if kind == SLUI_KIND_PET then
                return SLUI_DefaultPetIcon
            endif
            return SLUI_DefaultUnitIcon
        endif

        set iconPath = BlzGetAbilityIcon(GetUnitTypeId(u))
        if iconPath != null and iconPath != "" then
            return iconPath
        endif

        set iconPath = QuestGiver_GetCompanionIcon(u)
        if iconPath != null and iconPath != "" then
            return iconPath
        endif

        if kind == SLUI_KIND_PET then
            return SLUI_DefaultPetIcon
        endif
        return SLUI_DefaultUnitIcon
    endfunction

    private function SLUI_GetHealthPercent takes unit u returns integer
        local real maxLife
        if not SLUI_IsValidUnit(u) then
            return 0
        endif
        set maxLife = GetUnitState(u, UNIT_STATE_MAX_LIFE)
        if maxLife <= 0.0 then
            return 0
        endif
        return R2I((GetUnitState(u, UNIT_STATE_LIFE) / maxLife) * 100.0)
    endfunction

    private function SLUI_GetManaPercent takes unit u returns integer
        local real maxMana
        if not SLUI_IsValidUnit(u) then
            return 0
        endif
        set maxMana = GetUnitState(u, UNIT_STATE_MAX_MANA)
        if maxMana <= 0.0 then
            return 0
        endif
        return R2I((GetUnitState(u, UNIT_STATE_MANA) / maxMana) * 100.0)
    endfunction

    private function SLUI_IsDeadForDisplay takes unit u returns boolean
        if not SLUI_IsValidUnit(u) then
            return false
        endif
        if Pet_IsDead(u) then
            return true
        endif
        return GetWidgetLife(u) <= 0.405
    endfunction

    private function SLUI_GetLevelText takes unit u returns string
        if not SLUI_IsValidUnit(u) then
            return "-"
        endif
        if IsUnitType(u, UNIT_TYPE_HERO) then
            return I2S(GetHeroLevel(u))
        endif
        return I2S(GetUnitLevel(u))
    endfunction

    private function SLUI_GetReviveTimer takes unit u, integer kind returns timer
        if not SLUI_IsValidUnit(u) then
            return null
        endif
        if u == udg_Nazgrek then
            return udg_ReviveTimerNazgrek
        elseif u == udg_Zulkis then
            return udg_ReviveTimerZulkis
        elseif kind == SLUI_KIND_PET or u == udg_TamedUnit then
            return udg_ReviveTimerPet
        elseif u == udg_NPC_Horde_AI_Rogue then
            return udg_ReviveTimerRogue
        elseif u == udg_NPC_Horde_AI_Warlock then
            return udg_ReviveTimerWarlock
        elseif u == udg_NPC_Horde_AI_Shaman then
            return udg_ReviveTimerRestoshaman
        elseif u == udg_NPC_Horde_AI_Warrior then
            return udg_ReviveTimerWarrior
        elseif u == udg_NPC_Neutral_Engineer then
            return udg_ReviveTimerEngineer
        elseif u == udg_Valeria then
            return udg_ReviveTimerValeria
        endif
        return null
    endfunction

    private function SLUI_GetDeadStatusText takes unit u, integer kind returns string
        local timer reviveTimer = SLUI_GetReviveTimer(u, kind)
        local real remaining = 0.0

        if reviveTimer != null then
            set remaining = TimerGetRemaining(reviveTimer)
        endif

        set reviveTimer = null
        if remaining > 0.0 then
            return "|cffff4040Dead|r |cffbfbfbf(" + I2S(R2I(remaining + 0.5)) + "s)|r"
        endif
        return "|cffff4040Dead|r"
    endfunction

    private function SLUI_GetUnitStateText takes unit u, integer kind returns string
        local integer unitId

        if not SLUI_IsValidUnit(u) then
            return "|cff808080Unavailable|r"
        endif
        if SLUI_IsDeadForDisplay(u) then
            return SLUI_GetDeadStatusText(u, kind)
        endif

        set unitId = GetUnitUserData(u)
        if unitId > 0 then
            if udg_UnitIsCasting[unitId] then
                return "|cffffcc00Casting|r"
            elseif udg_GCSM_UnitInCombat[unitId] then
                return "|cffff8040Combat|r"
            elseif (kind == SLUI_KIND_PET or kind == SLUI_KIND_COMPANION) and udg_CompanionUnitIdle[unitId] then
                return "|cffbfbfbfIdle|r"
            elseif udg_UnitMoving[unitId] then
                return "|cff80a0ffMoving|r"
            endif
        endif

        return "|cff80ff80Ready|r"
    endfunction

    private function SLUI_GetTrackedPetUnit takes nothing returns unit
        if SLUI_IsValidUnit(udg_TamedUnit) then
            return udg_TamedUnit
        endif
        return null
    endfunction

    private function SLUI_GetTrackedUnitCount takes nothing returns integer
        local integer count = 0
        local integer i = 1

        if SLUI_ShowHeroes then
            if SLUI_IsPlayerOwnedMainHero(udg_Nazgrek) then
                set count = count + 1
            endif
            if SLUI_IsPlayerOwnedMainHero(udg_Zulkis) then
                set count = count + 1
            endif
        endif

        if SLUI_ShowPet and SLUI_GetTrackedPetUnit() != null then
            set count = count + 1
        endif

        if SLUI_ShowCompanions then
            loop
                exitwhen i > udg_CompanionCount
                if SLUI_IsValidUnit(udg_CompanionUnit[i]) then
                    set count = count + 1
                endif
                set i = i + 1
            endloop
        endif

        return count
    endfunction

    // CHANGE: Dynamic HP color. Warcraft III backdrops cannot make a true
    // multi-stop gradient inside one frame, so the fill color is interpolated:
    // 0% = red, 50% = yellow, 100% = green.
    private function SLUI_GetHealthColor takes integer percent returns integer
        local real t
        local integer red
        local integer green
        local integer blue = 36

        if percent < 0 then
            set percent = 0
        elseif percent > 100 then
            set percent = 100
        endif

        if percent <= 50 then
            set t = I2R(percent) / 50.0
            set red = 220
            set green = R2I(36.0 + (190.0 * t))
        else
            set t = I2R(percent - 50) / 50.0
            set red = R2I(220.0 - (188.0 * t))
            set green = 226
        endif

        return BlzConvertColor(235, red, green, blue)
    endfunction

    // CHANGE: MP always uses a light-blue fill.
    private function SLUI_GetManaColor takes nothing returns integer
        return BlzConvertColor(225, 105, 195, 255)
    endfunction

    // CHANGE: Shared semi-transparent grey empty-bar background.
    private function SLUI_GetEmptyBarColor takes nothing returns integer
        return BlzConvertColor(95, 165, 165, 165)
    endfunction

    private function SLUI_SetBar takes framehandle fillFrame, framehandle textFrame, real maxWidth, real height, integer percent, integer color, string label returns nothing
        local real width

        // CHANGE: Clamp percentage before using it for frame size.
        if percent < 0 then
            set percent = 0
        elseif percent > 100 then
            set percent = 100
        endif

        set width = maxWidth * I2R(percent) * 0.01

        if percent <= 0 then
            // CHANGE: Hide the fill at 0% so the grey empty bar is visible.
            call BlzFrameSetVisible(fillFrame, false)
            set width = 0.001
        else
            call BlzFrameSetVisible(fillFrame, true)
            if width < 0.001 then
                set width = 0.001
            elseif width > maxWidth then
                set width = maxWidth
            endif
        endif

        call BlzFrameSetSize(fillFrame, width, height)
        call BlzFrameSetVertexColor(fillFrame, color)
        call BlzFrameSetText(textFrame, label + " " + I2S(percent) + "%")

        set fillFrame = null
        set textFrame = null
    endfunction

    private function SLUI_SetRowVisible takes integer rowIndex, boolean visible returns nothing
        local integer visibleState = 0

        if visible then
            set visibleState = 1
        endif
        if SLUI_RowVisibleState[rowIndex] != visibleState then
            set SLUI_RowVisibleState[rowIndex] = visibleState
            call BlzFrameSetVisible(SLUI_RowButton[rowIndex], visible)
        endif
    endfunction

    private function SLUI_UpdateRowFrame takes integer rowIndex, unit u, integer kind returns nothing
        local integer handleId = GetHandleId(u)
        local integer hp = 0
        local integer mp = 0
        local integer dead = 0
        local string stateText = ""

        if SLUI_RowDisplayHandle[rowIndex] != handleId then
            set SLUI_RowDisplayHandle[rowIndex] = handleId
            set SLUI_RowHPValue[rowIndex] = -1
            set SLUI_RowMPValue[rowIndex] = -1
            set SLUI_RowDeadState[rowIndex] = -1
            set SLUI_RowStateCache[rowIndex] = ""
            call BlzFrameSetTexture(SLUI_RowIcon[rowIndex], SLUI_GetUnitIconPath(u, kind), 0, true)
            call BlzFrameSetText(SLUI_RowName[rowIndex], SLUI_GetKindLabel(kind) + " " + SLUI_GetDisplayName(u))
        endif

        if SLUI_IsDeadForDisplay(u) then
            set dead = 1
        else
            set hp = SLUI_GetHealthPercent(u)
            set mp = SLUI_GetManaPercent(u)
        endif

        if SLUI_RowDeadState[rowIndex] != dead or SLUI_RowHPValue[rowIndex] != hp or SLUI_RowMPValue[rowIndex] != mp then
            set SLUI_RowDeadState[rowIndex] = dead
            set SLUI_RowHPValue[rowIndex] = hp
            set SLUI_RowMPValue[rowIndex] = mp
            call SLUI_SetBar(SLUI_RowHPFill[rowIndex], SLUI_RowHPText[rowIndex], SLUI_BAR_WIDTH, 0.008, hp, SLUI_GetHealthColor(hp), "HP")
            call SLUI_SetBar(SLUI_RowMPFill[rowIndex], SLUI_RowMPText[rowIndex], SLUI_BAR_WIDTH, 0.006, mp, SLUI_GetManaColor(), "MP") // CHANGE: MP uses a stable light-blue fill
        endif

        call BlzFrameSetVisible(SLUI_RowMPBack[rowIndex], SLUI_ShowMana)
        call BlzFrameSetVisible(SLUI_RowMPFill[rowIndex], SLUI_ShowMana)
        call BlzFrameSetVisible(SLUI_RowMPText[rowIndex], SLUI_ShowMana)
        call BlzFrameSetVisible(SLUI_RowLevel[rowIndex], SLUI_ShowLevel)
        call BlzFrameSetVisible(SLUI_RowState[rowIndex], SLUI_ShowState)

        if SLUI_ShowLevel then
            call BlzFrameSetText(SLUI_RowLevel[rowIndex], "Level " + SLUI_GetLevelText(u))
        endif
        if SLUI_ShowState then
            set stateText = SLUI_GetUnitStateText(u, kind)
            if SLUI_RowStateCache[rowIndex] != stateText then
                set SLUI_RowStateCache[rowIndex] = stateText
                call BlzFrameSetText(SLUI_RowState[rowIndex], stateText)
            endif
        endif

        call SLUI_SetRowVisible(rowIndex, true)
    endfunction

    private function SLUI_AddUnitRow takes integer rowIndex, unit u, integer kind returns integer
        if not SLUI_IsValidUnit(u) then
            return rowIndex
        endif
        if rowIndex <= SLUI_MAX_ROWS then
            call SLUI_UpdateRowFrame(rowIndex, u, kind)
        endif
        return rowIndex + 1
    endfunction

    private function SLUI_UpdateTitle takes nothing returns nothing
        if SLUI_ConfigVisible then
            call BlzFrameSetText(SLUI_Title, "|cffffe4a3Monitor|r")
        elseif SLUI_Minimized then
            call BlzFrameSetText(SLUI_Title, "|cffffe4a3Party|r |cffbfbfbf" + I2S(udg_CompanionCount) + "/" + I2S(Companions_GetCompanionLimit()) + "|r")
        else
            call BlzFrameSetText(SLUI_Title, "|cffffe4a3Party|r |cffbfbfbf" + I2S(udg_CompanionCount) + "/" + I2S(Companions_GetCompanionLimit()) + "|r")
        endif
    endfunction

    private function SLUI_UpdateFooter takes integer total returns nothing
        local string statusText
        if SLUI_FooterText == null then
            return
        endif

        if SLUI_ConfigVisible or SLUI_Minimized then
            call BlzFrameSetText(SLUI_FooterText, "")
        elseif total > SLUI_MAX_ROWS then
            call BlzFrameSetText(SLUI_FooterText, "|cffbfbfbf" + Companions_GetCompanionStatusText() + " | +" + I2S(total - SLUI_MAX_ROWS) + " more|r")
        else
            set statusText = Companions_GetCompanionStatusText()
            call BlzFrameSetText(SLUI_FooterText, "|cffbfbfbf" + statusText + " | " + I2S(total) + " tracked|r")
        endif
    endfunction

    private function SLUI_UpdateRows takes player whichPlayer returns nothing
        local integer rowIndex = 1
        local integer i = 1
        local integer total = SLUI_GetTrackedUnitCount()
        local unit petUnit = null

        if GetLocalPlayer() != whichPlayer or SLUI_RowPane == null then
            set petUnit = null
            set whichPlayer = null
            return
        endif

        if SLUI_ShowHeroes then
            if SLUI_IsPlayerOwnedMainHero(udg_Nazgrek) then
                set rowIndex = SLUI_AddUnitRow(rowIndex, udg_Nazgrek, SLUI_KIND_HERO)
            endif
            if SLUI_IsPlayerOwnedMainHero(udg_Zulkis) then
                set rowIndex = SLUI_AddUnitRow(rowIndex, udg_Zulkis, SLUI_KIND_HERO)
            endif
        endif

        if SLUI_ShowPet then
            set petUnit = SLUI_GetTrackedPetUnit()
            set rowIndex = SLUI_AddUnitRow(rowIndex, petUnit, SLUI_KIND_PET)
        endif

        if SLUI_ShowCompanions then
            loop
                exitwhen i > udg_CompanionCount
                set rowIndex = SLUI_AddUnitRow(rowIndex, udg_CompanionUnit[i], SLUI_KIND_COMPANION)
                set i = i + 1
            endloop
        endif

        loop
            exitwhen rowIndex > SLUI_MAX_ROWS
            set SLUI_RowDisplayHandle[rowIndex] = 0
            set SLUI_RowStateCache[rowIndex] = ""
            call SLUI_SetRowVisible(rowIndex, false)
            set rowIndex = rowIndex + 1
        endloop

        call SLUI_UpdateFooter(total)
        set petUnit = null
        set whichPlayer = null
    endfunction

    private function SLUI_UpdateConfig takes player whichPlayer returns nothing
        if GetLocalPlayer() != whichPlayer or SLUI_ConfigPane == null then
            set whichPlayer = null
            return
        endif

        call BlzFrameSetText(SLUI_ConfigToggleButton[1], "Heroes: " + SLUI_OnOff(SLUI_ShowHeroes))
        call BlzFrameSetText(SLUI_ConfigToggleButton[2], "Pet: " + SLUI_OnOff(SLUI_ShowPet))
        call BlzFrameSetText(SLUI_ConfigToggleButton[3], "Companions: " + SLUI_OnOff(SLUI_ShowCompanions))
        call BlzFrameSetText(SLUI_ConfigToggleButton[4], "Mana: " + SLUI_OnOff(SLUI_ShowMana))
        call BlzFrameSetText(SLUI_ConfigToggleButton[5], "Level: " + SLUI_OnOff(SLUI_ShowLevel))
        call BlzFrameSetText(SLUI_ConfigToggleButton[6], "State: " + SLUI_OnOff(SLUI_ShowState))
        set whichPlayer = null
    endfunction

    // CHANGE: Layout helper anchors the panel by its right edge.
    // The left edge is derived from right - width, so the monitor remains fixed
    // against the right-side UI position without maintaining duplicate left constants.
    private function SLUI_SetPanelAbsRect takes real right, real width, real top, real bottom returns nothing
        call BlzFrameClearAllPoints(SLUI_Parent)
        call BlzFrameSetAbsPoint(SLUI_Parent, FRAMEPOINT_TOPRIGHT, right, top)
        call BlzFrameSetAbsPoint(SLUI_Parent, FRAMEPOINT_BOTTOMLEFT, right - width, bottom)
    endfunction

    private function SLUI_ApplyLayout takes player whichPlayer returns nothing
        if GetLocalPlayer() != whichPlayer or SLUI_Parent == null then
            set whichPlayer = null
            return
        endif

        // CHANGE: Use right-anchored layout in both minimized and maximized states.
        if SLUI_Minimized then
            call SLUI_SetPanelAbsRect(SLUI_MIN_RIGHT, SLUI_MIN_WIDTH, SLUI_PANEL_TOP, SLUI_MIN_BOTTOM)
            call BlzFrameSetText(SLUI_MinimizeButton, "+")
        else
            call SLUI_SetPanelAbsRect(SLUI_PANEL_RIGHT, SLUI_PANEL_WIDTH, SLUI_PANEL_TOP, SLUI_PANEL_BOTTOM)
            call BlzFrameSetText(SLUI_MinimizeButton, "-")
        endif

        call BlzFrameSetVisible(SLUI_RowPane, not SLUI_Minimized and not SLUI_ConfigVisible)
        call BlzFrameSetVisible(SLUI_ConfigPane, not SLUI_Minimized and SLUI_ConfigVisible)
        call BlzFrameSetVisible(SLUI_FooterText, not SLUI_Minimized and not SLUI_ConfigVisible)
        call SLUI_UpdateTitle()
        set whichPlayer = null
    endfunction

    private function SLUI_Update takes player whichPlayer returns nothing
        if SLUI_Parent == null then
            set whichPlayer = null
            return
        endif

        call SLUI_UpdateTitle()
        if not SLUI_Minimized and SLUI_ConfigVisible then
            call SLUI_UpdateConfig(whichPlayer)
        elseif not SLUI_Minimized then
            call SLUI_UpdateRows(whichPlayer)
        endif

        set whichPlayer = null
    endfunction

    private function SLUI_PeriodicRefresh takes nothing returns nothing
        if SLUI_Parent != null and BlzFrameIsVisible(SLUI_Parent) then
            call SLUI_Update(GetLocalPlayer())
        endif
    endfunction

    private function SLUI_SetRefreshActive takes boolean active returns nothing
        if SLUI_RefreshTimer == null then
            return
        endif
        if active then
            call TimerStart(SLUI_RefreshTimer, SLUI_REFRESH_INTERVAL, true, function SLUI_PeriodicRefresh)
        else
            call PauseTimer(SLUI_RefreshTimer)
        endif
    endfunction

    private function SLUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    public function Hide takes nothing returns nothing
        call SLUI_SetRefreshActive(false)
        if SLUI_Parent != null then
            call BlzFrameSetVisible(SLUI_Parent, false)
        endif
    endfunction

    public function HideForCinematic takes nothing returns nothing
        call Hide()
    endfunction

    public function Maximize takes nothing returns nothing
        set SLUI_Minimized = false
        call SLUI_ApplyLayout(GetLocalPlayer())
        call SLUI_Update(GetLocalPlayer())
    endfunction

    public function Minimize takes nothing returns nothing
        set SLUI_Minimized = true
        call SLUI_ApplyLayout(GetLocalPlayer())
        call SLUI_Update(GetLocalPlayer())
    endfunction

    private function SLUI_ToggleMinimized takes nothing returns nothing
        if SLUI_Minimized then
            call Maximize()
        else
            call Minimize()
        endif
    endfunction

    public function ShowLastState takes nothing returns nothing
        set SLUI_ConfigVisible = false
        call SLUI_SetRefreshActive(true)
        call SLUI_ApplyLayout(GetLocalPlayer())
        call SLUI_Update(GetLocalPlayer())
        if SLUI_Parent != null then
            call BlzFrameSetVisible(SLUI_Parent, true)
        endif
    endfunction

    public function ShowAfterCinematic takes nothing returns nothing
        call ShowLastState()
    endfunction

    public function Show takes nothing returns nothing
        call ShowLastState()
    endfunction

    public function IsMinimized takes nothing returns boolean
        return SLUI_Minimized
    endfunction

    public function ShowConfig takes nothing returns nothing
        set SLUI_ConfigVisible = true
        set SLUI_Minimized = false
        call SLUI_SetRefreshActive(true)
        call SLUI_ApplyLayout(GetLocalPlayer())
        call SLUI_Update(GetLocalPlayer())
        if SLUI_Parent != null then
            call BlzFrameSetVisible(SLUI_Parent, true)
        endif
    endfunction

    public function Refresh takes nothing returns nothing
        call SLUI_Update(GetLocalPlayer())
    endfunction

    public function Toggle takes nothing returns nothing
        if SLUI_Parent != null and BlzFrameIsVisible(SLUI_Parent) then
            call Hide()
        else
            call Show()
        endif
    endfunction

    private function SLUI_OpenStats takes nothing returns nothing
        call Hide()
        call ExecuteFunc("StatsUI_ShowFromStatsLite")
    endfunction

    private function SLUI_ButtonClickAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer actionId = 0
        local player p = GetTriggerPlayer()

        if SLUI_ButtonAction.has(handleId) then
            set actionId = SLUI_ButtonAction.integer[handleId]
            if actionId == SLUI_ACTION_MINIMIZE then
                call SLUI_ToggleMinimized()
            elseif actionId == SLUI_ACTION_STATS then
                call SLUI_OpenStats()
            elseif actionId == SLUI_ACTION_CONFIG then
                call ShowConfig()
            elseif actionId == SLUI_ACTION_CLOSE then
                call Hide()
            elseif actionId == SLUI_ACTION_MONITOR then
                call Show()
                call Maximize()
            elseif actionId == SLUI_ACTION_INFO then
                call Companions_ShowCompanionLimitInfo()
            elseif actionId == SLUI_ACTION_SHOW_HEROES then
                set SLUI_ShowHeroes = not SLUI_ShowHeroes
            elseif actionId == SLUI_ACTION_SHOW_PET then
                set SLUI_ShowPet = not SLUI_ShowPet
            elseif actionId == SLUI_ACTION_SHOW_COMPANIONS then
                set SLUI_ShowCompanions = not SLUI_ShowCompanions
            elseif actionId == SLUI_ACTION_SHOW_MANA then
                set SLUI_ShowMana = not SLUI_ShowMana
            elseif actionId == SLUI_ACTION_SHOW_LEVEL then
                set SLUI_ShowLevel = not SLUI_ShowLevel
            elseif actionId == SLUI_ACTION_SHOW_STATE then
                set SLUI_ShowState = not SLUI_ShowState
            endif
            call SLUI_Update(p)
        endif

        set p = null
    endfunction

    private function SLUI_RegisterButton takes framehandle whichFrame, integer actionId returns nothing
        call BlzTriggerRegisterFrameEvent(SLUI_ButtonTrigger, whichFrame, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SLUI_ClearFocusTrigger, whichFrame, FRAMEEVENT_CONTROL_CLICK)
        set SLUI_ButtonAction.integer[GetHandleId(whichFrame)] = actionId
        set whichFrame = null
    endfunction

    private function SLUI_CreateHeaderButton takes string name, string label, real width, framehandle anchor, real x returns framehandle
        local framehandle buttonFrame = BlzCreateFrameByType("GLUETEXTBUTTON", name, SLUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(buttonFrame, width, 0.022)
        call BlzFrameSetText(buttonFrame, label)
        call BlzFrameSetPoint(buttonFrame, FRAMEPOINT_TOPRIGHT, anchor, FRAMEPOINT_TOPLEFT, x, 0.0)
        // CHANGE: Header buttons must render above the background frame.
        call BlzFrameSetLevel(buttonFrame, 3)
        set anchor = null
        return buttonFrame
    endfunction

    private function SLUI_CreateConfigButton takes integer index, string label, integer actionId, real x, real y returns nothing
        set SLUI_ConfigToggleButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsLiteUIConfigButton" + I2S(index), SLUI_ConfigPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SLUI_ConfigToggleButton[index], 0.100, 0.028)
        call BlzFrameSetPoint(SLUI_ConfigToggleButton[index], FRAMEPOINT_TOPLEFT, SLUI_ConfigPane, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameSetText(SLUI_ConfigToggleButton[index], label)
        // CHANGE: Config buttons render above config pane background.
        call BlzFrameSetLevel(SLUI_ConfigToggleButton[index], 4)
        call SLUI_RegisterButton(SLUI_ConfigToggleButton[index], actionId)
    endfunction

    private function SLUI_CreateRow takes integer rowIndex, real y returns nothing
        local real barLeft = 0.126

        set SLUI_RowButton[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRow" + I2S(rowIndex), SLUI_RowPane, "", 0)
        call BlzFrameSetTexture(SLUI_RowButton[rowIndex], SLUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowPane, FRAMEPOINT_TOPLEFT, 0.006, y)
        call BlzFrameSetSize(SLUI_RowButton[rowIndex], 0.222, 0.040) // CHANGE: taller row; slightly narrower to stay inside native border
        call BlzFrameSetAlpha(SLUI_RowButton[rowIndex], 0)
        call BlzFrameSetVertexColor(SLUI_RowButton[rowIndex], BlzConvertColor(0, 10, 10, 10))
        // CHANGE: Row container stays above the main backdrop; row children are created under it.
        call BlzFrameSetLevel(SLUI_RowButton[rowIndex], 3)

        set SLUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowIcon" + I2S(rowIndex), SLUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(SLUI_RowIcon[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.006, -0.006) // CHANGE: icon aligned with taller row
        call BlzFrameSetSize(SLUI_RowIcon[rowIndex], 0.026, 0.026) // CHANGE: icon scaled for taller row
        call BlzFrameSetLevel(SLUI_RowIcon[rowIndex], 4) // CHANGE: row icon above translucent panel

        set SLUI_RowName[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowName" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowName[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.038, -0.003)
        call BlzFrameSetSize(SLUI_RowName[rowIndex], 0.090, 0.012)
        call BlzFrameSetTextAlignment(SLUI_RowName[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowName[rowIndex], 0.70) // CHANGE: name column now shares vertical space with level/state
        call BlzFrameSetEnable(SLUI_RowName[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowName[rowIndex], 4) // CHANGE: row text above translucent panel

        set SLUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowLevel" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowLevel[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.038, -0.015)
        // CHANGE: Level is now under the unit name instead of at the far right edge.
        call BlzFrameSetSize(SLUI_RowLevel[rowIndex], 0.080, 0.010)
        call BlzFrameSetTextAlignment(SLUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowLevel[rowIndex], 0.58)
        call BlzFrameSetEnable(SLUI_RowLevel[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowLevel[rowIndex], 4) // CHANGE: level text above translucent panel

        set SLUI_RowState[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowState" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowState[rowIndex], FRAMEPOINT_BOTTOMLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMLEFT, 0.038, 0.003)
        call BlzFrameSetSize(SLUI_RowState[rowIndex], 0.080, 0.010)
        call BlzFrameSetTextAlignment(SLUI_RowState[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowState[rowIndex], 0.58) // CHANGE: state sits under level inside the left text column
        call BlzFrameSetEnable(SLUI_RowState[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowState[rowIndex], 4) // CHANGE: state text above translucent panel

        set SLUI_RowHPBack[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowHPBack" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowHPBack[rowIndex], SLUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(SLUI_RowHPBack[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.132, -0.010)
        // CHANGE: Bars now occupy the right column; level text moved to the left column.
        call BlzFrameSetSize(SLUI_RowHPBack[rowIndex], SLUI_BAR_WIDTH, 0.008)
        call BlzFrameSetVertexColor(SLUI_RowHPBack[rowIndex], SLUI_GetEmptyBarColor()) // CHANGE: transparent light-grey empty bar background
        call BlzFrameSetEnable(SLUI_RowHPBack[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowHPBack[rowIndex], 4) // CHANGE: empty HP bar background below fill

        set SLUI_RowHPFill[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowHPFill" + I2S(rowIndex), SLUI_RowHPBack[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowHPFill[rowIndex], SLUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(SLUI_RowHPFill[rowIndex], FRAMEPOINT_LEFT, SLUI_RowHPBack[rowIndex], FRAMEPOINT_LEFT, 0.0, 0.0)
        call BlzFrameSetSize(SLUI_RowHPFill[rowIndex], 0.001, 0.008)
        call BlzFrameSetEnable(SLUI_RowHPFill[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowHPFill[rowIndex], 5) // CHANGE: HP fill above empty bar background

        set SLUI_RowHPText[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowHPText" + I2S(rowIndex), SLUI_RowHPBack[rowIndex], "", 0)
        call BlzFrameSetAllPoints(SLUI_RowHPText[rowIndex], SLUI_RowHPBack[rowIndex])
        call BlzFrameSetTextAlignment(SLUI_RowHPText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(SLUI_RowHPText[rowIndex], 0.55)
        call BlzFrameSetEnable(SLUI_RowHPText[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowHPText[rowIndex], 6) // CHANGE: HP text above fill

        set SLUI_RowMPBack[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowMPBack" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowMPBack[rowIndex], SLUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(SLUI_RowMPBack[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowHPBack[rowIndex], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        call BlzFrameSetSize(SLUI_RowMPBack[rowIndex], SLUI_BAR_WIDTH, 0.006)
        call BlzFrameSetVertexColor(SLUI_RowMPBack[rowIndex], SLUI_GetEmptyBarColor()) // CHANGE: transparent light-grey empty bar background
        call BlzFrameSetEnable(SLUI_RowMPBack[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowMPBack[rowIndex], 4) // CHANGE: empty MP bar background below fill

        set SLUI_RowMPFill[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowMPFill" + I2S(rowIndex), SLUI_RowMPBack[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowMPFill[rowIndex], SLUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(SLUI_RowMPFill[rowIndex], FRAMEPOINT_LEFT, SLUI_RowMPBack[rowIndex], FRAMEPOINT_LEFT, 0.0, 0.0)
        call BlzFrameSetSize(SLUI_RowMPFill[rowIndex], 0.001, 0.006)
        call BlzFrameSetEnable(SLUI_RowMPFill[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowMPFill[rowIndex], 5) // CHANGE: MP fill above empty bar background

        set SLUI_RowMPText[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowMPText" + I2S(rowIndex), SLUI_RowMPBack[rowIndex], "", 0)
        call BlzFrameSetAllPoints(SLUI_RowMPText[rowIndex], SLUI_RowMPBack[rowIndex])
        call BlzFrameSetTextAlignment(SLUI_RowMPText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(SLUI_RowMPText[rowIndex], 0.50)
        call BlzFrameSetEnable(SLUI_RowMPText[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowMPText[rowIndex], 6) // CHANGE: MP text above fill

        set SLUI_RowVisibleState[rowIndex] = -1
        call BlzFrameSetVisible(SLUI_RowButton[rowIndex], false)
    endfunction

    private function SLUI_CreateFrames takes nothing returns nothing
        local integer rowIndex = 1
        local real rowY = -0.008 // CHANGE: rows are taller because level is now placed under the unit name

        // CHANGE: The root is now a plain FRAME, not a visual BACKDROP.
        // This makes SLUI_Parent an invisible container. The actual panel surface is
        // SLUI_Backdrop below, so the backdrop stays behind title/buttons/rows.
        set SLUI_Parent = BlzCreateFrameByType("FRAME", "StatsLiteUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
        call SLUI_SetPanelAbsRect(SLUI_PANEL_RIGHT, SLUI_PANEL_WIDTH, SLUI_PANEL_TOP, SLUI_PANEL_BOTTOM)

        // CHANGE: Hide immediately after creation to prevent preload/init flicker.
        call BlzFrameSetVisible(SLUI_Parent, false)
        call BlzFrameSetLevel(SLUI_Parent, 0)

        // CHANGE: Native border/background frame. This keeps the Warcraft III EscMenu-style frame.
        set SLUI_Backdrop = BlzCreateFrame("EscMenuBackdrop", SLUI_Parent, 0, 0)
        call BlzFrameSetAllPoints(SLUI_Backdrop, SLUI_Parent)
        call BlzFrameSetEnable(SLUI_Backdrop, false)
        call BlzFrameSetLevel(SLUI_Backdrop, 0)

        // CHANGE: Separate inner translucent grey surface, similar to the reference UI.
        // It is inset so it does not cover the native border pieces.
        // Tune the first BlzConvertColor value if needed:
        // 70 = lighter/more transparent, 115 = darker/more readable.
        set SLUI_BackdropTint = BlzCreateFrameByType("BACKDROP", "StatsLiteUIBackdropTint", SLUI_Parent, "", 0)
        call BlzFrameSetTexture(SLUI_BackdropTint, SLUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SLUI_BackdropTint, FRAMEPOINT_TOPLEFT, SLUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.034)
        call BlzFrameSetPoint(SLUI_BackdropTint, FRAMEPOINT_BOTTOMRIGHT, SLUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.018, 0.034)
        call BlzFrameSetVertexColor(SLUI_BackdropTint, BlzConvertColor(90, 70, 70, 70))
        call BlzFrameSetEnable(SLUI_BackdropTint, false)
        call BlzFrameSetLevel(SLUI_BackdropTint, 1)

        set SLUI_Title = BlzCreateFrameByType("TEXT", "StatsLiteUITitle", SLUI_Parent, "", 0)
        call BlzFrameSetPoint(SLUI_Title, FRAMEPOINT_TOPLEFT, SLUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.012)
        call BlzFrameSetSize(SLUI_Title, 0.110, 0.016) // CHANGE: slightly wider title area for Party 0/1 or similar text
        call BlzFrameSetTextAlignment(SLUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_Title, 0.95)
        call BlzFrameSetEnable(SLUI_Title, false)
        // CHANGE: Header text is above the panel backdrop.
        call BlzFrameSetLevel(SLUI_Title, 3)

        set SLUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsLiteUIClose", SLUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SLUI_CloseButton, 0.022, 0.022)
        call BlzFrameSetText(SLUI_CloseButton, "X")
        call BlzFrameSetPoint(SLUI_CloseButton, FRAMEPOINT_TOPRIGHT, SLUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        // CHANGE: Close button must render above the background frame.
        call BlzFrameSetLevel(SLUI_CloseButton, 3)
        call SLUI_RegisterButton(SLUI_CloseButton, SLUI_ACTION_CLOSE)

        set SLUI_MinimizeButton = SLUI_CreateHeaderButton("StatsLiteUIMinimize", "-", 0.022, SLUI_CloseButton, -0.004)
        call SLUI_RegisterButton(SLUI_MinimizeButton, SLUI_ACTION_MINIMIZE)

        set SLUI_ConfigButton = SLUI_CreateHeaderButton("StatsLiteUIConfig", "", 0.022, SLUI_MinimizeButton, -0.004) // CHANGE: match ? / - / X button size
        set SLUI_ConfigIcon = BlzCreateFrameByType("BACKDROP", "StatsLiteUIConfigIcon", SLUI_ConfigButton, "", 0)
        call BlzFrameSetTexture(SLUI_ConfigIcon, SLUI_ConfigIconPath, 0, true)
        call BlzFrameSetAllPoints(SLUI_ConfigIcon, SLUI_ConfigButton)
        call BlzFrameSetEnable(SLUI_ConfigIcon, false)
        // CHANGE: Config icon is visual content above its button/backdrop.
        call BlzFrameSetLevel(SLUI_ConfigIcon, 4)
        call SLUI_RegisterButton(SLUI_ConfigButton, SLUI_ACTION_CONFIG)

        set SLUI_InfoButton = SLUI_CreateHeaderButton("StatsLiteUIInfo", "?", 0.022, SLUI_ConfigButton, -0.004)
        call SLUI_RegisterButton(SLUI_InfoButton, SLUI_ACTION_INFO)

        set SLUI_StatsButton = SLUI_CreateHeaderButton("StatsLiteUIStats", "Stats", 0.046, SLUI_InfoButton, -0.004)
        call SLUI_RegisterButton(SLUI_StatsButton, SLUI_ACTION_STATS)

        set SLUI_RowPane = BlzCreateFrameByType("FRAME", "StatsLiteUIRows", SLUI_Parent, "", 0)
        call BlzFrameSetPoint(SLUI_RowPane, FRAMEPOINT_TOPLEFT, SLUI_Parent, FRAMEPOINT_TOPLEFT, 0.008, -0.040)
        call BlzFrameSetPoint(SLUI_RowPane, FRAMEPOINT_BOTTOMRIGHT, SLUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.024) // CHANGE: a touch more right inner padding inside the native border
        call BlzFrameSetEnable(SLUI_RowPane, false)
        // CHANGE: Rows render above the panel backdrop.
        call BlzFrameSetLevel(SLUI_RowPane, 3)

        loop
            exitwhen rowIndex > SLUI_MAX_ROWS
            call SLUI_CreateRow(rowIndex, rowY)
            set rowY = rowY - 0.043 // CHANGE: taller row spacing for name, level, and state text
            set rowIndex = rowIndex + 1
        endloop

        set SLUI_FooterText = BlzCreateFrameByType("TEXT", "StatsLiteUIFooter", SLUI_Parent, "", 0)
        call BlzFrameSetPoint(SLUI_FooterText, FRAMEPOINT_BOTTOMLEFT, SLUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.014, 0.012)
        call BlzFrameSetSize(SLUI_FooterText, 0.200, 0.012)
        call BlzFrameSetTextAlignment(SLUI_FooterText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_FooterText, 0.65)
        call BlzFrameSetEnable(SLUI_FooterText, false)
        // CHANGE: Footer text is above the panel backdrop.
        call BlzFrameSetLevel(SLUI_FooterText, 2)

        set SLUI_ConfigPane = BlzCreateFrameByType("BACKDROP", "StatsLiteUIConfigPane", SLUI_Parent, "", 0)
        call BlzFrameSetTexture(SLUI_ConfigPane, SLUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(SLUI_ConfigPane, FRAMEPOINT_TOPLEFT, SLUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.044)
        call BlzFrameSetPoint(SLUI_ConfigPane, FRAMEPOINT_BOTTOMRIGHT, SLUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.016)
        call BlzFrameSetVertexColor(SLUI_ConfigPane, BlzConvertColor(220, 6, 6, 6))
        // CHANGE: Config pane is above the main backdrop and below its own controls.
        call BlzFrameSetLevel(SLUI_ConfigPane, 3)

        set SLUI_ConfigTitle = BlzCreateFrameByType("TEXT", "StatsLiteUIConfigTitle", SLUI_ConfigPane, "", 0)
        call BlzFrameSetPoint(SLUI_ConfigTitle, FRAMEPOINT_TOPLEFT, SLUI_ConfigPane, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
        call BlzFrameSetSize(SLUI_ConfigTitle, 0.160, 0.014)
        call BlzFrameSetTextAlignment(SLUI_ConfigTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_ConfigTitle, 0.82)
        call BlzFrameSetText(SLUI_ConfigTitle, "|cffffcc00Display|r")
        call BlzFrameSetEnable(SLUI_ConfigTitle, false)
        // CHANGE: Config title is above config pane background.
        call BlzFrameSetLevel(SLUI_ConfigTitle, 2)

        call SLUI_CreateConfigButton(1, "Heroes", SLUI_ACTION_SHOW_HEROES, 0.012, -0.036)
        call SLUI_CreateConfigButton(2, "Pet", SLUI_ACTION_SHOW_PET, 0.122, -0.036)
        call SLUI_CreateConfigButton(3, "Companions", SLUI_ACTION_SHOW_COMPANIONS, 0.012, -0.070)
        call SLUI_CreateConfigButton(4, "Mana", SLUI_ACTION_SHOW_MANA, 0.122, -0.070)
        call SLUI_CreateConfigButton(5, "Level", SLUI_ACTION_SHOW_LEVEL, 0.012, -0.104)
        call SLUI_CreateConfigButton(6, "State", SLUI_ACTION_SHOW_STATE, 0.122, -0.104)

        set SLUI_ConfigMonitorButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsLiteUIConfigMonitor", SLUI_ConfigPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SLUI_ConfigMonitorButton, 0.210, 0.030)
        call BlzFrameSetPoint(SLUI_ConfigMonitorButton, FRAMEPOINT_BOTTOM, SLUI_ConfigPane, FRAMEPOINT_BOTTOM, 0.0, 0.014)
        call BlzFrameSetText(SLUI_ConfigMonitorButton, "Show Monitor")
        // CHANGE: Config monitor button renders above config pane background.
        call BlzFrameSetLevel(SLUI_ConfigMonitorButton, 4)
        call SLUI_RegisterButton(SLUI_ConfigMonitorButton, SLUI_ACTION_MONITOR)

        call BlzFrameSetVisible(SLUI_ConfigPane, false)
        call BlzFrameSetVisible(SLUI_Parent, false)
    endfunction

    // CHANGE: This function is intentionally left unused.
    // Older versions scheduled it from Init, which could make the monitor appear
    // during preload/startup if SLUI_DefaultVisible was true or stale code existed.
    // The current Init does not call this; external API controls visibility.
    private function SLUI_DelayedShow takes nothing returns nothing
        if SLUI_DefaultVisible then
            call Show()
        endif
    endfunction

    public function Init takes nothing returns nothing
        if SLUI_Initialized then
            return
        endif
        set SLUI_Initialized = true

        set SLUI_ButtonAction = Table.create()

        set SLUI_ButtonTrigger = CreateTrigger()
        call TriggerAddAction(SLUI_ButtonTrigger, function SLUI_ButtonClickAction)

        set SLUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(SLUI_ClearFocusTrigger, function SLUI_ClearFocusAction)

        call SLUI_CreateFrames()

        set SLUI_RefreshTimer = CreateTimer()

        // CHANGE: Do not schedule SLUI_DelayedShow here.
        // Init now only creates the hidden frame tree and refresh timer.
        // Showing the monitor must happen through explicit API calls:
        //   call StatsLiteUI_Show()
        //   call StatsLiteUI_ShowConfig()
        //   call StatsLiteUI_Toggle()
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
