function Trig_TravelShipB_Movement_Start_Actions takes nothing returns nothing
    local integer i

    // ====================================
    // START PATROL
    // ====================================

    set udg_TravelShipB = gg_unit_odes_0061   // Replace with your ship’s rawcode & unit ID
    set udg_TempUnit = udg_TravelShipB

    set udg_PatrolSystem_Point[0]  = GetRectCenter(gg_rct_MoknathaShip01)
    set udg_PatrolSystem_Wait[0]   = 30.00  // At Moknatha

    set udg_PatrolSystem_Point[1]  = GetRectCenter(gg_rct_MoknathaShip02a)
    set udg_PatrolSystem_Wait[1]   = 0.00

    set udg_PatrolSystem_Point[2]  = GetRectCenter(gg_rct_MoknathaShip02)
    set udg_PatrolSystem_Wait[2]   = 0.00

    set udg_PatrolSystem_Point[3]  = GetRectCenter(gg_rct_MoknathaShip03)
    set udg_PatrolSystem_Wait[3]   = 0.00

    set udg_PatrolSystem_Point[4]  = GetRectCenter(gg_rct_MoknathaShip04)
    set udg_PatrolSystem_Wait[4]   = 0.00

    set udg_PatrolSystem_Point[5]  = GetRectCenter(gg_rct_MoknathaShip05)
    set udg_PatrolSystem_Wait[5]   = 0.00

    set udg_PatrolSystem_Point[6]  = GetRectCenter(gg_rct_MoknathaShip06)
    set udg_PatrolSystem_Wait[6]   = 0.00

    set udg_PatrolSystem_Point[7]  = GetRectCenter(gg_rct_MoknathaShip07)
    set udg_PatrolSystem_Wait[7]   = 0.00

    set udg_PatrolSystem_Point[8]  = GetRectCenter(gg_rct_MoknathaShip77)
    set udg_PatrolSystem_Wait[8]   = 0.00

    set udg_PatrolSystem_Point[9]  = GetRectCenter(gg_rct_MoknathaShip09)
    set udg_PatrolSystem_Wait[9]   = 0.00

    set udg_PatrolSystem_Point[10]  = GetRectCenter(gg_rct_MoknathaShip10)
    set udg_PatrolSystem_Wait[10]   = 0.00

    set udg_PatrolSystem_Point[11] = GetRectCenter(gg_rct_MoknathaShip11)
    set udg_PatrolSystem_Wait[11]  = 0.00

    set udg_PatrolSystem_Point[12] = GetRectCenter(gg_rct_MoknathaShip12)
    set udg_PatrolSystem_Wait[12]  = 0.00

    set udg_PatrolSystem_Point[13] = GetRectCenter(gg_rct_MoknathaShip13)
    set udg_PatrolSystem_Wait[13]  = 0.00

    set udg_PatrolSystem_Point[14] = GetRectCenter(gg_rct_MoknathaShip14)
    set udg_PatrolSystem_Wait[14]  = 0.00

    set udg_PatrolSystem_Point[15] = GetRectCenter(gg_rct_MoknathaShip15)
    set udg_PatrolSystem_Wait[15]  = 0.00

    set udg_PatrolSystem_Point[16] = GetRectCenter(gg_rct_MoknathaShip16)
    set udg_PatrolSystem_Wait[16]  = 0.00

    set udg_PatrolSystem_Point[17] = GetRectCenter(gg_rct_MoknathaShip17)
    set udg_PatrolSystem_Wait[17]  = 0.00

    set udg_PatrolSystem_Point[18] = GetRectCenter(gg_rct_MoknathaShip18)
    set udg_PatrolSystem_Wait[18]  = 0.00

    set udg_PatrolSystem_Point[19] = GetRectCenter(gg_rct_MoknathaShip19)
    set udg_PatrolSystem_Wait[19]  = 0.00

    set udg_PatrolSystem_Point[20] = GetRectCenter(gg_rct_MoknathaShip20)
    set udg_PatrolSystem_Wait[20]  = 0.00

    set udg_PatrolSystem_Point[21] = GetRectCenter(gg_rct_MoknathaShip21)
    set udg_PatrolSystem_Wait[21]  = 0.00

    set udg_PatrolSystem_Point[22] = GetRectCenter(gg_rct_MoknathaShip22)
    set udg_PatrolSystem_Wait[22]  = 0.00

    set udg_PatrolSystem_Point[23] = GetRectCenter(gg_rct_MoknathaShip23)
    set udg_PatrolSystem_Wait[23]  = 0.00

    set udg_PatrolSystem_Point[24] = GetRectCenter(gg_rct_MoknathaShip24)
    set udg_PatrolSystem_Wait[24]  = 30.00  // At Front Base

    // Regions names kind of messed up, but whatever

    set udg_PatrolSystem_Point[25] = GetRectCenter(gg_rct_MoknathaShip032)
    set udg_PatrolSystem_Wait[25]  = 0.00

    set udg_PatrolSystem_Point[26] = GetRectCenter(gg_rct_MoknathaShip033)
    set udg_PatrolSystem_Wait[26]  = 0.00

    set udg_PatrolSystem_Point[27] = GetRectCenter(gg_rct_MoknathaShip034)
    set udg_PatrolSystem_Wait[27]  = 0.00

    set udg_PatrolSystem_Point[28] = GetRectCenter(gg_rct_MoknathaShip035)
    set udg_PatrolSystem_Wait[28]  = 0.00

    set udg_PatrolSystem_Point[29] = GetRectCenter(gg_rct_MoknathaShip036)
    set udg_PatrolSystem_Wait[29]  = 0.00

    set udg_PatrolSystem_Point[30] = GetRectCenter(gg_rct_MoknathaShip037)
    set udg_PatrolSystem_Wait[30]  = 0.00

    set udg_PatrolSystem_Point[31] = GetRectCenter(gg_rct_MoknathaShip038)
    set udg_PatrolSystem_Wait[31]  = 0.00

    set udg_PatrolSystem_Point[32] = GetRectCenter(gg_rct_MoknathaShip039)
    set udg_PatrolSystem_Wait[32]  = 0.00

    set udg_PatrolSystem_Point[33] = GetRectCenter(gg_rct_MoknathaShip040)
    set udg_PatrolSystem_Wait[33]  = 0.00

    set udg_PatrolSystem_Point[34] = GetRectCenter(gg_rct_MoknathaShip041)
    set udg_PatrolSystem_Wait[34]  = 0.00

    set udg_PatrolSystem_Point[35] = GetRectCenter(gg_rct_MoknathaShip042)
    set udg_PatrolSystem_Wait[35]  = 0.00

    set udg_PatrolSystem_Point[36] = GetRectCenter(gg_rct_MoknathaShip043)
    set udg_PatrolSystem_Wait[36]  = 0.00

    set udg_PatrolSystem_Point[37] = GetRectCenter(gg_rct_MoknathaShip044)
    set udg_PatrolSystem_Wait[37]  = 0.00

    set udg_PatrolSystem_Point[38] = GetRectCenter(gg_rct_MoknathaShip045)
    set udg_PatrolSystem_Wait[38]  = 0.00

    set udg_PatrolSystem_Point[39] = GetRectCenter(gg_rct_MoknathaShip046)
    set udg_PatrolSystem_Wait[39]  = 0.00

    set udg_PatrolSystem_Point[40] = GetRectCenter(gg_rct_MoknathaShip047)
    set udg_PatrolSystem_Wait[40]  = 0.00

    set udg_PatrolSystem_Point[41] = GetRectCenter(gg_rct_MoknathaShip048)
    set udg_PatrolSystem_Wait[41]  = 30.00  // At Ironspine Post

    set udg_PatrolSystem_Point[42] = GetRectCenter(gg_rct_MoknathaShip045)
    set udg_PatrolSystem_Wait[42]  = 0.00

    set udg_PatrolSystem_Point[43] = GetRectCenter(gg_rct_MoknathaShip044)
    set udg_PatrolSystem_Wait[43]  = 0.00

    set udg_PatrolSystem_Point[44] = GetRectCenter(gg_rct_MoknathaShip043)
    set udg_PatrolSystem_Wait[44]  = 0.00

    set udg_PatrolSystem_Point[45] = GetRectCenter(gg_rct_MoknathaShip042)
    set udg_PatrolSystem_Wait[45]  = 0.00

    set udg_PatrolSystem_Point[46] = GetRectCenter(gg_rct_MoknathaShip041)
    set udg_PatrolSystem_Wait[46]  = 0.00

    set udg_PatrolSystem_Point[47] = GetRectCenter(gg_rct_MoknathaShip040)
    set udg_PatrolSystem_Wait[47]  = 0.00

    set udg_PatrolSystem_Point[48] = GetRectCenter(gg_rct_MoknathaShip039)
    set udg_PatrolSystem_Wait[48]  = 0.00

    set udg_PatrolSystem_Point[49] = GetRectCenter(gg_rct_MoknathaShip038)
    set udg_PatrolSystem_Wait[49]  = 0.00   

    set udg_PatrolSystem_Point[50] = GetRectCenter(gg_rct_MoknathaShip037)
    set udg_PatrolSystem_Wait[50]  = 0.00       

    set udg_PatrolSystem_Point[51] = GetRectCenter(gg_rct_MoknathaShip036)
    set udg_PatrolSystem_Wait[51]  = 0.00

    set udg_PatrolSystem_Point[52] = GetRectCenter(gg_rct_MoknathaShip035)
    set udg_PatrolSystem_Wait[52]  = 0.00

    set udg_PatrolSystem_Point[53] = GetRectCenter(gg_rct_MoknathaShip034)
    set udg_PatrolSystem_Wait[53]  = 0.00

    set udg_PatrolSystem_Point[54] = GetRectCenter(gg_rct_MoknathaShip033)
    set udg_PatrolSystem_Wait[54]  = 0.00   

    set udg_PatrolSystem_Point[55] = GetRectCenter(gg_rct_MoknathaShip032)
    set udg_PatrolSystem_Wait[55]  = 0.00   

    set udg_PatrolSystem_Point[56] = GetRectCenter(gg_rct_MoknathaShip031)              
    set udg_PatrolSystem_Wait[56]  = 0.00   

    set udg_PatrolSystem_Point[57] = GetRectCenter(gg_rct_MoknathaShip030)
    set udg_PatrolSystem_Wait[57]  = 30.00  

    set udg_PatrolSystem_Point[58] = GetRectCenter(gg_rct_MoknathaShip24)
    set udg_PatrolSystem_Wait[58]  = 30.00 // At Front Base

    set udg_PatrolSystem_Point[59] = GetRectCenter(gg_rct_MoknathaShip23)
    set udg_PatrolSystem_Wait[59]  = 0.00
    set udg_PatrolSystem_Point[60] = GetRectCenter(gg_rct_MoknathaShip22)
    set udg_PatrolSystem_Wait[60]  = 0.00
    set udg_PatrolSystem_Point[61] = GetRectCenter(gg_rct_MoknathaShip21)
    set udg_PatrolSystem_Wait[61]  = 0.00   
    set udg_PatrolSystem_Point[62] = GetRectCenter(gg_rct_MoknathaShip20)
    set udg_PatrolSystem_Wait[62]  = 0.00   
    set udg_PatrolSystem_Point[63] = GetRectCenter(gg_rct_MoknathaShip19)
    set udg_PatrolSystem_Wait[63]  = 0.00
    set udg_PatrolSystem_Point[64] = GetRectCenter(gg_rct_MoknathaShip18)       
    set udg_PatrolSystem_Wait[64]  = 0.00
    set udg_PatrolSystem_Point[65] = GetRectCenter(gg_rct_MoknathaShip17)
    set udg_PatrolSystem_Wait[65]  = 0.00       
    set udg_PatrolSystem_Point[66] = GetRectCenter(gg_rct_MoknathaShip16)
    set udg_PatrolSystem_Wait[66]  = 0.00           
    set udg_PatrolSystem_Point[67] = GetRectCenter(gg_rct_MoknathaShip15)
    set udg_PatrolSystem_Wait[67]  = 0.00   
    set udg_PatrolSystem_Point[68] = GetRectCenter(gg_rct_MoknathaShip14)
    set udg_PatrolSystem_Wait[68]  = 0.00   
    set udg_PatrolSystem_Point[69] = GetRectCenter(gg_rct_MoknathaShip13)
    set udg_PatrolSystem_Wait[69]  = 0.00   
    set udg_PatrolSystem_Point[70] = GetRectCenter(gg_rct_MoknathaShip12)
    set udg_PatrolSystem_Wait[70]  = 0.00
    set udg_PatrolSystem_Point[71] = GetRectCenter(gg_rct_MoknathaShip11)
    set udg_PatrolSystem_Wait[71]  = 0.00       
    set udg_PatrolSystem_Point[72] = GetRectCenter(gg_rct_MoknathaShip10)
    set udg_PatrolSystem_Wait[72]  = 0.00
    set udg_PatrolSystem_Point[73] = GetRectCenter(gg_rct_MoknathaShip09)   
    set udg_PatrolSystem_Wait[73]  = 0.00
    set udg_PatrolSystem_Point[74] = GetRectCenter(gg_rct_MoknathaShip77)   
    set udg_PatrolSystem_Wait[74]  = 0.00
    set udg_PatrolSystem_Point[75] = GetRectCenter(gg_rct_MoknathaShip07)
    set udg_PatrolSystem_Wait[75]  = 0.00           
    set udg_PatrolSystem_Point[76] = GetRectCenter(gg_rct_MoknathaShip08)   
    set udg_PatrolSystem_Wait[76]  = 0.00
    set udg_PatrolSystem_Point[77] = GetRectCenter(gg_rct_MoknathaShip06)
    set udg_PatrolSystem_Wait[77]  = 0.00
    set udg_PatrolSystem_Point[78] = GetRectCenter(gg_rct_MoknathaShip05)
    set udg_PatrolSystem_Wait[78]  = 0.00
    set udg_PatrolSystem_Point[79] = GetRectCenter(gg_rct_MoknathaShip04)
    set udg_PatrolSystem_Wait[79]  = 0.00
    set udg_PatrolSystem_Point[80] = GetRectCenter(gg_rct_MoknathaShip03)
    set udg_PatrolSystem_Wait[80]  = 0.00   
    set udg_PatrolSystem_Point[81] = GetRectCenter(gg_rct_MoknathaShip02)
    set udg_PatrolSystem_Wait[81]  = 0.00
    set udg_PatrolSystem_Point[82] = GetRectCenter(gg_rct_MoknathaShip025)
    set udg_PatrolSystem_Wait[82]  = 0.00
    set udg_PatrolSystem_Point[83] = GetRectCenter(gg_rct_MoknathaShip026)
    set udg_PatrolSystem_Wait[83]  = 0.00
    set udg_PatrolSystem_Point[84] = GetRectCenter(gg_rct_MoknathaShip027)
    set udg_PatrolSystem_Wait[84]  = 0.00   
    set udg_PatrolSystem_Point[85] = GetRectCenter(gg_rct_MoknathaShip028)
    set udg_PatrolSystem_Wait[85]  = 0.00   
    set udg_PatrolSystem_Point[86] = GetRectCenter(gg_rct_MoknathaShip029)
    set udg_PatrolSystem_Wait[86]  = 0.00

    // Call the patrol system
    call PatrolSystem_Start(udg_TempUnit, 87, 10.00, 0, true)

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
function InitTrig_TravelShipB_Movement_Start takes nothing returns nothing
    set gg_trg_TravelShipB_Movement_Start = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle(gg_trg_TravelShipB_Movement_Start, 15.00)
    call TriggerAddAction( gg_trg_TravelShipB_Movement_Start, function Trig_TravelShipB_Movement_Start_Actions )
endfunction
//===========================================================================

