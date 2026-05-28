# PatrolGroupThornwoodsHorde Testing Guide

## Quick Test Checklist

Before running the map, verify these settings in PatrolGroupThornwoodsHorde.j:

### 1. Regions Must Exist
In World Editor, check that these regions exist:
- ✅ `gg_rct_06Thornwoods` - Patrol area (should be a large region)
- ✅ `gg_rct_GruntPatrolSpawn` - Spawn point (small region inside or near patrol area)

### 2. Configuration Review
Current settings:
```jass
owner = Player(1)              // Player 2 (Red)
unitType = 'ogru'               // Grunt
unitCount = 4                   // 4 Grunts
respawnTime = 120.0             // 2 minutes
waypointCount = 20              // 20 random waypoints
patrolSpeed = 140.0             // Slow speed
waypointWait = 10.0             // 10 seconds at each waypoint
resetTime = 15.0                // 15 seconds after combat
pathStyle = PATROL_STYLE_PINGPONG  // Back and forth
moveOrder = "move"              // Move order (not attack-move)
```

### 3. Expected Debug Messages

When you start the game, press F12 to see debug messages. You should see this sequence:

#### Initial Startup (at 5 seconds):
```
[PatrolGroup] START called
[PatrolGroup] Spawning and starting patrol...
[PatrolGroup] Spawning 4 units at (x, y)...
[PatrolGroup] Spawned unit 0: Grunt at (x, y)
[PatrolGroup] Spawned unit 1: Grunt at (x, y)
[PatrolGroup] Spawned unit 2: Grunt at (x, y)
[PatrolGroup] Spawned unit 3: Grunt at (x, y)
[PatrolGroup] Spawn complete. Units in group: 4
[PatrolGroup] Patrol will start in 2.0 seconds
```

#### After 2 Second Delay:
```
[PatrolGroup] Delayed patrol start triggered
[PatrolGroup] Verifying units before patrol start...
[PatrolGroup]   Unit 0: Grunt at (x, y) - VALID
[PatrolGroup]   Unit 1: Grunt at (x, y) - VALID
[PatrolGroup]   Unit 2: Grunt at (x, y) - VALID
[PatrolGroup]   Unit 3: Grunt at (x, y) - VALID
[PatrolGroup] Valid units ready for patrol: 4
[PatrolGroup] Starting patrol...
[PatrolGroup] Units in unitGroup before: 4
[PatrolGroup] Generating waypoints...
[PatrolGroup] Waypoint 0 at (x, y)
[PatrolGroup] Waypoint 1 at (x, y)
... (20 waypoints total)
[PatrolGroup] Waypoints generated and set in udg_PatrolSystem_Point[]
[PatrolGroup] Total valid units for patrol: 4 (expected: 4)
[PatrolGroup] Calling PatrolSystem_GroupStart...
[PatrolGroup]   Units: 4
[PatrolGroup]   Waypoints: 20
[PatrolGroup]   ResetTime: 15.0
[PatrolGroup]   PathStyle: 1
[PatrolGroup]   MoveOrder: move
[PatrolGroup]   PatrolSpeed: 140.0
[PatrolGroup] PatrolSystem_GroupStart returned GroupID: 1
[PatrolGroup] SUCCESS: Patrol group started with GroupID 1
[PatrolGroup] Units in tracking group after start: 4
[PatrolGroup] Cleaned up 20 waypoint locations
```

## Troubleshooting

### Error: "patrolRegion is null!"
**Problem**: Region doesn't exist or variable name is wrong.
**Solution**: 
1. Open World Editor
2. Go to Layer → Regions
3. Create a region named exactly: `06Thornwoods`
4. Make sure it's visible and has a reasonable size (e.g., 2000x2000)

### Error: "spawnRegion is null!"
**Problem**: Spawn region doesn't exist.
**Solution**:
1. Create a region named exactly: `GruntPatrolSpawn`
2. Place it inside or near the patrol area
3. Make it small (e.g., 512x512)

