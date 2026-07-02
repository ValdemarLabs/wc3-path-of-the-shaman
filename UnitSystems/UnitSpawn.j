//===========================================================================

/*    UnitSpawn Library

        Author: Valdemar

        Description:
        - Library system to spawn waves of units randomly around a point
        - Each wave is tracked individually and can be removed separately
        - Uses Bribe's Table v6 for efficient wave tracking
        - Ex spawn APIs can play pre-spawn and on-spawn special effects and optional point sounds

        Usage:
        - Call wave spawn functions (e.g., WavesRiftWraits_Wave1) to create waves
        - Call Ex wave spawn functions to add spawn special effects
        - Store returned Wave instance to manage the wave (remove, kill, check count)
        - See examples at the bottom of this file for usage patterns
        - Integrates with GUI by storing Wave instance as integer variable
        - Clean up wave instances when done to avoid memory leaks

        How to add more functions:
        - Create new functions similar to WavesRiftWraits_Wave1 for custom waves
        - Use SpawnUnitRandomlyForWave helper to spawn units in the wave    
        - Customize unit types and counts as needed

        API Summary:
        - Wave Methods:
        - Wave.create()                    : Creates a new wave instance
        - wave.addUnit(unit u)             : Manually add a unit to the wave
        - wave.attackMove(real x, real y)  : Orders living wave units to attack-move
        - wave.removeAllUnits()            : Instantly remove all wave units (no death animation)
        - wave.killAllUnits()              : Kill all wave units (with death animation, XP
        - wave.getRemainingCount()         : Get count of living units in the wave
        - wave.destroy()                   : Clean up the wave (call when completely done with it)
        - wave.unitCount                   : Read the initial spawn count
        - wave.id                          : Unique wave ID
        - UnitSpawn_SpawnUnitRandomlyForWaveEx(...) : Generic random wave spawn with special effects
        - UnitSpawn_SpawnUnitRandomlyForWaveDelayedEx(...) : Generic delayed random wave spawn with pre-spawn effects
        - UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(...) : Delayed spawn with pre-spawn effect create/destroy sounds
        - WavesRiftWraits_Wave1Ex..Wave4Ex(...)     : Rift wave helpers with special effects
        - WavesRiftWraits_Wave1DelayedEx..Wave4DelayedEx(...) : Rift wave helpers with delayed pre-spawn effects
        - WavesRiftWraits_Wave1DelayedSoundEx..Wave4DelayedSoundEx(...) : Rift delayed helpers with effect sounds
*/
//===========================================================================

library UnitSpawn initializer Init requires Table, SpeciFX

globals
    // Configuration
    constant real WAVE_SPAWN_RADIUS = 300.0  // Random spawn radius around center point
    
    // Wave tracking
    private Table WaveData = 0  // Main table: [waveId].group = wave units, [waveId].integer[0] = unit count
    private Table PendingSpawnData = 0
    private Table PendingSoundData = 0
    private integer WaveIdCounter = 0  // Auto-incrementing wave ID
    private real WaveOrderX = 0.0
    private real WaveOrderY = 0.0

    private constant integer PENDING_WAVE_KEY = 1
    private constant integer PENDING_WAVE_ID_KEY = 2
    private constant integer PENDING_UNIT_TYPE_KEY = 3
    private constant integer PENDING_OWNER_KEY = 4
    private constant integer PENDING_X_KEY = 5
    private constant integer PENDING_Y_KEY = 6
    private constant integer PENDING_FACING_KEY = 7
    private constant integer PENDING_SPAWN_EFFECT_KEY = 8
    private constant integer PENDING_SPAWN_EFFECT_DURATION_KEY = 9
    private constant integer PENDING_TIMED_DESTROY_KEY = 10
    private constant integer PENDING_SOUND_PATH_KEY = 1
    private constant integer PENDING_SOUND_X_KEY = 2
    private constant integer PENDING_SOUND_Y_KEY = 3
endglobals

//===========================================================================
// Initialize the wave system
//===========================================================================
private function Init takes nothing returns nothing
    set WaveData = Table.create()
    set PendingSpawnData = Table.create()
    set PendingSoundData = Table.create()
