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
library StatsLiteUI requires Table, MasterUI, QuestGiver, Companions, Pet, AI // CHANGE: use AI registry instead of legacy udg_NPC_Horde_AI_xxx globals
    globals
        // Monitor sizing and refresh cadence.
        private constant real SLUI_REFRESH_INTERVAL = 0.35
        private constant integer SLUI_MAX_ROWS = 10

        // CHANGE: The monitor is positioned against a fullscreen relative frame.
        // This lets it sit at the real client right edge instead of the 4:3 edge.
        private constant real SLUI_SCREEN_HEIGHT = 0.600
        private constant real SLUI_SCREEN_CENTER_X = 0.400
        private constant real SLUI_PANEL_RIGHT_OFFSET = -0.008
        private constant real SLUI_PANEL_TOP_OFFSET = -0.034
        private constant real SLUI_PANEL_WIDTH = 0.284
        private constant real SLUI_PANEL_MIN_HEIGHT = 0.116
        private constant real SLUI_PANEL_MAX_HEIGHT = 0.392
        private constant real SLUI_PANEL_CONFIG_HEIGHT = 0.280
        private constant real SLUI_PANEL_MINIMIZED_HEIGHT = 0.044
        private constant real SLUI_PANEL_BASE_HEIGHT = 0.069
        private constant real SLUI_ROW_HEIGHT = 0.030
        private constant real SLUI_ROW_GAP = 0.003
        private constant real SLUI_BAR_WIDTH = 0.082 // CHANGE: bar column remains fixed while the left text area grows

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
        private constant integer SLUI_ACTION_ALERT_LOW_HP = 16 // CHANGE: config toggle for low-health row alerts
        private constant integer SLUI_ACTION_ALERT_LOW_RESOURCE = 17 // CHANGE: config toggle for low mana/rage/energy alerts
        private constant integer SLUI_ACTION_ALERT_FAR = 18 // CHANGE: config toggle for out-of-range companion alerts
        private constant integer SLUI_ACTION_DYNAMIC_HP_COLOR = 19 // CHANGE: config toggle for percentage-based HP bar colors
        private constant integer SLUI_ACTION_SHOW_CLASS = 20 // CHANGE: config toggle for row class text

        private constant integer SLUI_KIND_HERO = 1
        private constant integer SLUI_KIND_PET = 2
        private constant integer SLUI_KIND_COMPANION = 3
        private constant integer SLUI_UNIT_SHADOWCLAW = 'n655'
        private constant integer SLUI_RESOURCE_MANA = 0 // CHANGE: default caster mana/resource bar
        private constant integer SLUI_RESOURCE_RAGE = 1 // CHANGE: warrior-style red resource bar
        private constant integer SLUI_RESOURCE_ENERGY = 2 // CHANGE: rogue-style yellow resource bar
        private constant integer SLUI_ALERT_NONE = 0 // CHANGE: no row alert
        private constant integer SLUI_ALERT_FAR = 1 // CHANGE: companion is far from current leader
        private constant integer SLUI_ALERT_LOW_RESOURCE = 2 // CHANGE: low mana/rage/energy
        private constant integer SLUI_ALERT_LOW_HP = 3 // CHANGE: low health/dead alert has highest priority
        private constant real SLUI_LOW_HP_ALERT_PERCENT = 25.0 // CHANGE: matches the red HP bar threshold
        private constant real SLUI_LOW_RESOURCE_ALERT_PERCENT = 20.0 // CHANGE: low resource alert threshold
        private constant real SLUI_FAR_DISTANCE_NORMAL = 2500.0 // CHANGE: mirrors Companions normal follow distance
        private constant real SLUI_FAR_DISTANCE_AGGRESSIVE = 3500.0 // CHANGE: mirrors Companions aggressive follow distance

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
        private boolean SLUI_ShowClass = true
        private boolean SLUI_AlertLowHP = true // CHANGE: configurable low-health flash alert
        private boolean SLUI_AlertLowResource = true // CHANGE: configurable low mana/rage/energy flash alert
        private boolean SLUI_AlertFar = true // CHANGE: configurable far-away party member flash alert
        private boolean SLUI_DynamicHPColor = false // CHANGE: default false; HP bars stay green unless enabled in config

        private framehandle SLUI_ScreenParent = null
        private framehandle SLUI_ScreenAnchor = null
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
        private framehandle array SLUI_RowAlert
        private framehandle array SLUI_RowIcon
        private framehandle array SLUI_RowName
        private framehandle array SLUI_RowLevel
        private framehandle array SLUI_RowClass
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
        private string array SLUI_RowClassCache

        private Table SLUI_ButtonAction = 0
        private Table SLUI_ClassResourceMode = 0 // CHANGE: AI classId -> resource display mode

        private trigger SLUI_ButtonTrigger = null
        private trigger SLUI_ClearFocusTrigger = null
        // CHANGE: Kept for compatibility/readability, but Init no longer schedules
        // a delayed default show trigger. This prevents preload/init-time display.
        private trigger SLUI_InitTrigger = null
        private timer SLUI_RefreshTimer = null
        private integer SLUI_RefreshTick = 0

        private string SLUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        private string SLUI_BarEmptyTexture = "ReplaceableTextures\\TeamColor\\TeamColor08.blp" // CHANGE: grey empty bar texture
        private string SLUI_BarHPGreenTexture = "ReplaceableTextures\\TeamColor\\TeamColor06.blp" // CHANGE: green HP fill
        private string SLUI_BarHPYellowTexture = "ReplaceableTextures\\TeamColor\\TeamColor04.blp" // CHANGE: yellow HP fill
        private string SLUI_BarHPRedTexture = "ReplaceableTextures\\TeamColor\\TeamColor00.blp" // CHANGE: red HP / warrior resource fill
        private string SLUI_BarMPLightBlueTexture = "ReplaceableTextures\\TeamColor\\TeamColor09.blp" // CHANGE: light-blue mana fill
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

    private function SLUI_TrimText takes string text, integer maxLength returns string
        if text == null then
            return ""
        endif
        if maxLength <= 2 then
            return text
        endif
        if StringLength(text) > maxLength then
            return SubString(text, 0, maxLength - 2) + ".."
        endif
        return text
    endfunction

    // CHANGE: Resource-mode registry is separate from UI frame init so AI
    // sublibraries can register class resource colors during their own Init.
    private function SLUI_EnsureResourceRegistry takes nothing returns nothing
        if SLUI_ClassResourceMode == 0 then
            set SLUI_ClassResourceMode = Table.create()
        endif
    endfunction

    // CHANGE: Public API for AI class libraries.
    public function RegisterManaResourceClass takes integer classId returns nothing
        if classId <= 0 then
            return
        endif
        call SLUI_EnsureResourceRegistry()
        set SLUI_ClassResourceMode.integer[classId] = SLUI_RESOURCE_MANA
    endfunction

    // CHANGE: Public API for warrior/rage classes.
    public function RegisterRageResourceClass takes integer classId returns nothing
        if classId <= 0 then
            return
        endif
        call SLUI_EnsureResourceRegistry()
        set SLUI_ClassResourceMode.integer[classId] = SLUI_RESOURCE_RAGE
    endfunction

    // CHANGE: Public API for rogue/energy classes.
    public function RegisterEnergyResourceClass takes integer classId returns nothing
        if classId <= 0 then
            return
        endif
        call SLUI_EnsureResourceRegistry()
        set SLUI_ClassResourceMode.integer[classId] = SLUI_RESOURCE_ENERGY
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

    private function SLUI_HasResourceBar takes unit u returns boolean
        if not SLUI_IsValidUnit(u) then
            return false
        endif
        return GetUnitState(u, UNIT_STATE_MAX_MANA) > 0.0
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

    private function SLUI_GetFallbackUnitClassText takes unit u returns string
        local integer unitTypeId

        if not SLUI_IsValidUnit(u) then
            return "-"
        endif

        set unitTypeId = GetUnitTypeId(u)
        if udg_Nazgrek != null and GetHandleId(udg_Nazgrek) != 0 and unitTypeId == GetUnitTypeId(udg_Nazgrek) then
            return "Shaman"
        elseif unitTypeId == 'H60Y' then
            return "Paladin"
        elseif unitTypeId == '061H' then
            return "Shaman"
        elseif unitTypeId == 'O631' then
            return "Rogue"
        elseif unitTypeId == 'O629' then
            return "Warrior"
        elseif unitTypeId == 'H60X' then
            return "Warlock"
        elseif unitTypeId == 'N64O' or unitTypeId == 'N661' then
            return "Engineer"
        endif

        return "TBD"
    endfunction

    private function SLUI_GetUnitClassText takes unit u returns string
        if not SLUI_IsValidUnit(u) then
            return "-"
        endif
        if Pet_IsPetUnit(u) then
            return Pet_GetClassInfoText(u)
        endif
        if Companions_IsControlled(u) then
            return Companions_GetClassInfoText(u)
        endif
        return SLUI_GetFallbackUnitClassText(u)
    endfunction

    private function SLUI_GetReviveTimer takes unit u, integer kind returns timer
        local timer aiReviveTimer

        if not SLUI_IsValidUnit(u) then
            return null
        endif

        if u == udg_Nazgrek then
            return udg_ReviveTimerNazgrek
        elseif u == udg_Zulkis then
            return udg_ReviveTimerZulkis
        elseif kind == SLUI_KIND_PET or u == udg_TamedUnit then
            return udg_ReviveTimerPet
        endif

        // CHANGE: AI companion revive timers are owned by AI.j.
        set aiReviveTimer = AI_GetReviveTimer(u)
        return aiReviveTimer
    endfunction

    private function SLUI_GetDeadStatusText takes unit u, integer kind returns string
        local timer reviveTimer = SLUI_GetReviveTimer(u, kind)
        local real remaining = 0.0

        if reviveTimer != null then
            set remaining = TimerGetRemaining(reviveTimer)
        elseif kind == SLUI_KIND_COMPANION then
            set remaining = AI_GetReviveRemaining(u)
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

    // CHANGE: HP bars are green by default. When enabled in config, HP fill
    // changes by percentage: green > 50%, yellow 26-50%, red 0-25%.
    private function SLUI_GetHealthBarTexture takes integer percent returns string
        if not SLUI_DynamicHPColor then
            return SLUI_BarHPGreenTexture
        endif

        if percent > 50 then
            return SLUI_BarHPGreenTexture
        elseif percent > 25 then
            return SLUI_BarHPYellowTexture
        endif
        return SLUI_BarHPRedTexture
    endfunction

    // CHANGE: Resource mode is resolved from the AI class registry.
    // This replaces legacy udg_NPC_Horde_AI_xxx unit globals and works for
    // units registered by AI sublibraries such as AIWarrior/AIRogue.
    private function SLUI_GetResourceMode takes unit u returns integer
        local integer classId = 0
        local integer mode = SLUI_RESOURCE_MANA

        if SLUI_IsValidUnit(u) then
            set classId = AI_GetClassId(u)
        endif

        if classId > 0 then
            call SLUI_EnsureResourceRegistry()
            if SLUI_ClassResourceMode.has(classId) then
                set mode = SLUI_ClassResourceMode.integer[classId]
            endif
        endif

        return mode
    endfunction

    private function SLUI_GetResourceBarTexture takes unit u returns string
        local integer mode = SLUI_GetResourceMode(u)

        if mode == SLUI_RESOURCE_RAGE then
            return SLUI_BarHPRedTexture
        elseif mode == SLUI_RESOURCE_ENERGY then
            return SLUI_BarHPYellowTexture
        endif
        return SLUI_BarMPLightBlueTexture
    endfunction

    // CHANGE: Resource label follows class resource mode.
    private function SLUI_GetResourceBarLabel takes unit u returns string
        local integer mode = SLUI_GetResourceMode(u)

        if mode == SLUI_RESOURCE_RAGE then
            return "Rage"
        elseif mode == SLUI_RESOURCE_ENERGY then
            return "Energy"
        endif
        return "Mana"
    endfunction

    private function SLUI_SetBar takes framehandle fillFrame, framehandle textFrame, real maxWidth, real height, integer percent, string fillTexture, string label returns nothing
        local real width

        // CHANGE: Clamp first, then resize the fill frame.
        if percent < 0 then
            set percent = 0
        elseif percent > 100 then
            set percent = 100
        endif

        set width = maxWidth * I2R(percent) * 0.01

        if percent <= 0 then
            // CHANGE: At 0%, hide only the fill. The grey empty background remains visible.
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

        call BlzFrameSetTexture(fillFrame, fillTexture, 0, false)
        call BlzFrameSetSize(fillFrame, width, height)

        if label == "Energy" and percent > 50 then
            call BlzFrameSetText(textFrame, "|cff000000Energy " + I2S(percent) + "%|r")
        elseif label == "Energy" then
            call BlzFrameSetText(textFrame, "|cfffff569Energy " + I2S(percent) + "%|r")
        else
            call BlzFrameSetText(textFrame, label + " " + I2S(percent) + "%")
        endif

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

    private function SLUI_GetDistanceBetweenUnits takes unit a, unit b returns real
        local real dx
        local real dy

        if a == null or b == null then
            return 0.0
        endif

        set dx = GetUnitX(a) - GetUnitX(b)
        set dy = GetUnitY(a) - GetUnitY(b)
        return SquareRoot(dx * dx + dy * dy)
    endfunction

    // CHANGE: Resolve the leader used for far-away row alerts.
    // This mirrors the focus groups maintained by Companions.j without reaching
    // into Companions' private leader table.
    private function SLUI_GetAlertLeader takes unit u returns unit
        if u == null then
            return null
        endif

        if udg_CompanionFocusZulkis != null and IsUnitInGroup(u, udg_CompanionFocusZulkis) and SLUI_IsValidUnit(udg_Zulkis) then
            return udg_Zulkis
        endif
        if udg_CompanionFocusNazgrek != null and IsUnitInGroup(u, udg_CompanionFocusNazgrek) and SLUI_IsValidUnit(udg_Nazgrek) then
            return udg_Nazgrek
        endif
        if SLUI_IsValidUnit(udg_Nazgrek) then
            return udg_Nazgrek
        endif
        if SLUI_IsValidUnit(udg_Zulkis) then
            return udg_Zulkis
        endif

        return null
    endfunction

    private function SLUI_IsFarFromLeader takes unit u, integer kind returns boolean
        local unit leader
        local integer mode = 1
        local real distanceLimit = SLUI_FAR_DISTANCE_NORMAL
        local boolean result = false

        if not SLUI_AlertFar or not SLUI_IsValidUnit(u) or kind == SLUI_KIND_HERO then
            return false
        endif

        set leader = SLUI_GetAlertLeader(u)
        if leader == null or leader == u then
            set leader = null
            return false
        endif

        if Companions_IsControlled(u) then
            set mode = Companions_GetMode(u)
            if mode == 3 then
                set leader = null
                return false
            elseif mode == 4 then
                set distanceLimit = SLUI_FAR_DISTANCE_AGGRESSIVE
            endif
        endif

        set result = SLUI_GetDistanceBetweenUnits(u, leader) > distanceLimit
        set leader = null
        return result
    endfunction

    // CHANGE: Priority order is low HP/dead > low resource > far away.
    private function SLUI_GetRowAlertLevel takes unit u, integer kind, integer hp, integer mp, integer dead returns integer
        if dead == 1 and SLUI_AlertLowHP then
            return SLUI_ALERT_LOW_HP
        endif
        if SLUI_AlertLowHP and hp >= 0 and I2R(hp) <= SLUI_LOW_HP_ALERT_PERCENT then
            return SLUI_ALERT_LOW_HP
        endif
        if SLUI_AlertLowResource and SLUI_HasResourceBar(u) and I2R(mp) <= SLUI_LOW_RESOURCE_ALERT_PERCENT then
            return SLUI_ALERT_LOW_RESOURCE
        endif
        if SLUI_IsFarFromLeader(u, kind) then
            return SLUI_ALERT_FAR
        endif
        return SLUI_ALERT_NONE
    endfunction

    private function SLUI_GetAlertAlpha takes nothing returns integer
        if ModuloInteger(SLUI_RefreshTick, 2) == 0 then
            return 230
        endif
        return 90
    endfunction

    private function SLUI_ApplyRowAlert takes integer rowIndex, integer alertLevel returns nothing
        local integer alpha

        if alertLevel <= SLUI_ALERT_NONE then
            call BlzFrameSetVisible(SLUI_RowAlert[rowIndex], false)
            return
        endif

        set alpha = SLUI_GetAlertAlpha()
        call BlzFrameSetVisible(SLUI_RowAlert[rowIndex], true)

        if alertLevel == SLUI_ALERT_LOW_HP then
            call BlzFrameSetVertexColor(SLUI_RowAlert[rowIndex], BlzConvertColor(alpha, 255, 40, 40))
        elseif alertLevel == SLUI_ALERT_LOW_RESOURCE then
            call BlzFrameSetVertexColor(SLUI_RowAlert[rowIndex], BlzConvertColor(alpha, 80, 150, 255))
        else
            call BlzFrameSetVertexColor(SLUI_RowAlert[rowIndex], BlzConvertColor(alpha, 255, 220, 40))
        endif
    endfunction

    private function SLUI_UpdateRowFrame takes integer rowIndex, unit u, integer kind returns nothing
        local integer handleId = GetHandleId(u)
        local integer hp = 0
        local integer mp = 0
        local integer dead = 0
        local string stateText = ""
        local string classText = ""
        local integer alertLevel = SLUI_ALERT_NONE

        if SLUI_RowDisplayHandle[rowIndex] != handleId then
            set SLUI_RowDisplayHandle[rowIndex] = handleId
            set SLUI_RowHPValue[rowIndex] = -1
            set SLUI_RowMPValue[rowIndex] = -1
            set SLUI_RowDeadState[rowIndex] = -1
            set SLUI_RowStateCache[rowIndex] = ""
            set SLUI_RowClassCache[rowIndex] = ""
            call BlzFrameSetTexture(SLUI_RowIcon[rowIndex], SLUI_GetUnitIconPath(u, kind), 0, true)
            call BlzFrameSetText(SLUI_RowName[rowIndex], SLUI_GetKindLabel(kind) + " " + SLUI_TrimText(SLUI_GetDisplayName(u), 17))
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
            call SLUI_SetBar(SLUI_RowHPFill[rowIndex], SLUI_RowHPText[rowIndex], SLUI_BAR_WIDTH, 0.008, hp, SLUI_GetHealthBarTexture(hp), "HP") // CHANGE: HP fill texture changes by health percent
            call SLUI_SetBar(SLUI_RowMPFill[rowIndex], SLUI_RowMPText[rowIndex], SLUI_BAR_WIDTH, 0.007, mp, SLUI_GetResourceBarTexture(u), SLUI_GetResourceBarLabel(u)) // CHANGE: label and fill follow mana/rage/energy class mode
        endif

        call BlzFrameSetVisible(SLUI_RowMPBack[rowIndex], SLUI_ShowMana)
        call BlzFrameSetVisible(SLUI_RowMPFill[rowIndex], SLUI_ShowMana)
        call BlzFrameSetVisible(SLUI_RowMPText[rowIndex], SLUI_ShowMana)
        call BlzFrameSetVisible(SLUI_RowLevel[rowIndex], SLUI_ShowLevel)
        call BlzFrameSetVisible(SLUI_RowClass[rowIndex], SLUI_ShowClass)
        call BlzFrameSetVisible(SLUI_RowState[rowIndex], SLUI_ShowState)

        // CHANGE: Alert flash is evaluated every refresh because far-away and
        // blinking state can change even when HP/MP values do not.
        set alertLevel = SLUI_GetRowAlertLevel(u, kind, hp, mp, dead)
        call SLUI_ApplyRowAlert(rowIndex, alertLevel)

        if SLUI_ShowLevel then
            call BlzFrameSetText(SLUI_RowLevel[rowIndex], "Lvl " + SLUI_GetLevelText(u))
        endif
        if SLUI_ShowClass then
            set classText = SLUI_TrimText(SLUI_GetUnitClassText(u), 11)
            if SLUI_RowClassCache[rowIndex] != classText then
                set SLUI_RowClassCache[rowIndex] = classText
                call BlzFrameSetText(SLUI_RowClass[rowIndex], "|cffbfbfbf" + classText + "|r")
            endif
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
            set SLUI_RowClassCache[rowIndex] = ""
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

        call BlzFrameSetText(SLUI_ConfigToggleButton[1], "Hero: " + SLUI_OnOff(SLUI_ShowHeroes))
        call BlzFrameSetText(SLUI_ConfigToggleButton[2], "Pet: " + SLUI_OnOff(SLUI_ShowPet))
        call BlzFrameSetText(SLUI_ConfigToggleButton[3], "Comp: " + SLUI_OnOff(SLUI_ShowCompanions))
        call BlzFrameSetText(SLUI_ConfigToggleButton[4], "Mana: " + SLUI_OnOff(SLUI_ShowMana))
        call BlzFrameSetText(SLUI_ConfigToggleButton[5], "Level: " + SLUI_OnOff(SLUI_ShowLevel))
        call BlzFrameSetText(SLUI_ConfigToggleButton[6], "Class: " + SLUI_OnOff(SLUI_ShowClass))
        call BlzFrameSetText(SLUI_ConfigToggleButton[7], "State: " + SLUI_OnOff(SLUI_ShowState))
        call BlzFrameSetText(SLUI_ConfigToggleButton[8], "Low HP: " + SLUI_OnOff(SLUI_AlertLowHP))
        call BlzFrameSetText(SLUI_ConfigToggleButton[9], "Low Res: " + SLUI_OnOff(SLUI_AlertLowResource))
        call BlzFrameSetText(SLUI_ConfigToggleButton[10], "Far: " + SLUI_OnOff(SLUI_AlertFar))
        call BlzFrameSetText(SLUI_ConfigToggleButton[11], "HP Color: " + SLUI_OnOff(SLUI_DynamicHPColor)) // CHANGE: dynamic HP color toggle
        set whichPlayer = null
    endfunction

    private function SLUI_GetDisplayRowCount takes nothing returns integer
        local integer count = SLUI_GetTrackedUnitCount()
        if count < 1 then
            return 1
        elseif count > SLUI_MAX_ROWS then
            return SLUI_MAX_ROWS
        endif
        return count
    endfunction

    private function SLUI_GetPanelHeight takes nothing returns real
        local integer rowCount
        local real height

        if SLUI_Minimized then
            return SLUI_PANEL_MINIMIZED_HEIGHT
        endif
        if SLUI_ConfigVisible then
            return SLUI_PANEL_CONFIG_HEIGHT
        endif

        set rowCount = SLUI_GetDisplayRowCount()
        set height = SLUI_PANEL_BASE_HEIGHT + I2R(rowCount) * SLUI_ROW_HEIGHT + I2R(rowCount - 1) * SLUI_ROW_GAP
        if height < SLUI_PANEL_MIN_HEIGHT then
            return SLUI_PANEL_MIN_HEIGHT
        elseif height > SLUI_PANEL_MAX_HEIGHT then
            return SLUI_PANEL_MAX_HEIGHT
        endif
        return height
    endfunction

    private function SLUI_UpdateScreenAnchor takes nothing returns nothing
        local integer clientWidth
        local integer clientHeight
        local real screenWidth = 0.800

        if SLUI_ScreenAnchor == null then
            return
        endif

        set clientWidth = BlzGetLocalClientWidth()
        set clientHeight = BlzGetLocalClientHeight()
        if clientHeight > 0 then
            set screenWidth = I2R(clientWidth) / I2R(clientHeight) * SLUI_SCREEN_HEIGHT
        endif
        if screenWidth < 0.800 then
            set screenWidth = 0.800
        endif

        call BlzFrameClearAllPoints(SLUI_ScreenAnchor)
        call BlzFrameSetSize(SLUI_ScreenAnchor, screenWidth, SLUI_SCREEN_HEIGHT)
        call BlzFrameSetAbsPoint(SLUI_ScreenAnchor, FRAMEPOINT_BOTTOM, SLUI_SCREEN_CENTER_X, 0.0)
    endfunction

    private function SLUI_SetPanelFrame takes real width, real height returns nothing
        call SLUI_UpdateScreenAnchor()
        call BlzFrameClearAllPoints(SLUI_Parent)
        call BlzFrameSetSize(SLUI_Parent, width, height)
        call BlzFrameSetPoint(SLUI_Parent, FRAMEPOINT_TOPRIGHT, SLUI_ScreenAnchor, FRAMEPOINT_TOPRIGHT, SLUI_PANEL_RIGHT_OFFSET, SLUI_PANEL_TOP_OFFSET)
    endfunction

    private function SLUI_ApplyLayout takes player whichPlayer returns nothing
        if GetLocalPlayer() != whichPlayer or SLUI_Parent == null then
            set whichPlayer = null
            return
        endif

        // CHANGE: Use right-anchored layout in both minimized and maximized states.
        if SLUI_Minimized then
            call SLUI_SetPanelFrame(SLUI_PANEL_WIDTH, SLUI_GetPanelHeight())
            call BlzFrameSetText(SLUI_MinimizeButton, "+")
        else
            call SLUI_SetPanelFrame(SLUI_PANEL_WIDTH, SLUI_GetPanelHeight())
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

        call SLUI_ApplyLayout(whichPlayer)
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
            set SLUI_RefreshTick = SLUI_RefreshTick + 1
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
            elseif actionId == SLUI_ACTION_SHOW_CLASS then
                set SLUI_ShowClass = not SLUI_ShowClass
            elseif actionId == SLUI_ACTION_SHOW_STATE then
                set SLUI_ShowState = not SLUI_ShowState
            elseif actionId == SLUI_ACTION_ALERT_LOW_HP then
                set SLUI_AlertLowHP = not SLUI_AlertLowHP
            elseif actionId == SLUI_ACTION_ALERT_LOW_RESOURCE then
                set SLUI_AlertLowResource = not SLUI_AlertLowResource
            elseif actionId == SLUI_ACTION_ALERT_FAR then
                set SLUI_AlertFar = not SLUI_AlertFar
            elseif actionId == SLUI_ACTION_DYNAMIC_HP_COLOR then
                set SLUI_DynamicHPColor = not SLUI_DynamicHPColor
                // CHANGE: Force bar refresh because HP values may not have changed.
                set SLUI_RowHPValue[1] = -1
                set SLUI_RowHPValue[2] = -1
                set SLUI_RowHPValue[3] = -1
                set SLUI_RowHPValue[4] = -1
                set SLUI_RowHPValue[5] = -1
                set SLUI_RowHPValue[6] = -1
                set SLUI_RowHPValue[7] = -1
                set SLUI_RowHPValue[8] = -1
                set SLUI_RowHPValue[9] = -1
                set SLUI_RowHPValue[10] = -1
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
        call BlzFrameSetSize(SLUI_ConfigToggleButton[index], 0.112, 0.020)
        call BlzFrameSetPoint(SLUI_ConfigToggleButton[index], FRAMEPOINT_TOPLEFT, SLUI_ConfigPane, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameSetText(SLUI_ConfigToggleButton[index], label)
        // CHANGE: Config buttons render above config pane background.
        call BlzFrameSetLevel(SLUI_ConfigToggleButton[index], 4)
        call SLUI_RegisterButton(SLUI_ConfigToggleButton[index], actionId)
    endfunction

    private function SLUI_CreateRow takes integer rowIndex, real y returns nothing
        local real barLeft = 0.174 // CHANGE: right-side bar column; left text column is aligned after icon

        set SLUI_RowButton[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRow" + I2S(rowIndex), SLUI_RowPane, "", 0)
        call BlzFrameSetTexture(SLUI_RowButton[rowIndex], SLUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowPane, FRAMEPOINT_TOPLEFT, 0.006, y)
        call BlzFrameSetSize(SLUI_RowButton[rowIndex], 0.256, SLUI_ROW_HEIGHT) // CHANGE: row height gives name/meta text separate baselines
        call BlzFrameSetAlpha(SLUI_RowButton[rowIndex], 0)
        call BlzFrameSetVertexColor(SLUI_RowButton[rowIndex], BlzConvertColor(0, 10, 10, 10))
        // CHANGE: Row container stays above the main backdrop; row children are created under it.
        call BlzFrameSetLevel(SLUI_RowButton[rowIndex], 3)

        // CHANGE: Small flashing alert frame behind/around the unit icon.
        set SLUI_RowAlert[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowAlert" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowAlert[rowIndex], SLUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SLUI_RowAlert[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.002, -0.001)
        call BlzFrameSetSize(SLUI_RowAlert[rowIndex], 0.252, 0.028)
        call BlzFrameSetLevel(SLUI_RowAlert[rowIndex], 3)
        call BlzFrameSetEnable(SLUI_RowAlert[rowIndex], false)
        call BlzFrameSetVisible(SLUI_RowAlert[rowIndex], false)

        set SLUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowIcon" + I2S(rowIndex), SLUI_RowButton[rowIndex], "IconButtonTemplate", 0)
        call BlzFrameSetPoint(SLUI_RowIcon[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.006, -0.004) // CHANGE: compact top-left icon position
        call BlzFrameSetSize(SLUI_RowIcon[rowIndex], 0.022, 0.022) // CHANGE: icon stays clear of the text columns
        call BlzFrameSetLevel(SLUI_RowIcon[rowIndex], 4) // CHANGE: icon above translucent panel

        set SLUI_RowName[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowName" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowName[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.034, -0.003) // CHANGE: kind/name starts after icon with no overlap
        call BlzFrameSetSize(SLUI_RowName[rowIndex], 0.134, 0.010)
        call BlzFrameSetTextAlignment(SLUI_RowName[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowName[rowIndex], 0.50)
        call BlzFrameSetEnable(SLUI_RowName[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowName[rowIndex], 4) // CHANGE: name above translucent panel

        set SLUI_RowLevel[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowLevel" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowLevel[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.034, -0.016) // CHANGE: level aligned below kind/name in the same column
        call BlzFrameSetSize(SLUI_RowLevel[rowIndex], 0.041, 0.008)
        call BlzFrameSetTextAlignment(SLUI_RowLevel[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowLevel[rowIndex], 0.43)
        call BlzFrameSetEnable(SLUI_RowLevel[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowLevel[rowIndex], 4) // CHANGE: level above translucent panel

        set SLUI_RowClass[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowClass" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowClass[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.077, -0.016)
        call BlzFrameSetSize(SLUI_RowClass[rowIndex], 0.050, 0.008)
        call BlzFrameSetTextAlignment(SLUI_RowClass[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowClass[rowIndex], 0.43)
        call BlzFrameSetEnable(SLUI_RowClass[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowClass[rowIndex], 4)

        set SLUI_RowState[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowState" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetPoint(SLUI_RowState[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.128, -0.016) // CHANGE: status aligned after level/class with no icon overlap
        call BlzFrameSetSize(SLUI_RowState[rowIndex], 0.044, 0.008)
        call BlzFrameSetTextAlignment(SLUI_RowState[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SLUI_RowState[rowIndex], 0.43)
        call BlzFrameSetEnable(SLUI_RowState[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowState[rowIndex], 4) // CHANGE: status above translucent panel

        set SLUI_RowHPBack[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowHPBack" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowHPBack[rowIndex], SLUI_PanelTexture, 0, false) // CHANGE: darker translucent empty HP space; avoids white unused bar area
        call BlzFrameSetPoint(SLUI_RowHPBack[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, barLeft, -0.006)
        call BlzFrameSetSize(SLUI_RowHPBack[rowIndex], SLUI_BAR_WIDTH, 0.008)
        call BlzFrameSetVertexColor(SLUI_RowHPBack[rowIndex], BlzConvertColor(95, 80, 80, 80))
        call BlzFrameSetEnable(SLUI_RowHPBack[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowHPBack[rowIndex], 4) // CHANGE: empty bar background above row panel

        set SLUI_RowHPFill[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowHPFill" + I2S(rowIndex), SLUI_RowHPBack[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowHPFill[rowIndex], SLUI_BarHPGreenTexture, 0, false) // CHANGE: initial HP fill texture; updated dynamically
        call BlzFrameSetPoint(SLUI_RowHPFill[rowIndex], FRAMEPOINT_LEFT, SLUI_RowHPBack[rowIndex], FRAMEPOINT_LEFT, 0.0, 0.0)
        call BlzFrameSetSize(SLUI_RowHPFill[rowIndex], 0.001, 0.008)
        call BlzFrameSetEnable(SLUI_RowHPFill[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowHPFill[rowIndex], 5) // CHANGE: fill above empty bar background

        set SLUI_RowHPText[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowHPText" + I2S(rowIndex), SLUI_RowHPBack[rowIndex], "", 0)
        call BlzFrameSetAllPoints(SLUI_RowHPText[rowIndex], SLUI_RowHPBack[rowIndex])
        call BlzFrameSetTextAlignment(SLUI_RowHPText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(SLUI_RowHPText[rowIndex], 0.46)
        call BlzFrameSetEnable(SLUI_RowHPText[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowHPText[rowIndex], 6) // CHANGE: label above fill

        set SLUI_RowMPBack[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowMPBack" + I2S(rowIndex), SLUI_RowButton[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowMPBack[rowIndex], SLUI_PanelTexture, 0, false) // CHANGE: darker translucent empty MP/resource space; avoids white unused bar area
        call BlzFrameSetPoint(SLUI_RowMPBack[rowIndex], FRAMEPOINT_TOPLEFT, SLUI_RowHPBack[rowIndex], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        call BlzFrameSetSize(SLUI_RowMPBack[rowIndex], SLUI_BAR_WIDTH, 0.007)
        call BlzFrameSetVertexColor(SLUI_RowMPBack[rowIndex], BlzConvertColor(95, 80, 80, 80))
        call BlzFrameSetEnable(SLUI_RowMPBack[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowMPBack[rowIndex], 4) // CHANGE: empty bar background above row panel

        set SLUI_RowMPFill[rowIndex] = BlzCreateFrameByType("BACKDROP", "StatsLiteUIRowMPFill" + I2S(rowIndex), SLUI_RowMPBack[rowIndex], "", 0)
        call BlzFrameSetTexture(SLUI_RowMPFill[rowIndex], SLUI_BarMPLightBlueTexture, 0, false) // CHANGE: initial MP fill texture; updated dynamically
        call BlzFrameSetPoint(SLUI_RowMPFill[rowIndex], FRAMEPOINT_LEFT, SLUI_RowMPBack[rowIndex], FRAMEPOINT_LEFT, 0.0, 0.0)
        call BlzFrameSetSize(SLUI_RowMPFill[rowIndex], 0.001, 0.007)
        call BlzFrameSetEnable(SLUI_RowMPFill[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowMPFill[rowIndex], 5) // CHANGE: fill above empty bar background

        set SLUI_RowMPText[rowIndex] = BlzCreateFrameByType("TEXT", "StatsLiteUIRowMPText" + I2S(rowIndex), SLUI_RowMPBack[rowIndex], "", 0)
        call BlzFrameSetAllPoints(SLUI_RowMPText[rowIndex], SLUI_RowMPBack[rowIndex])
        call BlzFrameSetTextAlignment(SLUI_RowMPText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(SLUI_RowMPText[rowIndex], 0.44)
        call BlzFrameSetEnable(SLUI_RowMPText[rowIndex], false)
        call BlzFrameSetLevel(SLUI_RowMPText[rowIndex], 6) // CHANGE: label above fill

        set SLUI_RowVisibleState[rowIndex] = -1
        call BlzFrameSetVisible(SLUI_RowButton[rowIndex], false)
    endfunction

    private function SLUI_CreateFrames takes nothing returns nothing
        local integer rowIndex = 1
        local real rowY = -0.001 // CHANGE: move first monitored unit upward to fit full party better

        // CHANGE: Parent under ConsoleUIBackdrop so the fullscreen anchor can leave
        // the 4:3 UI space. Fall back to GAME_UI if the native frame is unavailable.
        set SLUI_ScreenParent = BlzGetFrameByName("ConsoleUIBackdrop", 0)
        if SLUI_ScreenParent == null then
            set SLUI_ScreenParent = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        endif

        set SLUI_ScreenAnchor = BlzCreateFrameByType("FRAME", "StatsLiteUIScreenAnchor", SLUI_ScreenParent, "", 0)
        call SLUI_UpdateScreenAnchor()

        // CHANGE: The root is now a plain FRAME, not a visual BACKDROP.
        // This makes SLUI_Parent an invisible container. The actual panel surface is
        // SLUI_Backdrop below, so the backdrop stays behind title/buttons/rows.
        set SLUI_Parent = BlzCreateFrameByType("FRAME", "StatsLiteUIPanel", SLUI_ScreenAnchor, "", 0)
        call SLUI_SetPanelFrame(SLUI_PANEL_WIDTH, SLUI_GetPanelHeight())

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

        set SLUI_ConfigButton = SLUI_CreateHeaderButton("StatsLiteUIConfig", "", 0.022, SLUI_MinimizeButton, -0.004) // CHANGE: config button footprint matches ? / - / X
        set SLUI_ConfigIcon = BlzCreateFrameByType("BACKDROP", "StatsLiteUIConfigIcon", SLUI_ConfigButton, "", 0)
        call BlzFrameSetTexture(SLUI_ConfigIcon, SLUI_ConfigIconPath, 0, true)
        call BlzFrameSetPoint(SLUI_ConfigIcon, FRAMEPOINT_CENTER, SLUI_ConfigButton, FRAMEPOINT_CENTER, 0.0, 0.0)
        call BlzFrameSetSize(SLUI_ConfigIcon, 0.014, 0.014) // CHANGE: smaller inset icon so it visually matches ? / - / X
        call BlzFrameSetEnable(SLUI_ConfigIcon, false)
        // CHANGE: Config icon is visual content above its button/backdrop.
        call BlzFrameSetLevel(SLUI_ConfigIcon, 4)
        call SLUI_RegisterButton(SLUI_ConfigButton, SLUI_ACTION_CONFIG)

        set SLUI_InfoButton = SLUI_CreateHeaderButton("StatsLiteUIInfo", "?", 0.022, SLUI_ConfigButton, -0.004)
        call SLUI_RegisterButton(SLUI_InfoButton, SLUI_ACTION_INFO)

        set SLUI_StatsButton = SLUI_CreateHeaderButton("StatsLiteUIStats", "Stats", 0.046, SLUI_InfoButton, -0.004)
        call SLUI_RegisterButton(SLUI_StatsButton, SLUI_ACTION_STATS)

        set SLUI_RowPane = BlzCreateFrameByType("FRAME", "StatsLiteUIRows", SLUI_Parent, "", 0)
        call BlzFrameSetPoint(SLUI_RowPane, FRAMEPOINT_TOPLEFT, SLUI_Parent, FRAMEPOINT_TOPLEFT, 0.008, -0.030) // CHANGE: move unit rows upward
        call BlzFrameSetPoint(SLUI_RowPane, FRAMEPOINT_BOTTOMRIGHT, SLUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.026) // CHANGE: keep rows clear of footer/bottom border
        call BlzFrameSetEnable(SLUI_RowPane, false)
        // CHANGE: Rows render above the panel backdrop.
        call BlzFrameSetLevel(SLUI_RowPane, 3)

        loop
            exitwhen rowIndex > SLUI_MAX_ROWS
            call SLUI_CreateRow(rowIndex, rowY)
            set rowY = rowY - (SLUI_ROW_HEIGHT + SLUI_ROW_GAP) // CHANGE: rows keep fixed spacing as panel height changes
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

        call SLUI_CreateConfigButton(1, "Hero", SLUI_ACTION_SHOW_HEROES, 0.010, -0.032)
        call SLUI_CreateConfigButton(2, "Pet", SLUI_ACTION_SHOW_PET, 0.130, -0.032)
        call SLUI_CreateConfigButton(3, "Comp", SLUI_ACTION_SHOW_COMPANIONS, 0.010, -0.057)
        call SLUI_CreateConfigButton(4, "Mana", SLUI_ACTION_SHOW_MANA, 0.130, -0.057)
        call SLUI_CreateConfigButton(5, "Level", SLUI_ACTION_SHOW_LEVEL, 0.010, -0.082)
        call SLUI_CreateConfigButton(6, "Class", SLUI_ACTION_SHOW_CLASS, 0.130, -0.082)
        call SLUI_CreateConfigButton(7, "State", SLUI_ACTION_SHOW_STATE, 0.010, -0.107)
        call SLUI_CreateConfigButton(8, "Low HP", SLUI_ACTION_ALERT_LOW_HP, 0.130, -0.107) // CHANGE: alert config toggle
        call SLUI_CreateConfigButton(9, "Low Res", SLUI_ACTION_ALERT_LOW_RESOURCE, 0.010, -0.132) // CHANGE: alert config toggle
        call SLUI_CreateConfigButton(10, "Far", SLUI_ACTION_ALERT_FAR, 0.130, -0.132) // CHANGE: alert config toggle
        call SLUI_CreateConfigButton(11, "HP Color", SLUI_ACTION_DYNAMIC_HP_COLOR, 0.010, -0.157) // CHANGE: toggle percentage-based HP bar coloring

        set SLUI_ConfigMonitorButton = BlzCreateFrameByType("GLUETEXTBUTTON", "StatsLiteUIConfigMonitor", SLUI_ConfigPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SLUI_ConfigMonitorButton, 0.112, 0.020) // CHANGE: compact monitor button leaves room for toggles
        call BlzFrameSetPoint(SLUI_ConfigMonitorButton, FRAMEPOINT_BOTTOMRIGHT, SLUI_ConfigPane, FRAMEPOINT_BOTTOMRIGHT, -0.012, 0.010)
        call BlzFrameSetText(SLUI_ConfigMonitorButton, "Monitor")
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
        call SLUI_EnsureResourceRegistry() // CHANGE: initialize AI class resource registry

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
