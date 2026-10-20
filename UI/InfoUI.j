/**
    InfoUI

    Author: Valdemar
    Version: 1.0.0

    Description:
    Displays the current seasonal calendar, local hero zone weather, and
    completed daily quests that remain locked until the next day.

    Credits:
    - Tasyen for TasQuestBox

    How to install:
    Import after MasterUI, Interface, WeatherSystem, ZonesCore, QuestMaster,
    and the TasQuestBox TOC.

    API:
    - InfoUI_Show()
    - InfoUI_Hide()
    - InfoUI_ForceUpdate()

**/
library InfoUI initializer AutoInit requires MasterUI, Interface, WeatherSystem, ZonesCore, QuestMaster

globals
    // Configuration
    private constant integer INFOUI_BUTTON_COUNT = 8
    private constant integer INFOUI_FRAME_CONTEXT = 5
    private constant integer INFOUI_DAYS_PER_YEAR = 360
    private constant real INFOUI_REFRESH_PERIOD = 0.50
    private constant string INFOUI_TOC_PATH = "war3mapImported/TasQuestBox.toc"
    private constant string INFOUI_DEFAULT_QUEST_ICON = "ReplaceableTextures\\CommandButtons\\BTNScroll.blp"

    private boolean INFOUI_Initialized = false
    private boolean INFOUI_SyncingSlider = false
    private boolean INFOUI_HandlingSliderAction = false
    private integer INFOUI_LockedQuestCount = 0
    private integer INFOUI_SliderMaxCache = -1
    private integer INFOUI_SliderValueCache = -1

    private integer array INFOUI_ViewOffset
    private integer array INFOUI_SelectedQuestId
    private integer array INFOUI_LockedQuestId

    private framehandle INFOUI_Parent = null
    private framehandle INFOUI_ReturnButton = null
    private framehandle INFOUI_Slider = null
    private framehandle INFOUI_TitleFrame = null
    private framehandle INFOUI_TextArea = null
    private framehandle array INFOUI_Button
    private framehandle array INFOUI_ButtonIcon
    private framehandle array INFOUI_ButtonText

    private trigger INFOUI_CloseTrigger = null
    private trigger INFOUI_ReturnTrigger = null
    private trigger INFOUI_ClearFocusTrigger = null
    private trigger INFOUI_WheelTrigger = null
    private trigger INFOUI_SliderTrigger = null
    private trigger INFOUI_ButtonTrigger = null
    private timer INFOUI_RefreshTimer = null
endglobals

private function INFOUI_ClearFocusAction takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        call StopCamera()
    endif
endfunction

private function INFOUI_PosBox takes framehandle frame returns nothing
    call BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.1, 0.55)
endfunction

private function INFOUI_IsPlayerHero takes unit whichUnit returns boolean
    return whichUnit != null and GetHandleId(whichUnit) != 0 and GetUnitTypeId(whichUnit) != 0 and GetOwningPlayer(whichUnit) == Player(0) and (whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis)
endfunction

private function INFOUI_GetControlledHero takes nothing returns unit
    if INFOUI_IsPlayerHero(udg_Zulkis) and IsUnitSelected(udg_Zulkis, Player(0)) then
        return udg_Zulkis
    elseif INFOUI_IsPlayerHero(udg_Nazgrek) and IsUnitSelected(udg_Nazgrek, Player(0)) then
        return udg_Nazgrek
    elseif INFOUI_IsPlayerHero(udg_Nazgrek) then
        return udg_Nazgrek
    elseif INFOUI_IsPlayerHero(udg_Zulkis) then
        return udg_Zulkis
    endif
    return null
endfunction

private function INFOUI_FormatSeason takes string season returns string
    if season == "spring" then
        return "Spring"
    elseif season == "summer" then
        return "Summer"
    elseif season == "autumn" then
        return "Autumn"
    elseif season == "winter" then
        return "Winter"
    endif
    return season
endfunction

private function INFOUI_FormatWeather takes string weatherType returns string
    if weatherType == "none" or weatherType == "" then
        return "Clear"
    elseif weatherType == "rain_light" then
        return "Light Rain"
    elseif weatherType == "rain_medium" then
        return "Rain"
    elseif weatherType == "rain_heavy" then
        return "Heavy Rain"
    elseif weatherType == "snow_light" then
        return "Light Snow"
    elseif weatherType == "snow_medium" then
        return "Snow"
    elseif weatherType == "snow_heavy" then
        return "Heavy Snow"
    elseif weatherType == "storm" then
        return "Storm"
    elseif weatherType == "wind" then
        return "Strong Wind"
    endif
    return weatherType
