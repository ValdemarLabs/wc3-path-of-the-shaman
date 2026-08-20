/**
    Drunk

    Author: Valdemar
    Version: 2.0.0

    Description:
    Handles drunken visuals, camera sway, movement/casting mishaps, puking,
    pass-outs, hangovers, reactions, and wake event callbacks.

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
    call Drunk_RegisterPassOutRect(whichRect)
    call Drunk_SetPassOutAnimation(unitTypeId, animationName)
    call Drunk_RegisterWakeHandler(function OnDrunkWake)
    set whichUnit = Drunk_GetWakeUnit()
    set hasHangover = Drunk_HasHangover(whichUnit)

**/

library Drunk initializer Init requires TimerUtils, Table, CameraControl, FallenHeroState, DialogSystem, AI, Companions, VoicelinesDrunk

globals
    // Core configuration.
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

    // Object Editor configuration. Replace these placeholders with hidden,
    // self-only aura abilities that display the Drunk, Puking, and Hangover
    // buffs. Puking should supply the visible miss-chance penalty.
    private constant integer D_DRUNK_ABILITY_ID = 'S01M'
    private constant integer D_PUKE_ABILITY_ID = 'S01O'
    private constant integer D_HANGOVER_ABILITY_ID = 'S01N'
    private constant integer D_SLEEP_ABILITY_ID = 'Asla'

    // Puke and pass-out tuning. Event chances are evaluated when alcohol is
    // added and scale from the normalized drunk level.
    private constant real D_PUKE_MIN_LEVEL = 0.25
    private constant real D_PUKE_BASE_CHANCE = 2.00
    private constant real D_PUKE_MAX_CHANCE = 38.00
    private constant real D_PUKE_ANIMATION_TIME = 2.50
    private constant real D_PUKE_AFTER_TIME = 10.00
    private constant real D_PUKE_ARMOR_PENALTY = 12.00
    private constant real D_PUKE_HIT_PENALTY = 65.00
    private constant real D_PASSOUT_MIN_LEVEL = 0.45
    private constant real D_PASSOUT_BASE_CHANCE = 0.50
    private constant real D_PASSOUT_MAX_CHANCE = 60.00
    private constant real D_PASSOUT_FADE_OUT = 2.00
    private constant real D_PASSOUT_FADE_IN = 2.00
    private constant real D_PASSOUT_SLEEP_AFTER_FADE = 3.00
    private constant real D_AI_PASSOUT_TIME = 8.00
    private constant real D_EVENT_COOLDOWN = 18.00
    private constant real D_REACTION_RANGE = 1600.00
    private constant real D_HANGOVER_DURATION = 300.00
    private constant integer D_MAX_PASSOUT_RECTS = 32
    private constant string D_PASSOUT_EFFECT = "Abilities\\Spells\\Other\\CreepSleep\\CreepSleepTarget.mdl"
    private constant string D_PASSOUT_ATTACH = "overhead"
    private constant string D_BLACK_FILTER = "ReplaceableTextures\\CameraMasks\\Black_mask.blp"

    private Table D_TimerGeneration = 0
    private real array D_UnitLevel
    private unit array D_Unit
    private effect array D_UnitEffect
    private timer array D_UnitTimer
    private integer array D_UnitGeneration
    private integer array D_NextMishapTick
    private integer array D_NextEventTick
    private boolean array D_HadDrunkAbility
    private boolean array D_Puking
    private boolean array D_HadPukeAbility
    private timer array D_PukeTimer
    private boolean array D_PassedOut
    private boolean array D_WasPaused
    private boolean array D_HadSleepAbility
    private effect array D_SleepEffect
    private timer array D_PassOutTimer
    private boolean array D_CameraSuspendedByPassOut
    private boolean array D_Hangover
    private boolean array D_HadHangoverAbility
    private timer array D_HangoverTimer
    private group D_DrunkUnits = null

    private integer D_PassOutRectCount = 0
    private rect array D_PassOutRect
    private Table D_PassOutAnimation = 0
    private trigger D_WakeHandlers = null
    unit Drunk_WakeUnit = null

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
    return FallenHeroState_IsAlive(whichUnit)
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

