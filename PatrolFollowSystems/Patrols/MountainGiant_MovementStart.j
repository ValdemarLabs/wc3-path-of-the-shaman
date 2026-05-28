function Trig_MountainGiant_Movement_Start_Actions takes nothing returns nothing
    local integer i
    local integer patrolCount = 17

    // ====================================
    // START PATROL
    // ====================================

    set udg_TempUnit = udg_BossMountainGiant

    set udg_PatrolSystem_Point[0]  = GetRectCenter(gg_rct_MountainGiantWP01)
    set udg_PatrolSystem_Wait[0]   = 00.00  
    set udg_PatrolSystem_Point[1]  = GetRectCenter(gg_rct_MountainGiantWP02)
    set udg_PatrolSystem_Wait[1]   = 0.00
    set udg_PatrolSystem_Point[2]  = GetRectCenter(gg_rct_MountainGiantWP03)
    set udg_PatrolSystem_Wait[2]   = 0.00
    set udg_PatrolSystem_Point[3]  = GetRectCenter(gg_rct_MountainGiantWP04)
    set udg_PatrolSystem_Wait[3]   = 0.00
    set udg_PatrolSystem_Point[4]  = GetRectCenter(gg_rct_MountainGiantWP05)
    set udg_PatrolSystem_Wait[4]   = 0.00
    set udg_PatrolSystem_Point[5]  = GetRectCenter(gg_rct_MountainGiantWP06)
    set udg_PatrolSystem_Wait[5]   = 0.00
    set udg_PatrolSystem_Point[6]  = GetRectCenter(gg_rct_MountainGiantWP07)
    set udg_PatrolSystem_Wait[6]   = 0.00
    set udg_PatrolSystem_Point[7]  = GetRectCenter(gg_rct_MountainGiantWP08)
    set udg_PatrolSystem_Wait[7]   = 0.00
    set udg_PatrolSystem_Point[8]  = GetRectCenter(gg_rct_MountainGiantWP09)
    set udg_PatrolSystem_Wait[8]   = 15.00
    set udg_PatrolSystem_Point[9]  = GetRectCenter(gg_rct_MountainGiantWP10)
    set udg_PatrolSystem_Wait[9]   = 0.00
    set udg_PatrolSystem_Point[10]  = GetRectCenter(gg_rct_MountainGiantWP11)
    set udg_PatrolSystem_Wait[10]   = 0.00
    set udg_PatrolSystem_Point[11]  = GetRectCenter(gg_rct_MountainGiantWP12)
    set udg_PatrolSystem_Wait[11]   = 0.00
    set udg_PatrolSystem_Point[12]  = GetRectCenter(gg_rct_MountainGiantWP06)
    set udg_PatrolSystem_Wait[12]   = 0.00
    set udg_PatrolSystem_Point[13]  = GetRectCenter(gg_rct_MountainGiantWP05)
    set udg_PatrolSystem_Wait[13]   = 0.00
    set udg_PatrolSystem_Point[14]  = GetRectCenter(gg_rct_MountainGiantWP04)
    set udg_PatrolSystem_Wait[14]   = 0.00
    set udg_PatrolSystem_Point[15]  = GetRectCenter(gg_rct_MountainGiantWP03)
    set udg_PatrolSystem_Wait[15]   = 0.00
    set udg_PatrolSystem_Point[16]  = GetRectCenter(gg_rct_MountainGiantWP02)
    set udg_PatrolSystem_Wait[16]   = 0.00


    // Call the patrol system
    call PatrolSystem_Start(udg_TempUnit, patrolCount, 30.00, 0, true, "attack", 120.00)

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
function InitTrig_MountainGiant_Movement_Start takes nothing returns nothing
    set gg_trg_MountainGiant_Movement_Start = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle(gg_trg_MountainGiant_Movement_Start, 7.00)
    call TriggerAddAction( gg_trg_MountainGiant_Movement_Start, function Trig_MountainGiant_Movement_Start_Actions )
endfunction
//===========================================================================