endfunction

private function INFOUI_RebuildLockedQuestList takes nothing returns nothing
    local integer questIndex = 1
    local integer questId
    local QuestData questData

    set INFOUI_LockedQuestCount = 0
    loop
        exitwhen questIndex > QuestMaster_GetQuestCount()
        set questId = QuestMaster_GetQuestIdByIndex(questIndex)
        set questData = QuestMaster_GetById(questId)
        if questData != 0 and questData.questType == "daily" and questData.completed then
            set INFOUI_LockedQuestCount = INFOUI_LockedQuestCount + 1
            set INFOUI_LockedQuestId[INFOUI_LockedQuestCount] = questId
        endif
        set questIndex = questIndex + 1
    endloop
endfunction

private function INFOUI_IsLockedQuest takes integer questId returns boolean
    local integer index = 1

    loop
        exitwhen index > INFOUI_LockedQuestCount
        if INFOUI_LockedQuestId[index] == questId then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function INFOUI_GetSelectedQuestId takes player whichPlayer returns integer
    local integer playerId = GetPlayerId(whichPlayer)

    if INFOUI_IsLockedQuest(INFOUI_SelectedQuestId[playerId]) then
        return INFOUI_SelectedQuestId[playerId]
    elseif INFOUI_LockedQuestCount > 0 then
        return INFOUI_LockedQuestId[1]
    endif
    return 0
endfunction

private function INFOUI_GetWorldInfoText takes integer selectedQuestId returns string
    local integer calendarDay = ModuloInteger(udg_DaysPassed, INFOUI_DAYS_PER_YEAR) + 1
    local integer zoneId = 0
    local integer weatherZoneId = 0
    local unit hero = INFOUI_GetControlledHero()
    local ZoneData zoneData = 0
    local ZoneData weatherZoneData = 0
    local QuestData questData = QuestMaster_GetById(selectedQuestId)
    local string heroName = "No controlled hero"
    local string zoneName = "Unknown"
    local string weatherName = "Unknown"
    local string text

    if calendarDay <= 0 then
        set calendarDay = 1
    endif
    if hero != null then
        set heroName = GetUnitName(hero)
        set zoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(hero), GetUnitY(hero))
        set weatherZoneId = zoneId
        set zoneData = ZonesCore_GetZoneData(zoneId)
        if zoneData != 0 then
            set zoneName = zoneData.name
            if zoneData.blocksWeatherEffects or not zoneData.weatherAllowed then
                set weatherName = "No Weather"
            else
                if zoneData.weatherInheritFromParent and ZonesCore_GetParentZoneId(zoneId) > 0 then
                    set weatherZoneId = ZonesCore_GetParentZoneId(zoneId)
                endif
                set weatherZoneData = ZonesCore_GetZoneData(weatherZoneId)
                if weatherZoneData != 0 then
                    set weatherName = INFOUI_FormatWeather(weatherZoneData.GetWeatherState())
                endif
            endif
        endif
    endif

    set text = "|cffffcc00Day|r|n"
    set text = text + "Current Day: |cffffffff" + I2S(calendarDay) + " / " + I2S(INFOUI_DAYS_PER_YEAR) + "|r|n"
    set text = text + "Days Passed: |cffffffff" + I2S(udg_DaysPassed) + "|r|n|n"
    set text = text + "|cffffcc00Weather|r|n"
    set text = text + "Season: |cffffffff" + INFOUI_FormatSeason(WeatherSystem_GetCurrentSeason()) + "|r|n"
    set text = text + "Controlled Hero: |cffffffff" + heroName + "|r|n"
    set text = text + "Current Zone: |cffffffff" + zoneName + "|r|n"
    set text = text + "Zone Weather: |cffffffff" + weatherName + "|r|n|n"
    set text = text + "|cffffcc00Daily Quest Lockout|r|n"
    set text = text + "Completed today: |cffffffff" + I2S(INFOUI_LockedQuestCount) + "|r|n"

    if questData != 0 then
        set text = text + "These quests can be acquired again when the next day begins.|n|n"
        set text = text + "|cffffffff" + questData.title + "|r"
        if questData.giverDisplayName != "" then
            set text = text + "|nQuest Giver: " + questData.giverDisplayName
        endif
        if questData.description != "" then
            set text = text + "|n|n" + questData.description
        endif
    elseif INFOUI_LockedQuestCount <= 0 then
        set text = text + "No completed daily quests are locked."
    endif

    set hero = null
    return text
