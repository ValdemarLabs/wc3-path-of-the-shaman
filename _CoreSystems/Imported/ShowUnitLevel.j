library ShowUnitLevel initializer Init requires optional FrameLoader
//===========================================================================
// ShowUnitLevel V1.2 by Tasyen
//
// Description:
//     Displays unit levels for selected non-hero, non-creep units.
//
// Credits:
//     Tasyen - original system
//
// How to install:
//     Import ShowUnitLevel.fdf and ShowUnitLevel.toc and add this library.
//
// API:
//     Selection changes refresh the display automatically.
//===========================================================================

globals
    private group Group
    private race RaceCreep = ConvertRace(8)
    private unit Unit

    private framehandle NativeStatsPanel = null
    private framehandle NativeClassValue = null
    private framehandle CustomClassValue = null

    private trigger SelectionTrigger = null
    private timer RefreshTimer = null
    private integer CustomModeCache = -1
    private string TextCache = ""
endglobals

private function FilterFunc takes nothing returns boolean
    return Unit != null and not IsUnitType(Unit, UNIT_TYPE_STRUCTURE) and not IsHeroUnitId(GetUnitTypeId(Unit)) and GetUnitRace(Unit) != RaceCreep
endfunction

private function Refresh takes nothing returns nothing
    local string text = ""

    call GroupEnumUnitsSelected(Group, GetLocalPlayer(), null)
    set Unit = FirstOfGroup(Group)
    call GroupClear(Group)

    if FilterFunc() then
        if CustomModeCache != 1 then
            call BlzFrameSetAlpha(NativeStatsPanel, 0)
            set CustomModeCache = 1
        endif
        if BlzFrameGetText(NativeClassValue) != " " then
            set text = BlzFrameGetText(NativeClassValue) + " "
        endif
        set text = text + GetLocalizedString("LEVEL") + " " + I2S(GetUnitLevel(Unit))
        if text != TextCache then
            call BlzFrameSetText(CustomClassValue, text)
            set TextCache = text
        endif
    else
        if CustomModeCache != 0 then
            call BlzFrameSetAlpha(NativeStatsPanel, 255)
            set CustomModeCache = 0
        endif
        if TextCache != "" then
            call BlzFrameSetText(CustomClassValue, "")
            set TextCache = ""
        endif
    endif

    set Unit = null
endfunction

private function QueueRefresh takes nothing returns nothing
    call TimerStart(RefreshTimer, 0.00, false, function Refresh)
endfunction

private function CreateFrames takes nothing returns nothing
    call BlzLoadTOCFile("war3mapImported/ShowUnitLevel.toc")

    set NativeStatsPanel = BlzGetFrameByName("SimpleUnitStatsPanel", 0)
    set NativeClassValue = BlzGetFrameByName("SimpleClassValue", 0)
    call BlzCreateSimpleFrame("CustomSimpleUnitStatsPanel", BlzGetFrameByName("SimpleInfoPanelUnitDetail", 0), 0)
    set CustomClassValue = BlzGetFrameByName("CustomSimpleClassValue", 0)

    set CustomModeCache = -1
    set TextCache = ""
    call QueueRefresh()
endfunction

private function InitFramesDelayed takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()

    call PauseTimer(expiredTimer)
    call DestroyTimer(expiredTimer)
    set expiredTimer = null
    call CreateFrames()
endfunction

private function Init takes nothing returns nothing
    set Group = CreateGroup()
    set RefreshTimer = CreateTimer()
    set SelectionTrigger = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(SelectionTrigger, EVENT_PLAYER_UNIT_SELECTED)
    call TriggerRegisterAnyUnitEventBJ(SelectionTrigger, EVENT_PLAYER_UNIT_DESELECTED)
    call TriggerAddAction(SelectionTrigger, function QueueRefresh)
    call TimerStart(CreateTimer(), 0.00, false, function InitFramesDelayed)

    static if LIBRARY_FrameLoader then
        call FrameLoaderAdd(function CreateFrames)
    endif
endfunction
endlibrary
