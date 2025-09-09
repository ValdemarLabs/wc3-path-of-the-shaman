function Trig_Mordrax_Movement_Start_Actions takes nothing returns nothing
    local integer i

    // ====================================
    // START PATROL
    // ====================================

    set udg_TempUnit = udg_BossMordrax

    set udg_PatrolSystem_Point[0]  = GetRectCenter(gg_rct_MordraxWP01)
    set udg_PatrolSystem_Wait[0]   = 15.00  // At Cave
    set udg_PatrolSystem_Point[1]  = GetRectCenter(gg_rct_MordraxWP02)
    set udg_PatrolSystem_Wait[1]   = 0.00
    set udg_PatrolSystem_Point[2]  = GetRectCenter(gg_rct_MordraxWP03)
    set udg_PatrolSystem_Wait[2]   = 0.00   
    set udg_PatrolSystem_Point[3]  = GetRectCenter(gg_rct_MordraxWP04)
    set udg_PatrolSystem_Wait[3]   = 0.00
    set udg_PatrolSystem_Point[4]  = GetRectCenter(gg_rct_MordraxWP05)
    set udg_PatrolSystem_Wait[4]   = 0.00
    set udg_PatrolSystem_Point[5]  = GetRectCenter(gg_rct_MordraxWP06)
    set udg_PatrolSystem_Wait[5]   = 0.00
    set udg_PatrolSystem_Point[6]  = GetRectCenter(gg_rct_MordraxWP07)
    set udg_PatrolSystem_Wait[6]   = 0.00
    set udg_PatrolSystem_Point[7]  = GetRectCenter(gg_rct_MordraxWP08)
    set udg_PatrolSystem_Wait[7]   = 0.00   
    set udg_PatrolSystem_Point[8]  = GetRectCenter(gg_rct_MordraxWP09)
    set udg_PatrolSystem_Wait[8]   = 0.00   
    set udg_PatrolSystem_Point[9]  = GetRectCenter(gg_rct_MordraxWP10)
    set udg_PatrolSystem_Wait[9]   = 0.00   
    set udg_PatrolSystem_Point[10]  = GetRectCenter(gg_rct_MordraxWP11)
    set udg_PatrolSystem_Wait[10]   = 0.00
    set udg_PatrolSystem_Point[11]  = GetRectCenter(gg_rct_MordraxWP12)
    set udg_PatrolSystem_Wait[11]   = 0.00
    set udg_PatrolSystem_Point[12]  = GetRectCenter(gg_rct_MordraxWP13)
    set udg_PatrolSystem_Wait[12]   = 0.00
    set udg_PatrolSystem_Point[13]  = GetRectCenter(gg_rct_MordraxWP14)
    set udg_PatrolSystem_Wait[13]   = 0.00
    set udg_PatrolSystem_Point[14]  = GetRectCenter(gg_rct_MordraxWP15)
    set udg_PatrolSystem_Wait[14]   = 0.00
    set udg_PatrolSystem_Point[15]  = GetRectCenter(gg_rct_MordraxWP16)
    set udg_PatrolSystem_Wait[15]   = 0.00
    set udg_PatrolSystem_Point[16]  = GetRectCenter(gg_rct_MordraxWP17)
    set udg_PatrolSystem_Wait[16]   = 0.00
    set udg_PatrolSystem_Point[17]  = GetRectCenter(gg_rct_MordraxWP18)
    set udg_PatrolSystem_Wait[17]   = 0.00
    set udg_PatrolSystem_Point[18]  = GetRectCenter(gg_rct_MordraxWP19)
    set udg_PatrolSystem_Wait[18]   = 0.00
    set udg_PatrolSystem_Point[19]  = GetRectCenter(gg_rct_MordraxWP20)
    set udg_PatrolSystem_Wait[19]   = 0.00
    set udg_PatrolSystem_Point[20]  = GetRectCenter(gg_rct_MordraxWP21)
    set udg_PatrolSystem_Wait[20]   = 0.00
    set udg_PatrolSystem_Point[21]  = GetRectCenter(gg_rct_MordraxWP22)
    set udg_PatrolSystem_Wait[21]   = 0.00
    set udg_PatrolSystem_Point[22]  = GetRectCenter(gg_rct_MordraxWP23)
    set udg_PatrolSystem_Wait[22]   = 0.00
    set udg_PatrolSystem_Point[23]  = GetRectCenter(gg_rct_MordraxWP24)
    set udg_PatrolSystem_Wait[23]   = 0.00
    set udg_PatrolSystem_Point[24]  = GetRectCenter(gg_rct_MordraxWP25)
    set udg_PatrolSystem_Wait[24]   = 0.00
    set udg_PatrolSystem_Point[25]  = GetRectCenter(gg_rct_MordraxWP26)
    set udg_PatrolSystem_Wait[25]   = 0.00

    // Call the patrol system
    call PatrolSystem_Start(udg_TempUnit, 26, 30.00, 0, true)

    // ====================================
    // Remove leaks
    // ====================================
    set i = 0
    loop
        exitwhen i > 85
        call RemoveLocation(udg_PatrolSystem_Point[i])
        set i = i + 1
    endloop

endfunction

//===========================================================================
function InitTrig_Mordrax_Movement_Start takes nothing returns nothing
    set gg_trg_Mordrax_Movement_Start = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle(gg_trg_Mordrax_Movement_Start, 7.00)
    call TriggerAddAction( gg_trg_Mordrax_Movement_Start, function Trig_Mordrax_Movement_Start_Actions )
endfunction
//===========================================================================