endfunction

private function INFOUI_UpdateUI takes nothing returns nothing
    local integer playerId = GetPlayerId(GetLocalPlayer())
    local integer rowIndex = 1
    local integer listIndex
    local integer questId
    local integer selectedQuestId
    local integer maxPage = 0
    local integer frameValue
    local QuestData questData

    if INFOUI_Parent == null or not BlzFrameIsVisible(INFOUI_Parent) then
        return
    endif

    call INFOUI_RebuildLockedQuestList()
    if INFOUI_LockedQuestCount > INFOUI_BUTTON_COUNT then
        set maxPage = (INFOUI_LockedQuestCount - 1) / INFOUI_BUTTON_COUNT
    endif
    if INFOUI_ViewOffset[playerId] < 0 then
        set INFOUI_ViewOffset[playerId] = 0
    elseif INFOUI_ViewOffset[playerId] > maxPage * INFOUI_BUTTON_COUNT then
        set INFOUI_ViewOffset[playerId] = maxPage * INFOUI_BUTTON_COUNT
    endif

    if not INFOUI_HandlingSliderAction then
        set frameValue = maxPage - (INFOUI_ViewOffset[playerId] / INFOUI_BUTTON_COUNT)
        set INFOUI_SyncingSlider = true
        if INFOUI_SliderMaxCache != maxPage then
            set INFOUI_SliderMaxCache = maxPage
            call BlzFrameSetMinMaxValue(INFOUI_Slider, 0.0, I2R(maxPage))
        endif
        if INFOUI_SliderValueCache != frameValue then
            set INFOUI_SliderValueCache = frameValue
            call BlzFrameSetValue(INFOUI_Slider, I2R(frameValue))
        endif
        set INFOUI_SyncingSlider = false
        call BlzFrameSetVisible(INFOUI_Slider, maxPage > 0)
    endif

    loop
        exitwhen rowIndex > INFOUI_BUTTON_COUNT
        set listIndex = INFOUI_ViewOffset[playerId] + rowIndex
        if listIndex <= INFOUI_LockedQuestCount then
            set questId = INFOUI_LockedQuestId[listIndex]
            set questData = QuestMaster_GetById(questId)
            if questData.iconPath != "" then
                call BlzFrameSetTexture(INFOUI_ButtonIcon[rowIndex], questData.iconPath, 0, false)
            else
                call BlzFrameSetTexture(INFOUI_ButtonIcon[rowIndex], INFOUI_DEFAULT_QUEST_ICON, 0, false)
            endif
            call BlzFrameSetVisible(INFOUI_ButtonIcon[rowIndex], true)
            call BlzFrameSetText(INFOUI_ButtonText[rowIndex], questData.title)
            call BlzFrameSetEnable(INFOUI_Button[rowIndex], true)
            call BlzFrameSetVisible(INFOUI_Button[rowIndex], true)
        elseif rowIndex == 1 and INFOUI_LockedQuestCount <= 0 then
            call BlzFrameSetTexture(INFOUI_ButtonIcon[rowIndex], INFOUI_DEFAULT_QUEST_ICON, 0, false)
            call BlzFrameSetVisible(INFOUI_ButtonIcon[rowIndex], true)
            call BlzFrameSetText(INFOUI_ButtonText[rowIndex], "No locked daily quests")
            call BlzFrameSetEnable(INFOUI_Button[rowIndex], false)
            call BlzFrameSetVisible(INFOUI_Button[rowIndex], true)
        else
            call BlzFrameSetVisible(INFOUI_Button[rowIndex], false)
        endif
        set rowIndex = rowIndex + 1
    endloop

    set selectedQuestId = INFOUI_GetSelectedQuestId(GetLocalPlayer())
    set INFOUI_SelectedQuestId[playerId] = selectedQuestId
    call BlzFrameSetText(INFOUI_TitleFrame, "Information")
    call BlzFrameSetText(INFOUI_TextArea, INFOUI_GetWorldInfoText(selectedQuestId))
endfunction

public function ForceUpdate takes nothing returns nothing
    call INFOUI_UpdateUI()
endfunction

