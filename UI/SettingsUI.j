/**
    SettingsUI

    Author: Valdemar
    Version: 1.0.0

    Description:
    In-game map and performance settings for difficulty, UI sounds, AI unit
    cap, DynamicFarZ profile, DoodadRender, and WeatherSystem detail. Minimap
    and IconQuery controls are opened in MinimapSettingsUI.

    Credits:
    Tasyen (TasQuestBox as inspiration)

    How to install:
    Import after MinimapSettingsUI, Difficulty, AI, Interface, DynamicFarZ,
    CameraControl, and Table. DoodadRender and WeatherSystem are optional.

    API:
    call SettingsUI_Show()
    call SettingsUI_Hide()
    call SettingsUI_Toggle()
    call SettingsUI_GetMapDifficulty()
    call SettingsUI_SetMapDifficulty(difficulty)

**/
library SettingsUI initializer AutoInit requires Table, MasterUI, MinimapSettingsUI, Difficulty, AI, Interface, DynamicFarZ, CameraControl, optional DoodadRender, optional WeatherSystem
    globals
        constant integer SETTINGSUI_MAP_DIFFICULTY_STORY = DIFFICULTY_STORY
        constant integer SETTINGSUI_MAP_DIFFICULTY_NORMAL = DIFFICULTY_NORMAL
        constant integer SETTINGSUI_MAP_DIFFICULTY_HARD = DIFFICULTY_HARD

        private constant string PSETUI_TOC_PATH = "war3mapimported\\templates.toc"
        private constant real PSETUI_AI_ACTIVE_CAP_MIN = 1.00
        private constant real PSETUI_AI_ACTIVE_CAP_MAX = 32.00

        private constant integer PSETUI_ACTION_MINIMAP = 1
        private constant integer PSETUI_ACTION_DIFFICULTY = 2
        private constant integer PSETUI_ACTION_UI_SOUNDS = 3
        private constant integer PSETUI_ACTION_FARZ_PROFILE = 4
        private constant integer PSETUI_ACTION_DOODAD_RENDER = 5
        private constant integer PSETUI_ACTION_WEATHER_DETAIL = 6

        private boolean PSETUI_Initialized = false
        private boolean PSETUI_Syncing = false
        private boolean PSETUI_HandlingSliderAction = false
        private integer PSETUI_MapDifficulty = SETTINGSUI_MAP_DIFFICULTY_NORMAL
        private real PSETUI_SliderValueCache = -1.00

        private framehandle PSETUI_Parent = null
        private framehandle PSETUI_Title = null
        private framehandle PSETUI_LeftPane = null
        private framehandle PSETUI_RightPane = null
        private framehandle PSETUI_CloseButton = null
        private framehandle PSETUI_ReturnButton = null
        private framehandle PSETUI_AISlider = null
        private framehandle PSETUI_AISliderLabel = null
        private framehandle PSETUI_AIDisclaimer = null
        private framehandle array PSETUI_Button

        private trigger PSETUI_CloseTrigger = null
        private trigger PSETUI_ReturnTrigger = null
        private trigger PSETUI_ButtonTrigger = null
        private trigger PSETUI_SliderTrigger = null
        private trigger PSETUI_ClearFocusTrigger = null
        private trigger PSETUI_InitTrigger = null

        private Table PSETUI_ButtonActionTable = 0
    endglobals

    private function PSETUI_LoadToc takes nothing returns nothing
        call BlzLoadTOCFile(PSETUI_TOC_PATH)
    endfunction

    private function PSETUI_OnOff takes boolean flag returns string
        if flag then
            return "|cff80ff80On|r"
        endif
        return "|cffff8080Off|r"
    endfunction

    private function PSETUI_Clamp takes real value, real minValue, real maxValue returns real
        if value < minValue then
            return minValue
        endif
        if value > maxValue then
            return maxValue
        endif
        return value
    endfunction

    private function PSETUI_GetDifficultyName takes nothing returns string
        if PSETUI_MapDifficulty == SETTINGSUI_MAP_DIFFICULTY_STORY then
            return "Story"
        elseif PSETUI_MapDifficulty == SETTINGSUI_MAP_DIFFICULTY_HARD then
            return "Hard"
        endif
        return "Normal"
    endfunction

    private function PSETUI_SetSliderVisible takes boolean visible returns nothing
        if PSETUI_AISlider != null then
            call BlzFrameSetVisible(PSETUI_AISlider, visible)
        endif
    endfunction

    private function PSETUI_SyncSliderValue takes real value returns nothing
        if PSETUI_AISlider != null and PSETUI_SliderValueCache != value then
            set PSETUI_SliderValueCache = value
            call BlzFrameSetValue(PSETUI_AISlider, value)
        endif
    endfunction

    private function PSETUI_Refresh takes player whichPlayer returns nothing
        local integer aiActiveCap

        if PSETUI_Parent == null then
            return
        endif

        set PSETUI_Syncing = true
        if GetLocalPlayer() == whichPlayer then
            set PSETUI_MapDifficulty = Difficulty_GetDifficulty()
            set aiActiveCap = AI_GetRandomSpawnActiveCap()
            call BlzFrameSetText(PSETUI_Button[2], "Difficulty: " + PSETUI_GetDifficultyName())
            call BlzFrameSetText(PSETUI_Button[3], "UI Sounds: " + PSETUI_OnOff(Interface_AreSoundsEnabled()))
            call BlzFrameSetText(PSETUI_Button[4], "Far Z Profile: " + DynamicFarZ_GetProfileName(whichPlayer))
            static if LIBRARY_DoodadRender then
                call BlzFrameSetText(PSETUI_Button[5], "Doodad Culling: " + PSETUI_OnOff(DoodadRender_IsEnabled()))
            else
                call BlzFrameSetText(PSETUI_Button[5], "Doodad Culling: Unavailable")
            endif
            static if LIBRARY_WeatherSystem then
                if WeatherSystem_IsFPSOptimizationEnabled() then
                    call BlzFrameSetText(PSETUI_Button[6], "Weather Detail: Reduced")
                else
                    call BlzFrameSetText(PSETUI_Button[6], "Weather Detail: Full")
                endif
            else
                call BlzFrameSetText(PSETUI_Button[6], "Weather Detail: Unavailable")
            endif
            call BlzFrameSetText(PSETUI_AISliderLabel, "AI Units Cap: " + I2S(aiActiveCap))
            call PSETUI_SyncSliderValue(I2R(aiActiveCap))
        endif
        set PSETUI_Syncing = false
    endfunction

    private function PSETUI_HideInternal takes nothing returns nothing
        if PSETUI_Parent != null and BlzFrameIsVisible(PSETUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        if PSETUI_Parent != null then
            call BlzFrameSetVisible(PSETUI_Parent, false)
        endif
        call PSETUI_SetSliderVisible(false)
    endfunction

    private function PSETUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function PSETUI_CloseAction takes nothing returns nothing
        call PSETUI_HideInternal()
    endfunction

    private function PSETUI_ReturnAction takes nothing returns nothing
        call PSETUI_HideInternal()
        call MasterUI_Show()
    endfunction

    private function PSETUI_CycleDifficulty takes nothing returns nothing
        set PSETUI_MapDifficulty = PSETUI_MapDifficulty + 1
        if PSETUI_MapDifficulty > SETTINGSUI_MAP_DIFFICULTY_HARD then
            set PSETUI_MapDifficulty = SETTINGSUI_MAP_DIFFICULTY_STORY
        endif
        call Difficulty_SetDifficulty(PSETUI_MapDifficulty)
    endfunction

    private function PSETUI_OpenMinimapSettings takes nothing returns nothing
        call PSETUI_HideInternal()
        call MinimapSettingsUI_Show()
    endfunction

    private function PSETUI_ButtonAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer actionId = 0
        local player whichPlayer = GetTriggerPlayer()

        if PSETUI_ButtonActionTable.has(handleId) then
            set actionId = PSETUI_ButtonActionTable.integer[handleId]
            if actionId == PSETUI_ACTION_MINIMAP then
                call PSETUI_OpenMinimapSettings()
            elseif actionId == PSETUI_ACTION_DIFFICULTY then
                call PSETUI_CycleDifficulty()
            elseif actionId == PSETUI_ACTION_UI_SOUNDS then
                call Interface_SetSoundsEnabled(not Interface_AreSoundsEnabled())
            elseif actionId == PSETUI_ACTION_FARZ_PROFILE then
                call DynamicFarZ_CycleProfile(whichPlayer)
                call CameraControl_RefreshFarZ(whichPlayer)
            elseif actionId == PSETUI_ACTION_DOODAD_RENDER then
                static if LIBRARY_DoodadRender then
                    if DoodadRender_IsEnabled() then
                        call DoodadRender_Disable()
                    else
                        call DoodadRender_Enable()
                    endif
                endif
            elseif actionId == PSETUI_ACTION_WEATHER_DETAIL then
                static if LIBRARY_WeatherSystem then
                    call WeatherSystem_SetFPSOptimization(not WeatherSystem_IsFPSOptimizationEnabled())
                endif
            endif
            if actionId != PSETUI_ACTION_MINIMAP then
                call PSETUI_Refresh(whichPlayer)
            endif
        endif

        set whichPlayer = null
    endfunction

    private function PSETUI_SliderAction takes nothing returns nothing
        local real value
        local player whichPlayer = GetTriggerPlayer()

        if PSETUI_Syncing or PSETUI_HandlingSliderAction then
            set whichPlayer = null
            return
        endif

        set PSETUI_HandlingSliderAction = true
        set value = PSETUI_Clamp(BlzGetTriggerFrameValue(), PSETUI_AI_ACTIVE_CAP_MIN, PSETUI_AI_ACTIVE_CAP_MAX)
        call AI_SetRandomSpawnActiveCap(R2I(value + 0.5))
        set PSETUI_SliderValueCache = I2R(AI_GetRandomSpawnActiveCap())
        call PSETUI_Refresh(whichPlayer)
        set PSETUI_HandlingSliderAction = false
        set whichPlayer = null
    endfunction

    private function PSETUI_CreateButton takes integer index, string label, integer actionId, framehandle parent, real y returns nothing
        set PSETUI_Button[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIButton" + I2S(index), parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(PSETUI_Button[index], 0.205, 0.032)
        call BlzFrameSetPoint(PSETUI_Button[index], FRAMEPOINT_TOPLEFT, parent, FRAMEPOINT_TOPLEFT, 0.018, y)
        call BlzFrameSetText(PSETUI_Button[index], label)
        call BlzTriggerRegisterFrameEvent(PSETUI_ButtonTrigger, PSETUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PSETUI_ClearFocusTrigger, PSETUI_Button[index], FRAMEEVENT_CONTROL_CLICK)
        set PSETUI_ButtonActionTable.integer[GetHandleId(PSETUI_Button[index])] = actionId
    endfunction

    private function PSETUI_CreateFrames takes nothing returns nothing
        set PSETUI_Parent = BlzCreateFrameByType("BACKDROP", "SettingsUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(PSETUI_Parent, FRAMEPOINT_TOPLEFT, 0.11, 0.55)
        call BlzFrameSetAbsPoint(PSETUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.61, 0.20)

        set PSETUI_Title = BlzCreateFrameByType("TEXT", "SettingsUITitle", PSETUI_Parent, "", 0)
        call BlzFrameSetPoint(PSETUI_Title, FRAMEPOINT_TOPLEFT, PSETUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(PSETUI_Title, 0.30, 0.018)
        call BlzFrameSetTextAlignment(PSETUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(PSETUI_Title, 1.10)
        call BlzFrameSetEnable(PSETUI_Title, false)
        call BlzFrameSetText(PSETUI_Title, "|cffffe4a3Settings|r")

        set PSETUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIClose", PSETUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(PSETUI_CloseButton, 0.030, 0.030)
        call BlzFrameSetText(PSETUI_CloseButton, "X")
        call BlzFrameSetPoint(PSETUI_CloseButton, FRAMEPOINT_TOPRIGHT, PSETUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        call BlzTriggerRegisterFrameEvent(PSETUI_CloseTrigger, PSETUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PSETUI_ClearFocusTrigger, PSETUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        set PSETUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "SettingsUIReturn", PSETUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(PSETUI_ReturnButton, 0.065, 0.030)
        call BlzFrameSetText(PSETUI_ReturnButton, "Return")
        call BlzFrameSetPoint(PSETUI_ReturnButton, FRAMEPOINT_TOPRIGHT, PSETUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
        call BlzTriggerRegisterFrameEvent(PSETUI_ReturnTrigger, PSETUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PSETUI_ClearFocusTrigger, PSETUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

        set PSETUI_LeftPane = BlzCreateFrameByType("BACKDROP", "SettingsUILeftPane", PSETUI_Parent, "", 0)
        call BlzFrameSetTexture(PSETUI_LeftPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
        call BlzFrameSetPoint(PSETUI_LeftPane, FRAMEPOINT_TOPLEFT, PSETUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.058)
        call BlzFrameSetPoint(PSETUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, PSETUI_Parent, FRAMEPOINT_BOTTOM, -0.006, 0.014)

        set PSETUI_RightPane = BlzCreateFrameByType("BACKDROP", "SettingsUIRightPane", PSETUI_Parent, "", 0)
        call BlzFrameSetTexture(PSETUI_RightPane, "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", 0, true)
        call BlzFrameSetPoint(PSETUI_RightPane, FRAMEPOINT_TOPLEFT, PSETUI_Parent, FRAMEPOINT_TOP, 0.006, -0.058)
        call BlzFrameSetPoint(PSETUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, PSETUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

        call PSETUI_CreateButton(1, "Minimap Settings", PSETUI_ACTION_MINIMAP, PSETUI_LeftPane, -0.024)
        call PSETUI_CreateButton(2, "Difficulty", PSETUI_ACTION_DIFFICULTY, PSETUI_LeftPane, -0.070)
        call PSETUI_CreateButton(3, "UI Sounds", PSETUI_ACTION_UI_SOUNDS, PSETUI_LeftPane, -0.116)
        call PSETUI_CreateButton(4, "Far Z Profile", PSETUI_ACTION_FARZ_PROFILE, PSETUI_RightPane, -0.024)
        call PSETUI_CreateButton(5, "Doodad Culling", PSETUI_ACTION_DOODAD_RENDER, PSETUI_RightPane, -0.070)
        call PSETUI_CreateButton(6, "Weather Detail", PSETUI_ACTION_WEATHER_DETAIL, PSETUI_RightPane, -0.116)

        set PSETUI_AISlider = BlzCreateFrame("EscMenuSliderTemplate", PSETUI_Parent, 0, 31)
        call BlzFrameSetPoint(PSETUI_AISlider, FRAMEPOINT_TOPLEFT, PSETUI_RightPane, FRAMEPOINT_TOPLEFT, 0.112, -0.184)
        call BlzFrameSetSize(PSETUI_AISlider, 0.115, 0.018)
        call BlzFrameSetMinMaxValue(PSETUI_AISlider, PSETUI_AI_ACTIVE_CAP_MIN, PSETUI_AI_ACTIVE_CAP_MAX)
        call BlzFrameSetStepSize(PSETUI_AISlider, 1.0)

        set PSETUI_AISliderLabel = BlzCreateFrame("EscMenuLabelTextTemplate", PSETUI_AISlider, 0, 0)
        call BlzFrameSetPoint(PSETUI_AISliderLabel, FRAMEPOINT_RIGHT, PSETUI_AISlider, FRAMEPOINT_LEFT, -0.006, 0.0)
        call BlzFrameSetSize(PSETUI_AISliderLabel, 0.100, 0.016)
        call BlzFrameSetTextAlignment(PSETUI_AISliderLabel, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)

        set PSETUI_AIDisclaimer = BlzCreateFrameByType("TEXT", "SettingsUIAIDisclaimer", PSETUI_RightPane, "", 0)
        call BlzFrameSetPoint(PSETUI_AIDisclaimer, FRAMEPOINT_TOPLEFT, PSETUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.220)
        call BlzFrameSetSize(PSETUI_AIDisclaimer, 0.210, 0.052)
        call BlzFrameSetTextAlignment(PSETUI_AIDisclaimer, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(PSETUI_AIDisclaimer, 0.78)
        call BlzFrameSetEnable(PSETUI_AIDisclaimer, false)
        call BlzFrameSetText(PSETUI_AIDisclaimer, "|cffffcc00More than 8 active AI units can cause lag, order issues, and input lag.|r|n|cffbfbfbfFor best performance, use 4-8 or lower.|r")

        call BlzTriggerRegisterFrameEvent(PSETUI_SliderTrigger, PSETUI_AISlider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        call BlzFrameSetVisible(PSETUI_AISlider, false)
        call BlzFrameSetVisible(PSETUI_Parent, false)
    endfunction

    private function PSETUI_DelayedInit takes nothing returns nothing
        call PSETUI_LoadToc()
        call PSETUI_CreateFrames()
        call PSETUI_Refresh(GetLocalPlayer())
    endfunction

    public function Init takes nothing returns nothing
        if PSETUI_Initialized then
            return
        endif
        set PSETUI_Initialized = true
        set PSETUI_MapDifficulty = Difficulty_GetDifficulty()
        set PSETUI_ButtonActionTable = Table.create()

        set PSETUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(PSETUI_CloseTrigger, function PSETUI_CloseAction)
        set PSETUI_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(PSETUI_ReturnTrigger, function PSETUI_ReturnAction)
        set PSETUI_ButtonTrigger = CreateTrigger()
        call TriggerAddAction(PSETUI_ButtonTrigger, function PSETUI_ButtonAction)
        set PSETUI_SliderTrigger = CreateTrigger()
        call TriggerAddAction(PSETUI_SliderTrigger, function PSETUI_SliderAction)
        set PSETUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(PSETUI_ClearFocusTrigger, function PSETUI_ClearFocusAction)

        set PSETUI_InitTrigger = CreateTrigger()
        call TriggerRegisterTimerEvent(PSETUI_InitTrigger, 0.20, false)
        call TriggerAddAction(PSETUI_InitTrigger, function PSETUI_DelayedInit)
    endfunction

    public function Hide takes nothing returns nothing
        call PSETUI_HideInternal()
    endfunction

    public function Show takes nothing returns nothing
        if not PSETUI_Initialized then
            call Init()
        endif
        call MasterUI_Hide()
        call MinimapSettingsUI_Hide()
        if PSETUI_Parent != null then
            if not BlzFrameIsVisible(PSETUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
            endif
            call BlzFrameSetVisible(PSETUI_Parent, true)
            call PSETUI_SetSliderVisible(true)
            call PSETUI_Refresh(GetLocalPlayer())
        endif
    endfunction

    public function Toggle takes nothing returns nothing
        if not PSETUI_Initialized then
            call Init()
        endif
        if PSETUI_Parent != null and BlzFrameIsVisible(PSETUI_Parent) then
            call Hide()
        else
            call Show()
        endif
    endfunction

    public function GetMapDifficulty takes nothing returns integer
        set PSETUI_MapDifficulty = Difficulty_GetDifficulty()
        return PSETUI_MapDifficulty
    endfunction

    public function SetMapDifficulty takes integer difficulty returns nothing
        if difficulty < SETTINGSUI_MAP_DIFFICULTY_STORY then
            set difficulty = SETTINGSUI_MAP_DIFFICULTY_STORY
        elseif difficulty > SETTINGSUI_MAP_DIFFICULTY_HARD then
            set difficulty = SETTINGSUI_MAP_DIFFICULTY_HARD
        endif
        set PSETUI_MapDifficulty = difficulty
        call Difficulty_SetDifficulty(PSETUI_MapDifficulty)
        call PSETUI_Refresh(GetLocalPlayer())
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
