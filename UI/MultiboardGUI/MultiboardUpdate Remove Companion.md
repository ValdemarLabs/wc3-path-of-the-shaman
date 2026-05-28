MultiboardUpdate Remove Companion
    Events
    Conditions
    Actions
        Set VariableSet Multiboard_RowVar = 6
        --------    -------- Find Companion to Remove -------- --------
        For each (Integer CompanionMB_ForLoopRemoval) from 1 to CompanionCount, do (Actions)
            Loop - Actions
                If (All Conditions are True) then do (Then Actions) else do (Else Actions)
                    If - Conditions
                        CompanionUnit[CompanionMB_ForLoopRemoval] Equal to CompanionUnitKicked
                    Then - Actions
                        -------- -------- Shift all subsequent companions up -------- --------
                        For each (Integer CompanionMB_IntB) from CompanionMB_ForLoopRemoval to (CompanionCount - 1), do (Actions)
                            Loop - Actions
                                Set VariableSet CompanionUnit[CompanionMB_IntB] = CompanionUnit[(CompanionMB_IntB + 1)]
                                Set VariableSet CompanionIcon[CompanionMB_IntB] = CompanionIcon[(CompanionMB_IntB + 1)]
                                -------- -------- Update the multiboard for the shifted companion --------
                                Multiboard - Set the text for Multiboard item in column 2, row (Multiboard_RowVar + CompanionMB_IntB) to (Proper name of CompanionUnit[CompanionMB_IntB])
                                Multiboard - Set the icon for Multiboard item in column 1, row (Multiboard_RowVar + CompanionMB_IntB) to CompanionIcon[CompanionMB_IntB]
                        -------- Clear the last row --------
                        Set VariableSet CompanionUnit[CompanionCount] = No unit
                        Set VariableSet CompanionIcon[CompanionCount] =  
                        Multiboard - Set the icon for Multiboard item in column 1, row (Multiboard_RowVar + CompanionCount) to  
                        Multiboard - Set the text for Multiboard item in column 1, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 2, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 3, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 4, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 5, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 6, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 7, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 8, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 9, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 10, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 11, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 12, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        Multiboard - Set the text for Multiboard item in column 13, row (Multiboard_RowVar + CompanionCount) to <Empty String>
                        -------- -------- Reduce the companion count -------- --------
                        Set VariableSet CompanionCount = (CompanionCount - 1)
                        -------- -------- Adjust visible rows --------- --------
                        Multiboard - Change the number of rows for Multiboard to (Multiboard_RowVar + CompanionCount)
                        -------- Force refresh --------
                        Multiboard - Minimize Multiboard
                        Multiboard - Maximize Multiboard
                    Else - Actions