public function Hide takes nothing returns nothing
    if INFOUI_Parent != null then
        if BlzFrameIsVisible(INFOUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        call BlzFrameSetVisible(INFOUI_Parent, false)
    endif
endfunction

public function Show takes nothing returns nothing
    set INFOUI_SliderValueCache = -1
    if INFOUI_Parent != null then
        if not BlzFrameIsVisible(INFOUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
        endif
        call BlzFrameSetVisible(INFOUI_Parent, true)
        call INFOUI_UpdateUI()
    endif
endfunction

private function INFOUI_CloseAction takes nothing returns nothing
    if GetLocalPlayer() == GetTriggerPlayer() then
        call Hide()
    endif
endfunction

private function INFOUI_ReturnAction takes nothing returns nothing
    call Hide()
    call MasterUI_Show()
endfunction

private function INFOUI_SliderAction takes nothing returns nothing
    local integer playerId = GetPlayerId(GetTriggerPlayer())
    local integer maxPage = 0
    local integer targetPage

    if INFOUI_SyncingSlider then
        return
    endif
    set INFOUI_HandlingSliderAction = true
    if INFOUI_LockedQuestCount > INFOUI_BUTTON_COUNT then
        set maxPage = (INFOUI_LockedQuestCount - 1) / INFOUI_BUTTON_COUNT
    endif
    set INFOUI_SliderValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
    set targetPage = maxPage - INFOUI_SliderValueCache
    if targetPage < 0 then
        set targetPage = 0
    elseif targetPage > maxPage then
        set targetPage = maxPage
    endif
    set INFOUI_ViewOffset[playerId] = targetPage * INFOUI_BUTTON_COUNT
    call INFOUI_UpdateUI()
    set INFOUI_HandlingSliderAction = false
endfunction

private function INFOUI_WheelAction takes nothing returns nothing
    local real nextValue
    local real maxValue

    if GetLocalPlayer() == GetTriggerPlayer() then
        if INFOUI_Slider == null or INFOUI_Parent == null or not BlzFrameIsVisible(INFOUI_Parent) or not BlzFrameIsVisible(INFOUI_Slider) then
            return
        endif
        if INFOUI_LockedQuestCount > INFOUI_BUTTON_COUNT then
            set maxValue = I2R((INFOUI_LockedQuestCount - 1) / INFOUI_BUTTON_COUNT)
        else
            set maxValue = 0.0
        endif
        if maxValue <= 0.0 then
            return
        endif

        set nextValue = BlzFrameGetValue(INFOUI_Slider)
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
        call BlzFrameSetValue(INFOUI_Slider, nextValue)
    endif
endfunction

private function INFOUI_ButtonAction takes nothing returns nothing
    local player triggerPlayer = GetTriggerPlayer()
    local framehandle clickedFrame = BlzGetTriggerFrame()
    local integer playerId = GetPlayerId(triggerPlayer)
    local integer rowIndex = 1
    local integer listIndex

    loop
        exitwhen rowIndex > INFOUI_BUTTON_COUNT
        if clickedFrame == INFOUI_Button[rowIndex] then
            set listIndex = INFOUI_ViewOffset[playerId] + rowIndex
            if listIndex <= INFOUI_LockedQuestCount then
                set INFOUI_SelectedQuestId[playerId] = INFOUI_LockedQuestId[listIndex]
                if GetLocalPlayer() == triggerPlayer then
                    call INFOUI_UpdateUI()
                endif
            endif
            set rowIndex = INFOUI_BUTTON_COUNT + 1
        else
            set rowIndex = rowIndex + 1
        endif
    endloop

    set clickedFrame = null
    set triggerPlayer = null
endfunction

private function INFOUI_InitFrames takes nothing returns nothing
    local framehandle wheelArea = null
    local framehandle closeButton = null
    local integer rowIndex = 1

    call BlzLoadTOCFile(INFOUI_TOC_PATH)

    set INFOUI_Parent = BlzCreateFrame("TasQuestBox", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, INFOUI_FRAME_CONTEXT)
    call INFOUI_PosBox(INFOUI_Parent)

    set INFOUI_Slider = BlzGetFrameByName("TasQuestBoxSlider1", INFOUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(INFOUI_SliderTrigger, INFOUI_Slider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
    call BlzTriggerRegisterFrameEvent(INFOUI_WheelTrigger, INFOUI_Slider, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetMinMaxValue(INFOUI_Slider, 0.0, 0.0)
    call BlzFrameSetStepSize(INFOUI_Slider, 1.0)

    set wheelArea = BlzCreateFrameByType("SLIDER", "InfoUIMoreScroll", INFOUI_Parent, "", 0)
    call BlzTriggerRegisterFrameEvent(INFOUI_WheelTrigger, wheelArea, FRAMEEVENT_MOUSE_WHEEL)
    call BlzFrameSetPoint(wheelArea, FRAMEPOINT_TOPRIGHT, INFOUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetPoint(wheelArea, FRAMEPOINT_BOTTOMLEFT, INFOUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)

    set INFOUI_TextArea = BlzGetFrameByName("TasQuestBoxTextArea1", INFOUI_FRAME_CONTEXT)
    set INFOUI_TitleFrame = BlzGetFrameByName("TasQuestBoxText1", INFOUI_FRAME_CONTEXT)
    call BlzFrameSetText(INFOUI_TitleFrame, "Information")

    set closeButton = BlzGetFrameByName("TasQuestBoxCloseButton1", INFOUI_FRAME_CONTEXT)
    call BlzTriggerRegisterFrameEvent(INFOUI_CloseTrigger, closeButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(INFOUI_ClearFocusTrigger, closeButton, FRAMEEVENT_CONTROL_CLICK)

    set INFOUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "InfoUIReturnButton", INFOUI_Parent, "ScriptDialogButton", 0)
    call BlzFrameSetSize(INFOUI_ReturnButton, 0.065, 0.03)
    call BlzFrameSetText(INFOUI_ReturnButton, "Return")
    call BlzFrameSetPoint(INFOUI_ReturnButton, FRAMEPOINT_TOPRIGHT, closeButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
    call BlzTriggerRegisterFrameEvent(INFOUI_ReturnTrigger, INFOUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
    call BlzTriggerRegisterFrameEvent(INFOUI_ClearFocusTrigger, INFOUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

    loop
        exitwhen rowIndex > INFOUI_BUTTON_COUNT
        set INFOUI_Button[rowIndex] = BlzCreateFrame("TasQuestBoxButton", INFOUI_Parent, 0, rowIndex + 500)
        if rowIndex > 1 then
            call BlzFrameSetPoint(INFOUI_Button[rowIndex], FRAMEPOINT_TOPLEFT, INFOUI_Button[rowIndex - 1], FRAMEPOINT_BOTTOMLEFT, 0.0, -0.002)
        endif
        set INFOUI_ButtonIcon[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonIcon", rowIndex + 500)
        set INFOUI_ButtonText[rowIndex] = BlzGetFrameByName("TasQuestBoxButtonText", rowIndex + 500)
        call BlzTriggerRegisterFrameEvent(INFOUI_ButtonTrigger, INFOUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(INFOUI_ClearFocusTrigger, INFOUI_Button[rowIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(INFOUI_WheelTrigger, INFOUI_Button[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
        set rowIndex = rowIndex + 1
    endloop
    call BlzFrameSetPoint(INFOUI_Button[1], FRAMEPOINT_TOPRIGHT, INFOUI_Slider, FRAMEPOINT_TOPLEFT, -0.006, 0.0)
    call BlzFrameSetVisible(INFOUI_Parent, false)

    set closeButton = null
    set wheelArea = null
endfunction

private function INFOUI_RefreshAction takes nothing returns nothing
    call INFOUI_UpdateUI()
endfunction

public function Init takes nothing returns nothing
    if INFOUI_Initialized then
        return
    endif
    set INFOUI_Initialized = true

    set INFOUI_CloseTrigger = CreateTrigger()
    call TriggerAddAction(INFOUI_CloseTrigger, function INFOUI_CloseAction)

    set INFOUI_ReturnTrigger = CreateTrigger()
    call TriggerAddAction(INFOUI_ReturnTrigger, function INFOUI_ReturnAction)

    set INFOUI_ClearFocusTrigger = CreateTrigger()
    call TriggerAddAction(INFOUI_ClearFocusTrigger, function INFOUI_ClearFocusAction)

    set INFOUI_ButtonTrigger = CreateTrigger()
    call TriggerAddAction(INFOUI_ButtonTrigger, function INFOUI_ButtonAction)

    set INFOUI_SliderTrigger = CreateTrigger()
    call TriggerAddAction(INFOUI_SliderTrigger, function INFOUI_SliderAction)

    set INFOUI_WheelTrigger = CreateTrigger()
    call TriggerAddAction(INFOUI_WheelTrigger, function INFOUI_WheelAction)

    call INFOUI_InitFrames()
    set INFOUI_RefreshTimer = CreateTimer()
    call TimerStart(INFOUI_RefreshTimer, INFOUI_REFRESH_PERIOD, true, function INFOUI_RefreshAction)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
