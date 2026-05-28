library PatrolGroupThornwoodsHorde initializer Init requires PatrolSystem

/*
    Thornwoods Grunt Patrol Configuration
    Author: [Valdemar]
    
    Spawns 4 Grunts for Player 2 in Thornwoods region.
    Automatically respawns after 120 seconds when all die.
*/

globals
    private PatrolGroup thornwoodsGrunts = 0
endglobals

private function StartThornwoodsPatrol takes nothing returns nothing
    call thornwoodsGrunts.start()
endfunction

private function Init takes nothing returns nothing
    local trigger startTrigger
    
    // Create patrol group
    set thornwoodsGrunts = PatrolGroup.create()
    
    // Configuration
    set thornwoodsGrunts.owner = Player(1)                      // Player 2
    set thornwoodsGrunts.unitType = 'ogru'                      // Grunt
    set thornwoodsGrunts.unitCount = 4                          // Number of units
    set thornwoodsGrunts.respawnTime = 5.0                    // Respawn time
    set thornwoodsGrunts.waypointCount = 5                     // Waypoints
    set thornwoodsGrunts.patrolSpeed = 140.0                    // Slow patrol
    set thornwoodsGrunts.waypointWait = 2.0                    // Wait at each point
    set thornwoodsGrunts.resetTime = 15.0                       // Combat reset time
    set thornwoodsGrunts.patrolRegion = gg_rct_06Thornwoods    // Patrol area
    set thornwoodsGrunts.spawnRegion = gg_rct_GruntPatrolSpawn // Spawn point
    set thornwoodsGrunts.pathStyle = PATROL_STYLE_PINGPONG     // Ping-pong
    set thornwoodsGrunts.moveOrder = "move"                     // Move order
    
    // Auto-start after 5 seconds
    set startTrigger = CreateTrigger()
    call TriggerRegisterTimerEventSingle(startTrigger, 5.00)
    call TriggerAddAction(startTrigger, function StartThornwoodsPatrol)
endfunction


endlibrary
