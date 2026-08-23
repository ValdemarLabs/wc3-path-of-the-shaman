/**
    Drunk

    Author: Valdemar
    Version: 2.2.0

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
    call Drunk_Add(whichUnit, amount)
    call Drunk_Clear(whichUnit)
    set amount = Drunk_GetLevel(whichUnit)
    call Drunk_RefreshPlayer(whichPlayer)
    call Drunk_RegisterPassOutRect(whichRect)
    call Drunk_SetPassOutAnimation(unitTypeId, animationName)
    call Drunk_RegisterWakeHandler(function OnDrunkWake)
    set whichUnit = Drunk_GetWakeUnit()
    set hasHangover = Drunk_HasHangover(whichUnit)

**/

library Drunk initializer Init requires TimerUtils, Table, CameraControl, FullscreenUI, MasterUI, FallenHeroState, DialogSystem, AI, Companions, VoicelinesDrunk

globals
    // Core configuration.
    private constant real D_TICK_PERIOD = 0.35
    private constant integer D_MAX_LEVEL = 100
    private constant integer D_DECAY_AMOUNT = 1
    private constant integer D_DECAY_TICKS = 14
    private constant integer D_ABSORB_AMOUNT = 1
    private constant integer D_ABSORB_TICKS = 2
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
    private constant string D_PUKE_EFFECT = "Abilities\\Weapons\\ChimaeraAcidMissile\\ChimaeraAcidMissile.mdl"
    private constant real D_PUKE_EFFECT_SCALE = 0.65

    // Object Editor configuration. Replace these placeholders with hidden,
    // self-only aura abilities that display the Drunk, Puking, and Hangover
    // buffs. Puking should supply the visible miss-chance penalty.
    private constant integer D_DRUNK_ABILITY_ID = 'S01M'
    private constant integer D_PUKE_ABILITY_ID = 'S01O'
    private constant integer D_HANGOVER_ABILITY_ID = 'S01N'
    private constant integer D_SLEEP_ABILITY_ID = 'Asla'

    // Puke and pass-out tuning. Event chances are checked periodically while
    // drunk and scale steeply near the upper end of the stat.
    private constant real D_PUKE_MIN_LEVEL = 0.25
    private constant real D_PUKE_BASE_CHANCE = 0.20
    private constant real D_PUKE_MAX_CHANCE = 45.00
    private constant real D_PUKE_MOVE_DISTANCE = 250.00
    private constant real D_PUKE_MOVE_TIME = 1.00
    private constant real D_PUKE_SPEW_TIME = 2.00
    private constant real D_PUKE_AFTER_TIME = 10.00
    private constant real D_PUKE_MISSILE_PERIOD = 0.04
    private constant integer D_PUKE_MISSILE_STEPS = 12
    private constant real D_PUKE_SOURCE_HEIGHT = 115.00
    private constant real D_PUKE_TARGET_DISTANCE = 145.00
    private constant real D_PUKE_TARGET_HEIGHT = 8.00
    private constant real D_PUKE_ARMOR_PENALTY = 12.00
    private constant integer D_PUKE_HIT_PENALTY = 65
    private constant real D_PASSOUT_MIN_LEVEL = 0.45
    private constant real D_PASSOUT_BASE_CHANCE = 0.50
    private constant real D_PASSOUT_MAX_CHANCE = 60.00
    private constant real D_PASSOUT_FADE_OUT = 2.00
    private constant real D_PASSOUT_FADE_IN = 2.00
    private constant real D_PASSOUT_SLEEP_AFTER_FADE = 3.00
    private constant real D_PASSOUT_CAMERA_STEP = 1.25
    private constant real D_PASSOUT_CAMERA_FAR = 3000.00
    private constant real D_PASSOUT_CAMERA_MIDDLE = 1900.00
    private constant real D_PASSOUT_CAMERA_NEAR = 1050.00
    private constant real D_AI_PASSOUT_TIME = 8.00
    private constant real D_EVENT_COOLDOWN = 12.00
    private constant real D_REACTION_RANGE = 1600.00
    private constant real D_HANGOVER_DURATION = 300.00
    private constant integer D_MAX_PASSOUT_RECTS = 32
    private constant string D_PASSOUT_EFFECT = "Abilities\\Spells\\Other\\CreepSleep\\CreepSleepTarget.mdl"
    private constant string D_PASSOUT_ATTACH = "overhead"
    private constant string D_BLACK_FILTER = "ReplaceableTextures\\CameraMasks\\Black_mask.blp"

    private unit array D_Unit
    private effect array D_UnitEffect
    private integer array D_NextMishapTick
    private integer array D_NextEventTick
    private integer array D_NextDecayTick
    private integer array D_NextAbsorbTick
    private integer array D_PendingAlcohol
    private integer array D_LastNoticeBand
    private boolean array D_HadDrunkAbility
    private boolean array D_Puking
    private boolean array D_PukePenalized
    private boolean array D_HadPukeAbility
    private timer array D_PukeTimer
    private timer array D_PukePenaltyTimer
    private timer array D_PukeMissileTimer
    private effect array D_PukeMissile
    private real array D_PukeSourceX
    private real array D_PukeSourceY
    private real array D_PukeSourceZ
    private real array D_PukeTargetX
    private real array D_PukeTargetY
    private real array D_PukeTargetZ
    private integer array D_PukeMissileStep
    private boolean array D_PassedOut
    private boolean array D_WasPaused
    private boolean array D_HadSleepAbility
    private effect array D_SleepEffect
    private timer array D_PassOutTimer
    private boolean array D_CameraSuspendedByPassOut
    private boolean array D_WasInvulnerable
    private boolean array D_FullscreenWasEnabled
    private boolean array D_MasterButtonWasVisible
    private integer array D_PassOutCameraStage
    private boolean array D_Hangover
    private boolean array D_HadHangoverAbility
    private timer array D_HangoverTimer
    private group D_DrunkUnits = null

    private integer D_PassOutRectCount = 0
    private rect array D_PassOutRect
    private Table D_PassOutAnimation = 0
    private trigger D_WakeHandlers = null
    unit Drunk_WakeUnit = null
    private trigger D_PassOutRectInit = null

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

