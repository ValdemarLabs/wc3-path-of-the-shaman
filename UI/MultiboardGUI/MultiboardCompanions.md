multiboardUpdate Companions
    Events
        Time - Every 1.00 seconds of game time
    Conditions
        (Number of units in Companion_Group) Greater than 0
    Actions
        -------- ================= COMPANIONS --------
        For each (Integer Multiboard_UpdateInt) from 1 to CompanionCount, do (Actions)
            Loop - Actions
                Set VariableSet Multiboard_RowVarUpdate = (6 + CompanionIndex[(Custom value of CompanionUnit[Multiboard_UpdateInt])])
                -------- HP --------
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        IsUnitAlive[(Custom value of CompanionUnit[Multiboard_UpdateInt])] Equal to True
                    Then - Actions
                        --------     -------- Get the unit of the current companion -------- --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of CompanionUnit[Multiboard_UpdateInt]) Greater than or equal to 75.00
                            Then - Actions
                                -------- Green --------
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to ((|cFF00FF00 + ((String((Integer((Percentage life of CompanionUnit[Multiboard_UpdateInt]))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of CompanionUnit[Multiboard_UpdateInt]))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of CompanionUnit[Multiboard_UpdateInt]) Greater than or equal to 50.00
                                (Percentage life of CompanionUnit[Multiboard_UpdateInt]) Less than 75.00
                            Then - Actions
                                -------- Yellow --------
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to ((|cFFFFFC01 + ((String((Integer((Percentage life of CompanionUnit[Multiboard_UpdateInt]))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of CompanionUnit[Multiboard_UpdateInt]))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of CompanionUnit[Multiboard_UpdateInt]) Greater than or equal to 25.00
                                (Percentage life of CompanionUnit[Multiboard_UpdateInt]) Less than 50.00
                            Then - Actions
                                -------- Orange --------
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to ((|cFFFE8A0E + ((String((Integer((Percentage life of CompanionUnit[Multiboard_UpdateInt]))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of CompanionUnit[Multiboard_UpdateInt]))))) + |r))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                (Percentage life of CompanionUnit[Multiboard_UpdateInt]) Less than 25.00
                            Then - Actions
                                -------- RED --------
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to ((|cFFFF0000 + ((String((Integer((Percentage life of CompanionUnit[Multiboard_UpdateInt]))))) + |r)) + (/ + (|cFF7EBFF1 + ((String((Integer((Percentage mana of CompanionUnit[Multiboard_UpdateInt]))))) + |r))))
                            Else - Actions
                    Else - Actions
                        Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to |cFFFF0000Dead|r
                        -------- Revive Time show depending on the Hero - multiple possibilities --------
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                CompanionUnit[Multiboard_UpdateInt] Equal to NPC_Horde_AI_Rogue
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerRogue))))) + ))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                CompanionUnit[Multiboard_UpdateInt] Equal to NPC_Horde_AI_Warlock
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerWarlock))))) + ))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                CompanionUnit[Multiboard_UpdateInt] Equal to NPC_Horde_AI_Shaman
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerRestoshaman))))) + ))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                CompanionUnit[Multiboard_UpdateInt] Equal to NPC_Horde_AI_Warrior
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerWarrior))))) + ))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                CompanionUnit[Multiboard_UpdateInt] Equal to NPC_Neutral_Engineer
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerEngineer))))) + ))))
                            Else - Actions
                        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                            If - Conditions
                                CompanionUnit[Multiboard_UpdateInt] Equal to Valeria
                            Then - Actions
                                Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVarUpdate to (|cFFFF0000Dead|r  + (( + ((String((Integer((Remaining time for ReviveTimerValeria))))) + ))))
                            Else - Actions
                --------  // HIT --------
                Multiboard - Set the text for Multiboard item in column 7, row Multiboard_RowVarUpdate to ((String(Stats_Hit[(Custom value of CompanionUnit[Multiboard_UpdateInt])])) + %)
                --------  // CRIT --------
                Multiboard - Set the text for Multiboard item in column 8, row Multiboard_RowVarUpdate to ((String(Stats_Crit[(Custom value of CompanionUnit[Multiboard_UpdateInt])])) + %)
                --------  // DODGE --------
                Multiboard - Set the text for Multiboard item in column 9, row Multiboard_RowVarUpdate to ((String(Stats_Dodge[(Custom value of CompanionUnit[Multiboard_UpdateInt])])) + %)
                --------  // BLOCK --------
                Multiboard - Set the text for Multiboard item in column 10, row Multiboard_RowVarUpdate to ((String(Stats_Block[(Custom value of CompanionUnit[Multiboard_UpdateInt])])) + %)
                --------  // SPELL BONUS --------
                Multiboard - Set the text for Multiboard item in column 11, row Multiboard_RowVarUpdate to ((String(Stats_SpellPowerPct[(Custom value of CompanionUnit[Multiboard_UpdateInt])])) + %)
