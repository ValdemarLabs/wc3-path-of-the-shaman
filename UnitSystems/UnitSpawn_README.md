# UnitSpawn Library - Upgrade Summary

## What Changed?

The UnitSpawn system has been transformed from a simple global system into a **library with individual wave tracking** using Bribe's Table v6.

### Key Improvements

1. **Individual Wave Management**: Each wave is now tracked separately with its own `Wave` instance
2. **Selective Removal**: You can now remove or kill specific waves without affecting others
3. **Wave Tracking**: Each wave has a unique ID and can be queried for remaining unit count
4. **Table v6 Integration**: Uses efficient hashtable storage for wave data
5. **Struct-Based Design**: Clean OOP approach with the `Wave` struct

## API Changes

### Old System (Global)
```jass
// Spawned all units into one global group
call WavesRiftWraits_Wave1(player, location)  // returns nothing
call UnitSpawn_RemoveAllUnits()                // Removes ALL waves
call UnitSpawn_KillAllUnits()                  // Kills ALL waves
```

### New System (Individual Tracking)
```jass
// Each wave returns a Wave instance for individual management
local Wave wave1 = WavesRiftWraits_Wave1(player, location)
local Wave wave2 = WavesRiftWraits_Wave2(player, location)

// Remove only wave1 (wave2 stays alive)
call wave1.removeAllUnits()
call wave1.destroy()

// Kill wave2 separately (with death animation, XP, drops)
call wave2.killAllUnits()
call wave2.destroy()
```

## Wave Struct API

### Methods
- `Wave.create()` - Creates a new wave instance
- `wave.addUnit(unit u)` - Manually add a unit to the wave
- `wave.removeAllUnits()` - Instantly remove all wave units (no death animation)
- `wave.killAllUnits()` - Kill all wave units (with death animation, XP, item drops)
- `wave.getRemainingCount()` - Get count of living units in the wave
- `wave.destroy()` - Clean up the wave (call when done)

### Properties
- `wave.unitCount` - Initial spawn count
- `wave.id` - Unique wave ID
- `wave.units` - Unit group (for advanced usage)

## Usage Examples

### Example 1: Spawn and Remove Individual Waves
```jass
function SpawnWaves takes nothing returns nothing
    local location loc = GetRectCenter(gg_rct_SpawnRegion)
    local player p = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    local Wave wave1
    local Wave wave2
    
    // Spawn two different waves
    set wave1 = WavesRiftWraits_Wave1(p, loc)
    set wave2 = WavesRiftWraits_Wave2(p, loc)
    
    // Wait 30 seconds then remove only wave1
    call TriggerSleepAction(30.0)
    call wave1.removeAllUnits()
    call wave1.destroy()
    // wave2 still exists!
    
    // Clean up wave2 later
    call TriggerSleepAction(30.0)
    call wave2.killAllUnits()
    call wave2.destroy()
    
    call RemoveLocation(loc)
    set loc = null
endfunction
```

### Example 2: Check Remaining Units
```jass
function CheckWaveCleared takes nothing returns nothing
    local Wave myWave = WavesRiftWraits_Wave3(player, location)
    local integer remaining
    
    call TriggerSleepAction(60.0)
    set remaining = myWave.getRemainingCount()
    
    if remaining <= 0 then
        call BJDebugMsg("Wave cleared!")
        call myWave.destroy()
    else
        call BJDebugMsg(I2S(remaining) + " enemies remaining")
    endif
endfunction
```

### Example 3: Store Waves in Arrays
```jass
function ManageMultipleWaves takes nothing returns nothing
    local Wave array waves
    local integer i = 0
    
    // Spawn multiple waves
    set waves[0] = WavesRiftWraits_Wave1(player, location)
    set waves[1] = WavesRiftWraits_Wave2(player, location)
    set waves[2] = WavesRiftWraits_Wave3(player, location)
    
    // Clean up all waves later
    loop
        exitwhen i > 2
        call waves[i].removeAllUnits()
        call waves[i].destroy()
        set i = i + 1
    endloop
endfunction
```

### Example 4: GUI Integration
In GUI, create an **Integer** variable called `CurrentWave`, then:

**Spawning:**
```jass
Custom script:   set udg_CurrentWave = WavesRiftWraits_Wave1(Player(PLAYER_NEUTRAL_AGGRESSIVE), udg_SpawnPoint)
```

**Removing:**
```jass
Custom script:   call Wave(udg_CurrentWave).removeAllUnits()
Custom script:   call Wave(udg_CurrentWave).destroy()
```

## Available Wave Functions

All wave functions now return a `Wave` instance:
- `WavesRiftWraits_Wave1(player, location)` - 3 Mana Spans
- `WavesRiftWraits_Wave2(player, location)` - 2 Mana Wraiths
- `WavesRiftWraits_Wave3(player, location)` - 3 Mana Spans + 1 Mana Wraith
- `WavesRiftWraits_Wave4(player, location)` - 2 Mana Spans + 1 Mana Devourer

## Creating Custom Waves

```jass
function MyCustomWave takes player owner, location loc returns Wave
    local Wave w = Wave.create()
    call SpawnUnitRandomlyForWave(w, owner, 'hfoo', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 10)
    call SpawnUnitRandomlyForWave(w, owner, 'hkni', GetLocationX(loc), GetLocationY(loc), WAVE_SPAWN_RADIUS, 5)
    return w
endfunction
```

## Requirements

- **Table v6** library (already in `00_PotS/Core/Table6.j`)
- Must be loaded after Table library in your map script

## Migration Notes

1. **Breaking Change**: Wave spawn functions now return `Wave` instead of `nothing`
2. **Store Wave References**: You must store the returned `Wave` to manage it later
3. **Manual Cleanup**: Call `wave.destroy()` when completely done with a wave
4. **No Global Removal**: The old `WaveSpawner_RemoveAllUnits()` function is removed - manage waves individually

## Benefits

✅ **Precise Control**: Remove specific waves without affecting others  
✅ **Wave Tracking**: Know exactly how many units remain in each wave  
✅ **Memory Safe**: Uses Table v6 for efficient hashtable management  
✅ **Flexible**: Store wave references in arrays, tables, or GUI variables  
✅ **Clean Code**: OOP struct-based design for maintainability  

## Internal Structure

The system uses:
- `Table WaveData` - Stores wave groups and unit counts
- `Wave` struct - Represents individual wave instances
- `WaveIdCounter` - Auto-incrementing unique wave IDs
- Bribe's Table v6 for efficient data storage