endfunction

private function OrderWaveUnitAttackMoveEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    if u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
        call IssuePointOrder(u, "attack", WaveOrderX, WaveOrderY)
    endif
    set u = null
endfunction

//===========================================================================
// Wave Structure - Represents a single wave instance
//===========================================================================
struct Wave
    integer id
    group units
    integer unitCount
    boolean active
    boolean hasAttackMoveOrder
    real attackMoveX
    real attackMoveY
    
    //=======================================================================
    // Create a new wave instance
    //=======================================================================
    static method create takes nothing returns Wave
        local Wave this = Wave.allocate()
        set WaveIdCounter = WaveIdCounter + 1
        set this.id = WaveIdCounter
        set this.units = CreateGroup()
        set this.unitCount = 0
        set this.active = true
        set this.hasAttackMoveOrder = false
        set this.attackMoveX = 0.0
        set this.attackMoveY = 0.0
        
        // Store in tracking table
        set WaveData.group[this.id] = this.units
        set WaveData.integer[this.id] = this.unitCount
        
        return this
    endmethod
    
    //=======================================================================
    // Add a unit to this wave
    //=======================================================================
    method addUnit takes unit u returns nothing
        call GroupAddUnit(this.units, u)
        set this.unitCount = this.unitCount + 1
        set WaveData.integer[this.id] = this.unitCount
        if this.hasAttackMoveOrder then
            call IssuePointOrder(u, "attack", this.attackMoveX, this.attackMoveY)
        endif
    endmethod

    //=======================================================================
    // Order all living units in this wave to attack-move toward a point
    //=======================================================================
    method attackMove takes real x, real y returns nothing
        set this.hasAttackMoveOrder = true
        set this.attackMoveX = x
        set this.attackMoveY = y
        set WaveOrderX = x
        set WaveOrderY = y
        call ForGroup(this.units, function OrderWaveUnitAttackMoveEnum)
    endmethod
    
    //=======================================================================
    // Remove all units in this wave (instant removal, no death animation)
    //=======================================================================
    method removeAllUnits takes nothing returns nothing
        local unit u
        
        loop
            set u = FirstOfGroup(this.units)
            exitwhen u == null
            call GroupRemoveUnit(this.units, u)
            call RemoveUnit(u)
        endloop
        
        set this.unitCount = 0
        set WaveData.integer[this.id] = 0
        set u = null
    endmethod
    
    //=======================================================================
    // Kill all units in this wave (plays death animation, drops items, gives XP)
    //=======================================================================
    method killAllUnits takes nothing returns nothing
        local unit u
        
        loop
            set u = FirstOfGroup(this.units)
            exitwhen u == null
            call GroupRemoveUnit(this.units, u)
            call KillUnit(u)
        endloop
        
        set this.unitCount = 0
        set WaveData.integer[this.id] = 0
        set u = null
    endmethod
    
    //=======================================================================
    // Get remaining unit count in this wave
    //=======================================================================
    method getRemainingCount takes nothing returns integer
        local integer count = 0
        local unit u
        local group temp = CreateGroup()
        
        // Count living units in the group
        loop
            set u = FirstOfGroup(this.units)
            exitwhen u == null
            call GroupRemoveUnit(this.units, u)
            if GetUnitTypeId(u) != 0 and IsUnitType(u, UNIT_TYPE_DEAD) == false then
                set count = count + 1
            endif
            call GroupAddUnit(temp, u)
        endloop

        loop
            set u = FirstOfGroup(temp)
            exitwhen u == null
            call GroupRemoveUnit(temp, u)
            call GroupAddUnit(this.units, u)
        endloop

        call DestroyGroup(temp)
        set temp = null
        set u = null
        
        return count
    endmethod
    
    //=======================================================================
    // Destroy the wave and clean up
    //=======================================================================
    method onDestroy takes nothing returns nothing
        set this.active = false
        call this.removeAllUnits()
        call DestroyGroup(this.units)
        call WaveData.remove(this.id)
        set this.units = null
    endmethod
endstruct

