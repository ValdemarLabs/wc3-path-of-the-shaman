library TerrainDamage initializer Init requires SoundTools, TimerUtils, Table, UnitDeathEvent
//===========================================================================

/*    TerrainDamage library

        Author: Valdemar

        Description:
        - This library provides a framework for creating damaging terrain effects in Warcraft 3.
        - You can configure which GUI unit groups are processed for terrain damage.
        - A global scan timer detects terrain state, while each affected unit owns its own local damage timer.
*/

//===========================================================================

globals
    // ============ CONFIGURATION ============

    // === Terrain types
    private constant integer TERRAIN_LAVA = 'Dlvc'      // "Lava Cracks" tile
    private constant integer TERRAIN_FEL  = 'Cpos'      // "Poison" tile

    // === Ignore marker ability
    private constant integer TERRAIN_DAMAGE_IGNORE_ABILITY = 'X666' // Units with this ability are ignored by TerrainDamage

    // === Scanner settings
    private constant boolean DEBUG = false
    private constant boolean DEBUG_BYPASS_SYSTEM = true // Hard debug bypass: skips all TerrainDamage setup and runtime timers
    private constant real SCAN_INTERVAL = 0.40          // How often tracked units are checked for damaging terrain
    private constant real PLAYER_RESYNC_INTERVAL = 10.00 // Slow safety resync for registered players; avoids full player scans every Periodic tick
    private constant real MIN_FIRST_TICK_DELAY = 0.20   // Prevents first damage from firing instantly when desyncing unit timers
    private constant integer TERRAIN_DAMAGE_MAX_PLAYER_INDEX = 27
    private constant integer TERRAIN_SOUND_VOLUME_NORMAL = 127
    private constant integer TERRAIN_SOUND_VOLUME_CORPSE = 64

    // === Damage settings
    private constant real LAVA_DAMAGE_PERCENT = 0.15    // Percent of max HP dealt per tick (e.g. 0.05 = 5%)
    private constant real FEL_DAMAGE_PERCENT  = 0.05    // Percent of max HP dealt per tick (e.g. 0.05 = 5%)

    // === Interval settings
        // Example:
        /*
        If START == END, there is no ramp. The terrain stays on a fixed interval.
        If RAMP_DURATION <= 0.00, there is no ramp.
        If START > END, damage accelerates over time because ticks become more frequent.
        If START < END, damage slows down over time.
        */ 
    private constant real LAVA_INTERVAL_START = 1.50
    private constant real LAVA_INTERVAL_END   = 1.00
    private constant real LAVA_RAMP_DURATION  = 10.00    // 0.00 keeps flat interval behavior

    private constant real FEL_INTERVAL_START = 1.50
    private constant real FEL_INTERVAL_END   = 1.00
    private constant real FEL_RAMP_DURATION  = 10.00     // Example accelerated terrain: start 1.50, end 0.60

    // === VISUALS
    private constant string LAVA_EFFECT = "Abilities\\Spells\\Human\\FlameStrike\\FlameStrikeEmbers.mdl"
    private constant string LAVA_ATTACH_POINT = "chest"
    private constant real LAVA_EFFECT_SCALE_START = 0.90
    private constant real LAVA_EFFECT_SCALE_END = 1.05

    private constant string FEL_EFFECT = "Abilities\\Spells\\Human\\FlameStrike\\FlameStrikeDamageTarget.mdl"
    private constant string FEL_ATTACH_POINT = "chest"
    private constant real FEL_EFFECT_SCALE_START = 0.90
    private constant real FEL_EFFECT_SCALE_END = 1.05
    private constant real TERRAIN_EFFECT_SCALE_VARIATION_FACTOR = 0.20 // Random scale variance grows with ramp progress

    // variations effects
    // "Abilities\\Spells\\Human\\FlameStrike\\FlameStrikeDamageTarget.mdl" // note: needs timed destroy
    // "Abilities\\Spells\\Other\\BreathOfFire\\BreathOfFireDamage.mdl" // note: needs timed destroy
    // "Abilities\\Spells\\Human\\FlameStrike\\FlameStrikeEmbers.mdl"

    // === SOUNDS
    private Sound LAVA_SOUND                            // Use SoundTools Sound struct, not native sound
    private string LAVA_SOUND_PATH = "Abilities\\Weapons\\FireballMissile\\FireBallMissileDeath.flac"
    private integer LAVA_SOUND_DURATION = 1477
    private constant boolean LAVA_SOUND_VARIATION = true
    private constant real LAVA_SOUND_PITCH_MIN = 0.85
    private constant real LAVA_SOUND_PITCH_MAX = 1.20

    private Sound FEL_SOUND                             // Use SoundTools Sound struct, not native sound
    private string FEL_SOUND_PATH = "Abilities\\Spells\\NightElf\\CorrosiveBreath\\CorrosiveBreathMissileLaunch1.flac"
    private integer FEL_SOUND_DURATION = 1101
    private constant boolean FEL_SOUND_VARIATION = true
    private constant real FEL_SOUND_PITCH_MIN = 0.85
    private constant real FEL_SOUND_PITCH_MAX = 1.20

    // variations for sounds
    //private string LAVA_SOUND_PATH = "Abilities\\Spells\\Other\\BreathOfFire\\BreathOfFire1.flac" // duration 1628
    //private string LAVA_SOUND_PATH = "Abilities\\Weapons\\FireballMissile\\FireBallMissileDeath.flac" // duration 1477

    // === GROUP CONFIGURATION
    private group array TerrainGroups                   // Array to hold registered groups for processing
    private integer TerrainGroupCount = 0

    // === PLAYER CONFIGURATION ===
    private player array TerrainPlayers
    private integer TerrainPlayerCount = 0
    private rect array TerrainPlayerTrackRects
    private integer TerrainPlayerTrackRectCount = 0
    private group TerrainPlayerScanGroup = CreateGroup()
    private group TerrainPlayerGroup = CreateGroup()
    private trigger TerrainPlayerIndexedTrig
    private trigger TerrainPlayerCreatedTrig
    private trigger TerrainPlayerRemovedTrig
    private trigger TerrainPlayerTransformedTrig
    private trigger TerrainPlayerOwnerChangeTrig
    private trigger TerrainPlayerRectEnterTrig
    private trigger TerrainPlayerRectLeaveTrig
    private boolean TerrainPlayerTrackingReady = false

    // === INTERNAL OPTIONAL GROUP (API USERS)
    private group TerrainDamageGroup = CreateGroup()

    // === PER-UNIT TIMER STATE ===
    private Table TerrainUnitTimers                     // timer by unit user data id
    private Table TerrainUnitTerrainTypes               // active terrain type by unit user data id
    private Table TerrainUnitCurrentIntervals           // current armed timeout by unit user data id
    private Table TerrainUnitElapsedTimes               // accumulated time on terrain by unit user data id
    private Table TerrainUnitLastScanPass               // de-duplicate units scanned multiple times during the same periodic pass
    private Table TerrainIgnoredUnitTypes               // ignored unit types
    private Table TerrainIgnoredPlayers                 // ignored owner player ids
    private integer TerrainDamageScanPass = 0

