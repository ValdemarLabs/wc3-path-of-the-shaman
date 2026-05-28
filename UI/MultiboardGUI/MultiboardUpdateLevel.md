MultiboardUpdateLevel
    Events
        Unit - A unit Gains a level
    Conditions
        Or - Any (Conditions) are true
            Conditions
                (Triggering unit) Equal to Nazgrek
                (Triggering unit) Equal to Zulkis
                ((Triggering unit) is in Companion_Group.) Equal to True
                ((Triggering unit) is in TamedUnits.) Equal to True
    Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Triggering unit) Equal to Nazgrek
            Then - Actions
                -------- NAZGREK Level --------
                Multiboard - Set the text for Multiboard item in column 4, row 2 to (|c007EBFF1 + ((String((Hero level of Nazgrek))) + |r))
                -------- NAZGREK Ability Points --------
                Multiboard - Set the text for Multiboard item in column 6, row 2 to (|c007EBFF1 + ((String(AbilityPointsNazgrek)) + |r))
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Triggering unit) Equal to Zulkis
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                -------- ZULKIS Level --------
                Multiboard - Set the text for Multiboard item in column 4, row 3 to (|c007EBFF1 + ((String((Hero level of Zulkis))) + |r))
                -------- ZULKIS Ability Points --------
                Multiboard - Set the text for Multiboard item in column 6, row 3 to (|c007EBFF1 + ((String(AbilityPointsZulkis)) + |r))
            Else - Actions
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ((Triggering unit) is in Companion_Group.) Equal to True
            Then - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        ((Triggering unit) is in Companion_Group.) Equal to True
                    Then - Actions
                        -------- Companion Level --------
                        Set VariableSet Multiboard_RowVar = (6 + CompanionIndex[(Custom value of (Triggering unit))])
                        Multiboard - Set the text for Multiboard item in column 4, row Multiboard_RowVar to (|c007EBFF1 + ((String((Hero level of (Triggering unit)))) + |r))
                    Else - Actions
            Else - Actions
