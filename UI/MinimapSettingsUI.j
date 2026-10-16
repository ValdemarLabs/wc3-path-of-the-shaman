/**
    MinimapSettingsUI

    Author: Valdemar
    Version: 1.0.0

    Description:
    In-game settings panel for IconQuery timing, minimap marker categories,
    pings, display mode, nearby available quests, and secondary marker scan
    frequency.

    Credits:
    Tasyen (TasQuestBox as inspiration)

    How to install:
    Import after IconQuery, MasterUI, Table, and Interface. Open from SettingsUI.

    API:
    call MinimapSettingsUI_Show()
    call MinimapSettingsUI_Hide()
    call MinimapSettingsUI_Toggle()

**/
library MinimapSettingsUI initializer AutoInit requires Table, MasterUI, IconQuery, Interface
    globals
        // UI-limited settings ranges. IconQuery also clamps internally.
        private constant string MMUI_TOC_PATH = "war3mapimported\\templates.toc"
        private constant real MMUI_QUERY_TIME_MIN = 1.00
        private constant real MMUI_QUERY_TIME_MAX = 15.00
        private constant real MMUI_QUERY_REST_MIN = 5.00
        private constant real MMUI_QUERY_REST_MAX = 120.00

        private constant integer MMUI_ACTION_ALL = 1
        private constant integer MMUI_ACTION_QUEST_GIVERS = 2
        private constant integer MMUI_ACTION_FLIGHT_MASTER = 3
        private constant integer MMUI_ACTION_BOSSES = 4
        private constant integer MMUI_ACTION_POI = 5
        private constant integer MMUI_ACTION_COMPANIONS = 6
        private constant integer MMUI_ACTION_SECONDARY_FREQUENCY = 8
        private constant integer MMUI_ACTION_PINGS = 9
        private constant integer MMUI_ACTION_ICON_MODE = 10
        private constant integer MMUI_ACTION_AVAILABLE_QUESTS = 12

        private constant integer MMUI_SLIDER_QUERY_TIME = 1
        private constant integer MMUI_SLIDER_REST_TIME = 2
        private constant integer MMUI_SLIDER_COUNT = 2

        private boolean MMUI_Initialized = false
        private boolean MMUI_Syncing = false
        private boolean MMUI_HandlingSliderAction = false

        private framehandle MMUI_Parent = null
        private framehandle MMUI_Title = null
        private framehandle MMUI_LeftPane = null
        private framehandle MMUI_RightPane = null
        private framehandle MMUI_CloseButton = null
        private framehandle MMUI_ReturnButton = null
        private framehandle array MMUI_Button
        private framehandle array MMUI_Slider
        private framehandle array MMUI_SliderLabel
        private real array MMUI_SliderValueCache

        private trigger MMUI_CloseTrigger = null
        private trigger MMUI_ReturnTrigger = null
        private trigger MMUI_ButtonTrigger = null
        private trigger MMUI_SliderTrigger = null
        private trigger MMUI_ClearFocusTrigger = null
        private trigger MMUI_InitTrigger = null

        private Table MMUI_ButtonActionTable = 0
        private Table MMUI_SliderKind = 0
    endglobals

    private function MMUI_LoadToc takes nothing returns nothing
        call BlzLoadTOCFile(MMUI_TOC_PATH)
    endfunction

    private function MMUI_OnOff takes boolean flag returns string
        if flag then
            return "|cff80ff80On|r"
        endif
        return "|cffff8080Off|r"
    endfunction

    private function MMUI_Clamp takes real value, real minValue, real maxValue returns real
        if value < minValue then
            return minValue
        endif
        if value > maxValue then
            return maxValue
        endif
        return value
    endfunction

    private function MMUI_GetSecondaryFrequencyText takes nothing returns string
        local integer frequency = IconQuery_GetSecondaryCategoryFrequency()
        if frequency <= 1 then
            return "Every"
        elseif frequency == 2 then
            return "Every 2nd"
        elseif frequency == 3 then
            return "Every 3rd"
        endif
        return "Every " + I2S(frequency) + "th"
    endfunction

    private function MMUI_SetFrameVisible takes framehandle frame, boolean visible returns nothing
        if frame != null then
            call BlzFrameSetVisible(frame, visible)
        endif
    endfunction

    private function MMUI_GetSliderValue takes integer index returns real
        if index == 1 then
            return IconQuery_GetQueryTime()
        endif
        return IconQuery_GetQueryRestTime()
    endfunction

    private function MMUI_SyncSliderValue takes integer index, real value returns nothing
        if MMUI_Slider[index] == null then
            return
        endif
        if MMUI_SliderValueCache[index] != value then
            set MMUI_SliderValueCache[index] = value
            call BlzFrameSetValue(MMUI_Slider[index], value)
        endif
    endfunction

    private function MMUI_Refresh takes player whichPlayer returns nothing
        local real queryTime
        local real restTime

        if MMUI_Parent == null then
            return
        endif

        set MMUI_Syncing = true
        if GetLocalPlayer() == whichPlayer then
            set queryTime = IconQuery_GetQueryTime()
            set restTime = IconQuery_GetQueryRestTime()

            call BlzFrameSetText(MMUI_Button[1], "All Icons: " + MMUI_OnOff(IconQuery_GetAllEnabled()))
            call BlzFrameSetText(MMUI_Button[2], "Quest Givers: " + IconQuery_GetCategoryModeName(ICONQUERY_CATEGORY_QUEST_GIVERS))
            call BlzFrameSetText(MMUI_Button[3], "Flight/Ship: " + IconQuery_GetCategoryModeName(ICONQUERY_CATEGORY_FLIGHT_MASTER))
            call BlzFrameSetText(MMUI_Button[4], "Bosses: " + IconQuery_GetCategoryModeName(ICONQUERY_CATEGORY_BOSSES))
            call BlzFrameSetText(MMUI_Button[5], "Places: " + IconQuery_GetCategoryModeName(ICONQUERY_CATEGORY_PLACES_OF_INTEREST))
            call BlzFrameSetText(MMUI_Button[6], "Companions: " + IconQuery_GetCategoryModeName(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS))
            call BlzFrameSetText(MMUI_Button[8], "Travel/Boss/Place: " + MMUI_GetSecondaryFrequencyText())
            call BlzFrameSetText(MMUI_Button[9], "Pings: " + MMUI_OnOff(IconQuery_GetPingsEnabled()))
            call BlzFrameSetText(MMUI_Button[10], "Mode: " + IconQuery_GetDisplayModeName())
            call BlzFrameSetText(MMUI_Button[12], "Available Quests: " + MMUI_OnOff(IconQuery_GetAvailableQuestIconsEnabled()))

            call BlzFrameSetText(MMUI_SliderLabel[1], "Query: " + I2S(R2I(queryTime + 0.5)) + "s")
            call BlzFrameSetText(MMUI_SliderLabel[2], "Rest: " + I2S(R2I(restTime + 0.5)) + "s")
            call MMUI_SyncSliderValue(1, queryTime)
            call MMUI_SyncSliderValue(2, restTime)
        endif
        set MMUI_Syncing = false
    endfunction

    private function MMUI_HideInternal takes nothing returns nothing
        local integer i = 1
        if MMUI_Parent != null and BlzFrameIsVisible(MMUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        call MMUI_SetFrameVisible(MMUI_Parent, false)
        loop
            exitwhen i > MMUI_SLIDER_COUNT
            call MMUI_SetFrameVisible(MMUI_Slider[i], false)
            set i = i + 1
        endloop
    endfunction

    private function MMUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function MMUI_CloseAction takes nothing returns nothing
        call MMUI_HideInternal()
    endfunction

    private function MMUI_ReturnAction takes nothing returns nothing
        call MMUI_HideInternal()
        call ExecuteFunc("SettingsUI_Show")
    endfunction

    private function MMUI_CycleSecondaryFrequency takes nothing returns nothing
        local integer frequency = IconQuery_GetSecondaryCategoryFrequency() + 1
        if frequency > 3 then
            set frequency = 1
        endif
        call IconQuery_SetSecondaryCategoryFrequency(frequency)
    endfunction

    private function MMUI_ButtonClickAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer actionId = 0
        local player p = GetTriggerPlayer()

        if MMUI_ButtonActionTable.has(handleId) then
            set actionId = MMUI_ButtonActionTable.integer[handleId]
            if actionId == MMUI_ACTION_ALL then
                call IconQuery_SetAllEnabled(not IconQuery_GetAllEnabled())
            elseif actionId == MMUI_ACTION_QUEST_GIVERS then
                call IconQuery_CycleCategoryMode(ICONQUERY_CATEGORY_QUEST_GIVERS)
            elseif actionId == MMUI_ACTION_FLIGHT_MASTER then
                call IconQuery_CycleCategoryMode(ICONQUERY_CATEGORY_FLIGHT_MASTER)
            elseif actionId == MMUI_ACTION_BOSSES then
                call IconQuery_CycleCategoryMode(ICONQUERY_CATEGORY_BOSSES)
            elseif actionId == MMUI_ACTION_POI then
                call IconQuery_CycleCategoryMode(ICONQUERY_CATEGORY_PLACES_OF_INTEREST)
            elseif actionId == MMUI_ACTION_COMPANIONS then
                call IconQuery_CycleCategoryMode(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS)
            elseif actionId == MMUI_ACTION_SECONDARY_FREQUENCY then
                call MMUI_CycleSecondaryFrequency()
            elseif actionId == MMUI_ACTION_PINGS then
                call IconQuery_SetPingsEnabled(not IconQuery_GetPingsEnabled())
            elseif actionId == MMUI_ACTION_ICON_MODE then
                call IconQuery_CycleDisplayMode()
            elseif actionId == MMUI_ACTION_AVAILABLE_QUESTS then
                call IconQuery_SetAvailableQuestIconsEnabled(not IconQuery_GetAvailableQuestIconsEnabled())
            endif
            call MMUI_Refresh(p)
        endif

        set p = null
    endfunction

    private function MMUI_SliderAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer sliderKind
        local real value
        local player p = GetTriggerPlayer()

        if MMUI_Syncing or MMUI_HandlingSliderAction then
            set p = null
            return
        endif

        if MMUI_SliderKind.has(handleId) then
            set MMUI_HandlingSliderAction = true
            set sliderKind = MMUI_SliderKind.integer[handleId]
            set value = BlzGetTriggerFrameValue()
            if sliderKind == MMUI_SLIDER_QUERY_TIME then
                call IconQuery_SetQueryTime(MMUI_Clamp(value, MMUI_QUERY_TIME_MIN, MMUI_QUERY_TIME_MAX))
                set MMUI_SliderValueCache[1] = IconQuery_GetQueryTime()
            elseif sliderKind == MMUI_SLIDER_REST_TIME then
                call IconQuery_SetQueryRestTime(MMUI_Clamp(value, MMUI_QUERY_REST_MIN, MMUI_QUERY_REST_MAX))
                set MMUI_SliderValueCache[2] = IconQuery_GetQueryRestTime()
            endif
            call MMUI_Refresh(p)
            set MMUI_HandlingSliderAction = false
        endif

        set p = null
    endfunction

    private function MMUI_CreateButton takes integer index, string label, integer actionId, real x, real y returns nothing
        set MMUI_Button[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "MinimapSettingsUIButton" + I2S(index), MMUI_LeftPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(MMUI_Button[index], 0.150, 0.030)
        call BlzFrameSetPoint(MMUI_Button[index], FRAMEPOINT_TOPLEFT, MMUI_LeftPane, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameSetText(MMUI_Button[index], label)
        call BlzTriggerRegisterFrameEvent(MMUI_ButtonTrigger, MMUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(MMUI_ClearFocusTrigger, MMUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        set MMUI_ButtonActionTable.integer[GetHandleId(MMUI_Button[index])] = actionId
    endfunction

    private function MMUI_CreateRightButton takes integer index, string label, integer actionId, real y returns nothing
        set MMUI_Button[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "MinimapSettingsUIButton" + I2S(index), MMUI_RightPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(MMUI_Button[index], 0.220, 0.030)
        call BlzFrameSetPoint(MMUI_Button[index], FRAMEPOINT_TOPLEFT, MMUI_RightPane, FRAMEPOINT_TOPLEFT, 0.022, y)
        call BlzFrameSetText(MMUI_Button[index], label)
        call BlzTriggerRegisterFrameEvent(MMUI_ButtonTrigger, MMUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(MMUI_ClearFocusTrigger, MMUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        set MMUI_ButtonActionTable.integer[GetHandleId(MMUI_Button[index])] = actionId
    endfunction

    private function MMUI_CreateSliderRow takes integer index, string label, integer sliderKind, real y, real minValue, real maxValue, real stepSize returns nothing
        set MMUI_Slider[index] = BlzCreateFrame("EscMenuSliderTemplate", MMUI_Parent, 0, index + 20)
        call BlzFrameSetPoint(MMUI_Slider[index], FRAMEPOINT_TOPLEFT, MMUI_RightPane, FRAMEPOINT_TOPLEFT, 0.108, y)
        call BlzFrameSetSize(MMUI_Slider[index], 0.150, 0.018)
        call BlzFrameSetMinMaxValue(MMUI_Slider[index], minValue, maxValue)
        call BlzFrameSetStepSize(MMUI_Slider[index], stepSize)

        set MMUI_SliderLabel[index] = BlzCreateFrame("EscMenuLabelTextTemplate", MMUI_Slider[index], 0, 0)
        call BlzFrameSetPoint(MMUI_SliderLabel[index], FRAMEPOINT_RIGHT, MMUI_Slider[index], FRAMEPOINT_LEFT, -0.006, 0.0)
        call BlzFrameSetSize(MMUI_SliderLabel[index], 0.090, 0.016)
        call BlzFrameSetTextAlignment(MMUI_SliderLabel[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetText(MMUI_SliderLabel[index], label)

        set MMUI_SliderValueCache[index] = -1.00
        set MMUI_Syncing = true
        call MMUI_SyncSliderValue(index, MMUI_GetSliderValue(index))
        set MMUI_Syncing = false

        call BlzTriggerRegisterFrameEvent(MMUI_SliderTrigger, MMUI_Slider[index], FRAMEEVENT_SLIDER_VALUE_CHANGED)
        set MMUI_SliderKind.integer[GetHandleId(MMUI_Slider[index])] = sliderKind
        call BlzFrameSetVisible(MMUI_Slider[index], false)
    endfunction

    private function MMUI_CreateFrames takes nothing returns nothing
        set MMUI_Parent = BlzCreateFrameByType("BACKDROP", "MinimapSettingsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(MMUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
        call BlzFrameSetAbsPoint(MMUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.08)

        set MMUI_Title = BlzCreateFrameByType("TEXT", "MinimapSettingsUITitle", MMUI_Parent, "", 0)
        call BlzFrameSetPoint(MMUI_Title, FRAMEPOINT_TOPLEFT, MMUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(MMUI_Title, 0.30, 0.018)
        call BlzFrameSetTextAlignment(MMUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(MMUI_Title, 1.10)
        call BlzFrameSetEnable(MMUI_Title, false)
        call BlzFrameSetText(MMUI_Title, "|cffffe4a3Minimap Settings|r")

        set MMUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "MinimapSettingsUIClose", MMUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(MMUI_CloseButton, 0.03, 0.03)
        call BlzFrameSetText(MMUI_CloseButton, "X")
        call BlzFrameSetPoint(MMUI_CloseButton, FRAMEPOINT_TOPRIGHT, MMUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        call BlzTriggerRegisterFrameEvent(MMUI_CloseTrigger, MMUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(MMUI_ClearFocusTrigger, MMUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        set MMUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "MinimapSettingsUIReturn", MMUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(MMUI_ReturnButton, 0.065, 0.03)
        call BlzFrameSetText(MMUI_ReturnButton, "Return")
        call BlzFrameSetPoint(MMUI_ReturnButton, FRAMEPOINT_TOPRIGHT, MMUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
        call BlzTriggerRegisterFrameEvent(MMUI_ReturnTrigger, MMUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(MMUI_ClearFocusTrigger, MMUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

        set MMUI_LeftPane = BlzCreateFrameByType("BACKDROP", "MinimapSettingsUILeftPane", MMUI_Parent, "", 0)
        call BlzFrameSetTexture(MMUI_LeftPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
        call BlzFrameSetPoint(MMUI_LeftPane, FRAMEPOINT_TOPLEFT, MMUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.058)
        call BlzFrameSetPoint(MMUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, MMUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

        set MMUI_RightPane = BlzCreateFrameByType("BACKDROP", "MinimapSettingsUIRightPane", MMUI_Parent, "", 0)
        call BlzFrameSetTexture(MMUI_RightPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
        call BlzFrameSetPoint(MMUI_RightPane, FRAMEPOINT_TOPLEFT, MMUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
        call BlzFrameSetPoint(MMUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, MMUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

        call MMUI_CreateButton(1, "All Icons", MMUI_ACTION_ALL, 0.010, -0.016)
        call MMUI_CreateButton(2, "Quest Givers", MMUI_ACTION_QUEST_GIVERS, 0.010, -0.052)
        call MMUI_CreateButton(3, "Flight/Ship", MMUI_ACTION_FLIGHT_MASTER, 0.010, -0.088)
        call MMUI_CreateButton(4, "Bosses", MMUI_ACTION_BOSSES, 0.010, -0.124)
        call MMUI_CreateButton(5, "Places", MMUI_ACTION_POI, 0.010, -0.160)
        call MMUI_CreateButton(6, "Companions", MMUI_ACTION_COMPANIONS, 0.010, -0.196)
        call MMUI_CreateButton(12, "Available Quests", MMUI_ACTION_AVAILABLE_QUESTS, 0.010, -0.232)

        call MMUI_CreateSliderRow(1, "Query", MMUI_SLIDER_QUERY_TIME, -0.030, MMUI_QUERY_TIME_MIN, MMUI_QUERY_TIME_MAX, 1.0)
        call MMUI_CreateSliderRow(2, "Rest", MMUI_SLIDER_REST_TIME, -0.070, MMUI_QUERY_REST_MIN, MMUI_QUERY_REST_MAX, 5.0)
        call MMUI_CreateRightButton(8, "Travel/Boss/Place", MMUI_ACTION_SECONDARY_FREQUENCY, -0.120)
        call MMUI_CreateRightButton(9, "Pings", MMUI_ACTION_PINGS, -0.160)
        call MMUI_CreateRightButton(10, "Icon Mode", MMUI_ACTION_ICON_MODE, -0.200)

        call BlzFrameSetVisible(MMUI_Parent, false)
    endfunction

    private function MMUI_DelayedInit takes nothing returns nothing
        call MMUI_LoadToc()
        call MMUI_CreateFrames()
        call MMUI_Refresh(GetLocalPlayer())
    endfunction

    public function Init takes nothing returns nothing
        if MMUI_Initialized then
            return
        endif
        set MMUI_Initialized = true

        set MMUI_ButtonActionTable = Table.create()
        set MMUI_SliderKind = Table.create()

        set MMUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(MMUI_CloseTrigger, function MMUI_CloseAction)

        set MMUI_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(MMUI_ReturnTrigger, function MMUI_ReturnAction)

        set MMUI_ButtonTrigger = CreateTrigger()
        call TriggerAddAction(MMUI_ButtonTrigger, function MMUI_ButtonClickAction)

        set MMUI_SliderTrigger = CreateTrigger()
        call TriggerAddAction(MMUI_SliderTrigger, function MMUI_SliderAction)

        set MMUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(MMUI_ClearFocusTrigger, function MMUI_ClearFocusAction)

        set MMUI_InitTrigger = CreateTrigger()
        call TriggerRegisterTimerEvent(MMUI_InitTrigger, 0.20, false)
        call TriggerAddAction(MMUI_InitTrigger, function MMUI_DelayedInit)
    endfunction

    public function Hide takes nothing returns nothing
        call MMUI_HideInternal()
    endfunction

    public function Show takes nothing returns nothing
        local integer i = 1
        if not MMUI_Initialized then
            call Init()
        endif
        call MasterUI_Hide()
        call ExecuteFunc("SettingsUI_Hide")
        if MMUI_Parent != null then
            if not BlzFrameIsVisible(MMUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
            endif
            call BlzFrameSetVisible(MMUI_Parent, true)
        endif
        loop
            exitwhen i > MMUI_SLIDER_COUNT
            call MMUI_SetFrameVisible(MMUI_Slider[i], true)
            set i = i + 1
        endloop
        call MMUI_Refresh(GetLocalPlayer())
    endfunction

    public function Toggle takes nothing returns nothing
        if not MMUI_Initialized then
            call Init()
        endif
        if MMUI_Parent != null and BlzFrameIsVisible(MMUI_Parent) then
            call Hide()
        else
            call Show()
        endif
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
