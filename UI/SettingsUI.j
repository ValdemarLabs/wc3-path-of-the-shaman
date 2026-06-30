/**
    SettingsUI

    Author: Valdemar
    Version:

    Description:
    In-game settings panel for icon query timing, minimap marker categories,
    secondary marker scan frequency, map difficulty, and future settings placeholders.

    Credits:
    Tasyen (TasQuestBox as inspiration)

    How to install:
    Import after IconQuery and MasterUI. Open from the MasterUI Settings button.

    API:
    call SettingsUI_Show()
    call SettingsUI_Hide()
    call SettingsUI_GetMapDifficulty()

**/
library SettingsUI initializer AutoInit requires Table, MasterUI, IconQuery, Difficulty
    globals
        // UI-limited settings ranges. IconQuery also clamps internally.
        private constant string SETUI_TOC_PATH = "war3mapimported\\templates.toc"
        private constant real SETUI_QUERY_TIME_MIN = 1.00
        private constant real SETUI_QUERY_TIME_MAX = 15.00
        private constant real SETUI_QUERY_REST_MIN = 5.00
        private constant real SETUI_QUERY_REST_MAX = 120.00

        private constant integer SETUI_ACTION_ALL = 1
        private constant integer SETUI_ACTION_QUEST_GIVERS = 2
        private constant integer SETUI_ACTION_FLIGHT_MASTER = 3
        private constant integer SETUI_ACTION_BOSSES = 4
        private constant integer SETUI_ACTION_POI = 5
        private constant integer SETUI_ACTION_COMPANIONS = 6
        private constant integer SETUI_ACTION_DIFFICULTY = 7
        private constant integer SETUI_ACTION_SECONDARY_FREQUENCY = 8
        private constant integer SETUI_ACTION_PLACEHOLDER_2 = 9

        private constant integer SETUI_SLIDER_QUERY_TIME = 1
        private constant integer SETUI_SLIDER_REST_TIME = 2

        constant integer SETTINGSUI_MAP_DIFFICULTY_STORY = 1
        constant integer SETTINGSUI_MAP_DIFFICULTY_NORMAL = 2
        constant integer SETTINGSUI_MAP_DIFFICULTY_HARD = 3

        private boolean SETUI_Initialized = false
        private boolean SETUI_Syncing = false
        private boolean SETUI_HandlingSliderAction = false
        private integer SETUI_MapDifficulty = SETTINGSUI_MAP_DIFFICULTY_NORMAL

        private framehandle SETUI_Parent = null
        private framehandle SETUI_Title = null
        private framehandle SETUI_LeftPane = null
        private framehandle SETUI_RightPane = null
        private framehandle SETUI_CloseButton = null
        private framehandle SETUI_ReturnButton = null
        private framehandle array SETUI_Button
        private framehandle array SETUI_Slider
        private framehandle array SETUI_SliderLabel
        private real array SETUI_SliderValueCache

        private trigger SETUI_CloseTrigger = null
        private trigger SETUI_ReturnTrigger = null
        private trigger SETUI_ButtonTrigger = null
        private trigger SETUI_SliderTrigger = null
        private trigger SETUI_ClearFocusTrigger = null
        private trigger SETUI_InitTrigger = null

        private Table SETUI_ButtonActionTable = 0
        private Table SETUI_SliderKind = 0
    endglobals

    private function SETUI_LoadToc takes nothing returns nothing
        call BlzLoadTOCFile(SETUI_TOC_PATH)
    endfunction

    private function SETUI_OnOff takes boolean flag returns string
        if flag then
            return "|cff80ff80On|r"
        endif
        return "|cffff8080Off|r"
    endfunction

    private function SETUI_Clamp takes real value, real minValue, real maxValue returns real
        if value < minValue then
            return minValue
        endif
        if value > maxValue then
            return maxValue
        endif
        return value
    endfunction

    private function SETUI_GetDifficultyName takes nothing returns string
        if SETUI_MapDifficulty == SETTINGSUI_MAP_DIFFICULTY_STORY then
            return "Story"
        elseif SETUI_MapDifficulty == SETTINGSUI_MAP_DIFFICULTY_HARD then
            return "Hard"
        endif
        return "Normal"
    endfunction

    private function SETUI_GetSecondaryFrequencyText takes nothing returns string
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

    private function SETUI_SetFrameVisible takes framehandle frame, boolean visible returns nothing
        if frame != null then
            call BlzFrameSetVisible(frame, visible)
        endif
    endfunction

    private function SETUI_GetSliderValue takes integer index returns real
        if index == 1 then
            return IconQuery_GetQueryTime()
        endif
        return IconQuery_GetQueryRestTime()
    endfunction

    private function SETUI_SyncSliderValue takes integer index, real value returns nothing
        if SETUI_Slider[index] == null then
            return
        endif
        if SETUI_SliderValueCache[index] != value then
            set SETUI_SliderValueCache[index] = value
            call BlzFrameSetValue(SETUI_Slider[index], value)
        endif
    endfunction

    private function SETUI_Refresh takes player whichPlayer returns nothing
        local real queryTime
        local real restTime

        if SETUI_Parent == null then
            return
        endif

        set SETUI_Syncing = true
        if GetLocalPlayer() == whichPlayer then
            set SETUI_MapDifficulty = Difficulty_GetDifficulty()
            set queryTime = IconQuery_GetQueryTime()
            set restTime = IconQuery_GetQueryRestTime()

            call BlzFrameSetText(SETUI_Button[1], "All Icons: " + SETUI_OnOff(IconQuery_GetAllEnabled()))
            call BlzFrameSetText(SETUI_Button[2], "Quest Givers: " + SETUI_OnOff(IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_QUEST_GIVERS)))
            call BlzFrameSetText(SETUI_Button[3], "Flight/Ship: " + SETUI_OnOff(IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_FLIGHT_MASTER)))
            call BlzFrameSetText(SETUI_Button[4], "Bosses: " + SETUI_OnOff(IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_BOSSES)))
            call BlzFrameSetText(SETUI_Button[5], "Places: " + SETUI_OnOff(IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_PLACES_OF_INTEREST)))
            call BlzFrameSetText(SETUI_Button[6], "Companions: " + SETUI_OnOff(IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS)))
            call BlzFrameSetText(SETUI_Button[7], "Difficulty: " + SETUI_GetDifficultyName())
            call BlzFrameSetText(SETUI_Button[8], "Other Icons: " + SETUI_GetSecondaryFrequencyText())
            call BlzFrameSetText(SETUI_Button[9], "Future Setting")

            call BlzFrameSetText(SETUI_SliderLabel[1], "Query: " + I2S(R2I(queryTime + 0.5)) + "s")
            call BlzFrameSetText(SETUI_SliderLabel[2], "Rest: " + I2S(R2I(restTime + 0.5)) + "s")
            call SETUI_SyncSliderValue(1, queryTime)
            call SETUI_SyncSliderValue(2, restTime)
        endif
        set SETUI_Syncing = false
    endfunction

    private function SETUI_HideInternal takes nothing returns nothing
        local integer i = 1
        call SETUI_SetFrameVisible(SETUI_Parent, false)
        loop
            exitwhen i > 2
            call SETUI_SetFrameVisible(SETUI_Slider[i], false)
            set i = i + 1
        endloop
    endfunction

    private function SETUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function SETUI_CloseAction takes nothing returns nothing
        call SETUI_HideInternal()
    endfunction

    private function SETUI_ReturnAction takes nothing returns nothing
        call SETUI_HideInternal()
        call MasterUI_Show()
    endfunction

    private function SETUI_CycleDifficulty takes nothing returns nothing
        set SETUI_MapDifficulty = SETUI_MapDifficulty + 1
        if SETUI_MapDifficulty > SETTINGSUI_MAP_DIFFICULTY_HARD then
            set SETUI_MapDifficulty = SETTINGSUI_MAP_DIFFICULTY_STORY
        endif
        call Difficulty_SetDifficulty(SETUI_MapDifficulty)
    endfunction

    private function SETUI_CycleSecondaryFrequency takes nothing returns nothing
        local integer frequency = IconQuery_GetSecondaryCategoryFrequency() + 1
        if frequency > 3 then
            set frequency = 1
        endif
        call IconQuery_SetSecondaryCategoryFrequency(frequency)
    endfunction

    private function SETUI_ButtonClickAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer actionId = 0
        local player p = GetTriggerPlayer()

        if SETUI_ButtonActionTable.has(handleId) then
            set actionId = SETUI_ButtonActionTable.integer[handleId]
            if actionId == SETUI_ACTION_ALL then
                call IconQuery_SetAllEnabled(not IconQuery_GetAllEnabled())
            elseif actionId == SETUI_ACTION_QUEST_GIVERS then
                call IconQuery_SetCategoryEnabled(ICONQUERY_CATEGORY_QUEST_GIVERS, not IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_QUEST_GIVERS))
            elseif actionId == SETUI_ACTION_FLIGHT_MASTER then
                call IconQuery_SetCategoryEnabled(ICONQUERY_CATEGORY_FLIGHT_MASTER, not IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_FLIGHT_MASTER))
            elseif actionId == SETUI_ACTION_BOSSES then
                call IconQuery_SetCategoryEnabled(ICONQUERY_CATEGORY_BOSSES, not IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_BOSSES))
            elseif actionId == SETUI_ACTION_POI then
                call IconQuery_SetCategoryEnabled(ICONQUERY_CATEGORY_PLACES_OF_INTEREST, not IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_PLACES_OF_INTEREST))
            elseif actionId == SETUI_ACTION_COMPANIONS then
                call IconQuery_SetCategoryEnabled(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS, not IconQuery_IsCategoryEnabled(ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS))
            elseif actionId == SETUI_ACTION_DIFFICULTY then
                call SETUI_CycleDifficulty()
            elseif actionId == SETUI_ACTION_SECONDARY_FREQUENCY then
                call SETUI_CycleSecondaryFrequency()
            elseif actionId == SETUI_ACTION_PLACEHOLDER_2 then
                call DisplayTextToPlayer(p, 0.0, 0.0, "|cffffcc00Settings|r option reserved for a future system.")
            endif
            call SETUI_Refresh(p)
        endif

        set p = null
    endfunction

    private function SETUI_SliderAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer sliderKind
        local real value
        local player p = GetTriggerPlayer()

        if SETUI_Syncing or SETUI_HandlingSliderAction then
            set p = null
            return
        endif

        if SETUI_SliderKind.has(handleId) then
            set SETUI_HandlingSliderAction = true
            set sliderKind = SETUI_SliderKind.integer[handleId]
            set value = BlzGetTriggerFrameValue()
            if sliderKind == SETUI_SLIDER_QUERY_TIME then
                call IconQuery_SetQueryTime(SETUI_Clamp(value, SETUI_QUERY_TIME_MIN, SETUI_QUERY_TIME_MAX))
                set SETUI_SliderValueCache[1] = IconQuery_GetQueryTime()
            elseif sliderKind == SETUI_SLIDER_REST_TIME then
                call IconQuery_SetQueryRestTime(SETUI_Clamp(value, SETUI_QUERY_REST_MIN, SETUI_QUERY_REST_MAX))
                set SETUI_SliderValueCache[2] = IconQuery_GetQueryRestTime()
            endif
            call SETUI_Refresh(p)
            set SETUI_HandlingSliderAction = false
        endif

        set p = null
    endfunction

    private function SETUI_CreateButton takes integer index, string label, integer actionId, real x, real y returns nothing
        set SETUI_Button[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIButton" + I2S(index), SETUI_LeftPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SETUI_Button[index], 0.145, 0.030)
        call BlzFrameSetPoint(SETUI_Button[index], FRAMEPOINT_TOPLEFT, SETUI_LeftPane, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameSetText(SETUI_Button[index], label)
        call BlzTriggerRegisterFrameEvent(SETUI_ButtonTrigger, SETUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SETUI_ClearFocusTrigger, SETUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        set SETUI_ButtonActionTable.integer[GetHandleId(SETUI_Button[index])] = actionId
    endfunction

    private function SETUI_CreateRightButton takes integer index, string label, integer actionId, real y returns nothing
        set SETUI_Button[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIButton" + I2S(index), SETUI_RightPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SETUI_Button[index], 0.150, 0.030)
        call BlzFrameSetPoint(SETUI_Button[index], FRAMEPOINT_TOPLEFT, SETUI_RightPane, FRAMEPOINT_TOPLEFT, 0.022, y)
        call BlzFrameSetText(SETUI_Button[index], label)
        call BlzTriggerRegisterFrameEvent(SETUI_ButtonTrigger, SETUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SETUI_ClearFocusTrigger, SETUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        set SETUI_ButtonActionTable.integer[GetHandleId(SETUI_Button[index])] = actionId
    endfunction

    private function SETUI_CreateSliderRow takes integer index, string label, integer sliderKind, real y, real minValue, real maxValue, real stepSize returns nothing
        set SETUI_Slider[index] = BlzCreateFrame("EscMenuSliderTemplate", SETUI_Parent, 0, index + 20)
        call BlzFrameSetPoint(SETUI_Slider[index], FRAMEPOINT_TOPLEFT, SETUI_RightPane, FRAMEPOINT_TOPLEFT, 0.108, y)
        call BlzFrameSetSize(SETUI_Slider[index], 0.150, 0.018)
        call BlzFrameSetMinMaxValue(SETUI_Slider[index], minValue, maxValue)
        call BlzFrameSetStepSize(SETUI_Slider[index], stepSize)

        set SETUI_SliderLabel[index] = BlzCreateFrame("EscMenuLabelTextTemplate", SETUI_Slider[index], 0, 0)
        call BlzFrameSetPoint(SETUI_SliderLabel[index], FRAMEPOINT_RIGHT, SETUI_Slider[index], FRAMEPOINT_LEFT, -0.006, 0.0)
        call BlzFrameSetSize(SETUI_SliderLabel[index], 0.090, 0.016)
        call BlzFrameSetTextAlignment(SETUI_SliderLabel[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetText(SETUI_SliderLabel[index], label)

        set SETUI_SliderValueCache[index] = -1.00
        set SETUI_Syncing = true
        call SETUI_SyncSliderValue(index, SETUI_GetSliderValue(index))
        set SETUI_Syncing = false

        call BlzTriggerRegisterFrameEvent(SETUI_SliderTrigger, SETUI_Slider[index], FRAMEEVENT_SLIDER_VALUE_CHANGED)
        set SETUI_SliderKind.integer[GetHandleId(SETUI_Slider[index])] = sliderKind
        call BlzFrameSetVisible(SETUI_Slider[index], false)
    endfunction

    private function SETUI_CreateFrames takes nothing returns nothing
        set SETUI_Parent = BlzCreateFrameByType("BACKDROP", "SettingsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(SETUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
        call BlzFrameSetAbsPoint(SETUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.18)

        set SETUI_Title = BlzCreateFrameByType("TEXT", "SettingsUITitle", SETUI_Parent, "", 0)
        call BlzFrameSetPoint(SETUI_Title, FRAMEPOINT_TOPLEFT, SETUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(SETUI_Title, 0.30, 0.018)
        call BlzFrameSetTextAlignment(SETUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SETUI_Title, 1.10)
        call BlzFrameSetEnable(SETUI_Title, false)
        call BlzFrameSetText(SETUI_Title, "|cffffe4a3Settings|r")

        set SETUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIClose", SETUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SETUI_CloseButton, 0.03, 0.03)
        call BlzFrameSetText(SETUI_CloseButton, "X")
        call BlzFrameSetPoint(SETUI_CloseButton, FRAMEPOINT_TOPRIGHT, SETUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        call BlzTriggerRegisterFrameEvent(SETUI_CloseTrigger, SETUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SETUI_ClearFocusTrigger, SETUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        set SETUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIReturn", SETUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SETUI_ReturnButton, 0.065, 0.03)
        call BlzFrameSetText(SETUI_ReturnButton, "Return")
        call BlzFrameSetPoint(SETUI_ReturnButton, FRAMEPOINT_TOPRIGHT, SETUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
        call BlzTriggerRegisterFrameEvent(SETUI_ReturnTrigger, SETUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SETUI_ClearFocusTrigger, SETUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

        set SETUI_LeftPane = BlzCreateFrameByType("BACKDROP", "SettingsUILeftPane", SETUI_Parent, "", 0)
        call BlzFrameSetTexture(SETUI_LeftPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
        call BlzFrameSetPoint(SETUI_LeftPane, FRAMEPOINT_TOPLEFT, SETUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.058)
        call BlzFrameSetPoint(SETUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, SETUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.182, 0.014)

        set SETUI_RightPane = BlzCreateFrameByType("BACKDROP", "SettingsUIRightPane", SETUI_Parent, "", 0)
        call BlzFrameSetTexture(SETUI_RightPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
        call BlzFrameSetPoint(SETUI_RightPane, FRAMEPOINT_TOPLEFT, SETUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.012, 0.0)
        call BlzFrameSetPoint(SETUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, SETUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

        call SETUI_CreateButton(1, "All Icons", SETUI_ACTION_ALL, 0.010, -0.016)
        call SETUI_CreateButton(2, "Quest Givers", SETUI_ACTION_QUEST_GIVERS, 0.010, -0.052)
        call SETUI_CreateButton(3, "Flight/Ship", SETUI_ACTION_FLIGHT_MASTER, 0.010, -0.088)
        call SETUI_CreateButton(4, "Bosses", SETUI_ACTION_BOSSES, 0.010, -0.124)
        call SETUI_CreateButton(5, "Places", SETUI_ACTION_POI, 0.010, -0.160)
        call SETUI_CreateButton(6, "Companions", SETUI_ACTION_COMPANIONS, 0.010, -0.196)

        call SETUI_CreateSliderRow(1, "Query", SETUI_SLIDER_QUERY_TIME, -0.030, SETUI_QUERY_TIME_MIN, SETUI_QUERY_TIME_MAX, 1.0)
        call SETUI_CreateSliderRow(2, "Rest", SETUI_SLIDER_REST_TIME, -0.070, SETUI_QUERY_REST_MIN, SETUI_QUERY_REST_MAX, 5.0)
        call SETUI_CreateRightButton(7, "Difficulty", SETUI_ACTION_DIFFICULTY, -0.120)
        call SETUI_CreateRightButton(8, "Other Icons", SETUI_ACTION_SECONDARY_FREQUENCY, -0.160)
        call SETUI_CreateRightButton(9, "Future Setting", SETUI_ACTION_PLACEHOLDER_2, -0.200)

        call BlzFrameSetVisible(SETUI_Parent, false)
    endfunction

    private function SETUI_DelayedInit takes nothing returns nothing
        call SETUI_LoadToc()
        call SETUI_CreateFrames()
        call SETUI_Refresh(GetLocalPlayer())
    endfunction

    public function Init takes nothing returns nothing
        if SETUI_Initialized then
            return
        endif
        set SETUI_Initialized = true

        set SETUI_ButtonActionTable = Table.create()
        set SETUI_SliderKind = Table.create()
        call Difficulty_SetDifficulty(SETUI_MapDifficulty)

        set SETUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(SETUI_CloseTrigger, function SETUI_CloseAction)

        set SETUI_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(SETUI_ReturnTrigger, function SETUI_ReturnAction)

        set SETUI_ButtonTrigger = CreateTrigger()
        call TriggerAddAction(SETUI_ButtonTrigger, function SETUI_ButtonClickAction)

        set SETUI_SliderTrigger = CreateTrigger()
        call TriggerAddAction(SETUI_SliderTrigger, function SETUI_SliderAction)

        set SETUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(SETUI_ClearFocusTrigger, function SETUI_ClearFocusAction)

        set SETUI_InitTrigger = CreateTrigger()
        call TriggerRegisterTimerEvent(SETUI_InitTrigger, 0.20, false)
        call TriggerAddAction(SETUI_InitTrigger, function SETUI_DelayedInit)
    endfunction

    public function Hide takes nothing returns nothing
        call SETUI_HideInternal()
    endfunction

    public function Show takes nothing returns nothing
        local integer i = 1
        if not SETUI_Initialized then
            call Init()
        endif
        if SETUI_Parent != null then
            call BlzFrameSetVisible(SETUI_Parent, true)
        endif
        loop
            exitwhen i > 2
            call SETUI_SetFrameVisible(SETUI_Slider[i], true)
            set i = i + 1
        endloop
        call SETUI_Refresh(GetLocalPlayer())
    endfunction

    public function Toggle takes nothing returns nothing
        if not SETUI_Initialized then
            call Init()
        endif
        if SETUI_Parent != null and BlzFrameIsVisible(SETUI_Parent) then
            call Hide()
        else
            call Show()
        endif
    endfunction

    public function GetMapDifficulty takes nothing returns integer
        return SETUI_MapDifficulty
    endfunction

    public function SetMapDifficulty takes integer difficulty returns nothing
        if difficulty < SETTINGSUI_MAP_DIFFICULTY_STORY then
            set difficulty = SETTINGSUI_MAP_DIFFICULTY_STORY
        elseif difficulty > SETTINGSUI_MAP_DIFFICULTY_HARD then
            set difficulty = SETTINGSUI_MAP_DIFFICULTY_HARD
        endif
        set SETUI_MapDifficulty = difficulty
        call Difficulty_SetDifficulty(SETUI_MapDifficulty)
        call SETUI_Refresh(GetLocalPlayer())
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