//===========================================================================
// Helper function to spawn units randomly around a point for a wave
//===========================================================================
private function PlaySpawnSoundAtPoint takes string soundPath, real x, real y returns nothing
    local sound s
    if soundPath == null or soundPath == "" then
        return
    endif
    set s = CreateSound(soundPath, false, true, true, 10, 10, "")
    call SetSoundPosition(s, x, y, 0.00)
    call SetSoundDistanceCutoff(s, 5000.00)
    call StartSound(s)
    call KillSoundWhenDone(s)
    set s = null
endfunction

private function PlayPendingSpawnSound takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId = GetHandleId(t)
    local Table data

    if PendingSoundData.has(timerId) then
        set data = PendingSoundData.link(timerId)
        call PlaySpawnSoundAtPoint(data.string[PENDING_SOUND_PATH_KEY], data.real[PENDING_SOUND_X_KEY], data.real[PENDING_SOUND_Y_KEY])
        call PendingSoundData.remove(timerId)
    endif

    call DestroyTimer(t)
    set t = null
endfunction

private function QueueSpawnSoundAtPoint takes string soundPath, real x, real y, real delay returns nothing
    local timer t
    local Table data

    if soundPath == null or soundPath == "" then
        return
    endif
    if delay <= 0.00 then
        call PlaySpawnSoundAtPoint(soundPath, x, y)
        return
    endif

    set t = CreateTimer()
    set data = PendingSoundData.link(GetHandleId(t))
    set data.string[PENDING_SOUND_PATH_KEY] = soundPath
    set data.real[PENDING_SOUND_X_KEY] = x
    set data.real[PENDING_SOUND_Y_KEY] = y
    call TimerStart(t, delay, false, function PlayPendingSpawnSound)
    set t = null
endfunction

private function PlaySpawnPointEffect takes string effectPath, real x, real y, real duration, boolean timedDestroy, animtype whichAnim, string createSound, string destroySound returns nothing
    local effect e
    if effectPath == null or effectPath == "" then
        return
    endif
    set e = AddSpecialEffect(effectPath, x, y)
    call PlaySpawnSoundAtPoint(createSound, x, y)
    if whichAnim != null then
        call BlzPlaySpecialEffect(e, whichAnim)
    endif
    if timedDestroy and duration > 0.00 then
        call SpeciFX_DestroyTimed(e, duration)
        call QueueSpawnSoundAtPoint(destroySound, x, y, duration)
    else
        call DestroyEffect(e)
        call PlaySpawnSoundAtPoint(destroySound, x, y)
    endif
    set e = null
endfunction

private function PlaySpawnUnitEffect takes string effectPath, unit u, real duration, boolean timedDestroy, animtype whichAnim returns nothing
    local effect e
    if effectPath == null or effectPath == "" or u == null then
        return
    endif
    set e = AddSpecialEffectTarget(effectPath, u, "origin")
    if whichAnim != null then
        call BlzPlaySpecialEffect(e, whichAnim)
    endif
    if timedDestroy and duration > 0.00 then
        call SpeciFX_DestroyTimed(e, duration)
    else
        call DestroyEffect(e)
    endif
    set e = null
endfunction

function UnitSpawn_SpawnUnitRandomlyForWaveEx takes Wave wave, player owner, integer unitId, real centerX, real centerY, real radius, integer count, string preSpawnEffect, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy, animtype preSpawnAnim, animtype spawnAnim returns nothing
    local integer i = 0
    local real angle
    local real distance
    local real x
    local real y
    local unit u

    if wave == 0 or owner == null or unitId == 0 or count <= 0 then
        return
    endif

    loop
        exitwhen i >= count

        set angle = GetRandomReal(0, 360) * bj_DEGTORAD
        set distance = GetRandomReal(0, radius)
        set x = centerX + distance * Cos(angle)
        set y = centerY + distance * Sin(angle)

        call PlaySpawnPointEffect(preSpawnEffect, x, y, preSpawnEffectDuration, timedDestroy, preSpawnAnim, "", "")
        set u = CreateUnit(owner, unitId, x, y, GetRandomReal(0, 360))
        call wave.addUnit(u)
        call PlaySpawnUnitEffect(spawnEffect, u, spawnEffectDuration, timedDestroy, spawnAnim)

        set i = i + 1
    endloop

    set u = null
