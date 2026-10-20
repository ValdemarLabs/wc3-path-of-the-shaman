/**
    ModernTotemTracker

    Author: Valdemar
    Version: 1.1.0

    Description:
    Displays Earth, Fire, Water, and Air badges above the modern player HUD.
    A live totem enlarges and brightens its element badge while a numeric
    countdown and thin lifetime bar show the remaining duration. The tracker
    reads the authoritative Totems slot registry and uses the shared modern
    HUD update callback; it creates no gameplay scanner or timer.

    Credits:
    - Blizzard Entertainment, Warcraft III frame API
    - Forgotten Hollow, compact status-indicator inspiration

    How to install:
    Import after Totems, ShamanCommon, FullscreenUI, and ModernPlayerHUD.
    Import the four PotSTotem*.tga textures at the exact paths documented in
    UI/_Modern/README.md.

    API:
    - call ModernTotemTracker_Refresh()

**/
library ModernTotemTracker initializer Init requires Totems, ShamanCommon, FullscreenUI, ModernPlayerHUD

globals
    private constant integer MTT_ELEMENT_COUNT = 4
    private constant real MTT_START_X = 0.332
    private constant real MTT_BOTTOM = 0.105
    private constant real MTT_SLOT_SIZE = 0.030
    private constant real MTT_SLOT_GAP = 0.005
    private constant real MTT_ACTIVE_SIZE = 0.030
    private constant real MTT_INACTIVE_SIZE = 0.022
    private constant real MTT_PROGRESS_WIDTH = 0.026
    private constant real MTT_PROGRESS_HEIGHT = 0.002
    private constant integer MTT_PROGRESS_STEPS = 20

    private constant string MTT_SURFACE_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
    private constant string MTT_EARTH_TEXTURE = "UI\\_Modern\\Assets\\PotSTotemEarth.tga"
    private constant string MTT_FIRE_TEXTURE = "UI\\_Modern\\Assets\\PotSTotemFire.tga"
    private constant string MTT_WATER_TEXTURE = "UI\\_Modern\\Assets\\PotSTotemWater.tga"
    private constant string MTT_AIR_TEXTURE = "UI\\_Modern\\Assets\\PotSTotemAir.tga"

    private boolean MTT_FramesCreated = false
    private boolean MTT_ParentVisible = false
    private framehandle MTT_Parent = null
    private framehandle array MTT_Slot
    private framehandle array MTT_Icon
    private framehandle array MTT_InactiveShade
    private framehandle array MTT_ProgressBack
    private framehandle array MTT_ProgressFill
    private framehandle array MTT_TimerText
    private trigger MTT_InitTrigger = null
    private unit MTT_CachedUnit = null
    private integer array MTT_CachedActive
    private integer array MTT_CachedSecond
    private integer array MTT_CachedProgress
endglobals

private function MTT_GetSlot takes integer index returns integer
    if index == 0 then
        return Totems_SLOT_EARTH
    elseif index == 1 then
        return Totems_SLOT_FIRE
    elseif index == 2 then
        return Totems_SLOT_WATER
    endif
    return Totems_SLOT_WIND
endfunction

private function MTT_GetTexture takes integer index returns string
    if index == 0 then
        return MTT_EARTH_TEXTURE
    elseif index == 1 then
        return MTT_FIRE_TEXTURE
    elseif index == 2 then
        return MTT_WATER_TEXTURE
    endif
    return MTT_AIR_TEXTURE
endfunction

private function MTT_GetColor takes integer index returns integer
    if index == 0 then
        return BlzConvertColor(255, 218, 151, 54)
    elseif index == 1 then
        return BlzConvertColor(255, 255, 82, 25)
    elseif index == 2 then
        return BlzConvertColor(255, 42, 151, 255)
    endif
    return BlzConvertColor(255, 180, 235, 255)
endfunction

private function MTT_IsPlayerHero takes unit whichUnit returns boolean
    return whichUnit != null and GetOwningPlayer(whichUnit) == Player(0) and ShamanCommon_IsPlayerHero(whichUnit)
endfunction

private function MTT_SetParentVisible takes boolean visible returns nothing
    if MTT_ParentVisible != visible then
        set MTT_ParentVisible = visible
        call BlzFrameSetVisible(MTT_Parent, visible)
    endif
endfunction

private function MTT_ResetCache takes nothing returns nothing
    local integer index = 0
    set MTT_CachedUnit = null
    loop
        exitwhen index >= MTT_ELEMENT_COUNT
        set MTT_CachedActive[index] = -1
        set MTT_CachedSecond[index] = -1
        set MTT_CachedProgress[index] = -1
        set index = index + 1
    endloop
