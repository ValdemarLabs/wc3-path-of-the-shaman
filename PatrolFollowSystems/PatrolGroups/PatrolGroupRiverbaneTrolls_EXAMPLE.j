library PatrolGroupRiverbaneTrolls initializer Init requires PatrolGroupSystem

/*
    Riverbane Troll Patrol Configuration
    Author: [Valdemar]
    
    Example: Spawns 6 Troll Headhunters for Player 14 in Riverbane region.
    Automatically respawns after 90 seconds when all die.
*/

globals
    private PatrolGroup riverbaneTrolls = 0
endglobals

private function Init takes nothing returns nothing
    local trigger startTrigger
    
    // Create patrol group
    set riverbaneTrolls = PatrolGroup.create()
    
    // Configuration
    set riverbaneTrolls.owner = Player(13)                        // Player 14
    set riverbaneTrolls.unitType = 'ohun'                          // Troll Headhunter
    set riverbaneTrolls.unitCount = 6                              // 6 units
    set riverbaneTrolls.respawnTime = 90.0                         // 90 seconds
    set riverbaneTrolls.waypointCount = 8                          // 8 waypoints
    set riverbaneTrolls.patrolSpeed = 200.0                        // Medium speed
    set riverbaneTrolls.waypointWait = 3.0                         // Wait 3s at each point
    set riverbaneTrolls.resetTime = 10.0                           // 10s combat reset
    set riverbaneTrolls.patrolRegion = gg_rct_RiverbanePatrolArea // Patrol area
    set riverbaneTrolls.spawnRegion = gg_rct_RiverbaneSpawn       // Spawn point
    set riverbaneTrolls.pathStyle = PATROL_STYLE_LOOP             // Loop
    set riverbaneTrolls.moveOrder = "attack"                       // Attack-move
    
    // Auto-start after 5 seconds
    set startTrigger = CreateTrigger()
    call TriggerRegisterTimerEventSingle(startTrigger, 5.00)
    call TriggerAddAction(startTrigger, function start)
endfunction

private function start takes nothing returns nothing
    call riverbaneTrolls.start()
endfunction

endlibrary