private function D_ClampLevel takes integer value returns integer
    if value < 0 then
        return 0
    elseif value > D_MAX_LEVEL then
        return D_MAX_LEVEL
    endif
    return value
endfunction

private function D_NormalizeLevel takes integer value returns real
    return I2R(D_ClampLevel(value))/I2R(D_MAX_LEVEL)
endfunction

private function D_GetFilterAlpha takes integer level returns integer
    return R2I(35.00 + D_NormalizeLevel(level) * 135.00)
endfunction

private function D_ShowFilter takes player whichPlayer, integer level returns nothing
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
    return D_IsUnitAlive(whichUnit) and GetOwningPlayer(whichUnit) == whichPlayer and udg_Stats_Drunk[unitId] > 0
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
        call D_ShowFilter(whichPlayer, udg_Stats_Drunk[unitId])
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

private function D_IsPlayerPartyUnit takes unit whichUnit returns boolean
    return whichUnit == udg_Nazgrek or whichUnit == udg_Zulkis or (udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group))
endfunction

private function D_GetNoticeBand takes integer level returns integer
    if level >= 95 then
        return 5
    elseif level >= 80 then
        return 4
    elseif level >= 60 then
        return 3
    elseif level >= 40 then
        return 2
    elseif level >= 20 then
        return 1
    endif
    return 0
endfunction

private function D_ShowLevelNotice takes unit whichUnit, integer oldLevel, integer newLevel returns nothing
    local integer unitId = D_GetUnitId(whichUnit)
    local integer band = D_GetNoticeBand(newLevel)
    local string unitName
    local string message = ""

    if unitId <= 0 or newLevel <= oldLevel or band <= D_LastNoticeBand[unitId] or GetOwningPlayer(whichUnit) != Player(0) or not D_IsPlayerPartyUnit(whichUnit) then
        return
    endif
    set unitName = GetUnitName(whichUnit)
    if band == 1 then
        set message = unitName + " is feeling light-headed."
    elseif band == 2 then
        set message = unitName + " is feeling dizzy."
    elseif band == 3 then
        set message = unitName + " is visibly drunk."
    elseif band == 4 then
        set message = unitName + " can barely stand."
    else
        set message = unitName + " is about to pass out..."
    endif
    set D_LastNoticeBand[unitId] = band
    call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 5.00, "|cffffcc66" + message + "|r")
endfunction

private function D_DestroyUnitVisual takes integer unitId returns nothing
    if D_UnitEffect[unitId] != null then
        call DestroyEffect(D_UnitEffect[unitId])
        set D_UnitEffect[unitId] = null
    endif
endfunction

private function D_GetTerrainZ takes real x, real y returns real
    local location point = Location(x, y)
    local real z = GetLocationZ(point)
    call RemoveLocation(point)
    set point = null
    return z