endglobals

//===========================================================================
private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("[TerrainDamage] " + msg)
    endif
endfunction

//===========================================================================
// Helper: units marked as being on a bridge are ignored by terrain damage.
private function TerrainDamage_IsUnitProtectedByBridge takes unit u returns boolean
    local integer unitIndex = 0

    if u == null then
        return false
    endif

    set unitIndex = GetUnitUserData(u)
    if unitIndex > 0 then
        return udg_IsUnitOnBridge[unitIndex]
    endif

    return false
endfunction

//===========================================================================
private function TerrainDamage_IsUnitValid takes unit u returns boolean
    return u != null and GetUnitTypeId(u) != 0
endfunction

//===========================================================================
private function TerrainDamage_IsUnitAlive takes unit u returns boolean
    return TerrainDamage_IsUnitValid(u) and not IsUnitType(u, UNIT_TYPE_DEAD) and GetUnitState(u, UNIT_STATE_LIFE) > 0.405
endfunction

//===========================================================================
private function TerrainDamage_ShouldIgnoreUnit takes unit u returns boolean
    return TerrainDamage_IsUnitValid(u) and (GetUnitAbilityLevel(u, TERRAIN_DAMAGE_IGNORE_ABILITY) > 0 or TerrainIgnoredUnitTypes.boolean[GetUnitTypeId(u)] or TerrainIgnoredPlayers.boolean[GetPlayerId(GetOwningPlayer(u))])
endfunction

//===========================================================================
private function TerrainDamage_GetTerrainTypeAtUnit takes unit u returns integer
    local integer terrainType

    if not TerrainDamage_IsUnitValid(u) then
        return 0
    endif

    if TerrainDamage_ShouldIgnoreUnit(u) then
        return 0
    endif

    if TerrainDamage_IsUnitProtectedByBridge(u) then
        return 0
    endif

    set terrainType = GetTerrainType(GetUnitX(u), GetUnitY(u))
    if terrainType == TERRAIN_LAVA or terrainType == TERRAIN_FEL then
        return terrainType
    endif

    return 0
endfunction

//===========================================================================
private function TerrainDamage_UsesPlayerTrackRects takes nothing returns boolean
    return TerrainPlayerTrackRectCount > 0
endfunction

//===========================================================================
private function TerrainDamage_IsUnitInPlayerTrackRect takes unit u returns boolean
    local integer i = 0

    if not TerrainDamage_IsUnitValid(u) then
        return false
    endif

    if not TerrainDamage_UsesPlayerTrackRects() then
        return true
    endif

    loop
        exitwhen i >= TerrainPlayerTrackRectCount
        if RectContainsUnit(TerrainPlayerTrackRects[i], u) then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

//===========================================================================
private function TerrainDamage_IsUnitTrackedSource takes unit u returns boolean
    local integer i = 0

    if not TerrainDamage_IsUnitValid(u) then
        return false
    endif

    if IsUnitInGroup(u, TerrainDamageGroup) then
        return true
    endif

    if IsUnitInGroup(u, TerrainPlayerGroup) then
        return true
    endif

    loop
        exitwhen i >= TerrainGroupCount
        if IsUnitInGroup(u, TerrainGroups[i]) then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

//===========================================================================
private function TerrainDamage_GetTrackedTerrainType takes unit u returns integer
    if not TerrainDamage_IsUnitValid(u) then
        return 0
    endif

    if not TerrainDamage_IsUnitAlive(u) then
        return 0
    endif

    return TerrainDamage_GetTerrainTypeAtUnit(u)
endfunction

//===========================================================================
private function TerrainDamage_GetDamagePercent takes integer terrainType returns real
    if terrainType == TERRAIN_LAVA then
        return LAVA_DAMAGE_PERCENT
    elseif terrainType == TERRAIN_FEL then
        return FEL_DAMAGE_PERCENT
    endif

    return 0.00
endfunction

//===========================================================================
private function TerrainDamage_GetStartInterval takes integer terrainType returns real
    if terrainType == TERRAIN_LAVA then
        return LAVA_INTERVAL_START
    elseif terrainType == TERRAIN_FEL then
        return FEL_INTERVAL_START
    endif

    return 0.00
endfunction

//===========================================================================
private function TerrainDamage_GetEndInterval takes integer terrainType returns real
    if terrainType == TERRAIN_LAVA then
        return LAVA_INTERVAL_END
    elseif terrainType == TERRAIN_FEL then
        return FEL_INTERVAL_END
    endif

    return 0.00
endfunction

//===========================================================================
private function TerrainDamage_GetRampDuration takes integer terrainType returns real
    if terrainType == TERRAIN_LAVA then
        return LAVA_RAMP_DURATION
    elseif terrainType == TERRAIN_FEL then
        return FEL_RAMP_DURATION
    endif

    return 0.00
