MultiboardUpdate Add Companion
    Events
    Conditions
    Actions
        Set VariableSet Multiboard_RowVar = (6 + CompanionCount)
        Game - Display to (All players) the text: (debug multiboard RowVar value:  + (String(Multiboard_RowVar)))
        -------- Adjust visible rows --------
        Multiboard - Change the number of rows for Multiboard to Multiboard_RowVar
        -------- Companion Heading --------
        Multiboard - Set the display style for Multiboard item in column 1, row 6 to Show text and Hide icons
        Multiboard - Set the text for Multiboard item in column 2, row 6 to |cFFFFCC00Companion...
        -------- ======================================== --------
        -------- Set column WIDTHS --------
        For each (Integer Multiboard_Int2) from 1 to Multiboard_RowVar, do (Actions)
            Loop - Actions
                Multiboard - Set the width for Multiboard item in column 1, row Multiboard_Int2 to Multiboard_ColumWidth[1]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 2, row Multiboard_Int2 to Multiboard_ColumWidth[2]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 3, row Multiboard_Int2 to Multiboard_ColumWidth[3]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 4, row Multiboard_Int2 to Multiboard_ColumWidth[4]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 5, row Multiboard_Int2 to Multiboard_ColumWidth[5]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 6, row Multiboard_Int2 to Multiboard_ColumWidth[6]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 7, row Multiboard_Int2 to Multiboard_ColumWidth[7]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 8, row Multiboard_Int2 to Multiboard_ColumWidth[8]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 9, row Multiboard_Int2 to Multiboard_ColumWidth[9]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 10, row Multiboard_Int2 to Multiboard_ColumWidth[10]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 11, row Multiboard_Int2 to Multiboard_ColumWidth[11]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 12, row Multiboard_Int2 to Multiboard_ColumWidth[12]% of the total screen width
                Multiboard - Set the width for Multiboard item in column 13, row Multiboard_Int2 to Multiboard_ColumWidth[13]% of the total screen width
        -------- Set display styles for ALL companion rows --------
        For each (Integer Multiboard_Int3) from 7 to Multiboard_RowVar, do (Actions)
            Loop - Actions
                -------- Hero/Unit icon --------
                Multiboard - Set the display style for Multiboard item in column 1, row Multiboard_Int3 to Show text and Show icons
                -------- stats --------
                Multiboard - Set the display style for Multiboard item in column 2, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 3, row Multiboard_RowVar to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 4, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 5, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 6, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 7, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 8, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 9, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 10, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 11, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 12, row Multiboard_Int3 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 13, row Multiboard_Int3 to Show text and Hide icons
        -------- ======================================== --------
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ((Unit-type of CompanionUnit[CompanionCount]) is A Hero) Equal to True
            Then - Actions
                -------- HERO --------
                Multiboard - Set the text for Multiboard item in column 2, row Multiboard_RowVar to (Proper name of CompanionUnit[CompanionCount])
            Else - Actions
                -------- UNIT --------
                Multiboard - Set the text for Multiboard item in column 2, row Multiboard_RowVar to (Name of CompanionUnit[CompanionCount])
        Multiboard - Set the icon for Multiboard item in column 1, row Multiboard_RowVar to CompanionIcon[CompanionCount]
        Multiboard - Set the text for Multiboard item in column 3, row Multiboard_RowVar to <Empty String>
        Multiboard - Set the text for Multiboard item in column 5, row Multiboard_RowVar to <Empty String>
        Multiboard - Set the text for Multiboard item in column 6, row Multiboard_RowVar to <Empty String>
        -------- Companion level and stats --------
        Multiboard - Set the text for Multiboard item in column 4, row Multiboard_RowVar to (|c007EBFF1 + ((String((Hero level of CompanionUnit[CompanionCount]))) + |r))
        If (All Conditions are True) then do (Then Actions) else do (Else Actions)
            If - Conditions
                ((Unit-type of CompanionUnit[CompanionCount]) is A Hero) Not equal to True
            Then - Actions
                Multiboard - Set the text for Multiboard item in column 4, row Multiboard_RowVar to (|c007EBFF1 + ((String(CompanionHiredUnitLevel[(Custom value of CompanionUnit[CompanionCount])])) + |r))
            Else - Actions
        --------  // HIT --------
        Multiboard - Set the text for Multiboard item in column 7, row Multiboard_RowVar to ((String(Stats_Hit[(Custom value of CompanionUnit[CompanionCount])])) + %)
        --------  // CRIT --------
        Multiboard - Set the text for Multiboard item in column 8, row Multiboard_RowVar to ((String(Stats_Crit[(Custom value of CompanionUnit[CompanionCount])])) + %)
        --------  // DODGE --------
        Multiboard - Set the text for Multiboard item in column 9, row Multiboard_RowVar to ((String(Stats_Dodge[(Custom value of CompanionUnit[CompanionCount])])) + %)
        --------  // BLOCK --------
        Multiboard - Set the text for Multiboard item in column 10, row Multiboard_RowVar to ((String(Stats_Block[(Custom value of CompanionUnit[CompanionCount])])) + %)
        --------  // SPELL BONUS --------
        Multiboard - Set the text for Multiboard item in column 11, row Multiboard_RowVar to ((String(Stats_SpellPowerPct[(Custom value of CompanionUnit[CompanionCount])])) + %)
        --------  // KILLS --------
        Multiboard - Set the text for Multiboard item in column 12, row Multiboard_RowVar to (0 + <Empty String>)
        --------  // DEATHS --------
        Multiboard - Set the text for Multiboard item in column 13, row Multiboard_RowVar to (0 + <Empty String>)
