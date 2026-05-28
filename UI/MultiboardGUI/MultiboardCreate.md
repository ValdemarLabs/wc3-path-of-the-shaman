MultiboardCreate
    Events
        Time - Elapsed game time is 1.00 seconds
    Conditions
    Actions
        -------- -------- Create a multiboard with 13 columns and 9 rows, titled Stats -------- --------
        Multiboard - Create a multiboard with 13 columns and 9 rows, titled Stats.
        Set VariableSet Multiboard = (Last created multiboard)
        -------- Colum Widths --------
        Set VariableSet Multiboard_ColumWidth[1] = 1.50
        Set VariableSet Multiboard_ColumWidth[2] = 7.00
        Set VariableSet Multiboard_ColumWidth[3] = 7.00
        Set VariableSet Multiboard_ColumWidth[4] = 3.00
        Set VariableSet Multiboard_ColumWidth[5] = 4.00
        Set VariableSet Multiboard_ColumWidth[6] = 4.00
        Set VariableSet Multiboard_ColumWidth[7] = 3.00
        Set VariableSet Multiboard_ColumWidth[8] = 3.00
        Set VariableSet Multiboard_ColumWidth[9] = 4.00
        Set VariableSet Multiboard_ColumWidth[10] = 3.00
        Set VariableSet Multiboard_ColumWidth[11] = 3.00
        Set VariableSet Multiboard_ColumWidth[12] = 3.00
        Set VariableSet Multiboard_ColumWidth[13] = 3.00
        -------- ======================================== --------
        -------- Set column WIDTHS --------
        For each (Integer Multiboard_Int2) from 1 to 9, do (Actions)
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
        -------- ======================================== --------
        -------- Show texts (Row 1) --------
        Multiboard - Set the display style for Multiboard item in column 1, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 2, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 3, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 4, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 5, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 6, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 7, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 8, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 9, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 10, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 11, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 12, row 1 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 13, row 1 to Show text and Hide icons
        -------- ======================================== --------
        For each (Integer Multiboard_Int1) from 2 to 9, do (Actions)
            Loop - Actions
                -------- Hero/Unit icon --------
                Multiboard - Set the display style for Multiboard item in column 1, row Multiboard_Int1 to Show text and Show icons
                -------- stats --------
                Multiboard - Set the display style for Multiboard item in column 2, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 3, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 4, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 5, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 6, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 7, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 8, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 9, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 10, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 11, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 12, row Multiboard_Int1 to Show text and Hide icons
                Multiboard - Set the display style for Multiboard item in column 13, row Multiboard_Int1 to Show text and Hide icons
        -------- Hide icons --------
        -------- ========== zulkis (at start needs to be hidden) --------
        Multiboard - Set the display style for Multiboard item in column 1, row 3 to Show text and Hide icons
        -------- ========== Tamed and Companions title row --------
        Multiboard - Set the display style for Multiboard item in column 1, row 4 to Show text and Hide icons
        Multiboard - Set the display style for Multiboard item in column 1, row 6 to Show text and Hide icons
        -------- ======================================== --------
        --------  -------- Titles for Columns (Header Row 1) -------- --------
        Multiboard - Set the text for Multiboard item in column 1, row 1 to <Empty String>
        Multiboard - Set the text for Multiboard item in column 2, row 1 to <Empty String>
        Multiboard - Set the text for Multiboard item in column 3, row 1 to |cFFFFCC00Status|r
        Multiboard - Set the text for Multiboard item in column 4, row 1 to |cFFFFCC00Level|r
        Multiboard - Set the text for Multiboard item in column 5, row 1 to |cFFFFCC00Rested|r
        Multiboard - Set the text for Multiboard item in column 6, row 1 to |cFFFFCC00Points|r
        Multiboard - Set the text for Multiboard item in column 7, row 1 to |cFFFFCC00Hit|r
        Multiboard - Set the text for Multiboard item in column 8, row 1 to |cFFFFCC00Crit|r
        Multiboard - Set the text for Multiboard item in column 9, row 1 to |cFFFFCC00Dodge|r
        Multiboard - Set the text for Multiboard item in column 10, row 1 to |cFFFFCC00Block|r
        Multiboard - Set the text for Multiboard item in column 11, row 1 to |cFFFFCC00Spell|r
        Multiboard - Set the text for Multiboard item in column 12, row 1 to |cFFFFCC00Kills|r
        Multiboard - Set the text for Multiboard item in column 13, row 1 to |cFFFFCC00Deaths|r
        -------- -------- Nazgrek (Main Hero, Row 2) -------- --------
        Multiboard - Set the text for Multiboard item in column 2, row 2 to Nazgrek
        Multiboard - Set the icon for Multiboard item in column 1, row 2 to ReplaceableTextures\CommandButtons\BTNFrostwolfrider.blp
        Multiboard - Set the text for Multiboard item in column 4, row 2 to (|c007EBFF1 + ((String((Hero level of Nazgrek))) + |r))
        Multiboard - Set the text for Multiboard item in column 6, row 2 to (|c007EBFF1 + ((String(AbilityPointsNazgrek)) + |r))
        -------- -------- 2nd Player Hero (Row 3) -------- --------
        Multiboard - Set the text for Multiboard item in column 2, row 3 to <Empty String>
        Multiboard - Set the icon for Multiboard item in column 1, row 3 to  
        -------- Tamed (Row 4) --------
        Multiboard - Set the text for Multiboard item in column 2, row 4 to |cFFFFCC00Tamed|r
        -------- Shadowclaw (Row 5) --------
        Multiboard - Set the text for Multiboard item in column 2, row 5 to Shadowclaw
        Multiboard - Set the icon for Multiboard item in column 1, row 5 to ReplaceableTextures\CommandButtons\BTNDireWolf.blp
        -------- Companions (Row 6) --------
        Multiboard - Set the text for Multiboard item in column 2, row 6 to |cFFFFCC00Companion...
        -------- -------- Companion 1 -------- --------
        Multiboard - Set the text for Multiboard item in column 2, row 7 to <Empty String>
        -------- -------- Companion 2 -------- --------
        Multiboard - Set the text for Multiboard item in column 2, row 8 to <Empty String>
        -------- -------- Companion 3 -------- --------
        Multiboard - Set the text for Multiboard item in column 2, row 9 to <Empty String>
        -------- ======================================== --------
        -------- At init - only show 5 rows --------
        Multiboard - Change the number of rows for Multiboard to 5
        -------- show multiboard --------
        Multiboard - Minimize Multiboard
        Multiboard - Maximize Multiboard
        Multiboard - Minimize Multiboard
        --------  TURN ON TRIGGERS FOR UPDATE... --------
        Trigger - Turn on MultiboardUpdate <gen>
        Trigger - Turn on MultiboardUpdateLevel <gen>
        Custom script:   call DestroyTrigger(gg_trg_MultiboardCreate)