endfunction

private function D_DestroyPukeMissile takes integer unitId returns nothing
    if D_PukeMissile[unitId] != null then
        call DestroyEffect(D_PukeMissile[unitId])
        set D_PukeMissile[unitId] = null
    endif
endfunction

private function D_StopPuke takes integer unitId returns nothing
    local unit whichUnit = D_Unit[unitId]

    if D_PukeMissileTimer[unitId] != null then
        call PauseTimer(D_PukeMissileTimer[unitId])
        call ReleaseTimer(D_PukeMissileTimer[unitId])
        set D_PukeMissileTimer[unitId] = null
    endif
    call D_DestroyPukeMissile(unitId)
    if D_Puking[unitId] then
        if whichUnit != null then
            call Companions_SetExternalOrderOverride(whichUnit, false)
            if D_IsUnitAlive(whichUnit) and not D_PassedOut[unitId] then
                call SetUnitAnimation(whichUnit, "stand")
            endif
        endif
        set D_Puking[unitId] = false
    endif
    set whichUnit = null
endfunction

private function D_RemovePukePenalty takes integer unitId returns nothing
    local unit whichUnit = D_Unit[unitId]

    if D_PukePenalized[unitId] and whichUnit != null then
        set udg_Stats_Hit[unitId] = udg_Stats_Hit[unitId] + D_PUKE_HIT_PENALTY
        call BlzSetUnitArmor(whichUnit, BlzGetUnitArmor(whichUnit) + D_PUKE_ARMOR_PENALTY)
        if not D_HadPukeAbility[unitId] then
            call UnitRemoveAbility(whichUnit, D_PUKE_ABILITY_ID)
        endif
    endif
    set D_PukePenalized[unitId] = false
    set D_HadPukeAbility[unitId] = false
    set whichUnit = null
endfunction

private function D_EndPukePenalty takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)

    set D_PukePenaltyTimer[unitId] = null
    call D_RemovePukePenalty(unitId)
    if udg_Stats_Drunk[unitId] <= 0 and D_PendingAlcohol[unitId] <= 0 and not D_Puking[unitId] and not D_PassedOut[unitId] and not D_Hangover[unitId] then
        set D_Unit[unitId] = null
    endif
    call ReleaseTimer(expired)
    set expired = null
endfunction

private function D_SchedulePukePenaltyEnd takes integer unitId returns nothing
    local timer penaltyTimer

    if D_PukePenaltyTimer[unitId] != null then
        call PauseTimer(D_PukePenaltyTimer[unitId])
        call ReleaseTimer(D_PukePenaltyTimer[unitId])
    endif
    set penaltyTimer = NewTimer()
    set D_PukePenaltyTimer[unitId] = penaltyTimer
    call SetTimerData(penaltyTimer, unitId)
    call TimerStart(penaltyTimer, D_PUKE_AFTER_TIME, false, function D_EndPukePenalty)
    set penaltyTimer = null
endfunction

private function D_AdvancePukeMissile takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)
    local real progress

    set D_PukeMissileStep[unitId] = D_PukeMissileStep[unitId] + 1
    if D_PukeMissile[unitId] == null then
        set D_PukeMissileTimer[unitId] = null
        call ReleaseTimer(expired)
        set expired = null
        return
    endif
    set progress = I2R(D_PukeMissileStep[unitId])/I2R(D_PUKE_MISSILE_STEPS)
    call BlzSetSpecialEffectPosition(D_PukeMissile[unitId], D_PukeSourceX[unitId] + (D_PukeTargetX[unitId] - D_PukeSourceX[unitId])*progress, D_PukeSourceY[unitId] + (D_PukeTargetY[unitId] - D_PukeSourceY[unitId])*progress, D_PukeSourceZ[unitId] + (D_PukeTargetZ[unitId] - D_PukeSourceZ[unitId])*progress)
    if D_PukeMissileStep[unitId] >= D_PUKE_MISSILE_STEPS then
        call D_DestroyPukeMissile(unitId)
        set D_PukeMissileTimer[unitId] = null
        call ReleaseTimer(expired)
        set expired = null
        return
    endif
    set expired = null
endfunction