private function D_ShowBlackFade takes player whichPlayer, boolean fadeOut, real duration returns nothing
    if GetLocalPlayer() == whichPlayer then
        call SetCineFilterTexture(D_BLACK_FILTER)
        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterStartUV(0.00, 0.00, 1.00, 1.00)
        call SetCineFilterEndUV(0.00, 0.00, 1.00, 1.00)
        if fadeOut then
            call SetCineFilterStartColor(0, 0, 0, 0)
            call SetCineFilterEndColor(0, 0, 0, 255)
        else
            call SetCineFilterStartColor(0, 0, 0, 255)
            call SetCineFilterEndColor(0, 0, 0, 0)
        endif
        call SetCineFilterDuration(duration)
        call DisplayCineFilter(true)
    endif
endfunction

private function D_GetOtherPlayerHero takes unit subject returns unit
    if subject == udg_Nazgrek and udg_Zulkis != null and GetOwningPlayer(udg_Zulkis) == Player(0) and D_IsUnitAlive(udg_Zulkis) then
        return udg_Zulkis
    elseif subject == udg_Zulkis and udg_Nazgrek != null and GetOwningPlayer(udg_Nazgrek) == Player(0) and D_IsUnitAlive(udg_Nazgrek) then
        return udg_Nazgrek
    endif
    return null
endfunction

private function D_GetRandomCompanyResponder takes unit subject returns unit
    local integer index = 1
    local integer count = Companions_GetControlledDisplayCount()
    local integer seen = 0
    local unit candidate
    local unit selected = null

    loop
        exitwhen index > count
        set candidate = Companions_GetControlledDisplayUnit(index)
        if candidate != null and candidate != subject and AI_GetInstance(candidate) > 0 and IsUnitType(candidate, UNIT_TYPE_HERO) and D_IsUnitAlive(candidate) and IsUnitInRange(candidate, subject, D_REACTION_RANGE) then
            set seen = seen + 1
            if GetRandomInt(1, seen) == 1 then
                set selected = candidate
            endif
        endif
        set index = index + 1
    endloop

    set candidate = null
    return selected
endfunction

private function D_PlayReaction takes unit subject, boolean passOut returns nothing
    local unit otherHero = D_GetOtherPlayerHero(subject)
    local unit companyHero

    if otherHero != null and IsUnitInRange(otherHero, subject, D_REACTION_RANGE) then
        call VoicelinesDrunk_PickHeroReaction(otherHero, passOut)
        call DialogSystem_QueueFieldLine(otherHero, "", VoicelinesDrunk_PickedKey, VoicelinesDrunk_PickedText)
    endif
    if not passOut then
        set companyHero = D_GetRandomCompanyResponder(subject)
        if companyHero != null then
            call VoicelinesDrunk_PickAIReaction(companyHero, false)
            call DialogSystem_QueueFieldLine(companyHero, "", VoicelinesDrunk_PickedKey, VoicelinesDrunk_PickedText)
        endif
    endif

    set otherHero = null
    set companyHero = null
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

private function D_RemovePuke takes integer unitId returns nothing
    local unit whichUnit = D_Unit[unitId]

    if not D_Puking[unitId] or whichUnit == null then
        set whichUnit = null
        return
    endif
    set udg_Stats_Hit[unitId] = udg_Stats_Hit[unitId] + D_PUKE_HIT_PENALTY
    call BlzSetUnitArmor(whichUnit, BlzGetUnitArmor(whichUnit) + D_PUKE_ARMOR_PENALTY)
    if not D_HadPukeAbility[unitId] then
        call UnitRemoveAbility(whichUnit, D_PUKE_ABILITY_ID)
    endif
    if D_IsUnitAlive(whichUnit) and not D_PassedOut[unitId] then
        call SetUnitAnimation(whichUnit, "stand")
    endif
    set D_Puking[unitId] = false
    set D_HadPukeAbility[unitId] = false
    set whichUnit = null
endfunction

private function D_EndPuke takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)

    set D_PukeTimer[unitId] = null
    call D_RemovePuke(unitId)
    if D_UnitLevel[unitId] <= 0.00 and not D_PassedOut[unitId] and not D_Hangover[unitId] then
        set D_Unit[unitId] = null
    endif
    call ReleaseTimer(expired)
    set expired = null