### Error: "Failed to spawn unit X"
**Problem**: Unit type code is wrong or player doesn't exist.
**Solutions**:
- Check that `'ogru'` is a valid unit type in your map
- Verify Player 2 exists in your map
- Try changing to a different unit type (e.g., `'hfoo'` for Footman)
- Try changing to Player 1 with `Player(0)`

### Error: "PatrolSystem_GroupStart returned 0!"
**Problem**: PatrolSystem rejected the group.
**Possible causes**:
1. **Group is empty** - No units were spawned
2. **Waypoints invalid** - Check waypoint generation messages
3. **Parameters invalid** - Check waypointCount > 0, units exist

### Units spawn but don't move
**Check these:**
1. Look for SUCCESS message with GroupID > 0
2. Check that waypoints are within the patrol region
3. Try changing `moveOrder` from "move" to "attack"
4. Try setting `patrolSpeed` to 0 (uses default speed)
5. Check that patrol region is large enough for 20 waypoints

### Units move to first waypoint then stop
**Possible causes:**
1. Timer issue in PatrolSystem
2. Combat reset triggering
3. Wait time too long (try reducing `waypointWait` to 2.0)

## Testing Commands

### Manual Testing (add to map):

```jass
// Test spawn only
function TestSpawn takes nothing returns nothing
    call BJDebugMsg("=== MANUAL TEST: Spawn ===")
    // Access the thornwoodsGrunts instance and test spawn
endfunction

// Test with different settings
function TestDifferentSettings takes nothing returns nothing
    local PatrolGroup testGroup = PatrolGroup.create()
    
    set testGroup.owner = Player(0)  // Player 1
    set testGroup.unitType = 'hfoo'  // Footman
    set testGroup.unitCount = 3
    set testGroup.respawnTime = 60.0
    set testGroup.waypointCount = 5  // Fewer waypoints
    set testGroup.patrolSpeed = 250.0  // Faster
    set testGroup.waypointWait = 2.0  // Less wait
    set testGroup.resetTime = 10.0
    set testGroup.patrolRegion = gg_rct_06Thornwoods
    set testGroup.spawnRegion = gg_rct_GruntPatrolSpawn
    set testGroup.pathStyle = PATROL_STYLE_LOOP
    set testGroup.moveOrder = "move"
    
    call testGroup.start()
endfunction
```

## Common Configuration Changes

### Make patrol faster:
```jass
set thornwoodsGrunts.patrolSpeed = 250.0
set thornwoodsGrunts.waypointWait = 2.0
set thornwoodsGrunts.waypointCount = 10
```

### Make patrol slower/more methodical:
```jass
set thornwoodsGrunts.patrolSpeed = 100.0
set thornwoodsGrunts.waypointWait = 15.0
set thornwoodsGrunts.waypointCount = 30
```

### Use attack-move instead of move:
```jass
set thornwoodsGrunts.moveOrder = "attack"
```

### Change to loop instead of ping-pong:
```jass
set thornwoodsGrunts.pathStyle = PATROL_STYLE_LOOP
```

## Expected Behavior

1. **At 5 seconds**: 4 Grunts spawn in formation at spawn region
2. **At 7 seconds**: Grunts start moving toward first waypoint
3. **Movement**: Grunts move as a group, maintaining formation
4. **At waypoints**: Grunts wait 10 seconds before moving to next
5. **Patrol pattern**: Ping-pong (A→B→C→B→A→B→C...)
6. **If attacked**: Patrol pauses, resumes after 15 seconds of no combat
7. **If all die**: Respawn at spawn region after 120 seconds

## Performance Notes

With 20 waypoints and 4 units:
- Memory usage: Minimal (1 struct instance, 1 timer, 1 group)
- CPU usage: Very low (event-driven, not polled)
- Should support dozens of patrol groups simultaneously

## Integration

This system is designed to work alongside:
- Single unit patrols (PatrolSystem)
- Other patrol groups
- Quest systems
- AI triggers
- Custom behaviors

No conflicts expected with other systems.
