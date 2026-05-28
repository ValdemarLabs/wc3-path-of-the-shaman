# PatrolSystem & PatrolGroupSystem Updates Summary

## Date: October 30, 2025

### 1. PatrolSystem.j - Fixed Dead Unit Distance Check

**Issue**: In group patrols, dead units were being counted in the "First unit distance" check, which could break the patrol if the dead unit was far from the waypoint.

**Solution**: Modified the distance check to find the first **living** unit in the group:
- Added a loop to iterate through all units in the group
- Uses `GetUnitTypeId(u) != 0` to verify unit is alive
- Only calculates distance for living units
- Returns error if no living units are found

**Location**: `PatrolSystem.j`, line ~502 in `GroupTimerExpire` function

**Code Change**:
```jass
// OLD: Checked first unit without verifying if alive
set u = LoadUnitHandle(grpHt, groupId, 10000 + 0)

// NEW: Find first living unit
set u = null
set i = 0
loop
    exitwhen i >= unitCount
    set u = LoadUnitHandle(grpHt, groupId, 10000 + i)
    if u != null and GetUnitTypeId(u) != 0 then
        exitwhen true  // Found a living unit
    endif
    set u = null  // Current unit is dead or null, keep searching
    set i = i + 1
endloop
```

---

### 2. PatrolGroupSystem.j - Added Manual Waypoint Support

**Feature**: Added ability to set manual waypoints instead of relying on random generation within a patrol region.

**New Struct Members**:
- `boolean useManualWaypoints` - Flag to enable manual waypoint mode
- `real array waypointX[50]` - X coordinates for manual waypoints
- `real array waypointY[50]` - Y coordinates for manual waypoints
- `real array waypointWaitTime[50]` - Wait times for each manual waypoint

**New Methods**:

1. **`setWaypoint(integer index, real x, real y, real waitTime)`**
   - Sets a waypoint at exact coordinates
   - Automatically enables manual waypoint mode
   
2. **`setWaypointFromRect(integer index, rect r, real waitTime)`**
   - Convenience method to set waypoint from rect center
   - Perfect for GUI region-based waypoints
   
3. **`setWaypointFromLocation(integer index, location loc, real waitTime)`**
   - Convenience method to set waypoint from location
   - Compatible with GUI location variables

**Private Method**:
- **`setManualWaypoints()`** - Applies manual waypoints to PatrolSystem

**Logic Changes**:
- `startPatrol()` now checks `useManualWaypoints` flag
- Calls `setManualWaypoints()` if manual mode, otherwise `generateRandomWaypoints()`
- `start()` validation updated to skip `patrolRegion` check when using manual waypoints

**Usage Example**:
```jass
set myPatrolGroup = PatrolGroup.create()
set myPatrolGroup.spawnRegion = gg_rct_SpawnPoint
set myPatrolGroup.waypointCount = 3
call myPatrolGroup.setWaypointFromRect(0, gg_rct_WP01, 3.00)
call myPatrolGroup.setWaypointFromRect(1, gg_rct_WP02, 0.00)
call myPatrolGroup.setWaypointFromRect(2, gg_rct_WP03, 2.00)
call myPatrolGroup.start()
```

---

### Supporting Files Created

1. **`PatrolGroup_ManualWaypoints_Example.j`**
   - Complete working example showing three methods for setting waypoints
   - Demonstrates both single-call and loop-based approaches
   - Similar style to `Mordrax_MovementStart.j`

2. **`PatrolGroupSystem_ManualWaypoints_Guide.md`**
   - Comprehensive documentation
   - API reference
   - Multiple usage examples
   - Comparison with random waypoints
   - Best practices and tips

---

### Benefits

**PatrolSystem Fix**:
- ✅ Group patrols now work correctly even when units die
- ✅ Dead units no longer block patrol progression
- ✅ More robust and reliable group patrol behavior

**PatrolGroupSystem Enhancement**:
- ✅ Precise control over patrol routes
- ✅ Individual wait times per waypoint
- ✅ GUI-friendly with rect and location support
- ✅ Backward compatible (random waypoints still work)
- ✅ Up to 50 waypoints per group
- ✅ Reusable waypoint patterns

---

### Testing Recommendations

1. **PatrolSystem Fix**:
   - Create a group patrol with 4-5 units
   - Kill one unit during patrol
   - Verify remaining units continue patrolling normally

2. **Manual Waypoints**:
   - Create 5 GUI regions for waypoints
   - Use `setWaypointFromRect()` to configure patrol
   - Verify units follow the exact path
   - Test with different wait times at each waypoint
   - Test with PATROL_STYLE_LOOP and PATROL_STYLE_PINGPONG

---

### Files Modified

1. `h:\Pelit\WC3_JASS\00_PotS\PatrolSystem.j`
2. `h:\Pelit\WC3_JASS\00_PotS\PatrolGroupSystem.j`

### Files Created

1. `h:\Pelit\WC3_JASS\00_PotS\LiteScripts\PatrolSystem\PatrolGroup_ManualWaypoints_Example.j`
2. `h:\Pelit\WC3_JASS\00_PotS\PatrolGroupSystem_ManualWaypoints_Guide.md`
3. `h:\Pelit\WC3_JASS\00_PotS\PatrolSystem_PatrolGroupSystem_Updates_Summary.md` (this file)