endfunction

private function FinishPendingDelayedSpawn takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer timerId = GetHandleId(t)
    local Table data
    local Wave wave
    local unit u

    if not PendingSpawnData.has(timerId) then
        call DestroyTimer(t)
        set t = null
        return
    endif

    set data = PendingSpawnData.link(timerId)
    set wave = data[PENDING_WAVE_KEY]
    if wave != 0 and wave.active and wave.id == data[PENDING_WAVE_ID_KEY] and wave.units != null and WaveData.group[wave.id] == wave.units then
        set u = CreateUnit(data.player[PENDING_OWNER_KEY], data[PENDING_UNIT_TYPE_KEY], data.real[PENDING_X_KEY], data.real[PENDING_Y_KEY], data.real[PENDING_FACING_KEY])
        call wave.addUnit(u)
        call PlaySpawnUnitEffect(data.string[PENDING_SPAWN_EFFECT_KEY], u, data.real[PENDING_SPAWN_EFFECT_DURATION_KEY], data.boolean[PENDING_TIMED_DESTROY_KEY], null)
    endif

    call PendingSpawnData.remove(timerId)
    call DestroyTimer(t)
    set u = null
    set t = null
endfunction

private function QueueDelayedSpawn takes Wave wave, player owner, integer unitId, real x, real y, real facing, real preSpawnDelay, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns nothing
    local timer t
    local Table data
    local unit u

    if preSpawnDelay <= 0.00 then
        set u = CreateUnit(owner, unitId, x, y, facing)
        call wave.addUnit(u)
        call PlaySpawnUnitEffect(spawnEffect, u, spawnEffectDuration, timedDestroy, null)
        set u = null
        return
    endif

    set t = CreateTimer()
    set data = PendingSpawnData.link(GetHandleId(t))
    set data[PENDING_WAVE_KEY] = wave
    set data[PENDING_WAVE_ID_KEY] = wave.id
    set data[PENDING_UNIT_TYPE_KEY] = unitId
    set data.player[PENDING_OWNER_KEY] = owner
    set data.real[PENDING_X_KEY] = x
    set data.real[PENDING_Y_KEY] = y
    set data.real[PENDING_FACING_KEY] = facing
    set data.string[PENDING_SPAWN_EFFECT_KEY] = spawnEffect
    set data.real[PENDING_SPAWN_EFFECT_DURATION_KEY] = spawnEffectDuration
    set data.boolean[PENDING_TIMED_DESTROY_KEY] = timedDestroy
    call TimerStart(t, preSpawnDelay, false, function FinishPendingDelayedSpawn)
    set t = null
endfunction

function UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx takes Wave wave, player owner, integer unitId, real centerX, real centerY, real radius, integer count, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string preSpawnCreateSound, string preSpawnDestroySound, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns nothing
    local integer i = 0
    local real angle
    local real distance
    local real x
    local real y
    local real facing

    if wave == 0 or owner == null or unitId == 0 or count <= 0 then
        return
    endif

    loop
        exitwhen i >= count

        set angle = GetRandomReal(0, 360) * bj_DEGTORAD
        set distance = GetRandomReal(0, radius)
        set x = centerX + distance * Cos(angle)
        set y = centerY + distance * Sin(angle)
        set facing = GetRandomReal(0, 360)

        call PlaySpawnPointEffect(preSpawnEffect, x, y, preSpawnEffectDuration, timedDestroy, null, preSpawnCreateSound, preSpawnDestroySound)
        call QueueDelayedSpawn(wave, owner, unitId, x, y, facing, preSpawnDelay, spawnEffect, spawnEffectDuration, timedDestroy)

        set i = i + 1
    endloop
endfunction

function UnitSpawn_SpawnUnitRandomlyForWaveDelayedEx takes Wave wave, player owner, integer unitId, real centerX, real centerY, real radius, integer count, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns nothing
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(wave, owner, unitId, centerX, centerY, radius, count, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, "", "", spawnEffect, spawnEffectDuration, timedDestroy)
endfunction

