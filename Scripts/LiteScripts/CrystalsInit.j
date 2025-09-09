/*===========================================================================
    Crystals
//===========================================================================
        -------- == ZONES == --------
        -------- 1. Twilight Grove - Levels 3-8 --------
        -------- 2. Sereneglade - Levels 1-9 --------
        -------- 3. Emberpeak Highlands - Levels 10-15 --------
        -------- 4. Dragonfire Peaks - Levels 20-30 --------
        -------- 5. Wyrmhold Sanctum - Levels 20-30 --------
        -------- 6. Thornwoods - Levels 1-10 --------
        -------- 7. Havenwoods - Levels 5-10 --------
        -------- 8. Bonecrush Stronghold - Levels 10-12 --------
        -------- 9. Vanguard Vale - Levels 8-12 --------
        -------- 10. Riverbane - Levels 8-12 --------
        -------- 11. Deadwoods - Levels 8-12 --------
        -------- 12. Felfire Bastion - Levels 12-15 (Stronghold 25-30) --------
        -------- 13. Stormhaven - Levels 12-18 --------
        -------- 14. Sirensong - Levels 10-15 --------
        -------- 15. Zul’Gurak - Levels 15-20 --------
        -------- 16. Firelands - Levels 20-30 --------
        -------- 17. Verdant Plains - Levels 15-20 --------
        -------- 18. Coliseum of Ages - Levels XXX --------
        -------- 19. Ghostwalk Ridge - Levels 5-10 --------

//===========================================================================
*/
//===========================================================================

function Trig_Crystals_Init_Actions takes nothing returns nothing
    // Define regions for spawning ores
// -------- Red Crystals --------
    set udg_CrystalRedRegions[1] = gg_rct_CrystalsRed0001
    set udg_CrystalRedRegions[2] = gg_rct_CrystalsRed0002
    set udg_CrystalRedRegions[3] = gg_rct_CrystalsRed0003
    set udg_CrystalRedRegions[4] = gg_rct_CrystalsRed0004
    set udg_CrystalRedRegions[5] = gg_rct_CrystalsRed0005
    set udg_CrystalRedRegions[6] = gg_rct_CrystalsRed0006
    set udg_CrystalRedRegions[7] = gg_rct_CrystalsRed0007
    set udg_CrystalRedRegions[8] = gg_rct_CrystalsRed0008
    set udg_CrystalRedRegions[9] = gg_rct_CrystalsRed0009
    set udg_CrystalRedRegions[10] = gg_rct_CrystalsRed0010
    set udg_CrystalRedRegions[11] = gg_rct_CrystalsRed0011
    set udg_CrystalRedRegions[12] = gg_rct_CrystalsRed0012
    set udg_CrystalRedRegions[13] = gg_rct_CrystalsRed0013
    set udg_CrystalRedRegions[14] = gg_rct_CrystalsRed0014
    set udg_CrystalRedRegions[15] = gg_rct_CrystalsRed0015
    set udg_CrystalRedRegions[16] = gg_rct_CrystalsRed0016
    set udg_CrystalRedRegions[17] = gg_rct_CrystalsRed0017
    set udg_CrystalRedRegions[18] = gg_rct_CrystalsRed0018
    set udg_CrystalRedRegions[19] = gg_rct_CrystalsRed0019
    set udg_CrystalRedRegions[20] = gg_rct_CrystalsRed0020

// -------- Blue Crystals --------


// -------- Green Crystals --------


// -------- Yellow Crystals --------


// -------- Any Crystals --------
    set udg_CrystalAnyRegions[1] = gg_rct_CrystalsAny0001
    set udg_CrystalAnyRegions[2] = gg_rct_CrystalsAny0002
    set udg_CrystalAnyRegions[3] = gg_rct_CrystalsAny0003
    set udg_CrystalAnyRegions[4] = gg_rct_CrystalsAny0004
    set udg_CrystalAnyRegions[5] = gg_rct_CrystalsAny0005
    set udg_CrystalAnyRegions[6] = gg_rct_CrystalsAny0006
// Continue making "ANY" spawn regions...

endfunction


//===========================================================================
function InitTrig_Crystals_Init takes nothing returns nothing
    set gg_trg_Crystals_Init = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle( gg_trg_Crystals_Init, 0.00 )
    call TriggerAddAction( gg_trg_Crystals_Init, function Trig_Crystals_Init_Actions )
endfunction