endfunction

private function MTT_UpdateElement takes integer index, unit whichHero returns nothing
    local unit totem = Totems_GetLiveTotemForSlot(whichHero, MTT_GetSlot(index))
    local integer active = 0
    local integer second
    local integer progress = 0
    local real remaining
    local real total

    if totem != null then
        set active = 1
    endif

    if MTT_CachedActive[index] != active then
        set MTT_CachedActive[index] = active
        if active == 1 then
            call BlzFrameSetSize(MTT_Icon[index], MTT_ACTIVE_SIZE, MTT_ACTIVE_SIZE)
            call BlzFrameSetVisible(MTT_InactiveShade[index], false)
            call BlzFrameSetVisible(MTT_ProgressBack[index], true)
            call BlzFrameSetVisible(MTT_TimerText[index], true)
        else
            call BlzFrameSetSize(MTT_Icon[index], MTT_INACTIVE_SIZE, MTT_INACTIVE_SIZE)
            call BlzFrameSetVisible(MTT_InactiveShade[index], true)
            call BlzFrameSetVisible(MTT_ProgressBack[index], false)
            call BlzFrameSetVisible(MTT_TimerText[index], false)
            set MTT_CachedSecond[index] = -1
            set MTT_CachedProgress[index] = -1
        endif
    endif

    if active == 1 then
        set remaining = Totems_GetRemainingDuration(totem)
        set total = Totems_GetTotalDuration(totem)
        set second = R2I(remaining + 0.99)
        if total > 0.00 then
            set progress = R2I(remaining / total * I2R(MTT_PROGRESS_STEPS))
        endif
        if progress < 0 then
            set progress = 0
        elseif progress > MTT_PROGRESS_STEPS then
            set progress = MTT_PROGRESS_STEPS
        endif
        if MTT_CachedSecond[index] != second then
            set MTT_CachedSecond[index] = second
            call BlzFrameSetText(MTT_TimerText[index], I2S(second))
        endif
        if MTT_CachedProgress[index] != progress then
            set MTT_CachedProgress[index] = progress
            if progress <= 0 then
                call BlzFrameSetSize(MTT_ProgressFill[index], 0.0001, MTT_PROGRESS_HEIGHT)
            else
                call BlzFrameSetSize(MTT_ProgressFill[index], MTT_PROGRESS_WIDTH * I2R(progress) / I2R(MTT_PROGRESS_STEPS), MTT_PROGRESS_HEIGHT)
            endif
        endif
    endif

    set totem = null
    set whichHero = null
endfunction

private function MTT_Update takes nothing returns nothing
    local unit whichHero
    local integer index = 0

    if not MTT_FramesCreated or not ModernPlayerHUD_IsEnabled() or FullscreenUI_IsEnabled() then
        if MTT_FramesCreated then
            call MTT_SetParentVisible(false)
        endif
        return
    endif

    set whichHero = ModernPlayerHUD_GetUnit()
    if not MTT_IsPlayerHero(whichHero) then
        call MTT_SetParentVisible(false)
        set whichHero = null
        return
    endif

    if MTT_CachedUnit != whichHero then
        call MTT_ResetCache()
        set MTT_CachedUnit = whichHero
    endif

    call MTT_SetParentVisible(true)
    loop
        exitwhen index >= MTT_ELEMENT_COUNT
        call MTT_UpdateElement(index, whichHero)
        set index = index + 1
    endloop
    set whichHero = null
endfunction

