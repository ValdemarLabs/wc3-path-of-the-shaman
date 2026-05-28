# PatrolGroupSystem Fixes

## Issues Fixed

### 1. **Waypoint Memory Leak and Corruption**
**Problem**: Old waypoint locations weren't being cleared before generating new ones, causing potential corruption.

**Fix**: Added cleanup loop in `generateRandomWaypoints()` that removes old locations before creating new ones.

```jass
// Clear old waypoints first
loop
    exitwhen i >= 20  // Clear up to 20 waypoints to be safe
    if udg_PatrolSystem_Point[i] != null then
        call RemoveLocation(udg_PatrolSystem_Point[i])
        set udg_PatrolSystem_Point[i] = null
    endif
    set udg_PatrolSystem_Wait[i] = 0.0
    set i = i + 1
endloop
```

### 2. **Invalid Unit Handling**
**Problem**: Dead or invalid units could be added to patrol groups, causing PatrolSystem to fail.

**Fix**: Added validation in `startPatrol()` to check units before adding them:

```jass
// Only add valid, alive units
if GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD) then
    call GroupAddUnit(tempGroup, u)
    call GroupAddUnit(this.unitGroup, u)
    set hasValidUnits = true
    set unitCount = unitCount + 1
else
    call BJDebugMsg("[PatrolGroup] WARNING: Skipping invalid/dead unit")
endif
```

### 3. **Spawn Delay Too Short**
**Problem**: 0.5 second delay wasn't enough for units to fully initialize before patrol started.

**Fix**: Increased delay to 1.0 seconds:

```jass
call TimerStart(delayTimer, 1.0, false, function thistype.delayedPatrolStart)
```

### 4. **Dead Unit Cleanup**
**Problem**: Dead units stayed in the tracking group, preventing accurate respawn detection.

**Fix**: Completely rewrote `areAllUnitsDead()` to remove dead units from the group:

```jass
// Check all units and rebuild the group with only alive ones
loop
    set u = FirstOfGroup(this.unitGroup)
    exitwhen u == null
    call GroupRemoveUnit(this.unitGroup, u)
    
    if GetUnitTypeId(u) == 0 or IsUnitType(u, UNIT_TYPE_DEAD) then
        set deadCount = deadCount + 1
        // Don't add dead units back to the group
    else
        set aliveCount = aliveCount + 1
        call GroupAddUnit(tempGroup, u)
    endif
endloop
```

### 5. **Configuration Validation**
**Problem**: No validation of required configuration before starting patrol.

**Fix**: Added checks in `start()` method:

```jass
// Validate configuration
if this.patrolRegion == null then
    call BJDebugMsg("[PatrolGroup] ERROR: patrolRegion is null!")
    return
endif

if this.spawnRegion == null then
    call BJDebugMsg("[PatrolGroup] ERROR: spawnRegion is null!")
    return
endif
```

### 6. **Enhanced Debug Output**
**Problem**: Limited debug information made troubleshooting difficult.

**Fix**: Added detailed debug messages throughout spawn and patrol initialization:
- Unit spawn positions
- Unit validation status
- Group size at each stage
- Configuration values being passed to PatrolSystem

## Debugging Guide

### Check Debug Messages

When you start a patrol group, you should see these messages in order:

```
[PatrolGroup] START called
[PatrolGroup] Spawning and starting patrol...
[PatrolGroup] Spawning 6 units at (x, y)...
[PatrolGroup] Spawned unit 0: [Unit Name] at (x, y)
[PatrolGroup] Spawned unit 1: [Unit Name] at (x, y)
...
[PatrolGroup] Spawn complete. Units in group: 6
[PatrolGroup] Patrol will start in 1.0 seconds
[PatrolGroup] Delayed patrol start triggered
[PatrolGroup] Starting patrol...
[PatrolGroup] Units in unitGroup before: 6
[PatrolGroup] Generating waypoints...
[PatrolGroup] Waypoint 0 at (x, y)
...
[PatrolGroup] Waypoints generated
[PatrolGroup] Total valid units for patrol: 6 (expected: 6)
[PatrolGroup] Calling PatrolSystem_GroupStart with 6 units, 8 waypoints
[PatrolGroup] Settings: resetTime=10.0, pathStyle=0, moveOrder=attack, speed=200.0
[PatrolGroup] PatrolSystem_GroupStart returned GroupID: 1
[PatrolGroup] SUCCESS: Patrol group started
```

### Common Error Messages and Solutions

#### "ERROR: patrolRegion is null!"
**Solution**: Make sure you've set the `patrolRegion` before calling `start()`:
```jass
set myGroup.patrolRegion = gg_rct_MyPatrolArea
```

#### "ERROR: spawnRegion is null!"
**Solution**: Make sure you've set the `spawnRegion`:
```jass
set myGroup.spawnRegion = gg_rct_MySpawnPoint
```

#### "ERROR: Failed to spawn unit X"
**Solution**: Check that:
- The unit type is valid (e.g., `'hfoo'` exists in your map)
- The player exists and is valid
- The spawn coordinates are within map bounds

#### "PatrolSystem_GroupStart returned 0!"
**Solution**: This means PatrolSystem rejected the group. Check:
- Units were actually spawned (check spawn messages)
- Units are valid (not null)
- Waypoints were properly generated
- The group isn't empty

#### Units spawn but don't move
**Solution**: Check the PatrolSystem debug output for:
- Timer creation issues
- Movement order issues (try changing `moveOrder` from "attack" to "move")
- Speed issues (try setting `patrolSpeed` to 0 to use default speed)

### Testing Checklist

1. **Verify regions exist**: Make sure `gg_rct_YourPatrolArea` and `gg_rct_YourSpawn` exist in your map
2. **Check player**: Verify the player number is correct (Player(0) = Player 1 in editor)
3. **Test unit type**: Try spawning the unit manually to verify the ID is correct
4. **Check waypoint count**: Make sure `waypointCount` matches your patrol area size
5. **Monitor respawn**: After killing all units, wait for respawn time and check debug messages

### Manual Testing Commands

You can test individual components:

```jass
// Test spawn only
call myGroup.spawnUnits()

// Test waypoint generation
call myGroup.generateRandomWaypoints()

// Force respawn
call myGroup.spawnAndStartPatrol()

// Check unit status
call myGroup.checkUnitStatus()
```

## Performance Notes

- Each PatrolGroup creates its own timer for respawning
- Waypoint locations are created fresh each patrol cycle
- Dead units are automatically cleaned from tracking groups
- The system uses the centralized UnitDeathEvent for efficiency

## Known Limitations

1. **Waypoint Limit**: Maximum 20 waypoints per group (can be adjusted in cleanup loop)
2. **Group Formation**: Units spawn in a 2-column formation (128 unit spacing)
3. **Death Detection**: Uses 1-second delay after death event for stability
4. **Respawn Delay**: Fixed 1-second delay between spawn and patrol start

## Integration with PatrolSystem

The PatrolGroupSystem relies on these PatrolSystem features:
- `PatrolSystem_GroupStart()` - Initializes group patrol
- `PatrolSystem_GroupStop()` - Stops group patrol
- `udg_PatrolSystem_Point[]` - Global waypoint array
- `udg_PatrolSystem_Wait[]` - Global wait time array

Make sure PatrolSystem is properly initialized before using PatrolGroupSystem.
