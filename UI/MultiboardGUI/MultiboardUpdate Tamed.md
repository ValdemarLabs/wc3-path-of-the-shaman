multiboardUpdate Tamed
    Events
        Time - Every 1.00 seconds of game time
    Conditions
        (Number of units in TamedUnits) Greater than 0
    Actions
        -------- ================= TAMED --------
        Set VariableSet Multiboard_RowVarUpdate = 5
        --------  // HIT --------
        Multiboard - Set the text for Multiboard item in column 7, row Multiboard_RowVarUpdate to ((String(Stats_Hit[(Custom value of TamedUnit)])) + %)
        --------  // CRIT --------
        Multiboard - Set the text for Multiboard item in column 8, row Multiboard_RowVarUpdate to ((String(Stats_Crit[(Custom value of TamedUnit)])) + %)
        --------  // DODGE --------
        Multiboard - Set the text for Multiboard item in column 9, row Multiboard_RowVarUpdate to ((String(Stats_Dodge[(Custom value of TamedUnit)])) + %)
        --------  // BLOCK --------
        Multiboard - Set the text for Multiboard item in column 10, row Multiboard_RowVarUpdate to ((String(Stats_Block[(Custom value of TamedUnit)])) + %)
        --------  // SPELL BONUS --------
        Multiboard - Set the text for Multiboard item in column 11, row Multiboard_RowVarUpdate to ((String(Stats_SpellPowerPct[(Custom value of TamedUnit)])) + %)