endfunction

private function D_StartPuke takes unit whichUnit, integer unitId returns nothing
    local timer t

    if D_Puking[unitId] or D_PassedOut[unitId] then
        return
    endif
    set D_Puking[unitId] = true
    set D_HadPukeAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_PUKE_ABILITY_ID) > 0
    if not D_HadPukeAbility[unitId] then
        call UnitAddAbility(whichUnit, D_PUKE_ABILITY_ID)
        call BlzUnitHideAbility(whichUnit, D_PUKE_ABILITY_ID, true)
    endif
    set udg_Stats_Hit[unitId] = udg_Stats_Hit[unitId] - D_PUKE_HIT_PENALTY
    call BlzSetUnitArmor(whichUnit, BlzGetUnitArmor(whichUnit) - D_PUKE_ARMOR_PENALTY)
    call IssueImmediateOrder(whichUnit, "stop")
    call SetUnitAnimation(whichUnit, "stand puke")
    call DestroyEffect(AddSpecialEffectTarget(D_TARGET_EFFECT, whichUnit, "origin"))
    call D_PlayReaction(whichUnit, false)

    set t = NewTimer()
    set D_PukeTimer[unitId] = t
    call SetTimerData(t, unitId)
    call TimerStart(t, D_PUKE_ANIMATION_TIME + D_PUKE_AFTER_TIME, false, function D_EndPuke)
    set t = null
endfunction

private function D_RemoveHangover takes integer unitId returns nothing
    local unit whichUnit = D_Unit[unitId]

    if D_Hangover[unitId] and whichUnit != null and not D_HadHangoverAbility[unitId] then
        call UnitRemoveAbility(whichUnit, D_HANGOVER_ABILITY_ID)
    endif
    set D_Hangover[unitId] = false
    set D_HadHangoverAbility[unitId] = false
    set whichUnit = null
endfunction

private function D_EndHangover takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)

    set D_HangoverTimer[unitId] = null
    call D_RemoveHangover(unitId)
    if D_UnitLevel[unitId] <= 0.00 and not D_Puking[unitId] and not D_PassedOut[unitId] then
        set D_Unit[unitId] = null
    endif
    call ReleaseTimer(expired)
    set expired = null
endfunction

private function D_StartHangover takes unit whichUnit, integer unitId returns nothing
    local timer t

    if D_HangoverTimer[unitId] != null then
        call PauseTimer(D_HangoverTimer[unitId])
        call ReleaseTimer(D_HangoverTimer[unitId])
        set D_HangoverTimer[unitId] = null
    endif
    if not D_Hangover[unitId] then
        set D_HadHangoverAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_HANGOVER_ABILITY_ID) > 0
    endif
    set D_Hangover[unitId] = true
    if not D_HadHangoverAbility[unitId] then
        call UnitAddAbility(whichUnit, D_HANGOVER_ABILITY_ID)
        call BlzUnitHideAbility(whichUnit, D_HANGOVER_ABILITY_ID, true)
    endif
    set t = NewTimer()
    set D_HangoverTimer[unitId] = t
    call SetTimerData(t, unitId)
    call TimerStart(t, D_HANGOVER_DURATION, false, function D_EndHangover)
    set t = null
endfunction

private function D_GetPassOutAnimation takes unit whichUnit returns string
    local string animationName = D_PassOutAnimation.string[GetUnitTypeId(whichUnit)]
    if animationName == null or animationName == "" then
        return "sleep"
    endif
    return animationName
endfunction

private function D_FireWakeHandlers takes unit whichUnit returns nothing
    set Drunk_WakeUnit = whichUnit
    if D_WakeHandlers != null then
        call TriggerExecute(D_WakeHandlers)
    endif
    set Drunk_WakeUnit = null
endfunction