private function D_LaunchPukeMissile takes unit whichUnit, integer unitId returns nothing
    local real angle = GetUnitFacing(whichUnit)*bj_DEGTORAD
    local timer missileTimer = NewTimer()

    set D_PukeSourceX[unitId] = GetUnitX(whichUnit) + 22.00*Cos(angle)
    set D_PukeSourceY[unitId] = GetUnitY(whichUnit) + 22.00*Sin(angle)
    set D_PukeSourceZ[unitId] = D_GetTerrainZ(D_PukeSourceX[unitId], D_PukeSourceY[unitId]) + D_PUKE_SOURCE_HEIGHT
    set D_PukeTargetX[unitId] = GetUnitX(whichUnit) + D_PUKE_TARGET_DISTANCE*Cos(angle)
    set D_PukeTargetY[unitId] = GetUnitY(whichUnit) + D_PUKE_TARGET_DISTANCE*Sin(angle)
    set D_PukeTargetZ[unitId] = D_GetTerrainZ(D_PukeTargetX[unitId], D_PukeTargetY[unitId]) + D_PUKE_TARGET_HEIGHT
    set D_PukeMissileStep[unitId] = 0
    set D_PukeMissile[unitId] = AddSpecialEffect(D_PUKE_EFFECT, D_PukeSourceX[unitId], D_PukeSourceY[unitId])
    call BlzSetSpecialEffectPosition(D_PukeMissile[unitId], D_PukeSourceX[unitId], D_PukeSourceY[unitId], D_PukeSourceZ[unitId])
    call BlzSetSpecialEffectOrientation(D_PukeMissile[unitId], angle, -0.60, 0.00)
    call BlzSetSpecialEffectScale(D_PukeMissile[unitId], D_PUKE_EFFECT_SCALE)
    set D_PukeMissileTimer[unitId] = missileTimer
    call SetTimerData(missileTimer, unitId)
    call TimerStart(missileTimer, D_PUKE_MISSILE_PERIOD, true, function D_AdvancePukeMissile)
    set missileTimer = null
endfunction

private function D_EndPuke takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)

    set D_PukeTimer[unitId] = null
    call D_StopPuke(unitId)
    call D_SchedulePukePenaltyEnd(unitId)
    if udg_Stats_Drunk[unitId] <= 0 and D_PendingAlcohol[unitId] <= 0 and not D_PukePenalized[unitId] and not D_PassedOut[unitId] and not D_Hangover[unitId] then
        set D_Unit[unitId] = null
    endif
    call ReleaseTimer(expired)
    set expired = null
endfunction

private function D_BeginPuke takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)
    local unit whichUnit = D_Unit[unitId]

    if whichUnit == null or not D_IsUnitAlive(whichUnit) or D_PassedOut[unitId] then
        set D_PukeTimer[unitId] = null
        call D_StopPuke(unitId)
        call D_SchedulePukePenaltyEnd(unitId)
        call ReleaseTimer(expired)
        set expired = null
        set whichUnit = null
        return
    endif
    call IssueImmediateOrder(whichUnit, "stop")
    call SetUnitAnimation(whichUnit, "spell")
    call QueueUnitAnimation(whichUnit, "stand")
    call D_LaunchPukeMissile(whichUnit, unitId)
    call TimerStart(expired, D_PUKE_SPEW_TIME, false, function D_EndPuke)
    set expired = null
    set whichUnit = null
endfunction