private function SpawnUnitRandomlyForWave takes Wave wave, player owner, integer unitId, real centerX, real centerY, real radius, integer count returns nothing
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(wave, owner, unitId, centerX, centerY, radius, count, "", 0.00, "", 0.00, false, null, null)
endfunction

//===========================================================================
// Wave 1 - Mana Spawns
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave1Ex takes player owner, location loc, string preSpawnEffect, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy, animtype preSpawnAnim, animtype spawnAnim returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3, preSpawnEffect, preSpawnEffectDuration, spawnEffect, spawnEffectDuration, timedDestroy, preSpawnAnim, spawnAnim)  // 3 Mana Spans
    return w
endfunction

function WavesRiftWraits_Wave1 takes player owner, location loc returns Wave
    return WavesRiftWraits_Wave1Ex(owner, loc, "", 0.00, "", 0.00, false, null, null)
endfunction

function WavesRiftWraits_Wave1DelayedSoundEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string preSpawnCreateSound, string preSpawnDestroySound, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, preSpawnCreateSound, preSpawnDestroySound, spawnEffect, spawnEffectDuration, timedDestroy)  // 3 Mana Spans
    return w
endfunction

function WavesRiftWraits_Wave1DelayedEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    return WavesRiftWraits_Wave1DelayedSoundEx(owner, loc, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, "", "", spawnEffect, spawnEffectDuration, timedDestroy)
endfunction

//===========================================================================
// Wave 2 - Mana Wraiths
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave2Ex takes player owner, location loc, string preSpawnEffect, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy, animtype preSpawnAnim, animtype spawnAnim returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(w, owner, 'n002', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2, preSpawnEffect, preSpawnEffectDuration, spawnEffect, spawnEffectDuration, timedDestroy, preSpawnAnim, spawnAnim)  // 2 Mana Wraiths
    return w
endfunction

function WavesRiftWraits_Wave2 takes player owner, location loc returns Wave
    return WavesRiftWraits_Wave2Ex(owner, loc, "", 0.00, "", 0.00, false, null, null)
endfunction

function WavesRiftWraits_Wave2DelayedSoundEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string preSpawnCreateSound, string preSpawnDestroySound, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(w, owner, 'n002', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, preSpawnCreateSound, preSpawnDestroySound, spawnEffect, spawnEffectDuration, timedDestroy)  // 2 Mana Wraiths
    return w
endfunction

function WavesRiftWraits_Wave2DelayedEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    return WavesRiftWraits_Wave2DelayedSoundEx(owner, loc, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, "", "", spawnEffect, spawnEffectDuration, timedDestroy)
endfunction

//===========================================================================
// Wave 3 - Mixed
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave3Ex takes player owner, location loc, string preSpawnEffect, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy, animtype preSpawnAnim, animtype spawnAnim returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3, preSpawnEffect, preSpawnEffectDuration, spawnEffect, spawnEffectDuration, timedDestroy, preSpawnAnim, spawnAnim)  // 3 Mana Spans
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(w, owner, 'n002', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1, preSpawnEffect, preSpawnEffectDuration, spawnEffect, spawnEffectDuration, timedDestroy, preSpawnAnim, spawnAnim)  // 1 Mana Wraiths
    return w
endfunction

function WavesRiftWraits_Wave3 takes player owner, location loc returns Wave
    return WavesRiftWraits_Wave3Ex(owner, loc, "", 0.00, "", 0.00, false, null, null)
endfunction

function WavesRiftWraits_Wave3DelayedSoundEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string preSpawnCreateSound, string preSpawnDestroySound, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, preSpawnCreateSound, preSpawnDestroySound, spawnEffect, spawnEffectDuration, timedDestroy)  // 3 Mana Spans
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(w, owner, 'n002', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, preSpawnCreateSound, preSpawnDestroySound, spawnEffect, spawnEffectDuration, timedDestroy)  // 1 Mana Wraiths
    return w
endfunction

