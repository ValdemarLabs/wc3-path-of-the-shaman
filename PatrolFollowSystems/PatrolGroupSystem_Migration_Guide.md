# PatrolGroupSystem Update - Migration Guide

## What Changed?

### ✅ Backward Compatibility
Your existing code using random waypoints will continue to work without any changes!

### ✨ New Feature
You can now set manual waypoints for precise patrol routes.

---

## If You're Using Random Waypoints

### No Action Required
Your existing code like this will work exactly as before:

```jass
set myPatrol = PatrolGroup.create()
set myPatrol.patrolRegion = gg_rct_PatrolArea
set myPatrol.spawnRegion = gg_rct_SpawnPoint
set myPatrol.waypointCount = 5
call myPatrol.start()
```

---

## If You Want to Use Manual Waypoints

### Quick Conversion Example

#### Before (Random)
```jass
function InitMyPatrol takes nothing returns nothing
    set myPatrol = PatrolGroup.create()
    set myPatrol.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    set myPatrol.unitType = 'hfoo'
    set myPatrol.unitCount = 4
    set myPatrol.patrolRegion = gg_rct_PatrolArea    ← Only change needed
    set myPatrol.spawnRegion = gg_rct_SpawnPoint
    set myPatrol.waypointCount = 5
    set myPatrol.waypointWait = 2.00
    call myPatrol.start()
endfunction
```

#### After (Manual)
```jass
function InitMyPatrol takes nothing returns nothing
    set myPatrol = PatrolGroup.create()
    set myPatrol.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    set myPatrol.unitType = 'hfoo'
    set myPatrol.unitCount = 4
    // Remove: set myPatrol.patrolRegion = ...        ← Not needed
    set myPatrol.spawnRegion = gg_rct_SpawnPoint
    set myPatrol.waypointCount = 5
    // Remove: set myPatrol.waypointWait = 2.00       ← Set per waypoint instead
    
    // Add: Manual waypoint configuration
    call myPatrol.setWaypointFromRect(0, gg_rct_WP01, 2.00)
    call myPatrol.setWaypointFromRect(1, gg_rct_WP02, 0.00)
    call myPatrol.setWaypointFromRect(2, gg_rct_WP03, 3.00)
    call myPatrol.setWaypointFromRect(3, gg_rct_WP04, 0.00)
    call myPatrol.setWaypointFromRect(4, gg_rct_WP05, 2.00)
    
    call myPatrol.start()
endfunction
```

---

## Converting from PatrolSystem_Start to PatrolGroup (Manual)

If you're using the old single-unit patrol style like Mordrax:

### Before (PatrolSystem_Start)
```jass
function StartBossPatrol takes nothing returns nothing
    local integer i
    
    set udg_TempUnit = udg_BossUnit
    
    set udg_PatrolSystem_Point[0] = GetRectCenter(gg_rct_BossWP01)
    set udg_PatrolSystem_Wait[0] = 5.00
    set udg_PatrolSystem_Point[1] = GetRectCenter(gg_rct_BossWP02)
    set udg_PatrolSystem_Wait[1] = 0.00
    set udg_PatrolSystem_Point[2] = GetRectCenter(gg_rct_BossWP03)
    set udg_PatrolSystem_Wait[2] = 3.00
    
    call PatrolSystem_Start(udg_TempUnit, 3, 30.00, 0, true, "move", 150.00)
    
    // Cleanup
    set i = 0
    loop
        exitwhen i > 3
        call RemoveLocation(udg_PatrolSystem_Point[i])
        set i = i + 1
    endloop
endfunction
```

### After (PatrolGroup with Manual Waypoints)
```jass
globals
    private PatrolGroup bossPatrol
endglobals

function StartBossPatrol takes nothing returns nothing
    set bossPatrol = PatrolGroup.create()
    
    // Configure the patrol
    set bossPatrol.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    set bossPatrol.unitType = 'Nbos'  // Boss unit type
    set bossPatrol.unitCount = 1      // Single unit
    set bossPatrol.spawnRegion = gg_rct_BossSpawn
    set bossPatrol.waypointCount = 3
    set bossPatrol.patrolSpeed = 150.00
    set bossPatrol.resetTime = 30.00
    set bossPatrol.pathStyle = PATROL_STYLE_LOOP
    set bossPatrol.moveOrder = "move"
    
    // Set waypoints (no need to remove locations!)
    call bossPatrol.setWaypointFromRect(0, gg_rct_BossWP01, 5.00)
    call bossPatrol.setWaypointFromRect(1, gg_rct_BossWP02, 0.00)
    call bossPatrol.setWaypointFromRect(2, gg_rct_BossWP03, 3.00)
    
    // Start patrol (handles spawning and movement)
    call bossPatrol.start()
endfunction
```

