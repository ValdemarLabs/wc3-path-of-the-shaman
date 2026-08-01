/**
    Drunk

    Author: Valdemar
    Version: 1.1

    Description:
    Handles drunken unit visuals, local player drunk fade, escalating camera
    sway, and high-level drunken movement/casting mishaps.

    Credits:

    How to install:
    Import this library after TimerUtils, Table, and CameraControl. Call
    Drunk_Add from consumable systems when a unit drinks a beverage.

    The player-side filter follows CameraControl's active Nazgrek/Zulkis target,
    not ordinary unit selection. The fade uses the cinematic filter layer, so
    other systems that also write cinematic filters may visually override it
    until the next Drunk tick.

    API:
    call Drunk_Add(whichUnit, amount, duration)
    call Drunk_Clear(whichUnit)
    set amount = Drunk_GetLevel(whichUnit)
    call Drunk_RefreshPlayer(whichPlayer)

**/

library Drunk initializer Init requires TimerUtils, Table, CameraControl

globals
    private constant real D_TICK_PERIOD = 0.35
    private constant real D_MAX_LEVEL = 3.00
    private constant real D_MIN_ROLL = 1.25
    private constant real D_MAX_ROLL = 7.00
    private constant real D_MISHAP_MIN_LEVEL = 0.30
    private constant integer D_MISHAP_MIN_TICKS = 10
    private constant integer D_MISHAP_MAX_TICKS = 28
    private constant real D_MISCAST_MEDIUM_LEVEL = 0.60
    private constant real D_MISCAST_HIGH_LEVEL = 0.85
    private constant string D_FILTER_TEXTURE = "ReplaceableTextures\\CameraMasks\\DiagonalSlash_mask.blp"
    private constant string D_TARGET_EFFECT = "Abilities\\Spells\\Other\\DrunkenHaze\\DrunkenHazeTarget.mdl"
    private constant string D_TARGET_ATTACH = "overhead"

    private Table D_TimerGeneration = 0
    private real array D_UnitLevel
    private unit array D_Unit
    private effect array D_UnitEffect
    private timer array D_UnitTimer
    private integer array D_UnitGeneration
    private integer array D_NextMishapTick
    private group D_DrunkUnits = null

    private boolean array D_FilterActive
    private real array D_SwayPhase
    private integer D_TickCount = 0
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

private function D_GetPlayerViewUnit takes player whichPlayer returns unit
    return CameraControl_GetTargetUnit(whichPlayer)
endfunction

private function D_RefreshPlayerIndex takes integer playerIndex returns nothing
    local player whichPlayer
    local unit whichUnit
    local integer unitId

    if playerIndex < 0 or playerIndex >= bj_MAX_PLAYERS then
        return
    endif

    set whichPlayer = Player(playerIndex)
    set whichUnit = D_GetPlayerViewUnit(whichPlayer)
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
        if D_GetPlayerViewUnit(Player(playerIndex)) == whichUnit then
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
    set D_NextMishapTick[unitId] = 0
    set D_UnitGeneration[unitId] = D_UnitGeneration[unitId] + 1
    call GroupRemoveUnit(D_DrunkUnits, whichUnit)
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
        set D_NextMishapTick[unitId] = 0
        call GroupRemoveUnit(D_DrunkUnits, whichUnit)
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

// Only gameplay abilities are eligible. This excludes profession/UI abilities
// that may also use Channel and would otherwise open interfaces while drunk.
private function D_IsElementalMiscastAbility takes integer abilityId returns boolean
    return abilityId == 'A6A0' or abilityId == 'A67H' or abilityId == 'A67L' or abilityId == 'A67J' or abilityId == 'A69L' or abilityId == 'A69N' or abilityId == 'A68H' or abilityId == 'A67Q'
endfunction

