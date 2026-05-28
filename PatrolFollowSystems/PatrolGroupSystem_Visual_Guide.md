# PatrolGroupSystem: Random vs Manual Waypoints

## Visual Comparison

### Random Waypoints Mode (Original)
```
┌─────────────────────────────────────┐
│   Patrol Region (Rectangle)         │
│                                      │
│    ●5        ●3                      │
│                                      │
│         ●2                           │
│                 ●4        ●1         │
│                                      │
└─────────────────────────────────────┘

Waypoints are randomly generated within
the patrol region bounds. Each run produces
different patrol paths.

Configuration:
  set pg.patrolRegion = gg_rct_PatrolArea
  set pg.waypointCount = 5
  call pg.start()
```

### Manual Waypoints Mode (New)
```
  Town Guard Patrol Route:
  
  [Guard Post]  ────①───→  [Town Square]
       ↑                         │
       │                         ②
       │                         ↓
   [Barracks]  ←───④───  [Town Gate]
       ↑                         │
       │                         ③
       └─────────────────────────┘

Waypoints follow a specific path.
Each waypoint can have custom wait times.

Configuration:
  call pg.setWaypointFromRect(0, gg_rct_TownSquare, 5.0)
  call pg.setWaypointFromRect(1, gg_rct_TownGate, 3.0)
  call pg.setWaypointFromRect(2, gg_rct_Barracks, 2.0)
  call pg.setWaypointFromRect(3, gg_rct_GuardPost, 5.0)
  call pg.start()
```

## Use Case Examples

### When to Use Random Waypoints
✅ Wildlife/creature patrols in forests
✅ Random mob movements in dungeons
✅ Generic area patrols
✅ Quick prototyping
✅ When exact path doesn't matter

Example: Forest wolves patrolling randomly
```jass
set wolfPatrol = PatrolGroup.create()
set wolfPatrol.patrolRegion = gg_rct_Forest
set wolfPatrol.unitType = 'nwlt'  // Wolf
set wolfPatrol.waypointCount = 8
call wolfPatrol.start()
```

### When to Use Manual Waypoints
✅ Town guard patrols on streets
✅ Road/path patrols
✅ Boss patrol routes (like Mordrax)
✅ Scripted/cinematic patrols
✅ Multiple groups with same route

Example: Town guards patrolling streets
```jass
set guardPatrol = PatrolGroup.create()
set guardPatrol.unitType = 'hfoo'  // Footman
set guardPatrol.waypointCount = 6
call guardPatrol.setWaypointFromRect(0, gg_rct_Street01, 0.0)
call guardPatrol.setWaypointFromRect(1, gg_rct_Street02, 0.0)
call guardPatrol.setWaypointFromRect(2, gg_rct_TownSquare, 10.0)  // Wait 10s
call guardPatrol.setWaypointFromRect(3, gg_rct_Street03, 0.0)
call guardPatrol.setWaypointFromRect(4, gg_rct_Street04, 0.0)
call guardPatrol.setWaypointFromRect(5, gg_rct_Barracks, 5.0)  // Wait 5s
call guardPatrol.start()
```

## Migration from Single Unit Patrol (Mordrax Style)

### Old Single Unit Method
```jass
set udg_PatrolSystem_Point[0] = GetRectCenter(gg_rct_WP01)
set udg_PatrolSystem_Wait[0] = 3.00
set udg_PatrolSystem_Point[1] = GetRectCenter(gg_rct_WP02)
set udg_PatrolSystem_Wait[1] = 0.00
// ... repeat for all waypoints
call PatrolSystem_Start(udg_BossUnit, 10, 30.00, 0, true, "move", 120.00)
```

### New Group Patrol Method
```jass
set bossPatrol = PatrolGroup.create()
set bossPatrol.unitCount = 1  // Single unit
set bossPatrol.unitType = 'Nbos'
set bossPatrol.spawnRegion = gg_rct_BossSpawn
set bossPatrol.waypointCount = 10
call bossPatrol.setWaypointFromRect(0, gg_rct_WP01, 3.00)
call bossPatrol.setWaypointFromRect(1, gg_rct_WP02, 0.00)
// ... repeat for all waypoints
call bossPatrol.start()
```

## Path Styles

### PATROL_STYLE_LOOP (0)
```
Start → ① → ② → ③ → ④ → ⑤ → ① → ② → ...
```
Goes in a circle, returning to start after last waypoint.

### PATROL_STYLE_PINGPONG (1)
```
Start → ① → ② → ③ → ④ → ⑤ → ④ → ③ → ② → ① → ② → ...
```
Bounces back and forth through waypoints.

## Feature Comparison Table

| Feature                    | Random Waypoints | Manual Waypoints |
|---------------------------|------------------|------------------|
| Patrol Region Required    | ✅ Yes           | ❌ No            |
| Spawn Region Required     | ✅ Yes           | ✅ Yes           |
| Precise Routes            | ❌ No            | ✅ Yes           |
| Individual Wait Times     | ❌ No            | ✅ Yes           |
| Setup Complexity          | Low              | Medium           |
| Reusable Patterns         | ❌ No            | ✅ Yes           |
| GUI Region Support        | Basic            | Full             |
| Max Waypoints             | Unlimited        | 50               |

## Quick Reference

### Random Waypoint Setup (3 steps)
```jass
set pg = PatrolGroup.create()
set pg.patrolRegion = gg_rct_Area        // Step 1: Define area
set pg.waypointCount = 5                  // Step 2: Set count
call pg.start()                           // Step 3: Start
```

### Manual Waypoint Setup (3+ steps)
```jass
set pg = PatrolGroup.create()
set pg.waypointCount = 3                  // Step 1: Set count
call pg.setWaypointFromRect(0, gg_rct_WP01, 2.0)  // Step 2a: Set WP1
call pg.setWaypointFromRect(1, gg_rct_WP02, 0.0)  // Step 2b: Set WP2
call pg.setWaypointFromRect(2, gg_rct_WP03, 3.0)  // Step 2c: Set WP3
call pg.start()                           // Step 3: Start
```
