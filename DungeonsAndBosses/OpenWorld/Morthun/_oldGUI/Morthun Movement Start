function Trig_Morthun_Movement_Start_Actions takes nothing returns nothing
    local integer i
    local integer patrolCount = 13

    // ====================================
    // START PATROL
    // ====================================

    set udg_TempUnit = udg_BossMorthun

    set udg_PatrolSystem_Point[0]  = GetRectCenter(gg_rct_MorthunWP02)
    set udg_PatrolSystem_Wait[0]   = 15.00  // by the lake
    set udg_PatrolSystem_Point[1]  = GetRectCenter(gg_rct_MorthunWP03)
    set udg_PatrolSystem_Wait[1]   = 0.00
    set udg_PatrolSystem_Point[2]  = GetRectCenter(gg_rct_MorthunWP04)
    set udg_PatrolSystem_Wait[2]   = 0.00
    set udg_PatrolSystem_Point[3]  = GetRectCenter(gg_rct_MorthunWP05)
    set udg_PatrolSystem_Wait[3]   = 0.00
    set udg_PatrolSystem_Point[4]  = GetRectCenter(gg_rct_MorthunWP06)
    set udg_PatrolSystem_Wait[4]   = 0.00
    set udg_PatrolSystem_Point[5]  = GetRectCenter(gg_rct_MorthunWP07)
    set udg_PatrolSystem_Wait[5]   = 0.00
    set udg_PatrolSystem_Point[6]  = GetRectCenter(gg_rct_MorthunWP08)
    set udg_PatrolSystem_Wait[6]   = 0.00
    set udg_PatrolSystem_Point[7]  = GetRectCenter(gg_rct_MorthunWP09)
    set udg_PatrolSystem_Wait[7]   = 0.00   
    set udg_PatrolSystem_Point[8]  = GetRectCenter(gg_rct_MorthunWP10)
    set udg_PatrolSystem_Wait[8]   = 0.00
    set udg_PatrolSystem_Point[9]  = GetRectCenter(gg_rct_MorthunWP11)
    set udg_PatrolSystem_Wait[9]   = 0.00
    set udg_PatrolSystem_Point[10] = GetRectCenter(gg_rct_MorthunWP12)
    set udg_PatrolSystem_Wait[10]  = 15.00 //
    set udg_PatrolSystem_Point[11] = GetRectCenter(gg_rct_MorthunWP13)
    set udg_PatrolSystem_Wait[11]  = 0.00
    set udg_PatrolSystem_Point[12] = GetRectCenter(gg_rct_MorthunWP14)
    set udg_PatrolSystem_Wait[12]  = 10.00  // by the mountain
  


    // Call the patrol system
    call PatrolSystem_Start(udg_TempUnit, patrolCount, 30.00, 1, true, "attack", 120.00)

    // ====================================
    // Remove leaks
    // ====================================
    set i = 0
    loop
        exitwhen i > patrolCount
        call RemoveLocation(udg_PatrolSystem_Point[i])
        set i = i + 1
    endloop

endfunction

//===========================================================================
function InitTrig_Morthun_Movement_Start takes nothing returns nothing
    set gg_trg_Morthun_Movement_Start = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle(gg_trg_Morthun_Movement_Start, 8.00)
    call TriggerAddAction( gg_trg_Morthun_Movement_Start, function Trig_Morthun_Movement_Start_Actions )
endfunction
//===========================================================================

