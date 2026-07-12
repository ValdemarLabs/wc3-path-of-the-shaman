//===========================================================================
//    Mana Crystals
//===========================================================================

function Trig_ManaCrystals_Init_Actions takes nothing returns nothing
    // Define regions for spawning ores
// -------- Red Crystals --------
    set udg_CrystalManaRegions[1] = gg_rct_ManaCrystal01
    set udg_CrystalManaRegions[2] = gg_rct_ManaCrystal02
    set udg_CrystalManaRegions[3] = gg_rct_ManaCrystal03
    set udg_CrystalManaRegions[4] = gg_rct_ManaCrystal04
    set udg_CrystalManaRegions[5] = gg_rct_ManaCrystal05
    set udg_CrystalManaRegions[6] = gg_rct_ManaCrystal06
    set udg_CrystalManaRegions[7] = gg_rct_ManaCrystal07
    set udg_CrystalManaRegions[8] = gg_rct_ManaCrystal08
    set udg_CrystalManaRegions[9] = gg_rct_ManaCrystal09
    set udg_CrystalManaRegions[10] = gg_rct_ManaCrystal10
    set udg_CrystalManaRegions[11] = gg_rct_ManaCrystal11
    set udg_CrystalManaRegions[12] = gg_rct_ManaCrystal12
    set udg_CrystalManaRegions[13] = gg_rct_ManaCrystal13
    set udg_CrystalManaRegions[14] = gg_rct_ManaCrystal14
    set udg_CrystalManaRegions[15] = gg_rct_ManaCrystal15
    set udg_CrystalManaRegions[16] = gg_rct_ManaCrystal16
    set udg_CrystalManaRegions[17] = gg_rct_ManaCrystal17
    set udg_CrystalManaRegions[18] = gg_rct_ManaCrystal18
    set udg_CrystalManaRegions[19] = gg_rct_ManaCrystal19

endfunction


//===========================================================================
function InitTrig_ManaCrystals_Init takes nothing returns nothing
    set gg_trg_ManaCrystals_Init = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle( gg_trg_ManaCrystals_Init, 0.00 )
    call TriggerAddAction( gg_trg_ManaCrystals_Init, function Trig_ManaCrystals_Init_Actions )
endfunction
