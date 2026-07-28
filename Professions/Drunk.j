/**
    Drunk

    Author: Valdemar
    Version: 1.0

    Description:
    Handles drunken unit visuals, local player drunk fade, and subtle camera
    sway for beverage effects.

    Credits:

    How to install:
    Import this library after Events, TimerUtils, and Table. Call Drunk_Add from
    consumable systems when a unit drinks a beverage.

    The player-side filter follows the currently selected owned unit. If the
    player switches from a drunk unit to another unit, the filter and camera roll
    are cleared locally. The fade uses the cinematic filter layer, so other
    systems that also write cinematic filters may visually override it until the
    next Drunk tick.

    API:
    call Drunk_Add(whichUnit, amount, duration)
    call Drunk_Clear(whichUnit)
    set amount = Drunk_GetLevel(whichUnit)
    call Drunk_RefreshPlayer(whichPlayer)

**/

library Drunk initializer Init requires TimerUtils, Table, Events

globals
    private constant real D_TICK_PERIOD = 0.35
    private constant real D_MAX_LEVEL = 3.00
    private constant real D_MIN_ROLL = 1.25
    private constant real D_MAX_ROLL = 7.00
    private constant string D_FILTER_TEXTURE = "ReplaceableTextures\\CameraMasks\\DiagonalSlash_mask.blp"
    private constant string D_TARGET_EFFECT = "Abilities\\Spells\\Other\\DrunkenHaze\\DrunkenHazeTarget.mdl"
    private constant string D_TARGET_ATTACH = "overhead"

    private Table D_TimerGeneration = 0
    private real array D_UnitLevel
    private unit array D_Unit
    private effect array D_UnitEffect
    private timer array D_UnitTimer
    private integer array D_UnitGeneration

    private unit array D_SelectedUnit
    private boolean array D_FilterActive
    private real array D_SwayPhase
    private timer D_TickTimer = null
endglobals

private function D_GetPlayerIndex takes player whichPlayer returns integer
    if whichPlayer == null then
        return -1
    endif
    return GetPlayerId(whichPlayer)
endfunction

private function D_GetUnitId takes unit whichUnit returns integer
    if whichUnit == null then
        return 0
    endif
    return GetUnitUserData(whichUnit)
endfunction

private function D_IsUnitAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
endfunction

private function D_ClampLevel takes real value returns real
    if value < 0.00 then
        return 0.00
    elseif value > D_MAX_LEVEL then
        return D_MAX_LEVEL
    endif
    return value
endfunction

private function D_NormalizeLevel takes real value returns real
    set value = D_ClampLevel(value) / D_MAX_LEVEL
    if value < 0.00 then
        return 0.00
    elseif value > 1.00 then
        return 1.00
    endif
    return value
endfunction

private function D_GetFilterAlpha takes real level returns integer
    return R2I(35.00 + D_NormalizeLevel(level) * 135.00)
endfunction

private function D_ShowFilter takes player whichPlayer, real level returns nothing
    local integer alpha = D_GetFilterAlpha(level)
    if GetLocalPlayer() == whichPlayer then
        call SetCineFilterTexture(D_FILTER_TEXTURE)
        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterStartUV(0.00, 0.00, 1.00, 1.00)
        call SetCineFilterEndUV(0.00, 0.00, 1.00, 1.00)
        call SetCineFilterStartColor(210, 255, 180, alpha)
        call SetCineFilterEndColor(160, 230, 120, alpha)
        call SetCineFilterDuration(D_TICK_PERIOD)
        call DisplayCineFilter(true)
    endif
endfunction

private function D_ClearLocalPlayerView takes player whichPlayer returns nothing
    if GetLocalPlayer() == whichPlayer then
        call DisplayCineFilter(false)
        call SetCameraField(CAMERA_FIELD_ROLL, 0.00, D_TICK_PERIOD)
    endif
endfunction

private function D_ShouldPlayerSeeDrunkUnit takes player whichPlayer, unit whichUnit returns boolean
    local integer unitId = D_GetUnitId(whichUnit)
    if unitId <= 0 then
        return false
    endif
    return D_IsUnitAlive(whichUnit) and GetOwningPlayer(whichUnit) == whichPlayer and D_UnitLevel[unitId] > 0.00
endfunction

private function D_RefreshPlayerIndex takes integer playerIndex returns nothing
    local player whichPlayer
    local unit whichUnit
    local integer unitId

    if playerIndex < 0 or playerIndex >= bj_MAX_PLAYERS then
        return
    endif

    set whichPlayer = Player(playerIndex)
    set whichUnit = D_SelectedUnit[playerIndex]
    set unitId = D_GetUnitId(whichUnit)

    if D_ShouldPlayerSeeDrunkUnit(whichPlayer, whichUnit) then
        set D_FilterActive[playerIndex] = true
        call D_ShowFilter(whichPlayer, D_UnitLevel[unitId])
    else
        if D_FilterActive[playerIndex] then
            call D_ClearLocalPlayerView(whichPlayer)
        endif
        set D_FilterActive[playerIndex] = false
    endif

    set whichPlayer = null
    set whichUnit = null
endfunction

private function D_RefreshPlayersForUnit takes unit whichUnit returns nothing
    local integer playerIndex = 0
    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        if D_SelectedUnit[playerIndex] == whichUnit then
            call D_RefreshPlayerIndex(playerIndex)
        endif
        set playerIndex = playerIndex + 1
    endloop
endfunction

private function D_DestroyUnitVisual takes integer unitId returns nothing
    if D_UnitEffect[unitId] != null then
        call DestroyEffect(D_UnitEffect[unitId])
        set D_UnitEffect[unitId] = null
    endif