private function D_StartPuke takes unit whichUnit, integer unitId returns nothing
    local timer t
    local real angle

    if D_Puking[unitId] or D_PassedOut[unitId] then
        return
    endif
    set D_Puking[unitId] = true
    call Companions_SetExternalOrderOverride(whichUnit, true)
    if D_PukePenaltyTimer[unitId] != null then
        call PauseTimer(D_PukePenaltyTimer[unitId])
        call ReleaseTimer(D_PukePenaltyTimer[unitId])
        set D_PukePenaltyTimer[unitId] = null
    endif
    if not D_PukePenalized[unitId] then
        set D_PukePenalized[unitId] = true
        set D_HadPukeAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_PUKE_ABILITY_ID) > 0
        if not D_HadPukeAbility[unitId] then
            call UnitAddAbility(whichUnit, D_PUKE_ABILITY_ID)
            call BlzUnitHideAbility(whichUnit, D_PUKE_ABILITY_ID, true)
        endif
        set udg_Stats_Hit[unitId] = udg_Stats_Hit[unitId] - D_PUKE_HIT_PENALTY
        call BlzSetUnitArmor(whichUnit, BlzGetUnitArmor(whichUnit) - D_PUKE_ARMOR_PENALTY)
    endif
    call D_PlayReaction(whichUnit, false)

    set angle = GetRandomReal(0.00, 2.00*bj_PI)
    call IssuePointOrder(whichUnit, "move", GetUnitX(whichUnit) + D_PUKE_MOVE_DISTANCE*Cos(angle), GetUnitY(whichUnit) + D_PUKE_MOVE_DISTANCE*Sin(angle))

    set t = NewTimer()
    set D_PukeTimer[unitId] = t
    call SetTimerData(t, unitId)
    call TimerStart(t, D_PUKE_MOVE_TIME, false, function D_BeginPuke)
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
    if udg_Stats_Drunk[unitId] <= 0 and D_PendingAlcohol[unitId] <= 0 and not D_Puking[unitId] and not D_PukePenalized[unitId] and not D_PassedOut[unitId] then
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
        if not D_WasInvulnerable[unitId] then
            call SetUnitInvulnerable(whichUnit, false)
        endif
        set owner = GetOwningPlayer(whichUnit)
        if D_CameraSuspendedByPassOut[unitId] then
            if GetLocalPlayer() == owner then
                call DisplayCineFilter(false)
            endif
            call CameraControl_ResumeWithDuration(owner, 0.75)
            if not D_FullscreenWasEnabled[unitId] then
                call FullscreenUI_SetEnabled(false)
            endif
        endif
        if D_MasterButtonWasVisible[unitId] then
            call MasterUI_ShowGameButton()
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
    endif
    set D_PassedOut[unitId] = false
    set D_WasPaused[unitId] = false
    set D_HadSleepAbility[unitId] = false
    set D_CameraSuspendedByPassOut[unitId] = false
    set D_WasInvulnerable[unitId] = false
    set D_FullscreenWasEnabled[unitId] = false
    set D_MasterButtonWasVisible[unitId] = false
    set D_PassOutCameraStage[unitId] = 0
    if udg_Stats_Drunk[unitId] <= 0 and not D_Hangover[unitId] and not D_Puking[unitId] and not D_PukePenalized[unitId] then
        set D_Unit[unitId] = null
    endif
    call ReleaseTimer(expired)
    set expired = null
    set whichUnit = null
    set owner = null
endfunction

private function D_AdvancePassOutCamera takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer unitId = GetTimerData(expired)
    local unit whichUnit = D_Unit[unitId]
    local player owner

    if whichUnit == null or not D_PassedOut[unitId] then
        set D_PassOutTimer[unitId] = null
        call ReleaseTimer(expired)
        set expired = null
        set whichUnit = null
        return
    endif
    set owner = GetOwningPlayer(whichUnit)
    set D_PassOutCameraStage[unitId] = D_PassOutCameraStage[unitId] + 1
    call PanCameraToTimedForPlayer(owner, GetUnitX(whichUnit), GetUnitY(whichUnit), D_PASSOUT_CAMERA_STEP)
    if D_PassOutCameraStage[unitId] == 1 then
        call SetCameraFieldForPlayer(owner, CAMERA_FIELD_TARGET_DISTANCE, D_PASSOUT_CAMERA_MIDDLE, D_PASSOUT_CAMERA_STEP)
        call TimerStart(expired, D_PASSOUT_CAMERA_STEP, false, function D_AdvancePassOutCamera)
    elseif D_PassOutCameraStage[unitId] == 2 then
        call SetCameraFieldForPlayer(owner, CAMERA_FIELD_TARGET_DISTANCE, D_PASSOUT_CAMERA_NEAR, D_PASSOUT_CAMERA_STEP)
        call TimerStart(expired, D_PASSOUT_CAMERA_STEP + D_PASSOUT_SLEEP_AFTER_FADE, false, function D_WakeFromPassOut)
    endif
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
        call SetCameraFieldForPlayer(owner, CAMERA_FIELD_TARGET_DISTANCE, D_PASSOUT_CAMERA_FAR, 0.00)
        call D_ShowBlackFade(owner, false, D_PASSOUT_FADE_IN)
        set D_PassOutCameraStage[unitId] = 0
        call TimerStart(expired, D_PASSOUT_FADE_IN, false, function D_AdvancePassOutCamera)
    else
        call TimerStart(expired, D_PASSOUT_SLEEP_AFTER_FADE, false, function D_WakeFromPassOut)
    endif
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
        call D_StopPuke(unitId)
    endif
    if D_PukePenaltyTimer[unitId] != null then
        call PauseTimer(D_PukePenaltyTimer[unitId])
        call ReleaseTimer(D_PukePenaltyTimer[unitId])
        set D_PukePenaltyTimer[unitId] = null
    endif
    call D_RemovePukePenalty(unitId)
    set D_PassedOut[unitId] = true
    set D_WasPaused[unitId] = IsUnitPaused(whichUnit)
    set D_WasInvulnerable[unitId] = BlzIsUnitInvulnerable(whichUnit)
    call SetUnitInvulnerable(whichUnit, true)
    set D_HadSleepAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_SLEEP_ABILITY_ID) > 0
    if not D_HadSleepAbility[unitId] then
        call UnitAddAbility(whichUnit, D_SLEEP_ABILITY_ID)
    endif
    call IssueImmediateOrder(whichUnit, "stop")
    call SetUnitAnimation(whichUnit, D_GetPassOutAnimation(whichUnit))
    call PauseUnit(whichUnit, true)
    set D_SleepEffect[unitId] = AddSpecialEffectTarget(D_PASSOUT_EFFECT, whichUnit, D_PASSOUT_ATTACH)
    call Companions_SetExternalOrderOverride(whichUnit, true)

    if D_UnitEffect[unitId] != null then
        call DestroyEffect(D_UnitEffect[unitId])
        set D_UnitEffect[unitId] = null
    endif
    set udg_Stats_Drunk[unitId] = 0
    set D_PendingAlcohol[unitId] = 0
    set D_LastNoticeBand[unitId] = 0
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
        set D_MasterButtonWasVisible[unitId] = MasterUI_IsGameButtonVisible()
        call MasterUI_HideGameButton()
        if not udg_InCinematic and CameraControl_GetTargetUnit(owner) == whichUnit and not CameraControl_IsSuspended(owner) then
            set D_CameraSuspendedByPassOut[unitId] = true
            set D_FullscreenWasEnabled[unitId] = FullscreenUI_IsEnabled()
            call FullscreenUI_SetEnabled(true)
            call CameraControl_Suspend(owner)
            call D_ShowBlackFade(owner, true, D_PASSOUT_FADE_OUT)
        endif
        call D_PlayReaction(whichUnit, true)
        call TimerStart(t, D_PASSOUT_FADE_OUT, false, function D_RelocatePassedOut)
    else
        call TimerStart(t, D_AI_PASSOUT_TIME, false, function D_WakeFromPassOut)
    endif
    set t = null
    set owner = null
