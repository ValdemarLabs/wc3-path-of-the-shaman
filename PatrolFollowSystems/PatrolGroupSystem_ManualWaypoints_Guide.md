# PatrolGroupSystem Manual Waypoints Guide

## Overview

The PatrolGroupSystem now supports two modes for waypoint configuration:

1. **Random Waypoints** (default): Waypoints are randomly generated within a patrol region
2. **Manual Waypoints** (new): Waypoints are manually set at specific coordinates

## When to Use Manual Waypoints

Use manual waypoints when you need:
- Precise patrol paths (e.g., town guards following streets)
- Specific routes between landmarks
- Patrols that follow a logical path (e.g., road patrols)
- Multiple patrol groups sharing the same waypoint pattern

## How to Set Manual Waypoints

### Method 1: Using Rect Centers (Recommended for GUI)

```jass
set myPatrolGroup = PatrolGroup.create()

// Configure basic settings
set myPatrolGroup.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
set myPatrolGroup.unitType = 'hfoo'
set myPatrolGroup.unitCount = 4
set myPatrolGroup.spawnRegion = gg_rct_SpawnPoint
set myPatrolGroup.waypointCount = 5

// Set waypoints from GUI regions
call myPatrolGroup.setWaypointFromRect(0, gg_rct_WP01, 3.00)  // Wait 3 seconds
call myPatrolGroup.setWaypointFromRect(1, gg_rct_WP02, 0.00)  // No wait
call myPatrolGroup.setWaypointFromRect(2, gg_rct_WP03, 5.00)  // Wait 5 seconds
call myPatrolGroup.setWaypointFromRect(3, gg_rct_WP04, 0.00)  // No wait
call myPatrolGroup.setWaypointFromRect(4, gg_rct_WP05, 2.00)  // Wait 2 seconds

// Start the patrol
call myPatrolGroup.start()
```

### Method 2: Using Exact Coordinates

```jass
set myPatrolGroup = PatrolGroup.create()

// Configure basic settings
set myPatrolGroup.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
set myPatrolGroup.unitType = 'hfoo'
set myPatrolGroup.unitCount = 4
set myPatrolGroup.spawnRegion = gg_rct_SpawnPoint
set myPatrolGroup.waypointCount = 3

// Set waypoints with exact coordinates
call myPatrolGroup.setWaypoint(0, -2304.0, 1536.0, 3.00)
call myPatrolGroup.setWaypoint(1, -1792.0, 2048.0, 0.00)
call myPatrolGroup.setWaypoint(2, -1280.0, 1536.0, 2.00)

// Start the patrol
call myPatrolGroup.start()
```

### Method 3: Using Locations (Compatible with GUI Variables)

```jass
set myPatrolGroup = PatrolGroup.create()

// Configure basic settings
set myPatrolGroup.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
set myPatrolGroup.unitType = 'hfoo'
set myPatrolGroup.unitCount = 4
set myPatrolGroup.spawnRegion = gg_rct_SpawnPoint
set myPatrolGroup.waypointCount = 3

// Set waypoints from GUI location variables
set udg_TempPoint = GetRectCenter(gg_rct_WP01)
call myPatrolGroup.setWaypointFromLocation(0, udg_TempPoint, 3.00)
call RemoveLocation(udg_TempPoint)

set udg_TempPoint = GetRectCenter(gg_rct_WP02)
call myPatrolGroup.setWaypointFromLocation(1, udg_TempPoint, 0.00)
call RemoveLocation(udg_TempPoint)

// Start the patrol
call myPatrolGroup.start()
```

## Important Notes

1. **Waypoint Index**: Waypoints must be set sequentially starting from index 0
2. **Waypoint Count**: Set `waypointCount` to match the number of waypoints you configure
3. **Wait Time**: The third parameter is the wait time in seconds at that waypoint (0.00 = no wait)
4. **No Patrol Region Needed**: When using manual waypoints, you don't need to set `patrolRegion`
5. **Spawn Region Required**: You must always set `spawnRegion` (where units initially spawn)
6. **Maximum Waypoints**: Up to 50 waypoints can be set per patrol group

## Comparison with Random Waypoints

### Random Waypoints
```jass
set myPatrolGroup = PatrolGroup.create()
set myPatrolGroup.patrolRegion = gg_rct_PatrolArea  // Required
set myPatrolGroup.spawnRegion = gg_rct_SpawnPoint
set myPatrolGroup.waypointCount = 5
set myPatrolGroup.waypointWait = 2.00  // All waypoints use same wait time
call myPatrolGroup.start()
```

### Manual Waypoints
```jass
set myPatrolGroup = PatrolGroup.create()
set myPatrolGroup.spawnRegion = gg_rct_SpawnPoint
set myPatrolGroup.waypointCount = 5
// Set each waypoint individually with custom wait times
call myPatrolGroup.setWaypointFromRect(0, gg_rct_WP01, 3.00)
call myPatrolGroup.setWaypointFromRect(1, gg_rct_WP02, 0.00)
call myPatrolGroup.setWaypointFromRect(2, gg_rct_WP03, 5.00)
call myPatrolGroup.setWaypointFromRect(3, gg_rct_WP04, 1.00)
call myPatrolGroup.setWaypointFromRect(4, gg_rct_WP05, 2.00)
call myPatrolGroup.start()
```

## Complete Example

See `PatrolGroup_ManualWaypoints_Example.j` for full working examples including:
- Basic manual waypoint setup
- Loop-based setup (Mordrax style)
- Different methods for setting waypoints

## API Reference

### `setWaypoint(integer index, real x, real y, real waitTime)`
Sets a waypoint at the given index with exact coordinates.
- **index**: Waypoint index (0 to 49)
- **x**: X coordinate
- **y**: Y coordinate
- **waitTime**: How long to wait at this waypoint (seconds)

### `setWaypointFromRect(integer index, rect r, real waitTime)`
Sets a waypoint at the center of a rect (GUI region).
- **index**: Waypoint index (0 to 49)
- **r**: The rect to use (e.g., gg_rct_Waypoint01)
- **waitTime**: How long to wait at this waypoint (seconds)

### `setWaypointFromLocation(integer index, location loc, real waitTime)`
Sets a waypoint from a location variable.
- **index**: Waypoint index (0 to 49)
- **loc**: The location to use
- **waitTime**: How long to wait at this waypoint (seconds)
- **Note**: Remember to call `RemoveLocation()` after to prevent leaks

## Benefits

1. **Precise Control**: Define exact patrol routes
2. **Individual Wait Times**: Each waypoint can have different wait durations
3. **Reusable Patterns**: Share waypoint configurations across multiple patrol groups
4. **GUI Friendly**: Easy to use with GUI regions and variables
5. **Backward Compatible**: Existing random waypoint code continues to work