private function D_WakeFromPassOut takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)
    local unit whichUnit = D_Unit[unitId]
    local player owner

    set D_PassOutTimer[unitId] = null
    if D_SleepEffect[unitId] != null then
        call DestroyEffect(D_SleepEffect[unitId])
        set D_SleepEffect[unitId] = null
    endif
    if whichUnit != null then
        if not D_HadSleepAbility[unitId] then
            call UnitRemoveAbility(whichUnit, D_SLEEP_ABILITY_ID)
        endif
        call Companions_SetExternalOrderOverride(whichUnit, false)
        if not D_WasPaused[unitId] and D_IsUnitAlive(whichUnit) then
            call PauseUnit(whichUnit, false)
        endif
        if D_IsUnitAlive(whichUnit) then
            call SetUnitAnimation(whichUnit, "stand")
            call D_StartHangover(whichUnit, unitId)
            if whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis then
                call VoicelinesDrunk_PickWakeLine(whichUnit)
                call DialogSystem_QueueFieldLine(whichUnit, "", VoicelinesDrunk_PickedKey, VoicelinesDrunk_PickedText)
            endif
            call D_FireWakeHandlers(whichUnit)
        endif
        set owner = GetOwningPlayer(whichUnit)
        if D_CameraSuspendedByPassOut[unitId] then
            if GetLocalPlayer() == owner then
                call DisplayCineFilter(false)
            endif
            call CameraControl_ResumeWithDuration(owner, 0.75)
        endif
    endif
    set D_PassedOut[unitId] = false
    set D_WasPaused[unitId] = false
    set D_HadSleepAbility[unitId] = false
    set D_CameraSuspendedByPassOut[unitId] = false
    if D_UnitLevel[unitId] <= 0.00 and not D_Hangover[unitId] and not D_Puking[unitId] then
        set D_Unit[unitId] = null
    endif
    call ReleaseTimer(expired)
    set expired = null
    set whichUnit = null
    set owner = null
endfunction

private function D_RelocatePassedOut takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)
    local unit whichUnit = D_Unit[unitId]
    local player owner
    local rect destination
    local real x
    local real y

    if whichUnit == null or not D_PassedOut[unitId] then
        set D_PassOutTimer[unitId] = null
        call ReleaseTimer(expired)
        set expired = null
        set whichUnit = null
        return
    endif
    if D_PassOutRectCount > 0 then
        set destination = D_PassOutRect[GetRandomInt(1, D_PassOutRectCount)]
        set x = GetRandomReal(GetRectMinX(destination), GetRectMaxX(destination))
        set y = GetRandomReal(GetRectMinY(destination), GetRectMaxY(destination))
        call SetUnitPosition(whichUnit, x, y)
    endif
    set owner = GetOwningPlayer(whichUnit)
    if D_CameraSuspendedByPassOut[unitId] then
        call PanCameraToTimedForPlayer(owner, GetUnitX(whichUnit), GetUnitY(whichUnit), 0.00)
        call D_ShowBlackFade(owner, false, D_PASSOUT_FADE_IN)
    endif
    call TimerStart(expired, D_PASSOUT_FADE_IN + D_PASSOUT_SLEEP_AFTER_FADE, false, function D_WakeFromPassOut)
    set expired = null
    set whichUnit = null
    set owner = null
    set destination = null
endfunction