endfunction

private function D_ReleaseUnitTimer takes integer unitId returns nothing
    if D_UnitTimer[unitId] != null then
        call PauseTimer(D_UnitTimer[unitId])
        call D_TimerGeneration.integer.remove(GetHandleId(D_UnitTimer[unitId]))
        call ReleaseTimer(D_UnitTimer[unitId])
        set D_UnitTimer[unitId] = null
    endif
endfunction

private function D_ClearById takes integer unitId returns nothing
    local unit whichUnit = D_Unit[unitId]

    if unitId <= 0 then
        set whichUnit = null
        return
    endif

    call D_ReleaseUnitTimer(unitId)
    call D_DestroyUnitVisual(unitId)
    set D_UnitLevel[unitId] = 0.00
    set D_UnitGeneration[unitId] = D_UnitGeneration[unitId] + 1
    set D_Unit[unitId] = null

    call D_RefreshPlayersForUnit(whichUnit)
    set whichUnit = null
endfunction

private function D_Expire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId = GetHandleId(t)
    local integer unitId = GetTimerData(t)
    local integer generation = D_TimerGeneration.integer[timerId]
    local unit whichUnit = D_Unit[unitId]

    call D_TimerGeneration.integer.remove(timerId)
    if generation == D_UnitGeneration[unitId] then
        set D_UnitTimer[unitId] = null
        call D_DestroyUnitVisual(unitId)
        set D_UnitLevel[unitId] = 0.00
        set D_Unit[unitId] = null
        call D_RefreshPlayersForUnit(whichUnit)
    endif

    call ReleaseTimer(t)
    set t = null
    set whichUnit = null
endfunction

private function D_StartTimer takes integer unitId, real duration returns nothing
    local timer t

    call D_ReleaseUnitTimer(unitId)
    if duration <= 0.00 then
        return
    endif

    set D_UnitGeneration[unitId] = D_UnitGeneration[unitId] + 1
    set t = NewTimer()
    set D_UnitTimer[unitId] = t
    call SetTimerData(t, unitId)
    set D_TimerGeneration.integer[GetHandleId(t)] = D_UnitGeneration[unitId]
    call TimerStart(t, duration, false, function D_Expire)
    set t = null
endfunction

private function D_OnUnitSelected takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer playerIndex = D_GetPlayerIndex(whichPlayer)

    if playerIndex >= 0 and playerIndex < bj_MAX_PLAYERS then
        set D_SelectedUnit[playerIndex] = GetTriggerUnit()
        call D_RefreshPlayerIndex(playerIndex)
    endif

    set whichPlayer = null
endfunction

private function D_Tick takes nothing returns nothing
    local integer playerIndex = 0
    local player whichPlayer
    local unit whichUnit
    local integer unitId
    local real level
    local real roll

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        set whichPlayer = Player(playerIndex)
        set whichUnit = D_SelectedUnit[playerIndex]
        set unitId = D_GetUnitId(whichUnit)

        if D_ShouldPlayerSeeDrunkUnit(whichPlayer, whichUnit) then
            set level = D_NormalizeLevel(D_UnitLevel[unitId])
            set D_FilterActive[playerIndex] = true
            call D_ShowFilter(whichPlayer, D_UnitLevel[unitId])
            set D_SwayPhase[playerIndex] = D_SwayPhase[playerIndex] + 0.70 + level * 0.55
            set roll = Sin(D_SwayPhase[playerIndex]) * (D_MIN_ROLL + (D_MAX_ROLL - D_MIN_ROLL) * level)
            if GetLocalPlayer() == whichPlayer then
                call SetCameraField(CAMERA_FIELD_ROLL, roll, D_TICK_PERIOD)
            endif
        else
            if D_FilterActive[playerIndex] then
                call D_ClearLocalPlayerView(whichPlayer)
            endif
            set D_FilterActive[playerIndex] = false
        endif

        set playerIndex = playerIndex + 1
    endloop

    set whichPlayer = null
    set whichUnit = null
endfunction

public function Add takes unit whichUnit, real amount, real duration returns nothing
    local integer unitId = D_GetUnitId(whichUnit)

    if whichUnit == null or unitId <= 0 or amount <= 0.00 then
        return
    endif

    set D_Unit[unitId] = whichUnit
    set D_UnitLevel[unitId] = D_ClampLevel(D_UnitLevel[unitId] + amount)
    if D_UnitEffect[unitId] == null then
        set D_UnitEffect[unitId] = AddSpecialEffectTarget(D_TARGET_EFFECT, whichUnit, D_TARGET_ATTACH)
    endif

    call D_StartTimer(unitId, duration)
    call D_RefreshPlayersForUnit(whichUnit)
endfunction

public function Clear takes unit whichUnit returns nothing
    call D_ClearById(D_GetUnitId(whichUnit))
endfunction

public function GetLevel takes unit whichUnit returns real
    local integer unitId = D_GetUnitId(whichUnit)
    if unitId <= 0 then
        return 0.00
    endif
    return D_UnitLevel[unitId]
endfunction

public function RefreshPlayer takes player whichPlayer returns nothing
    call D_RefreshPlayerIndex(D_GetPlayerIndex(whichPlayer))
endfunction

private function Init takes nothing returns nothing
    set D_TimerGeneration = Table.create()
    call Events_RegisterPlayerUnitEvent(function D_OnUnitSelected, EVENT_PLAYER_UNIT_SELECTED)
    set D_TickTimer = CreateTimer()
    call TimerStart(D_TickTimer, D_TICK_PERIOD, true, function D_Tick)
endfunction

endlibrary
