//===========================================================================
// GUI Trigger Example for Player 2 Grunt Patrol
//===========================================================================
// This is an example trigger you can create in GUI and convert to custom text
// 
// Event: Map initialization
// OR
// Event: Time - Elapsed game time is 5.00 seconds
//
// Actions:
//   Custom script: call StartPlayer2GruntPatrol(gg_rct_GruntPatrolArea, gg_rct_GruntSpawn)
//
//===========================================================================

function Trig_Start_Grunt_Patrol_Actions takes nothing returns nothing
    // Replace these with your actual region variables:
    // - gg_rct_GruntPatrolArea = The region where grunts will patrol
    // - gg_rct_GruntSpawn = The region where grunts will spawn
    
    call StartPlayer2GruntPatrol(gg_rct_GruntPatrolArea, gg_rct_GruntSpawn)
endfunction

//===========================================================================
function InitTrig_Start_Grunt_Patrol takes nothing returns nothing
    set gg_trg_Start_Grunt_Patrol = CreateTrigger()
    call TriggerRegisterTimerEventSingle(gg_trg_Start_Grunt_Patrol, 5.00)
    call TriggerAddAction(gg_trg_Start_Grunt_Patrol, function Trig_Start_Grunt_Patrol_Actions)
endfunction

//===========================================================================
// Optional: Trigger to stop the patrol system
//===========================================================================
function Trig_Stop_Grunt_Patrol_Actions takes nothing returns nothing
    call StopPlayer2GruntPatrol()
endfunction

//===========================================================================
function InitTrig_Stop_Grunt_Patrol takes nothing returns nothing
    set gg_trg_Stop_Grunt_Patrol = CreateTrigger()
    // Example: Stop when a unit enters a region
    call TriggerRegisterEnterRectSimple(gg_trg_Stop_Grunt_Patrol, gg_rct_StopPatrolZone)
    call TriggerAddAction(gg_trg_Stop_Grunt_Patrol, function Trig_Stop_Grunt_Patrol_Actions)
endfunction

//===========================================================================
// Optional: Trigger to restart patrol with new random waypoints
//===========================================================================
function Trig_Restart_Grunt_Patrol_Actions takes nothing returns nothing
    call RestartPlayer2GruntPatrol()
endfunction

//===========================================================================
function InitTrig_Restart_Grunt_Patrol takes nothing returns nothing
    set gg_trg_Restart_Grunt_Patrol = CreateTrigger()
    // Example: Restart every 5 minutes to randomize patrol path
    call TriggerRegisterTimerEventPeriodic(gg_trg_Restart_Grunt_Patrol, 300.00)
    call TriggerAddAction(gg_trg_Restart_Grunt_Patrol, function Trig_Restart_Grunt_Patrol_Actions)
endfunction
