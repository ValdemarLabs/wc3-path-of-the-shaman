MultiboardUpdateLevelTamed
    Events
    Conditions
    Actions
        -------- Tamed Unit Level --------
        Set VariableSet Multiboard_RowVar = 5
        Multiboard - Set the text for Multiboard item in column 4, row Multiboard_RowVar to (|c007EBFF1 + ((String((Level of TamedUnit))) + |r))