private function D_StartPassOut takes unit whichUnit, integer unitId returns nothing
    local timer t
    local player owner = GetOwningPlayer(whichUnit)
    local boolean playerHero = owner == Player(0) and (whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis)

    if D_PassedOut[unitId] then
        set owner = null
        return
    endif
    if D_Puking[unitId] then
        if D_PukeTimer[unitId] != null then
            call PauseTimer(D_PukeTimer[unitId])
            call ReleaseTimer(D_PukeTimer[unitId])
            set D_PukeTimer[unitId] = null
        endif
        call D_RemovePuke(unitId)
    endif
    set D_PassedOut[unitId] = true
    set D_WasPaused[unitId] = IsUnitPaused(whichUnit)
    set D_HadSleepAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_SLEEP_ABILITY_ID) > 0
    if not D_HadSleepAbility[unitId] then
        call UnitAddAbility(whichUnit, D_SLEEP_ABILITY_ID)
    endif
    call IssueImmediateOrder(whichUnit, "stop")
    call SetUnitAnimation(whichUnit, D_GetPassOutAnimation(whichUnit))
    call PauseUnit(whichUnit, true)
    set D_SleepEffect[unitId] = AddSpecialEffectTarget(D_PASSOUT_EFFECT, whichUnit, D_PASSOUT_ATTACH)
    call Companions_SetExternalOrderOverride(whichUnit, true)
    call D_PlayReaction(whichUnit, true)

    call D_ReleaseUnitTimer(unitId)
    if D_UnitEffect[unitId] != null then
        call DestroyEffect(D_UnitEffect[unitId])
        set D_UnitEffect[unitId] = null
    endif
    set D_UnitLevel[unitId] = 0.00
    call GroupRemoveUnit(D_DrunkUnits, whichUnit)
    if not D_HadDrunkAbility[unitId] then
        call UnitRemoveAbility(whichUnit, D_DRUNK_ABILITY_ID)
    endif
    set D_HadDrunkAbility[unitId] = false
    call D_RefreshPlayersForUnit(whichUnit)

    set t = NewTimer()
    set D_PassOutTimer[unitId] = t
    call SetTimerData(t, unitId)
    if playerHero then
        if not udg_InCinematic and CameraControl_GetTargetUnit(owner) == whichUnit and not CameraControl_IsSuspended(owner) then
            set D_CameraSuspendedByPassOut[unitId] = true
            call CameraControl_Suspend(owner)
            call D_ShowBlackFade(owner, true, D_PASSOUT_FADE_OUT)
        endif
        call TimerStart(t, D_PASSOUT_FADE_OUT, false, function D_RelocatePassedOut)
    else
        call TimerStart(t, D_AI_PASSOUT_TIME, false, function D_WakeFromPassOut)
    endif
    set t = null
    set owner = null
endfunction

private function D_TryDrinkEvent takes unit whichUnit, integer unitId returns nothing
    local real level = D_NormalizeLevel(D_UnitLevel[unitId])
    local real chance

    if D_PassedOut[unitId] or D_TickCount < D_NextEventTick[unitId] then
        return
    endif
    if level >= D_PASSOUT_MIN_LEVEL then
        set chance = D_PASSOUT_BASE_CHANCE + D_PASSOUT_MAX_CHANCE*level*level*level*level
        if GetRandomReal(0.00, 100.00) <= chance then
            set D_NextEventTick[unitId] = D_TickCount + R2I(D_EVENT_COOLDOWN/D_TICK_PERIOD)
            call D_StartPassOut(whichUnit, unitId)
            return
        endif
    endif
    if level >= D_PUKE_MIN_LEVEL then
        set chance = D_PUKE_BASE_CHANCE + D_PUKE_MAX_CHANCE*level*level
        if GetRandomReal(0.00, 100.00) <= chance then
            set D_NextEventTick[unitId] = D_TickCount + R2I(D_EVENT_COOLDOWN/D_TICK_PERIOD)
            call D_StartPuke(whichUnit, unitId)
        endif
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
    if D_PukeTimer[unitId] != null then
        call PauseTimer(D_PukeTimer[unitId])
        call ReleaseTimer(D_PukeTimer[unitId])
        set D_PukeTimer[unitId] = null
    endif
    call D_RemovePuke(unitId)
    if D_PassOutTimer[unitId] != null then
        call PauseTimer(D_PassOutTimer[unitId])
        call ReleaseTimer(D_PassOutTimer[unitId])
        set D_PassOutTimer[unitId] = null
    endif
    if D_SleepEffect[unitId] != null then
        call DestroyEffect(D_SleepEffect[unitId])
        set D_SleepEffect[unitId] = null
    endif
    if D_PassedOut[unitId] and whichUnit != null then
        call Companions_SetExternalOrderOverride(whichUnit, false)
        if not D_HadSleepAbility[unitId] then
            call UnitRemoveAbility(whichUnit, D_SLEEP_ABILITY_ID)
        endif
        if not D_WasPaused[unitId] and D_IsUnitAlive(whichUnit) then
            call PauseUnit(whichUnit, false)
            call SetUnitAnimation(whichUnit, "stand")
        endif
        if D_CameraSuspendedByPassOut[unitId] then
            if GetLocalPlayer() == GetOwningPlayer(whichUnit) then
                call DisplayCineFilter(false)
            endif
            call CameraControl_ResumeWithDuration(GetOwningPlayer(whichUnit), 0.75)
        endif
    endif
    if D_HangoverTimer[unitId] != null then
        call PauseTimer(D_HangoverTimer[unitId])
        call ReleaseTimer(D_HangoverTimer[unitId])
        set D_HangoverTimer[unitId] = null
    endif
    call D_RemoveHangover(unitId)
    if whichUnit != null and not D_HadDrunkAbility[unitId] then
        call UnitRemoveAbility(whichUnit, D_DRUNK_ABILITY_ID)
    endif
    set D_UnitLevel[unitId] = 0.00
    set D_NextMishapTick[unitId] = 0
    set D_NextEventTick[unitId] = 0
    set D_HadDrunkAbility[unitId] = false
    set D_PassedOut[unitId] = false
    set D_WasPaused[unitId] = false
    set D_HadSleepAbility[unitId] = false
    set D_CameraSuspendedByPassOut[unitId] = false
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
        if whichUnit != null and not D_HadDrunkAbility[unitId] then
            call UnitRemoveAbility(whichUnit, D_DRUNK_ABILITY_ID)
        endif
        set D_HadDrunkAbility[unitId] = false
        if not D_Puking[unitId] and not D_PassedOut[unitId] and not D_Hangover[unitId] then
            set D_Unit[unitId] = null
        endif
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

    if whichUnit == null or unitId <= 0 or amount <= 0.00 or D_PassedOut[unitId] then
        return
    endif

    set D_Unit[unitId] = whichUnit
    if D_UnitLevel[unitId] <= 0.00 then
        set D_HadDrunkAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_DRUNK_ABILITY_ID) > 0
        if not D_HadDrunkAbility[unitId] then
            call UnitAddAbility(whichUnit, D_DRUNK_ABILITY_ID)
            call BlzUnitHideAbility(whichUnit, D_DRUNK_ABILITY_ID, true)
        endif
    endif
    set D_UnitLevel[unitId] = D_ClampLevel(D_UnitLevel[unitId] + amount)
    call GroupAddUnit(D_DrunkUnits, whichUnit)
    call D_ScheduleNextMishap(unitId, D_NormalizeLevel(D_UnitLevel[unitId]))
    if D_UnitEffect[unitId] == null then
        set D_UnitEffect[unitId] = AddSpecialEffectTarget(D_TARGET_EFFECT, whichUnit, D_TARGET_ATTACH)
    endif

    call D_StartTimer(unitId, duration)
    call D_RefreshPlayersForUnit(whichUnit)
    call D_TryDrinkEvent(whichUnit, unitId)
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

