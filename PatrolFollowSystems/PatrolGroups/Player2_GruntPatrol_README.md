# Player 2 Grunt Patrol System - Quick Reference

## Overview
A complete system that spawns 4 Grunts for Player 2, makes them patrol random points in a region, and automatically respawns them 120 seconds after they all die.

## Features
- ✅ Spawns 4 Grunts at a designated spawn point
- ✅ Patrols 5 random waypoints within a specified region
- ✅ Uses PatrolSystem group functions for coordinated movement
- ✅ Maintains formation during patrol
- ✅ Automatically respawns after 120 seconds when all grunts die
- ✅ Fully configurable through global constants

## Setup Instructions

### 1. Create Required Regions in World Editor
Create two regions:
- **GruntPatrolArea** - Where the grunts will patrol (larger area)
- **GruntSpawn** - Where the grunts will spawn (small area)

### 2. Add Library to Map
Include the `Player2_GruntPatrol.j` file in your map's script.

### 3. Start the System
Three ways to start:

#### Option A: Auto-start (Edit Init function)
Uncomment these lines in `Player2_GruntPatrol.j`:
```jass
private function Init takes nothing returns nothing
    // ... existing code ...
    
    call TriggerSleepAction(10.0)  // Wait 10 seconds
    call StartPlayer2GruntPatrol(gg_rct_GruntPatrolArea, gg_rct_GruntSpawn)
endfunction
```

#### Option B: GUI Trigger
Create a trigger in GUI:
- **Event**: Map initialization (or time elapsed)
- **Actions**: 
  - Custom script: `call StartPlayer2GruntPatrol(gg_rct_GruntPatrolArea, gg_rct_GruntSpawn)`

#### Option C: JASS Trigger
Use the provided `Player2_GruntPatrol_Triggers.j` file.

## Configuration

Edit these constants in `Player2_GruntPatrol.j`:

```jass
private constant player GRUNT_OWNER = Player(1)         // Player 2
private constant integer GRUNT_TYPE = 'ogru'            // Unit type (Grunt)
private constant integer GRUNT_COUNT = 4                // Number of units
private constant real RESPAWN_TIME = 120.0              // Respawn delay in seconds
private constant integer WAYPOINT_COUNT = 5             // Number of patrol points
private constant real PATROL_SPEED = 250.0              // Movement speed
private constant real WAYPOINT_WAIT = 2.0               // Wait time at waypoints
private constant real RESET_TIME = 15.0                 // Combat recovery time
```

### Common Unit Type Codes
- `'ogru'` = Grunt
- `'ohun'` = Troll Headhunter
- `'otau'` = Tauren
- `'oshm'` = Shaman
- `'orai'` = Raider

## Public Functions

### StartPlayer2GruntPatrol
Starts the patrol system.
```jass
call StartPlayer2GruntPatrol(patrolRegion, spawnRegion)
```
**Parameters:**
- `patrolRegion` - rect where units patrol
- `spawnRegion` - rect where units spawn

**Example:**
```jass
call StartPlayer2GruntPatrol(gg_rct_GruntPatrolArea, gg_rct_GruntSpawn)
```

### StopPlayer2GruntPatrol
Stops the patrol system and removes all units.
```jass
call StopPlayer2GruntPatrol()
```

### RestartPlayer2GruntPatrol
Restarts patrol with new random waypoints (useful for variety).
```jass
call RestartPlayer2GruntPatrol()
```

## How It Works

1. **Spawn Phase**
   - 4 Grunts spawn in a small formation at the spawn region
   - Each grunt is added to a tracking group

2. **Patrol Phase**
   - System generates 5 random points within the patrol region
   - Grunts patrol these points using `PatrolSystem_GroupStart`
   - They maintain formation throughout the patrol
   - Wait 2 seconds at each waypoint

3. **Combat Phase**
   - If grunts are attacked or attack, they pause patrol
   - After 15 seconds of no combat, they resume patrol

4. **Death & Respawn Phase**
   - System monitors grunt deaths
   - When all 4 grunts are dead, starts 120-second timer
   - After timer expires, spawns new grunts and restarts patrol

## Advanced Usage

### Multiple Grunt Patrols
To create multiple independent patrols, copy the library and rename:
```jass
library Player3_GruntPatrol initializer Init
// Change all constants and function names
```

### Dynamic Control
```jass
// Stop patrol during boss fight
call StopPlayer2GruntPatrol()

// Restart after boss dies
call StartPlayer2GruntPatrol(gg_rct_GruntPatrolArea, gg_rct_GruntSpawn)

// Randomize patrol path every 5 minutes
call TriggerRegisterTimerEventPeriodic(trigger, 300.00)
call RestartPlayer2GruntPatrol()
```

### Custom Behaviors
Modify the `OnGruntDeath` function to add custom logic:
```jass
private function OnGruntDeath takes nothing returns nothing
    // Play death sound
    call PlaySoundBJ(gg_snd_GruntDeath)
    
    // Drop items
    call CreateItem('I001', GetUnitX(dying), GetUnitY(dying))
    
    // Existing death logic...
endfunction
```

## Troubleshooting

**Grunts don't spawn:**
- Check that regions are created in World Editor
- Verify region variable names match (case-sensitive)
- Check that Player 2 has proper alliance settings

**Grunts don't patrol:**
- Ensure PatrolSystem.j is included in your map
- Check that `udg_PatrolSystem_Point` and `udg_PatrolSystem_Wait` arrays exist

**Grunts don't respawn:**
- Verify all 4 grunts are actually dead
- Check that system is active: `isActive = true`
- Enable debug messages by uncommenting `BJDebugMsg` calls

**Patrol breaks formation:**
- Check that patrol region is large enough
- Ensure EPSILON value in PatrolSystem is appropriate (32.00)

## Debug Mode

Uncomment debug messages to troubleshoot:
```jass
call BJDebugMsg("[GruntPatrol] Started patrol with " + I2S(GRUNT_COUNT) + " grunts")
call BJDebugMsg("[GruntPatrol] All grunts dead. Respawning in 120s...")
call BJDebugMsg("[GruntPatrol] System started!")
```

## Dependencies
- PatrolSystem.j (main patrol system library)
- DamageEngine (for combat detection)
- Table library (used by PatrolSystem)