private function D_IsEnhancementMiscastAbility takes integer abilityId returns boolean
    return abilityId == 'A685' or abilityId == 'A6DP' or abilityId == 'A026' or abilityId == 'A022' or abilityId == 'A67N' or abilityId == 'A679' or abilityId == 'A673' or abilityId == 'A675' or abilityId == 'A677'
endfunction

private function D_IsRestorationMiscastAbility takes integer abilityId returns boolean
    return abilityId == 'A66Y' or abilityId == 'A672' or abilityId == 'A66W' or abilityId == 'A69W' or abilityId == 'A62Z' or abilityId == 'A01Z' or abilityId == 'A6AL' or abilityId == 'A638' or abilityId == 'A69Y'
endfunction

private function D_IsTotemicMiscastAbility takes integer abilityId returns boolean
    return abilityId == 'A63F' or abilityId == 'A63G' or abilityId == 'A63H' or abilityId == 'A63I' or abilityId == 'A68J' or abilityId == 'A68L' or abilityId == 'A68F' or abilityId == 'A68T' or abilityId == 'A01U' or abilityId == 'A636'
endfunction

private function D_IsMiscastAbility takes integer abilityId returns boolean
    return D_IsElementalMiscastAbility(abilityId) or D_IsEnhancementMiscastAbility(abilityId) or D_IsRestorationMiscastAbility(abilityId) or D_IsTotemicMiscastAbility(abilityId)
endfunction

private function D_TryRandomMiscast takes unit whichUnit returns boolean
    local integer index = 0
    local integer abilityId
    local integer abilityLevel
    local integer candidateCount = 0
    local integer selectedAbilityId = 0
    local string selectedOrder = ""
    local string order
    local ability whichAbility = BlzGetUnitAbilityByIndex(whichUnit, index)
    local real angle
    local real distance
    local integer castMode

    loop
        exitwhen whichAbility == null
        set abilityId = BlzGetAbilityId(whichAbility)
        set abilityLevel = GetUnitAbilityLevel(whichUnit, abilityId)
        if D_IsMiscastAbility(abilityId) and abilityLevel > 0 and BlzGetUnitAbilityCooldownRemaining(whichUnit, abilityId) <= 0.00 and GetUnitState(whichUnit, UNIT_STATE_MANA) >= I2R(BlzGetUnitAbilityManaCost(whichUnit, abilityId, abilityLevel - 1)) then
            set order = BlzGetAbilityStringLevelField(whichAbility, ABILITY_SLF_BASE_ORDER_ID_NCL6, abilityLevel - 1)
            if order != null and order != "" then
                set candidateCount = candidateCount + 1
                if GetRandomInt(1, candidateCount) == 1 then
                    set selectedAbilityId = abilityId
                    set selectedOrder = order
                endif
            endif
        endif
        set index = index + 1
        set whichAbility = BlzGetUnitAbilityByIndex(whichUnit, index)
    endloop

    set whichAbility = null
    if selectedAbilityId == 0 then
        return false
    endif

    set castMode = GetRandomInt(1, 3)
    if castMode == 1 and IssueImmediateOrder(whichUnit, selectedOrder) then
        return true
    elseif castMode == 2 and IssueTargetOrder(whichUnit, selectedOrder, whichUnit) then
        return true
    elseif castMode == 3 then
        set angle = GetRandomReal(0.00, 2.00*bj_PI)
        set distance = GetRandomReal(100.00, 450.00)
        if IssuePointOrder(whichUnit, selectedOrder, GetUnitX(whichUnit) + distance*Cos(angle), GetUnitY(whichUnit) + distance*Sin(angle)) then
            return true
        endif
    endif

    if IssueImmediateOrder(whichUnit, selectedOrder) then
        return true
    endif
    if IssueTargetOrder(whichUnit, selectedOrder, whichUnit) then
        return true
    endif
    set angle = GetRandomReal(0.00, 2.00*bj_PI)
    set distance = GetRandomReal(100.00, 450.00)
    return IssuePointOrder(whichUnit, selectedOrder, GetUnitX(whichUnit) + distance*Cos(angle), GetUnitY(whichUnit) + distance*Sin(angle))