endfunction

//===========================================================================
private function TerrainDamage_ComputeInterval takes integer terrainType, real elapsedTime returns real
    local real startInterval = TerrainDamage_GetStartInterval(terrainType)
    local real endInterval = TerrainDamage_GetEndInterval(terrainType)
    local real rampDuration = TerrainDamage_GetRampDuration(terrainType)
    local real alpha

    if rampDuration <= 0.00 or startInterval == endInterval then
        return startInterval
    endif

    if elapsedTime >= rampDuration then
        return endInterval
    endif

    set alpha = elapsedTime / rampDuration
    return startInterval + (endInterval - startInterval) * alpha
endfunction

//===========================================================================
private function TerrainDamage_GetEffectScaleStart takes integer terrainType returns real
    if terrainType == TERRAIN_LAVA then
        return LAVA_EFFECT_SCALE_START
    elseif terrainType == TERRAIN_FEL then
        return FEL_EFFECT_SCALE_START
    endif

    return 1.00
endfunction

//===========================================================================
private function TerrainDamage_GetEffectScaleEnd takes integer terrainType returns real
    if terrainType == TERRAIN_LAVA then
        return LAVA_EFFECT_SCALE_END
    elseif terrainType == TERRAIN_FEL then
        return FEL_EFFECT_SCALE_END
    endif

    return 1.00
endfunction

//===========================================================================
private function TerrainDamage_ComputeEffectScale takes integer terrainType, real elapsedTime returns real
    local real startScale = TerrainDamage_GetEffectScaleStart(terrainType)
    local real endScale = TerrainDamage_GetEffectScaleEnd(terrainType)
    local real rampDuration = TerrainDamage_GetRampDuration(terrainType)
    local real alpha = 0.00
    local real baseScale
    local real variation
    local real minScale
    local real maxScale

    if rampDuration > 0.00 and startScale != endScale then
        if elapsedTime >= rampDuration then
            set alpha = 1.00
        elseif elapsedTime > 0.00 then
            set alpha = elapsedTime / rampDuration
        endif
    endif

    set baseScale = startScale + (endScale - startScale) * alpha
    set variation = RAbsBJ(endScale - startScale) * TERRAIN_EFFECT_SCALE_VARIATION_FACTOR * alpha

    if endScale >= startScale then
        set minScale = baseScale - (variation * 0.35)
        set maxScale = baseScale + variation
        if minScale < startScale then
            set minScale = startScale
        endif
        if maxScale > endScale then
            set maxScale = endScale
        endif
    else
        set minScale = baseScale - variation
        set maxScale = baseScale + (variation * 0.35)
        if minScale < endScale then
            set minScale = endScale
        endif
        if maxScale > startScale then
            set maxScale = startScale
        endif
    endif

    if minScale > maxScale then
        return baseScale
    endif

    return GetRandomReal(minScale, maxScale)
endfunction

//===========================================================================
private function TerrainDamage_GetInitialPhaseOffset takes integer unitId, real baseInterval returns real
    local real maxPhase

    if baseInterval <= MIN_FIRST_TICK_DELAY then
        return 0.00
    endif

    set maxPhase = baseInterval - MIN_FIRST_TICK_DELAY
    return maxPhase * I2R(ModuloInteger(unitId, 97)) / 96.00
endfunction

//===========================================================================
private function TerrainDamage_PlaySoundOnUnit takes Sound whichSound, unit u, integer volume, boolean useVariation, real minPitch, real maxPitch returns nothing
    local sound s = RunSoundOnUnit(whichSound, u)
    local real pitch = 1.00

    if useVariation then
        if minPitch > maxPitch then
            set pitch = GetRandomReal(maxPitch, minPitch)
        else
            set pitch = GetRandomReal(minPitch, maxPitch)
        endif
    endif

    call SetSoundVolume(s, volume)
    call whichSound.setSoundPitch(s, pitch)

    set s = null
endfunction

