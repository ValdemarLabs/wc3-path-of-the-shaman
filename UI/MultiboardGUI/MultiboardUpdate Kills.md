MultiboardUpdate Kills
    Events
        Game - AfterDamageEvent becomes Equal to 1.00
    Conditions
        IsUnitAlive[(Custom value of DamageEventTarget)] Equal to False
        Or - Any (Conditions) are true
            Conditions
                DamageEventSource Equal to Nazgrek
                DamageEventSource Equal to Zulkis
                (DamageEventSource is in Companion_Group.) Equal to True
                (DamageEventSource is in TamedUnits.) Equal to True
    Actions
        -------- PLAYER UNITS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                DamageEventSource Equal to Nazgrek
            Then - Actions
                Set VariableSet NazgrekKillCount = (NazgrekKillCount + 1)
                Multiboard - Set the text for Multiboard item in column 12, row 2 to (String(NazgrekKillCount))
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                DamageEventSource Equal to Zulkis
            Then - Actions
                Set VariableSet ZulkisKillCount = (ZulkisKillCount + 1)
                Multiboard - Set the text for Multiboard item in column 12, row 3 to (String(ZulkisKillCount))
            Else - Actions
        -------- COMPANIONS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (DamageEventSource is in Companion_Group.) Equal to True
            Then - Actions
                -------- HERO --------
                -------- REGULAR --------
                Set VariableSet CompanionUnitKillCount[(Custom value of DamageEventSource)] = (CompanionUnitKillCount[(Custom value of DamageEventSource)] + 1)
                Set VariableSet Multiboard_RowVar = (6 + CompanionIndex[(Custom value of DamageEventSource)])
                Multiboard - Set the text for Multiboard item in column 12, row Multiboard_RowVarUpdate to ((String(CompanionUnitKillCount[(Custom value of DamageEventSource)])) + <Empty String>)
            Else - Actions
        -------- TAMED --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (DamageEventSource is in TamedUnits.) Equal to True
            Then - Actions
                -------- TAMED UNIT --------
                Set VariableSet TamedUnitKillCount = (TamedUnitKillCount + 1)
                Multiboard - Set the text for Multiboard item in column 12, row 5 to (String(TamedUnitKillCount))
                -------- REGULAR --------
            Else - Actions