private function MTT_CreateElement takes integer index returns nothing
    local real x = MTT_START_X + I2R(index) * (MTT_SLOT_SIZE + MTT_SLOT_GAP)

    set MTT_Slot[index] = BlzCreateFrameByType("FRAME", "ModernTotemTrackerSlot" + I2S(index), MTT_Parent, "", 0)
    call BlzFrameSetAbsPoint(MTT_Slot[index], FRAMEPOINT_BOTTOMLEFT, x, MTT_BOTTOM)
    call BlzFrameSetSize(MTT_Slot[index], MTT_SLOT_SIZE, MTT_SLOT_SIZE)
    call BlzFrameSetLevel(MTT_Slot[index], 32)

    set MTT_Icon[index] = BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerIcon" + I2S(index), MTT_Slot[index], "", 0)
    call BlzFrameSetPoint(MTT_Icon[index], FRAMEPOINT_CENTER, MTT_Slot[index], FRAMEPOINT_CENTER, 0.000, 0.000)
    call BlzFrameSetSize(MTT_Icon[index], MTT_INACTIVE_SIZE, MTT_INACTIVE_SIZE)
    call BlzFrameSetTexture(MTT_Icon[index], MTT_GetTexture(index), 0, true)
    call BlzFrameSetEnable(MTT_Icon[index], false)
    call BlzFrameSetLevel(MTT_Icon[index], 33)

    set MTT_InactiveShade[index] = BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerShade" + I2S(index), MTT_Icon[index], "", 0)
    call BlzFrameSetAllPoints(MTT_InactiveShade[index], MTT_Icon[index])
    call BlzFrameSetTexture(MTT_InactiveShade[index], MTT_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(MTT_InactiveShade[index], BlzConvertColor(155, 0, 0, 0))
    call BlzFrameSetEnable(MTT_InactiveShade[index], false)
    call BlzFrameSetLevel(MTT_InactiveShade[index], 34)

    set MTT_ProgressBack[index] = BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerProgressBack" + I2S(index), MTT_Slot[index], "", 0)
    call BlzFrameSetPoint(MTT_ProgressBack[index], FRAMEPOINT_BOTTOM, MTT_Slot[index], FRAMEPOINT_BOTTOM, 0.000, 0.001)
    call BlzFrameSetSize(MTT_ProgressBack[index], MTT_PROGRESS_WIDTH, MTT_PROGRESS_HEIGHT)
    call BlzFrameSetTexture(MTT_ProgressBack[index], MTT_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(MTT_ProgressBack[index], BlzConvertColor(220, 8, 8, 8))
    call BlzFrameSetEnable(MTT_ProgressBack[index], false)
    call BlzFrameSetLevel(MTT_ProgressBack[index], 35)

    set MTT_ProgressFill[index] = BlzCreateFrameByType("BACKDROP", "ModernTotemTrackerProgressFill" + I2S(index), MTT_ProgressBack[index], "", 0)
    call BlzFrameSetPoint(MTT_ProgressFill[index], FRAMEPOINT_LEFT, MTT_ProgressBack[index], FRAMEPOINT_LEFT, 0.000, 0.000)
    call BlzFrameSetSize(MTT_ProgressFill[index], 0.0001, MTT_PROGRESS_HEIGHT)
    call BlzFrameSetTexture(MTT_ProgressFill[index], MTT_SURFACE_TEXTURE, 0, false)
    call BlzFrameSetVertexColor(MTT_ProgressFill[index], MTT_GetColor(index))
    call BlzFrameSetEnable(MTT_ProgressFill[index], false)
    call BlzFrameSetLevel(MTT_ProgressFill[index], 36)

    set MTT_TimerText[index] = BlzCreateFrameByType("TEXT", "ModernTotemTrackerTimer" + I2S(index), MTT_Slot[index], "", 0)
    call BlzFrameSetAllPoints(MTT_TimerText[index], MTT_Slot[index])
    call BlzFrameSetTextAlignment(MTT_TimerText[index], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
    call BlzFrameSetScale(MTT_TimerText[index], 0.70)
    call BlzFrameSetEnable(MTT_TimerText[index], false)
    call BlzFrameSetLevel(MTT_TimerText[index], 37)

    call BlzFrameSetVisible(MTT_ProgressBack[index], false)
    call BlzFrameSetVisible(MTT_TimerText[index], false)
endfunction

private function MTT_CreateFrames takes nothing returns nothing
    local integer index = 0
    local framehandle gameUI

    if MTT_FramesCreated then
        return
    endif
    set MTT_FramesCreated = true
    set gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    set MTT_Parent = BlzCreateFrameByType("FRAME", "ModernTotemTracker", gameUI, "", 0)
    call BlzFrameSetAllPoints(MTT_Parent, gameUI)
    call BlzFrameSetLevel(MTT_Parent, 31)

    loop
        exitwhen index >= MTT_ELEMENT_COUNT
        call MTT_CreateElement(index)
        set index = index + 1
    endloop

    call MTT_ResetCache()
    call BlzFrameSetVisible(MTT_Parent, false)
    set gameUI = null
endfunction

public function Refresh takes nothing returns nothing
    call MTT_Update()
endfunction

private function MTT_DelayedInit takes nothing returns nothing
    call MTT_CreateFrames()
    call MTT_Update()
    call DestroyTrigger(MTT_InitTrigger)
    set MTT_InitTrigger = null
endfunction

private function Init takes nothing returns nothing
    set MTT_InitTrigger = CreateTrigger()
    call TriggerRegisterTimerEvent(MTT_InitTrigger, 0.30, false)
    call TriggerAddAction(MTT_InitTrigger, function MTT_DelayedInit)
    call ModernPlayerHUD_RegisterUpdate(function MTT_Update)
endfunction

endlibrary
