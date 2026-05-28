//===========================================================================

/*    UnitSpawn Library

        Author: Valdemar

        Description:
        - Library system to spawn waves of units randomly around a point
        - Each wave is tracked individually and can be removed separately
        - Uses Bribe's Table v6 for efficient wave tracking

        Usage:
        - Call wave spawn functions (e.g., WavesRiftWraits_Wave1) to create waves
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
        - wave.removeAllUnits()            : Instantly remove all wave units (no death animation)
        - wave.killAllUnits()              : Kill all wave units (with death animation, XP
        - wave.getRemainingCount()         : Get count of living units in the wave
        - wave.destroy()                   : Clean up the wave (call when completely done with it)
        - wave.unitCount                   : Read the initial spawn count
        - wave.id                          : Unique wave ID
*/
//===========================================================================

library UnitSpawn initializer Init requires Table

globals
    // Configuration
    constant real WAVE_SPAWN_RADIUS = 300.0  // Random spawn radius around center point
    
    // Wave tracking
    private Table WaveData = 0  // Main table: [waveId].group = wave units, [waveId].integer[0] = unit count
    private integer WaveIdCounter = 0  // Auto-incrementing wave ID
endglobals

//===========================================================================
// Initialize the wave system
//===========================================================================
private function Init takes nothing returns nothing
    set WaveData = Table.create()
endfunction

//===========================================================================
// Wave Structure - Represents a single wave instance
//===========================================================================
struct Wave
    integer id
    group units
    integer unitCount
    
    //=======================================================================
    // Create a new wave instance
    //=======================================================================
    static method create takes nothing returns Wave
        local Wave this = Wave.allocate()
        set WaveIdCounter = WaveIdCounter + 1
        set this.id = WaveIdCounter
        set this.units = CreateGroup()
        set this.unitCount = 0
        
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
        
        // Count living units in the group
        loop
            set u = FirstOfGroup(this.units)
            exitwhen u == null
            call GroupRemoveUnit(this.units, u)
            if GetUnitTypeId(u) != 0 and IsUnitType(u, UNIT_TYPE_DEAD) == false then
                set count = count + 1
            endif
        endloop
        
        return count
    endmethod
    
    //=======================================================================
    // Destroy the wave and clean up
    //=======================================================================
    method onDestroy takes nothing returns nothing
        call this.removeAllUnits()
        call DestroyGroup(this.units)
        call WaveData.remove(this.id)
        set this.units = null
    endmethod
endstruct

//===========================================================================
// Helper function to spawn units randomly around a point for a wave
//===========================================================================
private function SpawnUnitRandomlyForWave takes Wave wave, player owner, integer unitId, real centerX, real centerY, real radius, integer count returns nothing
    local integer i = 0
    local real angle
    local real distance
    local real x
    local real y
    local unit u
    
    loop
        exitwhen i >= count
        
        // Generate random angle and distance
        set angle = GetRandomReal(0, 360) * bj_DEGTORAD
        set distance = GetRandomReal(0, radius)
        
        // Calculate spawn position
        set x = centerX + distance * Cos(angle)
        set y = centerY + distance * Sin(angle)
        
        // Create unit and add to wave
        set u = CreateUnit(owner, unitId, x, y, GetRandomReal(0, 360))
        call wave.addUnit(u)
        
        set i = i + 1
    endloop
    
    set u = null
endfunction

//===========================================================================
// Wave 1 - Mana Spawns
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave1 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3)  // 3 Mana Spans
    return w
endfunction

//===========================================================================
// Wave 2 - Mana Wraiths
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave2 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'n002', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2)  // 2 Mana Wraiths
    return w
endfunction

//===========================================================================
// Wave 3 - Mixed
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave3 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 3)  // 3 Mana Spans
    call SpawnUnitRandomlyForWave(w, owner, 'n002', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1)  // 1 Mana Wraiths
    return w
endfunction

//===========================================================================
// Wave 4 - With Devourer
// Returns: Wave instance that can be used to manage this specific wave
//===========================================================================
function WavesRiftWraits_Wave4 takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'n027', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 2)  // 2 Mana Spans
    call SpawnUnitRandomlyForWave(w, owner, 'n028', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 1)  // 1 Mana Devourer
    return w
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
