MultiboardUpdate Deaths
    Events
        Unit - A unit Dies
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Triggering unit) Equal to Nazgrek
                (Triggering unit) Equal to Zulkis
                ((Triggering unit) is in Companion_Group.) Equal to True
    Actions
        -------- PLAYER UNITS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Triggering unit) Equal to Nazgrek
            Then - Actions
                Set VariableSet NazgrekDeathCount = (NazgrekDeathCount + 1)
                Multiboard - Set the text for Multiboard item in column 13, row 2 to (String(NazgrekDeathCount))
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Triggering unit) Equal to Zulkis
            Then - Actions
                Set VariableSet ZulkisDeathCount = (ZulkisDeathCount + 1)
                Multiboard - Set the text for Multiboard item in column 13, row 3 to (String(ZulkisDeathCount))
            Else - Actions
        -------- COMPANIONS --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ((Triggering unit) is in Companion_Group.) Equal to True
            Then - Actions
                -------- HERO --------
                -------- REGULAR --------
                Set VariableSet CompanionUnitDeathCount[(Custom value of (Triggering unit))] = (CompanionUnitDeathCount[(Custom value of (Triggering unit))] + 1)
                Set VariableSet Multiboard_RowVar = (6 + CompanionIndex[(Custom value of (Triggering unit))])
                Multiboard - Set the text for Multiboard item in column 13, row Multiboard_RowVarUpdate to ((String(CompanionUnitDeathCount[(Custom value of (Triggering unit))])) + <Empty String>)
            Else - Actions
        -------- TAMED --------