function WavesRiftWraits_Wave3DelayedEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    return WavesRiftWraits_Wave3DelayedSoundEx(owner, loc, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, "", "", spawnEffect, spawnEffectDuration, timedDestroy)
endfunction

//===========================================================================
// Wave 4 - With Devourer
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave4Ex takes player owner, location loc, string preSpawnEffect, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy, animtype preSpawnAnim, animtype spawnAnim returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2, preSpawnEffect, preSpawnEffectDuration, spawnEffect, spawnEffectDuration, timedDestroy, preSpawnAnim, spawnAnim)  // 2 Mana Spans
    call UnitSpawn_SpawnUnitRandomlyForWaveEx(w, owner, 'n028', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1, preSpawnEffect, preSpawnEffectDuration, spawnEffect, spawnEffectDuration, timedDestroy, preSpawnAnim, spawnAnim)  // 1 Mana Devourer
    return w
endfunction

function WavesRiftWraits_Wave4 takes player owner, location loc returns Wave
    return WavesRiftWraits_Wave4Ex(owner, loc, "", 0.00, "", 0.00, false, null, null)
endfunction

function WavesRiftWraits_Wave4DelayedSoundEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string preSpawnCreateSound, string preSpawnDestroySound, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    local Wave w = Wave.create()
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, preSpawnCreateSound, preSpawnDestroySound, spawnEffect, spawnEffectDuration, timedDestroy)  // 2 Mana Spans
    call UnitSpawn_SpawnUnitRandomlyForWaveDelayedSoundEx(w, owner, 'n028', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, preSpawnCreateSound, preSpawnDestroySound, spawnEffect, spawnEffectDuration, timedDestroy)  // 1 Mana Devourer
    return w
endfunction

function WavesRiftWraits_Wave4DelayedEx takes player owner, location loc, string preSpawnEffect, real preSpawnDelay, real preSpawnEffectDuration, string spawnEffect, real spawnEffectDuration, boolean timedDestroy returns Wave
    return WavesRiftWraits_Wave4DelayedSoundEx(owner, loc, preSpawnEffect, preSpawnDelay, preSpawnEffectDuration, "", "", spawnEffect, spawnEffectDuration, timedDestroy)
endfunction

endlibrary

//===========================================================================

