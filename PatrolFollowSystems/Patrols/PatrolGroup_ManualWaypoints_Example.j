//===========================================================================
// PatrolGroup Manual Waypoints Example
//===========================================================================
// This example demonstrates how to create a patrol group with manually
// set waypoints instead of randomly generated ones within a region.
//
// This is useful when you want precise control over the patrol path,
// such as creating specific routes through a town or along a road.
//===========================================================================

globals
    private PatrolGroup ManualPatrolGroup
endglobals

function InitManualPatrolGroup takes nothing returns nothing
    local integer i
    
    call BJDebugMsg("[ManualPatrolExample] Initializing patrol group with manual waypoints")
    
    // Create the patrol group
    set ManualPatrolGroup = PatrolGroup.create()
    
    // Configure basic settings
    set ManualPatrolGroup.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    set ManualPatrolGroup.unitType = 'noga'  // Ogre
    set ManualPatrolGroup.unitCount = 4
    set ManualPatrolGroup.respawnTime = 120.0
    set ManualPatrolGroup.patrolSpeed = 250.0
    set ManualPatrolGroup.resetTime = 15.0
    set ManualPatrolGroup.pathStyle = PATROL_STYLE_PINGPONG
    set ManualPatrolGroup.moveOrder = "move"
    
    // IMPORTANT: Set the spawn region (where units spawn)
    set ManualPatrolGroup.spawnRegion = gg_rct_ManualPatrolSpawn
    
    // Set the number of waypoints
    set ManualPatrolGroup.waypointCount = 5
    
    // Set manual waypoints using rect centers
    // Method 1: Using setWaypointFromRect (easiest for GUI regions)
    call ManualPatrolGroup.setWaypointFromRect(0, gg_rct_ManualWP01, 3.00)  // Wait 3 seconds
    call ManualPatrolGroup.setWaypointFromRect(1, gg_rct_ManualWP02, 0.00)  // No wait
    call ManualPatrolGroup.setWaypointFromRect(2, gg_rct_ManualWP03, 5.00)  // Wait 5 seconds
    call ManualPatrolGroup.setWaypointFromRect(3, gg_rct_ManualWP04, 0.00)  // No wait
    call ManualPatrolGroup.setWaypointFromRect(4, gg_rct_ManualWP05, 2.00)  // Wait 2 seconds
    
    // Method 2: Using setWaypoint with coordinates (if you know exact coords)
    // call ManualPatrolGroup.setWaypoint(0, -2304.0, 1536.0, 3.00)
    // call ManualPatrolGroup.setWaypoint(1, -1792.0, 2048.0, 0.00)
    // etc...
    
    // Method 3: Using setWaypointFromLocation (if using udg_PatrolSystem_Point from GUI)
    // set udg_PatrolSystem_Point[0] = GetRectCenter(gg_rct_ManualWP01)
    // call ManualPatrolGroup.setWaypointFromLocation(0, udg_PatrolSystem_Point[0], 3.00)
    // call RemoveLocation(udg_PatrolSystem_Point[0])  // Clean up location
    
    // Start the patrol
    call ManualPatrolGroup.start()
    
    call BJDebugMsg("[ManualPatrolExample] Patrol group started with manual waypoints")
endfunction

//===========================================================================
// Alternative example: Using a loop with global arrays (like Mordrax style)
//===========================================================================
function InitManualPatrolGroup_LoopStyle takes nothing returns nothing
    local integer i
    local integer waypointCount = 5
    
    // Create array of rects (you can also use a global array)
    local rect array waypoints
    local real array waitTimes
    
    call BJDebugMsg("[ManualPatrolExample] Initializing with loop style")
    
    // Setup waypoint data
    set waypoints[0] = gg_rct_ManualWP01
    set waitTimes[0] = 3.00
    set waypoints[1] = gg_rct_ManualWP02
    set waitTimes[1] = 0.00
    set waypoints[2] = gg_rct_ManualWP03
    set waitTimes[2] = 5.00
    set waypoints[3] = gg_rct_ManualWP04
    set waitTimes[3] = 0.00
    set waypoints[4] = gg_rct_ManualWP05
    set waitTimes[4] = 2.00
    
    // Create and configure patrol group
    set ManualPatrolGroup = PatrolGroup.create()
    set ManualPatrolGroup.owner = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    set ManualPatrolGroup.unitType = 'noga'
    set ManualPatrolGroup.unitCount = 4
    set ManualPatrolGroup.respawnTime = 120.0
    set ManualPatrolGroup.patrolSpeed = 250.0
    set ManualPatrolGroup.resetTime = 15.0
    set ManualPatrolGroup.pathStyle = PATROL_STYLE_PINGPONG
    set ManualPatrolGroup.moveOrder = "move"
    set ManualPatrolGroup.spawnRegion = gg_rct_ManualPatrolSpawn
    set ManualPatrolGroup.waypointCount = waypointCount
    
    // Set all waypoints in a loop
    set i = 0
    loop
        exitwhen i >= waypointCount
        call ManualPatrolGroup.setWaypointFromRect(i, waypoints[i], waitTimes[i])
        set i = i + 1
    endloop
    
    // Start the patrol
    call ManualPatrolGroup.start()
    
    call BJDebugMsg("[ManualPatrolExample] Loop-style patrol group started")
endfunction

//===========================================================================
// Initialization
//===========================================================================
function InitTrig_PatrolGroup_ManualWaypoints_Example takes nothing returns nothing
    // Call this during map initialization (after a small delay to ensure regions exist)
    call TimerStart(CreateTimer(), 2.0, false, function InitManualPatrolGroup)
    
    // Or use the loop style:
    // call TimerStart(CreateTimer(), 2.0, false, function InitManualPatrolGroup_LoopStyle)
endfunction