endfunction

private function D_TryDrinkEvent takes unit whichUnit, integer unitId returns nothing
    local real level = D_NormalizeLevel(udg_Stats_Drunk[unitId])
    local real chance

    if D_PassedOut[unitId] or D_Puking[unitId] or D_TickCount < D_NextEventTick[unitId] or level < D_PUKE_MIN_LEVEL then
        return
    endif
    set D_NextEventTick[unitId] = D_TickCount + R2I(D_EVENT_COOLDOWN/D_TICK_PERIOD)
    if level >= D_PASSOUT_MIN_LEVEL then
        set chance = D_PASSOUT_BASE_CHANCE + D_PASSOUT_MAX_CHANCE*level*level*level*level
        if GetRandomReal(0.00, 100.00) <= chance then
            call D_StartPassOut(whichUnit, unitId)
            return
        endif
    endif
    set chance = D_PUKE_BASE_CHANCE + D_PUKE_MAX_CHANCE*level*level*level*level
    if GetRandomReal(0.00, 100.00) <= chance then
        call D_StartPuke(whichUnit, unitId)
    endif
endfunction

private function D_ClearById takes integer unitId returns nothing
    local unit whichUnit = D_Unit[unitId]

    if unitId <= 0 then
        set whichUnit = null
        return
    endif

    call D_DestroyUnitVisual(unitId)
    if D_PukeTimer[unitId] != null then
        call PauseTimer(D_PukeTimer[unitId])
        call ReleaseTimer(D_PukeTimer[unitId])
        set D_PukeTimer[unitId] = null
    endif
    call D_StopPuke(unitId)
    if D_PukePenaltyTimer[unitId] != null then
        call PauseTimer(D_PukePenaltyTimer[unitId])
        call ReleaseTimer(D_PukePenaltyTimer[unitId])
        set D_PukePenaltyTimer[unitId] = null
    endif
    call D_RemovePukePenalty(unitId)
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
        if not D_WasInvulnerable[unitId] then
            call SetUnitInvulnerable(whichUnit, false)
        endif
        if D_CameraSuspendedByPassOut[unitId] then
            if GetLocalPlayer() == GetOwningPlayer(whichUnit) then
                call DisplayCineFilter(false)
            endif
            call CameraControl_ResumeWithDuration(GetOwningPlayer(whichUnit), 0.75)
            if not D_FullscreenWasEnabled[unitId] then
                call FullscreenUI_SetEnabled(false)
            endif
        endif
        if D_MasterButtonWasVisible[unitId] then
            call MasterUI_ShowGameButton()
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
    set udg_Stats_Drunk[unitId] = 0
    set D_PendingAlcohol[unitId] = 0
    set D_NextAbsorbTick[unitId] = 0
    set D_NextDecayTick[unitId] = 0
    set D_LastNoticeBand[unitId] = 0
    set D_NextMishapTick[unitId] = 0
    set D_NextEventTick[unitId] = 0
    set D_HadDrunkAbility[unitId] = false
    set D_PassedOut[unitId] = false
    set D_WasPaused[unitId] = false
    set D_HadSleepAbility[unitId] = false
    set D_CameraSuspendedByPassOut[unitId] = false
    set D_WasInvulnerable[unitId] = false
    set D_FullscreenWasEnabled[unitId] = false
    set D_MasterButtonWasVisible[unitId] = false
    set D_PassOutCameraStage[unitId] = 0
    call GroupRemoveUnit(D_DrunkUnits, whichUnit)
    set D_Unit[unitId] = null

    call D_RefreshPlayersForUnit(whichUnit)
    set whichUnit = null
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

    set level = D_NormalizeLevel(udg_Stats_Drunk[unitId])
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

