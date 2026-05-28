# Generic Patrol Group System

## Overview
A reusable, generic system for creating multiple patrol groups with automatic spawning and respawning. Each patrol group is configured in its own small file.

## Architecture

### Core Files
1. **PatrolGroupSystem.j** - Generic reusable patrol group struct and logic
2. **PatrolGroup_*.j** - Small configuration files for each specific patrol group

### Benefits
- ✅ Write the complex logic once
- ✅ Each patrol group is ~40 lines of simple configuration
- ✅ Easy to add new patrol groups
- ✅ Easy to maintain and debug
- ✅ Consistent behavior across all patrols

## Creating a New Patrol Group

### Step 1: Create a new file
Create `PatrolGroup_YourName.j`:

```jass
library PatrolGroup_YourName initializer Init requires PatrolGroupSystem

globals
    private PatrolGroup myPatrolGroup = 0
endglobals

private function Init takes nothing returns nothing
    local trigger startTrigger
    
    // Create patrol group
    set myPatrolGroup = PatrolGroup.create()
    
    // Configuration - CUSTOMIZE THESE!
    set myPatrolGroup.owner = Player(5)                    // Which player owns units
    set myPatrolGroup.unitType = 'ogru'                    // Unit type code
    set myPatrolGroup.unitCount = 4                        // How many units
    set myPatrolGroup.respawnTime = 120.0                  // Respawn delay in seconds
    set myPatrolGroup.waypointCount = 10                   // Number of random waypoints
    set myPatrolGroup.patrolSpeed = 250.0                  // Movement speed (0 = default)
    set myPatrolGroup.waypointWait = 2.0                   // Wait time at waypoints
    set myPatrolGroup.resetTime = 15.0                     // Combat reset time
    set myPatrolGroup.patrolRegion = gg_rct_YourPatrolArea // Where they patrol
    set myPatrolGroup.spawnRegion = gg_rct_YourSpawnPoint  // Where they spawn
    set myPatrolGroup.pathStyle = PATROL_STYLE_PINGPONG   // Or PATROL_STYLE_LOOP
    set myPatrolGroup.moveOrder = "move"                   // "move" or "attack"
    
    // Auto-start after 5 seconds
    set startTrigger = CreateTrigger()
    call TriggerRegisterTimerEventSingle(startTrigger, 5.00)
    call TriggerAddCondition(startTrigger, Condition(function thistype.start))
endfunction

private function start takes nothing returns boolean
    call myPatrolGroup.start()
    return false
endfunction

endlibrary
```

### Step 2: Include in your map
Just include the file - it starts automatically!

## Configuration Options

### owner (player)
Which player controls the units.
- `Player(0)` = Player 1 (Red)
- `Player(1)` = Player 2 (Blue)
- etc.

### unitType (integer)
Four-character unit type code.
- `'ogru'` = Grunt
- `'ohun'` = Troll Headhunter
- `'otau'` = Tauren
- `'hfoo'` = Footman
- `'hkni'` = Knight

### unitCount (integer)
Number of units in the patrol group (1-12 recommended).

### respawnTime (real)
Delay in seconds before respawning after all units die.

### waypointCount (integer)
Number of random waypoints to generate within patrol region.

### patrolSpeed (real)
Movement speed during patrol.
- `0.0` = Use unit's default speed
- `140.0` = Slow patrol
- `250.0` = Normal speed
- `350.0` = Fast patrol

### waypointWait (real)
How long to wait at each waypoint (seconds).

### resetTime (real)
How long after combat before resuming patrol (seconds).

### patrolRegion (rect)
Region where units will patrol (system generates random points within this area).

### spawnRegion (rect)
Region where units will spawn (usually a small area).

### pathStyle (integer)
Patrol pattern:
- `PATROL_STYLE_LOOP` = A → B → C → A → B → C...
- `PATROL_STYLE_PINGPONG` = A → B → C → B → A → B...

### moveOrder (string)
Order type for movement:
- `"move"` = Normal movement
- `"attack"` = Attack-move (will engage enemies)
- `"patrol"` = Patrol order

## Manual Control (Optional)

You can manually control any patrol group:

```jass
// Stop the patrol
call myPatrolGroup.stop()

// Restart the patrol
call myPatrolGroup.start()

// Restart with new random waypoints
call myPatrolGroup.restart()
```

## Examples

### Forest Scouts (Fast, Light Patrol)
```jass
set scouts.owner = Player(2)
set scouts.unitType = 'earc'              // Archer
set scouts.unitCount = 3
set scouts.respawnTime = 60.0             // Quick respawn
set scouts.waypointCount = 15             // Many waypoints
set scouts.patrolSpeed = 300.0            // Fast movement
set scouts.waypointWait = 1.0             // Brief stops
set scouts.pathStyle = PATROL_STYLE_LOOP
```

### Guard Tower Defense (Slow, Heavy Patrol)
```jass
set guards.owner = Player(5)
set guards.unitType = 'hkni'              // Knight
set guards.unitCount = 6
set guards.respawnTime = 180.0            // Long respawn
set guards.waypointCount = 4              // Few waypoints
set guards.patrolSpeed = 180.0            // Slow movement
set scouts.waypointWait = 15.0            // Long stops
set guards.pathStyle = PATROL_STYLE_PINGPONG
set guards.moveOrder = "attack"           // Aggressive
```

## Multiple Patrol Groups

You can have as many patrol groups as you want! Each is independent:

```
PatrolGroup_ThornwoodsGrunts.j     (4 grunts, slow patrol)
PatrolGroup_RiverbaneTrolls.j      (6 trolls, medium patrol)
PatrolGroup_ForestScouts.j         (3 archers, fast patrol)
PatrolGroup_CityGuards.j           (8 knights, defensive)
```

All use the same core system (PatrolGroupSystem.j).

## Troubleshooting

**Units don't spawn:**
- Check that regions exist in World Editor
- Verify region variable names are correct
- Check player index (Player(0) = Red, Player(1) = Blue, etc.)

**Units don't respawn:**
- Verify all units actually died
- Check `respawnTime` is > 0
- Check `unitType` matches exactly

**Units break formation:**
- Increase `EPSILON` in PatrolSystem.j if patrol area is very large
- Reduce `patrolSpeed` for tighter formation

**Multiple patrols interfere:**
- Each patrol group is independent - they shouldn't interfere
- If using same unit type and player, ensure spawn regions are different

## Performance

The system is highly optimized:
- Each patrol group has its own timer
- Death detection is shared across all groups (single trigger)
- Waypoints are generated once per spawn
- Can handle 10+ patrol groups without lag
