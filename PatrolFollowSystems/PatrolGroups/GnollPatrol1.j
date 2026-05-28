library GnollPatrol1 initializer Init requires PatrolSystem

/*
    Author: [Valdemar]
*/

globals
    private PatrolGroup gnollPatrol1 = 0
endglobals

private function PatrolGroupStart takes nothing returns nothing
    call gnollPatrol1.start()
endfunction

private function Init takes nothing returns nothing
    local trigger startTrigger
    
    // Create patrol group
    set gnollPatrol1 = PatrolGroup.create()
    
    // Configuration
    set gnollPatrol1.owner = Player(11)                      // Player 2
    set gnollPatrol1.unitType = 'ngno'                      // Grunt
    set gnollPatrol1.unitCount = 4                          // Number of units
    set gnollPatrol1.respawnTime = 300.0                    // Respawn time
    set gnollPatrol1.waypointCount = 5                    // Waypoints
    set gnollPatrol1.patrolSpeed = 120.0                    // Slow patrol
    set gnollPatrol1.resetTime = 30.0                       // Combat reset time
    set gnollPatrol1.spawnRegion = gg_rct_GnollPatrol1Spawn // Spawn point
    set gnollPatrol1.pathStyle = PATROL_STYLE_PINGPONG     // Ping-pong
    set gnollPatrol1.moveOrder = "move"                     // Move order
    
    call gnollPatrol1.setWaypointFromRect(0, gg_rct_GnollPatrol1WP01, 5.00)  
    call gnollPatrol1.setWaypointFromRect(1, gg_rct_GnollPatrol1WP02, 5.00)  
    call gnollPatrol1.setWaypointFromRect(2, gg_rct_GnollPatrol1WP03, 5.00)
    call gnollPatrol1.setWaypointFromRect(3, gg_rct_GnollPatrol1WP04, 5.00)
    call gnollPatrol1.setWaypointFromRect(4, gg_rct_GnollPatrol1WP05, 5.00)

    // Auto-start after 5 seconds
    set startTrigger = CreateTrigger()
    call TriggerRegisterTimerEventSingle(startTrigger, 5.00)
    call TriggerAddAction(startTrigger, function PatrolGroupStart)
endfunction


endlibrary