endfunction

private function D_ScheduleNextMishap takes integer unitId, real normalizedLevel returns nothing
    local integer interval = D_MISHAP_MAX_TICKS - R2I((D_MISHAP_MAX_TICKS - D_MISHAP_MIN_TICKS)*normalizedLevel)
    if interval < D_MISHAP_MIN_TICKS then
        set interval = D_MISHAP_MIN_TICKS
    endif
    set D_NextMishapTick[unitId] = D_TickCount + GetRandomInt(interval, interval + 8)
endfunction

private function D_ApplyMishap takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    local integer unitId = D_GetUnitId(whichUnit)
    local real level
    local integer miscastChance = 0

    if unitId <= 0 or not D_IsUnitAlive(whichUnit) or IsUnitPaused(whichUnit) then
        set whichUnit = null
        return
    endif

    set level = D_NormalizeLevel(D_UnitLevel[unitId])
    if level < D_MISHAP_MIN_LEVEL then
        set whichUnit = null
        return
    endif
    if D_NextMishapTick[unitId] <= 0 then
        call D_ScheduleNextMishap(unitId, level)
    elseif D_TickCount >= D_NextMishapTick[unitId] then
        if level >= D_MISCAST_HIGH_LEVEL then
            set miscastChance = 45
        elseif level >= D_MISCAST_MEDIUM_LEVEL then
            set miscastChance = 20
        endif

        if miscastChance > 0 and GetRandomInt(1, 100) <= miscastChance then
            if not D_TryRandomMiscast(whichUnit) then
                call IssueImmediateOrder(whichUnit, "stop")
            endif
        else
            call IssueImmediateOrder(whichUnit, "stop")
        endif
        if level >= D_MISCAST_MEDIUM_LEVEL then
            call SetUnitFacing(whichUnit, GetUnitFacing(whichUnit) + GetRandomReal(-55.00, 55.00))
        endif
        call D_ScheduleNextMishap(unitId, level)
    endif

    set whichUnit = null
endfunction

private function D_Tick takes nothing returns nothing
    local integer playerIndex = 0
    local player whichPlayer
    local unit whichUnit
    local integer unitId
    local real level
    local real roll
    local real swayScale

    set D_TickCount = D_TickCount + 1
    call ForGroup(D_DrunkUnits, function D_ApplyMishap)

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        set whichPlayer = Player(playerIndex)
        set whichUnit = D_GetPlayerViewUnit(whichPlayer)
        set unitId = D_GetUnitId(whichUnit)

        if D_ShouldPlayerSeeDrunkUnit(whichPlayer, whichUnit) then
            set level = D_NormalizeLevel(D_UnitLevel[unitId])
            set D_FilterActive[playerIndex] = true
            call D_ShowFilter(whichPlayer, D_UnitLevel[unitId])
            set D_SwayPhase[playerIndex] = D_SwayPhase[playerIndex] + 0.70 + level*0.55 + 0.08*Sin(D_SwayPhase[playerIndex]*0.73 + I2R(playerIndex))
            set swayScale = 1.00 + 0.18*Sin(D_SwayPhase[playerIndex]*2.31 + I2R(playerIndex)*1.77)
            set roll = Sin(D_SwayPhase[playerIndex])*(D_MIN_ROLL + (D_MAX_ROLL - D_MIN_ROLL)*level)*swayScale
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
    call GroupAddUnit(D_DrunkUnits, whichUnit)
    call D_ScheduleNextMishap(unitId, D_NormalizeLevel(D_UnitLevel[unitId]))
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
    set D_DrunkUnits = CreateGroup()
    set D_TickTimer = CreateTimer()
    call TimerStart(D_TickTimer, D_TICK_PERIOD, true, function D_Tick)
endfunction

endlibrary