//===========================================================================
private function TerrainDamage_ApplyTick takes unit u, integer terrainType, real tickInterval, real elapsedTime returns nothing
    local real damage = GetUnitState(u, UNIT_STATE_MAX_LIFE) * TerrainDamage_GetDamagePercent(terrainType)
    local real effectScale = TerrainDamage_ComputeEffectScale(terrainType, elapsedTime)
    local effect e
    local boolean isAlive = TerrainDamage_IsUnitAlive(u)

    if TerrainDamage_ShouldIgnoreUnit(u) then
        call DebugMsg("ApplyTick skipped ignored unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)))
        return
    endif

    if isAlive then
        call DebugMsg("ApplyTick unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)) + " terrainType=" + I2S(terrainType) + " damage=" + R2S(damage) + " interval=" + R2S(tickInterval))
        call UnitDamageTarget(u, u, damage, false, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_FIRE, null)
    else
        call DebugMsg("ApplyTick corpse visuals only unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)) + " terrainType=" + I2S(terrainType) + " interval=" + R2S(tickInterval))
    endif

    if terrainType == TERRAIN_LAVA then
        set e = AddSpecialEffectTarget(LAVA_EFFECT, u, LAVA_ATTACH_POINT)
        call BlzSetSpecialEffectScale(e, effectScale)
        call DestroyEffect(e)
        if isAlive then
            call TerrainDamage_PlaySoundOnUnit(LAVA_SOUND, u, TERRAIN_SOUND_VOLUME_NORMAL, LAVA_SOUND_VARIATION, LAVA_SOUND_PITCH_MIN, LAVA_SOUND_PITCH_MAX)
        else
            call TerrainDamage_PlaySoundOnUnit(LAVA_SOUND, u, TERRAIN_SOUND_VOLUME_CORPSE, LAVA_SOUND_VARIATION, LAVA_SOUND_PITCH_MIN, LAVA_SOUND_PITCH_MAX)
        endif
    elseif terrainType == TERRAIN_FEL then
        set e = AddSpecialEffectTarget(FEL_EFFECT, u, FEL_ATTACH_POINT)
        call BlzSetSpecialEffectScale(e, effectScale)
        call SpeciFX_DestroyTimed(e, tickInterval)
        if isAlive then
            call TerrainDamage_PlaySoundOnUnit(FEL_SOUND, u, TERRAIN_SOUND_VOLUME_NORMAL, FEL_SOUND_VARIATION, FEL_SOUND_PITCH_MIN, FEL_SOUND_PITCH_MAX)
        else
            call TerrainDamage_PlaySoundOnUnit(FEL_SOUND, u, TERRAIN_SOUND_VOLUME_CORPSE, FEL_SOUND_VARIATION, FEL_SOUND_PITCH_MIN, FEL_SOUND_PITCH_MAX)
        endif
    endif

    set e = null
endfunction

//===========================================================================
private function TerrainDamage_ClearUnitState takes integer unitId returns nothing
    local timer t = TerrainUnitTimers.timer[unitId]

    if t != null then
        call DebugMsg("ClearUnitState unitId=" + I2S(unitId))
        call ReleaseTimer(t)
        call TerrainUnitTimers.timer.remove(unitId)
    endif

    call TerrainUnitTerrainTypes.integer.remove(unitId)
    call TerrainUnitCurrentIntervals.real.remove(unitId)
    call TerrainUnitElapsedTimes.real.remove(unitId)

    set t = null
endfunction

//===========================================================================
private function TerrainDamage_OnUnitTimer takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer unitId = GetTimerData(t)
    local unit u
    local integer expectedTerrainType = TerrainUnitTerrainTypes.integer[unitId]
    local integer currentTerrainType
    local real elapsedTime = TerrainUnitElapsedTimes.real[unitId] + TerrainUnitCurrentIntervals.real[unitId]
    local real nextInterval
    local timer nextTimer

    if unitId > 0 then
        set u = udg_UDexUnits[unitId]
    endif

    call DebugMsg("OnUnitTimer fired unitId=" + I2S(unitId))
    call ReleaseTimer(t)
    call TerrainUnitTimers.timer.remove(unitId)
    set t = null

    if not TerrainDamage_IsUnitValid(u) then
        call DebugMsg("OnUnitTimer abort invalid unit unitId=" + I2S(unitId))
        call TerrainDamage_ClearUnitState(unitId)
        set u = null
        return
    endif
    if not TerrainDamage_IsUnitTrackedSource(u) then
        call DebugMsg("OnUnitTimer abort untracked unit=" + GetUnitName(u) + " unitId=" + I2S(unitId))
        call TerrainDamage_ClearUnitState(unitId)
        set u = null
        return
    endif

    set currentTerrainType = TerrainDamage_GetTerrainTypeAtUnit(u)
    if currentTerrainType != expectedTerrainType then
        call DebugMsg("OnUnitTimer abort terrain mismatch unit=" + GetUnitName(u) + " unitId=" + I2S(unitId) + " current=" + I2S(currentTerrainType) + " expected=" + I2S(expectedTerrainType))
        call TerrainDamage_ClearUnitState(unitId)
        set u = null
        return
    endif

    call TerrainDamage_ApplyTick(u, expectedTerrainType, TerrainUnitCurrentIntervals.real[unitId], elapsedTime)

    set nextInterval = TerrainDamage_ComputeInterval(expectedTerrainType, elapsedTime)
    if nextInterval <= 0.00 then
        call DebugMsg("OnUnitTimer abort non-positive next interval unit=" + GetUnitName(u) + " unitId=" + I2S(unitId))
        call TerrainDamage_ClearUnitState(unitId)
        set u = null
        return
    endif

    set nextTimer = NewTimerEx(unitId)
    set TerrainUnitTerrainTypes.integer[unitId] = expectedTerrainType
    set TerrainUnitCurrentIntervals.real[unitId] = nextInterval
    set TerrainUnitElapsedTimes.real[unitId] = elapsedTime
    set TerrainUnitTimers.timer[unitId] = nextTimer
    call DebugMsg("OnUnitTimer rearm unit=" + GetUnitName(u) + " unitId=" + I2S(unitId) + " nextInterval=" + R2S(nextInterval) + " elapsed=" + R2S(elapsedTime))
    call TimerStart(nextTimer, nextInterval, false, function TerrainDamage_OnUnitTimer)

    set nextTimer = null
    set u = null
endfunction

//===========================================================================
private function TerrainDamage_ArmUnitTimer takes unit u, integer terrainType, real delay, real elapsedTime returns nothing
    local integer unitId = GetUnitUserData(u)
    local timer t

    if unitId <= 0 then
        call DebugMsg("ArmUnitTimer skipped unitId <= 0 for unit=" + GetUnitName(u))
        return
    endif

    set t = NewTimerEx(unitId)

    set TerrainUnitTerrainTypes.integer[unitId] = terrainType
    set TerrainUnitCurrentIntervals.real[unitId] = delay
    set TerrainUnitElapsedTimes.real[unitId] = elapsedTime
    set TerrainUnitTimers.timer[unitId] = t
    call DebugMsg("ArmUnitTimer unit=" + GetUnitName(u) + " unitId=" + I2S(unitId) + " terrainType=" + I2S(terrainType) + " delay=" + R2S(delay) + " elapsed=" + R2S(elapsedTime))

    call TimerStart(t, delay, false, function TerrainDamage_OnUnitTimer)

    set t = null
endfunction

//===========================================================================
private function TerrainDamage_StartUnitTimer takes unit u, integer terrainType returns nothing
    local integer unitId = GetUnitUserData(u)
    local real baseInterval = TerrainDamage_ComputeInterval(terrainType, 0.00)
    local real initialPhase

    if unitId <= 0 then
        call DebugMsg("StartUnitTimer skipped unitId <= 0 for unit=" + GetUnitName(u))
        return
    endif

    set initialPhase = TerrainDamage_GetInitialPhaseOffset(unitId, baseInterval)

    if baseInterval <= 0.00 then
        call DebugMsg("StartUnitTimer skipped baseInterval <= 0 for unit=" + GetUnitName(u) + " unitId=" + I2S(unitId))
        return
    endif

    call DebugMsg("StartUnitTimer unit=" + GetUnitName(u) + " unitId=" + I2S(unitId) + " terrainType=" + I2S(terrainType) + " baseInterval=" + R2S(baseInterval) + " initialPhase=" + R2S(initialPhase))
    call TerrainDamage_ArmUnitTimer(u, terrainType, baseInterval - initialPhase, initialPhase)
endfunction

//===========================================================================
private function TerrainDamage_StopUnitTimer takes unit u returns nothing
    local integer unitId

    if u != null then
        set unitId = GetUnitUserData(u)
        if unitId > 0 then
            call DebugMsg("StopUnitTimer unit=" + GetUnitName(u) + " unitId=" + I2S(unitId))
            call TerrainDamage_ClearUnitState(unitId)
        endif
    endif
endfunction

//===========================================================================
private function TerrainDamage_IsRegisteredPlayer takes player p returns boolean
    local integer i = 0

    loop
        exitwhen i >= TerrainPlayerCount
        if TerrainPlayers[i] == p then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

//===========================================================================
private function TerrainDamage_RefreshPlayerTrackedUnit takes unit u returns nothing
    if not TerrainDamage_IsUnitValid(u) then
        call DebugMsg("RefreshPlayerTrackedUnit skipped invalid unit")
        return
    endif

    if TerrainDamage_IsRegisteredPlayer(GetOwningPlayer(u)) and TerrainDamage_IsUnitInPlayerTrackRect(u) then
        call DebugMsg("RefreshPlayerTrackedUnit add unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)) + " owner=" + I2S(GetPlayerId(GetOwningPlayer(u))))
        call GroupAddUnit(TerrainPlayerGroup, u)
    else
        call DebugMsg("RefreshPlayerTrackedUnit remove unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)) + " owner=" + I2S(GetPlayerId(GetOwningPlayer(u))))
        call GroupRemoveUnit(TerrainPlayerGroup, u)
        if not TerrainDamage_IsUnitTrackedSource(u) then
            call TerrainDamage_StopUnitTimer(u)
        endif
    endif
endfunction

//===========================================================================
private function TerrainDamage_OnUnitDeath takes nothing returns nothing
    call TerrainDamage_RefreshPlayerTrackedUnit(GetDyingUnit())
endfunction

//===========================================================================
private function TerrainDamage_RemovePlayerTrackedUnit takes unit u returns nothing
    if u == null then
        call DebugMsg("RemovePlayerTrackedUnit skipped null unit")
        return
    endif

    call DebugMsg("RemovePlayerTrackedUnit unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)))
    call GroupRemoveUnit(TerrainPlayerGroup, u)
    call TerrainDamage_StopUnitTimer(u)
endfunction

//===========================================================================
private function TerrainDamage_PlayerBootstrapEnum takes nothing returns nothing
    call TerrainDamage_RefreshPlayerTrackedUnit(GetEnumUnit())
endfunction

//===========================================================================
private function TerrainDamage_BootstrapTrackedRects takes nothing returns nothing
    local integer i = 0

    if not TerrainDamage_UsesPlayerTrackRects() then
        return
    endif

    loop
        exitwhen i >= TerrainPlayerTrackRectCount
        call GroupClear(TerrainPlayerScanGroup)
        call GroupEnumUnitsInRect(TerrainPlayerScanGroup, TerrainPlayerTrackRects[i], null)
        call ForGroup(TerrainPlayerScanGroup, function TerrainDamage_PlayerBootstrapEnum)
        set i = i + 1
    endloop
endfunction

//===========================================================================
private function TerrainDamage_BootstrapPlayer takes player p returns nothing
    local group g = CreateGroup()

    if TerrainDamage_UsesPlayerTrackRects() then
        call TerrainDamage_BootstrapTrackedRects()
        call DestroyGroup(g)
        set g = null
        return
    endif

    call GroupEnumUnitsOfPlayer(g, p, null)
    call ForGroup(g, function TerrainDamage_PlayerBootstrapEnum)
    call DestroyGroup(g)

    set g = null
endfunction

//===========================================================================
private function TerrainDamage_OnPlayerTrackedIndexed takes nothing returns nothing
    call DebugMsg("OnPlayerTrackedIndexed udex=" + I2S(udg_UDex))
    call TerrainDamage_RefreshPlayerTrackedUnit(udg_UDexUnits[udg_UDex])
endfunction

//===========================================================================
private function TerrainDamage_OnPlayerTrackedRemoved takes nothing returns nothing
    call DebugMsg("OnPlayerTrackedRemoved udex=" + I2S(udg_UDex))
    call TerrainDamage_RemovePlayerTrackedUnit(udg_UDexUnits[udg_UDex])
endfunction

//===========================================================================
private function TerrainDamage_OnPlayerTrackedTransformed takes nothing returns nothing
    call DebugMsg("OnPlayerTrackedTransformed udex=" + I2S(udg_UDex))
    call TerrainDamage_RefreshPlayerTrackedUnit(udg_UDexUnits[udg_UDex])
endfunction

//===========================================================================
private function TerrainDamage_OnPlayerTrackedOwnerChange takes nothing returns nothing
    call DebugMsg("OnPlayerTrackedOwnerChange unit=" + GetUnitName(GetTriggerUnit()) + " unitId=" + I2S(GetUnitUserData(GetTriggerUnit())) + " newOwner=" + I2S(GetPlayerId(GetOwningPlayer(GetTriggerUnit()))))
    call TerrainDamage_RefreshPlayerTrackedUnit(GetTriggerUnit())
endfunction

//===========================================================================
private function TerrainDamage_OnPlayerTrackRectEnter takes nothing returns nothing
    call TerrainDamage_RefreshPlayerTrackedUnit(GetTriggerUnit())
endfunction

//===========================================================================
private function TerrainDamage_OnPlayerTrackRectLeave takes nothing returns nothing
    call TerrainDamage_RefreshPlayerTrackedUnit(GetTriggerUnit())
endfunction

//===========================================================================
private function TerrainDamage_InitPlayerTracking takes nothing returns nothing
    local integer i = 0
    local trigger t = CreateTrigger()
    local group g = CreateGroup()

    call DebugMsg("InitPlayerTracking begin")
    set TerrainPlayerIndexedTrig = CreateTrigger()
    set TerrainPlayerCreatedTrig = CreateTrigger()
    set TerrainPlayerRemovedTrig = CreateTrigger()
    set TerrainPlayerTransformedTrig = CreateTrigger()
    set TerrainPlayerOwnerChangeTrig = t
    call DebugMsg("InitPlayerTracking created triggers")

    call TriggerRegisterVariableEvent(TerrainPlayerIndexedTrig, "udg_UnitIndexEvent", EQUAL, 1.00)      // unit Starts existing
    call TriggerAddAction(TerrainPlayerIndexedTrig, function TerrainDamage_OnPlayerTrackedIndexed)

    call TriggerRegisterVariableEvent(TerrainPlayerCreatedTrig, "udg_UnitIndexEvent", EQUAL, 1.50)      // unit Fully created
    call TriggerAddAction(TerrainPlayerCreatedTrig, function TerrainDamage_OnPlayerTrackedIndexed)

    call TriggerRegisterVariableEvent(TerrainPlayerRemovedTrig, "udg_UnitIndexEvent", EQUAL, 2.00)      // unit Stops existing
    call TriggerAddAction(TerrainPlayerRemovedTrig, function TerrainDamage_OnPlayerTrackedRemoved)

    call TriggerRegisterVariableEvent(TerrainPlayerTransformedTrig, "udg_UnitTypeEvent", EQUAL, 1.00)   // unit 
    call TriggerAddAction(TerrainPlayerTransformedTrig, function TerrainDamage_OnPlayerTrackedTransformed)
    call DebugMsg("InitPlayerTracking registered variable events")

    if TerrainDamage_UsesPlayerTrackRects() then
        set TerrainPlayerRectEnterTrig = CreateTrigger()
        set TerrainPlayerRectLeaveTrig = CreateTrigger()
        loop
            exitwhen i >= TerrainPlayerTrackRectCount
            call TriggerRegisterEnterRectSimple(TerrainPlayerRectEnterTrig, TerrainPlayerTrackRects[i])
            call TriggerRegisterLeaveRectSimple(TerrainPlayerRectLeaveTrig, TerrainPlayerTrackRects[i])
            set i = i + 1
        endloop
        call TriggerAddAction(TerrainPlayerRectEnterTrig, function TerrainDamage_OnPlayerTrackRectEnter)
        call TriggerAddAction(TerrainPlayerRectLeaveTrig, function TerrainDamage_OnPlayerTrackRectLeave)
        set i = 0
    endif

    loop
        exitwhen i > TERRAIN_DAMAGE_MAX_PLAYER_INDEX
        call DebugMsg("InitPlayerTracking register owner change event for playerIndex=" + I2S(i))
        call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_CHANGE_OWNER, null)
        set i = i + 1
    endloop
    call TriggerAddAction(t, function TerrainDamage_OnPlayerTrackedOwnerChange)
    call DebugMsg("InitPlayerTracking triggers registered")

    set i = 0
    if TerrainDamage_UsesPlayerTrackRects() then
        call TerrainDamage_BootstrapTrackedRects()
    else
        loop
            exitwhen i >= TerrainPlayerCount
            call DebugMsg("InitPlayerTracking bootstrap player=" + I2S(GetPlayerId(TerrainPlayers[i])))
            call GroupEnumUnitsOfPlayer(g, TerrainPlayers[i], null)
            call ForGroup(g, function TerrainDamage_PlayerBootstrapEnum)
            call GroupClear(g)
            set i = i + 1
        endloop
    endif

    call DestroyGroup(g)
    set g = null
    set t = null
    set TerrainPlayerTrackingReady = true
    call DebugMsg("InitPlayerTracking end")
endfunction

//===========================================================================
// Registers a GUI unit group into the system
function TerrainDamage_RegisterGroup takes group g returns nothing
    set TerrainGroups[TerrainGroupCount] = g
    set TerrainGroupCount = TerrainGroupCount + 1
endfunction

//===========================================================================
// Add units to terrain damage group
function TerrainDamage_AddUnit takes unit u returns nothing
    call DebugMsg("AddUnit unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)))
    call GroupAddUnit(TerrainDamageGroup, u)
endfunction

// Remove units to terrain damage group
function TerrainDamage_RemoveUnit takes unit u returns nothing
    call DebugMsg("RemoveUnit unit=" + GetUnitName(u) + " unitId=" + I2S(GetUnitUserData(u)))
    call GroupRemoveUnit(TerrainDamageGroup, u)
endfunction

function TerrainDamage_RegisterIgnoredUnitType takes integer unitTypeId returns nothing
    set TerrainIgnoredUnitTypes.boolean[unitTypeId] = true
endfunction

function TerrainDamage_UnregisterIgnoredUnitType takes integer unitTypeId returns nothing
    call TerrainIgnoredUnitTypes.boolean.remove(unitTypeId)
endfunction

function TerrainDamage_RegisterIgnoredPlayer takes player p returns nothing
    if p != null then
        set TerrainIgnoredPlayers.boolean[GetPlayerId(p)] = true
    endif
endfunction

function TerrainDamage_UnregisterIgnoredPlayer takes player p returns nothing
    if p != null then
        call TerrainIgnoredPlayers.boolean.remove(GetPlayerId(p))
    endif
endfunction

function TerrainDamage_RegisterPlayerTrackRect takes rect r returns nothing
    if r == null then
        return
    endif

    set TerrainPlayerTrackRects[TerrainPlayerTrackRectCount] = r
    set TerrainPlayerTrackRectCount = TerrainPlayerTrackRectCount + 1
endfunction

//===========================================================================
// Registers a player to be processed for terrain damage.
// If player track rects are configured, only units inside those rects are tracked.
function TerrainDamage_RegisterPlayer takes player p returns nothing
    local string trackingReadyText

    if TerrainDamage_IsRegisteredPlayer(p) then
        call DebugMsg("RegisterPlayer skipped duplicate player=" + I2S(GetPlayerId(p)))
        return
    endif

    call DebugMsg("RegisterPlayer begin player=" + I2S(GetPlayerId(p)))
    set TerrainPlayers[TerrainPlayerCount] = p
    set TerrainPlayerCount = TerrainPlayerCount + 1
    call DebugMsg("RegisterPlayer player=" + I2S(GetPlayerId(p)))

    if TerrainPlayerTrackingReady then
        set trackingReadyText = "true"
    else
        set trackingReadyText = "false"
    endif
    call DebugMsg("RegisterPlayer trackingReady=" + trackingReadyText)
    if TerrainPlayerTrackingReady then
        call DebugMsg("RegisterPlayer bootstrap existing units for player=" + I2S(GetPlayerId(p)))
        call TerrainDamage_BootstrapPlayer(p)
    endif
    call DebugMsg("RegisterPlayer end player=" + I2S(GetPlayerId(p)))

    set trackingReadyText = null
endfunction

//===========================================================================
// Scanner logic: detect damaging terrain and manage per-unit timers
private function ScanEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    local integer unitId
    local integer detectedTerrainType
    local integer activeTerrainType
    local timer activeTimer
    local string hasTimer

    if not TerrainDamage_IsUnitValid(u) then
        set u = null
        return
    endif

    set unitId = GetUnitUserData(u)
    if unitId <= 0 then
        call DebugMsg("ScanEnum skipped unitId <= 0 for unit=" + GetUnitName(u))
        set u = null
        return
    endif
    if TerrainUnitLastScanPass.integer[unitId] == TerrainDamageScanPass then
        set u = null
        return
    endif
    set TerrainUnitLastScanPass.integer[unitId] = TerrainDamageScanPass

    set detectedTerrainType = TerrainDamage_GetTerrainTypeAtUnit(u)
    set activeTerrainType = TerrainUnitTerrainTypes.integer[unitId]
    set activeTimer = TerrainUnitTimers.timer[unitId]
    if activeTimer != null then
        set hasTimer = "true"
    else
        set hasTimer = "false"
    endif
    if detectedTerrainType != 0 or activeTimer != null then
        call DebugMsg("ScanEnum unit=" + GetUnitName(u) + " unitId=" + I2S(unitId) + " detectedTerrainType=" + I2S(detectedTerrainType) + " activeTerrainType=" + I2S(activeTerrainType) + " hasTimer=" + hasTimer)
    endif

    if detectedTerrainType == 0 then
        if activeTimer != null then
            call TerrainDamage_StopUnitTimer(u)
        endif
    elseif activeTimer == null then
        call TerrainDamage_StartUnitTimer(u, detectedTerrainType)
    elseif activeTerrainType != detectedTerrainType then
        call TerrainDamage_StopUnitTimer(u)
        call TerrainDamage_StartUnitTimer(u, detectedTerrainType)
    endif

    set activeTimer = null
    set hasTimer = null
    set u = null
endfunction

//===========================================================================
// Loop through all configured groups
private function Periodic takes nothing returns nothing
    local integer i = 0

    set TerrainDamageScanPass = TerrainDamageScanPass + 1
    if TerrainDamageScanPass <= 0 then
        set TerrainDamageScanPass = 1
        call TerrainUnitLastScanPass.flush()
    endif

    // --- Process GUI groups ---
    loop
        exitwhen i >= TerrainGroupCount
        call ForGroup(TerrainGroups[i], function ScanEnum)
        set i = i + 1
    endloop

    // --- Process manually added units ---
    call ForGroup(TerrainDamageGroup, function ScanEnum)

    // --- Process units owned by registered players ---
    call ForGroup(TerrainPlayerGroup, function ScanEnum)
endfunction

//===========================================================================
// Slow safety resync for player-owned tracked units.
private function TerrainDamage_PeriodicPlayerResync takes nothing returns nothing
    local integer j = 0
    local unit u

    if TerrainDamage_UsesPlayerTrackRects() then
        loop
            set u = FirstOfGroup(TerrainPlayerGroup)
            exitwhen u == null
            call GroupRemoveUnit(TerrainPlayerGroup, u)
            call GroupAddUnit(TerrainPlayerScanGroup, u)
        endloop

        loop
            set u = FirstOfGroup(TerrainPlayerScanGroup)
            exitwhen u == null
            call GroupRemoveUnit(TerrainPlayerScanGroup, u)
            call TerrainDamage_RefreshPlayerTrackedUnit(u)
        endloop

        call TerrainDamage_BootstrapTrackedRects()
    else
        loop
            exitwhen j >= TerrainPlayerCount
            call GroupClear(TerrainPlayerScanGroup)
            call GroupEnumUnitsOfPlayer(TerrainPlayerScanGroup, TerrainPlayers[j], null)
            call ForGroup(TerrainPlayerScanGroup, function TerrainDamage_PlayerBootstrapEnum)
            set j = j + 1
        endloop
    endif

    set u = null
endfunction

//===========================================================================
// CONFIGURATION for UNIT GROUPS
//===========================================================================
// Initializes the groups to be processed
function TerrainDamage_InitGroups takes nothing returns nothing
    // ===== CONFIGURE YOUR GROUPS HERE =====
    call TerrainDamage_RegisterGroup(udg_Companion_Group)
    call TerrainDamage_RegisterGroup(udg_Pet)

    // Add more groups as needed

endfunction
//===========================================================================
// CONFIGURATION for UNITS
//===========================================================================
// Initializes the units to be processed
function TerrainDamage_InitUnits takes nothing returns nothing
    // ===== CONFIGURE YOUR GROUPS HERE =====
    call TerrainDamage_AddUnit(udg_Nazgrek)
    call TerrainDamage_AddUnit(udg_Zulkis)

    // Add more units as needed

endfunction

//===========================================================================
// CONFIGURATION for IGNORE RULES
//===========================================================================
function TerrainDamage_InitIgnoreRules takes nothing returns nothing
    // Examples:
    // call TerrainDamage_RegisterIgnoredPlayer(Player(22))
    // call TerrainDamage_RegisterIgnoredUnitType('uVei')
endfunction

//===========================================================================
// CONFIGURATION for PLAYERS
//===========================================================================
function TerrainDamage_InitPlayerTrackRects takes nothing returns nothing
    // ===== CONFIGURE the lava/fel area RECTS you want tracked. =====
    // If this function stays empty, behavior falls back to the old whole-player tracking model.
    call TerrainDamage_RegisterPlayerTrackRect(gg_rct_03EmberpeakHighlands)
    call TerrainDamage_RegisterPlayerTrackRect(gg_rct_04DragonfirePeaks)
    call TerrainDamage_RegisterPlayerTrackRect(gg_rct_05WyrmholdSanctum)
    call TerrainDamage_RegisterPlayerTrackRect(gg_rct_012FelfireBastion)
    call TerrainDamage_RegisterPlayerTrackRect(gg_rct_016Firelands)


    // Examples:
    // call TerrainDamage_RegisterPlayerTrackRect(gg_rct_03EmberpeakHighlands)
endfunction

//===========================================================================
// CONFIGURATION for PLAYERS
//===========================================================================
// Initializes the players to be processed
function TerrainDamage_InitPlayers takes nothing returns nothing
    // ===== CONFIGURE YOUR PLAYERS HERE =====
    // adding too many players could end up having too many units to track -> i.e. lag
    call DebugMsg("InitPlayers begin")
    call TerrainDamage_RegisterPlayer(Player(1))    // Horde
    call TerrainDamage_RegisterPlayer(Player(2))    // Human citizen
    call TerrainDamage_RegisterPlayer(Player(3))    // Shadow council
    call TerrainDamage_RegisterPlayer(Player(4))    // Shadow council
    call TerrainDamage_RegisterPlayer(Player(5))    // Horde
    call TerrainDamage_RegisterPlayer(Player(6))    // Goblins
    call TerrainDamage_RegisterPlayer(Player(7))    // Alliance Scouts
    call TerrainDamage_RegisterPlayer(Player(8))    // Goldshire
    call TerrainDamage_RegisterPlayer(Player(9))    // Alliance Scouts
    call TerrainDamage_RegisterPlayer(Player(10))   // Bonecrusher Clan
    call TerrainDamage_RegisterPlayer(Player(14))   // Riverbane Denizen
    call TerrainDamage_RegisterPlayer(Player(15))   // Elarindor
    call TerrainDamage_RegisterPlayer(Player(18))   // Companion AI Player
    call TerrainDamage_RegisterPlayer(Player(PLAYER_NEUTRAL_PASSIVE))
    call TerrainDamage_RegisterPlayer(Player(PLAYER_NEUTRAL_AGGRESSIVE))

    // call TerrainDamage_RegisterPlayer(Player(1)) // Example: Player 2 (blue)
    // Add more players as needed
    call DebugMsg("InitPlayers end")
endfunction

//===========================================================================
// CONFIGURATION for SOUNDS
//===========================================================================
// Initializes the units to be processed
private function InitSounds takes nothing returns nothing
    set LAVA_SOUND = NewSound(LAVA_SOUND_PATH, LAVA_SOUND_DURATION, false, true)
    set FEL_SOUND = NewSound(FEL_SOUND_PATH, FEL_SOUND_DURATION, false, true)
endfunction

//===========================================================================
// Initialization delayed
private function InitDelayed takes nothing returns nothing
    if DEBUG_BYPASS_SYSTEM then
        call DebugMsg("InitDelayed skipped because DEBUG_BYPASS_SYSTEM is enabled")
        return
    endif

    set TerrainUnitTimers = Table.create()
    set TerrainUnitTerrainTypes = Table.create()
    set TerrainUnitCurrentIntervals = Table.create()
    set TerrainUnitElapsedTimes = Table.create()
    set TerrainUnitLastScanPass = Table.create()
    set TerrainIgnoredUnitTypes = Table.create()
    set TerrainIgnoredPlayers = Table.create()
    call DebugMsg("InitDelayed start")

    call TerrainDamage_InitGroups()
    call TerrainDamage_InitUnits()
    call TerrainDamage_InitIgnoreRules()
    call TerrainDamage_InitPlayerTrackRects()
    call TerrainDamage_InitPlayers()
    call TerrainDamage_InitPlayerTracking()
    call UnitDeathEvent_Register(function TerrainDamage_OnUnitDeath)
    call InitSounds()
    call DebugMsg("InitDelayed complete, starting scan timer interval=" + R2S(SCAN_INTERVAL))

    call TimerStart(CreateTimer(), SCAN_INTERVAL, true, function Periodic)
    call TimerStart(CreateTimer(), PLAYER_RESYNC_INTERVAL, true, function TerrainDamage_PeriodicPlayerResync)

endfunction

//===========================================================================
// Initialization
private function Init takes nothing returns nothing
    local trigger trg_InitDelayed = CreateTrigger()

    call TriggerRegisterTimerEvent(trg_InitDelayed, 1.0, false)
    call TriggerAddAction(trg_InitDelayed, function InitDelayed)

endfunction

endlibrary