// EXAMPLES
/*
//===========================================================================
// USAGE EXAMPLES - NEW WAVE SYSTEM
//===========================================================================

// Example 1: Spawn and track individual waves
function TestWaves_Individual takes nothing returns nothing
    local location spawnPoint = GetRectCenter(gg_rct_SpawnRegion)
    local player p = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    local Wave wave1
    local Wave wave2
    
    // Spawn wave 1 and store reference
    set wave1 = WavesRiftWraits_Wave1(p, spawnPoint)
    call BJDebugMsg("Wave 1 spawned with " + I2S(wave1.unitCount) + " units")
    
    // Wait and spawn wave 2
    call TriggerSleepAction(30.0)
    set wave2 = WavesRiftWraits_Wave2(p, spawnPoint)
    call BJDebugMsg("Wave 2 spawned with " + I2S(wave2.unitCount) + " units")
    
    // Remove only wave 1 (wave 2 remains)
    call TriggerSleepAction(10.0)
    call wave1.removeAllUnits()
    call BJDebugMsg("Wave 1 removed")
    
    // Kill wave 2 later (plays death animations, gives XP)
    call TriggerSleepAction(20.0)
    call wave2.killAllUnits()
    call BJDebugMsg("Wave 2 killed")
    
    // Clean up wave instances when done
    call wave1.destroy()
    call wave2.destroy()
    
    call RemoveLocation(spawnPoint)
    set spawnPoint = null
endfunction

// Example 2: Check remaining units in a wave
function TestWaves_CheckRemaining takes nothing returns nothing
    local location spawnPoint = GetRectCenter(gg_rct_SpawnRegion)
    local player p = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    local Wave myWave = WavesRiftWraits_Wave3(p, spawnPoint)
    local integer remaining
    
    // Check how many units are still alive
    call TriggerSleepAction(30.0)
    set remaining = myWave.getRemainingCount()
    call BJDebugMsg("Wave has " + I2S(remaining) + " units remaining")
    
    if remaining <= 0 then
        call BJDebugMsg("Wave cleared!")
        call myWave.destroy()
    endif
    
    call RemoveLocation(spawnPoint)
    set spawnPoint = null
endfunction

// Example 3: Spawn multiple waves and manage them with arrays
function TestWaves_MultipleWaves takes nothing returns nothing
    local location spawnPoint = GetRectCenter(gg_rct_SpawnRegion)
    local player p = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    local Wave array waves
    local integer i = 0
    
    // Spawn 4 waves
    set waves[0] = WavesRiftWraits_Wave1(p, spawnPoint)
    set waves[1] = WavesRiftWraits_Wave2(p, spawnPoint)
    set waves[2] = WavesRiftWraits_Wave3(p, spawnPoint)
    set waves[3] = WavesRiftWraits_Wave4(p, spawnPoint)
    
    call BJDebugMsg("All 4 waves spawned!")
    
    // Remove all waves after some time
    call TriggerSleepAction(60.0)
    loop
        exitwhen i > 3
        call waves[i].removeAllUnits()
        call waves[i].destroy()
        set i = i + 1
    endloop
    
    call RemoveLocation(spawnPoint)
    set spawnPoint = null
endfunction

// Example 4: GUI Integration - Store wave in global variable
// In GUI, create an "integer" variable called "udg_CurrentWave"
// Then use this in a trigger:
function TestWaves_GUI takes nothing returns nothing
    local location loc = GetRectCenter(gg_rct_SpawnRegion)
    local player p = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    
    // Spawn wave and store it in GUI variable (cast to integer)
    set udg_CurrentWave = WavesRiftWraits_Wave1(p, loc)
    
    // Later, to remove the wave, cast back to Wave type:
    // call Wave(udg_CurrentWave).removeAllUnits()
    // call Wave(udg_CurrentWave).destroy()
    
    call RemoveLocation(loc)
    set loc = null
endfunction

//===========================================================================
// ALTERNATIVE WAVE EXAMPLES - Create your own waves
//===========================================================================

// Wave Example 1 - Mixed undead forces
function WavesExample_Wave1 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'ugho', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 5)  // 5 Ghouls
    call SpawnUnitRandomlyForWave(w, owner, 'ucry', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3)  // 3 Crypt Fiends
    return w
endfunction

// Wave Example 2 - Heavier forces
function WavesExample_Wave2 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'ugho', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 8)  // 8 Ghouls
    call SpawnUnitRandomlyForWave(w, owner, 'ucry', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 4)  // 4 Crypt Fiends
    call SpawnUnitRandomlyForWave(w, owner, 'uabo', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2)  // 2 Abominations
    return w
endfunction

// Wave Example 3 - Elite wave
function WavesExample_Wave3 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'ugho', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 10) // 10 Ghouls
    call SpawnUnitRandomlyForWave(w, owner, 'ucry', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 6)  // 6 Crypt Fiends
    call SpawnUnitRandomlyForWave(w, owner, 'uabo', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3)  // 3 Abominations
    call SpawnUnitRandomlyForWave(w, owner, 'ufro', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1)  // 1 Frost Wyrm
    return w
endfunction

//===========================================================================
// API SUMMARY
//===========================================================================
// Wave Methods:
//   - Wave.create()                    : Creates a new wave instance
//   - wave.addUnit(unit u)             : Manually add a unit to the wave
//   - wave.removeAllUnits()            : Instantly remove all wave units (no death animation)
//   - wave.killAllUnits()              : Kill all wave units (with death animation, XP, item drops)
//   - wave.getRemainingCount()         : Get count of living units in the wave
//   - wave.destroy()                   : Clean up the wave (call when completely done with it)
//   - wave.unitCount                   : Read the initial spawn count
//   - wave.id                          : Unique wave ID
//
// Wave Spawn Functions (return Wave instance):
//   - WavesRiftWraits_Wave1(player, location)
//   - WavesRiftWraits_Wave2(player, location)
//   - WavesRiftWraits_Wave3(player, location)
//   - WavesRiftWraits_Wave4(player, location)
//===========================================================================
*/