public function RegisterPassOutRect takes rect whichRect returns nothing
    if whichRect == null or D_PassOutRectCount >= D_MAX_PASSOUT_RECTS then
        set whichRect = null
        return
    endif
    set D_PassOutRectCount = D_PassOutRectCount + 1
    set D_PassOutRect[D_PassOutRectCount] = whichRect
    set whichRect = null
endfunction

// Models cannot report their animation names at runtime. Register "death" or
// "decay" here for unit types that do not provide a sleep animation.
public function SetPassOutAnimation takes integer unitTypeId, string animationName returns nothing
    if unitTypeId == 0 or animationName == null or animationName == "" then
        return
    endif
    set D_PassOutAnimation.string[unitTypeId] = animationName
endfunction

public function RegisterWakeHandler takes code handler returns nothing
    if handler == null then
        return
    endif
    if D_WakeHandlers == null then
        set D_WakeHandlers = CreateTrigger()
    endif
    call TriggerAddAction(D_WakeHandlers, handler)
endfunction

public function GetWakeUnit takes nothing returns unit
    return Drunk_WakeUnit
endfunction

public function HasHangover takes unit whichUnit returns boolean
    local integer unitId = D_GetUnitId(whichUnit)
    if unitId <= 0 then
        return false
    endif
    return D_Hangover[unitId]
endfunction

private function Init takes nothing returns nothing
    set D_TimerGeneration = Table.create()
    set D_PassOutAnimation = Table.create()
    set D_DrunkUnits = CreateGroup()
    set D_TickTimer = CreateTimer()
    call TimerStart(D_TickTimer, D_TICK_PERIOD, true, function D_Tick)
endfunction

endlibrary
