library PatrolGroupThornwoodsHordeManualWP initializer Init requires PatrolGroupSystem

/*
    Thornwoods Grunt Patrol Configuration (Manual Waypoints)
    Author: [Valdemar]
    
    Spawns 4 Grunts for Player 2 in Thornwoods region.
    Uses manually defined waypoints for precise patrol route.
    Automatically respawns after 120 seconds when all die.
    
    SETUP REQUIRED:
    Create the following regions in World Editor:
    - gg_rct_GruntPatrolSpawn (spawn location)
    - gg_rct_ThornwoodsWP01 through gg_rct_ThornwoodsWP05 (patrol waypoints)
*/

globals
    private PatrolGroup thornwoodsGrunts2 = 0
endglobals

private function StartThornwoodsPatrol takes nothing returns nothing
    call thornwoodsGrunts2.start()
endfunction

private function Init takes nothing returns nothing
    local trigger startTrigger
    
    // Create patrol group
    set thornwoodsGrunts2 = PatrolGroup.create()
    
    // Configuration
    set thornwoodsGrunts2.owner = Player(1)                      // Player 2
    set thornwoodsGrunts2.unitType = 'ogru'                      // Grunt
    set thornwoodsGrunts2.unitCount = 4                          // Number of units
    set thornwoodsGrunts2.respawnTime = 5.0                    // Respawn time
    set thornwoodsGrunts2.waypointCount = 8                      // Number of waypoints
    set thornwoodsGrunts2.patrolSpeed = 140.0                    // Slow patrol
    set thornwoodsGrunts2.resetTime = 15.0                       // Combat reset time
    set thornwoodsGrunts2.spawnRegion = gg_rct_TestWP01          // Spawn point
    set thornwoodsGrunts2.pathStyle = PATROL_STYLE_PINGPONG      // Ping-pong or loop
    set thornwoodsGrunts2.moveOrder = "attack"                     // Move order
    
    // NOTE: No patrolRegion needed when using manual waypoints
    
    // Set manual waypoints with individual wait times
    /*
    call thornwoodsGrunts.setWaypointFromRect(0, gg_rct_TestWP01, 3.00)  // Wait 3 seconds
    call thornwoodsGrunts.setWaypointFromRect(1, gg_rct_TestWP02, 0.00)  // No wait
    call thornwoodsGrunts.setWaypointFromRect(2, gg_rct_TestWP03, 5.00)  // Wait 5 seconds (lookout point)
    call thornwoodsGrunts.setWaypointFromRect(3, gg_rct_TestWWP04, 0.00)  // No wait
    call thornwoodsGrunts.setWaypointFromRect(4, gg_rct_TestWWP05, 2.00)  // Wait 2 seconds
    */
    call thornwoodsGrunts2.setWaypointFromRect(0, gg_rct_TestWP01, 0.00)  
    call thornwoodsGrunts2.setWaypointFromRect(1, gg_rct_TestWP02, 0.00)  
    call thornwoodsGrunts2.setWaypointFromRect(2, gg_rct_TestWP03, 0.00)  
    call thornwoodsGrunts2.setWaypointFromRect(3, gg_rct_TestWP04, 0.00)  
    call thornwoodsGrunts2.setWaypointFromRect(4, gg_rct_TestWP05, 0.00)
    call thornwoodsGrunts2.setWaypointFromRect(5, gg_rct_TestWP06, 0.00)
    call thornwoodsGrunts2.setWaypointFromRect(6, gg_rct_TestWP07, 0.00)
    call thornwoodsGrunts2.setWaypointFromRect(7, gg_rct_TestWP08, 0.00)
    
    // Auto-start after 5 seconds
    set startTrigger = CreateTrigger()
    call TriggerRegisterTimerEventSingle(startTrigger, 5.00)
    call TriggerAddAction(startTrigger, function StartThornwoodsPatrol)
endfunction

endlibrary