private function D_ApplyAlcohol takes nothing returns nothing
    local unit whichUnit = GetEnumUnit()
    local integer unitId = D_GetUnitId(whichUnit)
    local integer oldLevel

    if unitId <= 0 or not D_IsUnitAlive(whichUnit) or D_PassedOut[unitId] then
        set whichUnit = null
        return
    endif
    if D_PendingAlcohol[unitId] > 0 then
        if D_NextAbsorbTick[unitId] <= 0 then
            set D_NextAbsorbTick[unitId] = D_TickCount + D_ABSORB_TICKS
        elseif D_TickCount >= D_NextAbsorbTick[unitId] then
            set oldLevel = udg_Stats_Drunk[unitId]
            set udg_Stats_Drunk[unitId] = D_ClampLevel(oldLevel + D_ABSORB_AMOUNT)
            set D_PendingAlcohol[unitId] = D_PendingAlcohol[unitId] - D_ABSORB_AMOUNT
            if D_PendingAlcohol[unitId] < 0 or udg_Stats_Drunk[unitId] >= D_MAX_LEVEL then
                set D_PendingAlcohol[unitId] = 0
            endif
            set D_NextAbsorbTick[unitId] = D_TickCount + D_ABSORB_TICKS
            if D_PendingAlcohol[unitId] <= 0 then
                set D_NextDecayTick[unitId] = D_TickCount + D_DECAY_TICKS
            endif
            call D_ShowLevelNotice(whichUnit, oldLevel, udg_Stats_Drunk[unitId])
            call D_RefreshPlayersForUnit(whichUnit)
        endif
    elseif D_NextDecayTick[unitId] <= 0 then
        set D_NextDecayTick[unitId] = D_TickCount + D_DECAY_TICKS
    elseif D_TickCount >= D_NextDecayTick[unitId] then
        set udg_Stats_Drunk[unitId] = D_ClampLevel(udg_Stats_Drunk[unitId] - D_DECAY_AMOUNT)
        set D_NextDecayTick[unitId] = D_TickCount + D_DECAY_TICKS
        if udg_Stats_Drunk[unitId] <= 0 then
            call D_DestroyUnitVisual(unitId)
            call GroupRemoveUnit(D_DrunkUnits, whichUnit)
            if not D_HadDrunkAbility[unitId] then
                call UnitRemoveAbility(whichUnit, D_DRUNK_ABILITY_ID)
            endif
            set D_HadDrunkAbility[unitId] = false
            set D_LastNoticeBand[unitId] = 0
            set D_NextMishapTick[unitId] = 0
            if not D_Puking[unitId] and not D_PukePenalized[unitId] and not D_PassedOut[unitId] and not D_Hangover[unitId] then
                set D_Unit[unitId] = null
            endif
        endif
        call D_RefreshPlayersForUnit(whichUnit)
    endif
    call D_TryDrinkEvent(whichUnit, unitId)
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
    call ForGroup(D_DrunkUnits, function D_ApplyAlcohol)
    call ForGroup(D_DrunkUnits, function D_ApplyMishap)

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        set whichPlayer = Player(playerIndex)
        set whichUnit = D_GetPlayerViewUnit(whichPlayer)
        set unitId = D_GetUnitId(whichUnit)

        if D_ShouldPlayerSeeDrunkUnit(whichPlayer, whichUnit) then
            set level = D_NormalizeLevel(udg_Stats_Drunk[unitId])
            set D_FilterActive[playerIndex] = true
            call D_ShowFilter(whichPlayer, udg_Stats_Drunk[unitId])
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