**Benefits of the new approach:**
- ✅ No location leaks (no need for RemoveLocation)
- ✅ Automatic respawning
- ✅ Built-in death handling
- ✅ Cleaner code structure
- ✅ Easier to manage multiple patrols

---

## Common Migration Tasks

### Task 1: Converting 5 Random Waypoints to 5 Manual Waypoints

**Steps:**
1. Keep `waypointCount = 5`
2. Remove `patrolRegion` line
3. Remove `waypointWait` line (if set)
4. Add 5 `setWaypointFromRect()` calls
5. Keep everything else the same

### Task 2: Creating Regions in World Editor

Before using manual waypoints:
1. Open World Editor
2. Create regions for each waypoint (e.g., `WP01`, `WP02`, etc.)
3. Name them descriptively (e.g., `Town_Square`, `Guard_Post`)
4. Save the map

### Task 3: Testing Your Migration

```jass
// Enable debug messages to verify waypoints are set correctly
call BJDebugMsg("[Test] Starting manual waypoint patrol")

// The system will automatically log:
// [PatrolGroup] Manual waypoint [0] set: (x, y), wait=...
// [PatrolGroup] Manual waypoint [1] set: (x, y), wait=...
// etc.
```

---

## Troubleshooting

### Problem: "Waypoint [X] not set (0,0)"
**Solution:** You forgot to call `setWaypoint()` for that index
```jass
// Make sure you set ALL waypoints from 0 to waypointCount-1
call pg.setWaypointFromRect(0, ...)
call pg.setWaypointFromRect(1, ...)
call pg.setWaypointFromRect(2, ...)
// etc.
```

### Problem: "patrolRegion is null!"
**Solution:** When using manual waypoints, don't set patrolRegion
```jass
// Remove this line when using manual waypoints:
// set pg.patrolRegion = gg_rct_Area

// You only need spawnRegion:
set pg.spawnRegion = gg_rct_Spawn
```

### Problem: Units spawn but don't move
**Solution:** Check that waypointCount matches the number of waypoints set
```jass
set pg.waypointCount = 3  // Must match

call pg.setWaypointFromRect(0, ...)  // 1
call pg.setWaypointFromRect(1, ...)  // 2
call pg.setWaypointFromRect(2, ...)  // 3
```

### Problem: All units wait the same time at each waypoint
**Solution:** Set individual wait times per waypoint
```jass
// Each waypoint can have different wait time:
call pg.setWaypointFromRect(0, gg_rct_WP01, 5.00)  // Wait 5 seconds
call pg.setWaypointFromRect(1, gg_rct_WP02, 0.00)  // No wait
call pg.setWaypointFromRect(2, gg_rct_WP03, 10.00) // Wait 10 seconds
```

---

## Decision Tree: Which Method Should I Use?

```
Do you need precise patrol routes?
│
├─ No → Use RANDOM waypoints
│        ↓
│        set pg.patrolRegion = gg_rct_Area
│        set pg.waypointCount = 5
│        call pg.start()
│
└─ Yes → Use MANUAL waypoints
         ↓
         Do you have GUI regions set up?
         │
         ├─ Yes → Use setWaypointFromRect()
         │         ↓
         │         call pg.setWaypointFromRect(0, gg_rct_WP01, 2.0)
         │
         └─ No → Use setWaypoint() with coordinates
                  ↓
                  call pg.setWaypoint(0, -2304.0, 1536.0, 2.0)
```

---

## Summary Checklist

### ✅ For Existing Random Waypoint Users
- [ ] No changes needed
- [ ] Code continues to work as before
- [ ] Consider manual waypoints for special cases

### ✅ For New Manual Waypoint Users
- [ ] Create waypoint regions in World Editor
- [ ] Set `waypointCount` to match number of waypoints
- [ ] Call `setWaypointFromRect()` for each waypoint
- [ ] Set individual wait times per waypoint
- [ ] Don't set `patrolRegion` when using manual waypoints
- [ ] Always set `spawnRegion`
- [ ] Test with debug messages enabled

### ✅ For Migrating from PatrolSystem_Start
- [ ] Create PatrolGroup instance
- [ ] Set unitCount = 1 for single unit
- [ ] Use setWaypointFromRect() instead of GUI arrays
- [ ] No need to clean up locations
- [ ] Benefit from automatic respawning

---

## Need Help?

See these files for examples:
- `PatrolGroup_ManualWaypoints_Example.j` - Working examples
- `PatrolGroupSystem_ManualWaypoints_Guide.md` - Full documentation
- `PatrolGroupSystem_Visual_Guide.md` - Visual comparisons
- `Mordrax_MovementStart.j` - Original single-unit style
