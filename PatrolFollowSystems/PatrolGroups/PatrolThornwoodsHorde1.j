library PatrolThornwoodsHorde1 initializer Init requires PatrolSystem

/*
    Thornwoods Grunt Patrol Configuration
    Author: [Valdemar]
    
    Spawns 4 Grunts for Player 2 in Thornwoods region.
    Automatically respawns after 300 seconds when all die.
*/

globals
    private PatrolGroup thornwoodsHorde1 = 0
endglobals

private function PatrolGroupStart takes nothing returns nothing
    call thornwoodsHorde1.start()
endfunction

private function Init takes nothing returns nothing
    local trigger startTrigger
    
    // Create patrol group
    set thornwoodsHorde1 = PatrolGroup.create()
    
    // Configuration
    set thornwoodsHorde1.owner = Player(1)                      // Player 2
    set thornwoodsHorde1.unitType = 'ogru'                      // Grunt
    set thornwoodsHorde1.unitCount = 4                          // Number of units
    set thornwoodsHorde1.respawnTime = 300.0                    // Respawn time
    set thornwoodsHorde1.waypointCount = 20                     // Waypoints
    set thornwoodsHorde1.patrolSpeed = 120.0                    // Slow patrol
    set thornwoodsHorde1.waypointWait = 15.0                    // Wait at each point
    set thornwoodsHorde1.resetTime = 30.0                       // Combat reset time
    set thornwoodsHorde1.patrolRegion = gg_rct_06Thornwoods    // Patrol area
    set thornwoodsHorde1.spawnRegion = gg_rct_GruntPatrolSpawn // Spawn point
    set thornwoodsHorde1.pathStyle = PATROL_STYLE_PINGPONG     // Ping-pong
    set thornwoodsHorde1.moveOrder = "move"                     // Move order
    
    // Auto-start after 5 seconds
    set startTrigger = CreateTrigger()
    call TriggerRegisterTimerEventSingle(startTrigger, 5.00)
    call TriggerAddAction(startTrigger, function PatrolGroupStart)
endfunction


endlibrary