public function Add takes unit whichUnit, integer amount returns nothing
    local integer unitId = D_GetUnitId(whichUnit)
    local integer oldLevel
    local integer available

    if whichUnit == null or unitId <= 0 or amount <= 0 or D_PassedOut[unitId] then
        return
    endif

    set D_Unit[unitId] = whichUnit
    set oldLevel = udg_Stats_Drunk[unitId]
    if oldLevel <= 0 and D_PendingAlcohol[unitId] <= 0 then
        set D_HadDrunkAbility[unitId] = GetUnitAbilityLevel(whichUnit, D_DRUNK_ABILITY_ID) > 0
        if not D_HadDrunkAbility[unitId] then
            call UnitAddAbility(whichUnit, D_DRUNK_ABILITY_ID)
            call BlzUnitHideAbility(whichUnit, D_DRUNK_ABILITY_ID, true)
        endif
    endif
    set available = D_MAX_LEVEL - oldLevel - D_PendingAlcohol[unitId]
    if amount > available then
        set amount = available
    endif
    if amount <= 0 then
        return
    endif
    set D_PendingAlcohol[unitId] = D_PendingAlcohol[unitId] + amount
    set D_NextAbsorbTick[unitId] = D_TickCount + D_ABSORB_TICKS
    set D_NextDecayTick[unitId] = 0
    call GroupAddUnit(D_DrunkUnits, whichUnit)
    if D_UnitEffect[unitId] == null then
        set D_UnitEffect[unitId] = AddSpecialEffectTarget(D_TARGET_EFFECT, whichUnit, D_TARGET_ATTACH)
    endif

    call D_RefreshPlayersForUnit(whichUnit)
endfunction

public function Clear takes unit whichUnit returns nothing
    call D_ClearById(D_GetUnitId(whichUnit))
endfunction

public function GetLevel takes unit whichUnit returns integer
    local integer unitId = D_GetUnitId(whichUnit)
    if unitId <= 0 then
        return 0
    endif
    return udg_Stats_Drunk[unitId]
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

private function D_RegisterPassOutRects takes nothing returns nothing
    // Register all allowed player pass-out destinations here.
    call Drunk_RegisterPassOutRect(gg_rct_Passout1)
    call Drunk_RegisterPassOutRect(gg_rct_Passout2)
    call Drunk_RegisterPassOutRect(gg_rct_Passout3)
    call Drunk_RegisterPassOutRect(gg_rct_Passout4)
    call Drunk_RegisterPassOutRect(gg_rct_Passout5)
    call Drunk_RegisterPassOutRect(gg_rct_Passout6)
    call Drunk_RegisterPassOutRect(gg_rct_Passout7)
    call Drunk_RegisterPassOutRect(gg_rct_Passout8)
    call Drunk_RegisterPassOutRect(gg_rct_Passout9)
    call Drunk_RegisterPassOutRect(gg_rct_Passout10)
    call Drunk_RegisterPassOutRect(gg_rct_Passout11)
    call Drunk_RegisterPassOutRect(gg_rct_Passout12)
    call Drunk_RegisterPassOutRect(gg_rct_Passout13)
    call Drunk_RegisterPassOutRect(gg_rct_Passout14)
    call Drunk_RegisterPassOutRect(gg_rct_Passout15)

    // Initialization is one-shot, so the trigger is no longer needed.
    call DestroyTrigger(D_PassOutRectInit)
    set D_PassOutRectInit = null
endfunction

private function Init takes nothing returns nothing
    set D_PassOutAnimation = Table.create()
    set D_DrunkUnits = CreateGroup()
    set D_TickTimer = CreateTimer()
    call TimerStart(D_TickTimer, D_TICK_PERIOD, true, function D_Tick)

    // Delay map-specific rect registration until preplaced rects exist.
    set D_PassOutRectInit = CreateTrigger()
    call TriggerRegisterTimerEvent(D_PassOutRectInit, 0.10, false)
    call TriggerAddAction(D_PassOutRectInit, function D_RegisterPassOutRects)
endfunction

endlibrary
