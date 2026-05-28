MultiboardUpdate
    Events
        Time - Every 1.00 seconds of game time
    Conditions
    Actions
        -------- ================= ROW 2 --------
        --------  NAZGREK // HP --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                IsUnitAlive[(Custom value of Nazgrek)] Equal to True
            Then - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Percentage life of Nazgrek) Greater than or equal to 75.00
                    Then - Actions
                        -------- Green --------
                        Multiboard - Set the text for Multiboard item in column 3, row 2 to ((|cFF00FF00 + ((String((Integer((Percentage life of Nazgrek))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Nazgrek))))) + |r))))
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Percentage life of Nazgrek) Greater than or equal to 50.00
                        (Percentage life of Nazgrek) Less than 75.00
                    Then - Actions
                        -------- Yellow --------
                        Multiboard - Set the text for Multiboard item in column 3, row 2 to ((|cFFFFFC01 + ((String((Integer((Percentage life of Nazgrek))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Nazgrek))))) + |r))))
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Percentage life of Nazgrek) Greater than or equal to 25.00
                        (Percentage life of Nazgrek) Less than 50.00
                    Then - Actions
                        -------- Orange --------
                        Multiboard - Set the text for Multiboard item in column 3, row 2 to ((|cFFFE8A0E + ((String((Integer((Percentage life of Nazgrek))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Nazgrek))))) + |r))))
                    Else - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Percentage life of Nazgrek) Less than 25.00
                    Then - Actions
                        -------- RED --------
                        Multiboard - Set the text for Multiboard item in column 3, row 2 to ((|cFFFF0000 + ((String((Integer((Percentage life of Nazgrek))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Nazgrek))))) + |r))))
                    Else - Actions
            Else - Actions
                Multiboard - Set the text for Multiboard item in column 3, row 2 to |cFFFF0000Dead|r
                -------- Nazgrek (and zulkis) revive timers need to be merged: Just 1 ReviveTimer.... --------
                Multiboard - Set the text for Multiboard item in column 3, row 2 to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerNazgrek))))) + ))))
        -------- ================= ROW 3 --------
        --------  ZULKIS // HP --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Zulkis is alive) Equal to True
                    Then - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of Zulkis) Greater than or equal to 75.00
                            Then - Actions
                                -------- Green --------
                                Multiboard - Set the text for Multiboard item in column 3, row 3 to ((|cFF00FF00 + ((String((Integer((Percentage life of Zulkis))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Zulkis))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of Zulkis) Greater than or equal to 50.00
                                (Percentage life of Zulkis) Less than 75.00
                            Then - Actions
                                -------- Yellow --------
                                Multiboard - Set the text for Multiboard item in column 3, row 3 to ((|cFFFFFC01 + ((String((Integer((Percentage life of Zulkis))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Zulkis))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of Zulkis) Greater than or equal to 25.00
                                (Percentage life of Zulkis) Less than 50.00
                            Then - Actions
                                -------- Orange --------
                                Multiboard - Set the text for Multiboard item in column 3, row 3 to ((|cFFFE8A0E + ((String((Integer((Percentage life of Zulkis))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Zulkis))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of Zulkis) Less than 25.00
                            Then - Actions
                                -------- RED --------
                                Multiboard - Set the text for Multiboard item in column 3, row 2 to ((|cFFFF0000 + ((String((Integer((Percentage life of Zulkis))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of Zulkis))))) + |r))))
                            Else - Actions
                    Else - Actions
                        Multiboard - Set the text for Multiboard item in column 3, row 3 to |cFFFF0000Dead|r
                        -------- Nazgrek (and zulkis) revive timers need to be merged: Just 1 ReviveTimer.... --------
                        Multiboard - Set the text for Multiboard item in column 3, row 3 to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerZulkis))))) + ))))
            Else - Actions
        -------- RESTED --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Nazgrek has buff |cFF00FF00Rested|r ) Equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 5, row 2 to (|c007EBFF1 + (Yes + |r))
            Else - Actions
                Multiboard - Set the text for Multiboard item in column 5, row 2 to (|c007EBFF1 + (No + |r))
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        (Zulkis has buff |cFF00FF00Rested|r ) Equal to True
                    Then - Actions
                        Multiboard - Set the text for Multiboard item in column 5, row 3 to (|c007EBFF1 + (Yes + |r))
                    Else - Actions
                        Multiboard - Set the text for Multiboard item in column 5, row 3 to (|c007EBFF1 + (No + |r))
            Else - Actions
        --------  // HIT --------
        Multiboard - Set the text for Multiboard item in column 7, row 2 to ((String(Stats_Hit[(Custom value of Nazgrek)])) + %)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 7, row 3 to ((String(Stats_Hit[(Custom value of Zulkis)])) + %)
            Else - Actions
        --------  // CRIT --------
        Multiboard - Set the text for Multiboard item in column 8, row 2 to ((String(Stats_Crit[(Custom value of Nazgrek)])) + %)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 8, row 3 to ((String(Stats_Crit[(Custom value of Zulkis)])) + %)
            Else - Actions
        --------  // DODGE --------
        Multiboard - Set the text for Multiboard item in column 9, row 2 to ((String(Stats_Dodge[(Custom value of Nazgrek)])) + %)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 9, row 3 to ((String(Stats_Dodge[(Custom value of Zulkis)])) + %)
            Else - Actions
        --------  // BLOCK --------
        Multiboard - Set the text for Multiboard item in column 10, row 2 to ((String(Stats_Block[(Custom value of Nazgrek)])) + %)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 10, row 3 to ((String(Stats_Block[(Custom value of Zulkis)])) + %)
            Else - Actions
        --------  // SPELL BONUS --------
        Multiboard - Set the text for Multiboard item in column 11, row 2 to ((String(Stats_SpellPowerPct[(Custom value of Nazgrek)])) + %)
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                Multiboard_ZulkisCreated Equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 11, row 3 to ((String(Stats_SpellPowerPct[(Custom value of Zulkis)])) + %)
            Else - Actions
        -------- ================= ROW 5 --------
        -------- TAMED / HP --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                (Number of units in TamedUnits) Greater than or equal to 1
            Then - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        Pet_Dead Equal to False
                    Then - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of TamedUnit) Greater than or equal to 75.00
                            Then - Actions
                                -------- Green --------
                                Multiboard - Set the text for Multiboard item in column 3, row 5 to ((|cFF00FF00 + ((String((Integer((Percentage life of TamedUnit))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of TamedUnit))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of TamedUnit) Greater than or equal to 50.00
                                (Percentage life of TamedUnit) Less than 75.00
                            Then - Actions
                                -------- Yellow --------
                                Multiboard - Set the text for Multiboard item in column 3, row 5 to ((|cFFFFFC01 + ((String((Integer((Percentage life of TamedUnit))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of TamedUnit))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of TamedUnit) Greater than or equal to 25.00
                                (Percentage life of TamedUnit) Less than 50.00
                            Then - Actions
                                -------- Orange --------
                                Multiboard - Set the text for Multiboard item in column 3, row 5 to ((|cFFFE8A0E + ((String((Integer((Percentage life of TamedUnit))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of TamedUnit))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of TamedUnit) Less than 25.00
                            Then - Actions
                                -------- RED --------
                                Multiboard - Set the text for Multiboard item in column 3, row 5 to ((|cFFFF0000 + ((String((Integer((Percentage life of TamedUnit))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of TamedUnit))))) + |r))))
                            Else - Actions
                    Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Remaining time for ReviveTimerPet) Less than or equal to 0.00
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row 5 to |cFFFF0000Dead|r 
                            Else - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row 5 to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerPet))))) + ))))
            Else - Actions
                Multiboard - Set the text for Multiboard item in column 3, row 5 to <Empty String>
